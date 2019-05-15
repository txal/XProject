--混沌试炼
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CHunDunShiLian:Ctor(nID, nType)
	print("创建混沌试炼副本", nType)
	self.m_nID = nID					--战斗副本ID
	self.m_nType = nType 					--副本战斗类型
	self.m_tDupList = GF.WeakTable("v") 	--地图列表{地图对象,...}
	self.m_tRoleMap = GF.WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = GF.WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...}
	
	self.m_nMonsterIndex = 1				--目前打到第几个Boss
	self.m_nTotalWeight = 0					--所有商品的总权重
	self.m_tItemList = {}					--战斗结束翻牌奖励物品
	self.m_nFanPaFlag = false				--翻牌标记
	self.m_nMinTimer = 0
	self.m_PinTuRet = {}
	self.m_nOverTime = 0
	self.m_nOpenTime = os.time()
	self.m_nSwitchDupTimer = nil
	self.m_nTeamID = 0
	self.m_nLastTaskID = 0				--记录上一次的关卡ID
	self:Init()
end

function CHunDunShiLian:Init()
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
		oDup:RegTeamChangeCallback(function(oLuaObj) self:TeamChange(oLuaObj) end )
    end
    self:CalAwardWeight()
    self:RegActTimer()
end

--销毁副本
function CHunDunShiLian:OnRelease()
	for _, oDup in pairs(self.m_tDupList) do
		goDupMgr:RemoveDup(oDup:GetMixID())
	end
	goTimerMgr:Clear(self.m_nMinTimer)
	goTimerMgr:Clear(self.m_nOverTime)
	goTimerMgr:Clear(self.m_nSwitchDupTimer)
	self.m_nMinTimer = nil
	self.m_nOverTime = nil
	self.m_nSwitchDupTimer = nil
	self.m_tDupList = {}
	self.m_tRoleMap = {}
	self.m_tMonsterMap = {}
end

function CHunDunShiLian:GetID() return self.m_nID end --战斗副本ID
function CHunDunShiLian:GetType() return self.m_nType end --取副本战斗类型
function CHunDunShiLian:GetConf() return ctBattleDupConf[self:GetType()] end
function CHunDunShiLian:HasRole() return next(self.m_tRoleMap) end --是否有玩家

function CHunDunShiLian:GetItemConf(nID)
	return ctBattleDupConf[nID]
end

function CHunDunShiLian:GetMonsterID()
	local tBattleDupConf = self:GetItemConf(gtDailyID.eHunDunShiLian)
	if not tBattleDupConf then
		return
	end
	local tMonsterCfg = tBattleDupConf.tMonster
	if not tMonsterCfg  then
		return 
	end
	local nMonsterID = tMonsterCfg[self.m_nMonsterIndex - 1][1]
	return nMonsterID
end

function CHunDunShiLian:GetDupClearanceState()
	local tBattleDupConf = self:GetItemConf(gtDailyID.eHunDunShiLian)
	if not tBattleDupConf then
		return
	end
	if not tBattleDupConf.tMonster[self.m_nMonsterIndex] then
		return true
	end
end

--取地图对象
--@nIndex 副本中的第几个地图
function CHunDunShiLian:GetDupObj(nIndex)
	return self.m_tDupList[nIndex]
end


function CHunDunShiLian:TeamChange(oLuaObj)
	--self:LeaveDupCheck(oLuaObj)
end

--取地图ID
--@nIndex 副本中的第几个地图
function CHunDunShiLian:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

