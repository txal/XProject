#include "Server/LogicServer/Object/Actor.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/TimeMonitor.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/Component/Buff/Buff.h"
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
	m_nSession = 0;

	m_nRunSpeedX = 0;
	m_nRunSpeedY = 0;
	m_nRunStartX = 0;
	m_nRunStartY = 0;
	m_nRunStartMSTime = 0;
	m_nClientRunStartMSTime = 0;

	m_bDead = false;
	m_bAttacking = false;
	m_bBloodChange = false;
	m_nLastBuffUpdateTime = XTime::Time();
}

Actor::~Actor()
{
	ClearBuff();
}

void Actor::OnEnterScene(Scene* poScene, const Point& oPos, int nAOIID)
{
	Object::OnEnterScene(poScene, oPos, nAOIID);
	m_bDead = false;
	StopRun();
}

void Actor::AfterEnterScene()
{
	Object::AfterEnterScene();
}

void Actor::OnLeaveScene()
{
	Object::OnLeaveScene();
	ClearBuff();
	m_uRelives = 0;
}

void Actor::OnDead(Actor* poAtker, int nAtkID, int nAtkType)
{
	if (poAtker == NULL)
	{
		return;
	}
	if (IsDead() || GetScene() == NULL)
	{
		return;
	}
	m_bDead = true;
	StopRun();
	ClearBuff();
	StopAttack();
	m_oHateMap.clear();
	BroadcastActorDead();

	LuaWrapper::Instance()->FastCallLuaRef<void>("OnActorDead", 0, "iiiiii", m_oObjID.llID, m_nObjType, poAtker->GetID().llID, poAtker->GetType(), nAtkID, nAtkType);

}

void Actor::OnHurted(Actor* poAtker, int nHP, int nAtkID, int nAtkType)
{
	if (IsDead() || GetScene() == NULL)
	{
		return;
	}

	if (poAtker == NULL || poAtker->GetScene() != GetScene())
	{
		return;
	}

	int nOrgHP = m_oFightParam[eFP_HP];
	int nAtkerType = poAtker->GetType();
	if (GetType() == eOT_Player)
	{//玩家广播伤害
		BroadcastActorHurt(poAtker->GetAOIID(), nAtkerType, nOrgHP, nHP);
	}

	m_oFightParam[eFP_HP] = XMath::Max(0, m_oFightParam[eFP_HP] - nHP);
	bool bDead = m_oFightParam[eFP_HP] <= 0;
	m_bBloodChange = true;

	if (nAtkerType == eOT_Player || nAtkerType == eOT_Robot)
	{
		//伤害统计
		int nDmgHP = nOrgHP - m_oFightParam[eFP_HP];
		GetScene()->UpdateDamage(poAtker, this, nDmgHP, nAtkID, nAtkType, bDead);
		if (poAtker != this)
		{//仇恨值
			AddHate(poAtker, nDmgHP);
		}
	}

	if (bDead)
	{
		OnDead(poAtker, nAtkID, nAtkType);
	}
}

void Actor::Update(int64_t nNowMS)
{
	Object::Update(nNowMS);
	UpdateRunState(nNowMS);
	UpdateBuff(nNowMS);
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
		int nNewPosX = 0, nNewPosY = 0;
		bCanMove = CalcNewPositionAtTime(nNowMS, nNewPosX, nNewPosY);
		Object::SetPos(Point(nNewPosX, nNewPosY));
		//XLog(LEVEL_DEBUG, "Pos(%d,%d)\n", nNewPosX, nNewPosY);
		if (!bCanMove || (m_nRunSpeedX == 0 && m_nRunSpeedY == 0))
		{
			StopRun();
		}
	}
	return bCanMove;
}

bool Actor::CalcNewPositionAtTime(int64_t nNowMS, int& nNewPosX, int& nNewPosY)
{
	int nNewX = m_nRunStartX;
	int nNewY = m_nRunStartY;
	int nTimeElapased = (int)(nNowMS - m_nRunStartMSTime);

	if (nTimeElapased > 0)
	{
		//常规移动计算
		nNewX += (m_nRunSpeedX * nTimeElapased) / 1000;
		nNewY += (m_nRunSpeedY * nTimeElapased) / 1000;
	}

	bool bResult = true;
	if (nNewX != m_oPos.x || nNewY != m_oPos.y)
	{
		bResult = BattleUtil::FixLineMovePoint(GetScene()->GetMapConf(), m_oPos.x, m_oPos.y, nNewX, nNewY, this);
	}
	nNewPosX = nNewX;
	nNewPosY = nNewY;
	return bResult;
}

