--累充活动全局模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGLeiChong:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_nVersion = 1
end

function CGLeiChong:Init()
	self.m_tAwardMap = {} 		--{[charid]={[id]=flag,...},...}
	self.m_tRechargeMap = {} 	--{[charid]=num,...}
	self:MarkDirty(true)
end

function CGLeiChong:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then
		return
	end
	local tData = cjson.decode(sData)
	CHDBase.LoadData(self, tData)
	self.m_nVersion = tData.m_nVersion
	self.m_tAwardMap = tData.m_tAwardMap or {}
	self.m_tRechargeMap = tData.m_tRechargeMap or {}
end

function CGLeiChong:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_nVersion = self.m_nVersion
	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_tRechargeMap = self.m_tRechargeMap
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

--玩家上线
function CGLeiChong:Online(oPlayer)
	self:SyncState(oPlayer)
end

--取版本
function CGLeiChong:GetVersion()
	return self.m_nVersion
end

--进入初始状态
function CGLeiChong:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CGLeiChong:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self.m_nVersion = self.m_nVersion + 1
	self:MarkDirty(true)
	self:Init()
	self:SyncState()
end

--进入领奖状态
function CGLeiChong:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CGLeiChong:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
	self:CheckAward()
end

--取奖励状态
function CGLeiChong:GetAwardState(oPlayer, nID)
	local nCharID = oPlayer:GetCharID()
	local tAwardMap = self.m_tAwardMap[nCharID] or {}
	return (tAwardMap[nID] or 0) 
end

--设置奖励状态
function CGLeiChong:SetAwardState(oPlayer, nID, nState)
	local nCharID = oPlayer:GetCharID()
	self.m_tAwardMap[nCharID] = self.m_tAwardMap[nCharID] or {}
	self.m_tAwardMap[nCharID][nID] = nState
	self:MarkDirty(true)
end

--充值成功
function CGLeiChong:OnRechargeSuccess(oPlayer, nMoney)
	local nCharID = oPlayer:GetCharID()
	self.m_tRechargeMap[nCharID] = (self.m_tRechargeMap[nCharID] or 0) + nMoney
	self:MarkDirty(true)
end

--取充值金额
function CGLeiChong:GetTotalRecharge(oPlayer)
	local nCharID = oPlayer:GetCharID()
	return (self.m_tRechargeMap[nCharID] or 0)
end

--同步活动状态
function CGLeiChong:SyncState(oPlayer)
	local nState = self:GetState()
	local nStateTime = self:GetStateTime()
	local nBeginTime, nEndTime, nAwardTime = self:GetActTime()
	local tMsg = {
		nID = self:GetID(),
		nState = nState,
		nStateTime = nStateTime,
		nBeginTime = nBeginTime,
		nEndTime = nEndTime,
		nAwardTime = nAwardTime,
		bCanGetAward = false,
	}
	--同步给指定玩家
	if oPlayer then
		tMsg.bCanGetAward = oPlayer.m_oLeiChong:CanGetAward()
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "LeiChongStateRet", tMsg)
	--全服广播
	else
		local tSessionMap = goPlayerMgr:GetSessionMap()
		for nSession, oTmpPlayer in pairs(tSessionMap) do
			tMsg.bCanGetAward = oTmpPlayer.m_oLeiChong:CanGetAward()
			CmdNet.PBSrv2Clt(oTmpPlayer:GetSession(), "LeiChongStateRet", tMsg)
		end
	end
end

--检测活动结束奖励
function CGLeiChong:CheckAward()
	for nCharID, nMoney in pairs(self.m_tRechargeMap) do
		if nMoney > 0 then
			for nID, tConf in ipairs(ctLeiChongConf) do
				local tAwardMap = self.m_tAwardMap[nCharID] or {}
				self.m_tAwardMap[nCharID] = tAwardMap
				if not tAwardMap[nID] then
					if nMoney >= tConf.nMoney then
						tAwardMap[nID] = 2
						self:MarkDirty(true)
						local tList = table.DeepCopy(tConf.tAward)
						goMailMgr:SendMail("系统邮件", "累充活动", "您在累充活动达到累充"..tConf.nMoney.."元，获得了以下奖励，请查收。", tList, nCharID)
					end
				end
			end
		end
	end
end
