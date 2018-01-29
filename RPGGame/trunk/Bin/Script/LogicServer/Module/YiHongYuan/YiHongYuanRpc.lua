function CltPBProc.YHYInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oYiHongYuan:InfoReq()    
end

function CltPBProc.YHYChouJiangReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oYiHongYuan:ChouJiangReq(tData.nSelect)  
end

function CltPBProc.YHYBuyGongNvReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oYiHongYuan:BuyGongNvReq()  
end

function CltPBProc.YHYAddSpeedReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oYiHongYuan:AddSpeedReq()  
end