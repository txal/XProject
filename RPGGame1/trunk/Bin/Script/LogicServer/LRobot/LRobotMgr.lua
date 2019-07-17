--逻辑服机器人管理模块
--负责机器人在当前逻辑服的行为管理，不做资源管理
--机器人资源管理，嵌入融合到PlayerMgr中，以统一各处的行为
--机器人即可当做一个独立的角色对象，具有和角色一致的行为
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


local bRobotMoveTest = true    --是否开启主场景机器人移动测试(内网模式有效)

function CLRobotMgr:Ctor()
    self.m_tRobotMap = {}      --{nRobotID:oRobot, ...}
    setmetatable(self.m_tRobotMap, {__mode = "kv"}) --设置为虚表

    self.m_nCount = 0
    self.m_nTimer = GetGModule("TimerMgr"):Interval(3, function () self:Tick() end)
    -------------------------
    self.m_tRegMoveMap = {}
    self.m_tMovingMap = {}
    self.m_nLastRobotMoveStamp = os.time()

    -------------------------
    self.m_tTeamRobotMap = {}
    setmetatable(self.m_tRobotMap, {__mode = "kv"}) --设置为虚表

end

function CLRobotMgr:FindRobot(nRobotID)
    if not nRobotID then return end
    return self.m_tRobotMap[nRobotID]
end

function CLRobotMgr:OnEnterLogic(oRole) 
    if not oRole or not oRole:IsRobot() then 
        return 
    end
    local nRobotID = oRole:GetID()
    print(string.format("机器人(%d)登录逻辑服", nRobotID))
    --进入场景前设置，否则注册机器人移动会有问题
    if not self.m_tRobotMap[nRobotID] then 
        self.m_tRobotMap[nRobotID] = oRole
        self.m_nCount = self.m_nCount + 1

        if oRole:IsTeamRobot() then 
            self.m_tTeamRobotMap[nRobotID] = oRole
        end
    end
end

function CLRobotMgr:AfterRobotOnline(oRobot) 
    if not oRobot or not oRobot:IsRobot() then 
        return 
    end

    if gbInnerServer then 
        local tDupConf = oRobot:GetDupConf()
        if tDupConf and tDupConf.nType == CDupBase.tType.eCity then 
            self:RegMove(oRobot:GetID())
        end
    end
end

function CLRobotMgr:OnRobotOffline(oRobot) 
    if not oRobot or not oRobot:IsRobot() then 
        return 
    end
    -- self:CancelRegMove(oRobot:GetID())
end

function CLRobotMgr:OnRobotRelease(oRobot)
    if not oRobot or not oRobot:IsRobot() then 
        return 
    end
    self:CancelRegMove(oRobot:GetID())
    self.m_tRobotMap[oRobot:GetID()] = nil
    self.m_tTeamRobotMap[oRobot:GetID()] = nil
    self.m_nCount = math.max(self.m_nCount - 1, 0)
    print(string.format("移除机器人ID(%d),nSrcID(%d),sName(%s)", 
        oRobot:GetID(), oRobot:GetSrcID(), oRobot:GetName()))
    print(string.format("当前剩余机器人数量(%d)", self.m_nCount))
end

--成功，则返回机器人ID，失败，返回nil
function CLRobotMgr:CreateRobot(nServer, nRobotID, nSrcID, nRobotType, nDupMixID)
    --必须通过WGlobal  GRobotMgr创建，进行nRobotID排重，以及确定nSrcID的有效性
    assert(false, "不可使用")
end

function CLRobotMgr:RemoveRobot(nRobotID)
    if not CUtil:IsRobot(nRobotID) then 
        return 
    end
    goPlayerMgr:RoleOfflineReq(nRobotID, false)
end

--检查清理组队机器人
function CLRobotMgr:CheckClean(nTimeStamp)
    nTimeStamp = nTimeStamp or os.time()
    local tRemoveList = {}
    for nRobotID, oRobot in pairs(self.m_tTeamRobotMap) do 
        --不在队伍，或者在队伍并且是队长，或者在队伍并且当前已暂离
        if oRobot:CheckTeamOp() and math.abs(nTimeStamp - oRobot:GetRobotCreateStamp()) >= 60 then 
            table.insert(tRemoveList, nRobotID)
        end
    end
    for _, nRobotID in ipairs(tRemoveList) do 
        self:RemoveRobot(nRobotID)
    end
end

function CLRobotMgr:Tick(nTimeStamp)
    nTimeStamp  = nTimeStamp or os.time()
    self:CheckClean(nTimeStamp)
    self:TickMove()
end

