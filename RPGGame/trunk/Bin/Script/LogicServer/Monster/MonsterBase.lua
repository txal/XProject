--怪物/NPC基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CMonsterBase:Ctor(nMonType, nObjID, nConfID)
    assert(nMonType and nObjID and nConfID, "参数错误")
    self.m_nObjID = nObjID      --对象ID
    self.m_nConfID = nConfID    --配置ID
    self.m_nMonType = nMonType  --怪物类型
    self.m_nBattleID = 0 --战斗ID
    
    self.m_fnMoveTargetCallback = nil
    self.m_nActID = 0           --当前的动作行为
    self.m_nActStamp = 0
    self.m_nActTimer = nil      --动作定时器
end

function CMonsterBase:OnRelease()
    print(self:GetMonType(), self:GetConfID(), self:GetName(), "怪物对象释放")
    if self:GetNativeObj() then
        self:LeaveScene()
    end
    if self.m_nActTimer and self.m_nActTimer > 0 then 
        goTimerMgr:Clear(self.m_nActTimer)
    end
    self.m_nActTimer = nil
end

function CMonsterBase:GetID() return self.m_nObjID end
function CMonsterBase:GetName() return "子类缺接口" end
function CMonsterBase:GetAOIID() return 0 end --接口兼容
function CMonsterBase:GetMixObjID() return gtObjType.eMonster<<32|self.m_nObjID end
function CMonsterBase:GetLevel() return 0 end
function CMonsterBase:GetConfID() return self.m_nConfID end
function CMonsterBase:GetObjType() return gtObjType.eMonster end
function CMonsterBase:GetMonType() return self.m_nMonType end
function CMonsterBase:IsInBattle() return self.m_nBattleID>0 end
function CMonsterBase:GetBattleGroupConf() return ctBattleGroupConf[self:GetConf().nBattleGroup] end
function CMonsterBase:CheckCanBattle()
    if self:GetConf().nBattleGroup <= 0 then 
        return false
    end
    return true
end
function CMonsterBase:GetDupObj() end --场景对象
function CMonsterBase:GetNativeObj() end --CPP对象
function CMonsterBase:SetMoveTargetCallback(fnCallback)
    self.m_fnMoveTargetCallback = fnCallback
end
function CMonsterBase:OnReachTargetPos() 
    print(self:GetName(), "到达目的坐标") 
    if self.m_fnMoveTargetCallback then 
        self.m_fnMoveTargetCallback(self)
    end
    if self.m_oNativeObj then --前面的回调，可能已经从场景移除, 花轿功能会出现这个
        local oDup = self:GetDupObj()
        if oDup and self:GetAOIID() > 0 then 
            oDup:OnReachTargetPos(self)
        end
    end
end
function CMonsterBase:Tips(sCont) end --接口兼容

function CMonsterBase:GetActID() return self.m_nActID end
function CMonsterBase:GetActTime() 
    local nCurTime = os.time()
    return math.abs(nCurTime - self.m_nActStamp)
end
-- bSync是否做场景同步刷新
function CMonsterBase:SetActID(nActID, bSync)
    assert(nActID and nActID >= 0)
    --查看动作是否在配置表中，防止错误数据
    local tActConf = ctEntityActConf[nActID]
    if nActID ~= 0 and not tActConf then --0动作，即默认动作，不需要配置
        return
    end
    self.m_nActID = nActID
    self.m_nActStamp = os.time()

    --删除旧的定时器，可能旧动作未到时间，就设置了新动作
    if self.m_nActTimer and self.m_nActTimer > 0 then 
        goTimerMgr:Clear(self.m_nActTimer)
    end
    self.m_nActTimer = nil

    if nActID > 0 and tActConf then --大于0，非默认行为，设置定时器，默认行为，不设置
        if tActConf.nActTime >= 1 then 
            self.m_nActTimer = goTimerMgr:Interval(tActConf.nActTime, function() self:OnActTimer() end)
        else --动作时间小于1的，忽略
           self.m_nActID = 0
        end
    end
    if bSync then 
        self:FlushSceneView()
    end
end

