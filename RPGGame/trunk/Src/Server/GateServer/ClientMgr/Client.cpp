#include "Server/GateServer/ClientMgr/Client.h"
#include "Include/Network/Network.hpp"
#include "Common/PacketParser/PacketWriter.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"

Client::Client()
{
	m_uRemoteIP = 0;
	m_uCmdIndex = 0;
	m_nSession = 0;

	m_nRoleID = 0;
	m_nPacketTime = 0;
	m_nLogicService = 0;
	m_nLastKeepAlive = 0;
	m_nLastNotifyTime = 0;
}

Client::~Client()
{
}

void Client::Update(int64_t nNowMS)
{
	int nTimeNow = (int)time(0);
	//发呆>=30秒才发送
	if (nTimeNow - m_nPacketTime >= 30)
	{
		//每60秒通知一次
		if (nTimeNow - m_nLastNotifyTime < 60)
		{
			return;
		}
		m_nLastNotifyTime = nTimeNow;

		Packet* poPacket = Packet::Create(32, nPACKET_OFFSET_SIZE, __FILE__, __LINE__);
		if (poPacket == NULL)
		{
			return;
		}

		PacketWriter oWriter(poPacket);
		oWriter << m_nRoleID << m_nPacketTime;
		uint16_t uSrcServer = gpoContext->GetServerID();
		int8_t nSrcService = gpoContext->GetService()->GetServiceID();
		int8_t nTarService = 110;
		NetAdapter::SERVICE_NAVI oNavi(uSrcServer, nSrcService, gpoContext->GetWorldServerID(), nTarService, m_nSession);
		NetAdapter::SendInner(NSSysCmd::ssClientLastPacketTimeRet, poPacket, oNavi);
	}
	else if (m_nLastNotifyTime > 0)
	{
		m_nLastNotifyTime = 0;
	}
}