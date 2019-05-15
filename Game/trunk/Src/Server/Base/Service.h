#ifndef __SERVICE_H__
#define __SERVICE_H__

#include "Common/Platform.h"
#include "Include/Network/Network.hpp"

#define SERVICE_SHIFT 24
#define MAX_SERVICE_NUM 0x7F
#define FRAME_MSTIME 33
#define MAX_ROUTER_NUM 8

class Service
{
public:
	Service();
	bool Init(int8_t nServiceID, const char* psServiceName);
	int8_t GetServiceID() { return m_nServiceID; }
	const char* GetServiceName() { return m_sServiceName; }

	virtual bool Start() = 0;
	virtual INet* GetInnerNet() { return NULL; }
	virtual INet* GetExterNet() { return NULL; }
	virtual void Update(int64_t nMSTime);

private:
	int8_t m_nServiceID;
	char m_sServiceName[32];
	DISALLOW_COPY_AND_ASSIGN(Service);
};

#endif
