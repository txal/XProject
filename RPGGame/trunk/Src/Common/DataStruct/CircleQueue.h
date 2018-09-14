#ifndef __CIRCLEQUEUE_H__
#define __CIRCLEQUEUE_H__

#include <stdlib.h>
#include <string.h>

template<typename T>
class CircleQueue {
	CircleQueue(const CircleQueue&);
	CircleQueue& operator=(const CircleQueue&);	

	public:
		CircleQueue(int nSize)
		{
			(nSize <= 0) ? (nSize = 1) : 0;
			m_nSize	= nSize;
			m_pQueue = new T[m_nSize];
			m_nHead	= 0;
			m_nTail	= 0;
		}

		~CircleQueue()
		{
			delete[] m_pQueue;
			m_pQueue	= NULL;
			m_nSize = 0;
			m_nHead = 0;
			m_nTail = 0;
		}

		bool Push(const T& Data)
		{
			int nTmp = (m_nTail + 1) % m_nSize;
			/* Full */
			if (nTmp == m_nHead)
				return false;

			m_pQueue[m_nTail] = Data; 
			m_nTail = nTmp;
			return true;
		}

		T Pop()
		{
			/* Empty */
			if (m_nTail == m_nHead)
				return T();

			T Data = m_pQueue[m_nHead];
			m_nHead = (m_nHead + 1) % m_nSize;
			return Data;
		}

		bool IsEmpty()
		{
			return m_nHead == m_nTail;
		}

		bool IsFull()
		{
			return ((m_nTail + 1) % m_nSize == m_nHead);
		}

		int Size() 
		{
			return ((m_nSize + m_nTail - m_nHead) % m_nSize);
		}

	private:
		T *m_pQueue;
		int m_nHead;
		int m_nTail;
		int m_nSize;
};

#endif
