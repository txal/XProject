#ifndef __PROPERTY_VARIANT_H__
#define __PROPERTY_VARIANT_H__

#include "Common/Platform.h"

#ifndef IsNAN
#define IsNAN(x) (x != x)
#endif

//原子数据类型定义
enum VariantType
{
	vNULL,
	vBOOL,
	vSMALL,
	vBYTE,
	vSHORT,
	vUSHORT,
	vINT,
	vUINT,
	vFLOAT,
	vDOUBLE,
	vSTRING,
	vOBJECT,
};

//属性值变量
class Variant
{
public:
	VariantType type;
	union
	{
		bool b;
		int n;
		unsigned int u;
		double d;
	};
	std::string s;
public:
	Variant()
	{
		type = vNULL;
		d = 0;
	}
	Variant(const Variant& b)
	{
		type = vNULL;
		d = 0;
		operator = (b);
	}
	~Variant()
	{
		clear();
	}
	inline Variant& clear()
	{
		d = 0;
		type = vNULL;
		s.clear();
		return *this;
	}
	inline Variant& operator = (const Variant &b)
	{
		clear();
		type = b.type;
		switch (type)
		{
			case vBOOL:
				this->b = b.b;
				break;
			case vSMALL:
			case vSHORT:
			case vINT:
				n = b.n;
				break;
			case vBYTE:
			case vUSHORT:
			case vUINT:
				u = b.u;
				break;
			case vFLOAT:
			case vDOUBLE:
				d = b.d;
				break;
			case vSTRING:
				s = b.s;
				break;
			default:
				break;
		}
		return *this;
	}
	inline operator bool() const
	{
		if (type == vSTRING)
			return s.compare("true") == 0 ? true : false;
		return d != 0;
	}
	inline Variant& operator = (bool v)
	{
		clear();
		type = vBOOL;
		b = v;
		return *this;
	}
	inline operator char() const
	{
		if (type == vBOOL)
			return (char)b;
		if (type == vSMALL || type == vSHORT || type == vINT)
			return (char)n;
		if (type == vBYTE || type == vUSHORT || type == vUINT)
			return (char)u;
		if (type == vFLOAT || type == vDOUBLE)
			return (char)d;
		if (type == vSTRING)
			return (char)atoi(s.c_str());
		return 0;
	}
	inline Variant& operator = (char v)
	{
		clear();
		type = vSMALL;
		n = v;
		return *this;
	}
	inline operator unsigned char() const
	{
		if (type == vBOOL)
			return (unsigned char)b;
		if (type == vSMALL || type == vSHORT || type == vINT)
			return (unsigned char)n;
		if (type == vBYTE || type == vUSHORT || type == vUINT)
			return (unsigned char)u;
		if (type == vFLOAT || type == vDOUBLE)
			return (unsigned char)d;
		if (type == vSTRING)
			return (unsigned char)atoi(s.c_str());
		return 0;
	}
	inline Variant& operator = (unsigned char v)
	{
		clear();
		type = vBYTE;
		u = v;
		return *this;
	}
	inline operator short() const
	{
		if (type == vBOOL)
			return (short)b;
		if (type == vSMALL || type == vSHORT || type == vINT)
			return (short)n;
		if (type == vBYTE || type == vUSHORT || type == vUINT)
			return (short)u;
		if (type == vFLOAT || type == vDOUBLE)
			return (short)d;
		if (type == vSTRING)
			return (short)atoi(s.c_str());
		return 0;
	}
	inline Variant& operator = (short v)
	{
		clear();
		type = vSHORT;
		n = v;
		return *this;
	}
	inline operator unsigned short() const
	{
		if (type == vBOOL)
			return (unsigned short)b;
		if (type == vSMALL || type == vSHORT || type == vINT)
			return (unsigned short)n;
		if (type == vBYTE || type == vUSHORT || type == vUINT)
			return (unsigned short)u;
		if (type == vFLOAT || type == vDOUBLE)
			return (unsigned short)d;
		if (type == vSTRING)
			return (unsigned short)atoi(s.c_str());
		return 0;
	}
	inline Variant& operator = (unsigned short v)
	{
		clear();
		type = vUSHORT;
		u = v;
		return *this;
	}
	inline operator int() const
	{
		if (type == vBOOL)
			return (int)b;
		if (type == vSMALL || type == vSHORT || type == vINT)
			return (int)n;
		if (type == vBYTE || type == vUSHORT || type == vUINT)
			return (int)u;
		if (type == vFLOAT || type == vDOUBLE)
			return (int)d;
		if (type == vSTRING)
			return (int)atoi(s.c_str());
		return 0;
	}
	inline Variant& operator = (int v)
	{
		clear();
		type = vINT;
		n = v;
		return *this;
	}
	inline operator unsigned int() const
	{
		if (type == vBOOL)
			return (unsigned int)b;
		if (type == vSMALL || type == vSHORT || type == vINT)
			return (unsigned int)n;
		if (type == vBYTE || type == vUSHORT || type == vUINT)
			return (unsigned int)u;
		if (type == vFLOAT || type == vDOUBLE)
			return (unsigned int)d;
		if (type == vSTRING)
			return (unsigned int)atoi(s.c_str());
		return 0;
	}
	inline Variant& operator = (unsigned int v)
	{
		clear();
		type = vUINT;
		u = v;
		return *this;
	}
	inline operator float() const
	{
		if (type == vBOOL)
			return b ? (float)1 : 0;
		if (type == vSMALL || type == vSHORT || type == vINT)
			return (float)n;
		if (type == vBYTE || type == vUSHORT || type == vUINT)
			return (float)u;
		if (type == vFLOAT || type == vDOUBLE)
			return (float)d;
		if (type == vSTRING)
			return (float)atoi(s.c_str());
		return 0;
	}
	inline Variant& operator = (float v)
	{
		clear();
		type = vFLOAT;
		d = v;
		return *this;
	}
	inline operator double() const
	{
		if (type == vBOOL)
			return b ? 1 : 0;
		if (type == vSMALL || type == vSHORT || type == vINT)
			return (double)n;
		if (type == vBYTE || type == vUSHORT || type == vUINT)
			return (double)u;
		if (type == vFLOAT || type == vDOUBLE)
			return (double)d;
		if (type == vSTRING)
			return (double)atof(s.c_str());
		return 0;
	}
	inline Variant& operator = (double v)
	{
		clear();
		type = vDOUBLE;
		d = v;
		return *this;
	}
	inline operator const char* () const
	{
		static char sBuf[64];
#ifdef _WIN32
#pragma warning(push)
#pragma warning(disable:4996)
#endif
		if (type == vBOOL)
		{
			strcpy(sBuf, b ? "true" : "false");
			return sBuf;
		}
		if (type == vSMALL || type == vSHORT || type == vINT)
		{
			sprintf(sBuf, "%d", n);
			return sBuf;
		}
		if (type == vBYTE || type == vUSHORT || type == vUINT)
		{
			sprintf(sBuf, "%u", u);
			return sBuf;
		}
		if (type == vFLOAT || type == vDOUBLE)
		{
			if (IsNAN(d))
				strcpy(sBuf, "");
			else sprintf(sBuf, "%lf", d);
			return sBuf;
		}
		if (type == vSTRING)
		{
			return s.c_str();
		}
		sBuf[0] = 0;
		return sBuf;
#ifdef _WIN32
#pragma warning(pop)
#endif
	}
	inline operator std::string() const
	{
		if (type == vSTRING)
			return s;
		const char *v = operator const char* ();
		return std::string(v);
	}
	inline Variant& operator = (const char *v)
	{
		clear();
		type = vSTRING;
		s = v;
		return *this;
	}
	inline Variant& operator = (const std::string& v)
	{
		clear();
		type = vSTRING;
		s = v;
		return *this;
	}
	inline bool operator == (const Variant &another) const
	{
		static const std::string trueString("true");

		switch (type)
		{
			case vNULL: return another.type == vNULL;
				break;
			case vBOOL:
				switch (another.type)
				{
					case vBOOL: return b == another.b; break;
					case vSMALL:
					case vBYTE:
					case vSHORT:
					case vUSHORT:
					case vINT:
					case vUINT: return b == (another.n != 0); break;
					case vFLOAT:
					case vDOUBLE: return b == (another.d != 0); break;
					case vSTRING: return b == (s.compare(trueString) == 0); break;
					default: return false; break;
				}
				break;
			case vSMALL:
			case vSHORT:
			case vINT:
				switch (another.type)
				{
					case vBOOL: return (n != 0) == another.b; break;
					case vSMALL:
					case vSHORT:
					case vINT: return n == another.n; break;
					case vBYTE:
					case vUSHORT:
					case vUINT: return n == (int)another.u; break;
					case vFLOAT:
					case vDOUBLE: return (double)n == another.d; break;
					case vSTRING: return n == atoi(another.s.c_str()); break;
					default: return false; break;
				}
				break;
			case vBYTE:
			case vUSHORT:
			case vUINT:
				switch (another.type)
				{
					case vBOOL: return (u != 0) == another.b; break;
					case vSMALL:
					case vSHORT:
					case vINT: return u == (unsigned int)another.n; break;
					case vBYTE:
					case vUSHORT:
					case vUINT: return u == another.u; break;
					case vFLOAT:
					case vDOUBLE: return (double)u == another.d; break;
					case vSTRING: return u == atoll(another.s.c_str()); break;
					default: return false; break;
				}
				break;
			case vFLOAT:
			case vDOUBLE:
				switch (another.type)
				{
					case vBOOL: return (d != 0) == another.b; break;
					case vSMALL:
					case vSHORT:
					case vINT: return d == (double)another.n; break;
					case vBYTE:
					case vUSHORT:
					case vUINT: return d == (double)another.u; break;
					case vFLOAT:
					case vDOUBLE: return d == another.d; break;
					case vSTRING: return d == atof(another.s.c_str()); break;
					default: return false; break;
				}
				break;
			case vSTRING:
				switch (another.type)
				{
					case vSMALL:
					case vSHORT:
					case vINT: return atoi(s.c_str()) == another.n; break;
					case vBYTE:
					case vUSHORT:
					case vUINT: return atoll(s.c_str()) == another.u; break;
					case vFLOAT:
					case vDOUBLE: return atof(s.c_str()) == another.d; break;
					case vSTRING: return s == another.s; break;
					default: return false; break;
				}
				break;
			case vOBJECT:
				//switch (another.type)
				//{
				//	case vOBJECT: return obj == another.obj; break;
				//}
				break;
			default:
				break;
		}
		return false;
	}
	inline bool operator != (const Variant &another) const
	{
		return !(operator == (another));
	}
};

#endif