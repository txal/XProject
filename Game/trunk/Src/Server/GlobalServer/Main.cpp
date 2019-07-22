#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Server/GlobalServer/GlobalServer.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogServer/PacketProc/PacketProc.h"
#include "Server/LogServer/LuaSupport/LuaExport.h"

ServerContext* gpoContext;

bool InitNetwork(int8_t nServiceID)
{
	gpoContext->LoadServerConfig();

	ServerNode* poServer = NULL;
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oGlobalList.size(); i++)
	{
		if (oSrvConf.oGlobalList[i].oGlobal.uService == nServiceID)
		{
			poServer = &oSrvConf.oGlobalList[i];
			break;
		}
	}
	if (poServer == NULL)
	{
		XLog(LEVEL_ERROR, "GlobalServer conf:%d not found\n", nServiceID);
		return false;
	}

	GlobalServer* poGlobalServer = (GlobalServer*)gpoContext->GetService();
	if (!poGlobalServer->Init(nServiceID, poServer->oGlobal.sIP, poServer->oGlobal.uPort))
	{
		return false;
	}

	gpoContext->GetRouterMgr()->InitRouters();
	return true;
}


void StartScriptEngine()
{
	static bool bStarted = false;
	if (bStarted) return;
	bStarted = true;

	OpenLuaExport();
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	bool bRes = poLuaWrapper->DoFile("GlobalServer/Main");
	assert(bRes);
	bRes = poLuaWrapper->CallLuaFunc(NULL, "Main");
	assert(bRes);

	if (!Platform::FileExist("./debug.txt"))
	{
		char sLogName[256] = "";
		sprintf(sLogName, "globalserver%d", gpoContext->GetService()->GetServiceID());
		Logger::Instance()->SetLogFile("./Log/", sLogName);
	}

	bool bDebug = false;
#ifdef _DEBUG
	bDebug = true;
#endif
	lua_pushboolean(poLuaWrapper->GetLuaState(), bDebug);
	lua_setglobal(poLuaWrapper->GetLuaState(), "gbDebug");
	Logger::Instance()->SetSync(false);
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);

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

	GlobalServer* poGlobalServer = XNEW(GlobalServer);
	gpoContext->SetService(poGlobalServer);

	bool bRes = InitNetwork(nServiceID);
	assert(bRes);

	XLog(LEVEL_INFO, "GlobalServer start successful\n");
	bRes = gpoContext->GetService()->Start();
	assert(bRes);
	return 0;
}