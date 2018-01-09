function CltPBProc.NewbieGuidStepReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oNewbieGuid:GetGuidStepReq()
end

function CltPBProc.SetNewbieGuidStepReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oNewbieGuid:SetGuidStepReq(tData.nStep)
end
