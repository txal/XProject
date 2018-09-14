#include "Common/DataStruct/Array.h"
#include "Common/LuaCommon/LuaSerialize.h"
#include "Include/Script/Script.hpp"

#define TYPE_NIL 0
#define TYPE_BOOLEAN 1
// hibits 0 false 1 true
#define TYPE_NUMBER 2
// hibits 0: 0 , 1:byte, 2:word, 4:dword,  8:double
#define TYPE_NUMBER_ZERO 0
#define TYPE_NUMBER_BYTE 1
#define TYPE_NUMBER_WORD 2
#define TYPE_NUMBER_DWORD 4
#define TYPE_NUMBER_QWORD 6
#define TYPE_NUMBER_REAL 8

#define TYPE_USERDATA 3
#define TYPE_SHORT_STRING 4
// hibits 0~31 : len
#define TYPE_LONG_STRING 5
#define TYPE_TABLE 6

#define MAX_COOKIE 32
#define COMBINE_TYPE(t,v) ((t) | (v) << 3)

#define BLOCK_SIZE 128
#define MAX_DEPTH 32                                                                                                                                                   

//buffer
static Array<uint8_t> _array;

template<typename T>
static inline void TWriteData(T val)
{
	int nNewSize = _array.Size() + sizeof(val);
	if (!_array.Reserve(nNewSize)) return;
	*(T*)(_array.Ptr()+_array.Size()) = val;
	_array.SetSize(nNewSize);
}
static inline void TWriteStr(const char* str, int len)
{
	int nNewSize = _array.Size() + len;
	if (!_array.Reserve(nNewSize)) return;
	memcpy(_array.Ptr() + _array.Size(), str, len);
	_array.SetSize(nNewSize);
}

//Pack
static inline void _PackInteger(lua_Integer nVal)
{
	if (nVal == 0)
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_NUMBER, TYPE_NUMBER_ZERO);
		TWriteData<uint8_t>(nCT);
	}
	else if (nVal != (int)nVal)
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_NUMBER, TYPE_NUMBER_QWORD);
		TWriteData<uint8_t>(nCT);
		TWriteData<int64_t>((int64_t)nVal);
	}
	else if (nVal < 0)
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_NUMBER, TYPE_NUMBER_DWORD);
		TWriteData<uint8_t>(nCT);
		TWriteData<int32_t>((int32_t)nVal);
	}
	else if (nVal < 0x100)
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_NUMBER, TYPE_NUMBER_BYTE);
		TWriteData<uint8_t>(nCT);
		TWriteData<uint8_t>((uint8_t)nVal);
	}
	else if (nVal < 0x10000)
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_NUMBER, TYPE_NUMBER_WORD);
		TWriteData<uint8_t>(nCT);
		TWriteData<uint16_t>((uint16_t)nVal);
	}
	else
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_NUMBER, TYPE_NUMBER_DWORD);
		TWriteData<uint8_t>(nCT);
		TWriteData<uint32_t>((uint32_t)nVal);
	}
}

static inline void _PackNumber(double fVal)
{
	uint8_t nCT = COMBINE_TYPE(TYPE_NUMBER, TYPE_NUMBER_REAL);
	TWriteData<uint8_t>(nCT);
	TWriteData<double>((double)fVal);
}

static inline void _PackString(const char* pStr, int nLen)
{
	if (nLen < MAX_COOKIE)
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_SHORT_STRING, nLen);
		TWriteData<uint8_t>(nCT);
		if (nLen > 0)
		{
			TWriteStr(pStr, nLen);
		}
	}
	else
	{
		uint8_t nCT;
		if (nLen < 0x10000)
		{
			nCT = COMBINE_TYPE(TYPE_LONG_STRING, 2);
			TWriteData<uint8_t>(nCT);
			TWriteData<uint16_t>((uint16_t)nLen);
		}
		else
		{
			nCT = COMBINE_TYPE(TYPE_LONG_STRING, 4);
			TWriteData<uint8_t>(nCT);
			TWriteData<uint32_t>((uint32_t)nLen);
		}
		TWriteStr(pStr, nLen);
	}
}

