--队伍匹配
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


-- --合法的可以由客户端发起match的匹配类型对应的名称，服务器发起的目前不做检查
-- gtGameTypeMatchName = 
-- {
--     [gtBattleDupType.eZhenYao] = "抓鬼",
--     [gtBattleDupType.eLuanShiYaoMo] = "降妖除魔",
--     [gtBattleDupType.eXinMoQinShi] = "伏心魔",
--     [gtBattleDupType.eShenShouLeYuan] = "超级神兽",
--     [gtBattleDupType.eShenMoZhi] = "魔神讨伐",
--     [gtBattleDupType.eJueZhanJiuXiao] = "决战九霄",
--     [gtBattleDupType.eHunDunShiLian] = "群雄逐鹿",
--     [gtBattleDupType.eMengZhuWuShuang] = "大唐无双",
--    -- [gtBattleDupType.ePVEPrepare] = "PVE匹配大厅",
-- }

gtGameTypeMatchAutoMergeTeam = 
{
    [gtBattleDupType.eSchoolArena] = true,
    [gtBattleDupType.eQimaiArena] = true,
    [gtBattleDupType.eQingyunBattle] = true,
    [gtBattleDupType.eUnionArena] = true,
    [gtBattleDupType.eLuanShiYaoMo] = true,
    [gtBattleDupType.eXinMoQinShi] = true,
    [gtBattleDupType.ePVEPrepare] = true,
}

gtGameTypeMatchSceneRobot = 
{
    [gtBattleDupType.eSchoolArena] = true,
    [gtBattleDupType.eQimaiArena] = true,
    [gtBattleDupType.eQingyunBattle] = true,
    [gtBattleDupType.eUnionArena] = true,
}


gbTeamMatchRobot = true         --是否开启匹配机器人功能
-- gnRobotMatchLevelLimit = 100    --匹配机器人限制等级(低于此等级的玩家才会给匹配机器人)
local nRobotWaitTime = 30 --gbInnerServer and 20 or 120

gtTeamMatchLevelConf = {}
--每次reload，都初始化一次
for nID, tConfData in pairs(ctTeamMatchLevelConf) do 
    local tGroupTbl = gtTeamMatchLevelConf[tConfData.nGroupID]
    if not tGroupTbl then 
        tGroupTbl = {}
        gtTeamMatchLevelConf[tConfData.nGroupID] = tGroupTbl
    end
    table.insert(tGroupTbl, tConfData)
end

for _, tGroupTbl in pairs(gtTeamMatchLevelConf) do 
    table.sort(tGroupTbl, 
    function(tL, tR)
        if tL.nMatchLevelMax < tR.nMatchLevelMax then 
            return true 
        else
            return false
        end
    end)
end


function CTeamMatchMgr:Ctor()
    self.m_tTeamMap = {}         --{nTeamID:GameType, ...}
    self.m_tGameTeamMap = {}     --{nGameType:(tKeyList:Insert(key, data)), ...}, ...}
    self.m_tRoleMap = {}         --{nRoleID:nGameType, ...}      --没有队伍的
    self.m_tGameRoleMap = {}     --{nGameType:(tKeyList:Insert(key, data)), ...}, ...}

    self.m_tMatchOpRecord = {}   --{nRoleID:nTimeStamp, ...}

    self.m_tRemoveRecord = {}
    self.m_nAutoMergeTimer = nil

    self.m_tRobotMap = {}           --{nGameType:{nRobotID, ...}, ...}
    self.m_tRobotGameTypeMap = {}   --{nRobotID:nGameType, ...}
    self.m_tRobotMatchMap = {}      --{nGameType:CRBTree, ...}  --可匹配的机器人列表
end

function CTeamMatchMgr:Init()
    self.m_nAutoMergeTimer = goTimerMgr:Interval(5, function() self:Tick() end)
end

function CTeamMatchMgr:OnRelease()
    if self.m_nAutoMergeTimer then 
        goTimerMgr:Clear(self.m_nAutoMergeTimer)
    end
    self.m_nAutoMergeTimer = nil
end

function CTeamMatchMgr:CheckGameType(nGameType)
    if not nGameType then 
        return false
    end
    local nRealGameType = self:GetRealGameType(nGameType)
    if not nRealGameType or not ctTeamMatchConf[nRealGameType] then 
        return false 
    end
    return true
end

--检查是否可由客户端直接发起匹配
function CTeamMatchMgr:CheckCanMatchByClient(nRealGameType)
    if not nRealGameType or nRealGameType < 1 then 
        return false
    end
    -- if gtGameTypeMatchName[nRealGameType] then 
    --     return true
    -- end
    local tMatchConf = ctTeamMatchConf[nRealGameType]
    if not tMatchConf then 
        return false
    end
    return tMatchConf.bClientCall
end

function CTeamMatchMgr:GetGameNameByType(nGameType)
    local nRealGameType = nGameType & 0xffffffff
    -- return gtGameTypeMatchName[nRealGameType]
    return ctTeamMatchConf[nRealGameType].sGameName
end

function CTeamMatchMgr:GetRealGameType(nGameType)
    if not nGameType or type(nGameType) ~= "number" then 
        return 
    end
    local nRealGameType = nGameType & 0xffffffff
    return nRealGameType
end

function CTeamMatchMgr:IsAutoMerge(nGameType)
    local nRealGameType = self:GetRealGameType(nGameType)
    if not nRealGameType then
        return false
    end
    if gtGameTypeMatchAutoMergeTeam[nRealGameType] then 
        return true 
    else
        return false
    end
end

-- --由具体功能玩法入口处做检查限制
-- function CTeamMatchMgr:CheckCanJoinMatch(nRoleID, nGameType)
--     --TODO
--     return true
-- end

function CTeamMatchMgr:IsTeamMatching(nTeamID)
    if self.m_tTeamMap[nTeamID] then 
        return true 
    end
    return false
end

function CTeamMatchMgr:IsRoleMatching(nRoleID)
    if self.m_tRoleMap[nRoleID] then 
        return true 
    end
    return false
end

function CTeamMatchMgr:GetGameTeamMatch(nGameType)
    return self.m_tGameTeamMap[nGameType]
end

function CTeamMatchMgr:GetGameRoleMatch(nGameType)
    return self.m_tGameRoleMap[nGameType]
end

function CTeamMatchMgr:RemoveTeamMatch(nTeamID)  --内部私有接口，外层请勿直接调用
    local nGameType = self.m_tTeamMap[nTeamID]
    if not nGameType then 
        return 
    end
    self.m_tTeamMap[nTeamID] = nil
    self.m_tGameTeamMap[nGameType]:Remove(nTeamID)
    return true  --发生真实删除时
end

function CTeamMatchMgr:RemoveRoleMatch(nRoleID)  --内部私有接口
    local nGameType = self.m_tRoleMap[nRoleID]
    if not nGameType then 
        return 
    end
    self.m_tRoleMap[nRoleID] = nil
    self.m_tGameRoleMap[nGameType]:Remove(nRoleID)
    return true
end

