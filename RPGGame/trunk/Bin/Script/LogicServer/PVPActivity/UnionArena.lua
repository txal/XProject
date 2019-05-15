--帮战
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CUnionArena:Ctor(oModul, nActivityID, nSceneID,nUnionID,nEnemyUnionID, nOpenTime, nEndTime, nPrepareLastTime)
	print("正在创建<帮战>活动实例, 活动ID:"..nActivityID..", 场景ID:"..nSceneID..", 帮派派ID:"..nUnionID)
	CPVPActivityBase.Ctor(self, oModul, nActivityID, nSceneID, nOpenTime, nEndTime, nPrepareLastTime)
	self.m_nUnionID = nUnionID
	self.m_nEnemyUnionID = nEnemyUnionID
	self.m_tUnionData = {}
	self.m_nWinUnionID = 0
end


function CUnionArena:AddUnionData(nUnionID,tData)
	self.m_tUnionData[nUnionID] = tData
end

function CUnionArena:GetUnionName(nUnionID)
	local tData = self.m_tUnionData[nUnionID] or {}
	return tData["sName"]
end

function CUnionArena:GetUnionID() return self.m_nUnionID end
function CUnionArena:GetBattleDupType() return gtBattleDupType.eUnionArena end 

function CUnionArena:GetMixDupType(oRole) --玩法类型ID，用于快速组队
	local nUnionID = oRole:GetUnionID()
	return (nUnionID <<  32) | gtBattleDupType.eUnionArena
end

function CUnionArena:GetDupTypeName(oRole) --组队区分
	local tConf = self:GetConf()
	local nUnionID = oRole:GetUnionID()
	local sUnionName = self:GetUnionName(nUnionID)
	return (tConf.sActivityName.."["..sUnionName.."]")
end

function CUnionArena:EnterCheckReq(nRoleID,nUnionID)
	return true
end
function CUnionArena:GetWinUnion() return self.m_nWinUnionID end

--检查活动是否结束
function CUnionArena:CheckEnd()
	if not self:IsStart() then --只有当前活动处于已开始状态，才有检查结束的必要性
		return false
	end
	local bEnd = self:CheckTimeEnd()
	if bEnd then
		return true
	end
	local nActiveNum = 0
	local tActiveNum = {}
	for k, oRoleData in pairs(self.m_tRoleMap) do
		if oRoleData:IsActive() then
			local nUnionID = oRoleData:GetUnionID()
			if not tActiveNum[nUnionID] then
				tActiveNum[nUnionID] = 0
			end
			tActiveNum[nUnionID] = tActiveNum[nUnionID] + 1
		end
	end
	--只剩下一方时结束
	if table.Count(tActiveNum) <= 1 then
		return true
	end
	return bEnd
end

function CUnionArena:OnEnd() 
	self.m_nWinUnionID = self:CheckWinUnion()
	CPVPActivityBase.OnEnd(self)
end

function CUnionArena:CheckWinUnion()
	local tOnlineCnt = {}
	for k, oRoleData in pairs(self.m_tRoleMap) do
		if oRoleData:IsActive() then
			local nUnionID = oRoleData:GetUnionID()
			if not tOnlineCnt[nUnionID] then
				tOnlineCnt[nUnionID] = 0
			end
			tOnlineCnt[nUnionID] = tOnlineCnt[nUnionID] + 1
		end
	end
	local nCnt
	local nWinUnion
	for nUnionID,nOnlineCnt in pairs(tOnlineCnt) do
		if not nCnt or nCnt < nOnlineCnt then
			nCnt = nOnlineCnt
			nWinUnion = nUnionID
		end
	end
	return nWinUnion or 0
end

function CUnionArena:GetUnionOnlineData()
	local tOnlineCnt = {}
	for k, oRoleData in pairs(self.m_tRoleMap) do
		if oRoleData:IsActive() then
			local nUnionID = oRoleData:GetUnionID()
			if not tOnlineCnt[nUnionID] then
				tOnlineCnt[nUnionID] = 0
			end
			tOnlineCnt[nUnionID] = tOnlineCnt[nUnionID] + 1
		end
	end
	return tOnlineCnt
end

--战斗胜利奖励
function CUnionArena:AddRankReward()
	--通过邮件，给所有玩家发送奖励，因为很多玩家已不在当前逻辑服了，甚至下线了
	local sPVPActName= self:GetConf().sActivityName
	local sMailContent = string.format("%s活动胜利,这是此次活动的奖励",sPVPActName)
	local nWinUnion = self:GetWinUnion()
	local sMailTitle = sPVPActName
	local nServerID
	local nServiceID
	for nRoleID, oRoleData in pairs(self.m_tRoleMap) do
		if oRoleData:GetUnionID() == nWinUnion then
			nServerID = oRoleData.m_nServer
			nServiceID = goServerMgr:GetGlobalService(nServerID, 20)

			local tRewardPoolList = self:GetRankRewardList(1) --可能不存在奖励
			if tRewardPoolList and #tRewardPoolList > 0 then
				goRewardLaunch:MailLaunch(nRoleID, nServerID, tRewardPoolList, 
					oRoleData.m_nLevel, oRoleData.m_nRoleConfID, "PVP活动排行榜奖励",
					sMailTitle, sMailContent)
			end
		end
	end
	if nServerID and nServiceID then
		local nType = gtUnionGiftBoxReason.eUnionArena
		local nCnt = 5
		goRemoteCall:Call("AddUnionGiftBoxCnt",nServerID,nServiceID,0,nWinUnion,nType,nCnt)
	end
end

--同步活动数据
function CUnionArena:SyncPVPUnionData(oRole)
	local tOnlineCnt = self:GetUnionOnlineData()
	local tMsg = {}
	local tUnionData = {}
	for nUnionID,tData in pairs(self.m_tUnionData) do
		local nOnlineCnt = tOnlineCnt[nUnionID] or 0
		table.insert(tUnionData,{nUnionID = nUnionID,nOnlineCnt = nOnlineCnt,sName=self:GetUnionName(nUnionID)})
	end
	tMsg.nActivityID = self:GetActivityID()
	tMsg.tUnionData = tUnionData
	for k, oRoleData in pairs(self.m_tRoleMap) do
		if not oRoleData.m_bLeave then
			local oRole = goPlayerMgr:GetRoleByID(oRoleData.m_nRoleID)
			if oRole then
				oRole:SendMsg("PVPUnionDataRet",tMsg)
			end
		end
	end
end

function CUnionArena:AfterRoleEnter(oRole)
	CPVPActivityBase.AfterRoleEnter(self, oRole)
	self:SyncPVPUnionData(oRole)
end

--玩家离场
function CUnionArena:OnRoleLeave(oRole)
	CPVPActivityBase.OnRoleLeave(self, oRole)
	self:SyncPVPUnionData(oRole)
end

function CUnionArena:ValidBattle(oRole,nEnemyID)
	local oEnemyRole = goPlayerMgr:GetRoleByID(nEnemyID)
	if not oEnemyRole then
		return false
	end
	if oRole:GetUnionID() == oEnemyRole:GetUnionID() then
		oRole:Tips("同一个帮派不能PK")
		return false
	end
	return true
end

function CUnionArena:GetPBRankDataByRank(nRoleID, nRank)
	local tData = CPVPActivityBase.GetPBRankDataByRank(self, nRoleID, nRank)
	local oRoleData = self:GetRoleData(nRoleID)
	tData.nUnionID = oRoleData.m_nUnionID
	tData.sUnionName = self:GetUnionName(oRoleData.m_nUnionID)
	return tData
end

function CUnionArena:TickAddRobot(nTimeStamp)
	return 
end