--对象进入副本
function CHunDunShiLian:OnObjEnter(oLuaObj, bReconnect)
	print("CHunDunShiLian:OnObjEnter***", bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj
		self:SyncDupInfo()

	--人物
	elseif nObjType == gtObjType.eRole then
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
		oLuaObj:SetBattleDupID(self:GetID())
		self:AutoCreatrMonster(oLuaObj)
		self:SyncDupInfo(oLuaObj)
		self:CheckRoleNum(oLuaObj)
	end
end

--对象进入副本的时候主动创建怪物
function CHunDunShiLian:AutoCreatrMonster(oRole)
	assert(oRole, "参数错误")
	if next(self.m_tMonsterMap) then
		return
	end

	if not oRole:IsLeader() then
		return
	end
	self:CreateMonsterReq(oRole)
end

function CHunDunShiLian:PVELeaveCheck(oRole)
	self:LeaveDupCheck(oRole)
end

--对象离开副本
function CHunDunShiLian:OnObjLeave(oLuaObj, nBattleID)
	print("CHunDunShiLian:OnObjLeave***")
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


--注册活动结束定时器
function CHunDunShiLian:RegActTimer()
	--TODD去活动管理逻辑服取玩法结束时间,及整个活动是不是Gm开启
	local _RegActEndTime = function (bGMOpen, nEndTime)
		local nOverMis = 0
		--TODD不是GM开启的情况下读正常的开启结束时间
		if not bGMOpen then
			nOverMis = CDailyActivity:GetEndStamp(gtDailyID.eHunDunShiLian)
			assert(nOverMis > os.time(), "活动结束时间错误" .. nOverMis)
			nOverMis = nOverMis - os.time()
		else
			assert(nEndTime or nEndTime > os.time(), "活动结束时间错误")
			nOverMis = nEndTime - os.time()
		end
		print("活动结束时间为******************************************" .. nOverMis)
	    self.m_nOverTime  = goTimerMgr:Interval(nOverMis, function() self:ActEnd() end)
	    assert(self.m_nOverTime, "定时器创建错误")
	end

	local bLogic, nTarService = self:RecordActData()
	if bLogic then
		local fnGetISGMOpenActCallBack = function (bGMOpen, nEndTime)
			assert(nEndTime or nEndTime > 1, "结束时间错误")	
			_RegActEndTime(bGMOpen, nEndTime)
		end
		 goRemoteCall:CallWait("PVEActivityISGMOpenActReq",fnGetISGMOpenActCallBack, GF.GetServiceID(), nTarService, 0)
	else
		local bGMOpen, nEndTime = goPVEActivityMgr:GetISGMOpenAct()
		_RegActEndTime(bGMOpen, nEndTime)
	end
end

--活动结束强制销毁副本
function CHunDunShiLian:ActEnd()
	goTimerMgr:Clear(self.m_nOverTime)
	self.m_nOverTime = nil
	--强制结束战斗，然后在销毁副本
	for nRoleID, oRole in pairs(self.m_tRoleMap) do
		local nBattleID = oRole:GetBattleID()
		if nBattleID > 0 then
			local oBattle = goBattleMgr:GetBattle(nBattleID)
			if oBattle then
				oBattle:ForceFinish()
			end
		end
	end
	goBattleDupMgr:DestroyBattleDup(self:GetID())
end


--队长活跃信息事件,30分钟无操作移出
function CHunDunShiLian:OnLeaderActivity(oLuaObj, nInactivityTime)
	print("CHunDunShiLian:OnLeaderActivity***", nInactivityTime)
	if not oLuaObj:IsLeader() then
		return LuaTrace("队长信息错误", debug.traceback())
	end
	if nInactivityTime >= 30*60 then
		oLuaObj:EnterLastCity()
	end
end

--离开队伍则退出副本
function CHunDunShiLian:OnLeaveTeam(oLuaObj)
	print("CHunDunShiLian:OnLeaveTeam***")
	--oLuaObj:EnterLastCity()
	--退出以后重新回到组队大厅
	self:EnterBattleDupReq(oLuaObj)
end


--取队长角色对象
function CHunDunShiLian:GetLeader()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsLeader() then
			return oRole
		end
	end
end

--战斗结束
function CHunDunShiLian:OnBattleEnd(oLuaObj, tBTRes, tExtData)
	print("CHunDunShiLian:OnBattleEnd***")
	local nObjType = oLuaObj:GetObjType() --gtObjType
	if nObjType == gtObjType.eMonster then
		if not tBTRes.bWin then --怪物死亡
			print("怪物死了啊**********")
			self.m_nMinTimer = goTimerMgr:Interval(6, function() self:AutoReceiveReward() end)
			self.m_nFanPaFlag = true
			local tBattleDupConf = self:GetItemConf(gtDailyID.eHunDunShiLian)
			local tMonsterCfg = tBattleDupConf.tMonster
			self.m_nMonsterIndex =  self.m_nMonsterIndex + 1
			if not tMonsterCfg[self.m_nMonsterIndex] then
				self:CompleteCheck()
			end
			local nMonsterID = next(self.m_tMonsterMap)
			if nMonsterID then
				goMonsterMgr:RemoveMonster(nMonsterID)
			end
			self:DupInfoUpdate()
			self:SyncDupInfo()
		end
	elseif nObjType == gtObjType.eRole and tBTRes.bWin then
		local tMsg = {nSec= 0}
		oLuaObj:SendMsg("PVEFlopSendClientRet", tMsg)
		self:BattleDupReward(oLuaObj)
	end
end

--取会话列表
function CHunDunShiLian:GetSessionList()
	local tSessionList = {}
	for _, oRole in pairs(self.m_tRoleMap) do
		if not oRole:IsRobot() and oRole:IsOnline() then
			table.insert(tSessionList, oRole:GetServer())
			table.insert(tSessionList, oRole:GetSession())
		end
	end
	return tSessionList
end

--副本信息改变下发
function CHunDunShiLian:DupInfoUpdate(oRole)
	local tBattleDupConf = self:GetItemConf(202)
	local tMonsterCfg = tBattleDupConf.tMonster
	if not tMonsterCfg then return oRole:Tips("怪物不存在") end
	if not tMonsterCfg[self.m_nMonsterIndex] then
		return 
	end
	local nMonsterID = tMonsterCfg[self.m_nMonsterIndex][1]
	local tMsg = {}
	tMsg.nID = 202
	tMsg.nCheckpoint = self.m_nMonsterIndex
	tMsg.sCheckpointName = ctMonsterConf[nMonsterID].sName or "混沌试炼"
	if oRole then
		oRole:SendMsg("PVEDupInfoUpdateRet", tMsg)
	else
		for _, oRole in pairs(self.m_tRoleMap) do
			oRole:SendMsg("PVEDupInfoUpdateRet", tMsg)
			print("副本变化消息", tMsg)
		end
	end
end

function CHunDunShiLian:IsClearance()
	local tBattleDupConf = self:GetItemConf(gtDailyID.eHunDunShiLian)
	if not tBattleDupConf then
		return 
	end
	local tMonsterCfg = tBattleDupConf.tMonster
	if not tMonsterCfg then return end
	if not tMonsterCfg[self.m_nMonsterIndex] then
		return true
	end
	return false
end

--玩家进入进入指定场景
function CHunDunShiLian:SwitchMapReq(oRole)
	if not oRole:IsLeader() then
		return oRole:Tips("队长才能操作")
	end
	local tBattleDupConf = self:GetItemConf(202)
	if not tBattleDupConf then
		return oRole:Tips("配置不存在")
	end
	if self.m_nMonsterIndex >= 10 then
		return 
	end
	local nDupIndex = self.m_nMonsterIndex
	if self.m_nMonsterIndex > #self.m_tDupList then
		nDupIndex  = self.m_nMonsterIndex - #self.m_tDupList
	end

	local oDup = self.m_tDupList[nDupIndex]
	local tDupCfg = ctDupConf[GF.GetDupID(oDup:GetMixID())]
	if not tDupCfg then return end
	local tMsg = {}
	tMsg.nIndex = self.m_nMonsterIndex
	oRole:SendMsg("PVESwitchMapRet", tMsg)
	oRole:EnterScene(oDup:GetMixID(), tDupCfg.tBorn[1][1], tDupCfg.tBorn[1][2], -1, tDupCfg.nFace)
end

--同步场景信息
function CHunDunShiLian:SyncDupInfo(oRole)
	local tMsg = {tMonster={nDupMixID=0, nDupID=0, nMonObjID=0, nMonsterPosX=0, nMonsterPosY=0}, tDupList={}}
	local nMonsterID = next(self.m_tMonsterMap)
	local oMonster = self.m_tMonsterMap[nMonsterID]
	local nMonsterCount = 0
	for _, oMonster in pairs(self.m_tMonsterMap) do
		nMonsterCount = nMonsterCount + 1
	end
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
	else
		local tSessionList = self:GetSessionList()
		CmdNet.PBBroadcastExter("BattleDupInfoRet", tSessionList, tMsg)
	end
end

--创建怪物
function CHunDunShiLian:CreateMonsterReq(oRole)
	if not oRole:IsLeader() then
		return oRole:Tips("队长才能操作")
	end
	if next(self.m_tMonsterMap) then
		return oRole:Tips("怪物已经出现")
	end

	local tBattleDupConf = self:GetItemConf(gtDailyID.eHunDunShiLian)
	if not tBattleDupConf then
		return oRole:Tips("配置不存在")
	end
	local tMonsterCfg = tBattleDupConf.tMonster
	if not tMonsterCfg then return oRole:Tips("怪物不存在") end
	if not tMonsterCfg[self.m_nMonsterIndex] then
		return oRole:Tips("该副本已经全部通关")
	end

	local nMonsterID = tMonsterCfg[self.m_nMonsterIndex][1]
	if not nMonsterID then return end
	local nDupIndex = self.m_nMonsterIndex
	if self.m_nMonsterIndex > #self.m_tDupList then
		nDupIndex  = self.m_nMonsterIndex - #self.m_tDupList
	end

	local oDup = self.m_tDupList[nDupIndex]
	local tMonster = ctMonsterConf[nMonsterID]
	if not tMonster then
		return
	end
	local nPosX = tMonster.tPos[1][1]
	local nPosY = tMonster.tPos[1][2]
	goMonsterMgr:CreateMonster(nMonsterID, oDup:GetMixID(), nPosX, nPosY)
	oRole:Tips(string.format("怪物物出现在%s！", oDup:GetName()))
end

--攻击怪物
function CHunDunShiLian:AttackMonsterReq(oRole, nMonObjID)
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
		local tDailyDupConf = ctDailyBattleDupConf[gtBattleDupType.eHunDunShiLian]
		assert(tDailyDupConf, "混沌试炼日程配置错误")
		for _, tRole in ipairs(tTeam) do 
			local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oRole then
				if oRole.m_nLevel < tDailyDupConf.nAccpLimit then
					sStr = sStr .. oRole.m_sName .. ", "
					bAllCanJoin = false
				end
			end
		end
		if not bAllCanJoin then
			local sTips = sStr .. "等级不足" .. tDailyDupConf.nAccpLimit.."级"
			return oRole:Tips(sTips)				
		end

		oRole:PVE(oMonster, {nBattleDupType=gtBattleDupType.eHunDunShiLian})
	end)
