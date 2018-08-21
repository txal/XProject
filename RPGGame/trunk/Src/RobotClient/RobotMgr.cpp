#include "RobotClient/RobotMgr.h"
#include "Include/Script/Script.hpp"
#include "Common/TimerMgr/TimerMgr.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "RobotClient/Robot.h"
#include "Server/Base/ServerContext.h"

char RobotMgr::className[] = "RobotMgr";
Lunar<RobotMgr>::RegType RobotMgr::methods[] =
{
	LUNAR_DECLARE_METHOD(RobotMgr, GetRobot),
	LUNAR_DECLARE_METHOD(RobotMgr, CreateRobot),
	LUNAR_DECLARE_METHOD(RobotMgr, LogoutRobot),
	{ 0, 0 }
};


RobotMgr::RobotMgr()
{
	m_pExterNet = NULL;
	m_nMaxRobot = 0;
	m_nStartTick = 0;
	m_uClientTick = 0;
	m_nLastUpdateTime = 0;
}

RobotMgr::~RobotMgr()
{

}

bool RobotMgr::Init(int8_t nServiceID, int nMaxRobot)
{
	m_nMaxRobot = nMaxRobot;
	char sServiceName[32];
	sprintf(sServiceName, "RobotMgr:%d", nServiceID);
	m_oNetEventHandler.GetMailBox().SetName(sServiceName);

	if (!Service::Init(nServiceID, sServiceName))
	{
		return false;
	}
	m_pExterNet = INet::CreateNet(NET_TYPE_WEBSOCKET, nServiceID, m_nMaxRobot, &m_oNetEventHandler, 0, 0, 0, 180, true);
	if (m_pExterNet == NULL)
	{
		return false;
	}
	return true;
}

bool RobotMgr::Start()
{
	int64_t nNowMSTime = 0;
	while (!IsTerminate())
	{
        ProcessNetEvent(1);
		nNowMSTime = XTime::MSTime();
        ProcessTimer(nNowMSTime);
        ProcessRobotUpdate(nNowMSTime);
		ProcessConsoleTask(nNowMSTime);
	}
	return true;
}

void RobotMgr::ProcessNetEvent(int64_t nWaitMSTime)
{
	NSNetEvent::EVENT oEvent;
	if (!m_oNetEventHandler.RecvEvent(oEvent, (uint32_t)nWaitMSTime))
	{
		return;
	}
	switch (oEvent.uEventType)
	{
		case NSNetEvent::eEVT_ON_RECV:
		{
			OnExterNetMsg(oEvent.U.oRecv.nSessionID, oEvent.U.oRecv.poPacket);
			break;
		}
		case NSNetEvent::eEVT_ON_CLOSE:
		{
			OnExterNetClose(oEvent.U.oClose.nSessionID);
			break;
		}
		case NSNetEvent::eEVT_ON_CONNECT:
		{
			OnExterNetConnect(oEvent.U.oConnect.nSessionID);
			break;
		}
		case NSNetEvent::eEVT_HANDSHAKE:
		{
			Robot* poRobot = GetRobot(oEvent.U.oHandShake.nSessionID);
			if (poRobot != NULL)
			{
				poRobot->OnConnect(oEvent.U.oHandShake.nSessionID);
			}
			break;
		}
		default:
		break;
	}
}

void RobotMgr::ProcessTimer(int64_t nNowMS)
{
	static int64_t nLastMSTime = 0;
	if (nNowMS - nLastMSTime < 10)
	{
		return;
	}
	nLastMSTime = nNowMS;

	if (m_nStartTick == 0)
		m_nStartTick = nNowMS;

	int nTickElapsed = (int)(nNowMS - m_nStartTick) - m_uClientTick;
	assert(nTickElapsed >= 0);
	m_uClientTick += nTickElapsed;

	TimerMgr::Instance()->ExecuteTimer(nNowMS);
}

