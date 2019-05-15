--物品查询
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


local nMaxRoleNum = 5000
local nMaxCacheNum = 20
local nKeepTime = 1200 --20分钟

function CRoleQuery:Ctor()
    self.m_tCacheTypeList = {} --{nType:{{nItemID, tData, nTimeStamp}, ...}, ...}
    self.m_tRoleInfoCache = {}  --{tData=, nTimeStamp=}
    self.m_nLastUpdateStamp = os.time()
end

function CRoleQuery:GetCacheData(nItemType, nItemID, nMsgStamp)
    local tCacheData = self.m_tCacheTypeList[nItemType]
    if not tCacheData then 
        return 
    end
    local tCache = nil
    local nIndex = 0
    for k, tData in ipairs(tCacheData) do 
        if tData.nItemID == nItemID then 
            tCache = tData
            nIndex = k
            break
        end
    end
    if not tCache then 
        return 
    end
    local nCurTime = os.time()
    if tCache.nTimeStamp < nMsgStamp or math.abs(nCurTime - tCache.nTimeStamp) > nKeepTime then 
        table.remove(tCacheData, nIndex)
        return  
    end
    return tCache
end

function CRoleQuery:UpdateCacheData(nItemType, nItemID, tData)
    local tCacheData = self.m_tCacheTypeList[nItemType]
    if not tCacheData then 
        self.m_tCacheTypeList[nItemType] = {}
        tCacheData = self.m_tCacheTypeList[nItemType]
    end
    if #tCacheData > nMaxCacheNum then 
        table.remove(tCacheData, 1)
    end
    local nTimeStamp = os.time()
    table.insert(tCacheData, {nItemID = nItemID, tData = tData, nTimeStamp = nTimeStamp})
    self.m_nLastUpdateStamp = nTimeStamp
    return true
end

function CRoleQuery:GetRoleInfoCache(nTimeStamp)
    if self.m_tRoleInfoCache and self.m_tRoleInfoCache.tData then 
        if nTimeStamp <= self.m_tRoleInfoCache.nTimeStamp then 
            return self.m_tRoleInfoCache.tData
        else
            return --旧的不清理
        end
    end
    return
end

function CRoleQuery:UpdateRoleInfoCache(tData)
    self.m_tRoleInfoCache = {}
    self.m_tRoleInfoCache.tData  = tData
    self.m_tRoleInfoCache.nTimeStamp = os.time()
    return true
end

