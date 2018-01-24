function CGVGModule:Ctor(oPlayer)
	self.m_oPlayer = oPlayer

	self.m_nGVGFame = ctPlayerInitConf[1].nInitFame
	self.m_nLastSubTime = os.time()

	self.m_nTotalFights = 0
	self.m_nMultiExpFights = 0	
	self.m_nLastResetTime = 0

	self.m_nWins = 0	--连胜
	self.m_nLoses = 0	--连败

	self.m_nHistoryDmg = 0 --历史最高伤害
	self.m_nChangeDmg = 0 --改变的伤害(不保存)
end

function CGVGModule:GetType()
	return gtModuleDef.tGVGModule.nID, gtModuleDef.tGVGModule.sName
end

function CGVGModule:LoadData(tData)
	local nNowSec = os.time()
	self.m_nGVGFame = tData.nGVGFame or 0
	self.m_nLastSubTime = tData.nLastSubTime or nNowSec
	self.m_nMultiExpFights = tData.nMultiExpFights or 0
	self.m_nLastResetTime = tData.nLastResetTime or nNowSec
	self.m_nWins = tData.nWins or 0
	self.m_nLoses = tData.nLoses or 0
	self.m_nTotalFights = tData.nTotalFights or 0
	self.m_nHistoryDmg = tData.nHistoryDmg or 0
end

function CGVGModule:SaveData()
	local tData = {}
	tData.nGVGFame = self.m_nGVGFame
	tData.nLastSubTime = self.m_nLastSubTime
	tData.nMultiExpFights = self.m_nMultiExpFights
	tData.nLastResetTime = self.m_nLastResetTime
	tData.nWins = self.m_nWins
	tData.nLoses = self.m_nLoses
	tData.nTotalFights = self.m_nTotalFights
	tData.nHistoryDmg = self.m_nHistoryDmg
	return tData
end

function CGVGModule:_calc_fame_level_()
	for k = #ctGVGFameLevelConf, 1, -1 do
		local tConf = ctGVGFameLevelConf[k]
		if self.m_nGVGFame >= tConf.nFame then
			return tConf.nFameLevel
		end
	end
	return 1
end

function CGVGModule:_check_daily_sub_()
	local nTotalSub = 0
	local nSecNow = os.time()
	local nDays = os.PassDay(self.m_nLastSubTime, nSecNow, 0)
	if nDays > 0 then
		self.m_nLastSubTime = nSecNow
		for k = 1, nDays do
			local nLevel = self:_calc_fame_level_()
			local tConf = assert(ctGVGFameLevelConf[nLevel])
			local nSubVal = tConf.nDailySub
			if nSubVal > 0 then
				nTotalSub = nTotalSub + nSubVal
			    self.m_nGVGFame = math.max(ctPlayerInitConf[1].nMinFame, self.m_nGVGFame - nSubVal)
			end
		end
	end
	if nTotalSub > 0 then
	    goLogger:AwardLog(gtEvent.eSubItem, gtReason.eDailySubFame, self.m_oPlayer, gtObjType.eCurr, gtCurrType.eGVGFame, nTotalSub, self.m_nGVGFame, nDays)
		self.m_oPlayer:SyncCurr(gtCurrType.eGVGFame, self.m_nGVGFame)
		return true
	end
end

function CGVGModule:GetFame()
	if self:_check_daily_sub_() then
		self:OnFameChange()
	end
    return self.m_nGVGFame
end

function CGVGModule:GetFameLevel()
	self:_check_daily_sub_()
	return self:_calc_fame_level_()
end

function CGVGModule:AddFame(nCount)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self:_check_daily_sub_()
    self.m_nGVGFame = math.min(nMAX_INTEGER, self.m_nGVGFame + nCount)
	self.m_oPlayer:SyncCurr(gtCurrType.eGVGFame, self.m_nGVGFame)
	self:OnFameChange()
end

