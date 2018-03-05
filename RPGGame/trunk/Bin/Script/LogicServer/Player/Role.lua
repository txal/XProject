--角色对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAutoSaveTime = 3*60
function CRole:Ctor(nServer, nRoleID)
    ------不保存------
    self.m_bDirty = false
    self.m_nSaveTimer = nil
    self.m_nServer = nServer
    self.m_nSession = 0
    self.m_tServerInfo = nil

    ------保存--------
    self.m_bCreate = false  --是否新创建的角色
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
    self.m_tLastDup = {0, 0, 0} --副本唯一ID,坐标X,坐标Y
    self.m_tCurrDup = {0, 0, 0} --mixdupid,x,y
    self.m_nVIP = 0

    --人物基础属性
    self.m_nVitality = 0    --活力
    self.m_nExp = 0         --经验
    self.m_nStoreExp = 0    --储备经验
    self.m_nPotential = 0   --潜力点

    self.m_nYuanBao = 0     --元宝
    self.m_nYinBi = 0       --银币
    self.m_nTongBi = 0      --铜币

    --战斗属性
    self.m_tBaseAttr = {0, 0, 0, 0, 0}      --基本属性(体质,魔力,力量,耐力,敏捷)
    self.m_tPotenAttr = {0, 0, 0, 0, 0}     --潜力属性(体质,魔力,力量,耐力,敏捷)
    self.m_tResultAttr = {0, 0, 0, 0, 0, 0, 0}  --结果属性(气血,魔法,怒气,攻击,防御,灵力,速度)

    ------其他--------
    self.m_tModuleMap = {}  --映射
    self.m_tModuleList = {} --有序
    self:LoadSelfData() --这里先加载角色数据,子模块可能要用到角色数据
    self:CreateModules()
    self:LoadModuleData()
    self:RegAutoSave()

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
    self.m_oKnapsack = CKnapsack:new(self)

    self:RegisterModule(self.m_oVIP)
    self:RegisterModule(self.m_oKnapsack)
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

    self.m_bCreate = tData.m_bCreate or false
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
    self.m_nVIP = tData.m_nVIP or 0

    self.m_nVitality = tData.m_nVitality
    self.m_nExp = tData.m_nExp
    self.m_nStoreExp = tData.m_nStoreExp
    self.m_nPotential = tData.m_nPotential

    self.m_nYuanBao = tData.m_nYuanBao
    self.m_nYinBi = tData.m_nYinBi
    self.m_nTongBi = tData.m_nTongBi

    self.m_tBaseAttr = tData.m_tBaseAttr
    self.m_tPotenAttr = tData.m_tPotenAttr
    self.m_tResultAttr = tData.m_tResultAttr

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

    tData.m_nVitality = tData.m_nVitality
    tData.m_nExp = tData.m_nExp
    tData.m_nStoreExp = tData.m_nStoreExp
    tData.m_nPotential = tData.m_nPotential

    tData.m_nYuanBao = tData.m_nYuanBao
    tData.m_nYinBi = tData.m_nYinBi
    tData.m_nTongBi = tData.m_nTongBi

    tData.m_tBaseAttr = tData.m_tBaseAttr
    tData.m_tPotenAttr = tData.m_tPotenAttr
    tData.m_tResultAttr = tData.m_tResultAttr

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

            local sData = cjson.encode(tData)
            goDBMgr:GetSSDB(nServer, "user", nID):HSet(sModuleName, nID, sData)
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
    --新角色
    if self.m_bCreate then
        --初始活力
        self.m_nVitality = 20
        --基础主属性
        self.m_tBaseAttr = {10, 10, 10, 10, 10}
        --初始潜力
        local tConf = ctRolePotentialConf[self.m_nSchool]
        self.m_tPotenAttr = table.DeepCopy(tConf.tBorn[1], true)
        --身上携带1元价值的铜币，1元的算法为(SLV*25+4000)*10 //SLV为服务器等级
        self.m_nTongBi = (goServerMgr:GetServerLevel(gnServerID)*25+4000)*10
        --携带道具：改名许可证
        self:AddItem(gtItemType.eProp, 10401, 1, "创建角色")

        --人物默认学会5级门派技能 fix pd
        --基础0级装备1套，属性指定门派，单独见出生装备标签 fix pd
        --携带一只宠物宝宝，属性指定，单独见出生宠物标 fix pd

        self.m_bCreate = false
        self:MarkDirty(true)
    end
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

