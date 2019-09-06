--游戏角色
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRole:Ctor()
	CObjectBase.Ctor(self, 0, gtGDef.tObjType.eRole, 0)
	self.m_nSource = 0
	self.m_sChannel = ""
	self.m_nAccountID = 0
	self.m_sAccountName = ""
	self.m_sRoleName = ""
	self.m_tCurrencyMap = {}
	self.m_tCurrencyCache = {}

	
	self.m_nOnlineTime = 0
	self.m_nDisconnectTime = 0
	self.m_nOfflineTime = 0

	self.m_tModuleMap = {}
	self.m_tModuleList = {}
	self:InitModule()
	self:LoadData()
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
	local tData = {}
	CObjectBase.LoadData(self, tData)
end

function CRole:SaveSelfData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	local tData = CObjectBase.SaveData(self)
end

function CRole:LoadModuleData()
end

function CRole:SaveModuleData()
end

function CRole:GetSource() return self.m_nSource end
function CRole:GetChannel() return self.m_sChannel end
function CRole:GetObjName() return self.m_sRoleName end
function CRole:GetObjConf() return ctRoleConf[self.m_nConfID] end
function CRole:GetAccountID() return self.m_nAccountID end
function CRole:GetAccountName() return self.m_sAccountName end
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
	tMsg.nObjID = self:GetObjID()
	tMsg.nObjType = self:GetObjType()
	tMsg.tBaseData = self:GetObjBaseData()
	tMsg.tShapeData = self:GetObjShapeData()
    self:SendMsg("ObjEnterSceneRet", tMsg)
end

--同步角色初始数据
function CRole:SyncInitData()
	local tData = {
		nSource = self:GetSource(),
		sChannel = self:GetChannel(),
		nServerID = self:GetServerID(),
		nAccountID = self:GetAccountID(),
		sAccountName = self:GetAccountName(),
		nRoleID = self:GetObjID(),
		sRoleName = self:GetObjName(),
		nLevel = self:GetLevel(),
	}
	self:SendMsg("RoleInitDataRet", tData)
end

function CRole:Online(bReconnect)
	self.m_nOnlineTime = os.time()
	self:MarkDirty(true)
	for _, oModule in ipairs(self.m_tModuleList) do
		oModule:Online(bReconnect)
	end
	self:SyncInitData()
end

function CRole:OnDisconnect()
	self.m_nDisconnectTime = os.time()
	self:MarkDirty(true)
	for _, oModule in ipairs(self.m_tModuleList) do
		oModule:OnDisconnect()
	end
end

function CRole:Offline()
	self.m_nOfflineTime = os.time()
	self:MarkDirty(true)
	for _, oModule in ipairs(self.m_tModuleList) do
		oModule:Offline()
	end
end

--同步数据到登录服
function CRole:SyncSimpleRole()
	local tData = {
		m_nID = self:GetObjID(),
		m_nConfID = self:GetObjConf().nID,
		m_sName = self:GetObjName(),
		m_nLevel = self:GetLevel(),
		m_tCurrSceneInfo = self:GetCurrSceneInfo(),
		m_tLastSceneInfo = self:GetLastSceneInfo(),
	}
	local nServiceID = GetGModule("ServerMgr"):GetGlobalService(self:GetServerID())
	Network:RMCall("UpdateSimpleRoleReq", nil, self:GetServerID(), nServiceID, self:GetSessionID(), tData)
end

function CRole:ForceFinishBattle()
end
