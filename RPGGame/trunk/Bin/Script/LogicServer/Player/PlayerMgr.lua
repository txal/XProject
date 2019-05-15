--玩家(角色)管理模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPlayerMgr:Ctor()
	self.m_tRoleIDMap = {}		--角色ID影射: {[roleid]=role, ...}
	self.m_tRoleSSMap = {} 		--SS(server<<32|session)映射: {[mixid]=role, ...}
	self.m_nCount = 0

	self.m_nMinTimer = nil
	self.m_nHourTimer = nil
	self:RegMinTimer()
	self:RegHourTimer()
end

function CPlayerMgr:OnRelease()
	goTimerMgr:Clear(self.m_nMinTimer)
	goTimerMgr:Clear(self.m_nHourTimer)
end

--注册整分计时器
function CPlayerMgr:RegMinTimer()
    goTimerMgr:Clear(self.m_nMinTimer)
    self.m_nMinTimer = goTimerMgr:Interval(os.NextMinTime(os.time()), function() self:OnMinTimer() end)
end

--注册整点计时器
function CPlayerMgr:RegHourTimer()
    goTimerMgr:Clear(self.m_nHourTimer)
    self.m_nHourTimer = goTimerMgr:Interval(os.NextHourTime(os.time()), function() self:OnHourTimer() end)
end

function CPlayerMgr:OnMinTimer()
	self:RegMinTimer()
	for nRoleID, oRole in pairs(self.m_tRoleIDMap) do
		oRole:OnMinTimer()
	end
end

function CPlayerMgr:OnHourTimer()
	self:RegHourTimer()
	for nRoleID, oRole in pairs(self.m_tRoleIDMap) do
		oRole:OnHourTimer()
	end
end

function CPlayerMgr:GetCount()
	return self.m_nCount
end

function CPlayerMgr:GetRoleIDMap()
	return self.m_tRoleIDMap
end

function CPlayerMgr:GetRoleSSMap()
	return self.m_tRoleSSMap
end

function CPlayerMgr:MakeSSKey(nServer, nSession)
	local nSSKey = nServer << 32 | nSession
	return nSSKey
end

--通过角色ID取在线角色对象
function CPlayerMgr:GetRoleByID(nRoleID)
	return self.m_tRoleIDMap[nRoleID]
end

--通过SSKey取在线角色对象
function CPlayerMgr:GetRoleBySS(nServer, nSession)
	local nSSKey = self:MakeSSKey(nServer, nSession)
	return self.m_tRoleSSMap[nSSKey]
end

--角色登陆成功请求
--@nServer: 角色所属的服务器
--@nSession: 角色的会话ID
function CPlayerMgr:RoleOnlineReq(nServer, nSession, nRoleID, bSwitchLogic)
	print("CPlayerMgr:RoleOnlineReq***", nServer, nRoleID, bSwitchLogic)
	assert(nServer < gnWorldServerID, "角色所属服务器不能是世界服!")
	local oRole = self:GetRoleByID(nRoleID)
	if oRole and oRole:GetSession() > 0 then
		return LuaTrace("角色已在线", oRole:GetID(), oRole:GetName())
	end

	local bReconnect = false
	if not oRole then
		oRole = CRole:new(nServer, nRoleID)
		self.m_nCount = self.m_nCount + 1
	else
		bReconnect = true
		assert(oRole:GetID() == nRoleID, "角色错误")
		assert(oRole:GetServer() == nServer, "服务器错误")
		assert(oRole:GetSession() == 0, "会话ID错误")
		if oRole:GetAOIID() <= 0 and not oRole:IsInBattle() then --不在场景和战斗中,出错了
			bReconnect = false
			LuaTrace("角色数据错误(重连不在场景,也不在战斗中)", nRoleID, oRole:GetName())
		end
	end
	oRole:BindSession(nSession)
	self.m_tRoleIDMap[nRoleID] = oRole
	--可能队长带队,队员不在线,所以nSession>0时才放到表里面
	if nSession > 0 then
		local nSSKey = self:MakeSSKey(nServer, nSession)
		self.m_tRoleSSMap[nSSKey] = oRole
	end
	oRole:OnEnterLogic()
	--切换逻辑服不调用Online
	if not bSwitchLogic then
		oRole:Online(bReconnect)

		goLogger:EventLog(gtEvent.eOnline, oRole, oRole:GetOnlineTime()-oRole:GetOfflineTime())
		goLogger:UpdateRoleLog(oRole, {logintime=os.time(),online=1})
	end
end

function CPlayerMgr:CreateRobotReq(nServer, nRobotID, nSrcID, nRobotType, nDupMixID, tParam, tSaveData, bSwitchLogic)
	assert(nServer < gnWorldServerID, "角色所属服务器不能是世界服!")
	assert(nServer > 0, "角色所属服务器ID错误")
	if goLRobotMgr:IsServerClosing() then 
		return 
	end
	local oTempRobot = self:GetRoleByID(nRobotID)
	if oTempRobot then
		LuaTrace("机器人已存在", oTempRobot:GetID(), oTempRobot:GetName())
		return
	end
	--检查nDupMixID是否在当前逻辑服，如果在，检查是否存在此场景
	if not bSwitchLogic then 
		local nDupID = GF.GetDupID(nDupMixID)
		local tDupConf = ctDupConf[nDupID]
		if not tDupConf then
			return 
		end
		if GF.GetServiceID() == tDupConf.nLogic then 
			if not goDupMgr:GetDup(nDupMixID) then 
				LuaTrace("场景不存在，创建机器人失败")
				return 
			end
		end
	end
	local oRobot = CRobot:new(nServer, nRobotID, nSrcID, nRobotType, nDupMixID, tParam, tSaveData)
	if not oRobot then 
		return
	end
	self.m_tRoleIDMap[oRobot:GetID()] = oRobot
	oRobot:OnEnterLogic()
	if not bSwitchLogic then 
		oRobot:Online()
	else
		oRobot:SetOnline(true)
	end
	return oRobot:GetID()
