#include "Server/Base/Service.h"

Service::Service()
{
	m_nServiceID = 0;
	m_sServiceName[0] = '\0';
	m_uMainLoopCount = 0;
	m_bTerminate = false;
}

bool Service::Init(int8_t nServiceID, const char* psServiceName)
{
	assert(psServiceName != NULL && nServiceID >= 0 && nServiceID <= MAX_SERVICE_NUM);
	m_nServiceID = nServiceID;
	strcpy(m_sServiceName, psServiceName);
	return true;
}

void Service::Update(int64_t nMSTime)
{
	static int64_t nLastTime = 0;
	if (nMSTime - nLastTime < 60000)
	{
		return;
	}
	nLastTime = nMSTime;
	XLog(LEVEL_INFO, "CPP packets=%u\n", Packet::GetTotalPackets());
}
