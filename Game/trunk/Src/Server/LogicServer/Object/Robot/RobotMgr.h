#ifndef _ROBOTMGR_H__
#define __ROBOTMGR_H__

#include "Include/Script/Script.hpp"
#include "Server/Base/ServerContext.h"
#include "Server/LogicServer/Object/Robot/Robot.h"

class RobotMgr
{
public:
	LUNAR_DECLARE_CLASS(RobotMgr);

	typedef std::unordered_map<int64_t, Robot*> RobotIDMap;
	typedef RobotIDMap::iterator RobotIDIter;

public:
	RobotMgr();
	Robot* CreateRobot(const OBJID& oID, int nRobotID, const char* psName, int nAIID, int8_t nCamp, uint16_t uSyncHPTime);
	Robot* GetRobotByID(const OBJID& oID);

public:
	void UpdateRobots(int64_t nNowMS);



////////////////lua export///////////////////
public:
	int CreateRobot(lua_State* pState);
	int GetRobot(lua_State* pState);

private:
	RobotIDMap m_oRobotIDMap;
};




//Register to lua
void RegClassRobot();

#endif