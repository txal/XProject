--配置预处理
local nMaxCircleDay = 0
_ctHDCircleConf = {}
local function _PreprocessConf()
	for _, tConf in ipairs(ctHDCircleConf) do
		nMaxCircleDay = math.max(tConf.nDay, nMaxCircleDay)
		if not _ctHDCircleConf[tConf.nDay] then
			_ctHDCircleConf[tConf.nDay] = {}
		end
		table.insert(_ctHDCircleConf[tConf.nDay], tConf)
	end
end
_PreprocessConf()

--活动循环模块
function CHDCircle:Ctor()
	self.m_oMysql = MysqlDriver:new()
	self.m_nOpenTime = os.time()
	self:Init()

	self.m_tOpenMap = {}
	self.m_bDirty = false
	self.m_nTick = nil
end

function CHDCircle:Init()
	local tConf = gtMgrMysqlConf
	local bRes = self.m_oMysql:Connect(tConf.sIP, tConf.nPort, tConf.sDBName, tConf.sUserName, tConf.sPassword, "utf8")
	assert(bRes, "连接数据库失败:", tConf)

	bRes = self.m_oMysql:Query("select time from serverlist where serverid="..gnServerID)
	assert(bRes, "查询后台服务器失败")
	assert(self.m_oMysql:FetchRow(), "后台服务器不存在:"..gnServerID)
	self.m_nOpenTime = self.m_oMysql:ToInt32("time")
	local tDate = os.date("*t", self.m_nOpenTime)
	LuaTrace("开服时间:", self.m_nOpenTime, tDate)
	tDate.hour, tDate.min, tDate.sec = 0, 0, 0
	self.m_nOpenZeroTime = os.time(tDate)
end

function CHDCircle:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHDCircleDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_tOpenMap = tData.m_tOpenMap
	end
	self:StartMinTimer()
end

function CHDCircle:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	local tData = {m_tOpenMap=self.m_tOpenMap}
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHDCircleDB, "data", cjson.encode(tData))
end

function CHDCircle:OnRelease()
	self:SaveData()
	goTimerMgr:Clear(self.m_nTick)
	self.m_nTick = nil
end

function CHDCircle:IsDirty()
	return self.m_bDirty
end

function CHDCircle:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

--分钟计时器
function CHDCircle:StartMinTimer()
	goTimerMgr:Clear(self.m_nTick)
	self.m_nTick = goTimerMgr:Interval(os.NextMinTime(os.time()), function() self:OnMinTimer() end)	
end

--分钟计时器回调
function CHDCircle:OnMinTimer()
	self:StartMinTimer()
	local tConfList = self:GetNeedOpenAct()
	if #tConfList <= 0 then
		return
	end
	self:OpenAct(tConfList)
end

--取开服到现在的天数
function CHDCircle:GetSrvOpenDay()
	local nNowSec = os.time()
	local nPassTime = nNowSec - self.m_nOpenZeroTime
	local nDay = math.ceil(nPassTime/(24*3600))
	return nDay
end

--取要开启的活动ID
function CHDCircle:GetNeedOpenAct()
	local nOpenDay = self:GetSrvOpenDay()
	local nRawOpenDay = nOpenDay
	nOpenDay = nOpenDay % (nMaxCircleDay+1)
	if nOpenDay == 0 then
		nOpenDay = 1
	end
	LuaTrace("检测开服日期:", nOpenDay)

	local tOpenList = {}
	local tConfList = _ctHDCircleConf[nOpenDay]
	if not tConfList then
		return tOpenList
	end
	for _, tConf in ipairs(tConfList) do
		--不开放
		if tConf.nRunTimes < 0 then
		--有次数限制
		elseif tConf.nRunTimes > 0 and (self.m_tOpenMap[tConf.nIndex] or 0) >= tConf.nRunTimes then
		else
			local tDate = os.date("*t", os.time())
			if tDate.hour == tConf.tOpenTime[1][1] and tDate.min == tConf.tOpenTime[1][2] then
				table.insert(tOpenList, tConf)
			end
		end
	end
	return tOpenList
end

--开启活动请求
function CHDCircle:OpenAct(tOpenList)
	local tList = {}
	for _, tConf in ipairs(tOpenList) do
		LuaTrace("开启活动", tConf.nIndex, tConf.nActID, tConf.nSubActID)
		table.insert(tList, {nIndex=tConf.nIndex, tEndTime=tConf.tEndTime[1], nActID=tConf.nActID, nSubActID=tConf.nSubActID, nExtID=tConf.nExtID, nExtID1=tConf.nExtID1})
	end
	Srv2Srv.HDCircleOpenReq(gtNetConf:LogicService(), 0, tList)
end

--开启活动成功
function CHDCircle:HDCircleOpenRet(tList)
	for _, tData in ipairs(tList) do
		local nIndex = tData.nIndex
		local tConf = ctHDCircleConf[nIndex]
		local nBeginTime = tData.nBeginTime
		local nEndTime = tData.nEndTime
		local nAwardTime = tData.nAwardTime
		self.m_tOpenMap[nIndex] = (self.m_tOpenMap[nIndex] or 0) + 1
		self:MarkDirty(true)
		LuaTrace("活动开启成功", nIndex, tConf.nActID, tConf.nSubActID)


		local sTime = os.date("%Y-%m-%d %X", nBeginTime)
		local eTime = os.date("%Y-%m-%d %X", nEndTime)
		local aTime = os.date("%Y-%m-%d %X", nAwardTime)
		local nTime = os.time()

		--发公告
		local sTitle = tConf.sTitle
		local sNotice = tConf.sNotice
		if sTitle ~= "0" then
			sNotice = string.format(sNotice, sTime.."-"..eTime)
			self.m_oMysql:Query(string.format("delete from gamenotice where title='%s';", sTitle))
			self.m_oMysql:Query(string.format("insert into gamenotice set server=%d,title='%s',content='%s',`time`=%d,endtime=%d,effect=1;",
				gnServerID, sTitle, sNotice, os.time(), nAwardTime))
		end

		--同步后台活动列表
		local nSrvID = gnServerID
		local nActID, nSubActID = tConf.nActID, tConf.nSubActID
		local sActName = ctHuoDongConf[nActID].sName
		local sSubActName = ""
		if nSubActID > 0 then
			sSubActName = ctTimeAwardConf[nSubActID].sName
		end
		local nRounID = tConf.nExtID
		local nPropID = tConf.nExtID1
		local sSql = string.format("replace into activity set actid=%d,subactid=%d,actname='%s',subactname='%s',"
			.."stime='%s',etime='%s',atime='%s',srvid=%d,roundid=%d,propid=%d,time=%d;"
			, nActID, nSubActID, sActName, sSubActName, sTime, eTime, aTime, nSrvID, nRounID, nPropID, nTime)
		self.m_oMysql:Query(sSql)
	end
end

goHDCircle = goHDCircle or CHDCircle:new()