#include "Action.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/TimeMonitor.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/Object/Monster/MonsterMgr.h"
#include "Server/LogicServer/Object/Robot/RobotMgr.h"

Action::Action()
{
	m_poActor = NULL;
	m_poAIConf = NULL;

	m_nState = eATS_None;
	m_nLastState = eATS_None;
	m_nStateTime = 0;

	m_oMinDist.x = 5;
	m_oMinDist.y = 5;
	m_nAtkDist = 0; //0 没限制
	m_nLastMoveTime = 0;
	m_bTarPosChange = false;

	m_nWalkRadius = 0;
	m_nLastActorFrame = 0;
}

void Action::Init(Actor* poActor, AIConf* poAIConf)
{
	m_poActor = poActor;
	m_poAIConf = poAIConf;
	m_nAtkDist = XMath::Random(poAIConf->tR3[0], poAIConf->tR3[1]);
}

void Action::Reset()
{
	m_nState = eATS_None;
	m_nLastState = eATS_None;
	m_nStateTime = 0;
	m_oNextPos.Reset();
	m_oMoveTarPos.Reset();
	m_oLastActorPos.Reset();
}

void Action::SetTarget(Actor* poTarget)
{ 
	if (m_poTarget == poTarget && m_nState != eATS_None)
	{
		return;
	}
	Reset();
	StopAttack();
	StopMove(__LINE__);
	m_poTarget = poTarget;
	SetState(eATS_Idle, 300, __LINE__);
	//XLog(LEVEL_INFO, "SetTarget: %s->%s ******\n", m_poActor->GetName(), poTarget ? poTarget->GetName() : "NULL");
}

int Action::GetAtkDist()
{
	return m_nAtkDist;
}

