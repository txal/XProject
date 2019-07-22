--游戏对象基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local oNativeRoleMgr = GlobalExport.GetRoleMgr()

function CObjectBase:Ctor(nObjID, nObjType, nConfID)
	assert(nObjID and nObjType and nConfID, "参数错误")
	self.m_nObjID = nObjID
	self.m_nObjType = nObjType
	self.m_nConfID = nConfID
	self.m_nServerID = 0
	self.m_nSessionID = 0
	self.m_nCreateTime = os.time()

	self.m_nDupID = 0
	self.m_nSceneID = 0
	self.m_nNextSceneID = 0
	self.m_nPosX = 0
	self.m_nPosY = 0
	self.m_nLine = -1
	self.m_nFace = 0

	self.m_nLastDupID = 0
	self.m_nLastSceneID = 0
	self.m_nLastPosX= 0
	self.m_nLastPosY= 0
	self.m_nLastLine = -1
	self.m_nLastFace = 0

	self.m_bDirty = false
	self.m_bIsRelease = false
	self.m_oNativeObj = nil
end

function CObjectBase:SaveData() end
function CObjectBase:LoadData(tData) end
function CObjectBase:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CObjectBase:IsDirty() return self.m_bDirty end

function CObjectBase:Release()
	self.m_bIsRelease = true
	if self:IsSceneObj() then
		self:LeaveScene()
		oNativeRoleMgr:RemoveRole(self:GetObjID())
		self.m_oNativeObj = nil
	end
end

function CObjectBase:SendMsg(sCmd, tMsg, nServer, nSession)
    nServer = nServer or self:GetServer()
    nSession = nSession or self:GetSession()
    assert(nServer < GetGModule("ServerMgr"):GetWorldServerID(), "服务器ID错了")
    if nServer > 0 and nSession > 0 then
        Network.PBSrv2Clt(sCmd, nServer, nSession, tMsg)
    end
end

function CObjectBase:IsOnline() return self.m_nSessionID>0 end
function CObjectBase:IsRelease() return self.m_bIsRelease end
function CObjectBase:GetServer() return self.m_nServerID end
function CObjectBase:GetSession() return self.m_nSessionID end

function CObjectBase:GetObjID() return self.m_nObjID end
function CObjectBase:GetObjType() return self.m_nObjType end

function CObjectBase:GetObjConf() assert(false, "须子类实现") end
function CObjectBase:GetObjBaseData() assert(false, "须子类实现") end
function CObjectBase:GetObjShapeData() assert(false, "须子类实现") end

function CObjectBase:IsSceneObj() return self:GetObjConf().bSceneObj end
function CObjectBase:CheckSceneObj() assert(self:IsSceneObj(), "非场景对象") end
function CObjectBase:GetDupID()
	self:CheckSceneObj()
	return self.m_nDupID
end
function CObjectBase:GetDup()
	self:CheckSceneObj()
	return GetGModule("DupMgr"):GetDup(self.m_nDupID)
end
function CObjectBase:GetDupConf()
	self:CheckSceneObj()
	return self:GetDup():GetConf()
end
function CObjectBase:GetSceneID()
	self:CheckSceneObj()
	return self.m_nSceneID
end
function CObjectBase:GetScene()
	self:CheckSceneObj()
	return self:GetDup():GetScene(self:GetSceneID())
end
function CObjectBase:GetSceneConf()
	self:CheckSceneObj()
	return self:GetScene():GetConf()
end
function CObjectBase:GetAOIID()
	self:CheckSceneObj()
	return self.m_oNativeObj:GetAOIID()
end
function CObjectBase:GetNativeObj()
	self:CheckSceneObj()
	return self.m_oNativeObj
end
function CObjectBase:GetPos()
	self:CheckSceneObj()
	return self.m_oNativeObj:GetPos()
end
function CObjectBase:GetFace()
	self:CheckSceneObj()
	return self.m_oNativeObj:GetFace()
end
function CObjectBase:SetPos(nPosX, nPosY)
	self:CheckSceneObj()
	self.m_oNativeObj:SetPos()
end
function CObjectBase:StopRun()
	self:CheckSceneObj()
	self.m_oNativeObj:StopRun()
end
function CObjectBase:GetLine()
	self:CheckSceneObj()
	return self.m_oNativeObj:GetLine()
end
function CObjectBase:SetLine(nLine)
	self:CheckSceneObj()
	self.m_oNativeObj:SetLine(nLine)
end
function CObjectBase:GetFace()
	self:CheckSceneObj()
	return self.m_oNativeObj:GetFace()
end
function CObjectBase:GetNextSceneID()
	self:CheckSceneObj()
	return self.m_nNextSceneID
end
function CObjectBase:SetNextSceneID(nSceneID)
	self:CheckSceneObj()
	self.m_nNextSceneID = nSceneID
end
function CObjectBase:EnterScene(nDupID, nSceneID, nPosX, nPosY, nLine, nFace)
	self:CheckSceneObj()
	local oDup = GetGModule("DupMgr"):GetDup(nDupID)
	assert(oDup, "副本不存在:"..nDupID)
	oDup:EnterScene(nSceneID, self, nPosX, nPosY, nLine, nFace)
end
function CObjectBase:LeaveScene()
	self:CheckSceneObj()
	local oDup = GetGModule("DupMgr"):GetDup(self.m_nDupID)
	assert(oDup, "副本不存在:"..self.m_nDupID)
	oDup:LeaveScene(self)
end
function CObjectBase:OnEnterScene(oDup, oScene)
	self.m_nDupID = oDup:GetDupID()
	self.m_nSceneID = oScene:GetSceneID()
	self.m_nPosX, self.m_nPosY = self:GetPos()
	self.m_nLine = self:GetLine()
	self.m_nFace = self:GetFace()
end
function CObjectBase:OnLeaveScene(oDup, oScene, bKick)
	local nDupType = oDup:GetDupType()
	if nDupType == gtGDef.tDupType.eCity then
		self.m_nLastDupID = oDup:GetDupID()
		self.m_nLastSceneID = oDup:GetSceneID()
		self.m_nLastPosX, self.m_nLastPosY = self:GetPos()
		self.m_nLastLine = self:GetLine()
		self.m_nLastFace = self:GetFace()
	end
end
function CObjectBase:OnObjEnterView(tObserved)
end
function CObjectBase:OnObjLeaveView(tObserved)
end
function CObjectBase:OnObjReachTargetPos(nPosX, nPosY)
end
