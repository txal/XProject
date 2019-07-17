#ifndef __SERVER_CONFIG_H__
#define __SERVER_CONFIG_H__

#include "Common/DataStruct/XMath.h"

//struct LogNode
//{
//	uint16_t uID;
//	uint16_t uServer;
//	uint16_t uWorkers;
//	char sHttpAddr[256];
//};

//struct LoginNode
//{
//	uint16_t uServer;
//	uint16_t uID;
//};

struct GlobalNode
{
	uint16_t uID;
	uint16_t uServer;
	char sIP[256];
	uint16_t uPort;
	char sHttpAddr[256];
	uint16_t uWorkers;
};

struct RouterNode
{
	uint16_t uID;
	uint16_t uServer;
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

//typedef std::vector<LogNode> LogVector;
//typedef std::vector<LoginNode> LoginVector;
typedef std::vector<GateNode> GateVector;
typedef std::vector<LogicNode> LogicVector;
typedef std::vector<RouterNode> RouterVector;
typedef std::vector<GlobalNode> GlobalVector;

struct ServerConfig
{
	uint16_t uGroupID;
	uint16_t uServerID;
	uint16_t uWorldServerID;

	//LogVector oLogList;
	//LoginVector oLoginList;
	GateVector oGateList;
	LogicVector oLogicList;
	RouterVector oRouterList;
	GlobalVector oGlobalList;
	GlobalVector oWGlobalList;

	char sDataPath[256];
	char sLogPath[256];

	uint16_t GetGroupID() { return uGroupID; }
	uint16_t GetServerID() { return uServerID; }
	uint16_t GetWorldServerID() { return uWorldServerID; }
	const char* GetDataPath() { return sDataPath; }
	const char* GetLogPath() { return sLogPath; }

	int8_t RandomLogic(uint16_t uServerID)
	{
		LogicVector& oTmpLogicList = GetLogicList(GetServerID(), 0);
		if (oTmpLogicList.size() > 0)
		{
			int nRndIndex = XMath::Random(1, (int)oTmpLogicList.size());
			return (int8_t)oTmpLogicList[nRndIndex - 1].uID;
		}
		return 0;
	}

	GateVector& GetGateList(uint16_t uServerID, uint16_t uServiceID)
	{
		static GateVector oTarGateList;
		oTarGateList.clear();

		for (GateVector::iterator iter = oGateList.begin(); iter != oGateList.end(); iter++)
		{
			if ((uServerID == 0 || iter->uServer == uServerID) && (uServiceID == 0 || iter->uID == uServiceID))
			{
				oTarGateList.push_back(*iter);
			}
		}
		return oTarGateList;
	}

	LogicVector& GetLogicList(uint16_t uServerID, uint16_t uServiceID)
	{
		static LogicVector oTarLogicList;
		oTarLogicList.clear();

		for (LogicVector::iterator iter = oLogicList.begin(); iter != oLogicList.end(); iter++)
		{
			if ((uServerID == 0 || iter->uServer == uServerID) && (uServiceID == 0 || iter->uID == uServiceID))
			{
				oTarLogicList.push_back(*iter);
			}
		}
		return oTarLogicList;
	}

	RouterVector& GetRouterList(uint16_t uServerID, uint16_t uServiceID)
	{
		static RouterVector oTarRouterList;
		oTarRouterList.clear();

		for (RouterVector::iterator iter = oRouterList.begin(); iter != oRouterList.end(); iter++)
		{
			if ((uServerID == 0 || iter->uServer == uServerID) && (uServiceID == 0 || iter->uID == uServiceID))
			{
				oTarRouterList.push_back(*iter);
			}
		}
		return oTarRouterList;
	}

	GlobalVector& GetGlobalList(uint16_t uServerID, uint16_t uServiceID)
	{
		static GlobalVector oTarGlobalList;
		oTarGlobalList.clear();

		for (GlobalVector::iterator iter = oGlobalList.begin(); iter != oGlobalList.end(); iter++)
		{
			if ((uServerID == 0 || iter->uServer == uServerID) && (uServiceID == 0 || iter->uID == uServiceID))
			{
				oTarGlobalList.push_back(*iter);
			}
		}
		return oTarGlobalList;
	}

	GlobalVector& GetWGlobalList(uint16_t uServerID, uint16_t uServiceID)
	{
		static GlobalVector oTarWGlobalList;
		oTarWGlobalList.clear();

		for (GlobalVector::iterator iter = oWGlobalList.begin(); iter != oWGlobalList.end(); iter++)
		{
			if ((uServerID == 0 || iter->uServer == uServerID) && (uServiceID == 0 || iter->uID == uServiceID))
			{
				oTarWGlobalList.push_back(*iter);
			}
		}
		return oTarWGlobalList;
	}
};


#endif