#ifndef __SYNCMAP_H__
#define __SYNCMAP_H__

#include "HList.h"
#include "AtoLock.h"
#include "hashfunc.h"

#include <stdio.h>
#include <stdint.h>

template<typename T>
class SyncMap
{
public:
	SyncMap(int nBucketNum);
	~SyncMap();

	int GetBucketNum();
	HList<T>* GetHead();
	AtoLock* GetLockArray();

public:
	T Find(uint32_t uMD5);
	void Insert(uint32_t uMD5, T Value);
	void Remove(T Value);
	void Remove(uint32_t uMD5);
	void Remove(HLIST_NODE<T>* pNode);

	int Size();
	void Clear();
	void PrintMap();

private:
	HList<T>* m_pBucket;
	AtoLock* m_pAtoLock;
	int m_nBucketNum;
	DISALLOW_COPY_AND_ASSIGN(SyncMap);
};


template<typename T>
SyncMap<T>::SyncMap(int nBucketNum)
{
	m_nBucketNum = nBucketNum > 0 ? nBucketNum : 1;
	m_pBucket = new HList<T>[m_nBucketNum];
	m_pAtoLock = new AtoLock[m_nBucketNum];
}

template<typename T>
SyncMap<T>::~SyncMap()
{
	Clear();
	delete[] m_pBucket;
	m_pBucket = NULL;
	m_nBucketNum = 0;
}

template<typename T>
int SyncMap<T>::GetBucketNum()
{
	return m_nBucketNum;
}

template<typename T>
HList<T> *SyncMap<T>::GetHead()
{
	return m_pBucket;
}

template<typename T>
AtoLock* SyncMap<T>::GetLockArray()
{
	return m_pAtoLock;
}

template<typename T>
T SyncMap<T>::Find(uint32_t uMD5)
{
	T TarValue = T();
	int nBucket = uMD5 % m_nBucketNum;
	HLIST_NODE<T>* pPos = NULL, *pTmp = NULL;
	m_pAtoLock[nBucket].Lock();
	HLIST_NODE<T>* pHead = m_pBucket[nBucket].GetHead();
	HListForEachSafe(pPos, pTmp, pHead)
	{
		if (pPos->Value->uMD5 == uMD5)
		{
			TarValue = pPos->Value;
			break;
		}
	}
	m_pAtoLock[nBucket].Unlock();
	return TarValue;
}

template<typename T>
void SyncMap<T>::Insert(uint32_t uMD5, T Value)
{
	Value->uMD5 = uMD5;
	int nBucket = uMD5 % m_nBucketNum;
	bool bDuplicated = false;
	HLIST_NODE<T>* pPos = NULL, *pTmp = NULL;
	m_pAtoLock[nBucket].Lock();
	HLIST_NODE<T>* pHead = m_pBucket[nBucket].GetHead();
	HListForEachSafe(pPos, pTmp, pHead)
	{
		if (pPos->Value->uMD5 == uMD5)
		{
			fprintf(stderr, "Map key:%u duplicated!\n", uMD5);
			bDuplicated = true;
			break;
		}
	}
	if (!bDuplicated)
	{
		m_pBucket[nBucket].PushFront(Value);
		if (m_pBucket[nBucket].Size() >= MAX_ELEM_PERSLOT)
		{
			fprintf(stderr, "map Bucket elements out of range\n");
		}
	}
	m_pAtoLock[nBucket].Unlock();
}

template<typename T>
void SyncMap<T>::Remove(uint32_t uMD5)
{
	int nBucket = uMD5 % m_nBucketNum;
	HLIST_NODE<T>* pPos = NULL, *pTmp = NULL;
	m_pAtoLock[nBucket].Lock();
	HLIST_NODE<T>* pHead = m_pBucket[nBucket].GetHead();
	HListForEachSafe(pPos, pTmp, pHead)
	{
		if (pPos->Value->uMD5 == uMD5)
		{
			m_pBucket[nBucket].Remove(pPos);
			break;
		}
	}
	m_pAtoLock[nBucket].Unlock();
}

template<typename T>
void SyncMap<T>::Remove(T Value)
{
	Remove(Value->uMD5);
}

template<typename T>
void SyncMap<T>::Remove(HLIST_NODE<T>* pNode)
{
	Remove(pNode->Value->uMD5);
}

template<typename T>
void SyncMap<T>::Clear()
{
	for (int i = m_nBucketNum - 1; i >= 0; i--)
	{
		m_pAtoLock[i].Lock();
		m_pBucket[i].Clear();
		m_pAtoLock[i].Unlock();
	}
}

template<typename T>
int SyncMap<T>::Size()
{
	int nElemNum = 0;
	for (int i = m_nBucketNum - 1; i >= 0; i--)
	{
		m_pAtoLock[i].Lock();
		nElemNum += m_pBucket[i].Size();
		m_pAtoLock[i].Unlock();
	}
	return nElemNum;
}

template<typename T>
void SyncMap<T>::PrintMap()
{
	int nCount = 0;
	for (int i = 0; i < m_nBucketNum; i++)
	{
		m_pAtoLock[i].Lock();
		int nSize = m_pBucket[i].Size();
		m_pAtoLock[i].Unlock();
		if (nSize > 0)
		{
			fprintf(stdout, "%d=>%d ", i, nSize);
			if (++nCount % 10 == 0)
			{
				fprintf(stdout, "\n");
			}
		}
	}
	fprintf(stdout, "\n");
}

#endif
