local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local sPlayerDB = "PlayerDB"
local nAutoSaveTick = 5*60*1000

function CPlayer:Ctor(nSessionID, sAccount, sCharID, sCharName, nRoleID, sPlatform, sChannel)
    CObjBase.Ctor(self, gtObjType.ePlayer, sCharID, sCharName, nRoleID)
    self.m_oCppObj = nil
    ------不保存------
    self.m_nSession = nSessionID
    self.m_sAccount = sAccount
    self.m_sPlatform = sPlatform
    self.m_sChannel = sChannel
    self.m_nSceneIndex = 0

    ------保存--------
    self.m_sCharID = sCharID        --角色ID
    self.m_sCharName = sCharName    --角色名
    self.m_nRoleID= nRoleID         --配置ID
    self.m_nVIP = 0 --VIP等级

    self.m_nCharLevel = 1   --等级
    self.m_nGoldCount = ctPlayerInitConf[1].nInitGold   --金币
    self.m_nMoneyCount = 0  --钻石
    self.m_nExpCount = 0    --经验
    self.m_nOfflineTime = 0 --下线时间

    ------其他--------
    self.m_tModuleMap = {}  --映射
    self.m_tModuleList = {} --有序
    self:LoadSelfData() --这里先加载玩家数据,因为子模块可能要用到玩家数据
    self:CreateModules()
    self:LoadData()
end

function CPlayer:OnRelease()
    self.m_oCppObj = nil
    self.m_nSceneIndex = 0
    goCppPlayerMgr:RemovePlayer(self.m_sCharID)

    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:OnRelease()
    end
end

--创建各个子模块
function CPlayer:CreateModules()
    self.m_oBagModule = CBagModule:new(self) 
    self.m_oBattle = CBattle:new(self)
    self.m_oGVEModule = CGVEModule:new(self)
    self.m_oSingleDup = CSingleDup:new(self) 
    self.m_oWorkShop = CWorkShop:new(self)
    self.m_oMallModule = CMallModule:new(self)
    self.m_oGVGModule = CGVGModule:new(self)
    self.m_oMail = CMail:new(self)
    self.m_oBox = CBox:new(self)
    self.m_oNewbieGuide = CNewbieGuide:new(self)
    self.m_oVIP = CVIP:new(self)
    self.m_oDraw = CDraw:new(self)
    self.m_oTalent = CTalent:new(self)

    self:RegisterModule(self.m_oBagModule) 
    self:RegisterModule(self.m_oBattle) 
    self:RegisterModule(self.m_oGVEModule) 
    self:RegisterModule(self.m_oSingleDup) 
    self:RegisterModule(self.m_oWorkShop) 
    self:RegisterModule(self.m_oMallModule) 
    self:RegisterModule(self.m_oGVGModule) 
    self:RegisterModule(self.m_oMail) 
    self:RegisterModule(self.m_oBox) 
    self:RegisterModule(self.m_oNewbieGuide) 
    self:RegisterModule(self.m_oVIP) 
    self:RegisterModule(self.m_oDraw) 
    self:RegisterModule(self.m_oTalent) 
end

function CPlayer:RegisterModule(oModule)
	local nModuleID = oModule:GetType()
	assert(not self.m_tModuleMap[nModuleID], "重复注册模块:"..nModuleID)
	self.m_tModuleMap[nModuleID] = oModule
    table.insert(self.m_tModuleList, oModule)
end

function CPlayer:GetModule(nModuleID)
    return self.m_tModuleMap[nModuleID]
end

--加载子模块数据
function CPlayer:LoadData()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local _, sModuleName = oModule:GetType()
        local sData = goSSDB:HGet(sModuleName, self.m_sCharID)
        if sData ~= "" then
            local tData = GlobalExport.Str2Tb(sData)
            oModule:LoadData(tData)
        end
    end
    self.m_oCppObj = goCppPlayerMgr:CreatePlayer(self.m_sCharID, self.m_nRoleID, self.m_sCharName, gtCampType.eNeutral)
    goCppPlayerMgr:BindSession(self.m_sCharID, self.m_nSession)
end

--保存玩家和子模块数据
function CPlayer:SaveData(bOffline)
    if not bOffline then
        self:RegisterAutoSaveTick()
    end

    local nBegClock = os.clock()
    self:SaveSelfData()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local tData = oModule:SaveData()
        if tData and next(tData) then
            local sData = GlobalExport.Tb2Str(tData)
            local _, sModuleName = oModule:GetType()
            goSSDB:HSet(sModuleName, self.m_sCharID, sData)
            print("Save "..sModuleName, "len:"..string.len(sData))
        end
    end
    print("------SaveData------", self.m_sCharName, string.format("%.4f", os.clock() - nBegClock))
