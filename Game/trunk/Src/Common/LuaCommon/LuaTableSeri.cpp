#include "Common/LuaCommon/LuaTableSeri.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/HexStr.h"
#include "Include/Script/Script.hpp"

const int nMAX_LEVEL = 6;
const int nTABLE_WARNING_LEN = 1024*1024;	//1M发出警告

static int nCapacity = 32*1024;
static char* pTableBuf = (char*)XALLOC(pTableBuf, nCapacity);


// Expand buffer
static void CheckExpandBuf(lua_State* pState, int nNewCapacity)
{
	if (nCapacity >= nNewCapacity)
	{
		return;
	}
	while (nCapacity < nNewCapacity)
	{
		nCapacity *= 2;
	}
	if (nCapacity >= nTABLE_WARNING_LEN)
	{
		XLog(LEVEL_ERROR, "Table serialize buf size too big: %d\n", nCapacity);
	}
	pTableBuf = (char*)XALLOC(pTableBuf, nCapacity);
	if (pTableBuf == NULL)
	{
		LuaWrapper::luaM_error(pState, "Memory out!");
	}
}

// Convert table key value to string
static bool _Tb2StrKV(lua_State* pState, int nArg, int nType, int& nBufPos)
{
	switch (nArg)
	{
		//Key
		case -2:
		{
			if (!(nType == LUA_TNUMBER || nType == LUA_TSTRING))
			{
				LuaWrapper::luaM_error(pState, "Key type:%d not supported", nType);
				return false;
			}
			size_t uLen = 0;
			const char* psKey = "";
			if (lua_isinteger(pState, nArg))
			{
				psKey = XMath::Int2Str(lua_tointeger(pState, nArg), uLen);
			}
			else
			{
				psKey = lua_tolstring(pState, nArg, &uLen);
			}
			int nExtLen = nType == LUA_TNUMBER ? 3 : 1;
			int nTarPos = nBufPos + (int)uLen + nExtLen;
            if (nTarPos > nCapacity)
			{
				CheckExpandBuf(pState, nTarPos);
			}
			if (nType == LUA_TNUMBER)
			{
				pTableBuf[nBufPos++] = '[';
                memcpy(pTableBuf+nBufPos, psKey, uLen);
                nBufPos += (int)uLen;
				pTableBuf[nBufPos++] = ']';
				pTableBuf[nBufPos++] = '=';
			}
			else
			{
                memcpy(pTableBuf+nBufPos, psKey, uLen);
				nBufPos += (int)uLen;
				pTableBuf[nBufPos++] = '=';
			}
			break;
		}
		//Value
		case -1:
		{
			if (!(nType == LUA_TNUMBER || nType == LUA_TSTRING))
			{
				LuaWrapper::luaM_error(pState, "Value type:%d not supported", nType);
				return false;
			}
			size_t uLen = 0;
			const char* psVal = "";
			if (lua_isinteger(pState, nArg))
			{
				psVal = XMath::Int2Str(lua_tointeger(pState, nArg), uLen);
			}
			else
			{
				psVal = lua_tolstring(pState, nArg, &uLen);
			}
			int nExtLen = nType == LUA_TSTRING ? (int)uLen + 3 : 1;
			int nTarPos = nBufPos + (int)uLen + nExtLen;
            if (nTarPos > nCapacity)
            {
				CheckExpandBuf(pState, nTarPos);
            }
			if (nType != LUA_TSTRING)
			{
				memcpy(pTableBuf+nBufPos, psVal, (int)uLen);
                nBufPos += (int)uLen;
				pTableBuf[nBufPos++] = ',';
            }
            else
			{
                pTableBuf[nBufPos++] = '"';
				nBufPos += HexStr::ByteToHexStr((unsigned char*)psVal, pTableBuf+nBufPos, (int)uLen);
				pTableBuf[nBufPos++] = '"';
				pTableBuf[nBufPos++] = ',';
			}
			break;
		}
	}
	return true;
}

// Convert table to string
static int _Tb2StrProc(lua_State* pState, int& nBufPos)
{
	luaL_checktype(pState, -1, LUA_TTABLE);
	if (nBufPos >= nCapacity)
	{
		CheckExpandBuf(pState, nCapacity + 1);
	}
    pTableBuf[nBufPos++] = '{';
	int nLevel = 1;
	int nMaxLevel = 1;
	int nTbIdx = lua_gettop(pState);
	lua_pushnil(pState);
	while (lua_next(pState, nTbIdx))
	{
		int nVType = lua_type(pState, -1);
		int nKType = lua_type(pState, -2);
		_Tb2StrKV(pState, -2, nKType, nBufPos);
		if (nVType != LUA_TTABLE)
		{
			_Tb2StrKV(pState, -1, nVType, nBufPos);
		}
		else
		{
			nLevel = 1;
			nLevel += _Tb2StrProc(pState, nBufPos);
			nMaxLevel = XMath::Max(nLevel, nMaxLevel);
			if (nMaxLevel > nMAX_LEVEL)
			{
				return LuaWrapper::luaM_error(pState, "Table level out of range:%d", nMAX_LEVEL);
			}
		}
		lua_pop(pState, 1);
	}
	if (nBufPos + 2 > nCapacity)
	{
		return LuaWrapper::luaM_error(pState, "String len out of range");
	}
	pTableBuf[nBufPos++] = '}';
	pTableBuf[nBufPos++] = ',';
	return nMaxLevel;
}

