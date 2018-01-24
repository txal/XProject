local sCharIDDB = "CharIDDB"			--角色ID管理(Center)
local sAccountDB = "AccountDB"			--账号管理(Center)
local sUniqueNameDB = "UniqueNameDB"	--角色名管理(Center)
local nMaxCharID = 9999999
local nBaseCharID = 1000000

function CPlayerMgr:Ctor()
	self.m_tSessionMap = {}
	self.m_tAccountMap = {}
	self.m_tCharIDMap = {}
end

function CPlayerMgr:GetPlayerByCharID(nCharID)
	return self.m_tCharIDMap[nCharID]
end

function CPlayerMgr:GetPlayerBySession(nSession)
	return self.m_tSessionMap[nSession]
end

function CPlayerMgr:GetPlayerByAccount(sAccount)
	return self.m_tAccountMap[nSession]
end

--生产角色ID
function CPlayerMgr:_GenPlayerID()
	local oCenterDB = goDBMgr:GetSSDBByName("Center")	
	local nIncr = oCenterDB:HIncr(sCharIDDB, "IDIncr")
	local nCharID = (nBaseCharID + nIncr) % nMaxCharID + 1
	print("CPlayerMgr:_GenPlayerID***", nCharID)
	return nCharID
end

--登录
function CPlayerMgr:Login(nSession, sAccount, sPassword, sImgURL)
	local nSelfLogic = GlobalExport.GetServiceID()
	local oPlayer = self.m_tAccountMap[sAccount]
	if oPlayer then
	--玩家对象没移除
		local nOldSession = oPlayer:GetSession()
		if nOldSession == 0 then
			oPlayer:SetSession(nSession)
			self:OnLoginSuccess(oPlayer)

		elseif nOldSession ~= nSession then
			self:OtherPlaceLogin(nOldSession, nSession, sAccount, sPassword)

		else
			LuaTrace("重复登录:", sAccount)
		end
		return
	end
	local sErr = string.format("会话ID冲突(注销没关连接) session:%d account:%s", nSession, sAccount)
	assert(not self.m_tSessionMap[nSession], sErr)

	local oCenterDB = goDBMgr:GetSSDBByName("Center")
	local sAccountData = oCenterDB:HGet(sAccountDB, sAccount)
	--创建角色
	if sAccountData == "" then
		CmdNet.PBSrv2Clt(nSession, "LoginRet", {nCode=-1})
		return
	end
	--取逻辑服ID
	local tAccount = cjson.decode(sAccountData)
	local nTarLogic = self:GetRoomLogic(tAccount.nCharID)
	if nTarLogic ~= nSelfLogic then
		self:SwitchLogicServer(nTarLogic, nSession, tAccount)
		return
	end
	--创建玩家对象
	local oPlayer = CPlayer:new(nSession, tAccount, sImgURL)
	self:OnLoginSuccess(oPlayer)
	return oPlayer
end

--切换逻辑服
function CPlayerMgr:SwitchLogicServer(nTarLogic, nSession, tAccount)
	local nSrcLogic = GlobalExport.GetServiceID()
	print("切换逻辑服:"..nSrcLogic.."->"..nTarLogic)
	local oPlayer = self:GetPlayerByAccount(tAccount.sAccount)
	if oPlayer then
		self:ReleasePlayer(oPlayer)
		goLogger:EventLog(gtEvent.eSwitchLogic, oPlayer, nSrcLogic, nTarLogic)
	end
	Srv2Srv.SwitchLogicServerReq(nTarLogic, nSession, tAccount)
end

--取游戏房间逻辑服
function CPlayerMgr:GetRoomLogic(nCharID)
	assert(nCharID)
	local nRoomID = self:GetGameRoomID(nCharID)
	local nLogic = goGameMgr:GetRoomLogic(nRoomID)
	return nLogic
end

--取游戏房间ID
function CPlayerMgr:GetGameRoomID(nCharID)
	local nRoomID = 0
	local oPlayer = self:GetPlayerByCharID(nCharID)
	if oPlayer then
		nRoomID = oPlayer.m_oGame:GetCurrGame().nRoomID
	else
		local tCurrGame = CGame:DataFromDB(nCharID, "m_tCurrGame") 
		nRoomID = tCurrGame and tCurrGame.nRoomID or 0
	end
	return nRoomID
end

--登录成功
function CPlayerMgr:OnLoginSuccess(oPlayer)
	local nSelfService = GlobalExport.GetServiceID()
	local nSession = oPlayer:GetSession()	
	local sAccount = oPlayer:GetAccount()
	local nCharID = oPlayer:GetCharID()
	local sCharName = oPlayer:GetName()

	self.m_tSessionMap[nSession] = oPlayer
	self.m_tAccountMap[sAccount] = oPlayer
	self.m_tCharIDMap[nCharID] = oPlayer

	--通知gateway
	CmdNet.Srv2Srv("PlayerLogicServiceSync", nSession>>nSERVICE_SHIFT, nSession, nSelfService) 

    --通知global
	Srv2Srv.OnPlayerOnline(gtNetConf:GlobalService(), nSession, nCharID, sCharName, nSelfService)

	--通知客户端
	CmdNet.PBSrv2Clt(nSession, "LoginRet", {nCode=0, nRoomID=self:GetGameRoomID(nCharID)}) 
    oPlayer:Online()

    --log
	goLogger:EventLog(gtEvent.eLogin, oPlayer)
	LuaTrace("CPlayerMgr:OnLoginSuccess***", nSession, sAccount, sCharName)
end