static void _PackTable(lua_State* L, int nIndex, int nDepth);
static inline void _PackOne(lua_State* L, int nIndex, int nDepth)
{
	if (nDepth > MAX_DEPTH)
	{
		LuaWrapper::luaM_error(L, "Serialize can't pack too depth table");
		return;
	}
	int nType = lua_type(L, nIndex);
	switch (nType)
	{
	case LUA_TNIL:
	{
		uint8_t nByte = TYPE_NIL;
		TWriteData<uint8_t>(nByte);
		break;
	}
	case LUA_TNUMBER:
	{
		if (lua_isinteger(L, nIndex))
		{
			lua_Integer nInt = lua_tointeger(L, nIndex);
			_PackInteger(nInt);
		}
		else
		{
			lua_Number fNum = lua_tonumber(L, nIndex);
			_PackNumber(fNum);
		}
		break;
	}
	case LUA_TBOOLEAN:
	{
		int nBool = lua_toboolean(L, nIndex);
		uint8_t nCT = COMBINE_TYPE(TYPE_BOOLEAN, nBool ? 1 : 0);
		TWriteData<uint8_t>(nCT);
		break;
	}
	case LUA_TSTRING:
	{
		size_t uLen = 0;
		const char* pStr = lua_tolstring(L, nIndex, &uLen);
		_PackString(pStr, (int)uLen);
		break;
	}
	case LUA_TTABLE:
	{
		_PackTable(L, nIndex, nDepth + 1);
		break;
	}
	default:
	{
		LuaWrapper::luaM_error(L, "Unsupport type %s to serialize", lua_typename(L, nType));
		break;
	}
	}
}

static inline void _PackTable(lua_State* L, int nIndex, int nDepth)
{
	if (nIndex < 0)
	{
		nIndex = lua_gettop(L) + nIndex + 1;
	}
	// array
	int nArraySize = (int)lua_rawlen(L, nIndex);
	if (nArraySize >= MAX_COOKIE - 1)
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_TABLE, MAX_COOKIE - 1);
		TWriteData<uint8_t>(nCT);
		_PackInteger(nArraySize);
	}
	else
	{
		uint8_t nCT = COMBINE_TYPE(TYPE_TABLE, nArraySize);
		TWriteData<uint8_t>(nCT);
	}
	for (int i = 1; i <= nArraySize; i++)
	{
		lua_rawgeti(L, nIndex, i);
		_PackOne(L, -1, nDepth);
		lua_pop(L, 1);
	}
	// hash
	lua_pushnil(L);
	while (lua_next(L, nIndex))
	{
		if (lua_type(L, -2) == LUA_TNUMBER)
		{
			if (lua_isinteger(L, -2))
			{
				lua_Integer nInt = lua_tointeger(L, -2);
				if (nInt > 0 && nInt <= nArraySize)
				{
					lua_pop(L, 1);
					continue;
				}
			}
		}
		_PackOne(L, -2, nDepth);
		_PackOne(L, -1, nDepth);
		lua_pop(L, 1);
	}
	uint8_t nByte = TYPE_NIL;
	TWriteData<uint8_t>(nByte);
}

static inline int LuaEncode(lua_State* L)
{
	_array.Clear();
	_PackOne(L, 1, 0);
	if (_array.Size() <= 0)
	{
		lua_pushstring(L, "");
	}
	else
	{
		lua_pushlstring(L, (const char*)_array.Ptr(), _array.Size());
	}
	return 1;
}

// Unpack
static inline void _InvalidPacket(lua_State* L, int nLine)
{
	LuaWrapper::luaM_error(L, "Invalid packet:%d\n", nLine);
}

template<typename T>
static inline void _ReadNumber(lua_State* L, const uint8_t*& pBuf, int& nSize, T& tVal, int nRead)
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

static inline void _ReadBuf(lua_State* L, const uint8_t*& pBuf, int& nSize, int nRead)
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

static inline lua_Integer _UnpackInteger(lua_State* L, const uint8_t*& pBuf, int& nSize, int nCookie)
{
	lua_Integer nValTar = 0;
	switch (nCookie)
	{
	case TYPE_NUMBER_ZERO:
	{
		nValTar = 0;
		break;
	}
	case TYPE_NUMBER_BYTE:
	{
		uint8_t nVal = 0;
		_ReadNumber(L, pBuf, nSize, nVal, (int)sizeof(nVal));
		nValTar = nVal;
		break;
	}
	case TYPE_NUMBER_WORD:
	{
		uint16_t nVal = 0;
		_ReadNumber(L, pBuf, nSize, nVal, (int)sizeof(nVal));
		nValTar = nVal;
		break;
	}
	case TYPE_NUMBER_DWORD:
	{
		int nVal = 0;
		_ReadNumber(L, pBuf, nSize, nVal, (int)sizeof(nVal));
		nValTar = nVal;
		break;
	}
	case TYPE_NUMBER_QWORD:
	{
		int64_t nVal = 0;
		_ReadNumber(L, pBuf, nSize, nVal, (int)sizeof(nVal));
		nValTar = nVal;
		break;
	}
	default:
	{
		_InvalidPacket(L, __LINE__);
		break;
	}
	}
	return nValTar;
}

static inline double _UnpackNumber(lua_State* L, const uint8_t*& pBuf, int& nSize, int nCookie)
{
	double fVal = 0.0;
	_ReadNumber(L, pBuf, nSize, fVal, sizeof(fVal));
	return fVal;
}

