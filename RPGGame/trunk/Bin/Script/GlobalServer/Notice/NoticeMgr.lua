--公告管理模块

local nAutoSaveTime = 5*60 	--自动保存时间
function CNoticeMgr:Ctor()
	self.m_tNoticeMap = {} 	--{[id]={nStartTime=0, nEndTime=0, nInterval=0, nLastTime=0, sCont=""}, ...}

	--不保存
	self.m_bDirty = false
	self.m_nSaveTick = nil
	self.m_tNoticeTick = {} --{[id]=tickid, ...}
end

function CNoticeMgr:LoadData()
	print("加载公告数据")
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sNoticeDB, "notice")
	if sData ~= "" then
		local nNowSec = os.time()
		local tData = cjson.decode(sData)
		for nID, tNotice in pairs(tData.m_tNoticeMap) do
			if nNowSec < tNotice.nEndTime then --没结束得才加载
				self.m_tNoticeMap[nID] = tNotice
			else --有已结束的就要保存
				print("公告过期:", nID, tNotice)
				self:MarkDirty(true)
			end
		end
	end
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
	for nID, tNotice in pairs(self.m_tNoticeMap) do
		self.m_tNoticeTick[nID] = goTimerMgr:Interval(tNotice.nInterval, function() self:OnNoticeTimer(nID) end)
	end
end

function CNoticeMgr:SaveData()
	if not self.m_bDirty then return end
	self.m_bDirty = false
	local tData = {}
	tData.m_tNoticeMap = self.m_tNoticeMap
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sNoticeDB, "notice", cjson.encode(tData))
end

function CNoticeMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil

	for nID, nTick in pairs(self.m_tNoticeTick) do
		goTimerMgr:Clear(nTick)
		self.m_tNoticeTick[nID] = nil
	end
	self:SaveData()
end

--脏
function CNoticeMgr:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

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
		local tNotice = self.m_tNoticeMap[nID]
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
	local nNowSec = os.time() 
	if nID <= 0 or nInterval <= 0 or sCont =="" or not (nStartTime and nEndTime) then
		return LuaTrace("发送公告失败:", nID, nStartTime, nEndTime, nInterval, sCont)
	end
	self.m_tNoticeMap[nID] = {nStartTime=nStartTime, nEndTime=nEndTime, nInterval=nInterval, sCont=sCont, nLastTime=0}
	if self.m_tNoticeTick[nID] then goTimerMgr:Clear(self.m_tNoticeTick[nID]) end
	self.m_tNoticeTick[nID] = goTimerMgr:Interval(nInterval, function() self:OnNoticeTimer(nID) end)
	self:OnNoticeTimer(nID)
	self:MarkDirty(true)
	return true
end

goNoticeMgr = goNoticeMgr or CNoticeMgr:new()