#ifndef __OBJID_H__
#define __OBJID_H__

#include "Common/Platform.h"
#include "Common/DataStruct/XMath.h"

#define GUID_LEN 64  
#ifdef _WIN32
	static const char* GenUUID()
	{
		static char sBuffer[GUID_LEN] = { 0 };
		memset(sBuffer, sizeof(sBuffer), 0);

		GUID guid;
		if (CoCreateGuid(&guid))
			return NULL;

		snprintf(sBuffer, sizeof(sBuffer), "%08X-%04X-%04x-%02X%02X-%02X%02X%02X%02X%02X%02X",
			guid.Data1, guid.Data2, guid.Data3,
			guid.Data4[0], guid.Data4[1], guid.Data4[2],
			guid.Data4[3], guid.Data4[4], guid.Data4[5],
			guid.Data4[6], guid.Data4[7]);
		return sBuffer;
	}
#else
	#include <uuid/uuid.h>  
	static const char* GenUUID()
	{
		static char sBuffer[GUID_LEN] = { 0 };
		memset(sBuffer, sizeof(sBuffer), 0);

		uuid_t uu;
		uuid_generate(uu);
		snprintf("%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X-%02X"
			, uu[0], uu[1], uu[2], uu[3], uu[4], uu[5], uu[6], uu[7], uu[8], uu[9], uu[10], uu[11], uu[12], uu[13], uu[14], uu[15]);
		return sBuffer;
	}
#endif

#endif