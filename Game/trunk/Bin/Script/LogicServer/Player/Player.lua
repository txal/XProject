local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local sPlayerDB = "PlayerDB"            --玩家数据管理(Gamex)
local nAutoSaveTime = 5*60*1000         --自动保存数据时间
local nOfflineHoleTime = 30*60*1000     --离线对象保留时间

function CPlayer:Ctor(nSessionID, tAccount, sImgURL)
    ------不保存------
    self.m_nSession = nSessionID
    self.m_sAccount = tAccount.sAccount
    self.m_sPassword = tAccount.sPassword
    self.m_sDBName = nil        --玩家所在的数据仓库
    self.m_sImgURL = sImgURL    --玩家头像URL
    self.m_nObjType = gtObjType.ePlayer

    ------保存--------
    self.m_nCharID = tAccount.nCharID       --角色ID
    self.m_sCharName = tAccount.sCharName   --角色名
    self.m_nLevel = 1                   --角色等级

    self.m_nCard = 0        --房卡
    self.m_nGold = 0        --金币
    self.m_nDiamond = 0     --金块
    self.m_nTicket = 0      --奖券
    self.m_nExp = 0         --经验
    self.m_nMasterCoin = 0     --大师威望
    self.m_nFriendCoin = 0     --好友声望

    self.m_nCreateTime = os.time()  --创建时间
    self.m_nOfflineTime = 0 --下线时间
    self.m_nOnlineTime = 0  --上线时间

    ------其他--------
    self.m_tModuleMap = {}  --映射
    self.m_tModuleList = {} --有序
    self:LoadSelfData() --这里先加载玩家数据,因为子模块可能要用到玩家数据
    self:CreateModules()
    self:LoadData()

    self.m_nAutoSaveTick = nil
    self.m_nOfflineHoldTick = nil
end

function CPlayer:OnRelease()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:OnRelease()
    end
    self:SaveData()
    self:CancelAutoSaveTick()
    self:CancelOfflineHoldTick()
end

--创建各个子模块
function CPlayer:CreateModules()
    self.m_oMail = CMail:new(self)
    self.m_oVIP = CVIP:new(self)
    self.m_oGame = CGame:new(self)
    self.m_oGDMJ = CGDMJ:new(self)
    self.m_oNiuNiu = CNiuNiu:new(self)
    self.m_oDZPK = CDZPK:new(self)
    self.m_oDDZ = CDDZ:new(self)

    self:RegisterModule(self.m_oMail) 
    self:RegisterModule(self.m_oVIP) 
    self:RegisterModule(self.m_oGame) 
    self:RegisterModule(self.m_oGDMJ) 
    self:RegisterModule(self.m_oNiuNiu) 
    self:RegisterModule(self.m_oDZPK) 
    self:RegisterModule(self.m_oDDZ) 
end

function CPlayer:RegisterModule(oModule)
	local nModuleID = oModule:GetType()
	assert(not self.m_tModuleMap[nModuleID], "重复注册模块:"..nModuleID)
	self.m_tModuleMap[nModuleID] = oModule
    table.insert(self.m_tModuleList, oModule)
end

--取玩家数据库
function CPlayer:GetSSDB()
    if not self.m_sDBName then
        local oSSDB, sDBName = goDBMgr:GetSSDBByCharID(self.m_nCharID)
        self.m_sDBName = sDBName
        return oSSDB
    end
    return goDBMgr:GetSSDBByName(self.m_sDBName)
end

--加载子模块数据
function CPlayer:LoadData()
    local oSSDB = self:GetSSDB()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local _, sModuleName = oModule:GetType()
        local sData = oSSDB:HGet(sModuleName, self.m_nCharID)
        if sData ~= "" then
            local tData = cjson.decode(sData)
            oModule:LoadData(tData)
        end
    end
end

--保存玩家和子模块数据
function CPlayer:SaveData()
    local nBegClock = os.clock()
    self:SaveSelfData()
    local oSSDB = self:GetSSDB()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local tData = oModule:SaveData()
        if tData and next(tData) then
            local sData = cjson.encode(tData)
            local _, sModuleName = oModule:GetType()
            oSSDB:HSet(sModuleName, self.m_nCharID, sData)
            print("Save "..sModuleName, "len:"..string.len(sData))
        end
    end
    local nCostTime = os.clock() - nBegClock
    if nCostTime > 0 then
        LuaTrace("------SaveData------", self.m_sCharName, "costtime:", string.format("%.4f", nCostTime))
    end
