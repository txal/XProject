local math, table = math, table
local nLogService, tLogServer = gtNetConf:LogService()

--Mysql连接池(只给写LOG用,不支持SELECT)
CMysqlPool = CMysqlPool or class()

function CMysqlPool:Ctor()
	self.m_tMysqlList = {}	
end

function CMysqlPool:Init()
	local tMysqlConf = gtGameMysqlConf
	for i = 1, tLogServer.nMysqlConns do
		local oMysql = MysqlDriver:new()
		local bRes = oMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, tMysqlConf.sDBName, tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8")
		assert(bRes, "连接数据库失败:", tMysqlConf)
		LuaTrace("连接数据库成功: ", tMysqlConf)
		table.insert(self.m_tMysqlList, oMysql)
	end
end

function CMysqlPool:Query(sQuery)
	local nIndex = math.random(1, #self.m_tMysqlList)
	local oMysql = self.m_tMysqlList[nIndex]
	WorkerMgr.AddJob(oMysql, sQuery)
end

goMysqlPool = goMysqlPool or CMysqlPool:new()