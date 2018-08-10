#include "Server/LogicServer/Object/Actor.h"

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

void Actor::OnEnterScene(Scene* poScene, int nAOIID, const Point& oPos)
{
	Object::OnEnterScene(poScene, nAOIID, oPos);
	StopRun();
}

void Actor::AfterEnterScene()
{
	Object::AfterEnterScene();
}

void Actor::OnLeaveScene()
{
	Object::OnLeaveScene();
}

void Actor::Update(int64_t nNowMS)
{
	Object::Update(nNowMS);
	UpdateRunState(nNowMS);
}

void Actor::StartRun(int nSpeedX, int nSpeedY, int8_t nFace)
{
	m_nRunStartMSTime = XTime::MSTime();
	m_nRunSpeedX = nSpeedX;
	m_nRunSpeedY = nSpeedY;
	m_nRunStartX = m_oPos.x;
	m_nRunStartY = m_oPos.y;
	Object::SetFace(nFace);
	BroadcastStartRun();
	//XLog(LEVEL_INFO,"%s Start run pos:(%d, %d) speed:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, nSpeedX, nSpeedY);
}

void Actor::StopRun(bool bBroadcast, bool bClientStop)
{
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

bool Actor::UpdateRunState(int64_t nNowMS)
{
	bool bCanMove = false;
	if (m_nRunStartMSTime > 0 && GetScene() != NULL)
	{
		int nNewPosX = 0;
		int nNewPosY = 0;
		bCanMove = CalcPositionAtTime(nNowMS, nNewPosX, nNewPosY);
		Object::SetPos(Point(nNewPosX, nNewPosY));
		if (!bCanMove || (m_nRunSpeedX == 0 && m_nRunSpeedY == 0))
		{
			StopRun();
		}
		if (m_oTargetPos.IsValid() && m_oTargetPos.CheckDistance(m_oPos, Point(16,16)))
		{
			XLog(LEVEL_DEBUG, "%s reach target pos(%d,%d)\n", m_sName, m_oTargetPos.x, m_oTargetPos.y);
			StopRun();
			if (m_bRunCallback)
			{
				m_bRunCallback = false;
				LuaWrapper::Instance()->FastCallLuaRef<void>("OnObjReachPos", 0, "ii", m_nObjID, m_nObjType);
			}
		}
		UpdateFollow(nNowMS);
		//XLog(LEVEL_DEBUG, "Pos(%d,%d) canmove:%d\n", nNewPosX, nNewPosY, bCanMove);
	}
	return bCanMove;
}

void Actor::UpdateFollow(int64_t nNowMS)
{
	if (m_poScene == NULL)
		return;

	LogicServer* poLogic = (LogicServer*)(g_poContext->GetService());
	SceneMgr* poSceneMgr = poLogic->GetSceneMgr();

	RoleMgr* poRoleMgr = poLogic->GetRoleMgr();
	MonsterMgr* poMonsterMgr = poLogic->GetMonsterMgr();

	Follow::FollowVec* poFollowVec = (poSceneMgr->GetFollow()).GetFollowList(m_nObjType, m_nObjID);
	if (poFollowVec == NULL || poFollowVec->size() <= 0)
		return;

	const Point& oTarPos = GetPos();
	for (int i = 0; i < poFollowVec->size(); i++)
	{
		FOLLOW oFollow((*poFollowVec)[i]);

		Object* poFollowObj = NULL;
		if (oFollow.nObjType == eOT_Role)
			poFollowObj = poRoleMgr->GetRoleByID(oFollow.nObjID);
		else
			poFollowObj = poMonsterMgr->GetMonsterByID(oFollow.nObjID);

		if (poFollowObj == NULL || poFollowObj->GetScene() != m_poScene) continue;
		if (oTarPos.Distance(poFollowObj->GetPos()) >= (gnUnitWidth*gnTowerWidth)*0.5)
			poFollowObj->SetPos(oTarPos);
	}
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
	if (m_poScene == NULL)
	{
		return;
	}
	if (m_oPos == oTarPos)
	{
		return;
	}
	if (nMoveSpeed <= 0)
	{
		return;
	}

	float fMoveTime = BattleUtil::CalcMoveTime1(nMoveSpeed, m_oPos, oTarPos);
	int nSpeedX = (int)((oTarPos.x - m_oPos.x) / fMoveTime);
	int nSpeedY = (int)((oTarPos.y - m_oPos.y) / fMoveTime);
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
}

void Actor::SyncPosition(const char* pWhere)
{
	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int8_t)m_nFace;
	Packet* poPacket = gpoPacketCache->DeepCopy();

	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = g_poContext->GetServerID();
	oNavi.nSrcService = g_poContext->GetService()->GetServiceID();
	oNavi.uTarServer = GetServer();
	oNavi.nTarService = GetSession() >> SERVICE_SHIFT;
	oNavi.nTarSession = GetSession();
	NetAdapter::SendExter(NSCltSrvCmd::sSyncActorPosRet, poPacket, oNavi);
}

void Actor::BroadcastPos(bool bSelf)
{
	int nSelfServer = 0;
	int nSelfSession = 0;
	if (bSelf)
	{
		nSelfServer = m_uServer;
		nSelfSession = m_nSession;
	}
	CacheActorNavi(nSelfServer, nSelfSession);

	if (goNaviCache.Size() <= 0)
	{
		return;
	}

	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int8_t)m_nFace;
	Packet* poPacket = gpoPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sSyncActorPosRet, poPacket, goNaviCache);
}

void Actor::BroadcastStartRun()
{
	CacheActorNavi();
	if (goNaviCache.Size() <= 0)
	{
		return;
	}
	gpoPacketCache->Reset();
	uint16_t uTarPosX = (uint16_t)m_oTargetPos.x;
	uint16_t uTarPosY = (uint16_t)m_oTargetPos.y;
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int16_t)m_nRunSpeedX << (int16_t)m_nRunSpeedY << (uint8_t)m_nFace << uTarPosX << uTarPosY;
	Packet* poPacket = gpoPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sActorStartRunRet, poPacket, goNaviCache);
}

void Actor::BroadcastStopRun(bool bSelf)
{
	int nSelfServer = 0;
	int nSelfSession = 0;
	if (bSelf)
	{
		nSelfServer = m_uServer;
		nSelfSession = m_nSession;
	}
	CacheActorNavi(nSelfServer, nSelfSession);
	if (goNaviCache.Size() <= 0)
	{
		return;
	}

	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int8_t)m_nFace;
	Packet* poPacket = gpoPacketCache->DeepCopy();
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
	LogicServer * poLogic = (LogicServer*)g_poContext->GetService();
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
