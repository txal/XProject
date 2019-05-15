--称谓功能
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function  CAppellationBox:Ctor(oRole)
    self.m_oRole = oRole
    self.m_nSerialID = 1    --称号序列号，每个角色独立，用于维护区分同称号ID的不同称号，
    --比如情缘、结拜等称号，每次登录重置
    self.m_tAppellationObjMap = {}   --称号map {nID:oAppellationObj, ...}
    self.m_tConfIDMap = {}           --不存DB，为了避免后期迭代称号过多，用于快速根据配置查找称号{nConfID:{nID:nSubKey ...}, ...}
    
    self.m_nAttrAppeID = 0           --当前激活属性的称谓ID
    self.m_tDisplay = nil    --当前显示的称号，策划要求玩家称号失效消失后，玩家下线或者主动修改称号前，仍然保留显示该称号
    self.m_tTempDisplay = nil  --临时显示，用于某些活动状态，临时强制显示，一般和场景关联，不存DB
    self.m_bDirty = false
end

function CAppellationBox:InsertAppellationObj(oObj)
    assert(oObj)
    local nID = oObj:GetID()
    local nConfID = oObj:GetConfID()
    local nSubKey = oObj:GetSubKey()
    local nOldAppeID = self:GetAppellationObjID(nConfID, nSubKey)
    if nOldAppeID and nOldAppeID > 0 then 
        --某些限时称号，因为失效检查等，存在延迟情况，此时并没有被移除，然后又添加了新的称号
        --比如竞技场称号，某个玩家，连续2个赛季都获得了某个竞技场称号，但是，因为检查延迟
        --竞技场结算时，通知添加第二个赛季获得的相同称号时，此时，第一个赛季的称号，还存在
        --PVP活动奖励称号也存在此类问题
        --称号应当具有唯一性，不考虑同时存在新旧2个相同称号的情况的需求。
        --如果策划有此类需求，建议策划配置成2个名字显示一样但配置不同的称号
        self:RemoveAppellation(nOldAppeID) 
    end
    assert(nID > 0 and nConfID > 0)
    if self.m_tAppellationObjMap[nID] then 
        assert(false, "称号已存在, ID:"..nID)
    end
    self.m_tAppellationObjMap[nID] = oObj
    local tConfIDTbl = self.m_tConfIDMap[nConfID]
    if not tConfIDTbl then 
        tConfIDTbl = {}
        self.m_tConfIDMap[nConfID] = tConfIDTbl
    end
    tConfIDTbl[nID] = oObj:GetSubKey()   --不保存称号引用，避免多处地方引用对象
    self:MarkDirty(true)
end

function CAppellationBox:SaveData()
    if not self:IsDirty() then 
        return
    end
    local tData = {}
    tData.nSerialID = self.m_nSerialID
    tData.tAppellationObj = {}
    for k, oObj in pairs(self.m_tAppellationObjMap) do 
        local tObjData = oObj:SaveData()
        tData.tAppellationObj[oObj:GetID()] = tObjData
    end
    if self.m_tDisplay then 
        tData.tDisplay = self.m_tDisplay:SaveData()
    end
    tData.nAttrAppeID = self.m_nAttrAppeID
    self:MarkDirty(false)
    return tData
end

