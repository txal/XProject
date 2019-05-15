--尊师考验副本
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CTeachTest:Ctor(nID, nType)
    print(">>>>>>>>>>>>>>>>>>>>>>>>创建副本尊师考验")
    self.m_nID = nID 						--战斗副本ID
	self.m_nType = nType 					--副本战斗类型
	self.m_tDupList = GF.WeakTable("v") 	--地图列表{地图对象,...}
	self.m_tRoleMap = GF.WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = GF.WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...}
    
    self:Init()
end

function CTeachTest:Init()
	local tConf = ctBattleDupConf[self.m_nType]
	for _, tDup in ipairs(tConf.tDupList) do
		local oDup = goDupMgr:CreateDup(tDup[1])
	    oDup:SetAutoCollected(false) --设置非自动收集
		table.insert(self.m_tDupList, oDup)
	end
	for _, oDup in pairs(self.m_tDupList) do
		oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
		oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
		oDup:RegLeaderActivityCallback(function(oLuaObj, nLastPacketTime) self:OnLeaderActivity(oLuaObj, nLastPacketTime) end)
		oDup:RegLeaveTeamCallback(function(oLuaObj) self:OnLeaveTeam(oLuaObj) end )
		oDup:RegBattleEndCallback(function(...) self:OnBattleEnd(...) end )
		oDup:RegTeamChangeCallback(function(oLuaObj) self:OnTeamChange(oLuaObj) end)
    end
    
    --创建所有怪物
    local tBattleDupConf = self:GetConf()
	local tMonster = tBattleDupConf.tMonster
	for nIndex, tID in ipairs(tMonster) do
		self:CreateMonster(tID[1])
	end
end

function CTeachTest:OnRelease() 
	print("尊师考验副本被销毁", self.m_nID)
	for _, oDup in pairs(self.m_tDupList) do
		goDupMgr:RemoveDup(oDup:GetMixID())
	end
	self.m_tDupList = {}
	self.m_tRoleMap = {}
	self.m_tMonsterMap = {}
end

function CTeachTest:OnTeamChange(oLuaObj)
end

function CTeachTest:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

function CTeachTest:GetID() return self.m_nID end --战斗副本ID
function CTeachTest:GetType() return self.m_nType end --取副本战斗类型
function CTeachTest:GetConf() return ctBattleDupConf[self:GetType()] end
function CTeachTest:HasRole() return next(self.m_tRoleMap) end --是否有玩家

function CTeachTest:OnObjEnter(oLuaObj, bReconnect) 
    local nObjType = oLuaObj:GetObjType()
    --怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj
		self:SyncDupInfo()

	--人物
	elseif nObjType == gtObjType.eRole then
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
		oLuaObj:SetBattleDupID(self:GetID())
		self:SyncDupInfo(oLuaObj)
	end
end

function CTeachTest:OnObjLeave(oLuaObj, nBattleID)
	local nObjType = oLuaObj:GetObjType()
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = nil
		local nMonsterID = 0		
		local nObjID, oMonsterObj = next(self.m_tMonsterMap)
		if oMonsterObj then
			nMonsterID = oMonsterObj:GetConfID()
		end
		-- oRole:GetTeam(function(nTeamID, tTeam)
		-- 	for _, tRole in ipairs(tTeam) do 
		-- 		local oMember = goPlayerMgr:GetRoleByID(tRole.nRoleID)
		-- 		if oMember then
		-- 			print(">>>>>>>>>>>>>>>>>>>>>>>>>尊师考验下个目标"..nMonsterID)
		-- 			oMember:SendMsg("TeachTestNextMonInfoRet", {nMonsterID=nMonsterID})
		-- 		end
		-- 	end
		-- end)
		print(">>>>>>>>>>>>>>>>>>>>>>>>>尊师考验下个目标"..nMonsterID)
		local tSessionList = self:GetSessionList()
		CmdNet.PBBroadcastExter("TeachTestNextMonInfoRet", tSessionList, {nMonsterID=nMonsterID})


    elseif nObjType == gtObjType.eRole then
        if nBattleID <= 0 then
			oLuaObj:SetBattleDupID(0)
			self.m_tRoleMap[oLuaObj:GetID()] = nil
		end
    end
