#include "Common/LuaCommon/LuaCmd.h"
#include "Include/Network/Network.hpp"
#include "Include/Script/Script.hpp"

const char cInt8 = 'c';
const char cuInt8 = 'C';
const char cInt16 = 'w';
const char cuInt16 = 'W';
const char cInt32 = 'i';
const char cuInt32 = 'I';
const char cInt64 = 'q';
const char cBool = 'b';
const char cFloat = 'f';
const char cDouble = 'd';
const char cString = 's';
const char cTable = 't';


//打包
template<typename T>
static bool _PackNumber(Packet* poPacket, T xVal)
{
	return poPacket->WriteBuf(&xVal, sizeof(xVal));
}

static bool _PackString(Packet* poPacket, const char* pStrVal, int nSize)
{
    return poPacket->WriteBuf(pStrVal, nSize);
}

static bool _PackOne(lua_State* pState, Packet* poPacket, const char*& psProto, int nStackIdx);
static bool _PackTable(lua_State* pState, Packet* poPacket, const char*& psProto, int nTableIdx)
{
	if (nTableIdx < 0)
	{
		nTableIdx = nTableIdx + lua_gettop(pState) + 1;
	}
    luaL_checktype(pState, nTableIdx, LUA_TTABLE);
	uint16_t uLoopNum = (uint16_t)luaL_len(pState, nTableIdx);
	if (!_PackNumber(poPacket, uLoopNum))
	{
		return false;
	}
	const char* pPosBeg = psProto + 2;
	const char* pPosEnd = pPosBeg;
	int nLeft = 1, nRight = 0;
	while(nLeft != nRight && *pPosEnd != '\0')
	{
		if (*pPosEnd == '{')
		{
			nLeft++;
		}
		else if (*pPosEnd == '}')
		{
			nRight++;
		}
		if (nLeft == nRight)
		{
			break;
		}
		pPosEnd++;	
	}
	if (nLeft != nRight)
	{
		poPacket->Release();
		LuaWrapper::luaM_error(pState, "Protocal invalid table: %s", psProto);
		return false;
	}
	int nTableProtoLen = (int)(pPosEnd - pPosBeg);
    luaL_checkstack(pState, uLoopNum * (nTableProtoLen + 1), NULL);
	for (int i = 1; i <= (int) uLoopNum; i++)
	{
		lua_rawgeti(pState, nTableIdx, i);
        luaL_checktype(pState, -1, LUA_TTABLE);
        int nSubTableIdx = lua_gettop(pState);
        int nValueIdx = 1;
		const char* pParsingPos = pPosBeg;
        while (pParsingPos != pPosEnd)
        {
    		lua_rawgeti(pState, nSubTableIdx, nValueIdx++);
			bool bRes = _PackOne(pState, poPacket, pParsingPos, -1);	
            if (!bRes)
            {
                return false;
            }
            pParsingPos++;
			lua_pop(pState, 1);
        }
		lua_pop(pState, 1);
	}
    psProto = pPosEnd;
    return true;
}