function CAppellationBox:LoadData(tData)
    if not tData then 
        return 
    end
    self.m_nSerialID = tData.nSerialID or 1
    for nID, tObjData in pairs(tData.tAppellationObj) do 
        if ctAppellationConf[tObjData.nConfID] then 
            local oTempObj = self:CreateAppellation(nID, tObjData.nConfID, {}, tObjData.nSubKey)
            oTempObj:LoadData(tObjData)
            -- if not oTempObj:IsExpired() then 
            --     self:InsertAppellationObj(oTempObj)
            -- else
            --     self:MarkDirty(true)
            -- end
            -- 这里不处理，可能切换场景引发角色本地数据不正确
            self:InsertAppellationObj(oTempObj)
        else 
            LuaTrace(string.format("玩家(%d)(%s)称谓(%d)在称谓配置表中不存在，已删除", 
            self.m_oRole:GetID(), self.m_oRole:GetName(), tObjData.nConfID)) 
            self:MarkDirty(true)
        end
    end
    --玩家切换逻辑服等，要求仍然保留已被删除的称号显示，所以
    --先查找旧的是否存在 如果存在，引用旧对象
    if tData.tDisplay then 
        local tDisplay = tData.tDisplay
        local nDisplayID = tDisplay.nID
        local oAppellationObj = self:GetAppellationObj(nDisplayID)
        if oAppellationObj then 
            self:SetDisplayAppellation(oAppellationObj)
        else
            --旧的被删除了，构建一个临时的
            -- local oTempObj = self:CreateAppellation(nDisplayID, tDisplay.nConfID, {}, tDisplay.nSubKey)
            -- oTempObj:LoadData(tDisplay)
            -- self:SetDisplayAppellation(oTempObj)
            self:SetDisplayAppellation()
        end
    end
    self.m_nAttrAppeID = tData.nAttrAppeID or 0
    if not self:GetAppellationObj(self.m_nAttrAppeID) then 
        self.m_nAttrAppeID = 0
    end
end

--每次角色登录，都重新初始化一下ID，避免特殊情况下，一直增长下去
--不能放在load中，切换逻辑服等，也会导致变化，最终导致和客户端本地缓存数据不一致
function CAppellationBox:Online()

    --获取保存下旧的显示称号数据
    local nDisplayConfID = nil
    local nDisplaySubKey = nil
    local oOldDisplayObj = self:GetDisplayAppellation()
    if oOldDisplayObj then 
        local nOldDisplayID = oOldDisplayObj:GetID()
        --继续比对下现有称号，可能存在玩家上一次下线前，先失去，再获得，导致存在配置ID和SubKey一样，但是ID不一样
        if nOldDisplayID and nOldDisplayID > 0 then 
            --直接查找玩家列表，如果不存在，说明称号失效被删除了
            local oDisplayObj = self:GetAppellationObj(nOldDisplayID)
            if oDisplayObj then 
                nDisplayConfID = oDisplayObj:GetConfID()
                nDisplaySubKey = oDisplayObj:GetSubKey()
            end
        end
    end

    local nAttrAppeConfID = nil
    local nAttrAppeSubKey = nil
    local oAttrAppe = self:GetAppellationObj(self.m_nAttrAppeID)
    if oAttrAppe then 
        nAttrAppeConfID = oAttrAppe:GetConfID()
        nAttrAppeSubKey= oAttrAppe:GetSubKey()
    end

    --重新设置玩家称号的ID
    self.m_nSerialID = 1
    local tOldAppellation = self.m_tAppellationObjMap
    self.m_tAppellationObjMap = {}
    self.m_tConfIDMap = {}
    for nID, oObj in pairs(tOldAppellation) do 
        if not oObj:IsExpired() then --过滤失效的称谓
            local nNewID = self:GenID()
            oObj.m_nID = nNewID
            self:InsertAppellationObj(oObj)
        end
    end

    --设置下新的显示称号
    if nDisplayConfID and nDisplaySubKey then 
        local nNewDisplayID = self:GetAppellationObjID(nDisplayConfID, nDisplaySubKey)
        if nNewDisplayID and nNewDisplayID > 0 then 
            local oNewDisplayObj = self:GetAppellationObj(nNewDisplayID)
            self:SetDisplayAppellation(oNewDisplayObj)
        else
            self:SetDisplayAppellation()
            self:MarkDirty(true)
        end
    else
        self:SetDisplayAppellation()  --nil
    end
    if nAttrAppeConfID and nAttrAppeSubKey then 
        local nNewAttrAppeID = self:GetAppellationObjID(nAttrAppeConfID, nAttrAppeSubKey)
        self.m_nAttrAppeID = nNewAttrAppeID or 0
        if self.m_nAttrAppeID < 1  then 
            self.m_oRole:UpdateAttr()
            self:MarkDirty(true)
        end
    end
    self:SyncDisplayAppellation()
