--神魔志
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

_ctShenMoZhiConf = {}
_ctShenMoZhiBXConf = {}
local function _PreShenMoZhiConf()
    for nGuanQia,tData in pairs(ctShenMoZhiConf) do
		local nChapter = tData["nChapter"]
		local nType = tData["nType"]
		if not _ctShenMoZhiConf[nType] then
			_ctShenMoZhiConf[nType] = {}
		end
		if not _ctShenMoZhiConf[nType][nChapter] then
			_ctShenMoZhiConf[nType][nChapter] ={}
		end
		_ctShenMoZhiConf[nType][nChapter][nGuanQia] = tData
	end
end

local function _PreShenMoZhiBXConf()
    for nID,tData in pairs(ctShenMoZhiBXConf) do
		local nChapter = tData["nChapter"]
		local nType = tData["nType"]
		if not _ctShenMoZhiBXConf[nType] then
			_ctShenMoZhiBXConf[nType] = {}
		end
		_ctShenMoZhiBXConf[nType][nChapter] = tData
	end
end

_PreShenMoZhiConf()
_PreShenMoZhiBXConf()

function CShenMoZhiData:Ctor(oRole)
	self.m_oRole = oRole
	self.m_bDirty = false
	self.m_tPassGuanQia = {} 		 --已经通过的关卡
	self.m_tStarGuanQia = {} 		 --关卡星数
	self.m_tChapterStarReward = {}	 --已经领取的关卡奖励
end

function CShenMoZhiData:GetType()
	return gtModuleDef.tShenMoZhi.nID, gtModuleDef.tShenMoZhi.sName
end

function CShenMoZhiData:LoadData(tData)
	tData = tData or {}
	local tList = tData.tPassGuanQia or {}
	local tList2 = {}
	for _,nGuanQia in pairs(tList) do
		tList2[nGuanQia] = true
	end
	self.m_tPassGuanQia = tList2
	self.m_tStarGuanQia = tData.tStarGuanQia or {}
	self.m_tChapterStarReward = tData.m_tChapterStarReward or self.m_tChapterStarReward
end
function CShenMoZhiData:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tList = self.m_tPassGuanQia or {}
    local tList2 = {}
    for nGuanQia,_ in pairs(tList) do
    	table.insert(tList2,nGuanQia)
    end
    local tData = {}
    tData.tPassGuanQia = tList2
    tData.tStarGuanQia = self.m_tStarGuanQia or {}
    tData.m_tChapterStarReward = self.m_tChapterStarReward or {}
    return tData
end

function CShenMoZhiData:Online()
	self:SyncTypeChapterData()
end

function CShenMoZhiData:HasPass(nGuanQia)
	return self.m_tPassGuanQia[nGuanQia]
end

function CShenMoZhiData:PassGuanQia(nGuanQia,nStar)
	self.m_tPassGuanQia[nGuanQia] = true
	local nOldStar = self.m_tStarGuanQia[nGuanQia] or 0
	if nOldStar < nStar then
		self.m_tStarGuanQia[nGuanQia] = nStar
	end
	local tMsg = {nID = nGuanQia,nStar = nStar}
	self.m_oRole:SendMsg("ShenMoZhiFightRet",{tGuanQia = tMsg, tGuanQiaList = self:CheckClearanceChapter()})
	local nAddStar = math.max(nStar-nOldStar,0)
	if nAddStar > 0 then
		self.m_oRole:PushAchieve("神魔志总星数",{nValue = nAddStar})
	end
	self:MarkDirty(true)
end

