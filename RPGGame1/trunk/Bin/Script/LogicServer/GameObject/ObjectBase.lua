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
	self.m_bIsReleased = false
	self.m_oNativeObj = nil
end

function CObjectBase:SaveData() end
function CObjectBase:LoadData(tData) end
function CObjectBase:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CObjectBase:IsDirty() return self.m_bDirty end

function CObjectBase:Release()
	self.m_bIsReleased = true
	if self:IsSceneObj() then
		self:LeaveScene()
		oNativeRoleMgr:RemoveRole(self:GetObjID())
		self.m_oNativeObj = nil
	end
end

--发送消息
function CObjectBase:SendMsg(sCmd, tMsg, nServerID, nSessionID)
    nServerID = nServerID or self:GetServerID()
    nSessionID = nSessionID or self:GetSessionID()
    if nServerID <= 0 or nSessionID <= 0 then
    	return
    end
    assert(nServerID < GetGModule("ServerMgr"):GetWorldServerID(), "服务器ID错了")
    Network.PBSrv2Clt(sCmd, nServerID, nSessionID, tMsg)
end

--飘字通知
function CObjectBase:Tips(sCont, nServerID, nSessionID)
    self:SendMsg("TipsMsgRet", {sCont=sCont}, nServerID, nSessionID)
end

function CObjectBase:IsOnline() return self.m_nSessionID>0 end
function CObjectBase:IsReleased() return self.m_bIsReleased end
function CObjectBase:GetServerID() return self.m_nServerID end
function CObjectBase:GetSessionID() return self.m_nSessionID end

function CObjectBase:GetObjID() return self.m_nObjID end
function CObjectBase:GetObjType() return self.m_nObjType end

function CObjectBase:GetObjName() assert(false, "须子类实现") end
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
	return self:GetDup():GetDupConf()
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
	return self:GetScene():GetSceneConf()
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
--@tDupInfo 目标场景信息 {nDupID=0,nDupConfID=0,nSceneID=0,nSceneConfID=0,nPosX=0,nPosY=0,nLine=0,nFace=0}
function CObjectBase:EnterScene(tDupInfo)
	self:CheckSceneObj()
	GetGModule("DupMgr"):EnterDup(self, tDupInfo)
end
function CObjectBase:LeaveScene()
	self:CheckSceneObj()
	GetGModule("DupMgr"):LeaveDup(self)
end
function CObjectBase:OnEnterScene(oDup, oScene)
	self.m_nDupID = oDup:GetDupID()
	self.m_nSceneID = oScene:GetSceneID()
	self.m_nPosX, self.m_nPosY = self:GetPos()
	self.m_nLine = self:GetLine()
	self.m_nFace = self:GetFace()
end
function CObjectBase:OnLeaveScene(oDup, oScene, bSceneReleasedKick)
	local nDupType = oDup:GetDupType()
	if nDupType == gtGDef.tDupType.eCity then
		self.m_nLastDupID = oDup:GetDupID()
		self.m_nLastSceneID = oDup:GetSceneID()
		self.m_nLastPosX, self.m_nLastPosY = self:GetPos()
		self.m_nLastLine = self:GetLine()
		self.m_nLastFace = self:GetFace()
	end

	--如果是场景释放移出场景,则进入最后的城镇场景
	if bSceneReleasedKick then
	end
end
function CObjectBase:OnLeaveDup(oDup)
    print("对象离开整个副本", self:GetObjName())
end
function CObjectBase:OnObjEnterView(tObserved)
end
function CObjectBase:OnObjLeaveView(tObserved)
end
function CObjectBase:OnObjReachTargetPos(nPosX, nPosY)
end

--是否可以切换逻辑服的对象类型
function CObjectBase:IsSwitchLogicObjType()
	if not self:IsSceneObj() then
		return false
	end
    local nObjType = oGameLuaObj:GetObjType()
    return (nObjType == gtGDef.tObjType.eRole or nObjType == gtGDef.tObjType.eRobot or nObjType == gtGDef.tObjType.ePet)
end

--取进入/离开场景前检测需要的参数
function CObjectBase:GetSceneEnterLeaveCheckParams()
	local tCheckParams =
	{
		nObjID = self:GetObjID(),
		nObjType = self:GetObjType(),
	}
end

--生成切换逻辑服数据
--@tDupInfo {nDupID=0, nDupConfID=0, nSceneID=0 ,nSceneConfID=0 ,nPosX=0 ,nPosY=0 ,nLine=0 ,nFace=0}
function CObjectBase:MakeSwitchLogicData(tDupInfo)
	self:CheckSceneObj()
    local tDupConf = assert(ctDupConf[tDupInfo.nDupConfID], "副本配置不存在:"..tDupInfo.nDupConfID)
    local nTarServiceID = tDupConf.nLogicServiceID
    local nTarServerID = CUtil:GetServerByLogic(nTarServiceID)

	local tSwitchData =
	{
		nObjID = self:GetObjID(),
		nObjType = self:GetObjType(),
		nSessionID = self:GetSessionID(),
		nServerID = self:GetServerID(),

		nSrcServiceID = CUtil:GetServiceID(),
		nSrcDupConfID = self:GetDupConf().nID,
		nSrcSceneConfID = self:GetSceneConf().nID,
		nSrcLine = self:GetLine(),
		nSrcFace = self:GetFace(),

		nTarServerID = nTarServerID,
		nTarServiceID = nTarServiceID,
		nTarDupID = tDupInfo.nDupID,
		nTarDupConfID = tDupInfo.nDupConfID,
		nTarSceneID = tDupInfo.nSceneID,
		nTarSceneConfID = tDupInfo.nSceneConfID,
		nTarPosX = tDupInfo.nPosX,
		nTarPosY = tDupInfo.nPosY,
		nTarLine = tDupInfo.nLine,
		nTarFace = tDupInfo.nFace,
	}
	return tSwitchData
end
