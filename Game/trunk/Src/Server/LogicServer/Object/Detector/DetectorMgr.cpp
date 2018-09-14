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

Detector* DetectorMgr::CreateDetector(const GAME_OBJID& oID, int nConfID, const char* psName)
{
	Detector* poDetector = GetDetectorByID(oID);
	if (poDetector != NULL)
	{
		XLog(LEVEL_ERROR, "CreateDetector: %lld exist\n", oID.llID);
		return NULL;
	}
	poDetector = XNEW(Detector);
	poDetector->Init(oID, nConfID, psName);
	m_oDetectorMap[oID.llID] = poDetector;
	return poDetector;
}

Detector* DetectorMgr::GetDetectorByID(const GAME_OBJID& oID)
{
	DetectorIter iter = m_oDetectorMap.find(oID.llID);
	if (iter != m_oDetectorMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void DetectorMgr::UpdateDetectors(int64_t nNowMS)
{
	static int nLastUpdateTime = 0;
	if (nLastUpdateTime == (int)time(0))
	{
		return;
	}
	nLastUpdateTime = (int)time(0);

	DetectorIter iter = m_oDetectorMap.begin();
	DetectorIter iter_end = m_oDetectorMap.end();
	for (; iter != iter_end; )
	{
		Detector* poDetector = iter->second;
		if (poDetector->IsTimeToCollected(nNowMS))
		{
			iter = m_oDetectorMap.erase(iter);
			 LuaWrapper::Instance()->FastCallLuaRef<void>("OnObjCollected", 0, "ii", poDetector->GetID().llID, poDetector->GetType());
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
	int64_t nObjID = luaL_checkinteger(pState, 1);
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
	int64_t nObjID = luaL_checkinteger(pState, 1);
	Detector* poDetector = GetDetectorByID(nObjID);
	if (poDetector != NULL)
	{
		Lunar<Detector>::push(pState, poDetector);
		return 1;
	}
	return 0;
}