static inline void _UnpackString(lua_State* L, const uint8_t*& pBuf, int& nSize, int nType, int nCookie)
{
	if (nType == TYPE_SHORT_STRING)
	{
		_ReadBuf(L, pBuf, nSize, nCookie);
	}
	else
	{
		if (nCookie == 2)
		{
			uint16_t nLen = 0;
			_ReadNumber(L, pBuf, nSize, nLen, sizeof(nLen));
			_ReadBuf(L, pBuf, nSize, nLen);
		}
		else if (nCookie == 4)
		{
			uint32_t nLen = 0;
			_ReadNumber(L, pBuf, nSize, nLen, sizeof(nLen));
			_ReadBuf(L, pBuf, nSize, nLen);
		}
		else
		{
			_InvalidPacket(L, __LINE__);
			return;
		}
	}
}

static void _UnpackValue(lua_State* L, const uint8_t*& pBuf, int& nSize, int nType, int nCookie);
static inline void _UnpackOne(lua_State* L, const uint8_t*& pBuf, int& nSize)
{
	uint8_t nCT = 0;
	_ReadNumber(L, pBuf, nSize, nCT, (int)sizeof(nCT));
	int nType = nCT & 0x7;
	int nCookie = nCT >> 3;
	_UnpackValue(L, pBuf, nSize, nType, nCookie);
}

static void _UnpackTable(lua_State* L, const uint8_t*& pBuf, int& nSize, int nCookie)
{
	int nArraySize = nCookie;
	if (nArraySize == MAX_COOKIE - 1)
	{
		uint8_t nCT = 0;
		_ReadNumber(L, pBuf, nSize, nCT, (int)sizeof(nCT));
		if ((nCT & 0x7) != TYPE_NUMBER || (nCT >> 3) == TYPE_NUMBER_REAL)
		{
			_InvalidPacket(L, __LINE__);
			return;
		}
		nArraySize = (int)_UnpackInteger(L, pBuf, nSize, nCT >> 3);
	}
	lua_createtable(L, nArraySize, 0);
	for (int i = 1; i <= nArraySize; i++)
	{
		_UnpackOne(L, pBuf, nSize);
		lua_rawseti(L, -2, i);
	}
	for (;;)
	{
		_UnpackOne(L, pBuf, nSize);
		if (lua_isnil(L, -1))
		{
			lua_pop(L, 1);
			return;
		}
		_UnpackOne(L, pBuf, nSize);
		lua_rawset(L, -3);
	}
}

static inline void _UnpackValue(lua_State* L, const uint8_t*& pBuf, int& nSize, int nType, int nCookie)
{
	switch (nType)
	{
	case TYPE_NIL:
	{
		lua_pushnil(L);
		break;
	}
	case TYPE_BOOLEAN:
	{
		lua_pushboolean(L, nCookie);
		break;
	}
	case TYPE_NUMBER:
	{
		if (nCookie == TYPE_NUMBER_REAL)
		{
			double fVal = _UnpackNumber(L, pBuf, nSize, nCookie);
			lua_pushnumber(L, fVal);
		}
		else
		{
			lua_Integer nVal = _UnpackInteger(L, pBuf, nSize, nCookie);
			lua_pushinteger(L, nVal);
		}
		break;
	}
	case TYPE_SHORT_STRING:
	case TYPE_LONG_STRING:
	{
		_UnpackString(L, pBuf, nSize, nType, nCookie);
		break;
	}
	case TYPE_TABLE:
	{
		_UnpackTable(L, pBuf, nSize, nCookie);
		break;
	}
	default:
	{
		_InvalidPacket(L, __LINE__);
		break;
	}
	}
}

static inline int LuaDecode(lua_State* L)
{
	size_t nLen = 0;
	const char* pStr = luaL_checklstring(L, 1, &nLen);
	if (nLen <= 0)
	{
		return 0;
	}

	int nSize = (int)nLen;
	const uint8_t* pBuf = (const uint8_t*)pStr;

	lua_settop(L, 0);
	for (int i = 1; ; i++)
	{
		if (i % 16 == 0)
		{
			luaL_checkstack(L, i, "Lua stack out");
		}
		if (nSize <= 0)
		{
			break;
		}
		uint8_t nCT = 0;
		_ReadNumber(L, pBuf, nSize, nCT, (int)sizeof(nCT));
		int nType = nCT & 0x7;
		int nCookie = nCT >> 3;
		_UnpackValue(L, pBuf, nSize, nType, nCookie);
	}
	return lua_gettop(L);
}

// Register lua serialize
void RegLuaSerialize(const char* psTable)
{
	luaL_Reg aFuncList[] =
	{
		{ "encode", LuaEncode},
		{ "decode", LuaDecode},
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(aFuncList, psTable);
}

