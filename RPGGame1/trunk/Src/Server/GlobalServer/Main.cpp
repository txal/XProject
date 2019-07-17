//#include <vld.h>

#include "Include/Network/Network.hpp"
#include "Include/DBDriver/DBDriver.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/MGHttp/HttpLua.hpp"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/GlobalServer/GlobalServer.h"
#include "Server/GlobalServer/PacketProc/PacketProc.h"
#include "Server/GlobalServer/MysqlWorker/MysqlWorkerMgr.h"
#include "Server/GlobalServer/LuaSupport/LuaExport.h"

ServerContext* gpoContext;
bool InitNetwork(int8_t nServiceID)
{
	NetAPI::StartupNetwork();

	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	GlobalVector& oGlobalList = oSrvConf.GetGlobalList(oSrvConf.GetServerID(), nServiceID);
	if (oGlobalList.size() <= 0)
	{
		XLog(LEVEL_ERROR, "GlobalServer conf:%d not found\n", nServiceID);
		return false;
	}

	if (!((GlobalServer*)gpoContext->GetService())->Init(nServiceID, oGlobalList[0].sIP, oGlobalList[0].uPort))
	{
		return false;
	}

	gpoContext->GetRouterMgr()->InitRouters();
	return true;
}

void StartScriptEngine()
{
	XLog(LEVEL_INFO, "Start script engine...\n");
	static bool bStarted = false;
	if (bStarted)
	{
		return;
	}
	bStarted = true;
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();

	bool bDebug = false;
#ifdef _DEBUG
	bDebug = true;
#endif
	lua_pushboolean(poLuaWrapper->GetLuaState(), bDebug);
	lua_setglobal(poLuaWrapper->GetLuaState(), "gbDebug");

	OpenLuaExport();
	bool bRes = poLuaWrapper->DoFile("GlobalServer/Main");
	if (!bRes)
	{
		exit(-1);
	}

	bRes = poLuaWrapper->CallLuaFunc(NULL, "Main");
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

void OnSigInt(int)
{
	if (gpoContext != NULL)
	{
		gpoContext->GetService()->Terminate();
	}
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
	signal(SIGINT, OnSigInt);
	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
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

	gpoContext = XNEW(ServerContext);
	bool bRes = gpoContext->LoadServerConfig();
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "Load server conf fail!\n");
		exit(-1);
	}

	if (!Platform::FileExist("./debug.txt"))
	{
		char szLogName[128] = "";
		sprintf(szLogName, "globalserver%d", nServiceID);
		Logger::Instance()->SetLogFile(gpoContext->GetServerConfig().sLogPath, szLogName);
	}

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	gpoContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	gpoContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	GlobalServer* poGlobalServer = XNEW(GlobalServer);
	gpoContext->SetService(poGlobalServer);

	LuaSerialize* poSerialize = XNEW(LuaSerialize);
	gpoContext->SetLuaSerialize(poSerialize);

	bRes = InitNetwork(nServiceID);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "Init network fail!\n");
		exit(-1);
	}

	goHttpClient.Init();
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	GlobalVector& oGlobalList = oSrvConf.GetGlobalList(oSrvConf.GetServerID(), nServiceID);
	if (oGlobalList.size() > 0)
	{
		if (oGlobalList[0].sHttpAddr[0] != '\0')
		{
			goHttpServer.Init(oGlobalList[0].sHttpAddr);
		 }
		MysqlWorkerMgr::Instance()->Init(oGlobalList[0].uWorkers);
	}

	XLog(LEVEL_INFO, "GlobalServer start successful\n");
	bRes = gpoContext->GetService()->Start();
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "GlobalServer start server fail!\n");
		exit(-1);
	}

	//wchar_t wcBuffer[256] = { L"" };
	//wsprintfW(wcBuffer, L"global%d.leak", gpoContext->GetService()->GetServiceID());
	//VLDSetReportOptions(VLD_OPT_REPORT_TO_FILE | VLD_OPT_REPORT_TO_DEBUGGER, wcBuffer);

	SAFE_DELETE(gpoContext);
	TimerMgr::Instance()->Release();
	LuaWrapper::Instance()->Release();
	MysqlWorkerMgr::Instance()->Release();
	MysqlDriver::MysqlLibaryEnd();
	NetAdapter::Release();
	goHttpClient.Stop();
	goHttpServer.Stop();

	Logger::Instance()->Terminate();
	return 0;
}