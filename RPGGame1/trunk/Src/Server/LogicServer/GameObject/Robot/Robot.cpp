#include "Server/LogicServer/GameObject/Robot/Robot.h"	

#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/LogicServer/LogicServer.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/SceneMgr/SceneBase.h"


LUNAR_IMPLEMENT_CLASS(Robot)
{
	DECLEAR_OBJECT_METHOD(Robot),
	DECLEAR_ACTOR_METHOD(Robot),
	LUNAR_DECLARE_METHOD(Robot, SetWeaponList),
	{0, 0}
};

Robot::Robot()
{
	Actor::m_nObjType = OBJTYPE::eOT_Robot;

	m_nHPSyncInterval = 333;
	m_nLastHPSyncTime = XTime::MSTime();

	m_nAIID = 0;
	m_poAI = NULL;

	m_fAtkAngle = 0;
	m_nStartAttackTime = 0;

	m_nGunIndex = -1;
	m_bReloading = false;
	m_nReloadCompleteTime = 0;
}

Robot::~Robot()
{
	SAFE_DELETE(m_poAI);
}

void Robot::Init(int64_t nObjID, int nConfID, const char* psName, int nAIID, int8_t nCamp, uint16_t uSyncHPTime)
{
	Object::Init(OBJTYPE::eOT_Robot, nObjID, nConfID, psName);
	m_nAIID = nAIID;
	m_nHPSyncInterval = uSyncHPTime;
}

void Robot::Update(int64_t nNowMS)
{
	Actor::Update(nNowMS);

	//定时同步血量
	if (nNowMS - m_nLastHPSyncTime >= m_nHPSyncInterval)
	{
		m_nLastHPSyncTime = nNowMS;
		//Actor::BroadcastSyncHP();
	}
	//更新AI
	if (m_poAI != NULL)
	{
		m_poAI->Update(nNowMS);
	}

	//攻击检测
	if (m_nStartAttackTime > 0)
	{
		//Reload冷却时间检测
		if (!IsReloading(nNowMS))
		{
			if (nNowMS - m_nStartAttackTime >= m_oHotWeaponList.tGunList[m_nGunIndex].uTimePerShot)
			{
				m_nStartAttackTime = nNowMS;
				OnBulletConsume();
			}
		}
	}
}

void Robot::OnEnterScene(SceneBase* poScene, int nAOIID, Point& oPos)
{
	Actor::OnEnterScene(poScene, nAOIID, oPos);
	if (m_nAIID > 0)
	{
		SceneBase* poScene = Actor::GetScene();
		m_oAStar.InitMapData(poScene->GetMapConf()->nMapID);

		m_poAI = XNEW(RobotAI)();
		m_poAI->Init(this, m_nAIID);
	}
}

void Robot::OnLeaveScene()
{
	Actor::OnLeaveScene();
	StopRobotAttack();
	if (m_poAI != NULL)
	{
		m_poAI->Stop();
	}
}

void Robot::OnDead(Actor* poAtker, int nAtkID, int nAtkType)
{
	StopRobotAttack();
	if (m_poAI != NULL)
	{
		m_poAI->Stop();
	}
	m_nReloadCompleteTime = 0;
	m_oHotWeaponList = m_oOrgWeaponList;
}

void Robot::OnBattleResult()
{
	Actor::StopRun();
	StopRobotAttack();
	if (m_poAI != NULL)
	{
		m_poAI->Stop();
	}
}

void Robot::OnRelive()
{
	if (m_poAI != NULL)
	{
		m_poAI->Start();
	}
}

void Robot::StartRobotAttack(float fAngle)
{
	float fNewAngle = 90 - fAngle; //因为模型默认面向上而cocos旋转原点向右,所以需要90减
	if (m_nStartAttackTime == 0)
	{
		m_fAtkAngle = fNewAngle; 
		CheckReloadAndAttack();
	}
	else
	{
		if (fNewAngle != m_fAtkAngle)
		{
			m_fAtkAngle = fNewAngle; 
			CheckReloadAndAttack();
		}
	}
}

void Robot::StopRobotAttack()
{
	if (m_nStartAttackTime > 0)
	{
		m_fAtkAngle = 0;
		m_nStartAttackTime = 0;
		//Actor::StopAttack();
	}
}

