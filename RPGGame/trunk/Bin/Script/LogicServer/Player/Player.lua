local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nAutoSaveTime = 3*60 --自动保存时间

function CPlayer:Ctor(nSessionID, sAccount, nCharID, sCharName, nSource)
    ------不保存------
    self.m_bDirty = false
    self.m_nSession = nSessionID

    ------保存--------
    self.m_sAccount = sAccount
    self.m_nCharID = nCharID    --角色ID
    self.m_sName = sCharName    --角色名
    self.m_nSource = nSource

    local tConf = ctPlayerInitConf[1]
    self.m_nVIP = 0         --VIP
    self.m_nYuanBao = 0     --元宝
    self.m_nYinLiang = 0    --银两
    self.m_nLiangCao = 0    --粮草
    self.m_nBingLi = tConf.nInitBingLi      --兵力
    self.m_nTiLi = ctVIPConf[0].nMaxTL      --体力(姻缘点)
    self.m_nJingLi = ctVIPConf[0].nMaxJL    --精力
    self.m_nGuoLi = 0       --国力
    self.m_nWaiJiao = 0     --外交点(役事点)
    self.m_tAttr = {0, 0, 0, 0}             --属性(智才魅武)
    self.m_nShiLi = 0       --势力(已取消)
    self.m_nHistoryShiLi = 0--势力累计
    self.m_nWeiWang = 0     --威望
    self.m_nMaxWaiJiao = 0  --外交点上限
    self.m_nOnlineTime = 0  --上线时间
    self.m_nOfflineTime = 0 --下线时间
    self.m_nExp = 0         --国家经验
    self.m_nLevel = 1       --国家等级
    self.m_nWenHua = 0      --文化值
    self.m_sIcon = "icon_zhujue01"  --玩家头像
    self.m_nCreateTime = os.time()
    self.m_nFlourish = ctWFSFFlourishConf[1].nFlourish    --繁荣等级

    --定时恢复的货币
    local nNowSec = os.time()
    self.m_nLastTiLiRecoverTime = nNowSec
    self.m_nLastJingLiRecoverTime = nNowSec

    --定时器
    self.m_nTiLiTick = nil
    self.m_nJingLiTick = nil
    self.m_nAutoSaveTick = nil

    ------其他--------
    self.m_tModuleMap = {}  --映射
    self.m_tModuleList = {} --有序
    self:LoadSelfData() --这里先加载玩家数据,因为子模块可能要用到玩家数据
    self:CreateModules()
    self:LoadData()

end

function CPlayer:OnRelease()
    print("CPlayer:OnRelease***", self.m_sAccount)
    goTimerMgr:Clear(self.m_nTiLiTick)
    self.m_nTiLiTick = nil

    goTimerMgr:Clear(self.m_nJingLiTick)
    self.m_nJingLiTick = nil

    self:CancelAutoSaveTick()

    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:OnRelease()
    end
end

--创建各个子模块
function CPlayer:CreateModules()
    self.m_oMingChen = CMingChen:new(self)
    self.m_oGuoKu = CGuoKu:new(self)
    self.m_oDup = CDup:new(self)
    -- self.m_oFeiZi = CFeiZi:new(self)
    self.m_oNeiGe = CNeiGe:new(self)
    self.m_oLiFanYuan = CLiFanYuan:new(self)
    self.m_oVIP = CVIP:new(self)
    -- self.m_oJianZhu = CJianZhu:new(self)
    self.m_oJingShiFang = CJingShiFang:new(self)
    -- self.m_oLengGong = CLengGong:new(self)
    self.m_oChuXiuGong = CChuXiuGong:new(self)
    self.m_oZongRenFu = CZongRenFu:new(self)
    self.m_oZouZhang = CZouZhang:new(self)
    self.m_oLianYin = CLianYin:new(self)
    self.m_oMail = CMail:new(self)
    -- self.m_oQingAnZhe = CQingAnZhe:new(self)
    self.m_oWeiFuSiFang = CWeiFuSiFang:new(self)
    self.m_oMainTask = CMainTask:new(self)
    self.m_oDailyTask = CDailyTask:new(self)
    self.m_oJunJiChu = CJunJiChu:new(self)
    self.m_oQianDao = CQianDao:new(self)
    self.m_oChengZhiDiQiu = CChengZhiDiQiu:new(self)
    self.m_oDayRecharge = CDayRecharge:new(self)
    self.m_oWeekRecharge = CWeekRecharge:new(self)
    self.m_oTimeMall = CTimeMall:new(self)
    self.m_oLeiDeng = CLeiDeng:new(self)
    -- self.m_oYiHongYuan = CYiHongYuan:new(self)
    self.m_oZaoRenQiangGuo = CZaoRenQiangGuo:new(self)
    self.m_oLeiChong = CLeiChong:new(self)
    self.m_oRedPoint = CRedPoint:new(self)
    self.m_oMoBai = CMoBai:new(self)
    self.m_oShenJiZhuFu = CShenJiZhuFu:new(self)
    self.m_oShenMiBaoXiang = CShenMiBaoXiang:new(self)
    self.m_oParty = CParty:new(self)
    self.m_oKeyExchange = CKeyExchange:new(self)
    self.m_oWGL = CWGL:new(self)
    self.m_oFashion = CFashion:new(self)
	self.m_oAchievements = CAchievements:new(self)
    self.m_oTianDeng = CTianDeng:new(self)

    self:RegisterModule(self.m_oMingChen) 
    self:RegisterModule(self.m_oGuoKu) 
    self:RegisterModule(self.m_oDup)
    -- self:RegisterModule(self.m_oFeiZi)
    self:RegisterModule(self.m_oNeiGe)
    self:RegisterModule(self.m_oLiFanYuan) 
    self:RegisterModule(self.m_oVIP) 
    -- self:RegisterModule(self.m_oJianZhu) 
    self:RegisterModule(self.m_oJingShiFang) 
    -- self:RegisterModule(self.m_oLengGong) 
    self:RegisterModule(self.m_oChuXiuGong) 
    self:RegisterModule(self.m_oZouZhang) 
    self:RegisterModule(self.m_oZongRenFu) 
    self:RegisterModule(self.m_oLianYin) 
    self:RegisterModule(self.m_oMail) 
    -- self:RegisterModule(self.m_oQingAnZhe)
    self:RegisterModule(self.m_oWeiFuSiFang) 
    self:RegisterModule(self.m_oMainTask) 
    self:RegisterModule(self.m_oDailyTask)
    self:RegisterModule(self.m_oQianDao) 
    self:RegisterModule(self.m_oJunJiChu) 
    self:RegisterModule(self.m_oChengZhiDiQiu)
    self:RegisterModule(self.m_oDayRecharge)
    self:RegisterModule(self.m_oWeekRecharge)
    self:RegisterModule(self.m_oTimeMall)
    self:RegisterModule(self.m_oLeiDeng)
    -- self:RegisterModule(self.m_oYiHongYuan)
    self:RegisterModule(self.m_oZaoRenQiangGuo)
    self:RegisterModule(self.m_oLeiChong)
    self:RegisterModule(self.m_oRedPoint)
    self:RegisterModule(self.m_oMoBai)
    self:RegisterModule(self.m_oShenJiZhuFu)
    self:RegisterModule(self.m_oShenMiBaoXiang)
    self:RegisterModule(self.m_oParty)
    self:RegisterModule(self.m_oKeyExchange)
    self:RegisterModule(self.m_oWGL)
    self:RegisterModule(self.m_oFashion)
	self:RegisterModule(self.m_oAchievements)
    self:RegisterModule(self.m_oTianDeng)
