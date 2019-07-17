#include "Server/LogicServer/GameObject/Actor.h"

#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/TimeMonitor.h"

#include "Server/Base/CmdDef.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

LUNAR_IMPLEMENT_CLASS(Actor)
{
	DECLEAR_OBJECT_METHOD(Actor),
	DECLEAR_ACTOR_METHOD(Actor),
	{ 0, 0 },
};

Actor::Actor()
{
	m_uServer = 0;
	m_nSession = 0;

	m_nRunSpeedX = 0;
	m_nRunSpeedY = 0;
	m_nRunStartX = 0;
	m_nRunStartY = 0;
	m_nRunStartMSTime = 0;
	m_nClientRunStartMSTime = 0;

	m_bRunCallback = false;

}

Actor::~Actor()
{
}

void Actor::OnEnterScene(SceneBase* poScene, int nAOIID, Point& oPos)
{
	Object::OnEnterScene(poScene, nAOIID, oPos);
	StopRun();
}

void Actor::StartRun(int nSpeedX, int nSpeedY, int8_t nFace)
{
	if (!m_oTargetPos.IsValid())
	{
		XLog(LEVEL_ERROR, "Actor::StartRun target pos error!\n");
		return;
	}
	m_nRunStartMSTime = XTime::MSTime();
	m_nRunSpeedX = nSpeedX;
	m_nRunSpeedY = nSpeedY;
	m_nRunStartX = m_oPos.x;
	m_nRunStartY = m_oPos.y;
	SetFace(nFace);
	BroadcastStartRun();
	//XLog(LEVEL_INFO,"%s Start run pos:(%d, %d) speed:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, nSpeedX, nSpeedY);
}

void Actor::StopRun(bool bBroadcast, bool bClientStop)
{
	m_oLastTargetPos = m_oTargetPos;
	m_oTargetPos.Reset();
	if (m_nRunStartMSTime > 0)
	{
		m_nRunStartMSTime = 0;
		m_nRunSpeedX = 0;
		m_nRunSpeedY = 0;
		m_nRunStartX = 0;
		m_nRunStartY = 0;
		if (bBroadcast)
		{
			BroadcastStopRun(!bClientStop);
		}
		//XLog(LEVEL_INFO, "%s Stop run pos:(%d, %d) from_client:%d time:%d\n", m_sName, m_oPos.x, m_oPos.y, bClientStop, m_nClientRunStartMSTime);
	}
}

void Actor::UpdateRunState(int64_t nNowMS)
{
	if (m_nRunStartMSTime > 0 && GetScene() != NULL)
	{
		int nNewPosX = 0;
		int nNewPosY = 0;

		bool bCanMove = CalcPositionAtTime(nNowMS, nNewPosX, nNewPosY);
		SetPos(Point(nNewPosX, nNewPosY));
		if (!bCanMove || (m_nRunSpeedX == 0 && m_nRunSpeedY == 0))
		{
			StopRun();
		}
		if (m_oTargetPos.IsValid())
		{
			Point oStartPos(m_nRunStartX, m_nRunStartY);
			if (m_oPos.Distance(oStartPos) >= m_oTargetPos.Distance(oStartPos))
			{
				XLog(LEVEL_DEBUG, "%d %s reach target pos(%d,%d) tarpos(%d,%d)\n", time(NULL), m_sName, m_oPos.x, m_oPos.y, m_oTargetPos.x, m_oTargetPos.y);
				SetPos(m_oTargetPos);
				StopRun();

				if (m_bRunCallback)
				{
					m_bRunCallback = false;
					OnReacheTargetPos();
				}
			}
		}
	}
}

void Actor::OnReacheTargetPos()
{
	lua_State* pState = LuaWrapper::Instance()->GetLuaState();
	Lunar<SceneBase>::push(pState, m_poScene);
	Lunar<Actor>::push(pState, this);
	lua_pushinteger(pState, m_oTargetPos.x);
	lua_pushinteger(pState, m_oTargetPos.y);
	LuaWrapper::Instance()->CallLuaRef("OnObjReachTargetPos", 4, 0);
}

bool Actor::CalcPositionAtTime(int64_t nNowMS, int& nNewPosX, int& nNewPosY)
{
	int nNewX = m_nRunStartX;
	int nNewY = m_nRunStartY;
	int nTimeElapased = (int)(nNowMS - m_nRunStartMSTime);

	if (nTimeElapased > 0)
	{
		//常规移动计算
		nNewX += (int)((m_nRunSpeedX * nTimeElapased) * 0.001);
		nNewY += (int)((m_nRunSpeedY * nTimeElapased) * 0.001);
	}

	bool bRes = true;
	if (nNewX != m_oPos.x || nNewY != m_oPos.y)
	{
		bRes = BattleUtil::FixLineMovePoint(GetScene()->GetMapConf(), m_oPos.x, m_oPos.y, nNewX, nNewY, this);
	}
	nNewPosX = nNewX;
	nNewPosY = nNewY;
	return bRes;
}

