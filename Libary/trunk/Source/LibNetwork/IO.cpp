#include "Common/DataStruct/XTime.h"
#include "Include/Network/NetAPI.h"
#include "LibNetwork/Net.h"
#include "LibNetwork/IO.h"

//默认的切包函数
int DefaultSplitPacket(HSOCKET nSock, void* pUD, RECVBUF& oRecvBuf, Net* poNet) 
{
	uint8_t *pPos = oRecvBuf.pBuf;
	uint8_t *pSpPos = pPos;
	int nPackets = 0;
	int nMaxDataSize = oRecvBuf.nSize - sizeof(int);
	for (;;)
	{
		int nSize = (int)(oRecvBuf.pPos - pPos);
		if (nSize < (int)sizeof(int))
		{
			break;
		}
		int nDataSize = *(int*)pPos;
		if (nDataSize <= 0 || nDataSize > nMaxDataSize)
		{
			XLog(LEVEL_ERROR, "%s: sock:%d illegal packet size:%d max size:%d\n", poNet->GetName(), nSock, nDataSize, nMaxDataSize);
			return -1;
		}
		pPos += sizeof(int);
		// Wait for more data
		if (pPos + nDataSize > oRecvBuf.pPos)
		{
			break;
		}
		pPos += nDataSize;
		int nPacketSize = sizeof(int) + nDataSize;
		Packet* poPacket = Packet::Create(nPacketSize + sizeof(INNER_HEADER)*2, nPACKET_OFFSET_SIZE, __FILE__, __LINE__);
		poPacket->FillData(pSpPos, nPacketSize);
        poNet->OnRecvPacket(pUD, poPacket);
		pSpPos = pPos;
		nPackets++;
	}

	if (nPackets > 0)
	{
		if (oRecvBuf.pPos > pSpPos)
		{
			int nRemain = (int)(oRecvBuf.pPos - pSpPos);
			memmove(oRecvBuf.pBuf, pSpPos, nRemain);
			oRecvBuf.pPos = oRecvBuf.pBuf + nRemain;
		}
		else
		{
			oRecvBuf.pPos = oRecvBuf.pBuf;
		}
	}
	return nPackets;
}

int IORead(HSOCKET nSock, void* pUD, RECVBUF& oRecvBuf, Net* poNet, int nMaxReadPerEvent, SplitPacketFn fnSplitPacketCallback /*= DefaultSplitPacket*/)
{
	int nTotalReaded = 0;
	uint8_t* pEnd = oRecvBuf.pBuf + oRecvBuf.nSize;
	for (;;)
	{
		int nCapacity = (pEnd - oRecvBuf.pPos);
		int nReaded = ::recv(nSock, (char*)oRecvBuf.pPos, (int)nCapacity, 0);
		if (nReaded <= 0)
		{
			// Common close
			if (nReaded == 0)
			{
				return -1;
			}
#ifdef __linux
			if (errno == EINTR)
			{
				continue;
			}
			else if (errno == EAGAIN)
			{
				return 0;
			}
			XLog(LEVEL_ERROR, "Sock:%d read error:%s\n", nSock, strerror(errno));
#else
			int nErrCode = WSAGetLastError();
			if (nErrCode == WSAEINTR)
			{
				continue;
			}
			if (nErrCode == WSAEWOULDBLOCK)
			{
				return 0;
			}
			XLog(LEVEL_ERROR, "Sock:%d read error:%s", nSock, Platform::LastErrorStr(nErrCode));
#endif
			return -1;
		}
		oRecvBuf.pPos += nReaded;
		if (fnSplitPacketCallback(nSock, pUD, oRecvBuf, poNet) < 0)
		{
			return -1;
		}
		nTotalReaded += nReaded;
		if (nMaxReadPerEvent > 0 && nTotalReaded >= nMaxReadPerEvent)
		{
			XLog(LEVEL_ERROR, "Sock:%d read perevent out of range:%dk\n", nSock, nMaxReadPerEvent/1024);
			return 1;
		}
	}
	return 0;
}

int IOWrite(HSOCKET nSock, MsgList* poMsgList, uint32_t nMaxWritePerEvent, uint32_t* pSentPackets, uint32_t* pTotalWrited)
{
	while (poMsgList->Size() > 0)
	{
		Packet* poPacket = poMsgList->Front();
		uint8_t* pBuf = poPacket->GetData();
		int nDataSize = poPacket->GetDataSize();
		int nSentSize = poPacket->GetSentSize();
		int nWrited = ::send(nSock, (char*)pBuf + nSentSize, nDataSize - nSentSize, 0);
		if (nWrited == -1)
		{
#ifdef __linux
			if (errno == EINTR)
			{
				continue;
			}
			if (errno == EAGAIN)
			{
				XLog(LEVEL_INFO, " Sock:%d write EAGAIN:%d\n", nSock, nDataSize - nSentSize);
				return 0;
			}
			XLog(LEVEL_ERROR, "Sock:%d write error:%s\n", nSock, strerror(errno));
			return -1;
#else
			int nErrCode = WSAGetLastError();
			if (nErrCode == WSAEINTR)
			{
				continue;
			}
			if (nErrCode == WSAEWOULDBLOCK)
			{
				//XLog(LEVEL_ERROR, "Sock:%d write EAGAIN:%d\n", nSock, nDataSize - nSentSize);
				return 0;
			}
			XLog(LEVEL_ERROR, "Sock:%d write error:%s", nSock, Platform::LastErrorStr(nErrCode));
			return -1;
#endif
		} 
		nSentSize += nWrited;
		poPacket->SetSentSize(nSentSize);
		if (nSentSize == nDataSize)
		{
			poMsgList->PopFront();
			if (poPacket->GetRef() > 1)
			{
				poPacket->SetSentSize(0);
			}
			
			if (poPacket->IsMasking())
			{
				uint16_t uCmd = *(uint16_t*)poPacket->GetMaskingKey();
				if (uCmd == 1025)
				{
					XLog(LEVEL_INFO, "gate network sent mstime:%lld ref:%d nodelay:%d cork:%d\n", XTime::UnixMSTime(), poPacket->GetRef(), NetAPI::IsNoDelay(nSock), NetAPI::IsCork(nSock));
				}
			}

			poPacket->Release(__FILE__, __LINE__);
			(*pSentPackets)++;
		}
		else if (poPacket->GetRef() > 1)
		{
			poMsgList->PopFront();
			Packet* poNewPacket = poPacket->DeepCopy(__FILE__, __LINE__);
			poMsgList->PushFront(poNewPacket);
			poPacket->SetSentSize(0);
			poPacket->Release(__FILE__, __LINE__);
		}
		(*pTotalWrited) += nWrited;
		if ((*pTotalWrited) >= nMaxWritePerEvent)
		{
			XLog(LEVEL_ERROR, "Sock:%d write perevent out of range:%dK\n", nSock, nMaxWritePerEvent/1024);
			return 1;
		}
	}
	return 0;
}