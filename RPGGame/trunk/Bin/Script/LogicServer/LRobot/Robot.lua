--机器人对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--通过配置生成的机器人，nSrcID必须小于gnRobotIDMax
--tParam  如果是配置机器人，需要携带sName, nRoleConfID, nLevel
--tSaveData 如果有提供，则使用tSaveData 重新设置机器人的相关模块属性
function CRobot:Ctor(nServer, nRobotID, nSrcID, nRobotType, nDupMixID, tParam, tSaveData)
    print(nServer, nRobotID, nSrcID, nRobotType, nDupMixID)
    assert(nServer and nRobotID > 0 and nSrcID > 0 and nDupMixID)
    self.m_nSrcID = nSrcID --调用基类构造前设置
    self.m_tRobotParam = tParam --构造角色数据，回调会用到
    self.m_nRobotType = nRobotType or gtRobotType.eTeam
    assert(self.m_nRobotType)

    if GF.IsRobot(nSrcID) and not tSaveData then 
        assert(tParam and tParam.sName and tParam.nRoleConfID > 0 and tParam.nLevel >= 0)
    end

    CRole.Ctor(self, nServer, nSrcID, nRobotID, tSaveData)
    self.m_nID = nRobotID --外层再次保证下
    
    if not tSaveData then 
        self.m_nTeamID = 0
        self.m_bLeader = false
        self.m_bTeamLeave = false
        self.m_nTeamIndex = 0
        self.m_nTeamNum = 0

        self.m_bOnline = false

        if tParam and tParam.sName then 
            self.m_sName = tParam.sName
        end

        local nDupID = GF.GetDupID(nDupMixID)
        local tDupConf = ctDupConf[nDupID]
        assert(tDupConf)
        local tBorn = tDupConf.tBorn[1]
        local nPosX, nPosY = tBorn[1], tBorn[2]
        local nFace = tDupConf.nFace
        if self:GetRobotType() == gtRobotType.ePVPAct then 
            nPosX, nPosY, nFace = self:RandPVPActDupPos(tDupConf)
        end
        self.m_tCurrDup = {nDupMixID, nPosX, nPosY, nFace}

        self:InitRobot(tParam)
    end
    self.m_tRobotParam = nil  --使用完释放掉

    self.m_nRobotCreateStamp = os.time()
    print("创建机器人成功", self.m_nID, self.m_nSrcID)
end

-- function CRobot:InitSelfData(tData)
--     CRole.InitSelfData(self, tData)
--     if not GF.IsRobot(self.m_nSrcID) then 
--         return 
--     end
--     --TODO 使用配置数据初始化相关数据
--     assert(false, "当前未实现")
--     --TODO
-- end

function CRobot:LoadSelfData(tSaveData)
    if GF.IsRobot(self.m_nID) and not tSaveData then 
        local tParam = self.m_tRobotParam
        local tRoleConf = ctRoleInitConf[tParam.nRoleConfID]
        assert(tRoleConf)

        local tBorn = tRoleConf.tBorn[1]
        local nRndX, nRndY = GF.RandPos(tBorn[1], tBorn[2], 10)
        local tDupConf = ctDupConf[tRoleConf.nInitDup]
        --构建基本数据,和账号创建角色处数据一致
        local tData = {
            m_nSource = 0,
            m_nAccountID = 0,
            m_sAccountName = "",
            m_nCreateTime = os.time(),
            m_nID = self.m_nSrcID,
            m_nConfID = tParam.nRoleConfID,
            m_sName = tParam.sName,
            m_nLevel = tParam.nLevel,
            m_tLastDup = {0, 0, 0, 0},
            m_tCurrDup = {tRoleConf.nInitDup, nRndX, nRndY, tDupConf.nFace},
            m_nInviteRoleID = nInviteRoleID,
            m_bCreate = true, --是否创建新角色,给逻辑服用
        }
        self:InitSelfData(tData)
    else
        CRole.LoadSelfData(self, tSaveData)
    end
end

function CRobot:GetCreateData() 
    local tData = {}
    tData.nServer = self:GetServer()
    tData.nRobotID = self:GetID()
    tData.nSrcID = self:GetSrcID()
    tData.nRobotType = self:GetRobotType()
    -- tData.nDupMixID = self:GetDupMixID()  --暂时没用
    return tData
end

function CRobot:GetRoleSaveData() 
    local tData = CRole.GetRoleSaveData(self)
    return tData
end

function CRobot:AddInitEqu() end

function CRobot:InitRobotEquipment()
    local nRoleConfID = self:GetConfID()
    local nSchoolID = self:GetSchool()
    local nLevel = self:GetLevel()
    local nGender = self:GetGender()

    local tSchoolEqu = gtEquipmentSchoolMap[nSchoolID]
    assert(tSchoolEqu)  --不可能不存在，除非逻辑或者配置错误

    local tPartEquList = {}
    for nPartType, tPartData in pairs(tSchoolEqu) do 
        for nEquID, tConf in pairs(tPartData) do 
            if CKnapsack:CheckWearPermit(nRoleConfID, nLevel, nEquID) then 
                local nPreEquID = tPartEquList[nPartType]
                if not nPreEquID then 
                    tPartEquList[nPartType] = nEquID
                else 
                    local tPreConf = ctEquipmentConf[nPreEquID]
                    if tPreConf.nEquipLevel < tConf.nEquipLevel then 
                        tPartEquList[nPartType] = nEquID
                    end
                end
            end
        end
    end
    for nPartType, nEquID in pairs(tPartEquList) do 
        local nQuality = math.random(2, 4) --随机一个品质
        local tPropExt = {nQuality = nQuality}
        self.m_oKnapsack:AddItem(nEquID, 1, true, tPropExt)  --直接用背包的接口
    end
    self.m_oKnapsack:QuickWearEqu(self:GetLevel() + 1)
