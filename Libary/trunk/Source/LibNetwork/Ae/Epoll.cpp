#include "LibNetwork/Ae/Epoll.h"
#include "Include/Logger/Logger.h"
#include "Include/Network/NetAPI.h"
#include "Common/DataStruct/Thread.h"
#include "Common/DataStruct/XTime.h"

#ifdef __linux

Epoll::Epoll(int nTrigger, int nMaxConns)
{
	m_nEpollSock = 0;
	m_nTrigger = nTrigger;
	m_nMaxEvents = nMaxConns;
}

Epoll::~Epoll()
{
	SAFE_FREE(m_pEvents);
	NetAPI::CloseSocket(m_nEpollSock);
}

bool Epoll::Create(EventProc_T Proc, void* pParam)
{
	if (Proc == NULL)
	{
		return false;
	}
	m_pEventParam = pParam;
	m_fnEventProc = Proc;
	m_nEpollSock = epoll_create(1024);
	if (m_nEpollSock == -1) 
	{
		XLog(LEVEL_ERROR, "%s\n", strerror(errno));
		return false;
	}

	m_pEvents = (struct epoll_event*)XALLOC(NULL, (m_nMaxEvents + 1024) * sizeof(struct epoll_event));
	return true;
}

bool Epoll::Start()
{
	return m_EventThread.Create(Epoll::EventThread, this, false);
}

bool Epoll::AddEvent(HSOCKET nSock, void* pUD, int nEventMask, int nOp)
{
	if (nEventMask == AE_NONE)
	{
		return false;
	}
	struct epoll_event oEvent;
	oEvent.data.u64 = 0;	// Avoid valgrind warning
	oEvent.data.ptr = pUD;
	oEvent.events = 0;
	if (nEventMask & AE_READABLE)
	{
		oEvent.events |= EPOLLIN;
	}
	if (nEventMask & AE_WRITABLE)
	{
		oEvent.events |= EPOLLOUT;
	}
	oEvent.events |= m_nTrigger | EPOLLRDHUP; // Since linux 2.6.17
	const char *psOp = (nOp == EPOLL_CTL_ADD ? "add" : "mod"); 
	if (epoll_ctl(m_nEpollSock, nOp, nSock, &oEvent) == -1)
	{
		XLog(LEVEL_ERROR, "AddEvent(%s) error:%s\n", psOp, strerror(errno));
		return false;
	}
	return true;
}

bool Epoll::CreateEvent(HSOCKET nSock, void* pUD, int nEventMask)
{
	return AddEvent(nSock, pUD, nEventMask, EPOLL_CTL_ADD);
}

bool Epoll::ModifyEvent(HSOCKET nSock, void* pUD, int nEventMask)
{
	return AddEvent(nSock, pUD, nEventMask, EPOLL_CTL_MOD);
}

bool Epoll::DeleteEvent(HSOCKET nSock, void* pUD)
{
	struct epoll_event Event; /* For before linux 2.6.9 */
	Event.events = 0; /* Will be ignored */
	if (epoll_ctl(m_nEpollSock, EPOLL_CTL_DEL, nSock, &Event) == -1)
	{
		XLog(LEVEL_ERROR, "Fd:%d del event:%s\n", nSock, strerror(errno));
		return false;
	}
	return true;
}

void Epoll::EventLoop()
{
	int nMSTimeOut = 100;
	int64_t nLastMSTime = 0;
	for (;;)
	{
		if (m_bShutDown)
		{
			break;
		}
		int nEventNum = epoll_wait(m_nEpollSock, m_pEvents, m_nMaxEvents, nMSTimeOut);
		int64_t nMSTime = XTime::MSTime();
		if (nMSTime - nLastMSTime >= nMSTimeOut)
		{
			nLastMSTime = nMSTime;
			EVENT NewEvent;
			NewEvent.pUD = (void*)nMSTimeOut;
			NewEvent.nEvent	= AE_TIMER;
			(*m_fnEventProc)(m_pEventParam, NewEvent);
		}

		if (nEventNum <= 0)
		{
			if (nEventNum == -1)
			{
				XLog(LEVEL_ERROR, "%s\n", strerror(errno));
			}
			continue;
		}

		for (int i = 0; i < nEventNum; i++)
		{
			int events = m_pEvents[i].events;
			if (events & EPOLLERR || events & EPOLLRDHUP || events & EPOLLHUP)
			{
				EVENT NewEvent;
				NewEvent.pUD = m_pEvents[i].data.ptr;
				NewEvent.nEvent	= AE_CLOSE;
				(*m_fnEventProc)(m_pEventParam, NewEvent);
				continue;
			}
			if (events & EPOLLOUT)
			{
				EVENT NewEvent;
				NewEvent.pUD = m_pEvents[i].data.ptr;
				NewEvent.nEvent	= AE_WRITABLE;
				(*m_fnEventProc)(m_pEventParam, NewEvent);
			}
			if (events & EPOLLIN)
			{
				EVENT NewEvent;
				NewEvent.pUD = m_pEvents[i].data.ptr;
				NewEvent.nEvent	= AE_READABLE;
				(*m_fnEventProc)(m_pEventParam, NewEvent);
			}
		}
	}
	XLog(LEVEL_INFO, "ae:%0x thread exit\n", (void*)this);
}

#endif
