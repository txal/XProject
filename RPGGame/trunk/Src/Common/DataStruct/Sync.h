#ifndef __SYNC_H__
#define __SYNC_H__

#include "MutexLock.h"

class Sync
{
	Sync(const Sync&);
	Sync& operator=(const Sync&);

public:
	Sync() {}

	friend class ThreadSync;
	class ThreadSync
	{
		public:
			ThreadSync(Sync* pSync)
			{
				m_pSync = pSync;
				m_pSync->m_Lock.Lock(); 
			}

			~ThreadSync()
			{
				m_pSync->m_Lock.Unlock();
			}
		private:
			Sync *m_pSync;
	};

public:
	MutexLock& GetLock() { return m_Lock; }

private:
	MutexLock m_Lock;
};

#endif