end

function CRobot:InitRobotPet()
    self.m_oPet:AddPetObj(3003, 1)  --TODO 设置宠物等级
end

function CRobot:InitRobotPartner()

    local fnGetWeight = function(tConf) return 100 end
    local tResult = CWeightRandom:Random(ctPartnerConf, fnGetWeight, 4, true)
    if not tResult or #tResult <= 0 then 
        return 
    end
    for _, tPartnerConf in pairs(tResult) do 
        self.m_oPartner:AddPartner(tPartnerConf.nID)
        self.m_oPartner:AutoBattleActive(tPartnerConf.nID)
    end
end

function CRobot:InitRobot(tParam)
    if self:IsMirror() then 
        return 
    end 
    self:InitRobotEquipment()
    self:InitRobotPet()
    self:InitRobotPartner()
    
    self:UpdateAttr()
end

function CRobot:IsRobot() return true end
function CRobot:IsMirror() --是否为玩家镜像 
    local nSrcID = self:GetSrcID()
    if nSrcID > 0 and GF.IsRobot(nSrcID) then 
        return false 
    end
    return true 
end
function CRobot:SaveData() end
function CRobot:SyncRoleLogic(bRelease) end
function CRobot:UpdateRoleSummary() end
function CRobot:SendMsg(sCmd, tMsg, nServer, nSession) end
function CRobot:AddItem(nItemType, nItemID, nItemNum, sReason, bRawExp, bBind, tPropExt) end
function CRobot:IsOnline() return self.m_bOnline end
function CRobot:SetOnline(bOnline)
    self.m_bOnline = bOnline and true or false
end
function CRobot:GetRobotType() return self.m_nRobotType end

function CRobot:Online(bReconnect) 
    CRole.Online(self, bReconnect)
    if not self:IsMirror() then 
        self:OnLevelChange(0, self:GetLevel())
    end
	self.m_oSysOpen:OpenAll()
    self.m_bOnline = true
    if self:GetNativeObj() and self:GetAOIID() > 0 then
        --防止CRole.Online上线过程中，切换了场景，或者直接销毁了机器人
        goLRobotMgr:AfterRobotOnline(self)
    end
end

function CRobot:OnEnterLogic()
    goLRobotMgr:OnEnterLogic(self)
    CRole.OnEnterLogic(self)
end

function CRobot:OnDisconnect()
    self.m_bOnline = false
    CRole.OnDisconnect(self)
end

function CRobot:Offline() 
    self.m_bOnline = false
    goLRobotMgr:OnRobotOffline(self)
    return CRole.Offline(self)  --注意，这里一定要返回，会根据返回值决定是否释放对象
end

function CRobot:OnRelease()
    goLRobotMgr:OnRobotRelease(self)
    CRole.OnRelease(self)
end

function CRobot:GetGlobalOnlineData(bRelease)
    local tData = CRole.GetGlobalOnlineData(self, bRelease)
    tData.m_nRobotType = self:GetRobotType()
    return tData
end

function CRobot:RegAutoSave() end --机器人不创建自动保存定时器

function CRobot:GetBattleData(bMirror)
    local tBattleData = CRole.GetBattleData(self, bMirror)
    if tBattleData then 
        tBattleData.bAuto = true
        tBattleData.bRobot = true
    end
    return tBattleData
end

function CRobot:OnReachTargetPos()
    -- print(string.format("机器人(%d)到达目标点", self:GetID()))
    goLRobotMgr:OnReachTargetPos(self) --方便全局管理

    local oDup = self:GetCurrDupObj()
    if oDup and self:GetAOIID() > 0 then 
        oDup:OnReachTargetPos(self)
    end
end

function CRobot:RandPVPActDupPos(tDupConf)
    assert(tDupConf)
    -- 随机坐标和面向
    local nXPosMin = math.min(tDupConf.nWidth, 200)  --避免地图长款不足200的异常情况
    local nXPosMax = math.max(nXPosMin, tDupConf.nWidth - 200)
    local nYPosMin = math.min(tDupConf.nHeight, 200)
    local nYPosMax = math.max(nYPosMin, tDupConf.nHeight - 200)

    local nFace = math.random(0, 3)
    local nXPos = math.random(nXPosMin, nXPosMax) --避免出生在地图边缘
    local nYPos = math.random(nYPosMin, nYPosMax)
    return nXPos, nYPos, nFace
end

function CRobot:IsTeamRobot()
    return self.m_nRobotType == gtRobotType.eTeam
end

function CRobot:GetRobotCreateStamp()
    return self.m_nRobotCreateStamp
end

