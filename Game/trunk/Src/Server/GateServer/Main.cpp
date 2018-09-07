#include "Server/GateServer/Gateway.h"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Server/Base/ServerContext.h"
#include "Server/GateServer/PacketProc/GatewayPacketProc.h"
#include "Server/GateServer/PacketProc/GatewayPacketHandler.h"

ServerContext* g_poContext;

bool InitNetwork(int8_t nServiceID)
{
	g_poContext->LoadServerConfig();

	ServerNode* poServer = NULL;
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oGateList.size(); i++)
	{
		if (oSrvConf.oGateList[i].oGate.uService == nServiceID)
		{
			poServer = &oSrvConf.oGateList[i];
			break;
		}
	}
	if (poServer == NULL)
	{
		XLog(LEVEL_ERROR, "GateServer conf:%d not found\n", nServiceID);
		return false;
	}
	Gateway* poGateway = (Gateway*)g_poContext->GetService();
	if (!poGateway->Init(poServer))
	{
		return false;
	}

	g_poContext->GetRouterMgr()->InitRouters();
	return true;
}

void StartScriptEngine()
{

}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);
	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif

	Logger::Instance()->Init();
	NetAPI::StartupNetwork();
	g_poContext = XNEW(ServerContext);

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./debug.txt"));
	char szWorkDir[256] = {0};
	char szScriptPath[512] = {0};
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
	poLuaWrapper->AddSearchPath(szScriptPath);

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
    g_poContext->SetRouterMgr(poRouterMgr);

    GatewayPacketHandler* poPacketHandler = XNEW(GatewayPacketHandler);
    g_poContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	Gateway* poGateway = XNEW(Gateway);
	g_poContext->SetService(poGateway);

	bool bRes = InitNetwork(nServiceID);
	assert(bRes);

	if (!Platform::FileExist("./debug.txt"))
	{
		char sLogName[256] = "";
		sprintf(sLogName, "gateserver%d", nServiceID);
		Logger::Instance()->SetLogName(sLogName);
	}

	printf("GateServer start successful\n");
	bRes = g_poContext->GetService()->Start();
	assert(bRes);

	return 0;
}
