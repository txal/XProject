#include "Server/GlobalServer/UDPNet.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"

UDPNet::UDPNet(int nRoomID, uint16_t uServerPort)
{
	m_nRoomID = nRoomID;
	m_uServerPort = 0;
	m_nServerSocket = -1;
}

UDPNet::~UDPNet()
{
	NetAPI::CloseSocket(m_uServerPort);
	m_uServerPort = -1;
}

bool UDPNet::Init()
{
	 m_nServerSocket= NetAPI::CreateUdpSocket();
	 NetAPI::Bind(m_nServerSocket, INADDR_ANY, m_uServerPort);
	 XLog(LEVEL_INFO, "UDP room:%d bind at port:%d\n", m_nRoomID, m_uServerPort);
}

void UDPNet::Update(int64_t nNowMSTime)
{
}