end

function CPlayer:RegisterModule(oModule)
	local nModuleID = oModule:GetType()
	assert(not self.m_tModuleMap[nModuleID], "重复注册模块:"..nModuleID)
	self.m_tModuleMap[nModuleID] = oModule
    table.insert(self.m_tModuleList, oModule)
end

--加载子模块数据
function CPlayer:LoadData()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local _, sModuleName = oModule:GetType()
        local sData = goDBMgr:GetSSDB("Player"):HGet(sModuleName, self.m_nCharID)
        if sData ~= "" then
            oModule:LoadData(cjson.decode(sData))
        else
            oModule:LoadData()
        end
    end
    self:OnLoaded()
end

--取下次姻缘点恢复剩余时间
function CPlayer:GetTiLiRecoverCD()
    if self:GetTiLi() >= self:GetMaxTiLi() then
        return 0
    end
    local tConf = ctPlayerInitConf[1]
    local nRemainTimeSec = math.max(0, self.m_nLastTiLiRecoverTime+tConf.nTiLiRecoverTime-os.time())
    return nRemainTimeSec
end

--取下次精力恢复剩余时间
function CPlayer:GetJingLiRecoverCD()
    if self:GetJingLi() >= self:GetMaxJingLi() then
        return 0
    end
    local tConf = ctPlayerInitConf[1]
    local nRemainTimeSec = math.max(0, self.m_nLastJingLiRecoverTime+tConf.nJingLiRecoverTime-os.time())
    return nRemainTimeSec
end

--注册姻缘点TICK
function CPlayer:CheckTiLiRecover()
    goTimerMgr:Clear(self.m_nTiLiTick)
    self.m_nTiLiTick = nil

    local tConf = ctPlayerInitConf[1]
    if self.m_nLastTiLiRecoverTime > 0 then
        local nTiLiTime = os.time() - self.m_nLastTiLiRecoverTime
        local nTiLiAdd = math.floor(nTiLiTime / tConf.nTiLiRecoverTime)
        if nTiLiAdd > 0 then
            self.m_nLastTiLiRecoverTime = self.m_nLastTiLiRecoverTime + nTiLiAdd * tConf.nTiLiRecoverTime
            self:MarkDirty(true)
            return self:AddItem(gtItemType.eCurr, gtCurrType.eTiLi, nTiLiAdd, "姻缘点恢复") --这里会调用该函数
        end
    end

    if self:GetTiLi() >= self:GetMaxTiLi() then
        self.m_nLastTiLiRecoverTime = 0
        self:MarkDirty(true)
        return
    end

    if self.m_nLastTiLiRecoverTime <= 0 then
        self.m_nLastTiLiRecoverTime = os.time()
    end

    local nRemainTimeSec = self.m_nLastTiLiRecoverTime + tConf.nTiLiRecoverTime - os.time()
    if nRemainTimeSec <= 0 then
        return
    end

    self.m_nTiLiTick = goTimerMgr:Interval(nRemainTimeSec, function()
        self:CheckTiLiRecover()
    end)
end

--注册精力TICK
function CPlayer:CheckJingLiRecover()
    goTimerMgr:Clear(self.m_nJingLiTick)
    self.m_nJingLiTick = nil

    local tConf = ctPlayerInitConf[1]
    if self.m_nLastJingLiRecoverTime > 0 then
        local nJingLiTime = os.time() - self.m_nLastJingLiRecoverTime
        local nJingLiAdd = math.floor(nJingLiTime / tConf.nJingLiRecoverTime)
        if nJingLiAdd > 0 then
            self.m_nLastJingLiRecoverTime = self.m_nLastJingLiRecoverTime + nJingLiAdd * tConf.nJingLiRecoverTime
            self:MarkDirty(true)
            return self:AddItem(gtItemType.eCurr, gtCurrType.eJingLi, nJingLiAdd, "精力点恢复") --这里会调用该函数
        end
    end

    if self:GetJingLi() >= self:GetMaxJingLi() then
        self.m_nLastJingLiRecoverTime = 0
        self:MarkDirty(true)
        return
    end

    if self.m_nLastJingLiRecoverTime <= 0 then
        self.m_nLastJingLiRecoverTime = os.time()
    end

    local nRemainTimeSec = self.m_nLastJingLiRecoverTime + tConf.nJingLiRecoverTime - os.time()
    if nRemainTimeSec <= 0 then
        return
    end

    self.m_nJingLiTick = goTimerMgr:Interval(nRemainTimeSec, function()
        self:CheckJingLiRecover()
    end)
