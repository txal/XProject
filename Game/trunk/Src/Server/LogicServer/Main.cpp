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

ServerContext* gpoContext;

bool InitNetwork(int8_t nServiceID)
{
	gpoContext->LoadServerConfig();

	ServerNode* poServer = NULL;
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oLogicList.size(); i++)
	{
		if (oSrvConf.oLogicList[i].oLogic.uService == nServiceID)
		{
			poServer = &oSrvConf.oLogicList[i];
			break;
		}
	}
	if (poServer == NULL)
	{
		XLog(LEVEL_ERROR, "LogicServer conf:%d not found\n", nServiceID);
		return false;
	}

	gpoContext->GetRouterMgr()->InitRouters();
	return true;
}

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
		sprintf(sLogName, "logicserver%d", gpoContext->GetService()->GetServiceID());
		Logger::Instance()->SetLogFile("./Log/", sLogName);
	}
	gbPrintBattle = Platform::FileExist("./battle.txt");

	bool bDebug = false;
#ifdef _DEBUG
	bDebug = true;
#endif
	lua_pushboolean(poLuaWrapper->GetLuaState(), bDebug);
	lua_setglobal(poLuaWrapper->GetLuaState(), "gbDebug");
	Logger::Instance()->SetSync(false);
}


int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	XMath::RandomSeed((uint32_t)XTime::MSTime());
	Logger::Instance()->Init();
	Logger::Instance()->SetSync(true);

	NetAPI::StartupNetwork();
	//ConfMgr::Instance()->LoadConf();

	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
	gpoContext = XNEW(ServerContext);

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	gpoContext->SetRouterMgr(poRouterMgr);

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./debug.txt"));
	char szWorkDir[256] = {0};
	char szScriptPath[512] = {0};
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
    poLuaWrapper->AddSearchPath(szScriptPath);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	gpoContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	LogicServer* poService = XNEW(LogicServer);
	bool bRes = poService->Init(nServiceID);
	assert(bRes);
	gpoContext->SetService(poService);

	bRes = InitNetwork(nServiceID);
	assert(bRes);

	XLog(LEVEL_INFO, "LogicServer start successful\n");
	poService->Start();
	return 0;
}
