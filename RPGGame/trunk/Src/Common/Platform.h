#ifndef __PLATFORM_FN_H__
#define __PLATFORM_FN_H__

#include "Common/PlatformHeader.h"
#include "Common/DataStruct/Encoding.h"

namespace Platform
{
	inline const char* GetWorkDir(char* pBuf, int nLen)
	{
#if defined(_WIN32)
		GetCurrentDirectory(nLen, pBuf);
		return pBuf;
#else
		return getcwd(pBuf, nLen); 
		return pBuf;
#endif
	}

	inline bool FileExist(const char* psFile)
	{
		FILE* poFile = fopen(psFile, "r");
		if (poFile != NULL)
		{
			fclose(poFile);
			return true;
		}
		return false;
	}

	//取CPU核心数
	inline int GetCpuCoreNum()
	{
#if defined(WIN32)
		SYSTEM_INFO info;
		GetSystemInfo(&info);
		return info.dwNumberOfProcessors;
#elif defined(__linux)
		return get_nprocs();   //GNU fuction
#else
		return 1;
#endif
	}

#ifdef _WIN32
	inline const char* LastErrorStr(int nLastErrCode)
	{
		// Retrieve the system error message for the last-error code
		static char sMsgBuf[1024];
		memset(sMsgBuf, 0, sizeof(sMsgBuf));
		LPVOID lpMsgBuf = NULL;
		int nLen = FormatMessage(
			FORMAT_MESSAGE_ALLOCATE_BUFFER | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
			NULL,
			nLastErrCode,
			MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
			(LPTSTR)&lpMsgBuf,
			0, NULL);
		if (nLen > 0)
		{
			Encoding::GBKToUTF8((char*)lpMsgBuf, sMsgBuf, sizeof(sMsgBuf));
		}
		if (lpMsgBuf != NULL)
		{
			LocalFree(lpMsgBuf);
		}
		return sMsgBuf;
	}

	inline LONG WINAPI MyUnhandledFilter(struct _EXCEPTION_POINTERS* lpExceptionInfo)
	{
		LONG ret = EXCEPTION_EXECUTE_HANDLER;
		TCHAR szFileName[64];
		SYSTEMTIME st;
		::GetLocalTime(&st);

		TCHAR szFileFullPath[256];
		::GetModuleFileName(NULL, static_cast<LPTSTR>(szFileFullPath), 256);
		std::string szProcessName(szFileFullPath);
		int nPos = (int)szProcessName.rfind('\\');
		szProcessName = szProcessName.substr(nPos + 1);
		wsprintf(szFileName, TEXT("%s-%d-%02d-%02d-%02d-%02d-%02d.dmp"), szProcessName.c_str(), st.wYear, st.wMonth, st.wDay, st.wHour, st.wMinute, st.wSecond);

		HANDLE hFile = ::CreateFile(szFileName, GENERIC_WRITE, 0, NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);
		if (hFile != INVALID_HANDLE_VALUE)
		{
			MINIDUMP_EXCEPTION_INFORMATION ExInfo;
			ExInfo.ThreadId = ::GetCurrentThreadId();
			ExInfo.ExceptionPointers = lpExceptionInfo;
			ExInfo.ClientPointers = false;
			// write the dump
			BOOL bOK = MiniDumpWriteDump(GetCurrentProcess(), GetCurrentProcessId(), hFile, MiniDumpNormal, &ExInfo, NULL, NULL);
			if (bOK)
			{
				printf("Create Dump File Success!\n");
			}
			else
			{
				printf("MiniDumpWriteDump Failed: %d\n", GetLastError());
			}
			::CloseHandle(hFile);
		}
		else
		{
			printf("Create File %s Failed %d\n", szFileName, GetLastError());
		}
		return ret;
	}
#endif
};

#endif
