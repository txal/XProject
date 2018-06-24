#ifndef __LOG_UDPNET_H__
#define __LOG_DUPNET_H__

#include "Include/Network/Network.hpp"
#include "Common/DataStruct/Thread.h"

struct CLIENT
{
	uint32_t uIP;
	uint16_t uPort;
	uint32_t uPKIndex;
	char sStrIP[128];
	CLIENT(uint32_t _uIP = 0, uint16_t _uPort = 0) :uIP(_uIP), uPort(_uPort), uPKIndex(0) { sStrIP[0] = 0; }
	void Reset() { uIP = 0, uPort = 0; uPKIndex = 0; sStrIP[0] = 0; }
};

class UDPNet
{
public:
	typedef std::list<Packet*> PKList;
	typedef PKList::iterator PKIter;

public:
	UDPNet();
	~UDPNet();

	bool Init(int nRoomID, uint16_t uServerPort);
	void Update(int64_t nNowMSTime);

private:
	Packet* RecvData(uint32_t& uIP, uint16_t& uPort);
	void SendData(Packet* pPacket);
	Packet* ApplyPacket();
	void ReturnPacket(Packet* pPacket);
	void InsertPacket(Packet* pPacket);

private:
	int m_nRoomID;
	uint16_t m_uServerPort;
	HSOCKET m_nServerSocket;
	CLIENT m_tPairClient[2];

	PKList m_oPacketList;

	DISALLOW_COPY_AND_ASSIGN(UDPNet);
};

#endif