function CRobot:Ctor(nSessionID, sRobotName)
    self.m_nLastKeepAlive = os.time()
	self.m_nSessionID = nSessionID
    self.m_sName = sRobotName

    self.m_bLogged = false
    self.m_bEnterScene = false
    self.m_bStartRun = false

    self.m_nStartRunTime = 0
    self.m_nStopRunTime = 0
end

function CRobot:GetSession()
	return self.m_nSessionID
end

function CRobot:GenPacketIdx()
    local oCppRobot = goCppRobotMgr:GetRobot(self.m_nSessionID)
    if oCppRobot then
        return oCppRobot:GenPacketIdx()
    end
end

function CRobot:GetPos()
    local oCppRobot = goCppRobotMgr:GetRobot(self.m_nSessionID)
    if oCppRobot then
        return oCppRobot:GetPos()
    end
    return 0, 0
end

function CRobot:GetName()
    return self.m_sName
end

function CRobot:IsLogged()
    return self.m_bLogged
end

function CRobot:Release()
    self.m_bLogged = false
	if self.m_nTimer then
		GlobalExport.CancelTimer(self.m_nTimer)
        self.m_nTimer = nil
	end
end

function CRobot:Update()
    self:KeepAlive()
    self:CheckRun() 
end

function CRobot:CheckRun()
    if not self.m_bLogged or not self.m_bEnterScene then
        return
    end
    local oCppRobot = goCppRobotMgr:GetRobot(self.m_nSessionID)
    if not oCppRobot then
        return
    end
    if not self.m_bStartRun then
        oCppRobot:StopRun()
        return
    end
    local nTimeNow = os.time()
    if nTimeNow - self.m_nStartRunTime > 6 then
        self.m_nStartRunTime = nTimeNow
        local nDir = math.random(0, 7)
        oCppRobot:StartRun(nDir)
    end
end

function CRobot:KeepAlive()
    local nTimeNow = os.time()
    if nTimeNow - self.m_nLastKeepAlive >= 10 then
        self.m_nLastKeepAlive = nTimeNow
        CmdNet.Clt2Srv(self:GenPacketIdx(), self.m_nSessionID, "KeepAlive", nTimeNow)
        --LuaTrace("KeepAlive***", nTimeNow)
    end
end

function CRobot:Login()
    self.m_nLoginTime = os.clock()
    CmdNet.PBClt2Srv(self:GenPacketIdx(), self.m_nSessionID, "LoginReq", {sAccount=self.m_sName, sPassword="11", sPlatform="win", sChannel=""})
end

function CRobot:OnLoginRet(nRes)
    if nRes == -1 then
        local nRoleID = math.random(1, 3)
        CmdNet.PBClt2Srv(self:GenPacketIdx(), self.m_nSessionID, "CreateRoleReq", {sAccount=self.m_sName, sPassword="11", sCharName=self.m_sName, nRoleID=nRoleID})

    --登陆成功
    elseif nRes == 0 then
        self.m_bLogged = true
        goRobotMgr:OnLoginSucc(self.m_sName, os.clock() - self.m_nLoginTime)
        self.m_nTimer = GlobalExport.RegisterTimer(1000, function() self:Update() end)
    end
end

function CRobot:OnCreateRoleRet(nRes)
    print("CRobot:OnCreateRoleRet***", nRes)
    if nRes == -1 then
        print("角色名重复:", self.m_sName)
    elseif nRes == -2 then
        print("角色已存在:", self.m_sName)
    elseif nRes == 0 then
        print("CRobot:", self.m_sName.." 创建角色成功")
        self:Login()
    end
end

function CRobot:OnEnterScene(tData)
    local oCppRobot = goCppRobotMgr:GetRobot(self.m_nSessionID)
    local nPosX, nPosY = tData.nPosX, tData.nPosY 
    local tSceneConf = ctSceneConf[tData.nSceneID]
    oCppRobot:SetMapID(tSceneConf.nMapID)
    oCppRobot:SetPos(nPosX, nPosY)
    oCppRobot:SetName(self.m_sName)
    self.m_bEnterScene = true
    print(self.m_sName, " enter scene")
end

function CRobot:StartRun()
    if not self.m_bEnterScene then
        return
    end
    self.m_bStartRun = not self.m_bStartRun
end
