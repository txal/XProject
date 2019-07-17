#ifndef __LUA_PBPACKET_H__
#define __LUA_PBPACKET_H__

#include "Include/Network/Network.hpp"
#include "Include/Script/Script.hpp"

static int LuaPBPack(lua_State* pState)
{
	size_t uSize = 0;
	uint8_t* pData = (uint8_t*)luaL_checklstring(pState, 1, &uSize);
	Packet* poPacket = Packet::Create((int)uSize + 88, nPACKET_OFFSET_SIZE, __FILE__, __LINE__); //sizeof(INNER_HEADER)+20*sizeof(int)
	if (poPacket == NULL) {
		return LuaWrapper::luaM_error(pState, "Create packet fail\n");
	}
	poPacket->WriteBuf(pData, (int)uSize);
	lua_pushlightuserdata(pState, poPacket);
	return 1;
}

// Register lua cmd
static void RegLuaPBPack(const char* psTable)
{
	luaL_Reg aFuncList[] =
	{
		{ "PBPack", LuaPBPack},
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(aFuncList, psTable);
}



#endif