function CltPBProc.TimeGiftStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeGift)
	oAct:SyncState(oPlayer)
end

function CltPBProc.TimeGiftBuyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeGift)
	oAct:BuyReq(oPlayer, tData.nID)
end

function CltPBProc.TimeGiftGetActItemReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eTimeGift)
	oAct:GetActItem(oPlayer)
end
