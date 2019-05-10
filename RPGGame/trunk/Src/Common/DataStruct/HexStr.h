#ifndef __HEX_STR_H__
#define __HEX_STR_H__

#include "Common/Platform.h"

namespace HexStr
{
	static int ByteToHexStr(const unsigned char* source, char* dest, int sourceLen)
	{
		short i;
		unsigned char highByte, lowByte;

		for (i = 0; i < sourceLen; i++)
		{
			highByte = source[i] >> 4;
			lowByte = source[i] & 0x0f;

			highByte += 0x30;

			if (highByte > 0x39)
				dest[i * 2] = highByte + 0x07;
			else
				dest[i * 2] = highByte;

			lowByte += 0x30;
			if (lowByte > 0x39)
				dest[i * 2 + 1] = lowByte + 0x07;
			else
				dest[i * 2 + 1] = lowByte;
		}
		return sourceLen * 2;
	}

	static int HexStrToByte(const char* source, unsigned char* dest, int sourceLen)
	{
		short i;
		unsigned char highByte, lowByte;

		for (i = 0; i < sourceLen; i += 2)
		{
			highByte = toupper(source[i]);
			lowByte = toupper(source[i + 1]);

			if (highByte > 0x39)
				highByte -= 0x37;
			else
				highByte -= 0x30;

			if (lowByte > 0x39)
				lowByte -= 0x37;
			else
				lowByte -= 0x30;

			dest[i / 2] = (highByte << 4) | lowByte;
		}
		return sourceLen / 2;
	}
}

#endif
