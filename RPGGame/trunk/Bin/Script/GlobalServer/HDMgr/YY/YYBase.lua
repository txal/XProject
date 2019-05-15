--运营活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CYYBase:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self:Init()
end

function CYYBase:Init()
	self:MarkDirty(true)
end


function CYYBase:LoadData()
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	local sData = oSSDB:HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then return end

	local tData = cjson.decode(sData)
	CHDBase.LoadData(self, tData)
	self:Load(tData)
end

function CYYBase:SaveData()
	if not self:IsDirty() then
		return
	end
	local tData = CHDBase.SaveData(self)
	local tData = self:Save(tData)
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	oSSDB:HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
	self:MarkDirty(false)
end

function CYYBase:Load(tData)
end

function CYYBase:Save(tData)
	tData = tData or {}
	return tData
end

--开启活动
function CYYBase:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
	CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime, nExtID)	
end

--玩家上线
function CYYBase:Online(oRole)
	self:SyncState(oRole)
end

--取奖励状态
function CYYBase:GetAwardState(nRoleID, nID)
end

--设置奖励状态
function CYYBase:SetAwardState(oRole, nID, nState)
end

--取剩余天数
function CYYBase:GetRemainDays()
	local nBegDay = os.YDay(self.m_nBegTime)
	local nEndDay = os.YDay(self.m_nEndTime)
	local nYearDay = os.YearDays(self.m_nBegTime)
	if nEndDay < nBegDay then
		return nYearDay - nBegDay + nEndDay + 1
	else
		return nEndDay - os.YDay(os.time()) + 1
	end
end

--进入初始状态
function CYYBase:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CYYBase:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self:Init()
	self:SyncState()
end

--进入领奖状态
function CYYBase:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CYYBase:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
	self:CheckAward()
end

function CYYBase:CanGetAward(oRole)
	return false
end

--同步活动状态
function CYYBase:SyncState(oRole)
	local nState = self:GetState()
	local nBeginTime, nEndTime, nStateTime = self:GetStateTime()
	if nState == CHDBase.tState.eClose then
		nBeginTime, nEndTime = goHDCircle:GetActNextOpenTime(self:GetID())
		if nBeginTime > 0 and nBeginTime > os.time() then
			assert(nEndTime>nBeginTime, "下次开启时间错误")
			nState = CHDBase.tState.eInit
			nStateTime = nEndTime - nBeginTime
		end
	end
	local tMsg = {
		nID = self:GetID(),
		nState = nState,
		nStateTime = nStateTime,
		nBeginTime = nBeginTime,
		nEndTime = nEndTime,
		bCanGetAward = false,
	}
	--同步给指定玩家
	if oRole then
		tMsg.bCanGetAward = self:CanGetAward(oRole)
		oRole:SendMsg("ActYYStateRet", tMsg)
	--全服广播
	else
		local tSessionMap = goGPlayerMgr:GetRoleSSMap()
		for nSession, oTmpRole in pairs(tSessionMap) do
			tMsg.bCanGetAward = self:CanGetAward(oTmpRole)
			oTmpRole:SendMsg("ActYYStateRet", tMsg)
		end
	end
end

--检测奖励
function CYYBase:CheckAward()
end

--取信息
function CYYBase:InfoReq(oRole)
end

--领取奖励
function CYYBase:AwardReq(oRole, nID)
end