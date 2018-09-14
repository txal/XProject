#ifndef __GATEWAYPACKETHANDLER_H__
#define __GATEWAYPACKETHANDLER_H__

#include "Server/Base/PacketHandler.h"

class GatewayPacketHandler : public PacketHandler
{
public:
	GatewayPacketHandler();
	typedef PacketHandler super;

	virtual void OnRecvExterPacket(int nSrcSessionID, Packet *poPacket, EXTER_HEADER& oHeader);
	virtual void OnRecvInnerPacket(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	
private:
	void Forward(int nSrcSessionID, Packet* poPacket, INNER_HEADER& oHeader, int* pSessionArray);
	DISALLOW_COPY_AND_ASSIGN(GatewayPacketHandler);
};

#endif