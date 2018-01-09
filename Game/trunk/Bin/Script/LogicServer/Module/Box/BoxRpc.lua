function CltPBProc.BoxInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBox:BoxInfoReq()
end

function CltPBProc.GetBoxAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	oPlayer.m_oBox:GetBoxAwardReq(tData.nBoxType)
end
