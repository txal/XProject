#ifndef __CLIENT_H__
#define __CLIENT_H__

struct CLIENT
{
	uint32_t uRemoteIP;
	int nLogicService;
	uint32_t uCmdIndex;

	CLIENT()
	{
		nLogicService = 0;
		uCmdIndex = 0;
		uRemoteIP = 0;
	}
};

#endif