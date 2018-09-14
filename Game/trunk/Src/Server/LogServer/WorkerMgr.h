#ifndef __WORKERMGR_H__
#define __WORKERMGR_H__

#include "Include/DBDriver/DBDriver.hpp"
#include "Common/Platform.h"
#include "Common/DataStruct/Thread.h"
#include "Common/DataStruct/MutexLock.h"

struct Query
{
	MysqlDriver* poDriver;
	std::string* poQuery;
	Query(MysqlDriver* _poDriver = NULL, std::string* _poQuery = NULL)
	{
		poDriver = _poDriver;
		poQuery = _poQuery;
	}
};

struct Worker
{
	Thread oThread;
	MutexLock oLock;
	std::queue<Query> oMsgQueue;
};

class WorkerMgr
{
public:
	typedef std::vector<Worker*> WorkerVector;
	static WorkerMgr* Instance();
	bool Init(int nWorkers);
	void AddJob(MysqlDriver* poDriver, std::string* poQuery);

private:
	WorkerMgr() {};
	static void WorkerProc(void* pParam);

private:
	WorkerVector m_oWorkerList;
};

// export to lua
void RegWorkerMgr(const char* psTable);

#endif