--妖兽突袭
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
function CYaoShouTuXi:Ctor(oRole)
    self.m_oRole = oRole     
    self.m_nCompTimes = 0       		--已完成次数
    self.m_nLastResetTimeStamp = 0      --上次重置时间戳
    self.m_nCurYaoShouID = 0			--当前妖兽ID
   -- self.m_nStars = 0 					--当前妖兽星级
   self.m_bTaskState = false				--记录活动状态()
end

function CYaoShouTuXi:LoadData(tData)
    if tData then
	    self.m_nCompTimes = tData.m_nCompTimes or 0
	    self.m_nLastResetTimeStamp = tData.m_nLastResetTimeStamp or os.time()
	    self.m_bTaskState = tData.m_bTaskState
    end
end

function CYaoShouTuXi:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
    tData.m_nCompTimes = self.m_nCompTimes 
    tData.m_nLastResetTimeStamp = self.m_nLastResetTimeStamp
    tData.m_bTaskState = self.m_bTaskState
    return tData
end

function CYaoShouTuXi:IsSysOpen(bTips)
	return self.m_oRole.m_oSysOpen:IsSysOpen(47, bTips)
end

function CYaoShouTuXi:GetType()
	return gtModuleDef.tYaoShouTuXi.nID, gtModuleDef.tYaoShouTuXi.sName
end

--玩家上线检查任务信息
function CYaoShouTuXi:Online()
	if self:IsSysOpen() then
		local tTask = ctDailyActivity[gtDailyID.eYaoShouTuXi]
		if self.m_oRole:GetLevel() >= tTask.nLevelLimit then
			if not os.IsSameDay(self.m_nLastResetTimeStamp, os.time(), 0) then
		        self.m_nCompTimes = 0
		        self.m_nLastResetTimeStamp = os.time()
		        self:MarkDirty(true)
		    end
		    self:JoinYaoShouTuXi()
		end
	end
 end

 
--获取完成次数
function CYaoShouTuXi:GetCompTimes()
	return self.m_nCompTimes
end

--添加挑战次数
function CYaoShouTuXi:AddCompTimes(nTimes)
	self.m_nCompTimes = self.m_nCompTimes + nTimes
	self:MarkDirty(true)
end

--设置当前妖兽ID
function CYaoShouTuXi:SetYaoShouID(nYaoShouID)
	self.m_nCurYaoShouID = nYaoShouID
	self:MarkDirty(true)
end

function CYaoShouTuXi:SetYaoShouStar(nStar)
	self.m_nStars = nStar
end

function CYaoShouTuXi:GetYaoShouStar()
	return self.m_nStars
end

--获取当前攻击的妖兽ID
function CYaoShouTuXi:GetCurYaoShouID()
	return self.m_nCurYaoShouID
end

function CYaoShouTuXi:CheckTaskRepeat(tRetRand, nID)
	for _, tTask in ipairs(tRetRand) do
		if tTask.nTaskID == nID then
			return true
		end
	end
end

function CYaoShouTuXi:OnRoleLevelChange(nNewLevel)

end

