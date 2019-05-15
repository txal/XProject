--登录排队管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--[[
--流程管理
假设当前服务器人数满
排队处理放在账号登录获取角色后，登录具体角色时
1.当前无登录角色，登录时直接排队
2.在排队状态掉线，移除排队，再次尝试登录时，需要重新排队
3.当前有其他角色在排队，则移除掉旧的排队角色，将新角色添加到排队队列队尾
4.当前有其他角色在离线保护或者登录，此时登录其他角色，先将原角色下线，然后新角色排队
5.当前角色离线保护期间，重新登录，则不触发排队，直接进入游戏
-- 6.当前角色在线或者离线保护期间，通过其他客户端登录，是否触发排队？
]]

local nMaxLoginQueueNum = 2000     --最大登录排队人数

-----------------------------------------------
function CLoginQueue:Ctor()
    self.m_tLoginList = CKeyList:new(nMaxLoginQueueNum)
    self.m_tOfflineCount= {}    --{{nTimeStamp, nCount}, ...}
    
    self.m_nTotalOfflineNum = 0
    self.m_nTimer = goTimerMgr:Interval(2, function() self:Tick() end)
end

function CLoginQueue:OnRelease()
    if self.m_nTimer then 
        goTimerMgr:Clear(self.m_nTimer)
        self.m_nTimer = nil
    end
end

--最大允许排队人数
function CLoginQueue:GetQueueMaxNum() return self.m_tLoginList:MaxCount() end

