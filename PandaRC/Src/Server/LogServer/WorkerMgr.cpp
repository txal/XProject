#include "WorkerMgr.h"
#include "Include/Script/Script.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/HashFunc.h"

WorkerMgr* WorkerMgr::Instance()
{
	static WorkerMgr oWorkerMgr;
	return &oWorkerMgr;
}

bool WorkerMgr::Init(int nWorkers)
{
	assert(nWorkers > 0 && nWorkers <= 128);
	for (int i = 0; i < nWorkers; i++)
	{
		Worker* poWorker = new Worker();
		poWorker->oThread.Create(WorkerMgr::WorkerProc, poWorker);
		m_oWorkerList.push_back(poWorker);
	}
	return true;
}

void WorkerMgr::AddJob(MysqlDriver* poDriver, std::string* poQuery)
{
	uint64_t uAddr = (uint64_t)poDriver;
	int nIndex = jhash_2words((uint32_t)(uAddr>>32), (uint32_t)(uAddr&0xFFFFFFFF), 0) % m_oWorkerList.size();
	Worker* poWorker = m_oWorkerList[nIndex];
	poWorker->oLock.Lock();
	poWorker->oMsgQueue.push(Query(poDriver, poQuery));
	poWorker->oLock.Unlock();
}

void WorkerMgr::WorkerProc(void* pParam)
{
	Worker* poWorker = (Worker*)pParam;
	int nLastTime = (int)time(NULL);
	Query oQuery;
	for (;;)
	{
		oQuery.poDriver = NULL;
		oQuery.poQuery = NULL;
		poWorker->oLock.Lock();
		if (poWorker->oMsgQueue.size() > 0)
		{
			oQuery = poWorker->oMsgQueue.front();
			poWorker->oMsgQueue.pop();
			if (poWorker->oMsgQueue.size() >= 1024 && time(NULL) != nLastTime)
			{
				nLastTime = (int)time(NULL);
				XLog(LEVEL_WARNING, "Thread:%x mysql query msg overload:%d\n", (void*)poWorker, poWorker->oMsgQueue.size());
			}
		}
		poWorker->oLock.Unlock();
		if (oQuery.poDriver != NULL)
		{
			oQuery.poDriver->Query(oQuery.poQuery->c_str());
			SAFE_DELETE(oQuery.poQuery);
			continue;
		}
		XTime::MSSleep(10);
	}
}

// export to lua
static int AddJob(lua_State* poState)
{
	MysqlDriver* poDriver = (MysqlDriver*)Lunar<LMysqlDriver>::check(poState, 1);
	const char* psQuery = luaL_checkstring(poState, 2);
	std::string* poQuery = new std::string(psQuery);
	WorkerMgr::Instance()->AddJob(poDriver, poQuery);
	return 0;
}

void RegWorkerMgr(const char* psTable)
{
	luaL_Reg aFuncList[] =
	{
		{ "AddJob", AddJob },
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(aFuncList, psTable);
}
