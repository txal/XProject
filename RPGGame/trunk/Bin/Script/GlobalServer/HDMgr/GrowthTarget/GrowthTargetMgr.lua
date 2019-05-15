--开服目标活动管理器

--策划要求各个活动的折扣商店统一，全部放在一处
function CGrowthTargetMgr:Ctor()
    self.m_oActShop = CGrowthTargetShop:new()
end

--在goHDMgr之后初始化
function CGrowthTargetMgr:Init()
    self.m_tActivityMap = {}
    setmetatable(self.m_tActivityMap, {__mode = "kv"}) --设置为虚表
	self.m_tActivityMap[gtHDDef.eGTEquStrength] = goHDMgr:GetActivity(gtHDDef.eGTEquStrength)
	self.m_tActivityMap[gtHDDef.eGTPetPower] = goHDMgr:GetActivity(gtHDDef.eGTPetPower)
	self.m_tActivityMap[gtHDDef.eGTPartnerPower] = goHDMgr:GetActivity(gtHDDef.eGTPartnerPower)
	self.m_tActivityMap[gtHDDef.eGTFormationLv] = goHDMgr:GetActivity(gtHDDef.eGTFormationLv)
	self.m_tActivityMap[gtHDDef.eGTEquGemLv] = goHDMgr:GetActivity(gtHDDef.eGTEquGemLv)
	self.m_tActivityMap[gtHDDef.eGTMagicEquPower] = goHDMgr:GetActivity(gtHDDef.eGTMagicEquPower)
	self.m_tActivityMap[gtHDDef.eGTDrawSpiritLv] = goHDMgr:GetActivity(gtHDDef.eGTDrawSpiritLv)
	self.m_tActivityMap[gtHDDef.eGTPetSkillPower] = goHDMgr:GetActivity(gtHDDef.eGTPetSkillPower)
	self.m_tActivityMap[gtHDDef.eGTPricticeLv] = goHDMgr:GetActivity(gtHDDef.eGTPricticeLv)
	self.m_tActivityMap[gtHDDef.eGTGodEquPower] = goHDMgr:GetActivity(gtHDDef.eGTGodEquPower)
	self.m_tActivityMap[gtHDDef.eGTTreasureSearchScore] = goHDMgr:GetActivity(gtHDDef.eGTTreasureSearchScore)
	self.m_tActivityMap[gtHDDef.eGTArenaScore] = goHDMgr:GetActivity(gtHDDef.eGTArenaScore)
	self.m_tActivityMap[gtHDDef.eGTPersonUnionContri] = goHDMgr:GetActivity(gtHDDef.eGTPersonUnionContri)
	self.m_tActivityMap[gtHDDef.eGTDrawSpiritScore] = goHDMgr:GetActivity(gtHDDef.eGTDrawSpiritScore)
    self.m_tActivityMap[gtHDDef.eGTDressPower] = goHDMgr:GetActivity(gtHDDef.eGTDressPower)
    
    self:LoadData()

    self.m_nTimer = goTimerMgr:Interval(60, function() self:OnMinuTimer() end)
end

function CGrowthTargetMgr:OnReload()
    self.m_oActShop:ConfInit()
end

function CGrowthTargetMgr:LoadData()
    self.m_oActShop:LoadData()
end

function CGrowthTargetMgr:SaveData()
    self.m_oActShop:SaveData()
end

function CGrowthTargetMgr:OnMinuTimer()
    self.m_oActShop:OnMinuTimer()
    self:SaveData()
end

function CGrowthTargetMgr:OnActStart(nActID)
    self.m_oActShop:OnActStart(nActID)
end

function CGrowthTargetMgr:OnActAward(nActID)
    self.m_oActShop:OnActAward(nActID)
end

function CGrowthTargetMgr:OnActClose(nActID) 
    self.m_oActShop:OnActClose(nActID)
end

function CGrowthTargetMgr:OnRelease()
    goTimerMgr:Clear(self.m_nTimer)
    self:SaveData()
end

function CGrowthTargetMgr:GetActivity(nActID)
    return self.m_tActivityMap[nActID]
end

function CGrowthTargetMgr:GetOpenActList()
    local tList = {}
    for nActID, oAct in pairs(self.m_tActivityMap) do 
        if oAct:IsOpen() then 
            table.insert(tList, nActID)
        end
    end
    return tList
