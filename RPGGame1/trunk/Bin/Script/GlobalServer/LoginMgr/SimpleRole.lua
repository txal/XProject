--简单角色信息
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CSimpleRole:Ctor(nID, nLevel, sName, tCurrSceneInfo, tLastSceneInfo)
	self.m_nID = nID
	self.m_nConfID = nConfID
	self.m_sName = sName
	self.m_nLevel = nLevel
	self.m_nCreateTime = os.time()
	self.m_tCurrSceneInfo = tCurrSceneInfo
	self.m_tLastSceneInfo = tLastSceneInfo
end

function CSimpleRole:LoadData(tData)
	self.m_nID = tData.m_nID
	self.m_nConfID = tData.m_nConfID
	self.m_sName = tData.m_sName
	self.m_nLevel = tData.m_nLevel
	self.m_nCreateTime = tData.m_nCreateTime
	self.m_tLastSceneInfo = tData.m_tLastSceneInfo
	self.m_tCurrSceneInfo = tData.m_tCurrSceneInfo
end

function CSimpleRole:SaveData()
	tData.m_nID = self.m_nID
	tData.m_nConfID = self.m_nConfID
	tData.m_sName = self.m_sName
	tData.m_nLevel = self.m_nLevel
	tData.m_nCreateTime = self.m_nCreateTime
	tData.m_tLastSceneInfo = self.m_tLastSceneInfo
	tData.m_tCurrSceneInfo = self.m_tCurrSceneInfo
	return tData
end

function CSimpleRole:GetID() return self.m_nID end
function CSimpleRole:GetName() return self.m_sName end
function CSimpleRole:GetLevel() return self.m_nLevel end
function CSimpleRole:GetCreateTime() return self.m_nCreateTime end
function CSimpleRole:GetLastSceneInfo() return self.m_tLastSceneInfo end
function CSimpleRole:GetCurrSceneInfo() return self.m_tCurrSceneInfo end
function CSimpleRole:GetRoleConf() ctRoleConf[self.m_nConfID] end

function CSimpleRole:SetName(sName) self.m_sName = sName end
function CSimpleRole:SetLevel(nLevel) self.m_nLevel = nLevel end
function CSimpleRole:SetLastSceneInfo(tSceneInfo) self.m_tLastSceneInfo = tSceneInfo end
function CSimpleRole:SetCurrSceneInfo(tSceneInfo) self.m_tCurrSceneInfo = tSceneInfo end

function CSimpleRole:GetLogicServiceID()
	local tCurrSceneInfo = self:GetCurrSceneInfo()
	local tLastSceneInfo = self:GetLastSceneInfo()
	if tCurrSceneInfo then
		local tDupConf = ctDupConf[tCurrSceneInfo.nDupConfID]
		if tDupConf then
			return tDupConf.nLogicServiceID
		end
		local tDupConf = ctDupConf[tLastSceneInfo.nDupConfID]
		if tDupConf then
			return tDupConf.nLogicServiceID
		end
	end
	return 0
end

function CSimpleRole:GetCurrSceneType()
	local tCurrSceneInfo = self:GetCurrSceneInfo()
	if tCurrSceneInfo  then
		local nDupConfID = CUtil:GetDupConfID(tCurrSceneInfo.nDupID)
		local tDupConf = ctDupConf[nDupConfID]
		if tDupConf then
			return tDupConf.nDupType
		end
	end
	return 0
end

function CSimpleRole:UpdateData(tData)
	for key, val in pairs(tData) do
		assert(type(key) ~= "table", "数据错误")
		self[key] = val
	end
end