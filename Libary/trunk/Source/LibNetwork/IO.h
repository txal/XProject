#ifndef __IO_H__
#define __IO_H__

#include "LibNetwork/Session.h"

class Net;

//Split packet function define
typedef int SplitPacketFn(HSOCKET nSock, void* pUD, RECVBUF& oRecvBuf, Net* poNet);
int DefaultSplitPacket(HSOCKET nSock, void* pUD, RECVBUF& oRecvBuf, Net* poNet);

int SplitPacket(HSOCKET nSock, void* pUD, RECVBUF& oRecvBuf, Net* poNet);
int IORead(HSOCKET nSock, void* pUD, RECVBUF& oRecvBuf, Net* poNet, int nMaxReadPerEvent, SplitPacketFn fnSplitPacketCallback = DefaultSplitPacket);
int IOWrite(HSOCKET nSock, MsgList* poMsgList, uint32_t nMaxWritePerEvent, uint32_t* pSentPackets, uint32_t* pTotalWrited);

#endif
