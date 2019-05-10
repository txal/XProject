//#include <vld.h>

#include "Include/Network/Network.hpp"
#include "Include/DBDriver/DBDriver.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogServer/PacketProc/PacketProc.h"
#include "Server/LogServer/LuaSupport/LuaExport.h"
#include "Server/WGlobalServer/WGlobalServer.h"

std::string goScriptRoot;
ServerContext* g_poContext;
bool InitNetwork(int8_t nServiceID)
{
	GlobalNode* poNode = NULL;
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oWGlobalList.size(); i++)
	{
		if (oSrvConf.oWGlobalList[i].uServer == oSrvConf.uServerID && oSrvConf.oWGlobalList[i].uID == nServiceID)
		{
			poNode = &oSrvConf.oWGlobalList[i];
			break;
		}
	}
	if (poNode == NULL)
	{
		XLog(LEVEL_ERROR, "WGlobalServer conf:%d not found\n", nServiceID);
		return false;
	}

	WGlobalServer* poGlobalServer = (WGlobalServer*)g_poContext->GetService();
	if (!poGlobalServer->Init(nServiceID, poNode->sIP, poNode->uPort))
	{
		return false;
	}

	g_poContext->GetRouterMgr()->InitRouters();
	return true;
}


void StartScriptEngine()
{
	static bool bStarted = false;
	if (bStarted)
		return;
	bStarted = true;

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	bool bDebug = false;
#ifdef _DEBUG
	bDebug = true;
#endif
	lua_pushboolean(poLuaWrapper->GetLuaState(), bDebug);
	lua_setglobal(poLuaWrapper->GetLuaState(), "gbDebug");

	OpenLuaExport();
	bool bRes = poLuaWrapper->DoFile(goScriptRoot.c_str());
	assert(bRes);
	if (!bRes)
	{
		exit(-1);
	}
	bRes = poLuaWrapper->CallLuaFunc(NULL, "Main");
	assert(bRes);
	if (!bRes)
	{
		exit(-1);
	}
	Logger::Instance()->SetSync(false);
}

void ExitFunc(void)
{
	XTime::MSSleep(1000);
}

void OnSigTerm(int)
{
	XLog(LEVEL_INFO, "receive sigterm signal!\n");
}

void OnSigInt(int)
{
	if (g_poContext != NULL)
	{
		g_poContext->GetService()->Terminate();
	}
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 3);
	signal(SIGINT, OnSigInt);
	signal(SIGTERM, OnSigTerm);
	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
	goScriptRoot = pArgv[2];
	goScriptRoot = goScriptRoot + "/Main";
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	atexit(ExitFunc);
	Logger::Instance()->Init();
	Logger::Instance()->SetSync(true);
	MysqlDriver::MysqlLibaryInit();

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./adb.txt"));
	char szWorkDir[256] = { 0 };
	char szScriptPath[512] = { 0 };
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
	poLuaWrapper->AddSearchPath(szScriptPath);


	g_poContext = XNEW(ServerContext);
	bool bRes = g_poContext->LoadServerConfig();
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "load server conf fail!\n");
		exit(-1);
	}

	NetAPI::StartupNetwork();
	if (!Platform::FileExist("./debug.txt"))
	{
		char szLogName[128] = "";
		sprintf(szLogName, "wglobalserver%d", nServiceID);
		Logger::Instance()->SetLogFile(g_poContext->GetServerConfig().sLogPath, szLogName);
	}

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	g_poContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	g_poContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	WGlobalServer* poGlobalServer = XNEW(WGlobalServer);
	g_poContext->SetService(poGlobalServer);

	LuaSerialize* poSerialize = XNEW(LuaSerialize);
	g_poContext->SetLuaSerialize(poSerialize);

	bRes = InitNetwork(nServiceID);
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "init network fail!\n");
		exit(-1);
	}

	XLog(LEVEL_INFO, "WGlobalServer start successful\n");
	bRes = g_poContext->GetService()->Start();
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "start server fail!\n");
		exit(-1);
	}

	//wchar_t wcBuffer[256] = { L"" };
	//wsprintfW(wcBuffer, L"wglobal%d.leak", g_poContext->GetService()->GetServiceID());
	//VLDSetReportOptions(VLD_OPT_REPORT_TO_FILE | VLD_OPT_REPORT_TO_DEBUGGER, wcBuffer);

	SAFE_DELETE(g_poContext);
	TimerMgr::Instance()->Release();
	LuaWrapper::Instance()->Release();
	Logger::Instance()->Terminate();
	NetAdapter::Release();
	MysqlDriver::MysqlLibaryEnd();
	return 0;
}