--绑定会话ID
function CRole:BindSession(nSession)
    self.m_nSession = nSession
    self.m_oNativeObj:BindSession(nSession)
end

--取角色身上的装备
function CRole:GetEquipment()
    --fix pd
end

--计算战力(评分)
function CRole:UpdatePower()
    --fix pd
end

--取主属性
function CRole:GetMainAttr()
    local tMainAttr = {0, 0, 0, 0, 0}
    for k = 1, #self.m_tBaseAttr do
        tMainAttr[k] = tMainAttr[k] + self.m_tBaseAttr[k] + self.m_tPotenAttr[k]
    end
    return tMainAttr
end

--重现计算属性
function CRole:UpdateAttr()
    local tMainAttr = self:GetMainAttr()

    --根据主属性计算结果属性
    self.m_tResultAttr = {200, 0, 0, 40, 0, 0, 0} --结果属性(气血,魔法,怒气,攻击,防御,灵力,速度),攻击额外+40,气血额外加200
    for k=1, #tMainAttr do
        local nMainAttr = tMainAttr[k]
        for j=1, #self.m_tResultAttr do
            self.m_tResultAttr[j] = math.floor(self.m_tResultAttr[j]+ctRoleAttrConf[k]["nAttr"..j]*nMainAttr)
        end
    end
    --魔法默认值根据等级计算
    self.m_tResultAttr[2] = self.m_nLevel*20+30


    self:MarkDirty(true)
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

--同步角色上下线到[W]GLOBAL
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

    --[W]GLOBAL
    local tGlobalServiceList = gtServerConf:GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
        goRemoteCall:Call(sFunc, self:GetServer(), tConf.nID, self:GetSession(), self:GetID(), tRole)
    end
end

--更新角色信息到[W]GLOBAL
function CRole:GlobalRoleUpdate(tParam)
    --[W]GLOBAL
    local tGlobalServiceList = gtServerConf:GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
        goRemoteCall:Call("GRoleUpdateReq", self:GetServer(), tConf.nID, self:GetSession(), self:GetID(), tParam)
    end
end

--角色上线(注意:切换逻辑服不会调用)
function CRole:Online()
    print("CRole:Online***", self:GetAccountName(), self:GetName())
    self.m_nOnlineTime = os.time()
    self:MarkDirty(true)

    --各模块上线(可能有依赖关系所以用list)
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:Online()
    end

    --WGLOBALOBAL上线通知
    self:GlobalRoleOnline(true)
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
    self.m_nSession = 0
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


function CRole:GetVIP() return self.m_nVIP end
function CRole:GetVitality() return self.m_nVitality end    --
function CRole:GetExp() return self.m_nExp end
function CRole:GetStoreExp() return self.m_nStoreExp end
function CRole:GetPotential() return self.m_nPotential end
function CRole:GetYuanBao() return self.m_nYuanBao end
function CRole:GetYinBi() return self.m_nYinBi end
function CRole:GetTongBi() return self.m_nTongBi end

--活力上限
function CRole:MaxVitality()
   local nMaxVitality = 50 + self.m_nLevel * 20 
   return nMaxVitality
end