function CTeamMatchMgr:JoinTeamMatch(nTeamID, nGameType) --内部私有接口
    if not self.m_tGameTeamMap[nGameType] then 
        self.m_tGameTeamMap[nGameType] = CKeyList:new()
        self.m_tGameRoleMap[nGameType] = self.m_tGameRoleMap[nGameType] or CKeyList:new()
    end
    if self.m_tTeamMap[nTeamID] then --增加下容错
        LuaTrace("请检查代码")
        LuaTrace(debug.traceback())
        self:RemoveTeamMatch(nTeamID)
    end
    self.m_tTeamMap[nTeamID] = nGameType
    -- self.m_tGameTeamMap[nGameType][nTeamID] = {nTeamID = nTeamID, nTimeStamp = os.time()}
    local tMatchList = self:GetGameTeamMatch(nGameType)
    tMatchList:Insert(nTeamID, {nTeamID = nTeamID, nTimeStamp = os.time()})
    print("加入队伍匹配成功")
end

function CTeamMatchMgr:JoinRoleMatch(nRoleID, nGameType) --内部私有接口
    if not self.m_tGameRoleMap[nGameType] then 
        self.m_tGameRoleMap[nGameType] = CKeyList:new()
        self.m_tGameTeamMap[nGameType] = self.m_tGameTeamMap[nGameType] or CKeyList:new()
    end
    if self.m_tRoleMap[nRoleID] then 
        LuaTrace("请检查代码")
        LuaTrace(debug.traceback())
        self:RemoveRoleMatch(nRoleID)
    end
    self.m_tRoleMap[nRoleID] = nGameType
    -- self.m_tGameRoleMap[nGameType][nRoleID] = {nRoleID = nRoleID, nTimeStamp = os.time()}
    local tMatchList = self:GetGameRoleMatch(nGameType)
    tMatchList:Insert(nRoleID, {nRoleID = nRoleID, nTimeStamp = os.time()})
    print("加入玩家匹配成功")
end

function CTeamMatchMgr:GetMatchLevelID(nGameType, nLevel)
    if not nGameType or not nLevel then 
        return 0
    end
    local nRealGameType = self:GetRealGameType(nGameType)
    if not nRealGameType then 
        LuaTrace(string.format("玩法类型(%d)不存在", nGameType))
        return 0
    end
    local tGameTypeConf = ctTeamMatchConf[nRealGameType]
    if not tGameTypeConf then 
        return 0
    end
    local nMatchGroup = tGameTypeConf.nMatchLevelGroup
    local tGroupTbl = gtTeamMatchLevelConf[nMatchGroup]
    local tTargetConf = nil
    for _, tConf in ipairs(tGroupTbl) do 
        if nLevel >= tConf.nMatchLevelMin and nLevel <= tConf.nMatchLevelMax then 
            tTargetConf = tConf
            break
        end
    end
    if not tTargetConf then 
        return 0
    end
    return tTargetConf.nID
end

--检查队伍状态是否可被匹配
function CTeamMatchMgr:CheckTeamMatchState(nTeamID, nGameType)
    if nTeamID <= 0 then 
        return false 
    end
    local oTeam = goTeamMgr:GetTeamByID(nTeamID)
    if not oTeam then 
        if gbInnerServer then 
            --内网直接抛错，尽量暴露问题
            assert(false, string.format("数据错误!!!队伍ID(%d)不存在", nTeamID))
        end
        LuaTrace("数据错误!!!!!")
        LuaTrace(debug.traceback())
        return false
    end
    local nMatchNum = 5 - oTeam:GetMembers()
    if oTeam:IsFull() or nMatchNum < 1 then 
        return false
    end

    local tLeader = oTeam:GetLeader()
    if not tLeader then
        return false
    end
    local oRoleLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
    if not oRoleLeader or not oRoleLeader:IsOnline() then 
        return false
    end
    if oRoleLeader:IsRobot() then --如果队长是机器人，暂时不给匹配，防止异常情况 
        return false
    end
    --队长不在副本场景，不给匹配
    local tDupConf = oRoleLeader:GetDupConf()
    if not tDupConf or tDupConf.nType ~= 2 then 
        return false
    end
    return true 
end

--队伍玩家发起的一次匹配
function CTeamMatchMgr:MatchByTeam(nTeamID, nGameType) 
    local tGameTeamList = self:GetGameTeamMatch(nGameType)
    local tGameRoleList = self:GetGameRoleMatch(nGameType)
    assert(tGameTeamList and tGameRoleList)
    local oTeam = goTeamMgr:GetTeamByID(nTeamID)
    if not oTeam then 
        if gbInnerServer then 
            assert(false, string.format("数据错误!!!队伍ID(%d)不存在", nTeamID))
        end
        return self:RemoveTeamMatch(nTeamID)
    end
    local nMatchNum = 5 - oTeam:GetMembers()
    if oTeam:IsFull() or nMatchNum < 1 then 
        return self:RemoveTeamMatch(nTeamID)
    end

    local tTeamMatchData = tGameTeamList:GetData(nTeamID)
    local tLeader = oTeam:GetLeader()
    if not tLeader then
        return
    end
    local oRoleLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
    if not oRoleLeader or not oRoleLeader:IsOnline() then 
        return --队长离线队伍，不予匹配
    end
    if not self:CheckTeamMatchState(nTeamID, nGameType) then 
        return 
    end
    local nLeaderLevel = oRoleLeader:GetLevel()
    local nMatchLevelID = self:GetMatchLevelID(nGameType, nLeaderLevel)
    local tRoleRemoveList = {}
    local nPreKey = nil
    for k = 1, nMatchNum do 
        if tGameRoleList:IsTail(nPreKey) then 
            break 
        end
        if oTeam:IsFull() then 
            break
        end
        -- print("PreKey:", nPreKey)
        for nRoleID, tRoleData in tGameRoleList:Iterator(nPreKey) do 
            local bMatch = false
            local oTempRole = goGPlayerMgr:GetRoleByID(nRoleID)
            if not oTempRole then 
                table.insert(tRoleRemoveList, nRoleID)
            else
                local nTempLevelID = self:GetMatchLevelID(nGameType, oTempRole:GetLevel())
                if nTempLevelID == nMatchLevelID then 
                    bMatch = true 
                end
            end
            if bMatch then 
                print(string.format("成功匹配，队伍ID(%d), 玩家ID(%d), 玩法(%d)", 
                    nTeamID, nRoleID, nGameType))
                oTeam:Join(nRoleID, true) --这里会回调删除玩家匹配数据，导致迭代链表出错
                if tTeamMatchData then 
                    tTeamMatchData.nLastMatchStamp = os.time()
                end
                table.insert(tRoleRemoveList, nRoleID)
                break  --每次成功匹配一个，必须跳出，否则将导致迭代出错
            else
                nPreKey = nRoleID --保存下前一次迭代但未匹配的key，加速下一次迭代
            end
        end
    end
    --队伍成员发生变化，其实已经通过队伍成员变化事件回调删除匹配了
    --这里只是为了再次保证下，防止外层其他地方错误修改，导致没正常进行回调
    for k, nRoleID in pairs(tRoleRemoveList) do 
        tGameRoleList:Remove(nRoleID)
    end
    if oTeam:IsFull() then
        self:RemoveTeamMatch(nTeamID)
    end
