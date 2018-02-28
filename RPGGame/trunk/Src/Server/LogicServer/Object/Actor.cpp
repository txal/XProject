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

void Actor::StartRun(int nSpeedX, int nSpeedY)
{
	m_nRunStartMSTime = XTime::MSTime();
	m_nRunSpeedX = nSpeedX;
	m_nRunSpeedY = nSpeedY;
	m_nRunStartX = m_oPos.x;
	m_nRunStartY = m_oPos.y;
	BroadcastStartRun();
	//XLog(LEVEL_INFO,"%s Start run pos:(%d, %d) speed:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, nSpeedX, nSpeedY);
}

void Actor::StopRun(bool bBroadcast, bool bClientStop)
{
	if (m_nRunStartMSTime > 0)
	{
		m_nRunStartMSTime = 0;
		m_nRunSpeedX = 0;
		m_nRunSpeedY = 0;
		m_nRunStartX = 0;
		m_nRunStartY = 0;
		if (bBroadcast)
		{
			BroadcastStopRun();
		}
		//XLog(LEVEL_INFO, "%s Stop run pos:(%d, %d) client:%d time:%d\n", m_sName, m_oPos.x, m_oPos.y, bClientStop, m_nClientRunStartMSTime);
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
		//XLog(LEVEL_DEBUG, "Pos(%d,%d) canmove:%d\n", nNewPosX, nNewPosY, bCanMove);
	}
	return bCanMove;
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

void Actor::SyncPosition(const char* pWhere)
{
	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y;
	Packet* poPacket = gpoPacketCache->DeepCopy();

	NetAdapter::SERVICE_NAVI oNavi;
	oNavi.uSrcServer = g_poContext->GetServerID();
	oNavi.nSrcService = g_poContext->GetService()->GetServiceID();
	oNavi.uTarServer = GetServer();
	oNavi.nTarSession = GetSession();
	NetAdapter::SendExter(NSCltSrvCmd::sSyncActorPos, poPacket, oNavi);
}

void Actor::BroadcastStartRun()
{
	CacheActorNavi();
	if (goNaviCache.Size() <= 0)
	{
		return;
	}
	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int16_t)m_nRunSpeedX << (int16_t)m_nRunSpeedY;
	Packet* poPacket = gpoPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sBroadcastActorStartRun, poPacket, goNaviCache);
}

void Actor::BroadcastStopRun()
{
	CacheActorNavi();
	if (goNaviCache.Size() <= 0)
	{
		return;
	}

	gpoPacketCache->Reset();
	goPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y;
	Packet* poPacket = gpoPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sBroadcastActorStopRun, poPacket, goNaviCache);
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