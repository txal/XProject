function CltPBProc.QDInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oQianDao:InfoReq()
end

function CltPBProc.QDAwardReq(nCmd, nSrc, nSession, tData)     
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oQianDao:QianDaoAwardReq(tData.nSelect, tData.nID)    
end