--检查当前通关最大章节
function CShenMoZhiData:CheckClearanceChapter()
	local tChapterList = {}
	for nGuanQia, _ in pairs(self.m_tPassGuanQia) do
		local tChapter = ctShenMoZhiConf[nGuanQia]
		assert(tChapter, string.format("神魔志配置错误<%d>",  nGuanQia))
		if _ctShenMoZhiConf[tChapter.nType] and _ctShenMoZhiConf[tChapter.nType][tChapter.nChapter] then
			if not tChapterList[tChapter.nType] then
				tChapterList[tChapter.nType] = {}
			end
			if not tChapterList[tChapter.nType][tChapter.nChapter] then
				tChapterList[tChapter.nType][tChapter.nChapter] = true
			end
			local tChapterDta = _ctShenMoZhiConf[tChapter.nType][tChapter.nChapter]
			for nGuanQia, _ in pairs(tChapterDta) do
				if not self.m_tPassGuanQia[nGuanQia] then
					tChapterList[tChapter.nType][tChapter.nChapter] = nil
				end
			end
		end
	end
	local tChapterData = {}
	for nType, tChapter in pairs(tChapterList) do
		local nMaxChapter
		for nChapter, bValue in pairs(tChapter) do
			if not nMaxChapter then
				nMaxChapter = nChapter
			end
			if nChapter > nMaxChapter then
				nMaxChapter = nChapter
			end
		end
		if nMaxChapter then
			table.insert(tChapterData, {nType = nType, nMaxChapter = nMaxChapter})
		end
	end
	return tChapterData
end

function CShenMoZhiData:GetChapterData(nType,nChapter)
	local tData = _ctShenMoZhiConf[nType] or {}
	return tData[nChapter] or {}
end

function CShenMoZhiData:GetStar(nGuanQia)
	return self.m_tStarGuanQia[nGuanQia] or 0
end

function CShenMoZhiData:GetAllStar()
	local nAllStar = 0
	for nGuanQia,nStar in pairs(self.m_tStarGuanQia) do
		nAllStar = nAllStar + nStar
	end
	return nAllStar
end

function CShenMoZhiData:GetChapterStarRewardData(nType,nChapter)
	local tData = self.m_tChapterStarReward[nType] or {}
	tData = tData[nChapter] or {}
	return tData
end

function CShenMoZhiData:SetChapterStarReward(nType,nChapter,nStar)
	self:MarkDirty(true)
	if not self.m_tChapterStarReward[nType] then
		self.m_tChapterStarReward[nType] ={}
	end
	if not self.m_tChapterStarReward[nType][nChapter] then
		self.m_tChapterStarReward[nType][nChapter] ={}
	end
	table.insert(self.m_tChapterStarReward[nType][nChapter],nStar)
end

function CShenMoZhiData:IsChapterStarReward(nType,nChapter,nStar)
	local tData = self:GetChapterStarRewardData(nType,nChapter)
	for _,nStarReward in pairs(tData) do
		if nStarReward == nStar then
			return true
		end
	end
	return false
end

function CShenMoZhiData:LastChapterRedHot(nType,nChapter)
	local bFlag = false
	if nChapter > 1 then
		nChapter = nChapter - 1
		tChapterStarReward = self:GetChapterStarRewardData(nType,nChapter)
		if table.Count(tChapterStarReward) < 3 then
			bFlag = true
		end
	end
	return bFlag
end

function CShenMoZhiData:PackChapterData(nType,nChapter)
	local tChapterData = self:GetChapterData(nType,nChapter)
	if table.Count(tChapterData) <= 0 then
		return {}
	end
	local tGuanQia = {}
	local tGuanQiaList = table.Keys(tChapterData)
	table.sort(tGuanQiaList)
	for _,nGuanQia in ipairs(tGuanQiaList) do
		local nGuanQiaStar = self:GetStar(nGuanQia)
		table.insert(tGuanQia,{nID = nGuanQia,nStar=nGuanQiaStar}) 
	end
	local tMsg = {}
	tMsg.nType = nType
	tMsg.nChapter = nChapter
	tMsg.tGuanQia = tGuanQia
	tMsg.tChapterStarReward = self:GetChapterStarRewardData(nType,nChapter)
	tMsg.bLastChapterRedHot = self:LastChapterRedHot(nType,nChapter)
	tMsg.nStar = self:GetAllStar()
	tMsg.tGuanQiaList = self:CheckClearanceChapter()
	return tMsg
end

