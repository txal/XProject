#ifndef __ATOMIC_H__
#define __ATOMIC_H__

#ifdef __linux

class AtoLock
{
public:
	AtoLock()
	{
		m_nLock = 0;
	}

	~AtoLock()
	{
		__sync_lock_release(&m_nLock);
	}

public:
	void Lock()
	{
		while (__sync_lock_test_and_set(&m_nLock, 1)) {}
	}

	void Unlock()
	{
		__sync_lock_release(&m_nLock);
	}

private:
	int m_nLock;

	AtoLock(const AtoLock&);
	AtoLock& operator=(const AtoLock&);

};

#endif

#ifdef __linux
#define atomic_inc(x) __sync_add_and_fetch((x),1)   
#define atomic_inc16(x) __sync_add_and_fetch((x),1)   
#define atomic_dec(x) __sync_sub_and_fetch((x),1)   
#define atomic_dec16(x) __sync_sub_and_fetch((x),1)   
#define atomic_add(x,y) __sync_add_and_fetch((x),(y))   
#define atomic_add16(x,y) __sync_add_and_fetch((x),(y))   
#define atomic_sub(x,y) __sync_sub_and_fetch((x),(y))  
#define atomic_sub16(x,y) __sync_sub_and_fetch((x),(y))  
#else
#define atomic_inc(x) InterlockedIncrement((x))
#define atomic_inc16(x) InterlockedIncrement16((x))
#define atomic_dec(x) InterlockedDecrement((x))
#define atomic_dec16(x) InterlockedDecrement16((x))
#define aomic_add(x,y) InterlockedExchangeAdd((x), (y))		//y可为负数
#define aomic_add16(x,y) InterlockedExchangeAdd16((x), (y)) //y可为负数
#endif

#endif
