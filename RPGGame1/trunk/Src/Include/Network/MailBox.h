#ifndef __MAILBOX_H__
#define __MAILBOX_H__

#include "Include/Logger/Logger.h"
#include "Common/DataStruct/MutexLock.h"
#include "Common/DataStruct/PureList.h"
#include "Include/Network/XSignal.h"

template <typename T>
class MailBox
{
public:
	MailBox();
	~MailBox();

    HSOCKET GetSock();
	int Size();
    bool Send(const T& Msg);
    bool Recv(T* pMsg, int nMs); //millisecond
	void SetName(const char* psName) { strcpy(m_sName, psName); }

private:
	char m_sName[32];
    XSignal m_oSignal;
    MutexLock m_oLock;
    PureList<T> m_oMsgList;
	int m_nLastWarningTime;
    DISALLOW_COPY_AND_ASSIGN(MailBox);
};

template <typename T>
MailBox<T>::MailBox()
{
	m_sName[0] = '\0';
	m_nLastWarningTime = 0;
}

template <typename T>
MailBox<T>::~MailBox() {}

template <typename T>
HSOCKET MailBox<T>::GetSock()
{
    return m_oSignal.GetRSock();
}

template <typename T>
int MailBox<T>::Size()
{
	int nSize = 0;
    m_oLock.Lock();
    nSize = m_oMsgList.Size();
	m_oLock.Unlock();
	return nSize;
}

template <typename T>
bool MailBox<T>::Send(const T& Msg)
{
    m_oLock.Lock();
    m_oMsgList.PushBack(Msg);
    int nMsgNum = m_oMsgList.Size();
    m_oLock.Unlock();

    if (nMsgNum == 1)
    {
        return m_oSignal.Notify();
    }
    if (nMsgNum >= 1024)
    {
        int nTimeNow = (int)time(0);
        if (m_nLastWarningTime != nTimeNow)
        {
            m_nLastWarningTime = nTimeNow;
            XLog(LEVEL_WARNING, "Mailbox:%s msg num overload:%d\n", m_sName, nMsgNum);
        }
    }
    return true;
}

template <typename T>
bool MailBox<T>::Recv(T* pMsg, int nMs)
{
    m_oLock.Lock();
    int nSize = m_oMsgList.Size();
    if (nSize > 0)
    {
        *pMsg = m_oMsgList.Front();
        m_oMsgList.PopFront();
    }
    m_oLock.Unlock();
    if (nSize > 0)
    {
        return true;
    }

    if (m_oSignal.Wait(nMs))
    {
        m_oLock.Lock();
        nSize = m_oMsgList.Size();
        if (nSize > 0)
        {
            *pMsg = m_oMsgList.Front();
            m_oMsgList.PopFront();
        }
        m_oLock.Unlock();
        if (nSize > 0)
        {
            return true;
        }
    }
    return false;
}

#endif
