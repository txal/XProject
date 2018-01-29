function CltPBProc.HuaKuiStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	oAct:SyncState(oPlayer)
end

function CltPBProc.HuaKuiPropListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	oAct:PropListReq(oPlayer)
end

function CltPBProc.HuaKuiBuyPropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	oAct:BuyPropReq(oPlayer, tData.nPropID)
end

function CltPBProc.HuaKuiUsePropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	oAct:UsePropReq(oPlayer, tData.nPropID)
end

function CltPBProc.HuaKuiAwardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	oAct:AwardInfoReq(oPlayer)
end

function CltPBProc.HuaKuiAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	oAct:AwardReq(oPlayer)
end

function CltPBProc.HuaKuiExchangeListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	oAct:ExchangeListReq(oPlayer)
end

function CltPBProc.HuaKuiExchangeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	oAct:ExchangeReq(oPlayer, tData.nPropID)
end

function CltPBProc.HuaKuiRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	if tData.nType == 1 then
		oAct:PlayerRankingReq(oPlayer, tData.nRankNum)
	elseif tData.nType == 2 then
		oAct:UnionRankingReq(oPlayer, tData.nRankNum)
	end
end

function CltPBProc.HuaKuiRankAwardInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	if tData.nType == 1 then
		oAct:PlayerRankAwardInfoReq(oPlayer)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardInfoReq(oPlayer)
	end
end

function CltPBProc.HuaKuiRankAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eHuaKui)
	if tData.nType == 1 then
		oAct:PlayerRankAwardReq(oPlayer)
	elseif tData.nType == 2 then
		oAct:UnionRankAwardReq(oPlayer)
	end
end