end

--初始化玩家数据
function CPlayer:LoadSelfData()
    local sData = goSSDB:HGet(sPlayerDB, self.m_sCharID)  
    if sData == "" then
        return
    end
    local tData = GlobalExport.Str2Tb(sData)
    self.m_sCharName = tData.sCharName or ""
    self.m_nRoleID = tData.nRoleID or 0
    self.m_nCharLevel = math.max(1, tData.nCharLevel or 1)
    self.m_nGoldCount = tData.nGoldCount or 0
    self.m_nMoneyCount = tData.nMoneyCount or 0
    self.m_nExpCount = tData.nExpCount or 0
    self.m_nOfflineTime = tData.nOfflineTime or 0
end

function CPlayer:SaveSelfData()
    local tData = {}
    tData.sCharName = self.m_sCharName
    tData.nRoleID = self.m_nRoleID
    tData.nCharLevel = self.m_nCharLevel
    tData.nGoldCount = self.m_nGoldCount
    tData.nMoneyCount = self.m_nMoneyCount
    tData.nExpCount = self.m_nExpCount
    tData.nOfflineTime = self.m_nOfflineTime

    local sData = GlobalExport.Tb2Str(tData)
    goSSDB:HSet(sPlayerDB, self.m_sCharID, sData)
end

function CPlayer:UnregisterAutoSaveTick()
    if self.m_nAutoSaveTick then
        GlobalExport.CancelTimer(self.m_nAutoSaveTick)
        self.m_nAutoSaveTick = nil
    end
end

function CPlayer:RegisterAutoSaveTick()
    if self.m_nAutoSaveTick then
        self:UnregisterAutoSaveTick()
    end
    self.m_nAutoSaveTick = GlobalExport.RegisterTimer(nAutoSaveTick, function() self:SaveData() end)
end

function CPlayer:GetSession() return self.m_nSession end
function CPlayer:GetAccount() return self.m_sAccount end
function CPlayer:GetCharID() return self.m_sCharID end
function CPlayer:GetRoleID() return self.m_nRoleID end
function CPlayer:GetLevel() return self.m_nCharLevel end
function CPlayer:GetPlatform() return self.m_sPlatform end
function CPlayer:GetChannel() return self.m_sChannel end
function CPlayer:GetVIP() return 0 end

function CPlayer:IsDead() return self.m_oCppObj:IsDead() end 
function CPlayer:GetStaticSpeed() return ctPlayerInitConf[1].nMoveSpeed end
function CPlayer:GetBattleAttr() return self.m_oBattle:GetBattleAttr() end
function CPlayer:GetRunningSpeed() return self.m_oCppObj:GetRunningSpeed() end
function CPlayer:GetRuntimeBattleAttr() return self.m_oBattle:GetRuntimeBattleAttr() end

function CPlayer:GetPower(tBattleAttr)
    --战斗力=攻击*5.5+防御*6+生命
    local tBattleAttr = tBattleAttr or self:GetModule(CBattle:GetType()):GetBattleAttr()
    return GF.CalcPower(tBattleAttr[1], tBattleAttr[2], tBattleAttr[3])
end

--设置等级
function CPlayer:SetLevel(nLevel)
    local nOldLevel = self.m_nCharLevel
    self.m_nCharLevel = nLevel
    
    --模块
    for nID, oModule in pairs(self.m_tModuleMap) do
        oModule:OnLevelChange(nOldLevel, nLevel)
    end
    --战队
    goUnionMgr:OnLevelChange(self)

    self:UpdateBattleAttr()
    local tData = {nLevel=nLevel, nCurrExp=self.m_nExpCount, nNextExp=self:GetNextExp()} 
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerLevelSync", tData)
end

--进入场景
function CPlayer:EnterSceneOnLogin()
    local nSceneID = goLuaSceneMgr:GetBeginnerScene()
    local oScene = goLuaSceneMgr:GetSceneByID(nSceneID)
    if not oScene then
        print("EnterSceneOnLogin", "进入场景失败")
        return
    end
    self:EnterScene(oScene:GetSceneIndex(), {nType=gtBattleType.eTest, nCamp=gtCampType.eFreeLand})
end

--离开场景
function CPlayer:LeaveScene()
    if self.m_nSceneIndex == 0 then
        print(self:GetName(), " not in scene", self.m_nSceneIndex)
        return
    end
    local oScene = self:GetScene()
    if not oScene then
        print("Scene:"..self.m_nSceneIndex.." not found!")
        return
    end
    oScene:RemoveObj(self:GetAOIID())
