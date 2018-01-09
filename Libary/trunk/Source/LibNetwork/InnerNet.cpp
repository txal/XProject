#include "Common/Platform.h"
#include "LibNetwork/IO.h"
#include "LibNetwork/InnerNet.h"

InnerNet::InnerNet()
{
	m_nLastPrintTime = 0;
}

bool InnerNet::Init(int nServiceID, int nMaxConns)
{
	char sNetName[32];
	sprintf(sNetName, "Innernet%d", nServiceID);
	return Net::Init(sNetName, nServiceID, nMaxConns, INNERNET_MAX_RWBUF);
}

void InnerNet::ReadData(SESSION* pSession)
{
	int nRet = IORead(pSession->nSock, pSession, pSession->oRecvBuf, this, INNERNET_MAX_RW_PEREVENT);
	if (nRet == -1)
	{
		CloseSession(pSession->nSessionID);
		return;
	}
}

void InnerNet::WriteData(SESSION* pSession)
{
	uint32_t uOutPackets = 0;
	uint32_t uTotalWrited = 0;
	int nRet = IOWrite(pSession->nSock, &pSession->oPacketList, INNERNET_MAX_RW_PEREVENT, &uOutPackets, &uTotalWrited);
	if (nRet == -1)
	{
		CloseSession(pSession->nSessionID);
		return;
	}
	pSession->uBlockDataSize -= uTotalWrited;
	pSession->uOutPacketCount += uOutPackets;
	uint32_t &uTotalOutPackets = GetOutPackets();
	uTotalOutPackets += uOutPackets;
}

bool InnerNet::CheckBlockDataSize(SESSION* pSession)
{
	if (pSession->uBlockDataSize >= INNERNET_MAX_RW_PEREVENT)
	{
		int nNowSec = (int)time(0);
		if (m_nLastPrintTime != nNowSec)
		{
			m_nLastPrintTime = nNowSec;
			INNER_HEADER oHeader;
			Packet* poPacket = pSession->oPacketList.Back();
			int nCmd = 0, nSrc = 0, nTar = 0;
			if (poPacket != NULL)
			{
				poPacket->GetInnerHeader(oHeader, NULL, false);
				nCmd = oHeader.uCmd;
				nSrc = oHeader.nSrc;
				nTar = oHeader.nTar;
			}
			XLog(LEVEL_ERROR, "%s: Session:%d write block data out of size:%dK/%dK packets:%d cmd:%d src:%d tar:%d\n"
					, GetName(), pSession->nSessionID, pSession->uBlockDataSize / 1024, INNERNET_MAX_RW_PEREVENT / 1024
					, pSession->oPacketList.Size(), nCmd, nSrc, nTar);
		}
	}
	return true;
}

void InnerNet::Timer(long nInterval)
{
	static time_t nLastTime = time(0);
	static uint32_t nLastInPackets = 0;
	static uint32_t nLastOutPackets = 0;
	time_t nTimeNow = time(0);
	if (nLastTime != nTimeNow)
	{
		nLastTime = nTimeNow;
		uint32_t nCurInPackets = GetInPackets();
		uint32_t nCurOutPackets = GetOutPackets();
		//XLog(LEVEL_INFO, "%s: iopackets: %d/%d packets/sec\n", GetName(), nCurInPackets - nLastInPackets, nCurOutPackets - nLastOutPackets);
		nLastInPackets = nCurInPackets;
		nLastOutPackets = nCurOutPackets;
	}
}

void InnerNet::OnRecvPacket(void* pUD, Packet* poPacket)
{
	GetInPackets()++;
	SESSION* pSession = (SESSION*)pUD;
	pSession->uInPacketCount++;
	pSession->nLastInPacketTime	= (int)time(0);

	if (m_bDebugNet)
	{
		INNER_HEADER oHeader;
		poPacket->GetInnerHeader(oHeader, NULL, false);
		XLog(LEVEL_INFO, "Inner recv session:%d cmd:%d src:%d tar:%d size:%d\n", pSession->nSessionID, oHeader.uCmd, oHeader.nSrc, oHeader.nTar, poPacket->GetDataSize());
	}

	Net::OnRecvPacket(pUD, poPacket);
}

// Interface
bool InnerNet::SendPacket(int nSessionID, Packet* poPacket)
{
	if (poPacket->GetDataSize() > INNERNET_MAX_RWBUF)
	{
		XLog(LEVEL_ERROR, "%s: Session:%d packet size out of range:%dK\n", GetName(), nSessionID, INNERNET_MAX_RWBUF/1024);
		return false;
	}
	REQUEST_PACKET oRequest;
	oRequest.uCtrlType = eCTRL_SEND;
	oRequest.U.oSend.nSessionID = nSessionID;
	oRequest.U.oSend.pData = (void*)poPacket;

	if (m_bDebugNet)
	{
		INNER_HEADER oHeader;
		poPacket->GetInnerHeader(oHeader, NULL, false);
		XLog(LEVEL_INFO, "Inner send session:%d cmd:%d src:%d tar:%d size:%d\n", nSessionID, oHeader.uCmd, oHeader.nSrc, oHeader.nTar, poPacket->GetDataSize());
	}

	bool bRet = GetMailBox()->Send(oRequest);
    return bRet;
}
