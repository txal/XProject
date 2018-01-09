// Ctrl Request
#ifndef __CTRL_H__
#define __CTRL_H__

#include <stdint.h>
#include <string.h>

// Control type 
enum
{
	eCTRL_INVALID = 0,
	eCTRL_SEND = 1,
	eCTRL_CLOSE = 2,
	eCTRL_LISTEN = 3,
	eCTRL_CONNECT = 4,
	eCTRL_SENTCLOSE = 5,
	eCTRL_ADD_DATASOCK = 6,
};

struct REQUEST_SEND 
{
	int nSessionID;
	void *pData;
};

struct REQUEST_CLOSE
{
	int nSessionID;
};

struct REQUEST_LISTEN
{
	bool bNotCreateSession;
	uint16_t uPort;
	char sIP[256];
};

struct REQUEST_CONNECT
{
	uint16_t uRemotePort;
	char sRemoteIP[256];
};

struct REQUEST_ADD_DATASOCK
{
	HSOCKET hSock;
	uint32_t uRemoteIP;
	uint16_t uRemotePort;
};

struct REQUEST_SENTCLOSE
{
	int nSessionID;
};

struct REQUEST_PACKET
{
	uint8_t uCtrlType;
	union
	{
		REQUEST_SEND oSend;
		REQUEST_CLOSE oClose;
		REQUEST_LISTEN oListen;
		REQUEST_CONNECT oConnect;
		REQUEST_SENTCLOSE oSentClose;
		REQUEST_ADD_DATASOCK oDataSock;
	} U;
	REQUEST_PACKET()
	{
		uCtrlType = eCTRL_INVALID;
		memset(&U, 0, sizeof(U));
	}
};

#endif
