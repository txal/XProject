#ifndef __ENCODING_H__
#define __ENCODING_H__

#include "Common/Platform.h"

namespace Encoding
{
#ifdef __linux
	static inline int CodeConvert(const char* pFromCharset, const char* pToCharset, char* pInBuf, int nInLen, char* pOutBuf, int nOutLen)
	{
		char** pIn = &pInBuf;
		char** pOut = &pOutBuf;

		size_t stInLen = nInLen;
		size_t stOutLen = nOutLen;

		iconv_t ic = iconv_open(pToCharset, pFromCharset);
		if (ic == 0)
			return -1; 

		if (iconv(ic, pIn, &stInLen, pOut, &stOutLen) == (size_t)-1) 
		{   
			iconv_close(ic);
			return -1; 
		}   
		iconv_close(ic);
		return 0;
	}
#else
	static inline size_t WcToMb(char* pMbBuf, int nMbLen, const wchar_t* pWcStr)
	{
		setlocale(LC_ALL, "zh_CN.UTF-8");
		size_t szConverted = 0;
		return wcstombs_s(&szConverted, pMbBuf, nMbLen, pWcStr, _TRUNCATE);
		/*
		nMbLen = wcslen(pWcStr) + 1;
		pMbBuf = (char*)malloc(nMbLen * sizeof(char));
		*/
	}

	static inline size_t MbToWc(wchar_t* pWcBuf, const char* pMbStr, int nMbLen)
	{
		setlocale(LC_ALL, "zh_CN.UTF-8");
		size_t szConverted = 0;
		return mbstowcs_s(&szConverted, pWcBuf, nMbLen, pMbStr, _TRUNCATE);
		/*
		nMbLen = strlen(pMbStr) + 1;
		pWcBf = (wchar_t*)malloc(nMbLen * sizeof(wchar_t));
		*/
	}

	//GBK编码转换到UTF8编码
	static int GBKToUTF8(const char * lpGBKStr, char * lpUTF8Str, int nUTF8StrLen)
	{
		if (lpGBKStr == NULL)  //如果GBK字符串为NULL则出错退出
		{
			return 0;
		}
		int nRetLen = ::MultiByteToWideChar(CP_ACP, 0, (char *)lpGBKStr, -1, NULL, NULL);			//获取转换到Unicode编码后所需要的字符空间长度
		wchar_t* lpUnicodeStr = (wchar_t*)XALLOC(NULL, sizeof(wchar_t)*(nRetLen+1)); //为Unicode字符串空间
		nRetLen = ::MultiByteToWideChar(CP_ACP, 0, (char *)lpGBKStr, -1, lpUnicodeStr, nRetLen);	//转换到Unicode编码
		if (nRetLen == 0)  //转换失败则出错退出
		{
			return 0;
		}
		nRetLen = ::WideCharToMultiByte(CP_UTF8, 0, lpUnicodeStr, -1, NULL, 0, NULL, NULL);  //获取转换到UTF8编码后所需要的字符空间长度
		if (lpUTF8Str == NULL)  //输出缓冲区为空则返回转换后需要的空间大小
		{
			SAFE_FREE(lpUnicodeStr);
			return nRetLen;
		}
		if (nUTF8StrLen < nRetLen)  //如果输出缓冲区长度不够则退出
		{
			SAFE_FREE(lpUnicodeStr);
			return 0;
		}
		nRetLen = ::WideCharToMultiByte(CP_UTF8, 0, lpUnicodeStr, -1, (char *)lpUTF8Str, nUTF8StrLen, NULL, NULL);  //转换到UTF8编码
		SAFE_FREE(lpUnicodeStr);
		return nRetLen;
	}

	// UTF8编码转换到GBK编码
	static int UTF8ToGBK(const char * lpUTF8Str, char * lpGBKStr, int nGBKStrLen)
	{
		if (lpUTF8Str == NULL)  //如果UTF8字符串为NULL则出错退出
		{
			return 0;
		}
		int nRetLen = ::MultiByteToWideChar(CP_UTF8, 0, (char*)lpUTF8Str, -1, NULL, NULL);			//获取转换到Unicode编码后所需要的字符空间长度
		wchar_t* lpUnicodeStr = (wchar_t*)XALLOC(NULL, sizeof(wchar_t)*(nRetLen+1));
		nRetLen = ::MultiByteToWideChar(CP_UTF8, 0, (char *)lpUTF8Str, -1, lpUnicodeStr, nRetLen);  //转换到Unicode编码
		if (nRetLen == 0)  //转换失败则出错退出
		{
			SAFE_FREE(lpUnicodeStr);
			return 0;
		}
		nRetLen = ::WideCharToMultiByte(CP_ACP, 0, lpUnicodeStr, -1, NULL, NULL, NULL, NULL);		//获取转换到GBK编码后所需要的字符空间长度
		if (lpGBKStr == NULL)  //输出缓冲区为空则返回转换后需要的空间大小
		{
			SAFE_FREE(lpUnicodeStr)
			return nRetLen;
		}
		if (nGBKStrLen < nRetLen)  //如果输出缓冲区长度不够则退出
		{
			SAFE_FREE(lpUnicodeStr);
			return 0;
		}
		nRetLen = ::WideCharToMultiByte(CP_ACP, 0, lpUnicodeStr, -1, (char *)lpGBKStr, nRetLen, NULL, NULL);  //转换到GBK编码
		SAFE_FREE(lpUnicodeStr);
		return nRetLen;
	}


#endif
};

#endif
