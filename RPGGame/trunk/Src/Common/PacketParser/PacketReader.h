#ifndef __PACKET_READER_H__
#define __PACKET_READER_H__

#include "Common/Platform.h"

class Packet;

class PacketReader
{
public:
	PacketReader(Packet* poPacket = NULL);
	void SetPacket(Packet* poPacket);
	PacketReader& operator>>(uint8_t& uIntVal8);
	PacketReader& operator>>(uint16_t& uIntVal16);
	PacketReader& operator>>(int16_t& nIntVal16);
	PacketReader& operator>>(uint32_t& uIntVal32);
	PacketReader& operator>>(int32_t& nIntVal32);
	PacketReader& operator>>(int64_t& nIntVal64);
	PacketReader& operator>>(float& fFloatVal);
	PacketReader& operator>>(double& fDoubleVal);
	PacketReader& operator>>(std::string& oStrVal);
	PacketReader& ReadStr(const char** psStr, int& nStrLen);

protected:
	uint8_t* GetReadingPos(int nReadSize);

private:
	int m_nBuffSize;
	uint8_t* m_pbfBuff;
	int m_nReadedSize;
	DISALLOW_COPY_AND_ASSIGN(PacketReader);
};

#endif