#ifndef __MONSTERMGR_H__
#define __MONSTERMGR_H__

#include "Include/Script/Script.hpp"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/Object/Monster/Monster.h"

class MonsterMgr
{
public:
	LUNAR_DECLARE_CLASS(MonsterMgr);

	typedef std::unordered_map<int, Monster*> MonsterMap;
	typedef MonsterMap::iterator MonsterIter;

public:
	MonsterMgr();
	~MonsterMgr();

	Monster* CreateMonster(int nID, int nConfID, const char* psName, int nAIID, int8_t nCmap);
	void RemoveMonster(int nID);
	Monster* GetMonsterByID(int nID);

public:
	void Update(int64_t nNowMS);



////////////////lua export///////////////////
public:
	int CreateMonster(lua_State* pState);
	int RemoveMonster(lua_State* pState);
	int GetMonster(lua_State* pState);

private:
	MonsterMap m_oMonsterIDMap;
};


void RegClassMonster();

#endif