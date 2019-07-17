#ifndef __SERVERCONTEXT_H__
#define __SERVERCONTEXT_H__

#include "Include/Script/LuaWrapper.h"
#include "Common/Platform.h"
#include "Common/LuaCommon/LuaSerialize.h"
#include "Common/LuaCommon/LuaTableSeri.h"
#include "Server/Base/PacketHandler.h"
#include "Server/Base/RouterMgr.h"
#include "Server/Base/ServerConfig.h"
#include "Server/Base/Service.h"

class MysqlDriver;
class ServerContext
{
public:
	ServerContext();
	virtual ~ServerContext();

	Service* GetService() { return m_poService; }
	void SetService(Service* poService) { m_poService = poService; }

	RouterMgr* GetRouterMgr() { return m_poRouterMgr; }
	void SetRouterMgr(RouterMgr* poRouterMgr) { m_poRouterMgr = poRouterMgr; }

	PacketHandler* GetPacketHandler() { return m_poPacketHandler; }
	void SetPacketHandler(PacketHandler* poPacketHandler) { m_poPacketHandler = poPacketHandler; }

	uint16_t GetServerID() { return m_oServerConf.uServerID; }
	uint16_t GetWorldServerID() { return m_oServerConf.uWorldServerID; }

	int SelectLogic(int nSession);

	bool LoadServerConfig();
	bool LoadServerConfigByFile();
	ServerConfig& GetServerConfig() { return m_oServerConf; }
	LuaTableSeri* GetLuaTableSeri() { return m_poLuaTableSeri; }
	void SetLuaSerialize(LuaSerialize* seri) { m_poLuaSerialize = seri; }
	LuaSerialize* GetLuaSerialize() { return m_poLuaSerialize; }

private:
	Service* m_poService;
	RouterMgr* m_poRouterMgr;
	PacketHandler* m_poPacketHandler;
	LuaTableSeri* m_poLuaTableSeri;
	LuaSerialize* m_poLuaSerialize;
	
	ServerConfig m_oServerConf;
	MysqlDriver* m_pMgrMysql;
	DISALLOW_COPY_AND_ASSIGN(ServerContext);
};

extern ServerContext* gpoContext;

#endif