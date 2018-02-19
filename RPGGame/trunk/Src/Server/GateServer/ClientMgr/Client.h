#ifndef __CLIENT_H__
#define __CLIENT_H__

struct CLIENT
{
	uint32_t uRemoteIP;
	uint32_t uCmdIndex;
	int8_t nLogicService;

	CLIENT()
	{
		uRemoteIP = 0;
		uCmdIndex = 0;
		nLogicService = 0;
	}
};

#endif