// Convert Lua table to string
static int LuaTb2Str(lua_State* pState)
{
	luaL_checktype(pState, -1, LUA_TTABLE);
	int nBufPos = 0;
	_Tb2StrProc(pState, nBufPos);
	assert(nBufPos > 0);
	int nLen = (int)(nBufPos - 1);
	lua_pushlstring(pState, pTableBuf, nLen);
	return 1;
}

static bool _Str2TbKV(lua_State* pState, char cKV, const char* pStrPos, const char* pStrEnd)
{
	int nLen = (int)(pStrEnd - pStrPos + 1);
	// Key
	if (cKV == 'k')
	{
		if (*pStrPos == '[' && *pStrEnd == ']')
		{
			memcpy(pTableBuf, pStrPos + 1, nLen - 2);
			pTableBuf[nLen - 2] = '\0';
			if (strchr(pTableBuf, '.') != NULL)
			{
				double dKeyVal = atof(pTableBuf);
				lua_pushnumber(pState, dKeyVal);
			}
			else
			{
				lua_Integer nKeyVal = (lua_Integer)atoll(pTableBuf);
				lua_pushinteger(pState, nKeyVal);
			}
		}
		else
		{
			lua_pushlstring(pState, pStrPos, nLen);
		}
	}
	else
	{ //Value
		if (*pStrPos == '"' && *pStrEnd == '"')
		{
			int nCvtLen = HexStr::HexStrToByte(pStrPos + 1, (unsigned char*)pTableBuf, nLen - 2);
			lua_pushlstring(pState, pTableBuf, nCvtLen);
		}
		else
		{
			memcpy(pTableBuf, pStrPos, nLen);
			pTableBuf[nLen] = '\0';
			if (strchr(pTableBuf, '.') != NULL)
			{
				double dVal = atof(pTableBuf);
				lua_pushnumber(pState, dVal);
			}
			else
			{
				lua_Integer nVal = (lua_Integer)atoll(pTableBuf);
				lua_pushinteger(pState, nVal);
			}
		}
	}
	return true;
}

static int LuaStr2Tb(lua_State* pState)
{
	size_t uLen = 0;
	const char* pStr = luaL_checklstring(pState, -1, &uLen);
	CheckExpandBuf(pState, (int)uLen + 1);

	int nBeg = 0;
	int nEnd = 0;
	const char* pPos = pStr;
	while (*pPos)
	{
		switch (*pPos)
		{
			case '{':
			{
				if (*(pPos + 1) == '{')
				{
					goto FMT_ERR;
				}
				lua_newtable(pState);
				pPos++;
                nBeg++;
				break;
			}
			case '}':
			{
				pPos++;
				nEnd++;
				if (lua_gettop(pState) >= 3)
				{
					lua_settable(pState, -3);
				}
				break;
			}
			case ',':
			{
				pPos++;
				break;
			}
			default:
			{
				const char *pEqual = strchr(pPos, '=');
				if (pEqual == NULL)
				{
					goto FMT_ERR;
				}
			    // Key
				if (!_Str2TbKV(pState, 'k', pPos, pEqual - 1))
				{
					goto FMT_ERR;
				}
			    // Value 
				const char* pValBeg = pEqual + 1;
				if (*pValBeg == '{')
				{
					pPos = pEqual + 1;
					break;
				}
				const char* pValEnd = NULL;
			    // String value
				if (*pValBeg == '"')
				{
					pValEnd = strchr(pValBeg + 1, '"');
				   	if (pValEnd == NULL)
				   	{
					   	goto FMT_ERR;
				   	}
				}
				else
			    {// Number value
				   	pValEnd = strchr(pValBeg, ',');
				   	if (pValEnd == NULL)
				   	{
					   	goto FMT_ERR;
				   	}
				   	else
				   	{
					   	pValEnd -= 1;
				   	}
				}
				if (!_Str2TbKV(pState, 'v', pValBeg, pValEnd))
			    {
			    	goto FMT_ERR;
			    }
				lua_settable(pState, -3);
			    pPos = pValEnd + 2;
			}
		}
		if (nBeg == nEnd)
		{
			return 1;
		}
	}
FMT_ERR:
	{
		return LuaWrapper::luaM_error(pState, "Table format error");
	}
}

// Register lua table seri
void RegLuaTableSeri(const char* psTable)
{
	luaL_Reg aFuncList[] =
	{
		{ "Str2Tb", LuaStr2Tb},
		{ "Tb2Str", LuaTb2Str},
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(aFuncList, psTable);
}

