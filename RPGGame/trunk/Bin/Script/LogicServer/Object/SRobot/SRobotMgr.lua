function CSRobotMgr:Ctor()
	self.m_tRobotMap = {}
end

function CSRobotMgr:GetRobot(sObjID)
	return self.m_tRobotMap[sObjID]
end

function CSRobotMgr:GetCount()
	local nCount = 0
	for sObjID, oRobot in pairs(self.m_tRobotMap) do
		nCount = nCount + 1
	end
	return nCount
end

--创建机器人
function CSRobotMgr:CreateRobot(nConfID, nSceneIndex, nPosX, nPosY, tBattle)
	assert(tBattle and tBattle.nType and tBattle.nCamp)
	assert(ctRobotConf[nConfID], "机器人:"..nConfID.." 不存在")
	local sObjID = GlobalExport.MakeGameObjID()
	local oRobot = CSRobot:new(sObjID, nConfID, tBattle)
	self.m_tRobotMap[sObjID] = oRobot
	oRobot:EnterScene(nSceneIndex, nPosX, nPosY)
	return oRobot
end

--移除
function CSRobotMgr:RemoveRobot(sObjID)
	local oRobot = self:GetRobot(sObjID)
	if oRobot then
		oRobot:OnRelease()
	end
	self.m_tRobotMap[sObjID] = nil
end

--被清理
function CSRobotMgr:OnRobotCollected(sObjID)
	self:RemoveRobot(sObjID)
end


goCppSRobotMgr = GlobalExport.GetRobotMgr()
goLuaSRobotMgr = goLuaSRobotMgr or CSRobotMgr:new()
