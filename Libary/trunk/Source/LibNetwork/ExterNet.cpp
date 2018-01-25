#include "LibNetwork/ExterNet.h"
#include "Include/Network/NetAPI.h"
#include "Common/DataStruct/TimeMonitor.h"
#include "LibNetwork/IO.h"

bool ExterNet::Init(int nServiceId, int nMaxConns, int nSecureCPM, int nSecureQPM, int nSecureBlock, int nDeadLinkTime, bool bLinger)
{
	char sNetName[32];
	sprintf(sNetName, "Externet%d", nServiceId);
	m_nSecureCPM = nSecureCPM;
	m_nSecureQPM = nSecureQPM;
	m_nSecureBlock = nSecureBlock;
	m_nDeadLinkTime = nDeadLinkTime;
	return Net::Init(sNetName, nServiceId, nMaxConns, EXTERNET_MAX_RECVBUF, bLinger);
}

void ExterNet::CheckDLK()
{
	time_t nTimeNow = time(NULL);
	if (nTimeNow % 60 != 0)
	{
		return;
	}

	int nMaxSessions = GetMaxSessions();
	SESSION** pSessionArray = GetSessionArray();
	for (int i = 0; i < nMaxSessions; i++)
	{
		SESSION* pSession = pSessionArray[i];
		if (pSession == NULL || pSession->nSessionType != SESSION_TYPE_DATA)
		{
			continue;
		}
		if (nTimeNow - pSession->nLastInPacketTime >= m_nDeadLinkTime)
		{
			int nSessionID = pSession->nSessionID;
			XLog(LEVEL_INFO, "%s: Sock:%u session:%d dead last time:%d\n", GetName(), pSession->nSock, pSession->nSessionID, pSession->nLastInPacketTime);
			CloseSession(nSessionID);
		}
	}
}

// security
bool ExterNet::CheckCPM(uint32_t uIP, const char* psIP)
{
	if (m_nSecureCPM == 0)
	{
		return true;
	}
	int nTimeNow = (int)time(NULL);
	IPConnIter iter = m_oIPConnMap.find(uIP);
	if (iter == m_oIPConnMap.end())
	{
		ConnInfo oInfo;
		oInfo.uConns = 1;
		oInfo.nLastConnTime = nTimeNow;
		oInfo.nLastCheckCPM = nTimeNow;
		oInfo.nBlockStartTime = 0;
		m_oIPConnMap[uIP] = oInfo;
		return true;
	}
	ConnInfo& oInfo = iter->second;

	//屏蔽检测
	int nBlockRemainTime = oInfo.nBlockStartTime + m_nSecureBlock - nTimeNow;
	if (nBlockRemainTime > 0)
	{
		XLog(LEVEL_ERROR, "%s: Ip:%s is blocking remain:%d seconds\n", GetName(), psIP, nBlockRemainTime);
		return false;
	}

	oInfo.uConns++;
	oInfo.nLastConnTime = nTimeNow;
	
	//是否超过阀值
	if (oInfo.uConns < (uint32_t)m_nSecureCPM)
	{
		return true;
	}

	//1分钟超过阀值就屏蔽IP
	bool bRet = true;
	int nPassTime = nTimeNow - oInfo.nLastCheckCPM;
	if (nPassTime <= 60)
	{
		bRet = false;
		oInfo.nBlockStartTime = nTimeNow;
		XLog(LEVEL_ERROR, "%s: Ip:%s CPM >= %d block time:%d seconds\n", GetName(), psIP, m_nSecureCPM, m_nSecureBlock);
	}
	oInfo.uConns = 0;
	oInfo.nLastCheckCPM = nTimeNow;

	//IP地址有100万个则清理
	if (m_oIPConnMap.size() >= 1000000)
	{
		for (IPConnIter iter = m_oIPConnMap.begin(); iter != m_oIPConnMap.end();)
		{
			ConnInfo& oInfo = iter->second;
			if (nTimeNow - oInfo.nBlockStartTime < m_nSecureBlock)
			{
				++iter;
				continue;
			}
			//1天以上的非活跃IP清理掉
			if (nTimeNow - oInfo.nLastConnTime >= 86400)
			{
				iter = m_oIPConnMap.erase(iter);
			}
			else
			{
				++iter;
			}
		}
	}
	return bRet;
}

