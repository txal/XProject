--兑换活动管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CExchangeActivityMgr:Ctor()
    self.m_tActivityMap = {}        --兑换活动映射
    self.m_nHourTick = nil          --分钟时间器
    self.m_nSaveTick = nil          --保存计时器

    self:Init()
end

--每个兑换活动都一样
function CExchangeActivityMgr:Init()
    for nActivityID, tConf in ipairs(ctExchangeOpenConf) do
        if tConf.bIsOpen then
            self.m_tActivityMap[nActivityID] = CExchangeActivity:new(nActivityID)
        end
    end
end

function CExchangeActivityMgr:LoadData()
    local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
    local tKeys = oSSDB:HKeys(gtDBDef.sExchangeActDB)
    print("加载兑换活动数据", #tKeys)
    for _, sID in ipairs(tKeys) do
        local nID = tonumber(sID)
        local oAct = self.m_tActivityMap[nID]
        if oAct then
            local sData = oSSDB:HGet(gtDBDef.sExchangeActDB, sID)
            oAct:LoadData(cjson.decode(sData))
        end
    end

    self:RegHourTimer()
end

function CExchangeActivityMgr:SaveData()
    local oSSDB = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID())
	for nID, oAct in pairs(self.m_tActivityMap) do
		if oAct:IsDirty() then
			local tData = oAct:SaveData()
			if tData and next(tData) then
				oSSDB:HSet(gtDBDef.sExchangeActDB, nID, cjson.encode(tData))
				oAct:MarkDirty(false)
			end
		end
	end
end

function CExchangeActivityMgr:OnRelease()
    goTimerMgr:Clear(self.m_nHourTick)
    self.m_nHourTick = nil
    goTimerMgr:Clear(self.m_nSaveTick)
    self.m_nSaveTick = nil
end 

function CExchangeActivityMgr:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CExchangeActivityMgr:IsDirty() return self.m_bDirty end

function CExchangeActivityMgr:RegHourTimer()
    local nNextHourTime = os.NextHourTime(os.time())
    self.m_nHourTick = goTimerMgr:Interval(nNextHourTime, function() self:OnHourTimer() end)
    self.m_nSaveTick = goTimerMgr:Interval(gnAutoSaveTime, function() self:SaveData() end)
end

function CExchangeActivityMgr:OnHourTimer()
    goTimerMgr:Clear(self.m_nHourTick)
    local nNextHourTime = os.NextHourTime(os.time())
    self.m_nHourTick = goTimerMgr:Interval(nNextHourTime, function() self:OnHourTimer() end)
    for nID, oAct in pairs(self.m_tActivityMap) do
        oAct:OnHourTimer()
    end
end

-- function CExchangeActivityMgr:CheckState()
--     for nActID, oAct in pairs(self.m_tActivityMap) do
--         oAct:CheckState()
--     end
-- end

function CExchangeActivityMgr:GetBeginActID()
    local tActIDList = {}
    for nID, oAct in pairs(self.m_tActivityMap) do
        if CExchangeActivity.tState.eBegin == oAct:GetState() then
            table.insert(tActIDList, nID)
        end
    end
    return tActIDList
end

function CExchangeActivityMgr:Online(oRole)
    for nActID, oAct in pairs(self.m_tActivityMap) do
        oAct:Online(oRole)
    end
end

function CExchangeActivityMgr:ExchangeInfoReq(oRole) 
    self:SendAllExchangeInfo(oRole)
end

function CExchangeActivityMgr:ExchangeActClickReq(oRole, nActivityID)
    assert(ctExchangeOpenConf[nActivityID], "兑换活动配置不存在："..nActivityID)
    local oAct = self.m_tActivityMap[nActivityID]
    if not oAct then return end

    if not oAct:GetState() then
        return oRole:Tips("活动尚未开启")
    end
    local nRoleID = oRole:GetID()
    oAct:SetIsClick(nRoleID, true)
    local bIsClick = oAct:GetIsClick(nRoleID)
    oRole:SendMsg("ExchangeActClickRet", {nActID=nActivityID, bIsClick=bIsClick})
end

