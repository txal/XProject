--滚动公告管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CNoticeMgr:Ctor()
	self.m_tNoticeMap = {} 	--{[id]={nBeginTime=0, nEndTime=0, nInterval=0, nLastTime=0, nVIP=0, sCont=""}, ...}
	self.m_tNoticeTick = {} --{[id]=tickid, ...}
	self.m_nUpdateTimer = nil

	--不保存
	-- self.m_bDirty = false
	-- self.m_nSaveTimer = nil
end

function CNoticeMgr:LoadData()
	self:OnLoaded()
end

function CNoticeMgr:OnLoaded()
	self.m_nUpdateTimer = goTimerMgr:Interval(60, function() self:OnUpdateTimer() end)
end

function CNoticeMgr:SaveData()
end

function CNoticeMgr:OnRelease()
	-- self:SaveData()
	-- goTimerMgr:Clear(self.m_nSaveTimer)
	-- self.m_nSaveTimer = nil

	goTimerMgr:Clear(self.m_nUpdateTimer)
	self.m_nUpdateTimer = nil

	for nID, nTimer in pairs(self.m_tNoticeTick) do
		goTimerMgr:Clear(nTimer)
	end
	self.m_tNoticeTick = nil
end

function CNoticeMgr:IsDirty() return self.m_bDirty end
function CNoticeMgr:MarkDirty(bDirty) self.m_bDirty = bDirty end

--广播公告
function CNoticeMgr:DoNotice(nID)
	print("CNoticeMgr:DoNotice***", nID)
	local tNotice = self.m_tNoticeMap[nID]
	if not tNotice then
		return
	end

	local function _fnCondSessionList(nSource, nVIP)
		local function _fnCondCheck(oRole)
			if nSource > 0 and nVIP > 0 then
				if oRole:GetSource() == nSource and oRole:GetVIP() >= nVIP then
					return true
				end
			elseif nSource > 0 then
				if oRole:GetSource() == nSource then
					return true
				end
			elseif nVIP > 0 then
				if oRole:GetVIP() >= nVIP then
					return true
				end
			else
				assert(false, "参数错误:"..nSource.."-"..nVIP)
			end
		end
		local tSessionList = {}
		local tSSMap = goGPlayerMgr:GetRoleSSMap()
		for nSS, oRole in pairs(tSSMap) do
			if oRole:IsOnlnie() and _fnCondCheck(oRole) then
				tSessionList[#tSessionList] = oRole:GetServer()
				tSessionList[#tSessionList] = oRole:GetSession()
			end
		end
		return tSessionList
	end

	if tNotice.nVIP > 0 or tNotice.nSource > 0 then
		local tSessionList = _fnCondSessionList(tNotice.nVIP, tNotice.nSource)
		CmdNet.PBBroadcastExter("ScrollNoticeRet", tSessionList, {sCont=tNotice.sCont})
	else
		CmdNet.PBSrv2All("ScrollNoticeRet", {sCont=tNotice.sCont})
	end
end

--移除公告
function CNoticeMgr:RemoveNotice(nID)
	if self.m_tNoticeMap[nID] then
		self.m_tNoticeMap[nID] = nil

		goTimerMgr:Clear(self.m_tNoticeTick[nID])
		self.m_tNoticeTick[nID] = nil
	end
end

--公告到时
function CNoticeMgr:OnNoticeTimer(nID)
	local tNotice = self.m_tNoticeMap[nID]
	if not tNotice then
		return
	end
	local nNowSec = os.time()
	if nNowSec < tNotice.nBeginTime then
		return
	end
	if nNowSec - tNotice.nLastTime < tNotice.nInterval then
		return
	end
	self:DoNotice(nID)
	if nNowSec >= tNotice.nEndTime then
		self:RemoveNotice(nID)
	else
		tNotice.nLastTime = nNowSec
		goTimerMgr:Clear(self.m_tNoticeTick[nID])
		self.m_tNoticeTick[nID] = goTimerMgr:Interval(tNotice.nInterval, function() self:OnNoticeTimer(nID) end)
	end
end

--更新跑马灯公告,只能新增和删除,不能修改
function CNoticeMgr:OnUpdateTimer()
	local oMysql = goDBMgr:GetMgrMysql()
	local sSqlFmt = "select id,`source`,`content`,`interval`,begintime,endtime,vip from notice where serverid in(0,%d) and endtime>%d and `interval`>0;"
	local sSql = string.format(sSqlFmt, gnServerID, os.time())
	if not oMysql:Query(sSql) then
		return
	end
	local tNoticeList = {}
	while oMysql:FetchRow() do
		local sCont = oMysql:ToString("content")
		local nID, nSource, nInterval, nBeginTime, nEndTime, nVIP = oMysql:ToInt32("id", "source", "interval", "begintime", "endtime", "vip")
		table.insert(tNoticeList, nID)

		if not self.m_tNoticeMap[nID] then
			self.m_tNoticeMap[nID] = {nBeginTime=nBeginTime, nEndTime=nEndTime, nInterval=nInterval, sCont=sCont, nLastTime=0, nVIP=nVIP, nSource=nSource}
			local nTimerInterval = math.max(os.time()-nBeginTime, nInterval)
			self.m_tNoticeTick[nID] = goTimerMgr:Interval(nTimerInterval, function() self:OnNoticeTimer(nID) end)
			self:OnNoticeTimer(nID)
		end
	end
	for nID, tNotice in pairs(self.m_tNoticeMap) do
		if not table.InArray(nID, tNoticeList) then
			self:RemoveNotice(nID)
		end
	end
end

--后台调用
function CNoticeMgr:BrowserSendNotice(nID, nStartTime, nEndTime, nInterval, sCont)
end

--游戏内部发公告
function CNoticeMgr:SendNoticeReq(sCont)
	print("CNoticeMgr:SendNoticeReq***", sCont)
	CmdNet.PBSrv2All("ScrollNoticeRet", {sCont=sCont})
end

goNoticeMgr = goNoticeMgr or CNoticeMgr:new()