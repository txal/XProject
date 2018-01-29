--皇榜管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHBMgr:Ctor()
end

--玩家上线
function CHBMgr:Online(oPlayer, nID)
	if nID and nID == gtHDDef.eGLHB then --只发送1次
		self:SyncState(oPlayer)
	end
end

--进入初始状态
function CHBMgr:OnStateInit()
	self:SyncState()
end

--进入活动状态
function CHBMgr:OnStateStart()
	self:SyncState()
end

--进入领奖状态
function CHBMgr:OnStateAward()
	self:SyncState()
end

--进入关闭状态
function CHBMgr:OnStateClose()
	self:SyncState()
end

function CHBMgr:MakeMsg(oPlayer)
	local tMsg = {tActList={}}
	for k = gtHDDef.eGLHB, gtHDDef.eLMHB do
		local oAct = goHDMgr:GetHuoDong(k)
		if oAct then
			local nState = oAct:GetState()
			if nState ~= CHDBase.tState.eClose then
				local nStateTime = oAct:GetStateTime()
				local nBegTime, nEndTime, nAwardTime = oAct:GetActTime()
				local tAct = {
					nID=k, 
					nState=nState, 
					nStateTime=nStateTime, 
					nBegTime=nBegTime, 
					nEndTime=nEndTime,  
					nAwardTime=nAwardTime,
					nOpenTimes=oAct:GetOpenTimes(),
					bCanGetAward=oAct:CanGetAward(oPlayer)
				}
				table.insert(tMsg.tActList, tAct)
			end
		end
	end
	return tMsg
end

--同步状态
function CHBMgr:SyncState(oPlayer)
	if oPlayer then
		local tMsg = self:MakeMsg(oPlayer)
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "HBInfoRet", tMsg)
	else
		local tSessionMap = goPlayerMgr:GetSessionMap()
		for nSession, oTmpPlayer in pairs(tSessionMap) do
			local tMsg = self:MakeMsg(oTmpPlayer)
			CmdNet.PBSrv2Clt(oTmpPlayer:GetSession(), "HBInfoRet", tMsg)
		end
	end
end

goHBMgr = goHBMgr or CHBMgr:new()