#ifndef __LIST_H__
#define __LIST_H__

#include "Sync.h"

template<typename T>
struct ListNode<T> {
	T Value;
	ListNode<T>* pPrev;
	ListNode<T>* pNext;
};

template<typename T>
class List : public Sync {
	List(const List&);
	List& operator=(const List&);

	public:
		List();
		~List();
		ListNode<T>* GetHead();

	public:
		void RawPopBack();
		void RawPopFront();
		void RawPushBack(T Value);
		void RawPushFront(T Value);
		void RawRemove(ListNode<T>* pNode);

	public:
		T Back();
		T Front();
		void PopBack();
		void PopFront();
		void PushBack(T Value);
		void PushFront(T Value);

		int Size();
		void Clear();
		void Remove(T Value);
		void Remove(ListNode<T>* pNode);

	private:
		ListNode<T>* m_pHead;	
		int m_nCount;
};

template<typename T>
List<T>::List() {
	m_pHead = new ListNode<T>();
	m_pHead->Value = 0;
	m_pHead->pNext = m_pHead;
	m_pHead->pPrev = m_pHead;
	m_nCount = 0;
}

template<typename T>
List<T>::~List() {
	Clear();
	delete m_pHead;
	m_pHead = NULL;
}

template<typename T>
ListNode<T> *List<T>::GetHead() {
	return m_pHead;
}

template<typename T>
void List<T>::RawPopBack() {
	RawRemove(m_pHead->pPrev);
}

template<typename T>
void List<T>::RawPopFront() {
	RawRemove(m_pHead->pNext);
}

template<typename T>
void List<T>::RawPushBack(T Value) {
	ListNode<T>* pNode = new ListNode<T>();
	pNode->Value = Value;
	pNode->pNext = m_pHead;
	pNode->pPrev = m_pHead->pPrev;
	m_pHead->pPrev = pNode;
	pNode->pPrev->pNext = pNode;
	m_nCount++;
}

template<typename T>
void List<T>::RawPushFront(T Value) {
	ListNode<T>* pNode = new ListNode<T>();
	pNode->Value = Value;
	pNode->pNext = m_pHead->pNext;
	pNode->pPrev = m_pHead;
	m_pHead->pNext = pNode;
	pNode->pNext->pPrev = pNode;
	m_nCount++;
}

template<typename T>
void List<T>::RawRemove(ListNode<T>* pNode) {
	if (pNode == m_pHead)
		return;
	pNode->pPrev->pNext = pNode->pNext;
	pNode->pNext->pPrev = pNode->pPrev;
	delete pNode;
	pNode = NULL;
	m_nCount--;
}

template<typename T>
T List<T>::Back() {
	ThreadSync Sync(this);
	if (m_pHead->pNext == m_pHead)
		return T();
	return m_pHead->pPrev->Value;
}

template<typename T>
T List<T>::Front() {
	ThreadSync Sync(this);
	if (m_pHead->pNext == m_pHead)
		return T();
	return m_pHead->pNext->Value;
}

template<typename T>
void List<T>::PushBack(T Value) {
	ThreadSync Sync(this);
	RawPushBack(Value);
}

template<typename T>
void List<T>::PushFront(T Value) {
	ThreadSync Sync(this);
	RawPushFront(Value);
}

template<typename T>
void List<T>::PopBack() {
	ThreadSync Sync(this);
	RawPopBack();
}

template<typename T>
void List<T>::PopFront() {
	ThreadSync Sync(this);
	RawPopFront();
}

template<typename T>
int List<T>::Size() {
	ThreadSync Sync(this);
	return m_nCount;
}

template<typename T>
void List<T>::Clear() {
	ThreadSync Sync(this);
	ListNode<T>* pTmp = m_pHead->pNext;
	ListNode<T>* pTar = NULL;
	while (pTmp != m_pHead) {
		pTar = pTmp;
		pTmp = pTmp->pNext;
		delete pTar;
		pTar = NULL;
	}
	m_pHead->pNext = m_pHead;
	m_pHead->pPrev = m_pHead;
	m_nCount = 0;
}

template<typename T>
void List<T>::Remove(T Value) {
	ThreadSync Sync(this);
	if (m_pHead->pNext == m_pHead) 
		return;
	ListNode<T>* pTmp = m_pHead->pNext;
	ListNode<T>* pTar = NULL;
	while (pTmp != m_pHead) {
		pTar = pTmp;
		pTmp = pTmp->pNext;
		if (pTar->Value == Value)
			RawRemove(pTar);
	}
}

template<typename T>
void List<T>::Remove(ListNode<T>* pNode) {
	ThreadSync Sync(this);
	RawRemove(pNode);
}

#define ListForEachSafe(pPos, pTmp, pHead) \
for((pPos)=(pHead)->pNext; (pTmp)=(pPos)->pNext,(pPos)!=(pHead); (pPos)=(pTmp))

#endif
