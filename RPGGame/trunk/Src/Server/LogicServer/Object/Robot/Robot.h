#ifndef __ROBOT_H__
#define __ROBOT_H__

#include "Server/LogicServer/Component/AI/AI.h"
#include "Server/LogicServer/Component/AStar/AStarPathFind.h"
#include "Server/LogicServer/Component/Battle/WeaponList.h"
#include "Server/LogicServer/Object/Actor.h"

class Robot : public Actor
{
public:
	LUNAR_DECLARE_CLASS(Robot);

public:
	typedef Actor super;
	Robot();
	virtual ~Robot();

public:
	void Init(int nObjID, int nConfID, const char* psName, int nAOIID, int8_t nCamp, uint16_t uSyncHPTime);

public:
	virtual void Update(int64_t nNowMS);
	virtual void AfterEnterScene();
	virtual void OnLeaveScene();
	virtual void OnDead(Actor* poAtker, int nAtkID, int nAtkType);
	virtual void OnBattleResult();
	virtual void OnRelive();

public:
	AI* GetAI()					{ return m_poAI;  }
	AStarPathFind* GetAStar()	{ return &m_oAStar; }

	void StartRobotAttack(float fAngle);
	void StopRobotAttack();

private:
	bool ReloadBullet();
	bool SwitchWeapon();
	bool CheckReloadAndAttack();
	bool IsReloading(int64_t nNowMS);
	void OnBulletConsume();
	void BombAttack();

private:
	int m_nHPSyncInterval;			//血量同步间隔(毫秒)
	int64_t m_nLastHPSyncTime;		//上次同步血量时间(毫秒)

	AI* m_poAI;						//AI
	int m_nAIID;					//AI编号
	AStarPathFind m_oAStar;			//

	int m_nMoveSpeed;				//移动速度
	float m_fAtkAngle;				//攻击角度
	int64_t m_nStartAttackTime;		//开始攻击时间

	int64_t m_nReloadCompleteTime;	//换弹夹完成时间
	bool m_bReloading;				//在换弹夹中

	WeaponList m_oOrgWeaponList;	//原始武器列表
	WeaponList m_oHotWeaponList;	//当前轮换的武器列表
	int8_t m_nGunIndex;				//当前使用
	DISALLOW_COPY_AND_ASSIGN(Robot);



//////////////lua export////////////
public:
	int SetWeaponList(lua_State* pState);
};

#endif