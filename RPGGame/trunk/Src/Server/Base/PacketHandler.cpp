#include "Server/Base/PacketHandler.h"
#include "Include/Logger/Logger.hpp"
#include "Server/Base/CmdDef.h"

PacketHandler::PacketHandler()
{
	m_poInnerPacketProcMap = XNEW(PacketProcMap);
	m_poExterPacketProcMap = XNEW(PacketProcMap);
}

PacketHandler::~PacketHandler()
{
	if (m_poInnerPacketProcMap != NULL)
	{
		PacketProcIter iter = m_poInnerPacketProcMap->begin();
		PacketProcIter iter_end = m_poInnerPacketProcMap->end();
		for (; iter != iter_end; iter++)
		{
			SAFE_DELETE(iter->second);
		}
	}

	if (m_poExterPacketProcMap != NULL)
	{
		PacketProcIter iter = m_poExterPacketProcMap->begin();
		PacketProcIter iter_end = m_poExterPacketProcMap->end();
		for (; iter != iter_end; iter++)
		{
			SAFE_DELETE(iter->second);
		}
	}

	SAFE_DELETE(m_poInnerPacketProcMap);
	SAFE_DELETE(m_poExterPacketProcMap); 
}

void PacketHandler::RegsterInnerPacketProc(uint16_t uCmd, void* pPacketProc)
{
	PACKET_PROC* poProc = XNEW(PACKET_PROC);
	poProc->uCmd = uCmd;
	poProc->pProc = pPacketProc;
	m_poInnerPacketProcMap->insert(std::make_pair(uCmd, poProc));
}

void PacketHandler::OnRecvInnerPacket(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray)
{
	PacketProcIter iter = m_poInnerPacketProcMap->find(oHeader.uCmd);
	if (iter != m_poInnerPacketProcMap->end())
	{
		(*(InnerPacketProc)(iter->second->pProc))(nSrcSessionID, poPacket, oHeader, pSessionArray);
	}
	else if (oHeader.uCmd != NSMsgType::eLuaRpcMsg)
	{
			PacketProcIter iter = m_poInnerPacketProcMap->find(NSMsgType::eLuaCmdMsg);
			if (iter != m_poInnerPacketProcMap->end())
			{
				(*(InnerPacketProc)iter->second->pProc)(nSrcSessionID, poPacket, oHeader, pSessionArray);
			}
			else
			{
				XLog(LEVEL_ERROR, "CMD:%d proc not found\n", oHeader.uCmd);
			}
	}
	else
	{
		XLog(LEVEL_ERROR, "CMD:%d proc not found\n", oHeader.uCmd);
	}
	poPacket->Release(__FILE__, __LINE__);
}

void PacketHandler::RegsterExterPacketProc(uint16_t uCmd, void* pPacketProc)
{
	PACKET_PROC* poProc = XNEW(PACKET_PROC);
	poProc->uCmd = uCmd;
	poProc->pProc = (void*)pPacketProc;
	m_poExterPacketProcMap->insert(std::make_pair(uCmd, poProc));
}

void PacketHandler::OnRecvExterPacket(int nSrcSessionID, Packet *poPacket, EXTER_HEADER& oHeader)
{
	PacketProcIter iter = m_poExterPacketProcMap->find(oHeader.uCmd);
	if (iter != m_poExterPacketProcMap->end())
	{
		(*(ExterPacketProc)(iter->second->pProc))(nSrcSessionID, poPacket, oHeader);
	}
	else if (oHeader.uCmd != NSMsgType::eLuaRpcMsg)
	{
		PacketProcIter iter = m_poExterPacketProcMap->find(NSMsgType::eLuaCmdMsg);
		if (iter != m_poExterPacketProcMap->end())			
		{
			(*(ExterPacketProc)(iter->second->pProc))(nSrcSessionID, poPacket, oHeader);
		}
		else
		{
			XLog(LEVEL_ERROR, "CMD:%d proc not found\n", oHeader.uCmd);
		}
	}
	else
	{
			XLog(LEVEL_ERROR, "CMD:%d proc not found\n", oHeader.uCmd);
	}
	poPacket->Release(__FILE__, __LINE__);
}

void PacketHandler::CacheSessionArray(int* pnSessionOffset, int nCount)
{
	m_oSessionCache.Clear();
	if (pnSessionOffset == NULL || nCount <= 0)
	{
		return;
	}
	m_oSessionCache.Reserve(nCount);
	memcpy((void*)m_oSessionCache.Ptr(), (void*)pnSessionOffset, nCount * sizeof(int));
	m_oSessionCache.SetSize(nCount);
}
