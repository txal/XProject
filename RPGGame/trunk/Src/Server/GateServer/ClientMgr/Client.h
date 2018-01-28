#ifndef __CLIENT_H__
#define __CLIENT_H__

struct CLIENT
{
	uint32_t uRemoteIP;
	uint32_t uCmdIndex;
	uint16_t uServerID;
	int8_t nLogicService;

	CLIENT()
	{
		uRemoteIP = 0;
		uCmdIndex = 0;
		uServerID = 0;
		nLogicService = 0;
	}
};

#endif