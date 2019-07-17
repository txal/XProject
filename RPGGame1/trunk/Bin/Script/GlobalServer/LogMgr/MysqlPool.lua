--Mysql连接池(不支持SELECT)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMysqlPool:Ctor()
	self.m_tMgrMysql = {} 		--后台数据库连接
	self.m_tGameMysql = {}	 	--日志数据库连接
	self.m_oMgrMysql = nil   	--同步查询用的后台数据库 
end

function CMysqlPool:Init()
	local tConf = gtMgrSQL

	local oMysql = MysqlDriver:new()
	local bRes = oMysql:Connect(tConf.ip, tConf.port, tConf.db, tConf.usr, tConf.pwd, "utf8")
	assert(bRes, "连接数据库失败:"..tostring(tConf))
	table.insert(self.m_tMgrMysql, oMysql)

	self.m_tMgrMysql[1]:Query("select logdb from serverlist where serverid="..gnServerID)
	local bRes = self.m_tMgrMysql[1]:FetchRow()
	assert(bRes, "后台服务器不存在:"..gnServerID)

	local sLogDB = self.m_tMgrMysql[1]:ToString("logdb")
	local tLogDB = string.Split(sLogDB, "|")
	for i = 1, 2 do
		local oMysql = MysqlDriver:new()
		local bRes = oMysql:Connect(tLogDB[1], tLogDB[2], tLogDB[5], tLogDB[3], tLogDB[4], "utf8")
		assert(bRes, "连接数据库失败:"..tostring(tConf))
		table.insert(self.m_tGameMysql, oMysql)
	end

	local oMysql = MysqlDriver:new()
	local bRes = oMysql:Connect(tConf.ip, tConf.port, tConf.db, tConf.usr, tConf.pwd, "utf8")
	assert(bRes, "连接数据库失败:"..tostring(tConf))
	self.m_oMgrMysql = oMysql
end

--取后台数据库
function CMysqlPool:GetMgrMysql()
	return self.m_oMgrMysql
end

--插入游戏数据库
function CMysqlPool:GameAsyncQuery(sQuery)
	local nIndex = math.random(1, #self.m_tGameMysql)
	local oMysql = self.m_tGameMysql[nIndex]
	WorkerMgr.AddJob(oMysql, sQuery)
end

--插入后台数据库
function CMysqlPool:MgrAsyncQuery(sQuery)
	WorkerMgr.AddJob(self.m_tMgrMysql[1], sQuery)
end