end

--进入场景
function CPlayer:EnterScene(nSceneIndex, tBattle, nPosX, nPosY)
    assert(tBattle and tBattle.nType and tBattle.nCamp)
    if self.m_nSceneIndex == 0 then
    --有些战斗需要进入场景前调用SetBattle设置战斗类型,等到进入场景的时候需要重置,不然引起断言
        self:SetBattle(nil)
    end
    self:SetBattle(tBattle)

    local oScene = assert(goLuaSceneMgr:GetSceneByIndex(nSceneIndex))
    local tSceneConf = assert(goLuaSceneMgr:GetSceneConfByIndex(nSceneIndex))
    nPosX = nPosX or tSceneConf.nBornPosX
    nPosY = nPosY or tSceneConf.nBornPosY
    oScene:AddPlayer(self.m_oCppObj, nPosX, nPosY)
end

--客户端场景准备完毕
function CPlayer:OnClientSceneReady()
    print("CPlayer:OnClientSceneReady***")
    local oScene = self:GetScene()
    if not oScene then
        print("CBattl:ClientSceneReady*** player not in scene")
        return 
    end
    oScene:AddObserved(self.m_oCppObj)
    oScene:AddObserver(self.m_oCppObj)
    self.m_oBattle:OnClientSceneReady()
end

--同步玩家初始数据
function CPlayer:SyncInitData()
    local tData = {}
    tData.sCharID = self.m_sCharID
    tData.sCharName = self.m_sCharName
    tData.nRoleID = self.m_nRoleID
    tData.nCharLevel = self.m_nCharLevel
    tData.nGoldCount = self.m_nGoldCount
    tData.nMoneyCount = self.m_nMoneyCount
    tData.nCurrExp = self.m_nExpCount
    tData.nNextExp = self:GetNextExp()
    tData.nVIP = self.m_nVIP
    tData.tBattleAttr = self.m_oBattle:GetBattleAttr()
    tData.nMoveSpeed = self:GetStaticSpeed()
    tData.nFame = self.m_oGVGModule:GetFame()
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerInitDataSync", tData)
end 

--玩家上线
function CPlayer:Online()
    --各模块上线(可能有依赖关系所以用list)
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:Online()
    end
    self:UpdateBattleAttr(true) --更新战斗属性
    self:SyncInitData() --同步初始数据
    self:SyncBagContainer() --同步背包容量
    self:RegisterAutoSaveTick() --定时保存

    --战队
    goUnionMgr:Online(self)
end

--玩家下线
function CPlayer:Offline()
    self:LeaveScene()
    self.m_nOfflineTime = os.time()

    --模块
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:Offline()
    end
    --组队
    goTeamMgr:Offline(self)

    self:SaveData(true)
    self.m_nSession = 0
    self:UnregisterAutoSaveTick()
end

--玩家进入场景
function CPlayer:OnEnterScene(nSceneIndex)
    print("CPlayer:OnEnterScene***", nSceneIndex, self.m_sCharName)
    CObjBase.OnEnterScene(self, nSceneIndex)
    self.m_oBattle:OnEnterScene(nSceneIndex)

    --通知客户端
    local nSceneID = goLuaSceneMgr:GetSceneConfID(nSceneIndex)
    local nAOIID = self:GetAOIID()
    local nPosX, nPosY = self:GetPos()
    local tWeaponList = self.m_oBattle:GetWeaponList()
    local nBattleLevel = self.m_oBattle:GetBattleLevel()
    local tBattleAttr = self:GetRuntimeBattleAttr()
    local nPower = self:GetPower(tBattleAttr)
    local tBattle = self:GetBattle()
    local tMsg = {nSceneID=nSceneID, nAOIID=nAOIID, nPosX=nPosX, nPosY=nPosY
        , nBattleType=tBattle.nType, nBattleCamp=tBattle.nCamp, nBattleLevel=nBattleLevel
        , tBattleAttr=tBattleAttr, tWeaponList=tWeaponList, nPower=nPower}
    print("战斗属性:", self.m_sCharName, tBattleAttr)
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerEnterSceneRet", tMsg)
end

--进入场景后
function CPlayer:AfterEnterScene(nSceneIndex)
    self.m_oBattle:AfterEnterScene(nSceneIndex)
end

--玩家离开场景
function CPlayer:OnLeaveScene(nSceneIndex)
    print("CPlayer:OnLeaveScene***", nSceneIndex, self.m_sCharName)
    self.m_oBattle:OnLeaveScene(nSceneIndex)
    CObjBase.OnLeaveScene(self, nSceneIndex)

    local nSceneID = goLuaSceneMgr:GetSceneConfID(nSceneIndex)
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerLeaveSceneRet", {nSceneID=nSceneID})
end

