--服务器管理类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CServerMgr:Ctor()
	self.m_nServerID = 0 
	self.m_nDisplayID = 0 			--显示区号
	self.m_sServerName = 0
	self.m_oMgrMysql = nil
	self.m_nOpenTime = os.time() 	--开服时间
	self.m_nOpenZeroTime = 0 		--开服0点时间
end

function CServerMgr:Init(nServerID)
	self.m_nServerID = nServerID
	self.m_oMgrMysql = MysqlDriver:new() 
	
	local tConf = gtMgrMysqlConf
	local bRes = self.m_oMgrMysql:Connect(tConf.sIP, tConf.nPort, tConf.sDBName, tConf.sUserName, tConf.sPassword, "utf8")
	assert(bRes, "连接数据库失败", tConf)
	bRes = self.m_oMgrMysql:Query("select servername,displayid,time from serverlist where serverid="..self.m_nServerID)
	assert(bRes, "查询后台服务器失败", tConf)
	assert(self.m_oMgrMysql:FetchRow(), "后台服务器不存在:"..self.m_nServerID)
		
	self.m_nDisplayID, self.m_nOpenTime = self.m_oMgrMysql:ToInt32("displayid", "time")
	self.m_sServerName = self.m_oMgrMysql:ToString("servername")

	LuaTrace("服务器名:", self.m_sServerName)
	LuaTrace("服务器ID:", self.m_nServerID, "显示区号:", self.m_nDisplayID)
	LuaTrace("开服时间:", self.m_nOpenTime, os.date("*t", self.m_nOpenTime))

	local tDate = os.date("*t", self.m_nOpenTime)
	tDate.hour, tDate.min, tDate.sec = 0, 0, 0
	self.m_nOpenZeroTime = os.time(tDate)
end

function CServerMgr:GetOpenTime()
	return self.m_nOpenTime 
end

function CServerMgr:GetServerID()
	return self.m_nServerID
end

function CServerMgr:GetDisplayID()
	return self.m_nDisplayID
end

function CServerMgr:GetServerName()
	return self.m_sServerName
end

function CServerMgr:GetOpenZeroTime()
	return self.m_nOpenZeroTime
end

goServerMgr = goServerMgr or CServerMgr:new()
