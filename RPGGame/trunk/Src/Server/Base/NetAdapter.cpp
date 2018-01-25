#include "Server/Base/NetAdapter.h"
#include "Include/Network/Network.hpp"
#include "Server/Base/RouterMgr.h"
#include "Server/Base/Service.h"
#include "Server/Base/ServerContext.h"

#define MAX_GATEWAY_NUM 8		//单服最大网关数
#define MAX_GROUPSERVER_NUM 128 //每组服务器上限

//按服务器和网关分组
struct BROADCAST_HEADER
{
	INNER_HEADER oInerHeader;
	Array<int> oSessionList;
};
std::unordered_map<int, BROADCAST_HEADER> oBCHeaderMap;

bool NetAdapter::SendExter(uint16_t uCmd, Packet* poPacket, int8_t nToService, int nToSession, uint32_t uPacketIdx /*=0*/, int nToServer /*=0*/)
{
    assert(poPacket != NULL);
	Service* poService = g_poContext->GetService();
	int8_t nSessionService = nToSession >> SERVICE_SHIFT;
	if (nSessionService == poService->GetServiceID())
	{
		poPacket->AppendExterHeader(EXTER_HEADER(uCmd, poService->GetServiceID(), nToService, uPacketIdx));
		if (!poService->GetExterNet()->SendPacket(nToSession, poPacket))
		{
			poPacket->Release();
			return false;
		}
	}
	else
	{
		return SendInner(uCmd, poPacket, nToService, nToSession, nToServer);
	}
	return true;
}

bool NetAdapter::SendInner(uint16_t uCmd, Packet* poPacket, int8_t nToService, int nToSession, int nToServer)
{
    assert(poPacket != NULL);
    if (nToService <= 0 || nToService > MAX_SERVICE_NUM)
    {
    	poPacket->Release();
    	return false;
    }
	Service* poService = g_poContext->GetService();
	ROUTER* poRouter = g_poContext->GetRouterMgr()->ChooseRouter(poService->GetServiceID());
	if (poRouter == NULL)
	{
		poPacket->Release();
		return false;
	}
    poPacket->AppendInnerHeader(INNER_HEADER(uCmd, poService->GetServiceID(), nToService, 1, nToServer), &nToSession, 1);
    if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poPacket))
    {
		poPacket->Release();
		return false;
    }
	return true;
}

bool NetAdapter::BroadcastExter(uint16_t uCmd, Packet* poPacket, Array<INNER_NAVI>& oNaviList)
{
    assert(poPacket != NULL && oNaviList.Size() > 0);
	Service* poService = g_poContext->GetService();
	ROUTER* poRouter = g_poContext->GetRouterMgr()->ChooseRouter(poService->GetServiceID());
	if (poService == NULL || poRouter == NULL)
	{
		poPacket->Release();
		return false;
	}
	for (int i = oNaviList.Size() - 1; i >= 0; --i)
	{
		const INNER_NAVI& oNavi = oNaviList[i];
		int8_t nService = oNavi.u.nSession >> SERVICE_SHIFT;

		BROADCAST_HEADER& oBCHeader = tBroadcastHeaderList[tServiceMap[nService]];
		if (oBCHeader.oSessionList.Size() == 0)
		{
			oBCHeader.oHeader.uCmd = uCmd;
			oBCHeader.oHeader.nSrc = poService->GetServiceID();
			oBCHeader.oHeader.nTar = nService;
		}
		oBCHeader.oSessionList.PushBack(nSession);
	}
	for (int i = nFreeHeaderIndex - 1; i >= 0; --i)
	{
		BROADCAST_HEADER& oBCHeader = tBroadcastHeaderList[i];
		oBCHeader.oHeader.uSessions = oBCHeader.oSessionList.Size();
		Packet* poNewPacket = NULL;
		if (i == 0)
		{
			poNewPacket = poPacket;
		}
		else
		{
			poNewPacket = poPacket->DeepCopy();
		}
		poNewPacket->AppendInnerHeader(oBCHeader.oHeader, oBCHeader.oSessionList.Ptr(), oBCHeader.oSessionList.Size());
		if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poNewPacket))
		{
			poNewPacket->Release();
		}
		oBCHeader.oSessionList.Clear();
	}
	return true;
}

bool NetAdapter::BroadcastInner(uint16_t uCmd, Packet* poPacket, int tServiceList[], int nServiceNum, int tServerList[])
{
	assert(poPacket != NULL);
	Service* poService = g_poContext->GetService();
	ROUTER* poRouter = g_poContext->GetRouterMgr()->ChooseRouter(poService->GetServiceID());
	if (poService == NULL || poRouter == NULL)
	{
		poPacket->Release();
		return false;
	}
	for (int i = nServiceNum - 1; i >= 0; --i)
	{
		Packet* poNewPacket = NULL;
		if (i == 0)
		{
			poNewPacket = poPacket;
		}
		else
		{
			poNewPacket = poPacket->DeepCopy();
		}
		int nToServer = tServerList == NULL ? 0 : tServerList[i];
		poNewPacket->AppendInnerHeader(INNER_HEADER(uCmd, poService->GetServiceID(), tServiceList[i], 0, nToServer), NULL, 0);
		if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poNewPacket))
		{
			poNewPacket->Release();
		}
	}
	return true;
}