#ifndef __LUA_CJSON_H__
#define __LUA_CJSON_H__

#include "Include/Script/LuaInc/lua.hpp"
#ifdef __cplusplus
extern "C" {
#endif
	int luaopen_cjson(lua_State *l);
	int luaopen_cjson_raw(lua_State *l);
#ifdef __cplusplus
}
#endif


#endif