--梦诛无双
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMengZhuWuShuang:Ctor(nID, nType)
	print("创建梦诛无双副本", nID)
	self.m_nID = nID 						--战斗副本ID
	self.m_nType = nType 					--副本战斗类型
	self.m_tDupList = GF.WeakTable("v") 	--地图列表{地图对象,...}
	self.m_tRoleMap = GF.WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = GF.WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...}
	self.m_nMonsterConfID = 0				--被杀死的怪物的配置ID（用于发奖励）

	self.m_nRoundNum = 0					--回合数,最高30回合
	self.m_nMonsterUpadateNum = 0			--怪物刷新波数,最高99波
	self.m_nMaxMonsterUpdateNum = 0 		--最高的挑战次数
	self:Init()
end

function CMengZhuWuShuang:Init()
  local tConf = ctBattleDupConf[self.m_nType]
	for _, tDup in ipairs(tConf.tDupList) do
		local oDup = goDupMgr:CreateDup(tDup[1])
	    oDup:SetAutoCollected(false) --设置非自动收集
		table.insert(self.m_tDupList, oDup)
	end

	for _, oDup in pairs(self.m_tDupList) do
		oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
		oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
		oDup:RegLeaderActivityCallback(function(oLuaObj, nInactivityTime) self:OnLeaderActivity(oLuaObj, nInactivityTime) end)
		oDup:RegLeaveTeamCallback(function(oLuaObj) self:OnLeaveTeam(oLuaObj) end )
		oDup:RegBattleEndCallback(function(...) self:OnBattleEnd(...) end )
    end
    --初始化一个怪物
    self:CreateMonster()
end

--销毁副本
function CMengZhuWuShuang:OnRelease()
	print("梦诛无双副本被销毁", self.m_nID)
	for _, oDup in pairs(self.m_tDupList) do
		goDupMgr:RemoveDup(oDup:GetMixID())
	end
	self.m_tDupList = {}
	self.m_tRoleMap = {}
	self.m_tMonsterMap = {}
end

function CMengZhuWuShuang:GetID() return self.m_nID end --战斗副本ID
function CMengZhuWuShuang:GetType() return self.m_nType end --取副本战斗类型
function CMengZhuWuShuang:GetConf() return ctBattleDupConf[self:GetType()] end
function CMengZhuWuShuang:HasRole() return next(self.m_tRoleMap) end --是否有玩家

--取地图对象
--@nIndex 副本中的第几个地图
function CMengZhuWuShuang:GetDupObj(nIndex)
	return self.m_tDupList[nIndex]
end


--取地图ID
--@nIndex 副本中的第几个地图
function CMengZhuWuShuang:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

