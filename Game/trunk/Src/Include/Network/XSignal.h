#ifndef __SIGNAL_H__
#define __SIGNAL_H__

#include "Common/Platform.h"

class XSignal
{
public:
	XSignal();
	~XSignal();

public:
	HSOCKET GetRSock();
	bool Wait(int nMs);
	bool Notify();

private:
	bool MakeFdPair(HSOCKET* pRSock, HSOCKET* pWSock);

private:
	HSOCKET m_hRSock;
	HSOCKET m_hWSock;
	DISALLOW_COPY_AND_ASSIGN(XSignal);
};

#endif
