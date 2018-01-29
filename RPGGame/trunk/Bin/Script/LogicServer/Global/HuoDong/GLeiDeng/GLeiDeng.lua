--累登活动全局模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGLeiDeng:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_nVersion = 1
	self.m_nRounds = 1
	self:Init()

end

function CGLeiDeng:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nRounds = tData.m_nRounds or self.m_nRounds
		self.m_nVersion = tData.m_nVersion or self.m_nVersion

		self.m_tAwardMap = tData.m_tAwardMap or self.m_tAwardMap
		self.m_tLastLogin = tData.m_tLastLogin or self.m_tLastLogin
		self.m_tLoginCount = tData.m_tLoginCount or self.m_tLoginCount
		CHDBase.LoadData(self, tData)
	end
end

function CGLeiDeng:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_nRounds = self.m_nRounds
	tData.m_nVersion = self.m_nVersion

	tData.m_tAwardMap = self.m_tAwardMap
	tData.m_tLastLogin = self.m_tLastLogin
	tData.m_tLoginCount = self.m_tLoginCount
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

function CGLeiDeng:Init()
	self.m_tAwardMap = {} 		--已领取奖励映射{[charid]={[id]=flag, ...},...}
	self.m_tLastLogin = {} 		--上次登录时间
	self.m_tLoginCount = {} 	--累计登录次数
	self:MarkDirty(true)
end

--开启活动
function CGLeiDeng:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	LuaTrace("开启累登活动", nStartTime, nEndTime, nAwardTime, nExtID)
	nExtID = nExtID or 1

	local bExist = false
	for k=1, #ctLeiDengConf do 
		if ctLeiDengConf[k].nRounds == nExtID then 
			bExist = true
			break
		end
	end
	assert(bExist, "累登活动轮次错误")
	
	self.m_nRounds = nExtID
	CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime)	
	self:MarkDirty(true)
end

function CGLeiDeng:GetRounds()
	return self.m_nRounds
end

--玩家上线
function CGLeiDeng:Online(oPlayer)
	self:SyncState(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local nLastLogin = self.m_tLastLogin[nCharID] or 0
	if not os.IsSameDay(nLastLogin, os.time(), 0) then
		self.m_tLastLogin[nCharID] = os.time()
		self.m_tLoginCount[nCharID] = (self.m_tLoginCount[nCharID] or 0) + 1
		self:MarkDirty(true)
	end
end

--取登录天数
function CGLeiDeng:GetLoginCount(oPlayer)
	local nCharID = oPlayer:GetCharID()
	return (self.m_tLoginCount[nCharID] or 0)
end

--取奖励状态
function CGLeiDeng:GetAwardState(oPlayer, nID)
	local nCharID = oPlayer:GetCharID()
	local tAwardMap = self.m_tAwardMap[nCharID] or {}
	return (tAwardMap[nID] or 0)
end

--设置奖励状态
function CGLeiDeng:SetAwardState(oPlayer, nID, nState)
	local nCharID = oPlayer:GetCharID()
	if not self.m_tAwardMap[nCharID] then
		self.m_tAwardMap[nCharID] = {}
	end
	self.m_tAwardMap[nCharID][nID] = nState
	self:MarkDirty(true)
end

--取剩余天数
function CGLeiDeng:GetRemainDays()
	local nBegDay = os.YDay(self.m_nBegTime)
	local nEndDay = os.YDay(self.m_nEndTime)
	local nYearDay = os.YearDays(self.m_nBegTime)
	if nEndDay < nBegDay then
		return nYearDay - nBegDay + nEndDay + 1
	else
		return nEndDay - os.YDay(os.time()) + 1
	end
end

--取版本
function CGLeiDeng:GetVersion()
	return self.m_nVersion
end

--进入初始状态
function CGLeiDeng:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CGLeiDeng:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self.m_nVersion = self.m_nVersion + 1
	self:MarkDirty(true)
	self:Init()
	self:SyncState()
end

--进入领奖状态
function CGLeiDeng:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CGLeiDeng:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
	self:CheckAward()
end

--同步活动状态
function CGLeiDeng:SyncState(oPlayer)
	local nState = self:GetState()
	local nStateTime = self:GetStateTime()
	local nBeginTime, nEndTime = self:GetActTime()
	local tMsg = {
		nID = self:GetID(),
		nState = nState,
		nStateTime = nStateTime,
		nBeginTime = nBeginTime,
		nEndTime = nEndTime,
	}
	--同步给指定玩家
	if oPlayer then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "LeiDengStateRet", tMsg)
	--全服广播
	else
		CmdNet.PBSrv2All("LeiDengStateRet", tMsg) 
	end
end

--检测奖励
function CGLeiDeng:CheckAward()
	for nCharID, nCount in pairs(self.m_tLoginCount) do
		if nCount > 0 then
			for nID, tConf in ipairs(ctLeiDengConf) do
				if tConf.nRounds == self.m_nRounds then
					local nState = oAct:GetAwardState(self.m_oPlayer, nID)
					if nState == 0 and nCount >= tConf.nLoginCount then
						self.m_tAwardMap[nCharID] = self.m_tAwardMap[nCharID] or {}
						self.m_tAwardMap[nCharID][nID] = 2
						self:MarkDirty(true)
						local tList = table.DeepCopy(tConf.tAward)
						goMailMgr:SendMail("系统邮件", "累登活动", "您在累登活动达到累登"..tConf.nLoginCount.."次，获得了以下奖励，请查收。", tList, nCharID)
					end
				end
			end
		end
	end
end