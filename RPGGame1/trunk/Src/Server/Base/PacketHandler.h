#ifndef __PACKETHANDLER_H__
#define __PACKETHANDLER_H__

#include "Include/Network/Network.hpp"
#include "Common/DataStruct/Array.h"


typedef void(*ExterPacketProc)(int nSrcSessionID, Packet* poPacket, EXTER_HEADER& oHeader);
typedef void(*InnerPacketProc)(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pTarSessionArray);

struct PACKET_PROC
{
	uint16_t uCmd;
	void* pProc;
	PACKET_PROC()
	{
		uCmd = 0;
		pProc = NULL;
	}
};

class PacketHandler
{
public:
	typedef std::unordered_map<int, PACKET_PROC*> PacketProcMap;
	typedef PacketProcMap::iterator PacketProcIter;

public:
	PacketHandler();
	virtual ~PacketHandler();

	void RegsterInnerPacketProc(uint16_t uCmd, void* pPacketProc);
	virtual void OnRecvInnerPacket(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);

	void RegsterExterPacketProc(uint16_t uCmd, void* pPacketProc);
	virtual void OnRecvExterPacket(int nSrcSessionID, Packet *poPacket, EXTER_HEADER& oHeader);

protected:
	void CacheSessionArray(int* pnSessionOffset, int nCount);

protected:
	PacketProcMap* m_poInnerPacketProcMap;
	PacketProcMap* m_poExterPacketProcMap;

	Array<int> m_oSessionCache;
	DISALLOW_COPY_AND_ASSIGN(PacketHandler);
};

#endif