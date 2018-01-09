function CltPBProc.CreateTeamReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:CreateTeamReq(oPlayer, tData.nGameType, tData.nMapType)
end

function CltPBProc.EnterTeamReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:EnterTeamReq(oPlayer, tData.nRoomID)
end

function CltPBProc.KickMemberReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:KickMemberReq(oPlayer, tData.sCharID)
end

function CltPBProc.LeaveTeamReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:LeaveTeamReq(oPlayer)
end

function CltPBProc.SwitchTeamTypeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:SwitchTeamTypeReq(oPlayer, tData.nGameType, tData.nMapType)
end

function CltPBProc.SwitchTeamTypeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:StartMatchReq(oPlayer)
end

function CltPBProc.TeamReadyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:ReadyReq(oPlayer)
end

function CltPBProc.TeamReadyConfirmReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:ConfirmReq(oPlayer)
end

function CltPBProc.TeamStartMatchReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goTeamMgr:StartMatchReq(oPlayer)
end
