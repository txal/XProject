--神秘宝箱全局模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGShenMiBaoXiang:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_nVersion = 1
end

function CGShenMiBaoXiang:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nVersion = tData.m_nVersion
		CHDBase.LoadData(self, tData)
	end
end

function CGShenMiBaoXiang:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_nVersion = self.m_nVersion
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

--玩家上线
function CGShenMiBaoXiang:Online(oPlayer)
	self:SyncState(oPlayer)
end

--取版本
function CGShenMiBaoXiang:GetVersion()
	return self.m_nVersion
end

--进入初始状态
function CGShenMiBaoXiang:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CGShenMiBaoXiang:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self.m_nVersion = self.m_nVersion + 1
	self:MarkDirty(true)
	self:SyncState()
end

--进入领奖状态
function CGShenMiBaoXiang:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CGShenMiBaoXiang:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
end

--同步活动状态
function CGShenMiBaoXiang:SyncState(oPlayer)
	-- local nState = self:GetState()
	-- local nStateTime = self:GetStateTime()
	-- local nBeginTime, nEndTime = self:GetActTime()
	-- local tMsg = {
	-- 	nID = self:GetID(),
	-- 	nState = nState,
	-- 	nStateTime = nStateTime,
	-- 	nBeginTime = nBeginTime,
	-- 	nEndTime = nEndTime,
	-- }
	-- --同步给指定玩家
	-- if oPlayer then
	-- 	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ShenMiBaoXiangStateRet", tMsg)
	-- --全服广播
	-- else
	-- 	CmdNet.PBSrv2All("ShenMiBaoXiangStateRet", tMsg) 
	-- end
end