function CExchangeActivityMgr:ExchangeReq(oRole, nActivityID, nExchangeID)
    assert(ctExchangeOpenConf[nActivityID], "兑换活动配置不存在："..nActivityID)
    local oAct = self.m_tActivityMap[nActivityID]
    if not oAct then return end

    if not oAct:GetState() then
        return oRole:Tips("活动尚未开启")
    end

    --判断兑换次数是否足够
    local tConf = ctExchangeActivityConf.GetConf(nActivityID, nExchangeID)
    assert(tConf, "缺少兑换活动配置")
    local tRoleData = oAct:GetRoleData(oRole:GetID()) or {}
    tRoleData[nExchangeID] = tRoleData[nExchangeID] or 0
    if tConf.nMaxTimes > 0 and tRoleData[nExchangeID] >= tConf.nMaxTimes then
        return oRole:Tips("已达到兑换次数上限")
    end

    --判断材料是否足够
    local tStuffList = {}
    for nKey, tStuff in pairs(tConf.tStuffList) do
        local tTemp = {}
        tTemp.nType = gtItemType.eProp
        tTemp.nID = tStuff[1]
        tTemp.nNum = tStuff[2]
        table.insert(tStuffList, tTemp)
    end

    local function _CallBack(nCostSucc)
        if nCostSucc then
            local tItemList = {}
            for _, tItem in pairs(tConf.tItemList) do
                local tTemp = {}
                tTemp.nType = gtItemType.eProp
                tTemp.nID = tItem[1]
                tTemp.nNum = tItem[2]
                table.insert(tItemList, tTemp) 
            end
            local function UpdateData()
                local nRoleID = oRole:GetID()
                oAct:UpdateExchangeTimes(nRoleID, nExchangeID)
                oAct:UpdateJoinTimestamp(nRoleID, os.time())
                local nExchangeTimes = oAct:GetExchangeTimes(nRoleID, nExchangeID)
                self:SendSingleExchangeInfo(oRole, nActivityID, nExchangeID, nExchangeTimes)
                if tConf.bIsBroad then
                    local nItemID = tConf.tItemList[1][1]
                    local sStr = string.format("可喜可贺，%s通过兑换获得了%s!", oRole:GetName(), ctPropConf[nItemID].sName)
                    GF.SendNotice(oRole:GetServer(), sStr)
                end
            end
            oRole:AddItem(tItemList, "兑换活动兑换", UpdateData)
            goLogger:EventLog(gtEvent.eExchangeAct, oRole, nActivityID, nExchangeID, tRoleData[nExchangeID])
        end
    end
    oRole:SubItemShowNotEnoughTips(tStuffList, "兑换活动兑换", false, true, _CallBack)
end

function CExchangeActivityMgr:SendAllExchangeInfo(oRole)
    local tMsg = {tActInfoList={}}
    local tActIDList = self:GetBeginActID()
    for _, nActID in pairs(tActIDList) do           --只拿开启的活动
        local oAct = self.m_tActivityMap[nActID]
        if oAct then
            local tData = oAct:GetRoleData(oRole:GetID())           --role在该活动的数据
            local tInfo = {nActID=nActID, ExchangeInfoList={}}
            local tActConf = ctExchangeActivityConf.GetActConf(nActID)
            for nExchangeID, tExchangeConf in pairs(tActConf) do
                --local tConf = ctExchangeActivityConf.GetConf(nActID, nExchangeID)
                if tExchangeConf.bIsOpen then         --读取开启的兑换项的数据
                    local tTemp = {}
                    tTemp.nExchangeID = nExchangeID
                    tTemp.nExchangeTimes = tData[nExchangeID] or 0
                    table.insert(tInfo.ExchangeInfoList, tTemp)
                end
            end
            tInfo.bIsClick = tData.bIsClick or false
            table.insert(tMsg.tActInfoList, tInfo)
        end
    end
    oRole:SendMsg("ExchangeInfoListRet", tMsg)
    --PrintTable(tMsg)
end

function CExchangeActivityMgr:SendSingleExchangeInfo(oRole, nActID, nExchangeID, nExchangeTimes)
    local tMsg = {}
    tMsg.nActID = nActID
    tMsg.nExchangeID = nExchangeID
    tMsg.nExchangeTimes = nExchangeTimes
    oRole:SendMsg("ExchangeInfoRet", tMsg)
    print(">>>>>>>>>>>>>>>>>>>>单条兑换信息", tMsg)
end

function CExchangeActivityMgr:GMViewActState()
    for nActivityID, tConf in ipairs(ctExchangeOpenConf) do
        local oAct = self.m_tActivityMap[nActivityID]
        if oAct then
            local nState = oAct:GetState()
            print(">>活动ID："..nActivityID.."  是否开启："..nState.."  开启时间: "..os.date("%c",oAct.m_nBeginTimestamp).."  结束时间："..os.date("%c",oAct.m_nEndTimestamp))
        end   
    end
end

goExchangeActivityMgr = goExchangeActivityMgr or CExchangeActivityMgr:new()


