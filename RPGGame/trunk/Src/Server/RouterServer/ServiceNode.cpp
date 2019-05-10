#include "Server/RouterServer/ServiceNode.h"
#include "Include/Script/Script.hpp"

ServiceNode::ServiceNode(int nNetIndex)
{
	m_nServerID = 0;
	m_nServiceID = 0;
	m_nSessionID = 0;
	m_hSocket = INVALID_SOCKET;
	m_nNetIndex = nNetIndex;
	m_nServiceType = 0;
	m_nLastReportTime = 0;
}

ServiceNode::~ServiceNode()
{

}

void ServiceNode::Update(int nNowMS)
{
	if (nNowMS - m_nLastReportTime < 3*60)
	{
		return;
	}
	m_nLastReportTime = nNowMS;
	LuaWrapper* poLuaWrapper = LuaWrapper::Instance();
	//poLuaWrapper->FastCallLuaRef<void>("OnServiceReport", 0, "iii", m_nServerID, m_nServiceID, m_nServiceType);
}
