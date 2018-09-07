#ifndef __MINHEAP_H__
#define __MINHEAP_H__

/*
** T 必须是指针类型
*/

#include "Common/Platform.h"
#include "Include/Logger/Logger.h"

//初始容量
#define MINHEAP_DEF_CAP 16

//比较函数
typedef int (*MinHeapCmpFunc)(void*, void*);

template<typename T>
class MinHeap
{
public:
    MinHeap(MinHeapCmpFunc fnCmp);
    virtual ~MinHeap();

public:
    T Min();
    bool Push(const T& val);
    bool Remove(int nPos);
    bool Remove(const T& val);
	void Update(const T& val);
    int Size() { return m_nCount; }
	void Clear() { m_nCount = 0; }
	T& operator[](int nIdx)	{ return m_pHeap[nIdx]; }

protected:
    void BuildHeap();
    void FilterUp(int nIndex);
    void FilterDown(int nIndex);
    bool Expand();

private:
    T* m_pHeap;
    int m_nCount;
    int m_nHeapCap;
    MinHeapCmpFunc m_fnCmp;
    DISALLOW_COPY_AND_ASSIGN(MinHeap);
};

template<typename T>
MinHeap<T>::MinHeap(MinHeapCmpFunc fnCmp)
{
    m_fnCmp = fnCmp;
    m_nHeapCap = MINHEAP_DEF_CAP;
    m_pHeap = (T*)XALLOC(NULL, sizeof(T) * m_nHeapCap);
    memset(m_pHeap, 0, sizeof(T) * m_nHeapCap);
    m_nCount = 0;
}

template<typename T>
MinHeap<T>::~MinHeap()
{
    SAFE_FREE(m_pHeap)
    m_nCount = 0;
}

template<typename T>
bool MinHeap<T>::Expand()
{
   m_nHeapCap = m_nHeapCap * 2; 
   m_pHeap = (T*)XALLOC(m_pHeap, sizeof(T) * m_nHeapCap);
   if (m_pHeap == NULL)
   {
	   XLog(LEVEL_ERROR, "Memory out!\n");
	   return false;
   }
   return true;
}

template<typename T>
void MinHeap<T>::BuildHeap()
{
    for (int i = m_nCount / 2 - 1; i >= 0; i--)
    {
        FilterDown(i);
    }
}

template<typename T>
void MinHeap<T>::FilterUp(int nIndex)
{
	if (nIndex < 0 || nIndex >= m_nCount)
	{
		return;
	}
    int i = nIndex;
    int j = (i - 1) / 2;
    T tmp = m_pHeap[i];
    while (i > 0)
	{
        if (m_fnCmp(m_pHeap[j], tmp) <= 0)
        //if (m_pHeap[j]->nKey <= tmp->nKey)
        {
            break;
        }
        m_pHeap[i] = m_pHeap[j];
        i = j;
        j = (j - 1) / 2;
    }
    m_pHeap[i] = tmp;
}

template<typename T>
void MinHeap<T>::FilterDown(int nIndex)
{
	if (nIndex < 0 || nIndex >= m_nCount)
	{
		return;
	}
    int i = nIndex;
    int j = 2 * i + 1;
    T tmp = m_pHeap[i];
    while (j < m_nCount)
    {
        if (j < m_nCount - 1 && m_fnCmp(m_pHeap[j], m_pHeap[j + 1]) > 0)
        //if (j < m_nCount - 1 && m_pHeap[j]->nKey > m_pHeap[j + 1]->nKey)
        {
            j++;
        }
        if (m_fnCmp(m_pHeap[j], tmp) >= 0)
        //if (m_pHeap[j]->nKey >= tmp->nKey)
        {
            break;
        }
        m_pHeap[i] = m_pHeap[j];
        i = j;
        j = 2 * j + 1;
    }
    m_pHeap[i] = tmp;
}

template<typename T>
bool MinHeap<T>::Push(const T& val)
{
    if (m_nCount >= m_nHeapCap)
    {
        if (!Expand())
        {
            return false;
        }
    }
    m_pHeap[m_nCount++] = val;
    FilterUp(m_nCount - 1);
    return true;
}

template<typename T>
T MinHeap<T>::Min()
{
    if (m_nCount > 0)
    {
		assert(m_pHeap[0] != NULL);
        return m_pHeap[0];
    }
    else
    {
		return NULL;
    }
}

template<typename T>
bool MinHeap<T>::Remove(const T& val)
{
    int nPos = -1;
    for (int i = 0; i < m_nCount; i++)
    {
        if (m_pHeap[i] == val)
        {
            nPos = i;
            break;
        }
    }
    if (nPos < 0)
    {
		return false;
    }
    return Remove(nPos);
}

template<typename T>
bool MinHeap<T>::Remove(int nPos)
{
    if (nPos < 0 || nPos >= m_nCount)
    {
        return false;
    }
    m_pHeap[nPos] = m_pHeap[--m_nCount];
	m_pHeap[m_nCount] = NULL;
    FilterUp(nPos);
    FilterDown(nPos);
	return true;
}

template<typename T>
void MinHeap<T>::Update(const T& val)
{
	int nIdx = -1;
	for (int i = 0; i < m_nCount; i++)
	{
		if (m_pHeap[i] == val)
		{
			nIdx = i;
			break;
		}
	}
	if (nIdx < 0)
	{
		return;
	}
	FilterUp(nIdx);
	FilterDown(nIdx);
}

#endif
