#ifndef __PLAYERMGR_H__
#define __PLAYERMGR_H__

#include "Include/Script/Script.hpp"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/Object/Player/Player.h"

class PlayerMgr
{
public:
	LUNAR_DECLARE_CLASS(PlayerMgr);

	typedef std::unordered_map<int64_t, Player*> PlayerIDMap;
	typedef PlayerIDMap::iterator PlayerIDIter;

	typedef std::unordered_map<int, Player*> PlayerSessionMap;
	typedef PlayerSessionMap::iterator PlayerSessionIter;

public:
	PlayerMgr();
	Player* CreatePlayer(const GAME_OBJID& oID, int nRoleID, const char* psName, int8_t nCamp);
	void RemovePlayer(const GAME_OBJID& oID);

	Player* GetPlayerByID(const GAME_OBJID& oID);
	Player* GetPlayerBySession(int nSession);

	void BindSession(const GAME_OBJID& oID, int nSession);

public:
	void UpdatePlayers(int64_t nNowMS);



////////////////Lua export///////////////////
public:
	int CreatePlayer(lua_State* pState);
	int BindSession(lua_State* pState);
	int RemovePlayer(lua_State* pState);
	int GetPlayer(lua_State* pState);

private:
	PlayerIDMap m_oPlayerIDMap;
	PlayerSessionMap m_oPlayerSessionMap;
};




//Register to lua
void RegClassPlayer();

#endif