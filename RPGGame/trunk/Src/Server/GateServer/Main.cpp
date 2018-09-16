#include "Server/GateServer/Gateway.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/ServerContext.h"
#include "Server/GateServer/PacketProc/GatewayPacketProc.h"
#include "Server/GateServer/PacketProc/GatewayPacketHandler.h"

ServerContext* g_poContext;

bool InitNetwork(int8_t nServiceID)
{
	GateNode* poNode = NULL;
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oGateList.size(); i++)
	{
		if (oSrvConf.oGateList[i].uServer == oSrvConf.uServerID && oSrvConf.oGateList[i].uID == nServiceID)
		{
			poNode = &oSrvConf.oGateList[i];
			break;
		}
	}
	if (poNode == NULL)
	{
		XLog(LEVEL_ERROR, "GateServer conf:%d not found\n", nServiceID);
		return false;
	}
	Gateway* poGateway = (Gateway*)g_poContext->GetService();
	if (!poGateway->Init(poNode))
	{
		return false;
	}

	g_poContext->GetRouterMgr()->InitRouters();
	return true;
}

void StartScriptEngine()
{

}

void ExitFunc(void)
{
	XTime::MSSleep(1000);
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
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
		sprintf(sLogName, "gateserver%d", nServiceID);
		Logger::Instance()->SetLogName(sLogName);
	}

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./adb.txt"));
	char szWorkDir[256] = {0};
	char szScriptPath[512] = {0};
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

    GatewayPacketHandler* poPacketHandler = XNEW(GatewayPacketHandler);
    g_poContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	Gateway* poGateway = XNEW(Gateway);
	g_poContext->SetService(poGateway);

	bRes = InitNetwork(nServiceID);
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "init network fail!\n");
		exit(-1);
	}

	XLog(LEVEL_INFO, "GateServer start successful\n");
	bRes = g_poContext->GetService()->Start();
	assert(bRes);
	if (!bRes)
	{
		XLog(LEVEL_ERROR, "start server fail!\n");
		exit(-1);
	}

	g_poContext->GetService()->GetExterNet()->Release();
	g_poContext->GetService()->GetInnerNet()->Release();
	Logger::Instance()->Terminate();
	return 0;
}