end

function CAppellationBox:MarkDirty(bDirty)
    self.m_bDirty = bDirty
end
function CAppellationBox:IsDirty() return self.m_bDirty end
function CAppellationBox:GetType() 
    return gtModuleDef.tAppellation.nID, gtModuleDef.tAppellation.sName
end
function CAppellationBox:GenID()
    self.m_nSerialID = self.m_nSerialID % 0x7fffffff + 1
    self:MarkDirty(true)
    return self.m_nSerialID
end

function CAppellationBox:SetDisplayAppellation(oAppellationObj) 
    self.m_tDisplay = oAppellationObj
end

--请注意，这个获取到可能是一个临时称号数据
function CAppellationBox:GetDisplayAppellation() 
    if self.m_tTempDisplay then 
        return self.m_tTempDisplay
    end
    return self.m_tDisplay 
end

--设置临时显示称谓
function CAppellationBox:SetTempDisplayAppellation(oAppe)
    self.m_tTempDisplay = oAppe
    self.m_oRole:FlushRoleView()
end

function CAppellationBox:IsDisplay() 
    if self.m_tDisplay then 
        return true
    end
    return false 
end

--{nConfID, tNameParam}
--场景同步PB协议数据，称号应当是个optional数据
function CAppellationBox:GetSceneDisplayData()
    local oAppe = self:GetDisplayAppellation()
    if not oAppe then 
        return 
    end
    local tData = {}
    tData.nConfID = oAppe:GetConfID()
    tData.tNameParam = table.DeepCopy(oAppe:GetNameParam())
    return tData
end

function CAppellationBox:GetAppellationObjID(nConfID, nSubKey)
    assert(nConfID > 0)
    nSubKey = nSubKey or 0
    local tConf = ctAppellationConf[nConfID]
    if not tConf.bMulti then --强制置0
        nSubKey = 0
    end

    local tConfIDTbl = self.m_tConfIDMap[nConfID]
    if not tConfIDTbl then 
        return 
    end
    if not next(tConfIDTbl) then 
        return 
    end
    local tTar = nil
    for nID, nKey in pairs(tConfIDTbl) do 
        if nKey == nSubKey then 
            return nID
        end
    end
    return 
end

function CAppellationBox:GetAppellationObj(nID) return self.m_tAppellationObjMap[nID] end
function CAppellationBox:GetAppellationByConfIDAndSubKey(nConfID, nSubKey)
    local nAppeID = self:GetAppellationObjID(nConfID, nSubKey)
    if not nAppeID or nAppeID <= 0 then 
        return 
    end
    return self:GetAppellationObj(nAppeID)
end

-- [tParam] {tNameParam=, nTimeStamp=, }
function CAppellationBox:CreateAppellation(nID, nConfID, tParam, nSubKey)
    assert(nID and nConfID)
    local tConf = ctAppellationConf[nConfID]
    assert(tConf)
    local CAppe = gtAppellationClass[tConf.nType]
    assert(CAppe, "称号未实现")
    if tConf.bMulti then 
        --对于可重复添加的，必须提供nSubKey且nSubKey > 0
        assert(nSubKey and nSubKey > 0)
    else
        nSubKey = 0
    end
    tParam = tParam or {}
    nSubKey = nSubKey or 0
    local tObj = CAppe:new(self, nID, nConfID, tParam, nSubKey)
    return tObj
end

function CAppellationBox:OnAppellationAdd(nAppeID, bTips)
    if bTips then 
        local oAppe = self:GetAppellationObj(nAppeID)
        assert(oAppe)
        local oDisplayAppe = self:GetDisplayAppellation()
        if not oDisplayAppe then 
            self:DisplayReq(nAppeID) 
        else
            local fnConfirmCallback = function(tData) 
                if tData.nSelIdx == 1 then  --取消
                    return
                elseif tData.nSelIdx == 2 then  --确定
                    self:DisplayReq(nAppeID) 
                end
            end
            local sCont = "您是否需要装备当前获得的称谓？"
            local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=15}
            goClientCall:CallWait("ConfirmRet", fnConfirmCallback, self.m_oRole, tMsg)
        end
    end
