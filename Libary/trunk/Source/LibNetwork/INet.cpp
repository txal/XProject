#include "Common/Platform.h"
#include "LibNetwork/ExterNet.h"
#include "LibNetwork/InnerNet.h"
#include "LibNetwork/WebSocket.h"

class Logger;
class NetEventHandler;

INet* INet::CreateNet(int nNetType, int nServiceID, int nMaxConns, NetEventHandler* pNetEventHandler
	, int nSecureCPM/*=0*/, int nSecureQPM/*=0*/, int nSecureBlock/*=0*/, int nDeadLinkTime/*=180*/, bool bClient/*=false*/)
{
	assert(nMaxConns > 0 && nServiceID >= 0);
	INet* pNet = NULL;
	if (nNetType == NET_TYPE_INTERNAL)
	{
		InnerNet* pInnerNet = XNEW(InnerNet);
		if (!pInnerNet->Init(nServiceID, nMaxConns))
		{
			pInnerNet->Release();
		}
		else
		{
			pInnerNet->SetEventHandler(pNetEventHandler);
			pNet = pInnerNet;
		}
	}
	else if (nNetType == NET_TYPE_EXTERNAL)
	{
		ExterNet* pExterNet = XNEW(ExterNet);
		if (!pExterNet->Init(nServiceID, nMaxConns, nSecureCPM, nSecureQPM, nSecureBlock, nDeadLinkTime, true))
		{
			pExterNet->Release();
		}
		else
		{
			pExterNet->SetEventHandler(pNetEventHandler);
			pNet = pExterNet;
		}
	}
	else if (nNetType == NET_TYPE_WEBSOCKET)
	{
		WebSocket* pExterNet = XNEW(WebSocket);
		if (!pExterNet->Init(nServiceID, nMaxConns, nSecureCPM, nSecureQPM, nSecureBlock, nDeadLinkTime, true, bClient))
		{
			pExterNet->Release();
		}
		else
		{
			pExterNet->SetEventHandler(pNetEventHandler);
			pNet = pExterNet;
		}
	}
	return pNet;
}