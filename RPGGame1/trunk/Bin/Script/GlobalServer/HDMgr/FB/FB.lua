--充值翻倍活动
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CFB:Ctor(nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self:Init()

end

function CFB:Init()
end

function CFB:LoadData()
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oSSDB:HGet(gtDBDef.sHuoDongDB, self:GetID())
	if sData == "" then return end

	local tData = cjson.decode(sData)
	CHDBase.LoadData(self, tData)
end

function CFB:SaveData()
	if not self:IsDirty() then
		return
	end

	local tData = CHDBase.SaveData(self)
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	oSSDB:HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
	self:MarkDirty(false)
end

--开启活动
function CFB:OpenAct(nStartTime, nEndTime, nAwardTime)
	CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime)	
end

--进入初始状态
function CFB:OnStateInit()
	LuaTrace("活动:", self.m_nID, "进入初始状态")
	self:SyncState()
end

--进入活动状态
function CFB:OnStateStart()
	LuaTrace("活动:", self.m_nID, "进入开始状态")
	self:Init()
	self:CheckSysOpen()
end

--进入领奖状态
function CFB:OnStateAward()
	LuaTrace("活动:", self.m_nID, "进入奖励状态")
end

--进入关闭状态
function CFB:OnStateClose()
	LuaTrace("活动:", self.m_nID, "进入关闭状态")
	self:CheckSysOpen()
end

--玩家上线
function CFB:Online(oRole)
	self:CheckSysOpen(oRole)
end

--检测系统开放
function CFB:CheckSysOpen(oRole)
	local nSysID = 80
	if self:IsOpen() then
		if oRole then
			if not oRole:IsSysOpen(nSysID) then
				Network.oRemoteCall:Call("OpenSystemReq", oRole:GetStayServer(), oRole:GetLogic(), 0, oRole:GetID(), nSysID)
			end
		else
			local tSessionMap = goGPlayerMgr:GetRoleSSMap()
			for nSession, oTmpRole in pairs(tSessionMap) do
				if not oTmpRole:IsSysOpen(nSysID) then
					Network.oRemoteCall:Call("OpenSystemReq", oTmpRole:GetStayServer(), oTmpRole:GetLogic(), 0, oTmpRole:GetID(), nSysID)
				end
			end
		end
	else
		if oRole then
			if oRole:IsSysOpen(nSysID) then
				Network.oRemoteCall:Call("CloseSystemReq", oRole:GetStayServer(), oRole:GetLogic(), 0, oRole:GetID(), nSysID)
			end
		else
			local tSessionMap = goGPlayerMgr:GetRoleSSMap()
			for nSession, oTmpRole in pairs(tSessionMap) do
				if oTmpRole:IsSysOpen(nSysID) then
					Network.oRemoteCall:Call("CloseSystemReq", oTmpRole:GetStayServer(), oTmpRole:GetLogic(), 0, oTmpRole:GetID(), nSysID)
				end
			end
		end
	end
end

--同步活动状态
function CFB:SyncState(oRole)
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
	}
	--同步给指定玩家
	if oRole then
		oRole:SendMsg("ActFBStateRet", tMsg)
	--全服广播
	else
		Network.PBSrv2All("ActFBStateRet", tMsg)
	end
end
