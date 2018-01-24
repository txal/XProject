#include "PacketReader.h"
#include "Include/Logger/Logger.hpp"
#include "Include/Network/Network.hpp"
#include "Common/DataStruct/XMath.h"

PacketReader::PacketReader(Packet* poPacket)
{
	m_pbfBuff = NULL;
	m_nBuffSize = NULL;
	m_nReadedSize = 0;
	if (poPacket != NULL)
	{
		SetPacket(poPacket);
	}
}


void PacketReader::SetPacket(Packet* poPacket)
{
	assert(poPacket != NULL);
	m_nReadedSize = 0;
	m_pbfBuff = poPacket->GetRealData();
	m_nBuffSize = poPacket->GetRealDataSize();
}

uint8_t* PacketReader::GetReadingPos(int nReadSize)
{
	if ((m_nReadedSize + nReadSize) > m_nBuffSize)
	{
		XLog(LEVEL_ERROR, "Read buffer out\n");
		return NULL;
	}
	uint8_t* pbfReadingPos = m_pbfBuff + m_nReadedSize;
	return pbfReadingPos;
}

PacketReader& PacketReader::operator>>(uint8_t& uIntVal8)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(uIntVal8));
	if (pbfReadingPos != NULL)
	{
		uIntVal8 = *(uint8_t*)pbfReadingPos;
		m_nReadedSize += sizeof(uIntVal8);
	}
	return *this;
}

PacketReader& PacketReader::operator>>(uint16_t& uIntVal16)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(uIntVal16));
	if (pbfReadingPos != NULL)
	{
		uIntVal16 = *(uint16_t*)pbfReadingPos;
		m_nReadedSize += sizeof(uIntVal16);
	}
	return *this;
}

PacketReader& PacketReader::operator>>(int16_t& nIntVal16)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(nIntVal16));
	if (pbfReadingPos != NULL)
	{
		nIntVal16 = *(uint16_t*)pbfReadingPos;
		m_nReadedSize += sizeof(nIntVal16);
	}
	return *this;
}

PacketReader& PacketReader::operator>>(uint32_t& uIntVal32)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(uIntVal32));
	if (pbfReadingPos != NULL)
	{
		uIntVal32 = *(uint32_t*)pbfReadingPos;
		m_nReadedSize += sizeof(uIntVal32);
	}
	return *this;
}

PacketReader& PacketReader::operator>>(int32_t& nIntVal32)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(nIntVal32));
	if (pbfReadingPos != NULL)
	{
		nIntVal32 = *(int32_t*)pbfReadingPos;
		m_nReadedSize += sizeof(nIntVal32);
	}
	return *this;
}

PacketReader& PacketReader::operator>>(int64_t& nIntVal64)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(nIntVal64));
	if (pbfReadingPos != NULL)
	{
		nIntVal64 = *(int64_t*)pbfReadingPos;
		m_nReadedSize += sizeof(nIntVal64);
	}
	return *this;
}

PacketReader& PacketReader::operator>>(float& fFloatVal)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(fFloatVal));
	if (pbfReadingPos != NULL)
	{
		fFloatVal = *(float*)pbfReadingPos;
		m_nReadedSize += sizeof(fFloatVal);
	}
	return *this;
}

PacketReader& PacketReader::operator>>(double& fDoubleVal)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(fDoubleVal));
	if (pbfReadingPos != NULL)
	{
		fDoubleVal = *(double*)pbfReadingPos;
		m_nReadedSize += sizeof(fDoubleVal);
	}
	return *this;
}

PacketReader& PacketReader::operator>>(std::string& oStrVal)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(int));
	if (pbfReadingPos != NULL)
	{
		int nStrLen = *(int*)pbfReadingPos;
		m_nReadedSize += sizeof(nStrLen);
		
		pbfReadingPos = GetReadingPos(nStrLen);
		if (pbfReadingPos != NULL)
		{
			oStrVal = std::string((char*)pbfReadingPos, nStrLen);
			m_nReadedSize += nStrLen;
		}
	}
	return *this;
}


PacketReader& PacketReader::ReadStr(const char** psStr, int& nStrLen)
{
	uint8_t* pbfReadingPos = GetReadingPos(sizeof(int));
	if (pbfReadingPos != NULL)
	{
		int nLen = *(int*)pbfReadingPos;
		m_nReadedSize += sizeof(nLen);
		pbfReadingPos = GetReadingPos(nLen);
		if (pbfReadingPos != NULL)
		{
			m_nReadedSize += nLen;
			*psStr = (char*)pbfReadingPos;
			nStrLen = nLen;
		}
	}
	return *this;
}
