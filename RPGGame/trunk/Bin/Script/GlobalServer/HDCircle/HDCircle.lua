--活动循环模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--配置预处理
local nMaxCircleDay = 0
local _ctHDCircleConf = {}
local _ctHDCircleConfMap = {}
local function _PreprocessConf()
	for _, tConf in pairs(ctHDCircleConf) do
		nMaxCircleDay = math.max(tConf.nDay, nMaxCircleDay)
		if not _ctHDCircleConf[tConf.nDay] then
			_ctHDCircleConf[tConf.nDay] = {}
			_ctHDCircleConfMap[tConf.nDay] = {}
		end
		table.insert(_ctHDCircleConf[tConf.nDay], tConf)
		_ctHDCircleConfMap[tConf.nDay][tConf.nActID.."-"..tConf.nSubActID] = tConf
	end
end
_PreprocessConf()

function CHDCircle:Ctor()
	self:Init()

	self.m_tOpenMap = {}
	self.m_nMinTimer = nil
	self.m_nAutoSave = nil
	self.m_bDirty = false
end

function CHDCircle:Init()
end

function CHDCircle:LoadData()
	local sData = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID()):HGet(gtDBDef.sHDCircleDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_tOpenMap = tData.m_tOpenMap
	end
	self:RegMinTimer()
	self:RegAutoSave()
end

function CHDCircle:RegAutoSave()
	self.m_nAutoSave = goTimerMgr:Interval(gnAutoSaveTime, function() self:SaveData() end)
end

function CHDCircle:SaveData()
	if not self:IsDirty() then
		return
	end
	local tData = {m_tOpenMap=self.m_tOpenMap}
	goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID()):HSet(gtDBDef.sHDCircleDB, "data", cjson.encode(tData))
	self:MarkDirty(false)
end

function CHDCircle:OnRelease()
	goTimerMgr:Clear(self.m_nMinTimer)
	self.m_nMinTimer = nil
	goTimerMgr:Clear(self.m_nAutoSave)
	self.m_nAutoSave = nil
	self:SaveData()
end

function CHDCircle:IsDirty() return self.m_bDirty end
function CHDCircle:MarkDirty(bDirty) self.m_bDirty = bDirty end

--分钟计时器
function CHDCircle:RegMinTimer()
	goTimerMgr:Clear(self.m_nMinTimer)
	self.m_nMinTimer = goTimerMgr:Interval(os.NextMinTime(os.time()), function() self:OnMinTimer() end)	
end

--分钟计时器回调
function CHDCircle:OnMinTimer()
	self:RegMinTimer()
	local tConfList = self:GetNeedOpenAct()
	local nOpenDay = goServerMgr:GetOpenDays(gnServerID)
	LuaTrace("循环活动开启检测======", nOpenDay, tConfList)
	if #tConfList <= 0 then
		return
	end
	self:OpenAct(tConfList)
end

--活动是否可以开启
function CHDCircle:CanActOpen(tConf, nTime)
	--不开放
	if tConf.nRunTimes < 0 then
		return
	end
	--跨服活动不能自动开启
	local tHDConf = ctHuoDongConf[tConf.nActID]
	if tHDConf.bCrossServer then
		--LuaTrace("不支持跨服循环活动:", tConf)
		return 
	end

	--有次数限制
	if tConf.nRunTimes >= 0 then
		local tInfo = self.m_tOpenMap[tConf.nIndex]
		if tConf.nRunTimes > 0 and tInfo and tInfo.nTimes >= tConf.nRunTimes then
			return
		end

		local tDate = os.date("*t", nTime)
		if tDate.hour >= tConf.tOpenTime[1][1] or (tDate.hour == tConf.tOpenTime[1][1] and tDate.min >= tConf.tOpenTime[1][2]) then
			if not tInfo or (tInfo and not os.IsSameDay(tInfo.nLastOpenTime, nTime, 0)) then
				return true
			end
		end
	end
end

--取要开启的活动ID
function CHDCircle:GetNeedOpenAct()
	local tOpenList = {}
	local nServerState = goServerMgr:GetServerState(gnServerID)
	if nServerState == 0 then --[0不可用; 1白名单可进; 2对外开放],因为运营启用前可能会调整开服时间
		return tOpenList
	end

	local nOpenDay = goServerMgr:GetOpenDays(gnServerID)
	nOpenDay = nOpenDay % (nMaxCircleDay+1)
	if nOpenDay == 0 then nOpenDay = 1 end

	local tConfList = _ctHDCircleConf[nOpenDay]
	if not tConfList then
		return tOpenList
	end

	--正常开启的
	for _, tConf in ipairs(tConfList) do
		if self:CanActOpen(tConf, os.time()) then
			table.insert(tOpenList, tConf)
		end
	end

	--无限单曲的
	for nIndex, tConf in pairs(ctHDCircleConf) do
		if tConf.nLoopType == 1 and self.m_tOpenMap[nIndex] then --已经正常开启过一次,并且当前在关闭状态
			if goHDMgr:GetActState(tConf.nActID, tConf.nSubActID) == CHDBase.tState.eClose then
				table.insert(tOpenList, tConf)
			end
		end
	end

	return tOpenList
end

