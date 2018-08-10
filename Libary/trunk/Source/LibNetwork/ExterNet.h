#ifndef __EXTERNET_H__
#define __EXTERNET_H__

#include "LibNetwork/Net.h"

//连接信息
struct ConnInfo
{
	uint32_t uConns;	//连接个数
	int nLastConnTime;	//上一连接时间
	int nBlockStartTime; //屏蔽开始时间
	int nLastCheckCPM;	//上一检测时间
};

class ExterNet : public Net
{
public:
	typedef std::unordered_map<uint32_t, ConnInfo> IPConnMap;
	typedef IPConnMap::iterator IPConnIter;

public:
	ExterNet() { m_nNetType = NET_TYPE_EXTERNAL; }
	bool Init(int nServiceID, int nMaxConns, int nSecureCPM, int nSecureQPM, int nSecureBlock, int nDeadLinkTime, bool bLinger);

public:
	// Interface 
	virtual bool SendPacket(int nSessionID, Packet* poPacket);

public:
    //Packet income
	virtual void OnRecvPacket(void* pUD, Packet* poPacket);

private:
	// Security 
	void CheckDLK();
	bool CheckQPM(SESSION* pSession);
	virtual bool CheckCPM(uint32_t uIP, const char* psIP);


private:
	// Deal data 
	virtual void ReadData(SESSION* pSession);
	virtual void WriteData(SESSION* pSession);
	virtual bool CheckBlockDataSize(SESSION* pSession);
	virtual void Timer(long nInterval);

protected: //Sub class used
	virtual ~ExterNet() {};

	int m_nSecureCPM;
	int m_nSecureQPM;
	int m_nSecureBlock;
	int m_nDeadLinkTime;

	IPConnMap m_oIPConnMap;
	DISALLOW_COPY_AND_ASSIGN(ExterNet);
};

#endif
