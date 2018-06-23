#ifndef __LOG_UDPNET_H__
#define __LOG_DUPNET_H__

#include "Include/Network/Network.hpp"
#include "Common/DataStruct/Thread.h"

struct CLIENT
{
	uint32_t uIP;
	uint16_t uPort;
	CLIENT(uint32_t _uIP=0, uint16_t _uPort=0):uIP(_uIP),uPort(_uPort) {}
};

class UDPNet
{
public:
	UDPNet(int nRoomID, uint16_t uServerPort);
	~UDPNet();

	bool Init();

private:
	void Update(int64_t nNowMSTime);

private:
	int m_nRoomID;
	uint16_t m_uServerPort;
	HSOCKET m_nServerSocket;
	CLIENT m_tPairClient[2];

	DISALLOW_COPY_AND_ASSIGN(UDPNet);
};

#endif