#ifndef __ROUTERDEF_H__
#define __ROUTERDEF_H__

#include "Common/Platform.h"

#define MAX_ROUTER_NUM  8

struct ROUTER
{
    int nIndex;
    int nSession;
    int8_t nService;
    char szIP[256];
    uint16_t uPort;
	bool bRegisted;

	void Reset()
	{
	    nIndex = 0;
	    nSession = 0;
	    nService = 0;
	    szIP[0] = '\0';
	    uPort = 0;
		bRegisted = false;
	}
};

class RouterMgr
{
public:
    RouterMgr();
	void InitRouters();

	ROUTER* GetRouterByServiceID(int8_t nRouterService);
    ROUTER* OnConnectRouterSuccess(uint16_t uPort, int nSession);
    void OnRegisterRouterSuccess(int8_t nRouterService);
    void OnRouterDisconnected(int nSession);
    ROUTER* ChooseRouter(int8_t nTarService);

protected:
    bool AddRouter(int8_t nRouterService, const char* pszIP, uint16_t uPort);
	ROUTER* GetRouterByServicePort(uint16_t uRouterPort);
    bool IsRegisterFinish();
	void ClearDeadRouter();

	static void UpdateConfig(uint32_t uTimerID, void* pParam);

private:
    int m_nRouterNum;
    int m_nWaitForRegister;
    ROUTER m_RouterList[MAX_ROUTER_NUM];
	uint32_t m_nUpdateTimer;
    DISALLOW_COPY_AND_ASSIGN(RouterMgr);
};

#endif
