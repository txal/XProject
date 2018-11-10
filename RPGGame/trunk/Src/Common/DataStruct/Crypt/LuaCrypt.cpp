#include "LuaCrypt.hpp"
#include "Include/Script/Script.hpp"
#include "Base64.h"
#include "Md5.h"
#include "MSha1.h"

static int Base64Encode(lua_State* pState)
{
	size_t nSize = 0;
	const char* pStr = luaL_checklstring(pState, -1, &nSize);

	std::string oStr = base64_encode((unsigned char*)pStr, (unsigned)nSize);
	lua_pushlstring(pState, oStr.c_str(), oStr.size());
	return 1;
}

static int Base64Decode(lua_State* pState)
{
	size_t nSize = 0;
	const char* pStr = luaL_checklstring(pState, -1, &nSize);

	std::string oTmpStr(pStr, nSize);
	std::string oStr = base64_decode(oTmpStr);
	lua_pushlstring(pState, oStr.c_str(), oStr.size());
	return 1;
}

static int Sha1Encode(lua_State* pState)
{
	size_t nSize = 0;
	const char* pStr = luaL_checklstring(pState, -1, &nSize);

	MSHA1 oChecksum;
	std::string oTmpStr(pStr, nSize);
	oChecksum.update(oTmpStr);
	std::string oStr = oChecksum.final();
	lua_pushlstring(pState, oStr.c_str(), oStr.size());
	return 1;
}

static int MD5(lua_State* pState)
{
	char sOutput[64] = { 0 };
	const char* psCont = luaL_checkstring(pState, 1);
	MD5String(sOutput, psCont);
	lua_pushstring(pState, sOutput);
	return 1;
}


void RegLuaCrypt(const char* psTable)
{
	luaL_Reg _crypt_lua_func[] =
	{
		{ "Base64Encode", Base64Encode},
		{ "Base64Decode", Base64Decode},
		{ "Sha1Encode", Sha1Encode},
		{ "MD5", MD5},
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(_crypt_lua_func, psTable);
}
