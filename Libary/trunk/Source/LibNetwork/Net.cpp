#include "LibNetwork/Net.h"
#include "Include/Network/NetAPI.h"
#include "Include/Network/NetEventDef.h"
#include "Include/Network/NetEventHandler.h"
#include "LibNetwork/Session.h"

Net::Net()
{
	m_sNetName[0] = 0;
	m_nServiceID = 0;

	m_bLinger = true;
	m_bNoSession = false;

	m_nMaxSessions = 0;
	m_nCurSessions = 0;
	m_poSessionArray = NULL;
	m_nRecvBufSize = 0;

	m_pNetAe = NULL;
	m_poNetEventHandler = NULL;

	m_uInPackets = 0;
	m_uOutPackets = 0;
}


Net::~Net()
{
	for (int i = 0; i < m_nMaxSessions; i++)
	{
		if (m_poSessionArray[i] != NULL)
		{
			CloseSession(m_poSessionArray[i]->nSessionID);
			SAFE_DELETE(m_poSessionArray[i]);
		}
	}
	SAFE_FREE(m_poSessionArray);
	SAFE_DELETE(m_pNetAe);
}
void Net::Release()
{
	m_pNetAe->Stop();
	m_pNetAe->Join();
	delete(this);
}

bool Net::Init(const char* psNetName, int nServiceID, int nMaxConns, int nRecvBufSize, bool bLinger /* = true */)
{
	assert(nMaxConns > 0);
	assert(psNetName != NULL);
	assert(nRecvBufSize > 0);
	assert(nServiceID >= 0 && nServiceID <= MAX_SERVICE_NUM);

	strcpy(m_sNetName, psNetName);
	m_oMailBox.SetName(psNetName);
	m_nServiceID = nServiceID;
	m_bLinger = bLinger;
	m_nMaxSessions = nMaxConns + 2; //+ctrl&listen
	m_nCurSessions = 0;
	m_nRecvBufSize = nRecvBufSize;

	// Init net AE
#ifdef __linux
	m_pNetAe = XNEW(Epoll)(EPOLL_LT, m_nMaxSessions);
#else
	m_pNetAe = XNEW(Iocp);
#endif
	if (!m_pNetAe->Create(Net::EventProc, this))
	{
		return false;
	}

	// Init session array
    int nSessionSize = m_nMaxSessions * sizeof(SESSION*);
	m_poSessionArray = (SESSION**)XALLOC(NULL, nSessionSize);
    memset(m_poSessionArray, 0, nSessionSize);

	// Create CTRL session
	if (CreateSession(m_oMailBox.GetSock(), 0, 0, SESSION_TYPE_CTRL) == NULL)
	{
		return false;
	}

	return m_pNetAe->Start();
}

SESSION* Net::GetSession(int nSessionID)
{
	SESSION *pSession = m_poSessionArray[nSessionID % m_nMaxSessions];
	if (pSession == NULL
		|| pSession->nSessionType == SESSION_TYPE_INVALID
		|| pSession->nSessionID != nSessionID)
	{
		pSession = NULL;
	}
	return pSession;
}

void Net::CloseSession(int nSessionID)
{
	SESSION* pSession = GetSession(nSessionID);
	if (pSession == NULL)
	{
		return;
	}
	HSOCKET hSock = pSession->nSock;
	int nSessionType = pSession->nSessionType;
	
	m_pNetAe->DeleteEvent(hSock, pSession);
	NetAPI::CloseSocket(hSock);
	m_nCurSessions--;
	pSession->Reset();

	if (nSessionType == SESSION_TYPE_DATA)
	{
		OnClose(nSessionID);
	}
	XLog(LEVEL_INFO, "%s: Close sock:%u session:%d type:%d cur sessions:%d\n", m_sNetName, hSock, nSessionID, nSessionType, m_nCurSessions);
}

