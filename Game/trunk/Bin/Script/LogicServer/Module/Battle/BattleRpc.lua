function CltPBProc.PlayerRelvieReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBattle:ReliveReq()
end

function CltPBProc.PlayerSwitchWeaponReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBattle:SwitchWeapon(tData.nArmID)
end

function CltPBProc.ActorAddBuffReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBattle:AddBuf(tData.nBuffID)
end

function CltPBProc.PlayerEnterBackgroundReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBattle:OnEnterBackground()
end

function CltPBProc.PlayerEnterForegroundReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBattle:OnEnterForeground()
end

function CltPBProc.SendBattleFaceReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBattle:OnSendBattleFaceReq(tData.nFaceID)
end

function CltPBProc.CureReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBattle:OnCureReq(tData.nAOIID, tData.nPosX, tData.nPosY, tData.nAddHP)
end
