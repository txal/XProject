function CltPBProc.PickDropItemReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goLuaPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	goLuaDropItemMgr:PickDropItemReq(oPlayer, tData.nSrcAOIID, tData.nDropAOIID)
end