end

--初始化玩家数据
function CPlayer:LoadSelfData()
    local oSSDB = self:GetSSDB()
    local sData = oSSDB:HGet(sPlayerDB, self.m_nCharID)  
    if sData == "" then
        return
    end
    local nNowSec = os.time()
    local tData = cjson.decode(sData)
    self.m_sCharName = tData.sCharName or ""
    self.m_nLevel = tData.nLevel or 1
    self.m_nGold = tData.nGold or 0
    self.m_nCard = tData.nCard or 0
    self.m_nDiamond = tData.nDiamond or 0
    self.m_nTicket = tData.nTicket or 0
    self.m_nExp = tData.nExp or 0
    self.m_nMasterCoin = tData.nMasterCoin or 0
    self.m_nFriendCoin = tData.nFriendCoin or 0
    self.m_nCreateTime = tData.nCreateTime or nNowSec
    self.m_nOfflineTime = tData.nOfflineTime or nNowSec
    self.m_nOnlineTime = tData.nOnlineTime or nNowSec
end

function CPlayer:SaveSelfData()
    local tData = {}
    tData.sCharName = self.m_sCharName
    tData.nLevel = self.m_nLevel
    tData.nGold = self.m_nGold
    tData.nCard = self.m_nCard
    tData.nDiamond = self.m_nDiamond
    tData.nTicket = self.m_nTicket
    tData.nExp = self.m_nExp
    tData.nMasterCoin = self.m_nMasterCoin
    tData.nFriendCoin = self.m_nFriendCoin
    tData.nCreateTime = self.m_nCreateTime
    tData.nOfflineTime = self.m_nOfflineTime
    tData.nOnlineTime = self.m_nOnlineTime

    local sData = cjson.encode(tData)
    local oGameDB = self:GetSSDB()
    oGameDB:HSet(sPlayerDB, self.m_nCharID, sData)
end

function CPlayer:CancelAutoSaveTick()
    if self.m_nAutoSaveTick then
        GlobalExport.CancelTimer(self.m_nAutoSaveTick)
        self.m_nAutoSaveTick = nil
    end
end

function CPlayer:RegisterAutoSaveTick()
    self:CancelAutoSaveTick()
    self.m_nAutoSaveTick = GlobalExport.RegisterTimer(nAutoSaveTime, function() self:SaveData() end)
end

function CPlayer:CancelOfflineHoldTick()
    if self.m_nOfflineHoldTick then
        GlobalExport.CancelTimer(self.m_nOfflineHoldTick)
        self.m_nOfflineHoldTick = nil
    end
end

function CPlayer:RegisterOfflineHoldTick()
    self:CancelOfflineHoldTick()
    self.m_nOfflineHoldTick = GlobalExport.RegisterTimer(nOfflineHoleTime, function() self:OfflineHoldTimeOut() end) 
end

function CPlayer:OfflineHoldTimeOut()
    --有房间时角色对象一直存在内存中
    --,房间管理器会定时清理玩家的房间
    if self.m_oGame:GetCurrGame().nRoomID > 0 then
        return
    end
    self:OnRelease()
end

function CPlayer:GetObjType() return self.m_nObjType end
function CPlayer:GetSession() return self.m_nSession end
function CPlayer:SetSession(nSession) self.m_nSession = nSession end
function CPlayer:IsOnline() return self.m_nSession > 0 end
function CPlayer:GetAccount() return self.m_sAccount end
function CPlayer:GetCharID() return self.m_nCharID end
function CPlayer:GetName() return self.m_sCharName end
function CPlayer:GetLevel() return self.m_nLevel end
function CPlayer:GetVIP() return self.m_oVIP:GetVIP() end
function CPlayer:GetGold() return self.m_nGold end
function CPlayer:GetCard() return self.m_nCard end
function CPlayer:GetDiamond() return self.m_nDiamond end
function CPlayer:GetImgURL() return self.m_sImgURL end
function CPlayer:GetPassword() return self.m_sPassword end
function CPlayer:GetCreateTime() return self.m_nCreateTime end

