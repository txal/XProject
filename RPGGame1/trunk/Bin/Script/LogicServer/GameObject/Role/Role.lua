--游戏角色
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRole:Ctor()
	CObjectBase.Ctor(self, 0, gtGDef.tObjType.eRole, 0)

	self.m_nAccountID = 0
	self.m_nOnlineTime = 0
	self.m_nDisconnectTime = 0
	self.m_sRoleName = ""
	self.m_tCurrencyMap = {}
	self.m_tCurrencyCache = {}

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

function CRole:GetObjName() return self.m_sRoleName end
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

--取货币值
function CRole:GetCurrency()
	return (self.m_tCurrencyMap[nCurrType] or 0)
end

--添加货币
function CRole:AddCurrency(nCurrType, nAddValue, bNotSync)
	if nAddValue == 0 then
		return
	end
	local nOldValue = self:GetCurrency()
	
	self.m_tCurrencyMap[nCurrType] = math.max(0, math.min(gtGDef.tConst.nMaxInteger, nOldValue+nAddValue))
	self:MarkDirty(true)

	local nRealAddValue = self:GetCurrency(nCurrType) - nOldValue
	if nRealAddValue == 0 then
		return
	end

	if bNotSync then
		self.m_tCurrencyCache[nCurrType] = 1
	else
		self:SyncCurrency({{nType=nCurrType, nValue=self:GetCurrency(nCurrType)}})
	end
end

--同步货币
function CRole:SyncCurrency(tCurrList)
	if not tCurrList then
		tCurrList = {}
		for nCurrType, _ in pairs(self.m_tCurrencyCache) do
			table.insert({nType=nCurrType, nValue=self:GetCurrency(nCurrType)})
		end
	end
	if #tCurrList > 0 then
		Network.PBSrv2Clt("CurrencySyncRet", {tList=tCurrList})
	end
end