function CYaoShouTuXi:OnBattleEnd(bIsWin)
	print("妖兽突袭战斗结束------")
    if bIsWin then
    	local nStars = ctYaoShouTuXi[self.m_nCurYaoShouID].nStar
    	local nYinBi = ctYaoShouTuXi[self.m_nCurYaoShouID].fnSilverReward(nStars)
    	local nRoleExp = ctYaoShouTuXi[self.m_nCurYaoShouID].fnRoleExpReward(self.m_oRole:GetLevel(), nStars)
    	local tPet = self.m_oRole.m_oPet:GetCombatPet()
    	if tPet then
    		local nPetExp = ctYaoShouTuXi[self.m_nCurYaoShouID].fnPetExpReward(tPet.nPetLv, nStars)
    		self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "妖兽突袭获得")
    	end
    	self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp,nRoleExp,"妖兽突袭获得")
    	self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi,nYinBi,"妖兽突袭获得")

    	local nSpecialItem =  ctYaoShouTuXi[self.m_nCurYaoShouID].nSpecialItem
    	local nRet = math.random(1,100)
    	local tItem
    	if nSpecialItem >= nRet then
    		tItem = self:GetRewardItem()
    		if tItem then
    			self.m_oRole:AddItem(gtItemType.eProp,tItem[1].nItemID ,  tItem[1].nItemNum, "妖兽突袭获得")
    		end
    	end
    	self.m_oRole.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eYaoShouTuXi, "妖兽突袭")
    	local tActData = self.m_oRole.m_oDailyActivity:GetRecData(gtDailyID.eYaoShouTuXi)
    	local nTimes = tActData[gtDailyData.eCountComp]
    	local tMsg = {}
    	tMsg.nNewTimes = nTimes or 0
    	self.m_oRole:PushAchieve("妖兽来袭次数",{nValue = 1})
    	self.m_oRole:SendMsg("yaoshoutuxiTaskTimesRet", tMsg)
		self:AddCompTimes(1)
		
		local tData = {}
		tData.bIsHearsay = true
		tData.nStar = nStars
		CEventHandler:OnCompYaoShouTuXi(self.m_oRole, tData)
    end
    self:MarkDirty(true)
    self:SetYaoShouID(0)
end

--玩家攻击怪物(策划改需求,副本)
function CYaoShouTuXi:yaoshouAttacReq(nYaoShouID, nStars)
	-- if self.m_oRole:GetLevel() < 40  then
	-- 	return self.m_oRole:Tips("玩家等级低于40级,不能攻击怪物")
	-- end

	-- if self:GetCompTimes() > 3 then
	-- 	return self.m_oRole:Tips("今天已击杀三只妖兽,则不能参加战斗")
	-- end
	-- local tYaoShou = self:GetYaoShou(nYaoShouID)
	-- if not tYaoShou then return end
	-- -- local nServerID = self.m_oRole:GetServer()
	-- -- local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)

	-- local fnGetYaoShouBattleStatus = function (bBattle)
	-- 	if bBattle then return self.m_oRole:Tips("目标处于战斗状态,不能攻击怪物") end
	-- 	local nMonsterID = self:GetMonsterID(tYaoShou,nStars)
	-- 	if not nMonsterID then return LuaTrace("怪物ID错误", nMonsterID) end
	--     local oMonster = goMonsterMgr:CreateInvisibleMonster(nMonsterID)
	--     self:SetYaoShouID(nYaoShouID)
	--     self:SetYaoShouStar(nStars)
	--     self.m_oRole:PVE(oMonster, {bYaoShouTuXiTask = true})
	--     Network:RMCall("SetYaoShouBattleStatusReq", nil, nServerID, nGlobalLogic, 0, self.m_oRole:GetID(),nYaoShouID, true)
	-- end
	-- Network:RMCall("GetYaoShouBattleStatus", fnGetYaoShouBattleStatus,nServerID, nGlobalLogic, 0, self.m_oRole:GetID(),nYaoShouID)
end

function CYaoShouTuXi:yaoshouAttacReq(nYaoShouID)
	if not self:IsSysOpen(true) then
		-- return self.m_oRole:Tips("妖兽突袭系统尚未开启")
		return
	end
	local nOpenLimit = ctDailyActivity[gtDailyID.eYaoShouTuXi].nOpenLimit
	if self.m_oRole:GetLevel() < nOpenLimit then
		return self.m_oRole:Tips("玩家等级低于 " ..nOpenLimit .."级,不能攻击怪物")
	end

	local tActData = self.m_oRole.m_oDailyActivity:GetRecData(gtDailyID.eYaoShouTuXi)
	if tActData then
		 local nTimes = tActData[gtDailyData.eCountComp]
		 if ctDailyActivity[gtDailyID.eYaoShouTuXi] and nTimes >= ctDailyActivity[gtDailyID.eYaoShouTuXi].nTimesReward
		 	and not ctDailyActivity[gtDailyID.eYaoShouTuXi].bCanJoinContinues then
		 	return self.m_oRole:Tips(string.format("今天已击杀%d只妖兽,则不能参加战斗", nTimes))
		 end
	end
	local tYaoShou = self:GetYaoShou(nYaoShouID)
	if not tYaoShou then return end
	if bBattle then return self.m_oRole:Tips("目标处于战斗状态,不能攻击怪物") end
	local nMonsterID = tYaoShou.nMonster
	if not nMonsterID then return LuaTrace("怪物ID错误", nMonsterID) end
	if self.m_oRole:GetDupID() ~= ctNpcConf[nYaoShouID].nDupID then
		return self.m_oRole:Tips("当前地图不能攻击妖兽哦")
	end
    local oMonster = goMonsterMgr:CreateInvisibleMonster(nMonsterID)
    self:SetYaoShouID(nYaoShouID)
    self.m_oRole:PVE(oMonster, {bYaoShouTuXiTask = true})
