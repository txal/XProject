#ifndef __MUTEX_LOCK_H__
#define __MUTEX_LOCK_H__

#include "Common/Platform.h"

class MutexLock
{
private:
    DISALLOW_COPY_AND_ASSIGN(MutexLock);

public:
	MutexLock()
	{
#ifdef __linux
		pthread_mutexattr_t Attr;
		int nRet = pthread_mutexattr_init(&Attr);
		assert(nRet == 0);
		nRet = pthread_mutexattr_settype(&Attr, PTHREAD_MUTEX_ERRORCHECK);
		assert(nRet == 0);
		nRet = pthread_mutex_init(&m_Mutex, &Attr);
		assert(nRet == 0);
#else
		InitializeCriticalSection(&m_Mutex);
#endif
	}

	~MutexLock()
	{
#ifdef __linux
		int nRet = pthread_mutex_destroy(&m_Mutex);
		assert(nRet == 0);
#else
		DeleteCriticalSection(&m_Mutex);
#endif
	}

public:
	void Lock()
	{
#ifdef __linux
		int nRet = pthread_mutex_lock(&m_Mutex);
		assert(nRet == 0);
#else
		EnterCriticalSection(&m_Mutex);
#endif
	}

	void Unlock()
	{
#ifdef __linux
		int nRet = pthread_mutex_unlock(&m_Mutex);
		assert(nRet == 0);
#else
		LeaveCriticalSection(&m_Mutex);
#endif
	}

    bool TryLock()
    {
#ifdef __linux
        int nRet = pthread_mutex_trylock(&m_Mutex);
        if (nRet == EBUSY)
        {
            return false;
        }
		return true;
#else
		return (TryEnterCriticalSection(&m_Mutex) ? true : false);
#endif
	}

private:
#ifdef __linux
	pthread_mutex_t m_Mutex;
#else
	CRITICAL_SECTION m_Mutex;
#endif
};

#endif
