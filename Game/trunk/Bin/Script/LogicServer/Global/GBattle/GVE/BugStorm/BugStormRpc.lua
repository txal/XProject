function CltPBProc.BugStormSingleMatchReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oBugStormMgr = goBattleCnt:GetBattleMgr(gtBattleType.eBugStorm)
	oBugStormMgr:SingleMatchReq(oPlayer)
end

function CltPBProc.BugStormCancelMatchReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oBugStormMgr = goBattleCnt:GetBattleMgr(gtBattleType.eBugStorm)
	oBugStormMgr:CancelMatchReq(oPlayer)
end

function CltPBProc.BugStormStartBattleReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oBugStormMgr = goBattleCnt:GetBattleMgr(gtBattleType.eBugStorm)
	oBugStormMgr:StartBattleReq(oPlayer)
end

function CltPBProc.BuyBulletReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBattle:OnBuyBulletReq(oPlayer)
end
