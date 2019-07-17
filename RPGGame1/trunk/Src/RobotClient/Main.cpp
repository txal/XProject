#include "RobotClient/RobotMgr.h"
#include "Include/Network/Network.hpp"
#include "Include/Script/Script.hpp"
#include "RobotClient/LuaSupport/LuaExport.h"
#include "RobotClient/PacketProc/RobotPacketProc.h"
#include "Server/Base/ServerContext.h"
#include "Common/DataStruct/TimeMonitor.h"

ServerContext* gpoContext;

void TrimCmd(std::string& sCmd)
{

	int nPosStart = 0;
	int nPosEnd = (int)sCmd.length() - 1;
	for (int i = 0; i <= nPosEnd; ++i)
	{
		if (sCmd[i] != ' ')
		{
			break;
		}
		nPosStart++;
	}
	for (int i = nPosEnd; i >= 0; --i)
	{
		if (sCmd[i] != ' ')
		{
			break;
		}
		nPosEnd--;
	}
	if (nPosEnd - nPosStart < 0)
	{
		sCmd.clear();
		return;
	}
	sCmd = sCmd.substr(nPosStart, nPosEnd - nPosStart + 1);
}
bool SplitCmd(std::string& sCmd, std::list<std::string>& oParamList)
{
	TrimCmd(sCmd);
	if (sCmd == "")
	{
		return false;
	}
	int nLastPos = -1;
	int nTarPos = (int)std::string::npos;
	while (true)
	{
		while(++nLastPos < (int)sCmd.length() && sCmd[nLastPos] == ' ');
		nTarPos = (int)sCmd.find_first_of(' ', nLastPos);
		std::string sParam = sCmd.substr(nLastPos, nTarPos - nLastPos);
		if (sParam != "")
		{
			oParamList.push_back(sParam);
		}
		if (nTarPos == (int)std::string::npos)
		{
			break;
		}
		nLastPos = nTarPos;
	}
	return true;
}

bool gbStopCmd = false;
void CmdProc(void* pParam)
{
	RobotMgr* poRobotMgr = (RobotMgr*)pParam;
	char sCmdBuf[1024];
	while (!gbStopCmd)
	{
		std::cout << "CMD:";
		std::cin.getline(sCmdBuf, sizeof(sCmdBuf));
		std::string osTask(sCmdBuf);
		if (osTask == "")
		{
			continue;
		}
		poRobotMgr->PushTask(osTask);
	}
}

void StartScriptEngine()
{

}

//发送信号
void SendSignal()
{

}


int main(int nArg, char *pArgv[])
{
#ifdef _WIN32
	::SetUnhandledExceptionFilter(Platform::MyUnhandledFilter);
#endif
	Logger::Instance()->Init();
	NetAPI::StartupNetwork();

	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	poLuaWrapper->Init(Platform::FileExist("./adb.txt"));
	char szWorkDir[256] = {0};
	char szScriptPath[512] = {0};
	Platform::GetWorkDir(szWorkDir, sizeof(szWorkDir)-1);
	sprintf(szScriptPath, ";%s/Script/?.lua;%s/../Script/?.lua;", szWorkDir, szWorkDir);
	poLuaWrapper->AddSearchPath(szScriptPath);

	gpoContext = XNEW(ServerContext);
	
	RobotMgr* poRobotMgr = XNEW(RobotMgr);
	gpoContext->SetService(poRobotMgr);
	poRobotMgr->Init(0, 30000);

	PacketHandler* poPacketHandler = XNEW(PacketHandler);
	gpoContext->SetPacketHandler(poPacketHandler);

	NSPacketProc::RegisterPacketProc();

	OpenLuaExport();
	poLuaWrapper->DoFile("RobotClt/Main");

	LuaSerialize* poSerialize = XNEW(LuaSerialize);
	gpoContext->SetLuaSerialize(poSerialize);

	lua_State* pState = poLuaWrapper->GetLuaState();
	lua_getglobal(pState, "gsDataPath");
	const char* pDataPath = lua_tostring(pState, -1);
	ConfMgr::Instance()->LoadConf(pDataPath?pDataPath:"");

	poLuaWrapper->CallLuaFunc(NULL, "Main");

	XThread oCmdThread;
	oCmdThread.Create(CmdProc, poRobotMgr);
	poRobotMgr->Start();
	INet* pExterNet = gpoContext->GetService()->GetExterNet();
	pExterNet->Release();

	return 0;
}
