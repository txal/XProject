#ifndef __LUA_SERIALIZE_H__
#define __LUA_SERIALIZE_H__

#include "Common/DataStruct/Array.h"
#include "Include/Script/Script.hpp"

class LuaSerialize
{
public:
	LuaSerialize() {}
	~LuaSerialize() {} 

	//Pack
	void _PackInteger(lua_Integer nVal);
	void _PackNumber(double fVal);
	void _PackString(const char* pStr, int nLen);
	void _PackOne(lua_State* L, int nIndex, int nDepth);
	void _PackTable(lua_State* L, int nIndex, int nDepth);
	// Unpack
	lua_Integer _UnpackInteger(lua_State* L, const uint8_t*& pBuf, int& nSize, int nCookie);
	void _UnpackString(lua_State* L, const uint8_t*& pBuf, int& nSize, int nType, int nCookie);
	void _UnpackOne(lua_State* L, const uint8_t*& pBuf, int& nSize);
	void _UnpackTable(lua_State* L, const uint8_t*& pBuf, int& nSize, int nCookie);
	void _UnpackValue(lua_State* L, const uint8_t*& pBuf, int& nSize, int nType, int nCookie);

	template<typename T>
	void _ReadNumber(lua_State* L, const uint8_t*& pBuf, int& nSize, T& tVal, int nRead)
	{
		if (nSize < nRead)
		{
			_InvalidPacket(L, __LINE__);
			return;
		}
		tVal = *(T*)pBuf;
		pBuf += nRead;
		nSize -= nRead;
	}

	Array<uint8_t>* GetByteArray() { return &m_array; }

protected:
	void _InvalidPacket(lua_State* L, int nLine)
	{
		LuaWrapper::luaM_error(L, "Invalid packet:%d\n", nLine);
	}
	template<typename T>
	void TWriteData(T val)
	{
		int nNewSize = m_array.Size() + sizeof(val);
		if (!m_array.Reserve(nNewSize)) return;
		*(T*)(m_array.Ptr()+m_array.Size()) = val;
		m_array.SetSize(nNewSize);
	}
	void TWriteStr(const char* str, int len)
	{
		int nNewSize = m_array.Size() + len;
		if (!m_array.Reserve(nNewSize)) return;
		memcpy(m_array.Ptr() + m_array.Size(), str, len);
		m_array.SetSize(nNewSize);
	}
	void _ReadBuf(lua_State* L, const uint8_t*& pBuf, int& nSize, int nRead)
	{
		if (nSize < nRead)
		{
			_InvalidPacket(L, __LINE__);
			return;
		}
		lua_pushlstring(L, (char*)pBuf, nRead);
		pBuf += nRead;
		nSize -= nRead;
	}
	// Unpack
	double _UnpackNumber(lua_State* L, const uint8_t*& pBuf, int& nSize, int nCookie)
	{
		double fVal = 0.0;
		_ReadNumber(L, pBuf, nSize, fVal, sizeof(fVal));
		return fVal;
	}

private:
	Array<uint8_t> m_array;
};


void RegLuaSerialize(const char* psTable);

#endif