--创建角色
function CPlayerMgr:CreateRole(nSession, sAccount, sPassword, sCharName)
	assert(nSession and sAccount and sPassword and sCharName)
	local oCenterDB = goDBMgr:GetSSDBByName("Center")
	if oCenterDB:Setnx("lock.createrole", os.time()) == "0" then
		CmdNet.PBSrv2Clt(nSession, "CreateRoleRet", {nCode=-1})	--系统忙碌
		return
	end

	local function _create_role()
		local sAccountData = oCenterDB:HGet(sAccountDB, sAccount)
		if sAccountData ~= "" then
			CmdNet.PBSrv2Clt(nSession, "CreateRoleRet", {nCode=-2})	--角色已经存在
			return
		end

		local sExist = oCenterDB:HGet(sUniqueNameDB, sCharName)
		if sExist ~= "" then
			CmdNet.PBSrv2Clt(nSession, "CreateRoleRet", {nCode=-3})	--角色名重复
			return
		end

		local nCharID = self._GenPlayerID()
		local tAccount = {sAccount=sAccount, nCharID=nCharID, sCharName=sCharName, sPassword=sPassword}
		local sAccountData  = cjson.encode(tAccount)
		oCenterDB:HSet(sAccountDB, sAccount, sAccountData)
		oCenterDB:HSet(sUniqueNameDB, sCharName, nCharID)
		CmdNet.PBSrv2Clt(nSession, "CreateRoleRet", {nCode=0})

		--log
		goLogger:CreateAccountLog(sAccount, nCharID, sCharName)
	end

	xpcall(_create_role, function(sErr) LuaTrace(sErr) end)
	oCenterDB:Del("lock.createrole")
end


--客户端断开
function CPlayerMgr:OnClientClose(nSession)
	local oPlayer = self:GetPlayerBySession(nSession)
	local sName = oPlayer and oPlayer:GetName() or ""
	LuaTrace("CPlayerMgr:OnClientClose***", nSession, sName)
	if not oPlayer then
		return
	end
	--离线,数据不清
	oPlayer:Offline()
	self.m_tSessionMap[nSession] = nil
	
    --通知global
	Srv2Srv.OnPlayerOffline(gtNetConf:GlobalService(), nSession)
	--log
	goLogger:EventLog(gtEvent.eLogout, oPlayer)
end

--异地登录
function CPlayerMgr:OtherPlaceLogin(nOldSession, nNewSession, sAccount, sPassword)
	LuaTrace(string.format("异地登录 账号: %s 旧SESSION: %d 新SESSION: %d", sAccount, nOldSession, nNewSession))
	local oPlayer = assert(self:GetPlayerBySession(nOldSession), "异地登录玩家找不到")
	CmdNet.PBSrv2Clt(nOldSession, "OtherPlaceLoginRet", {})

	self:OnClientClose(nOldSession)
	self:Login(nNewSession, sAccount, sPassword)
	GlobalExport.RegisterTimer(3000, function(nTimerID) self:CloseSession(nOldSession, nTimerID) end)
end

--关闭会话
function CPlayerMgr:CloseSession(nSession, nTimerID)
	print("CPlayerMgr:CloseSession***", nSession, nTimerID)
	if nTimerID then	
		GlobalExport.CancelTimer(nTimerID)
	end
	CmdNet.Srv2Srv("KickClient", nSession>>nSERVICE_SHIFT, nSession)
end

--通过玩家名字取玩家ID
function CPlayerMgr:GetCharIDFromDB(sCharName)
	local oCenterDB = goDBMgr:GetSSDBByName("Center")
	local sCharID = oCenterDB:HGet(sUniqueNameDB, sCharName)
	if sCharID ~= "" then
		return tonumber(nCharID)
	end
end

--登出(注销)
function CPlayerMgr:Logout(nSession)
	LuaTrace("CPlayerMgr:Logout***", nSession)
	goPlayerMgr:OnClientClose(nSession)
	CmdNet.PBSrv2Clt(nSession, "LogoutRet", {})
end

--离线保持对象时间到时清除对象
function CPlayerMgr:ReleasePlayer(oPlayer)
	LuaTrace("CPlayerMgr:OfflineHoldTimeOut***", oPlayer:GetName())
	local nCharID = oPlayer:GetCharID()
	local sAccount = oPlayer:GetAccount()
	local nSession = oPlayer:GetSession()
	self.m_tCharIDMap[nCharID] = nil
	self.m_tAccountMap[sAccount] = nil
	self.m_tSessionMap[nSession] = nil
	oPlayer:OnRelease()
end

--取玩家Session列表
function CPlayerMgr:GetSessionList()
	local tSessionList = {}
	for k, v in pairs(self.m_tSessionMap) do
		table.insert(tSessionList, k)
	end
	return tSessionList
end




--------------cpp call--------------
--客户端断线
function OnClientClose(nSession)
	goPlayerMgr:OnClientClose(nSession)
end

--处理网关断开的情况
function OnServiceClose(nService)
	LuaTrace("OnServiceClose***", nService)
	if not gtNetConf.tGateService[nService] then
		return
	end
	for nSession, oPlayer in pairs(goPlayerMgr.m_tSessionMap) do
		local nTmpService = nSession >> nSERVICE_SHIFT 
		LuaTrace("OnServiceClose close session***", nSession, nTmpService, oPlayer:GetAccount())
		if nTmpService == nService then
			goPlayerMgr:OnClientClose(nSession)
		end
	end
end


goPlayerMgr = goPlayerMgr or CPlayerMgr:new()