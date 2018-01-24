#ifndef __THREAD_H__
#define __THREAD_H__

#include "Common/Platform.h"

typedef void (*ThreadFn_T)(void* pParam);

class Thread 
{
public:
	Thread()
	{
		m_Handle = 0;
		m_pArg = NULL;
		m_ThreadFn = NULL;
		m_bDetach = false;
	}

	bool Create(ThreadFn_T Fn, void* pArg, bool bDetach = true)
	{
		m_pArg = pArg;
		m_ThreadFn = Fn;
		m_bDetach = bDetach;
#ifdef __linux
		pthread_attr_t* pAttr = NULL;
		if (bDetach)
		{
			pthread_attr_t Attr;
			pAttr = &Attr;
			pthread_attr_init(pAttr);
			pthread_attr_setdetachstate(pAttr, PTHREAD_CREATE_DETACHED);
		}
		int nRet = pthread_create(&m_Handle, pAttr, Thread::MainLoop, (void*)this);
		if (pAttr != NULL)
		{
			pthread_attr_destroy(pAttr);
		}
		assert(nRet == 0);
#else
		m_Handle = (HANDLE)_beginthreadex(NULL, 0, Thread::MainLoop, this, 0, NULL);
		assert(m_Handle != NULL);
#endif
		return true;
	}

	void Join()
	{
		if (m_Handle == 0)
		{
			return;
		}
#ifdef __linux
		if (m_bDetach) //分离线程不需要JOIN
		{
			return;
		}
		int nRet = pthread_join(m_Handle, NULL);
		if (nRet != 0)
		{
			printf("pthread_join fail(%d):%s\n", nRet, strerror(nRet));
		}
#else
		WaitForSingleObject(m_Handle, INFINITE);
#endif
	}

private:

#ifdef __linux
	static void* MainLoop(void *pParam)
	{
		Thread* pSelf = (Thread*)pParam;
		pSelf->m_ThreadFn(pSelf->m_pArg);
		return (void*)0;
	}
#else
	static uint32_t __stdcall MainLoop(void *pParam)
	{
		Thread* pSelf = (Thread*)pParam;
		pSelf->m_ThreadFn(pSelf->m_pArg);
		return 0;
	}
#endif

private:
	DISALLOW_COPY_AND_ASSIGN(Thread);

	THREAD m_Handle;
	ThreadFn_T m_ThreadFn;
	void* m_pArg;
	bool m_bDetach;
};

#endif