end

function CTeachTest:OnLeaveTeam(oLuaObj)
	print("CZhenYao:OnLeaveTeam***")
	if oLuaObj:GetID() == self.m_nLeaderID then
		self.m_bLeaderLeave = true
	end
	oLuaObj:EnterLastCity()
end

function CTeachTest:GetLeader()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsLeader() then
			return oRole
		end
	end
end

function CTeachTest:OnBattleEnd(oLuaObj, tBTRes, tExtData)
	print("CZhenYao:OnBattleEnd***")
	local nObjType = oLuaObj:GetObjType() --gtObjType

	self.m_nLeaveBattleTimeStamp = os.time()
	if nObjType == gtObjType.eMonster then
		if tBTRes.bWin then --怪物没死亡
			self:SyncDupInfo()
		end
		
    elseif nObjType == gtObjType.eRole and tBTRes.bWin then
		local oHolidayTeachTest = oLuaObj.m_oHolidayActMgr:GetActByHolidayActType(gtHolidayActType.eTeachTest)
		if not oHolidayTeachTest then return end
		local nAlreadyKillTimes = oHolidayTeachTest:GetKillMonsterTimes(tExtData.nIndex)
		if 0 <= nAlreadyKillTimes and nAlreadyKillTimes < ctTeachTestConf[tExtData.nMonsterID].nMaxKill then
			self:Reward(oLuaObj, tExtData.nMonsterID, oHolidayTeachTest)
		end
		oHolidayTeachTest:SetKillMonsterTimes(tExtData.nIndex)
    end
end

function CTeachTest:Reward(oRole, nMonsterID, oHolidayTeachTest)
	assert(ctTeachTestConf[nMonsterID], "尊师考验奖励参数有误")
	local nCurrSeq = oHolidayTeachTest:GetAlreadyKillMonCount() + 1
	local nMaxMonsterNum = oHolidayTeachTest:GetTotalMonsterNum()
	if nCurrSeq > nMaxMonsterNum then return end
	local fnRoleExp = ctTeachTestConf[nMonsterID].fnRoleExp
	local fnPetExp = ctTeachTestConf[nMonsterID].fnPetExp
	local fnYinBi = ctTeachTestConf[nMonsterID].fnYinBi
	local nRoleLevel = oRole:GetLevel()
	local nRoleExp = fnRoleExp(nRoleLevel, nCurrSeq)
	local nPetExp = fnPetExp(nRoleLevel, nCurrSeq)
	local nYinBi = fnYinBi(nCurrSeq, nRoleLevel)
	local tRewardList = ctTeachTestConf[nMonsterID].tRewardItem
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "尊师考验奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "尊师考验奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "尊师考验奖励")
	for nIndex, tItem in ipairs(tRewardList) do
		oRole:AddItem(gtItemType.eProp, tItem[1], tItem[2], "尊师考验奖励")
	end
	if nCurrSeq == nMaxMonsterNum then
		--额外奖励
		local nPoolID = ctTeachTestConf[nMonsterID].tExtraReward[1][1]
		local nTimes = ctTeachTestConf[nMonsterID].tExtraReward[1][2]
		local tPool = ctAwardPoolConf.GetPool(nPoolID, nRoleLevel)
		local function GetItemWeight(tNode)
			return tNode.nWeight
		end
		local tRandItemList = CWeightRandom:Random(tPool, GetItemWeight, nTimes, false)
		for _, tReward in pairs(tRandItemList) do
			oRole:AddItem(gtItemType.eProp, tReward.nItemID, tReward.nItemNum, "尊师考验额外奖励")
		end
		oHolidayTeachTest:SetTeachTestCompTimes()
	end
end

function CTeachTest:GetSessionList()
	local tSessionList = {}
	for _, oRole in pairs(self.m_tRoleMap) do
		if not oRole:IsRobot() and oRole:IsOnline() then
			table.insert(tSessionList, oRole:GetServer())
			table.insert(tSessionList, oRole:GetSession())
		end
	end
	return tSessionList
end