end

--非队伍玩家发起的一次匹配
function CTeamMatchMgr:MatchByRole(nRoleID, nGameType)
    local tGameTeamList = self:GetGameTeamMatch(nGameType)
    local tGameRoleList = self:GetGameRoleMatch(nGameType)
    assert(tGameTeamList and tGameRoleList)

    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then 
        return
    end
    local nMatchLevelID = self:GetMatchLevelID(nGameType, oRole:GetLevel())
    local tTeamRemoveList = {}
    for nTeamID, tTeamData in tGameTeamList:Iterator() do 
        local oTeam = goTeamMgr:GetTeamByID(nTeamID)
        if not oTeam then 
            table.insert(tTeamRemoveList, nTeamID)
        else
            local tLeader = oTeam:GetLeader()
            if tLeader then
                local oRoleLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
                if oRoleLeader and oRoleLeader:IsOnline() then 
                    if self:CheckTeamMatchState(nTeamID, nGameType) then 
                        local bMatch = false 
                        local nLeaderMatchLevelID = self:GetMatchLevelID(nGameType, oRoleLeader:GetLevel())
                        if nLeaderMatchLevelID == nMatchLevelID then 
                            bMatch = true
                        end
                        if bMatch then 
                            print(string.format("成功匹配，玩家ID(%d), 玩法(%d)", nRoleID, nGameType))
                            oTeam:Join(nRoleID, true)  --这里会回调删除队伍匹配数据，导致后续迭代链表出错
                            tTeamData.nLastMatchStamp = os.time()
                            if oTeam:IsFull() then
                                table.insert(tTeamRemoveList, nTeamID) --正常在回调事件中已删除
                            end
                            self:RemoveRoleMatch(nRoleID) --再次确保下删除
                            break  --这里必须跳出，否则继续迭代将引发错误
                        end   
                    end 
                else
                    table.insert(tTeamRemoveList, nTeamID) --队长离线，不予匹配并从匹配列表删除
                end
            else
                table.insert(tTeamRemoveList, nTeamID)
            end
        end
    end
    for k, nTeamID in pairs(tTeamRemoveList) do 
        if self:RemoveTeamMatch(nTeamID) then 
            self:SyncMatchInfoByTeamID(nTeamID)
        end
    end
end

--自动合并匹配
function CTeamMatchMgr:AutoMergeMatch(nGameType) 
    local tGameTeamList = self:GetGameTeamMatch(nGameType)
    local tGameRoleList = self:GetGameRoleMatch(nGameType)
    assert(tGameTeamList and tGameRoleList)

    if tGameRoleList:Count() < 2 then 
        return 
    end
    local tMatchList = {}   --{nMatchLevelID:{tData, ...}, ...}
    local tRemoveList = {}
    for nRoleID, tRoleData in tGameRoleList:Iterator() do 
        local oTempRole = goGPlayerMgr:GetRoleByID(nRoleID)
        if oTempRole then 
            local nMatchLevelID = self:GetMatchLevelID(nGameType, oTempRole:GetLevel())
            local tMatchLevelTbl = tMatchList[nMatchLevelID]
            if not tMatchLevelTbl then 
                tMatchLevelTbl = {}
                tMatchList[nMatchLevelID] = tMatchLevelTbl
            end
            table.insert(tMatchLevelTbl, tRoleData)
        else
            table.insert(tRemoveList, nRoleID)
        end
    end
    for k, nRoleID in ipairs(tRemoveList) do 
        if self:RemoveRoleMatch(nRoleID) then 
            self:SyncMatchInfoByRoleID(nRoleID)
        end
    end

    local nCurTime = os.time()
    for nMatchLevelID, tMatchLevelTbl in pairs(tMatchList) do 
        if #tMatchLevelTbl > 1 then 
            --从列表中找出2个符合条件的玩家，自动合并创建队伍
            local tFirstData = nil  --默认是队长
            local tSecondData = nil
            local nTotalMatchNum = #tMatchLevelTbl
            for k = 1, nTotalMatchNum do 
                local tRoleData = tMatchLevelTbl[k]
                --如果排队时间大于设定值或者当前排队人数较多，则自动组队匹配
                --加入匹配时间有序的，后面都不满足，第二个队员，不检查排队时间
                if (not tFirstData) and 
                    (math.abs(nCurTime - tRoleData.nTimeStamp) < 20 and (nTotalMatchNum - k) < 25) then
                    break 
                end
                --必须检查是否已经被之前匹配过程匹配了，即是否已被自动删除
                if self:IsRoleMatching(tRoleData.nRoleID) then 
                    if not tFirstData then 
                        tFirstData = tRoleData
                    else
                        tSecondData = tRoleData
                    end

                    if tFirstData and tSecondData then 
                        --避免引发各种回调事件嵌套问题，主动取消这2个玩家的个人匹配
                        self:RemoveRoleMatch(tFirstData.nRoleID)
                        self:RemoveRoleMatch(tSecondData.nRoleID)

                        local oFirstRole = goGPlayerMgr:GetRoleByID(tFirstData.nRoleID)
                        goTeamMgr:CreateTeamReq(oFirstRole)
                        local oTempTeam = goTeamMgr:GetTeamByRoleID(tFirstData.nRoleID)
                        oTempTeam:Join(tSecondData.nRoleID, true)
                        local nTempTeamID = oTempTeam:GetID()
                        --请注意，这里如果有玩家被匹配了，
                        --会自动从管理器匹配列表(self.m_tRoleMap, self.m_tGameRoleMap)中删除
                        self:JoinTeamMatch(nTempTeamID, nGameType)
                        self:MatchByTeam(nTempTeamID, nGameType)
                        self:SyncMatchInfoByTeamID(nTempTeamID)
                        tFirstData = nil 
                        tSecondData = nil
                    end
                end
            end
        end
    end

end

function CTeamMatchMgr:TickAutoMergeMatch()
    local tGameMergeList = {}
    for nGameType, v in pairs(self.m_tGameTeamMap) do 
        if self:IsAutoMerge(nGameType) then 
            table.insert(tGameMergeList, nGameType)
        end
    end
    for k, nGameType in ipairs(tGameMergeList) do 
        self:AutoMergeMatch(nGameType)
    end
end

function CTeamMatchMgr:TickRemove()
    --自动收集，玩家和队伍匹配都已为空的GameTyep match
    --某些自定义玩法类型，在服务器长时间运行情况下，将一直增加整个匹配类型数量，影响其他地方迭代
    local tRemoveRecordList = self.m_tRemoveRecord
    for nGameType, tRoleGame in pairs(self.m_tGameRoleMap) do 
        if tRoleGame:IsEmpty() then 
            local tTeamGame = self.m_tGameTeamMap[nGameType]
            if tTeamGame and not tTeamGame:IsEmpty() then 
                tRemoveRecordList[nGameType] = nil
            elseif not tRemoveRecordList[nGameType] then 
                tRemoveRecordList[nGameType] = os.time()
            end
        else
            tRemoveRecordList[nGameType] = nil
        end
    end

    local nCurTime = os.time()
    for nGameType, nTimeStamp in pairs(tRemoveRecordList) do 
        if math.abs(nCurTime - nTimeStamp) >= 60 then 
            self.m_tGameTeamMap[nGameType] = nil
            self.m_tGameRoleMap[nGameType] = nil
        end
    end
