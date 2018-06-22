#include "Include/Logger/Logger.h"
#include "Include/Network/Network.hpp"
#include "Common/HttpRequest/HttpRequest.h"
#include <iostream>
using namespace std;

int main()
{
	Logger::Instance()->Init();
	NetAPI::StartupNetwork();

	HSOCKET nUDPSocket = NetAPI::CreateUdpSocket();
	const char* pStrIP = "127.0.0.1";
	uint32_t uIP = NetAPI::P2N(pStrIP);

	Packet* pPacket = Packet::Create();
	pPacket->WriteBuf("hello udp", 10);
	int nRet = NetAPI::SendTo(nUDPSocket, pPacket, uIP, 10086);
	XLog(LEVEL_INFO, LOG_ADDR"SendTo ret:%d ip:%s port:%d\n", nRet, pStrIP, 10086);

	getchar();
	return 0;
}
