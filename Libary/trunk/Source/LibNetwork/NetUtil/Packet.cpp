#include "Include/Logger/Logger.h"
#include "Include/Network/Packet.h"
#include "Common/DataStruct/Atomic.h"

MutexLock Packet::m_oLock;
volatile uint32_t Packet::m_uTotalPacket = 0;
Packet::PacketLogMap Packet::m_oPacketLogMap;

Packet* Packet::Create(int nSize/*=nPACKET_DEFAULT_SIZE*/, int nOffset/*=nPACKET_OFFSET_SIZE*/, const char* file /*=""*/, int line /*= 0*/)
{
	static uint32_t uPacketIndex = 0;
	if (nSize < nOffset || nSize > nPACKET_MAX_SIZE) 
	{
		XLog(LEVEL_ERROR, "Packet size out of range:%d [%d,%d]\n", nSize, nOffset, nPACKET_MAX_SIZE);
		return NULL;
	}

	uint32_t uPacketID = atomic_inc(&uPacketIndex);

	Packet* poPacket = XNEW(Packet)(nSize, nOffset, uPacketID);
	if (poPacket == NULL)
	{
		XLog(LEVEL_ERROR, "Memory out!!\n");
		return NULL;
	}

	atomic_inc(&m_uTotalPacket);

	//PACK_LOG log;
	//log.nCreateTime = (int)time(0);
	//log.nLine = line;
	//log.oFile = file;

	//m_oLock.Lock();
	//m_oPacketLogMap[uPacketID] = log;
	//m_oLock.Unlock();

	return poPacket;
}

Packet::Packet(int nSize, int nOffset, uint32_t uPacketIndex)
{
	m_nCapacity = nSize;
	m_nOffsetSize = (int8_t)nOffset;

	m_nCapacity = (m_nCapacity + 7) & ~(unsigned)7;
	m_nCapacity = m_nCapacity > nPACKET_MAX_SIZE ? nPACKET_MAX_SIZE : m_nCapacity;

    m_pData = (uint8_t*)XALLOC(NULL, m_nCapacity);
	m_nDataSize = m_nOffsetSize;
    *(int*)m_pData = 0;

	m_nSentSize = 0;
	m_nWebSocketMark = 0;
	m_nRef = 1;

	m_nMasking = 0;
	memset(m_tMaskingKey, 0, sizeof(m_tMaskingKey));

	m_uPacketID = uPacketIndex;
}

void Packet::DumpLeak()
{
	int nTimeNow = time(0);
	XLog(LEVEL_INFO, "packet current:\n");

	m_oLock.Lock();
	for (PacketLogIter iter = m_oPacketLogMap.begin(); iter != m_oPacketLogMap.end(); iter++)
	{
		if (nTimeNow - iter->second.nCreateTime >= 300)
		{
			XLog(LEVEL_INFO, "id=%u time=%d cmd=%d src-srv=%d src-sri=%d tar-srv=%d tar-sri=%d ssn=%d file=%s line=%d digest=%s\n"
				, iter->first, iter->second.nCreateTime, iter->second.oHeader.uCmd,iter->second.oHeader.uSrcServer, iter->second.oHeader.nSrcService
				, iter->second.oHeader.uTarServer, iter->second.oHeader.nTarService, iter->second.oHeader.uSessionNum
				, iter->second.oFile.c_str(), iter->second.nLine, iter->second.oDigest.c_str());
		}
	}
	m_oLock.Unlock();
}

void Packet::Release(const char* file/*=""*/, int line/*=0*/)
{
	int nRef = atomic_dec16(&m_nRef);
	if (nRef <= 0)
	{
		atomic_dec(&m_uTotalPacket);
		delete this;

		//m_oLock.Lock();
		//m_oPacketLogMap.erase(m_uPacketID);
		//m_oLock.Unlock();
	}
}

void Packet::Retain()
{
	atomic_inc16(&m_nRef);
}

void Packet::Reset() 
{
	m_nRef = 1;
	m_nSentSize = 0;
	m_nDataSize = m_nOffsetSize;
	*(int*)m_pData = 0;
}

