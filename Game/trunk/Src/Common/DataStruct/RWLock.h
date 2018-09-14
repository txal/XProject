#ifndef __RWLOCK_H__
#define __RWLOCK_H__

class RWLock 
{
	RWLock(const RWLock&);
	RWLock& operator=(const RWLock&);

public:
	RWLock() 
	{
		m_nRead = 0;
		m_nWrite = 0;
	}

public:
	void RLock()
	{
		for (;;)
		{
			while (m_nWrite)
				__sync_synchronize();

			__sync_add_and_fetch(&m_nRead, 1);

			if (m_nWrite)
				__sync_sub_and_fetch(&m_nRead, 1);
			else
				break;
		}
	}

	void WLock()
	{
		while (__sync_lock_test_and_set(&m_nWrite, 1)) {}

		while (m_nRead)
			__sync_synchronize();
	}

	void RUnlock()
	{
		__sync_sub_and_fetch(&m_nRead, 1);
	}

	void WUnlock()
	{
		__sync_lock_release(&m_nWrite);
	}

private:
	int m_nWrite;
	int m_nRead;
};

#endif