void Net::CheckAndModifyEvent(SESSION* poSession, int nPreEvent)
{
	if (poSession == NULL || poSession->nSessionType == SESSION_TYPE_INVALID)
	{
		return;
	}
	//epoll:注册事件后不主动移除一直存在,除非主动移除; iopc:注册事件后只要触发了事件,该事件会被清除,需要重新注册才会再被监听;
#ifdef _WIN32
	if (nPreEvent == AE_READABLE)
	{
        GetAe()->ModifyEvent(poSession->nSock, poSession, AE_READABLE);
	}
	else if (nPreEvent == AE_WRITABLE || nPreEvent == AE_NONE)
	{
		if (poSession->oPacketList.Size() > 0)
		{
	        GetAe()->ModifyEvent(poSession->nSock, poSession, AE_WRITABLE);
		}
	}
#else
	// epoll 一直都监听 AE_READABLE
	if (nPreEvent == AE_WRITABLE)
	{
	    if (poSession->oPacketList.Size() <= 0)
	    {
	        GetAe()->ModifyEvent(poSession->nSock, poSession, AE_READABLE); //去掉监听AE_WRITABLE
	    }
	}
	else if (nPreEvent == AE_NONE)
	{
	    if (poSession->oPacketList.Size() == 1) //发送消息时,如果列表中只有一个消息时监听AE_WRITABLE,否则说明已经监听了AE_WRITABLE (列表里有多个消息)
	    {
	        GetAe()->ModifyEvent(poSession->nSock, poSession, AE_READABLE|AE_WRITABLE);
	    }
	}
#endif
}


void Net::AcceptTcpConnect(SESSION* pListener)
{
	if (pListener->nSessionType != SESSION_TYPE_LISTEN)
	{
		return;
	}
	char sIP[256];
	for (;;)
	{
		uint32_t uRemoteIP = 0;
		uint16_t uRemotePort = 0;
		HSOCKET hClientSock = NetAPI::Accept(pListener->nSock, &uRemoteIP, &uRemotePort);
		if (hClientSock == INVALID_SOCKET)
		{
			break;
		}
		NetAPI::N2P(uRemoteIP, sIP, sizeof(sIP));
		if (!CheckCPM(uRemoteIP, sIP)) //Security
		{
			NetAPI::CloseSocket(hClientSock);
			continue;
		}
		if (m_bNoSession)
		{
			XLog(LEVEL_INFO, "%s: Accept sock with not session sock:%u session:%d ip:%s sessions:%d\n", m_sNetName, hClientSock, 0, sIP, m_nCurSessions);
			OnAccept(hClientSock, 0, uRemoteIP, uRemotePort);
		}
		else
		{
			SESSION* pSession = CreateSession(hClientSock, uRemoteIP, uRemotePort, SESSION_TYPE_DATA);
			if (pSession == NULL)
			{
				NetAPI::CloseSocket(hClientSock);
				XLog(LEVEL_ERROR, "%s: Close sock:%u ip:%s for server full\n", m_sNetName, hClientSock, sIP);
				continue;
			}
			XLog(LEVEL_INFO, "%s: Accept sock:%u session:%d ip:%s cur sessions:%d\n", m_sNetName, hClientSock, pSession->nSessionID, sIP, m_nCurSessions);
			OnAccept(0, pSession->nSessionID, uRemoteIP, uRemotePort); //不暴露SOCKET
		}
	}
}

int Net::GenSessionIndex()
{
	static int nIndex = 0; // Multi thread call
	nIndex = nIndex % SESSION_MASK + 1;
	int nSessionID = m_nServiceID << 24 | nIndex;
	return nSessionID;
}

