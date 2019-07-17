--双倍点数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CShuangBei:Ctor(oRole)
    self.m_oRole = oRole
    self.m_nUseShuangbei = 0        --消耗的双倍点数
    self.m_nUnuseShuangbei = 0      --储存双倍点数
    self.m_bGetedShuangbei = false          --是否已经领过双倍点
    self.m_nUseShuangbeiDanTimes = 0        --使用双倍丹次数
    self.m_nLastUseTimeStamp = 0            --上次使用双倍丹时间戳
    self.m_nLastRewardTimeStamp = 0         --上次奖励双倍点时间戳
end

function CShuangBei:LoadData(tData)
    if tData then
        self.m_nUseShuangbei = tData.m_nUseShuangbei or 0
        self.m_nUnuseShuangbei = tData.m_nUnuseShuangbei or 0
        self.m_bGetedShuangbei = tData.m_bGetedShuangbei or false
        self.m_nUseShuangbeiDanTimes = tData.m_nUseShuangbeiDanTimes or 0
        self.m_nLastUseTimeStamp = tData.m_nLastUseTimeStamp or 0
        self.m_nLastRewardTimeStamp = tData.m_nLastRewardTimeStamp or 0
    end
    --首次初始化数据
    if self.m_nLastRewardTimeStamp <= 0 then
        self.m_nUseShuangbei = 100
        self.m_nUnuseShuangbei = 100        --新手第一天登录默认200可领
        self.m_nLastRewardTimeStamp = os.time()
        self:MarkDirty(true)
    end
end

function CShuangBei:SaveData(oRole)
    if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)

    local tData = {}
    tData.m_nUseShuangbei = self.m_nUseShuangbei
    tData.m_nUnuseShuangbei = self.m_nUnuseShuangbei
    tData.m_bGetedShuangbei = self.m_bGetedShuangbei
    tData.m_nUseShuangbeiDanTimes = self.m_nUseShuangbeiDanTimes
    tData.m_nLastUseTimeStamp = self.m_nLastUseTimeStamp
    tData.m_nLastRewardTimeStamp = self.m_nLastRewardTimeStamp
    return tData
end

function CShuangBei:GetType(oRole)
    return gtModuleDef.tShuangBei.nID, gtModuleDef.tShuangBei.sName
end

function CShuangBei:AddShuangBei(nShuangBei)
    if 0 <= nShuangBei then  --添加时要判断是不是达到上限,大于0说明是存储的，消耗的nShuangBei只有小于0
        if self.m_nUnuseShuangbei < ctShuangBeiConf[1].nMaxSave then
            self.m_nUnuseShuangbei = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nUnuseShuangbei+nShuangBei))
        end
        self:MarkDirty(true)
        return self.m_nUnuseShuangbei
    else
        self.m_nUseShuangbei = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nUseShuangbei+nShuangBei))
        self:MarkDirty(true)
        return self.m_nUseShuangbei
    end
end

function CShuangBei:UseShuangbei()
    if self.m_nUnuseShuangbei <= 0 then
        return self.m_oRole:Tips("没有可领取的双倍点数")
    end

    if self.m_nUseShuangbei >= ctShuangBeiConf[1].nMaxUse then
        return self.m_oRole:Tips("可领取双倍达已到上限")
    end

    local nGetOnce = ctShuangBeiConf[1].nGetOnce
    local nNeed = ctShuangBeiConf[1].nMaxUse - self.m_nUseShuangbei
    if nGetOnce < self.m_nUnuseShuangbei and nGetOnce < nNeed then
        self.m_nUnuseShuangbei = self.m_nUnuseShuangbei - nGetOnce
        self.m_nUseShuangbei = self.m_nUseShuangbei + nGetOnce
    else
        local nTemp = self.m_nUnuseShuangbei
        self.m_nUnuseShuangbei = math.max(0, self.m_nUnuseShuangbei - nNeed)
        self.m_nUseShuangbei = self.m_nUseShuangbei + math.min(nNeed, nTemp)
    end
    self:MarkDirty(true)
end

function CShuangBei:UnuseShuangbei()
    if self.m_nUseShuangbei <= 0 then
        return self.m_oRole:Tips("没有可冻结的双倍点")
    end

    self.m_nUnuseShuangbei = self.m_nUnuseShuangbei + self.m_nUseShuangbei
    self.m_nUseShuangbei = 0
    self:MarkDirty(true)
end

function CShuangBei:GetUseShuangbei()
    return self.m_nUseShuangbei
end

function CShuangBei:OnHourTimer()
    if not os.IsSameDay(self.m_nLastRewardTimeStamp, os.time(), 0) then
        self.m_nLastRewardTimeStamp = os.time()
        self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eShuangBei, ctShuangBeiConf[1].nGetShuangBei, "零点奖励双倍点")
        self.m_bGetedShuangBei = true
        m_nLastRewardTimeStamp = os.time()
        self:MarkDirty(true)
    end

    if not os.IsSameWeek(self.m_nLastUseTimeStamp, os.time()) then
        self.m_nUseShuangBeiDanTimes = 0
        self:MarkDirty(true)
    end
end

function CShuangBei:Online()
    --增加零点免费双倍点数
    if not os.IsSameDay(self.m_nLastRewardTimeStamp, os.time(), 0) then
        local nDays = os.PassDay(self.m_nLastRewardTimeStamp, os.time(), 0)
        local nReward = nDays * ctShuangBeiConf[1].nGetShuangBei
        local nNeed = ctShuangBeiConf[1].nMaxSave - self.m_nUnuseShuangbei
        local nAdd = nReward <= nNeed and nReward or nNeed
        if self.m_nUnuseShuangbei < ctShuangBeiConf[1].nMaxSave then
            self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eShuangBei, nAdd, "每天奖励双倍点数") 
        end
        self.m_bGetedShuangBei = true
        self.m_nLastRewardTimeStamp = os.time()
        self:MarkDirty(true)
    end
end

function CShuangBei:GetMaxUseShuangBeiDan()
    return ctShuangBeiConf[1].nMaxTimes
end

function CShuangBei:AddShuangBeiDanTimes(nTimes)
    assert(nTimes > 0, "双倍丹使用次数错误")
    self.m_nUseShuangbeiDanTimes = self.m_nUseShuangbeiDanTimes + nTimes
    self:MarkDirty(true)
end

function CShuangBei:SetUseShuangBeiDanTime()
    self.m_nLastUseTimeStamp = os.time()
    self:MarkDirty(true)
end

function CShuangBei:GMPrintShuangBei()
    print("使用双倍点:".. self.m_nUseShuangbei .. "    " .. "储存双倍点:".. self.m_nUnuseShuangbei)
end