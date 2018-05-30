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

	m_nPacketTime = 0;
	m_nLogicService = 0;
	m_nLastNotifyTime = 0;
	m_nRoleID = 0;
}

Client::~Client()
{
}

void Client::Update(int64_t nNowMS)
{
	int nTimeNow = time(0);

	//每分钟通知一次
	if (nTimeNow - m_nLastNotifyTime < 60)
		return;
	m_nLastNotifyTime = nTimeNow;

	//发呆>=10分钟才发送
	if (nTimeNow - m_nPacketTime >= 600)
	{
		Packet* poPacket = Packet::Create(32);
		if (poPacket == NULL)
		{
			return;
		}
		PacketWriter oWriter(poPacket);
		oWriter << m_nRoleID << m_nPacketTime;
		uint16_t uSrcServer = g_poContext->GetServerID();
		int8_t nSrcService = g_poContext->GetService()->GetServiceID();
		int8_t nTarService = g_poContext->GetServerConfig().oWGlobalList[0].uID;
		NetAdapter::SERVICE_NAVI oNavi(uSrcServer, nSrcService, g_poContext->GetWorldServerID(), nTarService, m_nSession);
		NetAdapter::SendInner(NSSysCmd::ssClientLastPacketTimeRet, poPacket, oNavi);
	}
}