bool Packet::Reserve(int nSize)
{
	if (m_nCapacity >= nSize)
	{
		return true;
	}
	return CheckAndExpand(nSize - m_nDataSize);
}

bool Packet::CheckAndExpand(int nAppendSize)
{
	int nCapacity = m_nCapacity;
	int nNewSize = m_nDataSize + nAppendSize;
	if (nNewSize <= nCapacity)
	{
		return true;
	}
	if (nNewSize > nPACKET_MAX_SIZE)
	{
		XLog(LEVEL_ERROR, "Pack out of size:%d/%d\n", nNewSize, nPACKET_MAX_SIZE);
		return false;
	}
	while (nNewSize > nCapacity)
	{
		nCapacity *= 2;
	}
	nCapacity = (nCapacity + 7) & ~(unsigned)7;
	nCapacity = nCapacity > nPACKET_MAX_SIZE ? nPACKET_MAX_SIZE : nCapacity;
#ifdef _DEBUG
	XLog(LEVEL_INFO, "Packet expand:%d->%d\n", m_nCapacity, nCapacity);
#endif
	if (nCapacity == m_nCapacity)
	{
		return false;
	}
    m_nCapacity = nCapacity;
    m_pData = (uint8_t*)XALLOC(m_pData, m_nCapacity);
	assert(m_pData != NULL);
    return true;
}

bool Packet::WriteBuf(const void* pBuf, int nSize)
{
    if (!CheckAndExpand(nSize))
    {
    	return false;
    }
	uint8_t* pPos = m_pData + m_nDataSize;
	memcpy(pPos, pBuf, nSize);
	m_nDataSize += nSize;
	*(int*)m_pData += nSize;
	return true;
}

void Packet::Move(int nSize)
{
    assert(nSize > 0);
    int nOffset = m_nDataSize - nSize;
	if (nOffset <= 0)
	{
        return;
	}
    memmove(m_pData, m_pData + nOffset, nSize);
    m_nDataSize = nSize;
}

Packet* Packet::DeepCopy(const char* file/*=""*/, int line/*=0*/)
{
    Packet* poPacket = Create(m_nCapacity, m_nOffsetSize, file, line);
	if (poPacket == NULL)
	{
		return poPacket;
	}
    memcpy(poPacket->m_pData, m_pData, m_nDataSize);
    poPacket->m_nDataSize = m_nDataSize;
    poPacket->m_nSentSize = m_nSentSize;
    return poPacket;
}

void Packet::FillData(const uint8_t* pVal, int nSize)
{
    assert(pVal != NULL || nSize > 0);
	if (!CheckAndExpand(nSize - m_nDataSize))
	{
		return;
	}
	memcpy(m_pData, pVal, nSize);
	m_nDataSize = nSize;
}

void Packet::CutData(int nSize)
{
	if (nSize > m_nDataSize - nPACKET_OFFSET_SIZE)
	{
		return;
	}
	m_nDataSize -= nSize;
	*(int*)m_pData -= nSize;
}

bool Packet::GetExterHeader(EXTER_HEADER& oExterHeader, bool bRemove)
{
	int nHeaderSize = sizeof(oExterHeader);
	int nRealDataSize = m_nDataSize - m_nOffsetSize;
	if (nRealDataSize < nHeaderSize)
	{
        return false;
	}
	uint8_t* pHeaderPos = m_pData + m_nDataSize - nHeaderSize;
	oExterHeader = *(EXTER_HEADER*)pHeaderPos;
	if (bRemove)
    {
    	m_nDataSize -= nHeaderSize;
		*(int*)(m_pData) -= nHeaderSize;
	}
	return true;
}

void Packet::AppendExterHeader(const EXTER_HEADER& oExterHeader)
{
	int nHeaderSize = sizeof(oExterHeader);
	if (!CheckAndExpand(nHeaderSize))
	{
		return;
	}
    uint8_t* pHeaderPos = m_pData + m_nDataSize;
	*(EXTER_HEADER*)pHeaderPos = oExterHeader;
	m_nDataSize += nHeaderSize;
	*(int*)m_pData += nHeaderSize;
}

