local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRole:Ctor(oAccount, nID)
    ------不保存------
    self.m_bDirty = false
    self.m_oAccount = oAccount

    ------保存--------
    self.m_nID = nID
    self.m_nCreateTime = 0
    self.m_nOnlineTime = 0
    self.m_nOfflineTime = 0

    self.m_sName = ""
    self.m_nGender = 0
    self.m_nSchool = 0
    self.m_nLevel = 0
    self.m_nCity = 0
    self.m_nDup = 0

    ------其他--------
    self.m_tModuleMap = {}  --映射
    self.m_tModuleList = {} --有序
    self:LoadSelfData() --这里先加载角色数据,子模块可能要用到角色数据
    self:CreateModules()
    self:LoadModuleData()

end

function CRole:OnRelease()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:OnRelease()
    end
end

--创建各个子模块
function CRole:CreateModules()
    self.m_oVIP = CVIP:new(self)
    self:RegisterModule(self.m_oVIP)
end

function CRole:RegisterModule(oModule)
	local nModuleID = oModule:GetType()
	assert(not self.m_tModuleMap[nModuleID], "重复注册模块:"..nModuleID)
	self.m_tModuleMap[nModuleID] = oModule
    table.insert(self.m_tModuleList, oModule)
end

--加载角色数据
function CRole:LoadSelfData()
    local nServer, nID = self:GetServer(), self:GetID()
    local sData = goDBMgr:GetSSDB(nServer, "user", nID):HGet(gtDBDef.sRoleDB, nID)
    if sData == "" then 
        return self:MarkDirty(true)
    end
    local tData = cjson.decode(sData)

    self.m_nOnlineTime = tData.m_nOnlineTime
    self.m_nOfflineTime = tData.m_nOfflineTime
    self.m_nCreateTime = tData.m_nCreateTime

    self.m_nID = tData.m_nID
    self.m_sName = tData.m_sName
    self.m_nGender = tData.m_nGender
    self.m_nSchool = tData.m_nSchool
    self.m_nLevel = tData.m_nLevel

end

--保存角色数据
function CRole:SaveSelfData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}

    tData.m_nOnlineTime = self.m_nOnlineTime
    tData.m_nOfflineTime = self.m_nOfflineTime
    tData.m_nCreateTime = self.m_nCreateTime

    tData.m_nID = self.m_nID
    tData.m_sName = self.m_sName
    tData.m_nGender = self.m_nGender
    tData.m_nSchool = self.m_nSchool
    tData.m_nLevel = self.m_nLevel


    local nServer, nID = self:GetServer(), self:GetID()
    goDBMgr:GetSSDB(nServer, "user", nID):HSet(gtDBDef.sRoleDB, nID, cjson.encode(tData))
end

--加载子模块数据
function CRole:LoadModuleData()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local _, sModuleName = oModule:GetType()
        local nServer, nID = self:GetServer(), self:GetID()
        local sData = goDBMgr:GetSSDB(nServer, "user", nID):HGet(sModuleName, nID)
        if sData ~= "" then
            oModule:LoadData(cjson.decode(sData))
        else
            oModule:LoadData()
        end
    end
    self:OnLoaded()
end

--保存子模块数据
function CRole:SaveModuleData()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local tData = oModule:SaveData()
        if tData and next(tData) then
            local _, sModuleName = oModule:GetType()
            local nServer, nID = self:GetServer(), self:GetID()

            goDBMgr:GetSSDB(nServer, "user", nID):HSet(sModuleName, nID, cjson.encode(tData))
            print("save module:", sModuleName, "len:", string.len(sData))
        end
    end
end

--保存所有数据
function CRole:SaveData()
    local nBegClock = os.clock()
    self:SaveSelfData()
    self:SaveModuleData()
    local nCostTime = os.clock() - nBegClock
    LuaTrace("------save------", self:GetID(), self:GetName(), "time:", string.format("%.4f", nCostTime))
end

--加载所有数据完成
function CRole:OnLoaded()
end

function CRole:IsDirty() return self.m_bDirty end
function CRole:MarkDirty(bDirty) self.m_bDirty = bDirty end

function CRole:GetID() return self.m_nID end
function CRole:GetName() return self.m_sName end
function CRole:GetGender() return self.m_nGender end
function CRole:GetSchool() return self.m_nSchool end
function CRole:GetLevel() return self.m_nLevel end
function CRole:GetServer() return self.m_oAccount:GetServer() end
function CRole:GetSession() return self.m_oAccount:GetSession() end
function CRole:GetAccountID() return self.m_oAccount:GetID() end
function CRole:GetAccountName() return self.m_oAccount:GetName() end
function CRole:GetVIP() return self.m_oAccount:GetVIP() end
function CRole:GetCreateTime() return self.m_nCreateTime end
function CRole:GetOnlineTime() return self.m_nOnlineTime end
function CRole:GetOfflineTime() return self.m_nOfflineTime end
function CRole:GetLogic() GlobalExport.GetServiceID() end --当前所在逻辑服ID

--取角色身上的装备
function CRole:GetEquipment()
    --fix pd
end

--同步货币
function CRole:SyncCurrency(nType, nValue)
    assert(nType and nValue, "参数错误")
    CmdNet.PBSrv2Clt("RoleCurrencyRet", self:GetServer(), self:GetSession(), {nType=nType, nValue=nValue})