end

--加载数据完成
function CPlayer:OnLoaded()
    self:CheckTiLiRecover()
    self:CheckJingLiRecover()
end

--保存玩家和子模块数据
function CPlayer:SaveData()
    local nBegClock = os.clock()
    self:SaveSelfData()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        local tData = oModule:SaveData()
        if tData and next(tData) then
            local sData = cjson.encode(tData)
            local _, sModuleName = oModule:GetType()
            goDBMgr:GetSSDB("Player"):HSet(sModuleName, self.m_nCharID, sData)
            print("save module:", sModuleName, "len:"..string.len(sData))
        end
    end
    local nCostTime = os.clock() - nBegClock
    LuaTrace("------save------", self.m_nCharID, self.m_sName, "time:", string.format("%.4f", nCostTime))
end

--初始化玩家数据
function CPlayer:LoadSelfData()
    local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sPlayerDB, self.m_nCharID)  
    if sData == "" then 
        return self:MarkDirty(true)
    end
    local tData = cjson.decode(sData)

    self.m_nCharID = tData.m_nCharID
    self.m_sName = tData.m_sName
    self.m_nSource = tData.m_nSource or 0
    self.m_sAccount = (tData.m_sAccount or "") == "" and self.m_sAccount or tData.m_sAccount
    self.m_nVIP = math.min(tData.m_nVIP, #ctVIPConf)
    self.m_nYuanBao = tData.m_nYuanBao
    self.m_nYinLiang = tData.m_nYinLiang
    self.m_nLiangCao = tData.m_nLiangCao
    self.m_nBingLi = tData.m_nBingLi
    self.m_nTiLi = tData.m_nTiLi
    self.m_nJingLi = tData.m_nJingLi
    self.m_nGuoLi = tData.m_nGuoLi
    self.m_nWaiJiao = tData.m_nWaiJiao
    self.m_tAttr = tData.m_tAttr
    self.m_nShiLi = tData.m_nShiLi or 0
    self.m_nHistoryShiLi = tData.m_nHistoryShiLi or 0
    self.m_nOnlineTime= tData.m_nOnlineTime or 0
    self.m_nOfflineTime = tData.m_nOfflineTime or 0
    self.m_nWeiWang = tData.m_nWeiWang or 0
    self.m_nMaxWaiJiao = tData.m_nMaxWaiJiao or 0
    self.m_nCreateTime = tData.m_nCreateTime or os.time()
    self.m_nExp = tData.m_nExp or 0
    self.m_nLevel = tData.m_nLevel or self.m_nLevel
    self.m_nWenHua = tData.m_nWenHua or self.m_nWenHua
    self.m_sIcon = tData.m_sIcon or self.m_sIcon
    self.m_nFlourish = tData.m_nFlourish or self.m_nFlourish

    self.m_nLastTiLiRecoverTime = math.min(tData.m_nLastTiLiRecoverTime, os.time())
    self.m_nLastJingLiRecoverTime = math.min(tData.m_nLastJingLiRecoverTime, os.time())
end

function CPlayer:SaveSelfData()
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}

    tData.m_nCharID = self.m_nCharID
    tData.m_sName = self.m_sName
    tData.m_sAccount = self.m_sAccount
    tData.m_nSource = self.m_nSource
    tData.m_nVIP = self.m_nVIP
    tData.m_nYuanBao = self.m_nYuanBao
    tData.m_nYinLiang = self.m_nYinLiang
    tData.m_nLiangCao = self.m_nLiangCao
    tData.m_nBingLi = self.m_nBingLi
    tData.m_nTiLi = self.m_nTiLi
    tData.m_nJingLi = self.m_nJingLi
    tData.m_nGuoLi = self.m_nGuoLi
    tData.m_nWaiJiao = self.m_nWaiJiao
    tData.m_tAttr = self.m_tAttr
    tData.m_nShiLi = self.m_nShiLi
    tData.m_nHistoryShiLi = self.m_nHistoryShiLi
    tData.m_nWeiWang = self.m_nWeiWang
    tData.m_nMaxWaiJiao = self.m_nMaxWaiJiao
    tData.m_nOnlineTime= self.m_nOnlineTime
    tData.m_nOfflineTime = self.m_nOfflineTime
    tData.m_nLastTiLiRecoverTime = self.m_nLastTiLiRecoverTime
    tData.m_nLastJingLiRecoverTime = self.m_nLastJingLiRecoverTime
    tData.m_nCreateTime = self.m_nCreateTime
    tData.m_nExp = self.m_nExp
    tData.m_nLevel = self.m_nLevel
    tData.m_nWenHua = self.m_nWenHua
    tData.m_sIcon = self.m_sIcon
    tData.m_nFlourish = self.m_nFlourish

    goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sPlayerDB, self.m_nCharID, cjson.encode(tData))
end

function CPlayer:CancelAutoSaveTick()
    goTimerMgr:Clear(self.m_nAutoSaveTick)
    self.m_nAutoSaveTick = nil
end

function CPlayer:RegAutoSaveTick()
    self:CancelAutoSaveTick()
    self.m_nAutoSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CPlayer:IsDirty() return self.m_bDirty end
function CPlayer:MarkDirty(bDirty) self.m_bDirty = bDirty end