end

function CTeamMatchMgr:IsGameTypeMatchRobot(nGameType)
    if not gbTeamMatchRobot then return false end
    local nRealGameType = self:GetRealGameType(nGameType)
    if not nRealGameType then return false end
    local tTeamMatchConf = ctTeamMatchConf[nRealGameType]
    if not tTeamMatchConf then return false end
    return tTeamMatchConf.bMatchRobot
end

function CTeamMatchMgr:CheckCanMatchRobot(nTeamID, nGameType)
    local oTeam = goTeamMgr:GetTeamByID(nTeamID)
    if not oTeam then 
        return false 
    end
    if oTeam:IsFull() then 
        return false
    end
    if not self:IsGameTypeMatchRobot(nGameType) then 
        return false 
    end
    --队伍必须存在非离线、非暂离的玩家，且队长必须是正常玩家且在线
    local oLeaderRole = oTeam:GetLeaderRole()
    if not oLeaderRole or not oLeaderRole:IsOnline() then 
        return false 
    end
    --队长必须处于副本场景中
    local tDupConf = oLeaderRole:GetDupConf()
    if not tDupConf or tDupConf.nType ~= 2 then 
        return false 
    end
    -- if tDupConf.nLogic < 100 then --必须要处于跨服副本场景中 
    --     return false 
    -- end
    return true
end

