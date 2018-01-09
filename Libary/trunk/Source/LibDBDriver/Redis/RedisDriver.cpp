#include "Include/DBDriver/RedisDriver.h"

#ifdef __linux

RedisDriver::RedisDriver()
{
	m_sIP[0] = '\0';
	m_sPwd[0] = '\0';
	m_nPort = 0;
	m_nConnTimeout = 0;

	m_pContext = NULL;
	m_nFetchIndex = -1;
	m_nReplyCount = 0;
	memset(m_pReplyArray, 0, sizeof(m_pReplyArray));

	m_sConvBuf[0] = '\0';
}

RedisDriver::~RedisDriver()
{
	FreeReplies();
	if (m_pContext != NULL)
	{
		redisFree(m_pContext);
	}
}

bool RedisDriver::Connect(const char* pIP, uint16_t nPort, const char* pPwd, int nTimeout)
{
	assert(pIP != NULL && pPwd != NULL);

	strcpy(m_sIP, pIP);
	strcpy(m_sPwd, pPwd);
	m_nPort = nPort;
	m_nConnTimeout = nTimeout;

	struct timeval tv = {m_nConnTimeout, 500000}; // nTimeout.5 seconds
	m_pContext = redisConnectWithTimeout(m_sIP, m_nPort, tv);
	if (m_pContext->err)
	{
		XLog(LEVEL_ERROR, "%s\n", m_pContext->errstr);
		return false;
	} 
	char sBuf[32];
	sprintf(sBuf, "Auth %s", m_sPwd);
	return Query(sBuf);
}

bool RedisDriver::Query(const char* pCmd)
{
	redisReply* pReply = (redisReply*)redisCommand(m_pContext, pCmd);
	if (pReply == NULL)
	{
		XLog(LEVEL_ERROR, "%s\n", m_pContext->errstr);
		return false;
	}
	bool bRet = true;
	if (pReply->type == REDIS_REPLY_ERROR)
	{
		bRet = false;
		XLog(LEVEL_ERROR, "%s\n", pReply->str);
	}
	freeReplyObject(pReply);
	return bRet;
}

bool RedisDriver::AppendQuery(const char* pCmd, uint16_t& nCmdCount)
{
	assert(m_pContext != NULL);
	if (redisAppendCommand(m_pContext, pCmd) != REDIS_OK)
	{
		DumpReplyErr();
		return false;
	}
	nCmdCount++;
	return true;
}

bool RedisDriver::GetReplies(uint16_t nCmdCount)
{
	FreeReplies();
	if (nCmdCount > nREDIS_MAX_REPLY)
	{
		return false;
	}
	bool bRet = true;
	for (int i = 0; i < nCmdCount; i++)
	{
		if (redisGetReply(m_pContext, (void**)&m_pReplyArray[i]) != REDIS_OK)
		{
			DumpReplyErr();
			bRet = false;
			break;
		}
		m_nReplyCount++;
		switch (m_pReplyArray[i]->type)
		{
			case REDIS_REPLY_ERROR:
			{
				XLog(LEVEL_ERROR, "%s\n", m_pReplyArray[i]->str);
			}
			case REDIS_REPLY_NIL:
			case REDIS_REPLY_STATUS:
			case REDIS_REPLY_STRING:
			case REDIS_REPLY_INTEGER:
			{
				m_pReplyArray[i]->elements = 1;
				m_pReplyArray[i]->element = &m_pReplyArray[i];
				break;
			}
			case REDIS_REPLY_ARRAY:
			{
				break;
			}
		}
	}
	return bRet;
}

bool RedisDriver::FetchRow()
{
	if (m_nReplyCount <= 0 || m_nFetchIndex >= m_nReplyCount - 1)
	{
		return false;
	}
	m_nFetchIndex++;
	return true;
}

int RedisDriver::ElemNum()
{
	if (!CheckIndex())
	{
		return 0;
	}
	return m_pReplyArray[m_nFetchIndex]->elements;
}

int RedisDriver::ElemType(int nElemIndex)
{
	if (!CheckIndex())
	{
		return 0;
	}
	redisReply* pReply = m_pReplyArray[m_nFetchIndex]->element[nElemIndex];
	return pReply->type;
}

int RedisDriver::ToInt32(int nElemIndex)
{
	if (!CheckIndex())
	{
		return 0;
	}
	redisReply* pReply = m_pReplyArray[m_nFetchIndex]->element[nElemIndex];
	if (pReply->type == REDIS_REPLY_INTEGER)
	{
		return (int)pReply->integer;
	}
	else
	{
		return atoi(pReply->str ? pReply->str : "");
	}
}

int64_t RedisDriver::ToInt64(int nElemIndex)
{
	if (!CheckIndex())
	{
		return 0;
	}
	redisReply* pReply = m_pReplyArray[m_nFetchIndex]->element[nElemIndex];
	if (pReply->type == REDIS_REPLY_INTEGER)
	{
		return (int64_t)pReply->integer;
	}
	else
	{
		return (int64_t)atoll(pReply->str ? pReply->str : "");
	}
}

const char* RedisDriver::ToString(int nElemIndex)
{
	redisReply* pReply = m_pReplyArray[m_nFetchIndex]->element[nElemIndex];
	if (pReply->type == REDIS_REPLY_INTEGER)
	{
		sprintf(m_sConvBuf, "%lld", pReply->integer);
		return m_sConvBuf;
	}
	else
	{
		return pReply->str;
	}
}

bool RedisDriver::CheckIndex()
{
	if (m_nFetchIndex < 0 || m_nFetchIndex >= m_nReplyCount)
	{
		XLog(LEVEL_ERROR, "[Redis]: no replay data\n");
		return false;
	}
	return true;
}

void RedisDriver::FreeReplies()
{
	for (int i = 0; i < m_nReplyCount; i++)
	{
		freeReplyObject(m_pReplyArray[i]);
	}
	m_nFetchIndex = -1;
	m_nReplyCount = 0;
}

bool RedisDriver::Reconnect()
{
	if (m_pContext != NULL)
	{
		redisFree(m_pContext);
		m_pContext = NULL;
	}
	XLog(LEVEL_ERROR, "[Redis]: reconnecting...\n");
	return Connect(m_sIP, m_nPort, m_sPwd, m_nConnTimeout);
}

void RedisDriver::DumpReplyErr()
{
	switch (m_pContext->err)
	{
		case REDIS_ERR_PROTOCOL:
		{
			XLog(LEVEL_ERROR, "%s\n", m_pContext->errstr);
			break;
		}
		case REDIS_ERR_IO:
		case REDIS_ERR_EOF:
		case REDIS_ERR_OOM:
		case REDIS_ERR_OTHER:
		{
			XLog(LEVEL_ERROR, "Redis disconnected\n");
			Reconnect();	
			break;
		}
	}
}

#endif