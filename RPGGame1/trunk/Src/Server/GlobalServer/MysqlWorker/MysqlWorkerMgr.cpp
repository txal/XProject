#include "MysqlWorkerMgr.h"
#include "Include/Script/Script.hpp"
#include "Common/DataStruct/XTime.h"
#include "Common/DataStruct/XMath.h"
#include "Common/DataStruct/HashFunc.h"

MysqlWorkerMgr* MysqlWorkerMgr::poWorkderMgr = NULL;

MysqlWorkerMgr* MysqlWorkerMgr::Instance()
{
	if (poWorkderMgr == NULL)
	{
		poWorkderMgr = XNEW(MysqlWorkerMgr);
	}
	return poWorkderMgr;
}

void MysqlWorkerMgr::Release()
{
	if (poWorkderMgr != NULL)
	{
		SAFE_DELETE(poWorkderMgr);
	}
}

MysqlWorkerMgr::MysqlWorkerMgr()
{
}

MysqlWorkerMgr::~MysqlWorkerMgr()
{
	for (int i = 0; i < m_oWorkerList.size(); i++)
	{
		WORKER* poWorker = m_oWorkerList[i];
		poWorker->bTerminate = true;
		poWorker->oThread.Join();
		SAFE_DELETE(poWorker);
	}
}

bool MysqlWorkerMgr::Init(int nWorkers)
{
	assert(nWorkers > 0 && nWorkers <= 128);
	for (int i = 0; i < nWorkers; i++)
	{
		WORKER* poWorker = XNEW(WORKER)();
		if (poWorker->oThread.Create(MysqlWorkerMgr::WorkerProc, poWorker, false))
		{
			m_oWorkerList.push_back(poWorker);
		}
		else
		{
			SAFE_DELETE(poWorker);
		}
	}
	return true;
}

void MysqlWorkerMgr::AddMysqlJob(MysqlDriver* poDriver, std::string* poQuery)
{
	if (m_oWorkerList.size() <= 0)
	{
		XLog(LEVEL_ERROR, "MysqlWorkerMgr not init yet!\n");
		SAFE_DELETE(poQuery);
		return;
	}
	uint64_t uAddr = (uint64_t)poDriver;
	int nIndex = jhash_2words((uint32_t)(uAddr>>32), (uint32_t)(uAddr&0xFFFFFFFF), 0) % m_oWorkerList.size();
	WORKER* poWorker = m_oWorkerList[nIndex];
	poWorker->oLock.Lock();
	poWorker->oMsgQueue.push(QUERY(poDriver, poQuery));
	poWorker->oLock.Unlock();
}

void MysqlWorkerMgr::WorkerProc(void* pParam)
{
	WORKER* poWorker = (WORKER*)pParam;
	int nLastTime = (int)time(NULL);
	QUERY oQuery;

	while (!poWorker->bTerminate)
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
				XLog(LEVEL_WARNING, "Thread:%x mysql query num overload:%d\n", (void*)poWorker, poWorker->oMsgQueue.size());
			}
		}
		poWorker->oLock.Unlock();
		if (oQuery.poDriver != NULL && oQuery.poQuery != NULL)
		{
			oQuery.poDriver->Query(oQuery.poQuery->c_str());
			SAFE_DELETE(oQuery.poQuery);
			continue;
		}
		XTime::MSSleep(10);
	}
}

// export to lua
static int AddMysqlJob(lua_State* poState)
{
	MysqlDriver* poDriver = (MysqlDriver*)Lunar<LMysqlDriver>::check(poState, 1);
	const char* psQuery = luaL_checkstring(poState, 2);
	std::string* poQuery = XNEW(std::string)(psQuery);
	MysqlWorkerMgr::Instance()->AddMysqlJob(poDriver, poQuery);
	return 0;
}

void RegMysqlWorkerMgr(const char* psTable)
{
	luaL_Reg aFuncList[] =
	{
		{ "AddMysqlJob", AddMysqlJob },
		{ NULL, NULL },
	};
	LuaWrapper::Instance()->RegFnList(aFuncList, psTable);
}
