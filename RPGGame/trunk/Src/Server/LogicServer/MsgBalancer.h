
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
	typedef std::unordered_map<int64_t, CONNECTION*> ConnMap;
	typedef ConnMap::iterator ConnIter;
	int64_t GenKey(int16_t uServer, int nSession) { return (int64_t)uServer << 32 | nSession; }

public:
	MsgBalancer();
	~MsgBalancer();

	void SetEventHandler(NetEventHandler* poEventHandler)	{ m_poEventHandler = poEventHandler; }
	bool GetEvent(NSNetEvent::EVENT& oEvent, uint32_t uWaitMS);
	void RemoveConn(uint16_t uServer, int nSession);

protected:
	CONNECTION* GetConn(uint16_t uServer, int nSession);

private:
	ConnMap m_oConnMap;
	CircleQueue<int64_t> m_oConnQueue;
	NetEventHandler* m_poEventHandler;
	DISALLOW_COPY_AND_ASSIGN(MsgBalancer);
};

#endif