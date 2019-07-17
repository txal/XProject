--神兽乐园模块（已取消神兽乐园副本）
--后端 #5675
-- 前端 #5488: 【神兽乐园】神兽乐园入口修改（同步所有项目）
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxDayChalTimes = 20        --每天只能挑战20次(单单一个字段没地方配故写死)
local tChallenge = 
{
    eOne = 1,               --挑战一个貔貅
    eTen = 2,               --挑战十个貔貅
}

function CShenShouLeYuanModule:Ctor(oRole)
    self.m_oRole = oRole
    self.m_bIsMoveChalTimes = false         --是否挑战次数数据迁移
    self.m_tChalTimesMap = {}
    self.m_nLastResetTimeStamp = 0          --上次清空数据时间戳
end 

function CShenShouLeYuanModule:LoadData(tData)
    if tData then
        self.m_tChalTimesMap = tData.m_tChalTimesMap or {}
        self.m_bIsMoveChalTimes = tData.m_bIsMoveChalTimes or false
        self.m_nLastResetTimeStamp = tData.m_nLastResetTimeStamp or 0
    end

    --将数据迁移过来
    if not self.m_bIsMoveChalTimes then
        self.m_tChalTimesMap = self.m_oRole.m_tShenShouData or {}
        self.m_bIsMoveChalTimes = true
        self:MarkDirty(true)
    end

    if self.m_nLastResetTimeStamp == 0 then
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
    end
end

function CShenShouLeYuanModule:SaveData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
    tData.m_tChalTimesMap = self.m_tChalTimesMap
    tData.m_bIsMoveChalTimes = self.m_bIsMoveChalTimes
    tData.m_nLastResetTimeStamp = self.m_nLastResetTimeStamp or 0
    return tData
end

function CShenShouLeYuanModule:GetType()
    return gtModuleDef.tShenShouLeYuanModule.nID, gtModuleDef.tShenShouLeYuanModule.sName
end

function CShenShouLeYuanModule:GetTotalChalTimes()
    self:CheckReset()
    local nTotalTimes = 0
    for nType, nTimes in pairs(self.m_tChalTimesMap) do
        if nType == tChallenge.eOne then
            nTotalTimes = nTotalTimes + nTimes
        else
            nTotalTimes = nTotalTimes + nTimes*10       --记录的是请求挑战十次的次数
        end
    end
    return nTotalTimes
end

function CShenShouLeYuanModule:CheckReset()
   if not os.IsSameDay((self.m_nLastResetTimeStamp or 0), os.time()) then
        self.m_tChalTimesMap = {}
        self.m_nLastResetTimeStamp = os.time()
        self:MarkDirty(true)
   end
end

function CShenShouLeYuanModule:Opera(nChalType)
    if nChalType < tChallenge.eOne or nChalType > tChallenge.eTen then
        return self.m_oRole:Tips("挑战类型错误")
    end

    if self.m_oRole:IsInBattle() then
        return self.m_oRole:Tips("在战斗中不能挑战")
    end

    local oDup = self.m_oRole:GetCurrDupObj()
    local tDupConf = oDup:GetConf()
    if tDupConf.nType == CDupBase.tType.eDup then 
        return self.m_oRole:Tips("在副本中不能挑战")
    end

    local nChalTimes = self:GetTotalChalTimes()
    if nChalTimes >= nMaxDayChalTimes then
        return self.m_oRole:Tips("您本日参与次数已达到上限，请明天再来")
    end

    local nAddTimes = 0
    if nChalType == tChallenge.eOne then
        nAddTimes = 1
    elseif nChalType == tChallenge.eTen then
        nAddTimes = 10
    end
    if nChalTimes+nAddTimes > nMaxDayChalTimes then
        return self.m_oRole:Tips("此类型挑战将超上限，不能进行此类型挑战")
    end

    if nChalType == tChallenge.eOne then
        self:ChallengeMonster(tChallenge.eOne)

    elseif nChalType == tChallenge.eTen then
        self:ChallengeMonster( tChallenge.eTen)
    end