function CPlayer:GetSource() return self.m_nSource end
function CPlayer:GetSession() return self.m_nSession end
function CPlayer:GetAccount() return self.m_sAccount end
function CPlayer:GetCharID() return self.m_nCharID end
function CPlayer:GetName() return self.m_sName end
function CPlayer:GetVIP() return self.m_nVIP end
function CPlayer:GetYuanBao() return self.m_nYuanBao end
function CPlayer:GetYinLiang() return self.m_nYinLiang end
function CPlayer:GetLiangCao() return self.m_nLiangCao end
function CPlayer:GetBingLi() return self.m_nBingLi end
function CPlayer:GetTiLi() return self.m_nTiLi end
function CPlayer:GetMaxTiLi() return ctVIPConf[self.m_nVIP].nMaxTL end
function CPlayer:GetJingLi() return self.m_nJingLi end
function CPlayer:GetMaxJingLi() return ctVIPConf[self.m_nVIP].nMaxJL end
function CPlayer:GetGuoLi() return self.m_nGuoLi end
function CPlayer:GetWaiJiao() return self.m_nWaiJiao end
function CPlayer:GetAttr() return self.m_tAttr end
function CPlayer:GetShiLi() return self.m_nShiLi end
function CPlayer:GetOnlineTime() return self.m_nOnlineTime end
function CPlayer:GetOfflineTime() return self.m_nOfflineTime end
function CPlayer:GetWeiWang() return self.m_nWeiWang end
function CPlayer:MaxWaiJiao() return self.m_nMaxWaiJiao end
function CPlayer:GetCreateTime() return self.m_nCreateTime end
function CPlayer:GetExp() return self.m_nExp end
function CPlayer:GetLevel() return self.m_nLevel or 1 end
function CPlayer:GetWenHua() return self.m_nWenHua or 0 end
function CPlayer:GetIcon() return self.m_sIcon or "" end
function CPlayer:GetFlourish() return self.m_nFlourish or 1 end
function CPlayer:GetNextExp() return ctLevelConf[self.m_nLevel].nNeedExp end

--联盟贡献
function CPlayer:GetUnionContri()
    local oUnionPlayer = goUnionMgr:GetUnionPlayer(self.m_nCharID)
    if not oUnionPlayer then
        return 0
    end
    return oUnionPlayer:GetUnionContri()
end

--设置VIP
function CPlayer:SetVIP(nVIP, sReason)
    assert(nVIP and sReason, "参数错误")
    if not ctVIPConf[nVIP] then
        return self:Tips("VIP等级错误:"..nVIP)
    end
    local nOrgVIP = self.m_nVIP
    self.m_nVIP = nVIP
    self:SyncCurr(gtCurrType.eVIP, self.m_nVIP) --同步

    self.m_oVIP:OnVIPChange()
    goOfflineDataMgr:UpdateVIP(self, self.m_nVIP) --离线玩家

    goLogger:UpdateAccountLog(self, {vip=self.m_nVIP})  --更新
    goLogger:EventLog(gtEvent.eSetVIP, self, sReason, self.m_nVIP, nOrgVIP) --日志
    self:MarkDirty(true)
end

--元宝
function CPlayer:AddYuanBao(nCount, bFlyWord)
    if nCount == 0 then return end
    self.m_nYuanBao = math.max(0, math.min(nMAX_INTEGER, self.m_nYuanBao+nCount))
    self:SyncCurr(gtCurrType.eYuanBao, self.m_nYuanBao, bFlyWord)
    self:MarkDirty(true)
    if nCount < 0 then --累计消耗银两
        goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_nCharID, gtTAType.eYB, -nCount)
    end
    return self.m_nYuanBao
end

--银两
function CPlayer:AddYinLiang(nCount, bFlyWord)
    if nCount == 0 then return end
    self.m_nYinLiang = math.max(0, math.min(nMAX_INTEGER, self.m_nYinLiang+nCount))
    self:SyncCurr(gtCurrType.eYinLiang, self.m_nYinLiang, bFlyWord)
    self:MarkDirty(true)
    if nCount < 0 then --累计消耗银两
        goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_nCharID, gtTAType.eYL, -nCount)
    end
    return self.m_nYinLiang
end

--粮草
function CPlayer:AddLiangCao(nCount, bFlyWord)
    if nCount == 0 then return end
    -- self.m_nLiangCao = math.max(0, math.min(nMAX_INTEGER, self.m_nLiangCao+nCount))
    -- self:SyncCurr(gtCurrType.eLiangCao, self.m_nLiangCao, bFlyWord)
    -- self:MarkDirty(true)
    -- if nCount < 0 then --累计消耗粮草
    --     goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_nCharID, gtTAType.eLC, -nCount)
    -- end
    -- return self.m_nLiangCao
end

--兵力
function CPlayer:AddBingLi(nCount, bFlyWord)
    if nCount == 0 then return end
    self.m_nBingLi = math.max(0, math.min(nMAX_INTEGER, self.m_nBingLi+nCount))
    self:SyncCurr(gtCurrType.eBingLi, self.m_nBingLi, bFlyWord)
    self:MarkDirty(true)
    if nCount < 0 then --累计消耗兵力
        goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_nCharID, gtTAType.eBL, -nCount)
    end
    return self.m_nBingLi
end

--姻缘点
function CPlayer:AddTiLi(nCount, bFlyWord)
    if nCount == 0 then return end
    self.m_nTiLi = math.max(0, math.min(self:GetMaxTiLi(), self.m_nTiLi+nCount))
    self:SyncCurr(gtCurrType.eTiLi, self.m_nTiLi, bFlyWord)
    self:MarkDirty(true)
    self:CheckTiLiRecover()
    self.m_oChuXiuGong:CheckRedPoint()
    return self.m_nTiLi
end

