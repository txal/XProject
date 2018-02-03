#include "Server/Base/NetAdapter.h"
#include "Include/Network/Network.hpp"
#include "Server/Base/RouterMgr.h"
#include "Server/Base/Service.h"
#include "Server/Base/ServerContext.h"

#define MAX_GATEWAY_NUM 8

struct BROADCAST_HEADER
{
	INNER_HEADER oHeader;
	Array<int> oSessionList;
};

static int8_t tServiceMap[MAX_SERVICE_NUM+1];
static BROADCAST_HEADER tBroadcastHeaderList[MAX_GATEWAY_NUM];

bool NetAdapter::SendExter(uint16_t uCmd, Packet* poPacket, int8_t nToService, int nToSession, uint32_t uPacketIdx /*=0*/)
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
		return SendInner(uCmd, poPacket, nToService, nToSession);
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
    poPacket->AppendInnerHeader(INNER_HEADER(uCmd, 0, poService->GetServiceID(), nToServer, nToService, 1), &nToSession, 1);
    if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poPacket))
    {
		poPacket->Release();
		return false;
    }
	return true;
}

bool NetAdapter::BroadcastExter(uint16_t uCmd, Packet* poPacket, int tSessionList[], int nSessionNum)
{
    assert(poPacket != NULL && nSessionNum > 0);
	Service* poService = g_poContext->GetService();
	ROUTER* poRouter = g_poContext->GetRouterMgr()->ChooseRouter(poService->GetServiceID());
	if (poService == NULL || poRouter == NULL)
	{
		poPacket->Release();
		return false;
	}
	int nFreeHeaderIndex = 0;
	memset(tServiceMap, -1, sizeof(tServiceMap));
	for (int i = nSessionNum - 1; i >= 0; --i)
	{
		int nSession = tSessionList[i];
		int8_t nService = nSession >> SERVICE_SHIFT;
		if (tServiceMap[nService] == -1)
		{
			tServiceMap[nService] = nFreeHeaderIndex++;
		}
		BROADCAST_HEADER& oBCHeader = tBroadcastHeaderList[tServiceMap[nService]];
		if (oBCHeader.oSessionList.Size() == 0)
		{
			oBCHeader.oHeader.uCmd = uCmd;
			oBCHeader.oHeader.nSrcService = poService->GetServiceID();
			oBCHeader.oHeader.nTarService = nService;
		}
		oBCHeader.oSessionList.PushBack(nSession);
	}
	for (int i = nFreeHeaderIndex - 1; i >= 0; --i)
	{
		BROADCAST_HEADER& oBCHeader = tBroadcastHeaderList[i];
		oBCHeader.oHeader.uSessionNum = oBCHeader.oSessionList.Size();
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
		poNewPacket->AppendInnerHeader(INNER_HEADER(uCmd, 0, poService->GetServiceID(), nToServer, tServiceList[i], 0), NULL, 0);
		if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poNewPacket))
		{
			poNewPacket->Release();
		}
	}
	return true;
}