SESSION* Net::CreateSession(HSOCKET nSock, uint32_t uSessionIP, uint16_t nSessionPort, int nSessionType)
{
	if (m_nCurSessions >= m_nMaxSessions)
	{
		XLog(LEVEL_ERROR, "%s: Current sessions out of range:%d/%d\n", m_sNetName, m_nCurSessions, m_nMaxSessions);
		return NULL;
	}
	SESSION *pSession = NULL;
	int nSessionID = 0;
	for (int i = 0; i < m_nMaxSessions; i++)
	{
		nSessionID = GenSessionIndex();
		int nSlot = nSessionID % m_nMaxSessions;
		pSession = m_poSessionArray[nSlot];
		if (pSession != NULL && pSession->nSessionType != SESSION_TYPE_INVALID)
		{
			continue;
		}
		if (pSession == NULL) 
		{
			pSession = XNEW(SESSION)(m_nRecvBufSize);
			m_poSessionArray[nSlot] = pSession;
		}
		else
		{
			pSession->Reset();
		}
		break;
	}
	if (pSession == NULL)
	{
		return NULL;
	}

	do
	{
		if (!NetAPI::NonBlock(nSock))
		{
			pSession = NULL;
			break;
		}
		if (nSessionType == SESSION_TYPE_CTRL)
		{
			break;
		}
		if (!NetAPI::NoDelay(nSock) || (m_bLinger && !NetAPI::Linger(nSock)))
		{
			pSession = NULL;
			break;
		}
		if (nSessionType == SESSION_TYPE_LISTEN)
		{
			if (!NetAPI::ReuseAddr(nSock) || !NetAPI::Bind(nSock, uSessionIP, nSessionPort) || !NetAPI::Listen(nSock))
			{
				pSession = NULL;
				break;
			}
		}
	} while (0);

	if (pSession != NULL)
	{
		pSession->nSock = nSock;
		pSession->nSessionID = nSessionID;
		pSession->nSessionType = nSessionType;
		pSession->uSessionIP = uSessionIP;
		pSession->nSessionPort = nSessionPort;
		if (!m_pNetAe->CreateEvent(nSock, pSession, AE_READABLE))
		{
			pSession->Reset();
			return NULL;
		}
		m_nCurSessions++;
	}
	return pSession;
}

void Net::EventProc(void* pParam, const EVENT& Event)
{
	Net* pNet = (Net*)pParam;
	switch (Event.nEvent)
	{
		case AE_READABLE:
		{
			assert(Event.pUD != NULL);
			bool bSucc = true;
			SESSION* pSession = (SESSION*)Event.pUD;
			switch (pSession->nSessionType)
			{
				case SESSION_TYPE_CTRL:
				{
					pNet->CtrlProc(pSession);
					break;
				}
				case SESSION_TYPE_LISTEN: 
				{
					pNet->AcceptTcpConnect(pSession);
					break;
				}
				case SESSION_TYPE_DATA:
				{
					pNet->ReadData(pSession);
					break;
				}
				default:
				{
				    bSucc = false;
					//XLog(LEVEL_ERROR, "%s: Sock:%u session:%d read event session type error:%d\n", pNet->m_sNetName, pSession->nSock, pSession->nSessionID, pSession->nSessionType);
					break;
				}
			}
			if (bSucc)
			{
				pNet->CheckAndModifyEvent(pSession, AE_READABLE);
			}
			break;
		}
		case AE_WRITABLE:
		{
			assert(Event.pUD != NULL);
			SESSION* pSession = (SESSION*)Event.pUD;
			if (pSession->nSessionType == SESSION_TYPE_DATA)
			{
				pNet->WriteData(pSession);
				pNet->CheckAndModifyEvent(pSession, AE_WRITABLE);
			}
			else
			{
				//XLog(LEVEL_ERROR, "%s: Sock:%u session:%d write event session type error:%d\n", pNet->m_sNetName, pSession->nSock, pSession->nSessionID, pSession->nSessionType);
			}
			break;
		}
		case AE_CLOSE:
		{
			assert(Event.pUD != NULL);
			SESSION* pSession = (SESSION*)Event.pUD;
			pNet->CloseSession(pSession->nSessionID);
			break;
		}
		case AE_TIMER:
		{
			pNet->Timer((long)Event.pUD);
			break;
		}
		default:
		{
			XLog(LEVEL_ERROR, "%s: Event type error\n", pNet->m_sNetName);
			break;
		}
	}
}

