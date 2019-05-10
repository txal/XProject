#ifndef __MY_DEBUG_H__
#define __MY_DEBUG_H__

#include "Include/Logger/Logger.hpp"
#ifdef __linux
#include<execinfo.h>
#include<stdlib.h>
#include<stdio.h>
#endif

namespace NSCDebug
{

	static void TraceBack()
	{
#ifdef __linux
		void* sBuffer[64];
		int nPtrs = backtrace(sBuffer, 64);
		char** sStrings = backtrace_symbols(sBuffer, nPtrs);
		if (sStrings == NULL)
		{
			return;
		}
		XLog(LEVEL_ERROR, "traceback:\n");
		for (int k = 0; k < nPtrs; k++)
		{
			XLog(LEVEL_ERROR, "%s\n", sStrings[k]);
		}
		free(sStrings);
#endif
	}
}

#endif
