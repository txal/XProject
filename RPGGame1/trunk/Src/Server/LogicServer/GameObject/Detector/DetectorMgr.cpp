#include "Server/LogicServer/GameObject/Detector/DetectorMgr.h"

#include "Server/LogicServer/SceneMgr/SceneBase.h"

LUNAR_IMPLEMENT_CLASS(DetectorMgr)
{
	LUNAR_DECLARE_METHOD(DetectorMgr, CreateDetector),
	LUNAR_DECLARE_METHOD(DetectorMgr, GetDetector),
	{0, 0}
};


DetectorMgr::DetectorMgr()
{
}

DetectorMgr::~DetectorMgr()
{
	DetectorIter iter = m_oDetectorMap.begin();
	for (iter; iter != m_oDetectorMap.end(); iter++)
	{
		SAFE_DELETE(iter->second);
	}
}

Detector* DetectorMgr::CreateDetector(int64_t nObjID, int nConfID, const char* psName)
{
	Detector* poDetector = GetDetectorByID(nObjID);
	if (poDetector != NULL)
	{
		XLog(LEVEL_ERROR, "CreateDetector: %lld exist\n", nObjID);
		return NULL;
	}
	poDetector = XNEW(Detector);
	poDetector->Init(nObjID, nConfID, psName);
	m_oDetectorMap[nObjID] = poDetector;
	return poDetector;
}

Detector* DetectorMgr::GetDetectorByID(int64_t nObjID)
{
	DetectorIter iter = m_oDetectorMap.find(nObjID);
	if (iter != m_oDetectorMap.end())
	{
		return iter->second;
	}
	return NULL;
}

void DetectorMgr::RemoveDetector(int64_t nObjID)
{
	Detector* poDetector = GetDetectorByID(nObjID);
	if (poDetector == NULL)
	{
		return;
	}
	if (poDetector->GetScene() != NULL)
	{
		XLog(LEVEL_ERROR, "需要先离开场景才能删除对象");
		return;
	}
	poDetector->MarkDeleted();
}

void DetectorMgr::Update(int64_t nNowMS)
{
	static int64_t nLastUpdateTime = 0;
	if (nNowMS - nLastUpdateTime <= 1000)
	{
		return;
	}
	nLastUpdateTime = nNowMS;

	DetectorIter iter = m_oDetectorMap.begin();
	DetectorIter iter_end = m_oDetectorMap.end();
	for (; iter != iter_end; )
	{
		Detector* poDetector = iter->second;
		if (poDetector->IsDeleted())
		{
			iter = m_oDetectorMap.erase(iter);
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
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
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
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
	Detector* poDetector = GetDetectorByID(nObjID);
	if (poDetector != NULL)
	{
		Lunar<Detector>::push(pState, poDetector);
		return 1;
	}
	return 0;
}

int DetectorMgr::RemoveDetector(lua_State* pState)
{
	int64_t nObjID = (int64_t)luaL_checkinteger(pState, 1);
	RemoveDetector(nObjID);
	return 0;
}
