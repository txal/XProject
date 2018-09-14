--所有全局战斗管理器的基类

function CBattleBase:Ctor()
end

function CBattleBase:Offline(oPlayer)
	assert(false)
end	

function CBattleBase:OnEnterScene(oPlayer)
	assert(false)
end	

function CBattleBase:AfterEnterScene(oPlayer)
	assert(false)
end	

function CBattleBase:OnLeaveScene(oPlayer)
	assert(false)
end

function CBattleBase:OnPlayerDead(oPlayer, sAtkerID, nAtkerType, nArmID, nArmType)
	assert(false)
end

function CBattleBase:OnRobotDead(oSRobot, sAtkerID, nAtkerType, nArmID, nArmType)
	assert(false)
end

function CBattleBase:ClientSceneReady(oPlayer)
	assert(false)
end

function CBattleBase:OnReliveReq(oPlayer)
	assert(false)
end	

function CBattleBase:OnEnterBackground(oPlayer)
	assert(false)
end

function CBattleBase:OnEnterForeground(oPlayer)
	assert(false)
end
