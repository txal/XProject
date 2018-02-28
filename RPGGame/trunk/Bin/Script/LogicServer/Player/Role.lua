--角色对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAutoSaveTime = 3*60
function CRole:Ctor(nServer, nSession, nRoleID)
    ------不保存------
    self.m_bDirty = false
    self.m_nSaveTimer = nil
    self.m_nServer = nServer
    self.m_nSession = nSession

    ------保存--------
    self.m_nSource = 0
    self.m_nAccountID = 0
    self.m_sAccountName = 0

    self.m_nID = nRoleID
    self.m_nCreateTime = os.time()
    self.m_nOnlineTime = os.time()
    self.m_nOfflineTime = os.time()

    self.m_sName = ""
    self.m_nGender = 0
    self.m_nSchool = 0
    self.m_nLevel = 0
    self.m_tLastDup = {0, 0, 0} --mixdupid,x,y
    self.m_tCurrDup = {0, 0, 0} --mixdupid,x,y

    self.m_nVIP = 0

    ------其他--------
    self.m_tModuleMap = {}  --映射
    self.m_tModuleList = {} --有序
    self:LoadSelfData() --这里先加载角色数据,子模块可能要用到角色数据
    self:CreateModules()
    self:LoadModuleData()

    -----Native-------
    self.m_oNativeObj = goNativePlayerMgr:CreateRole(self.m_nID, self.m_nID, self.m_sName, self.m_nServer, self.m_nSession)
    assert(self.m_oNativeObj, "创建C++对象失败")

end

function CRole:OnRelease()
    goTimerMgr:Clear(self.m_nSaveTimer)
    goNativePlayerMgr:RemoveRole(self.m_nID)
    self.m_oNativeObj = nil

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

--注册自动保存
function CRole:RegAutoSave()
    goTimerMgr:Clear(self.m_nSaveTimer)
    self.m_nSaveTimer = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

--加载角色数据
function CRole:LoadSelfData()
    local nServer, nID = self:GetServer(), self:GetID()
    local sData = goDBMgr:GetSSDB(nServer, "user", nID):HGet(gtDBDef.sRoleDB, nID)
    assert(sData ~= "", "角色不存在!!! : "..nID)

    local tData = cjson.decode(sData)

    self.m_nSource = tData.m_nSource or 0
    self.m_nAccountID = tData.m_nAccountID or 0
    self.m_sAccountName = tData.m_sAccountName or ""

    self.m_nOnlineTime = tData.m_nOnlineTime or self.m_nOnlineTime
    self.m_nOfflineTime = tData.m_nOfflineTime or self.m_nOfflineTime
    self.m_nCreateTime = tData.m_nCreateTime

    self.m_nID = tData.m_nID
    self.m_sName = tData.m_sName
    self.m_nGender = tData.m_nGender
    self.m_nSchool = tData.m_nSchool
    self.m_nLevel = tData.m_nLevel
    self.m_tLastDup = tData.m_tLastDup
    self.m_tCurrDup = tData.m_tCurrDup
    self.m_nVIP = tData.m_nVIP

end

--保存角色数据
function CRole:SaveSelfData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}

    tData.m_nSource = self.m_nSource
    tData.m_nAccountID = self.m_nAccountID
    tData.m_sAccountName = self.m_sAccountName

    tData.m_nOnlineTime = self.m_nOnlineTime
    tData.m_nOfflineTime = self.m_nOfflineTime
    tData.m_nCreateTime = self.m_nCreateTime

    tData.m_nID = self.m_nID
    tData.m_sName = self.m_sName
    tData.m_nGender = self.m_nGender
    tData.m_nSchool = self.m_nSchool
    tData.m_nLevel = self.m_nLevel

    tData.m_tLastDup = self.m_tLastDup
    tData.m_tCurrDup = self.m_tCurrDup
    tData.m_nVIP = self.m_nVIP

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
function CRole:GetServer() return self.m_nServer end
function CRole:GetSession() return self.m_nSession  end
function CRole:GetSource() return self.m_nSource end
function CRole:GetAccountID() return self.m_nAccountID end
function CRole:GetAccountName() return self.m_sAccountName end
function CRole:GetVIP() return self.m_nVIP end
function CRole:GetCreateTime() return self.m_nCreateTime end
function CRole:GetOnlineTime() return self.m_nOnlineTime end
function CRole:GetOfflineTime() return self.m_nOfflineTime end
function CRole:GetLastDup() return self.m_tLastDup end
function CRole:GetCurrDup() return self.m_tCurrDup end
function CRole:GetLogic()return GlobalExport.GetServiceID() end --当前逻辑服ID
function CRole:GetAOIID() return self.m_oNativeObj:GetAOIID() end
function CRole:GetPos() return self.m_oNativeObj:GetPos() end
function CRole:GetSpeed() return self.m_oNativeObj:GetRunSpeed() end
function CRole:GetDupMixID() return self.m_oNativeObj:GetDupMixID() end
function CRole:GetNativeObj() return self.m_oNativeObj end
function CRole:IsOnline(nSession) return self.m_nSession>0 end
function CRole:BindSession(nSession) self.m_oNativeObj:BindSession(nSession) end

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
    tMsg.nSource = self:GetSource()
    tMsg.nAccountID = self:GetAccountID()
    tMsg.sAccountName = self:GetAccountName()
    tMsg.nRoleID = self.m_nID
    tMsg.sRoleName = self.m_sName
    tMsg.nLevel = self.m_nLevel
    tMsg.nVIP = self:GetVIP()
    
    CmdNet.PBSrv2Clt("RoleInitDataRet", self:GetServer(), self:GetSession(), tMsg)