function CShenMoZhiData:OpenShenMoZhiReq(tData)
	tData = tData or {}
	local nType = tData["nType"] or 1
	local nChapter = tData["nChapter"] or 1
	local tChapterData = self:GetChapterData(nType,nChapter)
	if table.Count(tChapterData) <= 0 then
		return
	end
	local tMsg = self:PackChapterData(nType,nChapter)
	self.m_oRole:SendMsg("OpenShenMoZhiRet",{tChapter = tMsg})
	--self:CheckClearanceChapter()
end

function CShenMoZhiData:GetChapterStar(nType,nChapter)
	local tChapterData = self:GetChapterData(nType,nChapter)
	local nStar = 0
	for nGuanQia,tData in pairs(tChapterData) do
		nStar = nStar + self:GetStar(nGuanQia)
	end
	return nStar
end

function CShenMoZhiData:ShenMoZhiStarRewardReq(tData)
	tData = tData or {}
	local nType = tData["nType"] or 0
	local nChapter = tData["nChapter"] or 0
	local nRewardStar = tData["nStar"] or 0
	if self:IsChapterStarReward(nType,nChapter,nRewardStar) then
		self.m_oRole:Tips("已领取奖励")
		return
	end
	local nChapterStar = self:GetChapterStar(nType,nChapter)
	if nChapterStar < nRewardStar then
		self.m_oRole:Tips("未完成对应星数，不能领取奖励")
		return
	end
	local oRole = self.m_oRole
	local nFreeGrid = oRole.m_oKnapsack:GetFreeGrid(1)
	if nFreeGrid == 0 then
		return self.m_oRole:Tips("背包空间不足，请及时清理背包")
	end

	local tStarRewardData = self:GetStarRewardData(nType,nChapter,nRewardStar)
	if not tStarRewardData then
		return
	end
	self:SetChapterStarReward(nType,nChapter,nRewardStar)
	
	for _,tRewardData in pairs(tStarRewardData) do
        local nItemType, nItemID,nNum = table.unpack(tRewardData)
        self.m_oRole:AddItem(nItemType,nItemID,nNum,"神魔志星级奖励",false,true)
    end
	
	local tMsg = {}
	tMsg.nType = nType
	tMsg.nChapter = nChapter
	tMsg.tRewardStar = self:GetChapterStarRewardData(nType,nChapter)
	self.m_oRole:SendMsg("ShenMoZhiStarRewardRet",tMsg)
end

function CShenMoZhiData:GetStarRewardData(nType,nChapter,nStar)
	local tData = _ctShenMoZhiBXConf[nType][nChapter] or {}
	if nStar == 5 then
		return tData["tCopperItemReward"]
	elseif nStar == 10 then
		return tData["tSilverItemReward"]
	elseif nStar == 15 then
		return tData["tGoldItemReward"]
	end
end

function CShenMoZhiData:SyncTypeChapterData()
	local tMsg = self:PackTypeChapterData()
	self.m_oRole:SendMsg("OnlineShenMoZhiDataRet",{tChapter = tMsg})
end

function CShenMoZhiData:PackTypeChapterData()
	local tChapter = {}
	for nGuanQia,_ in pairs(self.m_tPassGuanQia) do
		local tGuanQiaData = ctShenMoZhiConf[nGuanQia]
		if tGuanQiaData then
			local nType = tGuanQiaData["nType"]
			local nChapter = tGuanQiaData["nChapter"]
			if not tChapter[nType] or tChapter[nType] < nChapter then
				tChapter[nType] = nChapter
			end
		end
	end
	local tRet = {}
	for nType,nChapter in pairs(tChapter) do
		local tData = self:PackChapterData(nType,nChapter)
		table.insert(tRet,tData)
	end
	if #tRet <= 0 then
		local tData = self:PackChapterData(1,1)
		table.insert(tRet,tData)
	end

	return tRet
end

function CShenMoZhiData:GetTypeByGuanQia(nGuanQia)
	local tGuanQiaData = ctShenMoZhiConf[nGuanQia]
	if tGuanQiaData then
		return tGuanQiaData["nType"]
	end
end