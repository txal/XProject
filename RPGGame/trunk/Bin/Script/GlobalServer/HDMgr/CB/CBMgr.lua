--冲榜管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CCBMgr:Ctor()
end

--玩家上线
function CCBMgr:Online(oRole, nID)
	if nID == gtHDDef.ePowerCB then
		self:SyncState(oRole)
	end
end

--进入初始状态
function CCBMgr:OnStateInit()
	self:SyncState()
end

--进入活动状态
function CCBMgr:OnStateStart()
	self:SyncState()
end

--进入领奖状态
function CCBMgr:OnStateAward()
	self:SyncState()
end

--进入关闭状态
function CCBMgr:OnStateClose()
	self:SyncState()
end

function CCBMgr:MakeMsg(oRole)
	local tMsg = {tActList={}, nSingleServer=1}
	for nID = gtHDDef.ePowerCB, gtHDDef.eResumeYBCB do
		local oAct = goHDMgr:GetActivity(nID)
		if oAct then
			local nState = oAct:GetState()
			local nBeginTime, nEndTime, nStateTime = 0, 0, 0
			if nState == CHDBase.tState.eClose then
				nBeginTime, nEndTime = goHDCircle:GetActNextOpenTime(nID)
				if nBeginTime > 0 and nBeginTime > os.time() then
					assert(nEndTime>nBeginTime, "下次开启时间错误")
					nState = CHDBase.tState.eInit
					nStateTime = nEndTime - nBeginTime
				end
			else
				nBeginTime, nEndTime, nStateTime = oAct:GetStateTime()
			end
			local tAct = {
				nID=nID, 
				nState=nState, 
				nBeginTime=nBeginTime, 
				nEndTime=nEndTime,  
				nStateTime=nStateTime, 
				nOpenTimes=oAct:GetOpenTimes(),
				bCanGetAward=oAct:CanGetAward(oRole),
			}
			table.insert(tMsg.tActList, tAct)
		end
	end
	return tMsg
end

--同步状态
function CCBMgr:SyncState(oRole)
	if oRole then
		local tMsg = self:MakeMsg(oRole)
		oRole:SendMsg("CBInfoRet", tMsg)
	else
		local tRoleSSMap = goGPlayerMgr:GetRoleSSMap()
		for nSSKey, oTmpRole in pairs(tRoleSSMap) do
			local tMsg = self:MakeMsg(oTmpRole)
			oTmpRole:SendMsg("CBInfoRet", tMsg)
		end
	end
end

goCBMgr = goCBMgr or CCBMgr:new()