end

-- nSubKey 没有的直接填0或者不填，情缘、结拜等称号，用的对方的角色ID做nSubKey
function CAppellationBox:AddAppellation(nConfID, tParam, nSubKey, sReason, tExtData)
    assert(nConfID)
    tParam = tParam or {}
    if type(tParam) ~= "table" then 
        LuaTrace("添加称谓失败，数据错误", tParam)
        LuaTrace(debug.traceback())
        return 
    end
    local tConf = ctAppellationConf[nConfID]
    if not tConf then 
        LuaTrace(string.format("角色ID(%d)名称(%s)称谓ID(%d)", self.m_oRole:GetID(), 
            self.m_oRole:GetName(), nConfID))
        LuaTrace("tParam", tParam)
        LuaTrace("nSubKey", nSubKey)
        LuaTrace("sReason", sReason)
        assert(false, "称谓配置不存在")
    end
    if not tConf.bMulti then
        nSubKey = 0  --强制置0
    end 

    local bTips = true  
    if tExtData and tExtData.bNotTips then 
        bTips = false 
    end

    local nNewID = self:GenID()
    local oObj = self:CreateAppellation(nNewID, nConfID, tParam, nSubKey)
    --为了保持外层逻辑完整性，在这里需要检查是否已过期，已过期不添加
    --比如某些限时称号，通过邮件发放，以邮件发放时间为开始计时时间戳，玩家长时间未领取，已在邮件过期
    local nEventID = gtEvent.eAddItem
    sReason = sReason or "称谓系统"
    if oObj:IsExpired() then
        -- self.m_oRole:Tips("称号已过期") 
        print("称谓已过期")
        goLogger:AwardLog(nEventID, sReason, self.m_oRole, gtItemType.eAppellation, nConfID, 1, false)
        return 
    end
    self:InsertAppellationObj(oObj)
    self:AppellationAddNotify(nNewID)
    self:MarkDirty(true)
    goLogger:AwardLog(nEventID, sReason, self.m_oRole, gtItemType.eAppellation, nConfID, 1, true)
    self:OnAppellationAdd(nNewID, bTips)
    return true
end

function CAppellationBox:UpdateAppellation(nConfID, tParam, nSubKey)
    local nID = self:GetAppellationObjID(nConfID, nSubKey)
    if not nID or nID <= 0 then 
        -- print("找不到玩家称号", nConfID, nSubKey)
        return 
    end
    local oObj = self:GetAppellationObj(nID)
    if not oObj then 
        print("找不到玩家称号, ID:", nID)
        return
    end
    oObj:Update(tParam)
    self:OnAppellationUpdate(oObj:GetID())
    self:MarkDirty(true)
    self:AppellationUpdateNotify(nID)
end

function CAppellationBox:OnAppellationUpdate(nID)
    local oDisplayObj = self:GetDisplayAppellation()
    if oDisplayObj and oDisplayObj:IsEquiped() then 
        self.m_oRole:FlushRoleView()
    end
end

function CAppellationBox:RemoveAppellation(nID, sReason)
    assert(nID > 0)
    sReason = sReason or "称谓失效"
    local oAppellationObj = self:GetAppellationObj(nID)
    if not oAppellationObj then 
        return
    end
    local nConfID = oAppellationObj:GetConfID()
    self.m_tAppellationObjMap[nID] = nil
    local tConfIDTbl = self.m_tConfIDMap[nConfID]
    if tConfIDTbl then 
        tConfIDTbl[nID] = nil
    end

    local oDisplayObj = self:GetDisplayAppellation()
    if oDisplayObj and oDisplayObj:GetID() == nID then 
        self:SetDisplayAppellation()
        self:SyncDisplayAppellation()
        self.m_oRole:Tips("装备的称谓已失效")
        self.m_oRole:FlushRoleView()
    end
    if nID == self.m_nAttrAppeID then 
        self.m_nAttrAppeID = 0
        self.m_oRole:UpdateAttr()
    end
    self:MarkDirty(true)
    self:AppellationRemoveNotify(nID)

    goLogger:AwardLog(gtEvent.eSubItem, sReason, self.m_oRole, gtItemType.eAppellation, nConfID, 1, true)
    return true
