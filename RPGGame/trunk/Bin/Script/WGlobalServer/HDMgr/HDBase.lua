--活动基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--活动状态
CHDBase.tState = 
{
	eInit = 0, 		--初始状态
	eStart = 1, 	--进行中
	eAward = 2,		--领奖中
	eClose = 3, 	--已结束
}

--奖励状态
CHDBase.tAwardState = 
{
	eInit = 0, 	--初始状态	
	eFeed = 1, 	--满足未领取
	eClose = 2, --已领取	
}

function CHDBase:Ctor(nID)
	self.m_nID = nID
	self.m_nBegTime = 0 	--开始时间
	self.m_nEndTime = 0 	--结束时间
	self.m_nAwardTime = 0 	--领奖结束时间
	self.m_nState = CHDBase.tState.eInit 	--状态
	self.m_nOpenTimes = 0 	--开放次数
	self.m_bDirty = false
end

--加载数据
function CHDBase:LoadData(tData)
	self.m_nID = tData.m_nID
	self.m_nBegTime = tData.m_nBegTime
	self.m_nEndTime = tData.m_nEndTime
	self.m_nAwardTime = tData.m_nAwardTime
	self.m_nState = tData.m_nState
	self.m_nOpenTimes = tData.m_nOpenTimes or 0
end

--保存数据
function CHDBase:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_nBegTime = self.m_nBegTime
	tData.m_nEndTime = self.m_nEndTime
	tData.m_nAwardTime = self.m_nAwardTime
	tData.m_nState = self.m_nState
	tData.m_nOpenTimes = self.m_nOpenTimes
	return tData
end

--释放数据
function CHDBase:OnRelease()
	self:SaveData()
end

--取活动ID
function CHDBase:GetID() return self.m_nID end
function CHDBase:GetName() return ctHuoDongConf[self.m_nID].sName end
--设置脏
function CHDBase:MarkDirty(bDirty) self.m_bDirty = bDirty end
--是否脏
function CHDBase:IsDirty() return self.m_bDirty end
--取活动状态
function CHDBase:GetState() return self.m_nState end
--取活动时间
function CHDBase:GetActTime() return self.m_nBegTime, self.m_nEndTime, self.m_nAwardTime end

--开启活动
function CHDBase:OpenAct(nBegTime, nEndTime, nAwardTime, nExtID, nExtID1)
	print("CHDBase:OpenAct***", nBegTime, nEndTime, nAwardTime)
	assert(nAwardTime >= 0, "奖励时间必须>=0")
	LuaTrace("开启活动:", self:GetID(), self:GetName(), "当前状态:", self.m_nState
		, "开始时间:", os.date("%Y-%m-%d %X", nBegTime) , "结束时间:", os.date("%Y-%m-%d %X", nEndTime) , "领奖时间:", nAwardTime
		, nExtID, nExtID1)

	self.m_nBegTime = nBegTime
	self.m_nEndTime = nEndTime
	self.m_nAwardTime = nEndTime+nAwardTime
	self:UpdateState()
	self:MarkDirty(true)
end

--取当前状态剩余时间
function CHDBase:GetStateTime()
	if self.m_nState == CHDBase.tState.eInit then
		return self.m_nBegTime, self.m_nEndTime, self.m_nBegTime-os.time()
	end
	if self.m_nState == CHDBase.tState.eStart then
		return self.m_nBegTime, self.m_nEndTime, self.m_nEndTime-os.time()
	end
	if self.m_nState == CHDBase.tState.eAward then
		return self.m_nEndTime, self.m_nAwardTime, self.m_nAwardTime-os.time()
	end
	if self.m_nState == CHDBase.tState.eClose then
		return self.m_nBegTime, self.m_nEndTime, 0
	end
end

--更新状态
function CHDBase:UpdateState()
	local nNowSec = os.time()
	if nNowSec < self.m_nBegTime then
		if self.m_nState ~= CHDBase.tState.eInit then
			self.m_nState = CHDBase.tState.eInit
			self:MarkDirty(true)
			self:OnStateInit()
		end
	end
	if nNowSec >= self.m_nBegTime and nNowSec < self.m_nEndTime then
		if self.m_nState ~= CHDBase.tState.eStart then
			self.m_nState = CHDBase.tState.eStart
			self.m_nOpenTimes = self.m_nOpenTimes + 1
			self:MarkDirty(true)
			self:OnStateStart()
		end
	end
	if nNowSec >= self.m_nEndTime and nNowSec < self.m_nAwardTime then
		if self.m_nState ~= CHDBase.tState.eAward then
			self.m_nState = CHDBase.tState.eAward
			self:MarkDirty(true)
			self:OnStateAward()
		end
	end
	if nNowSec >= self.m_nAwardTime then
		if self.m_nState ~= CHDBase.tState.eClose then
			self.m_nState = CHDBase.tState.eClose
			self:MarkDirty(true)
			self:OnStateClose()
		end
	end
end

--活动是否开启
function CHDBase:IsOpen()
	local nState = self:GetState()
	return (nState == CHDBase.tState.eStart)
end

--玩家上线
function CHDBase:Online()
end

--进入初始状态
function CHDBase:OnStateInit()
	print("活动:", self.m_nID, "进入初始状态")
end

--进入活动状态
function CHDBase:OnStateStart()
	print("活动:", self.m_nID, "进入开始状态")
end

--进入领奖状态
function CHDBase:OnStateAward()
	print("活动:", self.m_nID, "进入奖励状态")
end

--进入关闭状态
function CHDBase:OnStateClose()
	print("活动:", self.m_nID, "进入关闭状态")
end

--取活动开启次数
function CHDBase:GetOpenTimes()
	return self.m_nOpenTimes
end
