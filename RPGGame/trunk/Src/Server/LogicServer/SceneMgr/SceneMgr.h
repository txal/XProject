#ifndef __SCENEMANAGER_H__
#define __SCENEMANAGER_H__

#include "Server/LogicServer/SceneMgr/Scene.h"
#include "Server/LogicServer/Object/Follow.h"

class SceneMgr
{
public:
	LUNAR_DECLARE_CLASS(SceneMgr);

	typedef std::unordered_map<int64_t, Scene*> SceneMap;
	typedef SceneMap::iterator SceneIter;

public:
	SceneMgr();
	~SceneMgr();
	Scene* GetScene(int64_t nSceneIndex);
	void RemoveScene(int64_t nSceneIndex);

public:
	void Update(int64_t nNowMS);
	Follow& GetFollow() { return m_oFollow; }

private:
	int64_t GenSceneMixID(uint16_t uConfID);
	void LogicToScreen(int nLogicX, int nLogicY, int &nScreenX, int &nSreenY); // Grid to Pixel
	void ScreenToLogic(int nScreenX, int nSreenY, int &nLogicX, int &nLogicY); // Pixel to Grid


/////////////lua export//////////
public:
	int CreateDup(lua_State* pState);
	int RemoveDup(lua_State* pState);
	int GetDup(lua_State* pState);
	int SetFollow(lua_State* pState);

private:

	//[mixid, scene*]
	SceneMap m_oSceneMap;

	//跟随管理
	Follow m_oFollow;


	DISALLOW_COPY_AND_ASSIGN(SceneMgr);
};


//Register to lua
void RegClassScene();

#endif
