#include "Server/LogicServer/GameObject/Monster/MonsterMgr.h"

#include "Common/DataStruct/XTime.h"
#include "Server/LogicServer/GameObject/Monster/Monster.h"
#include "Server/LogicServer/SceneMgr/SceneBase.h"

LUNAR_IMPLEMENT_CLASS(MonsterMgr)
{
	LUNAR_DECLARE_METHOD(MonsterMgr, CreateMonster),
	LUNAR_DECLARE_METHOD(MonsterMgr, GetMonster),
	LUNAR_DECLARE_METHOD(MonsterMgr, RemoveMonster),
	{0, 0}
};


MonsterMgr::MonsterMgr()
{
}

MonsterMgr::~MonsterMgr()
{
	MonsterIter iter = m_oMonsterIDMap.begin();
	for (iter; iter != m_oMonsterIDMap.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
	m_oMonsterIDMap.clear();
}

Monster* MonsterMgr::CreateMonster(int64_t nObjID, int nConfID, const char* psName, int nAIID, int8_t nCamp)
{
	Monster* poMonster = GetMonsterByID(nObjID);
	if (poMonster != NULL)
	{
		XLog(LEVEL_ERROR, "CreateMonster error for monster id:%d exist\n", nObjID);
		return poMonster;
	}
	poMonster = XNEW(Monster);
	poMonster->Init(nObjID, nConfID, psName);
	m_oMonsterIDMap[nObjID] = poMonster;
	return poMonster;
}

void MonsterMgr::RemoveMonster(int64_t nObjID)
{
	Monster* poMonster = GetMonsterByID(nObjID);
	if (poMonster == NULL)
	{
		return;
	}
	if (poMonster->GetScene() != NULL)
	{
		XLog(LEVEL_ERROR, "需要先离开场景才能删除对象");
		return;
	}
	poMonster->MarkDeleted();
}

Monster* MonsterMgr::GetMonsterByID(int64_t nObjID)
{
	MonsterIter iter = m_oMonsterIDMap.find(nObjID);
	if (iter != m_oMonsterIDMap.end() && !iter->second->IsDeleted())
	{
		return iter->second;
	}
	return NULL;
}

void MonsterMgr::Update(int64_t nNowMS)
{
	static int64_t nLastUpdateTime = 0;
	if (nNowMS - nLastUpdateTime < 30)
	{
		return;
	}
	nLastUpdateTime = nNowMS;

	int nMonsterCount = 0;
	MonsterIter iter = m_oMonsterIDMap.begin();
	MonsterIter iter_end = m_oMonsterIDMap.end();
	for (; iter != iter_end;)
	{
		Monster* poMonster = iter->second;
		if (poMonster->IsDeleted())
		{
			iter = m_oMonsterIDMap.erase(iter);
			SAFE_DELETE(poMonster);
			continue;
		}
		if (poMonster->GetScene() != NULL)
		{
			poMonster->Update(nNowMS);
		}
		nMonsterCount++;
		iter++;
	}	

	static int64_t nLastDumpTime = 0;
	if (nNowMS-nLastDumpTime >= 60000)
	{
		nLastDumpTime = nNowMS;
		XLog(LEVEL_INFO, "CPP current monster count=%d\n", nMonsterCount);
	}
}


///////////////// export to lua /////////////////
void RegClassMonster()
{
	REG_CLASS(Monster, false, NULL); 
	REG_CLASS(MonsterMgr, false, NULL); 
}

int MonsterMgr::CreateMonster(lua_State* pState)
{
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
	int nConfID = (int)luaL_checkinteger(pState, 2);
	const char* psName = luaL_checkstring(pState, 3);

	Monster* poMonster = CreateMonster(nObjID, nConfID, psName, 0, 0);
	if (poMonster != NULL)
	{
		Lunar<Monster>::push(pState, poMonster);
		return 1;
	}
	return 0;
}

int MonsterMgr::GetMonster(lua_State* pState)
{
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
	Monster* poMonster = GetMonsterByID(nObjID);
	if (poMonster != NULL)
	{
		Lunar<Monster>::push(pState, poMonster);
		return 1;
	}
	return 0;
}

int MonsterMgr::RemoveMonster(lua_State* pState)
{
	int64_t nObjID = (int)luaL_checkinteger(pState, 1);
	RemoveMonster(nObjID);
	return 0;
}