void Action::Update(int64_t nNowMS)
{
	switch (m_nState)
	{
		case eATS_None:
		{
			break;
		}
		case eATS_Idle:
		{
						  if (nNowMS >= m_nStateTime)
						  {
							  if (m_poTarget == NULL)
							  {
								  SetState(eATS_DefWalk, 0, __LINE__);
							  }
							  else
							  {
								 Point& oMyPos = m_poActor->GetPos();
								 Point& oEnemyPos = m_poTarget->GetPos();
								 if (CheckCanAttack(oMyPos, oEnemyPos) && CheckAtkDistance(oMyPos, oEnemyPos, m_nAtkDist))
								  {
									  SetState(eATS_AtkWalk, 0, __LINE__);
								  }
								  else
								  {
									  SetState(eATS_Track, 0, __LINE__);
								  }
							  }
						  }
						  break;
		}
		case eATS_AtkWalk:
		{
							 if (nNowMS >= m_nStateTime)
							 {
								 //第1次进
								 if (m_nLastState != eATS_AtkWalk)
								 {
									 m_nLastState = eATS_AtkWalk;
									 m_nLastMoveTime = nNowMS;
									 Point& oMyPos = m_poActor->GetPos();
									 Point& oEnemyPos = m_poTarget->GetPos();

									 StopMove(__LINE__);
									 float fAngle = BattleUtil::CalcDegree(oMyPos.x, oMyPos.y, oEnemyPos.x, oEnemyPos.y);
									 Attack(fAngle);

									 m_oRefPos.x = (int)((oMyPos.x / gnUnitWidth + 0.5f) * gnUnitWidth);
									 m_oRefPos.y = (int)((oMyPos.y / gnUnitHeight + 0.5f) * gnUnitHeight);

									 m_nWalkRadius = m_poAIConf->tR1[1] > 0 ? XMath::Max(gnUnitWidth, XMath::Random(m_poAIConf->tR1[0], m_poAIConf->tR1[1])) : 0;
									 if (m_nWalkRadius > 0)
									 {
										 m_oNextPos.Reset();
										 m_oMoveTarPos.Reset();
										 m_oLastActorPos.Reset();
										 CalcWalkPos();
									 }
								 }
								 //攻击游走
								 else if (m_nWalkRadius > 0)
								 {
									 if (CheckDistance(m_poActor->GetPos(), m_oNextPos, m_oMinDist))
									 {
										 StopMove(__LINE__);
										 CalcWalkPos();
										 //old: 240
										 int nStandTime = XMath::Random(300, 1000);
										 SetState(eATS_AtkWalk, nStandTime, __LINE__);
									 }
									 else if (!m_poActor->IsRunning())
									 {
										 MoveTo(__LINE__);
									 }
								 }

								 //攻击中每隔1秒检测目标位置变更和角度变化
								 if (nNowMS >= m_nLastMoveTime + 1000)
								 {
									 m_nLastMoveTime = nNowMS;
									 Point& oMyPos = m_poActor->GetPos();
									 Point& oEnemyPos = m_poTarget->GetPos();
									 if (!CheckCanAttack(oMyPos, oEnemyPos))
									 {
										 SetState(eATS_Track, 0, __LINE__);
									 }
									 else
									 {
										 float fAngle = BattleUtil::CalcDegree(oMyPos.x, oMyPos.y, oEnemyPos.x, oEnemyPos.y);
										 Attack(fAngle);
									 }
								 }
							 }
							 break;
		}
		case eATS_DefWalk:
		{						  
							 if (nNowMS >= m_nStateTime)
							 {
								 if (m_nLastState != eATS_DefWalk)
								 {
									 m_nLastState = eATS_DefWalk;
									 Point& oMyPos = m_poActor->GetPos();
									 m_oRefPos.x = (int)((oMyPos.x / gnUnitWidth + 0.5f) * gnUnitWidth);
									 m_oRefPos.y = (int)((oMyPos.y / gnUnitHeight + 0.5f) * gnUnitHeight);
									 m_nWalkRadius = m_poAIConf->tR2[1] > 0 ? XMath::Max(gnUnitWidth, XMath::Random(m_poAIConf->tR2[0], m_poAIConf->tR2[1])) : 0;
									 if (m_nWalkRadius > 0)
									 {
										 m_oNextPos.Reset();
										 m_oMoveTarPos.Reset();
										 m_oLastActorPos.Reset();
										 CalcWalkPos();
									 }
								 }
								 //防御游走
								 else if (m_nWalkRadius > 0)
								 {
									 if (CheckDistance(m_poActor->GetPos(), m_oNextPos, m_oMinDist))
									 {
										 StopMove(__LINE__);
										 CalcWalkPos();
										 int nStandTime = XMath::Random(500, 1000);
										 SetState(eATS_DefWalk, nStandTime, __LINE__);
									 }
									 else if (!m_poActor->IsRunning())
									 {
										 MoveTo(__LINE__);
									 }
								 }
							 }
							 break;
		}
		case eATS_Track:
		{
						   //第1次进
						   if (m_nLastState != eATS_Track)
						   {
							   StopAttack();
							   m_nLastState = eATS_Track;
							   m_nLastMoveTime = nNowMS;

							   m_oNextPos.Reset();
							   m_oMoveTarPos.Reset();
							   m_oLastActorPos.Reset();
							   CalcTrackPos();
							   MoveTo(__LINE__);
						   }
						   else
						   {
							   Point& oMyPos = m_poActor->GetPos();
							   if (CheckDistance(oMyPos, m_oNextPos, m_oMinDist))
							   {
								   SetState(eATS_AtkWalk, 0, __LINE__);
							   }
							   else  if (nNowMS >= m_nLastMoveTime + 500)
							   { //连续追踪需要间隔1段时间
								   m_nLastMoveTime = nNowMS;
								   Point& oEnemyPos = m_poTarget->GetPos();
								   if (CheckCanAttack(oMyPos, oEnemyPos) && CheckAtkDistance(oMyPos, m_oMoveTarPos, m_nAtkDist))
								   {
									   SetState(eATS_AtkWalk, 0, __LINE__);
								   }
								   else
								   {
									   CalcTrackPos();
									   MoveTo(__LINE__);
								   }
							   }
						   }
						  break;
		}
	}
}

