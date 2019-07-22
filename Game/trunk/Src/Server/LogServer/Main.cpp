#include "Server/LogServer/LogServer.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogServer/PacketProc/PacketProc.h"
#include "Server/LogServer/LuaSupport/LuaExport.h"
#include "Server/LogServer/WorkerMgr.h"

ServerContext* gpoContext;

bool InitNetwork(int8_t nServiceID)
{
	gpoContext->LoadServerConfig();

	ServerNode* poServer = NULL;
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oLogList.size(); i++)
	{
		if (oSrvConf.oLogList[i].oLog.uService == nServiceID)
		{
			poServer = &oSrvConf.oLogList[i];
			break;
		}
	}
	if (poServer == NULL)
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
	if (bStarted) return;
	bStarted = true;

	OpenLuaExport();
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	bool bRes = poLuaWrapper->DoFile("LogServer/Main");
	assert(bRes);
	bRes = poLuaWrapper->CallLuaFunc(NULL, "Main");
	assert(bRes);

	if (!Platform::FileExist("./debug.txt"))
	{
		char sLogName[256] = "";
		sprintf(sLogName, "logserver%d", gpoContext->GetService()->GetServiceID());
		Logger::Instance()->SetLogFile("./Log/", sLogName);
	}
	Logger::Instance()->SetSync(false);
}

//关服定时器
void OnSigTerm(int);
void OnShutdownTimer(uint32_t uTimerID, void*)
{
	TimerMgr::Instance()->RemoveTimer(uTimerID);
	OnSigTerm(SIGTERM);
}

//关服事件
void OnSigTerm(int)
{
	XLog(LEVEL_INFO, "OnSigTerm------\n");
	LogServer* poLogServer = (LogServer*)gpoContext->GetService();
	if (poLogServer->GetMsgCount() <= 0)
	{
		Logger::Instance()->Terminate();
		exit(0);
	}
	TimerMgr::Instance()->RegisterTimer(1000, OnShutdownTimer, NULL);
}

void OnExit(void)
{
	printf("Exit function called\n");
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
	signal(SIGTERM, OnSigTerm);
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	Logger::Instance()->Init();
	Logger::Instance()->SetSync(true);
	NetAPI::StartupNetwork();
	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
	gpoContext = XNEW(ServerContext);

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./debug.txt"));
	char szWorkDir[256] = { 0 };
	char szScriptPath[512] = { 0 };
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
	poLuaWrapper->AddSearchPath(szScriptPath);

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	gpoContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	gpoContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	LogServer* poLogServer = XNEW(LogServer);
	poLogServer->Init(nServiceID);
	gpoContext->SetService(poLogServer);

	bool bRes = InitNetwork(nServiceID);
	assert(bRes);

	//工作线程
	WorkerMgr::Instance()->Init(gpoContext->GetServerConfig().oLogList[0].oLog.uWorkers);
	XLog(LEVEL_INFO, "LogServer start successful\n");

	atexit(OnExit);
	bRes = gpoContext->GetService()->Start();
	assert(bRes);
	return 0;
}