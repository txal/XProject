#include "Server/GlobalServer/UDPNet.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"

std::queue<Packet*> goPacketPool;
UDPNet::UDPNet()
{
	m_nRoomID = 0;
	m_uServerPort = 0;
	m_nServerSocket = -1;
}

UDPNet::~UDPNet()
{
	NetAPI::CloseSocket(m_uServerPort);
	m_uServerPort = -1;
}

bool UDPNet::Init(int nRoomID, uint16_t uServerPort)
{
	m_nRoomID = nRoomID;
	m_uServerPort = uServerPort;

	 m_nServerSocket= NetAPI::CreateUdpSocket();
	 NetAPI::Bind(m_nServerSocket, INADDR_ANY, m_uServerPort);
	 NetAPI::NonBlock(m_nServerSocket);
	 NetAPI::MyWSAIcotl(m_nServerSocket);
	 XLog(LEVEL_INFO, "UDP room:%d bind at port:%d\n", m_nRoomID, m_uServerPort);
	 return true;
}

void UDPNet::Update(int64_t nNowMSTime)
{
	uint32_t uIP = 0;
	uint16_t uPort = 0;
	Packet* pPacket = RecvData(uIP, uPort);
	if (pPacket != NULL)
	{
		SendData(pPacket);
	}
}

void UDPNet::SendData(Packet* pPacket)
{
	EXTER_HEADER oHeader;
	pPacket->GetExterHeader(oHeader, false);
	int nTarget = oHeader.nTarService;
	if ( !(nTarget == 1 || nTarget == 2) )
	{
		ReturnPacket(pPacket);
		XLog(LEVEL_INFO, "SendData target:%d invalid!\n", nTarget);
		return;
	}
	CLIENT& oClient = m_tPairClient[nTarget - 1];
	if (oClient.uIP == 0)
	{
		ReturnPacket(pPacket);
		XLog(LEVEL_INFO, "SendData target:%d not register!\n", nTarget);
		return;
	}
	int nRet = NetAPI::SendTo(m_nServerSocket, pPacket, oClient.uIP, oClient.uPort);
	if (nRet == -1)
	{
		oClient.Reset();
		XLog(LEVEL_INFO, "SendData target:%d ip:%s port:%d index:%u fail!\n", nTarget, oClient.sStrIP, oClient.uPort, oHeader.uPacketIdx);
	}
	ReturnPacket(pPacket);
}

Packet* UDPNet::RecvData(uint32_t& uIP, uint16_t& uPort)
{
	Packet* pPacket = ApplyPacket();
	int nRet = NetAPI::RecvFrom(m_nServerSocket, pPacket, uIP, uPort);
	if (nRet != 1) 
	{
		ReturnPacket(pPacket);
		return NULL;
	}

	EXTER_HEADER oHeader;
	pPacket->GetExterHeader(oHeader, false);

	int nCmd = oHeader.uCmd;
	int nSource = oHeader.nSrcService;
	if (!(nSource == 1 || nSource == 2))
	{
		ReturnPacket(pPacket);
		XLog(LEVEL_INFO, "RecvData source:%d invalid!\n", nSource);
		return NULL;
	}
	CLIENT& oClient = m_tPairClient[nSource - 1];

	//XLog(LEVEL_ERROR, "RecvData source:%d packet ip:%s port:%d index:%u\n", nSource, oClient.sStrIP, uPort, oHeader.uPacketIdx);
	if (nCmd == 1) //注册
	{
		if (oClient.uIP == 0)
		{
			oClient.uIP = uIP;
			oClient.uPort = uPort;
			oClient.uPKIndex = oHeader.uPacketIdx;
			NetAPI::N2P(uIP, oClient.sStrIP, sizeof(oClient.sStrIP));
			XLog(LEVEL_INFO, "RecvData source:%d register successful ip:%s port:%d index:%u\n", nSource, oClient.sStrIP, uPort, oHeader.uPacketIdx);

		}
		else
		{
			XLog(LEVEL_INFO, "RecvData source:%d already register ip:%s port:%d index:%u\n", nSource, oClient.sStrIP, uPort, oHeader.uPacketIdx);
		}
		ReturnPacket(pPacket);
		return NULL;
	}

	if (oHeader.uPacketIdx != oClient.uPKIndex + 1)
	{
		XLog(LEVEL_ERROR, "RecvData source:%d packet lost ip:%s port:%d lastindex:%u nowindex:%u\n", nSource, oClient.sStrIP, uPort, oClient.uPKIndex, oHeader.uPacketIdx);
	}
	oClient.uPKIndex = oHeader.uPacketIdx;

	return pPacket;
}

Packet* UDPNet::ApplyPacket()
{
	if (goPacketPool.size() == 0)
	{
		Packet* pPacket = Packet::Create();
		return pPacket;
	}
	Packet* pPacket = goPacketPool.front();
	goPacketPool.pop();
	return pPacket;
}

void UDPNet::ReturnPacket(Packet* pPacket)
{
	pPacket->Reset();
	goPacketPool.push(pPacket);
}

void UDPNet::InsertPacket(Packet* pPacket)
{
	EXTER_HEADER oHeader;
	oHeader = pPacket->GetExterHeader(oHeader, false);

	for (PKIter iter = m_oPacketList.begin(); iter != m_oPacketList.end();)
	{
		EXTER_HEADER oTmpHeader = ((Packet*)*iter)->GetExterHeader(oHeader, false);
		if (oTmpHeader.uPacketIdx > oHeader.uPacketIdx)
		{
			m_oPacketList.insert(iter, pPacket);
			break;
		}
		else
		{
			if (++iter == m_oPacketList.end())
			{
				m_oPacketList.push_back(pPacket);
				break;
			}
		}
	}
}