end


--远程通知刷新当前死掉的怪物刷新
function CYaoShouTuXi:UpdateMonster()
	print("怪物更新-----")
	local fnBroadcastYaoShouCallBack = function (nDupID, tYaoShouInfo)
		if not nDupID or not tYaoShouInfo then return end
		local oDup = goDupMgr:GetDup(nDupID)
		if oDup then
			local tMsg ={}
			tMsg.tDupListInfo = tYaoShouInfo
			print("妖兽广播消息", tMsg)
			oDup:BroadcastScene(-1, "yaoshoutuxiInitInfoRet", tMsg)
		end
	end
	local nServerID = self.m_oRole:GetServer()
	local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)
	Network:RMCall("UpdateMonsterReq", fnBroadcastYaoShouCallBack, nServerID, nGlobalLogic, 0, self.m_oRole:GetID(),self.m_nCurYaoShouID)
	self.m_nCurYaoShouID = 0
	self:MarkDirty(true)
end

function CYaoShouTuXi:GetRewardItem()
	local nRewardPoolID = ctYaoShouTuXi[self.m_nCurYaoShouID].nItemAward
	print("奖池ID-------", nRewardPoolID)
	if not nRewardPoolID then return end
    local function fnGetWeight (tNode) return tNode.nWeight end
    local nRewardCount = 1
	local tItemList = ctAwardPoolConf.GetPool(nRewardPoolID, self.m_oRole:GetLevel(), self.m_oRole:GetConfID())
	local tReward = CWeightRandom:Random(tItemList, fnGetWeight, nRewardCount, false)
	return tReward
end

function CYaoShouTuXi:GetConf()
	local tYaoShouConf = ctYaoShouTuXi[self.m_nCurYaoShouID]
	if tYaoShouConf then
		for _, tConf in pairs(tYaoShouConf.tItemAward) do
			if tConf[1] == self.m_nStars then
				return tConf[2]
			end
		end
	end
end
function CYaoShouTuXi:GetYaoShou(nYaoShouID)
	if not nYaoShouID then return end
	return ctYaoShouTuXi[nYaoShouID]
end
function CYaoShouTuXi:GetRewardType()
	for _, tConf in pairs(ctYaoShouTuXi) do
		return tConf.nType
	end
end

--参加妖兽返回妖兽所有信息
function CYaoShouTuXi:JoinYaoShouTuXi()
	self.m_bTaskState = true
	local nServerID = self.m_oRole:GetServer()
	local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)
	local fnGetYaoShouCallBack = function (tYaoShou)
		if tYaoShou then
			local tMsg = {}
			local bFlag = true
			if self.m_nCompTimes >= ctDailyActivity[gtDailyID.eYaoShouTuXi].nTimesReward then
				bFlag = false
			end
			tMsg.nTimes = self.m_nCompTimes
			tMsg.tDupListInfo = tYaoShou
			tMsg.bFlag = bFlag
			tMsg.bState = self.m_bTaskState
			tMsg.nType = 1
			print("YaoShouTuXiMsg", tMsg)
			self.m_oRole:SendMsg("yaoshoutuxiInitInfoRet", tMsg)
		end
	end
	Network:RMCall("GetYaoShouInfoReq", fnGetYaoShouCallBack, nServerID, nGlobalLogic, 0, self.m_oRole:GetID())
end

function CYaoShouTuXi:YaoShouTuXiSend()
	
end