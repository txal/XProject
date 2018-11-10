#include "Server/Base/ServerContext.h"
#include "Include/DBDriver/MysqlDriver.h"

#include "Common/DataStruct/HashFunc.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/TimeMonitor.h"

ServerContext::ServerContext()
{
	m_poService = NULL;
	m_poRouterMgr = NULL;
	m_poPacketHandler = NULL;
}

int ServerContext::SelectLogic(int nSession)
{
	for (int i = 0; i < m_oServerConf.oLogicList.size(); i++)
	{
		if (m_oServerConf.oLogicList[i].uServer == m_oServerConf.uServerID)
		{
			return m_oServerConf.oLogicList[i].uID;
		}
	}
	return 0;
}

bool ServerContext::LoadServerConfig()
{
	TimeMonitor oMnt;
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	if (!poLuaWrapper->RawDoFile("ServerConf.lua"))
	{
		XLog(LEVEL_ERROR, "ServerConf.lua not found!\n");
		return false;
	}
	lua_State* pState = poLuaWrapper->GetLuaState();

	m_oServerConf.sDataPath[0] = '\0';
	lua_getglobal(pState, "gsDataPath");
	if (!lua_isnoneornil(pState, -1))
	{
		strcpy(m_oServerConf.sDataPath, lua_tostring(pState, -1));
	}

	m_oServerConf.sLogPath[0] = '\0';
	lua_getglobal(pState, "gsLogPath");
	if (!lua_isnoneornil(pState, -1))
	{
		strcpy(m_oServerConf.sLogPath, lua_tostring(pState, -1));
	}

	lua_getglobal(pState, "gnServerID");
	m_oServerConf.uServerID = (uint16_t)lua_tointeger(pState, -1);

	lua_getglobal(pState, "gnWorldServerID");
	m_oServerConf.uWorldServerID = (uint16_t)lua_tointeger(pState, -1);

	lua_getglobal(pState, "gnGroupID");
	int nGroupID = (int)lua_tointeger(pState, -1);

	lua_getglobal(pState, "gtMgrSQL");
	lua_getfield(pState, -1, "ip");
	const char* pBackIP = lua_tostring(pState, -1);
	lua_getfield(pState, -2, "port");
	int nBackPort = (int)lua_tointeger(pState, -1);
	lua_getfield(pState, -3, "db");
	const char* pBackDB = lua_tostring(pState, -1);
	lua_getfield(pState, -4, "usr");
	const char* pBackUsr = lua_tostring(pState, -1);
	lua_getfield(pState, -5, "pwd");
	const char* pBackPwd = lua_tostring(pState, -1);
	if (pBackIP == NULL || nBackPort <= 0 || pBackDB == NULL || pBackUsr == NULL || pBackPwd == NULL)
	{
		XLog(LEVEL_ERROR, "backstage conf error!\n");
		return false;
	}

	MysqlDriver* pMysql = XNEW(MysqlDriver);
	if (!pMysql->Connect(pBackIP, nBackPort, pBackDB, pBackUsr, pBackPwd, "utf8"))
	{
		SAFE_DELETE(pMysql);
		return false;
	}

	char sSQLBuff[1024] = {0};
	if (nGroupID <= 0 || m_oServerConf.uServerID != m_oServerConf.uWorldServerID)
	{
		if (nGroupID <= 0 && m_oServerConf.uServerID == m_oServerConf.uWorldServerID)
		{
			XLog(LEVEL_ERROR, "load serverconf worldserver groupid not exist: %d!\n", m_oServerConf.uServerID);
			SAFE_DELETE(pMysql);
			return false;
		}
		sprintf(sSQLBuff, "select groupid from serverlist where serverid=%d;", m_oServerConf.uServerID);
		if (!pMysql->Query(sSQLBuff))
		{
			SAFE_DELETE(pMysql);
			return false;
		}
		if (!pMysql->FetchRow())
		{
			XLog(LEVEL_ERROR, "load serverconf server id: %d not exist!\n", m_oServerConf.uServerID);
			SAFE_DELETE(pMysql);
			return false;
		}
		nGroupID = pMysql->ToInt32("groupid");
	}

	sprintf(sSQLBuff, "select * from appinfo where groupid=%d;", nGroupID);
	if (!pMysql->Query(sSQLBuff))
	{
		SAFE_DELETE(pMysql);
		return false;
	}
	if (pMysql->NumRows() <= 0)
	{
		XLog(LEVEL_ERROR, "load serverconf app of groupid: %d not exist!\n", nGroupID);
		SAFE_DELETE(pMysql);
		return false;
	}

	m_oServerConf.oGateList.clear();
	m_oServerConf.oGlobalList.clear();
	m_oServerConf.oLogicList.clear();
	m_oServerConf.oLoginList.clear();
	m_oServerConf.oRouterList.clear();
	m_oServerConf.oWGlobalList.clear();

	while (pMysql->FetchRow())
	{
		int nServerID = pMysql->ToInt32("serverid");
		int nServiceID = pMysql->ToInt32("serviceid");
		int nServicePort = pMysql->ToInt32("serviceport");

		const char* pServiceName = pMysql->ToString("servicename");
		pServiceName = pServiceName ? pServiceName : "";

		if (strcmp("GATE", pServiceName) == 0)
		{
			GateNode oGate;
			oGate.uID = nServiceID;
			oGate.uServer = nServerID;
			oGate.uPort = nServicePort;
			oGate.uMaxConns = 20000;
			oGate.uSecureCPM = 0;
			oGate.uSecureQPM = 300;
			oGate.uDeadLinkTime = 120;
			m_oServerConf.oGateList.push_back(oGate);
		}
		else if (strcmp("ROUTER", pServiceName) == 0)
		{

			const char* pServiceIP = pMysql->ToString("serviceip");
			pServiceIP = pServiceIP ? pServiceIP : "";

			RouterNode oRouter;
			oRouter.uID = nServiceID;
			oRouter.sIP[0] = '\0';
			strcpy(oRouter.sIP, pServiceIP);
			oRouter.uPort = nServicePort;
			m_oServerConf.oRouterList.push_back(oRouter);
		}
		else if (strcmp("LOGIC", pServiceName) == 0 || strcmp("WLOGIC", pServiceName) == 0)
		{
			LogicNode oLogic;
			oLogic.uID = nServiceID;
			oLogic.uServer = nServerID;
			m_oServerConf.oLogicList.push_back(oLogic);
		}
		else if (strcmp("GLOBAL", pServiceName) == 0)
		{
			GlobalNode oGlobal;
			oGlobal.uID = nServiceID;
			oGlobal.uServer = nServerID;
			oGlobal.sIP[0] = '\0';
			oGlobal.uPort = nServicePort;
			oGlobal.sHttpAddr[0] = '\0';
			m_oServerConf.oGlobalList.push_back(oGlobal);
		}
		else if (strcmp("LOG", pServiceName) == 0)
		{
			LogNode oLog;
			oLog.uID = nServiceID;
			oLog.uServer = nServerID;
			oLog.uWorkers = 2;
			oLog.sHttpAddr[0] = '\0';
			m_oServerConf.oLogList.push_back(oLog);
		}
		else if (strcmp("LOGIN", pServiceName) == 0)
		{
			LoginNode oLogin;
			oLogin.uID = nServiceID;
			oLogin.uServer = nServerID;
			m_oServerConf.oLoginList.push_back(oLogin);
		}
		else if (strcmp("WGLOBAL", pServiceName) == 0)
		{
			GlobalNode oGlobal;
			oGlobal.uID = nServiceID;
			oGlobal.uServer = nServerID;
			oGlobal.sIP[0] = '\0';
			oGlobal.uPort = nServicePort;
			m_oServerConf.oWGlobalList.push_back(oGlobal);
		}
	}
	SAFE_DELETE(pMysql);
	double fCostMSTime = oMnt.End();
	if (fCostMSTime >= 30)
	{
		XLog(LEVEL_ERROR, "load server conf is too slow: %fms\n", fCostMSTime);
	}
	return true;
}

