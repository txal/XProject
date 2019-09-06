--游戏对象基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local oNativeRoleMgr = GlobalExport.GetRoleMgr()

function CObjectBase:Ctor(nObjID, nObjType, nConfID)
	assert(nObjID and nObjType and nConfID, "参数错误")
	self.m_nObjID = nObjID
	self.m_nConfID = nConfID
	self.m_nObjType = nObjType
	self.m_nCreateTime = os.time()
	self.m_tCurrSceneInfo = {nDupID=0, nSceneID=0, nPosX=0, nPosY=0, nLine=-1, nFace=0}
	self.m_tLastSceneInfo = {nDupID=0, nSceneID=0, nPosX=0, nPosY=0, nLine=-1, nFace=0}
	self.m_nLevel = 0

	--不保存
	self.m_nServerID = 0
	self.m_nSessionID = 0
	self.m_nNextSceneID = 0
	self.m_bReleased = false
	self.m_oNativeObj = nil
	self.m_bDirty = false
end

function CObjectBase:SaveData() end
function CObjectBase:LoadData(tData) end
function CObjectBase:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CObjectBase:IsDirty() return self.m_bDirty end

function CObjectBase:Release()
	self.m_bReleased = true
	if self:IsSceneObj() then
		self:LeaveScene()
		oNativeRoleMgr:RemoveRole(self:GetObjID())
		self.m_oNativeObj = nil
	end
end

--发送消息次客户端
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
	if sCont == "" then
		return
	end
    self:SendMsg("FloatTipsRet", {sCont=sCont}, nServerID, nSessionID)
end

--道具不足通知
--@tPropList 道具ID列表
function CObjectBase:PropTips(tPropList)
	if not tPropList or #tPropList <= 0 then
		return
	end
	self:SendMsg("PropTipsRet", {tList=tPropList})
end

function CObjectBase:IsOnline() return self.m_nSessionID>0 end
function CObjectBase:IsReleased() return self.m_bReleased end
function CObjectBase:GetServerID() return self.m_nServerID end
function CObjectBase:GetSessionID() return self.m_nSessionID end

function CObjectBase:Online(bDisconnect) end
function CObjectBase:OnDisconnect() end
function CObjectBase:Offline() end

function CObjectBase:GetObjID() return self.m_nObjID end
function CObjectBase:GetObjType() return self.m_nObjType end
function CObjectBase:GetObjName() assert(false, "须子类实现") end
function CObjectBase:GetObjConf() assert(false, "须子类实现") end
function CObjectBase:GetObjBaseData() assert(false, "须子类实现") end
function CObjectBase:GetObjShapeData() assert(false, "须子类实现") end
function CObjectBase:GetLevel() return self.m_nLevel end

function CObjectBase:IsSceneObj() return self:GetObjConf().bSceneObj end
function CObjectBase:CheckSceneObj() assert(self:IsSceneObj(), "非场景对象") end
function CObjectBase:GetCurrSceneInfo() return self.m_tCurrSceneInfo end
function CObjectBase:GetLastSceneInfo() return self.m_tLastSceneInfo end
function CObjectBase:GetDupID()
	self:CheckSceneObj()
	return self.m_tCurrSceneInfo.nDupID
end
function CObjectBase:GetDupObj()
	self:CheckSceneObj()
	return GetGModule("DupMgr"):GetDup(self:GetDupID())
end
function CObjectBase:GetDupConf()
	self:CheckSceneObj()
	return self:GetDup():GetDupConf()
end
function CObjectBase:GetSceneID()
	self:CheckSceneObj()
	return self.m_tCurrSceneInfo.nSceneID
end
function CObjectBase:GetSceneObj()
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
	self.m_oNativeObj:SetPos(nPosX, nPosY)
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
--@tSceneInfo 目标场景信息 {nDupID=0,nSceneID=0,nPosX=0,nPosY=0,nLine=0,nFace=0}
function CObjectBase:EnterScene(tSceneInfo)
	self:CheckSceneObj()
	GetGModule("DupMgr"):EnterScene(self, tSceneInfo)
end
function CObjectBase:LeaveScene()
	self:CheckSceneObj()
	GetGModule("DupMgr"):LeaveScene(self)
end
--进入场景事件
function CObjectBase:OnEnterScene(oDup, oScene)
	local nPosX, nPosY = self:GetPos()
	self.m_tCurrSceneInfo = {
		nDupID = oDup:GetDupID(),
		nSceneID = oScene:GetSceneID(),
		nPosX = nPosX,
		nPosY = nPosY,
		nLine = self:GetLine(),
		nFace = sef:GetFace(),
	}
	self:MarkDirty(true)
end
--离开场景事件
function CObjectBase:OnLeaveScene(oDup, oScene, bSceneReleasedKick)
	local nDupType = oDup:GetDupType()
	if nDupType == gtGDef.tDupType.eCity then
		local nPosX, nPosY = self:GetPos()
		self.m_tLastSceneInfo = {
			nDupID = oDup:GetDupID(),
			nSceneID = oScene:GetSceneID(),
			nPosX = nPosX,
			nPosY = nPosY,
			nLine = self:GetLine(),
			nFace = sef:GetFace(),
		}
		self:MarkDirty(true)
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

--更新当前场景信息
function CObjectBase:UpdateCurrSceneInfo()
	self.m_tCurrSceneInfo.nPosX, self.m_tCurrSceneInfo.nPosY = self:GetPos()
	self.m_tCurrSceneInfo.nLine = self:GetLine()
	self.m_tCurrSceneInfo.nFace = self:GetFace()
	self:MarkDirty(true)
end

--是否可以切换逻辑服的对象类型
function CObjectBase:IsSwitchLogicObjType()
	if not self:IsSceneObj() then
		return false
	end
    local nObjType = oGameLuaObj:GetObjType()
    return (nObjType == gtGDef.tObjType.eRole or nObjType == gtGDef.tObjType.eRobot or nObjType == gtGDef.tObjType.ePet)
end

--取进入场景前检测需要的参数
function CObjectBase:GetSceneEnterCheckParams()
	local tCheckParams = {
		nObjID = self:GetObjID(),
		nObjType = self:GetObjType(),
	}
	return tCheckParams
end

--生成切换逻辑服数据
--@tSceneInfo 目标场景 {nDupID=0, nSceneID=0 ,nPosX=0 ,nPosY=0 ,nLine=0 ,nFace=0}
function CObjectBase:MakeSwitchLogicData(tSceneInfo)
	self:CheckSceneObj()
	local nDupConfID = CUtil:GetDupConfID(tSceneInfo.nDupID)
    local tDupConf = assert(ctDupConf[nDupConfID], string.format("副本配置不存在: %d", nDupConfID))
    local nTarServiceID = tDupConf.nLogicServiceID
    local nTarServerID = CUtil:GetServerByLogic(nTarServiceID)
    self:UpdateCurrSceneInfo()
	local tSwitchData = {
		nObjID = self:GetObjID(),
		nObjType = self:GetObjType(),
		nServerID = self:GetServerID(),
		nSessionID = self:GetSessionID(),
		nSrcServiceID = CUtil:GetServiceID(),
		tSrcSceneInfo = self.m_tCurrSceneInfo,
		
		nTarServerID = nTarServerID,
		nTarServiceID = nTarServiceID,
		tTarSceneInfo = tSceneInfo,
	}
	return tSwitchData
end
