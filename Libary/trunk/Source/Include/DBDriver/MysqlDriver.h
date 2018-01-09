#ifndef __MYSQLDRIVER_H__
#define __MYSQLDRIVER_H__

#include "Common/Platform.h"
#include "Include/DBDriver/mysql/mysql.h"

#define MYSQL_CONN_TIMEOUT	30 //Second
#define MYSQL_QUERY_TIMEOUT 10000 //Millisecond
#define MYSQL_MAX_STRINGLEN	2048 //Max string value len
#define MYSQL_MAX_SQLLEN (2048+256) //Max sql script len

class MysqlDriver
{
public:
	MysqlDriver();
	virtual ~MysqlDriver();

public:
	bool Connect(const char* pHost, uint16_t nPort, const char* pDB, const char* pUsr, const char* pPwd, const char* pCharset);
	bool Query(const char* pCmd);
	bool FetchRow();

	int NumRows();         //只对SELECT语句有效
	int InsertID();        //取到插入ID
	int AffectedRows();    //对INSERT, UPDATE, DELETE有效

	int ToInt32(const char* pColumn);
	int64_t ToInt64(const char* pColumn);
	double ToDouble(const char* pColumn);
	const char* ToString(const char* pColumn);

private:
	MYSQL* m_pMysql;
	MYSQL_RES* m_pMysqlRes; //只保存最后的结果集

	MYSQL_ROW m_pMysqlRow;
	int m_nFieldCount;
	MYSQL_FIELD* m_pMysqlFields;

	DISALLOW_COPY_AND_ASSIGN(MysqlDriver);
};

#endif
