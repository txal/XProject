#ifndef __REDIS_H__
#define __REDIS_H__

#ifdef __linux

#include "hiredis.h"
#include "LibLogger/LibLogger.h"

/* Redis define
#define REDIS_REPLY_STRING 1
#define REDIS_REPLY_ARRAY 2
#define REDIS_REPLY_INTEGER 3
#define REDIS_REPLY_NIL 4
#define REDIS_REPLY_STATUS 5
#define REDIS_REPLY_ERROR 6
*/

const int nREDIS_MAX_REPLY = 16;

class RedisDriver
{
public:
    RedisDriver();
    virtual ~RedisDriver();

public:
	bool Connect(const char* pIP, uint16_t nPort, const char* pPwd, int nTimeOut);
	bool Query(const char* pCmd);

	bool AppendQuery(const char* pCmd, uint16_t& nCmdCount);
	bool GetReplies(uint16_t nCmdCount);

	int ElemNum();
	int ElemType(int nElemIdx);
	bool FetchRow();

	int ToInt32(int nElemIdx);	
	int64_t ToInt64(int nElemIdx);
	const char* ToString(int nElemIdx);

private:
	bool Reconnect();
	bool CheckIndex();
	void FreeReplies();
	void DumpReplyErr();

private:
	char m_sIP[128];
	uint16_t m_nPort;
	char m_sPwd[32];
	int m_nConnTimeout;

	redisContext* m_pContext;
	redisReply* m_pReplyArray[nREDIS_MAX_REPLY];
	int16_t m_nFetchIndex;
	uint16_t m_nReplyCount;

	char m_sConvBuf[32];
	DISALLOW_COPY_AND_ASSIGN(RedisDriver);
};

#endif

#endif