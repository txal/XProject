//#include <vld.h>

#include "Server/RouterServer/Router.h"
#include "Include/Network/Network.hpp"
#include "Include/DBDriver/DBDriver.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/MGHttp/HttpLua.hpp"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/ServerContext.h"
#include "Server/RouterServer/LuaSupport/LuaExport.h"
#include "Server/RouterServer/PacketProc/RouterPacketHanderl.h"
#include "Server/RouterServer/PacketProc/RouterPacketProc.h"

ServerContext* gpoContext;
bool InitNetwork(int8_t nServiceID)
{
	RouterNode* poNode = NULL;
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oRouterList.size(); i++)
	{
		if (oSrvConf.oRouterList[i].uID == nServiceID)
		{
			poNode = &oSrvConf.oRouterList[i];
			break;
		}
	}
	if (poNode == NULL)
	{
		XLog(LEVEL_ERROR, "RouterServer conf:%d not found\n", nServiceID);
		return false;
	}

	Router* poRouter = (Router*)(gpoContext->GetService());
	return poRouter->Init(nServiceID, poNode->sIP, poNode->uPort);
}

void StartScriptEngine() 
{
	static bool bStarted = false;
	if (bStarted)
	{
		return;
	}
	bStarted = true;

	OpenLuaExport();
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	bool bRes = poLuaWrapper->DoFile("RouterServer/Main");
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
}

void ExitFunc(void)
{
	XTime::MSSleep(1000);
}

void OnSigTerm(int)
{	
	Router* poRouter = (Router*)(gpoContext->GetService());
	poRouter->GetServerClose().CloseServer(gpoContext->GetWorldServerID());
}

void OnSigInt(int)
{
	if (gpoContext == NULL)
	{
		return;
	}
	gpoContext->GetService()->Terminate();
}

int main(int nArg, char* pArgv[])
{
	assert(nArg >= 2);
	signal(SIGINT, OnSigInt);
	signal(SIGTERM, OnSigTerm);
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
	char szWorkDir[256] = {0};
	char szScriptPath[512] = {0};
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
	poLuaWrapper->AddSearchPath(szScriptPath);

	gpoContext = XNEW(ServerContext);
	bool bRes = gpoContext->LoadServerConfig();
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
		sprintf(szLogName, "routerserver%d", nServiceID);
		Logger::Instance()->SetLogFile(gpoContext->GetServerConfig().sLogPath, szLogName);
	}

	Router* poService = XNEW(Router);
	gpoContext->SetService(poService);

	RouterPacketHandler* poPacketHandler = XNEW(RouterPacketHandler);
	gpoContext->SetPacketHandler(poPacketHandler);
	NSPacketProc::RegisterPacketProc();

	bRes = InitNetwork(nServiceID);
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "init network fail!\n");
		exit(-1);
	}

	XLog(LEVEL_INFO, "RouterServer start successful\n");
	Logger::Instance()->SetSync(false);

	bRes = poService->Start();
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "start server fail!\n");
		exit(-1);
	}

	//wchar_t wcBuffer[256] = { L"" };
	//wsprintfW(wcBuffer, L"router%d.leak", gpoContext->GetService()->GetServiceID());
	//VLDSetReportOptions(VLD_OPT_REPORT_TO_FILE | VLD_OPT_REPORT_TO_DEBUGGER, wcBuffer);

	SAFE_DELETE(gpoContext);
	TimerMgr::Instance()->Release();
	LuaWrapper::Instance()->Release();
	Logger::Instance()->Terminate();
	MysqlDriver::MysqlLibaryEnd();
	return 0;
}

