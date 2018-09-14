function CGVEModule:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	local nSecNow = os.time()

	self.m_nGVEFame = 0
	self.m_nLastSubTime = nSecNow

	self.m_nPassTimes = 0
	self.m_nLastResetTime = nSecNow
end

function CGVEModule:GetType()
	return gtModuleDef.tGVEModule.nID, gtModuleDef.tGVEModule.sName
end

function CGVEModule:LoadData(tData)
	local nSecNow = os.time()
	self.m_nGVEFame = tData.nGVEFame or 0
	self.m_nLastSubTime = tData.nLastSubTime or nSecNow
	self.m_nPassTimes = tData.nPassTimes or 0
	self.m_nLastResetTime = tData.nLastResetTime or nSecNow
end

function CGVEModule:SaveData()
	local tData = {}
	tData.nGVEFame = self.m_nGVEFame
	tData.nLastSubTime = self.m_nLastSubTime
	tData.nPassTimes = self.m_nPassTimes
	tData.nLastResetTime = self.m_nLastResetTime
	return tData
end

function CGVEModule:_calc_fame_level()
	for k = #ctGVEFameLevelConf, 1, -1 do
		local tConf = ctGVEFameLevelConf[k]
		if self.m_nGVEFame >= tConf.nFame then
			return tConf.nFameLevel
		end
	end
	return 1
end

function CGVEModule:_check_daily_sub()
	local nTotalSub = 0
	local nSecNow = os.time()
	local nDays = os.PassDay(self.m_nLastSubTime, nSecNow, 0)
	if nDays > 0 then
		self.m_nLastSubTime = nSecNow
		for k = 1, nDays do
			local nLevel = self:_calc_fame_level()
			local tConf = assert(ctGVEFameLevelConf[nLevel])
			local nSubVal = tConf.nDailySub
			if nSubVal > 0 then
				nTotalSub = nTotalSub + nSubVal
			    self.m_nGVEFame = math.max(0, self.m_nGVEFame - nSubVal)
			end
		end
	end
	if nTotalSub > 0 then
	    goLogger:AwardLog(gtEvent.eSubItem, gtReason.eDailySubFame, self.m_oPlayer, gtObjType.eCurr, gtCurrType.eGVEFame, nTotalSub, self.m_nGVEFame, nDays)
	end
end

function CGVEModule:GetFameLevel()
	self:_check_daily_sub()
	return self:_calc_fame_level()
end

function CGVEModule:AddFame(nCount)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self:_check_daily_sub()
    self.m_nGVEFame = math.min(nMAX_INTEGER, self.m_nGVEFame + nCount)
end

function CGVEModule:OnBattleResult(bWin)
	if not bWin then
		return
	end
	self.m_nPassTimes = self.m_nPassTimes + 1
end

--取轮数
function CGVEModule:GetRoundInfo()
	local nSecNow = os.time()
	if not os.IsSameDay(self.m_nLastResetTime, nSecNow, 0) then
		self.m_nLastResetTime = nSecNow
		self.m_nPassTimes = 0
	end

	local tConf = ctBugStormEtc[1]
	local nCurrRound = math.ceil(self.m_nPassTimes / tConf.nTimesPerRound)
	nCurrRound = math.max(1, nCurrRound)
	local nRoundTimes = self.m_nPassTimes % tConf.nTimesPerRound
	if nRoundTimes == 0 and self.m_nPassTimes > 0 then
		nRoundTimes = tConf.nTimesPerRound
	end
	return nCurrRound, nRoundTimes
end