void Action::SetState(int nState, int nStateTime, int nLine)
{
	//XLog(LEVEL_DEBUG, "SetState %s state:%d laststate:%d line:%d\n", m_poActor->GetName(), nState, m_nState, nLine);
	m_nLastState = m_nState;
	m_nState = nState;
	m_nStateTime = XTime::MSTime() + nStateTime;
}

void Action::CalcTrackPos()
{
	Point oPos = m_poTarget->GetPos();
	//中心点
	oPos.x = (int)((oPos.x / gnUnitWidth + 0.5f) * gnUnitWidth);
	oPos.y = (int)((oPos.y / gnUnitHeight + 0.5f) * gnUnitHeight);
	if (m_oMoveTarPos == oPos)
	{
		return;
	}
	m_oMoveTarPos = oPos;
	m_oNextPos = oPos;
	m_oListPath.clear();
	m_bTarPosChange = true;
}

bool Action::CalcWalkPos()
{
	Point oPos;
	GetRandomPos(m_oRefPos, m_nWalkRadius, oPos);
	if (m_oMoveTarPos == oPos)
	{
		return false;
	}
	m_oMoveTarPos = oPos;
	m_oNextPos = oPos;
	m_oListPath.clear();
	m_bTarPosChange = true;
	return true;
}

void Action::StopMove(int nLine)
{
	if (m_poActor->IsRunning())
	{
		m_poActor->StopRun();
		//XLog(LEVEL_DEBUG, "%s stop move line:%d\n", m_poActor->GetName(), nLine);
	}
}

void Action::MoveTo(int nLine)
{
	if (!m_bTarPosChange)
	{
		return;
	}
	m_bTarPosChange = false;

	if (m_oMoveTarPos.x < 0 || m_oMoveTarPos.y < 0)
	{
		return;
	}

	Scene* poScene = m_poActor->GetScene();
	const Point& oMyPos = m_poActor->GetPos();

	MapConf* poMapConf = poScene->GetMapConf();
	bool bResult = BattleUtil::FloydCrossAble(poMapConf, oMyPos.x, oMyPos.y, m_oMoveTarPos.x, m_oMoveTarPos.y);
	if (!bResult)
	{
		AStarPathFind* poAStar = NULL;
		if (m_poActor->GetType() == eOT_Robot)
		{
			poAStar = ((Robot*)m_poActor)->GetAStar();
		}
		else if (m_poActor->GetType() == eOT_Monster)
		{
			poAStar = ((Monster*)m_poActor)->GetAStar();
		}
		if (poAStar != NULL)
		{
			int nResult = poAStar->PathFind(oMyPos.x, oMyPos.y, m_oMoveTarPos.x, m_oMoveTarPos.y, m_oListPath);
			if (nResult == 0)
			{
				//XLog(LEVEL_DEBUG,"%s A* path(%d,%d)->(%d,%d):", m_poActor->GetName(), oMyPos.x, oMyPos.y, m_oMoveTarPos.x, m_oMoveTarPos.y);
				//PathIter iter = m_oListPath.begin();
				//for (; iter != m_oListPath.end(); iter++)
				//{
				//	XLog(LEVEL_DEBUG,"[%d,%d] ", (*iter).x / gnUnitWidth, poMapConf->nUnitNumY - (*iter).y / gnUnitHeight - 1);
				//}
				//XLog(LEVEL_DEBUG," line:%d\n", nLine);
				m_oListPath.pop_front();
				m_oNextPos = m_oListPath.front();
				m_oListPath.pop_front();
			}
			else
			{
				XLog(LEVEL_INFO, "AStar path find fail code:%d\n", nResult);
			}
		}
	}
	else
	{
		assert(m_oMoveTarPos == m_oNextPos);
		//XLog(LEVEL_DEBUG,"%s Line path:[%d,%d]->[%d,%d] line:%d\n", m_poActor->GetName(), oMyPos.x/gnUnitWidth, poMapConf->nUnitNumY-1- oMyPos.y/gnUnitHeight, m_oNextPos.x/gnUnitWidth, poMapConf->nUnitNumY-1-m_oNextPos.y/gnUnitHeight, nLine );
	}
	//XLog(LEVEL_DEBUG, "%s MoveTo:(%d,%d)->(%d,%d) a*:%d line:%d\n", m_poActor->GetName(), oMyPos.x, oMyPos.y, m_oNextPos.x, m_oNextPos.y, !bResult, nLine);
	//StartMove(oMyPos, m_oNextPos, m_poActor->GetStaticSpeed(), nLine);
}

