--活动预约模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHDBook:Ctor()
	self.m_nMinTimer = nil
end

function CHDBook:LoadData()
	self:RegMinTimer()
end

function CHDBook:SaveData()
end

function CHDBook:OnRelease()
	goTimerMgr:Clear(self.m_nMinTimer)
	self.m_nMinTimer = nil
end

--分钟计时器
function CHDBook:RegMinTimer()
	goTimerMgr:Clear(self.m_nMinTimer)
	self.m_nMinTimer = goTimerMgr:Interval(os.NextMinTime(os.time()), function() self:OnMinTimer() end)	
end

--分钟计时器回调
function CHDBook:OnMinTimer()
	self:RegMinTimer()
	self:CheckActOpen()
end

--检测活动开启
function CHDBook:CheckActOpen()
	LuaTrace("检测预约活动开启======")
	local oMysql = goDBMgr:GetMgrMysql()

	local sServerList = ""
	local tServerMap = goServerMgr:GetServerMap()
	for nServerID, tServer in pairs(tServerMap) do
		sServerList = sServerList..nServerID..","
	end
	sServerList = string.sub(sServerList, 1, -2)
	if sServerList == "" then
		return
	end

	local nTimeNow = os.time()
	local sql = "select * from activitybook where srvid in (%s) and %d>=starttime and %d<endtime and state=0;"
	sql = string.format(sql, sServerList, nTimeNow, nTimeNow)
	oMysql:Query(sql)

	local nNumRows = oMysql:NumRows()
	if nNumRows <= 0 then
		return
	end

	local nProcRows = 0
	local tActStateMap = {}
	while oMysql:FetchRow() do
		local nID, nSrvID, nActID, nSubActID, nExtData, nStartTime, nEndTime = 
		oMysql:ToInt32("id", "srvid", "actid", "subactid", "roundid", "starttime", "endtime")

		local tAct = {nIndex=nID, nBeginTime=nStartTime, nEndTime=nEndTime, nActID=nActID, nSubActID=nSubActID, nExtID=nExtData}
		tActStateMap[nID] = {nState=-1, nActID=nActID, nSubActID=nSubActID, nExtData=nExtData, nSrvID=nSrvID} -- nState:-1失败,1成功

		local tActConf = ctHuoDongConf[nActID]
		if not tActConf then
			LuaTrace("预约活动配置不存在:", tAct)
			nProcRows = nProcRows + 1

		else
			if tActConf.bCrossServer then
				goRemoteCall:CallWait("BookActOpenReq", function(tSuccList)
					for _, tSucAct in ipairs(tSuccList or {}) do
						local tActState = tActStateMap[tSucAct.nIndex]
						tActState.nState = 1
						tActState.nBeginTime = tSubAct.nBeginTime
						tActState.nEndTime = tSubAct.nBeginTime
						tActState.nAwardTime = tSubAct.nAwardTime
					end
					nProcRows = nProcRows + 1

				end, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, {tAct})
			else
				goRemoteCall:CallWait("BookActOpenReq", function(tSuccList)
					for _, tSucAct in ipairs(tSuccList or {}) do
						local tActState = tActStateMap[tSucAct.nIndex]
						tActState.nState = 1
						tActState.nBeginTime = tSubAct.nBeginTime
						tActState.nEndTime = tSubAct.nBeginTime
						tActState.nAwardTime = tSubAct.nAwardTime
					end
					nProcRows = nProcRows + 1

				end, nSrvID, goServerMgr:GetGlobalService(nSrvID, 20), 0, {tAct})
			end
		end
	end

	goTimerMgr:Interval(15, function(nTimerID)
		goTimerMgr:Clear(nTimerID)
		LuaTrace("预约活动处理结果", "请求:"..nNumRows, "处理:"..nProcRows)
		for nID, tActState in pairs(tActStateMap) do
			if tActState.nState == 1 then
				LuaTrace("预约活动开启成功", nID, tActState)

				local nSrvID = tActState.nSrvID
				local tActConf = ctHuoDongConf[tActState.nActID]
				local sActName = tActConf.sName
				local nActID, nSubActID = tActState.nActID, tActState.nSubActID
				local tSubActConf = ctTimeAwardConf[nSubActID]
				local sSubActName = tSubActConf and tSubActConf.sName or ""
				local nRounID = tActState.nExtData
				local nPropID = 0

				local nBeginTime = tActState.nBeginTime
				local nEndTime = tActState.nEndTime
				local nAwardTime = tActState.nAwardTime
				local sTime = os.date("%Y-%m-%d %X", nBeginTime)
				local eTime = os.date("%Y-%m-%d %X", nEndTime)
				local aTime = os.date("%Y-%m-%d %X", nEndTime+nAwardTime)
				local sSql = string.format("replace into activity set actid=%d,subactid=%d,actname='%s',subactname='%s',"
					.."stime='%s',etime='%s',atime='%s',srvid=%d,roundid=%d,propid=%d,time=%d;"
					, nActID, nSubActID, sActName, sSubActName, sTime, eTime, aTime, nSrvID, nRounID, nPropID, os.time())
				oMysql:Query(sSql)

			else
				LuaTrace("预约活动开启失败", nID, tActState)
			end
			local sql = string.format("update activitybook set state=%d where id=%d;", tActState.nState, nID)
			oMysql:Query(sql)
		end
	end)
end

goHDBook = goHDBook or CHDBook:new()
