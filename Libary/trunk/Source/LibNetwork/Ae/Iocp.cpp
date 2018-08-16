#include "LibNetwork/Ae/Iocp.h"
#include "Include/Logger/Logger.h"
#include "Common/DataStruct/XTime.h"
#include "LibNetwork/Session.h"

#ifdef _WIN32

Iocp::Iocp()
{
    m_hCompletionPort = 0;
	m_hListenSock = INVALID_SOCKET;
	m_nListenSessionID = 0;
    memset(m_hObjects, 0, sizeof(m_hObjects));
}

Iocp::~Iocp()
{
	::CloseHandle(m_hCompletionPort);
	for (int i = 0; i < WAIT_OBJS; i++)
	{
		::CloseHandle(m_hObjects[i]);
	}
	SockEventIter iter = m_oSockEventMap.begin();
	SockEventIter iter_end = m_oSockEventMap.end();
	for (; iter != iter_end; iter++)
	{
        SAFE_FREE(iter->second);
	}
	ClearRetiredEvent();
}

bool Iocp::Create(EventProc_T fnProc, void* pParam)
{
    m_hCompletionPort = CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, 0, 0);
    if (m_hCompletionPort == NULL)
    {
        XLog(LEVEL_ERROR, "CreateIocompletionPort failed: %s\n", Platform::LastErrorStr(WSAGetLastError()));
        return false;
    }
    for (int i = 0; i < WAIT_OBJS; i++)
    {
        m_hObjects[i] = ::CreateEvent(NULL, FALSE, FALSE, NULL);
    }
	m_fnEventProc = fnProc;
	m_pEventParam = pParam;

    return true;
}

bool Iocp::Start()
{
	return m_EventThread.Create(Iocp::EventThread, this);
}

SOCK_EVENT* Iocp::GetSockEvent(int nSessionID)
{
	SockEventIter iter = m_oSockEventMap.find(nSessionID);
	if (iter != m_oSockEventMap.end())
	{
		return iter->second;
	}
	return NULL;
}

SOCK_EVENT* Iocp::CreateSockEvent(HSOCKET hSock, int nSessionID)
{
    SOCK_EVENT* poEvent = (SOCK_EVENT*)XALLOC(NULL, sizeof(SOCK_EVENT));
	memset(poEvent, 0, sizeof(SOCK_EVENT));
	poEvent->hSock = hSock;
	poEvent->nSessionID = nSessionID;
	m_oSockEventMap.insert(std::make_pair(nSessionID, poEvent));
	return poEvent;
}


bool Iocp::AddListenEvent(HSOCKET hSock, void* pUD)
{
	if (m_hListenSock != INVALID_SOCKET && m_hListenSock != hSock)
	{
		XLog(LEVEL_ERROR, "Only support one listen sock\n");
		return false;
	}
	SESSION* poSession = (SESSION*)pUD;
	m_hListenSock = hSock;
	m_nListenSessionID = poSession->nSessionID;
    SOCK_EVENT* poEvent = GetSockEvent(m_nListenSessionID);
	if (poEvent == NULL)
	{
		poEvent = CreateSockEvent(hSock, m_nListenSessionID);
		assert(poEvent != NULL);
	}
	memset(&poEvent->oReadEvent, 0, sizeof(poEvent->oReadEvent));
	poEvent->oReadEvent.nEvent = AE_READABLE;
	poEvent->oReadEvent.pUD = pUD;
	WSAEventSelect(hSock, m_hObjects[1], FD_ACCEPT);
	return true;
}

