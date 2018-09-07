--滚动公告管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAutoSaveTime = 5*60 	--自动保存时间
local nServerID = gnServerID

function CNoticeMgr:Ctor()
	self.m_tNoticeMap = {} 	--{[id]={nStartTime=0, nEndTime=0, nInterval=0, nLastTime=0, sCont=""}, ...}

	--不保存
	self.m_bDirty = false
	self.m_nSaveTimer = nil
	self.m_tNoticeTick = {} --{[id]=tickid, ...}
end

function CNoticeMgr:LoadData()
	local sData = goDBMgr:GetSSDB(nServerID, "global"):HGet(gtDBDef.sNoticeDB, "data")
	if sData ~= "" then
		local nNowSec = os.time()
		local tData = cjson.decode(sData)
		for nID, tNotice in pairs(tData.m_tNoticeMap) do
			if tNotice.nEndTime > nNowSec then --没结束得才加载
				self.m_tNoticeMap[nID] = tNotice

			else --有已结束的要保存
				print("公告过期:", nID, tNotice)
				self:MarkDirty(true)

			end
		end
	end
	self:OnLoaded()
end

function CNoticeMgr:OnLoaded()
	for nID, tNotice in pairs(self.m_tNoticeMap) do
		self.m_tNoticeTick[nID] = goTimerMgr:Interval(tNotice.nInterval, function() self:OnNoticeTimer(nID) end)
	end
	self.m_nSaveTimer = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CNoticeMgr:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tNoticeMap = self.m_tNoticeMap
	goDBMgr:GetSSDB(nServerID, "global"):HSet(gtDBDef.sNoticeDB, "data", cjson.encode(tData))
end

function CNoticeMgr:OnRelease()
	self:SaveData()

	goTimerMgr:Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = nil
	
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
	CmdNet.PBSrv2All("NoticeRet", {sCont=tNotice.sCont})
end

--移除公告
function CNoticeMgr:RemoveNotice(nID)
	if self.m_tNoticeMap[nID] then
		self.m_tNoticeMap[nID] = nil
		self:MarkDirty(true)

		goTimerMgr:Clear(self.m_tNoticeTick[nID])
		self.m_tNoticeTick[nID] = nil
	end
	return true
end

--公告到时
function CNoticeMgr:OnNoticeTimer(nID)
	local tNotice = self.m_tNoticeMap[nID]
	if not tNotice then
		return
	end
	local nNowSec = os.time()
	if nNowSec < tNotice.nStartTime then
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
		self:MarkDirty(true)
	end
end

--GM发公告
function CNoticeMgr:GMSendNotice(nID, nStartTime, nEndTime, nInterval, sCont)
	if nID <= 0 or nInterval <= 0 or sCont =="" or not (nStartTime and nEndTime) then
		return LuaTrace("发送公告失败:", nID, nStartTime, nEndTime, nInterval, sCont)
	end
	self.m_tNoticeMap[nID] = {nStartTime=nStartTime, nEndTime=nEndTime, nInterval=nInterval, sCont=sCont, nLastTime=0}
	if self.m_tNoticeTick[nID] then
		goTimerMgr:Clear(self.m_tNoticeTick[nID])
	end
	self.m_tNoticeTick[nID] = goTimerMgr:Interval(nInterval, function() self:OnNoticeTimer(nID) end)
	self:OnNoticeTimer(nID)
	self:MarkDirty(true)
	return true
end

goNoticeMgr = goNoticeMgr or CNoticeMgr:new()