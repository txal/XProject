#ifndef __XMATH_H__
#define __XMATH_H__

#include "Common/Platform.h"

#define MAX_INT_STR_LEN 32

namespace XMath
{
	template <typename T>
	inline T Max(T x, T y)
	{
		return (x >= y ? x : y);
	}

	template <typename T>
	inline T Min(T x, T y)
	{
		return (x <= y ? x : y);
	}

	inline void RandomSeed(uint32_t nSeed)
	{
		srand(nSeed);
		// Discard first value to avoid undesirable correlations
		NOTUSED(rand());
	}

	inline int Random(int nMin, int nMax)
	{
		assert(nMin <= nMax);
		double r = (double)(rand()%RAND_MAX) / (double)RAND_MAX;
		int nRnd = (int)(r*(nMax-nMin+1)) + nMin;
		return nRnd;
	}


	inline char* Int2Str(int64_t nVal, size_t& uLen)
	{
		static const char sDigits[11] = "0123456789";
		static char sVal[32];
		char* pPos = sVal + 31;
		*pPos = '\0';
		bool bNegative = nVal < 0;
		nVal = llabs(nVal);
		do
		{
			*--pPos = sDigits[nVal % 10];
			uLen++;
		} while (nVal /= 10);
		if (bNegative)
		{
			*--pPos = '-';
			uLen++;
		}
		return pPos;
	}
};

#endif