function CMonsterBase:OnActTimer()
    if self.m_nActTimer and self.m_nActTimer > 0 then 
        goTimerMgr:Clear(self.m_nActTimer)
    end
    self.m_nActTimer = nil
    -- local nActID = self:GetActID()
    -- self.m_nActID = 0 --先设置为默认动作0，防止处理失败，角色动作状态不对
    -- if nActID > 0 then 
    --     local tActConf = ctEntityActConf[nActID]
    --     if tActConf and tActConf.nNextAct > 0 then 
    --         self:SetActID(tActConf.nNextAct, true)
    --         return  --直接退出，其他情况，默认还原到默认动作
    --     end
    -- end
    self:SetActID(0, false)
end

function CMonsterBase:GetViewData() assert(false, "目前放在子类") end

function CMonsterBase:FlushSceneView()
    local tInfo = self:GetViewData()
    local oDup = self:GetDupObj()
    if oDup then 
        oDup:BroadcastObserver(self:GetAOIID(), "MonsterFlushViewRet", {tInfo})
    end
end

--进入场景成功
function CMonsterBase:OnEnterScene(nDupMixID) 
    if not self:GetNativeObj() then
        return
    end
    self:GetDupObj():OnObjEnter(self)
end

--进入场景后(同步了视野之后)
function CMonsterBase:AfterEnterScene(nDupMixID)
end

--离开场景完成
function CMonsterBase:OnLeaveScene(nDupMixID)
    print("CMonsterBase:OnLeaveScene***", self:GetName())
    if not self:GetNativeObj() then
        return
    end
    local oDupObj = self:GetDupObj()
    if not oDupObj then 
        return
    end
    oDupObj:OnObjLeave(self)
end

--进入场景
function CMonsterBase:EnterScene(nDupMixID, nPosX, nPosY, nLine, nFace)
    if not self:GetNativeObj() then
        return
    end
    goDupMgr:GetDup(nDupMixID):Enter(self.m_oNativeObj, nPosX, nPosY, nLine, nFace)
end

--离开场景
function CMonsterBase:LeaveScene()
    if not self:GetNativeObj() then
        return
    end
    local oDupObj = self:GetDupObj()
    if not oDupObj then
        return
    end
    self:StopRun()
    oDupObj:Leave(self:GetAOIID())
end

--取子怪物战斗数据
function CMonsterBase:GetSubMonsterBattleData(nSubMonsterID, nLevel)
    local tSubMonConf = ctSubMonsterConf[nSubMonsterID]
    local tMData = {}

    --基本信息 
    tMData.nSpouseID = 0
    tMData.nObjID = tSubMonConf.nID
    tMData.nObjType = gtObjType.eMonster
    tMData.sObjName = tSubMonConf.sName
    tMData.sModel = tSubMonConf.sModel
    tMData.nLevel = nLevel
    tMData.nExp = 0
    tMData.nSchool = tSubMonConf.nSchool

    --结果属性
    tMData.tBattleAttr = {}
    for _, v in pairs(gtBAT) do
        tMData.tBattleAttr[v] = 0
    end
    tMData.tBattleAttr[gtBAT.eQX] = tSubMonConf.fnHP(nLevel)
    tMData.tBattleAttr[gtBAT.eGJ] = tSubMonConf.fnAtk(nLevel)
    tMData.tBattleAttr[gtBAT.eFY] = tSubMonConf.fnDef(nLevel)
    tMData.tBattleAttr[gtBAT.eLL] = tSubMonConf.fnMana(nLevel)
    tMData.tBattleAttr[gtBAT.eSD] = tSubMonConf.fnSpeed(nLevel)
    tMData.tBattleAttr[gtBAT.eMF] = tSubMonConf.fnMag(nLevel)

    --HP/MP上限
    tMData.nMaxHP = tMData.tBattleAttr[gtBAT.eQX]
    --PVE战斗中的NPC，默认MP上限=9999；而各类竞技战斗中的伙伴或者人物，则直接调用其真实数据
    tMData.nMaxMP = 9999 --tMData.tBattleAttr[gtBAT.eMF]
    --自动战斗
    tMData.bAuto = true
    --武器攻击
    tMData.nWeaponAtk = tSubMonConf.fnWeaponAtk(nLevel)

    --宠物/道具
    tMData.tPetMap = {}
    tMData.tPropList = {}

    --怪物主动/被动技能
    tMData.tActSkillMap = {}
    for _, tSkill in ipairs(tSubMonConf.tActSkill) do
        if tSkill[1] > 0 then
            local nRnd = math.random(100)
            if nRnd <= tSkill[2] then
                local tSkillConf = ctSkillConf[tSkill[1]] or ctPetSkillConf[tSkill[1]] 
                tMData.tActSkillMap[tSkill[1]] = {nLevel=nLevel, sName=tSkillConf.sName}
            end
        end
    end
    tMData.tPasSkillMap = {}
    for _, tSkill in ipairs(tSubMonConf.tPasSkill) do
        if tSkill[1] > 0 then
            local nRnd = math.random(100)
            if nRnd <= tSkill[2] then
                tMData.tPasSkillMap[tSkill[1]] = {nLevel=nLevel, sName=ctPetSkillConf[tSkill[1]].sName}
            end
        end
    end

    --修炼战斗实现(攻法,防御,法抗)
    tMData.tPracticeMap = {}
    tMData.tPracticeMap[101] = tSubMonConf.fnAtkPra(nLevel)
    tMData.tPracticeMap[102] = tSubMonConf.fnDefPra(nLevel)
    tMData.tPracticeMap[103] = tSubMonConf.fnMagPra(nLevel)

    return tMData
