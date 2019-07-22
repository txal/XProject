--神兽乐园
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local tChallenge = 
{
    eOne = 1,               --挑战一个貔貅
    eTen = 2,               --挑战十个貔貅
    eBaiYin = 3,            --挑战白银貔貅
    eHuangJin = 4,          --挑战黄金貔貅
    eZuanShi = 5,           --挑战蓝钻貔貅
}

function CShenShouLeYuan:Ctor(nID, nType)
    self.m_nID = nID
    self.m_nType = nType
    self.m_tDupList = CUtil:WeakTable("v")
    self.m_tRoleMap = CUtil:WeakTable("v")
    self.m_tMonsterMap = CUtil:WeakTable("v")

    self:Init()
end

function CShenShouLeYuan:Init()
    local tConf = ctBattleDupConf[self.m_nType]
    for _, tDup in ipairs(tConf.tDupList) do
        local oDup = goDupMgr:CreateDup(tDup[1])
        oDup:SetAutoCollected(false)
        oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
        oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
        oDup:RegBattleEndCallback(function(...) self:OnBattleEnd(...) end )
        table.insert(self.m_tDupList, oDup)
    end
end

function CShenShouLeYuan:Release()
    for _, oDup in pairs(self.m_tDupList) do
        goDupMgr:RemoveDup(oDup:GetMixID())
    end
    self.m_tDupList = {}
    self.m_tRoleMap = {}
    self.m_tMonsterMap = {}
end

function CShenShouLeYuan:GetID() return self.m_nID end
function CShenShouLeYuan:GetType() return self.m_nType end
function CShenShouLeYuan:GetConf() return ctBattleDupConf[self:GetType()] end
function CShenShouLeYuan:HasRole() return next(self.m_tRoleMap) end

function CShenShouLeYuan:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

function CShenShouLeYuan:OnObjEnter(oLuaObj, bReconnect)
    local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj
		self:SyncDupInfo()

	--人物
	elseif nObjType == gtGDef.tObjType.eRole then
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
        oLuaObj:SetBattleDupID(self:GetID())
		self:SyncDupInfo(oLuaObj)
	end
end

function CShenShouLeYuan:OnObjLeave(oLuaObj, nBattleID)
    local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
        self.m_tMonsterMap[oLuaObj:GetID()] = nil
    --人物
	elseif nObjType == gtGDef.tObjType.eRole then
        if nBattleID <= 0 then
            self.m_tRoleMap[oLuaObj:GetID()] = nil
            oLuaObj:SetBattleDupID(0)
            if not next(self.m_tRoleMap) then
                goBattleDupMgr:DestroyBattleDup(self:GetID())
            end
        end
    end
end

function CShenShouLeYuan:SyncDupInfo(oRole)
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

