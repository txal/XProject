--服务器管理类

function CServerMgr:Ctor()
	self.m_nOpenTime = os.time() 	--开服时间
	self.m_nDisplayID = 0 			--显示区号
	self.m_nServerID = 0
	self.m_sServerName = 0
	self:Init()
end

function CServerMgr:Init()
	local oMgrMysql = MysqlDriver:new()
	local tMysqlConf = gtMgrMysqlConf
	local bRes = oMgrMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, tMysqlConf.sDBName, tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8")
	assert(bRes, "连接数据库失败:", tMysqlConf)
	bRes = oMgrMysql:Query("select serverid,servername,displayid,time from serverlist where serverid="..gnServerID)
	assert(bRes, "查询后台服务器失败")
	assert(oMgrMysql:FetchRow(), "后台服务器不存在:"..gnServerID)
		
	self.m_nServerID, self.m_nDisplayID, self.m_nOpenTime = oMgrMysql:ToInt32("serverid", "displayid", "time")
	self.m_sServerName = oMgrMysql:ToString("servername")
	LuaTrace("服务器名:", self.m_sServerName)
	LuaTrace("服务器ID:", self.m_nServerID, "显示区号:", self.m_nDisplayID)
	LuaTrace("开服时间:", self.m_nOpenTime, os.date("*t", self.m_nOpenTime))
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

goServerMgr = CServerMgr:new()
