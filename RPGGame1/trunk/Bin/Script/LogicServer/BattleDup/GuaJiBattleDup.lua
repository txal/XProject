--挂机副本
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--角色一直在场景，并且选择了自动挑战boss 要自动切入boss
--由于小怪没有战斗，根据挂机模块所给奖励次数判断是否能挑战boss
function CGuaJiBattleDup:Ctor(nID, nType)
	self.m_nID = nID
    self.m_nType = nType
    self.m_tDupList = CUtil:WeakTable("v")
    self.m_tRoleMap = CUtil:WeakTable("v")
	self.m_tMonsterMap = CUtil:WeakTable("v")
	self.m_nBattleSecTimer = 0              --自动战斗定时器(角色在副本中才调用启用)
	self.m_bIsInBattle = false              --当前是否在战斗中
	self.m_tExecEvent = {}                  --后续执行事件映射

	self:Init()
end

function CGuaJiBattleDup:Init()
	local tConf = ctBattleDupConf[self.m_nType]
    for _, tDup in ipairs(tConf.tDupList) do
        local oDup = goDupMgr:CreateDup(tDup[1])
        oDup:SetAutoCollected(false)
        oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
        oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
		oDup:RegBattleEndCallback(function(...) self:OnBattleEnd(...) end )
		oDup:RegObjAfterEnterCallback(function(oLuaObj) self:ObjAfterEnter(oLuaObj) end)
        table.insert(self.m_tDupList, oDup)
	end
	self:RegisterExecEvent()
end

function CGuaJiBattleDup:Release()
	for _, oDup in pairs(self.m_tDupList) do
        goDupMgr:RemoveDup(oDup:GetMixID())
    end
    self.m_tDupList = {}
    self.m_tRoleMap = {}
	self.m_tMonsterMap = {}
	
	GetGModule("TimerMgr"):Clear(self.m_nBattleSecTimer)
	self.m_nBattleSecTimer = nil
end

--设置自动战斗(如果在副本中，通知播放动画)
function CGuaJiBattleDup:RegAutoBattle(oRole)
	if not oRole then
		return
	end
	GetGModule("TimerMgr"):Clear(self.m_nBattleSecTimer)
	local nGuanQia, nBattleTimes = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
	local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
    self.m_nBattleSecTimer = GetGModule("TimerMgr"):Interval(tGuanQiaConf.nPatrolSec, function() self:NoticeBattleStart() end)
end

function CGuaJiBattleDup:StopAutoBattle()
    GetGModule("TimerMgr"):Clear(self.m_nBattleSecTimer)
	self.m_nBattleSecTimer = nil
	--self.m_bIsInBattle = false		--不在战斗中，要客户端播完动画通知
end

function CGuaJiBattleDup:GetID() return self.m_nID end
function CGuaJiBattleDup:GetType() return self.m_nType end
function CGuaJiBattleDup:GetConf() return ctBattleDupConf[self:GetType()] end
function CGuaJiBattleDup:HasRole() return next(self.m_tRoleMap) end

function CGuaJiBattleDup:GetDupMixID(nIndex)
    local oDup = self.m_tDupList[nIndex]
    return oDup:GetMixID()
end

