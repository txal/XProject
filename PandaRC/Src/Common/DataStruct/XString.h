#ifndef __XSTRING_H__
#define __XSTRING_H__

#include "MemPool.h"

class XString : public CMemPool<XString>
{
	public:
		XString(const char*);
		XString(const char*, int);
		XString(const XString&);
		XString(const char);
		virtual ~XString();

	public:
		XString operator+(const XString&);
		XString& operator+=(const XString&);
		XString& operator=(const XString&);
		bool operator<(const XString&) const;
		bool operator==(const XString&) const;
		XString operator()(int, int) const;
		char &operator[](int);
		char operator[](int) const;

		void LTrim();
		void RTrim();
		void Trim();
		int GetLength() const;
public:
		static char* ToLower(char*);
		static char* ToUpper(char*);
        static char* AddSlashes(const char*pStr, int nLen, char* pBuf, int nBufSize);
        static char* StripSlashes(const char* pStr, int nLen, char* pBuf, int nBufSize);

	public:
		const char* c_str() const
		{
			return m_pStr;
		}

		bool operator!=(const XString& Right) const
		{ 
			return !(*this == Right); 
		}

		bool operator>(const XString& Right) const
		{ 
			return Right < *this; 
		}

		bool operator<=(const XString& Right) const
		{ 
			return !(Right < *this); 
		} 

		bool operator>=(const XString& Right) const
		{ 
			return !(*this < Right); 
		}

	protected:
		void SetXString(const char*, int);
		bool IsSpace(char);

	private:
		char* m_pStr;
		int m_nLength; 
}; 

#endif
