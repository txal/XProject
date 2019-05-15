
function CltPBProc.PayPushReceiveRewardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oPayPush:PayPushReceiveRewardReq(tData.nID)
end