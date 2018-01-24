#ifndef __PACKET_WRITER_H__
#define __PACKET_WRITER_H__

#include "Common/Platform.h"

class Packet;

class PacketWriter
{
public:
	PacketWriter(Packet* poPacket = NULL);
	void SetPacket(Packet* poPacket);
	PacketWriter& operator<<(uint8_t uInt8);
	PacketWriter& operator<<(uint16_t uInt16);
	PacketWriter& operator<<(int16_t nInt16);
	PacketWriter& operator<<(uint32_t uInt32);
	PacketWriter& operator<<(int32_t nInt32);
	PacketWriter& operator<<(int64_t nInt64);
	PacketWriter& operator<<(float fFloat);
	PacketWriter& operator<<(double fDouble);
	PacketWriter& operator<<(std::string& osVal);
	PacketWriter& operator<<(const char* psVal);
	PacketWriter& WriteStr(const char* psVal, int nLen);

private:
	Packet* m_poPacket;
	DISALLOW_COPY_AND_ASSIGN(PacketWriter);
};

#endif