end

--角色离线请求(清数据)
function CPlayerMgr:RoleOfflineReq(nRoleID, bSwitchLogic)
	print("CPlayerMgr:RoleOfflineReq***", nRoleID, bSwitchLogic)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole then
		if not GF.IsRobot(nRoleID) then 
			LuaTrace("CPlayerMgr:RoleOfflineReq 角色未登录:", nRoleID)
		end
		return 0
	end

	local function _ReleaseRole()
		oRole:OnRelease()
		local nServer = oRole:GetServer()
		local nSession = oRole:GetSession()
		local nSSKey = self:MakeSSKey(nServer, nSession)
		self.m_tRoleIDMap[nRoleID] = nil
		self.m_tRoleSSMap[nSSKey] = nil
		self.m_nCount = self.m_nCount - 1
	end

	--释放处理
	if not bSwitchLogic then
		if oRole:IsOnline() then --在线先下线
			self:RoleDisconnectReq(nRoleID)
		end
		if oRole:Offline() then
			_ReleaseRole()
			if not oRole:IsRobot() then
				goLogger:EventLog(gtEvent.eRoleRelease, oRole)		
			end
		end
	else
		_ReleaseRole()
	end

	return oRole:GetAccountID()
end

--角色断线请求(保留数据)
function CPlayerMgr:RoleDisconnectReq(nRoleID)
	print("CPlayerMgr:RoleDisconnectReq***", nRoleID)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole or not oRole:IsOnline() then
		LuaTrace("角色未登录:", nRoleID)
		return (oRole and oRole:GetAccountID() or 0)
	end

	--断线
	local nServer = oRole:GetServer()
	local nSession = oRole:GetSession()
	local nSSKey = self:MakeSSKey(nServer, nSession)
	self.m_tRoleSSMap[nSSKey] = nil
	oRole:OnDisconnect()

	--日志
	if not oRole:IsRobot() then
		goLogger:EventLog(gtEvent.eOffline, oRole, oRole:GetOfflineTime()-oRole:GetOnlineTime())
		goLogger:UpdateRoleLog(oRole, {online=0})
	end
	return oRole:GetAccountID()
end

--切换逻辑服请求
function CPlayerMgr:OnSwitchLogicReq(tSwitch)
	local nSrcDupID = GF.GetDupID(tSwitch.nSrcDupMixID)
	local nTarDupID = GF.GetDupID(tSwitch.nTarDupMixID)
    print("切换逻辑服:", nSrcDupID.."->"..nTarDupID, tSwitch)

    self:RoleOnlineReq(tSwitch.nServer, tSwitch.nSession, tSwitch.nRoleID, true)
    local oRole = self:GetRoleByID(tSwitch.nRoleID)
    goDupMgr:EnterDup(tSwitch.nTarDupMixID, oRole:GetNativeObj(), tSwitch.nPosX, tSwitch.nPosY, tSwitch.nLine, tSwitch.nFace)
end

function CPlayerMgr:OnRobotSwitchLogicReq(tSwitch, tCreateData, tSaveData) 
	--nServer, nRobotID, nSrcID, nRobotType, nDupMixID, tParam
	local nServer = tCreateData.nServer
	local nRobotID = tCreateData.nRobotID
	local nSrcID = tCreateData.nSrcID
	local nRobotType = tCreateData.nRobotType

	self:CreateRobotReq(nServer, nRobotID, nSrcID, nRobotType, 0, nil, tSaveData, true)
	local oRole = self:GetRoleByID(tSwitch.nRoleID)
	goDupMgr:EnterDup(tSwitch.nTarDupMixID, oRole:GetNativeObj(), tSwitch.nPosX, tSwitch.nPosY, 
		tSwitch.nLine, tSwitch.nFace)
end

--踢人
function CPlayerMgr:KickRole(nRoleID)
	local oRole = self:GetRoleByID(nRoleID)
	if not oRole or not oRole:IsOnline() then
		return
	end
	local nSession = oRole:GetSession()
	CmdNet.Srv2Srv("KickClientReq", oRole:GetServer(), nSession>>gnServiceShift, nSession)
end

--只有角色在线时，登录服才会发起检查
function CPlayerMgr:DeleteRoleCheckReq(nRoleID) 
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then 
		--没找到返回false，防止异步事件bug，角色正好切换逻辑服，登录服发起删除检查请求
		return false, "角色不存在" 
	end
	if oRole:IsInBattle() then 
		return false, "战斗中，无法删除"
	end
	self:RoleOfflineReq(nRoleID)
	if not oRole:IsReleased() then 
		return false, "角色离线错误，暂时无法删除" 
	end
	return true 
end


--服务器关闭
function CPlayerMgr:OnServerClose(nServer)
	--强制对应服玩家下线
	for nRoleID, oRole in pairs(self.m_tRoleIDMap) do
		if nServer == oRole:GetServer() then
			local nBattleID = oRole:GetBattleID()
			if nBattleID > 0 then
				local oBattle = goBattleMgr:GetBattle(nBattleID)
				if oBattle then
					oBattle:ForceFinish()
				end
			end
			self:RoleOfflineReq(nRoleID)
		end
	end
end


goPlayerMgr = goPlayerMgr or CPlayerMgr:new()
goNativePlayerMgr = GlobalExport.GetPlayerMgr()