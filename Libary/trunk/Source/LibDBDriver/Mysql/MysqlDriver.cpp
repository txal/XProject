#include "Include/DBDriver/MysqlDriver.h"
#include "Include/Logger/Logger.h"

MysqlDriver::MysqlDriver()
{
	m_pMysql = NULL;
	m_pMysqlRes = NULL;
	m_pMysqlRow = NULL;

	m_nFieldCount = 0;
	m_pMysqlFields = NULL;
}

MysqlDriver::~MysqlDriver()
{
	XLog(LEVEL_INFO, "MysqlDriver destruct!\n");
    if (m_pMysql != NULL)
    {
        mysql_close(m_pMysql);
		mysql_thread_end();
    }
    if (m_pMysqlRes != NULL)
    {
        mysql_free_result(m_pMysqlRes);
    }
}

bool MysqlDriver::Connect(const char* pHost, uint16_t nPort, const char* pDB, const char* pUsr, const char* pPwd, const char* pCharset)
{
	if (m_pMysql != NULL)
	{
		mysql_close(m_pMysql);
	}
	m_pMysql = mysql_init(NULL);
	if (m_pMysql == NULL)
	{
		XLog(LEVEL_ERROR, "Mysql init fail\n");
		return false;
	}

	my_bool bReconnect = true;
	int nQueryTimeOut = MYSQL_QUERY_TIMEOUT;
	int nConnectTimeOut = MYSQL_CONN_TIMEOUT;
	mysql_options(m_pMysql, MYSQL_OPT_CONNECT_TIMEOUT, (char*)&nConnectTimeOut); 
	mysql_options(m_pMysql, MYSQL_OPT_WRITE_TIMEOUT, (char*)&nQueryTimeOut); 
	mysql_options(m_pMysql, MYSQL_OPT_READ_TIMEOUT, (char*)&nQueryTimeOut); 
	mysql_options(m_pMysql, MYSQL_OPT_RECONNECT, (char*)&bReconnect); 

	if (!mysql_real_connect(m_pMysql, pHost, pUsr, pPwd, pDB, nPort, NULL, CLIENT_COMPRESS | CLIENT_MULTI_RESULTS | CLIENT_MULTI_STATEMENTS))
	{
		XLog(LEVEL_ERROR, "Mysql connect error: %s\n", mysql_error(m_pMysql));
		return false;
	}
	if (mysql_set_character_set(m_pMysql, pCharset))
	{
		XLog(LEVEL_ERROR, "Mysql set charset error: %s\n", mysql_error(m_pMysql));
		mysql_close(m_pMysql);
		m_pMysql = NULL;
		return false;
	}

	return true;
}

bool MysqlDriver::Query(const char* pCmd)
{
	if (m_pMysql == NULL)
	{
		XLog(LEVEL_ERROR, "Mysql not init yet\n");
		return false;
	}
	if (m_pMysqlRes != NULL)
	{
		mysql_free_result(m_pMysqlRes);
		m_pMysqlRes = NULL;
	}
	m_pMysqlRow	= NULL;
	m_pMysqlFields = NULL;

	//多线程环境下需要调用mysql_thread_init,否则触发重连会崩溃
	mysql_thread_init();
	if (mysql_query(m_pMysql, pCmd))
	{
		mysql_thread_end();
		XLog(LEVEL_ERROR, "%s(%s)\n", mysql_error(m_pMysql), pCmd);
		return false;
	}
	mysql_thread_end();

	int nStatus = 0;
	bool bResult = true;
	do
	{
		MYSQL_RES* pMysqlRes = mysql_store_result(m_pMysql);
		if (pMysqlRes != NULL)
		{
			if (m_pMysqlRes != NULL)
			{
				mysql_free_result(m_pMysqlRes);
				m_pMysqlRes = NULL;
			}
			m_pMysqlRes = pMysqlRes;
			m_nFieldCount = mysql_num_fields(m_pMysqlRes);
			m_pMysqlFields = mysql_fetch_fields(m_pMysqlRes);
		}
		else if (mysql_field_count(m_pMysql) != 0)
		{
			XLog(LEVEL_ERROR, "%s(%s)\n", mysql_error(m_pMysql), pCmd);
			bResult = false;
			break;
		}
		if ((nStatus = mysql_next_result(m_pMysql)) > 0)
		{
			XLog(LEVEL_ERROR, "%s(%s)\n", mysql_error(m_pMysql), pCmd);
			bResult = false;
			break;
		}
	} while (nStatus == 0);
	return bResult;
}

int MysqlDriver::NumRows()
{
	if (m_pMysqlRes != NULL)
	{
		return (int)mysql_num_rows(m_pMysqlRes);
	}
	return 0;
}

int MysqlDriver::AffectedRows()
{
	if (m_pMysqlRes != NULL)
	{
		return (int)mysql_affected_rows(m_pMysql);
	}
	return 0;
}

bool MysqlDriver::FetchRow()
{
	if (m_pMysqlRes != NULL)
	{
		m_pMysqlRow = mysql_fetch_row(m_pMysqlRes);
		return (m_pMysqlRow != NULL);
	}
	return false;
}

int MysqlDriver::InsertID()
{
	if (m_pMysql != NULL)
	{
		return (int)mysql_insert_id(m_pMysql);
	}
	return 0;
}

int MysqlDriver::ToInt32(const char* pColumn)
{
	if (m_pMysqlRow == NULL)
	{
		XLog(LEVEL_ERROR, "No data, not fetchrow?\n");
		return 0;
	}
	for (int i = 0; i < m_nFieldCount; i++)
	{
		if (strcmp(m_pMysqlFields[i].name, pColumn) == 0)
		{
			return atoi(m_pMysqlRow[i]);
		}
	}
	XLog(LEVEL_ERROR, "Field '%s' not found\n", pColumn);
	return 0;
}

int64_t MysqlDriver::ToInt64(const char* pColumn)
{
	if (m_pMysqlRow == NULL)
	{
		XLog(LEVEL_ERROR, "No data, not fetchrow?\n");
		return 0;
	}
	for (int i = 0; i < m_nFieldCount; i++)
	{
		if (strcmp(m_pMysqlFields[i].name, pColumn) == 0)
		{
			return (int64_t)atoll(m_pMysqlRow[i]);
		}
	}
	XLog(LEVEL_ERROR, "Field '%s' not found\n", pColumn);
	return 0;
}

double MysqlDriver::ToDouble(const char* pColumn)
{
	if (m_pMysqlRow == NULL)
	{
		XLog(LEVEL_ERROR, "No data, not fetchrow?\n");
		return 0;
	}
	for (int i = 0; i < m_nFieldCount; i++)
	{
		if (strcmp(m_pMysqlFields[i].name, pColumn) == 0)
		{
			return atof(m_pMysqlRow[i]);
		}
	}
	XLog(LEVEL_ERROR, "Field '%s' not found\n", pColumn);
	return 0;
}

const char* MysqlDriver::ToString(const char* pColumn)
{
	if (m_pMysqlRow == NULL)
	{
		XLog(LEVEL_ERROR, "No data, not fetchrow?\n");
		return "";
	}
	for (int i = 0; i < m_nFieldCount; i++)
	{
		if (strcmp(m_pMysqlFields[i].name, pColumn) == 0)
		{
			return m_pMysqlRow[i];
		}
	}
	XLog(LEVEL_ERROR, "Field '%s' not found\n", pColumn);
	return "";
}