void Actor::RunTo(const Point& oTarPos, int nMoveSpeed)
{
	if (m_poScene == NULL  || m_oPos == oTarPos || nMoveSpeed <= 0)
	{
		return;
	}

	int nSpeedX = 0;
	int nSpeedY = 0;
	BattleUtil::CalcMoveSpeed1(nMoveSpeed, m_oPos, oTarPos, nSpeedX, nSpeedY);
	if (nSpeedX == 0 && nSpeedY == 0)
	{
		StopRun();
	}

	int nOldSpeedX = GetSpeedX();
	int nOldSpeedY = GetSpeedY();
	if (!IsRunning() || nSpeedX != nOldSpeedX || nSpeedY != nOldSpeedY)
	{
		m_oTargetPos = oTarPos;
		m_bRunCallback = true;
		StartRun(nSpeedX, nSpeedY, m_nFace);
	}
#ifdef _DEBUG
	XLog(LEVEL_DEBUG, "%d %s run to speed(%d,%d), pos(%d,%d), tarpos(%d,%d)\n", time(NULL), m_sName, nSpeedX, nSpeedY, m_oPos.x, m_oPos.y, oTarPos.x, oTarPos.y);
#endif // _DEBUG

}

//同步自己坐标
void Actor::SyncPosition()
{
	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int8_t)m_nFace;
	Packet* poPacket = gpoPacketCache->DeepCopy(__FILE__, __LINE__);

	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = gpoContext->GetServerConfig().GetServerID();
	oNavi.nSrcService = gpoContext->GetService()->GetServiceID();
	oNavi.uTarServer = GetServer();
	oNavi.nTarService = GetSession() >> SERVICE_SHIFT;
	oNavi.nTarSession = GetSession();
	NetAdapter::SendExter(NSCltSrvCmd::sSyncActorPosRet, poPacket, oNavi);
}

//广播当前位置
//@bSelf 是否广播给自己
void Actor::BroadcastPos(bool bSelf)
{
	int nSelfServer = 0;
	int nSelfSession = 0;
	if (bSelf)
	{
		nSelfServer = m_uServer;
		nSelfSession = m_nSession;
	}
	CacheObjNavi(nSelfServer, nSelfSession);

	if (goNaviCache.Size() <= 0)
	{
		return;
	}

	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int8_t)m_nFace;
	Packet* poPacket = gpoPacketCache->DeepCopy(__FILE__, __LINE__);
	NetAdapter::BroadcastExter(NSCltSrvCmd::sSyncActorPosRet, poPacket, goNaviCache);
}

//广播起跑,不广播给自己
void Actor::BroadcastStartRun()
{
	CacheObjNavi();
	if (goNaviCache.Size() <= 0)
	{
		return;
	}
	gpoPacketCache->Reset();
	uint16_t uTarPosX = (uint16_t)m_oTargetPos.x;
	uint16_t uTarPosY = (uint16_t)m_oTargetPos.y;
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int16_t)m_nRunSpeedX << (int16_t)m_nRunSpeedY << (uint8_t)m_nFace << uTarPosX << uTarPosY;
	Packet* poPacket = gpoPacketCache->DeepCopy(__FILE__, __LINE__);
	NetAdapter::BroadcastExter(NSCltSrvCmd::sActorStartRunRet, poPacket, goNaviCache);
}

//广播停止跑动
//@bSelf 是否广播给自己
void Actor::BroadcastStopRun(bool bSelf)
{
	int nSelfServer = 0;
	int nSelfSession = 0;
	if (bSelf)
	{
		nSelfServer = m_uServer;
		nSelfSession = m_nSession;
	}
	CacheObjNavi(nSelfServer, nSelfSession);
	if (goNaviCache.Size() <= 0)
	{
		return;
	}

	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int8_t)m_nFace;
	Packet* poPacket = gpoPacketCache->DeepCopy(__FILE__, __LINE__);
	NetAdapter::BroadcastExter(NSCltSrvCmd::sActorStopRunRet, poPacket, goNaviCache);
}


///////////////lua export//////////////////
#define GET_FIGHT_PARAM(pState, nType) \
{\
lua_rawgeti(pState, -1, nType); \
m_oFightParam[nType] = (int)lua_tointeger(pState, -1); \
lua_pop(pState, 1); \
}

#define PUSH_FIGHT_PARAM(pState, nType) \
{\
lua_pushinteger(pState, m_oFightParam[nType]); \
lua_rawseti(pState, -2, nType);\
}

int Actor::GetRunSpeed(lua_State* pState)
{
	lua_pushinteger(pState, m_nRunSpeedX);
	lua_pushinteger(pState, m_nRunSpeedY);
	return 2;
}

int Actor::BindSession(lua_State* pState)
{
	int nSession = (int)lua_tointeger(pState, -1);
	LogicServer * poLogic = (LogicServer*)gpoContext->GetService();
	poLogic->GetRoleMgr()->BindSession(m_nObjID, nSession);
	return 0;
}

int Actor::StopRun(lua_State* pState)
{
	StopRun();
	return 0;
}

int Actor::RunTo(lua_State* pState)
{
	int nPosX = (int)luaL_checkinteger(pState, 1);
	int nPosY = (int)luaL_checkinteger(pState, 2);
	int nSpeed = (int)luaL_checkinteger(pState, 3);
	RunTo(Point(nPosX, nPosY), nSpeed);
	return 0;
}

int Actor::GetTarPos(lua_State* pState)
{
	lua_pushinteger(pState, m_oTargetPos.x);
	lua_pushinteger(pState, m_oTargetPos.y);
	return 2;
}
