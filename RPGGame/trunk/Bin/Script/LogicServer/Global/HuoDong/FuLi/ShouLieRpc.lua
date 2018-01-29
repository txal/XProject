function CltPBProc.ShouLieStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	oAct:SyncState(oPlayer)
end

function CltPBProc.ShouLiePropListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	oAct:PropListReq(oPlayer)
end

function CltPBProc.ShouLieBuyPropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	oAct:BuyPropReq(oPlayer, tData.nPropID)
end

function CltPBProc.ShouLieUsePropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	oAct:UsePropReq(oPlayer, tData.nPropID)
end

function CltPBProc.ShouLieAwardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	oAct:AwardInfoReq(oPlayer)
end

function CltPBProc.ShouLieAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	oAct:AwardReq(oPlayer)
end

function CltPBProc.ShouLieExchangeListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	oAct:ExchangeListReq(oPlayer)
end

function CltPBProc.ShouLieExchangeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	oAct:ExchangeReq(oPlayer, tData.nPropID)
end

function CltPBProc.ShouLieRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	if tData.nType == 1 then
		oAct:PlayerRankingReq(oPlayer, tData.nRankNum)
	elseif tData.nType == 2 then
		oAct:UnionRankingReq(oPlayer, tData.nRankNum)
	end
end

function CltPBProc.ShouLieRankAwardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	if tData.nType == 1 then
		oAct:PlayerRankAwardInfoReq(oPlayer)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardInfoReq(oPlayer)
	end
end

function CltPBProc.ShouLieRankAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eShouLie)
	if tData.nType == 1 then
		oAct:PlayerRankAwardReq(oPlayer)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardReq(oPlayer)
	end
end
