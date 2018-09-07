local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--广东麻将模块
function CGDMJ:Ctor(oPlayer)
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

function CGDMJ:GetType()
	return gtModuleDef.tGDMJ.nID, gtModuleDef.tGDMJ.sName
end

function CGDMJ:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CGDMJ:LoadData(tData)
	--fix pd LOAD
end

function CGDMJ:SaveData()
	if not self.m_bDirty then
		return
	end
	--fix pd SAVE
	self.m_bDirty = false
end

function CGDMJ:Offline()
end

function CGDMJ:Online()
end

function CGDMJ:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nResetTime, 0) then
		self.m_nDayWin = 0
		self.m_nDayRound = 0
		self:MarkDirty(true)
	end
end

function CGDMJ:AddDayRound(bWin)
	self:CheckReset()
	self.m_nDayRound = self.m_nDayRound + 1
	if bWin then
		self.m_nDayWin = self.m_nDayWin + 1
	end
	self:MarkDirty(true)
end

function CGDMJ:GetDayRound()
	self:CheckReset()
	return self.m_nDayRound, self.m_nDayWin
end

function CGDMJ:SetTili(nTili)
	self.m_nTili = nTili
	self:MarkDirty(true)
end

function CGDMJ:GetTili()
	return self.m_nTili
end

function CGDMJ:SetWinCnt(nWinCnt)
	self.m_nWinCnt = nWinCnt
	self:MarkDirty(true)
end

function CGDMJ:GetWinCnt()
	return (self.m_nWinCnt or 0)
end

function CGDMJ:SetRounds(nRounds)
	self.m_nRounds = nRounds
end

function CGDMJ:GetRounds()
	return self.m_nRounds
end