end

--进入副本请求,可能会切换服务进程
function CHunDunShiLian:EnterBattleDupReq(oRole)
	if not oRole:IsSysOpen(31, true) then
		-- return oRole:Tips("该活动对你还没有开放哦")
		return
	end
	goPVEActivityMgr:EnterReadyDupReq(oRole)
end

function CHunDunShiLian:BattleDupReward(oRole)
	if not oRole then return end
	--判断玩家有没有重复领取
	local bRet = self:RewardCheck(oRole, false)
	if bRet then return end

	--经验奖励
	local fnRoleExp = ctDailyBattleDupConf[gtDailyID.eHunDunShiLian].fnRoleExpReward
	local fnPetExp = ctDailyBattleDupConf[gtDailyID.eHunDunShiLian].fnPetExpReward
	local nRoleLevel = oRole:GetLevel()
	local nRoleExp = fnRoleExp(nRoleLevel)

	--队长加成
	if oRole:IsLeader() then
		nRoleExp = nRoleExp + nRoleExp * (ctDailyBattleDupConf[gtDailyID.eHunDunShiLian].nDuiZhang/100)
	end
	local tPet = oRole.m_oPet:GetCombatPet()
	if tPet then
		local nPetExp = fnPetExp(tPet.nPetLv)
		oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "混沌试炼副本奖励")
	end
	local fSilverNum = ctDailyBattleDupConf[gtDailyID.eHunDunShiLian].fnSilverReward
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "混沌试炼副本奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, fSilverNum(), "混沌试炼副本奖励")

