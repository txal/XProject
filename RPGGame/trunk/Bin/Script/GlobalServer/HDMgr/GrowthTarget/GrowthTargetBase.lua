--开服目标活动

local tActGrowthTargetAwardConf = {}  --{nActID:{nIndexID:tConf, ...}, ...}
for nIndexID, tConf in pairs(ctGrowthTargetAwardConf) do 
    local tActConfMap = tActGrowthTargetAwardConf[tConf.nID] or {}
    tActConfMap[nIndexID] = tConf
    tActGrowthTargetAwardConf[tConf.nID] = tActConfMap
end

local tActGrowthTargetRankAwardConf = {}  --{nActID:{nIndexID:tConf, ...}, ...}
for nIndexID, tConf in pairs(ctGrowthTargetRankConf) do 
    local tActConfMap = tActGrowthTargetRankAwardConf[tConf.nID] or {}
    tActConfMap[nIndexID] = tConf
    tActGrowthTargetRankAwardConf[tConf.nID] = tActConfMap
end

local tActGrowthRechargeAwardConf = {}  --{nActID:{nIndexID:tConf, ...}, ...}
for nIndexID, tConf in pairs(ctGrowthTargetRechargeConf) do 
    local tActConfMap = tActGrowthRechargeAwardConf[tConf.nID] or {}
    tActConfMap[nIndexID] = tConf
    tActGrowthRechargeAwardConf[tConf.nID] = tActConfMap
end


function CGrowthTargetBase:Ctor(nID)
    CHDBase.Ctor(self, nID)
    self:Init()
end

function CGrowthTargetBase:Init()
    local fnCmp = function(tDataL, tDataR) 
        if tDataL > tDataR then 
            return -1
        elseif tDataL < tDataR then 
            return 1
        else
            return 0
        end
    end

    self.m_tRoleMap = {}                --{nRoleID:tRoleData, ...}
    self.m_oTargetRank = CRBTree:new(fnCmp)
    self.m_tRechargeMap = {}            --{nRoleID:nRechargeVal, ...}
    self.m_tTargetRankAwardMap = {}     --{nRoleID:{nRank=, bAccept=, }, ...}

    self.m_tTargetAwardRecord = {}      --{nRoleID:{已领取ID, ...}, ...}
    self.m_tRechargeAwardRecord = {}    --{nRoleID:{已领取ID, ...}, ...}

    self:MarkDirty(true)
end

function CGrowthTargetBase:LoadData() 
    local sData = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID()):HGet(gtDBDef.sHuoDongDB, self:GetID()) 
    if sData == "" then return end

    local tData = cjson.decode(sData)
    CHDBase.LoadData(self, tData)
    self.m_tRoleMap = tData.m_tRoleMap
    self.m_tRechargeMap = tData.m_tRechargeMap
    self.m_tTargetRankAwardMap = tData.m_tTargetRankAwardMap
    self.m_tTargetAwardRecord = tData.m_tTargetAwardRecord
    self.m_tRechargeAwardRecord = tData.m_tRechargeAwardRecord

    local tErrDataList = {}
    for nRoleID, nVal in pairs(self.m_tRoleMap) do 
        if not GF.IsRobot(nRoleID) then --过滤错误的机器人数据
            self.m_oTargetRank:Insert(nRoleID, nVal)
        else
            table.insert(tErrDataList, nRoleID)
        end
    end

    for _, nRoleID in ipairs(tErrDataList) do 
        self.m_tRoleMap[nRoleID] = nil
        self:MarkDirty(true)
    end
end

function CGrowthTargetBase:SaveData() 
    if not self:IsDirty() then
		return
	end      
    local tData = CHDBase.SaveData(self)
	tData.m_tRoleMap = self.m_tRoleMap
    tData.m_tRechargeMap = self.m_tRechargeMap
    tData.m_tTargetRankAwardMap = self.m_tTargetRankAwardMap
    tData.m_tTargetAwardRecord = self.m_tTargetAwardRecord
    tData.m_tRechargeAwardRecord = self.m_tRechargeAwardRecord

	goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID()):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
	self:MarkDirty(false)
