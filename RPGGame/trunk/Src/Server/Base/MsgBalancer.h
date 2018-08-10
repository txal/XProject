
#ifndef __MSG_BALANCER_H__
#define __MSG_BALANCER_H__

#include "Include/Network/Network.hpp"
#include "Common/DataStruct/CircleQueue.h"
#include "Common/Platform.h"

struct CONNECTION
{
	bool bRelease;
	PureList<NSNetEvent::EVENT> oEventList;
	CONNECTION() : bRelease(false) {
	}
	~CONNECTION()
	{
		PURELIST_NODE<NSNetEvent::EVENT> *pPos = NULL, *pTmp = NULL, *pHead = oEventList.GetHead();
		PureListForEachSafe(pPos, pTmp, pHead)
		{
			NSNetEvent::EVENT& oEvent = pPos->Value;
			if (oEvent.uEventType == NSNetEvent::eEVT_ON_RECV)
				oEvent.U.oRecv.poPacket->Release();
		}
	}
};

class MsgBalancer
{
public:
	typedef std::unordered_map<int64_t, CONNECTION*> ConnMap;
	typedef ConnMap::iterator ConnIter;

public:
	int64_t GenKey(uint16_t uServer, int8_t nService, int nSession) { return ((int64_t)uServer << 40) | ((int64_t)nService << 32) | nSession;}
	void DecKey(int64_t nKey, uint16_t& uServer, int8_t& nService, int& nSession) 
	{ 
		uServer = (uint16_t)((nKey >> 40) & 0xFFFF);
		nService = (int8_t)((nKey >> 32) & 0xFF);
		nSession = (int)(nKey & 0xFFFFFFFF);
	}

public:
	MsgBalancer();
	~MsgBalancer();

	void SetEventHandler(NetEventHandler* poEventHandler)	{ m_poEventHandler = poEventHandler; }
	bool GetEvent(NSNetEvent::EVENT& oEvent, uint32_t uWaitMS);
	void RemoveConn(uint16_t uServer, int8_t nService, int nSession);

protected:
	CONNECTION* GetConn(int64_t nKey);
	bool QueueEvent(NSNetEvent::EVENT& oEvent);

private:
	ConnMap m_oConnMap;
	CircleQueue<int64_t> m_oConnQueue;
	NetEventHandler* m_poEventHandler;
	DISALLOW_COPY_AND_ASSIGN(MsgBalancer);
};

#endif