end

function CAppellationBox:RemoveAppellationBySubKey(nConfID, nSubKey, sReason)
    print(string.format("nConfID (%d), nSubKey (%d)", nConfID, nSubKey))
    local nID = self:GetAppellationObjID(nConfID, nSubKey)
    if not nID then 
        return 
    end
    self:RemoveAppellation(nID, sReason)
end

function CAppellationBox:Update(nOp, nConfID, tParam, nSubKey, sReason, tExtData)
    if nOp == gtAppellationOpType.eAdd then 
        self:AddAppellation(nConfID, tParam, nSubKey, sReason, tExtData)
    elseif nOp == gtAppellationOpType.eUpdate then 
        self:UpdateAppellation(nConfID, tParam, nSubKey)
    elseif nOp == gtAppellationOpType.eRemove then 
        self:RemoveAppellationBySubKey(nConfID, nSubKey, sReason)
    else
        LuaTrace("不受支持的称号操作类型", nOp)
    end
end

function CAppellationBox:OnMinTimer()
    -- do something
end

--同步称号模块数据
function CAppellationBox:SyncAppellationData()
    self:CheckExpired()
    local tMsg = {}
    tMsg.tAppellationList = {}
    for k, oObj in pairs(self.m_tAppellationObjMap) do 
        local tTemp = oObj:GetPBData()
        if tTemp then 
            table.insert(tMsg.tAppellationList, tTemp)
        end
    end
    local oDisplayObj = self:GetDisplayAppellation()
    if oDisplayObj then 
        local tTemp = oDisplayObj:GetPBData()
        if tTemp then 
            tMsg.tDisplay = tTemp
        end
    end
    tMsg.nAttrAppeID = 
    self.m_oRole:SendMsg("AppellationDataRet", tMsg)
end

function CAppellationBox:SyncDisplayAppellation(bActive)
    local tMsg = {}
    local oDisplayObj = self:GetDisplayAppellation()
    if oDisplayObj then 
        local tTemp = oDisplayObj:GetPBData()
        if tTemp then 
            tMsg.tAppellation = tTemp
        end
    end
    tMsg.bActive = bActive and true or false
    self.m_oRole:SendMsg("AppellationDisplayRet", tMsg)
end

function CAppellationBox:AppellationAddNotify(nID)
    assert(nID)
    local oAppellationObj = self:GetAppellationObj(nID)
    if not oAppellationObj then 
        return 
    end
    local tMsg = {}
    tMsg.tAppellation = oAppellationObj:GetPBData()
    self.m_oRole:SendMsg("AppellationAddRet", tMsg)
end

function CAppellationBox:AppellationUpdateNotify(nID)
    assert(nID)
    local oAppellationObj = self:GetAppellationObj(nID)
    if not oAppellationObj then 
        return 
    end
    local tMsg = {}
    tMsg.tAppellation = oAppellationObj:GetPBData()
    self.m_oRole:SendMsg("AppellationUpdateRet", tMsg)
end

function CAppellationBox:AppellationRemoveNotify(nID)
    local tMsg = {}
    tMsg.nID = nID
    self.m_oRole:SendMsg("AppellationRemoveRet", tMsg)
end

--设置当前显示称号
function CAppellationBox:DisplayReq(nID)
    assert(nID)
    if nID <= 0 then 
        self:SetDisplayAppellation()
    else
        local oAppellationObj = self:GetAppellationObj(nID)
        if not oAppellationObj then 
            return self.m_oRole:Tips("称号不存在")
        end
        self:SetDisplayAppellation(oAppellationObj)
    end
    self:MarkDirty(true)
    self.m_oRole:FlushRoleView()
    self:SyncDisplayAppellation(true)
end

