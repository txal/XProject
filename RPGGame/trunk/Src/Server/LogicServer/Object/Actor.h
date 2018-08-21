#ifndef __ACTOR_H__
#define __ACTOR_H__

#include "Include/Script/Script.hpp"
#include "Server/LogicServer/Object/Object.h"

class Actor : public Object
{
public:
	LUNAR_DECLARE_CLASS(Actor);

public:
    Actor();
    virtual ~Actor();

public:
	bool IsRunning() { return m_nRunStartMSTime > 0; }
	void SetServer(uint16_t uServer) { m_uServer = uServer; }
	void SetSession(int nSession) { m_nSession = nSession; }

	int GetSpeedX() { return m_nRunSpeedX; }
	int GetSpeedY() { return m_nRunSpeedY; }

public:
	virtual void Update(int64_t nNowMS);
	virtual void OnEnterScene(Scene* poScene, int nAOIID, const Point& oPos);
	virtual void AfterEnterScene();
	virtual void OnLeaveScene();
	virtual int GetSession() { return m_nSession; }
	virtual uint16_t GetServer() { return m_uServer; }

public:
	void StartRun(int nSpeedX, int nSpeedY, int8_t nFace);					//开始跑动
	void StopRun(bool bBroadcast=true, bool bClientStop=false);				//停止跑动
	bool CalcPositionAtTime(int64_t nNowMS, int& nNewPosX, int& nNewPosY);	//计算角色位置
	void RunTo(const Point& oTarPos, int nMoveSpeed);						//跑到目标位置
	void SetTargetPos(const Point& oTargetPos) { m_oTargetPos = oTargetPos; }

protected:
	virtual bool UpdateRunState(int64_t nNowMS);	//处理跑步
	virtual void UpdateFollow(int64_t nNowMS);		//处理跟随
	virtual void UpdateViewList(int64_t nNowMS);	//处理视野

//网络函数
public:
	void BroadcastStartRun();
	void BroadcastStopRun(bool bSelf);
	void SyncPosition(const char* pWhere = NULL);
	void BroadcastPos(bool bSelf);

protected:
	uint16_t m_uServer;					//所属服务器
	int m_nSession;						//网络句柄

	//跑动
	int m_nRunSpeedX;					//速度(像素/秒)
	int m_nRunSpeedY;					
	int m_nRunStartX;					//起跑坐标
	int m_nRunStartY;					
	int64_t m_nRunStartMSTime;			//服务器开跑时间(毫秒)
	int64_t m_nClientRunStartMSTime;	//客户端开跑时间(毫秒)

	Point m_oTargetPos;					//目标点
	Point m_oLastTargetPos;				//上次目标点

	bool m_bRunCallback;				//移动到目标点回调

	DISALLOW_COPY_AND_ASSIGN(Actor);


////////////////lua export//////////////////////
public:
	int GetRunSpeed(lua_State* pState);
	int BindSession(lua_State* pState);
	int StopRun(lua_State* pState);
	int RunTo(lua_State* pState);
	
};

#define DECLEAR_ACTOR_METHOD(Class) \
	LUNAR_DECLARE_METHOD(Class, GetRunSpeed),\
	LUNAR_DECLARE_METHOD(Class, BindSession),\
	LUNAR_DECLARE_METHOD(Class, StopRun),\
	LUNAR_DECLARE_METHOD(Class, RunTo)



#endif
