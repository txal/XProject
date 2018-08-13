#ifndef __SERVICE_NODE_H__
#define __SERVICE_NODE_H__

#include "Include/Network/Network.hpp"
#include "Server/Base/Service.h"

class ServiceNode
{
public:
	ServiceNode(int nNetIndex);
	~ServiceNode();

	static int Key(int nServerID, int nServiceID) { return (nServerID << 16 | nServiceID); }

public:
	void SetServerID(int nServerID)		{ m_nServerID = nServerID; }
	void SetServiceID(int nServiceID)	{ m_nServiceID = nServiceID; }
	void SetSessionID(int nSessionID)	{ m_nSessionID = nSessionID; }
	void SetSocket(HSOCKET hSocket)	{ m_hSocket = hSocket;  }
	void SetServiceType(int nServiceType) { m_nServiceType = nServiceType; }

	int GetServerID()	{ return m_nServerID; }
	int GetServiceID()	{ return m_nServiceID; }
	int GetSessionID()	{ return m_nSessionID; }
	HSOCKET GetSocket() { return m_hSocket; }
	int GetNetIndex() { return m_nNetIndex; }
	int GetServcieType() { return m_nServiceType; }

private:
	int m_nServerID;
	int m_nServiceID;
	int m_nSessionID;
	HSOCKET m_hSocket;
	int m_nNetIndex;
	int m_nServiceType;

	DISALLOW_COPY_AND_ASSIGN(ServiceNode);
};

#endif
