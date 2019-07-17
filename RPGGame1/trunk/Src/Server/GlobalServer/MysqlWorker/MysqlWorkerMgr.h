#ifndef __MysqlWorkerMgr_H__
#define __MysqlWorkerMgr_H__

#include "Include/DBDriver/DBDriver.hpp"
#include "Common/Platform.h"
#include "Common/DataStruct/XThread.h"
#include "Common/DataStruct/MutexLock.h"

struct QUERY
{
	MysqlDriver* poDriver;
	std::string* poQuery;

	QUERY(MysqlDriver* _poDriver = NULL, std::string* _poQuery = NULL)
	{
		poDriver = _poDriver;
		poQuery = _poQuery;
	}
};

struct WORKER
{
	XThread oThread;
	MutexLock oLock;
	bool bTerminate;
	std::queue<QUERY> oMsgQueue;
	WORKER() :bTerminate(false) {}
};

class MysqlWorkerMgr
{
public:
	typedef std::vector<WORKER*> WorkerVector;
	
public:
	static MysqlWorkerMgr* poWorkderMgr;
	static MysqlWorkerMgr* Instance();
	static void Release();

	bool Init(int nWorkers);
	void AddMysqlJob(MysqlDriver* poDriver, std::string* poQuery);

private:
	static void WorkerProc(void* pParam);
	MysqlWorkerMgr();
	~MysqlWorkerMgr();

private:
	bool m_bTerminate;
	WorkerVector m_oWorkerList;
};

// export to lua
void RegMysqlWorkerMgr(const char* psTable);

#endif