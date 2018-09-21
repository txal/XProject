#include "Server/LogServer/LogServer.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/MGHttp/HttpLua.hpp"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogServer/PacketProc/PacketProc.h"
#include "Server/LogServer/LuaSupport/LuaExport.h"
#include "Server/LogServer/WorkerMgr.h"

ServerContext* g_poContext;

bool InitNetwork(int8_t nServiceID)
{
	LogNode* poLog = NULL;
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
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

	g_poContext->GetRouterMgr()->InitRouters();
	return true;
}

//注册到Router成功后调用
void StartScriptEngine()
{
	static bool bStarted = false;
	if (bStarted)
		return;
	bStarted = true;

	OpenLuaExport();
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
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
}

void OnSigTerm(int)
{
	XLog(LEVEL_INFO, "OnSigTerm------\n");
}

void ExitFunc(void)
{
	XTime::MSSleep(1000);
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
	//signal(SIGTERM, OnSigTerm);
	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	atexit(ExitFunc);
	Logger::Instance()->Init();
	NetAPI::StartupNetwork();

	if (!Platform::FileExist("./debug.txt"))
	{
		char sLogName[256] = "";
		sprintf(sLogName, "logserver%d", nServiceID);
		Logger::Instance()->SetLogName(sLogName);
	}

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

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	g_poContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	g_poContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	LogServer* poLogServer = XNEW(LogServer);
	poLogServer->Init(nServiceID);
	g_poContext->SetService(poLogServer);

	bRes = InitNetwork(nServiceID);
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "init network fail!\n");
		exit(-1);
	}

	goHttpClient.Init();
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oLogList.size(); i++)
	{
		LogNode& oNode = oSrvConf.oLogList[i];
		if (oNode.uServer == oSrvConf.uServerID && oNode.uID == poLogServer->GetServiceID())
		{
			if (oNode.sHttpAddr[0] != '\0')
				goHttpServer.Init(oNode.sHttpAddr);
			WorkerMgr::Instance()->Init(oNode.uWorkers);
			break;
		}
	}

	XLog(LEVEL_INFO, "LogServer start successful\n");
	bRes = g_poContext->GetService()->Start();
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "start server fail!\n");
		exit(-1);
	}

	g_poContext->GetService()->GetInnerNet()->Release();
	Logger::Instance()->Terminate();
	return 0;
}