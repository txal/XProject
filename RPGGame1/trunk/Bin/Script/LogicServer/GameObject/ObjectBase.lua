--游戏对象基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CObjectBase:Ctor()
	self.m_bIsRelease = false
end

function CObjectBase:IsOnline() end
function CObjectBase:IsRelease() end

function CObjectBase:GetDup() end
function CObjectBase:GetDupID() end
function CObjectBase:GetScene() end
function CObjectBase:GetSceneID() end
function CObjectBase:GetAOIID() end
function CObjectBase:GetNativeObj() end

function CObjectBase:GetPos() end
function CObjectBase:SetPos(nPosX, nPosY) end
function CObjectBase:StopRun() end

function CObjectBase:GetLine() end
function CObjectBase:SetLine(nLine) end

function CObjectBase:GetNextSceneID() end
function CObjectBase:SetNextSceneID(nSceneID) end

function CObjectBase:EnterScene(nDupID, nSceneID) end
function CObjectBase:LeaveScene() end

function CObjectBase:OnEnterScene(oDup, oScene) end
function CObjectBase:OnLeaveScene(oDup, oScene, bKick) end

function CObjectBase:OnObjEnterView(tObserved) end
function CObjectBase:OnObjLeaveView(tObserved) end
function CObjectBase:OnObjReachTargetPos(nPosX, nPosY) end
