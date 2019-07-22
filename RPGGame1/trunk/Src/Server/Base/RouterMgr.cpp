#include "Server/Base/RouterMgr.h"
#include "Include/Logger/Logger.hpp"
#include "Common/DataStruct/HashFunc.h"
#include "Common/TimerMgr/TimerMgr.h"
#include "Server/Base/ServerContext.h"

extern void StartScriptEngine();

RouterMgr::RouterMgr()
{
    m_nRouterNum = 0;
    memset(m_RouterList, 0, sizeof(m_RouterList));
	m_nUpdateTimer = 0;
}

RouterMgr::~RouterMgr()
{
	if (m_nUpdateTimer != 0)
	{
		TimerMgr::Instance()->RemoveTimer(m_nUpdateTimer);
	}
}

void RouterMgr::InitRouters()
{

	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oRouterList.size(); i++)
	{
		const RouterNode& oNode = oSrvConf.oRouterList[i];
		AddRouter((int8_t)oNode.uID, oNode.sIP, oNode.uPort);
	}
	if (m_nUpdateTimer == 0)
	{
		m_nUpdateTimer = TimerMgr::Instance()->RegisterTimer(60*1000, RouterMgr::UpdateConfig, this);
	}
}

void RouterMgr::UpdateConfig(uint32_t uTimerID, void* pParam)
{
	RouterMgr* poRouterMgr = (RouterMgr*)pParam;
	gpoContext->LoadServerConfig();
	poRouterMgr->ClearDeadRouter();
	poRouterMgr->InitRouters();
}


bool RouterMgr::IsRegisterFinish()
{
	ServerConfig& oSrvConf = gpoContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oRouterList.size(); i++)
	{
		int nService = oSrvConf.oRouterList[i].uID;
		ROUTER* poRouter = GetRouterByServiceID(nService);
		if (poRouter == NULL || !poRouter->bRegisted)
		{
			return false;
		}
	}
	return true;
}

bool RouterMgr::AddRouter(int8_t nRouterService, const char* pszIP, uint16_t uPort)
{
    if (m_nRouterNum >= MAX_ROUTER_NUM)
    {
        return false;
    }
	if (GetRouterByServiceID(nRouterService) != NULL)
	{
		return true;
	}
	ROUTER& oRouter = m_RouterList[m_nRouterNum];
	oRouter.Reset();
    oRouter.nService = nRouterService;
    oRouter.nIndex = m_nRouterNum++;
    strcpy(oRouter.szIP, pszIP);
    oRouter.uPort = uPort;
	return gpoContext->GetService()->GetInnerNet()->Connect(pszIP, uPort);
}

ROUTER* RouterMgr::OnConnectRouterSuccess(uint16_t uPort, int nSession)
{
	ROUTER* poRouter = GetRouterByServicePort(uPort);
    if (poRouter != NULL)
    {
        poRouter->nSession = nSession;
    }
    return poRouter;
}

void RouterMgr::OnRegisterRouterSuccess(int8_t nRouterService)
{
	XLog(LEVEL_INFO, "%s: Register to router:%d successful\n", gpoContext->GetService()->GetServiceName(), nRouterService);
	ROUTER* poRouter = GetRouterByServiceID(nRouterService);
    assert(poRouter != NULL && poRouter->nSession > 0);
	poRouter->bRegisted = true;

	if (IsRegisterFinish())
	{
		StartScriptEngine();
	}
}

void RouterMgr::OnRouterDisconnected(int nSession)
{
    for (int i = 0; i < m_nRouterNum; i++)
    {
        if (m_RouterList[i].nSession == nSession)
        {
			m_RouterList[i] = m_RouterList[--m_nRouterNum];
            break;
        }
    }
}

ROUTER* RouterMgr::GetRouterBySessionID(int nRouterSessionID)
{
	ROUTER* poRouter = NULL;
    for (int i = 0; i < m_nRouterNum; i++)
    {
        if (m_RouterList[i].nSession == nRouterSessionID)
        {
			poRouter = &m_RouterList[i];
            break;
        }
    }
	return poRouter;
}

ROUTER* RouterMgr::GetRouterByServiceID(int8_t nRouterService)
{
	ROUTER* poRouter = NULL;
    for (int i = 0; i < m_nRouterNum; i++)
    {
        if (m_RouterList[i].nService == nRouterService)
        {
			poRouter = &m_RouterList[i];
			break;
        }
    }
	return poRouter;
}

ROUTER* RouterMgr::GetRouterByServicePort(uint16_t uRouterPort)
{
	ROUTER* poRouter = NULL;
	for (int i = 0; i < m_nRouterNum; i++)
	{
		if (m_RouterList[i].uPort == uRouterPort)
		{
			poRouter = &m_RouterList[i];
			break;
		}
	}
	return poRouter;
}


ROUTER* RouterMgr::ChooseRouter(int8_t nTarService)
{
    if (m_nRouterNum <= 0)
    {
		XLog(LEVEL_ERROR, "Router count is 0!\n");
        return NULL;
    }
	int nIndex = jhash_1word(nTarService, 0) % m_nRouterNum;
    ROUTER* poRouter = &m_RouterList[nIndex];
    if (poRouter->nSession > 0)
    {
        return poRouter;
    }
    XLog(LEVEL_ERROR, "Router: %d disconnected!\n", poRouter->nService);
    return NULL;
}

void RouterMgr::ClearDeadRouter()
{
	for (int i = 0; i < m_nRouterNum; )
	{
		if (m_RouterList[i].nSession == 0)
		{
			m_RouterList[i] = m_RouterList[--m_nRouterNum];
		}
		else
		{
			i++;
		}
	}
}