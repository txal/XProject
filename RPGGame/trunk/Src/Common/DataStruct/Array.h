// 缓存指针,结构体,内部数据类型,自动扩容(自动扩容)
#ifndef __Array_H__
#define __Array_H__

#include "Common/Platform.h"
#include "Include/Logger/Logger.h"

#define DCR_DEF_CAP 8

template<class T>
class Array
{
public:
	Array();
	~Array();

	void PushBack(const T& Val);
	T& operator[](int nIndex);

	void Clear();
	bool Reserve(int nCap);

	T* Ptr()	{ return m_pData; }
	int Size()	{ return m_nSize;  }
	void SetSize(int nSize);

protected:
	bool Expand();

private:
	int m_nCap;
	int m_nSize;
	T* m_pData;
	DISALLOW_COPY_AND_ASSIGN(Array);
};

template<class T>
Array<T>::Array()
{
	m_nCap = DCR_DEF_CAP;
	m_nSize = 0;
	m_pData = (T*)XALLOC(NULL, sizeof(T) * m_nCap);
}

template<class T>
Array<T>::~Array()
{
	SAFE_FREE(m_pData);
}

template<class T>
bool Array<T>::Reserve(int nCap)
{
	while (m_nCap < nCap)
	{
		if (!Expand())
		{
			return false;
		}
	}
	return true;
}

template<class T>
bool Array<T>::Expand()
{
	int nNewCap = m_nCap * 2;
	T* pNewData = (T*)XALLOC(m_pData, sizeof(T) * nNewCap);
	if (pNewData == NULL)
	{
		XLog(LEVEL_ERROR, "Memory out!\n");
		return false;
	}
	m_nCap = nNewCap;
	m_pData = pNewData;
	return true;
}

template<class T>
void Array<T>::PushBack(const T& Val)
{
	if (m_nSize >= m_nCap)
	{
		if (!Expand())
		{
			return;
		}
	}
	m_pData[m_nSize++] = Val;
}

template<class T>
T& Array<T>::operator[](int nIndex)
{
	assert(nIndex >= 0 && nIndex < m_nSize);
	return m_pData[nIndex];
}

template<class T>
void Array<T>::Clear()
{
	m_nSize = 0;
}

template<class T>
void Array<T>::SetSize(int nSize)
{
	m_nSize = nSize;
	Reserve(m_nSize);
}

#endif