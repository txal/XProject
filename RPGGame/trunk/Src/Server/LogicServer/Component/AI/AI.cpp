#include "AI.h"
#include "Common/DataStruct/XTime.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"

AI::AI()
{
	m_bRun = false;	
	m_poAIConf = NULL;
	m_poActor = NULL;
	m_poTarget = NULL;
	m_poAction = NULL;
	m_nNextSearchTime = 0;

	m_nState = eAIS_Idle;
	m_nLastState = eAIS_None;
	m_nStateTime = 0;
	m_nNextAtkTime = 0;
}

AI::~AI()
{
	SAFE_DELETE(m_poAction);
}

bool AI::Init(Actor* poActor, int nAIID)
{
	assert(m_poAction != NULL);
	m_poAIConf = ConfMgr::Instance()->GetAIMgr()->GetConf(nAIID);
	if (m_poAIConf == NULL)
	{
		XLog(LEVEL_ERROR, "AI config %d not found!\n", nAIID);
		return false;
	}
	m_poActor = poActor;
	m_poAction->Init(poActor, m_poAIConf);
	return true;
}

void AI::Stop()
{
	m_bRun = false;
}

void AI::Start()
{
	if (m_bRun)
	{
		return;
	}
	m_bRun = true;
	m_nState = eAIS_Idle;
	m_nLastState = eAIS_None;
	m_nStateTime = 0;
	m_nNextAtkTime = 0;
	m_poAction->Reset();
}

int AI::SelectAction()
{
	int nTotal = m_poAIConf->tActRandom[0] + m_poAIConf->tActRandom[1];
	int nRnd = XMath::Random(1, nTotal);
	int nPreWeight = 0;
	for (int i = 0; i < 2; i++)
	{
		int nMinWeight = nPreWeight + 1;
		int nMaxWeight = nMinWeight + m_poAIConf->tActRandom[i] - 1;
		nPreWeight = nMaxWeight;
		if (nRnd >= nMinWeight && nRnd <= nMaxWeight)
		{
			return i;
		}
	}
	return 0;
}

int AI::GetStateTime(int nState)
{
	if (nState == eAIS_Idle)
	{
		return 0; //不持续
	}
	if (nState == eAIS_Atk)
	{
		return XMath::Random(m_poAIConf->tAtkTime[0], m_poAIConf->tAtkTime[1]);
	}
	if (nState == eAIS_Def)
	{
		return XMath::Random(m_poAIConf->tDefTime[0], m_poAIConf->tDefTime[1]);
	}
	return 0;
}
void AI::SetState(int nState, int nStateTime, int nLine)
{
	int64_t nNowMS = XTime::MSTime();

	m_nLastState = m_nState;
	m_nState = nState;
	m_nStateTime = nNowMS + nStateTime;
	if (m_nState != eAIS_Atk && m_nLastState == eAIS_Atk)
	{
		m_nNextAtkTime = nNowMS + m_poAIConf->nAtkCD;
	}
}


//////////monster ai//////////
MonsterAI::MonsterAI()
{
	m_poAction = XNEW(MonsterAction)();
}

void MonsterAI::Update(int64_t nNowMS)
{
	if (!m_bRun)
	{
		return;
	}
	//if (m_poActor == NULL || m_poActor->GetScene() == NULL || m_poActor->IsDead())
	//{
	//	return;
	//}

	//if (m_poTarget != NULL && (m_poTarget->IsDead() || m_poTarget->GetScene() == NULL))
	//{
	//	m_poTarget = NULL;
	//	m_poAction->SetTarget(m_poTarget);
	//	SetState(eAIS_Idle, GetStateTime(eAIS_Idle), __LINE__);
	//}

	switch (m_nState)
	{
		case eAIS_Idle:
		{
						  if (nNowMS >= m_nStateTime)
						  {
							  int nActType = SelectAction();
							  if (nActType == eATT_Atk)
							  {
								  if (nNowMS >= m_nNextAtkTime)
								  {
									  SetState(eAIS_Atk, GetStateTime(eAIS_Atk), __LINE__);
								  }
								  else
								  {
									  SetState(eAIS_Idle, 300, __LINE__);
								  }
							  }
							  else if (nActType == eATT_Def)
							  {
								  SetState(eAIS_Def, GetStateTime(eAIS_Def), __LINE__);
							  }
						  }
						  break;
		}
		case eAIS_Atk:
		{
						 if (nNowMS >= m_nStateTime)
						 {
							 SetState(eAIS_Idle, GetStateTime(eAIS_Idle), __LINE__);
						 }
						 else
						 {
							 if (m_nLastState != eAIS_Atk)
							 {
								 m_nLastState = eAIS_Atk;
								 m_nNextSearchTime = nNowMS;
								 m_poTarget = NULL;
							 }
							 SearchNearTarget(nNowMS);
							 m_poAction->SetTarget(m_poTarget);
						 }
						 break;
		}
		case eAIS_Def:
		{
						 if (nNowMS >= m_nStateTime)
						 {
							 SetState(eAIS_Idle, GetStateTime(eAIS_Idle), __LINE__);
						 }
						 else
						 {
							 if (m_nLastState != eAIS_Def)
							 {
								 m_nLastState = eAIS_Def;
								 m_nNextSearchTime = nNowMS;
								 m_poTarget = NULL;
							 }
							 SearchNearTarget(nNowMS);
							 m_poAction->SetTarget(m_poTarget);
						 }
						 break;
		}
	}
	m_poAction->Update(nNowMS);
}

