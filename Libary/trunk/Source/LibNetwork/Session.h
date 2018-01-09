#ifndef __SESSION_H__
#define __SESSION_H__

#include "LibNetwork/MsgList.h"

// Session type
enum 
{
	SESSION_TYPE_INVALID = 0,
	SESSION_TYPE_CTRL = 1, // Recv control session
	SESSION_TYPE_DATA = 2, // Common data session
	SESSION_TYPE_LISTEN = 3, // Listener session
};

// Websocket state
enum
{
	WEBSOCKET_UNCONNECT = 0,
	WEBSOCKET_HANDSHAKED = 1,
};

struct RECVBUF
{
    uint8_t* pBuf;
    uint8_t* pPos;
	int nSize;
};

struct SESSION
{
	RECVBUF oRecvBuf;			// Recv buf
	MsgList oPacketList; 		// Packet send list
	uint32_t uBlockDataSize;	// Blocking packet data size

	HSOCKET nSock;
	int nSessionID;
	int8_t nSessionType;	
	bool bSentClose; 			// Close socket after sent

	uint32_t uSessionIP;
	uint16_t nSessionPort;

	uint32_t uInPacketCount;
	int nLastInPacketTime;
	int nLastCheckQPM;
	uint32_t uOutPacketCount;
	
	int nCreateTime;
	int8_t nWebSocketState;

	SESSION(int nRecvBufSize) 
	{
		oRecvBuf.nSize = nRecvBufSize;
		oRecvBuf.pBuf = (uint8_t*)XALLOC(NULL, oRecvBuf.nSize);
		oRecvBuf.pPos = oRecvBuf.pBuf;
		Reset();
	}

	~SESSION()
	{
		Reset();	
		SAFE_FREE(oRecvBuf.pBuf)	;
	}

	void Reset()
	{
		oPacketList.Release();
		oRecvBuf.pPos = oRecvBuf.pBuf;
		uBlockDataSize = 0;

		nSock = 0;
		nSessionID = 0;
		nSessionType = SESSION_TYPE_INVALID;
		bSentClose = false;

		uSessionIP = 0;
		nSessionPort = 0;

		uInPacketCount = 0;
		uOutPacketCount = 0;
		int nTimeNow = (int)time(NULL);
		nLastInPacketTime = nTimeNow;
		nLastCheckQPM = nTimeNow;
		nCreateTime	= nTimeNow;
		nWebSocketState = (int8_t)WEBSOCKET_UNCONNECT;
	}
};

#endif
