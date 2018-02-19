--帐号(玩家)管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPlayerMgr:Ctor()
	self.m_tAccountIDMap = {}		--账号ID影射: {[accountid]=account, ...}
	self.m_tAccountSSMap = {} 		--SS(server<<32|session)映射: {[mixid]=account, ...}
end

function CPlayerMgr:GetAccountIDMap()
	return self.m_tAccountIDMap
end

function CPlayerMgr:GetAccountSSMap()
	return self.m_tAccountSSMap
end

function CPlayerMgr:MakeSSKey(nServer, nSession)
	local nSSKey = nServer << 32 | nSession
	return nSSKey
end

--通过账号ID取在线账号对象
function CPlayerMgr:GetAccountByID(nAccountID)
	return self.m_tAccountIDMap[nAccountID]
end

--通过账号ID取在线角色对象
function CPlayerMgr:GetRoleByAccountID(nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if oAccount then
		return oAccount:GetOnlineRole()
	end
end

--通过SSKey取在线账号对象
function CPlayerMgr:GetAccountBySS(nServer, nSession)
	local nSSKey = self:MakeSSKey(nServer, nSession)
	return self.m_tAccountSSMap[nSSKey]
end

--通过SSKey取在线角色对象
function CPlayerMgr:GetRoleBySS(nServer, nSession)
	local oAccount = self:GetAccountBySS(nServer, nServer)
	if oAccount then
		return oAccount:GetOnlineRole()
	end
end

--更新玩家摘要信息请求
function CPlayerMgr:UpdateRoleSummaryReq(nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return
	end
	oAccount:UpdateRoleSummary()
	return nAccountID
end

--玩家登陆成功请求
function CPlayerMgr:OnlineReq(nServer, nSession, nAccountID, nRoleID)
	assert(nServer < 10000, "源服务器不会是世界服")
	local oAccount = self:GetAccountByID(nAccountID)
	assert(not oAccount, "帐号已在线")

	local oAccount = CAccount:new(nServer, nSession, nAccountID)
	if not oAccount:LoadData() then
		return CRole:Tips("帐号不存在", nServer, nSession)
	end
	if oAccount:Online(nRoleID) then
		local oRole = oAccount:GetOnlineRole()
		goLogger:EventLog(gtEvent.eLogin, oRole, oRole:GetOnlineTime()-oRole:GetOfflineTime())
		return nAccountID
	end
end

--玩家离线成功请求
function CPlayerMgr:OfflineReq(nAccountID)
	local oAccount = self:GetAccountByID(nAccountID)
	if not oAccount then
		return
	end

	--日志
	local oRole = oAccount:GetOnlineRole()
	goLogger:EventLog(gtEvent.eLogout, oRole, oRole:GetOfflineTime()-oRole:GetOnlineTime())

	--下线处理
	oAccount:Offline()
	oAccount:OnRelease()
	self.m_tAccountIDMap[nAccountID] = nil
	return nAccountID
end


goPlayerMgr = goPlayerMgr or CPlayerMgr:new()
goCppPlayerMgr = GlobalExport.GetPlayerMgr()

