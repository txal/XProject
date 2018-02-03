#include "Server/LogicServer/Object/Player/Player.h"	
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/SceneMgr/Scene.h"

LUNAR_IMPLEMENT_CLASS(Player)
{
	DECLEAR_OBJECT_METHOD(Player),
	DECLEAR_ACTOR_METHOD(Player),
	{0, 0}
};

Player::Player()
{
	m_nObjType = eOT_Player;
}

Player::~Player()
{
}

void Player::Init(int nID, int nConfID, const char* psName, int8_t nCamp)
{
	m_nObjID = nID;
	m_nConfID = nConfID;
	strcpy(m_sName, psName);
	m_nCamp = nCamp;
}

void Player::Update(int64_t nNowMS)
{
	Actor::Update(nNowMS);
}

void Player::OnEnterScene(Scene* poScene, const Point& oPos, int nAOIID)
{
	Actor::OnEnterScene(poScene, oPos, nAOIID);
}

void Player::AfterEnterScene()
{
	Actor::AfterEnterScene();
}

void Player::OnLeaveScene()
{
	Actor::OnLeaveScene();
}

void Player::PlayerRunHandler(Packet* poPacket)
{
	if (IsDead() || GetScene() == NULL)
	{
		XLog(LEVEL_ERROR, "%s can not run: dead:%d scene:%s\n", m_sName, m_bDead, m_poScene ? "true" : "NULL");
		return;
	}
	uint16_t uPosX = 0;
	uint16_t uPosY = 0;
	int16_t nSpeedX = 0;
	int16_t nSpeedY = 0;
	uint32_t uClientMSTime = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> uPosX >> uPosY >> nSpeedX >> nSpeedY >> uClientMSTime;
	//客户端提供的时间值必须大于起始时间值
	if (uClientMSTime < m_nClientRunStartMSTime)
	{
		XLog(LEVEL_ERROR,  "%s sync pos: start run client time invalid\n", m_sName);
		Actor::SendSyncPosition();
		return;
	}
	MapConf* poMapConf = m_poScene->GetMapConf();
	if (uPosX >= poMapConf->nPixelWidth
		|| uPosY >= poMapConf->nPixelHeight
		|| poMapConf->IsBlockUnit(uPosX/gnUnitWidth, uPosY/gnUnitHeight))
	{
		XLog(LEVEL_ERROR, "%s sync pos: start run pos invalid\n", m_sName);
		Actor::SendSyncPosition();
		return;
	}
	//正在移动则先更新移动后的新位置
	if (m_nRunStartMSTime > 0)
	{
		Actor::UpdateRunState(m_nRunStartMSTime + uClientMSTime - m_nClientRunStartMSTime);
	}
	//客户端与服务器坐标误差在一定范围内，则以客户端坐标为准
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uPosX, uPosY))
	{
		XLog(LEVEL_ERROR, "%s sync pos: start run faultbit srv:(%d, %d) clt:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY);
		uPosX = (uint16_t)m_oPos.x;
		uPosY = (uint16_t)m_oPos.y;
		Actor::SendSyncPosition();
	}
	Actor::SetPos(Point(uPosX, uPosY), __FILE__, __LINE__);
	
	m_nClientRunStartMSTime = uClientMSTime;
	Actor::StartRun(nSpeedX, nSpeedY);
}