bool Robot::ReloadBullet()
{
	assert(m_nGunIndex >= 0);
	Gun* poOrgGun = &m_oOrgWeaponList.tGunList[m_nGunIndex];
	Gun* poCurrGun = &m_oHotWeaponList.tGunList[m_nGunIndex];
	if (poCurrGun->uClipCap >= poOrgGun->uClipCap)
	{
		//XLog(LEVEL_INFO, "%s Reload bullet already full\n", m_sName);
		return true;
	}
	if (poCurrGun->uSubType != eGT_SQ && poCurrGun->uBulletBackup <= 0)
	{
		//XLog(LEVEL_INFO, "%s Reload bullet fail\n", m_sName);
		return false;
	}
	if (poCurrGun->uSubType == eGT_SQ)
	{
		poCurrGun->uClipCap = poOrgGun->uClipCap;
	}
	else
	{
		int nReqBullet = poOrgGun->uClipCap - poCurrGun->uClipCap;
		nReqBullet = XMath::Min(nReqBullet, (int)poCurrGun->uBulletBackup);
		poCurrGun->uClipCap += nReqBullet;
		poCurrGun->uBulletBackup -= nReqBullet;
	}
	m_nReloadCompleteTime = XTime::MSTime() + poCurrGun->uReloadTime;
	m_bReloading = true;
	//XLog(LEVEL_INFO, "%s Reload bullet ok\n", m_sName);
	return true;
}

bool Robot::SwitchWeapon()
{
	assert(m_nGunIndex >= 0);
	int nMetGunNum = 0;
	int tMetGuns[nMAX_GUNS];
	int nShouQiangIndex = -1;
	Gun* poOldGun = &m_oHotWeaponList.tGunList[m_nGunIndex];
	for (int i = 0; i < nMAX_GUNS; i++)
	{
		Gun& oHotGun = m_oHotWeaponList.tGunList[i];
		if (oHotGun.uID <= 0)
		{
			break;
		}
		if (i != m_nGunIndex)
		{
			if (oHotGun.uSubType == eGT_SQ)
			{
				nShouQiangIndex = i;
			}
			else if (oHotGun.uClipCap > 0 || oHotGun.uBulletBackup > 0)
			{
				tMetGuns[nMetGunNum++] = i;
			}
		}
	}
	if (nMetGunNum == 0 && nShouQiangIndex < 0)
	{
		//XLog(LEVEL_INFO, "%s Switch weapon fail\n", m_sName);
		return false;
	}
	if (nMetGunNum > 0)
	{
		int nRnd = XMath::Random(1, nMetGunNum);
		m_nGunIndex = tMetGuns[nRnd-1];
	}
	else if (nShouQiangIndex >= 0)
	{
		m_nGunIndex = nShouQiangIndex;
	}
	Gun& oGun = m_oHotWeaponList.tGunList[m_nGunIndex];
	LuaWrapper::Instance()->FastCallLuaRef<void,CNOTUSE>("RobotSwitchWeapon", 0, "ii", Actor::GetID(), oGun.uID);
	//if (gbPrintBattle)
	//{
	//	XLog(LEVEL_INFO, "%s Switch weapon successful old:%d new:%d\n", m_sName, poOldGun->uID, oGun.uID);
	//}
	return true;
}

bool Robot::IsReloading(int64_t nNowMS)
{
	if (m_nReloadCompleteTime > nNowMS)
	{
		return true;
	}
	if (m_bReloading && m_nReloadCompleteTime <= nNowMS)
	{
		m_bReloading = false;
		if (m_nStartAttackTime > 0)
		{
			Gun& oGun = m_oHotWeaponList.tGunList[m_nGunIndex];
			//Actor::StartAttack(m_oPos.x, m_oPos.y, oGun.uID, 0, m_fAtkAngle, oGun.uClipCap);
			oGun.uClipCap--;
			m_nStartAttackTime = nNowMS;
		}
	}
	return false;
}

bool Robot::CheckReloadAndAttack()
{
	int64_t nNowMS = XTime::MSTime();
	//正在Reload
	if (IsReloading(nNowMS))
	{
		return false;
	}

	//是否需要Reload
	Gun* poGun = &m_oHotWeaponList.tGunList[m_nGunIndex];
	if (poGun->uClipCap > 0)
	{
		//Actor::StartAttack(m_oPos.x, m_oPos.y, poGun->uID, 0, m_fAtkAngle, poGun->uClipCap);
		if (m_nStartAttackTime == 0)
		{
			poGun->uClipCap--;
			m_nStartAttackTime = nNowMS;
		}
		return true;
	}

	//Actor::StopAttack();

	//雷攻
	int nRnd = XMath::Random(1, 100);
	int nDropBombRate = m_poAI->GetAIConf()->nDropBombRate;
	if (nRnd >= 1 && nRnd <= nDropBombRate)
	{
		BombAttack();
	}
	
	//换枪
	nRnd = XMath::Random(1, 100);
	int nSwitchRate = m_poAI->GetAIConf()->nSwitchWeaponRate;
	if (nRnd >= 1 && nRnd <= nSwitchRate)
	{
		if (!SwitchWeapon())
		{
			ReloadBullet();
			return false;
		}

		poGun = &m_oHotWeaponList.tGunList[m_nGunIndex];
		if (poGun->uClipCap <= 0)
		{
			bool bRet = ReloadBullet();
			assert(bRet);
			return false;
		}
		//Actor::StartAttack(m_oPos.x, m_oPos.y, poGun->uID, 0, m_fAtkAngle, poGun->uClipCap);
		poGun->uClipCap--;
		m_nStartAttackTime = nNowMS;
	}

	if (ReloadBullet() || !SwitchWeapon())
	{
		return false;
	}
	poGun = &m_oHotWeaponList.tGunList[m_nGunIndex];
	if (poGun->uClipCap <= 0)
	{
		bool bRet = ReloadBullet();
		assert(bRet);
		return false;
	}
	//Actor::StartAttack(m_oPos.x, m_oPos.y, poGun->uID, 0, m_fAtkAngle, poGun->uClipCap);
	poGun->uClipCap--;
	m_nStartAttackTime = nNowMS;
	return true;
}

