#include "Server/Base/ServerContext.h"
#include "Common/DataStruct/HashFunc.h"
#include "Common/DataStruct/XMath.h"

ServerContext::ServerContext()
{
	m_poService = NULL;
	m_poRouterMgr = NULL;
	m_poPacketHandler = NULL;
}

int ServerContext::SelectLogic(int nSession)
{
	uint32_t uCount = (uint32_t)m_oServerConf.oLogicList.size();
	if (uCount <= 0)
	{
		return 0;
	}
	int nIndex = jhash_1word(nSession, 0) % uCount;
	return m_oServerConf.oLogicList[nIndex].uID;
}

bool ServerContext::LoadServerConfig()
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	if (!poLuaWrapper->RawDoFile("ServerConf.lua"))
	{
		XLog(LEVEL_ERROR, "ServerContext::LoadServerConfig fail!\n");
		return false;
	}

	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_getglobal(pState, "gnServerID");
	m_oServerConf.uServerID = (uint16_t)lua_tointeger(pState, -1);

	lua_getglobal(pState, "gnWorldServerID");
	m_oServerConf.uWorldServerID = (uint16_t)lua_tointeger(pState, -1);

	lua_getglobal(pState, "gtServerConf");
	int nTbIdx = lua_gettop(pState);

	//网关
	m_oServerConf.oGateList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tGateService");
	if (!lua_isnil(pState, -1))
	{
		int nLen = (int)lua_rawlen(pState, -1);
		for (int i = 1; i <= nLen; i++)
		{
			GateNode oGate;
			lua_rawgeti(pState, -1, i);
			lua_getfield(pState, -1, "nID");
			oGate.uID = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -2, "nServer");
			oGate.uServer = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -3, "nPort");
			oGate.uPort = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -4, "nMaxConns");
			oGate.uMaxConns = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -5, "nSecureCPM");
			oGate.uSecureCPM = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -6, "nSecureQPM");
			oGate.uSecureQPM = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -7, "nSecureBlock");
			oGate.uSecureBlock = (uint32_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -8, "nDeadLinkTime");
			oGate.uDeadLinkTime = (uint16_t)lua_tointeger(pState, -1);
			m_oServerConf.oGateList.push_back(oGate);
			lua_pop(pState, 9);

		}
	}

	//路由
	m_oServerConf.oRouterList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tRouterService");
	if (!lua_isnil(pState, -1))
	{
		int nLen = (int)lua_rawlen(pState, -1);
		for (int i = 1; i <= nLen; i++)
		{
			RouterNode oRouter;
			lua_rawgeti(pState, -1, i);
			lua_getfield(pState, -1, "nID");
			oRouter.uID = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -2, "sIP");
			const char* psIP = lua_tostring(pState, -1);
			strcpy(oRouter.sIP, psIP);
			lua_getfield(pState, -3, "nPort");
			oRouter.uPort = (uint16_t)lua_tointeger(pState, -1);
			m_oServerConf.oRouterList.push_back(oRouter);
			lua_pop(pState, 4);
		}
	}

	//逻辑
	m_oServerConf.oLogicList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tLogicService");
	if (!lua_isnil(pState, -1))
	{
		int nLen = (int)lua_rawlen(pState, -1);
		for (int i = 1; i <= nLen; i++)
		{
			LogicNode oLogic;
			lua_rawgeti(pState, -1, i);
			lua_getfield(pState, -1, "nID");
			oLogic.uID = (uint16_t)lua_tointeger(pState, -1);
			m_oServerConf.oLogicList.push_back(oLogic);
			lua_pop(pState, 2);
		}
	}

	//全局
	m_oServerConf.oGlobalList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tGlobalService");
	if (!lua_isnil(pState, -1))
	{
		int nLen = (int)lua_rawlen(pState, -1);
		for (int i = 1; i <= nLen; i++)
		{
			GlobalNode oGlobal;
			lua_rawgeti(pState, -1, i);
			lua_getfield(pState, -1, "nID");
			oGlobal.uID = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -2, "nServer");
			oGlobal.uServer = (uint16_t)lua_tointeger(pState, -1);
			oGlobal.sIP[0] = 0;
			lua_getfield(pState, -3, "sIP");
			if (!lua_isnil(pState, -1))
			{
				const char* psIP = lua_tostring(pState, -1);
				strcpy(oGlobal.sIP, psIP);
			}
			lua_getfield(pState, -4, "nPort");
			oGlobal.uPort = (uint16_t)lua_tointeger(pState, -1);
			m_oServerConf.oGlobalList.push_back(oGlobal);
			lua_pop(pState, 5);
		}
	}

	//日志
	m_oServerConf.oLogList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tLogService");
	if (!lua_isnil(pState, -1))
	{
		int nLen = (int)lua_rawlen(pState, -1);
		for (int i = 1; i <= nLen; i++)
		{
			LogNode oLog;
			lua_rawgeti(pState, -1, i);
			lua_getfield(pState, -1, "nID");
			oLog.uID = (uint16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -2, "nServer");
			oLog.uServer = (int16_t)lua_tointeger(pState, -1);
			lua_getfield(pState, -3, "nWorkers");
			oLog.uWorkers = (uint16_t)lua_tointeger(pState, -1);
			m_oServerConf.oLogList.push_back(oLog);
			lua_pop(pState, 4);
		}
	}

	//登录
	m_oServerConf.oLoginList.clear();
	lua_pushvalue(pState, nTbIdx);
	lua_getfield(pState, -1, "tLoginService");
	if (!lua_isnil(pState, -1))
	{
		int nLen = (int)lua_rawlen(pState, -1);
		for (int i = 1; i <= nLen; i++)
		{
			LoginNode oLogin;
			lua_rawgeti(pState, -1, i);
			lua_getfield(pState, -1, "nID");
			oLogin.uID = (uint16_t)lua_tointeger(pState, -1);
			m_oServerConf.oLoginList.push_back(oLogin);
			lua_pop(pState, 2);
		}
	}

	lua_getglobal(pState, "gtWorldConf");
	nTbIdx = lua_gettop(pState);
	if (!lua_isnil(pState, -1))
	{
		//世界全局服
		m_oServerConf.oWGlobalList.clear();
		lua_pushvalue(pState, nTbIdx);
		lua_getfield(pState, -1, "tGlobalService");
		if (!lua_isnil(pState, -1))
		{
			int nLen = (int)lua_rawlen(pState, -1);
			for (int i = 1; i <= nLen; i++)
			{
				GlobalNode oGlobal;
				lua_rawgeti(pState, -1, i);
				lua_getfield(pState, -1, "nID");
				oGlobal.uID = (uint16_t)lua_tointeger(pState, -1);
				lua_getfield(pState, -2, "nServer");
				oGlobal.uServer = (uint16_t)lua_tointeger(pState, -1);
				oGlobal.sIP[0] = 0;
				oGlobal.uPort = 0;
				m_oServerConf.oWGlobalList.push_back(oGlobal);
				lua_pop(pState, 3);
			}
		}
	}
	return true;
}
