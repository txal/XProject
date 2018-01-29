function CltPBProc.DianDengStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	oAct:SyncState(oPlayer)
end

function CltPBProc.DianDengPropListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	oAct:PropListReq(oPlayer)
end

function CltPBProc.DianDengBuyPropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	oAct:BuyPropReq(oPlayer, tData.nPropID)
end

function CltPBProc.DianDengUsePropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	oAct:UsePropReq(oPlayer, tData.nPropID)
end

function CltPBProc.DianDengAwardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	oAct:AwardInfoReq(oPlayer)
end

function CltPBProc.DianDengAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	oAct:AwardReq(oPlayer)
end

function CltPBProc.DianDengExchangeListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	oAct:ExchangeListReq(oPlayer)
end

function CltPBProc.DianDengExchangeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	oAct:ExchangeReq(oPlayer, tData.nPropID)
end

function CltPBProc.DianDengRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	if tData.nType == 1 then
		oAct:PlayerRankingReq(oPlayer, tData.nRankNum)
	elseif tData.nType == 2 then
		oAct:UnionRankingReq(oPlayer, tData.nRankNum)
	end
end

function CltPBProc.DianDengRankAwardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	if tData.nType == 1 then
		oAct:PlayerRankAwardInfoReq(oPlayer)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardInfoReq(oPlayer)
	end
end

function CltPBProc.DianDengRankAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eDianDeng)
	if tData.nType == 1 then
		oAct:PlayerRankAwardReq(oPlayer)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardReq(oPlayer)
	end
end