end 

--同步角色上下线到GLOBAL/WGLOBAL
function CRole:GlobalRoleOnline(bOnline)
    local tRole = nil
    local sFunc = "GRoleOfflineReq"
    if bOnline then
        sFunc = "GRoleOnlineReq"

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
        goRemoteCall:Call(sFunc, self:GetServer(), tConf.nID, self:GetSession(), self:GetID(), tRole)
    end
    --世界服GLOBAL(世界服本身没有gtWorldConf)
    if gtWorldConf then
        for _, tConf in pairs(gtWorldConf.tGlobalService) do
            goRemoteCall:Call(sFunc, self:GetServer(), tConf.nID, self:GetSession(), self:GetID(), tRole)
        end
    end
end

--更新角色信息到GLOBAL/WGLOBAL
function CRole:GlobalRoleUpdate(tParam)
    --本服GLOBAL
    for _, tConf in pairs(gtServerConf.tGlobalService) do
        goRemoteCall:Call("GRoleUpdateReq", self:GetServer(), tConf.nID, self:GetSession(), self:GetID(), tParam)
    end
    --世界服GLOBAL(世界服本身没有gtWorldConf)
    if gtWorldConf then
        for _, tConf in pairs(gtWorldConf.tGlobalService) do
            goRemoteCall:Call("GRoleUpdateReq", self:GetServer(), tConf.nID, self:GetSession(), self:GetID(), tParam)
        end
    end
end


--角色上线(注意:切换逻辑服不会调用)
function CRole:Online()
    print("CRole:Online***", self:GetAccountName(), self:GetName())
    self.m_nOnlineTime = os.time()
    self:MarkDirty(true)
    self:RegAutoSave()

    --GLOBAL/WGLOBAL上线通知
    self:GlobalRoleOnline(true)

    --各模块上线(可能有依赖关系所以用list)
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:Online()
    end

    --发送初始化数据 
    self:SyncInitData()
end

--上线成功(注意:切换逻辑服不会调用)
--@bReconnect: 是否重连
function CRole:AfterOnline(bReconnect)
    --进入场景
    local tCurrDup = self:GetCurrDup() 
    local oDup = goDupMgr:GetDup(tCurrDup[1])
    if oDup then
        if bReconnect then
            self:OnEnterScene(oDup:GetMixID())
            return oDup:AddObserver(self:GetAOIID())
        else
            return oDup:Enter(self.m_oNativeObj, tCurrDup[2], tCurrDup[3], -1)
        end
    end

    local tLastDup = self:GetLastDup()
    oDup = goDupMgr:GetDup(tLastDup[1])
    if not oDup then
        return LuaTrace("登录进入场景失败(不存在):", tLastDup[1])
    end
    if bReconnect then
        self:OnEnterScene(oDup:GetMixID())
        return oDup:AddObserver(self:GetAOIID())
    else
        return oDup:Enter(self.m_oNativeObj, tLastDup[2], tLastDup[3], -1)
    end
end

--断线(不清数据)
function CRole:OnDisconnect()
    self:BindSession(0)
    self:SaveData()
    --保存数据

    --移除观察者身份
    local tCurrDup = self:GetCurrDup() 
    local oDup = goDupMgr:GetDup(tCurrDup[1])
    oDup:RemoveObserver(self:GetAOIID())

    --更新角色摘要到登录服
    self:UpdateRoleSummary()
end

--角色下线(注意:切换逻辑服不会调用)
function CRole:Offline()
    self.m_nOfflineTime = os.time()
    self:MarkDirty(true)

    --各模块下线
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:Offline()
    end
    self:SaveData()
    --离开场景
    goDupMgr:LeaveDup(self:GetDupMixID(), self:GetAOIID())

    --GLOBAL/WGLOBAL下线通知
    self:GlobalRoleOnline(false)
    --更新角色摘要到登录服
    self:UpdateRoleSummary()
end

--物品数量
function CRole:ItemCount(nItemType, nItemID)
    if nItemType == gtItemType.eProp then
        local tConf = assert(ctPropConf[nItemID], "道具不存在:"..nItemID)
        if tConf.nType == gtPropType.eCurr then
            return self:ItemCount(gtItemType.eCurr, tConf.nSubType)
        else
            return self.m_oGuoKu:ItemCount(nItemID)
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