void Player::PlayerStopRunHandler(Packet* poPacket)
{
	if (GetScene() == NULL)
	{
		return;
	}
	uint16_t uPosX = 0;
	uint16_t uPosY = 0;
	uint32_t uClientMSTime = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> uPosX >> uPosY >> uClientMSTime;
	if (m_nRunStartMSTime == 0)
	{
		//XLog(LEVEL_INFO, "%s already stop client\n", m_sName, uPosX, uPosY);
		if (uPosX != m_oPos.x || uPosY != m_oPos.y)
		{
			//XLog(LEVEL_ERROR, "%s sync pos: stop run srv:(%d,%d) clt:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY);
			Actor::SendSyncPosition();
		}
		return;
	}
	//客户端提交的时间比起跑时提交的时间小，则视为非法数据，强制使用服务器计算的值
	MapConf* poMapConf = m_poScene->GetMapConf();
	if (uClientMSTime < m_nClientRunStartMSTime
		|| uPosX >= poMapConf->nPixelWidth
		|| uPosY >= poMapConf->nPixelHeight
		|| poMapConf->IsBlockUnit(uPosX/gnUnitWidth, uPosY/gnUnitHeight))
	{
		int64_t nNowMS = XTime::MSTime();
		Actor::UpdateRunState(nNowMS);
		Actor::SendSyncPosition();
		Actor::StopRun(true, true);
		XLog(LEVEL_ERROR, "%s sync pos: stop run pos(%d,%d) or time(%d) error\n", m_sName, uPosX, uPosY, uClientMSTime-m_nClientRunStartMSTime);
		return;
	}
	//正在移动则先更新移动后的新位置
	if (m_nRunStartMSTime > 0)
	{
		//这里如果前方有障碍区，而客户端发上来的坐标进入了障碍区，且没有超过修正范围，那么以客户端为准，服务端也会进入障碍区
		Actor::UpdateRunState(m_nRunStartMSTime + uClientMSTime - m_nClientRunStartMSTime);
	}
	//客户端与服务器坐标误差在一定范围内，则以客户端坐标为准
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uPosX, uPosY))
	{
		XLog(LEVEL_ERROR, "%s sync pos: stop run faultbit srv:(%d, %d) clt:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y, uPosX, uPosY);
		uPosX = (uint16_t)m_oPos.x;
		uPosY = (uint16_t)m_oPos.y;
		Actor::SendSyncPosition();
	}
	m_nClientRunStartMSTime = uClientMSTime;
	Actor::SetPos(Point(uPosX, uPosY), __FILE__, __LINE__);
	Actor::StopRun(true, true);
}

void Player::PlayerStartAttackHandler(Packet* poPacket)
{
	if (IsDead() || GetScene() == NULL)
	{
		return;
	}
	int nAOIID = 0;
	uint16_t uPosX = 0;
	uint16_t uPosY = 0;
	uint16_t uAtkID = 0;
	uint8_t uAtkType = 0;
	float fAtkAngle = 0.0f;
	int16_t nRemainBullet = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> nAOIID >> uPosX >> uPosY >> uAtkID >> uAtkType >> fAtkAngle >> nRemainBullet;
	if (GetAOIID() != nAOIID)
	{
		XLog(LEVEL_ERROR, "%s start attack aoi id error:%d correct:%d\n", m_sName, nAOIID, GetAOIID());
		return;
	}
	//XLog(LEVEL_INFO, "%s attack currpos:(%d,%d) atkid:%d atktype:%d angle:%f tick:%d\n", m_sName, uPosX, uPosY, uAtkID, uAtkType, fAtkAngle, uClientMSTime);
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uPosX, uPosY))
	{
		Actor::SendSyncPosition();
		XLog(LEVEL_ERROR, "%s attack pos error:(%d,%d) curr:(%d,%d)\n", m_sName, uPosX, uPosY, m_oPos.x, m_oPos.y);
		return;
	}
	Actor::StartAttack(uPosX, uPosY, uAtkID, uAtkType, fAtkAngle, nRemainBullet);
}

void Player::PlayerStopAttackHandler(Packet* poPacket)
{
	if (GetScene() == NULL)
	{
		return;
	}
	int nAOIID = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> nAOIID;
	if (GetAOIID() != nAOIID)
	{
		XLog(LEVEL_ERROR, "%s stop attack aoi id error:%d correct:%d\n", m_sName, nAOIID, GetAOIID());
		return;
	}
	Actor::StopAttack();
}

