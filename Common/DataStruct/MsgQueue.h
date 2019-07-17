#ifndef __MSGQUEUE_H__
#define __MSGQUEUE_H__

#include "Common/XTime.h"
#include "Common/PureList.h"
#include "Common/Platform.h"


/* Max message number of one queue */
#define MAX_MSG_NUM 204800

template<typename T>
class MsgQueue
{
	MsgQueue(const MsgQueue&);
	MsgQueue& operator=(const MsgQueue&);

	public:
		MsgQueue();
		void SetQueueName(const char* pName);
		int GetMsgCount();

	public:
		bool FetchMsg(T& Msg, int nMs);
		bool PumpMsgBack(const T& Msg);
		bool PumpMsgFront(const T& Msg);
	
	protected:
		bool PumpMsg(const T& Msg, bool bFront);

	private:
		PureList<T> m_MsgList;
		pthread_cond_t m_Cond;
		pthread_mutex_t m_Mutex;
		char m_QueueName[32];
};

template<typename T>
MsgQueue<T>::MsgQueue()
{
	m_QueueName[0] = '\0';
	pthread_mutex_init(&m_Mutex, NULL);
	pthread_cond_init(&m_Cond, NULL);
}

template<typename T>
void MsgQueue<T>::SetQueueName(const char* pName)
{
	if (pName != NULL)
		memcpy(m_QueueName, pName, sizeof(m_QueueName));
}

template<typename T>
int MsgQueue<T>::GetMsgCount()
{
	return m_MsgList.Size();
}

template<typename T>
bool MsgQueue<T>::FetchMsg(T& Msg, int nMs)
{
	pthread_mutex_lock(&m_Mutex);

	while (m_MsgList.Size() <= 0)
	{/* Use while see man */
		int nRes = 0;
		if (nMs > 0)
        {
			struct timespec ts = XTime::MakeTimespec(nMs);
			nRes = pthread_cond_timedwait(&m_Cond, &m_Mutex, &ts);
        }
        else
        {
            nRes = pthread_cond_wait(&m_Cond, &m_Mutex);
        }
		if (nRes != 0)
        {
			if (nRes == ETIMEDOUT) break;
			fprintf(stderr, "%s\n", strerror(nRes));
		}
	}

	bool bHasMsg = false;
	if (m_MsgList.Size() > 0)
	{
		Msg = m_MsgList.Front();
		m_MsgList.PopFront();
		bHasMsg = true;
	}

	pthread_mutex_unlock(&m_Mutex);
	return bHasMsg;
}

template<typename T>
bool MsgQueue<T>::PumpMsg(const T& Msg, bool bFront)
{
	pthread_mutex_lock(&m_Mutex);

	int nMsgCount = m_MsgList.Size();
	if (nMsgCount >= MAX_MSG_NUM)
	{
		static int nLastTime = time(0);
		int nTimeNow = time(0);
		if (nLastTime != nTimeNow)
		{
			nLastTime = nTimeNow;
			fprintf(stderr, "msgqueue:%s out of range:%d/%d\n", m_QueueName, nMsgCount, MAX_MSG_NUM);
		}
	}
	bFront ? m_MsgList.PushFront(Msg) : m_MsgList.PushBack(Msg);

	pthread_cond_signal(&m_Cond);
	pthread_mutex_unlock(&m_Mutex);
	return true;
}

template<typename T>
bool MsgQueue<T>::PumpMsgFront(const T &msg)
{
	return PumpMsg(msg, true);
}

template<typename T>
bool MsgQueue<T>::PumpMsgBack(const T &msg)
{
	return PumpMsg(msg, false);
}

#endif
