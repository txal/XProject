function CltPBProc.VIPAwardListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:VIPAwardListReq()
end

function CltPBProc.VIPAwardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:VIPAwardReq(tData.nVIP)
end

function CltPBProc.RechargeListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:RechargeListReq()
end

function CltPBProc.FirstRechargeAwardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:FirstRechargeAwardReq()
end

function CltPBProc.RechargeRebateAwardInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:RechargeRebateAwardInfoReq()
end

function CltPBProc.RechargeRebateAwardReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:RechargeRebateAwardReq(tData.nID)
end

function CltPBProc.RechargeGetTotalPureYuanBaoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)     
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	oRole.m_oVIP:GetTotalPureYuanBaoReq()
end


------服务器内部------
function Srv2Srv.ProccessRechargeOrderReq(nSrcServer, nSrcService, nTarSession, sOrderID, nRechargeID, nTime)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end
	return oRole.m_oVIP:ProcessRechargeOrderReq(sOrderID, nRechargeID, nTime)
end 

--获取累计充值
function Srv2Srv.GetTotalMoneyReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole.m_oVIP:GetTotalRecharge()
end

