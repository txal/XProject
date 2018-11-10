#ifndef __SERVER_CONFIG_H__
#define __SERVER_CONFIG_H__

#include "Common/Platform.h"

struct LogNode
{
	uint16_t uID;
	uint16_t uServer;
	uint16_t uWorkers;
	char sHttpAddr[256];
};

struct GlobalNode
{
	uint16_t uID;
	uint16_t uServer;
	char sIP[256];
	uint16_t uPort;
	char sHttpAddr[256];
};

struct RouterNode
{
	uint16_t uID;
	char sIP[256];
	uint16_t uPort;
};

struct GateNode
{
	uint16_t uID;
	uint16_t uServer;
	uint16_t uPort;
	uint16_t uMaxConns;
	uint16_t uSecureCPM;
	uint16_t uSecureQPM;
	uint32_t uSecureBlock;
	uint16_t uDeadLinkTime;
};

struct LogicNode
{
	uint16_t uServer;
	uint16_t uID;
};


struct LoginNode
{
	uint16_t uServer;
	uint16_t uID;
};

typedef std::vector<LogNode> LogVector;
typedef std::vector<GateNode> GateVector;
typedef std::vector<LogicNode> LogicVector;
typedef std::vector<RouterNode> RouterVector;
typedef std::vector<GlobalNode> GlobalVector;
typedef std::vector<LoginNode> LoginVector;

struct ServerConfig
{
	uint16_t uServerID;
	uint16_t uWorldServerID;

	LogVector oLogList;
	GateVector oGateList;
	LogicVector oLogicList;
	RouterVector oRouterList;
	GlobalVector oGlobalList;
	LoginVector oLoginList;
	GlobalVector oWGlobalList;

	char sDataPath[256];
	char sLogPath[256];
};


#endif