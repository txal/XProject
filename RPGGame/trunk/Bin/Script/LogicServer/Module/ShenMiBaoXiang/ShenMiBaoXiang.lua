--神秘宝箱模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CShenMiBaoXiang:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nActiveTime = 0 			--激活时间
	self.m_bExchanged = false 		--是否已经兑换
end

function CShenMiBaoXiang:LoadData(tData)
	if not tData then return end
	self.m_nActiveTime = tData.m_nActiveTime
	self.m_bExchanged = tData.m_bExchanged
end

function CShenMiBaoXiang:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)
	
	local tData = {}
	tData.m_nActiveTime = self.m_nActiveTime
	tData.m_bExchanged  = self.m_bExchanged
	return tData
end

function CShenMiBaoXiang:GetType()
	return gtModuleDef.tShenMiBaoXiang.nID, gtModuleDef.tShenMiBaoXiang.sName
end

--上线
function CShenMiBaoXiang:Online()
	self:SyncInfo()
end

--检测开放
function CShenMiBaoXiang:IsOpen()
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShenMiBaoXiang)
	return oAct:IsOpen()
end

--特定任务出现
function CShenMiBaoXiang:OnTaskAppear(nTaskID)
	if ctSMBXEtcConf[1].nActTask ~= nTaskID then
		return
	end
	if not self:IsOpen() then
		return
	end

	self.m_nActiveTime = os.time()
	self.m_bExchanged = false
	self:MarkDirty(true)
	self:SyncInfo()
end

--同步信息
function CShenMiBaoXiang:SyncInfo()
	local nNowSec = os.time()
	local tConf = ctSMBXEtcConf[1]
	local tMsg = {bOpen=false, nRemainTime=0}
	if not self.m_bExchanged and self.m_nActiveTime > 0 and nNowSec < self.m_nActiveTime+tConf.nValidTime then
		tMsg.bOpen = true
		tMsg.nRemainTime = self.m_nActiveTime+tConf.nValidTime-nNowSec
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "SMBXInfoRet", tMsg)
end

--兑换请求
function CShenMiBaoXiang:ExchangeReq(nType, sCDKey, tAward)
	if self.m_bExchanged then
		self:SyncInfo()
		return self.m_oPlayer:Tips("已兑换过神秘宝箱")

	elseif self.m_nActiveTime <= 0 then	
		self:SyncInfo()
		return self.m_oPlayer:Tips("神秘宝箱活动未开启")

	elseif os.time() >= self.m_nActiveTime+ctSMBXEtcConf[1].nValidTime then
		self:SyncInfo()
		return self.m_oPlayer:Tips("神秘宝箱活动已结束")

	end
	self.m_bExchanged = true
	self:MarkDirty(true)

	local tList = {}
	for _, tItem in ipairs(tAward) do
		self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "兑换神秘宝箱")
		table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "SMBXExchangeRet", {tList=tList})
	Srv2Srv.OnExchangeRet(gtNetConf:GlobalService(), self.m_oPlayer:GetSession(), nType, sCDKey)
	goLogger:EventLog(gtEvent.eShenMiBaoXiang, self.m_oPlayer, sCDKey)
	self:SyncInfo()
end