--同步玩家初始数据
function CPlayer:SyncInitData()
    local tMsg = {}
    tMsg.nCharID = self.m_nCharID
    tMsg.sCharName = self.m_sCharName
    tMsg.nLevel = self.m_nLevel
    tMsg.nGold = self.m_nGold
    tMsg.nCard = self.m_nCard
    tMsg.nDiamond = self.m_nDiamond
    tMsg.nTicket = self.m_nTicket
    tMsg.nExp = self.m_nExp
    tMsg.nMasterCoin = self.m_nMasterCoin
    tMsg.nFriendCoin = self.m_nFriendCoin
    print("CPlayer:SyncInitMsg***", tMsg)
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerInitDataRet", tMsg)
end 

--玩家上线
function CPlayer:Online()
    self.m_nOnlineTime = os.time()
    --各模块上线(可能有依赖关系所以用list)
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:Online()
    end
    self.m_nCard = 100 --默认房卡fix pd
    self:SyncInitData() --同步初始数据
    self:RegisterAutoSaveTick() --定时保存
    self:CancelOfflineHoldTick() --去掉离线保持
end

--玩家下线
function CPlayer:Offline()
    self.m_nSession = 0
    self.m_nOfflineTime = os.time()
    --模块调用
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:Offline()
    end
    --管理器下线事件
    goGameMgr:Offline(self)
    --保存数据
    self:SaveData()
    --注册离线保持
    self:RegisterOfflineHoldTick()
end

function CPlayer:AddGold(nCount, bFlyWord)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nGold = math.min(nMAX_INTEGER, self.m_nGold + nCount)
    self:SyncCurr(gtCurrType.eGold, self.m_nGold, bFlyWord)
end

function CPlayer:SubGold(nCount, nReason, bFlyWord)
    assert(nCount >= 0 and nReason)
    if nCount == 0 then return end
    self.m_nGold = math.max(0, self.m_nGold - nCount)
    self:SyncCurr(gtCurrType.eGold, self.m_nGold, bFlyWord)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtItemType.eCurr, gtCurrType.eGold, nCount, self.m_nGold)
end

function CPlayer:AddCard(nCount, bFlyWord)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nCard = math.min(nMAX_INTEGER, self.m_nCard + nCount)
    self:SyncCurr(gtCurrType.eCard, self.m_nCard, bFlyWord)
end

function CPlayer:SubCard(nCount, nReason, bFlyWord)
    assert(nCount >= 0 and nReason)
    if nCount == 0 then return end
    self.m_nCard = math.max(0, self.m_nCard - nCount)
    self:SyncCurr(gtCurrType.eCard, self.m_nCard, bFlyWord)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtItemType.eCurr, gtCurrType.eCard, nCount, self.m_nCard)
end

function CPlayer:AddDiamond(nCount, bFlyWord)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nDiamond = math.min(nMAX_INTEGER, self.m_nDiamond + nCount)
    self:SyncCurr(gtCurrType.eDiamond, self.m_nDiamond, bFlyWord)
end

function CPlayer:SubDiamond(nCount, nReason, bFlyWord)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nDiamond = math.max(0, self.m_nDiamond - nCount)
    self:SyncCurr(gtCurrType.eDiamond, self.m_nDiamond, bFlyWord)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtItemType.eCurr, gtCurrType.eDiamond, nCount, self.m_nDiamond)
end

function CPlayer:AddTicket(nCount, bFlyWord)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nTicket = math.min(nMAX_INTEGER, self.m_nTicket + nCount)
    self:SyncCurr(gtCurrType.eTicket, self.m_nTicket, bFlyWord)
end

function CPlayer:SubTicket(nCount, nReason, bFlyWord)
    assert(nCount >= 0 and nReason)
    if nCount == 0 then return end
    self.m_nTicket = math.max(0, self.m_nTicket - nCount)
    self:SyncCurr(gtCurrType.eTicket, self.m_nTicket, bFlyWord)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtItemType.eCurr, gtCurrType.eTicket, nCount, self.m_nTicket)
end