static bool _PackOne(lua_State* pState, Packet* poPacket, const char*& psProto, int nStackIdx)
{
    if (nStackIdx < 0)
    {
        nStackIdx = nStackIdx + lua_gettop(pState) + 1;
    }
	bool bRes = true;
	switch(*psProto)
	{
        case '\0':
        {
            bRes = false;
            break;
        }
		case cInt8:
		{
			int8_t xVal = (int8_t)lua_tointeger(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cuInt8:
		{
			uint8_t xVal = (uint8_t)lua_tointeger(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cInt16:
		{
			int16_t xVal = (int16_t)lua_tointeger(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cuInt16:
		{
			uint16_t xVal = (uint16_t)lua_tointeger(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cInt32:
		{
			int32_t xVal = (int32_t)lua_tointeger(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cuInt32:
		{
			uint32_t xVal = (uint32_t)lua_tointeger(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cInt64:
		{
			int64_t xVal = (int64_t)lua_tointeger(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cBool:
		{
			int8_t xVal = lua_toboolean(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cFloat:
		{
			float xVal = (float)lua_tonumber(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cDouble:
		{
			double xVal = (double)lua_tonumber(pState, nStackIdx);
			bRes = _PackNumber(poPacket, xVal);
			break;
		}
		case cString:
		{
			size_t uSize = 0;
			const char* pStr = lua_tolstring(pState, nStackIdx, &uSize);
            int nSize = (int)uSize;
			bRes = _PackNumber(poPacket, nSize);
			bRes = bRes && _PackString(poPacket, pStr, nSize);
			break;
		}
		case cTable:
		{
			bRes = _PackTable(pState, poPacket, psProto, nStackIdx);
			break;
		}
		default:
		{
			bRes = false;
			poPacket->Release();
			LuaWrapper::luaM_error(pState, "Proto type: %c error\n", *psProto);
			break;
		}
	}
	return bRes;
}

static int LuaCmdPack(lua_State* pState)
{
	const char* psProto = luaL_checkstring(pState, 1);
   	Packet* poPacket = Packet::Create();
	if (poPacket == NULL) {
		return LuaWrapper::luaM_error(pState, "Create packet fail proto:%s\n", psProto);
	}
    int nStackIdx = 2;
    while (_PackOne(pState, poPacket, psProto, nStackIdx))
    {
        psProto++;
        nStackIdx++;
    }
	if (*psProto != '\0')
	{
		poPacket->Release();
		return LuaWrapper::luaM_error(pState, "Packet '%s' out of range\n", psProto);
	}
    lua_pushlightuserdata(pState, poPacket);
	return 1;
}

//解包
template<typename T>
static bool _UnpackNumber(const uint8_t*& pbfData, int& nDataLen, T& xVal)
{
    if (nDataLen < (int)sizeof(xVal))
    {
        return false;
    }
    xVal = *(T*)pbfData;
    pbfData += sizeof(xVal);
    nDataLen -= sizeof(xVal);
    return true;
}

static bool _UnpackString(const uint8_t*& pbfData, int& nDataLen, const char*& psVal, int nLen)
{
    if (nDataLen < nLen)
    {
        return false;
    }
	psVal = (char*)pbfData;
    pbfData += nLen;
    nDataLen -= nLen;
    return true;
}

static bool _UnpackOne(lua_State* pState, const uint8_t*& pbfData, int& nDataLen, const char*& psProto);
static bool _UnpackTable(lua_State* pState, const uint8_t*& pbfData, int& nDataLen, const char*& psProto)
{
    uint16_t uLoopNum = 0;
    if (!_UnpackNumber(pbfData, nDataLen, uLoopNum))
    {
        LuaWrapper::luaM_error(pState, "Unpack number error: %s", psProto);
        return false;
    }
    lua_newtable(pState);
    int nTableIdx = lua_gettop(pState);
    char sTableProto[128] = { 0 };
    const char* pPosEnd = psProto + 2;
    int nLeft = 1, nRight = 0;
    while (nLeft != nRight && *pPosEnd != '\0')
    {
        if (*pPosEnd == '{')
        {
            nLeft++;
        }
        else if (*pPosEnd == '}')
        {
            nRight++;
        }
        if (nLeft == nRight)
        {
            break;
        }
        pPosEnd++;
    }
    if (nLeft != nRight)
    {
        LuaWrapper::luaM_error(pState, "Protocal invalid table: %s", psProto);
        return false;
    }
    int nTableProtoLen = (int)(pPosEnd - psProto - 2);
    memcpy(sTableProto, psProto + 2, nTableProtoLen);
    for (int i = 1; i <= (int)uLoopNum; i++)
    {
        lua_newtable(pState);
        int nSubTableIdx = lua_gettop(pState);
        int nValueIdx = 1;
        const char* pParsingPos = sTableProto;
        while (*pParsingPos != '\0')
        {
            _UnpackOne(pState, pbfData, nDataLen, pParsingPos);
            lua_rawseti(pState, nSubTableIdx, nValueIdx++);
            pParsingPos++;
        }
        lua_rawseti(pState, nTableIdx, i);
    }
    psProto = pPosEnd;
    return true;
}

static bool _UnpackOne(lua_State* pState, const uint8_t*& pbfData, int& nDataLen, const char*& psProto)
{
    bool bRes = true;
    switch (*psProto)
    {
        case '\0':
        {
            bRes = false;
            break;
        }
        case cInt8:
        {

            int8_t xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cuInt8:
        {
            uint8_t xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cInt16:
        {
            int16_t xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cuInt16:
        {
            uint16_t xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cInt32:
        {
            int32_t xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cuInt32:
        {
            uint32_t xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cInt64:
        {
            int64_t xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cBool:
        {
            int8_t xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushboolean(pState, xVal);
            break;
        }
        case cFloat:
        {
            float xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushnumber(pState, xVal);
            break;
        }
        case cDouble:
        {
            double xVal = 0;
			bRes = _UnpackNumber(pbfData, nDataLen, xVal);
            lua_pushnumber(pState, xVal);
            break;
        }
        case cString:
        {
            int nSize = 0;
			const char* psVal = "";
			bRes = _UnpackNumber(pbfData, nDataLen, nSize);
			if (nSize >= nPACKET_MAX_SIZE)
			{
		        LuaWrapper::luaM_error(pState, "String size out of range:%d/%d\n", nSize, nPACKET_MAX_SIZE);
				break;
			}
			bRes = bRes && _UnpackString(pbfData, nDataLen, psVal, nSize);
			lua_pushlstring(pState, psVal, nSize);
            break;
        }
        case cTable:
        {
            bRes = _UnpackTable(pState, pbfData, nDataLen, psProto);
            break;
        }
        default:
        {
            bRes = false;
	        LuaWrapper::luaM_error(pState, "Proto type:%c error\n", *psProto);
            break;
        }
    }
    return bRes;
}

static int LuaCmdUnpack(lua_State* pState)
{
    const char* psProto = luaL_checkstring(pState, 1);
    Packet* poPacket = (Packet*)lua_touserdata(pState, 2);
	const uint8_t* pbfData = poPacket->GetRealData();
	int nDataLen = poPacket->GetRealDataSize();
    int nDataCount = 0;
    while (_UnpackOne(pState, pbfData, nDataLen, psProto))
    {
        psProto++;
        nDataCount++;
    }
	if (*psProto != '\0')
	{
		return LuaWrapper::luaM_error(pState, "Packet size error:%s\n", psProto);
	}
	return nDataCount;
}

// Register lua cmd
void RegLuaCmd(const char* psTable)
{
    luaL_Reg aFuncList[] =
    {
        { "CmdPack", LuaCmdPack},
        { "CmdUnpack", LuaCmdUnpack},
        { NULL, NULL },
    };
    LuaWrapper::Instance()->RegFnList(aFuncList, psTable);
}