void Packet::RemoveExterHeader()
{
	int nHeaderSize = sizeof(EXTER_HEADER);
	int nRealDataSize = m_nDataSize - m_nOffsetSize;
	if (nRealDataSize < nHeaderSize)
	{
        return;
	}
	m_nDataSize -= nHeaderSize;
	*(int*)(m_pData) -= nHeaderSize;
}

bool Packet::GetInnerHeader(INNER_HEADER& oInnerHeader, int** ppnSessionOffset, bool bRemove)
{
	int nHeaderSize = sizeof(oInnerHeader);
	int nRealDataSize = m_nDataSize - m_nOffsetSize;
	if (nRealDataSize < nHeaderSize)
	{
		return false;
	}
	uint8_t* pHeaderPos = m_pData + m_nDataSize - nHeaderSize;
	oInnerHeader = *(INNER_HEADER*)pHeaderPos;
	if (ppnSessionOffset != NULL && oInnerHeader.uSessionNum > 0)
    {
		*ppnSessionOffset = (int*)(pHeaderPos - oInnerHeader.uSessionNum * sizeof(int));
	}
	if (bRemove) 
    {
		int nTotalHeaderSize = nHeaderSize + oInnerHeader.uSessionNum * sizeof(int);
		m_nDataSize -= nTotalHeaderSize;
		*(int*)m_pData -= nTotalHeaderSize;
	}

	//m_oLock.Lock();
	//PacketLogIter iter = m_oPacketLogMap.find(m_uPacketID);
	//if (iter != m_oPacketLogMap.end())
	//{
	//	iter->second.oHeader = oInnerHeader;
	//	iter->second.oDigest = std::string((char*)GetRealData(), GetRealDataSize());
	//}
	//m_oLock.Unlock();
	return true;
}

void Packet::AppendInnerHeader(const INNER_HEADER& oInnerHeader, const int* pnSessionArray, int nSessions)
{
	if (nSessions > 0) assert(pnSessionArray != NULL);
	int nHeaderSize = sizeof(oInnerHeader);
	int nSessionSize = nSessions * sizeof(int);
	int nTotalHeaderSize = nHeaderSize + nSessionSize;
	if (!CheckAndExpand(nTotalHeaderSize))
	{
		return;
	}
	if (pnSessionArray != NULL && nSessions > 0) 
    {
    	uint8_t* puSessionPos = m_pData + m_nDataSize;
		memcpy(puSessionPos, pnSessionArray, nSessionSize);
		m_nDataSize += nSessionSize;
	}
	uint8_t* pHeaderPos = m_pData + m_nDataSize;
	*(INNER_HEADER*)pHeaderPos = oInnerHeader;
	m_nDataSize += nHeaderSize;
	*(int*)m_pData += nTotalHeaderSize;

	//m_oLock.Lock();
	//PacketLogIter iter = m_oPacketLogMap.find(m_uPacketID);
	//if (iter != m_oPacketLogMap.end())
	//{
	//	iter->second.oHeader = oInnerHeader;
	//	iter->second.oDigest = std::string((char*)GetRealData(), GetRealDataSize());
	//}
	//m_oLock.Unlock();
}

void Packet::RemoveInnerHeader()
{
	int nHeaderSize = sizeof(INNER_HEADER);
	int nRealDataSize = m_nDataSize - m_nOffsetSize;
	if (nRealDataSize < nHeaderSize)
	{
		return;
	}
	uint8_t* pHeaderPos = m_pData + m_nDataSize - nHeaderSize;
	INNER_HEADER oInnerHeader = *(INNER_HEADER*)pHeaderPos;
	int nTotalHeaderSize = nHeaderSize + oInnerHeader.uSessionNum * sizeof(int);
	m_nDataSize -= nTotalHeaderSize;
	*(int*)m_pData -= nTotalHeaderSize;

	//m_oLock.Lock();
	//PacketLogIter iter = m_oPacketLogMap.find(m_uPacketID);
	//if (iter != m_oPacketLogMap.end())
	//{
	//	iter->second.oHeader = oInnerHeader;
	//	iter->second.oDigest = std::string((char*)GetRealData(), GetRealDataSize());
	//}
	//m_oLock.Unlock();
}