void RobotMgr::ProcessRobotUpdate(int64_t nNowMS)
{
	if (nNowMS - m_nLastUpdateTime < 10)
	{
		return;
	}
	m_nLastUpdateTime = nNowMS;

	RobotIter iter = m_oRobotMap.begin();
	RobotIter iter_end = m_oRobotMap.end();
	for (; iter != iter_end; iter++)
	{
		iter->second->Update(nNowMS);
	}
}

void RobotMgr::ProcessConsoleTask(int64_t nNowMS)
{
	static int64_t nLastMSTime = 0;
	if (nNowMS - nLastMSTime < 60)
	{
		return;
	}
	nLastMSTime = nNowMS;

	while (!m_oTaskList.empty())
	{
		lua_State* pState = LuaWrapper::Instance()->GetLuaState();
		std::string& osTask = m_oTaskList.front();
		LuaWrapper::Instance()->FastCallLuaRef<void>("TaskDispatcher", 0, "s", osTask.c_str());
		m_oTaskList.pop_front();
	}
}

void RobotMgr::CreateRobot(int nRobotNum, const char* pszIP, uint16_t uPort)
{
	nRobotNum = XMath::Min(nRobotNum, m_nMaxRobot);
	for (int i = 0; i < nRobotNum; i++)
	{
		m_pExterNet->Connect(pszIP, uPort);
	}
}

Robot* RobotMgr::GetRobot(int nSession)
{
	RobotIter iter = m_oRobotMap.find(nSession);
	if (iter != m_oRobotMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void RobotMgr::OnExterNetConnect(int nSessionID)
{
	Robot* poRobot = XNEW(Robot)(this);
	m_oRobotMap.insert(std::make_pair(nSessionID, poRobot));
	m_pExterNet->ClientHandShakeReq(nSessionID);
}

void RobotMgr::OnExterNetClose(int nSessionID)
{
	RobotIter iter = m_oRobotMap.find(nSessionID);
	if (iter != m_oRobotMap.end())
	{
        iter->second->OnDisconnect();
		SAFE_DELETE(iter->second);
		m_oRobotMap.erase(iter);
	}
}

void RobotMgr::OnExterNetMsg(int nSessionID, Packet* poPacket)
{
	RobotIter iter = m_oRobotMap.find(nSessionID);
	if (iter == m_oRobotMap.end())
	{
		return;
	}
	EXTER_HEADER oHeader;
	if (!poPacket->GetExterHeader(oHeader, true))
	{
		XLog(LEVEL_ERROR, "Get header fail\n");
		poPacket->Release();
		return;
	}
	g_poContext->GetPacketHandler()->OnRecvExterPacket(nSessionID, poPacket, oHeader);
}

void RobotMgr::PushTask(std::string& osTask)
{
	m_oTaskList.push_back(osTask);
}


///////////////////////////lua export//////////////////////////
void RegClassRobot()
{
	REG_CLASS(Robot, false, NULL);
	REG_CLASS(RobotMgr, false, NULL);
}

int RobotMgr::GetRobot(lua_State* pState)
{
	int nSession = (int)luaL_checkinteger(pState, 1);
	Robot* poRobot = GetRobot(nSession);
	Lunar<Robot>::push(pState, poRobot);
	return 1;
}

int RobotMgr::CreateRobot(lua_State* pState)
{
	const char* psIP = luaL_checkstring(pState, 1);
	uint16_t uPort = (uint16_t)luaL_checkinteger(pState, 2);
	int nRobotNum = (int)luaL_checkinteger(pState, 3);
	CreateRobot(nRobotNum, psIP, uPort);
	return 0;
}

int RobotMgr::LogoutRobot(lua_State* pState)
{
	RobotIter iter = m_oRobotMap.begin();
	for (; iter != m_oRobotMap.end(); iter++)
	{
		m_pExterNet->Close(iter->first);
	}
	return 0;
}