--精力
function CPlayer:AddJingLi(nCount, bFlyWord)
    if nCount == 0 then return end
    self.m_nJingLi = math.max(0, math.min(self:GetMaxJingLi(), self.m_nJingLi+nCount))
    self:SyncCurr(gtCurrType.eJingLi, self.m_nJingLi, bFlyWord)
    self:MarkDirty(true)
    self:CheckJingLiRecover()
    return self.m_nJingLi
end

--外交上限
function CPlayer:UpdateMaxWaiJiao()
    local nOrgMaxWaiJiao = self.m_nMaxWaiJiao
    self.m_nMaxWaiJiao = (self.m_oDup:MaxChapterPass()*2400)
    if nOrgMaxWaiJiao ~= self.m_nMaxWaiJiao then
        self:MarkDirty(true)
    end
end

--外交
function CPlayer:AddWaiJiao(nCount, bFlyWord)
    if nCount == 0 then return end
    local nMaxWaiJiao = self:MaxWaiJiao()
    self.m_nWaiJiao = math.max(0, math.min(nMaxWaiJiao, self.m_nWaiJiao+nCount))
    self:SyncCurr(gtCurrType.eWaiJiao, self.m_nWaiJiao, bFlyWord)
    self:MarkDirty(true)
    self.m_oLiFanYuan:OnWaiJiaoChange()
    return self.m_nWaiJiao
end

--势力
function CPlayer:AddShiLi(nCount, bFlyWord)
    if nCount == 0 then return end
    self.m_nShiLi = math.max(0, math.min(nMAX_INTEGER, self.m_nShiLi+nCount))
    self:SyncCurr(gtCurrType.eShiLi, self.m_nShiLi, bFlyWord)
    self:MarkDirty(true)
    if nCount > 0 then
        self.m_nHistoryShiLi = self.m_nHistoryShiLi + nCount
        goRankingMgr.m_oSLRanking:Update(self, self.m_nHistoryShiLi)
    end
    return self.m_nShiLi
end

--威望加/减
function CPlayer:AddWeiWang(nCount, bFlyWord)
    if nCount == 0 then return end
    self.m_nWeiWang = math.max(0, math.min(nMAX_INTEGER, self.m_nWeiWang+nCount))
    self:SyncCurr(gtCurrType.eWeiWang, self.m_nWeiWang, bFlyWord)
    goOfflineDataMgr:UpdateWeiWang(self, self.m_nWeiWang)
    goRankingMgr.m_oWWRanking:Update(self.m_nCharID, self.m_nWeiWang)
    self:MarkDirty(true)
    return self.m_nWeiWang
end

--文化值加/减
function CPlayer:AddWenHua(nCount)
    if nCount == 0 then return end
    self.m_nWenHua = math.max(0, math.min(nMAX_INTEGER, self.m_nWenHua+nCount))
    self:MarkDirty(true)
    self:SyncCurr(gtCurrType.eWenHua, self.m_nWenHua, bFlyWord)
    if nCount < 0 then --累计消耗文化
        goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_nCharID, gtTAType.eWH, -nCount)
    end
    return self.m_nExp
end

--国家经验加/减
function CPlayer:AddExp(nCount)
    if nCount == 0 then return end
    self.m_nExp = math.max(0, math.min(nMAX_INTEGER, self.m_nExp+nCount))
    self:MarkDirty(true)
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerLevelRet", {nLevel=self.m_nLevel, nMaxLevel=#ctLevelConf, nExp=self.m_nExp, nNextExp=self:GetNextExp()})
    return self.m_nExp
end

--检测升级
function CPlayer:UpgradeReq()
    if self.m_nLevel >= #ctLevelConf then
        return self:Tips("已达到最高等级")
    end
    local tConf = ctLevelConf[self.m_nLevel]
    if self.m_nExp >= tConf.nNeedExp then
        self.m_nExp = self.m_nExp - tConf.nNeedExp
        self.m_nLevel = self.m_nLevel + 1
        self:MarkDirty(true)
    end

    goOfflineDataMgr:UpdateLevel(self, self.m_nLevel)
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerLevelRet", {nLevel=self.m_nLevel, nMaxLevel=#ctLevelConf, nExp=self.m_nExp, nNextExp=self:GetNextExp()})
    
    --任务
    self.m_oMainTask:Progress(gtMainTaskType.eCond37, self.m_nLevel, nil, true)
    --成就
    self.m_oAchievements:SetAchievement(gtAchieDef.eCond2, self.m_nLevel, true)
    --内阁等级变化
    self.m_oNeiGe:OnLevelChange()
    goLogger:EventLog(gtEvent.eCountryUpgrade, self, self.m_nLevel, self.m_nExp)
end

