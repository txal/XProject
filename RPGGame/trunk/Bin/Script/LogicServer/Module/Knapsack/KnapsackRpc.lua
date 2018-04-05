function CltPBProc.KnapsackSellItemReq(nCmd, nServer, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:SellItemReq(tData.nGrid, tData.nNum)
end

function CltPBProc.KnapsackUseItemReq(nCmd, Server, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:UseItemReq(tData.nGrid, tData.nNum)
end

function CltPBProc.KnapsackComposeReq(nCmd, Server, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSession)
	if not oRole then return end
	oRole.m_oKnapsack:ComposeItemReq(tData.nID)
end
