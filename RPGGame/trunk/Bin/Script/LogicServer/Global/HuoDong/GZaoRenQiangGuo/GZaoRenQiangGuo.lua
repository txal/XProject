--造人强国活动全服模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGZaoRenQiangGuo:Ctor(nID)
	CHDBase.Ctor(self, nID)
	self.m_nVersion = 1					--版本号
end

function CGZaoRenQiangGuo:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nVersion = tData.m_nVersion or self.m_nVersion
		CHDBase.LoadData(self, tData)
	end
end

function CGZaoRenQiangGuo:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_nVersion = self.m_nVersion
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end


--取版本
function CGZaoRenQiangGuo:GetVersion()
	return self.m_nVersion
end

--玩家上线
function CGZaoRenQiangGuo:Online(oPlayer)
	self:SyncState(oPlayer)
end

--进入初始状态
function CGZaoRenQiangGuo:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CGZaoRenQiangGuo:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self.m_nVersion = self.m_nVersion + 1
	goRankingMgr.m_oZRQGRanking:ResetRanking()
	self:SyncState()
	self:MarkDirty(true)
end

--进入领奖状态
function CGZaoRenQiangGuo:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
	self:SyncState()
end

--进入关闭状态
function CGZaoRenQiangGuo:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:SyncState()
end

--同步活动状态
function CGZaoRenQiangGuo:SyncState(oPlayer)
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
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ZRQGStateRet", tMsg)
	--全服广播
	else
		CmdNet.PBSrv2All("ZRQGStateRet", tMsg) 
	end
end