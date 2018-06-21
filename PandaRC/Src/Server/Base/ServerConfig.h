#ifndef __SERVER_CONFIG_H__
#define __SERVER_CONFIG_H__

#include "Common/Platform.h"

struct LogNode
{
	uint16_t uService;
	uint8_t uWorkers;
	uint8_t uMysqlConns;
};

struct GlobalNode
{
	uint16_t uService;
	char sIP[256];
	uint16_t uPort;
};

struct RouterNode
{
	uint16_t uService;
	char sIP[256];
	uint16_t uPort;
};

struct GateNode
{
	uint16_t uService;
	uint16_t uPort;
	uint16_t uMaxConns;
	uint16_t uSecureCPM;
	uint16_t uSecureQPM;
	uint32_t uSecureBlock;
	uint16_t uDeadLinkTime;
};

struct LogicNode
{
	uint16_t uService;
};


union ServerNode
{
	LogNode oLog;
	GlobalNode oGlobal;
	RouterNode oRouter;
	GateNode oGate;
	LogicNode oLogic;
};

typedef std::vector<ServerNode> ServerVector;

struct ServerConfig
{
	uint16_t uServerID;
	ServerVector oGateList;
	ServerVector oLogicList;
	ServerVector oRouterList;

	ServerVector oLogList;
	ServerVector oGlobalList;
};


#endif