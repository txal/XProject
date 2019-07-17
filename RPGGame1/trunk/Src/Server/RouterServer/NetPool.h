#ifndef __NETPOOL_H__
#define __NETPOOL_H__

#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XMath.h"

const int MAX_NETS = 128;

class NetPool
{
public:
	NetPool();
	~NetPool();

public:
	bool Init(int nNum, NetEventHandler* poHandler);
	INet* GetNet(int nIndex);
	int RandomNetIndex() { return XMath::Random(1, m_nNetNum)-1; }

private:
	int m_nNetNum;
	NetEventHandler* m_poHandler;
	INet* m_tInnerNet[MAX_NETS];
	DISALLOW_COPY_AND_ASSIGN(NetPool);
};

#endif
