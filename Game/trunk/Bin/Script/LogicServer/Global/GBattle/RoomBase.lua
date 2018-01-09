--所有全局战斗管理器的基类

function CRoomBase:Ctor()
end

function CRoomBase:IsRuning()
	print("CRoomBase:IsRuning***")
	assert(false)
end

function CRoomBase:Offline(oPlayer)
	print("CRoomBase:Offline***")
end	

function CRoomBase:OnEnterScene(oPlayer)
	print("CRoomBase:OnEnterScene***")
end	

function CRoomBase:AfterEnterScene(oPlayer)
	print("CRoomBase:AfterEnterScene***")
end	

function CRoomBase:OnLeaveScene(oPlayer)
	print("CRoomBase:OnLeaveScene***")
end

function CRoomBase:OnClientSceneReady(oPlayer)
	print("CRoomBase:OnClientSceneReady***")
end

function CRoomBase:OnEnterBackground(oPlayer)
	print("CRoomBase:OnEnterBackground***")
end

function CRoomBase:OnEnterForeground(oPlayer)
	print("CRoomBase:OnEnterForeground***")
end

--玩家死亡
function CRoomBase:OnPlayerDead(oPlayer, sAtkerID, nAtkerType, nArmID, nArmType)
	print("CRoomBase:OnPlayerDead***")
end

--发送战场表情请求
function CRoomBase:OnSendBattleFaceReq(oPlayer, nFaceID)
	print("CRoomBase:OnSendBattleFaceReq***")
end

--复活请求
function CRoomBase:OnReliveReq(oPlayer)
	print("CRoomBase:OnReliveReq***")
end	

--治疗请求
function CRoomBase:OnCureReq(oPlayer)
	print("CRoomBase:OnCureReq***")
end	
