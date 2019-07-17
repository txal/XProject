--日充值玩家模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CDayRecharge:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
end

function CDayRecharge:LoadData(tData)
end

function CDayRecharge:SaveData()
end

function CDayRecharge:GetType()
	return gtModuleDef.tDayRecharge.nID, gtModuleDef.tDayRecharge.sName
end

--检测重置
function CDayRecharge:CheckReset()
end

--检测开放
function CDayRecharge:IsOpen()
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDayRecharge)
	return oAct:IsOpen()
end

--取信息
function CDayRecharge:InfoReq()
	self:CheckReset()
	if not self:IsOpen() then
		return self.m_oPlayer:Tips("今天没有活动哦，请娘娘稍待几日")
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDayRecharge)
	local nRemainTime = oAct:GetStateTime()
	local nDayRecharge = oAct:GetDayRecharge(self.m_oPlayer)

	local tMsg = {nDayRecharge=nDayRecharge, nRemainTime=nRemainTime, tList={}}	
	for nID, tConf in ipairs(ctDayRechargeConf) do
		local nState = oAct:GetAwardState(self.m_oPlayer, nID)
		if nState == 0 then
			nState = nDayRecharge >= tConf.nMoney and 1 or 0
		end
		local tInfo = {nID=nID, nState=nState}
		table.insert(tMsg.tList, tInfo)
	end
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "DayRechargeInfoRet", tMsg)
end

--领取奖励
function CDayRecharge:AwardReq(nID)
	self:CheckReset()
	if not self:IsOpen() then
		return self.m_oPlayer:Tips("今天没有活动哦，请娘娘稍待几日")
	end

	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDayRecharge)
	local nAwardState = oAct:GetAwardState(self.m_oPlayer, nID)
	if nAwardState == 2 then
		return self.m_oPlayer:Tips("该奖励已经领取过了")
	end

	local tConf = ctDayRechargeConf[nID]
	local nDayRecharge = oAct:GetDayRecharge(self.m_oPlayer)
	if nDayRecharge < tConf.nMoney then
		return self.m_oPlayer:Tips("未达到充值条件")
	end

	local nItemID = oAct:GetAwardID()
	local tAward = ctDayRechargeConf[nID].tAward
	for _, tItem in ipairs(tAward) do 
		local nID = tItem[2]
		if nID == -1 then 
			nID = nItemID
		end
		self.m_oPlayer:AddItem(tItem[1], nID, tItem[3], "日充值奖励")
	end

	oAct:SetAwardState(self.m_oPlayer, nID, 2)
	Network.PBSrv2Clt(self.m_oPlayer:GetSession(), "DayRechargeAwardRet", {nID=nID, nItemID=nItemID})

	self:InfoReq()
	self:CheckRedPoint()
end

--玩家充值成功
function CDayRecharge:OnRechargeSuccess(nMoney)
	if not self:IsOpen() then
		return
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDayRecharge)
	oAct:OnRechargeSuccess(self.m_oPlayer, nMoney)
	self:CheckRedPoint()
end

--是否可以领奖
function CDayRecharge:CanGetAward()
	if not self:IsOpen() then
		return false
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDayRecharge)
	local nDayRecharge = oAct:GetDayRecharge(self.m_oPlayer)
	for nID, tConf in ipairs(ctDayRechargeConf) do
		local nAwardState = oAct:GetAwardState(self.m_oPlayer, nID)
		if nAwardState == 0 then
			if nDayRecharge >= tConf.nMoney then
				return true
			end
		end
	end
	return false
end

--检测小红点
function CDayRecharge:CheckRedPoint()
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDayRecharge)
	oAct:SyncState(self.m_oPlayer)
end