function CAppellationBox:RemoveAllUnionAppellation()
    local tRemoveList = {}
    for k, oAppeObj in pairs(self.m_tAppellationObjMap) do 
        if oAppeObj:GetType() == gtAppellationType.eUnionPos then 
            table.insert(tRemoveList, oAppeObj:GetID())
        end
    end
    for k, nTempID in ipairs(tRemoveList) do 
        self:RemoveAppellation(nTempID, "更新帮会称号")
    end
end

function CAppellationBox:UpdateUnionAppellation(nAppeConfID, tParam, nSubKey)
    if nAppeConfID <= 0 then 
        self:RemoveAllUnionAppellation()
    else
        local nAppeID = self:GetAppellationObjID(nAppeConfID, nSubKey)
        if not nAppeID then 
            self:RemoveAllUnionAppellation()
            self:AddAppellation(nAppeConfID, tParam, nSubKey)
        else
            self:UpdateAppellation(nAppeConfID, tParam, nSubKey)
        end 
    end
end

function CAppellationBox:RemoveAllArenaAppellation()
    local tRemoveList = {}
    for k, oAppe in pairs(self.m_tAppellationObjMap) do 
        if oAppe:GetType() == gtAppellationType.eArena then 
            table.insert(tRemoveList, 
                {nConfID = oAppe:GetConfID(), nSubKey = oAppe:GetSubKey()})
        end
    end
    for k, v in ipairs(tRemoveList) do 
        self:RemoveAppellationBySubKey(v.nConfID, v.nSubKey, "竞技场称谓更新")
    end
end

function CAppellationBox:UpdateArenaAppellation(nAppeConfID, tParam, nSubKey)
    if nAppeConfID <= 0 then 
        self:RemoveAllArenaAppellation()
    else
        local nAppeID = self:GetAppellationObjID(nAppeConfID, nSubKey)
        if not nAppeID then 
            self:RemoveAllArenaAppellation()
            self:AddAppellation(nAppeConfID, tParam, nSubKey)
        end  --已经存在此称号，不处理
    end
end

function CAppellationBox:CheckExpired()
    local tRemoveList = {}
    local nCurTime = os.time()
    for k, oAppe in pairs(self.m_tAppellationObjMap) do 
        if oAppe:IsExpired(nCurTime) then 
            table.insert(tRemoveList, 
                {nConfID = oAppe:GetConfID(), nSubKey = oAppe:GetSubKey()})
        end
    end
    for k, v in ipairs(tRemoveList) do 
        self:RemoveAppellationBySubKey(v.nConfID, v.nSubKey, "称谓过期")
    end
end

function CAppellationBox:GetBattleAttr()
    if self.m_nAttrAppeID <= 0 then 
        return {}
    end
    local oAppe = self:GetAppellationObj(self.m_nAttrAppeID)
    if not oAppe then 
        return {}
    end
    return oAppe:GetBattleAttr()
end

function CAppellationBox:AttrSetReq(nID)
    if not nID or nID < 0 then 
        self.m_oRole:Tips("不合法的称谓")
        return 
    end
    if nID > 0 then 
        if self.m_nAttrAppeID == nID then 
            self.m_oRole:Tips("当前已激活该称谓属性")
            return 
        end
        local oAppe = self:GetAppellationObj(nID)
        if not oAppe then 
            self.m_oRole:Tips("称谓不存在")
            return 
        end
        local tAttrList = oAppe:GetBattleAttr()
        if not tAttrList or not next(tAttrList) then 
            self.m_oRole:Tips("该称谓没有属性")
            return 
        end
    else
        if self.m_nAttrAppeID == 0 then 
            self.m_oRole:Tips("当前未激活称谓属性")
            return 
        end
    end
    local nOldAppeID = self.m_nAttrAppeID
    self.m_nAttrAppeID = nID
    self.m_oRole:UpdateAttr()

    local tMsg = {}
    tMsg.nID = nID
    tMsg.nOldID = nOldAppeID
    self.m_oRole:SendMsg("AppellationAttrSetRet", tMsg)
end

