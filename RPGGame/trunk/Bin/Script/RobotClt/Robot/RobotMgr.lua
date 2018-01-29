goCppRobotMgr = GlobalExport.GetRobotMgr()

function CRobotMgr:Ctor()
	self.m_tRobotSessionMap = {}
	self.m_nRobotNum = 0
	self.m_nMinRobotID = 0
	self.m_nMaxRobotID = 0
	self.m_nRobotID = 0
end

function CRobotMgr:GetRndRobot()
	for nSessionID, oRobot in pairs(self.m_tRobotSessionMap) do
		if oRobot:IsLogged() then
			return oRobot
		end
	end
	LuaTrace("please login robot first")
	return
end

function CRobotMgr:GetRndConn()
	local nSessionID, oRobot = next(self.m_tRobotSessionMap)
	return oRobot
end

function CRobotMgr:LoginRobot(nMinRobotID, nMaxRobotID)
	local nRobotNum = nMaxRobotID - nMinRobotID + 1
	assert(nRobotNum > 0, string.format("登录范围[%d,%d]错误", nMinRobotID, nMaxRobotID))
	self.m_nMinRobotID = nMinRobotID
	self.m_nMaxRobotID = nMaxRobotID
	self.m_nRobotID = self.m_nMinRobotID
	goCppRobotMgr:CreateRobot(gsServerIP, gnServerPort, nRobotNum)
end

function CRobotMgr:LoginAccount(sAccount)
	self.m_sAccount = sAccount
	goCppRobotMgr:CreateRobot(gsServerIP, gnServerPort, 1)
end

function CRobotMgr:LogoutRobot()
	goCppRobotMgr:LogoutRobot()
	self.m_nMinRobotID = 0
	self.m_nMaxRobotID = 0
	self.m_sAccount = nil
	self.m_nRobotID = self.m_nMinRobotID
end

function CRobotMgr:OnLoginSucc(sRobotName, nMSTime)
	self.m_nRobotNum = self.m_nRobotNum + 1
	LuaTrace(string.format("%s 登陆成功(%f) 当前: %d", sRobotName, nMSTime, self.m_nRobotNum))
end

function CRobotMgr:GetRobot(nSessionID)
	local oRobot = self.m_tRobotSessionMap[nSessionID]
	return oRobot
end

--开始跑动
function CRobotMgr:StartRun()
	for _, oRobot in pairs(self.m_tRobotSessionMap) do
		oRobot:StartRun()
	end
end

--场景准备完毕
function CRobotMgr:SceneReady()
	for nSession, oRobot in pairs(self.m_tRobotSessionMap) do
		if oRobot:IsLogged() then
		    CmdNet.PBClt2Srv(oRobot:GenPacketIdx(), nSession, "ClientSceneReadyReq", {})
		end
	end
end




-------------cpp call--------------
function OnRobotConnected(nSessionID)
	LuaTrace("CRobotMgr.OnRobotConnected***", nSessionID)
	if goRobotMgr.m_nRobotID <= goRobotMgr.m_nMaxRobotID then
		local sRobotName 
		if goRobotMgr.m_sAccount then
			sRobotName = goRobotMgr.m_sAccount
		else
			sRobotName = "Robot"..goRobotMgr.m_nRobotID
		end
		local oRobot = CRobot:new(nSessionID, sRobotName) 
		oRobot:Login()
		goRobotMgr.m_tRobotSessionMap[nSessionID] = oRobot
		goRobotMgr.m_nRobotID = goRobotMgr.m_nRobotID + 1
	else
		LuaTrace("ID段["..m_nMinRobotID..","..m_nMaxRobotID.."]用完 当前:", goRobotMgr.m_nRobotNum)
	end
end

function OnRobotDisconnected(nSessionID)
	LuaTrace("CRobotMgr.OnRobotDisconnected***", nSessionID)
	local oRobot = goRobotMgr.m_tRobotSessionMap[nSessionID]
	if oRobot then
		local sRobotName = oRobot:GetName()
		if oRobot:IsLogged() then
			goRobotMgr.m_nRobotNum = goRobotMgr.m_nRobotNum - 1
			LuaTrace(sRobotName.." 已经下线 当前:", goRobotMgr.m_nRobotNum)
		end
		oRobot:Release()
		goRobotMgr.m_tRobotSessionMap[nSessionID] = nil

	end
end


goRobotMgr = goRobotMgr or CRobotMgr:new()
