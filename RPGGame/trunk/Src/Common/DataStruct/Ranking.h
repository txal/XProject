#ifndef __RANKING_H__
#define __RANKING_H__

#include "Common/Platform.h"
#include "Common/DataStruct/Array.h"

typedef int(*_fnCompare)(void* pData1, void* pData2);
typedef void(*_fnTraverse)(int nRank, void* pData, void* pContext);

template<class T>
class Ranking
{
public:
	typedef std::unordered_map<int64_t, int> RankMap;
	typedef RankMap::iterator RankIter;

public:
	Ranking(_fnCompare fnComparator = NULL)
	{
		m_nTotalDmg = 0;
		m_fnComparator = fnComparator;
	}

	~Ranking()
	{
		Clear();
	}

	int InsertData(int64_t llID, T& data)
	{
		RankIter iter = m_oRankMap.find(llID);
		if (iter != m_oRankMap.end())
		{
			return -1;
		}
		int nCurrIndex = m_oRankList.Size();
		m_oRankList.PushBack(data);
		m_oRankMap[llID] = nCurrIndex;
		return Reranking(nCurrIndex, data);
	}

	int UpdateData(int64_t llID)
	{
		RankIter iter = m_oRankMap.find(llID);
		if (iter == m_oRankMap.end())
		{
			return -1;
		}
		int nCurrIndex = iter->second;
		T data = m_oRankList[nCurrIndex];
		return Reranking(nCurrIndex, data);
	}

	//nStart > 0, nEnd >= nStart
	int Traverse(int nStart, int nEnd, _fnTraverse fnCallback, void* pContext)
	{
		assert(nEnd >= nStart && nStart > 0);
		int nCount = m_oRankList.Size();

		int nTraverseCount = 0;
		T* pDataList = m_oRankList.Ptr();
		for (int i = nStart - 1; i < nEnd && i < nCount; ++i)
		{
			fnCallback(i + 1, &pDataList[i], pContext);
			++nTraverseCount;
		}
		return nTraverseCount;
	}

	T* GetDataByID(int64_t llID, int* pnRank = NULL)
	{
		RankIter iter = m_oRankMap.find(llID);
		if (iter != m_oRankMap.end())
		{
			if (pnRank != NULL)
			{
				*pnRank = iter->second + 1;
			}
			return &m_oRankList[iter->second];
		}
		return NULL;
	}

	//nRank > 0
	T* GetDataByRank(int nRank)
	{
		assert(nRank > 0);
		int nCount = m_oRankList.Size();
		if (nRank > 0 && nRank <= nCount)
		{
			return &m_oRankList[nRank - 1];
		}
		return NULL;
	}

	void Clear()
	{
		m_oRankMap.clear();
		m_oRankList.Clear();
	}

	int Size() { return m_oRankList.Size(); }
	int& GetTotalDmg() { return m_nTotalDmg;  }

private:
	int Reranking(int nRank, T& data)
	{
		int nOldRank = nRank;
		while (nRank > 0)
		{
			T& tmp = m_oRankList[nRank-1];
			if ((*m_fnComparator)(&tmp, &data) >= 0)
			{
				break;
			}
			--nRank;
		}

		if (nOldRank == nRank)
		{
			int nMaxRank = m_oRankList.Size() - 1;
			while (nRank < nMaxRank)
			{
				T& tmp = m_oRankList[nRank + 1];
				if ((*m_fnComparator)(&tmp, &data) <= 0)
				{
					break;
				}
				++nRank;
			}
		}

		if (nOldRank != nRank)
		{
			RankIter iter;
			RankIter iter_end = m_oRankMap.end();
			T* pDataList = m_oRankList.Ptr();
			if (nOldRank > nRank)
			{
				memmove(pDataList + nRank + 1, pDataList + nRank, (nOldRank - nRank) * sizeof(pDataList[0]));
				for (int i = nRank + 1; i <= nOldRank; ++i)
				{
					iter = m_oRankMap.find(pDataList[i].llID);
					if (iter != iter_end)
					{
						++iter->second;
					}
				}
			}
			else
			{
				memmove(pDataList + nOldRank, pDataList + nOldRank + 1, (nRank - nOldRank) * sizeof(pDataList[0]));
				for (int i = nOldRank; i < nRank; ++i)
				{
					iter = m_oRankMap.find(pDataList[i].llID);
					if (iter != iter_end)
					{
						--iter->second;
					}
				}
			}
			pDataList[nRank] = data;
			iter = m_oRankMap.find(data.llID);
			if (iter != iter_end)
			{
				iter->second = nRank;
			}
		}
		return nRank;
	}


private:
	int m_nTotalDmg;
	RankMap m_oRankMap;
	Array<T> m_oRankList;
	_fnCompare m_fnComparator;
};

#endif