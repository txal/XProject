--机器人管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--[[
机器人创建及销毁流程

创建
查找符合条件的离线玩家
rpc调用对应逻辑服CreateRobotReq
在这个调用中，其实走的就是和角色上线RoleOnlineReq类似的流程
利用上线回调中的同步信息，对相关全局服进行RoleOnlineReq同步
全局服中区分是机器人ID还是玩家，进行对应处理，创建全局服上的机器人数据对象
机器人不需要走全局服的子模块online流程

销毁
逻辑服上角色离线触发
也可以由全局服直接rpc调用触发
首先清理当前逻辑服上的机器人数据对象
机器人离线过程逻辑和角色一样的，会触发角色离线同步到全局服
全局服收到角色离线同步信息RoleOfflineReq时判断是否为机器人
然后将机器人对象数据从全局服清理

]]


local nRobotTestLimitNum = 15    --主场景测试机器人总数量(内网模式有效)
local bMirrorDuplicate = false   --是否可创建重复的玩家镜像机器人(更改后需重启)

function CGRobotMgr:Ctor() 
    self.m_tRobotMap = {}  --nRobotID:nSrcID
    self.m_nRobotCount = 0
    self.m_nKey = 0

    self.m_tMirrorMap = {}      --玩家镜像map {nRoleID:{RobotID:{}, ...}, ...}

    self.m_tRobotNameMap = {}   --缓存机器人临时占用的名称
    self.m_tRandNameData = {nCount = 0, nTryTimes = 0, nFail = 0, nTimeCost = 0}   --统计数据

    self.m_nStartStamp = os.time()  --Test
    self.m_tTestRobotMap = {}       --Test
    self.m_nTestRobotCount = 0      --Test
    self.m_tTestRobotCreateStamp = os.time()  --Test

    self.m_oMatchPool = CMatchHelper:new(1) 
end

function CGRobotMgr:GenRobotID()
    if self.m_nRobotCount >= 9998 then 
        return 
    end
    local nRobotID = 0
    for k = 1, 500 do --最多尝试500次
        self.m_nKey = math.max(self.m_nKey % 9999, 1) + 1  --屏蔽掉id 1
        if not self.m_tRobotMap[self.m_nKey] then --当前已存在，还未销毁
            nRobotID = self.m_nKey
            break
        end
    end
    return nRobotID
end

function CGRobotMgr:Init() --放在GPlayerMgr后面处理
    for k, oRole in pairs(goGPlayerMgr.m_tRoleIDMap) do 
        if not oRole:IsRobot() then 
            self:AddToRoleMatchPool(oRole:GetID(), oRole:GetLevel())
        end
    end
    self.m_nTimer = goTimerMgr:Interval(3, function () self:Tick() end)
end

function CGRobotMgr:AddToRoleMatchPool(nRoleID, nLevel)
    assert(nRoleID > 0 and nLevel >= 0)
    if not bMirrorDuplicate then 
        local tMirror = self.m_tMirrorMap[nSrcID] or {}
        if tMirror and next(tMirror) then 
            return
        end
    end


    --低等级玩家太多了，过滤下
    if nLevel <= 5 then
        return 
    end
    self.m_oMatchPool:UpdateValue(nRoleID, nLevel)
end

function CGRobotMgr:RemoveFromMatchPool(nRoleID)
    self.m_oMatchPool:Remove(nRoleID)
end

function CGRobotMgr:OnRelease()
    goTimerMgr:Clear(self.m_nTimer)
end

function CGRobotMgr:OnRobotCreate(oRobot)
    assert(oRobot and oRobot:IsRobot(), "错误调用")
    local nRobotID = oRobot:GetID()
    local nSrcID = oRobot:GetSrcID()
    self.m_tRobotMap[nRobotID] = nSrcID
    self.m_nRobotCount = self.m_nRobotCount + 1

    local tMirror = self.m_tMirrorMap[nSrcID] or {}
    tMirror[nRobotID] = {}
    self.m_tMirrorMap[nSrcID] = tMirror

    if GF.IsRobot(nSrcID) then 
        --如果是配置机器人，将机器人名字打上标记，当前已使用
    end
    -- if not bMirrorDuplicate then 
    --     self:RemoveFromMatchPool(nSrcID)
    -- end
    print(string.format("创建机器人成功,nID(%d),nSrcID(%d),sName(%s)", nRobotID, nSrcID, oRobot:GetName()))