--对象进入副本
function CMengZhuWuShuang:OnObjEnter(oLuaObj, bReconnect)
	print("CMengZhuWuShuang:OnObjEnter***", bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
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

--对象离开副本
function CMengZhuWuShuang:OnObjLeave(oLuaObj, nBattleID)
	print("CMengZhuWuShuang:OnObjLeave***")
	 local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
	    self.m_tMonsterMap[oLuaObj:GetID()] = nil

	--人物
	elseif nObjType == gtObjType.eRole then
	    if nBattleID > 0 then --如果是战斗离开副本,不用处理
	    else
	        oLuaObj:SetBattleDupID(0)
	        self.m_tRoleMap[oLuaObj:GetID()] = nil
	        --所有玩家离开就销毁副本
	        -- if not next(self.m_tRoleMap) then
	        --     goBattleDupMgr:DestroyBattleDup(self:GetID())
	        -- end
	    end

    end
end

--队长活跃信息事件,30分钟无操作移出
function CMengZhuWuShuang:OnLeaderActivity(oLuaObj, nInactivityTime)
	print("CLuanShiYaoMo:OnLeaderActivity***", nInactivityTime)
	if not oLuaObj:IsLeader() then
		return LuaTrace("队长信息错误", debug.traceback())
	end
	if nInactivityTime >= 30*60 then
		oLuaObj:EnterLastCity()
	end
end


--离开队伍则退出副本
function CMengZhuWuShuang:OnLeaveTeam(oLuaObj)
	print("CMengZhuWuShuang:OnLeaveTeam***")
	oLuaObj:EnterLastCity()
end


--取队长角色对象
function CMengZhuWuShuang:GetLeader()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsLeader() then
			return oRole
		end
	end
end

--战斗结束
function CMengZhuWuShuang:OnBattleEnd(oLuaObj, tBTRes, tExtData)
	print("CMengZhuWuShuang:OnBattleEnd***")
	local nObjType = oLuaObj:GetObjType() --gtObjType
	if nObjType == gtObjType.eMonster then
		if not tBTRes.bWin then --怪物死亡
			self:BattleDupReward()
		end
	elseif nObjType == gtObjType.eRole and tBTRes.bWin then
		self:BattleDupReward(oLuaObj)
	end
end

--取会话列表
function CMengZhuWuShuang:GetSessionList()
	local tSessionList = {}
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsOnline() then
			table.insert(tSessionList, oRole:GetServer())
			table.insert(tSessionList, oRole:GetSession())
		end
	end
	return tSessionList
end

--同步场景信息
function CMengZhuWuShuang:SyncDupInfo(oRole)
	local tMsg = {tMonster={nDupMixID=0, nDupID=0, nMonObjID=0, nMonsterPosX=0, nMonsterPosY=0}, tDupList={}}
	local nMonsterID = next(self.m_tMonsterMap)
	local oMonster = self.m_tMonsterMap[nMonsterID]
	if oMonster then
		tMsg.tMonster.nMonObjID = oMonster:GetID()
		local oDup = oMonster:GetDupObj()
		tMsg.tMonster.nDupMixID = oDup:GetMixID()
		tMsg.tMonster.nDupID = oDup:GetDupID()
		tMsg.tMonster.nMonsterPosX, tMsg.tMonster.nMonsterPosY = oMonster:GetPos()
	end
	for _, oDup in ipairs(self.m_tDupList) do
		table.insert(tMsg.tDupList, {nDupMixID=oDup:GetMixID(), nDupID=oDup:GetDupID()})
	end
	if oRole then
		oRole:SendMsg("BattleDupInfoRet", tMsg)
		print(">>>>>>>>>>>>>>>>>>>>人物进入梦诛无双", tMsg)
	else
		local tSessionList = self:GetSessionList()
		CmdNet.PBBroadcastExter("BattleDupInfoRet", tSessionList, tMsg)
	end
end

--创建怪物
function CMengZhuWuShuang:CreateMonsterReq(oRole)
	print("CZhenYao:CreateMonsterReq***")
	
	if not oRole:IsLeader() then
		return oRole:Tips("队长才能操作")
	end
	if next(self.m_tMonsterMap) then
		return oRole:Tips("怪物已经出现")
	end

	local tBattleDupConf 
	if self.m_nMonsterIndex == 1 then
		tBattleDupConf = self:GetItemConf()
		self.m_nMonsterIndex  = tBattleDupConf.nTaskId
	end

	if self.m_nMonsterIndex == 0 then
		return oRole:Tips("该副本已经全部通关")
	end
	if not tBattleDupConf then
		return 
	end
	local oDup = self.m_tDupList[1]
	self.m_nMonsterIndex = self.m_nMonsterIndex + 1
	local tMapConf = oDup:GetMapConf()
	local nPosX = math.random(0, tMapConf.nWidth)	
	local nPosY = math.random(0, tMapConf.nHeight)
	goMonsterMgr:CreateMonster(nMonConfID, oDup:GetMixID(), nPosX, nPosY)
	oRole:Tips(string.format("怪物物出现在%s！", oDup:GetName()))
end

--攻击怪物
function CMengZhuWuShuang:AttackMonsterReq(oRole, nMonObjID)
	local oMonster = self.m_tMonsterMap[nMonObjID]
	if not oMonster then
		return oRole:Tips("怪物不存在")
	end

	oRole:GetTeam(function(nTeamID, tTeam)
		if nTeamID <= 0 then
			return oRole:Tips("请先组队伍")
		end
		if tTeam[1].nRoleID ~= oRole:GetID() then
			return oRole:Tips("队长才能攻击")
		end

		local tBattleDupConf = self:GetConf()
		local nReturnCount = 0
		for _, tRole in pairs(tTeam) do
			if not tRole.bLeave then nReturnCount = nReturnCount+1 end
		end
		if nReturnCount < tBattleDupConf.nTeamMembs then
			return oRole:Tips(string.format("归队人数不足%d人", tBattleDupConf.nTeamMembs))
		end

		--检查人员等级
		local bAllCanJoin = true
		local sStr = ""
		for _, tRole in ipairs(tTeam) do 
			local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oRole then
				if oRole.m_nLevel < ctDailyBattleDupConf[gtBattleDupType.eMengZhuWuShuang].nAccpLimit then
					sStr = sStr .. oRole.m_sName .. ", "
					bAllCanJoin = false
				end
			end
		end
		if not bAllCanJoin then
			local sTips = sStr .. "等级不足30级"
			return oRole:Tips(sTips)				
		end

		oRole:PVE(oMonster, {nBattleDupType=gtBattleDupType.eMengZhuWuShuang})
	end)
end

--进入准备大厅
function CMengZhuWuShuang:EnterBattleDupReq(oRole)
	local sCont = "面对无穷无尽的妖魔怪兽，需要有进无退的决心！优秀的后辈们，你们能坚持到第几波？"
	local tOption = {"我要参加梦诛无双 ", "我还要准备一下"}
	local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
	local fnEnterBattleDupCallBack = function (tData)
		--我要参加梦诛无双
		if tData.nSelIdx == 1 then
			if oRole:GetLevel() < 30 then
				return oRole:Tips("您的等级不够30级，请升到30级再来吧")
			end
			goPVEActivityMgr:EnterReadyDupReq(oRole)
		end
	end
	goClientCall:CallWait("ConfirmRet", fnEnterBattleDupCallBack, oRole, tMsg)
end


function CMengZhuWuShuang:BattleDupReward(oRole)
	if not oRole then return end
	--经验奖励
	local fnRoleExp = ctDailyBattleDupConf[gtDailyID.eMengZhuWuShuang].fnRoleExpReward
	local fnPetExp = ctDailyBattleDupConf[gtDailyID.eMengZhuWuShuang].fnPetExpReward
	local nRoleLevel = oRole:GetLevel()
	local nRoleExp = fnRoleExp(nRoleLevel)
	local tPet = oRole.m_oPet:GetCombatPet()
	if tPet then
		local nPetExp = fnPetExp(tPet.nPetLv)
		oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "决战九霄副本奖励")
	end
	
	local nSilverNum = ctDailyBattleDupConf[gtDailyID.eMengZhuWuShuang].fnSilverReward
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "决战九霄副本奖励")

	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nSilverNum(), "决战九霄副本奖励")


	self.m_tItemList = self:GetRewardItem()
	local tMsg = {tList={}}
	for _, tItem in ipairs(self.m_tItemList) do
		tMsg.tList[#tMsg.tList+1] = {nID = tItem.nItemID, nNum = tItem.nItemNum}
	end

	for _, oRole in pairs(self.m_tRoleMap) do
		oRole:SendMsg("PVERewardSendClientRet", tMsg)
	end
end

--点击怪物
function CMengZhuWuShuang:TouchMonsterReq(oRole, nMonObjID)
	local oMonster = self.m_tMonsterMap[nMonObjID]
	if not oMonster then
		return oRole:Tips("怪物不存在")
    end
    
    local sCont = "破坏……混乱……鲜血……哈哈哈，我们最爱的乱世！"
    local tOption = {"进入战斗", "暂时撤退"}
    local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}

    goClientCall:CallWait("ConfirmRet", function(tData)
        if tData.nSelIdx == 1 then	--进入战斗
            oRole:GetTeam(function(nTeamID, tTeam)
	            if nTeamID <= 0 then
	                return oRole:Tips("请先组队伍")
				end
				
				--检查人员等级
				local bAllCanJoin = true
				local sStr = ""
				for _, tRole in pairs(tTeam) do 
					local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
					if oRole.m_nLevel < ctDailyBattleDupConf[gtBattleDupType.eMengZhuWuShuang].nAccpLimit then
						sStr = sStr .. tRole.m_sName .. ", "
						bAllCanJoin = false
					end
				end
				if not bAllCanJoin then
					local sTips = sStr .. "等级不足30级"
					return oRole:Tipes(sTips)				
				end

				--检查人数
				local tBattleDupConf = self:GetConf()
	            local nReturnCount = 0
	            for _, tRole in ipairs(tTeam) do
	                if not tRole.bLeave then nReturnCount = nReturnCount+1 end
	            end
	            if nReturnCount < tBattleDupConf.nTeamMembs then
	                return oRole:Tips(string.format("队伍归队人数不足%d人", tBattleDupConf.nTeamMembs))
	            end

	            if tTeam[1].nRoleID ~= oRole:GetID() then
	                return oRole:Tips("队长才能攻击")
	            end
				oRole:PVE(oMonster, {nBattleDupType=gtBattleDupType.eMengZhuWuShuang})
			end)
		else
			return	--暂时退避
		end 
	end, oRole, tMsg)
end