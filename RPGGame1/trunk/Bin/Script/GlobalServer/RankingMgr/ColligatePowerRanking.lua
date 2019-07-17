--综合战力榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CColligatePowerRanking:Ctor(nID)
	CRankingBase.Ctor(self, nID)
	self.m_tCongratMap = {} 	--祝贺映射
	self.m_nCongratTime = os.time() --祝贺时间

	self.m_nZeroTimer = nil
	self.m_bDirty = false
end

function CColligatePowerRanking:LoadData()
	CRankingBase.LoadData(self)

	--杂项
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	local sEtcData = oSSDB:HGet(gtDBDef.sRankingEtcDB, self:GetID())
	if sEtcData ~= "" then
		local tEtcData = cjson.decode(sEtcData)
		self.m_tCongratMap = tEtcData.m_tCongratMap
		self.m_nCongratTime = tEtcData.m_nCongratTime
	end

	self:OnZeroTimer()

	for k = 1, 10 do 
		local nRoleID = self:GetElementByRank(k)
		if not nRoleID then 
			break 
		end
		if nRoleID > 0 then 
			Network.oRemoteCall:Call("RemoveRoleFromRobotPoolReq", gnWorldServerID, 
				goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID)
		end
	end
end

function CColligatePowerRanking:SaveData()
	CRankingBase.SaveData(self)

	--杂项
	local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	if self:IsEtcDirty() then
		local tData = {}
		tData.m_tCongratMap = self.m_tCongratMap
		tData.m_nCongratTime = self.m_nCongratTime

		oSSDB:HSet(gtDBDef.sRankingEtcDB, self:GetID(), cjson.encode(tData))
		self:MarkEtcDirty(false)
	end
end

function CColligatePowerRanking:Release()
	CRankingBase.Release(self)
	GetGModule("TimerMgr"):Clear(self.m_nZeroTimer)
end

function CColligatePowerRanking:OnZeroTimer()
	GetGModule("TimerMgr"):Clear(self.m_nZeroTimer)
	self.m_nZeroTimer = GetGModule("TimerMgr"):Interval(os.NextHourTime1(0), function() self:OnZeroTimer() end)
	if self:CheckReset() then
		self:BroadcastCongrat()
	end
end

function CColligatePowerRanking:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nCongratTime, 0) then
		self.m_tCongratMap = {}
		self.m_nCongratTime = os.time()
		self:MarkEtcDirty(true)
		return true
	end
end

function CColligatePowerRanking:BroadcastCongrat()
	local tSSRoleMap = goGPlayerMgr:GetRoleSSMap()
	local tMsg = {nRankID=self:GetID(), bCanCongrat=true}
	Network.PBSrv2All("RankingRedpointRet", tMsg) 
end

function CColligatePowerRanking:Online(oRole)
	self:CheckReset()
	if not self:CheckSysOpen(oRole) then
		return
	end
	local nRoleID = oRole:GetID()
	local bCanCongrat = not self.m_tCongratMap[nRoleID]
	oRole:SendMsg("RankingRedpointRet", {nRankID=self:GetID(), bCanCongrat=bCanCongrat})
end

function CColligatePowerRanking:MarkEtcDirty(bDirty) self.m_bDirty = true end
function CColligatePowerRanking:IsEtcDirty() return self.m_bDirty end

function CColligatePowerRanking:OnRankChange(nRoleID, nNewRank, nOldRank)

	local nFilterRank = 10
	if nNewRank <= nFilterRank and (nOldRank > nFilterRank or nOldRank <= 0) then 
		Network.oRemoteCall:Call("RemoveRoleFromRobotPoolReq", gnWorldServerID, 
			goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID)

		local nTarRoleID = self:GetElementByRank(nFilterRank + 1)
		if nTarRoleID and nTarRoleID > 0 then 
			Network.oRemoteCall:Call("AddRole2RobotPoolReq", gnWorldServerID, 
				goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nTarRoleID)
		end
	end
	if nNewRank > nFilterRank and (nOldRank <= nFilterRank and nOldRank > 0) then 
		Network.oRemoteCall:Call("AddRole2RobotPoolReq", gnWorldServerID, 
			goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID)
		
		local nTarRoleID = self:GetElementByRank(nFilterRank + 1)
		if nTarRoleID and nTarRoleID > 0 then 
			Network.oRemoteCall:Call("RemoveRoleFromRobotPoolReq", gnWorldServerID, 
				goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nTarRoleID)
		end
	end
end

function CColligatePowerRanking:Update(nRoleID, nValue)
	local nOldRank = self:GetKeyRank(nRoleID)
	CRankingBase.Update(self, nRoleID, nValue)
	if nValue == 0 then
		return
	end
	local nNewRank = self:GetKeyRank(nRoleID)
	if nNewRank ~= nOldRank then 
		self:OnRankChange(nRoleID, nNewRank, nOldRank)
	end

	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local nSchool = oRole:GetSchool()
	local nRankID = gtSchoolRankingDef[nSchool]
	local oRanking = goRankingMgr:GetRanking(nRankID)
	oRanking:Update(nRoleID, nValue)
end

--祝贺
function CColligatePowerRanking:CongratReq(oRole)
	self:CheckReset()
	if not self:CheckSysOpen(oRole, true) then
		return
	end
	local nRoleID = oRole:GetID()
	local bCanCongrat = not self.m_tCongratMap[nRoleID]
	if not bCanCongrat then
		return oRole:Tips("你今天已经祝贺过了")
	end
	self.m_tCongratMap[nRoleID] = 1
	self:MarkEtcDirty(true)

	local nYuanBao = 1000
	local tItemList = {{nType=gtItemType.eCurr, nID=gtCurrType.eBYuanBao, nNum=nYuanBao}}
	oRole:AddItem(tItemList, "排行榜祝贺")
	oRole:SendMsg("RankingRedpointRet", {nRankID=self:GetID(), bCanCongrat=false})
	
	Network.oRemoteCall:Call("OnCongratulate", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
	oRole:Tips("祝贺成功")
end

--排行榜请求,特殊需求派生类实现
function CColligatePowerRanking:RankingReq(oRole, nRankNum)
	self:CheckReset()

	local nRoleID = oRole:GetID()
	nRankNum = math.max(1, math.min(CRankingBase.nMaxViewNum, nRankNum))

	--我的排名
	local nMyRank = self:GetKeyRank(nRoleID)
	local tMyData = self:GetKeyData(nRoleID)
	local nMyValue = tMyData and tMyData[1] or 0
	local bCanCongrat = not self.m_tCongratMap[nRoleID]

	--前nRankNum名
	local tRanking = {}
	local function _fnTraverse(nRank, nRoleID, tData)
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole then
			local tRank = {nRank=nRank, nValue=tData[1], nRoleID=nRoleID, sRoleName=oRole:GetName(), nSchool=oRole:GetSchool()}
			table.insert(tRanking, tRank)
		end
	end
	self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
	local tMsg = {
		nRankID = self:GetID(),
		tRanking = tRanking,
		nMyRank = nMyRank,
		nMyValue = nMyValue,
		bCanCongrat = bCanCongrat,
	}
	oRole:SendMsg("RankingListRet", tMsg)
end