end

function CGrowthTargetMgr:GetActList() 
    local tActList = {}
    for nActID, oAct in pairs(self.m_tActivityMap) do 
        table.insert(tActList, nActID)
    end
    return tActList
end

function CGrowthTargetMgr:SyncActInfo(oRole, nActID)
    local nRoleID = oRole:GetID()
    if nActID <= 0 then 
        oRole:Tips("参数错误")
        return 
    end
    local oAct = self:GetActivity(nActID)
    if not oAct then 
        oRole:Tips("活动不存在")
        return 
    end
    oAct:SyncActInfo(oRole)
end

function CGrowthTargetMgr:SyncActInfoList(nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole or not oRole:IsOnline() then 
        return 
    end
    local tActInfoList = {}
    local tActIDList = self:GetActList()
    for _, nActID in ipairs(tActIDList) do 
        local oAct = goHDMgr:GetActivity(nActID)
        if oAct and oAct:IsActive() then 
            table.insert(tActInfoList, oAct:GetActInfo(nRoleID))
        end
    end

    local tMsg = {}
    tMsg.tActInfoList = tActInfoList
    oRole:SendMsg("GrowthTargetActInfoListRet", tMsg)
end

--检查哪些活动，玩家没有活动数据，通知刷新玩家活动数据
function CGrowthTargetMgr:TriggerRoleActInfo(oRole, fnCallback)
    if oRole:IsRobot() then 
        return 
    end
    --暂时硬编码 不需要触发主动更新的数据
    --即增量更新数据的活动类型
    local tFilterMap = 
    {
        [111] = true, 
        [113] = true,
        [114] = true,
    }
    local tActTriggerList = {}
    for nActID, oAct in pairs(self.m_tActivityMap) do 
        if not tFilterMap[nActID] then 
            if oAct:IsOpen() and not oAct:IsJoinAct(oRole:GetID()) then
                table.insert(tActTriggerList, nActID)
            end 
        end
    end
    if #tActTriggerList <= 0 then 
        fnCallback()
        return 
    end
    oRole:TriggerGrowthTargetActData(tActTriggerList)
    local nServer = oRole:GetServer()
    goRemoteCall:CallWait("TriggerGrowthTargetActDataReq", fnCallback, oRole:GetServer(), 
        oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), tActTriggerList)
end

function CGrowthTargetMgr:TargetAwardReq(oRole, nActID, nRewardID)
    local oAct = self:GetActivity(nActID)
    if not oAct or not oAct:IsActive() then 
        oRole:Tips("活动未开启")
        return 
    end
    oAct:TargetAwardReq(oRole, nRewardID)
end

function CGrowthTargetMgr:RankingAwardReq(oRole, nActID)
    local oAct = self:GetActivity(nActID)
    if not oAct or not oAct:IsActive() then 
        oRole:Tips("活动未开启")
        return 
    end
    oAct:RankingAwardReq(oRole)
end

function CGrowthTargetMgr:RechargeAwardReq(oRole, nActID, nRewardID)
    local oAct = self:GetActivity(nActID)
    if not oAct or not oAct:IsActive() then 
        oRole:Tips("活动未开启")
        return 
    end
    oAct:RechargeAwardReq(oRole, nRewardID)
end

function CGrowthTargetMgr:ActRankInfoReq(oRole, nActID, nPageID)
    if not oRole or not oRole:IsOnline() then 
        return 
    end
    local nRoleID = oRole:GetID()
    local oAct = self:GetActivity(nActID)
    if not oAct or not oAct:IsActive() then 
        oRole:Tips("活动未开启")
        return 
    end
    oAct:SyncRankInfo(oRole, nPageID)
end

function CGrowthTargetMgr:SyncActShop(oRole)
    self.m_oActShop:SyncShopInfo(oRole)
end

function CGrowthTargetMgr:ActShopPurchaseReq(oRole, nIndexID, nNum)
    self.m_oActShop:PurchaseItemReq(oRole, nIndexID, nNum)
end

goGrowthTargetMgr = goGrowthTargetMgr or CGrowthTargetMgr:new()
goGrowthTargetMgr:OnReload()

