--Mysql连接池(只给写LOG用,不支持SELECT)
local math = math
CMysqlPool = class()
local tLogServer = gtNetConf.tLogService[1]

function CMysqlPool:Ctor()
	self.m_tMysqlList = {}	
end

function CMysqlPool:Init()
	local tMysqlConf = gtGameMysqlConf[1]
	for i = 1, tLogServer.nMysqlConns do
		local oMysql = MysqlDriver:new()
		local bRes = oMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, tMysqlConf.sDBName, tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8")
		assert(bRes, "连接Mysql:"..table.ToString(tMysqlConf, true).."失败")
		LuaTrace("连接Mysql: "..table.ToString(tMysqlConf, true).."成功")
		table.insert(self.m_tMysqlList, oMysql)
	end
end

function CMysqlPool:Query(sQuery)
	local nIndex = math.random(1, #self.m_tMysqlList)
	local oMysql = self.m_tMysqlList[nIndex]
	WorkerMgr.AddJob(oMysql, sQuery)
end

goMysqlPool = goMysqlPool or CMysqlPool:new()