void Net::CtrlProc(SESSION* pSession)
{
	if (pSession->nSessionType != SESSION_TYPE_CTRL)
	{
		return;
	}
	REQUEST_PACKET Request;
	while (m_oMailBox.Recv(&Request, 0))
	{
		// Todo: need to break after x msgs ?
		uint8_t uCtrlType = Request.uCtrlType;
		switch (uCtrlType)
		{
			case eCTRL_SEND:
			{
				DoSend(&Request.U.oSend);
				break;
			}
			case eCTRL_CLOSE:
			{
				DoClose(&Request.U.oClose);
				break;
			}
			case eCTRL_LISTEN:
			{
				DoListen(&Request.U.oListen);
				break;
			}
			case eCTRL_CONNECT:
			{
				DoConnect(&Request.U.oConnect);
				break;
			}
			case eCTRL_SENTCLOSE:
			{
				DoSentClose(&Request.U.oSentClose);
				break;
			}
			case eCTRL_ADD_DATASOCK:
			{
				DoAddDataSock(&Request.U.oDataSock);
				break;
			}
			case eCTRL_REMAINPACKETS:
			{
				DoRemainPackets(&Request.U.oRemainPackets);
				break;
			}
			default:
			{
				XLog(LEVEL_ERROR, "%s: Unknown ctrl type:%d\n", m_sNetName, uCtrlType);
				break;
			}
		}	
	}
}

void Net::DoRemainPackets(REQUEST_REMAINPACKETS* pRequest)
{
	int nPackets = 0;
	for (int i = 0; i < m_nMaxSessions; i++)
	{
		SESSION *pSession = m_poSessionArray[i];
		if (pSession != NULL && pSession->nSessionType == SESSION_TYPE_DATA)
		{
			nPackets += pSession->oPacketList.Size();
		}
	}
	nPackets += m_oMailBox.Size();
}

void Net::DoListen(REQUEST_LISTEN* pRequest)
{
	uint16_t nPort = pRequest->uPort;
	const char* psIP = pRequest->sIP;
	m_bNoSession = pRequest->bNotCreateSession;

	HSOCKET nSock = NetAPI::CreateTcpSocket();
    if (nSock == INVALID_SOCKET)
    {
        return;
    }
	uint32_t uIP = psIP[0] == '\0' ? INADDR_ANY : NetAPI::P2N(psIP);
	SESSION* pSession = CreateSession(nSock, uIP, nPort, SESSION_TYPE_LISTEN);
	if (pSession == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Listen port:%d fail\n", m_sNetName, nPort);
		NetAPI::CloseSocket(nSock);
		return;
	}
	XLog(LEVEL_INFO, "%s: Listen at port:%d\n", m_sNetName, nPort);
	OnListen(nPort, pSession->nSessionID);
}

void Net::DoConnect(REQUEST_CONNECT* pRequest)
{
	uint16_t uRemotePort = pRequest->uRemotePort;
	const char* psRemoteIP = pRequest->sRemoteIP;
	HSOCKET hSock = NetAPI::CreateTcpSocket();
	if (hSock == INVALID_SOCKET)
	{
		return;
	}
	if (!NetAPI::Connect(hSock, psRemoteIP, uRemotePort))
	{
		XLog(LEVEL_INFO, "%s: Connect ip:%s port:%d fail\n", m_sNetName, psRemoteIP, uRemotePort);
		return;
	}
	SESSION* pSession = CreateSession(hSock, 0, 0, SESSION_TYPE_DATA);
	if (pSession == NULL)
	{
		NetAPI::CloseSocket(hSock);
		XLog(LEVEL_ERROR, "%s: Closs socket:%u for create session fail!\n", m_sNetName, hSock);
		return;
	}
	XLog(LEVEL_INFO, "%s: Connect ip:%s port:%d success\n", m_sNetName, psRemoteIP, uRemotePort);
	OnConnect(pSession->nSessionID, NetAPI::P2N(psRemoteIP), uRemotePort);
}

void Net::DoClose(REQUEST_CLOSE* pRequest)
{
	int nSessionID = pRequest->nSessionID;
	CloseSession(nSessionID);
}