void Actor::StartAttack(int nPosX, int nPosY, int nAtkID, int nAtkType, float fAngle, int nRemainBullet)
{
	m_bAttacking = true;
	CachePlayerSessionList();
	if (g_oSessionCache.Size() <= 0)
	{
		return;
	}
	g_poPacketCache->Reset();
	g_oPKWriter << m_nAOIID << (uint16_t)nPosX << (uint16_t)nPosY << (uint16_t)nAtkID << (uint8_t)nAtkType << fAngle << (int16_t)nRemainBullet;
	Packet* poPacket = g_poPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::ppActorStartAttack, poPacket, g_oSessionCache.Ptr(), g_oSessionCache.Size());
}

void Actor::StopAttack()
{
	if (!m_bAttacking)
	{
		return;
	}
	m_bAttacking = false;
	CachePlayerSessionList();
	if (g_oSessionCache.Size() <= 0)
	{
		return;
	}
	g_poPacketCache->Reset();
	g_oPKWriter << m_nAOIID;
	Packet* poPacket = g_poPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::ppActorStopAttack, poPacket, g_oSessionCache.Ptr(), g_oSessionCache.Size());
}

bool Actor::Relive(int nPosX, int nPosY)
{
	if (!IsDead() || Object::GetScene() == NULL)
	{
		return false;
	}
	m_bDead = false;
	m_uRelives++;

	Scene* poScene = Object::GetScene();
	MapConf* poMapConf = poScene->GetMapConf();
	nPosX = XMath::Max(0, XMath::Min(poMapConf->nPixelWidth - 1, nPosX));
	nPosY = XMath::Max(0, XMath::Min(poMapConf->nPixelHeight - 1, nPosY));
	Object::SetPos(Point(nPosX, nPosY));

	OnRelive();
	return true;
}

void Actor::SendSyncPosition(const char* pWhere)
{
	g_poPacketCache->Reset();
	g_oPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y;
	Packet* poPacket = g_poPacketCache->DeepCopy();
	NetAdapter::SendExter(NSCltSrvCmd::sSyncActorPos, poPacket, m_nSession >> SERVICE_SHIFT, m_nSession);
}

void Actor::BroadcastStartRun()
{
	CachePlayerSessionList();
	if (g_oSessionCache.Size() <= 0)
	{
		return;
	}
	g_poPacketCache->Reset();
	g_oPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int16_t)m_nRunSpeedX << (int16_t)m_nRunSpeedY;
	Packet* poPacket = g_poPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sBroadcastActorRun, poPacket, g_oSessionCache.Ptr(), g_oSessionCache.Size());
}

void Actor::BroadcastStopRun()
{
	CachePlayerSessionList();
	if (g_oSessionCache.Size() <= 0)
	{
		return;
	}
	g_poPacketCache->Reset();
	g_oPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y;
	Packet* poPacket = g_poPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sBroadcastActorStopRun, poPacket, g_oSessionCache.Ptr(), g_oSessionCache.Size());
}

void Actor::BroadcastActorHurt(int nSrcAOIID, int nSrcType, int nCurrHP, int nHurtHP)
{
	CachePlayerSessionList(GetSession());
	if (g_oSessionCache.Size() <= 0)
	{
		return;
	}
	g_poPacketCache->Reset();
	g_oPKWriter << nSrcAOIID << (uint8_t)nSrcType << m_nAOIID << (uint8_t)m_nObjType << nCurrHP << nHurtHP;
	Packet* poPacket = g_poPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sBroadcastActorHurt, poPacket, g_oSessionCache.Ptr(), g_oSessionCache.Size());
}

void Actor::BroadcastActorDead()
{
	CachePlayerSessionList(m_nSession);
	if (g_oSessionCache.Size() <= 0)
	{
		return;
	}
	g_poPacketCache->Reset();
	g_oPKWriter << m_nAOIID << (uint8_t)m_nObjType;
	Packet* poPacket = g_poPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sBroadcastActorDead, poPacket, g_oSessionCache.Ptr(), g_oSessionCache.Size());
}

void Actor::BroadcastSyncHP()
{
	if (IsDead() || GetScene() == NULL)
	{
		return;
	}

	if (!m_bBloodChange)
	{
		return;
	}
	m_bBloodChange = false;

	CachePlayerSessionList();
	if (g_oSessionCache.Size() <= 0)
	{
		return;
	}
	g_poPacketCache->Reset();
	g_oPKWriter << m_nAOIID << m_oFightParam[eFP_HP];
	Packet* poPacket = g_poPacketCache->DeepCopy();
	NetAdapter::BroadcastExter(NSCltSrvCmd::sSyncActorHP, poPacket, g_oSessionCache.Ptr(), g_oSessionCache.Size());
}

