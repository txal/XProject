function CltPBProc.JJCInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:SyncInfo()
end

function CltPBProc.JJCAddMCReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:AddMC(tData.nGroup, tData.nGrid, tData.nMCID)
end

function CltPBProc.JJCRemoveMCReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:RemoveMC(tData.nGroup, tData.nGrid)
end

function CltPBProc.JJCSendReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:Send(tData.bUseProp)
end

function CltPBProc.JJCExtraRobReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:ExtraRobReq(tData.bExtraRob)
end

function CltPBProc.JJCZhaoJianListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:ZJListReq()
end

function CltPBProc.JJCChouHenListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:CHListReq(tData.nWinType)
end

function CltPBProc.JJCAttackReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:AttackReq(tData.nTarCharID, tData.nTarGroup, tData.nBattleType, tData.nNoticeID)
end

function CltPBProc.JJCTongJiListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:TongJiListReq()
end

function CltPBProc.JJCRankTongJiListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:RankTongJiListReq()
end

function CltPBProc.JJCPlayerTongJiReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:TongJiPlayerReq(tData.nTarCharID)
end

function CltPBProc.JJCNoticeListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:NoticeReq()
end

function CltPBProc.JJCOneKeyAddMCReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:OneKeyAddMCReq()
end

function CltPBProc.JJCJFCTReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:JFCTReq()
end

function CltPBProc.JJCGuWuReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:GuWuReq(tData.nGWType)
end

function CltPBProc.JJCExchangePosReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:ExchangePosReq(tData.nGrid1, tData.nGrid2)
end

function CltPBProc.JJCStartBattleReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:StartBattleReq(tData.nBattleType)
end