void Robot::OnBulletConsume()
{
	Gun& oGun = m_oHotWeaponList.tGunList[m_nGunIndex];
	if (oGun.uClipCap == 0)
	{
		CheckReloadAndAttack();
		return;
	}
	oGun.uClipCap--;
}

void Robot::BombAttack()
{
	int64_t nNowMS = XTime::MSTime();
	int nBombNum = 0;
	Bomb* tUsableBomb[nMAX_BOMBS];
	for (int i = 0; i < nMAX_BOMBS; i++)
	{
		Bomb& oBomb = m_oHotWeaponList.tBombList[i];
		if (oBomb.uID <= 0) break;
		if (oBomb.uBombCap > 0 && oBomb.nCDCompleteTime <= nNowMS)
		{
			tUsableBomb[nBombNum++] = &oBomb;
		}
	}
	if (nBombNum <= 0)
	{
		return;
	}
	int nRnd = XMath::Random(1, nBombNum);
	Bomb* poBomb = tUsableBomb[nRnd - 1];
	//Actor::StartAttack(m_oPos.x, m_oPos.y, poBomb->uID, 0, m_fAtkAngle, poBomb->uBombCap);
	poBomb->uBombCap--;
	poBomb->nCDCompleteTime = nNowMS + poBomb->uBombCD;
}




///////////////////lua export///////////////////
int Robot::SetWeaponList(lua_State* pState)
{
	luaL_checktype(pState, 1, LUA_TTABLE);
	lua_getfield(pState, 1, "nCurrWeapon");
	int nCurrWeapon = (uint16_t)luaL_checkinteger(pState, -1);
	lua_getfield(pState, 1, "tGunList");
	int nGuns = (int)lua_rawlen(pState, -1);
	assert(nGuns > 0 && nCurrWeapon > 0);
	for (int i = 1; i <= nGuns && i <= nMAX_GUNS; i++)
	{
		lua_rawgeti(pState, -1, i);
		luaL_checktype(pState, -1, LUA_TTABLE);

		Gun& oGun = m_oOrgWeaponList.tGunList[i - 1];
		lua_getfield(pState, -1, "uID");
		oGun.uID = (uint16_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_getfield(pState, -1, "uSubType");
		oGun.uSubType = (uint8_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_getfield(pState, -1, "uClipCap");
		oGun.uClipCap = (uint8_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_getfield(pState, -1, "uBulletBackup");
		oGun.uBulletBackup= (uint16_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_getfield(pState, -1, "uReloadTime");
		oGun.uReloadTime= (uint16_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_getfield(pState, -1, "uTimePerShot");
		oGun.uTimePerShot = (uint16_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_getfield(pState, -1, "uRecoilTime");
		oGun.uRecoilTime = (uint16_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_pop(pState, 1);

		if (oGun.uID == nCurrWeapon)
		{
			m_nGunIndex = i - 1;
		}
	}
	assert(m_nGunIndex >= 0);

	lua_getfield(pState, 1, "tBombList");
	int nBombs = (int)lua_rawlen(pState, -1);
	for (int i = 1; i <= nBombs && i <= nMAX_BOMBS; i++)
	{
		lua_rawgeti(pState, -1, i);
		luaL_checktype(pState, -1, LUA_TTABLE);

		Bomb& oBomb = m_oOrgWeaponList.tBombList[i - 1];
		lua_getfield(pState, -1, "uID");
		oBomb.uID = (uint16_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_getfield(pState, -1, "uBombCap");
		oBomb.uBombCap = (uint8_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_getfield(pState, -1, "uBombCD");
		oBomb.uBombCD = (uint16_t)luaL_checkinteger(pState, -1);
		lua_pop(pState, 1);

		lua_pop(pState, 1);
	}

	m_oHotWeaponList = m_oOrgWeaponList;

	return 0;
}