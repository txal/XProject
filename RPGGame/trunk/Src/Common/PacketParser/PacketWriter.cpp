#include "PacketWriter.h"
#include "Include/Logger/Logger.hpp"
#include "Include/Network/Network.hpp"

PacketWriter::PacketWriter(Packet* poPacket)
{
	m_poPacket = poPacket;
}

void PacketWriter::SetPacket(Packet* poPacket)
{
	assert(poPacket != NULL);
	m_poPacket = poPacket;
}

PacketWriter& PacketWriter::operator<<(uint8_t uInt8)
{
	m_poPacket->WriteBuf(&uInt8, sizeof(uInt8));
	return *this;
}

PacketWriter& PacketWriter::operator<<(uint16_t uInt16)
{
	m_poPacket->WriteBuf(&uInt16, sizeof(uInt16));
	return *this;
}

PacketWriter& PacketWriter::operator<<(int16_t nInt16)
{
	m_poPacket->WriteBuf(&nInt16, sizeof(nInt16));
	return *this;
}

PacketWriter& PacketWriter::operator<<(uint32_t uInt32)
{
	m_poPacket->WriteBuf(&uInt32, sizeof(uInt32));
	return *this;
}

PacketWriter& PacketWriter::operator<<(int32_t nInt32)
{
	m_poPacket->WriteBuf(&nInt32, sizeof(nInt32));
	return *this;
}

PacketWriter& PacketWriter::operator<<(int64_t nInt64)
{
	m_poPacket->WriteBuf(&nInt64, sizeof(nInt64));
	return *this;
}

PacketWriter& PacketWriter::operator<<(float fFloat)
{
	m_poPacket->WriteBuf(&fFloat, sizeof(fFloat));
	return *this;
}

PacketWriter& PacketWriter::operator<<(double fDouble)
{
	m_poPacket->WriteBuf(&fDouble, sizeof(fDouble));
	return *this;
}

PacketWriter& PacketWriter::operator<<(std::string& osVal)
{
	int nLen = (int)osVal.size();
	m_poPacket->WriteBuf(&nLen, sizeof(nLen));
	m_poPacket->WriteBuf(osVal.data(), nLen);
	return *this;
}

PacketWriter& PacketWriter::operator<<(const char* psVal)
{
	int nLen = (int)strlen(psVal);
	WriteStr(psVal, nLen);
	return *this;
}

PacketWriter& PacketWriter::WriteStr(const char* psVal, int nLen)
{
	m_poPacket->WriteBuf(&nLen, sizeof(nLen));
	m_poPacket->WriteBuf(psVal, nLen);
	return *this;	
}


