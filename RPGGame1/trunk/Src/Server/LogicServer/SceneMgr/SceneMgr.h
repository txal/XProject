#ifndef __SCENEMANAGER_H__
#define __SCENEMANAGER_H__

#include "Server/LogicServer/SceneMgr/SceneBase.h"

class SceneMgr
{
public:
	LUNAR_DECLARE_CLASS(SceneMgr);

	typedef std::unordered_map<int64_t, SceneBase*> SceneMap;
	typedef SceneMap::iterator SceneIter;

public:
	SceneMgr();
	~SceneMgr();
	SceneBase* GetScene(int64_t nSceneID);
	void RemoveScene(int64_t nSceneID);

public:
	void Update(int64_t nNowMS);

private:
	void LogicToScreen(int nLogicX, int nLogicY, int &nScreenX, int &nSreenY); // Grid to Pixel
	void ScreenToLogic(int nScreenX, int nSreenY, int &nLogicX, int &nLogicY); // Pixel to Grid


/////////////lua export//////////
public:
	int CreateScene(lua_State* pState);
	int RemoveScene(lua_State* pState);
	int GetScene(lua_State* pState);
	int GetSceneList(lua_State* pState);
	int DumpSceneInfo(lua_State* pState);

private:
	//[id, scene*]
	SceneMap m_oSceneMap;

private:
	DISALLOW_COPY_AND_ASSIGN(SceneMgr);
};


//Register to lua
void RegClassScene();

#endif