--同步场景信息
function CTeachTest:SyncDupInfo(oRole)
	local tMsg = {tMonster={nDupMixID=0, nDupID=0, nMonObjID=0, nMonsterPosX=0, nMonsterPosY=0, nMonsterConfID=0}, tDupList={}}
	local nMonsterID = next(self.m_tMonsterMap)
	local oMonster = self.m_tMonsterMap[nMonsterID]
	if oMonster then
		tMsg.tMonster.nMonObjID = oMonster:GetID()
		local oDup = oMonster:GetDupObj()
		tMsg.tMonster.nDupMixID = oDup:GetMixID()
		tMsg.tMonster.nDupID = oDup:GetDupID()
		tMsg.tMonster.nMonsterPosX, tMsg.tMonster.nMonsterPosY = oMonster:GetPos()
		tMsg.tMonster.nMonsterConfID = oMonster:GetConfID()
	end
	for _, oDup in ipairs(self.m_tDupList) do
		table.insert(tMsg.tDupList, {nDupMixID=oDup:GetMixID(), nDupID=oDup:GetDupID()})
	end

	-- if oRole then
	-- 	tMsg.nCompTimes = oRole.m_oDailyActivity:GetRecData(gtDailyID.eZhenYao)[gtDailyData.eCountComp]
	-- 	oRole:SendMsg("BattleDupInfoRet", tMsg)
	-- else
	-- 	for nIndex, oRole in pairs(self.m_tRoleMap) do
	-- 		tMsg.nCompTimes = oRole.m_oDailyActivity:GetRecData(gtDailyID.eZhenYao)[gtDailyData.eCountComp] 
	-- 		oRole:SendMsg("BattleDupInfoRet", tMsg)
	-- 	end
    -- end
    
    if oRole then
        oRole:SendMsg("BattleDupInfoRet", tMsg)
    else
        local tSessionList = self:GetSessionList()
		CmdNet.PBBroadcastExter("BattleDupInfoRet", tSessionList, tMsg)
    end
end

function CTeachTest:OnLeaderActivity(oLuaObj, nInactivityTime)
end

function CTeachTest:CreateMonster(nMonsterID)
	print("CTeackTest:CreateMonsterReq***")

	local oDup = self.m_tDupList[1]
	local tMapConf = oDup:GetMapConf()
	local nPosX = math.random(300, tMapConf.nWidth - 300)	
	local nPosY = math.random(300, tMapConf.nHeight - 300)
	goMonsterMgr:CreateMonster(nMonsterID, oDup:GetMixID(), nPosX, nPosY)
end

function CTeachTest:TouchMonsterReq(oRole, nMonObjID)
	local oMonster = self.m_tMonsterMap[nMonObjID]
	if not oMonster then
		return oRole:Tips("怪物不存在")
	end
	
	oRole:GetTeam(function(nTeamID, tTeam)
		if nTeamID <= 0 then
			return oRole:Tips("请先组队伍")
		end

		-- 检查人数
		-- local tBattleDupConf = self:GetConf()
		-- local nReturnCount = 0
		-- for _, tRole in ipairs(tTeam) do
		--     if not tRole.bLeave then nReturnCount = nReturnCount+1 end
		-- end
		-- if nReturnCount < tBattleDupConf.nTeamMembs then
		--     return oRole:Tips(string.format("队伍归队人数不足%d人", tBattleDupConf.nTeamMembs))
		-- end
		
		--检查人员等级
		local bAllCanJoin = true
		local tConf = ctBattleDupConf[gtBattleDupType.eTeachTest]		
		local nLevelLimit = tConf.nLevelLimit
		local sStr = ""
		for _, tRole in ipairs(tTeam) do 
			local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oRole then
				if oRole.m_nLevel < nLevelLimit then
					sStr = sStr .. oRole.m_sName .. ", "
					bAllCanJoin = false
				end
			end
		end
		if not bAllCanJoin then
			return oRole:Tips(sStr.."等级不足"..nLevelLimit.."级,不能战斗")				
		end

		if tTeam[1].nRoleID ~= oRole:GetID() then
			return oRole:Tips("队长才能攻击")
		end
		local nMonsterID = oMonster:GetConfID()
		local nIndex = ctTeachTestConf[nMonsterID].nIndex
		oRole:PVE(oMonster, {nMonsterID=nMonsterID, nIndex=nIndex})
	end)
end

