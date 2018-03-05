--服务器管理类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CServerMgr:Ctor()
	self.m_tServerMap = {} --{[serverid]={serverid=,displayid=,servername=,opentime=}
	self.m_oMgrMysql = nil

end

function CServerMgr:Init()
	self.m_oMgrMysql = MysqlDriver:new() 
	
	local tConf = gtMgrMysqlConf
	local bRes = self.m_oMgrMysql:Connect(tConf.sIP, tConf.nPort, tConf.sDBName, tConf.sUserName, tConf.sPassword, "utf8")
	assert(bRes, "连接数据库失败: ", tConf)
	bRes = self.m_oMgrMysql:Query("select serverid,servername,displayid,time from serverlist;")
	assert(bRes, "查询后台服务器失败: ", tConf)
		

	while self.m_oMgrMysql:FetchRow() do
		local sServerName = self.m_oMgrMysql:ToString("servername")
		local nServerID, nDisplayID, nOpenTime = self.m_oMgrMysql:ToInt32("serverid", "displayid", "time")
		self.m_tServerMap[nServerID] = {nDisplayID=nDisplayID, nOpenTime=nOpenTime, sServerName=sServerName}
	end
end

function CServerMgr:GetOpenTime(nServer)
	local tServerMap = self.m_tServerMap[nServer]
	if not tServerMap then
		return os.time()
	end
	return tServerMap.nOpenTime
end

function CServerMgr:GetDisplayID(nServer)
	local tServerMap = assert(self.m_tServerMap[nServer])
	return tServerMap.nDisplayID
end

function CServerMgr:GetServerName(nServer)
	local tServerMap = assert(self.m_tServerMap[nServer])
	return tServerMap.sServerName
end

function CServerMgr:GetOpenZeroTime(nServer) 
	local nOpenTime = self:GetOpenTime(nServer)
	local tDate = os.date("*t", nOpenTime)
	tDate.hour, tDate.min, tDate.sec = 0, 0, 0
	return os.time(tDate)
end

--开放天数(1开始)
function CServerMgr:GetOpenDays(nServer)
	local nOpenZeroTime = self:GetOpenZeroTime(nServer)	
	local nPassTime = os.time() - nOpenZeroTime
	return math.ceil(nPassTime/(24*3600))
end

--服务器等级,返回服务器等级和下一等级时间
function CServerMgr:GetServerLevel(nServer)
	local tCurrConf, tNextConf = nil, nil

	local nDays = self:GetOpenDays(nServer)
	for k=#ctServerLevelConf, 1, -1 do
		local tConf = ctServerLevelConf[k]
		if nDays >= tConf.nDays then
			tCurrConf = tConf
			tNextConf = ctServerLevelConf[k+1]
			break
		end
	end

	--已达等级上限
	if not tNextConf then
		return tCurrConf.nLevel, -1
	end

	--下一等级时间
	local nNextDays = tNextConf.nDays
	local nNextTime= self:GetOpenZeroTime()+(nNextDays-1)*24*3600
	return tCurrConf.nLevel, nNextTime
end

goServerMgr = goServerMgr or CServerMgr:new()
