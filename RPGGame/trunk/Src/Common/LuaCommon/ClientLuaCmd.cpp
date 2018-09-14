#include "ClientLuaCmd.h"

#define MAX_PACKET_SIZE (4*1024)

struct PacketHeader
{
	uint16_t uCmd;
	int8_t nSrc;
	int8_t nTar;
};

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
static bool _PackNumber(uint8_t* pBuf, int& nLen, T xVal)
{
	if (nLen + sizeof(xVal) > MAX_PACKET_SIZE)
	{
		return false;
	}
	*(T*)(pBuf + nLen) = xVal;
	nLen += sizeof(xVal);
	return true;
}

static bool _PackString(uint8_t* pBuf, int& nLen, const char* psVal, int nSize)
{
	if (nLen + nSize > MAX_PACKET_SIZE)
	{
		return false;
	}
	uint8_t* pPos = pBuf + nLen;
	memcpy(pPos, psVal, nSize);
	nLen += nSize;
	return true;
}

static bool _PackOne(lua_State* pState, uint8_t* pBuf, int& nLen, const char*& psProto, int nStackIdx);
static bool _PackTable(lua_State* pState, uint8_t* pBuf, int& nLen, const char*& psProto, int nTableIdx)
{
	if (nTableIdx < 0)
	{
		nTableIdx = nTableIdx + lua_gettop(pState) + 1;
	}
    luaL_checktype(pState, nTableIdx, LUA_TTABLE);
	uint16_t uLoopNum = (uint16_t)luaL_len(pState, nTableIdx);
	if (!_PackNumber(pBuf, nLen, uLoopNum))
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
		luaL_error(pState, "Protocal table invalid: %s", psProto);
		return false;
	}
	int nTbProtoLen = (int)(pPosEnd - pPosBeg);
    luaL_checkstack(pState, uLoopNum * (nTbProtoLen + 1), NULL);
	for (int i = 1; i <= (int)uLoopNum; i++)
	{
		lua_rawgeti(pState, nTableIdx, i);
        luaL_checktype(pState, -1, LUA_TTABLE);
        int nSubTbIdx = lua_gettop(pState);
        int nValueIdx = 1;
    	const char* pParsingPos = pPosBeg;
        while (pParsingPos != pPosEnd)
        {
    		lua_rawgeti(pState, nSubTbIdx, nValueIdx++);
			bool bRes = _PackOne(pState, pBuf, nLen, pParsingPos, -1);	
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

static bool _PackOne(lua_State* pState, uint8_t* pBuf, int& nLen, const char*& psProto, int nStackIdx)
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
			int8_t xVal = (int8_t)luaL_checkinteger(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cuInt8:
		{
			uint8_t xVal = (uint8_t)luaL_checkinteger(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cInt16:
		{
			int16_t xVal = (int16_t)luaL_checkinteger(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cuInt16:
		{
			uint16_t xVal = (uint16_t)luaL_checkinteger(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cInt32:
		{
			int32_t xVal = (int32_t)luaL_checkinteger(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cuInt32:
		{
			uint32_t xVal = (uint32_t)luaL_checkinteger(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cBool:
		{
			int8_t xVal = lua_toboolean(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cFloat:
		{
			float xVal = (float)luaL_checknumber(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cDouble:
		{
			double xVal = (double)luaL_checknumber(pState, nStackIdx);
			bRes = _PackNumber(pBuf, nLen, xVal);
			break;
		}
		case cString:
		{
			size_t uSize = 0;
			const char* pStr = luaL_checklstring(pState, nStackIdx, &uSize);
            int nSize = (int)uSize;
			bRes = _PackNumber(pBuf, nLen, nSize);
			bRes = bRes && _PackString(pBuf, nLen, pStr, nSize);
			break;
		}
		case cTable:
		{
			bRes = _PackTable(pState, pBuf, nLen, psProto, nStackIdx);
			break;
		}
		case cInt64:
		default:
		{
			bRes = false;
		    luaL_error(pState, "Proto type: %c not supprot", *psProto);
			break;
		}
	}
	return bRes;
}

static int LuaCmdPack(lua_State* pState)
{
	uint16_t uCmd = (uint16_t)luaL_checkinteger(pState, 1);
	int8_t nService = (int8_t)luaL_checkinteger(pState, 2);
	const char* psProto = luaL_checkstring(pState, 3);
    int nStackIdx = 4;

	static uint8_t sBuf[MAX_PACKET_SIZE];
	int nLen = sizeof(int);
    while (_PackOne(pState, sBuf, nLen, psProto, nStackIdx))
    {
        psProto++;
        nStackIdx++;
    }
	//添加包尾
	PacketHeader oHeader;
	oHeader.uCmd = uCmd;
	oHeader.nSrc = 0;
	oHeader.nTar = nService;
	if (nLen + sizeof(oHeader) > MAX_PACKET_SIZE)
	{
		return luaL_error(pState, "Pack packet out of range:4k");
	}
	*(PacketHeader*)(sBuf + nLen) = oHeader;
	nLen += sizeof(oHeader);
	int* pPos = (int*)sBuf;
	*pPos = nLen - sizeof(int);
	
	lua_pushlightuserdata(pState, (void*)sBuf); //这里为了效率，返回指针
	lua_pushinteger(pState, nLen);
	return 2;
}


//解包
template<typename T>
static bool _UnpackNumber(const uint8_t*& pPos, int& nLen, T& xVal)
{
    if (nLen < (int)sizeof(xVal))
    {
        return false;
    }
    xVal = *(T*)pPos;
    pPos += sizeof(xVal);
    nLen -= sizeof(xVal);
    return true;
}

static bool _UnpackString(const uint8_t*& pPos, int& nLen, const char*& psVal, int nStrLen)
{
    if (nLen < nStrLen)
    {
        return false;
    }
	psVal = (char*)pPos;
    pPos += nStrLen;
    nLen -= nStrLen;
    return true;
}

static bool _UnpackOne(lua_State* pState, const uint8_t*& pData, int& nLen, const char*& psProto);
static bool _UnpackTable(lua_State* pState, const uint8_t*& pData, int& nLen, const char*& psProto)
{
    uint16_t uLoopNum = 0;
    if (!_UnpackNumber(pData, nLen, uLoopNum))
    {
        luaL_error(pState, "Unpack number error: %s", psProto);
        return false;
    }
    lua_newtable(pState);
    int nTableIdx = lua_gettop(pState);
	const char* pPosBeg = psProto + 2;
    const char* pPosEnd = pPosBeg;
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
        luaL_error(pState, "Protocal table invalid: %s", psProto);
        return false;
    }
    for (int i = 1; i <= (int)uLoopNum; i++)
    {
        lua_newtable(pState);
        int nSubTableIdx = lua_gettop(pState);
        int nValueIdx = 1;
        const char* pParsingPos = pPosBeg;
        while (pParsingPos != pPosEnd)
        {
            _UnpackOne(pState, pData, nLen, pParsingPos);
            lua_rawseti(pState, nSubTableIdx, nValueIdx++);
            pParsingPos++;
        }
        lua_rawseti(pState, nTableIdx, i);
    }
    psProto = pPosEnd;
    return true;
}

static bool _UnpackOne(lua_State* pState, const uint8_t*& pData, int& nLen, const char*& psProto)
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
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cuInt8:
        {
            uint8_t xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cInt16:
        {
            int16_t xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cuInt16:
        {
            uint16_t xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cInt32:
        {
            int32_t xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cuInt32:
        {
            uint32_t xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cInt64:
        {
            int64_t xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushinteger(pState, xVal);
            break;
        }
        case cBool:
        {
            int8_t xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushboolean(pState, xVal);
            break;
        }
        case cFloat:
        {
            float xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushnumber(pState, xVal);
            break;
        }
        case cDouble:
        {
            double xVal = 0;
			bRes = _UnpackNumber(pData, nLen, xVal);
            lua_pushnumber(pState, xVal);
            break;
        }
        case cString:
        {
            int nSize = 0;
			const char* psVal = "";
			bRes = _UnpackNumber(pData, nLen, nSize);
			bRes = bRes && _UnpackString(pData, nLen, psVal, nSize);
			lua_pushlstring(pState, psVal, nSize);
            break;
        }
        case cTable:
        {
            bRes = _UnpackTable(pState, pData, nLen, psProto);
            break;
        }
        default:
        {
            bRes = false;
			luaL_error(pState, "Proto type:%c error\n", *psProto);
            break;
        }
    }
    return bRes;
}

static int LuaCmdUnpack(lua_State* pState)
{
    const char* psProto = luaL_checkstring(pState, 1);
	const uint8_t* pData = (uint8_t*)lua_touserdata(pState, 2);
	if (pData == NULL)
	{
		return luaL_error(pState, "Unpack packet userdata error: %s\n", psProto);
	}
	int nLen = (int)luaL_checkinteger(pState, 3);
    int nCount = 0;
    while (_UnpackOne(pState, pData, nLen, psProto))
    {
        psProto++;
        nCount++;
    }
	if (*psProto != '\0')
	{
		return luaL_error(pState, "Unpack packet size error: %s\n", psProto);
	}
	return nCount;
}

//取包尾
static int LuaPacketHeader(lua_State* pState)
{
	const uint8_t* pData = (uint8_t*)lua_touserdata(pState, 1);
	int nLen = (int)luaL_checkinteger(pState, 2);
	PacketHeader oHeader;
	if (nLen < (int)(sizeof(oHeader) + sizeof(int)))
	{
		return luaL_error(pState, "GetPacketHeader packet size invalid");
	}
	oHeader = *(PacketHeader*)(pData + nLen - sizeof(oHeader));
	pData += sizeof(int);
	lua_pushlightuserdata(pState, (void*)pData);
	lua_pushinteger(pState, nLen - sizeof(oHeader)-sizeof(int));
	lua_pushinteger(pState, oHeader.uCmd);
	lua_pushinteger(pState, oHeader.nSrc);
	return 4;
}

static int UserdataToString(lua_State* pState)
{
	uint8_t* pData = (uint8_t*)lua_touserdata(pState, 1);
	if (pData == NULL)
	{
		return luaL_error(pState, "UserdataToString userdata error");
	}
	int nLen = (int)luaL_checkinteger(pState, 2);
	lua_pushlstring(pState, (char*)pData, nLen);
	return 1;
}

static int PBAddHeader(lua_State* pState)
{
	static uint8_t sBuf[MAX_PACKET_SIZE];
	size_t uSize = 0;
	uint8_t* pData = (uint8_t*)luaL_checklstring(pState, 1, &uSize);
	uint16_t uCmd = (uint16_t)luaL_checkinteger(pState, 2);
	int8_t nService = (uint8_t)luaL_checkinteger(pState, 3);
	PacketHeader oHeader;
	if ((int)uSize + sizeof(int) + sizeof(oHeader) > MAX_PACKET_SIZE)
	{
		return luaL_error(pState, "Packet out of size:4k");
	}
	oHeader.uCmd = uCmd;
	oHeader.nSrc = 0;
	oHeader.nTar = nService;

	int nSize = (int)uSize;
	memcpy(sBuf + sizeof(int), pData, nSize);
	nSize += sizeof(int);
	*(PacketHeader*)(sBuf + nSize) = oHeader;
	nSize += sizeof(oHeader);
	int* pPos = (int*)sBuf;
	*pPos = nSize - sizeof(int);
	lua_pushlightuserdata(pState, (void*)sBuf);
	lua_pushinteger(pState, nSize);
	return 2;
}


// Register lua cmd
void RegClientLuaCmd(lua_State* pState, const char* psTable)
{
    luaL_Reg aFuncList[] =
    {
        { "ClientCmdPack", LuaCmdPack},
        { "ClientCmdUnpack", LuaCmdUnpack},
		{ "ClientPacketHeader", LuaPacketHeader},
		{ "UserdataToString", UserdataToString},
		{ "PBAddHeader", PBAddHeader},
        { NULL, NULL },
    };


	if (psTable == NULL)
	{
		lua_pushglobaltable(pState);
	}
	else
	{
		lua_getglobal(pState, psTable);
		if (lua_isnil(pState, -1))
		{
			lua_newtable(pState);
			lua_pushvalue(pState, -1);
			lua_setglobal(pState, psTable);
		}
	}
	for (luaL_Reg *r = aFuncList; r->name; r++)
	{
		lua_pushcfunction(pState, r->func);
		lua_setfield(pState, -2, r->name);
	}
}