end

function CHunDunShiLian:CalAwardWeight()
	local tRewardPool = ctDailyBattleDupConf[gtDailyID.eHunDunShiLian].tItemAward
	for key, tItemPool in pairs(tRewardPool) do 
		self.m_nTotalWeight = self.m_nTotalWeight + tItemPool[1]
	end
end

function CHunDunShiLian:FIndSavaItemPlayer()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole._oDailyActivity.m_tActDataMap.tItemList then
			return oRole
		end
	end
end

--时间到了自动翻牌
function CHunDunShiLian:AutoReceiveReward()
	goTimerMgr:Clear(self.m_nMinTimer)
	self.m_nFanPaFlag = false
	--找出没有翻牌子的格子
	local tTmp = {} 
	for i = 1, 5, 1 do
		if not self.m_tItemList[i] then
			tTmp[#tTmp+1] = i
		end
	end
	local tRoleList = {}
	local nIndex = 1
	--暂离状态不给与奖励
	for nRoleID, oRole in pairs(self.m_tRoleMap) do
		local fnGetTeamCallBack = function (nTeamID, tTeam)
			--当前没有队伍
			for _, tRole in pairs(tTeam) do
				local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
				if not tRole.bLeave and oRole then
					if self:RewardHandle(oRole, nIndex, tTmp) then
						nIndex = nIndex + 1
					end
				end
			end
			self:SendRewardComplete()
			self.m_tItemList = {}

			--领完奖励自动切换到下一个场景
			local oRole = self:GetLeader()
			if oRole and not self:IsClearance() then
				--self:SwitchMapReq(oRole)
				self.m_nSwitchDupTimer = goTimerMgr:Interval(3, function() self:SwitchMap() end)
				assert(self.m_nSwitchDupTimer, "定时器错误")

			end
		end
		oRole:GetTeam(fnGetTeamCallBack)
		break
	end
end

--防止在定时器之间队长发生交换,从新取一下队长角色
function CHunDunShiLian:SwitchMap()
	goTimerMgr:Clear(self.m_nSwitchDupTimer)
	self.m_nSwitchDupTimer = nil

	local oRole = self:GetLeader()
	if oRole and not self:IsClearance() then
		local nDupIndex = self.m_nMonsterIndex
		if self.m_nMonsterIndex > #self.m_tDupList then
			nDupIndex  = self.m_nMonsterIndex - #self.m_tDupList
		end
		local oDup = self.m_tDupList[nDupIndex]
		if oDup then
			if oDup:GetMixID() == oRole:GetDupMixID() then
				self:CreateMonsterReq(oRole)
			else
				if oRole then
					self:SwitchMapReq(oRole)
				end
			end
		end
	end
end

--奖励处理
function CHunDunShiLian:RewardHandle(oRole, nIndex, tTmp)
	local bRet = self:RewardCheck(oRole, true)
	if not bRet then
		tItem = self:GetRewardItem(oRole)
		if tItem then
			self.m_tItemList[tTmp[nIndex]] = {nGrid = tTmp[nIndex] ,nRoleID = oRole:GetID(), nRoleName = oRole:GetName(),
			ItemID = tItem[1].nItemID, nNum = tItem[1].nItemNum}
			oRole:AddItem(gtItemType.eProp, tItem[1].nItemID, tItem[1].nItemNum, "决战九霄副本奖励")
			local tData = {}
			tData.bIsHearsay = true
			tData.nItemID = tItem[1].nItemID
			CEventHandler:OnCompJueZhanJiuXiao(oRole, tData)

			local tMsg = {tList = {}}
			for nID, tItem in pairs(self.m_tItemList) do
				tMsg.tList[#tMsg.tList+1] = {nGrid = tItem.nGrid, nRoleName = tItem.nRoleName, nID = tItem.ItemID, nNum = tItem.nNum}
			end

			for nID, oRole in pairs(self.m_tRoleMap) do
				oRole:SendMsg("PVEClickRewardRet", tMsg)
			end
			return true
		end
	end	
end

function CHunDunShiLian:FindPlayerInfo(nRoleID)
	for _, tItem in pairs(self.m_tItemList) do
		if nRoleID == tItem.nRoleID then
			return true
		end
	end
end

--玩家点击翻牌
function CHunDunShiLian:ClickFlopReq(oRole, nID)
	local tItemList = {}
	if self.m_tItemList[nID] then
		return  oRole:Tips("该奖励已被玩家领取")
	end
	local bRet = self:RewardCheck(oRole, true)
	if bRet then return oRole:Tips("你今日已经领取了该奖励哦") end
	if not self.m_nFanPaFlag then return end
	local tItem = self:GetRewardItem(oRole)
	if tItem then
		self.m_tItemList[nID] = { nGrid = nID ,nRoleID = oRole:GetID(), nRoleName = oRole:GetName(),ItemID = tItem[1].nItemID, nNum = tItem[1].nItemNum}

		oRole:AddItem(gtItemType.eProp, tItem[1].nItemID, tItem[1].nItemNum, "混沌试炼副本奖励")
		local tData = {}
		tData.bIsHearsay = true
		tData.nItemID = tItem[1].nItemID
		CEventHandler:OnCompHunDunShiLian(oRole, tData)
		local tMsg = {tList = {}}
		for nID, tItem in pairs(self.m_tItemList) do
			tMsg.tList[#tMsg.tList+1] = {nGrid = tItem.nGrid, nRoleName = tItem.nRoleName, nID = tItem.ItemID, nNum = tItem.nNum}
		end

		for nID, oRole in pairs(self.m_tRoleMap) do
			oRole:SendMsg("PVEClickRewardRet", tMsg)
		end
	end

end

--玩家是否领取过该关卡奖励检测
function CHunDunShiLian:RewardCheck(oRole, bBattleReward)
	-- --玩家已经领取该关卡的奖励,不能再次发放奖励
	local tActData = oRole:GetPVEActData(gtDailyID.eHunDunShiLian)
	local nLastMonsterID =  self:GetMonsterID()
	if not nLastMonsterID then return end
	if not tActData then
		if bBattleReward then
			oRole:SetPVEActData(gtDailyID.eHunDunShiLian, nLastMonsterID)
		end
	elseif not os.IsSameDay(os.time(), tActData.nResetTime, 0) then
		--检查时间重置
		if bBattleReward then
			oRole:ResetPVEData()
			oRole:SetPVEActData(gtDailyID.eHunDunShiLian, nLastMonsterID)
		end
	else
		if tActData[nLastMonsterID] then
			return true
		end
		if bBattleReward then
			oRole:SetPVEActData(gtDailyID.eHunDunShiLian, nLastMonsterID)
		end
	end
end

--TODD,检查玩家当当天有没有全部通关奖励
function CHunDunShiLian:CheckRewardComplete(oRole)
	tActData = oRole:GetPVEActData(gtDailyID.eHunDunShiLian)
	if not tActData then
		return false
	end

	 if not os.IsSameDay(os.time(), tActData.nResetTime, 0) then
	 	return false
	end
	local tBattleDupConf = ctBattleDupConf[gtDailyID.eHunDunShiLian].tMonster
	for _, tMonster in pairs(tBattleDupConf) do
		if not tActData[tMonster[1]] then
			return false
		end
	end
	--TODD
	oRole:SendMsg("PVERewardCompleteRet", {})
end


function CHunDunShiLian:SendRewardComplete()
	for _, oRole in pairs(self.m_tRoleMap) do
		self:CheckRewardComplete(oRole)
	end
end

function CHunDunShiLian:FindItemInfo(nID)
	for i = 1, #self.m_tItemList, 1 do
		if tItemList[i].nID == nID then
			return tItemList[i]
		end
	end
end

--策划要求前八关使用副本自身的奖励库,九关使用神兽乐园奖励库
function CHunDunShiLian:GetRewardItem(oRole)
	local nRandPool = math.random(1, self.m_nTotalWeight)
	local tRewardPool
	if self.m_nMonsterIndex -1 == 9 then
		tRewardPool = ctDailyBattleDupConf[gtDailyID.eShenShouLeYuan].tItemAward
		print("混沌试炼使用神兽乐园奖励库***************")
	else
		tRewardPool = ctDailyBattleDupConf[gtDailyID.eHunDunShiLian].tItemAward
	end
	local nRewardPoolID

	--根据权重找到是那个物品池
	for key, tItemPool in ipairs(tRewardPool) do
		if nRandPool <= tItemPool[1] then
			nRewardPoolID = tItemPool[2]
			break
		else
			nRandPool = nRandPool - tItemPool[1]
		end
	end

	if not nRewardPoolID then
		return 
	end

    local function fnGetWeight (tNode) return tNode.nWeight end
    local nRewardCount = 1
	local tItemList = ctAwardPoolConf.GetPool(nRewardPoolID, oRole:GetLevel(), oRole:GetConfID())
	local tReward = CWeightRandom:Random(tItemList, fnGetWeight, nRewardCount, false)
	--根据权重拿到物品
	return tReward
end

--点击怪物
function CHunDunShiLian:TouchMonsterReq(oRole, nMonObjID)
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
			--return oRole:Tips(string.format("归队人数不足%d人", tBattleDupConf.nTeamMembs))
			local sCont = "人数不够，是否便捷组队？"
			local tOption = {"取消", "确定"}
			local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10}
			goClientCall:CallWait("ConfirmRet", function(tData)
				if tData.nSelIdx == 2 then
					oRole:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
					return
				end
			end, oRole, tMsg)
		else

			--检查人员等级
			local bAllCanJoin = true
			local sStr = ""
			for _, tRole in ipairs(tTeam) do 
				local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
				if oRole then
					if oRole.m_nLevel < ctDailyBattleDupConf[gtBattleDupType.eHunDunShiLian].nAccpLimit then
						sStr = sStr .. oRole.m_sName .. ", "
						bAllCanJoin = false
					end
				end
			end
			if not bAllCanJoin then
				local sTips = sStr .. "等级不足30级"
				return oRole:Tips(sTips)				
			end
			oRole:PVE(oMonster, {nBattleDupType=gtBattleDupType.eHunDunShiLian})
		end
	end)
end

--记录进入玩家
function CHunDunShiLian:CheckRoleNum(oRole)

	self.m_nTeamID = oRole:GetTeamID()
    local tRoleActData = {}
	tRoleActData.nRoleID = oRole:GetID()
	tRoleActData.nServerID = oRole:GetServer()
	tRoleActData.nLevel = oRole:GetLevel()
	tRoleActData.bLeave = false
    local bRet, nTarService= self:RecordActData()
    if bRet then
         goRemoteCall:Call("PVESetSettlementActDataReq", oRole:GetServer(), 
            nTarService, 0, oRole:GetID(), self.m_nTeamID,  tRoleActData)
    else
        goPVEActivityMgr:SettlementActData(self.m_nTeamID,  tRoleActData)
    end
end

--离开副本检查
function CHunDunShiLian:LeaveDupCheck(oRole)
    local bRet,nTarService = self:RecordActData()
    local tRoleData = {}
    tRoleData.nRoleID = oRole:GetID()
    tRoleData.bLeave = true
    if bRet then
          goRemoteCall:Call("PVEDataChangeReq", oRole:GetServer(), 
                nTarService, 0,  oRole:GetID(), self.m_nTeamID, tRoleData)
    else
        goPVEActivityMgr:PVEDataChange(self.m_nTeamID, tRoleData)
    end
end

--副本全部通关检查
function CHunDunShiLian:CompleteCheck()
	local nCurrTime = os.time()
	local nCompleteTime = nCurrTime - self.m_nOpenTime
    local tRoleData = {tActData = {}}
	for _, oRole in pairs(self.m_tRoleMap) do
		local tRoleActData = {}
		tRoleActData.nServerID = oRole:GetServer()
		tRoleActData.nRoleID = oRole:GetID()
		tRoleActData.nLevel = oRole:GetLevel()
        table.insert(tRoleData.tActData,tRoleActData)
		local nHour, nMin, nSec = os.SplitTime(nCompleteTime)
		oRole:Tips("您本次副本完成时间是" .. nMin .. "分钟" ..nSec .."秒")
	end
    tRoleData.nCompleteTime = nCompleteTime
    local bRet, nTarService = self:RecordActData()
    if bRet then
        goRemoteCall:Call("PVEDataCheckReq",tRoleData.tActData[1].nServerID, 
                    nTarService, 0,  tRoleData.tActData[1].nRoleID, self.m_nTeamID, nCompleteTime)
    else
        goPVEActivityMgr:PVEDataCheckReq(self.m_nTeamID, nCompleteTime)
    end
	print("混沌试炼完成数据", tRoleData)
end

function CHunDunShiLian:RecordActData()
    local nMapID = self.m_nCurrSceneID
	local nCurService = GF.GetServiceID()

	local nTarService = goPVEActivityMgr:GetReadySceneServiceID(10400)
	if nCurService ~= nTarService then
        return true, nTarService
	else
        return false, nTarService
	end
end