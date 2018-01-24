function CltPBProc.BugHoleSingleMatchReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oBugHoleMgr = goBattleCnt:GetBattleMgr(gtBattleType.eBugHole)
	oBugHoleMgr:SingleMatchReq(oPlayer)
end

function CltPBProc.BugHoleCancelMatchReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oBugHoleMgr = goBattleCnt:GetBattleMgr(gtBattleType.eBugHole)
	oBugHoleMgr:CancelMatchReq(oPlayer)
end

function CltPBProc.BugHoleTeamKillDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oBugHoleMgr = goBattleCnt:GetBattleMgr(gtBattleType.eBugHole)
	local oRoom = oBugHoleMgr:GetRoomByPlayer(oPlayer)
	if oRoom then
		oRoom:TeamKillDetailReq(oPlayer)
	end
end
