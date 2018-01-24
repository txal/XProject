function CltPBProc.LoginReq(nCmd, nSrc, nSession, tData)
	local sAccount = string.Trim(tData.sAccount or "")
	local sPassword = string.Trim(tData.sPassword or "")
	assert(sAccount ~= "" and  sPassword ~= "")
	local sPlatform = string.lower(tData.sPlatform or "")
	local sChannel = string.lower(tData.sChannel or "")
    goLuaPlayerMgr:Login(nSession, sAccount, sPassword, sPlatform, sChannel)
end


function CltPBProc.CreateRoleReq(nCmd, nSrc, nSession, tData)
	local sAccount = string.Trim(tData.sAccount or "")
	local sPassword = string.Trim(tData.sPassword or "")
	local sCharName = string.Trim(tData.sCharName or "")
	assert(sAccount ~="" and sPassword ~= "" and sCharName ~= "")
	local nRoleID = tData.nRoleID or 0
    goLuaPlayerMgr:CreateRole(nSession, sAccount, sPassword, sCharName, nRoleID)
end


function CltPBProc.PlayerEnterSceneReq(nCmd, nSrc, nSession, tData)
	local nSceneID = tData.nSceneID
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oScene = goLuaSceneMgr:CreateScene(nSceneID)
	assert(oScene)
	oPlayer:EnterScene(oScene:GetSceneIndex(), gtBattleType.eTest)
end

function CltPBProc.PlayerLeaveSceneReq(nCmd, nSrc, nSession, tData)
	local nSceneID = tData.nSceneID
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer:LeaveScene(nSceneID)
end

function CltPBProc.ClientSceneReadyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer:OnClientSceneReady()
end

---------------服务器内部----------------
function Srv2Srv.GlobalPlayerStateReq(nSrc, nSession, sCharID)
	local oPlayer
	if nSession > 0 then
		oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	elseif sCharID ~= "" then
		oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
	end
	print("Srv2Srv.GlobalPlayerStateReq***", nSrc, nSession, sCharID)
	if oPlayer then
		Srv2Srv.OnPlayerOnline(gtNetConf:GetGlobalService(), oPlayer:GetSession(), oPlayer:GetCharID(), oPlayer:GetName()
			, GlobalExport:GetServiceID(), oPlayer:GetPlatform(), oPlayer:GetChannel()) 
	end
end
