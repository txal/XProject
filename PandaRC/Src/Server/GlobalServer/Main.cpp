﻿#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XTime.h"
#include "Server/GlobalServer/GlobalServer.h"
#include "Server/Base/ServerContext.h"
#include "Server/LogServer/PacketProc/PacketProc.h"
#include "Server/LogServer/LuaSupport/LuaExport.h"

ServerContext* g_poContext;

bool InitNetwork(int8_t nServiceID)
{
	GlobalServer* poGlobalServer = (GlobalServer*)g_poContext->GetService();
	if (!poGlobalServer->Init(nServiceID, "", 0))
	{
		return false;
	}
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
		sprintf(sLogName, "globalserver%d", g_poContext->GetService()->GetServiceID());
		Logger::Instance()->SetLogName(sLogName);
	}

	bool bDebug = false;
#ifdef _DEBUG
	bDebug = true;
#endif
	lua_pushboolean(poLuaWrapper->GetLuaState(), bDebug);
	lua_setglobal(poLuaWrapper->GetLuaState(), "gbDebug");
}

int main(int nArg, char *pArgv[])
{
	assert(nArg >= 2);

#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	Logger::Instance()->Init();
	NetAPI::StartupNetwork();

	int8_t nServiceID = (int8_t)atoi(pArgv[1]);
	g_poContext = XNEW(ServerContext);

	RouterMgr* poRouterMgr = XNEW(RouterMgr);
	g_poContext->SetRouterMgr(poRouterMgr);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	g_poContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	GlobalServer* poGlobalServer = XNEW(GlobalServer);
	g_poContext->SetService(poGlobalServer);

	bool bRes = InitNetwork(nServiceID);
	assert(bRes);

	printf("GlobalServer start successful\n");
	bRes = g_poContext->GetService()->Start();
	assert(bRes);
	return 0;
}