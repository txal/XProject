#include "XString.h"

#include <stdio.h>
#include <ctype.h>

XString::XString(const char* pStr)
{
	m_pStr = NULL;
	m_nLength = 0;
	int nLen = pStr != NULL ? (int)strlen(pStr) : 0;
	SetXString(pStr, nLen);
}

XString::XString(const XString& Copy)
{
	m_pStr = NULL;
	m_nLength = 0;
	SetXString(Copy.m_pStr, Copy.m_nLength);
}

XString::XString(const char Chr)
{
	m_pStr = NULL;
	m_nLength = 0;
	int nLen = Chr == '\0' ? 0 : 1;
	SetXString(&Chr, nLen);
}

/* Support binary pString */
XString::XString(const char* pStr, int nLen)
{
	m_pStr = NULL;
	m_nLength = 0;
	nLen < 0 ? (nLen = 0) : 0;
	SetXString(pStr, nLen);
}

XString::~XString()
{
	if (m_pStr != NULL)
		alloc::deallocate(m_pStr, m_nLength + 1);
	m_pStr = NULL;
	m_nLength = 0;
} 

/* Function called by conpStructors and operator= */
void XString::SetXString(const char *pStr, int nLen)
{
	if (pStr == NULL) 
		return;
	if (m_pStr != NULL)
	{
		alloc::deallocate(m_pStr, m_nLength + 1); 
		m_pStr = NULL;
		m_nLength = 0;
	}
	m_pStr = (char*)alloc::allocate(nLen + 1); 
	if (m_pStr != NULL)
	{
		memcpy(m_pStr, pStr, nLen);
		m_pStr[nLen] = '\0'; 
		m_nLength = nLen;
	}
}

bool XString::IsSpace(char Chr)
{
	bool bRes = (Chr == ' ' || Chr == '\f' || Chr == '\n'
			|| Chr == '\r' || Chr == '\t' || Chr =='\v');
	return  bRes;
}

XString& XString::operator=(const XString& Right)
{
	/* Avoid self assignment */
	if (&Right != this)
	{
		/* Prevents memory leak */
		alloc::deallocate(m_pStr, m_nLength + 1);
		m_pStr = NULL;
		m_nLength = 0;
		SetXString(Right.m_pStr, Right.m_nLength);
	} 
	return *this; 
} 

XString XString::operator+(const XString& Right)
{
	int nNewnLength = m_nLength + Right.m_nLength; 
	char* pTmp = (char*)alloc::allocate(nNewnLength);
	memcpy(pTmp, m_pStr, m_nLength); 
	memcpy(pTmp + m_nLength, Right.m_pStr, Right.m_nLength);
	XString TmpObj(pTmp, nNewnLength);
	alloc::deallocate(pTmp, nNewnLength);
	return TmpObj;
}

XString& XString::operator+=(const XString& Right)
{
	*this = *this + Right;
	return *this; 
}

bool XString::operator==(const XString& Right) const
{ 
	return strcmp(m_pStr, Right.m_pStr) == 0; 
}

bool XString::operator<(const XString& Right) const
{ 
	return strcmp(m_pStr, Right.m_pStr) < 0; 
}

char &XString::operator[](int nIndex)
{
	if (nIndex < 0 || nIndex >= m_nLength)
	{
		fprintf(stderr, "string nIndex invalid\n");
		exit(1);
	}
	return m_pStr[nIndex];
}

char XString::operator[](int nIndex) const
{
	if (nIndex < 0 || nIndex >= m_nLength)
	{
		fprintf(stderr, "string nIndex invalid\n");
		exit(1);
	}
	return m_pStr[nIndex]; 
}