--取角色视野信息
function CRole:GetViewData()
    local tInfo = {tBaseData={}}
    tInfo.tBaseData.nAOIID = self:GetAOIID()
    tInfo.tBaseData.nObjType = gtObjType.eRole
    tInfo.tBaseData.nConfID = 0
    tInfo.tBaseData.sName = self:GetName()
    tInfo.tBaseData.nLevel = self:GetLevel()
    tInfo.tBaseData.nPosX, tInfo.tBaseData.nPosY = self:GetPos()
    tInfo.tBaseData.nSpeedX, tInfo.tBaseData.nSpeedY = self:GetSpeed()
    return tInfo
end

--同步逻辑服到网关
function CRole:SyncRoleLogic()
    local nSession = self:GetSession()
    local nGateService = GF.GetService(nSession)
    CmdNet.Srv2Srv("SyncRoleLogic", self:GetServer(), nGateService, nSession)
end

--角色进入场景
function CRole:OnEnterScene(nDupMixID)
    print("CRole:OnEnterScene***", nDupMixID, self:GetName())
    local tCurrDup = self:GetCurrDup()
    tCurrDup[1] = nDupMixID
    tCurrDup[2], tCurrDup[3] = self:GetPos()
    self:MarkDirty(true)

    --通知GLOBAL/WGLOBAL
    local nDupID = GF.GetDupID(nDupMixID)
    self:GlobalRoleUpdate({m_nDupID=nDupID})

    --通知网关服当前逻辑服
    self:SyncRoleLogic()

    --通知客户端
    local tMsg = {
        nMixID = nDupMixID,
        nDupID = nDupID, 
        nAOIID = self:GetAOIID(),
        nPosX = tCurrDup[2],
        nPosY = tCurrDup[3],
    }
    CmdNet.PBSrv2Clt("RoleEnterSceneRet", self:GetServer(), self:GetSession(), tMsg)
end

--角色进入场景后(同步视野后)
function CRole:AfterEnterScene(nDupMixID)
end

--角色离开场景
function CRole:OnLeaveScene(nDupMixID)
    print("CRole:OnLeaveScene***", nDupMixID, self:GetName())
    local nDupID = GF.GetDupID(nDupMixID)
    local nPosX, nPosY = self:GetPos()

    --记录上次所在的城镇
    local tDupConf = ctDupConf[nDupID]
    if tDupConf.nType == CDupBase.tType.eCity then
        local tLastDup = self:GetLastDup()
        tLastDup[1], tLastDup[2], tLastDup[3] = nDupMixID, nPosX, nPosY
        self:MarkDirty(true)
    end
    CmdNet.PBSrv2Clt("RoleLeaveSceneRet", self:GetServer(), self:GetSession(), {})
end

--场景对象进入视野
function CRole:OnObjEnterObj(tObserved)
    local nObjPerPacket = 64 --N个对象发1次(以免包过大)
    
    local tRoleList = {}
    local tMonsterList = {}
    for j = 1, #tObserved do
        local oNativeObj = tObserved[j]
        local nObjID, nObjType = oNativeObj:GetObjID(), oNativeObj:GetObjType()

       if nObjType == gtObjType.eRole then
            local oRole = goPlayerMgr:GetRoleByID(nObjID)
            local tViewData = oRole:GetViewData()
            table.insert(tRoleList, tViewData)

        elseif nObjType == gtObjType.eMonster then
            local oMonster = goMonsterMgr:GetMonster(nObjID)
            local tViewData = oMonster:GetViewData()
            table.insert(tMonsterList, tViewData)

        else
            assert(false, "不存在对象类型:"..nObjType)
        end
        
        if #tRoleList >= nObjPerPacket then
            CmdNet.PBSrv2Clt("RoleEnterViewRet", self:GetServer(), self:GetSession(), {tList=tRoleList})
            tRoleList = {}
        end
        if #tMonsterList >= nObjPerPacket then
            CmdNet.PBSrv2Clt("MonsterEnterViewRet", self:GetServer(), self:GetSession(), {tList=tMonsterList})
            tMonsterList = {}
        end
    end
    if #tRoleList > 0 then
        CmdNet.PBSrv2Clt("RoleEnterViewRet", self:GetServer(), self:GetSession(), {tList=tRoleList})
    end
    if #tMonsterList > 0 then
        CmdNet.PBSrv2Clt("MonsterEnterViewRet", self:GetServer(), self:GetSession(), {tList=tMonsterList})
    end
end

--更新角色摘要信息
function CRole:UpdateRoleSummary()
    local tSummary = {}
    tSummary.nID = nID
    tSummary.sName = self:GetName()
    tSummary.nLevel = self:GetLevel()
    tSummary.nGender = self:GetGender()
    tSummary.nSchool = self:GetSchool()
    tSummary.tLastDup = self:GetLastDup()
    tSummary.tCurrDup = self:GetCurrDup()
    tSummary.tEquipment = self:GetEquipment()
    goRemoteCall:Call("RoleUpdateSummaryReq", self:GetServer(), gtServerConf:GetLoginService(), self:GetSession()
        , self:GetAccountID(), self:GetID(), tSummary)
end