void MonsterAI::SearchNearTarget(int64_t nNowMS)
{
	if (nNowMS < m_nNextSearchTime)
	{
		return;
	}
	m_nNextSearchTime = nNowMS + 2000;

	m_poTarget = NULL;
	int nMinDistance = 0;
	Point& oMyPos = m_poActor->GetPos();

	Actor* poMonster = NULL; //玩家要守护的东西
	Actor* poNearTar = NULL; //最近的目标

	Scene* poScene = m_poActor->GetScene();
	Scene::ObjMap& oObjMap = poScene->GetObjMap();
	Scene::ObjIter iter = oObjMap.begin();
	Scene::ObjIter iter_end = oObjMap.end();
	for (; iter != iter_end; ++iter)
	{
		Object* poObj = iter->second;
		if (poObj->GetType() != eOT_Role
			&& poObj->GetType() != eOT_Monster)
		{
			continue;
		}

		Actor* poActor = (Actor*)poObj;
		//if (m_poActor == poActor || poActor->IsDead() || poActor->GetScene() != poScene || !m_poActor->CheckCamp(poActor))
		//{
		//	continue;
		//}

		if (poActor->GetType() == eOT_Monster)
		{
			poMonster = poActor;
		}

		Point& oTarPos = poActor->GetPos();
		int nDistance = oMyPos.Distance(oTarPos);
		if (nMinDistance == 0 || nDistance < nMinDistance)
		{
			nMinDistance = nDistance;
			poNearTar = poActor;
		}
	}
	m_poTarget = poNearTar;

	//如果最近的目标在攻击距离外，则选择玩家保护的东西作为目标，否则就攻击最近的目标
	if (poNearTar != NULL)
	{
		int nAtkDist = m_poAction->GetAtkDist();
		int nTarDist = oMyPos.Distance(poNearTar->GetPos());
		if (nTarDist > nAtkDist && poMonster != NULL)
		{
			m_poTarget = poMonster;
		}
	}
}


////////robot ai////////
RobotAI::RobotAI()
{
	m_poAction = XNEW(RobotAction)();
}

void RobotAI::Update(int64_t nNowMS)
{
	if (!m_bRun)
	{
		return;
	}
	//if (m_poActor == NULL || m_poActor->GetScene() == NULL || m_poActor->IsDead())
	//{
	//	return;
	//}

	//if (m_poTarget != NULL && (m_poTarget->IsDead() || m_poTarget->GetScene() == NULL))
	//{
	//	m_poTarget = NULL;
	//	m_poAction->SetTarget(m_poTarget);
	//	SetState(eAIS_Idle, GetStateTime(eAIS_Idle), __LINE__);
	//}

	switch (m_nState)
	{
		case eAIS_Idle:
		{
						  if (nNowMS >= m_nStateTime)
						  {
							  int nActType = SelectAction();
							  if (nActType == eATT_Atk)
							  {
								  if (nNowMS >= m_nNextAtkTime)
								  {
									  SetState(eAIS_Atk, GetStateTime(eAIS_Atk), __LINE__);
								  }
								  else
								  {
									  SetState(eAIS_Idle, 300, __LINE__);
								  }
							  }
							  else if (nActType == eATT_Def)
							  {
								  SetState(eAIS_Def, GetStateTime(eAIS_Def), __LINE__);
							  }
						  }
						  break;
		}
		case eAIS_Atk:
		{
						 if (nNowMS >= m_nStateTime)
						 {
							 SetState(eAIS_Idle, GetStateTime(eAIS_Idle), __LINE__);
						 }
						 else
						 {
							 if (m_nLastState != eAIS_Atk)
							 {
								 m_nLastState = eAIS_Atk;
								 m_nNextSearchTime = nNowMS;
								 m_poTarget = NULL;
							 }
							 SearchViewTarget(nNowMS);
							 if (m_poTarget == NULL)
							 {
								 m_nNextSearchTime = nNowMS;
								 SearchNearTarget(nNowMS);
							 }
							 m_poAction->SetTarget(m_poTarget);
						 }
						 break;
		}
		case eAIS_Def:
		{
						 if (nNowMS >= m_nStateTime)
						 {
							 SetState(eAIS_Idle, GetStateTime(eAIS_Idle), __LINE__);
						 }
						 else
						 {
							 if (m_nLastState != eAIS_Def)
							 {
								 m_nLastState = eAIS_Def;
								 m_nNextSearchTime = nNowMS;
								 m_poTarget = NULL;
							 }
							 SearchViewTarget(nNowMS);
							 m_poAction->SetTarget(m_poTarget);
						 }
						 break;
		}
	}
	m_poAction->Update(nNowMS);
}

