#include "Include/Logger/Logger.h"
#include "Include/Network/Network.hpp"
#include "Common/HttpRequest/HttpRequest.h"
#include "Common/DataStruct/XTime.h"
#include <iostream>
using namespace std;

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
	int8_t nServiceID = (int8_t)atoi(pArgv[1]);

	Logger::Instance()->Init();
	NetAPI::StartupNetwork();

	HSOCKET nUDPSocket = NetAPI::CreateUdpSocket();
	NetAPI::NonBlock(nUDPSocket);
	const char* pStrIP = "192.168.32.231";
	uint32_t uIP = NetAPI::P2N(pStrIP);
	uint16_t uPort = 10086;

	char buff[32 * 1024] = "hello udp";
	Packet* pPacket = Packet::Create();
	pPacket->WriteBuf(buff, sizeof(buff));


	//注册
	EXTER_HEADER oHeader(1, nServiceID, 0, 1);
	pPacket->AppendExterHeader(oHeader);
	bool bRes = NetAPI::SendTo(nUDPSocket, pPacket, uIP, 10086);
	XLog(LEVEL_INFO, "SendTo ret:%d ip:%s port:%d index:%u\n", bRes, pStrIP, 10086, oHeader.uPacketIdx);
	
	pPacket->RemoveExterHeader();
	oHeader.uCmd = 0;
	oHeader.nSrcService = nServiceID;
	oHeader.nTarService = nServiceID==1 ? 2 : 1;
	oHeader.uPacketIdx = 2;
	pPacket->AppendExterHeader(oHeader);

	Packet* pRecvPacket = Packet::Create();
	bRes = false;

	while (true)
	{
		bRes = NetAPI::SendTo(nUDPSocket, pPacket, uIP, 10086);
		if (bRes)
		{
			XLog(LEVEL_INFO, "send from:%d to:%d ip:%s port:%d index:%u\n", oHeader.nSrcService, oHeader.nTarService, pStrIP, 10086, oHeader.uPacketIdx);
			pPacket->RemoveExterHeader();
			oHeader.uPacketIdx++;
			pPacket->AppendExterHeader(oHeader);
		}

		EXTER_HEADER oRecvHeader;
		bRes = NetAPI::RecvFrom(nUDPSocket, pRecvPacket, uIP, uPort);
		if (bRes)
		{
			pRecvPacket->GetExterHeader(oRecvHeader, false);
			XLog(LEVEL_INFO, "recv from:%d to:%d port:%d\n", oRecvHeader.nSrcService, oRecvHeader.nTarService, uPort);
		}

		XTime::MSSleep(1000);
	}

	getchar();
	return 0;
}