void Action::StartMove(const Point& oStartPos, const Point& oTarPos, int nMoveSpeed, int nLine)
{
	float fMoveTime = BattleUtil::CalcMoveTime(nMoveSpeed, oStartPos, oTarPos);
	int nSpeedX = (int)((oTarPos.x - oStartPos.x) / fMoveTime);
	int nSpeedY = (int)((oTarPos.y - oStartPos.y) / fMoveTime);
	if (nSpeedX != 0 || nSpeedY != 0)
	{
		int nOldSpeedX = m_poActor->GetSpeedX();
		int nOldSpeedY = m_poActor->GetSpeedY();
		if (!m_poActor->IsRunning() || nSpeedX != nOldSpeedX || nSpeedY != nOldSpeedY)
		{
			//XLog(LEVEL_DEBUG, "%s StartMove:(%d,%d)->(%d,%d) line:%d\n", m_poActor->GetName(), oStartPos.x, oStartPos.y, m_oNextPos.x, m_oNextPos.y, nLine);
			m_poActor->StartRun(nSpeedX, nSpeedY, 0);
		}
	}
}

bool Action::CheckDistance(const Point& oSrcPos, const Point& oTarPos, const Point& oDist)
{
	assert(oTarPos.x >= 0 && oTarPos.y >= 0);
	if (oSrcPos.CheckDistance(oTarPos, oDist))
	{
		m_oLastActorPos.Reset();
		m_nLastActorFrame = 0;
		if (m_oListPath.size() > 0)
		{
			m_oNextPos = m_oListPath.front();
			m_oListPath.pop_front();
			//StartMove(oSrcPos, m_oNextPos, m_poActor->GetStaticSpeed(), __LINE__);
			return false;
		}
		return true;
	}
	else
	{
		if (m_oLastActorPos == oSrcPos)
		{
			m_nLastActorFrame++;
			if (m_nLastActorFrame >= 4)
			{
				//MapConf* poMapConf = m_poActor->GetScene()->GetMapConf();
				//int nSrcUnitX = oSrcPos.x / gnUnitWidth;
				//int nSrcUnitY = poMapConf->nUnitNumY - oSrcPos.y / gnUnitHeight - 1;
				//int nTarUnitX = oTarPos.x / gnUnitWidth;
				//int nTarUnitY = poMapConf->nUnitNumY - oTarPos.y / gnUnitHeight - 1;
				XLog(LEVEL_DEBUG, "%s Blocking!!\n", m_poActor->GetName());

				Point oNewPos;
				oNewPos.x = (int)((oSrcPos.x / gnUnitWidth + 0.5f) * gnUnitWidth);
				oNewPos.y = (int)((oSrcPos.y / gnUnitHeight + 0.5f) * gnUnitHeight);
				if (!(m_oNextPos == oNewPos))
				{
					m_oListPath.push_front(m_oNextPos);
					m_oNextPos = oNewPos;
				}
				//StartMove(oSrcPos, m_oNextPos, m_poActor->GetStaticSpeed(), __LINE__);
				m_nLastActorFrame = 0;

				//int nNextUnitX = m_oNextPos.x / gnUnitWidth;
				//int nNextUnitY = m_oNextPos.y / gnUnitHeight;
				//int nIndex = XMath::Random(1, 8) - 1;
				//nNextUnitX += gtDir[nIndex][0];
				//nNextUnitY += gtDir[nIndex][1];
				//if (!poMapConf->IsBlockUnit(nNextUnitX, nNextUnitY))
				//{
				//	m_nLastActorFrame = 0;
				//	m_oNextPos.x = (int)((nNextUnitX + 0.5f) * gnUnitWidth);
				//	m_oNextPos.y = (int)((nNextUnitY + 0.5f) * gnUnitHeight);
				//	StartMove(oSrcPos, m_oNextPos, m_poActor->GetStaticSpeed(), __LINE__);
				//}
			}
		}
		else
		{
			m_nLastActorFrame = 0;
			m_oLastActorPos = oSrcPos;
		}
	}
	return false;
}

