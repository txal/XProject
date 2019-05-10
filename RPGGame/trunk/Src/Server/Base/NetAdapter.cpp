#include "Server/Base/NetAdapter.h"
#include "Server/Base/RouterMgr.h"
#include "Server/Base/Service.h"
#include "Server/Base/ServerContext.h"

NetAdapter::BCHeaderMap NetAdapter::m_oBCHeaderMap;
void NetAdapter::Release()
{
	BCHeaderIter iter = m_oBCHeaderMap.begin();
	for (iter; iter != m_oBCHeaderMap.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
}

bool NetAdapter::SendExter(uint16_t uCmd, Packet* poPacket, SERVICE_NAVI& oNavi, uint32_t uPacketIdx /*= 0*/)
{
    assert(poPacket != NULL);
	Service* poService = g_poContext->GetService();
	if ((oNavi.uTarServer == g_poContext->GetServerID() && oNavi.nTarService == poService->GetServiceID()) || uPacketIdx > 0) //uPackeIdx>0表示客户端发出的指令
	{
		poPacket->AppendExterHeader(EXTER_HEADER(uCmd, poService->GetServiceID(), oNavi.nTarService, uPacketIdx));
		if (!poService->GetExterNet()->SendPacket(oNavi.nTarSession, poPacket))
		{
			poPacket->Release(__FILE__, __LINE__);
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
    if (oNavi.nTarService <= 0 || oNavi.nTarService > MAX_SERVICE_NUM)
    {
    	poPacket->Release(__FILE__, __LINE__);
    	return false;
    }
	Service* poService = g_poContext->GetService();
	ROUTER* poRouter = g_poContext->GetRouterMgr()->ChooseRouter(poService->GetServiceID());
	if (poRouter == NULL)
	{
		poPacket->Release(__FILE__, __LINE__);
		return false;
	}
    poPacket->AppendInnerHeader(INNER_HEADER(uCmd, oNavi.uSrcServer, oNavi.nSrcService, oNavi.uTarServer, oNavi.nTarService, 1), &oNavi.nTarSession, 1);
    if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poPacket))
    {
		poPacket->Release(__FILE__, __LINE__);
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
		poPacket->Release(__FILE__, __LINE__);
		return false;
	}

	for (int i = oNaviList.Size() - 1; i >= 0; --i)
	{
		SERVICE_NAVI& oNavi = oNaviList[i];
		oNavi.nTarService = oNavi.nTarSession >> SERVICE_SHIFT;

		int nKey = (int)oNavi.uTarServer << 16 | oNavi.nTarService;

		BROADCAST_HEADER* poBCHeader = NULL;
		BCHeaderIter iter = m_oBCHeaderMap.find(nKey);
		if (iter == m_oBCHeaderMap.end())
		{
			poBCHeader = XNEW(BROADCAST_HEADER)();
			m_oBCHeaderMap[nKey] = poBCHeader;
		}
		else
		{
			poBCHeader = iter->second;
		}
		if (poBCHeader->oSessionList.Size() == 0)
		{
			poBCHeader->oInnerHeader.uCmd = uCmd;
			poBCHeader->oInnerHeader.uSrcServer = oNavi.uSrcServer;
			poBCHeader->oInnerHeader.nSrcService = oNavi.nSrcService;
			poBCHeader->oInnerHeader.uTarServer = oNavi.uTarServer;
			poBCHeader->oInnerHeader.nTarService = oNavi.nTarService;
			poBCHeader->oInnerHeader.uSessionNum = 0;
		}
		poBCHeader->oSessionList.PushBack(oNavi.nTarSession);
	}

	if (m_oBCHeaderMap.size() == 0) 
	{
		poPacket->Release(__FILE__, __LINE__);
		return false;
	}

	BCHeaderIter iter = m_oBCHeaderMap.begin();
	BCHeaderIter iterend = m_oBCHeaderMap.end();
	for (; iter != iterend; iter++)
	{
		BROADCAST_HEADER* poBCHeader = iter->second;
		if (poBCHeader->oSessionList.Size() == 0)
		{
			continue;
		}

		Packet* poNewPacket = NULL;
		poBCHeader->oInnerHeader.uSessionNum = poBCHeader->oSessionList.Size();
		poNewPacket = poPacket->DeepCopy(__FILE__, __LINE__);
		poNewPacket->AppendInnerHeader(poBCHeader->oInnerHeader, poBCHeader->oSessionList.Ptr(), poBCHeader->oSessionList.Size());

		if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poNewPacket))
		{
			poNewPacket->Release(__FILE__, __LINE__);
		}
		poBCHeader->oSessionList.Clear();
	}
	poPacket->Release(__FILE__, __LINE__);
	return true;
}

bool NetAdapter::BroadcastInner(uint16_t uCmd, Packet* poPacket, Array<SERVICE_NAVI>& oNaviList)
{
	assert(poPacket != NULL);
	Service* poService = g_poContext->GetService();
	ROUTER* poRouter = g_poContext->GetRouterMgr()->ChooseRouter(poService->GetServiceID());
	if (poService == NULL || poRouter == NULL)
	{
		poPacket->Release(__FILE__, __LINE__);
		return false;
	}
	for (int i = oNaviList.Size() - 1; i >= 0; --i)
	{
		Packet* poNewPacket = NULL;
		poNewPacket = poPacket->DeepCopy(__FILE__, __LINE__);
		poNewPacket->AppendInnerHeader(INNER_HEADER(uCmd, oNaviList[i].uSrcServer, oNaviList[i].nSrcService, oNaviList[i].uTarServer, oNaviList[i].nTarService, 1), &(oNaviList[i].nTarSession), 1);
		if (!poService->GetInnerNet()->SendPacket(poRouter->nSession, poNewPacket))
		{
			poNewPacket->Release(__FILE__, __LINE__);
		}
	}
	poPacket->Release(__FILE__, __LINE__);
	return true;
}