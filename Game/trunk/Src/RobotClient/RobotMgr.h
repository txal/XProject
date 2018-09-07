#ifndef __ROBOTMGR_H__
#define __ROBOTMGR_H__

#include "Include/Network/Network.hpp"
#include "Server/Base/Service.h"
#include "RobotClient/Robot.h"

class Packet;

class RobotMgr: public Service
{
public:
	static char className[];
	static Lunar<RobotMgr>::RegType methods[];
	RobotMgr(lua_State* pState) { XLog(LEVEL_ERROR, "RobotMgr should not create in lua!\n"); }

	typedef std::unordered_map<int, Robot*> RobotMap;
	typedef RobotMap::iterator RobotIter;

public:
	RobotMgr();
	virtual ~RobotMgr();
	
	bool Init(int8_t nServiceID, int nMaxRobot);
	virtual INet* GetExterNet() { return m_pExterNet;  }
	bool Start();

	Robot* GetRobot(int nSession);
	void CreateRobot(int nRobotNum, const char* pszIP, uint16_t uPort);
	uint32_t GetClientTick() { return m_uClientTick;  }

public:
	void PushTask(std::string& osTask);

private:
	void tt();
    void ProcessNetEvent(int64_t nWaitMS);
    void ProcessConsoleTask(int64_t nNowMS);
    void ProcessRobotUpdate(int64_t nNowMS);
	void ProcessTimer(int64_t nNowMSTime);

	void OnExterNetConnect(int nSessionID);
	void OnExterNetClose(int nSessionID);
	void OnExterNetMsg(int nSessionID, Packet* poPacket);

private:
	//时间同步
	uint64_t m_nStartTick;
	uint32_t m_uClientTick;

	int m_nMaxRobot;
	RobotMap m_oRobotMap;

	INet* m_pExterNet;
	NetEventHandler m_oNetEventHandler;


	std::list<std::string> m_oTaskList;
	DISALLOW_COPY_AND_ASSIGN(RobotMgr);


////////////////export to lua//////////////
public:
	int GetRobot(lua_State* pState);
	int CreateRobot(lua_State* pState);
	int LogoutRobot(lua_State* pState);
};



//Register to lua
void RegClassRobot();

#endif
