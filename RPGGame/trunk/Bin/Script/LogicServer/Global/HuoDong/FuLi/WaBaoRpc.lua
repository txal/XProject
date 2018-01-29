function CltPBProc.WaBaoStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	oAct:SyncState(oPlayer)
end

function CltPBProc.WaBaoPropListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	oAct:PropListReq(oPlayer)
end

function CltPBProc.WaBaoBuyPropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	oAct:BuyPropReq(oPlayer, tData.nPropID)
end

function CltPBProc.WaBaoUsePropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	oAct:UsePropReq(oPlayer, tData.nPropID)
end

function CltPBProc.WaBaoAwardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	oAct:AwardInfoReq(oPlayer)
end

function CltPBProc.WaBaoAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	oAct:AwardReq(oPlayer)
end

function CltPBProc.WaBaoExchangeListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	oAct:ExchangeListReq(oPlayer)
end

function CltPBProc.WaBaoExchangeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	oAct:ExchangeReq(oPlayer, tData.nPropID)
end

function CltPBProc.WaBaoRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	if tData.nType == 1 then
		oAct:PlayerRankingReq(oPlayer, tData.nRankNum)
	elseif tData.nType == 2 then
		oAct:UnionRankingReq(oPlayer, tData.nRankNum)
	end
end

function CltPBProc.WaBaoRankAwardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	if tData.nType == 1 then
		oAct:PlayerRankAwardInfoReq(oPlayer)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardInfoReq(oPlayer)
	end
end

function CltPBProc.WaBaoRankAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eWaBao)
	if tData.nType == 1 then
		oAct:PlayerRankAwardReq(oPlayer)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardReq(oPlayer)
	end
end
