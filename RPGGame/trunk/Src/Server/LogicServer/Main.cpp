#ifdef _WIN32
#define _CRTDBG_MAP_ALLOC
#include <stdlib.h>
#include <crtdbg.h>
#endif

#include "Server/LogicServer/LogicServer.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/TimeMonitor.h"
#include "LuaSupport/LuaExport.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/PacketProc/LogicPacketProc.h"

ServerContext* g_poContext;

//网络初始化
bool InitNetwork(int8_t nServiceID)
{
	g_poContext->LoadServerConfig();

	LogicNode* poNode = NULL;
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oLogicList.size(); i++)
	{
		if (oSrvConf.oLogicList[i].uID == nServiceID)
		{
			poNode = &oSrvConf.oLogicList[i];
			break;
		}
	}
	if (poNode == NULL)
	{
		XLog(LEVEL_ERROR, "LogicServer conf:%d not found\n", nServiceID);
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
		XTime::MSSleep(10000);

		uNowMainLoops = g_poContext->GetService()->GetMainLoopCount();
		if (uNowMainLoops == uLastMainLoops && !LuaWrapper::Instance()->IsBreaking())
		{
			XLog(LEVEL_ERROR, "May endless loop!!!\n");
			LuaWrapper::Instance()->SetEndlessLoop(1);
		}
		uLastMainLoops = uNowMainLoops;
	}
}

//启动脚本虚拟机
void StartScriptEngine()
{
	XLog(LEVEL_INFO, "Start script engine...\n");
	static bool bStarted = false;
	if (bStarted) return;
	bStarted = true;

	OpenLuaExport();
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	bool bRes = poLuaWrapper->DoFile("LogicServer/Main");
	assert(bRes);
	bRes = poLuaWrapper->CallLuaFunc(NULL, "Main");
	assert(bRes);

	if (!Platform::FileExist("./debug.txt"))
	{
		char sLogName[256] = "";
		sprintf(sLogName, "logicserver%d", g_poContext->GetService()->GetServiceID());
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


int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	XMath::RandomSeed((uint32_t)XTime::MSTime());
	Logger::Instance()->Init();
	NetAPI::StartupNetwork();
	ConfMgr::Instance()->LoadConf();

	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
	g_poContext = XNEW(ServerContext);

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	g_poContext->SetRouterMgr(poRouterMgr);

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./debug.txt"));
	char szWorkDir[256] = {0};
	char szScriptPath[512] = {0};
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
    poLuaWrapper->AddSearchPath(szScriptPath);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	g_poContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	LogicServer* poService = XNEW(LogicServer);
	bool bRes = poService->Init(nServiceID);
	assert(bRes);
	g_poContext->SetService(poService);

	bRes = InitNetwork(nServiceID);
	assert(bRes);

	printf("LogicServer start successful\n");
	bRes = poService->Start();
	assert(bRes);

	g_poContext->GetService()->GetInnerNet()->Release();
	Logger::Instance()->Terminate();

#ifdef _WIN32
	//_CrtDumpMemoryLeaks();
#endif // _WIN32
	return 0;
}