function CShenShouLeYuan:OnBattleEnd(oLuaObj, tBTRes, tExtData)
    local nObjType = oLuaObj:GetObjType() --gtObjType
    local nType = tExtData.nChallengeType
    local nRewardID = ctShenShouLeYuanConf[nType].tReward[1][1]
    local nRewardCount = ctShenShouLeYuanConf[nType].tReward[1][2]

    local tItemIDList = {}
    if nObjType == gtGDef.tObjType.eRole and tBTRes.bWin then
        if nType == tChallenge.eOne or nType == tChallenge.eTen then
            --挑战一个或十个貔貅的奖励
            local fnRoleExp = ctDailyBattleDupConf[gtDailyID.eShenShouLeYuan].fnRoleExpReward
            local fnPetExp = ctDailyBattleDupConf[gtDailyID.eShenShouLeYuan].fnPetExpReward
            local nRoleLevel = oLuaObj:GetLevel()
            
            local tItemList = ctAwardPoolConf.GetPool(nRewardID, nRoleLevel, oLuaObj:GetConfID())
            local function fnGetWeight (tNode) return tNode.nWeight end
            local tReward = CWeightRandom:Random(tItemList, fnGetWeight, nRewardCount, false)
            assert(next(tReward), "神兽乐园奖励配置错误，人物等级: "..nRoleLevel)
            for i = 1, nRewardCount do
                local nRoleExp = fnRoleExp(nRoleLevel)
                local nPetExp = fnPetExp(nRoleLevel)
                oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "挑战貔貅奖励")
                oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "挑战貔貅奖励")
                oLuaObj:AddItem(tReward[i].nItemType, tReward[i].nItemID, tReward[i].nItemNum, "挑战貔貅奖励")
                local tItem = {tReward[i].nItemID, 1}
                table.insert(tItemIDList, tItem)
            end
            
            --蓝钻奖励
            oLuaObj:AddShenShouChalTimes(nType, 1)
            if oLuaObj.m_tShenShouData[nType] >= ctShenShouLeYuanConf[nType].nRewardLimit then
                local tRewardFiveTimesAfter = ctShenShouLeYuanConf[nType].tRewardFiveTimesAfter
                local nItemID = tRewardFiveTimesAfter[1][1]
                if nItemID > 0 then
                    local tPropConf = assert(ctPropConf[nItemID], "道具不存在:"..nType.."-"..nItemID)
                    local nItemSubType = tPropConf.nSubType
                    oLuaObj:AddItem(gtItemType.eCurr, nItemSubType, tRewardFiveTimesAfter[1][2], "挑战貔貅五次后奖励")
                end
                oLuaObj:ResetShenShouChalTimes(nType)
            end

        else
            --挑战变异貔貅的奖励
            oLuaObj:AddItem(gtItemType.eProp, nRewardID, nRewardCount, "挑战变异貔貅奖励")
            local tItem = {nRewardID, nRewardCount}
            table.insert(tItemIDList, tItem)
        end
        if nType == tChallenge.eTen then
            for i = 1, 10 do
                oLuaObj.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eShenShouLeYuan, "神兽乐园挑战成功")
            end
        else
            oLuaObj.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eShenShouLeYuan, "神兽乐园挑战成功")
        end
    end
    local tData = {}
    tData.bIsHearsay = true
    tData.tItemIDList = tItemIDList
    CEventHandler:OnCompShenShouLeYuan(oLuaObj, tData)

    local nCompCount = oLuaObj.m_oDailyActivity.m_tActDataMap[gtDailyID.eShenShouLeYuan][gtDailyData.eCountComp]
    local nRewardTimes = ctDailyActivity[gtDailyID.eShenShouLeYuan].nTimesReward
    if nCompCount >= nRewardTimes then
        oLuaObj:EnterLastCity()
    end
end

function CShenShouLeYuan:GetSessionList()
    local tSessionList = {}
	for _, oRole in pairs(self.m_tRoleMap) do
       if not oRole:IsRobot() and oRole:IsOnline() then
    		table.insert(tSessionList, oRole:GetServer())
    		table.insert(tSessionList, oRole:GetSession())
        end
	end
	return tSessionList
end

--挑战貔貅
function CShenShouLeYuan:ChallengeMonster(oRole, nChallengeType)
    if nChallengeType < tChallenge.eOne or nChallengeType > tChallenge.eZuanShi then
        return oRole:Tips("挑战类型非法")
    end

    -- if nChallengeType == tChallenge.eOne or nChallengeType == tChallenge.eTen then
    --     local nNeedJinDing = ctShenShouLeYuanConf[nChallengeType].nCostJinDing
    --     if oRole.m_nJinDing < nNeedJinDing then
    --         return oRole:Tips("金锭不足")
    --     end

    --     oRole:AddItem(gtItemType.eCurr, gtCurrType.eJinDing, -nNeedJinDing, "挑战貔貅消耗")
    --     self:AttackMonster(oRole, nChallengeType)

    -- else
        --改成所有的都消耗物品
        local tNeed = ctShenShouLeYuanConf[nChallengeType].tNeedChallenge
        assert(ctPropConf[tNeed[1][1]], "没有该物品")
        local nHadCount = oRole:ItemCount(gtItemType.eProp, tNeed[1][1])
        if nHadCount >= tNeed[1][2] then     --挑战所需道具
            oRole:AddItem(gtItemType.eProp, tNeed[1][1], -tNeed[1][2], "挑战貔貅扣除")
            self:AttackMonster(oRole, nChallengeType)
        else
            return oRole:Tips(string.format("%s不足。挑战貔貅有几率掉落。",ctPropConf[tNeed[1][1]].sName))
        end
    --end
end

function CShenShouLeYuan:AttackMonster(oRole, nChallengeType)
    if tChallenge.eBaiYin <= nChallengeType and nChallengeType <= tChallenge.eZuanShi then
        return oRole:Tips("挑战错误")
    end
    local oDup = self.m_tDupList[1]
    local tMapConf = oDup:GetMapConf()
    local nPosX = math.random(100, tMapConf.nWidth - 100)	
    local nPosY = math.random(100, tMapConf.nHeight - 100)
    local nMonConfID = ctShenShouLeYuanConf[nChallengeType].nMonsterID
    local oMonster = goMonsterMgr:CreateInvisibleMonster(nMonConfID)
    oRole:PVE(oMonster, {nChallengeType=nChallengeType, nBattleDupType=gtBattleDupType.eShenShouLeYuan})
    oRole:PushAchieve("神兽乐园战斗次数",{nValue = 1})
