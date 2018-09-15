﻿#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/MGHttp/HttpLua.hpp"
#include "Server/GlobalServer/GlobalServer.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogServer/PacketProc/PacketProc.h"
#include "Server/LogServer/LuaSupport/LuaExport.h"

ServerContext* g_poContext;

bool InitNetwork(int8_t nServiceID)
{
	GlobalNode* poNode = NULL;
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oGlobalList.size(); i++)
	{
		if (oSrvConf.oGlobalList[i].uServer == oSrvConf.uServerID && oSrvConf.oGlobalList[i].uID == nServiceID)
		{
			poNode = &oSrvConf.oGlobalList[i];
			break;
		}
	}
	if (poNode == NULL)
	{
		XLog(LEVEL_ERROR, "GlobalServer conf:%d not found\n", nServiceID);
		return false;
	}

	GlobalServer* poGlobalServer = (GlobalServer*)g_poContext->GetService();
	if (!poGlobalServer->Init(nServiceID, poNode->sIP, poNode->uPort))
	{
		return false;
	}

	g_poContext->GetRouterMgr()->InitRouters();
	return true;
}

//LUA死循环检测
static Thread goMonitorThread;
static void MonitorThreadFunc(void* pParam)
{
	uint32_t uLastMainLoops = 0;
	uint32_t uNowMainLoops = 0;
	for (;;)
	{
		XTime::MSSleep(30000);

		uNowMainLoops = g_poContext->GetService()->GetMainLoopCount();
		if (uNowMainLoops == uLastMainLoops && !LuaWrapper::Instance()->IsBreaking())
		{
			XLog(LEVEL_ERROR, "May endless loop!!!\n");
			LuaWrapper::Instance()->SetEndlessLoop(1);
		}
		uLastMainLoops = uNowMainLoops;
	}
}

void StartScriptEngine()
{
	static bool bStarted = false;
	if (bStarted) return;
	bStarted = true;

	OpenLuaExport();
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	bool bRes = poLuaWrapper->DoFile("GlobalServer/Main");
	assert(bRes);
	bRes = poLuaWrapper->CallLuaFunc(NULL, "Main");
	assert(bRes);

	if (!Platform::FileExist("./debug.txt"))
	{
		char sLogName[256] = "";
		sprintf(sLogName, "globalserver%d", g_poContext->GetService()->GetServiceID());
		Logger::Instance()->SetLogName(sLogName);
	}

	bool bDebug = false;
#ifdef _DEBUG
	bDebug = true;
#endif
	lua_pushboolean(poLuaWrapper->GetLuaState(), bDebug);
	lua_setglobal(poLuaWrapper->GetLuaState(), "gbDebug");

	goMonitorThread.Create(MonitorThreadFunc, NULL);
}

void OnSigTerm(int)
{	
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->CallLuaRef("CppCloseServerReq", 0);
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
	signal(SIGTERM, OnSigTerm);

	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	Logger::Instance()->Init();
	NetAPI::StartupNetwork();

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./adb.txt"));
	char szWorkDir[256] = { 0 };
	char szScriptPath[512] = { 0 };
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
	poLuaWrapper->AddSearchPath(szScriptPath);

	g_poContext = XNEW(ServerContext);
	if (!g_poContext->LoadServerConfig())
	{
		XLog(LEVEL_ERROR, "load server conf fail!\n");
		exit(0);
	}

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	g_poContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	g_poContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	GlobalServer* poGlobalServer = XNEW(GlobalServer);
	g_poContext->SetService(poGlobalServer);

	bool bRes = InitNetwork(nServiceID);
	assert(bRes);

	goHttpClient.Init();
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oGlobalList.size(); i++)
	{
		GlobalNode& oNode = oSrvConf.oGlobalList[i];
		if (oNode.uServer == oSrvConf.uServerID && oNode.uID == poGlobalServer->GetServiceID() && oNode.sHttpAddr[0] != '\0')
		{
			goHttpServer.Init(oNode.sHttpAddr);
			break;
		}
	}

	printf("GlobalServer start successful\n");
	bRes = g_poContext->GetService()->Start();
	assert(bRes);

	g_poContext->GetService()->GetInnerNet()->Release();
	g_poContext->GetService()->GetExterNet()->Release();
	Logger::Instance()->Terminate();
	return 0;
}