void RobotAI::SearchNearTarget(int64_t nNowMS)
{ 
	if (nNowMS < m_nNextSearchTime)
	{
		return;
	}
	m_nNextSearchTime = nNowMS + 2000;

	m_poTarget = NULL;
	int nMinDistance = 0;
	Point& oMyPos = m_poActor->GetPos();

	Scene* poScene = m_poActor->GetScene();
	Array<AOIOBJ*>& oObjList = poScene->GetAreaObserveds(m_poActor->GetAOIID(), 0);
	for (int i = 0; i < oObjList.Size(); ++i)
	{
		Object* poObj = oObjList[i]->poGameObj;
		if (poObj->GetType() != eOT_Role
			&& poObj->GetType() != eOT_Robot)
		{
			continue;
		}

		Actor* poActor = (Actor*)poObj;
		//if (m_poActor == poActor || poActor->IsDead() || poActor->GetScene() != poScene || !m_poActor->CheckCamp(poActor))
		//{
		//	continue;
		//}

		Point& oTarPos = poActor->GetPos();
		int nDistance = oMyPos.Distance(oTarPos);
		if (nMinDistance == 0 || nDistance < nMinDistance)
		{
			nMinDistance = nDistance;
			m_poTarget = poActor;
		}
	}
}


void RobotAI::SearchViewTarget(int64_t nNowMS)
{
	if (nNowMS < m_nNextSearchTime)
	{
		return;
	}
	m_nNextSearchTime = nNowMS + 2000;

	Point& oMyPos = m_poActor->GetPos();
	Scene* poScene = m_poActor->GetScene();
	MapConf* poMapConf = poScene->GetMapConf();

	m_poTarget = NULL;
	int nMaxHateVal = 0;

	Array<AOIOBJ*>& oObjList = poScene->GetAreaObserveds(m_poActor->GetAOIID(), 0);
	for (int i = 0; i < oObjList.Size(); ++i)
	{
		Object* poObj = oObjList[i]->poGameObj;
		int nObjType = poObj->GetType();
		if (nObjType != eOT_Role && nObjType != eOT_Robot)
		{
			continue;
		}

		Actor* poTarget = (Actor*)poObj;
		//if (m_poActor == poTarget || poTarget->IsDead() || poTarget->GetScene() != poScene || !m_poActor->CheckCamp(poTarget))
		//{
		//	continue;
		//}

		int nHateVal = 0;
		//HATE* poHate = m_poActor->GetHate(poTarget->GetID());
		//if (poHate != NULL)
		//{
		//	int nRelives = poTarget->GetRelives();
		//	if (nRelives != poHate->uRelives)
		//	{
		//		poHate->nValue = 0;
		//		poHate->uRelives = (uint8_t)nRelives;
		//	}
		//	nHateVal = poHate->nValue;
		//}
		//XLog(LEVEL_DEBUG, "%s Hate %s %d\n", m_poActor->GetName(), poTarget->GetName(), nHateVal);

		Point& oTarPos = poTarget->GetPos();
		if ((nMaxHateVal == 0 || nHateVal > nMaxHateVal) && BattleUtil::FloydCrossAble(poMapConf, oMyPos.x, oMyPos.y, oTarPos.x, oTarPos.y))
		{
			m_poTarget = poTarget;
			nMaxHateVal = nHateVal;
		}
	}
	//XLog(LEVEL_DEBUG, "%s Search hate target %s\n", m_poActor->GetName(), m_poTarget?m_poTarget->GetName():"null");
}