function CLRobotMgr:Release()
    GetGModule("TimerMgr"):Clear(self.m_nTimer)
    self.m_nTimer = nil
    local tRobotList = {}  --防止回调修改迭代数据，缓存下
    for nRobotID, oRobot in pairs(self.m_tRobotMap) do 
        table.insert(tRobotList, nRobotID)
    end
    print("开始清理机器人")
    for k, nRobotID in ipairs(tRobotList) do 
        self:RemoveRobot(nRobotID)
    end
end

function CLRobotMgr:IsServerClosing() 
    return gbServerClosing
end

function CLRobotMgr:RegMove(nRobotID) 
    if not CUtil:IsRobot(nRobotID) then 
        return 
    end
    local oRobot = self.m_tRobotMap[nRobotID]
    if not oRobot then 
        return 
    end
    assert(oRobot:GetAOIID() > 0, "逻辑错误，机器人不在场景")
    self.m_tRegMoveMap[nRobotID] = os.time()
    oRobot:StopRun()
    print(">>>>>>> 注册机器人移动成功 <<<<<<<<")
end

function CLRobotMgr:CancelRegMove(nRobotID) 
    if not CUtil:IsRobot(nRobotID) then 
        return 
    end
    self.m_tRegMoveMap[nRobotID] = nil 
    self.m_tMovingMap[nRobotID] = nil
    print(">>>>>>> 取消注册机器人移动成功 <<<<<<<<")
end

function CLRobotMgr:TickMove()
    local nCurStamp = os.time()
    local nInterval = 3
	if math.abs(nCurStamp - self.m_nLastRobotMoveStamp) < nInterval then 
		return 
	end
    self.m_nLastRobotMoveStamp = nCurStamp

    local tRunSet = {}
    for nRobotID, _ in pairs(self.m_tRegMoveMap) do 
		local oRobot = self.m_tRobotMap[nRobotID]
        if oRobot and not oRobot:IsInBattle() 
            and oRobot:GetNativeObj() and oRobot:GetAOIID() > 0 then 
			if oRobot:CheckTeamOp() and not self.m_tMovingMap[oRobot:GetID()] then 
				table.insert(tRunSet, oRobot:GetID())
			end
		end
	end
	local nSetNum = #tRunSet
    if nSetNum > 0 then 
        local nMoveSpeed = gtGDef.tConst.nRobotMoveSpeed
        assert(nMoveSpeed > 0)

        local nMoveCount = math.random(1, math.ceil(nSetNum/3))
        local tRandList = CUtil:RandDiffNum(1, nSetNum, nMoveCount)
        for _, nRandIndex in ipairs(tRandList) do 
            local nRobotID = tRunSet[nRandIndex]
            local oRobot = self.m_tRobotMap[nRobotID]

            if oRobot and oRobot:GetNativeObj() and oRobot:GetAOIID() > 0 then 
                local tDupConf = oRobot:GetDupConf()
                assert(tDupConf)
                local nXPosMin = math.min(tDupConf.nWidth, 100)  --避免地图长宽不足100的异常情况
                local nXPosMax = math.max(nXPosMin, tDupConf.nWidth - 100)
                local nYPosMin = math.min(tDupConf.nHeight, 100)
                local nYPosMax = math.max(nYPosMin, tDupConf.nHeight - 100)
                if not (nXPosMin == nXPosMax and nYPosMin == nYPosMax) then 
                    local nXPos = math.random(nXPosMin, nXPosMax)
                    local nYPos = math.random(nYPosMin, nYPosMax)
                    oRobot:RunTo(nXPos, nYPos, nMoveSpeed)
                    self.m_tMovingMap[nRobotID] = nCurStamp
                end
            else
                LuaTrace(string.format("逻辑错误，机器人(%d) 对象(%s)", 
                    nRobotID, oRobot and "不在场景中" or "不存在"))
                if gbInnerServer then 
                    assert(false, string.format("逻辑错误，机器人(%d) 对象(%s)", 
                        nRobotID, oRobot and "不在场景中" or "不存在"))
                end
                self:CancelRegMove(nRobotID)
            end
        end
    end

	--清理旧的异常数据
	local tRemoveList = {}
	for nRobotID, nTempTimeStamp in pairs(self.m_tMovingMap) do 
		if math.abs(nCurStamp - nTempTimeStamp) > 30 then 
			table.insert(tRemoveList, nRobotID) 
		end
	end
    for k, nRobotID in ipairs(tRemoveList) do 
        self.m_tMovingMap[nRobotID] = nil
		local oRobot = self.m_tRobotMap[nRobotID]
		--可能直接离线被踢出去了当前不存在此对象了，或者已离开场景了
        if oRobot and oRobot:GetNativeObj() and oRobot:GetAOIID() > 0 then 
            oRobot:StopRun()
        end
    end
end

function CLRobotMgr:OnReachTargetPos(oRobot)
    if not oRobot or not oRobot:IsRobot() then 
        return 
    end
    self.m_tMovingMap[oRobot:GetID()] = nil
end

