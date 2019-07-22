#ifndef __MONSTERMGR_H__
#define __MONSTERMGR_H__

#include "Include/Script/Script.hpp"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/Object/Monster/Monster.h"

class MonsterMgr
{
public:
	LUNAR_DECLARE_CLASS(MonsterMgr);

	typedef std::unordered_map<int64_t, Monster*> MonsterIDMap;
	typedef MonsterIDMap::iterator MonsterIDIter;

public:
	MonsterMgr();
	Monster* CreateMonster(int64_t nID, int nConfID, const char* psName, int nAIID, int8_t nCmap);
	void RemoveMonster(int64_t nID);
	Monster* GetMonsterByID(int64_t nID);

public:
	void UpdateMonsters(int64_t nNowMS);



////////////////lua export///////////////////
public:
	int CreateMonster(lua_State* pState);
	int RemoveMonster(lua_State* pState);
	int GetMonster(lua_State* pState);

private:
	MonsterIDMap m_oMonsterIDMap;
};


void RegClassMonster();

#endif