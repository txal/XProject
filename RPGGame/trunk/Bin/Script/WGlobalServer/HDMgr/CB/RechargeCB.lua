--全服充值冲榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRechargeCB:Ctor(nID)
	CCBBase.Ctor(self, nID)     --继承基类
	self.m_nRobotSerial = 0
end

function CRechargeCB:Init()
	CCBBase.Init(self)
	-- self.m_nRobotSerial = 0 
	--这个不重置，如果单服充值活动时间不一致, 会导致单服活动数据冲突
	self.m_tRobotNameMap = {}
end

function CRechargeCB:DealLoadData(tData) 
	CCBBase.DealLoadData(self, tData)
	self.m_nRobotSerial = tData.m_nRobotSerial or self.m_nRobotSerial
	self.m_tRobotNameMap = tData.m_tRobotNameMap or self.m_tRobotNameMap
end

function CRechargeCB:GetSaveData() 
	local tData = CCBBase.GetSaveData(self)
	tData.m_nRobotSerial = self.m_nRobotSerial
	tData.m_tRobotNameMap = self.m_tRobotNameMap
	return tData
end

function CRechargeCB:GetRankingConf()
	return ctRechargeRankingKFConf
end

function CRechargeCB:GetAwardRanking()
	local tConf = ctMZCBEtcConf[1]
	return 1, tConf.nRechargeAwardRanking
end

--获取上榜条件值
function CRechargeCB:GetRankLimitValue()
	return ctMZCBEtcConf[1].nRechargeRankLimitValue
end

function CRechargeCB:GetFirstRank()
	local tRank = self.m_tTmpRanking[1] 
	if not tRank then
		return "", 0
	end
	if not self:IsRobot(tRank[1]) then 
		local oRole = goGPlayerMgr:GetRoleByID(tRank[1])
		return oRole:GetName(), tRank[2]
	else
		return self:GetRobotName(tRank[1]), tRank[2]
	end
end


--冲榜榜单请求
function CRechargeCB:RankingReq(oRole, nRankNum)
	if self:GetState() == CHDBase.tState.eInit or self:GetState() == CHDBase.tState.eClose then
		return oRole:Tips("活动已结束")
	end

	local nMinRank, nMaxRank = self:GetAwardRanking()
	nRankNum = math.max(1, math.min(nMaxRank, nRankNum))
	local nMyRank, nMyValue = self:MyRank(oRole:GetID())

	local tRanking = {}
	for k=1, nRankNum do 
		local tRank = self.m_tTmpRanking[k]
		if tRank then
			local nRoleID = tRank[1]
			if not self:IsRobot(nRoleID) then 
				local oTempRole = goGPlayerMgr:GetRoleByID(tRank[1])
				local sExtName = oTempRole and goServerMgr:GetServerName(oTempRole:GetServer()) or ""
				-- local nValue = tRank[2]
				-- if #tRanking >= 3 then
				-- 	nValue = "***" --运营指定,显示前50名,只有前3显示充值金额.
				-- end
				local nValue = "???"  --策划要求所有充值金额都设置为'???'

				local tData = {}
				tData.nRank = k
				tData.sName = oTempRole:GetName()
				tData.nValue = nValue
				tData.sExtName = sExtName
				if k == 1 then 
					tData.tShapeData = oTempRole:GetShapeData()
				end
				table.insert(tRanking, tData)
			else
				local sExtName = ""
				local nValue = "???"
				table.insert(tRanking, {nRank=k, sName=self:GetRobotName(nRoleID), nValue=nValue, 
					sExtName=sExtName})
			end
		else
			break
		end
	end

	local tMsg = {
		nID = self:GetID(),
		tRanking = tRanking,
		nMyRank = nMyRank,
		nMyValue = nMyValue,
	}
	oRole:SendMsg("CBRankingRet", tMsg)
	print("RankingReq***", self:GetName(), tMsg)
end

--生成机器人ID
function CRechargeCB:GenRobotID()  --使用角色的
	self.m_nRobotSerial = self.m_nRobotSerial % gnRobotIDMax + 1
	self:MarkDirty(true)
	return self.m_nRobotSerial
end

function CRechargeCB:IsRobot(nRoleID)
	if nRoleID > 0 and nRoleID <= gnRobotIDMax then
		return true 
	end
	return false
end

function CRechargeCB:GetRobotName(nRoleID)
	return self.m_tRobotNameMap[nRoleID] or ""
end

--检测未领奖的玩家,然后发奖
function CRechargeCB:CheckCloseAward()
	local nMinRank, nMaxRank = self:GetAwardRanking()
	for k = nMinRank, nMaxRank do
		local tRank = self.m_tTmpRanking[k]
		if tRank then
			local nRoleID = tRank[1]
			if not self:IsRobot(nRoleID) then 
				if self.m_tAwardState[nRoleID] == CHDBase.tAwardState.eFeed then
					self.m_tAwardState[nRoleID] = CHDBase.tAwardState.eClose
					self:MarkDirty(true)

					local oRole = goGPlayerMgr:GetRoleByID(nRoleID)	
					local sCont = string.format("您在%s活动中获得第%d名，获得了以下奖励，请查收。", self:GetName(), k)
					GF.SendMail(oRole:GetServer(), self:GetName().."奖励", sCont, self:GetRankAward(nRoleID, k), nRoleID)
				end
			end
		end
	end
end

--Redmine#5664
--策划新需求，要求往排行榜加入假数据，数量等同于团购机器人数量
--机器人充值金额都为6元
function CRechargeCB:OnRobotRecharge(nRobotNum, nServerID) 
	print("世界服机器人充值冲榜, 数量", nRobotNum)
	for k = 1, nRobotNum do 
		local nRoleID = self:GenRobotID()
		local sName = GF.GenNameByPool() --忽略重名等情况
		local nRechargeVal = 6  --默认充值6块
		if self:IsOpen() then 
			self.m_tRobotNameMap[nRoleID] = sName
			self:MarkDirty(true)
			self:UpdateValue(nRoleID, nRechargeVal)
		end
		-- --随机派发通知到一个逻辑服，防止全区数据和单服数据不一致
		-- local tServerMap = goServerMgr:GetServerMap()
		-- local tServerList = table.Keys(tServerMap)
		-- if #tServerList > 0 then 
		-- 	local nTarServer = tServerList[math.random(#tServerList)]
		-- 	local nService = goServerMgr:GetGlobalService(nTarServer, 20)
		-- 	goRemoteCall:Call("OnRobotRechargeCB", nTarServer, 
		-- 		nService, 0, nRoleID, sName, nRechargeVal)
		-- end
		local nService = goServerMgr:GetGlobalService(nServerID, 20)
		goRemoteCall:Call("OnRobotRechargeCB", nServerID, 
				nService, 0, nRoleID, sName, nRechargeVal)
	end
end
