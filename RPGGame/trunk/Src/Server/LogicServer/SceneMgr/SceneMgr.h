#ifndef __SCENEMANAGER_H__
#define __SCENEMANAGER_H__

#include "Scene.h"

class SceneMgr
{
public:
	LUNAR_DECLARE_CLASS(SceneMgr);

	typedef std::unordered_map<uint32_t, Scene*> SceneMap;
	typedef SceneMap::iterator SceneIter;

public:
	SceneMgr();
	~SceneMgr();
	Scene* GetScene(uint32_t uSceneIndex);
	void RemoveScene(uint32_t uSceneIndex);

public:
	void Update(int64_t nNowMS);

private:
	uint32_t GenSceneMixID(uint16_t uConfID);
	void LogicToScreen(int nLogicX, int nLogicY, int &nScreenX, int &nSreenY); // Grid to Pixel
	void ScreenToLogic(int nScreenX, int nSreenY, int &nLogicX, int &nLogicY); // Pixel to Grid


/////////////lua export//////////
public:
	int CreateDup(lua_State* pState);
	int RemoveDup(lua_State* pState);
	int GetDup(lua_State* pState);

private:

	// [mixid, scene*]
	SceneMap m_oSceneMap;
	DISALLOW_COPY_AND_ASSIGN(SceneMgr);
};


//Register to lua
void RegClassScene();

#endif
