--角色时间过期相关 逻辑服统一管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

gtRoleTimeExpiryType = 
{
    eRoleState = 1,        --角色buff
}

--比较函数返回值 -1, 0, 1. -1排前面
--较早过期的数据，需要排在前面，否则逻辑会不正确
local tExpiryDataCmp = 
{
    [gtRoleTimeExpiryType.eRoleState] = CRoleState.RoleStateExpiryCmp,
}

-- 回调函数 fnCheck(tData, nTimeStamp), 返回true 已过期失效, false 有效
local tExpiryCheckHandle = 
{
    [gtRoleTimeExpiryType.eRoleState] = CRoleState.RoleStateExpiryCheckHandle,
}

-- 回调函数 fnRemove(nRoleID, nKey, tData)
local tRemoveCallback = 
{
    [gtRoleTimeExpiryType.eRoleState] = CRoleState.RoleStateExpiryHandle,
}

local nMaxKeyBitNum = 24
local nMaxKeyVal = math.floor(2^nMaxKeyBitNum) - 1

--角色专用，主要是为了简化业务逻辑，不需要关心角色释放后的数据清理问题
--模块内部会主动清理记录的该角色数据
function CRoleTimeExpiryMgr:Ctor()
    self.m_tExpiryMap = {}
    self.m_tRoleMap = {}     --{nRoleID:{nType:{nKey:tData, ...}, ...}, ..}
    
    self.m_nTimer = nil
end

function CRoleTimeExpiryMgr:Init() 
    for _, nTypeID in pairs(gtRoleTimeExpiryType) do 
        assert(tExpiryDataCmp[nTypeID], string.format("(%d)没有提供比较函数", nTypeID))
        assert(tExpiryCheckHandle[nTypeID], string.format("(%d)没有提供过期检查处理函数", nTypeID))
        assert(tRemoveCallback[nTypeID], string.format("(%d)没有提供过期回调函数", nTypeID))
    end

    for _, nType in pairs(gtRoleTimeExpiryType) do 
        local fnCmp = tExpiryDataCmp[nType]
        assert(fnCmp, "比较函数不存在")
        local oExpiryTree = CRBTree:new(fnCmp)
        self.m_tExpiryMap[nType] = oExpiryTree
    end
    self.m_nTimer = goTimerMgr:Interval(3, function () self:Check() end)
end

function CRoleTimeExpiryMgr:OnRelease() 
    goTimerMgr:Clear(self.m_nTimer)
end

--维护角色数据的记录
function CRoleTimeExpiryMgr:OnAddData(nRoleID, nType, nKey, tData) 
    local tRoleData = self.m_tRoleMap[nRoleID] or {}
    local tTypeData = tRoleData[nType] or {}
    tTypeData[nKey] = tData
    tRoleData[nType] = tTypeData
    self.m_tRoleMap[nRoleID] = tRoleData
end

--维护角色数据的记录
function CRoleTimeExpiryMgr:OnRemoveData(nRoleID, nType, nKey) 
    local tRoleData = self.m_tRoleMap[nRoleID]
    if not tRoleData then 
        return 
    end
    local tTypeData = tRoleData[nType]
    if not tTypeData then 
        return 
    end

    --如果没有数据，则清理，避免这张表数据一直膨胀
    tTypeData[nKey] = nil
    if not next(tTypeData) then 
        tRoleData[nType] = nil
    else
        tRoleData[nType] = tTypeData
    end

    if not next(tRoleData) then 
        self.m_tRoleMap[nRoleID] = nil
    else
        self.m_tRoleMap[nRoleID] = tRoleData
    end
end

function CRoleTimeExpiryMgr:Insert(nRoleID, nType, nKey, tData) 
    assert(nRoleID > 0 and nKey <= nMaxKeyVal and tData, "参数错误")
    local oTree = self.m_tExpiryMap[nType]
    assert(oTree)
    local nMixKey = (nRoleID << nMaxKeyBitNum) | nKey
    oTree:Insert(nMixKey, tData)
    self:OnAddData(nRoleID, nType, nKey, tData)
end

--nKey不存在，则插入
function CRoleTimeExpiryMgr:Update(nRoleID, nType, nKey, tData) 
    assert(nRoleID > 0 and nKey <= nMaxKeyVal and tData, "参数错误")
    local oTree = self.m_tExpiryMap[nType]
    assert(oTree)
    local nMixKey = (nRoleID << nMaxKeyBitNum) | nKey
    oTree:Update(nMixKey, tData)
    self:OnAddData(nRoleID, nType, nKey, tData)
end

function CRoleTimeExpiryMgr:Remove(nRoleID, nType, nKey)
    local oTree = self.m_tExpiryMap[nType]
    assert(oTree)
    local nMixKey = (nRoleID << nMaxKeyBitNum) | nKey
    oTree:Remove(nMixKey)
    OnRemoveData(nRoleID, nType, nKey)
end

--清理角色数据, 不触发回调事件
function CRoleTimeExpiryMgr:CleanRoleData(nRoleID) 
    assert(nRoleID > 0, "参数错误")
    local tRoleData = self.m_tRoleMap[nRoleID] 
    if not tRoleData then 
        return 
    end

    for nType, tTypeData in pairs(tRoleData) do 
        local oTypeTree = self.m_tExpiryMap[nType]
        for nKey, tData in pairs(tTypeData) do 
            local nMixKey = (nRoleID << nMaxKeyBitNum) | nKey
            oTypeTree:Remove(nMixKey)
        end
    end
    self.m_tRoleMap[nRoleID] = nil
    -- print(string.format("角色(%d)释放，成功清理角色计时数据", nRoleID))
end

function CRoleTimeExpiryMgr:Check()
    local nTimeStamp = os.time()
    for nType, oTree in pairs(self.m_tExpiryMap) do 
        local fnCheckExpiry = tExpiryCheckHandle[nType]
        assert(fnCheckExpiry)
        
        local tExpiryDataMap = {}
        local fnTraverse = function(nIndex, nMixKey, tData) 
            if not fnCheckExpiry(tData, nTimeStamp) then 
                return true
            end
            tExpiryDataMap[nMixKey] = tData
        end
        oTree:Traverse(1, oTree:Count(), fnTraverse)

        local fnRemoveCallback = tRemoveCallback[nType]
        for nMixKey, tData in pairs(tExpiryDataMap) do
            oTree:Remove(nMixKey) --先移除，防止回调发生异常，导致影响整个功能
            local nRoleID = nMixKey >> nMaxKeyBitNum
            local nKey = nMixKey & nMaxKeyVal
            self:OnRemoveData(nRoleID, nType, nKey)
            fnRemoveCallback(nRoleID, nType, nKey)
        end
    end
end

function CRoleTimeExpiryMgr:OnRoleLeaveLogic(oRole) 
    if oRole:IsTempRole() then --防止创建临时镜像角色，导致清理掉正常角色数据
        return 
    end
    self:CleanRoleData(oRole:GetID())
end


goRoleTimeExpiryMgr = goRoleTimeExpiryMgr or CRoleTimeExpiryMgr:new()