end

--挑战貔貅
function CShenShouLeYuanModule:ChallengeMonster(nChallengeType)
    if nChallengeType < tChallenge.eOne or nChallengeType > tChallenge.eTen then
        return self.m_oRole:Tips("挑战类型非法")
    end

    --改成所有的都消耗物品
    local tNeed = ctShenShouLeYuanConf[nChallengeType].tNeedChallenge
    assert(ctPropConf[tNeed[1][1]], "没有该物品")
    local nHadCount = self.m_oRole:ItemCount(gtItemType.eProp, tNeed[1][1])
    if nHadCount >= tNeed[1][2] then     --挑战所需道具
        self.m_oRole:AddItem(gtItemType.eProp, tNeed[1][1], -tNeed[1][2], "挑战貔貅扣除")
        self:AttackMonster(nChallengeType)
    else
        return self.m_oRole:Tips(string.format("%s不足。挑战貔貅有几率掉落。",ctPropConf[tNeed[1][1]].sName))
    end
end

function CShenShouLeYuanModule:AttackMonster(nChallengeType)
    local nMonConfID = ctShenShouLeYuanConf[nChallengeType].nMonsterID
    local oMonster = goMonsterMgr:CreateInvisibleMonster(nMonConfID)
    self.m_oRole:PVE(oMonster, {nChallengeType=nChallengeType, bShenShouLeYuan=true})
    self.m_oRole:PushAchieve("神兽乐园战斗次数",{nValue = 1})
end

function CShenShouLeYuanModule:OnBattleEnd(tBTRes, tExtData)
    local nType = tExtData.nChallengeType
    local nRewardID = ctShenShouLeYuanConf[nType].tReward[1][1]
    local nRewardCount = ctShenShouLeYuanConf[nType].tReward[1][2]

    local tItemIDList = {}
    if tBTRes.bWin then
        if nType == tChallenge.eOne or nType == tChallenge.eTen then
            --挑战一个或十个貔貅的奖励
            local fnRoleExp = ctDailyBattleDupConf[gtDailyID.eShenShouLeYuan].fnRoleExpReward
            local fnPetExp = ctDailyBattleDupConf[gtDailyID.eShenShouLeYuan].fnPetExpReward
            local nRoleLevel = self.m_oRole:GetLevel()
            
            local tItemList = ctAwardPoolConf.GetPool(nRewardID, nRoleLevel, self.m_oRole:GetConfID())
            local function fnGetWeight (tNode) return tNode.nWeight end
            local tReward = CWeightRandom:Random(tItemList, fnGetWeight, nRewardCount, false)
            assert(next(tReward), "神兽乐园奖励配置错误，人物等级: "..nRoleLevel)
            for i = 1, nRewardCount do
                local nRoleExp = fnRoleExp(nRoleLevel)
                local nPetExp = fnPetExp(nRoleLevel)
                self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "挑战貔貅奖励")
                self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "挑战貔貅奖励")
                self.m_oRole:AddItem(tReward[i].nItemType, tReward[i].nItemID, tReward[i].nItemNum, "挑战貔貅奖励")
                local tItem = {tReward[i].nItemID, 1}
                table.insert(tItemIDList, tItem)
            end
            
            self:AddShenShouChalTimes(nType, 1)
        end
    end
    local tData = {}
    tData.bIsHearsay = true
    tData.tItemIDList = tItemIDList
    CEventHandler:OnCompShenShouLeYuan(self.m_oRole, tData)
end

function CShenShouLeYuanModule:AddShenShouChalTimes(nChalType, nVal)
    if nVal == 0 then return end
    assert(1 <= nChalType and nChalType <= 2, "神兽乐园保存数据有误")
    local nChalTimes = self.m_tChalTimesMap[nChalType]
    self.m_tChalTimesMap[nChalType] = (nChalTimes or 0) + nVal
    self:MarkDirty(true)
end