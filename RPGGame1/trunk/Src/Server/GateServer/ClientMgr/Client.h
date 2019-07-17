#ifndef __CLIENT_H__
#define __CLIENT_H__

#include "Common/Platform.h"

class Client
{
public:
	Client();
	~Client();
	
	void Update(int64_t nNowMS);

public:
	int32_t m_nSession;
	uint32_t m_uRemoteIP;
	uint32_t m_uCmdIndex;

	int32_t m_nRoleID;
	int8_t m_nLogicService;

	int32_t m_nLastPacketTime;
	int32_t m_nLastNotifyTime;
	int32_t m_nLastKeepAliveTime;
};

#endif