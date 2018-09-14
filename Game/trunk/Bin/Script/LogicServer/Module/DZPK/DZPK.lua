local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--牛牛模块
function CDZPK:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_bDirty = false

	--自由场相关
	self.m_nDayWin = 0 		--今日胜局数
	self.m_nDayRound = 0	--今日对局数
	self.m_nResetTime = os.time()
	
	self.m_nTili = 0 		--体力
	self.m_nWinCnt = 0 		--连胜
	self.m_nRounds = 0 		--对局数
end

function CDZPK:GetType()
	return gtModuleDef.tDZPK.nID, gtModuleDef.tDZPK.sName
end

function CDZPK:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CDZPK:LoadData(tData)
	--fix pd LOAD
end

function CDZPK:SaveData()
	if not self.m_bDirty then
		return
	end
	--fix pd SAVE
	self.m_bDirty = false
end

function CDZPK:Offline()
end

function CDZPK:Online()
end

function CDZPK:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nResetTime, 0) then
		self.m_nDayWin = 0
		self.m_nDayRound = 0
		self:MarkDirty(true)
	end
end

function CDZPK:AddDayRound(bWin)
	self:CheckReset()
	self.m_nDayRound = self.m_nDayRound + 1
	if bWin then
		self.m_nDayWin = self.m_nDayWin + 1
	end
	self:MarkDirty(true)
end

function CDZPK:GetDayRound()
	self:CheckReset()
	return self.m_nDayRound, self.m_nDayWin
end

function CDZPK:SetTili(nTili)
	self.m_nTili = nTili
	self:MarkDirty(true)
end

function CDZPK:GetTili()
	return self.m_nTili
end

function CDZPK:SetWinCnt(nWinCnt)
	self.m_nWinCnt = nWinCnt
	self:MarkDirty(true)
end

function CDZPK:GetWinCnt()
	return (self.m_nWinCnt or 0)
end

function CDZPK:SetRounds(nRounds)
	self.m_nRounds = nRounds
end

function CDZPK:GetRounds()
	return self.m_nRounds
end
