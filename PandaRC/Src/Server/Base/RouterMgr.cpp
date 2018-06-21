#include "Server/Base/RouterMgr.h"
#include "Include/Logger/Logger.hpp"
#include "Server/Base/ServerContext.h"
#include "Common/TimerMgr/TimerMgr.h"

extern void StartScriptEngine();

RouterMgr::RouterMgr()
{
    m_nRouterNum = 0;
    memset(m_RouterList, 0, sizeof(m_RouterList));
	m_nUpdateTimer = 0;
}

void RouterMgr::InitRouters()
{

	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oRouterList.size(); i++)
	{
		const ServerNode& oNode = oSrvConf.oRouterList[i];
		AddRouter((int8_t)oNode.oRouter.uService, oNode.oRouter.sIP, oNode.oRouter.uPort);
	}
	if (m_nUpdateTimer == 0)
	{
		m_nUpdateTimer = TimerMgr::Instance()->RegisterTimer(60 * 1000, RouterMgr::UpdateConfig, this);
	}
}

void RouterMgr::UpdateConfig(uint32_t uTimerID, void* pParam)
{
	//XLog(LEVEL_INFO, "RouterMgr::UpdateConfig***\n");
	RouterMgr* poRouterMgr = (RouterMgr*)pParam;
	g_poContext->LoadServerConfig();
	poRouterMgr->ClearDeadRouter();
	poRouterMgr->InitRouters();
}


bool RouterMgr::IsRegisterFinish()
{
	ServerConfig& oSrvConf = g_poContext->GetServerConfig();
	for (int i = 0; i < oSrvConf.oRouterList.size(); i++)
	{
		int nService = oSrvConf.oRouterList[i].oRouter.uService;
		ROUTER* poRouter = GetRouter(nService);
		if (poRouter == NULL || poRouter->nSession == 0)
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
	if (GetRouter(nRouterService) != NULL)
	{
		return true;
	}
	ROUTER& oRouter = m_RouterList[m_nRouterNum];
	oRouter.Reset();
    oRouter.nService = nRouterService;
    oRouter.nIndex = m_nRouterNum++;
    strcpy(oRouter.szIP, pszIP);
    oRouter.uPort = uPort;
	return g_poContext->GetService()->GetInnerNet()->Connect(pszIP, uPort);
}

ROUTER* RouterMgr::OnConnectRouterSuccess(uint16_t uPort, int nSession)
{
    ROUTER* poRouter = NULL;
    for (int i = 0; i < m_nRouterNum; i++)
    {
        if (m_RouterList[i].uPort == uPort)
        {
            poRouter = &m_RouterList[i];
            break;
        }
    }
    if (poRouter != NULL)
    {
        poRouter->nSession = nSession;
    }
    return poRouter;
}

void RouterMgr::OnRegisterRouterSuccess(int8_t nRouterService)
{
	XLog(LEVEL_INFO, "%s: Register to router:%d successful\n", g_poContext->GetService()->GetServiceName(), nRouterService);
    ROUTER* pRouter = NULL;
    for (int i = 0; i < m_nRouterNum; i++)
    {
        if (m_RouterList[i].nService == nRouterService)
        {
            pRouter = &m_RouterList[i];
            break;
        }
    }
    assert(pRouter != NULL && pRouter->nSession > 0);
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

ROUTER* RouterMgr::GetRouter(int8_t nRouterService)
{
    for (int i = 0; i < m_nRouterNum; i++)
    {
        if (m_RouterList[i].nService == nRouterService)
        {
			return &m_RouterList[i];
        }
    }
	return NULL;
}


ROUTER* RouterMgr::ChooseRouter(int8_t nTarService)
{
    if (m_nRouterNum <= 0)
    {
		XLog(LEVEL_ERROR, "Router count is 0!\n");
        return NULL;
    }
    int nIndex = nTarService % m_nRouterNum;
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