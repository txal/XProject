#ifndef __ACTION_H__
#define __ACTION_H__

#include "Common/Platform.h"
#include "Common/DataStruct/Point.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/Object/Actor.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

//行为层&基础层: 动作分解和执行控制
class Action
{
public:
	enum ActionState
	{
		eATS_None = -1,
		eATS_Idle = 0,
		eATS_AtkWalk = 1,	//攻击游走
		eATS_DefWalk = 2,	//防御巡逻
		eATS_Track = 3,		//追踪
	};

	typedef std::list<Point> PathList;
	typedef PathList::iterator PathIter;
public:
	Action();
	void Init(Actor* poActor, AIConf* poAIConf);
	void Update(int64_t nNowMS);
	void SetTarget(Actor* poTarget);
	int GetAtkDist();
	void Reset();

protected:
	void CalcTrackPos(); //计算目标坐标
	bool CalcWalkPos(); //计算防守游走坐标
	bool CheckDistance(const Point& oSrcPos, const Point& oTarPos, const Point& oDist); //检测距离
	bool CheckCanAttack(const Point& oSrcPos, const Point& oTarPos); //检测子弹能否飞越
	void StartMove(const Point& oStartPos, const Point& oTarPos, int nMoveSpeed, int nLine);	//开始跑动
	void GetRandomPos(const Point& oRefPos, int nRadius, Point& oTarPos);	//取随机点
	bool CheckAtkDistance(const Point& oSrcPos, const Point& oTarPos, int nDist); //检测攻击距离

protected:
	virtual void MoveTo(int nLine = 0);
	virtual void StopMove(int nLine = 0);
	virtual void Attack(float fAngle) = 0;
	virtual void StopAttack() = 0;

protected:
	void SetState(int nState, int nStateTime, int nLine = 0);

protected:
	AIConf* m_poAIConf;
	Actor* m_poActor;
	Actor* m_poTarget;

	//追踪目标相关
	Point m_oMinDist;				//最小距离
	int m_nAtkDist;					//攻击距离
	Point m_oAtkPos;				//目标点-攻击距离
	Point m_oMoveTarPos;			//移动目标位置
	Point m_oNextPos;				//下1坐标(A*)
	bool m_bTarPosChange;			//目标位置变更
	PathList m_oListPath;			//A星路径

	//卡点检测
	Point m_oLastActorPos;			//角色上1位置(判定Blocking)
	int m_nLastActorFrame;			//上次卡点检测帧

	//游走相关
	Point m_oRefPos;				//参考点
	int m_nWalkRadius;				//半径

	int m_nState;					//状态
	int m_nLastState;				//上1状态
	int64_t m_nStateTime;			//状态时间
	int64_t m_nLastMoveTime;		//上次移动时间
	DISALLOW_COPY_AND_ASSIGN(Action);
};

///////////怪物行为//////////
class MonsterAction : public Action
{
protected:
	virtual void Attack(float fAngle);
	virtual void StopAttack();
};

//////////机器人行为////////
class RobotAction : public Action
{
protected:
	virtual void Attack(float fAngle);
	virtual void StopAttack();
};

#endif