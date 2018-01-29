function CltPBProc.NewbieGuideStepReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oNewbieGuide:GetGuideStepReq()
end

function CltPBProc.SetNewbieGuideStepReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oNewbieGuide:SetGuideStepReq(tData.nStep)
end
