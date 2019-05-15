--切换城镇场景
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBScene:Ctor(oRobot)
	self.m_oRobot = oRobot
	self.m_nNextTime = os.time() + math.random(300, 600)
end

function CRBScene:Run()
	if os.time() < self.m_nNextTime then
		return
	end
	self.m_nNextTime = os.time() + math.random(300, 600)

	local tCityList = {}
	for _, tConf in pairs(ctDupConf) do
		if tConf.nType == 1 then
			if ctMapConf[tConf.nMapID] then
				table.insert(tCityList, tConf)
			end
		end
	end
	local tConf = tCityList[math.random(#tCityList)]
	local tBorn = tConf.tBorn[1]
	local tMsg = {nRoleID=self.m_oRobot:GetID(), nDupMixID=tConf.nID, nPosX=tBorn[1], nPosY=tBorn[2]}
	self.m_oRobot:SendPressMsg("RoleEnterSceneReq", tMsg)
end