function CRoleQuery:IsExpired(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    return math.abs(nTimeStamp - self.m_nLastUpdateStamp) >= nKeepTime
end

-----------------------------------------------------
function CItemQueryMgr:Ctor()
    self.m_tRoleList = CKeyList:new(nMaxRoleNum)
    self.m_nTimer = nil
end

function CItemQueryMgr:Init()
    self.m_nTimer = goTimerMgr:Interval(20, function () self:Tick() end)
end

function CItemQueryMgr:GetRoleQuery(nRoleID) 
    return self.m_tRoleList:GetData(nRoleID)
end

function CItemQueryMgr:OnRelease()
    if self.m_nTimer then 
        goTimerMgr:Clear(self.m_nTimer)
        self.m_nTimer = nil 
    end
end

function CItemQueryMgr:Tick()
    local nTimeStamp = os.time()
    local tRemoveList = {}
    for nRoleID, tRoleQuery in self.m_tRoleList:Iterator() do 
        if tRoleQuery:IsExpired(nTimeStamp) then 
            table.insert(tRemoveList, nRoleID)
        else  --链表有序，后面的必定不过期
            break
        end
    end
    for k, nRoleID in ipairs(tRemoveList) do 
        self.m_tRoleList:Remove(nRoleID)
    end
end

function CItemQueryMgr:Query(nRoleID, nTarID, nItemType, nItemID)
    assert(nRoleID and nTarID and nItemType and nItemID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    assert(oRole)
    print("缓存不存在，开始发起查询")
    local fnQueryCallback = function(bRet, tData)
        if not bRet then
            if tData and type(tData) == "string" then 
                oRole:Tips(tData)
            end
            return 
        end
        assert(nTarID > 0 and nItemType > 0 and tData)
        local oTarQuery = self:GetRoleQuery(nTarID)
        if not oTarQuery then 
            if self.m_tRoleList:IsFull() then 
                self.m_tRoleList:Pop()
            end
            --插入角色query
            oTarQuery = CRoleQuery:new()
            self.m_tRoleList:Insert(nTarID, oTarQuery)
        else --每次缓存发生变化，都将移动到链表尾部
            self.m_tRoleList:Remove(nTarID)
            oTarQuery.m_nLastUpdateStamp = os.time()
            self.m_tRoleList:Insert(nTarID, oTarQuery)
        end
        oTarQuery:UpdateCacheData(nItemType, nItemID, tData)
        self:SendItemDetailInfo(oRole, nItemType, tData)
    end

    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if not oTarRole then 
        oRole:Tips("玩家不存在")
        return 
    end
    local nTarServer = oTarRole:GetStayServer()
    local nBelongServer = oTarRole:GetServer()
    local nLogic = oTarRole:GetLogic()
    goRemoteCall:CallWait("RoleItemDetailDataReq", fnQueryCallback, nTarServer, nLogic, 
        0, nTarID, nBelongServer, nItemType, nItemID)
end

function CItemQueryMgr:QueryReq(nRoleID, nTarID, nItemType, nItemID, nMsgStamp)
    nMsgStamp = nMsgStamp or 0
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then --可能是机器人已被销毁 
        return
    end
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if not oTarRole then 
        return 
    end
    if oTarRole:IsOnline() then 
        nMsgStamp = math.max(nMsgStamp, os.time() - 60)
    else
        nMsgStamp = math.min(nMsgStamp, os.time() - 120)
    end

    if nItemType ~= gtItemType.eProp and nItemType ~= gtItemType.ePet then 
        return 
    end

    local oTarQuery = self:GetRoleQuery(nTarID)
    if not oTarQuery then 
        self:Query(nRoleID, nTarID, nItemType, nItemID)
        return 
    end

    local tCache = oTarQuery:GetCacheData(nItemType, nItemID, nMsgStamp)
    if not tCache then 
        self:Query(nRoleID, nTarID, nItemType, nItemID)
        return 
    end
    print("缓存存在，直接返回")
    self:SendItemDetailInfo(oRole, nItemType, tCache.tData)
end

function CItemQueryMgr:SendItemDetailInfo(oRole, nItemType, tItemData)
    local tMsg = {}
    tMsg.nItemType = nItemType
    if nItemType == gtItemType.eProp then 
        tMsg.tPropData = tItemData
    elseif nItemType == gtItemType.ePet then 
        tMsg.tPetData = tItemData
    else
        LuaTrace("不受支持的物品类型")
        return
    end
    oRole:SendMsg("ItemQueryRet", tMsg)
    print("发送消息成功:", tMsg)
end

--------------------------------------------------------------
function CItemQueryMgr:RoleInfoQuery(nRoleID, nTarID)
    assert(nRoleID and nTarID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    assert(oRole)
    print("角色信息缓存不存在，开始发起查询")
    local fnQueryCallback = function(bRet, tData)
        if not bRet then
            if tData and type(tData) == "string" then 
                oRole:Tips(tData)
            end
            return 
        end
        assert(nTarID > 0 and tData)
        local oTarQuery = self:GetRoleQuery(nTarID)
        if not oTarQuery then 
            if self.m_tRoleList:IsFull() then 
                self.m_tRoleList:Pop()
            end
            --插入角色query
            oTarQuery = CRoleQuery:new()
            self.m_tRoleList:Insert(nTarID, oTarQuery)
        else --每次缓存发生变化，都将移动到链表尾部
            self.m_tRoleList:Remove(nTarID)
            oTarQuery.m_nLastUpdateStamp = os.time()
            self.m_tRoleList:Insert(nTarID, oTarQuery)
        end
        oTarQuery:UpdateRoleInfoCache(tData)
        self:SendRoleInfo(oRole, tData)
    end

    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if not oTarRole then 
        oRole:Tips("玩家不存在")
        return 
    end
    local nTarServer = oTarRole:GetStayServer()
    local nBelongServer = oTarRole:GetServer()
    local nLogic = oTarRole:GetLogic()
    goRemoteCall:CallWait("RoleInfoDataReq", fnQueryCallback, nTarServer, nLogic, 
        0, nTarID, nBelongServer)
end

function CItemQueryMgr:RoleInfoQueryReq(nRoleID, nTarID, nTimeStamp)
    nTimeStamp = nTimeStamp or 0
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then --可能是机器人已被销毁 
        return
    end
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
    if not oTarRole then 
        oRole:Tips("角色不存在")
        return 
    end
    if oTarRole:IsOnline() then --在线玩家，这个数据尽量即时刷新
        nTimeStamp = os.time()
    else --非在线玩家，全部走缓存，不允许强行发起查询最新信息
        nTimeStamp = math.min(nTimeStamp, os.time() - 120)
    end
    local oTarQuery = self:GetRoleQuery(nTarID)
    if not oTarQuery then 
        self:RoleInfoQuery(nRoleID, nTarID)
        return 
    end
    local tCache = oTarQuery:GetRoleInfoCache(nTimeStamp)
    if not tCache then 
        self:RoleInfoQuery(nRoleID, nTarID)
        return 
    end
    print("角色信息缓存存在，直接返回")
    self:SendRoleInfo(oRole, tCache)
end

function CItemQueryMgr:SendRoleInfo(oRole, tCache)
    oRole:SendMsg("RoleInfoQueryRet", tCache)
end


goItemQueryMgr = goItemQueryMgr or CItemQueryMgr:new()

