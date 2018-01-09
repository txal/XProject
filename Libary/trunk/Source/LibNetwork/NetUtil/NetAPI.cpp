#include "Include/Network/NetAPI.h"
#include "Include/Logger/Logger.h"

void NetAPI::StartupNetwork()
{
#ifdef __linux
	signal(SIGPIPE, SIG_IGN);
#else
	WSADATA wsa = { 0 };
	WSAStartup(MAKEWORD(2, 2), &wsa);
#endif
}

HSOCKET NetAPI::CreateTcpSocket()
{
	HSOCKET hSock = socket(AF_INET, SOCK_STREAM, 0);
	if (hSock == INVALID_SOCKET)
	{
#ifdef __linux
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", strerror(errno));
#else
		XLog(LEVEL_ERROR, LOG_ADDR"%s", Platform::LastErrorStr(GetLastError()));
#endif
	}
	return hSock;
}

void NetAPI::CloseSocket(HSOCKET nSock)
{
#ifdef __linux
	close(nSock);
#else
	closesocket(nSock);
#endif

}

bool NetAPI::NonBlock(HSOCKET hSock)
{
#ifdef __linux
	int nFlags = fcntl(hSock, F_GETFL);
	if (nFlags == -1) 
	{
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", strerror(errno));
		return false;
	}
	nFlags |= O_NONBLOCK;
	int nRet = fcntl(hSock, F_SETFL, nFlags);
	if (nRet == -1)
	{
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", strerror(errno));
		return false;
	}
#else
	u_long nNonBlock = 1;
	int nRet = ioctlsocket(hSock, FIONBIO, &nNonBlock);
	if (nRet == SOCKET_ERROR)
	{
		XLog(LEVEL_ERROR, LOG_ADDR"%s", Platform::LastErrorStr(GetLastError()));
		return false;
	}
#endif
	return true;
}

bool NetAPI::ReuseAddr(HSOCKET hSock)
{
	int nReuse = 1;
	int nRet = setsockopt(hSock, SOL_SOCKET, SO_REUSEADDR, (char*)&nReuse, sizeof(nReuse));
	if (nRet == SOCKET_ERROR)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", psErr);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
#endif
		return false;
	}
	return true;
}

bool NetAPI::NoDelay(HSOCKET hSock)
{
	int nNoDelay = 1;
	int nRet = setsockopt(hSock, IPPROTO_TCP, TCP_NODELAY, (char*)&nNoDelay, sizeof(nNoDelay));
	if (nRet == SOCKET_ERROR)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", psErr);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
#endif
		return false;
	}
	return true;
}

bool NetAPI::Linger(HSOCKET hSock)
{
	struct _LINGER
	{
		int l_onoff;
		int l_linger;
	} LINGER = { 1, 0 };
	int nRet = setsockopt(hSock, SOL_SOCKET, SO_LINGER, (char*)&LINGER, sizeof(LINGER));
	if (nRet == SOCKET_ERROR)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", psErr);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
#endif
		return false;
	}
	return true;
}

bool NetAPI::Bind(HSOCKET hSock, uint32_t uIP, uint16_t nPort)
{
	struct sockaddr_in Addr;
	Addr.sin_family = AF_INET;
	Addr.sin_addr.s_addr = uIP;
	Addr.sin_port = htons(nPort);
	int nRet = ::bind(hSock, (struct sockaddr*)&Addr, sizeof(Addr));
	if (nRet == SOCKET_ERROR)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
		XLog(LEVEL_ERROR, LOG_ADDR"Bind port %d error (%s)\n", nPort, psErr);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"Bind port %d error (%s)", nPort, psErr);
#endif
		return false;
	}
	return true;
}

bool NetAPI::Listen(HSOCKET hSock)
{
	int nRet = ::listen(hSock, SOMAXCONN);//SOMAXCONN=128Local
	if (nRet == SOCKET_ERROR)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", psErr);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
#endif
		return false;
	}
	return true;
}

