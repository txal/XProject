--Mysql连接池(只给写LOG用,不支持SELECT)
local math, table = math, table
local tLogService = gtServerConf.tLogService[1]

function CMysqlPool:Ctor()
	self.m_tMysqlList = {}	
end

function CMysqlPool:Init()
	local tConf = gtServerConf.tLogDB
	for i = 1, tLogService.nWorkers do
		local oMysql = MysqlDriver:new()
		local bRes = oMysql:Connect(tConf.sIP, tConf.nPort, tConf.sDBName, tConf.sUserName, tConf.sPassword, "utf8")
		assert(bRes, "连接数据库失败:", tConf)
		LuaTrace("连接数据库成功: ", tConf)
		table.insert(self.m_tMysqlList, oMysql)
	end
end

function CMysqlPool:Query(sQuery)
	local nIndex = math.random(1, #self.m_tMysqlList)
	local oMysql = self.m_tMysqlList[nIndex]
	WorkerMgr.AddJob(oMysql, sQuery)
end

goMysqlPool = goMysqlPool or CMysqlPool:new()