end

--更新活动状态
function CGrowthTargetBase:UpdateState()
	CHDBase.UpdateState(self)
end

--进入初始状态
function CGrowthTargetBase:OnStateInit()
	CHDBase.OnStateInit(self)
    goCBMgr:OnStateInit()
    self:MarkDirty(true)
    -- self:SyncActInfo()
end

--进入开始状态
function CGrowthTargetBase:OnStateStart()
    self:Init()
    CHDBase.OnStateStart(self)
    self:MarkDirty(true)
    print(string.format("活动(%d)(%s)开启...", self:GetID(), self:GetName()))
    goGrowthTargetMgr:OnActStart(self:GetID())
    self:SyncActInfo()
end

function CGrowthTargetBase:OnStateAward() 
    CHDBase.OnStateAward(self)
    print(string.format("活动(%d)(%s)进入领奖状态", self:GetID(), self:GetName()))
    goGrowthTargetMgr:OnActAward(self:GetID())
    self:SyncActInfo()
end

function CGrowthTargetBase:SetRankAward()
    print(string.format("设置活动(%d)(%s) 排名奖励", self:GetID(), self:GetName()))
    self.m_tTargetRankAwardMap = {}
    local fnTraverse = function(nRank, nRoleID, nTargetVal)
        local tRoleRank = {nRank = nRank, bAccept = false, }
        self.m_tTargetRankAwardMap[nRoleID] = tRoleRank
        -- print(string.format("设置玩家(%d) 排名(%d)", nRoleID, nRank))
    end
    self.m_oTargetRank:Traverse(1, self.m_oTargetRank:Count(), fnTraverse)
    self:MarkDirty(true)
end

function CGrowthTargetBase:OnStateClose() 
    self:SetRankAward()
    CHDBase.OnStateClose(self)
    self:CheckCloseAward()
    self:MarkDirty(true)
    print(string.format("活动(%d)(%s)关闭...", self:GetID(), self:GetName()))
    goGrowthTargetMgr:OnActClose(self:GetID())
    self:SyncActInfo()
end