void Actor::UpdateBuff(int64_t nNowMS)
{

	int nNowSec = XTime::Time();
	if (nNowSec == m_nLastBuffUpdateTime)
	{
		return;
	}
	m_nLastBuffUpdateTime = nNowSec;

	BuffIter iter = m_oBuffMap.begin();
	BuffIter iter_end = m_oBuffMap.end();
	for (; iter != iter_end;)
	{
		Buff* poBuff = iter->second;
		if (poBuff->IsExpired(nNowMS))
		{
			iter = m_oBuffMap.erase(iter);
			LuaWrapper::Instance()->FastCallLuaRef<void>("OnActorBuffExpired", 0, "iii", m_oObjID.llID, m_nObjType, poBuff->GetID());
			SAFE_DELETE(poBuff);
			continue;
		}
		iter++;
	}
}

Buff* Actor::GetBuff(int nBuffID)
{
	BuffIter iter = m_oBuffMap.find(nBuffID);
	if (iter != m_oBuffMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void Actor::ClearBuff()
{
	BuffIter iter = m_oBuffMap.begin();
	BuffIter iter_end = m_oBuffMap.end();
	for (; iter != iter_end; iter++)
	{
		SAFE_DELETE(iter->second);
	}
	m_oBuffMap.clear();
}

HATE* Actor::GetHate(GAME_OBJID& oObjID)
{
	HateIter iter = m_oHateMap.find(oObjID.llID);
	if (iter != m_oHateMap.end())
	{
		return &(iter->second);
	}
	return NULL;
}

void Actor::AddHate(Actor* poAtker, int nValue)
{
	if (poAtker == NULL || nValue <= 0)
	{
		return;
	}
	GAME_OBJID& oAtkerID = poAtker->GetID();
	HATE* poHate = GetHate(oAtkerID);
	if (poHate != NULL)
	{
		poHate->nValue += nValue;
	}
	else
	{
		HATE oHate;
		oHate.nValue = nValue;
		oHate.uRelives = poAtker->GetRelives();
		m_oHateMap[oAtkerID.llID] = oHate;
	}
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

int Actor::InitFightParam(lua_State* pState)
{
	luaL_checktype(pState, 1, LUA_TTABLE);

	for (int i = 1; i < eFP_Count; i++)
	{
		GET_FIGHT_PARAM(pState, i);
	}

	m_bBloodChange = true;
	return 0;
}

int Actor::UpdateFightParam(lua_State* pState)
{
	int nType = (int)luaL_checkinteger(pState, 1);
	int nValue = (int)luaL_checkinteger(pState, 2);
	if (nType < eFP_Atk || nType >= eFP_Count)
	{
		return LuaWrapper::luaM_error(pState, "Fight param type error:%d\n", nType);
	}
	m_oFightParam[nType] = nValue;
	if (nType == eFP_HP)
	{
		m_bBloodChange = true;
	}
	return 0;
}

int Actor::GetFightParam(lua_State* pState)
{
	if (lua_isnoneornil(pState, 1))
	{
		lua_newtable(pState);
		for (int i = 1; i < eFP_Count; i++)
		{
			PUSH_FIGHT_PARAM(pState, i);
		}
	}
	else
	{
		int nType = (int)luaL_checkinteger(pState, 1);
		if (nType < eFP_Atk || nType >= eFP_Count)
		{
			return LuaWrapper::luaM_error(pState, "Fight param type error:%d\n", nType);
		}
		lua_pushinteger(pState, m_oFightParam[nType]);
	}
	return 1;
}

int Actor::GetRunningSpeed(lua_State* pState)
{
	lua_pushinteger(pState, m_nRunSpeedX);
	lua_pushinteger(pState, m_nRunSpeedY);
	return 2;
}

int Actor::AddBuff(lua_State* pState)
{
	if (IsDead() || GetScene() == NULL)
	{
		return 0;
	}
	int nBuffID = (int)luaL_checkinteger(pState, 1);
	int nMSTime = (int)luaL_checkinteger(pState, 2);
	Buff* poBuff = GetBuff(nBuffID);
	if (poBuff != NULL)
	{
		poBuff->Restart();
	}
	else
	{
		poBuff = XNEW(Buff)(nBuffID, nMSTime);
		m_oBuffMap[nBuffID] = poBuff;
	}
	lua_pushboolean(pState, 1);
	return 1;
}

int Actor::ClearBuff(lua_State* pState)
{
	ClearBuff();
	return 0;
}

int Actor::IsDead(lua_State* pState)
{
	lua_pushboolean(pState, IsDead());
	return 1;
}

int Actor::Relive(lua_State* pState)
{
	int nPosX = -1;
	int nPosY = -1;
	if (!lua_isnoneornil(pState, 1) && !lua_isnoneornil(pState, 2))
	{
		nPosX = (int)luaL_checkinteger(pState, 1);
		nPosY = (int)luaL_checkinteger(pState, 2);
	}
	bool bRes = Relive(nPosX, nPosY);
	lua_pushboolean(pState, bRes);
	return 1;
}