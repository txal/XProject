--游戏角色
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRole:Ctor()
	self.m_nAccountID = 0
	self.m_nOnlineTime = 0
	self.m_nDisconnectTime = 0

	self.m_tModuleMap = {}
	self.m_tModuleList = {}
	self:InitModule()
	self:LoadData()
	CObjectBase.Ctor(self, self.m_nObjID, gtGDef.tObjType.eRole, self.m_nConfID)
end

function CRole:InitModule()
end

function CRole:LoadData()
	self:LoadSelfData()
	self:LoadModuleData()
end

function CRole:SaveData()
	self:SaveSelfData()
	self:SaveModuleData()
end

function CRole:LoadSelfData()
end

function CRole:SaveSelfData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
end

function CRole:LoadModuleData()
end

function CRole:SaveModuleData()
end

function CRole:GetObjConf() return ctRoleConf[self.m_nConfID] end
function CRole:GetAccountID() return self.m_nAccountID end
function CRole:GetOnlineTime() return self.m_nOnlineTime end
function CRole:GetDisconnectTime() return self.m_nDisconnectTime end

function CRole:BindServer(nServerID)
	self.m_nServerID = nServerID
	self.m_oNativeObj:BindServer(nServerID)
end

function CRole:BindSession(nSessionID)
	self.m_nSessionID = nSessionID
	self.m_oNativeObj:BindSession(nSessionID)
end

--生成切换逻辑服数据
function CRole:MakeSwitchLogicData(nTarDupID, nTarDupConfID, nTarSceneID, nTarSceneConfID, nTarPosX, nTarPosY, nTarLine, nTarFace)
	local tSwitchData =
	{
		nRoleID = self:GetObjID(),
		nServer = self:GetServer(),
		nSession = self:GetSession(),
		nSrcLine = self:GetLine(),
		nSrcFace = self:GetFace(),
		nSrcDupConfID = self:GetDupConf().nID,
		nSrcSceneConfID = self:GetSceneConf().nID,

		nTarDupID = nTarDupID,
		nTarDupConfID = nTarDupConfID,
		nTarSceneID = nTarSceneID,
		nTarSceneConfID = nTarSceneConfID,
		nTarPosX = nTarPosX,
		nTarPosY = nTarPosY,
		nTarLine = nTarLine,
		nTarFace = nTarFace,
	}
	return tSwitchData
end

function CRole:GetObjBaseData()
	local tBaseData = {}
	return tBaseData
end

function CRole:GetObjShapeData()
	local tShapeData = {}
	return tShapeData
end

function CRole:OnEnterScene(oDup, oScene)
	CObjectBase.OnEnterScene(self, oDup, oScene)

	local tMsg = {}
	tMsg.nDupID = self:GetDupID()
	tMsg.nSceneID = self:GetSceneID()
	tMsg.nDupConfID = self:GetDupConf().nID
	tMsg.nSceneConfID = self:GetSceneConf().nID
	tMsg.nObjID = self:GetObjID()
	tMsg.nObjType = self:GetObjType()
	tMsg.tBaseData = self:GetObjBaseData()
	tMsg.tShapeData = self:GetObjShapeData()
    self:SendMsg("ObjEnterSceneRet", tMsg)
end
