#ifndef __IOCP_H__
#define __IOCP_H__

#include "LibNetwork/Ae/Ae.h"

#ifdef _WIN32

#define WAIT_OBJS 0x2

struct IOCP_EVENT
{
	OVERLAPPED oOverlapped;
	WSABUF oWsabuf;
	int nEvent;
	void* pUD;
};

struct SOCK_EVENT
{
	HSOCKET hSock;
	int nSessionID;
	IOCP_EVENT oReadEvent;	
	IOCP_EVENT oWriteEvent;	
};

class Iocp: public Ae
{
public:
	//<session,event>
	typedef std::unordered_map<int, SOCK_EVENT*> SockEventMap;
	typedef SockEventMap::iterator SockEventIter;

public:
	Iocp();
	virtual ~Iocp();
	virtual bool Create(EventProc_T fnProc, void* pParam);
	virtual bool Start();
	virtual bool CreateEvent(HSOCKET hSock, void* pUD, int nEventMask);
	virtual bool ModifyEvent(HSOCKET hSock, void* pUD, int nEventMask);
	virtual bool DeleteEvent(HSOCKET hSock, void* pUD);

private:
	bool AddEvent(HSOCKET hSock, void* pUD, int nEventMask);
	bool AddListenEvent(HSOCKET, void* pUD);
	SOCK_EVENT* GetSockEvent(int nSessionID);
	SOCK_EVENT* CreateSockEvent(HSOCKET hSock, int nSessionID);
	void CheckIocpEvent(IOCP_EVENT* poEvent);
	virtual void EventLoop();
	void ClearRetiredEvent();

private:
	HSOCKET m_hListenSock;
	int m_nListenSessionID;
    HANDLE m_hCompletionPort;
    HANDLE m_hObjects[WAIT_OBJS];
    SockEventMap m_oSockEventMap;
    std::vector<SOCK_EVENT*> m_oRetiredSockEventVec;
	DISALLOW_COPY_AND_ASSIGN(Iocp);
};

#endif //_WIN32

#endif