#ifndef __LUA_TABLESERI_H__
#define __LUA_TABLESERI_H__

#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/HexStr.h"
#include "Include/Script/Script.hpp"

class LuaTableSeri
{
public:
	LuaTableSeri();
	~LuaTableSeri();

	// Expand buffer
	void CheckExpandBuf(lua_State* pState, int nNewCapacity);
	// Convert table key value to string
	bool _Tb2StrKV(lua_State* pState, int nArg, int nType, int& nBufPos);
	// Convert table to string
	int _Tb2StrProc(lua_State* pState, int& nBufPos);
	// Conver string to table kv
	bool _Str2TbKV(lua_State* pState, char cKV, const char* pStrPos, const char* pStrEnd);
	char* GetBuffer() { return m_pTableBuf; }

private:
	int m_nCapacity;
	char* m_pTableBuf;

};

void RegLuaTableSeri(const char* psTable);


#endif