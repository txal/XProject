#ifndef __SLASHES_H__
#define __SLASHES_H__

static inline char*
AddSlashes(const char* pFrom, int nFromLen, char* pTo)
{
	char* pPos = pTo;
	const char* pBegin = pFrom;
	const char* pEnd = pFrom + nFromLen;
	while (pBegin < pEnd)
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
	return pTo;
}

static inline char*
StripSlashes(const char* pFrom, int nFromLen, char* pTo)
{
	char* pPos = pTo;
	const char* pBegin = pFrom;
	const char* pEnd = pFrom + nFromLen;
	while (pBegin < pEnd)
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
	return pTo;
}

#endif