--开启活动请求
function CHDCircle:OpenAct(tOpenList)
	local tActList = {}

	local tDate = os.date("*t", os.time())
	for _, tConf in ipairs(tOpenList) do
		LuaTrace("开启循环活动", tConf.nIndex, tConf.nActID, tConf.nSubActID)
		local nBeginTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tConf.tOpenTime[1][1], tConf.tOpenTime[1][2], 0) --时,分
		local nEndTime = nBeginTime+tConf.tEndTime[1][1]*24*3600+tConf.tEndTime[1][2]*3600+tConf.tEndTime[1][3]*60 --天,时,分
		table.insert(tActList, {nIndex=tConf.nIndex, nBeginTime=nBeginTime, nEndTime=nEndTime, nActID=tConf.nActID, nSubActID=tConf.nSubActID, nExtID=tConf.nExtID, nExtID1=tConf.nExtID1})
	end
	local tSuccList = goHDMgr:HDCircleActOpen(tActList)
	self:HDCircleOpenRet(tSuccList)
end

--开启活动成功
function CHDCircle:HDCircleOpenRet(tList)
	for _, tData in ipairs(tList) do
		local nIndex = tData.nIndex
		local tConf = ctHDCircleConf[nIndex]

		local nBeginTime = tData.nBeginTime
		local nEndTime = tData.nEndTime
		local nAwardTime = tData.nAwardTime

		self.m_tOpenMap[nIndex] = self.m_tOpenMap[nIndex] or {nTimes=0, nLastOpenTime=0}
		self.m_tOpenMap[nIndex].nTimes = self.m_tOpenMap[nIndex].nTimes + 1
		self.m_tOpenMap[nIndex].nLastOpenTime = os.time()
		self:MarkDirty(true)

		LuaTrace("循环活动开启成功", nIndex, tConf.nActID, tConf.nSubActID, tConf.sName)

		local sTime = os.date("%Y-%m-%d %X", nBeginTime)
		local eTime = os.date("%Y-%m-%d %X", nEndTime)
		local aTime = os.date("%Y-%m-%d %X", nAwardTime)
		local nTime = os.time()

		local oMgrMysql = goDBMgr:GetMgrMysql()
		--发公告
		local sTitle = tConf.sTitle
		local sNotice = tConf.sNotice
		if sNotice and sTitle and sTitle ~= "0" and sTitle ~= "" then
			sNotice = string.format(sNotice, sTime.."-"..eTime)
			oMgrMysql:Query(string.format("delete from gamenotice where title='%s';", sTitle))
			oMgrMysql:Query(string.format("insert into gamenotice set serverid=%d,title='%s',content='%s',`time`=%d,endtime=%d,effect=1;",
				gnServerID, sTitle, sNotice, os.time(), nAwardTime))
		end

		--同步后台活动列表
		local nSrvID = gnServerID
		local nActID, nSubActID = tConf.nActID, tConf.nSubActID
		local sActName = ctHuoDongConf[nActID].sName
		local sSubActName = nSubActID > 0 and "unknown" or ""
		local nRounID = tConf.nExtID
		local nPropID = tConf.nExtID1
		local sSql = string.format("replace into activity set actid=%d,subactid=%d,actname='%s',subactname='%s',"
			.."stime='%s',etime='%s',atime='%s',srvid=%d,roundid=%d,propid=%d,time=%d;"
			, nActID, nSubActID, sActName, sSubActName, sTime, eTime, aTime, nSrvID, nRounID, nPropID, nTime)
		oMgrMysql:Query(sSql)
	end
end

--取某一个活动下次开放时间
function CHDCircle:GetActNextOpenTime(nActID, nSubActID)
	local nServerState = goServerMgr:GetServerState(gnServerID)
	if nServerState == 0 then --[0不可用; 1白名单可进; 2对外开放],因为运营启用前可能会调整开服时间
		return 0, 0
	end

	nSubActID = nSubActID or 0
	local sKey = nActID.."-"..nSubActID

	local nOpenDay = goServerMgr:GetOpenDays(gnServerID)
	local nStartDay = nOpenDay % (nMaxCircleDay+1)
	if nStartDay == 0 then nStartDay = 1 end

	local tDate = os.date("*t", os.time())
	local nMaxDayTime = os.MakeTime(tDate.year, tDate.month, tDate.day, 23, 59, 0) --一天的最后一分钟

	local nNowZeroTime = os.ZeroTime(os.time())
	for k = nStartDay, nStartDay+nMaxCircleDay do
		local nDay = nStartDay % nMaxCircleDay
		if nDay == 0 then
			nDay = nMaxCircleDay
		end

		nMaxDayTime = nMaxDayTime + (k-nStartDay)*24*3600
		local tConfMap = _ctHDCircleConfMap[nDay]
		if tConfMap and tConfMap[sKey] then
			local tConf = tConfMap[sKey]
			if self:CanActOpen(tConf, nMaxDayTime) then
				local tTmpDate = os.date("*t", nMaxDayTime)
				local nBeginTime = os.MakeTime(tTmpDate.year, tTmpDate.month, tTmpDate.day, tConf.tOpenTime[1][1], tConf.tOpenTime[1][2], 0) --时,分
				local nEndTime = nBeginTime+tConf.tEndTime[1][1]*24*3600+tConf.tEndTime[1][2]*3600+tConf.tEndTime[1][3]*60 --天,时,分
				return nBeginTime, nEndTime
			end
		end
	end
	return 0, 0
end

--重置循环活动信息
function CHDCircle:GMReset(oRole)
	self.m_tOpenMap = {}
	self:MarkDirty(true)
	if oRole then 
		oRole:Tips("重置循环活动信息成功")
	end
end




goHDCircle = goHDCircle or CHDCircle:new()