local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRobot:Ctor(nSessionID, sRobotName)
    self.m_nLastKeepAlive = os.time()
	self.m_nSessionID = nSessionID
    self.m_sName = sRobotName
    self.m_nAccountID = 0
    self.m_nRoleID = 0

    self.m_bLogon = false
    self.m_nLoginTime = 0

    self.m_bStartRun = false
    self.m_bEnterScene = false

    --self.m_nRunHoldTime = 0
    --self.m_nStopHoldTime = 0
	--self.m_bWalk = false
	
	self.m_nNextMsgTime = os.time()+math.random(4, 16)


    self.m_nDupID = 0
    self.m_tModuleList = {}
	self.m_tModuleMap = {}
    self:CreateModule()
end

function CRobot:CreateModule()
	self.m_tModuleMap["scene"] = CRBScene:new(self)
    self.m_tModuleMap["battle"] = CRBBattle:new(self)
    self.m_tModuleMap["friend"] = CRBFriend:new(self)
    self.m_tModuleMap["talk"] = CRBTalk:new(self)
    self.m_tModuleMap["team"] = CRBTeam:new(self)
    self.m_tModuleMap["union"] = CRBUnion:new(self)
    self.m_tModuleMap["kanpsack"] = CRBKnapsack:new(self)
    self.m_tModuleMap["ranking"] = CRBRanking:new(self)
    self.m_tModuleMap["walk"] = CRBWalk:new(self)

	for _, oModule in pairs(self.m_tModuleMap) do
		table.insert(self.m_tModuleList, oModule)
	end
end

function CRobot:GetSession() return self.m_nSessionID end
function CRobot:GetName() return self.m_sName end
function CRobot:IsLogon() return self.m_bLogon end
function CRobot:GetID() return self.m_nRoleID end
function CRobot:GetDupID() return self.m_nDupID end

function CRobot:PacketID()
    local oNativeRobot = goNativeRobotMgr:GetRobot(self.m_nSessionID)
    if oNativeRobot then
        return oNativeRobot:PacketID()
    end
end

function CRobot:SendMsg(sCmd, tMsg)
    CmdNet.PBClt2Srv(sCmd, self:PacketID(), self.m_nSessionID, tMsg)
end

function CRobot:SendPressMsg(sCmd, tMsg)
    if self.m_bStartRun then
        CmdNet.PBClt2Srv(sCmd, self:PacketID(), self.m_nSessionID, tMsg)
		goRobotMgr:AddPacketCount()
    end
end

function CRobot:GetPos()
    local oNativeRobot = goNativeRobotMgr:GetRobot(self.m_nSessionID)
    if oNativeRobot then
        return oNativeRobot:GetPos()
    end
    return 0, 0
end

function CRobot:Release()
    self.m_bLogon = false
    goTimerMgr:Clear(self.m_nTimer)
    self.m_nTimer = nil
end

function CRobot:Update()
    self:KeepAlive()
    --self:CheckRun()
    self:UpdateModule()
end

function CRobot:RndMoveTarget()
    local tDupConf = ctDupConf[self.m_nDupID]
    local tMapConf = ctMapConf[tDupConf.nMapID] 
    local nTarPosX = math.random(tMapConf.nWidth)-1
    local nTarPosY = math.random(tMapConf.nHeight)-1
    local nDir = math.random(3) - 1
     local oNativeRobot = goNativeRobotMgr:GetRobot(self.m_nSessionID)
    local nSpeedX, nSpeedY = oNativeRobot:CalcMoveSpeed(300, nTarPosX, nTarPosY)
    return nSpeedX, nSpeedY, nTarPosX, nTarPosY, nDir
end

function CRobot:CheckRun()
    if not self.m_bLogon or not self.m_bEnterScene then
        return
    end
    local oNativeRobot = goNativeRobotMgr:GetRobot(self.m_nSessionID)
    if not oNativeRobot then
        return
    end

    if not self.m_bStartRun then
        return oNativeRobot:StopRun()
    end
	
	 if not self.m_bWalk then
        return oNativeRobot:StopRun()
	 end

    if self.m_nRunHoldTime > 0 then
        if os.time() >= self.m_nRunHoldTime then
            self.m_nRunHoldTime = 0
            self.m_nStopHoldTime = os.time() + math.random(4, 16)
            oNativeRobot:StopRun()
			--LuaTrace("stopwalk****")
        end

    elseif self.m_nStopHoldTime > 0 then
        if os.time() >= self.m_nStopHoldTime then
            self.m_nRunHoldTime = os.time() + math.random(4, 16)
            self.m_nStopHoldTime = 0
			if not self.m_tModuleMap["battle"]:IsInBattle() then
				oNativeRobot:StartRun(self:RndMoveTarget())
				--LuaTrace("startwalk****")
			end
        end
    end
end

function CRobot:KeepAlive()
    local nTimeNow = os.time()
    if nTimeNow - self.m_nLastKeepAlive >= 10 then
        self.m_nLastKeepAlive = nTimeNow
        CmdNet.Clt2Srv("KeepAlive", self:PacketID(), self.m_nSessionID, nTimeNow)
    end
end

function CRobot:RoleListReq()
    self.m_nLoginTime = os.clock()
    self:SendMsg("RoleListReq", {nSource=0, sAccount=self.m_sName})
end

function CRobot:OnRoleListRet(tData)
    local nSource = 0
    if #tData.tList > 0 then
        print("登录角色请求", self.m_nSessionID) 
        local tRole = tData.tList[math.random(#tData.tList)]
        self:SendMsg("RoleLoginReq", {nAccountID=tData.nAccountID, nRoleID=tRole.nID})
    else
        print("创建角色请求", self.m_nSessionID) 
        local nConfID = 1 --math.random(#ctRoleInitConf)
        self:SendMsg("RoleCreateReq", {nAccountID=tData.nAccountID, nConfID=nConfID, sName=self.m_sName})
    end
end

function CRobot:OnLoginRet(tData)
    self.m_nAccountID = tData.nAccountID
    self.m_nRoleID = tData.nRoleID

    goRobotMgr:OnLoginSuccess(self.m_sName, os.clock()-self.m_nLoginTime)
    self.m_nTimer = goTimerMgr:Interval(1, function() self:Update() end)
    self.m_bLogon = true
    self.m_nLoginTime = os.time()

end

function CRobot:OnEnterScene(tData)
    local oNativeRobot = goNativeRobotMgr:GetRobot(self.m_nSessionID)
    local nPosX, nPosY = tData.nPosX, tData.nPosY 
    local tDupConf = ctDupConf[tData.nDupID]
    oNativeRobot:SetMapID(tDupConf.nMapID, tData.nAOIID)
    oNativeRobot:SetName(self.m_sName)
    oNativeRobot:SetPos(nPosX, nPosY)
    self.m_bEnterScene = true
    self.m_nDupID = tData.nDupID
end


function CRobot:StartRun()
	if not self.m_bLogon then
		return
	end
    self.m_bStartRun = true
    self.m_nStopHoldTime = os.time()+math.random(4, 16)
end

function CRobot:StopRun()
	--self.m_bWalk = false
    self.m_bStartRun = false
end

--function CRobot:StartWalk()
	--self.m_bWalk = true
--end

--function CRobot:StopWalk()
	--self.m_bWalk = false
--end

function CRobot:UpdateModule()
    if not self.m_bStartRun then
        return
    end
	if os.time() < self.m_nNextMsgTime then
		return
	end
	self.m_nNextMsgTime = os.time()+math.random(4, 16)

	local oModule = self.m_tModuleList[math.random(#self.m_tModuleList)]
	oModule:Run()
end
