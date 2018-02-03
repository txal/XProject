local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--账号模块

local nAutoSaveTime = 5*60 --自动保存时间
function CAccount:Ctor(nServer, nSource, nID, sName)
	self.m_nSaveTick = nil
	self.m_bDirty = false

	self.m_nID = nID
	self.m_sName = sName
	self.m_nSource = nSource
	self.m_nServer = nServer

	self.m_tRoleSummaryMap = {} 	--角色摘要信息
	self.m_nLastRoleID = 0 			--上次登录的角色ID
	self.m_oOnlineRole = nil 		--在线角色对象(同时只允许一个角色在线)
end

function CAccount:IsDirty()
	return self.m_bDirty
end

function CAccount:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CAccount:LoadData()
	--fix pd
end

function CAccount:SaveData()
	self.m_oOnlineRole:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	--fix pd
end

function CAccount:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil

	if self.m_oOnlineRole then
		self.m_oOnlineRole:OnRelease()
		self.m_oOnlineRole = nil
	end
end

function CAccount:RegAutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CAccount:GetID()
	return self.m_nID
end

function CAccount:GetName()
	return self.m_sName
end

function CAccount:GetSource()
	return self.m_nScoure
end

function CAccount:GetServer()
	return self.m_nServer
end

function CAccount:GetOnlineRole()
	return self.m_oOnlineRole
end

function CAccount:Online()
	if not self.m_oOnlineRole then
		return
	end
	self:RegAutoSave()
	self.m_oOnlineRole:Online()
	self.m_nLastRoleID = self.m_oOnlineRole:GetID()
	self:MarkDirty(true)
end

function CAccount:Offline()
	if not self.m_oOnlineRole then
		return
	end
	self.m_oOnlineRole:Offline()
	self:UpdateSummary()
	self.m_oOnlineRole = nil
end

function CAccount:UpdateSummary()
	if not self.m_oOnlineRole then
		return
	end
	--fix pd
end

function CAccount:CreateRole()
end

function CAccount:DeleteRole()
end