
#ifndef __MSG_BALANCER_H__
#define __MSG_BALANCER_H__

#include "Include/Network/Network.hpp"
#include "Common/DataStruct/CircleQueue.h"
#include "Common/Platform.h"

struct CONNECTION
{
	PureList<NSNetEvent::EVENT> oEventList;
	~CONNECTION()
	{
		assert(oEventList.Size() == 0);
	}
};

class MsgBalancer
{
public:
	typedef std::unordered_map<int, CONNECTION*> ConnMap;
	typedef ConnMap::iterator ConnIter;

public:
	MsgBalancer();
	~MsgBalancer();

	void SetEventHandler(NetEventHandler* poEventHandler)	{ m_poEventHandler = poEventHandler; }
	bool GetEvent(NSNetEvent::EVENT& oEvent, uint32_t uWaitMS);
	void RemoveConn(int nSession);

protected:
	CONNECTION* GetConn(int nSession);

private:
	ConnMap m_oConnMap;
	CircleQueue<int> m_oConnQueue;
	NetEventHandler* m_poEventHandler;
	DISALLOW_COPY_AND_ASSIGN(MsgBalancer);
};

#endif