// security
bool ExterNet::CheckQPM(SESSION* pSession)
{
	//是否超过阀值
	if (m_nSecureQPM == 0 || pSession->uInPacketCount < (uint32_t)m_nSecureQPM)
	{
		return true;
	}

	//1分钟内超过阀值,就断开
	bool bRet = true;
	int nTimeNow = (int)time(NULL);
	int nPassTime = nTimeNow - pSession->nLastCheckQPM;
	if (nPassTime <= 60)
	{
		bRet = false;
		char sIP[256];
		NetAPI::N2P(pSession->uSessionIP, sIP, sizeof(sIP));
		XLog(LEVEL_ERROR, "%s: Session:%d sock:%u ip:%s QPM >= %d close it\n", GetName(), pSession->nSessionID, pSession->nSock, sIP, m_nSecureQPM);
		CloseSession(pSession->nSessionID);
	}
	pSession->uInPacketCount = 0;
	pSession->nLastCheckQPM = nTimeNow;
	return bRet;
}


void ExterNet::ReadData(SESSION* pSession)
{
	int nRet = IORead(pSession->nSock, pSession, pSession->oRecvBuf, this, EXTERNET_MAX_READ_PEREVENT);
	if (nRet == -1 || nRet == 1)
	{
		if (nRet == 1)
		{
			XLog(LEVEL_INFO, "%s: Session:%d read blocking size:%d io packets:%d/%d\n"
				, GetName(), pSession->nSessionID, pSession->uBlockDataSize, pSession->uInPacketCount, pSession->uOutPacketCount);
		}
		CloseSession(pSession->nSessionID);
		return;
	}
}

void ExterNet::WriteData(SESSION* pSession)
{
	uint32_t uOutPackets = 0;
	uint32_t uTotalWrited = 0;
	int nRet = IOWrite(pSession->nSock, &(pSession->oPacketList), EXTERNET_MAX_WRITE_PEREVENT, &uOutPackets, &uTotalWrited);
	if (nRet == -1 || nRet == 1 || pSession->bSentClose)
	{
		CloseSession(pSession->nSessionID);
		if (nRet == 1)
		{
			XLog(LEVEL_INFO, "%s: Session:%d write blocking size:%d io packets:%d/%d\n"
				, GetName(), pSession->nSessionID, pSession->uBlockDataSize, pSession->uInPacketCount, pSession->uOutPacketCount);
		}
		return;
    }
	pSession->uBlockDataSize -= uTotalWrited;
	//XLog(LEVEL_INFO, "%s: write session:%d packs:%d blocks:%d writed:%d\n", GetName(), pSession->nSessionID, pSession->oPacketList.Size(), pSession->nBlockDataSize, nTotalWrited);
	pSession->uOutPacketCount += uOutPackets;

	uint32_t& uTotalOutPackets = GetOutPackets();
	uTotalOutPackets += uOutPackets;
}

bool ExterNet::CheckBlockDataSize(SESSION* pSession)
{
	if (pSession->uBlockDataSize >= EXTERNET_MAX_BLOCK_SIZE)
	{
		XLog(LEVEL_INFO, "%s: Session:%d write block data out of size:%dK/%dK packets:%d\n"
			, GetName(), pSession->nSessionID, pSession->uBlockDataSize / 1024, EXTERNET_MAX_BLOCK_SIZE / 1024, pSession->oPacketList.Size());
		return false;
	}
	return true;
}

void ExterNet::Timer(long nInterval)
{
	CheckDLK();
}

void ExterNet::OnRecvPacket(void* pUD, Packet* poPacket)
{
	GetInPackets()++;
	SESSION* pSession = (SESSION*)pUD;
	pSession->uInPacketCount++;
	pSession->nLastInPacketTime	= (int)time(NULL);
	if (!CheckQPM(pSession))
	{
		poPacket->Release();
		CloseSession(pSession->nSessionID);
		return;
	}

	Net::OnRecvPacket(pUD, poPacket);
}

// Interface
bool ExterNet::SendPacket(int nSessionID, Packet* poPacket)
{
	if (poPacket->GetDataSize() >= 16*1024) //16k
	{
		XLog(LEVEL_INFO, "%s: Session:%d send large packet :%d\n", GetName(), nSessionID, poPacket->GetDataSize());
	}
	if (poPacket->GetDataSize() > EXTERNET_MAX_SENDBUF)
	{
		XLog(LEVEL_ERROR, "%s: Session:%d packet size out of range:%d\n" , GetName(), nSessionID, EXTERNET_MAX_SENDBUF);
		return false;
	}
	REQUEST_PACKET oRequest;
	oRequest.uCtrlType = eCTRL_SEND;
	oRequest.U.oSend.nSessionID = nSessionID;
	oRequest.U.oSend.pData = (void*)poPacket;

	return GetMailBox()->Send(oRequest);
}

