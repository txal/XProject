#include "Common/DataStruct/TimeMonitor.h"
#include "LibNetwork/Base64.h"
#include "LibNetwork/IO.h"
#include "LibNetwork/WebSocket.h"
#include "LibNetwork/Sha1.h"
#include "Include/Network/NetAPI.h"
#include "Include/Network/NetEventDef.h"
#include "Include/Network/NetEventHandler.h"

#define MAGIC_KEY "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"

//websocket 头部
struct WSHeader
{
	uint8_t fin_;
	uint8_t opcode_;
	uint8_t mask_;
	uint8_t masking_key_[4];
	uint64_t payload_length_;
	void Reset()
	{
		fin_ = 0;
		opcode_ = 0;
		mask_ = 0;
		payload_length_ = 0;
		memset(masking_key_, 0, sizeof(masking_key_));
	}
};
WSHeader oWSHeader;

bool WebSocket::Init(int nServiceId, int nMaxConns, int nSecureCPM, int nSecureQPM, int nSecureBlock, int nDeadLinkTime, bool bLinger, bool bClient)
{
	char sNetName[32];
	sprintf(sNetName, "WebSocket%d", nServiceId);
	m_nSecureCPM = nSecureCPM;
	m_nSecureQPM = nSecureQPM;
	m_nSecureBlock = nSecureBlock;
	m_nDeadLinkTime = nDeadLinkTime;
	m_bClient = bClient;
	return Net::Init(sNetName, nServiceId, nMaxConns, EXTERNET_MAX_RECVBUF, bLinger);
}

// Callback
void WebSocket::OnRecvPacket(void* pUD, Packet* poPacket)
{
	ExterNet::OnRecvPacket(pUD, poPacket);
}

// Interface
bool WebSocket::SendPacket(int nSessionID, Packet* poPacket)
{
	SESSION* poSession = GetSession(nSessionID);
	if (poSession == NULL)
	{
		return false;
	}
	if (poSession->nWebSocketState == WEBSOCKET_HANDSHAKED && poPacket->WebSocketMark() == 0)
	{
		uint8_t sHeader[14];
		uint8_t* pPos = sHeader;
		int nHeaderLen = 2;
		pPos[0] = 1 << 7 | 0x2; //fin_ & pocode_
		pPos[1] = 0; //mask_ 
		const int nPacketSize = poPacket->GetDataSize();
		if (nPacketSize < 126)
		{
			pPos[1] |= nPacketSize;
		}
		else if (nPacketSize < 65536)
		{
			pPos[1] |= 126;
			pPos[2] = nPacketSize >> 8;
			pPos[3] = nPacketSize & 0xFF;
			nHeaderLen += 2;
		}
		else
		{
			pPos[1] |= 127;
			//只支4字节整型大小的包
			pPos[2] = 0;
			pPos[3] = 0;
			pPos[4] = 0;
			pPos[5] = 0;
			pPos[6] = nPacketSize >> 24;
			pPos[7] = nPacketSize >> 16;
			pPos[8] = nPacketSize >> 8;
			pPos[9] = nPacketSize & 0xFF;
			memcpy((void*)(pPos + 2), &nPacketSize, 8);
			nHeaderLen += 8;
		}
		poPacket->CheckAndExpand(nHeaderLen);
		uint8_t* pData = poPacket->GetData();
		memmove(pData + nHeaderLen, pData, nPacketSize);
		memcpy(pData, sHeader, nHeaderLen);
		poPacket->SetDataSize(nPacketSize + nHeaderLen);

		//fix pd
		EXTER_HEADER oExterHeader;
		poPacket->GetExterHeader(oExterHeader, false);
		if (oExterHeader.uCmd == 1025)
		{
			poPacket->SetMaskingKey(true, (uint8_t*)&oExterHeader.uCmd);
		}
	}

	return ExterNet::SendPacket(nSessionID, poPacket);
}

void WebSocket::ReadData(SESSION* pSession)
{
	int nRet = IORead(pSession->nSock, pSession, pSession->oRecvBuf, this, EXTERNET_MAX_READ_PEREVENT, SplitPacket);
	if (nRet == -1 || nRet == 1)
	{
		if (nRet == 1)
		{
			XLog(LEVEL_INFO, "%s: Session:%d read blocking size:%d io packets:%d/%d\n"
				, GetName(), pSession->nSessionID, pSession->uBlockDataSize, pSession->uInPacketCount, pSession->uOutPacketCount);
		}
		CloseSession(pSession->nSessionID);
		return;
	}
}