void Player::PlayerHurtedHandler(Packet* poPacket)
{
	if (IsDead() || GetScene() == NULL )
	{
		return;
	}
	int nSrcAOIID = 0;
	uint8_t uSrcType = 0;
	uint16_t uSrcPosX = 0;
	uint16_t uSrcPosY = 0;
	uint16_t uMyPosX = 0;
	uint16_t uMyPosY = 0;
	int nCurrHP = 0;
	int nHurtHP = 0;
	uint16_t uAtkID = 0;
	uint8_t uAtkType = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> nSrcAOIID >> uSrcType >> uSrcPosX >> uSrcPosY >> uMyPosX >> uMyPosY >> nCurrHP >> nHurtHP >> uAtkID >> uAtkType;
	if (nHurtHP <= 0)
	{
		XLog(LEVEL_ERROR, "PlayerHurted: %s hurted hp error:%d\n", m_sName, nHurtHP);
		return;
	}
	Actor* poSource = (Actor*)m_poScene->GetGameObj(nSrcAOIID);
	if (poSource == NULL || poSource->GetScene() != GetScene())
	{
		XLog(LEVEL_ERROR, "PlayerHurted: attacker has leave scene!\n");
		return;
	}
	if (poSource != this && poSource->GetType() != eOT_Robot && poSource->GetType() != eOT_Monster)
	{
		XLog(LEVEL_ERROR, "PlayerHurted: attacker:%s type error!\n", poSource->GetName());
		return;
	}

	//这里不校验当前血量,因为客户端是收到受伤广播后才扣血(包括自己),如果同时受多次伤害,那么当前血量就不正确了

	Point& oSrcPos = poSource->GetPos();
	if (!BattleUtil::IsAcceptablePositionFaultBit(oSrcPos.x, oSrcPos.y, uSrcPosX, uSrcPosY))
	{
		poSource->SendSyncPosition();
		XLog(LEVEL_ERROR, "PlayerHurted: %s hurted src pos error:(%d,%d) curr:(%d,%d)\n", m_sName, uSrcPosX, uSrcPosY, oSrcPos.x, oSrcPos.y);
	}
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uMyPosX, uMyPosY))
	{
		Actor::SendSyncPosition();
		XLog(LEVEL_ERROR, "PlayerHurted: %s hurted tar pos error:(%d,%d) curr:(%d,%d)\n", m_sName, uMyPosX, uMyPosY, m_oPos.x, m_oPos.y);
		return;
	}
	OnHurted(poSource, nHurtHP, uAtkID, uAtkType);
	if (gbPrintBattle)
	{
		XLog(LEVEL_INFO, "PlayerHurted: %s->%s hurted pos:(%d, %d) hurt:%d after:%d\n", poSource->GetName(), m_sName, uMyPosX, uMyPosY, nHurtHP, m_oFightParam[eFP_HP]);
	}
}

