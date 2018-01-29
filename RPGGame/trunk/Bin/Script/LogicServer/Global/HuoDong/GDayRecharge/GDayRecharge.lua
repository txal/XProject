--日充值活动全局模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGDayRecharge:Ctor(nID)
	CHDBase.Ctor(self, nID)     		--继承基类
	self.m_nItemID = 0 					--替换ID
	self:Init()
end

function CGDayRecharge:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nItemID = tData.m_nItemID or self.m_nItemID
		self.m_tDayRechargeMap = tData.m_tDayRechargeMap or self.m_tDayRechargeMap
		self.m_nLastResetTime = tData.m_nLastResetTime or self.m_nLastResetTime
		CHDBase.LoadData(self, tData)
	end
end

function CGDayRecharge:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_nItemID = self.m_nItemID
	tData.m_tDayRechargeMap = self.m_tDayRechargeMap
	tData.m_nLastResetTime = self.m_nLastResetTime
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

function CGDayRecharge:Init()
	self.m_tAwardMap = {} 				--领奖
	self.m_tDayRechargeMap = {} 		--日充映射
	self.m_nLastResetTime = os.time() 	--上1次重置时间
	self:MarkDirty(true)
end

--获取替换物品ID
function CGDayRecharge:GetAwardID()
	return self.m_nItemID
end

--玩家上线
function CGDayRecharge:Online(oPlayer)
	self:SyncState(oPlayer)
end

--检测重置
function CGDayRecharge:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nLastResetTime) then
		self:CheckAward()
		self:Init()
	end
end

--更新状态
function CGDayRecharge:UpdateState()
	CHDBase.UpdateState(self) --调用基类
	self:CheckReset()
end

--进入初始状态
function CGDayRecharge:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CGDayRecharge:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self:Init()
	self:SyncState()
end

--进入领奖状态
function CGDayRecharge:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
end

--进入关闭状态
function CGDayRecharge:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
end

--开启活动
function CGDayRecharge:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	LuaTrace("开启日充活动", nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = nExtID or 0
	assert(ctPropConf[nExtID], "日充活动动态奖励ID错误")
	self.m_nItemID = nExtID
	CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime)	
	self:MarkDirty(true)
end

--取当前重置数量
function CGDayRecharge:GetDayRecharge(oPlayer)
	self:CheckReset()
	local nCharID = oPlayer:GetCharID()
	return (self.m_tDayRechargeMap[nCharID] or 0)
end

--取奖励状态
function CGDayRecharge:GetAwardState(oPlayer, nID)
	self:CheckReset()
	local nCharID = oPlayer:GetCharID()
	local tAwardMap = self.m_tAwardMap[nCharID]
	if not tAwardMap then
		return 0
	end
	return (tAwardMap[nID] or 0)
end

--设置已领奖
function CGDayRecharge:SetAwardState(oPlayer, nID, nState)
	self:CheckReset()
	local nCharID = oPlayer:GetCharID()
	if not self.m_tAwardMap[nCharID] then
		self.m_tAwardMap[nCharID] = {}
	end
	self.m_tAwardMap[nCharID][nID] = nState
	self:MarkDirty(true)
end

--玩家重置成功
function CGDayRecharge:OnRechargeSuccess(oPlayer, nDayRecharge)
	self:CheckReset()
	local nCharID = oPlayer:GetCharID()
	self.m_tDayRechargeMap[nCharID] = nDayRecharge
	self.m_tAwardMap[nCharID] = self.m_tAwardMap[nCharID] or {}
	self:MarkDirty(true)
end

--同步活动状态
function CGDayRecharge:SyncState(oPlayer)
	local nState = self:GetState()
	local nStateTime = self:GetStateTime()
	local nBeginTime, nEndTime = self:GetActTime()
	local tMsg = {
		nID=self:GetID(),
		nState=nState,
		nStateTime=nStateTime,
		nBeginTime=nBeginTime,
		nEndTime=nEndTime,
		bCanGetAward = false,
		nItemID = self.m_nItemID,
	}
	if oPlayer then
		tMsg.bCanGetAward = oPlayer.m_oDayRecharge:CanGetAward()
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "DayRechargeStateRet", tMsg)
	else
		local tSessionMap = goPlayerMgr:GetSessionMap()
		for nSession, oTmpPlayer in pairs(tSessionMap) do
			tMsg.bCanGetAward = oTmpPlayer.m_oDayRecharge:CanGetAward()
			CmdNet.PBSrv2Clt(oTmpPlayer:GetSession(), "DayRechargeStateRet", tMsg)
		end
	end
end

--检测未领奖
function CGDayRecharge:CheckAward()
	for nCharID, nDayRecharge in pairs(self.m_tDayRechargeMap) do
		for nID, tConf in ipairs(ctDayRechargeConf) do
			local tAwardMap = self.m_tAwardMap[nCharID] or {}
			self.m_tAwardMap[nCharID] = tAwardMap
			if not tAwardMap[nID] then
				if nDayRecharge >= tConf.nMoney then
					tAwardMap[nID] = 2
					self:MarkDirty(true)

					local tList = {}
					for _, tItem in ipairs(tConf.tAward) do 
						local nID = tItem[2]
						if nID == -1 then 
							nID = self.m_nItemID
						end
						table.insert(tList, {tItem[1], nID, tItem[3]})
					end

					goMailMgr:SendMail("系统邮件", "日充活动奖励"
						, string.format("您在日充活动中充值满%d元，获得了以下奖励，请查收。", tConf.nMoney), tList, nCharID)
				end
			end
		end
	end
end