end

function CGRobotMgr:OnRobotRelease(oRobot)
    if not oRobot or not oRobot:IsRobot() then 
        return 
    end
    local nRobotID = oRobot:GetID()
    if goTeamMgr then 
        local oTeam = goTeamMgr:GetTeamByRoleID(nRobotID)
        if oTeam then
            oTeam:QuitReq(oRobot)
        end
    end

    self.m_tRobotMap[nRobotID] = nil
    self.m_nRobotCount = math.max(self.m_nRobotCount - 1, 0)

    local nSrcID = oRobot:GetSrcID()
    local tMirror = self.m_tMirrorMap[nSrcID]
    if tMirror then 
        tMirror[nRobotID] = nil
        if not next(tMirror) then --如果没其他机器人了，清理掉此数据，防止一直存留在服务器
            self.m_tMirrorMap[nSrcID] = nil
        end
    end

    print(string.format("移除机器人成功,nID(%d),nSrcID(%d),sName(%s)", 
        nRobotID, oRobot:GetSrcID(), oRobot:GetName()))

    if self.m_tTestRobotMap[nRobotID] then 
        self.m_tTestRobotMap[nRobotID] = nil
        self.m_nTestRobotCount = math.max(self.m_nTestRobotCount - 1, 0)
    end

    if GF.IsRobot(nSrcID) then 
        self.m_tRobotNameMap[oRobot:GetName()] = nil
    end
end

