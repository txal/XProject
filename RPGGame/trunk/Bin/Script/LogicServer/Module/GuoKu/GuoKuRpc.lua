function CltPBProc.GuoKuSellItemReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oGuoKu:SellItemReq(tData.nGrid, tData.nNum)
end

function CltPBProc.GuoKuUseItemReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oGuoKu:UseItemReq(tData.nGrid, tData.nNum)
end

function CltPBProc.GuoKuComposeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oGuoKu:ComposeItemReq(tData.nID)
end
