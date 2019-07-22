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
#include "Server/LogicServer/Component/Battle/BattleUtil.h"

LUNAR_IMPLEMENT_CLASS(Robot)
{
	LUNAR_DECLARE_METHOD(Robot, GetPos),
	LUNAR_DECLARE_METHOD(Robot, SetPos),
	LUNAR_DECLARE_METHOD(Robot, SetName),
	LUNAR_DECLARE_METHOD(Robot, StartRun),
	LUNAR_DECLARE_METHOD(Robot, StopRun),
	LUNAR_DECLARE_METHOD(Robot, IsRunning),
	LUNAR_DECLARE_METHOD(Robot, SetMapID),
	LUNAR_DECLARE_METHOD(Robot, PacketID),
	LUNAR_DECLARE_METHOD(Robot, CalcMoveSpeed),
	{0, 0}
};

extern ServerContext* gpoContext;
Robot::Robot(RobotMgr* poRobotMgr)
{
	m_poPacketCache = Packet::Create(nPACKET_DEFAULT_SIZE, nPACKET_OFFSET_SIZE, __FILE__, __LINE__);
	oPKWriter.SetPacket(m_poPacketCache);

	m_poRobotMgr = poRobotMgr;
	m_nSessionID = 0;
	m_sName[0] = 0;
	m_uPacketID = 0;
	m_nLastUpdateTime = XTime::MSTime();

	m_nMapID = 0;
	m_poMapConf = NULL;

	m_nSpeedX = 0;
	m_nSpeedY = 0;
	m_nMoveSpeed = 300;
	m_nStartRunX = 0;
	m_nStartRunY = 0;
	m_nRunStartTime = 0;

	m_nAOIID = 0;
}

Robot::~Robot()
{
	m_poPacketCache->Release();
	Lunar<Robot>::cthunk_once(LuaWrapper::Instance()->GetLuaState(), this);
}

void Robot::Update(int64_t nNowMS)
{
	if (nNowMS - m_nLastUpdateTime < 50)
		return;
	m_nLastUpdateTime = nNowMS;
	ProcessRun(nNowMS);
}

void Robot::SetPos(int nPosX, int nPosY)
{
	m_oPos.x = nPosX;
	m_oPos.y = nPosY;
}

void Robot::ProcessRun(int64_t nNowMS)
{
	bool bCanMove = false;
	if (m_nRunStartTime > 0)
	{
		int nNewPosX = 0;
		int nNewPosY = 0;
		bCanMove = CalcPositionAtTime(nNowMS, nNewPosX, nNewPosY);
		SetPos(nNewPosX, nNewPosY);
		if (!bCanMove || (m_nSpeedX == 0 && m_nSpeedY == 0))
		{
			StopRun();
		}
		if (m_oTarPos.IsValid())
		{
			Point oStartPos(m_nStartRunX, m_nStartRunY);
			if (oStartPos.Distance(m_oPos) >= oStartPos.Distance(m_oTarPos))
			{
				XLog(LEVEL_DEBUG, "%s reach target pos(%d,%d)\n", m_sName, m_oTarPos.x, m_oTarPos.y);
				StopRun();
			}
		}
		//XLog(LEVEL_DEBUG, "Pos(%d,%d) canmove:%d\n", nNewPosX, nNewPosY, bCanMove);
	}
}

bool Robot::CalcPositionAtTime(int64_t nNowMS, int& nNewPosX, int& nNewPosY)
{
	int nNewX = m_nStartRunX;
	int nNewY = m_nStartRunY;
	int nTimeElapased = (int)(nNowMS - m_nRunStartTime);

	if (nTimeElapased > 0)
	{
		//常规移动计算
		nNewX += (int)((m_nSpeedX * nTimeElapased) * 0.001);
		nNewY += (int)((m_nSpeedY * nTimeElapased) * 0.001);
	}

	bool bRes = true;
	if (nNewX != m_oPos.x || nNewY != m_oPos.y)
	{
		bRes = BattleUtil::FixLineMovePoint(m_poMapConf, m_oPos.x, m_oPos.y, nNewX, nNewY);
	}
	nNewPosX = nNewX;
	nNewPosY = nNewY;
	return bRes;
}

