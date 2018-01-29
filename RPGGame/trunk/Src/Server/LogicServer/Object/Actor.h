#ifndef __ACTOR_H__
#define __ACTOR_H__

#include "Include/Script/Script.hpp"
#include "Server/LogicServer/Object/Object.h"
#include "Server/LogicServer/Component/Battle/BattleDef.h"

class Buff;
class Actor : public Object
{
public:
	LUNAR_DECLARE_CLASS(Actor);

	//<buffid, buff*>
	typedef std::unordered_map<int, Buff*> BuffMap;
	typedef BuffMap::iterator BuffIter;

	//<objid, hurt>
	typedef std::unordered_map<int64_t, HATE> HateMap;
	typedef HateMap::iterator HateIter;

public:
    Actor();
    virtual ~Actor();

public:
	bool IsDead() { return m_bDead; }
	bool IsRunning() { return m_nRunStartMSTime > 0; }

    FIGHT_PARAM& GetFightParam() { return m_oFightParam; }
	int GetRelives() { return m_uRelives; }

	int GetSession() { return m_nSession; }
	void SetSession(int nSession) { m_nSession = nSession; }

	uint16_t GetServer() { return m_uServer; }
	void SetServer(uint16_t uServer) { m_uServer = uServer; }

	int GetSpeedX() { return m_nRunSpeedX; }
	int GetSpeedY() { return m_nRunSpeedY; }

	int GetStaticSpeed() { return m_oFightParam[eFP_Speed]; }

	//仇恨
	HATE* GetHate(GAME_OBJID& oObjID);
	void AddHate(Actor* poAckter, int nValue);

public:
	virtual void Update(int64_t nNowMS);	//定时更新
	virtual void OnEnterScene(Scene* poScene, const Point& oPos, int nAOIID);
	virtual void AfterEnterScene();
	virtual void OnLeaveScene();
	virtual void OnHurted(Actor* poAtker, int nHP, int nAtkID, int nAtkType);
	virtual void OnDead(Actor* poAtker,  int nAtkID, int nAtkType);
	virtual void OnRelive() {}
	virtual void OnBattleResult() {}

public:
	void StartRun(int nSpeedX, int nSpeedY);									//开始跑动
	void StopRun(bool bBroadcast = true, bool bClientStop = false);				//停止跑动
	bool CalcNewPositionAtTime(int64_t nNowMS, int& nNewPosX, int& nNewPosY);	//计算服务角色位置

	void StartAttack(int nPosX, int nPosY, int nAtkID, int nAtkType, float fAngle, int nRemainBullet);
	void StopAttack();

protected:
	void ClearBuff();
	Buff* GetBuff(int nBuffID);

	bool Relive(int nPosX, int nPosY);		//复活
	void UpdateBuff(int64_t nNowMS);		//处理BUFF
	bool UpdateRunState(int64_t nNowMS);	//处理跑步

//网络函数
public:
	void SendSyncPosition(const char* pWhere = NULL);

	void BroadcastStartRun();
	void BroadcastStopRun();
	void BroadcastActorHurt(int nSrcAOIID, int nSrcType, int nCurrHP, int nHurtHP);
	void BroadcastActorDead();
	void BroadcastSyncHP();				//场景同步血量

protected:
	uint16_t m_uServer;					//所在服务器
	int m_nSession;						//网络句柄

	//跑动
	int m_nRunSpeedX;					//像素/秒
	int m_nRunSpeedY;					//像素/秒
	int m_nRunStartX;					//起跑坐标
	int m_nRunStartY;					
	int64_t m_nRunStartMSTime;			//服务器开跑时间(毫秒)
	int64_t m_nClientRunStartMSTime;	//客户端开跑时间(毫秒)

	//战斗
	bool m_bDead;						//死亡
	BuffMap m_oBuffMap;					//BUFF
    FIGHT_PARAM m_oFightParam;			//战斗属性
	int m_nLastBuffUpdateTime;			//上次更新BUFF时间(秒)
	bool m_bAttacking;					//是否正在攻击
	bool m_bBloodChange;				//血量是否发生改变(定时同步血量用)

	//仇恨列表
	HateMap m_oHateMap;					//仇恨列表
	uint8_t m_uRelives;					//复活次数
	DISALLOW_COPY_AND_ASSIGN(Actor);



////////////////lua export//////////////////////
public:
	int InitFightParam(lua_State* pState);
	int UpdateFightParam(lua_State* pState);
	int GetFightParam(lua_State* pState);
	int GetRunningSpeed(lua_State* pState);

	int AddBuff(lua_State* pState);
	int ClearBuff(lua_State* pState);

	int IsDead(lua_State* pState);
	int Relive(lua_State* pState);
	
};

#define DECLEAR_ACTOR_METHOD(Class) \
	LUNAR_DECLARE_METHOD(Class, InitFightParam), \
	LUNAR_DECLARE_METHOD(Class, UpdateFightParam), \
	LUNAR_DECLARE_METHOD(Class, GetFightParam), \
	LUNAR_DECLARE_METHOD(Class, GetRunningSpeed), \
	LUNAR_DECLARE_METHOD(Class, AddBuff), \
	LUNAR_DECLARE_METHOD(Class, ClearBuff),\
	LUNAR_DECLARE_METHOD(Class, IsDead),\
	LUNAR_DECLARE_METHOD(Class, Relive)


#endif
