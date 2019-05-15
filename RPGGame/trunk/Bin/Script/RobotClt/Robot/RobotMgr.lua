function CRobotMgr:Ctor()
	self.m_tRobotSessionMap = {}
	self.m_sPrefix = ""
	self.m_nRobotNum = 0
	self.m_nRobotID = 0

	self.m_nPacketCount = 0
	self.m_nLastPacketTime = 0
end

function CRobotMgr:RndRobot()
	for nSessionID, oRobot in pairs(self.m_tRobotSessionMap) do
		if oRobot:IsLogon() then
			return oRobot
		end
	end
	LuaTrace("Login robot first")
	return
end

function CRobotMgr:GetRndConn()
	local nSessionID, oRobot = next(self.m_tRobotSessionMap)
	return oRobot
end

function CRobotMgr:GetRobot(nSessionID)
	local oRobot = self.m_tRobotSessionMap[nSessionID]
	return oRobot
end

function CRobotMgr:LoginRobot(sPrefix, nRobotNum)
	self.m_sPrefix = sPrefix
    for k = 1, nRobotNum do
        local tGate = gtGateList[math.random(#gtGateList)]
        goNativeRobotMgr:CreateRobot(tGate[1], tGate[2], 1)                                                                                                                                                                                 
    end 
end

function CRobotMgr:LogoutRobot()
	goNativeRobotMgr:LogoutRobot()
	self.m_sPrefix = ""
	self.m_nRobotID = 0
end

function CRobotMgr:OnLoginSuccess(sRobotName, nMSTime)
	self.m_nRobotNum = self.m_nRobotNum + 1
	LuaTrace(string.format("%s 登陆成功(%f) 当前: %d", sRobotName, nMSTime, self.m_nRobotNum))
end

--开始运行
function CRobotMgr:StartRun()
	for _, oRobot in pairs(self.m_tRobotSessionMap) do
		oRobot:StartRun()
	end
end

--停止运行
function CRobotMgr:StopRun()
	for _, oRobot in pairs(self.m_tRobotSessionMap) do
		oRobot:StopRun()
	end
end

--开始跑动
function CRobotMgr:StartWalk()
	for _, oRobot in pairs(self.m_tRobotSessionMap) do
		oRobot:StartWalk()
	end
end

--停止跑动
function CRobotMgr:StopWalk()
	for _, oRobot in pairs(self.m_tRobotSessionMap) do
		oRobot:StopWalk()
	end
end

--场景准备完毕
function CRobotMgr:SceneReady()
	for nSession, oRobot in pairs(self.m_tRobotSessionMap) do
		if oRobot:IsLogon() then
		    CmdNet.PBClt2Srv("SceneReadyReq", oRobot:PacketID(), nSession, {})
		end
	end
end

function CRobotMgr:AddPacketCount()
	self.m_nPacketCount = self.m_nPacketCount + 1
	if self.m_nLastPacketTime ~= os.time() then
		LuaTrace("second packets:", self.m_nPacketCount)
		self.m_nLastPacketTime = os.time()
		self.m_nPacketCount = 0
	end
end


-------------Native call--------------
function OnRobotConnected(nSessionID)
	LuaTrace("CRobotMgr.OnRobotConnected***", nSessionID)
	local sRobotName = goRobotMgr.m_sPrefix.."Robot"..goRobotMgr.m_nRobotID
	local oRobot = CRobot:new(nSessionID, sRobotName) 
	oRobot:RoleListReq()
	goRobotMgr.m_tRobotSessionMap[nSessionID] = oRobot
	goRobotMgr.m_nRobotID = goRobotMgr.m_nRobotID + 1
end

function OnRobotDisconnected(nSessionID)
	LuaTrace("CRobotMgr.OnRobotDisconnected***", nSessionID)
	local oRobot = goRobotMgr.m_tRobotSessionMap[nSessionID]
	if not oRobot then
		return
	end
	local sRobotName = oRobot:GetName()
	if oRobot:IsLogon() then
		goRobotMgr.m_nRobotNum = goRobotMgr.m_nRobotNum - 1
		LuaTrace(sRobotName.." 已经下线 当前:", goRobotMgr.m_nRobotNum)
	end
	oRobot:Release()
	goRobotMgr.m_tRobotSessionMap[nSessionID] = nil
end


goRobotMgr = goRobotMgr or CRobotMgr:new()
goNativeRobotMgr = GlobalExport.GetRobotMgr()
