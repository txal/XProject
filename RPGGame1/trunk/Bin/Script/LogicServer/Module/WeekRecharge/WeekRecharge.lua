--周充值模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CWeekRecharge:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tAwardMap = {} 			--已领取奖励映射
	self.m_nResetTime = os.time() 	--上次重置时间
end

function CWeekRecharge:LoadData(tData)
	if not tData then return end
	self.m_nResetTime = tData.m_nResetTime
	self.m_tAwardMap = tData.m_tAwardMap
end

function CWeekRecharge:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	local tData = {}
	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_nResetTime = self.m_nResetTime
	return tData
end

function CWeekRecharge:GetType()
	return gtModuleDef.tWeekRecharge.nID, gtModuleDef.tWeekRecharge.sName
end

--上线
function CWeekRecharge:Online()
	self:InfoReq()
end

--检测重置
function CWeekRecharge:CheckReset()
	local nNowSec = os.time()
	if not os.IsSameWeek(nNowSec, self.m_nResetTime, 0) then
		self.m_nResetTime = nNowSec
		self.m_tAwardMap = {}
		self:MarkDirty(true)
	end
end

--取信息
function CWeekRecharge:InfoReq()
	self:CheckReset()
	local nWeekRechargeTimes, nBegTime, nEndTime = self.m_oPlayer.m_oVIP:GetWeekRechargeTimes(os.time())
	local tMsg = {nWeekRechargeTimes=nWeekRechargeTimes, nBegTime=nBegTime, nEndTime=nEndTime,  tList={}}	
	for nID, tConf in ipairs(ctWeekRechargeConf) do
		local nState = self.m_tAwardMap[nID]
		if not nState then
			nState = nWeekRechargeTimes >= tConf.nTimes and 1 or 0
		end
		local tInfo = {nID=nID, nState=nState}
		table.insert(tMsg.tList, tInfo)
	end
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "WeekRechargeInfoRet", tMsg)
end

--领取奖励
function CWeekRecharge:AwardReq(nID)
	self:CheckReset()
	if (self.m_tAwardMap[nID] or 0) == 2 then
		return self.m_oPlayer:Tips("该奖励已经领取过了")
	end
	local tConf = ctWeekRechargeConf[nID]
	local nWeekRechargeTimes = self.m_oPlayer.m_oVIP:GetWeekRechargeTimes(os.time())
	if nWeekRechargeTimes < tConf.nTimes then
		return self.m_oPlayer:Tips("未达到充值条件")
	end
	local tAward = tConf.tAward
	for _, tConf in ipairs(tAward) do 
		local tTmp = {nType=tConf[1], nID=tConf[2], nNum=tConf[3]}
		self.m_oPlayer:AddItem(tConf[1], tConf[2], tConf[3], "周充值奖励")
	end

	self.m_tAwardMap[nID] = 2
	self:MarkDirty(true)
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "WeekRechargeAwardRet", {nID=nID})
	self:InfoReq()
end

--玩家充值成功
function CWeekRecharge:OnRechargeSuccess()
	self:InfoReq()
end
