#ifndef __ACTOR_H__
#define __ACTOR_H__

#include "Include/Script/Script.hpp"
#include "Server/LogicServer/Component/AStar/AStarPathFind.h"
#include "Server/LogicServer/GameObject/Object.h"

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
	void OnEnterScene(SceneBase* poScene, int nAOIID, Point& oPos);

	virtual int GetSession() { return m_nSession; }
	virtual uint16_t GetServer() { return m_uServer; }
	virtual AStarPathFind* GetAStar() { return NULL; }

public:
	void RunTo(const Point& oTarPos, int nMoveSpeed);						//跑到目标位置
	void StartRun(int nSpeedX, int nSpeedY, int8_t nFace);					//开始跑动
	void StopRun(bool bBroadcast=true, bool bClientStop=false);				//停止跑动
	bool CalcPositionAtTime(int64_t nNowMS, int& nNewPosX, int& nNewPosY);	//计算角色位置
	void SetTargetPos(Point& oTargetPos) { m_oTargetPos = oTargetPos; }
	void OnReacheTargetPos();

//网络函数
public:
	void BroadcastStartRun();
	void BroadcastStopRun(bool bSelf);
	void BroadcastPos(bool bSelf);
	void SyncPosition();

protected:
	virtual void UpdateRunState(int64_t nNowMS);	//处理跑步

protected:
	int m_nSession;						//网络句柄
	uint16_t m_uServer;					//所属服务器

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

private:
	DISALLOW_COPY_AND_ASSIGN(Actor);


////////////////lua export//////////////////////
public:
	int GetRunSpeed(lua_State* pState);
	int BindServer(lua_State* pState);
	int BindSession(lua_State* pState);
	int StopRun(lua_State* pState);
	int RunTo(lua_State* pState);
	int GetTarPos(lua_State* pState);
	
};

#define DECLEAR_ACTOR_METHOD(Class) \
	LUNAR_DECLARE_METHOD(Class, GetRunSpeed),\
	LUNAR_DECLARE_METHOD(Class, BindSession),\
	LUNAR_DECLARE_METHOD(Class, StopRun),\
	LUNAR_DECLARE_METHOD(Class, RunTo),\
	LUNAR_DECLARE_METHOD(Class, GetTarPos)



#endif
