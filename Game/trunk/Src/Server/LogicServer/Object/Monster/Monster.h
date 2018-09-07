#ifndef __MONSTER_H__
#define __MONSTER_H__

#include "Server/LogicServer/Component/AI/AI.h"
#include "Server/LogicServer/Component/AStar/AStarPathFind.h"
#include "Server/LogicServer/Object/Actor.h"

class Monster : public Actor
{
public:
	LUNAR_DECLARE_CLASS(Monster);

public:
	Monster();
	virtual ~Monster();
	void Init(const GAME_OBJID& oObjID, int nConfID, const char* psName, int nAIID, int8_t nCamp);

public:
	virtual void Update(int64_t nNowMS);
	virtual void OnEnterScene(Scene* poScene, const Point& oPos, int nAOIID);
	virtual void AfterEnterScene();
	virtual void OnLeaveScene();
	virtual void OnDead(Actor* poAtker, int nAtkID, int nAtkType);
	virtual void OnBattleResult();
	virtual void OnRelive();

public:
	AI* GetAI() { return m_poAI; }
	AStarPathFind* GetAStar() { return &m_oAStar; }
	void StartMonsterAttack(float fAngle);
	void StopMonsterAttack();

private:
	int m_nHPSyncInterval;			//血量同步间隔(毫秒)
	int64_t m_nLastHPSyncTime;		//上次同步血量时间(毫秒)

	AI* m_poAI;						//AI
	int m_nAIID;					//A编号
	AStarPathFind m_oAStar;			//
	DISALLOW_COPY_AND_ASSIGN(Monster);


/////////////////lua export////////////
public:
	int MoveTo(lua_State* pState);
};

#endif