bool Action::CheckAtkDistance(const Point& oSrcPos, const Point& oTarPos, int nDist)
{
	if (nDist < gnUnitWidth)
	{
		return true;
	}
	int nTarDist = oSrcPos.Distance(oTarPos);
	if (nTarDist > nDist)
	{
		return false;
	}
	return true;
}

bool Action::CheckCanAttack(const Point& oSrcPos, const Point& oTarPos)
{
	Scene* poScene = m_poActor->GetScene();
	return BattleUtil::FloydCrossAble(poScene->GetMapConf(), oSrcPos.x, oSrcPos.y, oTarPos.x, oTarPos.y);
}

void Action::GetRandomPos(const Point& oRefPos, int nRadius, Point& oTarPos)
{
	Point& oMyPos = m_poActor->GetPos();
	oTarPos = oMyPos;
	if (nRadius <= 0)
	{
		return;
	}
	int nMyUnitX = oMyPos.x / gnUnitWidth;
	int nMyUnitY = oMyPos.y / gnUnitHeight;

	MapConf* poMapConf = m_poActor->GetScene()->GetMapConf();
	int nMinUnitX = XMath::Max(0, oRefPos.x - nRadius) / gnUnitWidth;
	int nMaxUnitX = XMath::Min((int)poMapConf->nPixelWidth - 1, oRefPos.x + nRadius) / gnUnitWidth;
	int nMinUnitY = XMath::Max(0, oRefPos.y - nRadius) / gnUnitHeight;
	int nMaxUnitY = XMath::Min((int)poMapConf->nPixelHeight - 1, oRefPos.y + nRadius) / gnUnitHeight;
	if (nMinUnitX == nMaxUnitX && nMinUnitY == nMaxUnitY)
	{
		return;
	}

	for (int i = 0; i < 16; i++)
	{
		int nUnitX = XMath::Random(nMinUnitX, nMaxUnitX);
		int nUnitY = XMath::Random(nMinUnitY, nMaxUnitY);
		if (!poMapConf->IsBlockUnit(nUnitX, nUnitY) && (nUnitX != nMyUnitX || nUnitY != nMyUnitY))
		{
			oTarPos.x = (int)((nUnitX + 0.5f) * gnUnitWidth);
			oTarPos.y = (int)((nUnitY + 0.5f) * gnUnitHeight);
			return;
		}
	}
}

//
/////////////怪物行为//////////
void MonsterAction::Attack(float fAngle)
{
	Monster* poMon = (Monster*)m_poActor;
	//poMon->StartMonsterAttack(fAngle);
}

void MonsterAction::StopAttack()
{
	Monster* poMon = (Monster*)m_poActor;
	//poMon->StopMonsterAttack();
}

//////////机器人行为////////
void RobotAction::Attack(float fAngle)
{
	//((Robot*)m_poActor)->StartRobotAttack(fAngle);
}

void RobotAction::StopAttack()
{
	//((Robot*)m_poActor)->StopRobotAttack();
}
