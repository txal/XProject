function CMallModule:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nLastResetTime = os.time()
	self.m_tDailyBuyTimesRecord = {}
end

function CMallModule:LoadData(tData)
	self.m_nLastResetTime = tData.nLastResetTime or os.time()
	self.m_tDailyBuyTimesRecord = tData.tDailyBuyTimesRecord or {}
end

function CMallModule:SaveData()
	local tData = {}
	tData.nLastResetTime = self.m_nLastResetTime
	tData.tDailyBuyTimesRecord = self.m_tDailyBuyTimesRecord
	return tData
end

function CMallModule:GetType()
	return gtModuleDef.tMallModule.nID, gtModuleDef.tMallModule.sName
end

function CMallModule:CheckReset()
	local nNowSec = os.time()
	if not os.IsSameDay(nNowSec, self.m_nLastResetTime, 0) then
		self.m_nLastResetTime = nNowSec
		self.m_tDailyBuyTimesRecord = {}
	end
end

function CMallModule:GetDailyBuyTimes(nGoodsID)
	self:CheckReset()
	return (self.m_tDailyBuyTimesRecord[nGoodsID] or 0)
end

function CMallModule:AddDailyBuyTimes(nGoodsID, nBuyTimes)
	assert(nGoodsID)
	self:CheckReset()
	self.m_tDailyBuyTimesRecord[nGoodsID] = math.min(nMAX_INTEGER, (self.m_tDailyBuyTimesRecord[nGoodsID] or 0) + nBuyTimes)
end