--场景对象进入视野
function CPlayer:OnObjEnterObj(tObserved)
    local nOBJ_PER_SEND = 16 --16个对象发1次(以免包过大)
    
    local tPlayerList = {}
    local tMonsterList = {}
    local tDropList = {}
    for j = 1, #tObserved do
        local oCppObj = tObserved[j]
        local sObjID, nObjType = oCppObj:GetObjID(), oCppObj:GetObjType()

       if nObjType == gtObjType.ePlayer then
            local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sObjID)
            local tViewData = oPlayer.m_oBattle:GetViewData() 
            table.insert(tPlayerList, tViewData)

        elseif nObjType == gtObjType.eRobot then
            local oSRobot = goLuaSRobotMgr:GetRobot(sObjID)
            local tViewData = oSRobot:GetViewData()
            table.insert(tPlayerList, tViewData)

        elseif nObjType == gtObjType.eMonster then
            local oMonster = goLuaMonsterMgr:GetMonster(sObjID)
            local tViewData = oMonster:GetViewData()
            table.insert(tMonsterList, tViewData)

        elseif nObjType == gtObjType.eSceneDrop then
            local oDropItem = goLuaDropItemMgr:GetDropItem(sObjID)
            local tViewData = oDropItem:GetViewData()
            table.insert(tDropList, tViewData)
        else
            assert(false, "不存在对象类型:"..nObjType)
        end
        
        if #tPlayerList >= nOBJ_PER_SEND then
            print("OnObjEnterObj:PlayerEnterViewSync***")
            CmdNet.PBSrv2Clt(self.m_nSession, "PlayerEnterViewSync", {tPlayerList=tPlayerList})
            tPlayerList = {}
        end
        if #tMonsterList >= nOBJ_PER_SEND then
            print("OnObjEnterObj:MonsterEnterViewSync***")
            CmdNet.PBSrv2Clt(self.m_nSession, "MonsterEnterViewSync", {tMonsterList=tMonsterList})
            tMonsterList = {}
        end
        if #tDropList >= nOBJ_PER_SEND then
            print("OnObjEnterObj:DropItemEnterViewSync***")
            CmdNet.PBSrv2Clt(self.m_nSession, "DropItemEnterViewSync", {tDropList=tDropList})
            tDropList = {}
        end
    end
    if #tPlayerList > 0 then
        print("OnObjEnterObj:PlayerEnterViewSync***")
        CmdNet.PBSrv2Clt(self.m_nSession, "PlayerEnterViewSync", {tPlayerList=tPlayerList})
    end
    if #tMonsterList > 0 then
        print("OnObjEnterObj:MonsterEnterViewSync***", #tMonsterList)
        CmdNet.PBSrv2Clt(self.m_nSession, "MonsterEnterViewSync", {tMonsterList=tMonsterList})
    end
    if #tDropList > 0 then
        print("OnObjEnterObj:DropItemEnterViewSync***")
        CmdNet.PBSrv2Clt(self.m_nSession, "DropItemEnterViewSync", {tDropList=tDropList})
    end
end

--玩家战斗属性变化
function CPlayer:UpdateBattleAttr(bOnline)
    local tBattleAttr = self.m_oBattle:CalcBattleAttr()
    if not bOnline then
        CmdNet.PBSrv2Clt(self.m_nSession, "BattleAttrSync", {tAttr=tBattleAttr})
    end
end

function CPlayer:GetGold()
    return self.m_nGoldCount
end

function CPlayer:AddGold(nCount)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nGoldCount = math.min(nMAX_INTEGER, self.m_nGoldCount + nCount)
    self:SyncCurr(gtCurrType.eGold, self.m_nGoldCount)
end

function CPlayer:SubGold(nCount, nReason)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nGoldCount = math.max(0, self.m_nGoldCount - nCount)
    self:SyncCurr(gtCurrType.eGold, self.m_nGoldCount)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtObjType.eCurr, gtCurrType.eGold, nCount, self.m_nGoldCount)
end

function CPlayer:GetMoney()
    return self.m_nMoneyCount
end

function CPlayer:AddMoney(nCount)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nMoneyCount = math.min(nMAX_INTEGER, self.m_nMoneyCount + nCount)
    self:SyncCurr(gtCurrType.eMoney, self.m_nMoneyCount)
end

function CPlayer:SubMoney(nCount, nReason)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nMoneyCount = math.max(0, self.m_nMoneyCount - nCount)
    self:SyncCurr(gtCurrType.eMoney, self.m_nMoneyCount)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtObjType.eCurr, gtCurrType.eMoney, nCount, self.m_nMoneyCount)
