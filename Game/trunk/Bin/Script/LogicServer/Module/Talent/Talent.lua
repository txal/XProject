CTalent.tType = 
{
	eJuji = 1,		--狙击
	eTuji = 2,		--突击
	eZhiLiao = 3,	--治疗
	eCount = 3,	
}

--天赋系统
function CTalent:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nTotalTalent = oPlayer:GetLevel() --总天赋点数
	self.m_nRemainTalent = self.m_nTotalTalent  --未分配点数
	self.m_tAllocTalent = {} --每类已配天赋点
	self.m_tTalentMap = {}
	self.m_nResetTimes = 0
end

function CTalent:LoadData(tData)
	self.m_nTotalTalent = tData.nTotalTalent or self.m_oPlayer:GetLevel()
	self.m_nRemainTalent = tData.nRemainTalent
	self.m_tAllocTalent = tData.tAllocTalent
	self.m_tTalentMap = tData.tTalentMap
	self.m_nResetTimes = tData.nResetTimes
	local nAllocTalent = 0
	for k, v in pairs(self.m_tAllocTalent) do
		nAllocTalent = nAllocTalent + v
	end
	self.m_nRemainTalent = math.max(0, self.m_nTotalTalent - nAllocTalent)
end

function CTalent:OnLevelChange(nOldLevel, nNewLevel)
	local nUpLevel = nNewLevel - nOldLevel
	if nUpLevel > 0 then
		self.m_nTotalTalent = self.m_nTotalTalent + nUpLevel
		self.m_nRemainTalent = self.m_nRemainTalent + nUpLevel
	end
end

function CTalent:SaveData()
	local tData = {}
	tData.nTotalTalent = self.m_nTotalTalent
	tData.nRemainTalent = self.m_nRemainTalent
	tData.tAllocTalent = self.m_tAllocTalent
	tData.tTalentMap = self.m_tTalentMap
	tData.nResetTimes = self.m_nResetTimes
	return tData
end

function CTalent:GetType()
	return gtModuleDef.tTalent.nID, gtModuleDef.tTalent.sName
end

--分配天赋点
function CTalent:SaveTalent(tSaveTalent)
	local tTalentList = tSaveTalent.tList
	local nRemainTalent = tSaveTalent.nRemain
	assert(nRemainTalent >= 0, "数据非法")
	assert(#tTalentList > 0, "数据非法")

	local nAllocTalent = 0
	local tTalentMap = {}
	local tAllocTalent = {}
	for _, v in pairs(tTalentList) do
		local tConf = assert(ctTalentConf[v.nID])
		assert(v.nValue > 0 and v.nValue <= tConf.nLevelMax, "等级数据超出范围")
		assert((self.m_tAllocTalent[tConf.nType] or 0) >= tConf.nNeedPoint, "天赋:"..v.nID.."未开放")
		nAllocTalent = nAllocTalent + v.nValue
		tTalentMap[v.nID] = v.nValue
		tAllocTalent[tConf.nType] = (tAllocTalent[tConf.nType] or 0) + v.nValue
	end
	assert(nRemainTalent + nAllocTalent == self.m_nTotalTalent, "总天赋点数错误")
	self.m_tTalentMap = tTalentMap
	self.m_tAllocTalent = tAllocTalent
	self.m_nRemainTalent = nRemainTalent
	self:SyncInfo()
end

--重置天赋
function CTalent:ResetTalent()
	--是否能重置
	local nAllocTalent = 0
	for k = 1, self.tType.eCount do
		nAllocTalent = nAllocTalent + (self.m_tAllocTalent[k] or 0)
	end
	if nAllocTalent == 0 then
		return
	end
	--判断扣钱
	local nResetCost = 0
	if self.m_nResetTimes >= ctTalentEtc[1].nFreeTimes then
		nResetCost = ctTalentEtc[1].nResetCost 
		if self.m_oPlayer:GetMoney() < nResetCost then
			return self.m_oPlayer:ScrollMsg(ctLang[4])
		end
	end
	--重置所有天赋
	for k = 1, self.tType.eCount do
		self.m_nRemainTalent = self.m_nRemainTalent + (self.m_tAllocTalent[k] or 0)
	end
	self.m_tAllocTalent = {}

	assert(self.m_nRemainTalent == self.m_nTotalTalent, "天赋点不同步")
	--清空天赋表
	self.m_tTalentMap = {}
	if nResetCost > 0 then
		self.m_oPlayer:SubMoney(nResetCost, gtReason.eResetTalent)
	end
	--加重置次数
	self.m_nResetTimes = self.m_nResetTimes + 1
	--log
	goLogger:EventLog(gtEvent.eResetTalent, self.m_oPlayer, self.m_nRemainTalent, self.m_nResetTimes)
	self:SyncInfo()
end

--同步天赋信息
function CTalent:SyncInfo()
	local tMsg = {}
	tMsg.nTotal = self.m_nTotalTalent
	tMsg.nRemain = self.m_nRemainTalent
	tMsg.bFreeReset = self.m_nResetTimes < ctTalentEtc[1].nFreeTimes
	tMsg.tList = {}
	for k, v in pairs(self.m_tTalentMap) do
		local tItem = {nID=k, nValue=v}
		table.insert(tMsg.tList, tItem)
	end
	print("CTalent:SyncInfo***", tMsg)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "TalentInfoRet", tMsg)
end