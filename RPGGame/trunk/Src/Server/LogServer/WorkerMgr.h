#ifndef __WORKERMGR_H__
#define __WORKERMGR_H__

#include "Include/DBDriver/DBDriver.hpp"
#include "Common/Platform.h"
#include "Common/DataStruct/XThread.h"
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
	XThread oThread;
	MutexLock oLock;
	bool bTerminate;
	std::queue<Query> oMsgQueue;
	Worker() :bTerminate(false) {}
};

class WorkerMgr
{
public:
	typedef std::vector<Worker*> WorkerVector;
	
public:
	static WorkerMgr* g_poWorkderMgr;
	static WorkerMgr* Instance();
	static void Release();

	bool Init(int nWorkers);
	void AddJob(MysqlDriver* poDriver, std::string* poQuery);

private:
	WorkerMgr();
	~WorkerMgr();
	static void WorkerProc(void* pParam);

private:
	WorkerVector m_oWorkerList;
	bool m_bTerminate;
};

// export to lua
void RegWorkerMgr(const char* psTable);

#endif