--国力更新
function CPlayer:UpdateGuoLi(sFrom)
    print("CPlayer:UpdateGuoLi***", sFrom)
    -- 势力 = 国家总智力 + 国家总才力 + 国家总魅力 + 国家总武力
    -- 国家总智力 = 1000 + 知己智力总值 + 宠物智力总值 + 时装智力总值 + 获得知己后的智力加成
    -- 国家总才力 = 1000 + 知己才力总值 + 宠物才力总值 + 时装才力总值 + 获得知己后的才力加成
    -- 国家总魅力 = 1000 + 知己魅力总值 + 宠物魅力总值 + 时装魅力总值 + 获得知己后的魅力加成
    -- 国家总武力 = 1000 + 知己武力总值 + 宠物武力总值 + 时装武力总值 + 获得知己后的武力加成

    local nOrgGuoLi = self.m_nGuoLi
    self.m_nGuoLi = 0

    local tOrgAttr = self.m_tAttr
    self.m_tAttr = {0, 0, 0, 0}

    print("----------------计算属性---------------", self.m_sName)
    --名臣
    local tMinChen = self.m_oMingChen:GetTotalAttr()
    print("知己***", tMinChen)

    --后宫
    -- local tJianZhu = self.m_oJianZhu:GetTotalAttr()
    -- print("后宫***", tJianZhu)

    --妃子
    -- local tFeiZi = self.m_oFeiZi:GetTotalAttr()
    -- print("妃子***", tFeiZi)

    --子女/配偶
    local tHZAttr = self.m_oZongRenFu:GetTotalAttr()
    print("子女***", tHZAttr)

    local tPOAttr = self.m_oZongRenFu:GetTotalPOAttr()
    print("配偶***", tPOAttr)

    local tCLAttrPer = self.m_oZongRenFu:GetCLAttrPer()
    print("彩礼百分比加成", tCLAttrPer)

   --时装 
   local tFashionAttr = self.m_oFashion:GetFashionAttr()

    --计算总属性和国力
    for k = 1, 4 do
        self.m_tAttr[k] = 1000 + (tMinChen[k] or 0)
        self.m_tAttr[k] = self.m_tAttr[k] + (tHZAttr[k] or 0)
        self.m_tAttr[k] = self.m_tAttr[k] + (tPOAttr[k] or 0)
        self.m_tAttr[k] = self.m_tAttr[k] + (tFashionAttr[k] or 0)
        self.m_tAttr[k] = math.floor(self.m_tAttr[k]*(1+tCLAttrPer[k]))
        
        self.m_nGuoLi = math.min(nMAX_INTEGER, self.m_nGuoLi+self.m_tAttr[k])
        --同步属性
        if self.m_tAttr[k] ~= tOrgAttr[k] then
            self:MarkDirty(true)
            self:SyncCurr(gtAttrMap[k], self.m_tAttr[k])
        end
    end
    print("总计***", "属性:", self.m_tAttr, "国力:", self.m_nGuoLi, "国力增加:", self.m_nGuoLi-nOrgGuoLi)

    --同步国力
    if self.m_nGuoLi ~= nOrgGuoLi then
        --繁荣度
        local nFlourish = self:GetFlourish()
        for k=#ctWFSFFlourishConf, nFlourish, -1 do 
            if self.m_nGuoLi >= ctWFSFFlourishConf[k].nSL then 
                self.m_nFlourish = k 
            end 
        end
        self:MarkDirty(true)

        self:SyncCurr(gtCurrType.eGuoLi, self.m_nGuoLi) --同步属性
        goRankingMgr.m_oGLRanking:Update(self, self.m_nGuoLi, self.m_tAttr) --更新排行榜
        --联盟
        local oUnion = goUnionMgr:GetUnionByCharID(self.m_nCharID)
        if oUnion then oUnion:UpdateGuoLi() end
        --任务
        self.m_oMainTask:Progress(gtMainTaskType.eCond25, self.m_nGuoLi, nil, true)
        --成就
        self.m_oAchievements:SetAchievement(gtAchieDef.eCond3, self.m_nGuoLi, true)
    end
end

--同步货币
function CPlayer:SyncCurr(nCurrType, nCurrValue, bFlyWord)
    assert(nCurrType and nCurrValue, "参数错误")
    bFlyWord = bFlyWord and true or false
    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerCurrSync", {nCurrType=nCurrType, nCurrValue=nCurrValue, bFlyWord=bFlyWord})
end

--同步玩家初始数据
function CPlayer:SyncInitData()
    local tInfo = {}
    tInfo.nCharID = self.m_nCharID
    tInfo.nSource = self.m_nSource
    tInfo.sName = self.m_sName
    tInfo.nVIP = self.m_nVIP
    tInfo.nYuanBao = self.m_nYuanBao
    tInfo.nYinLiang = self.m_nYinLiang
    tInfo.nLiangCao = self.m_nLiangCao
    tInfo.nBingLi = self.m_nBingLi
    tInfo.nTiLi = self.m_nTiLi
    tInfo.nJingLi = self.m_nJingLi
    tInfo.nGuoLi = self.m_nGuoLi
    tInfo.nWaiJiao = self.m_nWaiJiao
    tInfo.nShiLi = self.m_nShiLi
    tInfo.tAttr = self.m_tAttr
    tInfo.nServerID = goServerMgr:GetServerID() 
    tInfo.sServerName = goServerMgr:GetServerName()
    tInfo.nCreateTime = self.m_nCreateTime
    tInfo.nZoneID = goServerMgr:GetDisplayID()
    tInfo.nLevel = self.m_nLevel
    tInfo.nMaxLevel = #ctLevelConf
    tInfo.nExp = self.m_nExp
    tInfo.nNextExp = self:GetNextExp()
    tInfo.nHeadID = 0 --fix pd
    tInfo.nGongDou = 0 --fix pd
    tInfo.nWenHua = self.m_nWenHua

    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerInitDataSync", tInfo)
end 

--玩家上线
function CPlayer:Online()
    print("CPlayer:Online***", self.m_sAccount, self.m_nSource)
    self.m_nOnlineTime = os.time()
    self:RegAutoSaveTick() --定时保存
    self:MarkDirty(true)
    self:ClientReady()
end

--前端准备好了
function CPlayer:ClientReady()
    --离线玩家模块
    goOfflineDataMgr:Online(self)
    --各模块上线(可能有依赖关系所以用list)
    for _, oModule in ipairs(self.m_tModuleList) do
        oModule:Online()
    end
    --公会
    goUnionMgr:Online(self)
    --活动
    goHDMgr:Online(self)
    --聊天记录
    goTalk:Online(self)
    --同步初始数据
    self:SyncInitData()
end

--玩家下线
function CPlayer:Offline()
    self.m_nSession = 0
    self.m_nOfflineTime = os.time()
    for nModuleID, oModule in pairs(self.m_tModuleMap) do
        oModule:Offline()
    end
    self:MarkDirty(true)
    self:SaveData()
    self:CancelAutoSaveTick()