void Robot::OnConnect(int nSessionID)
{
	m_nSessionID = nSessionID;
    LuaWrapper::Instance()->FastCallLuaRef<void,CNOTUSE>("OnRobotConnected", 0, "i", m_nSessionID);
}

void Robot::OnDisconnect()
{
	LuaWrapper::Instance()->FastCallLuaRef<void,CNOTUSE>("OnRobotDisconnected", 0, "i", m_nSessionID);
}

void Robot::StartRun(int nSpeedX, int nSpeedY, int nDir)
{
	if (m_nRunStartTime == 0 || m_nSpeedX != nSpeedX || m_nSpeedY != nSpeedY)
	{
		m_nRunStartTime = XTime::MSTime();
		m_nSpeedX = nSpeedX;
		m_nSpeedY = nSpeedY;
		m_nStartRunX = m_oPos.x;
		m_nStartRunY = m_oPos.y;

		m_poPacketCache->Reset();
		double dClientTick = (double)XTime::MSTime();
		oPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << (int16_t)m_nSpeedX << (int16_t)m_nSpeedY << dClientTick << (uint8_t)nDir << (uint16_t)m_oTarPos.x << (uint16_t)m_oTarPos.y;

		Packet* poPacket = m_poPacketCache->DeepCopy(__FILE__, __LINE__);
		NetAdapter::SERVICE_NAVI oNavi;
		oNavi.nTarSession = m_nSessionID;
		NetAdapter::SendExter(NSCltSrvCmd::cRoleStartRunReq, poPacket, oNavi, ++m_uPacketID);
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
		m_oTarPos.Reset();

		m_poPacketCache->Reset();
		double dClientTick = (double)XTime::MSTime();
		oPKWriter << m_nAOIID << (uint16_t)m_oPos.x << (uint16_t)m_oPos.y << dClientTick;

		Packet* poPacket = m_poPacketCache->DeepCopy(__FILE__, __LINE__);
		NetAdapter::SERVICE_NAVI oNavi;
		oNavi.nTarSession = m_nSessionID;
		NetAdapter::SendExter(NSCltSrvCmd::cRoleStopRunReq, poPacket, oNavi, ++m_uPacketID);
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
	int nSpeedX = (int)luaL_checkinteger(pState, 1);
	int nSpeedY = (int)luaL_checkinteger(pState, 2);
	int nTarPosX = (int)luaL_checkinteger(pState, 3);
	int nTarPosY = (int)luaL_checkinteger(pState, 4);
	int nDir = (int)luaL_checkinteger(pState, 5);
	m_oTarPos = Point(nTarPosX, nTarPosY);
	StartRun(nSpeedX, nSpeedY, nDir);
	return 0;
}

int Robot::StopRun(lua_State* pState)
{
	StopRun();
	return 0;
}

int Robot::IsRunning(lua_State* pState)
{
	bool bRunning = m_nRunStartTime > 0;
	lua_pushboolean(pState, bRunning);
	return 1;
}


int Robot::SetMapID(lua_State* pState)
{
	m_nMapID = (int)luaL_checkinteger(pState, 1);
	m_nAOIID = (int)luaL_checkinteger(pState, 2);
	m_poMapConf = ConfMgr::Instance()->GetMapMgr()->GetConf(m_nMapID);
	return 0;
}

int Robot::PacketID(lua_State* pState)
{
	lua_pushinteger(pState, ++m_uPacketID);
	return 1;
}

int Robot::CalcMoveSpeed(lua_State* pState)
{
	int nMoveSpeed = (int)luaL_checkinteger(pState, 1);
	int nTarPosX = (int)luaL_checkinteger(pState, 2);
	int nTarPosY = (int)luaL_checkinteger(pState, 3);
	Point oTarPos(nTarPosX, nTarPosY);
	int nSpeedX = 0;
	int nSpeedY = 0;
	BattleUtil::CalcMoveSpeed1(nMoveSpeed, m_oPos, oTarPos, nSpeedX, nSpeedY);
	lua_pushinteger(pState, nSpeedX);
	lua_pushinteger(pState, nSpeedY);
	return 2;
}