end

--同步角色初始数据
function CRole:SyncInitData()
    local tMsg = {}
    tMsg.nRoleID = self.m_nID
    tMsg.sRoleName = self.m_sName
    tMsg.nVIP = self:GetVIP()

    CmdNet.PBSrv2Clt("RoleInitDataRet", self:GetServer(), self:GetSession(), tMsg)
end 

--同步角色上下线到GLOBAL
function CRole:GlobalRoleOnline(bOnline)
    local tRole = nil
    if bOnline then
        tRole = {}
        tRole.m_nServer = self:GetServer()
        tRole.m_nSession = self:GetSession()

        tRole.m_nID = self.m_nID
        tRole.m_sName = self.m_sName
        tRole.m_nAccountID = self:GetAccountID()
        tRole.m_sAccountName = self:GetAccountName()
        tRole.m_nCreateTime = self:GetCreateTime()
        tRole.m_nLevel = self:GetLevel()
        tRole.m_nVIP = self:GetVIP()
    end
    --本服GLOBAL
    for _, tConf in pairs(gtServerConf.tGlobalService) do
        goRemoteCall:Call("GRoleOnlineReq", tConf.nServer, tConf.nID, self:GetSession(), bOnline, tRole)
    end
    --世界服GLOBAL
    for _, tConf in pairs(gtWorldConf.tGlobalService) do
        goRemoteCall:Call("GRoleOnlineReq", tConf.nServer, tConf.nID, self:GetSession(), bOnline, tRole)
    end
end


--角色上线
function CRole:Online()
    print("CRole:Online***", self:GetAccountName(), self:GetName())
    self.m_nOnlineTime = os.time()
    self:MarkDirty(true)
    self:GlobalRoleOnline(true)
end

--前端准备好了
function CRole:ClientReady()
    --各模块上线(可能有依赖关系所以用list)
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:Online()
    end
    self:SyncInitData()
end

--角色下线
function CRole:Offline()
    self.m_nOfflineTime = os.time()
    self:MarkDirty(true)

    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:Offline()
    end
    self:SaveData()
    self:GlobalRoleOnline(false)
end

--物品数量
function CRole:GetItemCount(nItemType, nItemID)
    if nItemType == gtItemType.eProp then
        local tConf = assert(ctPropConf[nItemID], "道具不存在:"..nItemID)
        if tConf.nType == gtPropType.eCurr then
            return self:GetItemCount(gtItemType.eCurr, tConf.nSubType)
        else
            return self.m_oGuoKu:GetItemCount(nItemID)
        end

    elseif nItemType == gtItemType.eCurr then
        if nItemID == gtCurrType.eYuanBao then
            return self:GetYuanBao()

        else
            assert(false, "不支持货币类型:"..nItemID)
        end

    else
        assert(false, "不支持物品类型:"..nItemType)

    end
end

--扣除物品
function CRole:SubItem(nItemType, nItemID, nItemNum, sReason)
    assert(sReason, "扣除物品原因缺失")
    if not (nItemType > 0 and nItemID > 0 and nItemNum >= 0) then
        return self:Tips("参数错误")
    end
    if nItemNum == 0 then
        return
    end
    return self:AddItem(nItemType, nItemID, -nItemNum, sReason)
end

--添加物品
function CRole:AddItem(nItemType, nItemID, nItemNum, sReason)
    assert(sReason, "添加物品原因缺失")
    if not (nItemType > 0 and nItemID > 0 and nItemNum) then
        return self:Tips("参数错误")
    end
    if nItemNum == 0 then
        return
    end

    local bRes = true
    if nItemType == gtItemType.eProp then
        local tConf = ctPropConf[nItemID]
        if not tConf then
            return self:Tips("道具表不存在道具:"..nItemID)
        end

        if tConf.nType == gtPropType.eCurr then
            return self:AddItem(gtItemType.eCurr, tConf.nSubType, nItemNum, sReason)
        else   
            if nItemNum > 0 then
                bRes = self.m_oGuoKu:AddItem(nItemID, nItemNum)
            else
                bRes = self.m_oGuoKu:SubItem(nItemID, nItemNum)
            end
        end

    elseif nItemType == gtItemType.eCurr then
        if nItemID == gtCurrType.eYuanBao then
            bRes = self:AddYuanBao(nItemNum, bFlyWord)
            
        else
            return self:Tips("不支持货币类型:"..nItemID)

        end

    else
        return self:Tips("不支持添加物品类型:"..nItemType)

    end

    --日志
    if bRes then
        local nEventID = nItemNum > 0 and gtEvent.eAddItem or gtEvent.eSubItem
        goLogger:AwardLog(nEventID, sReason, self, nItemType, nItemID, math.abs(nItemNum), bRes)
    end
    return bRes
end


--元宝不足弹框
function CRole:YBDlg()
    self:Tips("元宝不足")
    -- local nServer, nSession = self:GetServer(), self:GetSession()
    -- CmdNet.PBSrv2Clt("YBDlgRet", nServer, nSession , {})
end

--飘字通知
function CRole:Tips(sCont, nServer, nSession)
    assert(sCont)
    nServer = nServer or self:GetServer()
    nSession = nSession or self:GetSession()
    CmdNet.PBSrv2Clt("TipsMsgRet", nServer, nSession, {sCont=sCont})
end