void Player::PlayerDamageHandler(Packet* poPacket)
{
	if (GetScene() == NULL)
	{
		return;
	}
	int nTarAOIID = 0;
	uint8_t uTarType = 0;
	uint16_t uMyPosX = 0;
	uint16_t uMyPosY = 0;
	uint16_t uTarPosX = 0;
	uint16_t uTarPosY = 0;
	int nCurrHP = 0;
	int nHurtHP = 0;
	uint16_t uAtkID = 0;
	uint8_t uAtkType = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> nTarAOIID >> uTarType >> uMyPosX >> uMyPosY >> uTarPosX >> uTarPosY >> nCurrHP >> nHurtHP >> uAtkID >> uAtkType;
	if (nHurtHP <= 0)
	{
		XLog(LEVEL_ERROR, "PlayerDamage: dmg hp error:%d\n", nHurtHP);
		return;
	}
	Actor* poTarget = (Actor*)m_poScene->GetGameObj(nTarAOIID);
	if (poTarget == NULL || poTarget->IsDead() || poTarget->GetScene() != GetScene())
	{
		XLog(LEVEL_ERROR, "PlayerDamage: target not exist or dead or leave scene!\n");
		return;
	}
	if (!BattleUtil::IsAcceptablePositionFaultBit(m_oPos.x, m_oPos.y, uMyPosX, uMyPosY))
	{
		SendSyncPosition();
		XLog(LEVEL_ERROR, "PlayerDamage: %s src pos error:(%d,%d) curr:(%d,%d)\n", m_sName, uMyPosX, uMyPosY, m_oPos.x, m_oPos.y);
		return;
	}
	Point& oTarPos = poTarget->GetPos();
	if (!BattleUtil::IsAcceptablePositionFaultBit(oTarPos.x, oTarPos.y, uTarPosX, uTarPosY))
	{
		poTarget->SendSyncPosition();
		XLog(LEVEL_ERROR, "PlayerDamage: %s tar pos error:(%d,%d) curr:(%d,%d)\n", poTarget->GetName(), uTarPosX, uTarPosY, oTarPos.x, oTarPos.y);
		return;
	}
	poTarget->OnHurted(this, nHurtHP, uAtkID, uAtkType);
	if (gbPrintBattle)
	{
		XLog(LEVEL_INFO, "PlayerDamage: %s->%s pos(%d, %d) hurt:%d after:%d\n", m_sName, poTarget->GetName(), uTarPosX, uTarPosY, nHurtHP, poTarget->GetFightParam()[eFP_HP]);
	}
}

void Player::EveHurtedHandler(Packet* poPacket)
{
	if (GetScene() == NULL)
	{
		return;
	}
	int nSrcAOIID = 0;
	int nTarAOIID = 0;
	int nCurrHP = 0;
	int nHurtHP = 0;
	uint16_t uAtkID = 0;
	uint8_t uAtkType = 0;
	goPKReader.SetPacket(poPacket);
	goPKReader >> nSrcAOIID >> nTarAOIID >> nCurrHP >> nHurtHP >> uAtkID >> uAtkType;
	Actor* poTarget = (Actor*)m_poScene->GetGameObj(nTarAOIID);
	if (poTarget == NULL || poTarget->IsDead() || poTarget->GetScene() != GetScene())
	{
		XLog(LEVEL_ERROR, "EveHurtedHandler: target %s not exist or dead or leave scene!\n", poTarget ? poTarget->GetName() : "NULL");
		return;
	}
	if (nHurtHP <= 0)
	{
		XLog(LEVEL_ERROR, "EveHurtedHandler: tar %s hurted hp error:%d!\n", poTarget->GetName(), nHurtHP);
		return;
	}
	if (poTarget->GetType() != eOT_Monster && poTarget->GetType() != eOT_Robot)
	{
		XLog(LEVEL_ERROR, "EveHurtedHandler: tar %s must be monster or robot!\n", poTarget->GetName());
		return;
	}
	Actor* poSource = (Actor*)m_poScene->GetGameObj(nSrcAOIID);
	if (poSource == NULL || poSource->GetScene() != GetScene())
	{
		XLog(LEVEL_ERROR, "EveHurtedHandler: src not exist or leave scene!\n");
		return;
	}
	if (poSource->GetType() != eOT_Monster && poSource->GetType() != eOT_Robot)
	{
		XLog(LEVEL_ERROR, "EveHurtedHandler: src %s must be monster or robot!\n", poSource->GetName());
		return;
	}
	poTarget->OnHurted(poSource, nHurtHP, uAtkID, uAtkType);
	if (gbPrintBattle)
	{
		XLog(LEVEL_INFO, "EveHurtedHandler: %s->%s hurt:%d after:%d\n", poSource->GetName(), poTarget->GetName(), nHurtHP, poTarget->GetFightParam()[eFP_HP]);
	}
}


///////////////////lua export///////////////////