--添加活力
function CRole:AddVitality(nVal)
    self.m_nVitality = math.max(0, math.min(self:MaxVitality(), self.m_nVitality+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eVitality, self.m_nVitality)
end

--添加经验
function CRole:AddExp(nVal)
    self.m_nExp = math.max(0, math.min(nMAX_INTEGER, sel.m_nExp+nVal))
    self:MarkDirty(true)
    self:CheckUpgrade()
    self:SyncCurrency(gtCurrType.eExp, self.m_nExp)
end

--检测升级
function CRole:CheckUpgrade()
    --计算升级
    local nLevel = self.m_nLevel
    for k=self.m_nLevel, #ctRoleLevelConf-1 do
        local tConf = ctRoleLevelConf[k]
        if self.m_nExp >= tConf.nNeedExp then
            self.m_nLevel = self.m_nLevel + 1
            self.m_nExp = self.m_nExp - tConf.nNeedExp
            self:MarkDirty(true)
        end
    end
    if nLevel ~= self.m_nLevel then
        self:OnLevelChange(nLevel, self.m_nLevel)
    end
end

--角色等级变化
function CRole:OnLevelChange(nOldLevel, nNewLevel)
    self:SyncLevel()
    
    --计算基础属性
    local nDiffLevel = nNewLevel - nOldLevel
    for k=1, #self.m_tBaseAttr do
        self.m_tBaseAttr[k] = self.m_tBaseAttr[k] + nDiffLevel
    end
    self:MarkDirty(true)

    --计算潜力点
    if self.m_nLevel >= 40 then
        self:AddItem(gtItemType.eCurr, gtCurrType.ePotential, nDiffLevel*5, "等级变化")

    else
        --40级前自动加点
        local tDefault = ctRolePotentialConf[self.m_nSchool].tDefault[1]
        for k = 1, #tDefault do
            self.m_tPotenAttr[k] = self.m_tPotenAttr[k] + tDefault[k]
            self:MarkDirty(true)
        end
    end
end

--同步货币
function CRole:SyncCurrency(nType, nValue)
    assert(nType and nValue, "参数错误")
    CmdNet.PBSrv2Clt("RoleCurrencyRet", self:GetServer(), self:GetSession(), {nType=nType, nValue=nValue})
end

--同步等级
function CRole:SyncLevel()
    local nMaxLevel = #ctRoleLevelConf
    local nNextExp = ctRoleLevelConf[self.m_nLevel].nNextExp
    CmdNet.PBSrv2Clt("RoleLevelRet", self:GetServer(), self:GetSession()
        , {nLevel=self.m_nLevel,nExp=self.m_nExp,nMaxLevel=nMaxLevel,nNextExp=nNextExp})
end

--添加储备经验
function CRole:AddStoreExp()
    self.m_nStoreExp = math.max(0, math.min(nMAX_INTEGER, sel.m_nStoreExp+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eStoreExp, self.m_nStoreExp)
    return self.m_nStoreExp
end

--添加潜力点
function CRole:AddPotential()
    self.m_nPotential = math.max(0, math.min(nMAX_INTEGER, sel.m_nPotential+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.ePotential, self.m_nPotential)
    return self.m_nPotential
end

--添加元宝
function CRole:AddYuanBao()
    self.m_nYuanBao = math.max(0, math.min(nMAX_INTEGER, sel.m_nYuanBao+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eYuanBao, self.m_nYuanBao)
    return self.m_nYuanBao
end

--添加银币
function CRole:AddYinBi()
    self.m_nYinBi = math.max(0, math.min(nMAX_INTEGER, sel.m_nYinBi+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eYinBi, self.m_nYinBi)
    return self.m_nYinBi
end

--添加铜币
function CRole:AddTongBi()
    self.m_nTongBi = math.max(0, math.min(nMAX_INTEGER, sel.m_nTongBi+nVal))
    self:MarkDirty(true)

    self:SyncCurrency(gtCurrType.eTongBi, self.m_nTongBi)
    return self.m_nTongBi
end

--物品数量
function CRole:ItemCount(nItemType, nItemID)
    if nItemType == gtItemType.eProp then
        local tConf = assert(ctPropConf[nItemID], "道具不存在:"..nItemID)
        if tConf.nType == gtPropType.eCurr then
            return self:ItemCount(gtItemType.eCurr, tConf.nSubType)
        else
            return self.m_oKnapsack:ItemCount(nItemID)
        end
    end

    if nItemType == gtItemType.eCurr then
        if nItemID == gtCurrType.eVIP then
            return self:GetVIP()
        end
        if nItemID == gtCurrType.eYuanBao then
            return self:GetYuanBao()
        end
        if nItemID == gtCurrType.eYinBi then
            return self:GetYinBi()
        end
        if nItemID == gtCurrType.eTongBi then
            return self:GetTongBi()
        end
        if nItemID == gtCurrType.eVitality then
            return self:GetVitality()
        end
        if nItemID == gtCurrType.eExp then
            return self:GetExp()
        end
        if nItemID == gtCurrType.eStoreExp then
            return self:GetStoreExp()
        end
        if nItemID == gtCurrType.ePotential then
            return self:GetPotential()
        end
        assert(false, "不支持货币类型:"..nItemID)

    end
    assert(false, "不支持物品类型:"..nItemType)
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

    local xRes = true
    if nItemType == gtItemType.eProp then
        local tConf = ctPropConf[nItemID]
        if not tConf then
            return self:Tips("道具表不存在道具:"..nItemID)
        end

        if tConf.nType == gtPropType.eCurr then
            return self:AddItem(gtItemType.eCurr, tConf.nSubType, nItemNum, sReason)

        else   
            if nItemNum > 0 then
                xRes = self.m_oKnapsack:AddItem(nItemID, nItemNum)
            else
                xRes = self.m_oKnapsack:SubItem(nItemID, nItemNum)
            end

        end

    elseif nItemType == gtItemType.eCurr then
        if nItemID == gtCurrType.eYuanBao then
            xRes = self:AddYuanBao(nItemNum)

        elseif nItemID == gtCurrType.eYinBi then
            xRes = self:AddYinBi(nItemNum)

        elseif nItemID == gtCurrType.eTongBi then
            xRes = self:AddTongBi(nItemNum)

        elseif nItemID == gtCurrType.eVitality then
            xRes = self:AddVitality(nItemNum)

        elseif nItemID == gtCurrType.eExp then
            xRes = self:AddExp(nItemNum)

        elseif nItemID == gtCurrType.eStoreExp then
            xRes = self:AddStoreExp(nItemNum)

        elseif nItemID == gtCurrType.ePotential then
            xRes = self:AddPotential(nItemNum)

        else 
            return self:Tips("不支持货币类型:"..nItemID)
        end

    else
        return self:Tips("不支持物品类型:"..nItemType)
    end

    --日志
    if xRes then
        local nEventID = nItemNum > 0 and gtEvent.eAddItem or gtEvent.eSubItem
        goLogger:AwardLog(nEventID, sReason, self, nItemType, nItemID, math.abs(nItemNum), xRes)
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

--飘图标通知
function CRole:IconTips(tItemList, nServer, nSession)
    assert(sCont)
    nServer = nServer or self:GetServer()
    nSession = nSession or self:GetSession()
    CmdNet.PBSrv2Clt("IconTips", nServer, nSession, {tList=tItemList})
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

    --通知[W]GLOBAL
    local nDupID = GF.GetDupID(nDupMixID)
    self:GlobalRoleUpdate({m_nDupID=nDupID})
    --更新玩家摘要到登录服
    self:UpdateRoleSummary()
    --通知网关服当前逻辑服
    self:SyncRoleLogic()

    --通知客户端
    local tMsg = {
        nDupMixID = nDupMixID,
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
    goRemoteCall:Call("RoleUpdateSummaryReq", self:GetServer(), gtServerConf:GetLoginService(gnServerID), self:GetSession()
        , self:GetAccountID(), self:GetID(), tSummary)
end