function CGuaJiBattleDup:OnObjEnter(oLuaObj, bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
		--人物
	if nObjType == gtGDef.tObjType.eRole then
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
        oLuaObj:SetBattleDupID(self:GetID())
		self:SyncDupInfo(oLuaObj)
		local nGuanQia, nBattleTimes = oLuaObj.m_oGuaJi:GetGuanQiaAndBattleTimes()
		local nServerID = oLuaObj:GetServer()
		--Network.oRemoteCall:Call("StartGuaJiAutoReward", nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oLuaObj:GetID(), {nGuanQia=nGuanQia})
		oLuaObj.m_oGuaJi:SendGuanQiaInfo()
		-- 	梁建荣(梁建荣) 03-02 14:07:42
		-- 这屏蔽不显示
		--self:SendLeaveRewardInfo(oLuaObj)
		if not oLuaObj:IsInBattle() then		--重连boss战时不发
			self:SendGuaJiStatue(oLuaObj)
		end

		CEventHandler:OnEnterGuaJiDup(oLuaObj, {})

		--检查当前状态，如果非战斗状态同时满足Boss战，切入挑战boss
		local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
		local function CallBack(bAutoBattle)
			if nBattleTimes >= tGuanQiaConf.nChalBossLimit and not self.m_bIsInBattle and bAutoBattle then
				--进入boss战
				self:ChallengeBoss(oLuaObj)
			else
				--开始能看到动画的自动战斗(战斗结束通过客户端通知动画播放完毕)
				if not oLuaObj:IsInBattle() then		--如果是重连在boss战先不启动
					--self:RegAutoBattle(oLuaObj)
					--进入场景是先让离开收益面板有足够时间显示所以巡逻时间上+3秒
					local nLeaveTime = oLuaObj.m_oGuaJi:GetLeaveTimestamp()
					if nLeaveTime == 0 or (nLeaveTime > 0 and os.time() - nLeaveTime < 60) then		--离开时间等0表示首次进来，或小于60秒都马上战斗
						self:NoticeBattleStart()
					else
						GetGModule("TimerMgr"):Clear(self.m_nBattleSecTimer)
						self.m_nBattleSecTimer = GetGModule("TimerMgr"):Interval(tGuanQiaConf.nPatrolSec+3, function() self:NoticeBattleStart() end)
					end
				end
			end
			Network.oRemoteCall:Call("StopGuaJiAutoReward", nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oLuaObj:GetID())
		end
		Network.oRemoteCall:CallWait("GetIsAutoBattle", CallBack, nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oLuaObj:GetID())
	end
end

function CGuaJiBattleDup:OnObjLeave(oLuaObj, nBattleID)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	    --人物
	if nObjType == gtGDef.tObjType.eRole and (not oLuaObj:IsRobot()) then
        if nBattleID <= 0 then
            self.m_tRoleMap[oLuaObj:GetID()] = nil
            oLuaObj:SetBattleDupID(0)
            if not next(self.m_tRoleMap) then
                goBattleDupMgr:DestroyBattleDup(self:GetID())
			end
			--离开副本再清空一次
			oLuaObj.m_oGuaJi:ClearLeaveRewardData()
			--角色离开场景设置挂机模块重新自动奖励
			self:StopAutoBattle()
			--oLuaObj.m_oGuaJi:SetLeaveTimestamp()
			for nRoleID, oRole in pairs(self.m_tRoleMap) do
				if oRole:IsRobot() then
					goLRobotMgr:RemoveRobot(nRoleID)
					self.m_tRoleMap[nRoleID] = nil
				end
			end
			--客户端在普通场景时不用发结束动画通知
			if oLuaObj:IsOnline() then
				local nGuanQia, nBattleTimes = oLuaObj.m_oGuaJi:GetGuanQiaAndBattleTimes()
				local nServerID = oLuaObj:GetServer()
				Network.oRemoteCall:Call("StartGuaJiAutoReward", nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oLuaObj:GetID(), {nGuanQia=nGuanQia})
			end
        end
    end
end

function CGuaJiBattleDup:SendLeaveRewardInfo(oRole)
	if not oRole then return end 
	local function LeaveRewardInfo(bIsGuaJi)
		if bIsGuaJi then
			if (os.time() - oRole.m_oGuaJi:GetLeaveTimestamp()) > 60 then
				oRole.m_oGuaJi:SendLeaveRewardInfo(1, oRole.m_oGuaJi.m_tLeaveReward)		--1:表示离开挂机场景的收益
			end
			--进入副本后清空非挂机场景累积的奖励数据
			oRole.m_oGuaJi:ClearLeaveRewardData()
		end
    end
    local nServerID = oRole:GetServer()
    Network.oRemoteCall:CallWait("IsGuaJi", LeaveRewardInfo, nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oRole:GetID())
end

function CGuaJiBattleDup:ObjAfterEnter(oLuaObj)
	assert(oLuaObj, "数据错误")
	if oLuaObj:IsRobot() then
		goLRobotMgr:RegMove(oLuaObj:GetID())
	end
end

function CGuaJiBattleDup:SyncDupInfo(oRole)
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
	else
		local tSessionList = self:GetSessionList()
		Network.PBBroadcastExter("BattleDupInfoRet", tSessionList, tMsg)
	end
end

function CGuaJiBattleDup:SetAutoBattle(oRole, bAutoBattle)
	CEventHandler:ClickAutoChalGuaJiBoss(oRole, {})
	local nServerID = oRole:GetServer()	
	Network.oRemoteCall:Call("SetIsAutoBattle", nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oRole:GetID(), {bAutoBattle=bAutoBattle})
end

--挑战boss
function CGuaJiBattleDup:ChallengeBoss(oRole)
	--检查是否达到挑战boss的条件
	CEventHandler:ClickChalGuaJiBoss(oRole, {})
	if self.m_bIsInBattle then
		--强行设置状态，停止定时器倒计时
		self.m_bIsInBattle = false
		self:StopAutoBattle()
	end
	if not self.m_bIsInBattle then
		local nGuanQia, nBattleTimes = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
		local tConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
		assert(next(tConf), "获取关卡配置失败")
		if nBattleTimes < tConf.nChalBossLimit then
			return oRole:Tips("您还未能与本关BOSS战斗，请继续巡逻消灭更多的怪物")
		end

		self:StopAutoBattle()
		local nConfID = tConf.nSeq
		--Boss属性增强
		local oMonster = goMonsterMgr:CreateMonsterByGroup(nConfID, ctGuaJiConf)	--根据配置中nBattleGroup字段获取到战斗组
		oRole:PVE(oMonster, {nAddAttrModType=gtAddAttrModType.eGuaJi})
	end
end

function CGuaJiBattleDup:OnBattleEnd(oLuaObj, tBTRes, tExtData)
	--只有boss战才调用到这里
	local nObjType = oLuaObj:GetObjType() --gtObjType
	local nGuanQia = oLuaObj.m_oGuaJi:GetGuanQiaAndBattleTimes()
	local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
	if nObjType == gtGDef.tObjType.eRole and tBTRes.bWin then
		--战斗胜利奖励
		local tMsg = {tItemList={}}
		local nRoleExp = math.floor(tGuanQiaConf.fnRoleExpReward(tGuanQiaConf.nPatrolSec, nGuanQia))
		local nPetExp = math.floor(tGuanQiaConf.fnPetExpReward(tGuanQiaConf.nPatrolSec, nGuanQia))
		local nYinBi = math.floor(tGuanQiaConf.fnYinBiReward(tGuanQiaConf.nPatrolSec, nGuanQia))
		local nJinBi = math.floor(tGuanQiaConf.fnJinBiReward(nGuanQia))
		oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "挂机挑战boss奖励", true, false, {bNoTips=true})
		oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "挂机挑战boss奖励", true, false, {bNoTips=true})
		oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "挂机挑战boss奖励", true, false, {bNoTips=true})
		oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.eJinBi, nJinBi, "挂机挑战boss奖励", true, false, {bNoTips=true})
		table.insert(tMsg.tItemList, {nItemType=gtItemType.eProp, nItemID=7, nItemNum=nRoleExp})
		table.insert(tMsg.tItemList, {nItemType=gtItemType.eProp, nItemID=8, nItemNum=nPetExp})
		table.insert(tMsg.tItemList, {nItemType=gtItemType.eProp, nItemID=4, nItemNum=nYinBi})
		table.insert(tMsg.tItemList, {nItemType=gtItemType.eProp, nItemID=3, nItemNum=nJinBi})										
		local nRoleLevel = oLuaObj:GetLevel()
		local tRewardPool = ctAwardPoolConf.GetPool(tGuanQiaConf.tReward[1][1], nRoleLevel, oLuaObj:GetConfID())
		if next(tRewardPool) then
			assert(next(tRewardPool), "挂机挑战boss奖励池抽取错误,人物等级："..nRoleLevel.."奖励库ID: "..tGuanQiaConf.tReward[1][1])
			local function GetItemWeight(tConf)
				return tConf.nWeight
			end
			local tRewardItemList = CWeightRandom:Random(tRewardPool, GetItemWeight, tGuanQiaConf.tReward[1][2], false)
			for nIndex, tReward in pairs(tRewardItemList) do
				if  tReward.nItemID > 0 and tReward.nItemNum > 0 then
					oLuaObj:AddItem(gtItemType.eProp, tReward.nItemID, tReward.nItemNum, "挂机挑战boss奖励", true, false, nil, true)
					table.insert(tMsg.tItemList, {nItemType=gtItemType.eProp, nItemID=tReward.nItemID, nItemNum=tReward.nItemNum})
				end
			end
		end

		--固定奖励
		for nIndex, tItem in pairs(tGuanQiaConf.tFixReward) do
			if ctPropConf[tItem[2]] then
				if tItem[1] > 0 and tItem[2] > 0 and tItem[3] > 0 then
					oLuaObj:AddItem(tItem[1], tItem[2], tItem[3], "挂机挑战boss奖励", true, tItem[4], nil, true)
					table.insert(tMsg.tItemList, {nItemType=gtItemType.eProp, nItemID=tItem[2], nItemNum=tItem[3]})
				end
			end
		end

		oLuaObj.m_oGuaJi:SetNextGuanQia(nGuanQia)
		oLuaObj.m_oGuaJi:SetBattleTimes(0)
		--self:RegAutoBattle(oLuaObj)
		tMsg.nOldGuanQia = tGuanQiaConf.nSeq--nGuanQia
        tMsg.nNewGuanQia =	self:GetGuanQiaSeq(oLuaObj)	--oLuaObj.m_oGuaJi:GetGuanQiaAndBattleTimes()

       	tMsg.tItemList = self:PropSendCheck(tMsg.tItemList)
		self:SendBossRewardInfo(oLuaObj, tMsg)
		self:SendGuaJiStatue(oLuaObj)
		--延时启动自动巡逻战斗
		GetGModule("TimerMgr"):Clear(self.m_nBattleSecTimer)
		self.m_nBattleSecTimer = GetGModule("TimerMgr"):Interval(7, function() self:NoticeBattleStart() end)		--前端显示界面5秒，关闭界面后2秒进入战斗
	elseif nObjType == gtGDef.tObjType.eRole and not tBTRes.bWin then
		--被Boss打死后设置重新开始,要发一次协议刷新面板
		local function CallBack(bAutoBattle)
			if bAutoBattle then
				self:SetAutoBattle(oLuaObj, false)
			end
			oLuaObj.m_oGuaJi:SetBattleTimes(0)
			self:SendGuaJiStatue(oLuaObj)
			self:RegAutoBattle(oLuaObj)
		end
		local nServerID = oLuaObj:GetServer()
		Network.oRemoteCall:CallWait("GetIsAutoBattle", CallBack, nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oLuaObj:GetID())
	end
