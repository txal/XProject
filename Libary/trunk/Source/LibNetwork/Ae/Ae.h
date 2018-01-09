#ifndef __AE_H__
#define __AE_H__

#include "Common/DataStruct/Thread.h"

#define AE_NONE 0
#define AE_READABLE 1
#define AE_WRITABLE 2
#define AE_CLOSE 3
#define AE_TIMER 4

struct EVENT
{
	void *pUD;  // User data
	int nEvent; // One of AE_(READABLE|WRITEABLE|TIMER)
};

// Message proc
typedef void(*EventProc_T)(void* pParam, const EVENT& Event);

class Ae
{
public:
	Ae() { m_fnEventProc = NULL; m_pEventParam = NULL; m_bShutDown = false;  }
	virtual ~Ae() {}

public:
	virtual bool Create(EventProc_T Proc, void* pParam) = 0;
	virtual bool Start() = 0;
	virtual void Stop() { m_bShutDown = true;  }
	virtual bool CreateEvent(HSOCKET nSock, void* pUD, int nEventMask) = 0;
	virtual bool ModifyEvent(HSOCKET nSock, void* pUD, int nEventMask) = 0;
	virtual bool DeleteEvent(HSOCKET nSock, void* pUD) = 0;

public:
	void Join() { m_EventThread.Join(); }

protected:
	virtual void EventLoop() = 0; // Event generator
	static void EventThread(void* pParam)
	{
		Ae* poAe = (Ae*)pParam;
		poAe->EventLoop();
	}

protected:
	Thread m_EventThread;
	EventProc_T m_fnEventProc;
	void* m_pEventParam;
	bool m_bShutDown;
	DISALLOW_COPY_AND_ASSIGN(Ae);
};

#endif
