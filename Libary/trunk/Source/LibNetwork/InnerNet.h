/*
 * Internal net 
 * When connection recv/send packets out of stick num will be break and wait next event 
 */

#ifndef __INNERNET_H__
#define __INNERNET_H__

#include "LibNetwork/Net.h"

class InnerNet : public Net
{
public:
	InnerNet();
	bool Init(int nServiceID, int nMaxConns);

public:
	// Interface
	virtual bool SendPacket(int nSessionID, Packet* poPacket);

public:
    // Packet income
	virtual void OnRecvPacket(void* pUD, Packet* poPacket);

private:
	// Process data
	virtual void ReadData(SESSION* pSession);
	virtual void WriteData(SESSION* pSession);
	virtual bool CheckBlockDataSize(SESSION* pSession);
	virtual void Timer(long nInterval);

private:
	int m_nLastPrintTime;
	DISALLOW_COPY_AND_ASSIGN(InnerNet);
	virtual ~InnerNet() {}

};

#endif