bool Iocp::AddEvent(HSOCKET hSock, void* pUD, int nEventMask)
{
	if (nEventMask == AE_NONE)
	{
		return false;
	}
	SESSION* poSession = (SESSION*)pUD;
    SOCK_EVENT* poEvent = GetSockEvent(poSession->nSessionID);
	if (poEvent == NULL)
	{
		poEvent = CreateSockEvent(hSock, poSession->nSessionID);
		assert(poEvent != NULL);
	}

    DWORD uFlags = 0;
    if (nEventMask & AE_READABLE)
    {
        DWORD uRecvBytes = 0;
		memset(&poEvent->oReadEvent, 0, sizeof(poEvent->oReadEvent));
        poEvent->oReadEvent.oOverlapped.hEvent = m_hObjects[0];
        poEvent->oReadEvent.nEvent = AE_READABLE;
        poEvent->oReadEvent.pUD = pUD;
		if (WSARecv(hSock, &(poEvent->oReadEvent.oWsabuf), 1, &uRecvBytes, &uFlags, &(poEvent->oReadEvent.oOverlapped), NULL) == SOCKET_ERROR)
        {
			int nLastError = WSAGetLastError();
            if(nLastError != ERROR_IO_PENDING)
            {
                XLog(LEVEL_ERROR, "WSARecv failed: %s", Platform::LastErrorStr(nLastError));
                return false;
            } 
        }
    }

    if (nEventMask & AE_WRITABLE)
    {
        DWORD uSendBytes = 0;
		memset(&poEvent->oWriteEvent, 0, sizeof(poEvent->oWriteEvent));
        poEvent->oWriteEvent.oOverlapped.hEvent = m_hObjects[0];
		poEvent->oWriteEvent.nEvent = AE_WRITABLE;
        poEvent->oWriteEvent.pUD = pUD;
		if (WSASend(hSock, &(poEvent->oWriteEvent.oWsabuf), 1, &uSendBytes, uFlags, &(poEvent->oWriteEvent.oOverlapped), NULL) == SOCKET_ERROR)
        {
			int nLastError = WSAGetLastError();
            if(nLastError != ERROR_IO_PENDING)
            {
                XLog(LEVEL_ERROR, "WSASend failed: %s", Platform::LastErrorStr(nLastError));
                return false;
            }
        }
    }
    return true;
}

bool Iocp::CreateEvent(HSOCKET hSock, void* pUD, int nEventMask)
{
	if (nEventMask == AE_NONE)
	{
		return false;
	}
	SESSION* poSession = (SESSION*)pUD;
	SOCK_EVENT* poEvent = GetSockEvent(poSession->nSessionID);
	assert(poEvent == NULL);

	if (poSession->nSessionType == SESSION_TYPE_LISTEN)
	{
		return AddListenEvent(hSock, pUD);
	}
    if (CreateIoCompletionPort((HANDLE)hSock, m_hCompletionPort, poSession->nSessionID, 0) == NULL)
    {
        // If ERROR_INVALID_PARAMETER, then this handle was already registered.
        int nLastError = WSAGetLastError();
        if (nLastError != ERROR_INVALID_PARAMETER)
        {
            XLog(LEVEL_ERROR, "CreateIoCompletionPort fail! %s", Platform::LastErrorStr(nLastError));
            return false;
        }
    }
	return AddEvent(hSock, pUD, nEventMask);
}

bool Iocp::ModifyEvent(HSOCKET hSock, void* pUD, int nEventMask)
{
	if (nEventMask == AE_NONE)
	{
		return false;
	}
	SESSION* poSession = (SESSION*)pUD;
	if (poSession->nSessionType == SESSION_TYPE_LISTEN)
	{
		return AddListenEvent(hSock, pUD);
	}
	return AddEvent(hSock, pUD, nEventMask);
}

bool Iocp::DeleteEvent(HSOCKET hSock, void* pUD)
{
	SESSION* poSession = (SESSION*)pUD;
    SOCK_EVENT* poEvent = GetSockEvent(poSession->nSessionID);
    if (poEvent != NULL)
    {
		m_oSockEventMap.erase(poSession->nSessionID);
	    m_oRetiredSockEventVec.push_back(poEvent);
    }
	return true;
}
void Iocp::CheckIocpEvent(IOCP_EVENT* poEvent)
{
    if (poEvent->nEvent == AE_WRITABLE)
    {
        EVENT oNetEvent;
        oNetEvent.pUD = poEvent->pUD;
        oNetEvent.nEvent = AE_WRITABLE;
        (*m_fnEventProc)(m_pEventParam, oNetEvent);
    }
    else if (poEvent->nEvent == AE_READABLE)
    {
        EVENT oNetEvent;
        oNetEvent.pUD = poEvent->pUD;;
        oNetEvent.nEvent = AE_READABLE;
        (*m_fnEventProc)(m_pEventParam, oNetEvent);
    }
    else
    {
        XLog(LEVEL_ERROR, LOG_ADDR"CheckIocpEvent event type error!\n");
    }
}

