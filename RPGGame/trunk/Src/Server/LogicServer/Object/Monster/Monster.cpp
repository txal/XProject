#include "Server/LogicServer/Object/Monster/Monster.h"	
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Server/LogicServer/SceneMgr/Scene.h"
#include "Server/LogicServer/SceneMgr/SceneMgr.h"

LUNAR_IMPLEMENT_CLASS(Monster)
{
	DECLEAR_OBJECT_METHOD(Monster),
	DECLEAR_ACTOR_METHOD(Monster),
	{0, 0}
};

Monster::Monster()
{
	m_nObjType = eOT_Monster;
	m_nHPSyncInterval = 333;
	m_nLastHPSyncTime = XTime::MSTime();
	m_nAIID = 0;
	m_poAI = NULL;
}

Monster::~Monster()
{
	SAFE_DELETE(m_poAI);
}

void Monster::Init(int nID, int nConfID, const char* psName, int nAIID, int8_t nCamp)
{
	m_nObjID = nID;
	m_nConfID = nConfID;
	strcpy(m_sName, psName);
	m_nAIID = nAIID;
	m_nCamp = nCamp;
}

void Monster::Update(int64_t nNowMS)
{
	Actor::Update(nNowMS);

	//定时同步血量
	if (nNowMS - m_nLastHPSyncTime >= m_nHPSyncInterval)
	{
		m_nLastHPSyncTime = nNowMS;
		Actor::BroadcastSyncHP();
	}
	//更新AI
	if (m_poAI != NULL)
	{
		m_poAI->Update(nNowMS);
	}
}

void Monster::OnEnterScene(Scene* poScene, const Point& oPos, int nAOIID)
{
	Actor::OnEnterScene(poScene, oPos, nAOIID);
}

void Monster::AfterEnterScene()
{
	Actor::AfterEnterScene();
	if (m_nAIID > 0)
	{
		Scene* poScene = Actor::GetScene();
		m_oAStar.InitMapData(poScene->GetMapConf()->nMapID);

		m_poAI = XNEW(MonsterAI)();
		m_poAI->Init(this, m_nAIID);
	}
}

void Monster::OnLeaveScene()
{
	Actor::OnLeaveScene();
	StopMonsterAttack();
	if (m_poAI != NULL)
	{
		m_poAI->Stop();
	}
}

void Monster::OnDead(Actor* poAtker, int nAtkID, int nAtkType)
{
	Actor::OnDead(poAtker, nAtkID, nAtkType);
	SAFE_DELETE(m_poAI);
	if (m_poAI != NULL)
	{
		m_poAI->Stop();
	}
}

void Monster::OnBattleResult()
{
	Actor::StopRun();
	StopMonsterAttack();
	if (m_poAI != NULL)
	{
		m_poAI->Stop();
	}
}

void Monster::OnRelive()
{
	if (m_poAI != NULL)
	{
		m_poAI->Start();
	}
}

void Monster::StartMonsterAttack(float fAngle)
{
	Actor::StartAttack(m_oPos.x, m_oPos.y, 0, 0, fAngle, 0);
}

void Monster::StopMonsterAttack()
{
	Actor::StopAttack();
}




///////////////////lua export///////////////////