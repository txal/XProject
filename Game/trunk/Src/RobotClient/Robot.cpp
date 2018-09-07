#include "RobotClient/Robot.h"
#include "RobotClient/RobotMgr.h"
#include "Include/Logger/Logger.hpp"
#include "Include/Network/Network.hpp"
#include "Include/Script/Script.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Server/Base/CmdDef.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"

char Robot::className[] = "Robot";
Lunar<Robot>::RegType Robot::methods[] =
{
	LUNAR_DECLARE_METHOD(Robot, GetPos),
	LUNAR_DECLARE_METHOD(Robot, SetPos),
	LUNAR_DECLARE_METHOD(Robot, SetName),
	LUNAR_DECLARE_METHOD(Robot, StartRun),
	LUNAR_DECLARE_METHOD(Robot, StopRun),
	LUNAR_DECLARE_METHOD(Robot, SetMapID),
	LUNAR_DECLARE_METHOD(Robot, GenPacketIdx),
	{0, 0}
};

extern ServerContext* g_poContext;
Robot::Robot(RobotMgr* poRobotMgr)
{
	m_poPacketCache = Packet::Create();
	oPKWriter.SetPacket(m_poPacketCache);

	m_poRobotMgr = poRobotMgr;
	m_nSessionID = 0;
	m_sName[0] = 0;
	m_uPacketIdx = 0;
	m_nLastUpdateTime = XTime::MSTime();

	m_nMapID = 0;
	m_poMapConf = NULL;

	m_nSpeedX = 0;
	m_nSpeedY = 0;
	m_nMoveSpeed = 300;
	m_nStartRunX = 0;
	m_nStartRunY = 0;
	m_nRunStartTime = 0;
}

Robot::~Robot()
{
	m_poPacketCache->Release();
}

void Robot::Update(int64_t nNowMS)
{
	m_nLastUpdateTime = nNowMS;
	ProcessRun(nNowMS);
}

void Robot::ProcessRun(int64_t nNowMS)
{
	if (m_nRunStartTime > 0)
	{
		int nTimeElapased = (int)(nNowMS - m_nRunStartTime);
		int nNewX = m_nStartRunX;
		int nNewY = m_nStartRunY;
		//匀速移动过程
		nNewX += (int)(m_nSpeedX * nTimeElapased * 0.001f);
		nNewY += (int)(m_nSpeedY * nTimeElapased * 0.001f);

		int nTmpX = nNewX, nTmpY = nNewY;
		bool bResult = FixMovePoint(m_poMapConf, m_oPos.x, m_oPos.y, nNewX, nNewY);
		//if (bResult && nNewX == m_oPos.x && nNewY == m_oPos.y) nTimeElapased 很短时可能会相等
		//{
		//	bResult = false;
		//}
		m_oPos.x = nNewX;
		m_oPos.y = nNewY;
		//XLog(LEVEL_INFO, "update start:(%d,%d), tmp:(%d,%d) pos:(%d,%d) res:%d elap:%d\n", m_nStartRunX, m_nStartRunY, nTmpX, nTmpY, nNewX, nNewY, bRes, nTimeElapased);
		if (!bResult || (m_nSpeedX == 0 && m_nSpeedY == 0))
		{
			StopRun();
		}
	}
}

void Robot::OnConnect(int nSessionID)
{
	m_nSessionID = nSessionID;
    LuaWrapper::Instance()->FastCallLuaRef<void>("OnRobotConnected", 0, "i", m_nSessionID);
}

void Robot::OnDisconnect()
{
	LuaWrapper::Instance()->FastCallLuaRef<void>("OnRobotDisconnected", 0, "i", m_nSessionID);
}

void Robot::StartRun(int nSpeedX, int nSpeedY)
{
	if (m_nRunStartTime == 0 || m_nSpeedX != nSpeedX || m_nSpeedY != nSpeedY)
	{
		m_nRunStartTime = XTime::MSTime();
		m_nSpeedX = nSpeedX;
		m_nSpeedY = nSpeedY;
		m_nStartRunX = m_oPos.x;
		m_nStartRunY = m_oPos.y;

		m_poPacketCache->Reset();
		uint32_t uClientTick = (uint32_t)(((double)clock() / (double)CLOCKS_PER_SEC) * 1000.0);
		oPKWriter << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int16_t)m_nSpeedX << (int16_t)m_nSpeedY << uClientTick;
		Packet* poPacket = m_poPacketCache->DeepCopy();
		NetAdapter::SendExter(NSCltSrvCmd::cPlayerRun, poPacket, 0, m_nSessionID, ++m_uPacketIdx);
		//XLog(LEVEL_INFO, "%s start run pos:(%d,%d) speed:(%d,%d) tick:%u\n", m_sName, m_oPos.x, m_oPos.y, m_nSpeedX, m_nSpeedY, uClientTick);
	}
}

