function CltPBProc.JZRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oJZRanking:JZRankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.GLRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oGLRanking:GLRankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.HZRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oHZRanking:HZRankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.SLRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oSLRanking:SLRankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.QMRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oQMRanking:QMRankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.NLRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oNLRanking:NLRankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.CDRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oCDRanking:CDRankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.WWRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oWWRanking:WWRankingReq(oPlayer, tData.nRankNum, tData.nType)
end

function CltPBProc.ZJRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oZJRanking:ZJRankingReq(oPlayer, tData.nRankNum)
end

function CltPBProc.UGLRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oUGLRanking:UGLRankingReq(oPlayer, tData.nRankNum, tData.nType)
end

function CltPBProc.CZDQRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oCZDQRanking:PeiKuanRankingReq(oPlayer, tData.nRankNum)
end  

function CltPBProc.DupRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oDupRanking:DupRankingReq(oPlayer, tData.nRankNum)
end  

function CltPBProc.ZRQGRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oZRQGRanking:ZRQGRankingReq(oPlayer, tData.nRankNum) 
end  

function CltPBProc.MCRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oMCRanking:MCRankingReq(oPlayer, tData.nRankNum) 
end  

function CltPBProc.PartyRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oPartyRanking:PartyRankingReq(oPlayer, tData.nRankNum) 
end 

function CltPBProc.GDRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goRankingMgr.m_oGDRanking:GDRankingReq(oPlayer, tData.nRankNum, tData.nType) 
end 