function CGrowthTargetBase:CheckCloseAward() 
    for nRoleID, nTargetVal in pairs(self.m_tRoleMap) do 
        --邮件发送活动目标奖励
        local tAwardIndexList = self:GetTargetAwardIndexList(nTargetVal)
        if #tAwardIndexList > 0 then 
            local tTargetAwardList = {} 
            --判断其中部分奖励是否已领取
            local tRecord = self.m_tTargetAwardRecord[nRoleID] or {}
            for _, nIndexID in ipairs(tAwardIndexList) do 
                if not tRecord[nIndexID] then 
                    table.insert(tTargetAwardList, nIndexID)
                end
            end
            if #tTargetAwardList > 0 then 
                --将所有奖励设置为已领取
                for _, nIndexID in ipairs(tTargetAwardList) do 
                    tRecord[nIndexID] = true 
                end
                self.m_tTargetAwardRecord[nRoleID] = tRecord
                self:MarkDirty(true)
                
                local tAwardList = {}
                for _, nIndexID in ipairs(tTargetAwardList) do 
                    local tAwardConf = ctGrowthTargetAwardConf[nIndexID]
                    for k, tAward in ipairs(tAwardConf.tAward) do 
                        local nItemType, nItemID, nItemNum = tAward[1], tAward[2], tAward[3]
                        if nItemType > 0 and nItemID > 0 and nItemNum > 0 then 
                            table.insert(tAwardList, {nItemType, nItemID, nItemNum,})
                        end
                    end
                end
                if #tAwardList > 0 then 
                    local sTitle = string.format("%s活动奖励", self:GetName())
                    local sContent = "未及时领取的活动奖励，请查收"

                    local tMailItemList = {}
                    for _, tItem in ipairs(tAwardList) do 
                        table.insert(tMailItemList, tItem)
                        if #tMailItemList >= gnMaxMailItemLength then 
                            GF.SendMail(gnServerID, sTitle, sContent, tMailItemList, nRoleID)
                            tMailItemList = {}
                        end
                    end
                    if #tMailItemList > 0 then 
                        GF.SendMail(gnServerID, sTitle, sContent, tMailItemList, nRoleID)
                    end
                end
            end
        end

        --充值奖励
        local nRechargeVal = self.m_tRechargeMap[nRoleID] or 0
        local tAwardIndexList = self:GetRechargeAwardIndexList(nRechargeVal)
        if #tAwardIndexList > 0 then 
            local tRechargeAwardList = {} 
            --判断其中部分奖励是否已领取
            local tRecord = self.m_tRechargeAwardRecord[nRoleID] or {}
            for _, nIndexID in ipairs(tAwardIndexList) do 
                if not tRecord[nIndexID] then 
                    table.insert(tRechargeAwardList, nIndexID)
                end
            end
            if #tRechargeAwardList > 0 then 
                --将所有奖励设置为已领取
                for _, nIndexID in ipairs(tRechargeAwardList) do 
                    tRecord[nIndexID] = true
                end
                self.m_tTargetAwardRecord[nRoleID] = tRecord
                self:MarkDirty(true)

                local tAwardList = {}
                for _, nIndexID in ipairs(tRechargeAwardList) do 
                    local tAwardConf = ctGrowthTargetRechargeConf[nIndexID]
                    for k, tAward in ipairs(tAwardConf.tAward) do 
                        local nItemType, nItemID, nItemNum = tAward[1], tAward[2], tAward[3]
                        if nItemType > 0 and nItemID > 0 and nItemNum > 0 then 
                            table.insert(tAwardList, {nItemType, nItemID, nItemNum,})
                        end
                    end
                end
                if #tAwardList > 0 then
                    local sTitle = string.format("%s活动奖励", self:GetName())
                    local sContent = "未及时领取的活动充值奖励，请查收"
                    local tMailItemList = {}
                    for _, tItem in ipairs(tAwardList) do 
                        table.insert(tMailItemList, tItem)
                        if #tMailItemList >= gnMaxMailItemLength then 
                            GF.SendMail(gnServerID, sTitle, sContent, tMailItemList, nRoleID)
                            tMailItemList = {}
                        end
                    end
                    if #tMailItemList > 0 then 
                        GF.SendMail(gnServerID, sTitle, sContent, tMailItemList, nRoleID)
                    end
                end
            end
        end

        --排名奖励
        local tRoleRank = self.m_tTargetRankAwardMap[nRoleID]
        if tRoleRank and not tRoleRank.bAccept then 
            tRoleRank.bAccept = true 
            local nRank = tRoleRank.nRank
            local nRankAwardIndex = self:GetRankAwardIndex(nRank)
            if nRankAwardIndex > 0 then 
                local tRankAwardConf = ctGrowthTargetRankConf[nRankAwardIndex]
                assert(tRankAwardConf)
                local tAwardList = {}
                for _, tAwardConf in ipairs(tRankAwardConf.tAward) do 
                    local nAwardType = tAwardConf[1]
                    local nAwardID = tAwardConf[2]
                    local nAwardNum = tAwardConf[3]
                    if nAwardType > 0 and nAwardID > 0 and nAwardNum > 0 then 
                        table.insert(tAwardList, {nAwardType, nAwardID, nAwardNum,})
                    end
                end
                local nActVal = self:GetRoleActValue(nRoleID)
                if nActVal >= tRankAwardConf.nExtraAwardLimit then 
                    for _, tAwardConf in ipairs(tRankAwardConf.tExtraAward) do 
                        local nAwardType = tAwardConf[1]
                        local nAwardID = tAwardConf[2]
                        local nAwardNum = tAwardConf[3]
                        if nAwardType > 0 and nAwardID > 0 and nAwardNum > 0 then 
                            table.insert(tAwardList, {nAwardType, nAwardID, nAwardNum,})
                        end
                    end
                end
                if #tAwardList > 0 then
                    local sTitle = string.format("%s活动排名奖励", self:GetName())
                    local sContent = string.format("%s活动中排名第%d，这是此次活动的排名奖励，请查收", self:GetName(), nRank)
                    local tMailItemList = {}
                    for _, tItem in ipairs(tAwardList) do 
                        table.insert(tMailItemList, tItem)
                        if #tMailItemList >= gnMaxMailItemLength then 
                            GF.SendMail(gnServerID, sTitle, sContent, tMailItemList, nRoleID)
                            tMailItemList = {}
                        end
                    end
                    if #tMailItemList > 0 then 
                        GF.SendMail(gnServerID, sTitle, sContent, tMailItemList, nRoleID)
                    end
                end 

                if nActVal >= tRankAwardConf.nExtraAwardLimit and tRankAwardConf.nTitle > 0 then 
                    local nAppeID = tRankAwardConf.nTitle
                    if ctAppellationConf[nAppeID] then 
                        local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
                        if oRole then 
                            oRole:AddAppellation(nAppeID, nil, nil, "开服目标活动")
                        end
                    else
                        LuaTrace(string.format("配置错误, 称谓(%d)不存在！！！", nAppeID))
                        LuaTrace(debug.traceback())
                    end
                end
            end
        end
        self:MarkDirty(true)
    end
