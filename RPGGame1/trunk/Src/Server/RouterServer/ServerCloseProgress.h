#ifndef __SERVERCLOSE_PROGRESS_H__
#define __SERVERCLOSE_PROGRESS_H__

#include "Include/Network/Network.hpp"
#include "Server/Base/Service.h"
#include "ServiceNode.h"

class ServerCloseProgress
{
public:
	ServerCloseProgress();
	~ServerCloseProgress();

public:
	bool IsClosingServer() { return m_oServerList.size() > 0; }
	void CloseServer(int nServerID);
	void OnServiceClose(int nServerID, int nServiceID, int nServiceType);

private:
	void StartRoutine();
	void CloseGate();
	void CloseLogin();
	void CloseLogic();
	void CloseGlobal();
	void CloseLog();

private:
	void BroadcastPrepServerClose(ServiceNode** tServiceList, int nNum, int nTarServer=0, int nTarService=0);
	void OnCloseServerFinish(int nServerID);

private:
	std::list<int> m_oServerList;
	DISALLOW_COPY_AND_ASSIGN(ServerCloseProgress);
};

#endif
