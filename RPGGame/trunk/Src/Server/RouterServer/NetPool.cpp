#include "Server/RouterServer/NetPool.h"

NetPool::NetPool()
{
	m_nNetNum = 0;
	memset(m_tInnerNet, 0, sizeof(m_tInnerNet));
}

NetPool::~NetPool()
{
	for (int i = 0; i < m_nNetNum; i++)
		m_tInnerNet[i]->Release();
}

bool NetPool::Init(int nNum, NetEventHandler* poHandler)
{
	assert(nNum > 0 && poHandler != NULL);
	XLog(LEVEL_INFO, "Worker thread num:%d\n", nNum);

	m_nNetNum = nNum;
	for (int i = 0; i < nNum; i++)
	{
		m_tInnerNet[i] = INet::CreateNet(NET_TYPE_INTERNAL, i, 1024, poHandler);
		assert(m_tInnerNet[i] != NULL);
	}
	return true;
}