#include "PlayerMgr.h"

LUNAR_IMPLEMENT_CLASS(PlayerMgr)
{
	LUNAR_DECLARE_METHOD(PlayerMgr, CreatePlayer),
	LUNAR_DECLARE_METHOD(PlayerMgr, BindSession),
	LUNAR_DECLARE_METHOD(PlayerMgr, RemovePlayer),
	LUNAR_DECLARE_METHOD(PlayerMgr, GetPlayer),
	{0, 0}
};


PlayerMgr::PlayerMgr()
{
}

Player* PlayerMgr::CreatePlayer(const OBJID& oID, int nRoleID, const char* psName, int8_t nCamp)
{
	
	Player* poPlayer = GetPlayerByID(oID);
	if (poPlayer != NULL)
	{
		XLog(LEVEL_ERROR, "CreatePlayer: %lld exist\n", oID.llID);
		return NULL;
	}
	poPlayer = XNEW(Player);
	poPlayer->Init(oID, nRoleID, psName, nCamp);
	m_oPlayerIDMap[oID.llID] = poPlayer;
	return poPlayer;
}

void PlayerMgr::BindSession(const OBJID& oID, int nSession)
{
	Player* poPlayer = GetPlayerByID(oID);
	if (poPlayer == NULL)
	{
		return;
	}

	poPlayer->SetSession(nSession);
	if (nSession > 0)
	{
		m_oPlayerSessionMap[nSession] = poPlayer;
	}
	else
	{
		m_oPlayerSessionMap.erase(nSession);
	}
}

void PlayerMgr::RemovePlayer(const OBJID& oID)
{
	PlayerIDIter iter = m_oPlayerIDMap.find(oID.llID);
	if (iter == m_oPlayerIDMap.end())
	{
		return;
	}
	Player* poPlayer = iter->second;
	if (poPlayer->GetScene() != NULL)
	{
		XLog(LEVEL_ERROR, "Remove player must leave scene first\n");
		return;
	}
	m_oPlayerIDMap.erase(iter);

	int nSession = poPlayer->GetSession();
	m_oPlayerSessionMap.erase(nSession);

	SAFE_DELETE(poPlayer);
}

Player* PlayerMgr::GetPlayerByID(const OBJID& oID)
{
	PlayerIDIter iter = m_oPlayerIDMap.find(oID.llID);
	if (iter != m_oPlayerIDMap.end())
	{
		return iter->second;
	}
	return NULL;
}

Player* PlayerMgr::GetPlayerBySession(int nSession)
{
	PlayerSessionIter iter = m_oPlayerSessionMap.find(nSession);
	if (iter != m_oPlayerSessionMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void PlayerMgr::UpdatePlayers(int64_t nNowMS)
{
	PlayerIDIter iter = m_oPlayerIDMap.begin();
	PlayerIDIter iter_end = m_oPlayerIDMap.end();
	for (; iter != iter_end; iter++)
	{
		Player* poPlayer = iter->second;
		if (nNowMS - poPlayer->GetLastUpdateTime() >= FRAME_MSTIME)
		{
			if (!poPlayer->IsDead() && poPlayer->GetScene() != NULL)
			{
				poPlayer->Update(nNowMS);
			}
		}
	}	
}




//////////////////////lua export//////////////////
void RegClassPlayer()
{
	REG_CLASS(Actor, false, NULL); 
	REG_CLASS(Player, false, NULL); 
	REG_CLASS(PlayerMgr, false, NULL); 
}

int PlayerMgr::CreatePlayer(lua_State* pState)
{
	int64_t nCharID = luaL_checkinteger(pState, 1);
	int nRoleID = (int)luaL_checkinteger(pState, 2);
	const char* psName = luaL_checkstring(pState, 3);
	int8_t nCamp = (int8_t)luaL_checkinteger(pState, 4);
	Player* poPlayer = CreatePlayer(nCharID, nRoleID, psName, nCamp);
	if (poPlayer != NULL)
	{
		Lunar<Player>::push(pState, poPlayer);
		return 1;
	}
	return 0;
}

int PlayerMgr::BindSession(lua_State* pState)
{
	int64_t nCharID = luaL_checkinteger(pState, 1);
	int nSession = (int)luaL_checkinteger(pState, 2);
	BindSession(nCharID, nSession);
	return 0;
}

int PlayerMgr::RemovePlayer(lua_State* pState)
{
	int64_t nCharID = luaL_checkinteger(pState, 1);
	RemovePlayer(nCharID);
	return 0;
}

int PlayerMgr::GetPlayer(lua_State* pState)
{
	int64_t nCharID = luaL_checkinteger(pState, 1);
	Player* poPlayer = GetPlayerByID(nCharID);
	if (poPlayer != NULL)
	{
		Lunar<Player>::push(pState, poPlayer);
		return 1;
	}
	return 0;
}