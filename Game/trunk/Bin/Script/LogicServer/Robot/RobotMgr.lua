function CRobotMgr:Ctor()
	self.m_tRobotMap = {}
end

function CRobotMgr:GetRobot(nObjID)
	return self.m_tRobotMap[nObjID]
end

--生产角色ID
function CRobotMgr:_GenRobotID()
	return CPlayerMgr:_GenPlayerID()
end

--创建Robot
function CRobotMgr:CreateRobot(nCharID)
	local nRobotID = nCharID or self:_GenRobotID()
	print("CRobotMgr:CreateRobot***", nRobotID)
	local oRobot = CRobot:new(nRobotID, "Robot"..nRobotID)	
	self.m_tRobotMap[nRobotID] = oRobot
	return oRobot
end

--移除Robot
function CRobotMgr:RemoveRobot(nRobotID)
	local oRobot = self.m_tRobotMap[nRobotID]
	self.m_tRobotMap[nRobotID] = nil
	if oRobot then
		oRobot:OnRelease()
	end
end

goRobotMgr = goRobotMgr or CRobotMgr:new()