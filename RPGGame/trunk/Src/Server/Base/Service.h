﻿#ifndef __SERVICE_H__
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
	Service();
	bool Init(int8_t nServiceID, const char* psServiceName);
	int8_t GetServiceID() { return m_nServiceID; }
	const char* GetServiceName() { return m_sServiceName; }
	uint32_t GetMainLoopCount() { return m_uMainLoopCount; }

	virtual bool Start() = 0;
	virtual INet* GetInnerNet() { return NULL; }
	virtual INet* GetExterNet() { return NULL; }

protected:
	uint32_t m_uMainLoopCount;

private:
	int8_t m_nServiceID;
	char m_sServiceName[32];

	DISALLOW_COPY_AND_ASSIGN(Service);
};

#endif