int WebSocket::ServerHandShakeReq(void* pUD, RECVBUF& oRecvBuf)
{
	m_oHeaderMap.clear();
	std::string buf((char*)oRecvBuf.pBuf, oRecvBuf.pPos - oRecvBuf.pBuf);
	//XLog(LEVEL_INFO, "WEBSOCKET HAND SHAKE:%s\n", buf.c_str());
	std::istringstream s(buf);
	std::string request;

	std::getline(s, request);
	if (request[request.size() - 1] == '\r')
	{
		request.erase(request.end() - 1);
	}
	else
	{
		return -1;
	}

	std::string header;
	std::string::size_type end;

	while (std::getline(s, header) && header != "\r")
	{
		if (header[header.size() - 1] != '\r')
		{
			continue; //end
		}
		else
		{
			header.erase(header.end() - 1);	//remove last char
		}

		end = header.find(": ", 0);
		if (end != std::string::npos)
		{
			std::string key = header.substr(0, end);
			std::string value = header.substr(end + 2);
			m_oHeaderMap[key] = value;
		}
	}

	char sResponse[1024] = { 0 };
	strcat(sResponse, "HTTP/1.1 101 Switching Protocols\r\n");
	strcat(sResponse, "Connection: upgrade\r\n");
	strcat(sResponse, "Sec-WebSocket-Accept: ");
	std::string server_key = m_oHeaderMap["Sec-WebSocket-Key"];
	server_key += MAGIC_KEY;

	SHA1 sha;
	unsigned int message_digest[5];
	sha.Reset();
	sha << server_key.c_str();

	sha.Result(message_digest);
	for (int i = 0; i < 5; i++)
	{
		message_digest[i] = htonl(message_digest[i]);
	}
	server_key = base64_encode(reinterpret_cast<const unsigned char*>(message_digest), 20);
	server_key += "\r\n";
	strcat(sResponse, server_key.c_str());
	strcat(sResponse, "Upgrade: websocket\r\n\r\n");


	SESSION* poSession = (SESSION*)pUD;
	int nSendLen = (int)strlen(sResponse);
	Packet* poPacket = Packet::Create(nSendLen, 0, __FILE__, __LINE__);
	poPacket->FillData((uint8_t*)sResponse, nSendLen);
	if (!ExterNet::SendPacket(poSession->nSessionID, poPacket))
	{
		poPacket->Release(__FILE__, __LINE__);
		return -1;
	}
	else
	{
		oRecvBuf.pPos = oRecvBuf.pBuf;
		poSession->nWebSocketState = WEBSOCKET_HANDSHAKED;
		return 0;
	}
}

int WebSocket::ServerHandShakeRet(void* pUD, RECVBUF& oRecvBuf)
{
	oRecvBuf.pPos = oRecvBuf.pBuf;
	SESSION* poSession = (SESSION*)pUD;
	poSession->nWebSocketState = WEBSOCKET_HANDSHAKED;

	SESSION* pSession = (SESSION*)pUD;
	NSNetEvent::EVENT oEvent;
	oEvent.pNet = this;
	oEvent.uEventType = NSNetEvent::eEVT_HANDSHAKE;
	oEvent.U.oHandShake.nSessionID = pSession->nSessionID;
	GetEventHandler()->SendEvent(oEvent);
	return 0;
}

bool WebSocket::ClientHandShakeReq(int nSessionID)
{
	SESSION* poSession = GetSession(nSessionID);
	if (poSession == NULL || poSession->nWebSocketState == WEBSOCKET_HANDSHAKED)
	{
		return false;
	}
	const char* psRequest = "Sec-WebSocket-Key:uVLnN70S11/d8YnNckqzJQ==0\r\n";
	int nSendLen = (int)strlen(psRequest);
	Packet* poPacket = Packet::Create(nSendLen, 0, __FILE__, __LINE__);
	poPacket->FillData((uint8_t*)psRequest, nSendLen);
	if (ExterNet::SendPacket(nSessionID, poPacket))
	{
		return true;
	}
	poPacket->Release(__FILE__, __LINE__);
	return false;
}

bool WebSocket::DecodeMask(uint8_t* pInData, uint8_t* pOutData, int nLen)
{
	if (oWSHeader.mask_ == 1)
	{
		for (int i = 0; i < nLen; i++)
		{
			int j = i % 4;
			pOutData[i] = pInData[i] ^ oWSHeader.masking_key_[j];
		}
		return true;
	}
	return false;
}