XString XString::operator()(int nIndex, int nLength) const
{
	if (nIndex < 0 || nIndex >= m_nLength || nLength < 0)
		return "";
	int nLen = 0;
	if (nLength == 0 || nIndex + nLength > m_nLength) 
		nLen = m_nLength - nIndex;
	else
		nLen = nLength;
	char* pTmp = (char*)alloc::allocate(nLen);
	memcpy(pTmp, &m_pStr[nIndex], nLen);
	XString TmpObj(pTmp, nLen);
	alloc::deallocate(pTmp, nLen);
	return TmpObj;
} 

int XString::GetLength() const
{ 
	return m_nLength; 
}

void XString::LTrim()
{
	int nIndex = 0;
	while (nIndex < m_nLength && IsSpace(m_pStr[nIndex]))
		nIndex++;
	if (nIndex == 0)
		return; 
	int nLength	= m_nLength - nIndex; 
	char *pTmp = (char*)alloc::allocate(nLength + 1);
	memcpy(pTmp, &m_pStr[nIndex], nLength);
	pTmp[nLength] = '\0';
	alloc::deallocate(m_pStr, m_nLength + 1);
	m_pStr = pTmp;
	m_nLength = nLength;
}

void XString::RTrim()
{
	if (m_nLength == 0)
		return;
	int nSpace = 0;
	int nIndex = m_nLength - 1;
	while (nIndex >= 0 && IsSpace(m_pStr[nIndex]))
	{
		nIndex--;
		nSpace++;
	}
	if (nSpace == 0)
		return;
	int nLength	= m_nLength - nSpace;
	char* pTmp	= (char*)alloc::allocate(nLength + 1);
	memcpy(pTmp, m_pStr, nLength);
	pTmp[nLength] = '\0';
	alloc::deallocate(m_pStr, m_nLength + 1);
	m_pStr = pTmp;
	m_nLength = nLength;
}

void XString::Trim()
{
	LTrim();
	RTrim();
}

char* XString::ToLower(char* pStr)
{
	if (pStr == NULL)
		return pStr;
	char* pTmp = pStr;
	while (*pTmp != '\0')
	{
		*pTmp = (char)tolower(*pTmp);
		pTmp++;
	}
	return pStr;
}

char* XString::ToUpper(char* pStr)
{
	if (pStr == NULL)
		return pStr;
	char* pTmp = pStr;
	while (*pTmp != '\0') 
	{
		*pTmp = (char)toupper(*pTmp);
		pTmp++;
	}
	return pStr;
}

char* XString::AddSlashes(const char*pStr, int nLen, char* pBuf, int nBufSize)
{
	char* pPos = pBuf;
    char* pBufEnd = pBuf + nBufSize - 1;
	const char* pBegin = pStr;
	const char* pEnd = pStr+ nLen;
	while (pBegin < pEnd && pBuf < pBufEnd)
	{
		switch (*pBegin)
		{
			case '\0':
			{
				*pPos++ = '\\';
				*pPos++ = '0';
				break;
			}
			case '\'':
			case '\"':
			case '\\':
			{
				*pPos++ = '\\';
			}
			default:
			{
				*pPos++ = *pBegin;
				break;
			}
		}
		pBegin++;
	}
	*pPos = '\0';
	return pBuf;
}

char* XString::StripSlashes(const char* pStr, int nLen, char* pBuf, int nBufSize)
{
	char* pPos = pBuf;
    char* pBufEnd = pBuf + nBufSize - 1;
	const char* pBegin = pStr;
	const char* pEnd = pStr+ nLen;
	while (pBegin < pEnd && pPos < pBufEnd)
	{
		if (*pBegin == '\\')
		{
			switch (*(pBegin + 1))
			{
				case '0':
				{
					*pPos++ = '\0';
					pBegin++;
					break;
				}
				case '\'':
				case '\"':
				case '\\':
				{
					*pPos++ = *(++pBegin);
					break;
				}
				default:
				{
					*pPos++ = *pBegin;
					break;
				}
			}
		} else
			*pPos++ = *pBegin;
		pBegin++;
	}
	*pPos = '\0';
	return pBuf;
}
