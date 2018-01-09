#ifndef __PACKET_H__
#define __PACKET_H__

#include "Common/Platform.h"

const int nPACKET_OFFSET_SIZE = 4;			//packet len(4)
const int nPACKET_DEFAULT_SIZE = 128;		//packet default size
const int nPACKET_MAX_SIZE = 0xFFFF + 1;	//pack max size

struct EXTER_HEADER 
{
	uint16_t uCmd;
	int8_t nSrc;
	int8_t nTar;
	uint32_t uIdx;
	EXTER_HEADER(uint16_t _uCmd = 0, int8_t _nSrc = 0, int8_t _nTar = 0, uint32_t _uIdx = 0)
	{
		uCmd = _uCmd;
		nSrc = _nSrc;
		nTar = _nTar;
		uIdx = _uIdx;
	}
};

struct INNER_HEADER 
{
	uint16_t uCmd;	
	int8_t nSrc;
	int8_t nTar;
	uint16_t uServer;      //目的服务器ID
	uint16_t uSessions;    //目的会话ID
	INNER_HEADER(uint16_t _uCmd = 0, int8_t _nSrc = 0, int8_t _nTar = 0, uint16_t _uSessions = 0, uint16_t _uServer = 0)
	{
		uCmd = _uCmd;
		nSrc = _nSrc;
		nTar = _nTar;
		uServer = _uServer;
		uSessions = _uSessions;
	}
};

class Packet
{
public:
	static Packet* Create(int nSize = nPACKET_DEFAULT_SIZE, int nOffset = nPACKET_OFFSET_SIZE);

	void Reset();
	void Retain();
	void Release();

	int16_t  GetRef() { return m_nRef; }
	uint8_t* GetData() { return m_pData; }
	int GetDataSize() { return m_nDataSize; }
	uint8_t* GetRealData() { return m_pData + m_nOffsetSize; }
	int GetRealDataSize() { return m_nDataSize - m_nOffsetSize; }

public:
	Packet* DeepCopy();
	void Move(int nLen);
	void CutData(int nSize);
	bool WriteBuf(const void* pBuf, int nSize);
	void FillData(const uint8_t* pVal, int nSize);

	int  GetSentSize() { return m_nSentSize; }
	void SetSentSize(int nSize) { m_nSentSize = nSize; }
	void SetDataSize(int nSize) { assert(nSize >= 0 && nSize <= m_nCapacity); m_nDataSize = nSize; }

	int8_t IsMasking() { return m_nMasking; }
	uint8_t* GetMaskingKey() { return m_tMaskingKey; }
	void SetMaskingKey(bool bMasking, uint8_t* pKey) { if (bMasking) { m_nMasking = 1;  memcpy(m_tMaskingKey, pKey, 4); } }
	int WebSocketMark() { if (m_nWebSocketMark == 0) { m_nWebSocketMark = 1; return 0; } return 1; }

public:
	bool GetExterHeader(EXTER_HEADER& oExterHeader, bool bRemove);
	void AppendExterHeader(const EXTER_HEADER& oExterHeader);
	void RemoveExterHeader();
	bool GetInnerHeader(INNER_HEADER& oInnerHeader, int** ppnSessionOffset, bool bRemove);
	void AppendInnerHeader(const INNER_HEADER& oInnerHeader, const int* pnSessionArray, int nSessions);
	void RemoveInnerHeader();

public:
    bool CheckAndExpand(int nAppendSize);

private:
	Packet(int nSize, int nOffset);
	~Packet() { SAFE_FREE(m_pData); }

private:
    uint8_t* m_pData;
    int m_nCapacity;
    int m_nDataSize;
	int m_nSentSize;
	int8_t m_nOffsetSize;
	int8_t m_nWebSocketMark;
	volatile short m_nRef;

	int8_t m_nMasking;
	uint8_t m_tMaskingKey[4]; //Websocket mask 长度在切包的时候解码,真正数据放到网关解码;
	DISALLOW_COPY_AND_ASSIGN(Packet);
};

#endif