function CPlayer:AddExp(nCount, bFlyWord)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nExp = math.min(nMAX_INTEGER, self.m_nExp+ nCount)
    self:SyncCurr(gtCurrType.eExp, self.m_nExp, bFlyWord)
end

function CPlayer:SubExp(nCount, nReason, bFlyWord)
    assert(nCount >= 0 and nReason)
    if nCount == 0 then return end
    self.m_nExp= math.max(0, self.m_nExp- nCount)
    self:SyncCurr(gtCurrType.eExp, self.m_nExp, bFlyWord)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtItemType.eCurr, gtCurrType.eExp, nCount, self.m_nExp)
end

function CPlayer:AddMasterCoin(nCount, bFlyWord)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nMasterCoin = math.min(nMAX_INTEGER, self.m_nMasterCoin+ nCount)
    self:SyncCurr(gtCurrType.eMasterCoin, self.m_nMasterCoin, bFlyWord)
end

function CPlayer:SubMasterCoin(nCount, nReason, bFlyWord)
    assert(nCount >= 0 and nReason)
    if nCount == 0 then return end
    self.m_nMasterCoin= math.max(0, self.m_nMasterCoin- nCount)
    self:SyncCurr(gtCurrType.eMasterCoin, self.m_nMasterCoin, bFlyWord)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtItemType.eCurr, gtCurrType.eMasterCoin, nCount, self.m_nMasterCoin)
end

function CPlayer:AddFriendCoin(nCount, bFlyWord)
    assert(nCount >= 0)
    if nCount == 0 then return end
    self.m_nFriendCoin = math.min(nMAX_INTEGER, self.m_nFriendCoin+ nCount)
    self:SyncCurr(gtCurrType.eFriendCoin, self.m_nFriendCoin, bFlyWord)
end

function CPlayer:SubFriendCoin(nCount, nReason, bFlyWord)
    assert(nCount >= 0 and nReason)
    if nCount == 0 then return end
    self.m_nFriendCoin= math.max(0, self.m_nFriendCoin- nCount)
    self:SyncCurr(gtCurrType.eFriendCoin, self.m_nFriendCoin, bFlyWord)
    goLogger:AwardLog(gtEvent.eSubItem, nReason, self, gtItemType.eCurr, gtCurrType.eFriendCoin, nCount, self.m_nFriendCoin)
end

--同步玩家货币
function CPlayer:SyncCurr(nCurrType, nCurrValue, bFlyWord)
    bFlyWord = bFlyWord or false
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerCurrSync", {nCurrType=nCurrType, nCurrValue=nCurrValue, bFlyWord=bFlyWord})
end


--添加物品
function CPlayer:AddItem(nItemType, nItemID, nItemNum, nReason, bFlyWord)
    assert(nReason, "添加物品原因缺失")
    assert(nItemType > 0 and nItemID > 0 and nItemNum >= 0, "参数错误")
    nItemNum = math.max(0, math.min(nMAX_INTEGER, nItemNum))
    if nItemNum == 0 then return end

    local bRes = true
    if nItemType == gtItemType.eProp then
        local tConf = assert(ctPropConf[nItemID], "道具表找不到道具:"..nItemID)
        if tConf.nType == gtPropType.eCurrency then
            return self:AddItem(gtItemType.eCurr, tConf.nSubType, nItemNum, nReason, bFlyWord)

        elseif tConf.nType == gtPropType.eNormal or tConf.nType == gtPropType.eGift then
            bRes = self.m_oBagModule:AddItem(gtItemType.eProp, nItemID, nItemNum)

        else   
            assert(false, "不支持道具类型:"..tConf.nType)
        end

    elseif nItemType == gtItemType.eCurr then
        if nItemID == gtCurrType.eGold then
            self:AddGold(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eCard then
            self:AddCard(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eDiamond then
            self:AddDiamond(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eTicket then
            self:AddTicket(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eExp then
            self:AddExp(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eMasterCoin then
            self:AddMasterCoin(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eFriendCoin then
            self:AddFriendCoin(nItemNum, bFlyWord)

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

--Tips通知
function CPlayer:Tips(sCont, nSession)
    nSession = nSession or self.m_nSession
    goNoticeMgr:Tips(sCont, nSession)
end