// Add data socket
void Net::DoAddDataSock(REQUEST_ADD_DATASOCK* pRequest)
{
	SESSION* pSession = CreateSession(pRequest->hSock, pRequest->uRemoteIP, pRequest->uRemotePort, SESSION_TYPE_DATA);
	if (pSession == NULL)
	{
		NetAPI::CloseSocket(pRequest->hSock);
		XLog(LEVEL_ERROR, "%s: Closs socket:%u for create session fail!\n", m_sNetName, pRequest->hSock);
		return;
	}
	XLog(LEVEL_INFO, "%s: Add data socket:%u successful\n", m_sNetName, pRequest->hSock);
	OnAddDataSock(pSession->nSock, pSession->nSessionID);
}

void Net::DoSend(REQUEST_SEND* pRequest)
{
	int nSessionID = pRequest->nSessionID;
	Packet* poPacket = (Packet*)pRequest->pData;
	SESSION* pSession = GetSession(nSessionID);
	if (pSession == NULL)
	{
		poPacket->Release();
		return;
	}
	pSession->oPacketList.PushBack(poPacket);
	pSession->uBlockDataSize += poPacket->GetDataSize();
	//XLog(LEVEL_INFO, "%s: dosend session:%d packs:%d blocks:%d packsize:%d\n", GetName(), nSessionID, pSession->oPacketList.Size(), pSession->nBlockDataSize, poPacket->GetDataSize());
	if (!CheckBlockDataSize(pSession))
	{
		CloseSession(nSessionID);
		return;
	}
	CheckAndModifyEvent(pSession, AE_NONE);
}

void Net::DoSentClose(REQUEST_SENTCLOSE* pRequest)
{
	int nSessionID = pRequest->nSessionID;
	SESSION* pSession = GetSession(nSessionID);
	if (pSession == NULL)
	{
		return;
	}
	pSession->bSentClose = true;
}

// Interface
bool Net::Listen(const char* psIP, uint16_t uListenPort, bool bNotCreateSession)
{
	psIP = psIP == NULL ? "" : psIP;
	REQUEST_PACKET oRequest;
	oRequest.uCtrlType = eCTRL_LISTEN;
	oRequest.U.oListen.uPort = uListenPort;
	oRequest.U.oListen.bNotCreateSession = bNotCreateSession;
	strcpy(oRequest.U.oListen.sIP, psIP);
	bool bRet = m_oMailBox.Send(oRequest);
    return bRet;
}

bool Net::Connect(const char* psRemoteIP, uint16_t uRemotePort)
{
	assert(psRemoteIP != NULL);
	REQUEST_PACKET oRequest;
	oRequest.uCtrlType = eCTRL_CONNECT;
	oRequest.U.oConnect.uRemotePort = uRemotePort;
	strcpy(oRequest.U.oConnect.sRemoteIP, psRemoteIP);
	bool bRet = m_oMailBox.Send(oRequest);
    return bRet;
}

bool Net::Close(int nSessionID)
{
	REQUEST_PACKET oRequest;
	oRequest.uCtrlType = eCTRL_CLOSE;
	oRequest.U.oClose.nSessionID = nSessionID;
	bool bRet = m_oMailBox.Send(oRequest);
    return bRet;
}

bool Net::SetSentClose(int nSessionID)
{
	REQUEST_PACKET oRequest;
	oRequest.uCtrlType = eCTRL_SENTCLOSE;
	oRequest.U.oSentClose.nSessionID = nSessionID;
	bool bRet = m_oMailBox.Send(oRequest);
    return bRet;
}

bool Net::AddDataSock(HSOCKET hSock, uint32_t uRemoteIP, uint16_t uRemotePort)
{
	REQUEST_PACKET oRequest;
	oRequest.uCtrlType = eCTRL_ADD_DATASOCK;
	oRequest.U.oDataSock.hSock = hSock;
	oRequest.U.oDataSock.uRemoteIP = uRemoteIP;
	oRequest.U.oDataSock.uRemotePort = uRemotePort;
	bool bRet = m_oMailBox.Send(oRequest);
    return bRet;
}

int Net::RemainPackets()
{
	REQUEST_PACKET oRequest;
	oRequest.uCtrlType = eCTRL_REMAINPACKETS;
	bool bRet = m_oMailBox.Send(oRequest);
	return bRet;
}

