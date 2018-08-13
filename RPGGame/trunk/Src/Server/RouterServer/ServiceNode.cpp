#include "Server/RouterServer/ServiceNode.h"

ServiceNode::ServiceNode(int nNetIndex)
{
	m_nServerID = 0;
	m_nServiceID = 0;
	m_nSessionID = 0;
	m_hSocket = INVALID_SOCKET;
	m_nNetIndex = nNetIndex;
	m_nServiceType = 0;
}

ServiceNode::~ServiceNode()
{

}

