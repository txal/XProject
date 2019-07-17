#ifndef __SCENEBASE_H__
#define __SCENEBASE_H__

#include "Include/Script/Script.hpp"

#include "Server/LogicServer/GameObject/ObjectDef.h"
#include "Server/LogicServer/SceneMgr/AOI.h"
#include "Server/LogicServer/SceneMgr/SceneDef.h"
#include "Common/DataStruct/XUUID.h"
#include "Common/DataStruct/Point.h"

class Object;
class SceneMgr;
struct MAPCONF;

class SceneBase
{
public:
	LUNAR_DECLARE_CLASS(SceneBase);
	friend class SceneMgr;

	typedef std::unordered_map<int64_t, Object*> GameObjMap;
	typedef GameObjMap::iterator GameObjIter;

public:
	SceneBase();
	virtual ~SceneBase();
	bool Init(SceneMgr* poSceneMgr, int64_t nSceneID, uint16_t uConfID, MAPCONF* poMapConf, SCENETYPE nSceneType, int nMaxLineObjs);

	void Update(int64_t nNowMS);
	bool IsDeleted() { return m_bIsDeleted; }
	void MarkDeleted() { m_bIsDeleted = true; }

	AOI* GetAOI() { return &m_oAOI; }
	Object* GetGameObjByAOIID(int nAOIID);
	Object* GetGameObjByObjID(int64_t nObjID);

	int64_t GetSceneID() { return m_nSceneID; }
	MAPCONF* GetMapConf() { return m_poMapConf; }
	SceneMgr* GetSceneMgr() { return m_poSceneMgr; }
	SCENETYPE GetSceneType() { return m_nSceneType; }
	GameObjMap& GetGameObjMap() { return m_oGameObjMap; }

public:
	int EnterScene(Object* poGameObj, int nPosX, int nPosY, int8_t nAOIMode, int nAOIArea[], int8_t nAOIType, int16_t nLine);
	void LeaveScene(int nAOIID, bool bKicked) { m_oAOI.RemoveAOIObj(nAOIID, true, bKicked); }

	void SetGameObjLine(int nAOIID, int16_t nLine) { m_oAOI.ChangeAOIObjLine(nAOIID, nLine); }
	void MoveGameObj(int nAOIID, int nTarX, int nTarY) { m_oAOI.MoveAOIObj(nAOIID, nTarX, nTarY); }

	void OnObjEnterScene(AOIOBJ* poAOIObj);
	void OnObjLeaveScene(AOIOBJ* poAOIObj, bool bKicked);
	void OnObjEnterObj(Array<AOIOBJ*>& oObserverCache, AOIOBJ* poObserved);
	void OnObjEnterObj(AOIOBJ* poObserver, Array<AOIOBJ*>& oObservedCache);
	void OnObjLeaveObj(Array<AOIOBJ*>& oObserverCache, AOIOBJ* poObserved);
	void OnObjLeaveObj(AOIOBJ* poObserver, Array<AOIOBJ*>& oObservedCache);

	Array<AOIOBJ*>& GetAreaObservers(int nAOIID, OBJTYPE nObjType);
	Array<AOIOBJ*>& GetAreaObserveds(int nAOIID, OBJTYPE nObjType);
	void KickAllGameObjs(int nObjType);

private:
	int m_nLuaObjRef;
	AOI m_oAOI;						//AOI
	Array<AOIOBJ*> m_oObjCache;		//AOI对象缓存
	GameObjMap m_oGameObjMap;		//游戏对象映射

	MAPCONF* m_poMapConf;			//地图配置
	SceneMgr* m_poSceneMgr;			//场景管理器
	SCENETYPE m_nSceneType;			//场景类型
	int64_t m_nSceneID;				//场景ID
	uint16_t m_uConfID;				//场景配置ID
	int m_nCreateTime;				//创建时间
	bool m_bIsDeleted;				//是否已被删除

	int64_t m_nLastUpdateTime;		//最后更新时间

private:
	DISALLOW_COPY_AND_ASSIGN(SceneBase);


/////////////////export to lua///////////////////////
public:
	int GetID(lua_State* pState);
	int GetConfID(lua_State* pState);
	int EnterScene(lua_State* pState);
	int LeaveScene(lua_State* pState);
	int GetSceneType(lua_State* pState);
	int GetCreateTime(lua_State* pState);
	int GetGameObj(lua_State* pState);
	int GetGameObjList(lua_State* pState);
	int GetGameObjCount(lua_State* pState);

	int AddObserver(lua_State* pState);
	int AddObserved(lua_State* pState);
	int RemoveObserver(lua_State* pState);
	int RemoveObserved(lua_State* pState);

	int GetAreaObservers(lua_State* pState);
	int GetAreaObserveds(lua_State* pState);

	int KickAllGameObjs(lua_State* pState);
	int DumpSceneInfo(lua_State* pState);

	int GetLuaObj(lua_State* pState);
	int BindLuaObj(lua_State* pState);
};


#endif
