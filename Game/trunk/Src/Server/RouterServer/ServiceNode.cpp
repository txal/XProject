#include "Server/RouterServer/ServiceNode.h"

ServiceNode::ServiceNode()
{
	m_nServerID = 0;
	m_nServiceID = 0;
	m_nSessionID = 0;
	m_poInnerNet = NULL;
	m_hSocket = INVALID_SOCKET;
}

ServiceNode::~ServiceNode()
{
	if (m_poInnerNet != NULL)
	{
		m_poInnerNet->Release();
	}
}

bool ServiceNode::Init(int nParentService, NetEventHandler* poHandler)
{
	m_poInnerNet = INet::CreateNet(NET_TYPE_INTERNAL, nParentService, 512, poHandler);
	return (m_poInnerNet != NULL);
}