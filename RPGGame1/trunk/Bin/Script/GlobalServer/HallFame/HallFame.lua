--名人堂
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHallFame:Ctor()
	self.m_tTitleMap = {} --{[title]={roleid, congrat}, ...}
	self.m_tCongratMap = {} --{[roleid]={[title]=false, ...}, ...}
	self.m_nLastCongratTime = 0

	self.m_nZeroTimer = nil
	self.m_nSaveTimer = nil
end

function CHallFame:RegZeroTimer()
	GetGModule("TimerMgr"):Clear(self.m_nZeroTimer)
	local nNextZeroTime = os.NextHourTime1(0)
	self.m_nZeroTimer = GetGModule("TimerMgr"):Interval(nNextZeroTime, function() self:OnZeroTimer() end)
end

function CHallFame:RegAutoSave()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

function CHallFame:Release()
	GetGModule("TimerMgr"):Clear(self.m_nZeroTimer)
	GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
	self:SaveData()
end

function CHallFame:LoadData()
	local sData = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID()):HGet(gtDBDef.sHallFameDB, "data")
	if sData ~= "" then
		local tData = cseri.decode(sData)
		self.m_tTitleMap = tData.m_tTitleMap
		self.m_tCongratMap = tData.m_tCongratMap
		self.m_nLastCongratTime = tData.m_nLastCongratTime
	end

	self:RegZeroTimer()
	self:RegAutoSave()
end

function CHallFame:SaveData()
	if not self:IsDirty() then
		return
	end
	local tData = {}
	tData.m_tTitleMap = self.m_tTitleMap
	tData.m_tCongratMap = self.m_tCongratMap
	tData.m_nLastCongratTime = self.m_nLastCongratTime

	goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID()):HSet(gtDBDef.sHallFameDB, "data", cseri.encode(tData))
	self:MarkDirty(false)
end

function CHallFame:IsDirty() return self.m_bDirty end
function CHallFame:MarkDirty(bDirty) self.m_bDirty = bDirty end

function CHallFame:OnZeroTimer()
	self:RegZeroTimer()
	self:SyncInfo()
end

function CHallFame:ValidTitle(nTitleID)
	for _, nTmpTitleID in pairs(gtCBTitle) do
		if nTmpTitleID == nTitleID then
			return true
		end
	end
end

--移除旧的，添加新的
function CHallFame:AddTitle(nTitleID, nRoleID)
	if not self:ValidTitle(nTitleID) then
		return
	end
	local tOldTitle = self.m_tTitleMap[nTitleID]
	if tOldTitle and tOldTitle[1] == nRoleID then
		return
	end

	if tOldTitle and tOldTitle[1] ~= nRoleID then
		local oOldRole = goGPlayerMgr:GetRoleByID(tOldTitle[1])
		local tData = {nOpType=gtAppellationOpType.eRemove, nConfID=nTitleID}
		oOldRole:AppellationUpdate(tData)
	end
	self.m_tTitleMap[nTitleID] = {nRoleID, ""}
	self:MarkDirty(true)

	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local tData = {nOpType=gtAppellationOpType.eAdd, nConfID=nTitleID}
	oRole:AppellationUpdate(tData)

	self:SyncInfo()
end

function CHallFame:GetTitle(nTitleID)
	return self.m_tTitleMap[nTitleID]
end

function CHallFame:GetCongrat(nRoleID)
	if not os.IsSameDay(os.time(), self.m_nLastCongratTime, 0) then
		self.m_tCongratMap = {}
		self.m_nLastCongratTime = os.time()
		self:MarkDirty(true)
	end
	if not self.m_tCongratMap[nRoleID] then
		self.m_tCongratMap[nRoleID] = {}
		self:MarkDirty(true)
	end
	return self.m_tCongratMap[nRoleID]
end

--祝贺
function CHallFame:CongratReq(oRole, nTitleID)
	if not self:ValidTitle(nTitleID) then
		return
	end
	
	local tCongratMap = self:GetCongrat(oRole:GetID())
	if tCongratMap[nTitleID] then
		return oRole:Tips("今日已经祝贺过了，请明日再来")
	end
	tCongratMap[nTitleID] = true
	self:MarkDirty(true)

	local nGold = math.random(500, 1000)
	local tItemList = {{nType=gtItemType.eCurr, nID=gtCurrType.eJinBi, nNum=nGold}}
	oRole:AddItem(tItemList, "名人堂祝贺")
	self:SyncInfo(oRole)

	local sTips = "谢谢你的祝贺，一点小心意给你"
	local tTite = self:GetTitle(nTitleID)
	if tTite and tTite[2] ~= "" then
		sTips = tTite[2]
	end
	oRole:Tips(sTips)
	self:SyncInfo(oRole)
	Network:RMCall("OnCongratulate", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
end

--设置祝贺词
function CHallFame:SetCongratTipsReq(oRole, nTitleID, sTips)
	if string.len(sTips) >= 64*3 then 
		return oRole:Tips("贺词过长，64个汉字内")
	end
	local function fnCallback(bRes)
		bRes = bRes == nil and true or bRes
		if bRes then
			return oRole:Tips("贺词存在非法字符")
		end

		local tTitle = self:GetTitle(nTitleID)
		if not tTitle or tTitle[1] ~= oRole:GetID() then
			return oRole:Tips("请先获得称号")
		end
		tTitle[2] = sTips
		self:MarkDirty(true)
		oRole:SendMsg("HallFameSetCongratTipsRet", {nTitleID=nTitleID, sTips=sTips})
	end
	CUtil:HasBadWord(sTips, fnCallback)
end

--同步信息
function CHallFame:SyncInfo(oRole)
	local tMsgCache
	local function _fnMakeMsg(oTmpRole)
		if not tMsgCache then
			tMsgCache = {tList={}}
			for _, nTitleID in pairs(gtCBTitle) do
				local tTitle = self.m_tTitleMap[nTitleID]
				local tInfo = {nTitleID=nTitleID, nRoleID=0, sHeader=0, bCongrat=false, sTips=""}
				if tTitle then
					local oTitleRole = goGPlayerMgr:GetRoleByID(tTitle[1])
					tInfo.nRoleID = tTitle[1]
					tInfo.sHeader = oTitleRole:GetHeader()
					tInfo.sTips = tTitle[2]
				end
				table.insert(tMsgCache.tList, tInfo)
			end
		end
		local nTmpRoleID = oTmpRole:GetID()
		for _, tInfo in ipairs(tMsgCache.tList) do
			if self:GetCongrat(nTmpRoleID)[tInfo.nTitleID] then
				tInfo.bCongrat = false
			else
				tInfo.bCongrat = true
			end
		end
		return tMsgCache
	end
	if oRole then
		local tMsg = _fnMakeMsg(oRole)
		oRole:SendMsg("HallFameInfoRet", tMsg)
	else
		local tSSRoleMap = goGPlayerMgr:GetRoleSSMap()
		for _, oRole in pairs(tSSRoleMap) do
			local tMsg = _fnMakeMsg(oRole)
			oRole:SendMsg("HallFameInfoRet", tMsg)
		end
	end
end

function CHallFame:Online(oRole)
	self:SyncInfo(oRole)
end
