#include "Include/Logger/Logger.h"
#include "Include/Network/Network.hpp"
#include "Common/HttpRequest/HttpRequest.h"
#include "Common/DataStruct/XTime.h"
#include <iostream>
using namespace std;

int main()
{
	Logger::Instance()->Init();
	NetAPI::StartupNetwork();

	HSOCKET nUDPSocket = NetAPI::CreateUdpSocket();
	const char* pStrIP = "192.168.1.131";
	uint32_t uIP = NetAPI::P2N(pStrIP);

	char buff[32 * 1024] = "hello udp";
	Packet* pPacket = Packet::Create();
	pPacket->WriteBuf(buff, sizeof(buff));

	EXTER_HEADER oHeader(1, 0, 0, 1);
	pPacket->AppendExterHeader(oHeader);

	while (true)
	{
		bool nRes = NetAPI::SendTo(nUDPSocket, pPacket, uIP, 10086);
		XLog(LEVEL_INFO, "SendTo ret:%d ip:%s port:%d index:%u\n", nRes, pStrIP, 10086, oHeader.uPacketIdx);
		XTime::MSSleep(33);

		pPacket->RemoveExterHeader();
		oHeader.uPacketIdx++;
		pPacket->AppendExterHeader(oHeader);
	}

	getchar();
	return 0;
}
