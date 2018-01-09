#ifndef __EPOLL_H__
#define __EPOLL_H__

#include "LibNetwork/Ae/Ae.h"

#ifdef __linux

#define EPOLL_LT 0 /* Level-Triggered */
#define EPOLL_ET EPOLLET /* Edge-Triggered */

class Epoll : public Ae
{
private:
	DISALLOW_COPY_AND_ASSIGN(Epoll);

public:
	Epoll(int nTrigger, int nMaxConns);
	virtual ~Epoll();

	virtual bool Create(EventProc_T Proc, void* pParam);
	virtual bool Start();
	virtual bool CreateEvent(HSOCKET nSock, void* pUD, int nEventMask);
	virtual bool ModifyEvent(HSOCKET nSock, void* pUD, int nEventMask);
	virtual bool DeleteEvent(HSOCKET nSock, void* pUD);

protected:
	bool AddEvent(HSOCKET nSock, void* pUD, int nEventMask, int nOp);
	virtual void EventLoop();

private:
	int m_nTrigger;
	int m_nMaxEvents;
	HSOCKET m_nEpollSock;
	struct epoll_event* m_pEvents;
};

#endif

#endif