end

--增加活动数据
function CGrowthTargetBase:AddTargetVal(nRoleID, nVal)
    if nRoleID <= 0 or nVal == 0 then 
        return 
    end
    if not self:IsOpen() then 
        return 
    end
    self.m_tRoleMap[nRoleID] = (self.m_tRoleMap[nRoleID] or 0) + nVal
    local nNewVal = self.m_tRoleMap[nRoleID]
    assert(nNewVal)
    self.m_oTargetRank:Update(nRoleID, nNewVal)
    self:MarkDirty(true)
end

--更新活动数据
function CGrowthTargetBase:UpdateTargetVal(nRoleID, nVal)
    nVal = math.floor(nVal)
    if nRoleID <= 0 or nVal < 0 then --直接调用Update的，允许0值通过
        return 
    end
    if GF.IsRobot(nRoleID) then 
        return 
    end
    if not self:IsOpen() then 
        return 
    end
    local nOldVal = self.m_tRoleMap[nRoleID]
    if nOldVal and nOldVal == nVal then --没必要更新
        return 
    end

    self.m_tRoleMap[nRoleID] = nVal
    self:MarkDirty(true)
    self.m_oTargetRank:Update(nRoleID, nVal)
end

function CGrowthTargetBase:RemoveTargetVal(nRoleID)
    self.m_tRoleMap[nRoleID] = nil
    self.m_oTargetRank:Remove(nRoleID)
    self:MarkDirty(true)
end

--填加充值数据
function CGrowthTargetBase:AddRechargeVal(nRoleID, nVal)
    if nRoleID <= 0 or nVal == 0 then 
        return 
    end
    if GF.IsRobot(nRoleID) then 
        return 
    end
    if not self:IsOpen() then 
        return 
    end
    self.m_tRechargeMap[nRoleID] = (self.m_tRechargeMap[nRoleID] or 0) + nVal
    self:MarkDirty(true)
end

function CGrowthTargetBase:OnRelease() 
    self:SaveData()
end

function CGrowthTargetBase:GetTargetRank(nRoleID) 
    return self.m_oTargetRank:GetIndex(nRoleID)
end

function CGrowthTargetBase:GetRechargeValue(nRoleID)
    return self.m_tRechargeMap[nRoleID] or 0
end

--获取排名奖励配置索引ID
function CGrowthTargetBase:GetRankAwardIndex(nRank)
    if nRank <= 0 then 
        return 0
    end
    local tActRankConf = tActGrowthTargetRankAwardConf[self:GetID()]
    if not tActRankConf then 
        return 0 
    end
    for nIndexID, tRankConf in pairs(tActRankConf) do 
        local tRank = tRankConf.tRank[1]
        if tRank[1] <= nRank and tRank[2] >= nRank then 
            return nIndexID
        end
    end
    return 0
end

--获取活动目标值可领取的奖励ID列表
function CGrowthTargetBase:GetTargetAwardIndexList(nTargetVal)
    local tAwardConf = tActGrowthTargetAwardConf[self:GetID()]
    if not tAwardConf then 
        return {} 
    end
    local tIndexList ={}
    for nIndexID, tConf in pairs(tAwardConf) do 
        if nTargetVal >= tConf.nTargetVal then 
            table.insert(tIndexList, nIndexID)
        end
    end
    return tIndexList
