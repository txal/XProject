#include "Server/LoginServer/LoginServer.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/ServerContext.h"
#include "Server/LoginServer/PacketProc/PacketProc.h"
#include "Server/LoginServer/LuaSupport/LuaExport.h"

ServerContext* g_poContext;
bool InitNetwork(int8_t nServiceID)
{
	g_poContext->LoadServerConfig();

	LogNode* poLog = NULL;
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oLogList.size(); i++)
	{
		if (oSrvConf.oLogList[i].uID == nServiceID)
		{
			poLog = &oSrvConf.oLogList[i];
			break;
		}
	}
	if (poLog == NULL)
	{
		XLog(LEVEL_ERROR, "LoginServer conf:%d not found\n", nServiceID);
		return false;
	}

	g_poContext->GetRouterMgr()->InitRouters();
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
	bool bRes = poLuaWrapper->DoFile("LoginServer/Main");
	assert(bRes);
	bRes = poLuaWrapper->CallLuaFunc(NULL, "Main");
	assert(bRes);

	if (!Platform::FileExist("./debug.txt"))
	{
		char sLogName[256] = "";
		sprintf(sLogName, "logserver%d", g_poContext->GetService()->GetServiceID());
		Logger::Instance()->SetLogName(sLogName);
	}
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
	LoginServer* poLoginServer = (LoginServer*)g_poContext->GetService();
	if (poLoginServer->GetMsgCount() <= 0)
	{
		Logger::Instance()->SetAndWaitClose();
		exit(0);
	}
	TimerMgr::Instance()->RegisterTimer(1000, OnShutdownTimer, NULL);
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
	signal(SIGTERM, OnSigTerm);
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	Logger::Instance()->Init();
	NetAPI::StartupNetwork();
	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
	g_poContext = XNEW(ServerContext);

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./debug.txt"));
	char szWorkDir[256] = { 0 };
	char szScriptPath[512] = { 0 };
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
	poLuaWrapper->AddSearchPath(szScriptPath);

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	g_poContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	g_poContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	LoginServer* poLoginServer = XNEW(LoginServer);
	poLoginServer->Init(nServiceID);
	g_poContext->SetService(poLoginServer);

	bool bRes = InitNetwork(nServiceID);
	assert(bRes);

	printf("LoginServer start successful\n");
	bRes = g_poContext->GetService()->Start();
	assert(bRes);
	return 0;
}