int WebSocket::SplitPacket(HSOCKET nSock, void* pUD, RECVBUF& oRecvBuf, Net* poNet)
{
	SESSION* poSession = (SESSION*)pUD;
	WebSocket* poWebSocket = (WebSocket*)poNet;
	if (poSession->nWebSocketState == WEBSOCKET_UNCONNECT)
	{
		if (poWebSocket->m_bClient)
		{
			return poWebSocket->ServerHandShakeRet(pUD, oRecvBuf);
		}
		else
		{
			return poWebSocket->ServerHandShakeReq(pUD, oRecvBuf);
		}
	}

	int nPackets = 0;
	uint8_t *pSplitPos = NULL;
	uint8_t *pPos = oRecvBuf.pBuf;
	const uint8_t *pPosEnd = oRecvBuf.pPos;
	int nMaxDataSize = oRecvBuf.nSize - sizeof(int) - 14; //14是WEBSOCKET头部最大长度

	for (;;)
	{
		//////取到websock头部信息//////
		oWSHeader.Reset();

		//fin_
		if (pPos >= pPosEnd)
		{
			break;
		}
		oWSHeader.fin_ = (*pPos) >> 7;
		//opcode_
		oWSHeader.opcode_ = (*pPos) & 0x0f;
		pPos++;

		//mask_
		if (pPos >= pPosEnd)
		{
			break;
		}
		oWSHeader.mask_ = (*pPos) >> 7;
		//payload_length_
		oWSHeader.payload_length_ = (*pPos) & 0x7f;
		pPos++;

		//extended payload_length_
		if (oWSHeader.payload_length_ == 126)
		{
			if (pPos + 2 > pPosEnd)
			{
				break;
			}
			uint16_t uLength = 0;
			memcpy(&uLength, pPos, 2);
			pPos += 2;
			oWSHeader.payload_length_ = ntohs(uLength);
		}
		else if (oWSHeader.payload_length_ == 127)
		{
			if (pPos + 8 > pPosEnd)
			{
				break;
			}
			uint64_t uLength = 0;
			memcpy(&uLength, pPos, 8);
			pPos += 8;
			oWSHeader.payload_length_ = NetAPI::N2Hll(uLength);
		}

		//XLog(LEVEL_INFO, "SESSION:%d, WEBSOCKET PROTOCOL FIN:%d OPCODE:%d MASK:%d PAYLOADLEN:%d\n", poSession->nSessionID, oWSHeader.fin_, oWSHeader.opcode_, oWSHeader.mask_, oWSHeader.payload_length_);

		//连接关闭
		if (oWSHeader.opcode_ == 0x8)
		{
			return -1;
		}

		//mask_key_
		if (oWSHeader.mask_ == 1)
		{
			if (pPos + 4 > pPosEnd)
			{
				break;
			}
			for (int i = 0; i < 4; i++)
			{
				oWSHeader.masking_key_[i] = *(pPos + i);
			}
			pPos += 4;
		}


		//////切真正的数据包//////
		uint8_t*pTmpPos = pPos;
		int nSize = (int)(pPosEnd - pPos);
		if (nSize < (int)sizeof(int))
		{
			break;
		}

		int nDataSize = 0;
		uint8_t tmpbuffer[4] = { 0 };
		if (poWebSocket->DecodeMask(pPos, tmpbuffer, sizeof(int)))
		{
			nDataSize = *(int*)tmpbuffer;
		}
		else
		{
			nDataSize = *(int*)pPos;
		}

		if (nDataSize <= 0 || nDataSize > nMaxDataSize)
		{
			XLog(LEVEL_ERROR, "%s: sock:%d illegal packet size:%d max size:%d\n", poNet->GetName(), nSock, nDataSize, nMaxDataSize);
			return -1;
		}
		pPos += sizeof(int);
		if (pPos + nDataSize > pPosEnd)
		{
			break; // Wait for more data
		}
		pPos += nDataSize;
		pSplitPos = pPos;
		nPackets++;

		int nPacketSize = sizeof(int)+nDataSize;
		Packet* poPacket = Packet::Create(nPacketSize + sizeof(INNER_HEADER)* 2, nPACKET_OFFSET_SIZE, __FILE__, __LINE__);
		poPacket->SetMaskingKey(oWSHeader.mask_==1, oWSHeader.masking_key_);
		poPacket->FillData(pTmpPos, nPacketSize);
	
		EXTER_HEADER oExterHeader;
		poPacket->GetExterHeader(oExterHeader, false);
		if (oExterHeader.uCmd == 1025)
		{
			XLog(LEVEL_INFO, "ping splict------ time: %lld packets:%d nodelay:%d sendbuff:%d recvbuff:%d\n"
				, XTime::UnixMSTime(), nPackets, NetAPI::IsNoDelay(nSock), NetAPI::SendBufSize(nSock), NetAPI::ReceiveBufSize(nSock));
		}

		poNet->OnRecvPacket(pUD, poPacket);
	}

	if (nPackets > 0)
	{
		if (pPosEnd > pSplitPos)
		{
			int nRemain = (int)(pPosEnd - pSplitPos);
			memmove(oRecvBuf.pBuf, pSplitPos, nRemain);
			oRecvBuf.pPos = oRecvBuf.pBuf + nRemain;
		}
		else
		{
			oRecvBuf.pPos = oRecvBuf.pBuf;
		}
	}
	return nPackets;
}
