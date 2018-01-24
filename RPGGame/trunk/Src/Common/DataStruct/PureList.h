#ifndef __PURELIST_H__
#define __PURELIST_H__

#include <stdlib.h>

template <typename T>
struct PURELIST_NODE
{
	T Value;
	PURELIST_NODE<T>* pNext;
};

template <typename T>
class PureList
{
	PureList(const PureList&);
	PureList& operator=(const PureList&);

public:
	PureList();
	~PureList();

	 PURELIST_NODE<T>* GetHead();

public:
	T Front();
	T Back();
	void PopFront();
	void PushBack(T val);
	void PushFront(T val);
	void Remove(T val);

	int Size();
	void Clear();

private:
	PURELIST_NODE<T>* m_pHead;
	PURELIST_NODE<T>* m_pTail;	
	int m_nCount;
};

template <typename T>
PureList<T>::PureList()
{
	m_pHead = NULL;
	m_pTail = NULL;
	m_nCount = 0;
}

template <typename T>
PureList<T>::~PureList()
{
	Clear();
}

template <typename T>
PURELIST_NODE<T>* PureList<T>::GetHead()
{
	return m_pHead;
}

template <typename T>
int PureList<T>::Size()
{
	return m_nCount;
}

template <typename T>
void PureList<T>::Clear()
{
	while (m_pHead != NULL)
	{
		m_pTail = m_pHead;
		m_pHead = m_pHead->pNext;
		delete m_pTail;
		m_pTail = NULL;
	}
	m_nCount = 0;
}

template <typename T>
T PureList<T>::Front()
{
	if (m_pHead == NULL)
		return T();
	return m_pHead->Value;
}

template <typename T>
T PureList<T>::Back()
{
	if (m_pTail == NULL)
		return T();
	return m_pTail->Value;
}

template <typename T>
void PureList<T>::PopFront()
{
	if (m_pHead == NULL)
		return;
	PURELIST_NODE<T>* pTmp = m_pHead;
	if (m_pHead == m_pTail)
		m_pHead = m_pTail = NULL;
	else
		m_pHead = m_pHead->pNext;
	delete pTmp;
	pTmp = NULL;
	m_nCount--;
}

template <typename T>
void PureList<T>::PushBack(T Val)
{
	PURELIST_NODE<T>* pNode = new PURELIST_NODE<T>();
	pNode->Value = Val;
	pNode->pNext = NULL;
	if (m_pHead == NULL)
		m_pHead = m_pTail = pNode;	
	else
	{
		m_pTail->pNext = pNode;
		m_pTail = pNode;
	}
	m_nCount++;
}

template <typename T>
void PureList<T>::PushFront(T Val) 
{
	PURELIST_NODE<T>* pNode = new PURELIST_NODE<T>();
	pNode->Value = Val;
	pNode->pNext = NULL;
	if (m_pHead == NULL)
		m_pHead = m_pTail = pNode;	
	else 
	{
		pNode->pNext = m_pHead;
		m_pHead = pNode;
	}
	m_nCount++;
}

template <typename T>
void PureList<T>::Remove(T Val)
{
	if (m_pHead == NULL)
		return;
	PURELIST_NODE<T>* pPreNode = NULL;
	PURELIST_NODE<T>* pCurNode = m_pHead;
	PURELIST_NODE<T>* pTmpNode = NULL;
	do
	{
		if (pCurNode->Value == Val)
		{
			pTmpNode = pCurNode;
			pCurNode = pCurNode->pNext;
			if (pTmpNode == m_pHead)
			{
				m_pHead = pCurNode;
				if (m_pHead == NULL)
					m_pTail = NULL;
			}
			else if (pTmpNode == m_pTail)
			{
				m_pTail = pPreNode;
				pPreNode->pNext = pCurNode;
			}
			else
				pPreNode->pNext = pCurNode;

			delete pTmpNode;
			m_nCount--;
		}
		else
		{
			pPreNode = pCurNode;
			pCurNode = pCurNode->pNext;
		}
	} while (pCurNode != NULL);
}

#define PureListForEachSafe(pPos, pTmp, pHead) \
for ((pPos)=(pHead); (pTmp)=((pPos)?(pPos)->pNext:0),pPos; (pPos)=(pTmp))

#endif