// Msg handler
void Net::OnRemainPackets()
{
	if (m_poNetEventHandler == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Msg handler not init\n", m_sNetName);
		return;
	}
	NSNetEvent::EVENT oEvent;
	oEvent.pNet = this;
	oEvent.uEventType = NSNetEvent::eEVT_REMAINPACKETS;
	m_poNetEventHandler->SendEvent(oEvent);
}

void Net::OnListen(uint16_t uListenPort, int nSessionID)
{
	if (m_poNetEventHandler == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Msg handler not init\n", m_sNetName);
		return;
	}
	NSNetEvent::EVENT oEvent;
	oEvent.pNet = this;
	oEvent.uEventType = NSNetEvent::eEVT_ON_LISTEN;
	oEvent.U.oListen.uListenPort = uListenPort;
	oEvent.U.oListen.nSessionID = nSessionID;
	m_poNetEventHandler->SendEvent(oEvent);
}

void Net::OnAccept(HSOCKET hSock, int nSessionID, uint32_t uRemoteIP, uint16_t uRemotePort)
{
	if (m_poNetEventHandler == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Msg handler not init\n", m_sNetName);
		return;
	}
	NSNetEvent::EVENT oEvent;
	oEvent.pNet = this;
	oEvent.uEventType = NSNetEvent::eEVT_ON_ACCEPT;
	oEvent.U.oAccept.hSock = hSock;
	oEvent.U.oAccept.nSessionID = nSessionID;
	oEvent.U.oAccept.uRemoteIP = uRemoteIP;
	oEvent.U.oAccept.uRemotePort = uRemotePort;
    m_poNetEventHandler->SendEvent(oEvent);
}

void Net::OnConnect(int nSessionID, uint32_t uRemoteIP, uint16_t uRemotePort)
{
	if (m_poNetEventHandler == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Msg handler not init\n", m_sNetName);
		return;
	}
	NSNetEvent::EVENT oEvent;
	oEvent.pNet = this;
	oEvent.uEventType = NSNetEvent::eEVT_ON_CONNECT;
	oEvent.U.oConnect.nSessionID = nSessionID;
	oEvent.U.oConnect.uRemoteIP = uRemoteIP;
	oEvent.U.oConnect.uRemotePort = uRemotePort;
    m_poNetEventHandler->SendEvent(oEvent);
}

void Net::OnClose(int nSessionID)
{
	if (m_poNetEventHandler == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Msg handler not init\n", m_sNetName);
		return;
	}
	NSNetEvent::EVENT oEvent;
	oEvent.pNet = this;
	oEvent.uEventType = NSNetEvent::eEVT_ON_CLOSE;
	oEvent.U.oClose.nSessionID = nSessionID;
    m_poNetEventHandler->SendEvent(oEvent);
}

void Net::OnAddDataSock(HSOCKET hSock, int nSessionID)
{
	if (m_poNetEventHandler == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Msg handler not init\n", m_sNetName);
		return;
	}
	NSNetEvent::EVENT oEvent;
	oEvent.pNet = this;
	oEvent.uEventType = NSNetEvent::eEVT_ADD_DATASOCK;
	oEvent.U.oDataSock.hSock = hSock;
	oEvent.U.oDataSock.nSessionID = nSessionID;
    m_poNetEventHandler->SendEvent(oEvent);
}

void Net::OnRecvPacket(void* pUD, Packet* poPacket)
{
	if (m_poNetEventHandler == NULL)
	{
		XLog(LEVEL_ERROR, "%s: Msg handler not init\n", m_sNetName);
		poPacket->Release();
		return;
	}
	SESSION* pSession = (SESSION*)pUD;
	NSNetEvent::EVENT oEvent;
	oEvent.pNet = this;
	oEvent.uEventType = NSNetEvent::eEVT_ON_RECV;
	oEvent.U.oRecv.nSessionID = pSession->nSessionID;
	oEvent.U.oRecv.poPacket = poPacket;
    m_poNetEventHandler->SendEvent(oEvent);
}