--离线玩家统计
function CLoginQueue:OfflineCount(nCount, nTimeStamp)
    assert(nCount > 0)
    nTimeStamp = nTimeStamp or os.time()
    local tRecord = nil
    if #self.m_tOfflineCount > 0 then 
        tRecord = self.m_tOfflineCount[#self.m_tOfflineCount]
    end

    --统计区间5秒一组
    if not tRecord or tRecord.nTimeStamp ~= math.floor(nTimeStamp / 5) then 
        tRecord = {nTimeStamp = math.floor(nTimeStamp / 5), nCount = 0}
        if #self.m_tOfflineCount >= 60 then --缓存60组
            table.remove(self.m_tOfflineCount, 1)
        end
        table.insert(self.m_tOfflineCount, tRecord)
    end
    assert(tRecord)
    tRecord.nCount = tRecord.nCount + nCount
end

--更新离线玩家统计数据，加速计算
function CLoginQueue:UpdateOfflineRecord()
    local nRemoveRecordNum = 0
    local nTimeStamp = os.time()
    local nRecordStamp = math.floor(nTimeStamp / 5)
    for k, tRecord in ipairs(self.m_tOfflineCount) do 
        --可能中间某个区间段，没有玩家离线，导致旧的数据没有被删除
        if math.abs(nRecordStamp - tRecord.nTimeStamp) >= 60 then 
            nRemoveRecordNum = nRemoveRecordNum + 1
        else
            break --有序列表，后面的无需计算了
        end 
    end
    for k = 1, nRemoveRecordNum do 
        table.remove(self.m_tOfflineCount, 1)
    end
    if #self.m_tOfflineCount > 0 then 
        local nTotalOfflineNum = 0
        for k, tRecord in ipairs(self.m_tOfflineCount) do 
            nTotalOfflineNum = nTotalOfflineNum + tRecord.nCount
        end
        if nTotalOfflineNum > 0 then 
            self.m_nTotalOfflineNum = nTotalOfflineNum
        else
            self.m_nTotalOfflineNum = math.max(0, self.m_nTotalOfflineNum - 10)
        end
    else
        --这一轮次，没有数据了，沿用旧数据
        self.m_nTotalOfflineNum = math.max(0, self.m_nTotalOfflineNum - 10)
    end
end

function CLoginQueue:CalcWaitTimeByRank(nRank)
    if self.m_nTotalOfflineNum < 1 then 
        return 60 * nRank
    end
    --正常，如果达到服务器排队，5分钟内的玩家下线数据肯定存在
    local nTime = math.ceil(nRank * math.min(60.0, 300 / self.m_nTotalOfflineNum))
    return nTime
end

function CLoginQueue:SyncLoginQueue(nAccountID, nRoleID, nRank)
    local oAccount = goLoginMgr:GetAccountByID(nAccountID)
    local nSession = oAccount:GetSession()
    if not oAccount or nSession <= 0 then 
        return 
    end
    local tMsg = {}
    tMsg.nRoleID = nRoleID
    tMsg.nRank = nRank
    tMsg.nWaitTime = self:CalcWaitTimeByRank(nRank)
    CmdNet.PBSrv2Clt("RoleLoginQueueRet", oAccount:GetServer(), nSession, tMsg)
    -- print(string.format("(%d)正在排队，排队编号(%d), 预计时间(%d), 总排队人数(%d)", 
    --     nAccountID, nRank, tMsg.nWaitTime, self.m_tLoginList:Count()))
end

function CLoginQueue:BroadcastLoginQueue()
    local fnCallback = function(tNode, nRank)
        if not tNode or tNode.nKey <= 0 then 
            return 
        end
        self:SyncLoginQueue(tNode.nKey, tNode.tData.nRoleID, nRank)
    end
    self.m_tLoginList:NodeCallback(fnCallback)
end

function CLoginQueue:Login(nAccountID, nRoleID)
    local oAccount = goLoginMgr:GetAccountByID(nAccountID)
    if not oAccount then 
        return 
    end
    if oAccount:GetSession() <= 0 then 
        return 
    end
    -- 统一由账号那里边管理控制
    -- if oAccount:GetOnlineRoleID() > 0 then 
    --     print(string.format("账号(%d)已有角色在线，放弃登录", nAccountID))
    --     return 
    -- end
    print(string.format("(%d)开始登录，玩家ID(%d)", nAccountID, nRoleID))
    oAccount:DealLogin(nRoleID)
end

function CLoginQueue:Tick()
    local nOnlineNum = goLoginMgr:GetOnlineNum()
    -- print(string.format("当前服务器在线玩家数量 ( %d )", nOnlineNum))
    -- self.m_tLoginList:DebugPrint()
    self:UpdateOfflineRecord()
    local nAllowNum = goLoginMgr:GetLoginAllowNum()
    if nAllowNum > 0 then 
        local nLoginQueueNum = self.m_tLoginList:Count()
        if nLoginQueueNum > 0 then 
            for k = 1, math.min(nAllowNum, nLoginQueueNum) do 
                local tNode = self.m_tLoginList:Pop()
                if tNode then 
                    self:Login(tNode.nKey, tNode.tData.nRoleID)
                end
            end
        end
    end
    self:BroadcastLoginQueue() --不论是否登录人数发生变化，都广播下，可能有人放弃了排队
end

--是否触发排队
function CLoginQueue:IsTriggerQueue() 
    if self.m_tLoginList:Count() > 0 then 
        return true
    end
    if goLoginMgr:IsServerMax() then 
        return true
    end
    return false
end

function CLoginQueue:Remove(nAccountID)
    self.m_tLoginList:Remove(nAccountID)
end

function CLoginQueue:Insert(nAccountID, nRoleID, nIndex)
    -- nIndex = math.random(1, self.m_tLoginList:Count() + 1) --test
    assert(nAccountID and nRoleID)
    self:Remove(nAccountID) --尝试删除掉原来的排队，可能客户端连续多次请求登录动作，会导致此类问题
    if self:IsTriggerQueue() then 
        if self.m_tLoginList:IsFull() then 
            return false
        end
        local tNode, nRetIndex = self.m_tLoginList:Insert(nAccountID, {nRoleID = nRoleID}, nIndex)
        if not tNode then 
            return false
        end
        nIndex = nIndex or self.m_tLoginList:Count()
        self:SyncLoginQueue(nAccountID, nRoleID, nRetIndex)
    else
        self:Login(nAccountID, nRoleID)
    end
    return true
end



