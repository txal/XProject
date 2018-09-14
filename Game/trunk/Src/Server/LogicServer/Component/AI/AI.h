#ifndef __AI_H__
#define __AI_H__

#include "Action.h"
#include "Common/Platform.h"

//角色层状态机
class AI
{
public:
	enum ActionType
	{
		eATT_Atk = 0,	//攻击
		eATT_Def = 1,	//防守
	};
	enum AIState
	{
		eAIS_None = -1,	//无
		eAIS_Idle = 0,	//空闲
		eAIS_Atk = 1,	//攻击
		eAIS_Def = 2,	//防守
	};

public:
	AI();
	virtual ~AI();

	bool Init(Actor* poActor, int nAIID);
	virtual void Update(int64_t nNowMS) = 0;
	AIConf* GetAIConf(){ return m_poAIConf; }
	void Stop();
	void Start();

protected:
	int SelectAction();
	int GetStateTime(int nState);
	void SetState(int nState, int nStateTime, int nLine = 0);

protected:
	virtual void SearchNearTarget(int64_t nNowMS) = 0;

protected:
	bool m_bRun;	
	int m_nState;
	int m_nLastState; //上1状态
	int64_t m_nStateTime;
	int64_t m_nNextAtkTime; //下次可攻击时间

	AIConf* m_poAIConf;
	Actor* m_poActor;
	Actor* m_poTarget;
	Action* m_poAction;
	int64_t m_nNextSearchTime;
	DISALLOW_COPY_AND_ASSIGN(AI);
};

////////怪物///////
class MonsterAI : public AI
{
public:
	MonsterAI();
	virtual void Update(int64_t nNowMS);

protected:
	void SearchNearTarget(int64_t nNowMS);
};

//////Robot/////////
class RobotAI : public AI
{
public:
	RobotAI();
	virtual void Update(int64_t nNowMS);

protected:
	void SearchNearTarget(int64_t nNowMS);	//搜索最近的目标
	void SearchViewTarget(int64_t nNowMS);	//搜索视野范围内的目标
};

#endif