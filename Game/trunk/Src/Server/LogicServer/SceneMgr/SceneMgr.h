#ifndef __SCENEMANAGER_H__
#define __SCENEMANAGER_H__

#include "Scene.h"

class SceneMgr
{
public:
	static char className[];
	static Lunar<SceneMgr>::RegType methods[];

	typedef std::unordered_map<uint32_t, Scene*> SceneMap;
	typedef SceneMap::iterator SceneIter;

public:
	SceneMgr();
	~SceneMgr();
	Scene* GetScene(uint32_t uSceneIndex);
	void RemoveScene(uint32_t uSceneIndex);
	void UpdateScenes(int64_t nNowMS);

private:
	uint32_t GenSceneIndex(uint16_t uConfID);
	void LogicToScreen(int nLogicX, int nLogicY, int &nScreenX, int &nSreenY); // Grid to Pixel
	void ScreenToLogic(int nScreenX, int nSreenY, int &nLogicX, int &nLogicY); // Pixel to Grid


/////////////lua export//////////
public:
	SceneMgr(lua_State* pState);
	int CreateScene(lua_State* pState);
	int RemoveScene(lua_State* pState);
	int GetScene(lua_State* pState);

private:

	// [nSceneIndex, Scene*]
	SceneMap m_oSceneMap;
	DISALLOW_COPY_AND_ASSIGN(SceneMgr);
};


//Register to lua
void RegClassScene();

#endif