function CTeamMatchMgr:MatchTeamRobot(tTeamData, nGameType) 
    local nTeamID  = tTeamData.nTeamID
    local oTeam = goTeamMgr:GetTeamByID(tTeamData.nTeamID)
    if not oTeam or oTeam:IsFull() then 
        return 
    end
    --策划新需求, 只有队伍人数小于3人，才匹配机器人
    --单次直接匹配足够数量的机器人
    local nMatchRobotLimitNum = 3 
    local nTeamMembers = oTeam:GetMembers()
    if nTeamMembers >= nMatchRobotLimitNum then 
        return 
    end
    local oLeaderRole = oTeam:GetLeaderRole()
    if not oLeaderRole then return end

    local nDupMixID = oLeaderRole:GetDupMixID()
    if nDupMixID <= 0 then 
        return 
    end

    -- tTeamData.nStartRobotMatchStamp = os.time()  --防止发生错误，一直尝试匹配

    local fnGetRobotMatchLevel = function(nGameType, nLeaderLevel)
        local nDefaultMin = math.max(nLeaderLevel - 5, 1)
        local nDefaultMax = math.min(nLeaderLevel + 5, #ctRoleLevelConf)
        local nMatchLevelID = self:GetMatchLevelID(nGameType, nLeaderLevel)
        if nMatchLevelID > 0 then --优先根据配置的等级匹配区间匹配
            local tMatchLevelConf = ctTeamMatchLevelConf[nMatchLevelID]
            local nMin = math.max(tMatchLevelConf.nMatchLevelMin, nDefaultMin)
            local nMax = math.max(math.min(tMatchLevelConf.nMatchLevelMax, nDefaultMax), nMin)
            assert(nMin <= nMax)
            return nMin, nMax
        end

        local nRealGameType = self:GetRealGameType(nGameType)
        local tBattleDupConf = ctBattleDupConf[nRealGameType]
        if tBattleDupConf then --如果是副本玩法
            if tBattleDupConf.nDailyActID > 0 then --如果有关联日常活动配置
                local tDailyActConf = ctDailyActivity[tBattleDupConf.nDailyActID]
                local nMin = math.max(tDailyActConf.nLevelLimit, nDefaultMin)
                local nMax = math.max(nDefaultMax, nMin)
                return nMin, nMax
            else
                local nMin = math.max(tBattleDupConf.nLevelLimit, nDefaultMin)
                local nMax = math.max(nDefaultMax, nMin)
                return nMin, nMax
            end
        end
        --PVP玩法的，暂时不用考虑相关情况
        return nDefaultMin, nDefaultMax
    end

    --不考虑失败和各种异步数据处理问题了
    for k = 1, nMatchRobotLimitNum - nTeamMembers do 
        --查找和队长等级相近玩家，是否有附近等级段机器人，如果存在，则匹配
        local nServer = oLeaderRole:GetServer()
        local nLeaderLevel = oLeaderRole:GetLevel()
        local nMinLevel, nMaxLevel = fnGetRobotMatchLevel(nGameType, nLeaderLevel)
        local tConfID = {}
        if self:GetRealGameType(nGameType) == gtBattleDupType.eZhenYao then 
            local bRoleConfLimit = true 
            --检查当前队伍中，是否存在圣巫或者天音
            for k, tRoleConf in pairs(oTeam:GetRoleList()) do 
                local oTempRole = goGPlayerMgr:GetRoleByID(tRoleConf.nRoleID)
                if oTempRole then 
                    local nTempSchool = oTempRole:GetSchool()
                    if nTempSchool == gtSchoolType.eTY or nTempSchool == gtSchoolType.eSW then 
                        bRoleConfLimit = false 
                        break 
                    end
                end
            end
            if bRoleConfLimit then 
                tConfID = {5, 6, 9, 10}  --TODO 待优化,暂时硬编码
            end
        end
        local nRoleConfID = 0
        if #tConfID > 0 then 
            nRoleConfID = tConfID[math.random(#tConfID)]
        end

        local fnCreateCallback = function(nRobotID)
            if not nRobotID or nRobotID <= 0 then 
                print("匹配机器人失败")
                return 
            end
            -- local oRobot = goGPlayerMgr:GetRoleByID(nRobotID)
            -- assert(oRobot)
            local oTeam = goTeamMgr:GetTeamByID(nTeamID)
            if not oTeam or oTeam:IsFull() then --rpc期间，队伍被解散或已满员
                goGRobotMgr:RemoveRobot(nRobotID)
                return 
            end
            oTeam:Join(nRobotID, true)
            tTeamData.nLastMatchStamp = os.time()
            -- if gbInnerServer then 
            --     local oRobot = goGPlayerMgr:GetRoleByID(nRobotID)
            --     oLeaderRole:Tips(string.format("匹配到测试机器人%s", oRobot:GetFormattedName()))
            -- end
        end
        goGRobotMgr:CreateRobot(nServer, nMinLevel, nMaxLevel, nRoleConfID, gtRobotType.eTeam, nDupMixID, nTeamID, fnCreateCallback)
    end
end

function CTeamMatchMgr:MatchSceneRobot(tTeamData, nGameType) 
    local nTeamID  = tTeamData.nTeamID
    local oTeam = goTeamMgr:GetTeamByID(tTeamData.nTeamID)
    if not oTeam or oTeam:IsFull() then 
        return 
    end
    local oLeaderRole = oTeam:GetLeaderRole()
    if not oLeaderRole then return end

    local nDupMixID = oLeaderRole:GetDupMixID()
    if nDupMixID <= 0 then 
        return 
    end
    local tMatchMap = self.m_tRobotMatchMap[nGameType]
    if not tMatchMap or tMatchMap:Count() <= 0 then 
        return 
    end

    local tRandSet = {}
    local fnTraverse = function(nIndex, nRoleID, tData) 
        if not oTeam:IsInTeam(nRoleID) then 
            table.insert(tRandSet, nRoleID)
            if #tRandSet >= 5 then --前面5个满足条件的随机
                return true 
            end
        end
    end
    tMatchMap:Traverse(1, tMatchMap:Count(), fnTraverse)
    if #tRandSet <= 0 then 
        return 
    end

    local nRandIndex = math.random(#tRandSet)
    local nRobotID = tRandSet[nRandIndex]
    local oRobot = goGPlayerMgr:GetRoleByID(nRobotID)
    if oRobot and oRobot:IsOnline() then 
        oTeam:Join(nRobotID, true)
        --回调中，会从列表清理掉，这里再次保证下
        tMatchMap:Remove(nRobotID)
        tTeamData.nLastMatchStamp = os.time()
        -- if gbInnerServer then 
        --     oLeaderRole:Tips(string.format("匹配到测试机器人%s", oRobot:GetFormattedName()))
        -- end
    else
        --清理掉无效错误数据
        local tRobotMap = self.m_tRobotMap[nGameType]
        if tRobotMap then 
            tRobotMap[nRobotID] = nil
        end
        self.m_tRobotGameTypeMap[nRobotID] = nil
        tMatchMap:Remove(nRobotID)
    end
end

function CTeamMatchMgr:GetMatchRobotInfo(nTeamID)
    local oTeam = goTeamMgr:GetTeamByID(nTeamID)
    if not oTeam and oTeam:GetMembers() >= 3 then
        return false
    end
    local nGameType = self.m_tTeamMap[nTeamID]
    if not self:IsGameTypeMatchRobot(nGameType) then 
        return false 
    end
    if gtGameTypeMatchSceneRobot[nRealGameType] then 
        return false
    end
    local tMatchList = self:GetGameTeamMatch(nGameType)
    if not tMatchList then 
        return false
    end
    local tTeamData = tMatchList:GetData(nTeamID)
    if not tTeamData then 
        return false
    end
    local nStartRobotMatchStamp = tTeamData.nStartRobotMatchStamp or tTeamData.nTimeStamp
    return true, math.max(0, nStartRobotMatchStamp + nRobotWaitTime - os.time())
end

function CTeamMatchMgr:TeamMatchRobot(tTeamData, nGameType)
    if not gbTeamMatchRobot then 
        return 
    end
    if not tTeamData or not nGameType then return end
    local nTeamID = tTeamData.nTeamID
    if not self:CheckTeamMatchState(nTeamID, nGameType) then 
        return 
    end
    if not self:CheckCanMatchRobot(nTeamID, nGameType) then 
        return 
    end

    local nRealGameType = self:GetRealGameType(nGameType)
    if gtGameTypeMatchSceneRobot[nRealGameType] then 
        local nCurTime = os.time()
        local nInterval = math.random(30, 60)
        if gbInnerServer then 
            nInterval = math.random(3, 8)
        end
        if not ((math.abs(nCurTime - tTeamData.nTimeStamp) >= nInterval 
                and not tTeamData.nLastMatchStamp) 
            or (tTeamData.nLastMatchStamp 
                and math.abs(nCurTime - tTeamData.nLastMatchStamp) >= nInterval)) then 
            return
        end
        self:MatchSceneRobot(tTeamData, nGameType)
    else
        --固定2分钟
        local nStartRobotMatchStamp = tTeamData.nStartRobotMatchStamp or tTeamData.nTimeStamp
        if math.abs(os.time() - nStartRobotMatchStamp) >= nRobotWaitTime then 
            self:MatchTeamRobot(tTeamData, nGameType)
        end
    end
end

function CTeamMatchMgr:TickMatchRobot()
    --只给队伍匹配机器人
    for nGameType, tKeyList in pairs(self.m_tGameTeamMap) do 
        if self:IsGameTypeMatchRobot(nGameType) then
            --一大坑，递归回调事件会修改源List数据，重新缓存构造一个list
            local tMatchRobotList = {}
            for nTeamID, tTeamData in tKeyList:Iterator() do 
                table.insert(tMatchRobotList, tTeamData)
            end
            for k, tTeamData in ipairs(tMatchRobotList) do 
                self:TeamMatchRobot(tTeamData, nGameType)
            end
        end
    end
end

function CTeamMatchMgr:Tick()
    self:TickRemove()
    self:TickAutoMergeMatch()
    self:TickMatchRobot()
end

--监听下队伍变化事件
function CTeamMatchMgr:OnRoleJoinTeam(nRoleID, nTeamID)
    --如果原来存在队伍，则必定不存在单个玩家的匹配信息
    --如果原来没有队伍，需要尝试，清理掉原来的匹配信息
    --如果玩家当前是队长，并且队伍只有一个人，说明是新创建队伍
    --检查该玩家之前是否有在个人匹配中，如果有，则自动将玩家匹配状态转换成队伍匹配
    local bCreateTeam = false
    local oTeam = goTeamMgr:GetTeamByID(nTeamID) 
    if oTeam then 
        if oTeam:IsLeader(nRoleID) and oTeam:GetMembers() == 1 then 
            bCreateTeam = true
        end
    end

    local nGameType = self.m_tRoleMap[nRoleID]
    self:RemoveRoleMatch(nRoleID)
    if bCreateTeam and nGameType then 
        self:JoinTeamMatch(nTeamID, nGameType)  --自动转换成队伍匹配
        -- --当前只针对镇妖，自动转换队伍匹配，发送广播
        -- if self:GetRealGameType(nGameType) == gtBattleDupType.eZhenYao then 
        --     self:BroadcastTeamMatch(nRoleID, nGameType)
        -- end
        self:BroadcastTeamMatch(nRoleID, nGameType)  --所有的都触发广播
        self:MatchByTeam(nTeamID, nGameType)
        self:SyncMatchInfoByRoleID(nRoleID)
    end

    --可能其他人通过入队申请加入到之前匹配中的队伍了，导致队伍人数满了，此种情况，需要移除匹配
    if nTeamID and nTeamID > 0 then 
        local oTeam = goTeamMgr:GetTeamByID(nTeamID)
        if not oTeam or oTeam:IsFull() then
            if self:RemoveTeamMatch(nTeamID) then 
                self:SyncMatchInfoByRoleID(nRoleID)
            end
            return
        end

        if GF.IsRobot(nRoleID) then 
            local nGameType = self.m_tRobotGameTypeMap[nRoleID]
            if nGameType then 
                local tMatchMap = self.m_tRobotMatchMap[nGameType]
                if tMatchMap then 
                    tMatchMap:Remove(nRoleID)
                end
            end
        end
    end
end

function CTeamMatchMgr:OnRoleQuitTeam(nRoleID, nTeamID)
    --这里需要注意，如果队伍只存在一个玩家，如果此玩家离队，也会调用到这里，然后才会调用到队伍解散
    --do something
    if self.m_tTeamMap[nTeamID] then --原队伍有在匹配，需要给离队玩家同步新的匹配信息
        local oTeam = goTeamMgr:GetTeamByID(nTeamID)
        if oTeam and oTeam:GetMembers() < 3 then --暂时所有玩法匹配的队伍, 都标记下触发机器人匹配的开始时间
            local nGameType = self.m_tTeamMap[nTeamID]
            local tMatchList = self:GetGameTeamMatch(nGameType)
            if tMatchList then 
                local tTeamData = tMatchList:GetData(nTeamID)
                if tTeamData then 
                    tTeamData.nStartRobotMatchStamp = os.time()
                end
            end
        end

        self:SyncMatchInfoByRoleID(nRoleID)
    end

    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if oRole and GF.IsRobot(nRoleID) then 
        local nGameType = self.m_tRobotGameTypeMap[nRoleID]
        if nGameType and oRole:IsOnline() then 
            local tMatchMap = self.m_tRobotMatchMap[nGameType]
            if tMatchMap then 
                tMatchMap:Insert(nRoleID, {nTimeStamp = os.time()})
            end
        end
    end
end

-- function CTeamMatchMgr:OnTeamMemberChange(nTeamID)
--     if not nTeamID or nTeamID < 1 then 
--         return 
--     end
--     local oTeam = goTeamMgr:GetTeamByID(nTeamID)
--     if not oTeam or oTeam:IsFull() then
--         if self:RemoveTeamMatch(nTeamID) then 
--             self:SyncMatchInfoByRoleID(nRoleID)
--         end
--         return
--     end
-- end

function CTeamMatchMgr:OnTeamDismiss(nTeamID)
    if not nTeamID or nTeamID < 1 then 
        return 
    end
    self:RemoveTeamMatch(nTeamID)
end

function CTeamMatchMgr:OnRoleOffline(nRoleID)
    self:RemoveRoleMatch(nRoleID)
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    if oTeam and oTeam:IsLeader(nRoleID) then 
        if self:RemoveTeamMatch(oTeam:GetID()) then 
            print(string.format("队长离线，清除队伍匹配(%d)成功", oTeam:GetID()))
        end
        self:SyncMatchInfoByTeamID(oTeam:GetID())
    end
    if GF.IsRobot(nRoleID) then 
        self:RobotCancelTeamMatch(nRoleID)
    end
end

function CTeamMatchMgr:OnRoleEnterScene(oRole)
    assert(oRole)
    local tDupConf = oRole:GetDupConf()
    if not tDupConf or tDupConf.nType ~= 1 then 
        return 
    end
    --进入主城场景的，都尝试取消所有匹配
    local nRoleID = oRole:GetID()
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    if oTeam and oTeam:IsLeader(nRoleID) then 
        if self:RemoveTeamMatch(oTeam:GetID()) then 
            self:SyncMatchInfoByRoleID(nRoleID)
        end
    else
        if self:RemoveRoleMatch(nRoleID) then 
            self:SyncMatchInfoByRoleID(nRoleID)
        end
    end
end

function CTeamMatchMgr:OnTeamLeaderChange(oTeam, nOldLeaderID)
    --队伍没人，自动解散
    if not oTeam or not oTeam:GetLeader() then 
        return 
    end
    local tLeader = oTeam:GetLeader()
    assert(tLeader)
    local oRoleLeader = goGPlayerMgr:GetRoleByID(tLeader.nRoleID)
    if not oRoleLeader:IsOnline() then 
        if self:RemoveTeamMatch(oTeam:GetID()) then 
            self:SyncMatchInfoByTeamID(oTeam:GetID())
        end
    else
        self:OnRoleEnterScene(oRoleLeader)
    end
end

function CTeamMatchMgr:RemoveMatchByRoleID(nRoleID, bForce) 
    assert(nRoleID > 0, "参数错误")
    -- local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    -- assert(oRole)
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    if oTeam then 
        if not bForce and not oTeam:IsLeader(nRoleID) then
            return 
        end
        local nTeamID = oTeam:GetID()

        -- --------------- DEBUG -------------
        -- local nCurGameType = self.m_tTeamMap[nTeamID]
        -- if nCurGameType then 
        --     print(string.format("队伍(%d)匹配(%d)被取消", nTeamID, nCurGameType))
        -- end
        -- --------------- DEBUG -------------
        
        self:RemoveTeamMatch(nTeamID)
        self:SyncMatchInfoByTeamID(nTeamID)
    else
        -- --------------- DEBUG -------------
        -- local nCurGameType = self.m_tRoleMap[nRoleID]
        -- if nCurGameType then 
        --     print(string.format("玩家(%d)匹配(%d)被取消", nRoleID, nCurGameType))
        -- end
        -- --------------- DEBUG -------------

        self:RemoveRoleMatch(nRoleID)
        self:SyncMatchInfoByRoleID(nRoleID)
    end
end

-----------------外部接口----------------------
--如果当前有处于匹配，则移除匹配
function CTeamMatchMgr:RemoveMatchReq(nRoleID) 
    self:RemoveMatchByRoleID(nRoleID)
end

--只能移除指定玩法的匹配，如果当前不处于指定玩法的匹配，则忽略
function CTeamMatchMgr:RemoveSpecifyGameMatchReq(nRoleID, nGameType)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    assert(oRole)
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    if oTeam and self:IsTeamMatching(oTeam:GetID()) then 
        if not oTeam:IsLeader(nRoleID) then
            oRole:Tips("只有队长才可操作")
            return 
        end
        local nTeamID = oTeam:GetID()
        local nCurGameType = self.m_tTeamMap[nTeamID]
        if nCurGameType and nCurGameType == nGameType then 
            self:RemoveMatchReq(nRoleID)
        end
    else
        if self:IsRoleMatching(nRoleID) then 
            local nCurGameType = self.m_tRoleMap[nRoleID]
            if nCurGameType and nCurGameType == nGameType then 
                self:RemoveMatchReq(nRoleID)
            end
        end
    end
end

function CTeamMatchMgr:BroadcastTeamMatch(nRoleID, nGameType, sGameName)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    assert(oRole)
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    if not oTeam then 
        return 
    end

    sGameName = self:GetGameNameByType(nGameType) or sGameName
    if sGameName then
        local tTalkConf = ctTalkConf["teaminvite"]
        local nMatchLevelID = self:GetMatchLevelID(nGameType, oRole:GetLevel())
        local tMatchLevelConf = ctTeamMatchLevelConf[nMatchLevelID]
        local sLevelString = ""
        if tMatchLevelConf then
            -- sLevelString = string.format("%d-%d级", tMatchLevelConf.nMatchLevelMin, 
            --     tMatchLevelConf.nMatchLevelMax)
            if tMatchLevelConf.sContent and tMatchLevelConf.sContent ~= "0" then 
                sLevelString = tMatchLevelConf.sContent
            end
        end
        local nSysOpenID = 0
        local tTeamMatchConf = ctTeamMatchConf[nGameType]
        if tTeamMatchConf then 
            nSysOpenID = tTeamMatchConf.nSysOpenID or 0
        end

        local sContent = string.format(tTalkConf.sContent, sGameName, sLevelString, oTeam:GetID(), nSysOpenID)
        GF.SendWorldTalk(nRoleID, sContent, true)
    end
end

--sGameName 目前被忽略
function CTeamMatchMgr:JoinMatchReq(nRoleID, nGameType, sGameName, bSys) --sGameName后续准备废弃 
    if not self:CheckGameType(nGameType) then 
        print("不合法的匹配类型", nGameType)
        return 
    end
    if not self.m_tGameTeamMap[nGameType] then 
        self.m_tGameTeamMap[nGameType] = CKeyList:new()
    end
    if not self.m_tGameRoleMap[nGameType] then 
        self.m_tGameRoleMap[nGameType] =  CKeyList:new()
    end
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    assert(oRole)
    if oRole:IsInMarriageActState() then 
        oRole:Tips("婚礼状态无法发起组队匹配")
        return 
    end
    if oRole:IsInPalanquinActState() then 
        oRole:Tips("花轿游行状态无法发起组队匹配")
        return 
    end
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    if oTeam then 
        if not oTeam:IsLeader(nRoleID) then 
            oRole:Tips("只有队长才可操作")
            return 
        end
        if oTeam:IsFull() then 
            oRole:Tips("队伍成员已满")
            return 
        end
        local nTeamID = oTeam:GetID()
        local nOldGame = self.m_tTeamMap[nTeamID]
        if nOldGame and nOldGame == nGameType then 
            oRole:Tips("当前正在匹配中...")
            return 
        end
        if not bSys then 
            local nLastOpStamp = self.m_tMatchOpRecord[nRoleID] or 0
            local nTimeStamp = os.time()
            local nInterval = math.abs(nTimeStamp - nLastOpStamp)  --可能运行中测试改时间
            if nInterval < 60 then 
                return oRole:Tips(string.format("太频繁了，%s秒后再试", 60 - nInterval))
            end
            self.m_tMatchOpRecord[nRoleID] = nTimeStamp
        end

        --尝试移除下旧的匹配
        self:RemoveTeamMatch(nTeamID)
        self:RemoveRoleMatch(nRoleID) --尝试移除下，防止其他地方没回调到，以单人申请匹配，然后马上建队伍，以队伍进行匹配
        self:JoinTeamMatch(nTeamID, nGameType)
        self:BroadcastTeamMatch(nRoleID, nGameType)

        oRole:Tips("匹配进行中，请耐心等待...")
        self:MatchByTeam(nTeamID, nGameType)
    else
        local nOldGame = self.m_tRoleMap[nRoleID]
        if nOldGame and nOldGame == nGameType then 
            oRole:Tips("当前正在匹配中...")
            return 
        end
        if not bSys then 
            local nLastOpStamp = self.m_tMatchOpRecord[nRoleID] or 0
            local nTimeStamp = os.time()
            local nInterval = math.abs(nTimeStamp - nLastOpStamp)  --可能运行中测试改时间
            if nInterval < 60 then 
                return oRole:Tips(string.format("太频繁了，%s秒后再试", 60 - nInterval))
            end
        end
        self.m_tMatchOpRecord[nRoleID] = nTimeStamp
        self:RemoveRoleMatch(nRoleID)
        self:JoinRoleMatch(nRoleID, nGameType)
        oRole:Tips("匹配进行中，请耐心等待...")
        self:MatchByRole(nRoleID, nGameType)
    end
    --不论是否匹配成功，都可以通知到受影响的玩家最新的匹配状态
    self:SyncMatchInfoByRoleID(nRoleID)

    if self:IsAutoMerge(nGameType) then 
        self:AutoMergeMatch(nGameType, sGameName)
    end

    -- --如果没匹配到队伍，则给玩家自动创建队伍
    -- local oTarTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    -- if not oTarTeam then 
    --     goTeamMgr:CreateTeamReq(oRole)
    -- end
    --目前这一步，由具体玩法处控制
end

function CTeamMatchMgr:ClientJoinMatchReq(nRoleID, nGameType)
    assert(nRoleID and nGameType)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    if not self:CheckCanMatchByClient(nGameType) then 
        oRole:Tips("不合法的匹配类型")
        return
    end
    local sGameName = self:GetGameNameByType(nGameType)
    self:JoinMatchReq(oRole:GetID(), nGameType, sGameName, false)
end

function CTeamMatchMgr:SyncMatchInfoByTeamID(nTeamID)
    local nGameType = self.m_tTeamMap[nTeamID]
    local oTeam = goTeamMgr:GetTeamByID(nTeamID)
    if not oTeam then 
        return 
    end

    local nWaitTime = 0
    local nTimeStamp = os.time()
    local nRealGameType = nil
    if nGameType then 
        nRealGameType = self:GetRealGameType(nGameType)
        local tGameTeamList = self:GetGameTeamMatch(nGameType)
        assert(tGameTeamList)
        local tMatchData = tGameTeamList:GetData(nTeamID)
        if tMatchData then 
            nWaitTime = math.max(0, nTimeStamp - tMatchData.nTimeStamp)  --可能改时间
        end
    end

    local bMatchRobot, nRobotCountdown = self:GetMatchRobotInfo(nTeamID)

    local tMsg = {}
    tMsg.nGameType = nRealGameType  -- optional, nGameType可以为nil
    if nRealGameType then 
        tMsg.nWaitTime = nWaitTime
    end
    tMsg.bMatchRobot = bMatchRobot
    tMsg.nRobotCountdown = nRobotCountdown
    
    local tRoleList = oTeam:GetRoleList()
    for k, tRole in pairs(tRoleList) do 
        local oRole = goGPlayerMgr:GetRoleByID(tRole.nRoleID)
        if oRole and oRole:IsOnline() then 
            oRole:SendMsg("TeamMatchInfoRet", tMsg)
        end
    end
end

--如果在队伍，会做队伍广播
function CTeamMatchMgr:SyncMatchInfoByRoleID(nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    assert(oRole)
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    if oTeam then 
        local nTeamID = oTeam:GetID()
        self:SyncMatchInfoByTeamID(nTeamID)
    else
        local nTimeStamp = os.time()
        local nGameType = self.m_tRoleMap[nRoleID]
        local nRealGameType = nil
        local nWaitTime = 0
        if nGameType then 
            nRealGameType = self:GetRealGameType(nGameType)
            local tGameRoleList = self:GetGameRoleMatch(nGameType)
            assert(tGameRoleList)
            local tMatchData = tGameRoleList:GetData(nRoleID)
            if tMatchData then 
                nWaitTime = math.max(0, nTimeStamp - tMatchData.nTimeStamp)
            end 
        end
        local tMsg = {}
        tMsg.nGameType = nRealGameType  -- optional, nGameType可以为nil
        if nRealGameType then 
            tMsg.nWaitTime = nWaitTime
        end
        oRole:SendMsg("TeamMatchInfoRet", tMsg)
    end
end

--同步玩家单人自己的matchinfo
function CTeamMatchMgr:SyncRoleMatchInfo(nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    assert(oRole)
    local nTimeStamp = os.time()
    local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
    if oTeam then 
        local nTeamID = oTeam:GetID()
        local nGameType = self.m_tTeamMap[nTeamID]
        local nRealGameType = nil
        local nWaitTime = 0
        if nGameType then 
            nRealGameType = self:GetRealGameType(nGameType)
            local tGameTeamList = self:GetGameTeamMatch(nGameType)
            assert(tGameTeamList)
            local tMatchData = tGameTeamList:GetData(nTeamID)
            if tMatchData then 
                nWaitTime = math.max(0, nTimeStamp - tMatchData.nTimeStamp)  --可能改时间
            end
        end
        local bMatchRobot, nRobotCountdown = self:GetMatchRobotInfo(nTeamID)
        local tMsg = {}
        tMsg.nGameType = nRealGameType
        if nRealGameType then 
            tMsg.nWaitTime = nWaitTime
        end
        tMsg.bMatchRobot = bMatchRobot
        tMsg.nRobotCountdown = nRobotCountdown

        oRole:SendMsg("TeamMatchInfoRet", tMsg)
    else
        local nGameType = self.m_tRoleMap[nRoleID]
        local nRealGameType = nil
        local nWaitTime = 0
        if nGameType then 
            nRealGameType = self:GetRealGameType(nGameType)
            local tGameRoleList = self:GetGameRoleMatch(nGameType)
            assert(tGameRoleList)
            local tMatchData = tGameRoleList:GetData(nRoleID)
            if tMatchData then 
                nWaitTime = math.max(0, nTimeStamp - tMatchData.nTimeStamp)
            end 
        end
        local tMsg = {}
        tMsg.nGameType = nRealGameType  -- optional, nGameType可以为nil
        if nRealGameType then 
            tMsg.nWaitTime = nWaitTime
        end
        oRole:SendMsg("TeamMatchInfoRet", tMsg)
    end
end

function CTeamMatchMgr:CreateRobotMatchMap() 
    local fnCmp = function(tDataL, tDataR)
        if tDataL.nTimeStamp < tDataR.nTimeStamp then 
            return -1
        elseif tDataL.nTimeStamp > tDataR.nTimeStamp then 
            return 1
        else 
            return 0
        end
    end
    --需要删除和索引性能
    return CRBTree:new(fnCmp)
end

function CTeamMatchMgr:IsSceneMatchRobot(nRobotID) 
    return self.m_tRobotGameTypeMap[nRobotID] and true or false
end

function CTeamMatchMgr:RobotJoinTeamMatch(nRobotID, nGameType)
    print(string.format("机器人(%d)加入队伍匹配请求(%d)", nRobotID, nGameType))
    local oRobot = goGPlayerMgr:GetRoleByID(nRobotID)
    if not oRobot then 
        print(string.format("机器人(%d)对象不存在", nRobotID))
        return 
    end
    local tRobotMap = self.m_tRobotMap[nGameType]
    if not tRobotMap then 
        tRobotMap = {}
        self.m_tRobotMap[nGameType] = tRobotMap
    end
    tRobotMap[nRobotID] = {nTimeStamp = os.time()}

    self.m_tRobotGameTypeMap[nRobotID] = nGameType

    local oTeam = goTeamMgr:GetTeamByRoleID(nRobotID)
    if not oTeam then 
        local tMatchMap = self.m_tRobotMatchMap[nGameType]
        if not tMatchMap then 
            tMatchMap = self:CreateRobotMatchMap()
            self.m_tRobotMatchMap[nGameType] = tMatchMap
        end
        tMatchMap:Insert(nRobotID, {nTimeStamp = os.time()})
    end
end

function CTeamMatchMgr:RobotCancelTeamMatch(nRobotID, nGameType)
    local nRobotGameType = self.m_tRobotGameTypeMap[nRobotID]
    if not nRobotGameType then 
        return 
    end
    print(string.format("机器人(%d)离开队伍匹配请求(%s)", nRobotID, tostring(nGameType)))
    --如果有提供GameType, 校验下，防止某些错误逻辑，将其他匹配机器人移除了
    if nGameType and nGameType ~= nRobotGameType then 
        return 
    end
    nGameType = nRobotGameType

    local tRobotMap = self.m_tRobotMap[nGameType]
    if not tRobotMap then 
        return 
    end
    if not tRobotMap[nRobotID] then 
        return 
    end
    tRobotMap[nRobotID] = nil

    local tMatchMap = self.m_tRobotMatchMap[nGameType]
    if tMatchMap then 
        tMatchMap:Remove(nRobotID)
    end

    if not next(tRobotMap) then --当前匹配活动所有机器人都移除了
        self.m_tRobotMatchMap[nGameType] = nil 
    end
end

function CTeamMatchMgr:CheckJoinMergeTeam(nTeamID, nGameType) 
    local tGameTeamList = self:GetGameTeamMatch(nGameType)
    if not tGameTeamList or tGameTeamList:Count() <= 0 then 
        return false
    end
    local oTeam = goTeamMgr:GetTeamByID(nTeamID)
    if not oTeam or oTeam:IsFull() then 
        return false
    end
    local nTeamMembers = oTeam:GetMembers()
    if nTeamMembers <= 0 then 
        return false
    end

    for nTarTeamID, tTarTeamData in tGameTeamList:Iterator() do 
        local oTarTeam = goTeamMgr:GetTeamByID(nTarTeamID)
        if oTarTeam and oTarTeam:GetID() ~= nTeamID and not oTarTeam:IsFull() then 
            if oTarTeam:GetMembers() + 
                nTeamMembers <= goTeamMgr:GetTeamMemberMaxNum() then 
                return true 
            end
        end
    end
    return false
end

function CTeamMatchMgr:JoinMergeTeam(nTeamID, nGameType) 
    local tGameTeamList = self:GetGameTeamMatch(nGameType)
    if not tGameTeamList or tGameTeamList:Count() <= 0 then 
        return false
    end
    local oTeam = goTeamMgr:GetTeamByID(nTeamID)
    if not oTeam or oTeam:IsFull() then 
        return false
    end
    local nTeamMembers = oTeam:GetMembers()
    if nTeamMembers <= 0 then 
        return false
    end

    for nTarTeamID, tTarTeamData in tGameTeamList:Iterator() do 
        local oTarTeam = goTeamMgr:GetTeamByID(nTarTeamID)
        if oTarTeam and oTarTeam:GetID() ~= nTeamID and not oTarTeam:IsFull() then 
            if oTarTeam:GetMembers() + 
                nTeamMembers <= goTeamMgr:GetTeamMemberMaxNum() then 
                --解散nTeamID队伍, 将成员加入新队伍
                local tRoleIDList = {}
                for _, tTeamRole in ipairs(oTeam:GetRoleList()) do 
                    table.insert(tRoleIDList, tTeamRole.nRoleID)
                end
                oTeam:RemoveTeam()
                for _, nRoleID in ipairs(tRoleIDList) do 
                    oTarTeam:Join(nRoleID, true)
                end
                return true 
            end
        end
    end
    return false
end
