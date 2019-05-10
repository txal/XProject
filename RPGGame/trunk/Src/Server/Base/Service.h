#ifndef __SERVICE_H__
#define __SERVICE_H__

#include "Common/Platform.h"
#include "Include/Network/Network.hpp"

#define SERVICE_SHIFT 24
#define MAX_SERVICE_NUM 0x7F
#define MAX_ROUTER_NUM 8
#define MAX_GATEWAY_NUM 8

class Service
{
public:
	enum
	{
		SERVICE_NONE,
		SERVICE_GATE,
		SERVICE_LOGIN,
		SERVICE_LOG,
		SERVICE_LOGIC,
		SERVICE_GLOBAL,
	};

public:
	Service();
	virtual ~Service() {}

	bool Init(int8_t nServiceID, const char* psServiceName);
	int8_t GetServiceID() { return m_nServiceID; }
	const char* GetServiceName() { return m_sServiceName; }
	uint32_t GetMainLoopCount() { return m_uMainLoopCount; }
	bool IsTerminate() { return m_bTerminate; }

public:
	virtual bool Start() = 0;
	virtual INet* GetInnerNet() { return NULL; }
	virtual INet* GetExterNet() { return NULL; }
	virtual void Terminate() { m_bTerminate = true; }
	virtual void Update(int64_t nMSTime);

protected:
	uint32_t m_uMainLoopCount;

private:
	int8_t m_nServiceID;
	char m_sServiceName[32];
	bool m_bTerminate;

	DISALLOW_COPY_AND_ASSIGN(Service);
};

#endif
