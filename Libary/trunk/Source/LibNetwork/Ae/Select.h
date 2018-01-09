#ifndef __SELECT_H__
#define __SELECT_H__

#include "LibNetwork/Ae/Ae.h"

class Select : public Ae
{
public:
	Select();
	virtual ~Select();

	virtual bool Create(EventProc_T Proc, void* pParam);
	virtual bool Start();
	virtual bool CreateEvent(HSOCKET hSock, void* pUD, int nEventMask);
	virtual bool ModifyEvent(HSOCKET hSock, void* pUD, int nEventMask);
	virtual bool DeleteEvent(HSOCKET hSock);

private:
	virtual void EventLoop();

private:
	bool m_bRetired;
	HSOCKET m_nMaxSock;

	int m_nSockNum;
	HSOCKET m_SockArray[FD_SETSIZE];

	void** m_pUDMap;
	int m_nUDCap;

	fd_set m_oSourceReadSet;
	fd_set m_oSourceWriteSet;
	fd_set m_oSourceExceptSet;

	fd_set m_oReadSet;
	fd_set m_oWriteSet;
	fd_set m_oExceptSet;
	DISALLOW_COPY_AND_ASSIGN(Select);

};

#endif
