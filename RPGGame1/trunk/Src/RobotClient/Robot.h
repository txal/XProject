#ifndef __ROBOT_H__
#define __ROBOT_H__

#include "Include/Network/Network.hpp"
#include "Include/Script/Script.hpp"
#include "Common/DataStruct/Point.h"
#include "Common/PacketParser/PacketReader.h"
#include "Common/PacketParser/PacketWriter.h"
#include "Common/Platform.h"
#include "Server/LogicServer/ConfMgr/ConfMgr.h"

class RobotMgr;
class Robot
{
public:
	static char className[];
	static Lunar<Robot>::RegType methods[];
	Robot(lua_State* pState) { XLog(LEVEL_ERROR, "Robot should not new in lua!\n"); }

public:
	Robot(RobotMgr* poRobotMgr);
	~Robot();
	void Update(int64_t nNowMS);
	void OnConnect(int nSessionID);
	void OnDisconnect();
	int64_t GetLastUpdateTime() { return m_nLastUpdateTime; }

public:
	void ProcessRun(int64_t nNowMS);
	void StartRun(int nSpeedX, int nSpeedY, int nDir);
	void StopRun();

private:
	void SetPos(int nPosX, int nPosY);
	bool CalcPositionAtTime(int64_t nNowMS, int& nNewPosX, int& nNewPosY);

public:
	void OnSyncActorPosHandler(Packet* poPacket);

private:
	PacketWriter oPKWriter;
	PacketReader oPKReader;
	Packet* m_poPacketCache;

private:
	RobotMgr* m_poRobotMgr;
	int m_nSessionID;
	char m_sName[256];
	uint32_t m_uPacketID;
	int64_t m_nLastUpdateTime;

	int m_nMapID;
	MAPCONF* m_poMapConf;
	int m_nAOIID;

	//位置同步相关
	Point m_oPos;
	int m_nSpeedX;
	int m_nSpeedY;
	int m_nStartRunX;
	int m_nStartRunY;
	int m_nMoveSpeed;
	int64_t m_nRunStartTime;
	Point m_oTarPos;
	DISALLOW_COPY_AND_ASSIGN(Robot);




//////////////lua export//////////
public:
	int GetPos(lua_State* pState);
	int SetPos(lua_State* pState);
	int SetName(lua_State* pState);
	int SetMoveSpeed(lua_State* pState);
	int StartRun(lua_State* pState);
	int StopRun(lua_State* pState);
	int IsRunning(lua_State* pState);
	int SetMapID(lua_State* pState);
	int PacketID(lua_State* pState);
	int CalcMoveSpeed(lua_State* pState);

};

#endif