HSOCKET NetAPI::Accept(HSOCKET nServerSock, uint32_t* pClientIP, uint16_t* pClientPort)
{
	struct sockaddr_in Addr;
	memset(&Addr, 0, sizeof(Addr));
#ifdef __linux
	socklen_t nAddrLen = sizeof(Addr);
#else
	int nAddrLen = sizeof(Addr);
#endif
	HSOCKET nClientSock = ::accept(nServerSock, (struct sockaddr*)&Addr, &nAddrLen);
	if (nClientSock == SOCKET_ERROR)
	{
		return nClientSock;
	}
	if (pClientIP != NULL)
	{
		*pClientIP = Addr.sin_addr.s_addr;
		//*pClientIP = ntohl(Addr.sin_addr.s_addr);
	}
	if (pClientPort != NULL)
	{
		*pClientPort = ntohs(Addr.sin_port);
	}
	return nClientSock;
}

bool NetAPI::Connect(HSOCKET nClientSock, const char* pszServerIP, uint16_t uServerPort)
{
	struct sockaddr_in oAddr;
	oAddr.sin_family = AF_INET;
	oAddr.sin_addr.s_addr = P2N(pszServerIP);
	oAddr.sin_port = htons(uServerPort);
	int nRet = connect(nClientSock, (struct sockaddr*)&oAddr, sizeof(oAddr));
	if (nRet == SOCKET_ERROR)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
		XLog(LEVEL_ERROR, LOG_ADDR"Connect %s %d fail: %s\n", pszServerIP, uServerPort, psErr);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"Connect %s %d fail: %s", pszServerIP, uServerPort, psErr);
#endif
		return false;
	}
	return true;
}

int NetAPI::SendBufSize(HSOCKET hSock)
{
	int nOptVal = 0;
#ifdef __linux
	socklen_t nOptLen = sizeof(nOptVal); 
#else
	int nOptLen = sizeof(nOptVal);
#endif
	int nRet = getsockopt(hSock, SOL_SOCKET, SO_SNDBUF, (char*)&nOptVal, &nOptLen);
	if (nRet == SOCKET_ERROR)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", psErr);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
#endif
		return 0;
	}
	return nOptVal;
}

int NetAPI::ReceiveBufSize(HSOCKET hSock)
{
	int nOptVal = 0;
#ifdef __linux
	socklen_t nOptLen = sizeof(nOptVal); 
#else
	int nOptLen = sizeof(nOptVal);
#endif
	int nRet = getsockopt(hSock, SOL_SOCKET, SO_RCVBUF, (char*)&nOptVal, &nOptLen);
	if (nRet == SOCKET_ERROR)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", psErr);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
		XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
#endif
		return 0;
	}
	return nOptVal;
}

bool NetAPI::KeepAlive(HSOCKET hSock)
{
	/* 最好是用心跳，不用心跳，就只有用这个方法了，
	 * 没有其他的办法了，其实这个方法也是心跳，
	 * 要想不发送任何数据来检测对方online与否是不可能的！
	 * 该方法缺点是因为服务端主动发包，会占用额外的带宽和流量。
	 * */

	/* 单位：0.5秒 */
	/* 打开TCP KEEPALIVE开关*/
	int nKeepAlive = 1;
	/* 对一个连接进行有效性探测之前运行的最大非活跃时间间隔
	 * (没有任何数据交互)，默认值为14400(即2个小时)
	 * */
	int nKeepIdle = 3 * 60 * 2;
	/* 两个探测的时间间隔 */
	int nKeepIntvl = 3 * 2;
	/* 关闭一个非活跃连接之前进行探测的最大次数，默认为8次 */
	int nKeepCnt = 1;
	do
	{
#ifdef __linux
		if (setsockopt(hSock, SOL_SOCKET, SO_KEEPALIVE, (char*)&nKeepAlive, sizeof(nKeepAlive)) == -1)
			break;
		if (setsockopt(hSock, SOL_TCP, TCP_KEEPIDLE, (char*)&nKeepIdle, sizeof(nKeepIdle)) == -1)
			break;
		if (setsockopt(hSock, SOL_TCP, TCP_KEEPINTVL, (char*)&nKeepIntvl, sizeof(nKeepIntvl)) == -1)
			break;
		if (setsockopt(hSock, SOL_TCP, TCP_KEEPCNT, (char*)&nKeepCnt, sizeof(nKeepCnt)) == -1)
			break;
#endif
		return true;
	} while (0);
#ifdef __linux
	const char* psErr = strerror(errno);
	XLog(LEVEL_ERROR, LOG_ADDR"%s\n", psErr);
#else
	const char* psErr = Platform::LastErrorStr(GetLastError());
	XLog(LEVEL_ERROR, LOG_ADDR"%s", psErr);
#endif
	return false;
}

