--好友对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxDegrees = 50000 --好友度上限
local nMaxDayBattleDegrees = 100 --每天战斗好友度上限
-- local nFlowerOnlyDegrees = 5000 --只能送鲜花道具的好友度限制
local nMaxTalkHistory = 20 --聊天记录保存

function CFriend:Ctor(oFriendMgr, nSrcRoleID, nRoleID, bStranger)
	assert(nSrcRoleID and nRoleID, "参数错误")
	self.m_oFriendMgr = oFriendMgr
	
	self.m_nSrcRoleID = nSrcRoleID --谁的好友或陌生人
	self.m_nRoleID = nRoleID --好友或陌生人
	self.m_nAddTime = os.time()
	self.m_nDegrees = 0
	self.m_bStranger = bStranger 	--是否陌生人

	--战斗好友度
	self.m_nDayBattleDegrees = 0
	self.m_nLastResetTime = os.time()

	--聊天记录
	self.m_tTalkHistory = {}

	------不保存
	self.m_nOfflineTalk = 0
end

function CFriend:LoadData(tData)
	for sKey, xVal in pairs(tData) do
		self[sKey] = xVal
	end
end

function CFriend:SaveData()
	local tData = {}
	tData.m_nSrcRoleID = self.m_nSrcRoleID
	tData.m_nRoleID = self.m_nRoleID
	tData.m_nAddTime = self.m_nAddTime
	tData.m_nDegrees = self.m_nDegrees
	tData.m_nDayBattleDegrees = self.m_nDayBattleDegrees
	tData.m_nLastResetTime = self.m_nLastResetTime
	tData.m_tTalkHistory = self.m_tTalkHistory
	tData.m_bStranger = self.m_bStranger
	return tData
end

function CFriend:OnRelease()
	if not self.m_bStranger then
		local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
		goRemoteCall:Call("OnTAHYDReq", oRole:GetServer(), goServerMgr:GetGlobalService(oRole:GetServer(),20), 0, oRole:GetID(), -self:GetDegrees())

		--总好友度
		self.m_oFriendMgr:OnDegreesChange(self.m_nSrcRoleID)
	end
end

function CFriend:MarkDirty(bDirty)
	if self.m_bStranger then
		self.m_oFriendMgr:MarkStrangerDirty(self.m_nSrcRoleID, bDirty)
	else		
		self.m_oFriendMgr:MarkFriendDirty(self.m_nSrcRoleID, bDirty)
	end
end

function CFriend:GetID() return self.m_nRoleID end
function CFriend:GetAddTime() return self.m_nAddTime end
function CFriend:GetDegrees() return self.m_nDegrees end

--重置好友度
function CFriend:ResetDegrees() 
	self.m_nDegrees = 0
	self:MarkDirty(true)

	local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
    goLogger:EventLog(gtEvent.eResetFriendDegree, oRole)
end

--只能通过鲜花道具增加好友度
-- function CFriend:IsFlowerOnly()
-- 	return (self.m_nDegrees>=nFlowerOnlyDegrees)
-- end

--检测战斗好友度重置
function CFriend:CheckBattleDegreeReset()
	if not os.IsSameDay(os.time(), self.m_nLastResetTime, 0) then
		self.m_nDayBattleDegrees = 0
		self.m_nLastResetTime = os.time()
		self:MarkDirty(true)
	end
end

--添加好友度
function CFriend:AddDegrees(nVal, sReason)
	assert(nVal and sReason, "参数错误")
	assert(not self.m_bStranger, "非好友")

	local nOldDegrees = self.m_nDegrees
	self.m_nDegrees = math.max(0, math.min(nMaxDegrees, self.m_nDegrees+nVal))
	self:MarkDirty(true)

	--日志
	local oRole = goGPlayerMgr:GetRoleByID(self:GetID())
    goLogger:EventLog(gtEvent.eFriendDegree, oRole, nVal, self.m_nDegrees)

    --成就
    if nOldDegrees < 1000 and self.m_nDegrees >= 1000 then
    	oRole:PushAchieve("友好度1000以上好友数",{nValue = 1})
    end

    --好友度涨幅
    local nDiffVal = self.m_nDegrees-nOldDegrees
	goRemoteCall:Call("OnTAHYDReq", oRole:GetServer(), goServerMgr:GetGlobalService(oRole:GetServer(),20), 0, oRole:GetID(), nDiffVal)

	--总好友度
	self.m_oFriendMgr:OnDegreesChange(self.m_nSrcRoleID)

    return nDiffVal
end

--战斗增加好友度
function CFriend:OnBattleEnd()
	self:CheckBattleDegreeReset()
	if self.m_nDayBattleDegrees >= nMaxDayBattleDegrees then
		return
	end
	self.m_nDayBattleDegrees = self.m_nDayBattleDegrees + 1
	self:MarkDirty(true)

	return self:AddDegrees(1, "好友组队战斗")
end

--道具增加好友度
-- function CFriend:OnSendProp(nPropID, nPropNum)
-- 	local tPropConf = ctPropConf[nPropID]
-- 	local nDegrees = 0

-- 	if tPropConf.nType ~= gtPropType.eFlower then
-- 		if self:IsFlowerOnly() then return 0 end
-- 		nDegrees = 1 * nPropNum
-- 	end

-- 	if tPropConf.nType == gtPropType.eFlower then
-- 		nDegrees = tPropConf.eParam() * nPropNum
-- 	end
	
-- 	return self:AddDegrees(nDegrees, string.format("赠送道具ID:%d NUM:%d", nPropID, nPropNum))
-- end

--@bOffline 是否离线聊天
function CFriend:AddTalk(tTalkMsg, bOffline)
	table.insert(self.m_tTalkHistory, tTalkMsg)
	if #self.m_tTalkHistory > nMaxTalkHistory then
		table.remove(self.m_tTalkHistory, 1)
	end
	self:MarkDirty(true)
	if bOffline then
		self.m_nOfflineTalk = self.m_nOfflineTalk + 1
	end
end

function CFriend:GetOfflineTalk()
	return self.m_nOfflineTalk
end
function CFriend:ClearOfflineTalk()
	self.m_nOfflineTalk = 0
end

function CFriend:GetTalkList()
	return self.m_tTalkHistory
end

function CFriend:GetLastTalk()
	return self.m_tTalkHistory[#self.m_tTalkHistory]
end