bool ServerContext::LoadServerConfigByFile()
{
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	if (!poLuaWrapper->RawDoFile("ServerConf.lua"))
	{
		XLog(LEVEL_ERROR, "ServerContext::LoadServerConfig fail!\n");
		return false;
	}
	lua_State* pState = poLuaWrapper->GetLuaState();
	m_oServerConf.sDataPath[0] = '\0';
	lua_getglobal(pState, "gsDataPath");
	if (!lua_isnoneornil(pState, -1))
	{
		strcpy(m_oServerConf.sDataPath, lua_tostring(pState, -1));
	}

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
			lua_getfield(pState, -2, "nServer");
			oLogic.uServer = (uint16_t)lua_tointeger(pState, -1);
			m_oServerConf.oLogicList.push_back(oLogic);
			lua_pop(pState, 3);
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

			oGlobal.sHttpAddr[0] = 0;
			lua_getfield(pState, -5, "sHttpAddr");
			if (!lua_isnil(pState, -1))
			{
				const char* psAddr = lua_tostring(pState, -1);
				strcpy(oGlobal.sHttpAddr, psAddr);
			}
			m_oServerConf.oGlobalList.push_back(oGlobal);
			lua_pop(pState, 6);
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
			lua_getfield(pState, -4, "sHttpAddr");
			oLog.sHttpAddr[0] = 0;
			if (!lua_isnil(pState, -1))
			{
				const char* psAddr = lua_tostring(pState, -1);
				strcpy(oLog.sHttpAddr, psAddr);
			}
			m_oServerConf.oLogList.push_back(oLog);
			lua_pop(pState, 5);
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
			lua_getfield(pState, -2, "nServer");
			oLogin.uServer = (uint16_t)lua_tointeger(pState, -1);
			m_oServerConf.oLoginList.push_back(oLogin);
			lua_pop(pState, 3);
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