function CGVGModule:SubFame(nCount, nReason)
	assert(nCount >= 0)
	assert(nReason, "需要写上原因")
	if nCount == 0 then return end
    self:_check_daily_sub_()
    self.m_nGVGFame = math.max(ctPlayerInitConf[1].nMinFame, self.m_nGVGFame - nCount) --保底声望
	self.m_oPlayer:SyncCurr(gtCurrType.eGVGFame, self.m_nGVGFame)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self.m_oPlayer, gtObjType.eCurr, gtCurrType.eGVGFame, nCount, self.m_nGVGFame)
	self:OnFameChange()
end

--声望变化
function CGVGModule:OnFameChange()
	--战队	
	goUnionMgr:OnFameChange(self.m_oPlayer)
end

--重置10倍经验
function CGVGModule:_check_multiexp_fights_()
	local nNowSec = os.time()
	if not os.IsSameDay(nNowSec, self.m_nLastResetTime, 0) then
		self.m_nLastResetTime = nNowSec
		local nAdd, nMax = table.unpack(ctBugHoleEtc[1].tMultiExpFights[1])
		self.m_nMultiExpFights = math.min(nMax, self.m_nMultiExpFights + nAdd)
	end
end

--战斗结束:nResult(0新手;1胜利;2失败)
function CGVGModule:AddFights(nResult)
	self.m_nTotalFights = self.m_nTotalFights + 1
	--新手不计算连胜连败
	if nResult == 0 then
		return
	end

	--连胜/连败
	if nResult == 1 then
		self.m_nWins = self.m_nWins + 1
		self.m_nLoses = 0
	elseif nResult == 2 then
		self.m_nLoses = self.m_nLoses + 1
		self.m_nWins = 0
	end
end

--连胜/败数据
function CGVGModule:GetWinsInfo()
	return self.m_nWins, self.m_nLoses
end

--10倍经验战斗场数
function CGVGModule:GetMultiExpFights()
	self:_check_multiexp_fights_()
	return self.m_nMultiExpFights
end

--扣10倍经验战斗剩余场数
function CGVGModule:SubMultiExpFights()
	self:_check_multiexp_fights_()
	self.m_nMultiExpFights = math.max(0, self.m_nMultiExpFights - 1)
	return self.m_nMultiExpFights
end

--总战斗数
function CGVGModule:GetTotalFights()
	return self.m_nTotalFights
end

--记录历史最高伤害
function CGVGModule:UpdateDmg(nDmg)
	print("CGVGModule:UpdateDmg***", nDmg, self.m_nHistoryDmg)
	if nDmg <= self.m_nHistoryDmg then
		return
	end
	self.m_nChangeDmg = nDmg - self.m_nHistoryDmg
	self.m_nHistoryDmg = nDmg
end

--最高伤害是否发生了变化
function CGVGModule:CheckDmgChange()
	print("CGVGModule:CheckDmgChange***", self.m_nChangeDmg)
	if self.m_nChangeDmg <= 0 then
		return
	end
	
	local nGoldNum =  math.floor(self.m_nChangeDmg * ctBugHoleEtc[1].nHistoryDmgAdj)
	if nGoldNum > 0 then
		self.m_oPlayer:AddItem(gtObjType.eCurr, gtCurrType.eGold, nGoldNum, gtReason.eBugHoleHistoryDmg)
		local tSendData = {nOrgDmg=self.m_nHistoryDmg-self.m_nChangeDmg, nNewDmg=self.m_nHistoryDmg, nGoldNum=nGoldNum}		
		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BugHoleHistoryDmgRet", tSendData)
	end
	self.m_nChangeDmg = 0
end

--战场情报
function CGVGModule:BattleIntelligenceReq()
	local nFame = self:GetFame()
	local nFameLevel = self:GetFameLevel()
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BugHoleIntelligenceRet", {nFame=nFame, nFameLevel=nFameLevel})
end
