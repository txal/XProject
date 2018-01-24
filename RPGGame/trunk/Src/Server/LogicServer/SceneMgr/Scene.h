#ifndef __SCENE_H__
#define __SCENE_H__

#include "AOI.h"
#include "Include/Script/Script.hpp"
#include "Common/DataStruct/ObjID.h"
#include "Common/DataStruct/Point.h"
#include "Common/DataStruct/Ranking.h"
#include "Server/LogicServer/Component/Rank/RankData.h"

class Object;
class Actor;
class Player;
class SceneMgr;
struct MapConf;
class Scene
{
public:
	static char className[];
	static Lunar<Scene>::RegType methods[];
	friend class SceneMgr;

	//<GameObjID, GameObjPointer>
	typedef std::unordered_map<int64_t, Object*> ObjMap;
	typedef ObjMap::iterator  ObjIter;

public:
	Scene(SceneMgr* poSceneMgr, uint32_t uSceneIndex, MapConf* poMapConf, uint8_t uBattleType, bool bCanCollected = true);
	~Scene();

	void Update(int64_t nNowMS);
	bool InitAOI(int nMapWidth, int nMapHeight)	{ return m_oAOI.Init(this, nMapWidth, nMapHeight); }
	bool IsTimeToCollected(int64_t nNowMS);

	ObjMap& GetObjMap()				{ return m_oObjMap; }
	int GetPlayerCount()			{ return m_nPlayerCount;  }
	MapConf* GetMapConf()			{ return m_poMapConf; }
	SceneMgr* GetSceneMgr()			{ return m_poSceneMgr;  }
	uint32_t GetSceneIndex()		{ return m_uSceneIndex; }
	Ranking<DmgData>& GetRanking()	{ return m_oDmgRanking; }
	Object* GetGameObj(int nAOIID);

public:
	int AddObj(Object* poObject, int nPosX, int nPosY, int8_t nAOIMode, int8_t nAOIType, int nAOIArea[]);
	void MoveObj(int nAOIObjID, int nTarX, int nTarY) { m_oAOI.MoveObj(nAOIObjID, nTarX, nTarY); }
	void RemoveObj(int nAOIObjID);
	void KickAllPlayer();

	void OnObjEnterScene(AOI_OBJ* pObj);	//进入场景但是未同步视野未
	void AfterObjEnterScene(AOI_OBJ* pObj);	//同步了视野后
	void OnObjLeaveScene(AOI_OBJ* pObj);
	void OnObjEnterObj(Array<AOI_OBJ*>& oObserverCache, AOI_OBJ* pObserved);
	void OnObjEnterObj(AOI_OBJ* pObserver, Array<AOI_OBJ*>& oObservedCache);
	void OnObjLeaveObj(Array<AOI_OBJ*>& oObserverCache, AOI_OBJ* pObserved);
	void OnObjLeaveObj(AOI_OBJ* pObserver, Array<AOI_OBJ*>& oObservedCache);
	Array<AOI_OBJ*>& GetAreaObservers(int nAOIObjID, int nGameObjType);
	Array<AOI_OBJ*>& GetAreaObserveds(int nAOIObjID, int nGameObjType);

public:
	void UpdateDamage(Actor* poAtker, Actor* poDefer, int nHP, int nAtkID, int nAtkType, bool bDead=false);

private:
	AOI m_oAOI;						//AOI
	Array<AOI_OBJ*> m_oObjCache;	//AOI对象缓存

	SceneMgr* m_poSceneMgr;
	uint32_t m_uSceneIndex;			//incrid|sysid
	bool m_bCanCollected;			//是否可以被收集
	
	ObjMap m_oObjMap;				//游戏对象列表
	uint16_t m_nPlayerCount;		//玩家数量

	int64_t m_nLastUpdateTime;		//上次更新时间(毫秒)
	int64_t m_nLastPlayerLeaveTime;	//最近玩家离开场景时间(毫秒)

	uint8_t m_uBattleType;			//战斗类型

	Ranking<DmgData> m_oDmgRanking;//伤害排行榜
	int64_t m_nLastDmgRankSyncTime;	//上次伤害排行榜广播时间

	MapConf* m_poMapConf;			//地图配置
	DISALLOW_COPY_AND_ASSIGN(Scene);


/////////////////export to lua///////////////////////
public:
	Scene(lua_State* pState);
	int GetSceneIndex(lua_State* pState);
	int AddObj(lua_State* pState);
	int GetObj(lua_State* pState);
	int MoveObj(lua_State* pState);
	int RemoveObj(lua_State* pState);
	int RemoveObserver(lua_State* pState);
	int RemoveObserved(lua_State* pState);
	int AddObserver(lua_State* pState);
	int AddObserved(lua_State* pState);
	int GetAreaObservers(lua_State* pState);
	int GetAreaObserveds(lua_State* pState);
	int GetSceneObjList(lua_State* pState);
	int KickAllPlayer(lua_State* pState);
	int BattleResult(lua_State* pState);
	int StartAI(lua_State* pState);
	int StopAI(lua_State* pState);
	int GetActorDmg(lua_State* pState);
};


#endif