//uIP为网络字节顺序
const char* NetAPI::N2P(uint32_t uIP, char* pBuf, int nBufLen)
{
	const char* pStrIP = inet_ntop(AF_INET, &uIP, pBuf, nBufLen);
	if (pStrIP == NULL)
	{
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", strerror(errno));
		return 0;
	}
	return pStrIP;
}

uint32_t NetAPI::P2N(const char* pszIP)
{
	struct in_addr oAddr;
	int nRet = inet_pton(AF_INET, pszIP, &oAddr);
	if (nRet <= 0)
	{
#ifdef __linux
		const char* pszErr = strerror(errno);
	    XLog(LEVEL_ERROR, LOG_ADDR"%s\n", pszErr);
#else
		const char* pszErr = Platform::LastErrorStr(GetLastError());
	    XLog(LEVEL_ERROR, LOG_ADDR"%s", pszErr);
#endif
		return 0;
	}
	//Addr.s_addr为网络字节顺序
	return oAddr.s_addr;
}

bool NetAPI::GetPeerName(HSOCKET hSock, uint32_t* puPeerIP, uint16_t* puPeerPort)
{
	struct sockaddr_in Addr;
#ifdef __linux
	socklen_t nAddrLen = sizeof(Addr);
#else
	int nAddrLen = sizeof(Addr);
#endif
	int nRet = getpeername(hSock, (sockaddr*)&Addr, &nAddrLen);
	if (nRet == -1)
	{
#ifdef __linux
		const char* psErr = strerror(errno);
#else
		const char* psErr = Platform::LastErrorStr(GetLastError());
#endif
		XLog(LEVEL_ERROR, LOG_ADDR"%s\n", psErr);
		return false;
	}
	if (puPeerIP != NULL)
	{
		*puPeerIP = Addr.sin_addr.s_addr;	//网络字节顺序
	}
	if (puPeerPort != NULL)
	{
		*puPeerPort = ntohs(Addr.sin_port);	//转成主机字节顺序
	}
	return true;
}

unsigned long long NetAPI::N2Hll(unsigned long long val)
{
#ifdef __linux
	if (__BYTE_ORDER == __LITTLE_ENDIAN)
	{
		return (((unsigned long long)htonl((int)((val << 32) >> 32))) << 32) | (unsigned int)htonl((int)(val >> 32));
	}
	else if (__BYTE_ORDER == __BIG_ENDIAN)
	{
		return val;
	}
#else
	return ntohll(val);
#endif
}

unsigned long long NetAPI::H2Nll(unsigned long long val)
{
#ifdef __linux
	if (__BYTE_ORDER == __LITTLE_ENDIAN)
	{
		return (((unsigned long long)htonl((int)((val << 32) >> 32))) << 32) | (unsigned int)htonl((int)(val >> 32));
	}
	else if (__BYTE_ORDER == __BIG_ENDIAN)
	{
		return val;
	}
#else
	return htonll(val);
#endif
}