void Robot::StopRun()
{
	if (m_nRunStartTime > 0)
    {
        m_nRunStartTime = 0;
		m_nSpeedX = 0;
		m_nSpeedY = 0;
		m_nStartRunX = 0;
		m_nStartRunY = 0;


		m_poPacketCache->Reset();
		uint32_t uClientTick = (uint32_t)(((double)clock() / (double)CLOCKS_PER_SEC) * 1000.0);
		oPKWriter << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << uClientTick;
		Packet* poPacket = m_poPacketCache->DeepCopy();
		NetAdapter::SendExter(NSCltSrvCmd::cPlayerStopRun, poPacket, 0, m_nSessionID, ++m_uPacketIdx);
		//XLog(LEVEL_INFO, "%s stop run pos:(%d,%d)\n", m_sName, m_oPos.x, m_oPos.y);
    }
}


void Robot::OnSyncActorPosHandler(Packet* poPacket)
{
	PacketReader oPKReader(poPacket);
	int nAOIID = 0;
	uint16_t uPosX = 0, uPosY = 0;
	oPKReader >> nAOIID >> uPosX >> uPosY;
	m_oPos.x = uPosX;
	m_oPos.y = uPosY;
	StopRun();
	//XLog(LEVEL_INFO, "%s sync pos pos:(%u,%u)\n", m_sName, uPosX, uPosY);
}

void Robot::CalcMoveSpeed(int nMoveSpeed, int nDir8, int& nSpeedX, int& nSpeedY)
{
	assert(nMoveSpeed >= 0);
	switch (nDir8)
	{
		case 0:
			nSpeedX = 0;
			nSpeedY = -nMoveSpeed;
			break;
		case 1:
			nSpeedX = nMoveSpeed;
			nSpeedY = -nMoveSpeed;
			break;
		case 2:
			nSpeedX = nMoveSpeed;
			nSpeedY = 0;
			break;
		case 3:
			nSpeedX = nMoveSpeed;
			nSpeedY = nMoveSpeed;
			break;
		case 4:
			nSpeedX = 0;
			nSpeedY = nMoveSpeed;
			break;
		case 5:
			nSpeedX = -nMoveSpeed;
			nSpeedY = nMoveSpeed;
			break;
		case 6:
			nSpeedX = -nMoveSpeed;
			nSpeedY = 0;
			break;
		case 7:
			nSpeedX = -nMoveSpeed;
			nSpeedY = -nMoveSpeed;
			break;
		default:
			nSpeedX = 0;
			nSpeedY = 0;
			break;
	}

	//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
	//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
	//以下速度调整系数是目前最优体验与数值平衡值，请勿随意更改！
	//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
	//★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★★
	if (nSpeedX == 0)
	{
		nSpeedY *= 0.7f;
	}
	else if (nSpeedY != 0)
	{
		nSpeedY *= 0.4f;//0.3f;miros：2014-02-10 调整默认移动比例值，优化操作体验
		nSpeedX *= 0.9f;//0.7f;miros：2014-02-10 调整默认移动比例值，优化操作体验
	}
}