void Iocp::EventLoop()
{
	int nMSTickTimeOut = 100;
	int64_t nLastTickMSTime = 0;

	int nMSClearTimeOut = 60 * 1000;
	int64_t nLastClearMSTime = 0;

    for (;;)
    {
		if (m_bShutDown)
		{
			break;
		}
		
        int nIndex = WSAWaitForMultipleEvents(WAIT_OBJS, m_hObjects, FALSE, nMSTickTimeOut, FALSE );
		int64_t nNowMSTime = XTime::MSTime();
		if (nNowMSTime - nLastTickMSTime >= nMSTickTimeOut)
		{
			nLastTickMSTime = nNowMSTime;
			EVENT oNetEvent;
			oNetEvent.pUD = (void*)nMSTickTimeOut;
			oNetEvent.nEvent = AE_TIMER;
			(*m_fnEventProc)(m_pEventParam, oNetEvent);
		}
        if (nIndex == WAIT_FAILED || nIndex == WAIT_TIMEOUT )
        {
            if (nIndex == WAIT_FAILED)
            {
                XLog(LEVEL_ERROR, "WSAWaitForMultipleEvents fail! %s", Platform::LastErrorStr(WSAGetLastError()));
            }
            continue;
        }

		//listen
		if (nIndex == 1)
		{
			SOCK_EVENT* poSockEvent = GetSockEvent(m_nListenSessionID);
			if (poSockEvent != NULL)
			{
				CheckIocpEvent(&(poSockEvent->oReadEvent));
			}
			else
			{
				XLog(LEVEL_ERROR, "Socket event for listen socket fail\n");
				assert(false);
			}
		}
		//normal
		else if (nIndex == 0)
		{
			for (;;)
			{
				DWORD uTransByte = 0;
				ULONG_PTR uIocpKey = 0;
				IOCP_EVENT* poEvent = NULL;
				BOOL bRet = GetQueuedCompletionStatus(m_hCompletionPort, &uTransByte, &uIocpKey, (OVERLAPPED**)&poEvent, 0);
				int nLastError = WSAGetLastError();
				if (!bRet)
				{
					if (poEvent != NULL)
					{
						//如果主动调用CloseSession会提前释放SOCK_EVENT,而事先又投递了事件,会导致这里返回的poEvent为野指针,所以用Retire机制
						if (GetSockEvent((int)uIocpKey) != NULL)
						{
							CheckIocpEvent(poEvent);
						}
						continue;
					}
					else if (nLastError != WAIT_TIMEOUT)
					{
						XLog(LEVEL_ERROR, "GetQueuedCompletionStatus error: %s", Platform::LastErrorStr(nLastError));
					}
					break;
				}
				if (poEvent == NULL)
				{
					XLog(LEVEL_ERROR, "Event is null, dangerous!\n");
					break;
				}
				CheckIocpEvent(poEvent);
			}
		}

		if (nNowMSTime - nLastClearMSTime >= nMSClearTimeOut)
		{
			nLastClearMSTime = nNowMSTime;
			ClearRetiredEvent();
		}
    }
	XLog(LEVEL_INFO, "ae:%0x thread exit\n", (void*)this);
}

void Iocp::ClearRetiredEvent()
{
	for (int i = 0; i < m_oRetiredSockEventVec.size(); i++)
	{
		SAFE_FREE(m_oRetiredSockEventVec[i]);
	}
	m_oRetiredSockEventVec.clear();
}

#endif
