function CltPBProc.HallCreateRoomReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goGameMgr:HallCreateRoomReq(oPlayer, tData.nGameType)
end

function CltPBProc.HallJoinRoomReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goGameMgr:HallJoinRoomReq(oPlayer, tData.nRoomID)
end

function CltPBProc.HallClickGameReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goGameMgr:HallClickGameReq(oPlayer, tData.nGameType)
end

function CltPBProc.HallEtcReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goGameMgr:HallEtcReq(oPlayer)
end
