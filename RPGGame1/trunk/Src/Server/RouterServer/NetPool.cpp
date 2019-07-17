#include "Server/RouterServer/NetPool.h"

NetPool::NetPool()
{
	m_nNetNum = 0;
	m_poHandler = NULL;;
	memset(m_tInnerNet, 0, sizeof(m_tInnerNet));
}

NetPool::~NetPool()
{
	for (int i = 0; i < m_nNetNum; i++)
	{
		if (m_tInnerNet[i] != NULL)
		{
			m_tInnerNet[i]->Release();
		}
	}
}

bool NetPool::Init(int nNum, NetEventHandler* poHandler)
{
	assert(nNum > 0 && poHandler != NULL);
	XLog(LEVEL_INFO, "NetPool thread num:%d\n", nNum);

	m_nNetNum = nNum;
	m_poHandler = poHandler;
	return true;
}

INet* NetPool::GetNet(int nIndex)
{
	assert(nIndex >= 0 && nIndex < m_nNetNum);
	if (m_tInnerNet[nIndex] == NULL)
	{
		m_tInnerNet[nIndex] = INet::CreateNet(NET_TYPE_INTERNAL, nIndex, 512, m_poHandler);
		assert(m_tInnerNet[nIndex] != NULL);
	}
	return m_tInnerNet[nIndex];
}