end

function CGuaJiBattleDup:GetGuanQiaSeq(oLuaObj)
	local nGuanQia = oLuaObj.m_oGuaJi:GetGuanQiaAndBattleTimes()
	local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
	return tGuanQiaConf.nSeq
end

function CGuaJiBattleDup:PropSendCheck(tItemList)
	local tTemList = {}
	for nKey = #tItemList, 1, -1 do
		if tItemList[nKey].nItemNum < 1 or  tItemList[nKey].nItemType < 1
		 or tItemList[nKey].nItemID < 1 then
			table.remove(tItemList, nKey)
		else
			if not tTemList[tItemList[nKey].nItemID] then
				tTemList[tItemList[nKey].nItemID] = tItemList[nKey]
			else
				tTemList[tItemList[nKey].nItemID].nItemNum = tTemList[tItemList[nKey].nItemID].nItemNum +  tItemList[nKey].nItemNum
			end
		end
	end
	tItemList ={}
	for _, tItem in pairs(tTemList) do
		table.insert(tItemList,tItem)
	end
	return tItemList
end

function CGuaJiBattleDup:GetSessionList()
	local tSessionList = {}
	for _, oRole in pairs(self.m_tRoleMap) do
		if not oRole:IsRobot() and oRole:IsOnline() then
			table.insert(tSessionList, oRole:GetServer())
			table.insert(tSessionList, oRole:GetSession())
		end
	end
	return tSessionList