end

--物品数量
function CPlayer:GetItemCount(nItemType, nItemID)
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

        elseif nItemID == gtCurrType.eYinLiang then
            return self:GetYinLiang()

        elseif nItemID == gtCurrType.eLiangCao then
            return self:GetLiangCao()

        elseif nItemID == gtCurrType.eBingLi then
            return self:GetBingLi()

        elseif nItemID == gtCurrType.eTiLi then
            return self:GetTiLi()

        elseif nItemID == gtCurrType.eMaxTiLi then
            return self:GetMaxTiLi()

        elseif nItemID == gtCurrType.eJingLi then
            return self:GetJingLi()

        elseif nItemID == gtCurrType.eMaxJingLi then
            return self:GetMaxJingLi()

        elseif nItemID == gtCurrType.eWaiJiao then
            return self:GetWaiJiao()

        elseif nItemID == gtCurrType.eShiLi then
            return self:GetShiLi()

        elseif nItemID == gtCurrType.eWeiWang then
            return self:GetWeiWang()

        else
            assert(false, "不支持货币类型:"..nItemID)
        end

    else
        assert(false, "不支持物品类型:"..nItemType)
    end
end

--扣除物品
function CPlayer:SubItem(nItemType, nItemID, nItemNum, sReason, bFlyWord)
    assert(sReason, "删除物品原因缺失")
    if not (nItemType > 0 and nItemID > 0 and nItemNum) then return self:Tips("参数错误") end
    if nItemNum == 0 then return end
    return self:AddItem(nItemType, nItemID, -nItemNum, sReason, bFlyWord)
end

