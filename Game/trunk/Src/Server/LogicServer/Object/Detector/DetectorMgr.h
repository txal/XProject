#ifndef __DETETOR_MGR_H__
#define __DETETOR_MGR_H__

#include "Detector.h"
#include "Include/Script/Script.hpp"
#include "Server/Base/ServerContext.h"

class DetectorMgr
{
public:
	LUNAR_DECLARE_CLASS(DetectorMgr);

	typedef std::unordered_map<int64_t, Detector*> DetectorMap;
	typedef DetectorMap::iterator DetectorIter;

public:
	DetectorMgr();
	Detector* CreateDetector(const OBJID& oID, int nConfID, const char* psName);
	Detector* GetDetectorByID(const OBJID& oID);

public:
	void UpdateDetectors(int64_t nNowMS);

private:
	DISALLOW_COPY_AND_ASSIGN(DetectorMgr);



////////////////lua export///////////////////
public:
	int CreateDetector(lua_State* pState);
	int RemoveDetector(lua_State* pState);
	int GetDetector(lua_State* pState);

private:
	DetectorMap m_oDetectorMap;
};




//Register to lua
void RegClassDetector();

#endif