end

--获取充值金额可领取的充值奖励ID
function CGrowthTargetBase:GetRechargeAwardIndexList(nRechargeVal)
    local tAwardConf = tActGrowthRechargeAwardConf[self:GetID()]
    if not tAwardConf then 
        return {} 
    end
    local tIndexList ={}
    for nIndexID, tConf in pairs(tAwardConf) do 
        if nRechargeVal >= tConf.nRechargeVal then 
            table.insert(tIndexList, nIndexID)
        end
    end
    return tIndexList
end

--获取玩家活动数值
function CGrowthTargetBase:GetRoleActValue(nRoleID) 
    return self.m_tRoleMap[nRoleID] or 0
end

function CGrowthTargetBase:IsJoinAct(nRoleID)
    return self.m_tRoleMap[nRoleID] and true or false
end

--同步活动信息
function CGrowthTargetBase:GetActInfo(nRoleID) 
    local tData = {}
    tData.nID = self:GetID()
    tData.nState = self:GetState()
    local nBeginTime, nEndTime, nStateTime =  self:GetStateTime()
    tData.nStateTime = nStateTime
    tData.nActVal = self:GetRoleActValue(nRoleID)
    tData.nRank = self:GetTargetRank(nRoleID)
    tData.nRechargeNum = self:GetRechargeValue(nRoleID)
    local tTargetAwardRecord = {}
    local tRoleRecord = self.m_tTargetAwardRecord[nRoleID]
    if tRoleRecord then 
        for nIndexID, _ in pairs(tRoleRecord) do 
            table.insert(tTargetAwardRecord, nIndexID)
        end
    end
    tData.tTargetAwardRecord = tTargetAwardRecord

    local tRechargeAwardRecord = {}
    local tRoleRecord = self.m_tRechargeAwardRecord[nRoleID]
    if tRoleRecord then 
        for nIndexID, _ in pairs(tRoleRecord) do 
            table.insert(tRechargeAwardRecord, nIndexID)
        end
    end
    tData.tRechargeAwardRecord = tRechargeAwardRecord

    local nRankAwardState = 1
    local tRankRecord = self.m_tTargetRankAwardMap[nRoleID]
    if tRankRecord and self:IsAward() then 
        if not tRankRecord.bAccept then 
            nRankAwardState = 2
        else
            nRankAwardState = 3
        end
    end
    tData.nRankAwardState = nRankAwardState
    return tData
end

function CGrowthTargetBase:SyncActInfo(oRole) 
    if oRole then 
        if not oRole:IsOnline() then 
            return 
        end
        local tData = self:GetActInfo(oRole:GetID())
        oRole:SendMsg("GrowthTargetActInfoRet", tData)
    else
        local tSessionMap = goGPlayerMgr:GetRoleSSMap()
        for nSession, oTmpRole in pairs(tSessionMap) do
            local tData = self:GetActInfo(oTmpRole:GetID())
            oTmpRole:SendMsg("GrowthTargetActInfoRet", tData)
		end
    end
end

