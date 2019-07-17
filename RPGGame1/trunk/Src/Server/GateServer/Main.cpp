//#include <vld.h>

#include "Server/GateServer/Gateway.h"
#include "Include/Network/Network.hpp"
#include "Include/DBDriver/DBDriver.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/NetAdapter.h"
#include "Server/Base/ServerContext.h"
#include "Server/GateServer/PacketProc/GatewayPacketProc.h"
#include "Server/GateServer/PacketProc/GatewayPacketHandler.h"

ServerContext* gpoContext;
bool InitNetwork(int8_t nServiceID)
{
	NetAPI::StartupNetwork();
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	GateVector& oGateList = oSrvConf.GetGateList(oSrvConf.GetServerID(), nServiceID);
	if (oGateList.size() <= 0)
	{
		XLog(LEVEL_ERROR, "GateServer conf:%d not found\n", nServiceID);
		return false;
	}
	if (!((Gateway*)gpoContext->GetService())->Init(&oGateList[0]))
	{
		return false;
	}
	gpoContext->GetRouterMgr()->InitRouters();
	return true;
}

void StartScriptEngine()
{

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

	if (!Platform::FileExist("./debug.txt"))
	{
		char szLogName[128] = "";
		sprintf(szLogName, "gateserver%d", nServiceID);
		Logger::Instance()->SetLogFile(gpoContext->GetServerConfig().sLogPath, szLogName);
	}

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
    gpoContext->SetRouterMgr(poRouterMgr);

    GatewayPacketHandler* poPacketHandler = XNEW(GatewayPacketHandler);
    gpoContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	Gateway* poGateway = XNEW(Gateway);
	gpoContext->SetService(poGateway);

	bRes = InitNetwork(nServiceID);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "init network fail!\n");
		exit(-1);
	}

	XLog(LEVEL_INFO, "GateServer start successful\n");
	Logger::Instance()->SetSync(false);

	bRes = gpoContext->GetService()->Start();
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "start server fail!\n");
		exit(-1);
	}

	//wchar_t wcBuffer[256] = { L"" };
	//wsprintfW(wcBuffer, L"gate%d.leak", gpoContext->GetService()->GetServiceID());
	//VLDSetReportOptions(VLD_OPT_REPORT_TO_FILE | VLD_OPT_REPORT_TO_DEBUGGER, wcBuffer);

	SAFE_DELETE(gpoContext);
	TimerMgr::Instance()->Release();
	LuaWrapper::Instance()->Release();
	MysqlDriver::MysqlLibaryEnd();
	NetAdapter::Release();

	Logger::Instance()->Terminate();
	return 0;
}