--添加物品
function CPlayer:AddItem(nItemType, nItemID, nItemNum, sReason, bFlyWord)
    assert(sReason, "添加物品原因缺失")
    if not (nItemType > 0 and nItemID > 0 and nItemNum) then
        return self:Tips("参数错误:"..nItemType..":"..nItemID..":"..nItemNum)
    end
    if nItemNum == 0 then
        return
    end

    local bRes = true
    if nItemType == gtItemType.eProp then
        local tConf = ctPropConf[nItemID]
        if not tConf then return self:Tips("道具表找不到道具:"..nItemID) end
        if tConf.nType == gtPropType.eCurr then
            if tConf.nSubType == gtCurrType.eQinMi then --知己亲密度
                bRes = self.m_oMingChen:AddQinMi(tConf.nVal, nItemNum)
            else
                return self:AddItem(gtItemType.eCurr, tConf.nSubType, nItemNum, sReason, bFlyWord)
            end
        else   
            if nItemNum > 0 then
                bRes = self.m_oGuoKu:AddItem(nItemID, nItemNum)
            else
                bRes = self.m_oGuoKu:SubItem(nItemID, nItemNum)
            end
        end

    elseif nItemType == gtItemType.eGongNv then
        -- if not ctGongNvConf[nItemID] then return self:Tips("宫女表找不到:"..nItemID) end
        -- if nItemNum ~= 1 then return self:Tips("宫女只能一个个加:"..nItemNum) end
        -- bRes = self.m_oChuXiuGong:AddGongNv(nItemID)

    elseif nItemType == gtItemType.eFeiZi then
        -- if not ctFeiZiConf[nItemID] then return self:Tips("妃子表找不到:"..nItemID) end
        -- if nItemNum ~= 1 then self:Tips("妃子只能一个个加:"..nItemNum) end
        -- bRes = self.m_oFeiZi:Create(nItemID)

    elseif nItemType == gtItemType.eFashion then
        bRes = self.m_oFashion:AddFashion(nItemID)

    elseif nItemType == gtItemType.eMingChen then
        if not ctMingChenConf[nItemID] then return self:Tips("知己表找不到:"..nItemID) end
        if nItemNum ~= 1 then self:Tips("知己只能一个个加:"..nItemNum) end
        bRes = self.m_oMingChen:Create(nItemID)

    elseif nItemType == gtItemType.eCurr then
        if nItemID == gtCurrType.eYuanBao then
            bRes = self:AddYuanBao(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eYinLiang then
            bRes = self:AddYinLiang(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eLiangCao then
            -- bRes = self:AddLiangCao(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eBingLi then
            bRes = self:AddBingLi(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eTiLi then
            bRes = self:AddTiLi(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eJingLi then
            bRes = self:AddJingLi(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eWaiJiao then
            bRes = self:AddWaiJiao(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eShiLi then
            -- bRes = self:AddShiLi(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eWeiWang then
            -- bRes = self:AddWeiWang(nItemNum, bFlyWord)

        elseif nItemID == gtCurrType.eVIPExp then
            bRes = self.m_oVIP:AddVIPExp(nItemNum)

        elseif nItemID == gtCurrType.eCountryExp then
            bRes = self:AddExp(nItemNum)

        elseif nItemID == gtCurrType.eCSScore then
            bRes = self.m_oJunJiChu:AddCSScore(nItemNum)

        elseif nItemID == gtCurrType.eWenHua then
            bRes = self:AddWenHua(nItemNum)

        elseif nItemID == gtCurrType.eActivity then
            bRes = self.m_oDailyTask:AddActivity(nItemNum)
            
        else
            return self:Tips("不支持货币类型:"..nItemID)
        end

    else
        return self:Tips("不支持添加物品类型:"..nItemType)
    end
    if bRes then
        local nEventID = nItemNum > 0 and gtEvent.eAddItem or gtEvent.eSubItem
        goLogger:AwardLog(nEventID, sReason, self, nItemType, nItemID, math.abs(nItemNum), bRes)
    end
    return bRes
end

--取家信息请求
function CPlayer:GetInfo()
    --显示昵称，VIP等级，国力，编号，商业，政治，农业，军事，亲密度，子嗣数，威望以及通关地图
    local tInfo = {}
    tInfo.nCharID = self.m_nCharID
    tInfo.sCharName = self.m_sName
    tInfo.nVIP = self.m_nVIP
    tInfo.nLevel = self.m_nLevel
    tInfo.nExp = self.m_nExp
    tInfo.nGuoLi = self.m_nGuoLi
    tInfo.tAttr = self.m_tAttr

    local tData = goRankingMgr.m_oQMRanking.m_oRanking:GetDataByKey(self.m_nCharID)
    tInfo.nQinMi = tData and tData[2] or 0
    tInfo.nFeiZiNum =  0
    local tData = goRankingMgr.m_oNLRanking.m_oRanking:GetDataByKey(self.m_nCharID)
    tInfo.nNengLi = tData and tData[2] or 0
    tInfo.nChildNum = self.m_oZongRenFu:GetChildNum()
    local tData = goRankingMgr.m_oCDRanking.m_oRanking:GetDataByKey(self.m_nCharID)
    tInfo.nCaiDe = tData and tData[2] or 0

    tInfo.nYL = self:GetYinLiang()
    tInfo.nLC = self:GetLiangCao()
    tInfo.nBL = self:GetBingLi()

    tInfo.nWeiWang = self.m_nWeiWang
    tInfo.nChapter = self.m_oDup:MaxChapterPass()
    return tInfo
end

--玩家改名
function CPlayer:ModName(sCharName)
    local nNameLen = string.len(sCharName) 
    if nNameLen <= 0 or nNameLen > 6*3 then
        return self:Tips("昵称长度非法")
    end
    local nCostYB = 10 --改名需要10元宝
    if self:GetYuanBao() < nCostYB then
        return self:YBDlg()
    end

    --非法字检测
    if GF.HasBadWord(sCharName) then
        return self:Tips("名字含有非法字，操作失败")
    end

    if goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sUniqueNameDB, sCharName) ~= "" then
        return self:Tips("当前昵称已存在，操作失败")
    end
    self:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, -nCostYB, "游戏昵称修改")

    local sOrgName = self.m_sName
    self.m_sName = sCharName
    goOfflineDataMgr:ModName(self)

    goDBMgr:GetSSDB("Player"):HDel(gtDBDef.sUniqueNameDB, sOrgName)
    goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sUniqueNameDB, sCharName, self.m_nCharID)

    CmdNet.PBSrv2Clt(self.m_nSession, "PlayerModNameRet", {sCharName=sCharName})
    self:MarkDirty(true)

    goLogger:UpdateAccountLog(self, {char_name=self.m_sName})  --更新
    self:Tips("成功修改昵称")
end

--取威望(不管在不在线)
function CPlayer:GetWeiWangAnyway(nCharID)
    local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
    if oPlayer then
        return oPlayer:GetWeiWang()
    end
    local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sPlayerDB, nCharID)  
    local tData = cjson.decode(sData)
    return tData.m_nWeiWang
end

--增加威望(不管在不在线)
function CPlayer:AddWeiWangAnyway(nCharID, nVal, sReason)
    if nVal == 0 then return end
    assert(sReason, "没写原因")
    --在线加
    local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
    if oPlayer then
        return oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWeiWang, nVal, sReason)      
    end
    
    --离线加 
    local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sPlayerDB, nCharID)  
    local tData = cjson.decode(sData)
    tData.m_nWeiWang = math.max(0, math.min(nMAX_INTEGER, tData.m_nWeiWang+nVal))
    goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sPlayerDB, nCharID, cjson.encode(tData))  

    goRankingMgr.m_oWWRanking:Update(nCharID, tData.m_nWeiWang)
    local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
    local oOffline = goOfflineDataMgr:GetPlayer(nCharID)
    goLogger:AwardLog(nEventID, sReason, oOffline, gtItemType.eCurr, gtCurrType.eWeiWang, nVal, tData.m_nWeiWang)

    return tData.m_nWeiWang
end

--取外交(不管在不在线)
function CPlayer:GetWaiJiaoAnyway(nCharID)
    local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
    if oPlayer then
        return oPlayer:GetWaiJiao()
    end
    local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sPlayerDB, nCharID)  
    local tData = cjson.decode(sData)
    return tData.m_nWaiJiao
end

--增加外交(不管在不在线)
function CPlayer:AddWaiJiaoAnyway(nCharID, nVal, sReason)
    if nVal == 0 then return end
    assert(sReason, "没写原因")
    --在线加
    local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
    if oPlayer then
        return oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWaiJiao, nVal, sReason)      
    end

    --离线加 
    local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sPlayerDB, nCharID)  
    local tData = cjson.decode(sData)
    tData.m_nWaiJiao = math.max(0, math.min(nMAX_INTEGER, tData.m_nWaiJiao+nVal))
    goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sPlayerDB, nCharID, cjson.encode(tData))  

    local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
    local oOffline = goOfflineDataMgr:GetPlayer(nCharID)
    goLogger:AwardLog(nEventID, sReason, Offline, gtItemType.eCurr, gtCurrType.eWaiJiao, nVal, tData.m_nWaiJiao)

    return tData.m_nWaiJiao
end

--元宝不足弹框
function CPlayer:YBDlg()
    self:Tips("元宝不足")
    -- CmdNet.PBSrv2Clt(self.m_nSession, "YBDlgRet", {})
end

--飘字通知
function CPlayer:Tips(sCont, nSession)
    assert(sCont)
    nSession = nSession or self.m_nSession
    CmdNet.PBSrv2Clt(nSession, "TipsMsgRet", {sCont=sCont})
end

--图标飘字通知
function CPlayer:IconTips(nID, nNum)
    CmdNet.PBSrv2Clt(self.m_nSession, "IconTipsRet", {nID=nID, nNum=nNum})
end
