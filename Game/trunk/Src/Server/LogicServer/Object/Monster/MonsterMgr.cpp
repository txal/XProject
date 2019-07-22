#include "MonsterMgr.h"
#include "Common/DataStruct/XTime.h"

LUNAR_IMPLEMENT_CLASS(MonsterMgr)
{
	LUNAR_DECLARE_METHOD(MonsterMgr, CreateMonster),
	//LUNAR_DECLARE_METHOD(MonsterMgr, RemoveMonster), 自动收集不需要主动删除
	LUNAR_DECLARE_METHOD(MonsterMgr, GetMonster),
	{0, 0}
};


MonsterMgr::MonsterMgr()
{
}

Monster* MonsterMgr::CreateMonster(int64_t nID, int nConfID, const char* psName, int nAIID, int8_t nCamp)
{
	Monster* poMonster = GetMonsterByID(nID);
	if (poMonster != NULL)
	{
		XLog(LEVEL_ERROR, "CreateMonster: %lld exist\n", nID);
		return NULL;
	}
	poMonster = XNEW(Monster);
	poMonster->Init(nID, nConfID, psName, nAIID, nCamp);
	m_oMonsterIDMap[nID] = poMonster;
	return poMonster;
}

void MonsterMgr::RemoveMonster(int64_t nID)
{
	MonsterIDIter iter = m_oMonsterIDMap.find(nID);
	if (iter == m_oMonsterIDMap.end())
	{
		return;
	}
	Monster* poMonster = iter->second;
	if (poMonster->GetScene() != NULL)
	{
		XLog(LEVEL_ERROR, "Remove monster must leave scene first\n");
		return;
	}
	m_oMonsterIDMap.erase(iter);
	SAFE_DELETE(poMonster);
}

Monster* MonsterMgr::GetMonsterByID(int64_t nID)
{
	MonsterIDIter iter = m_oMonsterIDMap.find(nID);
	if (iter != m_oMonsterIDMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void MonsterMgr::UpdateMonsters(int64_t nNowMS)
{
	MonsterIDIter iter = m_oMonsterIDMap.begin();
	MonsterIDIter iter_end = m_oMonsterIDMap.end();
	for (; iter != iter_end;)
	{
		Monster* poMonster = iter->second;
		if (nNowMS - poMonster->GetLastUpdateTime() >= FRAME_MSTIME)
		{
			if (poMonster->IsTimeToCollected(nNowMS))
			{
				iter = m_oMonsterIDMap.erase(iter);
				LuaWrapper::Instance()->FastCallLuaRef<void, CNOTUSE>("OnObjCollected", 0, "ii", poMonster->GetID(), poMonster->GetType());
				SAFE_DELETE(poMonster);
				continue;
			}
			if (!poMonster->IsDead() && poMonster->GetScene() != NULL)
			{
				poMonster->Update(nNowMS);
			}
		}
		iter++;
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
	int64_t nObjID = luaL_checkinteger(pState, 1);
	int nConfID = (int)luaL_checkinteger(pState, 2);
	const char* psName = luaL_checkstring(pState, 3);
	int nAIID = (int)luaL_checkinteger(pState, 4);
	int8_t nCamp = (int8_t)luaL_checkinteger(pState, 5);

	Monster* poMonster = CreateMonster(nObjID, nConfID, psName, nAIID, nCamp);
	if (poMonster != NULL)
	{
		Lunar<Monster>::push(pState, poMonster);
		return 1;
	}
	return 0;
}

int MonsterMgr::RemoveMonster(lua_State* pState)
{
	int64_t nObjID = luaL_checkinteger(pState, 1);
	RemoveMonster(nObjID);
	return 0;
}

int MonsterMgr::GetMonster(lua_State* pState)
{
	int64_t nObjID = luaL_checkinteger(pState, 1);
	Monster* poMonster = GetMonsterByID(nObjID);
	if (poMonster != NULL)
	{
		Lunar<Monster>::push(pState, poMonster);
		return 1;
	}
	return 0;
}