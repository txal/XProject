#ifndef __HLIST_H__
#define __HLIST_H__

#include <stdlib.h>

template<typename T>
struct HLIST_NODE
{
	T Value;
	HLIST_NODE<T> *pNext;
	HLIST_NODE<T> **pPPrev;
};

template<typename T>
class HList
{
	public:
		HList();
		~HList();
		HLIST_NODE<T>* GetHead();

	public:
		T Front();
		void PopFront();
		void PushFront(T Value);

		int Size();
		void Clear();
		void Remove(T Value);
		void Remove(HLIST_NODE<T> *pNode);

	private:
		HLIST_NODE<T> *m_pHead;	
		int m_nSize;

};

template<typename T>
HList<T>::HList()
{
	m_pHead = NULL;
	m_nSize = 0;
}

template<typename T>
HList<T>::~HList()
{
	Clear();
}

template<typename T>
HLIST_NODE<T>* HList<T>::GetHead()
{
	return m_pHead;
}

template<typename T>
T HList<T>::Front()
{
	if (m_nSize == 0)
	{
		return 0;
	}
	return m_pHead->Value;
}

template<typename T>
void HList<T>::PopFront()
 {
	if (m_nSize == 0)
	{
		return;
	}

	Remove(m_pHead);
}

template<typename T>
void HList<T>::PushFront(T Value)
 {
	HLIST_NODE<T>* pNode = new HLIST_NODE<T>();
	pNode->Value = Value;
	pNode->pNext = m_pHead;
	if (m_pHead != NULL)
	{
		m_pHead->pPPrev = &pNode->pNext;
	}
	m_pHead = pNode;
	pNode->pPPrev = &m_pHead;
	m_nSize++;
}

template<typename T>
int HList<T>::Size()
{
	return m_nSize;
}

template<typename T>
void HList<T>::Clear()
{
	HLIST_NODE<T>* pTmp = NULL;
	while (m_pHead != NULL)
	{
		pTmp = m_pHead;
		m_pHead = m_pHead->pNext;
		delete pTmp;
		pTmp = NULL;
	}
	m_nSize = 0;
}

template<typename T>
void HList<T>::Remove(T Value)
{
	HLIST_NODE<T>* pTmp = m_pHead;
	HLIST_NODE<T> *pTar = NULL;
	while (pTmp != NULL)
	{
		pTar = pTmp;
		pTmp = pTmp->pNext;
		if (pTar->Value == Value)
		{
			Remove(pTar);
		}
	}
}

template<typename T>
void HList<T>::Remove(HLIST_NODE<T>* pNode)
{
	if (pNode == NULL)
	{
		return;
	}
	HLIST_NODE<T> *pNext	= pNode->pNext;
	HLIST_NODE<T> **pPPrev = pNode->pPPrev;
	*pPPrev = pNext;
	if (pNext != NULL)
	{
		pNext->pPPrev = pPPrev;
	}
	delete pNode;
	pNode = NULL;
	m_nSize--;
}

#define HListForEachSafe(pPos, pTmp, pHead) \
for((pPos)=(pHead); (pTmp)=((pPos)?(pPos)->pNext:0),(pPos); (pPos)=(pTmp))

#endif

