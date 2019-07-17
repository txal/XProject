//#include <vld.h>

#include "Server/LogServer/LogServer.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/MGHttp/HttpLua.hpp"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogServer/PacketProc/PacketProc.h"
#include "Server/LogServer/LuaSupport/LuaExport.h"
#include "Server/LogServer/WorkerMgr.h"

ServerContext* gpoContext;

bool InitNetwork(int8_t nServiceID)
{
	LogNode* poLog = NULL;
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oLogList.size(); i++)
	{
		if (oSrvConf.oLogList[i].uServer == oSrvConf.uServerID && oSrvConf.oLogList[i].uID == nServiceID)
		{
			poLog = &oSrvConf.oLogList[i];
			break;
		}
	}
	if (poLog == NULL)
	{
		XLog(LEVEL_ERROR, "LogServer conf:%d not found\n", nServiceID);
		return false;
	}

	gpoContext->GetRouterMgr()->InitRouters();
	return true;
}

//注册到Router成功后调用
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
	bool bRes = poLuaWrapper->DoFile("LogServer/Main");
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
	if (gpoContext != NULL)
	{
		gpoContext->GetService()->Terminate();
	}
}

int main(int nArg, char *pArgv[])
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
	char szWorkDir[256] = { 0 };
	char szScriptPath[512] = { 0 };
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
		sprintf(szLogName, "logserver%d", nServiceID);
		Logger::Instance()->SetLogFile(gpoContext->GetServerConfig().sLogPath, szLogName);
	}


	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	gpoContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	gpoContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	LogServer* poLogServer = XNEW(LogServer);
	poLogServer->Init(nServiceID);
	gpoContext->SetService(poLogServer);

	LuaSerialize* poSerialize = XNEW(LuaSerialize);
	gpoContext->SetLuaSerialize(poSerialize);

	bRes = InitNetwork(nServiceID);
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "init network fail!\n");
		exit(-1);
	}

	goHttpClient.Init();
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oLogList.size(); i++)
	{
		LogNode& oNode = oSrvConf.oLogList[i];
		if (oNode.uServer == oSrvConf.uServerID && oNode.uID == poLogServer->GetServiceID())
		{
			if (oNode.sHttpAddr[0] != '\0')
			{
				goHttpServer.Init(oNode.sHttpAddr);
			}
			WorkerMgr::Instance()->Init(oNode.uWorkers);
			break;
		}
	}

	XLog(LEVEL_INFO, "LogServer start successful\n");
	bRes = gpoContext->GetService()->Start();
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "start server fail!\n");
		exit(-1);
	}

	//wchar_t wcBuffer[256] = { L"" };
	//wsprintfW(wcBuffer, L"log%d.leak", gpoContext->GetService()->GetServiceID());
	//VLDSetReportOptions(VLD_OPT_REPORT_TO_FILE | VLD_OPT_REPORT_TO_DEBUGGER, wcBuffer);

	SAFE_DELETE(gpoContext);
	TimerMgr::Instance()->Release();
	WorkerMgr::Instance()->Release();
	LuaWrapper::Instance()->Release();
	Logger::Instance()->Terminate();
	MysqlDriver::MysqlLibaryEnd();
	return 0;
}