--同步活动排行榜信息
function CGrowthTargetBase:SyncRankInfo(oRole, nPageID)
    if not oRole or not oRole:IsOnline() then 
        return 
    end
    if nPageID <= 0 then 
        oRole:Tips("参数错误")
        return 
    end

    local tMsg = {}
    tMsg.nActID = self:GetID()

    local nPageNum = 30  --每页数据
    local nTotalCount = self.m_oTargetRank:Count()
    local nMaxPageID = math.ceil(nTotalCount / nPageNum)
    local nRankBegin = (nPageID - 1)*nPageNum + 1
    local nRankEnd = math.min(nPageID*nPageNum, nTotalCount)

    if nTotalCount > 0 then 
        if nMaxPageID < nPageID then 
            oRole:Tips("没有更多数据了")
            return 
        end
        tMsg.nMaxPageID = nMaxPageID
        tMsg.nPageID = nPageID

        local tRankList = {}
        local fnTraverse = function(nRank, nTarRoleID, nVal) 
            local tRoleRank = {}
            tRoleRank.nRank = nRank
            tRoleRank.nID = nTarRoleID
            local oTempRole = goGPlayerMgr:GetRoleByID(nTarRoleID)

            tRoleRank.sName = oTempRole:GetName()
            tRoleRank.nRoleConfID = oTempRole:GetConfID()
            tRoleRank.nVal = nVal
            if 1 == nRank then 
                tRoleRank.nLevel = oTempRole:GetLevel()
                tRoleRank.tShapeData = oTempRole:GetShapeData()
            end
            table.insert(tRankList, tRoleRank)
        end
        self.m_oTargetRank:Traverse(nRankBegin, nRankEnd, fnTraverse)
        tMsg.tRankList = tRankList
    else
        tMsg.nMaxPageID = 1
        tMsg.nPageID = 1
        tMsg.tRankList = {}
    end

    local nRoleID = oRole:GetID()
    local tMyRank = {}
    tMyRank.nRank = self:GetTargetRank(nRoleID)
    tMyRank.nID = oRole:GetID()
    tMyRank.sName = oRole:GetName()
    tMyRank.nRoleConfID = oRole:GetConfID()
    tMyRank.nVal = self:GetRoleActValue(nRoleID)
    tMsg.tMyRank = tMyRank

    oRole:SendMsg("GrowthTargetActRankInfoRet", tMsg)
    -- print("GrowthTargetActRankInfoRet", tMsg)
end

--领取活动目标奖励
function CGrowthTargetBase:TargetAwardReq(oRole, nIndexID) 
    if not nIndexID or nIndexID <= 0 then 
        return 
    end
    if not self:IsActive() then 
        oRole:Tips("活动已结束")
        return
    end
    local tConf = ctGrowthTargetAwardConf[nIndexID]
    if not tConf then 
        return 
    end
    if self:GetID() ~=  tConf.nID then 
        oRole:Tips("参数错误")
        return 
    end
    local nRoleID = oRole:GetID()
    if self:GetRoleActValue(nRoleID) < tConf.nTargetVal then 
        oRole:Tips("当前未达到可领取条件")
        return 
    end

    local tRoleRecord = self.m_tTargetAwardRecord[nRoleID] or {}
    if tRoleRecord[nIndexID] then 
        oRole:Tips("该奖励已领取")
        return 
    end

    --发放奖励
    local tAwardList = {}
    for _, tAwardConf in ipairs(tConf.tAward) do 
        local nAwardType = tAwardConf[1]
        local nAwardID = tAwardConf[2]
        local nAwardNum = tAwardConf[3]
        if nAwardType > 0 and nAwardID > 0 and nAwardNum > 0 then 
            table.insert(tAwardList, {nType = nAwardType, nID = nAwardID, nNum = nAwardNum})
        end
    end
    if #tAwardList <= 0 then --防止配置错误
        return 
    end
    oRole:AddItem(tAwardList, "开服目标活动")

    local tRoleRecord = self.m_tTargetAwardRecord[nRoleID] or {}
    tRoleRecord[nIndexID] = true 
    self.m_tTargetAwardRecord[nRoleID] = tRoleRecord
    self:MarkDirty(true)
    oRole:Tips("成功领取奖励")
    self:SyncActInfo(oRole)
end

