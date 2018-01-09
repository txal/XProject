#include "LibNetwork/Ae/Select.h"
#include "Include/Logger/Logger.h"
#include "Common/DataStruct/XTime.h"

Select::Select()
{
	m_bRetired = false;
	m_nMaxSock = 0;

	m_nSockNum = 0;
	memset(m_SockArray, 0, sizeof(m_SockArray));

	m_nUDCap = FD_SETSIZE;
	m_pUDMap = (void**)XALLOC(NULL, m_nUDCap * sizeof(void*));

	FD_ZERO(&m_oSourceReadSet);
    FD_ZERO(&m_oSourceWriteSet);
    FD_ZERO(&m_oSourceExceptSet);
}

Select::~Select()
{
	SAFE_FREE(m_pUDMap);
}

bool Select::Create(EventProc_T Proc, void* pParam)
{
	m_fnEventProc = Proc;
	m_pEventParam = pParam;
    return true;
}

bool Select::Start()
{
	return m_EventThread.Create(Select::EventThread, this, false);
}

bool Select::CreateEvent(HSOCKET hSock, void* pUD, int nEventMask)
{
	if (m_nSockNum >= FD_SETSIZE)
	{
		XLog(LEVEL_ERROR, "Socket num:%d out of FD_SETSIZE:%d\n", m_nSockNum, FD_SETSIZE);
		return false;
	}
	FD_CLR(hSock, &m_oSourceReadSet);
	FD_CLR(hSock, &m_oSourceWriteSet);
	FD_CLR(hSock, &m_oSourceExceptSet);
	if (nEventMask & AE_READABLE)
	{
		FD_SET(hSock, &m_oSourceReadSet);
	}
	if (nEventMask & AE_WRITABLE)
	{
		FD_SET(hSock, &m_oSourceWriteSet);
	}
	FD_SET(hSock, &m_oSourceExceptSet);
	if (hSock > m_nMaxSock)
	{
		m_nMaxSock = hSock;
		while ((int)m_nMaxSock >= m_nUDCap)
		{
			m_nUDCap *= 2;
		}
		m_pUDMap = (void**)XALLOC(m_pUDMap, m_nUDCap * sizeof(void*));
	}
	m_SockArray[m_nSockNum++] = hSock;
	m_pUDMap[hSock] = pUD;
	return true;
}

bool Select::ModifyEvent(HSOCKET hSock, void* pUD, int nEventMask)
{
	if (nEventMask & AE_READABLE)
	{
		FD_SET(hSock, &m_oSourceReadSet);
	}
	else
	{
		FD_CLR(hSock, &m_oSourceReadSet);
	}
	if (nEventMask & AE_WRITABLE)
	{
		FD_SET(hSock, &m_oSourceWriteSet);
	}
	else
	{
		FD_CLR(hSock, &m_oSourceWriteSet);
	}
	return true;
}

bool Select::DeleteEvent(HSOCKET hSock)
{
	FD_CLR(hSock, &m_oSourceReadSet);
	FD_CLR(hSock, &m_oSourceWriteSet);
	FD_CLR(hSock, &m_oSourceExceptSet);
	for (int i = 0; i < m_nSockNum; i++)
	{
		if (m_SockArray[i] == hSock)
		{
			m_SockArray[i] = INVALID_SOCKET;
			m_pUDMap[hSock] = NULL;
			m_bRetired = true;
			break;
		}
	}
	return true;
}

void Select::EventLoop()
{
	int nMSTimeOut = 100;
	int64_t nLastMSTime = 0;
	struct timeval tv = { (long)(nMSTimeOut / 1000), (long)(nMSTimeOut % 1000 * 1000) };
	for (;;)
	{
		if (m_bShutDown)
		{
			break;
		}
        memcpy(&m_oReadSet, &m_oSourceReadSet, sizeof(m_oSourceReadSet));
        memcpy(&m_oWriteSet, &m_oSourceWriteSet, sizeof(m_oSourceWriteSet));
        memcpy(&m_oExceptSet, &m_oSourceExceptSet, sizeof(m_oSourceExceptSet));
		// First param 'nfds' will be ignored in window
		int nRet = select((int)m_nMaxSock + 1, &m_oReadSet, &m_oWriteSet, &m_oExceptSet, &tv);
		int64_t nMSTime = XTime::MSTime();
		if (nMSTime - nLastMSTime >= nMSTimeOut)
		{
			nLastMSTime = nMSTime;
			EVENT NewEvent;
			NewEvent.pUD = (void*)nMSTimeOut;
			NewEvent.nEvent = AE_TIMER;
			m_fnEventProc(m_pEventParam, NewEvent);
		}
		if (nRet <= 0)
		{
			if (nRet == -1)
			{
#ifdef _WIN32
				const char* pErr = Platform::LastErrorStr(GetLastError());
#else
				const char* pErr = strerror(errno);
#endif
				XLog(LEVEL_ERROR, "%s\n", pErr);
			}
			continue;
		}

		for (int i = 0; i < m_nSockNum; i ++)
		{
			if (FD_ISSET(m_SockArray[i], &m_oExceptSet))
			{
				EVENT NewEvent;
				NewEvent.pUD = m_pUDMap[m_SockArray[i]];
				NewEvent.nEvent = AE_CLOSE;
				m_fnEventProc(m_pEventParam, NewEvent);
			}

            if (FD_ISSET(m_SockArray[i], &m_oWriteSet))
			{
				EVENT NewEvent;
				NewEvent.pUD = m_pUDMap[m_SockArray[i]];
				NewEvent.nEvent = AE_WRITABLE;
				m_fnEventProc(m_pEventParam, NewEvent);
			}

            if (FD_ISSET(m_SockArray[i], &m_oReadSet))
			{
				EVENT NewEvent;
				NewEvent.pUD = m_pUDMap[m_SockArray[i]];
				NewEvent.nEvent = AE_READABLE;
				m_fnEventProc(m_pEventParam, NewEvent);
			}
        }
        //  Destroy retired event sources.
        if (m_bRetired)
		{
			for (int i = 0; i < m_nSockNum; )
			{
				if (m_SockArray[i] == INVALID_SOCKET)
				{
					m_SockArray[i] = m_SockArray[--m_nSockNum];
				}
				else
				{
					i++;
				}
			}
            m_bRetired = false;
        }
	}
	XLog(LEVEL_INFO, "ae:%0x thread exit\n", (void*)this);
}