end

--下一级需要经验
function CPlayer:GetNextExp()
    local tLevelConf = ctPlayerLevelConf[self.m_nCharLevel+1]
    local nNextExp = tLevelConf and tLevelConf.nExp or -1
    return nNextExp
end

--增加玩家经验
function CPlayer:AddExp(nCount)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nExpCount = math.min(nMAX_INTEGER, self.m_nExpCount + nCount)
    self:SyncCurr(gtCurrType.eExp, self.m_nExpCount)
    self:CheckUpgrade()
end

--升级判断
function CPlayer:CheckUpgrade()
    for k = self.m_nCharLevel+1, #ctPlayerLevelConf do
        local tConf = ctPlayerLevelConf[k]
        if self.m_nExpCount >= tConf.nExp then 
            self:SubExp(tConf.nExp, gtReason.ePlayerUpgrade)
            self:SetLevel(k)
        else
            break
        end
    end
end

function CPlayer:SubExp(nCount, nReason)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nExpCount= math.max(0, self.m_nExpCount - nCount)
    self:SyncCurr(gtCurrType.eExp, self.m_nExpCount)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtObjType.eCurr, gtCurrType.eExp, nCount, self.m_nExpCount)
end

--同步玩家货币
function CPlayer:SyncCurr(nCurrType, nCurrValue)
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerCurrSync", {nCurrType=nCurrType, nCurrValue=nCurrValue})
end


--添加物品
function CPlayer:AddItem(nItemType, nItemID, nItemNum, nReason)
    assert(nReason, "添加物品原因缺失")
    if nItemType <= 0 or nItemID <= 0 or nItemNum <= 0 then
        return
    end
    nItemNum = math.min(nMAX_INTEGER, nItemNum)

    local bRes = true
    local oBagModule = self:GetModule(CBagModule:GetType())
    if nItemType == gtObjType.eArm then
        bRes = oBagModule:AddItem(gtObjType.eArm, nItemID, nItemNum)

    elseif nItemType == gtObjType.eProp then
        local tConf = assert(ctPropConf[nItemID])
        if tConf.nType == gtPropType.eCurrency then
            return self:AddItem(gtObjType.eCurr, tConf.nSubType, nItemNum, nReason)

        elseif tConf.nType == gtPropType.eNormal or tConf.nType == gtPropType.eFeature or tConf.nType == gtPropType.eGift then
            bRes = oBagModule:AddItem(gtObjType.eProp, nItemID, nItemNum)

        else   
            assert(false, "不支持道具类型:"..tConf.nType)
        end

    elseif nItemType == gtObjType.eWSProp then
        local oWorkShop = self:GetModule(CWorkShop:GetType())
        bRes = oWorkShop:AddProp(nItemID, nItemNum)

    elseif nItemType == gtObjType.eCurr then
        if nItemID == gtCurrType.eGold then
            self:AddGold(nItemNum)

        elseif nItemID == gtCurrType.eMoney then
            self:AddMoney(nItemNum)

        elseif nItemID == gtCurrType.eExp then
            self:AddExp(nItemNum)

        elseif nItemID == gtCurrType.eGVEFame then
            self:GetModule(CGVEModule:GetType()):AddFame(nItemNum)
            
        elseif nItemID == gtCurrType.eGVGFame then
            self:GetModule(CGVGModule:GetType()):AddFame(nItemNum)

        elseif nItemID >= gtCurrType.eSQMaster and nItemID <= gtCurrType.eSPXMaster then
            self:GetModule(CWorkShop:GetType()):AddMaster(nItemID, nItemNum)
            
        else
            assert(false, "不支持货币类型:"..nItemID)
        end

    else
        assert(false, "不支持添加物品类型:"..nItemType)
    end
    if bRes then
        goLogger:AwardLog(gtEvent.eAddItem, nReason, self, nItemType, nItemID, nItemNum)
    end
    return bRes
end

--飘字通知
function CPlayer:ScrollMsg(sCont, nSession)
    assert(sCont)
    nSession = nSession or self.m_nSession
    CmdNet.PBSrv2Clt(nSession, "ScrollMsgNotify", {sCont=sCont})
end

--同步背包和工坊背包容量
function CPlayer:SyncBagContainer()
    local nBag = self.m_oBagModule:GetFreeGridNum()
    local nWorkShop = self.m_oWorkShop:FreeGridCount()
    local tSendData = {nBag=nBag, nWorkShop=nWorkShop}
    CmdNet.PBSrv2Clt(self.m_nSession, "BagContainerSync", tSendData)
end
