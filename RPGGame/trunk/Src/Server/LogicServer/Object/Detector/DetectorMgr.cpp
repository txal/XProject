#include "DetectorMgr.h"

LUNAR_IMPLEMENT_CLASS(DetectorMgr)
{
	LUNAR_DECLARE_METHOD(DetectorMgr, CreateDetector),
	LUNAR_DECLARE_METHOD(DetectorMgr, GetDetector),
	{0, 0}
};


DetectorMgr::DetectorMgr()
{
}

Detector* DetectorMgr::CreateDetector(int nID, int nConfID, const char* psName)
{
	Detector* poDetector = GetDetectorByID(nID);
	if (poDetector != NULL)
	{
		XLog(LEVEL_ERROR, "CreateDetector: %lld exist\n", nID);
		return NULL;
	}
	poDetector = XNEW(Detector);
	poDetector->Init(nID, nConfID, psName);
	m_oDetectorMap[nID] = poDetector;
	return poDetector;
}

Detector* DetectorMgr::GetDetectorByID(int nID)
{
	DetectorIter iter = m_oDetectorMap.find(nID);
	if (iter != m_oDetectorMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void DetectorMgr::Update(int64_t nNowMS)
{
	static int nLastUpdateTime = 0;
	int nNowSec = (int)time(0);
	if (nLastUpdateTime == nNowSec)
		return;
	nLastUpdateTime = nNowSec;

	DetectorIter iter = m_oDetectorMap.begin();
	DetectorIter iter_end = m_oDetectorMap.end();
	for (; iter != iter_end; )
	{
		Detector* poDetector = iter->second;
		if (poDetector->IsTime2Collect(nNowMS))
		{
			iter = m_oDetectorMap.erase(iter);
			 LuaWrapper::Instance()->FastCallLuaRef<void>("OnObjCollected", 0, "ii", poDetector->GetID(), poDetector->GetType());
			SAFE_DELETE(poDetector);
			continue;
		}
		if (poDetector->GetScene() != NULL)
		{
			poDetector->Update(nNowMS);
		}
		iter++;
	}	
}




////////////////////////lua export///////////////////////
void RegClassDetector()
{
	REG_CLASS(Detector, false, NULL); 
	REG_CLASS(DetectorMgr, false, NULL); 
}

int DetectorMgr::CreateDetector(lua_State* pState)
{
	int nObjID = (int)luaL_checkinteger(pState, 1);
	int nConfID = (int)luaL_checkinteger(pState, 2);
	const char* psName = luaL_checkstring(pState, 3);
	int nAliveTime  = (int)luaL_checkinteger(pState, 4);
	int nCamp = (int)luaL_checkinteger(pState, 5);
	Detector* poDetector = CreateDetector(nObjID, nConfID, psName);
	if (poDetector != NULL)
	{
		Lunar<Detector>::push(pState, poDetector);
		return 1;
	}
	return 0;
}

int DetectorMgr::GetDetector(lua_State* pState)
{
	int nObjID = (int)luaL_checkinteger(pState, 1);
	Detector* poDetector = GetDetectorByID(nObjID);
	if (poDetector != NULL)
	{
		Lunar<Detector>::push(pState, poDetector);
		return 1;
	}
	return 0;
}