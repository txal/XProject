function Network.CltPBProc.HallFameCongratReq(nCmd, nServer, nSrevice, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goHallFame:CongratReq(oRole, tData.nTitleID)
end

function Network.CltPBProc.HallFameSetCongratTipsReq(nCmd, nServer, nSrevice, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goHallFame:SetCongratTipsReq(oRole, tData.nTitleID, tData.sTips)
end
