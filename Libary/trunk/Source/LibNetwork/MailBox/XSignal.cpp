#include "Include/Network/XSignal.h"
#include "Include/Network/NetAPI.h"
#include "Common/DataStruct/XTime.h"
#include "Include/Logger/Logger.h"

XSignal::XSignal() 
{
	int nRet = MakeFdPair(&m_hRSock, &m_hWSock);
	if (nRet == -1)
	{
		::abort();
	}
	nRet = NetAPI::NonBlock(m_hRSock);
	if (nRet == -1)
	{
		::abort();
	}
	nRet = NetAPI::NonBlock(m_hWSock);
	if (nRet == -1)
	{
		::abort();
	}
	//Pipe is more fast than socketpair(3 times), but windows not support non block
	//int bRet = pipe(m_fds);
	//if (bRet == -1)
	//{
	//	abort();
	//}
}

XSignal::~XSignal() 
{
	NetAPI::CloseSocket(m_hRSock);
	NetAPI::CloseSocket(m_hWSock);
}

HSOCKET XSignal::GetRSock()
{
	return m_hRSock;
}

bool XSignal::Wait(int nMs)
{
#ifdef __linux
	struct pollfd pfd;
	pfd.fd = m_hRSock;
	pfd.events = POLLIN;
	int nRet = ::poll(&pfd, 1, nMs);
	if (nRet <= 0)
	{
		if (nRet < 0)
		{
			XLog(LEVEL_ERROR, LOG_ADDR"%s", strerror(errno));
		}
		return false;
	}
	if (!(pfd.revents & POLLIN))
	{
		return false;
	}
	uint64_t nEvents;
	int nBytes = ::read(pfd.fd, &nEvents, sizeof(nEvents));
	if (nBytes != (int)sizeof(nEvents))
	{
		XLog(LEVEL_ERROR, LOG_ADDR"%s", strerror(errno));
		return false;
	}
	return true;
#else
	fd_set oSet;
    FD_ZERO(&oSet);
    FD_SET(m_hRSock, &oSet);
    struct timeval oTimeout = {0, 0};
    if (nMs > 0) 
	{
		oTimeout.tv_sec = nMs / 1000;
		oTimeout.tv_usec = (nMs % 1000) * 1000;
    }
	int nRet = ::select(0, &oSet, NULL, NULL, nMs >= 0 ? &oTimeout : NULL);
	if (nRet == SOCKET_ERROR || nRet == 0)
	{
		if (nRet == SOCKET_ERROR)
		{
			const char* psErr = Platform::LastErrorStr(GetLastError());
			XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
		}
		return false;
	}
    uint8_t nDummy;
    int nBytes = ::recv(m_hRSock, (char*)&nDummy, sizeof(nDummy), 0);
	if (nBytes != sizeof(nDummy))
	{
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
		return false;
	}
	return true;
#endif
}

bool XSignal::Notify()
{
#ifdef __linux
	uint64_t nEvents = 1;
	int nBytes = ::write(m_hWSock, &nEvents, sizeof(nEvents));
	if (nBytes != sizeof(nEvents))
	{
		XLog(LEVEL_ERROR, LOG_ADDR"%s", strerror(errno));
		return false;
	}
	return true;
#else
	uint8_t nDummy = 0;
    int nBytes = ::send(m_hWSock, (char*)&nDummy, sizeof(nDummy), 0);
	if (nBytes != sizeof(nDummy))
	{
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
		return false;
	}
	return true;
#endif
}

bool XSignal::MakeFdPair(HSOCKET* pRSock, HSOCKET* pWSock)
{
#ifdef __linux
	int nFD = eventfd(0, 0);
	if (nFD == SOCKET_ERROR)
	{
		return false;
	}
	*pRSock = *pWSock = nFD;
	return true;
#else
	*pWSock = INVALID_SOCKET;
    *pRSock = INVALID_SOCKET;
	do 
	{
		HSOCKET hListenSock;
		hListenSock = NetAPI::CreateTcpSocket();
		if (hListenSock == INVALID_SOCKET)
		{
			break;
		}
		const uint16_t uXSignalPort = (10000 + XTime::MSTime() % 20000 + (int)getpid()) % 0xFFFF;
		uint32_t uIP = NetAPI::P2N("127.0.0.1");
		bool bRet = NetAPI::Bind(hListenSock, uIP, uXSignalPort);
		if (!bRet)
		{
			break;
		}
		bRet = NetAPI::Listen(hListenSock);
		if (!bRet)
		{
			break;
		}

		//  Create the writer socket.
		*pWSock = NetAPI::CreateTcpSocket();
		if (*pWSock == INVALID_SOCKET)
		{
			break;
		}
		bRet = NetAPI::NoDelay(*pWSock);
		if (!bRet)
		{
			break;
		}
		bRet = NetAPI::Connect(*pWSock, "127.0.0.1", uXSignalPort);
		if (!bRet)
		{
			break;
		}
        //The reader socket
		*pRSock = NetAPI::Accept(hListenSock, NULL, NULL);
		if (*pRSock == SOCKET_ERROR)
		{
			NetAPI::CloseSocket(hListenSock);
			XLog(LEVEL_ERROR, LOG_ADDR"%s", Platform::LastErrorStr(GetLastError()));
			break;
		}
		NetAPI::CloseSocket(hListenSock);
		return true;
	} while (0);
	return false;
#endif
}
