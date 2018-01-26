#include "Server/Base/NetAdapter.h"
#include "Include/Network/Network.hpp"
#include "Server/Base/RouterMgr.h"
#include "Server/Base/Service.h"
#include "Server/Base/ServerContext.h"

//按服务器和网关分组
struct BROADCAST_HEADER
{
	INNER_HEADER oInnerHeader;
	Array<int> oSessionList;
};

typedef std::unordered_map<int, BROADCAST_HEADER> BCHeaderMap;
typedef BCHeaderMap::iterator BCHeaderIter;
static BCHeaderMap oBCHeaderMap;

bool NetAdapter::SendExter(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi, uint32_t uPacketIdx /*= 0*/)
{
    assert(poPacket != NULL);
	Service* poService = g_poContext->GetService();
	oNavi.nServiceID = oNavi.nSessionID >> SERVICE_SHIFT;
	if (oNavi.nServiceID == poService->GetServiceID() && oNavi.nServerID == g_poContext->GetServerID())
	{
		poPacket->AppendExterHeader(EXTER_HEADER(uCmd, poService->GetServiceID(), oNavi.nServiceID, uPacketIdx));
		if (!poService->GetExterNet()->SendPacket(oNavi.nSessionID, poPacket))
		{
			poPacket->Release();
			return false;
		}
	}
	else
	{
		return SendInner(uCmd, poPacket, oNavi);
	}
	return true;
}

bool NetAdapter::SendInner(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi)
{
    assert(poPacket != NULL);
    if (oNavi.nServiceID <= 0 || oNavi.nServiceID > MAX_SERVICE_NUM)
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
    poPacket->AppendInnerHeader(INNER_HEADER(uCmd, poService->GetServiceID(), oNavi.nServiceID, 1, oNavi.nServerID), &oNavi.nSessionID, 1);
    if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poPacket))
    {
		poPacket->Release();
		return false;
    }
	return true;
}

bool NetAdapter::BroadcastExter(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList)
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
		SERVICE_NAVI& oNavi = oNaviList[i];
		int nServer = oNavi.nServerID;
		int nService = oNavi.nSessionID >> SERVICE_SHIFT;
		oNavi.nServiceID = nService;

		int nKey = nServer << 16 | nService;

		BROADCAST_HEADER& oBCHeader = oBCHeaderMap[nKey]; //没有会自动生成一个
		if (oBCHeader.oSessionList.Size() == 0)
		{
			oBCHeader.oInnerHeader.uCmd = uCmd;
			oBCHeader.oInnerHeader.nSrc = poService->GetServiceID();
			oBCHeader.oInnerHeader.nTar = nService;
			oBCHeader.oInnerHeader.uSessions = 0;
			oBCHeader.oInnerHeader.uServer = nServer;
		}
		oBCHeader.oSessionList.PushBack(oNavi.nSessionID);
	}

	BCHeaderIter iter = oBCHeaderMap.begin();
	BCHeaderIter iterend = oBCHeaderMap.end();
	BCHeaderIter itertmp = iter;
	BCHeaderIter iternext = ++itertmp;
	for (; iter != iterend; iter++, iternext++)
	{
		BROADCAST_HEADER& oBCHeader = iter->second;
		if (oBCHeader.oSessionList.Size() == 0)
			continue;

		oBCHeader.oInnerHeader.uSessions = oBCHeader.oSessionList.Size();

		Packet* poNewPacket = NULL;
		if (iternext == iterend)
			poNewPacket = poPacket;
		else
			poNewPacket = poPacket->DeepCopy();
		poNewPacket->AppendInnerHeader(oBCHeader.oInnerHeader, oBCHeader.oSessionList.Ptr(), oBCHeader.oSessionList.Size());

		if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poNewPacket))
		{
			poNewPacket->Release();
		}
		oBCHeader.oSessionList.Clear();
	}
	return true;
}

bool NetAdapter::BroadcastInner(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList)
{
	assert(poPacket != NULL);
	Service* poService = g_poContext->GetService();
	ROUTER* poRouter = g_poContext->GetRouterMgr()->ChooseRouter(poService->GetServiceID());
	if (poService == NULL || poRouter == NULL)
	{
		poPacket->Release();
		return false;
	}
	for (int i = oNaviList.Size() - 1; i >= 0; --i)
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
		int nSessionNum = 0;
		int* pSessionList = NULL;
		if (oNaviList[i].nSessionID > 0)
		{
			nSessionNum = 1;
			pSessionList = &oNaviList[i].nSessionID;
		}

		poNewPacket->AppendInnerHeader(INNER_HEADER(uCmd, poService->GetServiceID(), oNaviList[i].nServiceID, nSessionNum, oNaviList[i].nServerID), pSessionList, nSessionNum);
		if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poNewPacket))
		{
			poNewPacket->Release();
		}
	}
	return true;
}