end

--取战斗数据
function CMonsterBase:GetBattleData(nLevel, nTeamMembers)
    local tConf = self:GetConf()
    local nBattleGroup = tConf.nBattleGroup
    local tBattleGroup = ctBattleGroupConf[nBattleGroup]
    if not tBattleGroup then
        return LuaTrace("怪物战斗组不存在", tConf, nBattleGroup)
    end
    
    local nFmtID = tBattleGroup.tFmt[math.random(#tBattleGroup.tFmt)][1]
    local nFmtLv = tBattleGroup.nFmtLv
    local tFmtAttrAdd = CFormation:GetAttrAddByFmtAndLv(nFmtID, nFmtLv)

    local tBTData = {
        nFmtID = nFmtID,
        nFmtLv = nFmtLv,
        tFmtAttrAdd = tFmtAttrAdd,
        tUnitMap = {},
    }
    
    --根据队伍人数算怪物数量
    local nSubMonsterNum = 10
    if tBattleGroup.nNumType == 2 then
        nSubMonsterNum = tBattleGroup.eMonNum(nTeamMembers)
    end
    for k = 1, nSubMonsterNum do
        local nUnitID = 200 + k
        local tSubMon= tBattleGroup['tPos'..k]
        if tSubMon[1][1] > 0 then
            local nSubMon = tSubMon[math.random(#tSubMon)][1]
            tBTData.tUnitMap[nUnitID] = self:GetSubMonsterBattleData(nSubMon, nLevel)
        end
    end
    return tBTData
end

--进入战斗
function CMonsterBase:OnBattleBegin(nBattleID)
    print("CMonsterBase:OnBattleBegin***", self:GetID())
    --999号怪测试用
    if self:GetConfID() == 999 then
        return
    end
    if self:IsInBattle() then
        return print("怪物已经在战斗，战斗失败")
    end

    self.m_nBattleID = nBattleID
    if self:GetNativeObj() then --表示场景怪
        local oDup = self:GetDupObj()
        if not oDup then
            return LuaTrace("怪物已经离开了场景", self:GetName())
        end
        oDup:RemoveObserved(self:GetAOIID())
    else
        return LuaTrace("怪物已被释放或非场景怪", self:GetName())
    end
end

--战斗结束
--@tBTRes 同RoleBattle.lua
--@tExtData 额外数据，原样返回
function CMonsterBase:OnBattleEnd(tBTRes, tExtData)
    print("怪物战斗结束", self:GetName(), tBTRes, tExtData)
    self.m_nBattleID = 0

    local oDup = self:GetDupObj()
    if oDup then --场景怪
        --999号怪测试用
        if self:GetConfID() == 999 then
            return
        end
        if self:GetNativeObj() and self:GetAOIID() > 0 then --可能OnBattleEnd回调中将怪物删除，触发离开场景
            if tBTRes.bWin then
                self:GetDupObj():AddObserved(self:GetAOIID())
            else
                self:LeaveScene()
            end
        end
        oDup:OnBattleEnd(self, tBTRes, tExtData)

    else --非场景怪

        --纯战斗怪无论失败或者胜利都要移除
        goMonsterMgr:RemoveMonster(self:GetID())
    end
end
