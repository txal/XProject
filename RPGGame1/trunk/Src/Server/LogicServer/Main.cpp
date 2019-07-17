//#include <vld.h>

#include "Server/LogicServer/LogicServer.h"
#include "Include/Network/Network.hpp"
#include "Include/DBDriver/DBDriver.hpp"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/TimeMonitor.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "LuaSupport/LuaExport.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"
#include "Server/LogicServer/Component/Battle/BattleUtil.h"
#include "Server/LogicServer/PacketProc/LogicPacketProc.h"

ServerContext* gpoContext;
//网络初始化
bool InitNetwork(int8_t nServiceID)
{
	NetAPI::StartupNetwork();

	LogicNode* poNode = NULL;
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	LogicVector& oLogicList = oSrvConf.GetLogicList(oSrvConf.GetServerID(), nServiceID);
	if (oLogicList.size() <= 0)
	{
		XLog(LEVEL_ERROR, "LogicServer conf:%d not found\n", nServiceID);
		return false;
	}

	gpoContext->GetRouterMgr()->InitRouters();
	return true;
}

//启动脚本虚拟机
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
	bool bRes = poLuaWrapper->DoFile("LogicServer/Main");
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
	XMath::RandomSeed((uint32_t)XTime::MSTime());
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
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "load server conf fail!\n");
		exit(-1);
	}
	ConfMgr::Instance()->LoadConf(gpoContext->GetServerConfig().sDataPath);

	if (!Platform::FileExist("./debug.txt"))
	{
		char szLogName[128] = "";
		sprintf(szLogName, "logicserver%d", nServiceID);
		Logger::Instance()->SetLogFile(gpoContext->GetServerConfig().sLogPath, szLogName);
	}

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	gpoContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	gpoContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	LogicServer* poService = XNEW(LogicServer);
	bRes = poService->Init(nServiceID);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "init service fail!\n");
		exit(-1);
	}
	gpoContext->SetService(poService);

	LuaSerialize* poSerialize = XNEW(LuaSerialize);
	gpoContext->SetLuaSerialize(poSerialize);

	bRes = InitNetwork(nServiceID);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "Init network fail!\n");
		exit(-1);
	}

	XLog(LEVEL_INFO, "LogicServer start successful\n");
	bRes = poService->Start();
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "Start server fail!\n");
		exit(-1);
	}

	//wchar_t wcBuffer[256] = {L""};
	//wsprintfW(wcBuffer, L"logic%d.leak", gpoContext->GetService()->GetServiceID());
	//VLDSetReportOptions(VLD_OPT_REPORT_TO_FILE|VLD_OPT_REPORT_TO_DEBUGGER, wcBuffer);

	SAFE_DELETE(gpoContext);
	TimerMgr::Instance()->Release();
	LuaWrapper::Instance()->Release();
	ConfMgr::Instance()->Release();
	NetAdapter::Release();
	MysqlDriver::MysqlLibaryEnd();

	Logger::Instance()->Terminate();
	return 0;
}