function CGRobotMgr:RandRobotName()
    local fnGenName = function()
        local fnGetWeight = function(tConf) return 100 end
        local tResult = CWeightRandom:Random(ctRoleNamePoolConf, fnGetWeight, 2, false)
        assert(tResult and #tResult == 2)
        local tLastName = tResult[1].tXing 
        local tFirstName = tResult[2].tMing 
        local sLastName = tLastName[math.random(#tLastName)][1]
        local sFirstName = tFirstName[math.random(#tFirstName)][1]
        return sLastName..sFirstName
    end

    local nBeginTime = os.clock()
    local sName = nil
    local nTryTimes = 0
    for k = 1, 20 do  --暴力随机
        nTryTimes = k
        local sTempName = fnGenName()
        if sTempName then 
            if not self.m_tRobotNameMap[sTempName] then 
                local sData = goDBMgr:GetSSDB(0, "center"):HGet(gtDBDef.sRoleNameDB, sTempName)
                if sData == "" then
                    sName = sTempName
                    break
                end
            end
        end
    end
    local nEndTime = os.clock()

    local tRandData = self.m_tRandNameData
    tRandData.nCount = tRandData.nCount + 1
    tRandData.nTryTimes = tRandData.nTryTimes + nTryTimes
    tRandData.nTimeCost = tRandData.nTimeCost + math.ceil((nEndTime - nBeginTime) * 1000)
    if not sName then 
        tRandData.nFail = tRandData.nFail + 1
        local nAverageTry = math.ceil(tRandData.nCount / math.max(tRandData.nTryTimes, 1))
        LuaTrace("随机机器人名称失败！！！！")
        LuaTrace(string.format("总共随机(%d)次, 尝试(%d)次, 平均每次尝试(%d)次, 共失败(%d)次", 
            tRandData.nCount, tRandData.nTryTimes, nAverageTry, tRandData.nFail))
        local nAverageTime = math.ceil((tRandData.nTimeCost / tRandData.nCount))
        LuaTrace(string.format("总耗时(%d)ms, 平均每次耗时(%d)ms", tRandData.nTimeCost, nAverageTime))
    end
    return sName
end

--fnCallback(nRobotID) nRobotID大于0，才是有效值
--nSrcID 机器人配置ID或者镜像数据源的真实角色ID
--nRobotType  gtRobotType
--角色和配置的走同一个 配置ID范围为 101 - 9999
--nServer 机器人所属服务器, 如果为玩家镜像机器人数据，则当前nServer需为nSrcID角色同一个服ID
--后续再扩展跨服镜像机器人
--tParam, 如果nSrcID >= 0 and nSrcID <= 9999, 则需要tParam{nRoleConfID, nLevel, }
--如果nRoleConfID不提供，则随机，nLevel不提供，则1-99随机

--TODO 优化拆分
function CGRobotMgr:_CreateRobot(nServer, nSrcID, nRobotType, nDupMixID, fnCallback, tParam)
    assert(nServer and nSrcID and nDupMixID) --当前不支持逻辑服切换，必须指定场景

    local sRandRobotName = nil
    local fnInnerCallback = function(nRobotID)
        if not nRobotID or nRobotID <= 0 then 
            print("创建机器人失败")
            if nSrcID > 0 and not GF.IsRobot(nSrcID) then 
                local oSrcRole = goGPlayerMgr:GetRoleByID(nSrcID)
                if oSrcRole and not oSrcRole:IsOnline() then  
                    self:AddToRoleMatchPool(nSrcID, oSrcRole:GetLevel())
                end
                if sRandRobotName then 
                    self.m_tRobotNameMap[sRandRobotName] = nil
                end
            end
            if fnCallback then 
                fnCallback(nRobotID)
            end
            return
        end
        if fnCallback then 
            fnCallback(nRobotID)
        end
    end
    if not bMirrorDuplicate then 
         --直接在这里移除匹配，防止异步返回前，再次创建机器人，导致出现多个重复的
        self:RemoveFromMatchPool(nSrcID) 
    end
    local nServiceID = 0
    local nDupID = GF.GetDupID(nDupMixID)
    local tDupConf = ctDupConf[nDupID]
    if tDupConf then
        nServiceID = tDupConf.nLogic
    else
        return fnInnerCallback(0)
    end

    --nSrcID暂时改动下，支持由服务器动态生成机器人
    --目前非玩家镜像机器人，不走配置，直接指定nSrcID为0，并附带相关参数即可
    if nSrcID < 0 then 
        return  fnInnerCallback(0)
    end

    --具体规则，由外部玩法控制
    if nSrcID > 0 and not GF.IsRobot(nSrcID) then 
        local oSrcRole = goGPlayerMgr:GetRoleByID(nSrcID) 
        if not oSrcRole then 
            print(string.format("目标角色镜像(%d)不存在，已退出", nSrcID))
            return 
        end
        --暂时不支持创建跨服机器人
        --例如角色A位于1服，角色B位于2服
        --当向1服的本地逻辑服创建角色B的镜像机器人时，访问数据受限，需要中转下
        --后续再支持创建跨服镜像机器人
        assert(nServer == oSrcRole:GetServer())
    end
    
    --实际根据nRobotID来区分机器人唯一性，允许用同一个玩家数据，创建多个镜像机器人
    local nRobotID = self:GenRobotID()
    if not nRobotID or nRobotID <= 0 then 
        fnInnerCallback(0)
    end

    if nSrcID == 0 or GF.IsRobot(nSrcID) then 
        tParam = tParam or {}
        sRandRobotName = self:RandRobotName()
        if not sRandRobotName then 
            return fnInnerCallback(0) 
        end
        self.m_tRobotNameMap[sRandRobotName] = nRobotID

        tParam.sName = sRandRobotName
        if not tParam.nRoleConfID then 
            tParam.nRoleConfID = math.random(10)
        end
        if not tParam.nLevel then 
            tParam.nLevel = math.random(1, 99)
        end
        nSrcID = nRobotID --直接指定和robotid一样，兼容后续机器人配置功能
        print("创建机器人参数", tParam)
    end

    goRemoteCall:CallWait("CreateRobotReq", fnInnerCallback, nServer, nServiceID, 0,
        nServer, nRobotID, nSrcID, nRobotType, nDupMixID, tParam)
end

--nServer 机器人所属服务器ID, 类似每个角色都有一个所归属的服务器ID
-- 如果机器人是投放到是世界服上的逻辑服，而且可以属于跨服组的任意服务器, 可以填0，则会随机指定一个服务器
--nLevelMin, nLevelMax, 机器人等级随机范围
--nRoleConfID 机器人角色配置ID，决定机器人职业性别，填0则随机一个职业
--nRobotType 机器人类型 查看 gtRobotType
--nDupMixID 机器人即将进入的场景ID
--nTeamID 可为nil, 如果有提供nTeamID, 则创建的机器人，必定不会是这个队伍中的离线玩家镜像
--fnCallback 创建回调, 可以为nil  fnCallback(nRobotID) 如果nRobotID > 0则创建成功，否则创建失败
function CGRobotMgr:CreateRobot(nServer, nLevelMin, nLevelMax, nRoleConfID, nRobotType, nDupMixID, nTeamID, fnCallback)
    assert(nServer and nServer < gnWorldServerID and nLevelMin and nLevelMax > 0 
        and nRoleConfID and nRobotType and nDupMixID, "参数错误")
    
    local tRoleConfID = {}
    if nRoleConfID > 0 then 
        tRoleConfID = {nRoleConfID}
    end
    local nSrcID = goGRobotMgr:MatchRobotSrcID(nServer, nLevelMin, nLevelMax, tRoleConfID, nTeamID)

    local tRobotParam = {}
    if not nSrcID or nSrcID <= 0 then 
        nSrcID = 0
        tRobotParam.nLevel = math.random(nLevelMin, nLevelMax)
        if nRoleConfID > 0 then 
            tRobotParam.nRoleConfID = nRoleConfID
        end

        if nServer <= 0 then 
            local tServerList = {}
            local tServerMap = goServerMgr:GetServerMap()
            for nServerID, v in pairs(tServerMap) do 
                table.insert(tServerList, nServerID)
            end
            nServer = tServerList[math.random(#tServerList)]
        end
    else
        local oRole = goGPlayerMgr:GetRoleByID(nSrcID)
        assert(oRole)
        nServer = oRole:GetServer() --可能为0，需要设置为角色的服务器
    end
    goGRobotMgr:_CreateRobot(nServer, nSrcID, nRobotType, nDupMixID, fnCallback, tRobotParam)
end

--角色和机器人上线，都会回调这个
function CGRobotMgr:Online(oRole)
    if not oRole then return end
    local bRobot = oRole:IsRobot()
    if bRobot then 
        self:OnRobotCreate(oRole)
    end
    if not bRobot then 
        self:RemoveFromMatchPool(oRole:GetID())
        --如果当前有机器人占用了这个角色的名称
        if self.m_tRobotNameMap[oRole:GetName()] then 
            local nRobotID = self.m_tRobotNameMap[oRole:GetName()]
            self:RemoveRobot(nRobotID)
        end
    end

    --如果存在该玩家镜像机器人，通知机器人下线
    if not bRobot then 
        local tMirror = self.m_tMirrorMap[oRole:GetID()] 
        if tMirror then 
            for nRobotID, tData in pairs(tMirror) do 
                self:RemoveRobot(nRobotID)
            end
        end
    end
end

--角色和机器人离线，都会回调这个
function CGRobotMgr:Offline(oRole)
    if not oRole then return end
    if oRole:IsRobot() then 
        if goTeamMgr then 
            local nRobotID = oRole:GetID()
            local oTeam = goTeamMgr:GetTeamByID(nRobotID)
            if oTeam then 
                oTeam:QuitReq(oRole)
            end
        end
    end
end

--角色和机器人离线，都会回调这个
function CGRobotMgr:OnRoleRelease(oRole)
    if not oRole then return end
    local bRobot = oRole:IsRobot()
    if bRobot then 
        self:OnRobotRelease(oRole)
    end

    --如果是角色或者角色镜像机器人，重新加入到匹配池
    if not oRole:IsRobot() then 
        self:AddToRoleMatchPool(oRole:GetID(), oRole:GetLevel())
    elseif oRole:IsMirror() then  
        local nSrcID = oRole:GetSrcID()
        local oSrcRole = goGPlayerMgr:GetRoleByID(nSrcID)
        --角色上线，会触发机器人离线，执行到这里时，角色已在线，所以这里需要判断下源角色是否在线
        if oSrcRole and not oSrcRole:IsOnline() then 
            self:AddToRoleMatchPool(nSrcID, oSrcRole:GetLevel())
        end
    end

end

function CGRobotMgr:RemoveRobot(nRobotID)
    local oRobot = goGPlayerMgr:GetRoleByID(nRobotID)
    if not oRobot or not oRobot:IsRobot() then --机器人离线会循环触发多次回调到这里
        -- LuaTrace(string.format("RemoveRobot:机器人不存在(%d)", nRobotID))
        print("机器人不存在或者目标不是机器人", nRobotID)
        return 
    end
    -- LuaTrace(string.format("RemoveRobot:移除机器人(%d)(%s)", oRobot:GetID(), oRobot:GetName()))
    goRemoteCall:Call("RoleOfflineReq", oRobot:GetStayServer(), oRobot:GetLogic(), 0, nRobotID)
end

--nServer填0，不限服务器
--tRoleConfIDList,目标职业ID，空table{}或者nil，表示任意职业, tRoleConfIDList应当是一个数组列表，例如{1, 3, 4, 5}
--nTeamID可以为nil
function CGRobotMgr:MatchRobotSrcID(nServer, nLevelMin, nLevelMax, tRoleConfIDList, nTeamID)
    assert(nServer and nLevelMin >= 0 and nLevelMax >= 0 and nLevelMin <= nLevelMax, "参数错误")
    local oTeam = nil
    if nTeamID and nTeamID > 0 then 
        oTeam = goTeamMgr:GetTeamByID(nTeamID)
    end
    local fnFilter = function(nID)
        local oRole = goGPlayerMgr:GetRoleByID(nID)
        if not oRole then 
            return false
        end
        if oTeam and oTeam:IsInTeam(nID) then 
            return false 
        end
        if 0 ~= nServer then
            if oRole:GetServer() ~= nServer then 
                return false 
            end
        end
        local nRoleLevel = oRole:GetLevel()
        if nRoleLevel < nLevelMin or nRoleLevel > nLevelMax then 
            return false
        end
        if tRoleConfIDList and #tRoleConfIDList > 0 then 
            local nRoleConfID = oRole:GetConfID()
            local bMatch = false 
            for _, nTempConfID in ipairs(tRoleConfIDList) do 
                if nTempConfID == nRoleConfID then 
                    bMatch = true 
                    break 
                end
            end
            if not bMatch then 
                return false 
            end
        end
        return true 
    end

    if self.m_oMatchPool:IsEmpty() then 
        return
    end

    local nTarLevel = math.floor((nLevelMin + nLevelMax) / 2)
    local tRoleList = self.m_oMatchPool:MatchTarget({}, nLevelMin, nLevelMax, nTarLevel, 6, 30, fnFilter)	
    local nMatchCount = #tRoleList
    if nMatchCount <= 0 then --没有其他玩家
        return 
    end
    local nTarRole = tRoleList[math.random(nMatchCount)]
    return nTarRole
end

function CGRobotMgr:TestCreate()
    if self.m_nTestRobotCount >= nRobotTestLimitNum then 
        return 
    end
    if self.m_oMatchPool:IsEmpty() then 
        return
    end
    local nLevel = math.random(5, 90)
    local tRoleList = self.m_oMatchPool:MatchTarget({}, 
        math.max(nLevel-10, 0), nLevel+10, nLevel, 6, 30)	
    local nMatchCount = #tRoleList
    if nMatchCount <= 0 then --没有其他玩家
        return
    end
    local nTarRole = tRoleList[math.random(nMatchCount)]
    local oTarRole = goGPlayerMgr:GetRoleByID(nTarRole)
    if not oTarRole then 
        return 
    end

    --随机一个场景
    local tRandDupList = {1, 2, 3, 4, 5, 6, 8, 20}
    local tDupConf = ctDupConf[tRandDupList[math.random(#tRandDupList)]]
    assert(tDupConf)

    local fnCallback = function(nRobotID)
        if not nRobotID or nRobotID <= 0 then return end 
        self.m_tTestRobotMap[nRobotID] = nRobotID
        self.m_nTestRobotCount = self.m_nTestRobotCount + 1
    end
    self:_CreateRobot(oTarRole:GetServer(), nTarRole, gtRobotType.eTeam, tDupConf.nID, fnCallback)
end

function CGRobotMgr:TestRemove()
    if self.m_nTestRobotCount < nRobotTestLimitNum or self.m_nTestRobotCount <= 0 then 
        return 
    end
    local fnGetWeight = function(tNode) return 100 end
    local tRandResult = CWeightRandom:RandomRetKey(self.m_tTestRobotMap, fnGetWeight, 1, false)
    assert(tRandResult and #tRandResult > 0)
    local nRobotID = tRandResult[1].key
    self:RemoveRobot(nRobotID)
end

function CGRobotMgr:Tick(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    if gbInnerServer and math.abs(nTimeStamp - self.m_nStartStamp) >= 60 
        and math.abs(nTimeStamp - self.m_tTestRobotCreateStamp) > 20 then 
        -- print(string.format("当前机器人总数量(%d),测试机器人数量(%d)", 
        --     self.m_nRobotCount, self.m_nTestRobotCount))
        self.m_tTestRobotCreateStamp = nTimeStamp
        self:TestRemove()
        self:TestCreate()
    end
end


goGRobotMgr = goGRobotMgr or CGRobotMgr:new()