--领取活动排名奖励
function CGrowthTargetBase:RankingAwardReq(oRole) 
    if not self:IsAward() then 
        oRole:Tips("活动结束后才可领取排名奖励")
        return
    end
    local nRoleID = oRole:GetID()
    local tRoleRank = self.m_tTargetRankAwardMap[nRoleID]
    if not tRoleRank then 
        oRole:Tips("不满足领取条件")
        return 
    end
    if tRoleRank.bAccept then 
        oRole:Tips("奖励已领取")
        return 
    end
    local nRank = tRoleRank.nRank
    if nRank <= 0 then 
        return 
    end
    local nRankAwardIndex = self:GetRankAwardIndex(nRank)
    if nRankAwardIndex <= 0 then 
        oRole:Tips("未达到排名领取条件")
        return
    end

    local tRankAwardConf = ctGrowthTargetRankConf[nRankAwardIndex]
    assert(tRankAwardConf)
    local tAwardList = {}
    for _, tAwardConf in ipairs(tRankAwardConf.tAward) do 
        local nAwardType = tAwardConf[1]
        local nAwardID = tAwardConf[2]
        local nAwardNum = tAwardConf[3]
        if nAwardType > 0 and nAwardID > 0 and nAwardNum > 0 then 
            table.insert(tAwardList, {nType = nAwardType, nID = nAwardID, nNum = nAwardNum})
        end
    end
    local nActVal = self:GetRoleActValue(nRoleID)
    if nActVal >= tRankAwardConf.nExtraAwardLimit then 
        for _, tAwardConf in ipairs(tRankAwardConf.tExtraAward) do 
            local nAwardType = tAwardConf[1]
            local nAwardID = tAwardConf[2]
            local nAwardNum = tAwardConf[3]
            if nAwardType > 0 and nAwardID > 0 and nAwardNum > 0 then 
                table.insert(tAwardList, {nType = nAwardType, nID = nAwardID, nNum = nAwardNum})
            end
        end
    end

    tRoleRank.bAccept = true
    self:MarkDirty(true)

    if #tAwardList > 0 then
        oRole:AddItem(tAwardList, "开服目标活动")
    end 
    if nActVal >= tRankAwardConf.nExtraAwardLimit and tRankAwardConf.nTitle > 0 then 
        local nAppeID = tRankAwardConf.nTitle
        if ctAppellationConf[nAppeID] then 
            oRole:AddAppellation(nAppeID, nil, nil, "开服目标活动")
        else
            LuaTrace(string.format("配置错误, 称谓(%d)不存在！！！", nAppeID))
            LuaTrace(debug.traceback())
        end
    end
    self:SyncActInfo(oRole)
end

--领取活动充值奖励
--nIndexID 充值金额奖励ID
function CGrowthTargetBase:RechargeAwardReq(oRole, nIndexID) 
    if not self:IsActive() then 
        oRole:Tips("活动已结束")
        return
    end
    local tConf = ctGrowthTargetRechargeConf[nIndexID]
    if not tConf then 
        return 
    end
    if self:GetID() ~=  tConf.nID then 
        oRole:Tips("参数错误")
        return 
    end

    local nRoleID = oRole:GetID()
    local nRechargeVal = self:GetRechargeValue(nRoleID)
    local tRechargeIndexList = self:GetRechargeAwardIndexList(nRechargeVal)
    local bAward = false
    for _, nAwardIndex in ipairs(tRechargeIndexList) do 
        if nAwardIndex == nIndexID then 
            bAward = true 
            break 
        end
    end
    if not bAward then 
        oRole:Tips("不满足领取条件")
        return 
    end
    local tRecord = self.m_tRechargeAwardRecord[nRoleID] or {}
    if tRecord[nIndexID] then 
        oRole:Tips("该奖励已领取")
        return 
    end

    --发放奖励
    local tConf = ctGrowthTargetRechargeConf[nIndexID]
    local tAwardList = {}
    for _, tAwardConf in ipairs(tConf.tAward) do 
        local nAwardType = tAwardConf[1]
        local nAwardID = tAwardConf[2]
        local nAwardNum = tAwardConf[3]
        if nAwardType > 0 and nAwardID > 0 and nAwardNum > 0 then 
            table.insert(tAwardList, {nType = nAwardType, nID = nAwardID, nNum = nAwardNum})
        end
    end
    if #tAwardList <= 0 then --防止配置错误
        return 
    end
    oRole:AddItem(tAwardList, "开服目标活动充值奖励")

    local tRecord = self.m_tRechargeAwardRecord[nRoleID] or {}
    tRecord[nIndexID] = true 
    self.m_tRechargeAwardRecord[nRoleID] = tRecord
    self:MarkDirty(true)
    oRole:Tips("成功领取奖励")
    self:SyncActInfo(oRole)
end