end

function CGuaJiBattleDup:EnterBattleDupReq(oRole)
	--判断是是否在副本中
    local oCurrDupObj = oRole:GetCurrDupObj()
    local tCurrDupConf = oCurrDupObj and oCurrDupObj:GetConf()
    if (tCurrDupConf and tCurrDupConf.nType == CDupBase.tType.eDup) then
            return oRole:Tips("副本中不能操作")
    end

	if oRole:GetTeamID() > 0 then
		return oRole:Tips("在队伍中不能进入挂机场景")
	end

    if not oRole.m_oSysOpen:IsSysOpen(32, true) then
        return
    end

    local oDup = oRole:GetCurrDupObj()
    if oDup:GetConf().nBattleType == gtBattleDupType.eGuaJi then
        return oRole:Tips("已在挂机场景中")
    end


	goBattleDupMgr:CreateBattleDup(gtBattleDupType.eGuaJi, function(nDupMixID)
		local nGuanQia, nBattleTimes = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
		local tConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
		local tRobotList = {}
		for i = 1, tConf.nRobotNum do
			local tData = {}
			--local nTarServer = tServerList[math.random(#tServerList)]
			tData.nMinLevel = 0
			tData.nMaxLevel = 1
			tData.nServer = gnServerID
			tData.nDupMixID = nDupMixID
			table.insert(tRobotList, tData)
		end
		--Network.oRemoteCall:Call("GuaJiCreateRobotReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, tRobotList)
        local tConf = assert(ctDupConf[CUtil:GetDupID(nDupMixID)])
        local tDupList = ctBattleDupConf[gtBattleDupType.eGuaJi].tDupList
        local tDupConf = assert(ctDupConf[tDupList[1][1]])
		oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
    end, false, oRole:GetServer())
end

--通知战斗动画开始
function CGuaJiBattleDup:NoticeBattleStart()
	local oRealRole = nil
	for nRoleiD, oRole in pairs(self.m_tRoleMap) do
		if oRole and (not oRole:IsRobot()) then
			oRealRole = oRole
		end
	end
	if oRealRole then				--真正的角色还在
		self.m_bIsInBattle = true
		self:SendGuaJiStatue(oRealRole)
		self:StopAutoBattle()
	else
		GetGModule("TimerMgr"):Clear(self.m_nBattleSecTimer)
		self.m_nBattleSecTimer = nil
	end
end

--在挂机场景才会下发的协议
function CGuaJiBattleDup:SendGuaJiStatue(oRole)
	local nGuanQia, nBattleTiems = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
    local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
    local tMsg = {}
    tMsg.bIsInBattle = self.m_bIsInBattle
    tMsg.bCanChalBoss = (nBattleTiems >= tGuanQiaConf.nChalBossLimit) and true or false
	tMsg.nBattleTimes = nBattleTiems
	tMsg.nGuanQiaSeqID = tGuanQiaConf.nSeq
	local function SendMsg(bAutoBattle)
		tMsg.bIsAutoBattle = bAutoBattle
		oRole:SendMsg("GuaJiStatusRet", tMsg)
		--PrintTable(tMsg)				
	end
	local nServerID = oRole:GetServer()	
	Network.oRemoteCall:CallWait("GetIsAutoBattle", SendMsg, nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oRole:GetID())
end

--收到战斗动画结束通知
function CGuaJiBattleDup:GuaJiBattleEndNoticeReq(oRole)
	if self.m_bIsInBattle then
		--检查时间是否合理，发奖励，达到boss战时，进入boss战
		local nGuanQia, nBattleTimes = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
		local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
		--if os.time() - oRole.m_oGuaJi.m_nLastRewardTimeStamp >= 3*tGuanQiaConf.nPatrolSec then
			oRole.m_oGuaJi:Reward(false)
		--end
		self.m_bIsInBattle = false
		self:SendGuaJiStatue(oRole)
		local function CallBack(bAutoBattle)
			--每次战斗动画播完都判断一下能不能参加boss战
			local nGuanQia, nBattleTimes = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
			local tGuanQiaConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
			--print(">>>动画结束通知，是否自动切换到boss战", bAutoBattle, " 完成次数", nBattleTimes, " 是否在战斗", self.m_bIsInBattle)
			if nBattleTimes >= tGuanQiaConf.nChalBossLimit and not self.m_bIsInBattle and bAutoBattle then
				self:ChallengeBoss(oRole)
			else
				self:RegAutoBattle(oRole)
			end
		end
		local nServerID = oRole:GetServer()
		Network.oRemoteCall:CallWait("GetIsAutoBattle", CallBack, nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oRole:GetID())
	end
end

--开启通知动画请求(boss奖励展示确定按钮)
function CGuaJiBattleDup:StartNoticReq(oRole)
	if not oRole then return end
	self:RegAutoBattle(oRole)
end

function CGuaJiBattleDup:SendBossRewardInfo(oRole, tMsg)
	if not oRole then return end
	oRole:SendMsg("BossRewardInfoRet", tMsg)
	--PrintTable(tMsg)
end

--注册后续执行事件
function CGuaJiBattleDup:RegisterExecEvent()
    self.m_tExecEvent[1] = function(oRole) self:GivePet(oRole) end
    self.m_tExecEvent[2] = function(oRole) self:GetPartner(oRole) end
end

function CGuaJiBattleDup:GivePet(oRole)
	local nGuanQia, nBattleTimes = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
	local tConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
	local nPetID = tConf.tEventConf[1]
    oRole:AddItem(gtItemType.ePet, nPetID, 1, "目标任务后续的引导任务赠送")
end

function CGuaJiBattleDup:GetPartner(oRole)
	local nGuanQia, nBattleTimes = oRole.m_oGuaJi:GetGuanQiaAndBattleTimes()
	local tConf = ctGuaJiConf:GetGuanQiaConf(nGuanQia)
    for _, tPartner in pairs(tConf.tEventConf) do
        local nPlanID = tPartner[1]
        local nPartnerID = tPartner[2]
        oRole.m_oPartner:RecruitPartnerReq(nPartnerID)
        oRole.m_oPartner:BattleActiveReq(nPlanID, nPartnerID)
    end
end