bool Robot::FixMovePoint(MapConf* poMapConf, int nStartPosX, int nStartPosY, int& nTarPosX, int& nTarPosY)
{
	if (poMapConf == NULL)
	{
		return false;
	}
	bool bResult = true;
	int nMapWidthPixel = poMapConf->nPixelWidth;
	int nMapHeightPixel = poMapConf->nPixelHeight;
	if (nStartPosX < 0)
	{
		nStartPosX = 0;
		bResult = false;
	}
	else if (nStartPosX >= nMapWidthPixel)
	{
		nStartPosX = nMapWidthPixel - 1;
		bResult = false;
	}
	if (nStartPosY < 0)
	{
		nStartPosY = 0;
		bResult = false;
	}
	else if (nStartPosY >= nMapHeightPixel)
	{
		nStartPosY = nMapHeightPixel - 1;
		bResult = false;
	}

	bool bXOut = false;
	bool bYOut = false;
	if (nTarPosX < 0)
	{
		nTarPosX = 0;
		bXOut = true;
	}
	else if (nTarPosX >= nMapWidthPixel)
	{
		nTarPosX = nMapWidthPixel - 1;
		bXOut = true;
	}
	if (nTarPosY < 0)
	{
		nTarPosY = 0;
		bYOut = true;
	}
	else if (nTarPosY >= nMapHeightPixel)
	{
		nTarPosY = nMapHeightPixel - 1;
		bYOut = true;
	}
	if (bXOut && bYOut)
	{
		bResult = false;
	}

	double fUnitX = (double)nStartPosX / gnUnitWidth;
	double fUnitY = (double)nStartPosY / gnUnitHeight;
	double fUnitTarX = (double)nTarPosX / gnUnitWidth;
	double fUnitTarY = (double)nTarPosY / gnUnitHeight;
	if ((int)fUnitX == (int)fUnitTarX && (int)fUnitY == (int)fUnitTarY)
	{
		return bResult;
	}
	bool bInBlockUnit = poMapConf->IsBlockUnit((int)fUnitX, (int)fUnitY);
	double fDistUnitX = fUnitTarX - fUnitX;
	double fDistUnitY = fUnitTarY - fUnitY;
	int nDistUnitMax = XMath::Max(1, XMath::Max((int)ceil(abs(fDistUnitX)), (int)ceil(abs(fDistUnitY))));
	fDistUnitX = fDistUnitX / nDistUnitMax;
	fDistUnitY = fDistUnitY / nDistUnitMax;

	double fOrgUnitX = fUnitX, fOrgUnitY = fUnitY;
	for (int i = nDistUnitMax - 1; i > -1; --i)
	{
		double fNewUnitX = fUnitX + fDistUnitX;
		double fNewUnitY = fUnitY + fDistUnitY;

		int8_t nMasks = 0;
		if (fNewUnitX >= 0 && fNewUnitX < poMapConf->nUnitNumX && fNewUnitY >= 0 && fNewUnitY < poMapConf->nUnitNumY)
		{
			nMasks = 1;
		}
		if (nMasks == 0)
		{
			bResult = false;
		}
		else if (!bInBlockUnit)
		{
			bool bBlockUnit = poMapConf->IsBlockUnit((int)fNewUnitX, (int)fNewUnitY);
			if (bBlockUnit)
			{
				bResult = false;
			}
		}
		if (bResult)
		{
			fUnitX = fNewUnitX;
			fUnitY = fNewUnitY;
		}
		else
		{
			if (fUnitX != fOrgUnitX || fUnitY != fOrgUnitY)
			{
				nTarPosX = (int)(fUnitX * gnUnitWidth);
				nTarPosY = (int)(fUnitY * gnUnitHeight);
			}
			else
			{
				nTarPosX = nStartPosX;
				nTarPosY = nStartPosY;
			}
			break;
		}
	}
	return bResult;
}



//////////////lua export////////////
int Robot::GetPos(lua_State* pState)
{
	lua_pushinteger(pState, m_oPos.x);
	lua_pushinteger(pState, m_oPos.y);
	return 2;
}

int Robot::SetPos(lua_State* pState)
{
	int nPosX = (int)luaL_checkinteger(pState, 1);
	int nPosY = (int)luaL_checkinteger(pState, 2);
	m_oPos.x = nPosX;
	m_oPos.y = nPosY;
	return 0;
}

int Robot::SetName(lua_State* pState)
{
	const char* psName = luaL_checkstring(pState, 1);
	strcpy(m_sName, psName);
	return 0;
}

int Robot::SetMoveSpeed(lua_State* pState)
{
	m_nMoveSpeed = (int)luaL_checkinteger(pState, 1);
	return 0;
}

int Robot::StartRun(lua_State* pState)
{
	int nSpeedX, nSpeedY;
	if (lua_gettop(pState) == 2)
	{
		nSpeedX = (int)luaL_checkinteger(pState, 1);
		nSpeedY = (int)luaL_checkinteger(pState, 2);
	}
	else
	{
		int nDir = (int)luaL_checkinteger(pState, 1);
		CalcMoveSpeed(m_nMoveSpeed, nDir, nSpeedX, nSpeedY);
	}
	StartRun(nSpeedX, nSpeedY);
	return 0;
}

int Robot::StopRun(lua_State* pState)
{
	StopRun();
	return 0;
}

int Robot::SetMapID(lua_State* pState)
{
	m_nMapID = (int)luaL_checkinteger(pState, 1);
	m_poMapConf = ConfMgr::Instance()->GetMapMgr()->GetConf(m_nMapID);
	return 0;
}

int Robot::GenPacketIdx(lua_State* pState)
{
	lua_pushinteger(pState, ++m_uPacketIdx);
	return 1;
}