end

--随机产生NPC怪物
function CShenShouLeYuan:CreateMonsterReq(oRole)
    if next(self.m_tMonsterMap) then
		return oRole:Tips("怪物已经出现")
	end
    local tBattleDupConf = self:GetConf()
    local tMonster = tBattleDupConf.tMonster
    local nMonsterID = tMonster[1][1]
    local oDup = self.m_tDupList[1]
    local tMapConf = oDup:GetMapConf()
    local nPosX = math.random(600, tMapConf.nWidth - 600)
    local nPosY = math.random(600, tMapConf.nHeight - 600)
    goMonsterMgr:CreateMonster(nMonsterID, oDup:GetMixID(), nPosX, nPosY)

    local nBattleDupConfID = oDup:GetDupID()
    local sDupName = ctDupConf[nBattleDupConfID].sName
    oRole:Tips(string.format("发现貔貅出现在%s(%d;%d)", sDupName, nPosX, nPosY))
end

function CShenShouLeYuan:EnterBattleDupReq(oRole)
    -- local tDupList = ctBattleDupConf[gtBattleDupType.eShenShouLeYuan].tDupList
    -- local tDupConf = assert(ctDupConf[tDupList[1][1]])
    -- if CUtil:GetServiceID() ~= tDupConf.nLogic then
    --     return oRole:Tips("副本中不能操作")
    -- end

    --判断是是否在副本中
    local oCurrDupObj = oRole:GetCurrDupObj()
    local tCurrDupConf = oCurrDupObj and oCurrDupObj:GetConf()
    if (tCurrDupConf and tCurrDupConf.nType == CDupBase.tType.eDup) then
            return oRole:Tips("副本中不能操作")
    end

    -- if oRole:GetLevel() < ctDailyActivity[gtDailyID.eShenShouLeYuan].nLevelLimit then
    --     return oRole:Tips("等级不够，不能进入神兽乐园")
    -- end

    if not oRole.m_oSysOpen:IsSysOpen(38, true) then       --38系统开放ID
        return
    end

    local oDup = oRole:GetCurrDupObj()
    if oDup:GetConf().nBattleType == gtBattleDupType.eShenShouLeYuan then
        return oRole:Tips("已在神兽乐园中")
    end

    goBattleDupMgr:CreateBattleDup(gtBattleDupType.eShenShouLeYuan, function(nDupMixID)
        local tConf = assert(ctDupConf[CUtil:GetDupID(nDupMixID)])
        local tDupList = ctBattleDupConf[gtBattleDupType.eShenShouLeYuan].tDupList
        local tDupConf = assert(ctDupConf[tDupList[1][1]])
        oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
    end, false, oRole:GetServer())
end

function CShenShouLeYuan:Opera(oRole, nChalType)
    if nChalType < tChallenge.eOne or nChalType > tChallenge.eTen then
        return oRole:Tips("挑战类型错误")
    end
    local nCompCount = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eShenShouLeYuan][gtDailyData.eCountComp]
    local nRewardTimes = ctDailyActivity[gtDailyID.eShenShouLeYuan].nTimesReward
    local nCanChalTimes = nRewardTimes - nCompCount
    local nChalTimes = 0
    if nChalType == tChallenge.eOne then
        nChalTimes = 1
    elseif nChalType == tChallenge.eTen then
        nChalTimes = 10
    end
    if nCanChalTimes < nChalTimes then
        sTips = string.format("您本日剩余次数不足%d次，不能选择此项", nChalTimes)
        return oRole:Tips(sTips) 
    end

    if nChalType == tChallenge.eOne then
        self:ChallengeMonster(oRole, tChallenge.eOne)

    elseif nChalType == tChallenge.eTen then
        self:ChallengeMonster(oRole, tChallenge.eTen)

    --暂时屏蔽
    -- elseif nChalType == tChallenge.eBaiYin then
    --     self:ChallengeMonster(oRole, tChallenge.eBaiYin)

    -- elseif nChalType == tChallenge.eHuangJin then
    --     self:ChallengeMonster(oRole, tChallenge.eHuangJin)

    -- elseif nChalType == tChallenge.eZuanShi then
    --     self:ChallengeMonster(oRole, tChallenge.eZuanShi)
    end
end