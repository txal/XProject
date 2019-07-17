function Network.CltPBProc.FashionMallReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFashion:FashionMallReq()
end

function Network.CltPBProc.FashionBuyReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFashion:FashionBuyReq(tData.nID)
end

function Network.CltPBProc.FashionWearReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFashion:FashionWearReq(tData.nID)
end

function Network.CltPBProc.FashionOffReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFashion:FashionOffReq(tData.nID)
end

function Network.CltPBProc.FashionStrengthReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFS = oPlayer.m_oFashion:GetFashion(tData.nID)
	oFS:StrengthReq(tData.tList)
end

function Network.CltPBProc.FashionAdvanceReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFS = oPlayer.m_oFashion:GetFashion(tData.nID)
	oFS:AdvanceReq()
end

function Network.CltPBProc.FashionUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFS = oPlayer.m_oFashion:GetFashion(tData.nID)
	oFS:UpgradeReq()
end

function Network.CltPBProc.FashionMakeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFashion:FashionMakeReq(tData.nID)
end
