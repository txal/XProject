function Network.CltPBProc.MCUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nID)
	oMC:UpgradeReq()
end

function Network.CltPBProc.MCOneKeyUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nID)
	oMC:OneKeyUpgradeReq()
end

function Network.CltPBProc.SKUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:SkillUpgradeReq(tData.nSKID)
end

function Network.CltPBProc.SKOneKeyUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:SkillOneKeyUpgradeReq(tData.nSKID)
end

function Network.CltPBProc.SKAdvanceReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:SkillAdvanceReq(tData.nSKID)
end

function Network.CltPBProc.GiveTreasureReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nID)
	oMC:GiveTreasureReq(tData.nPropID, tData.nPropNum)
end

function Network.CltPBProc.MCTrainReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nID)
	oMC:TrainReq()
end

function Network.CltPBProc.QuaBreachReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:BreachReq(tData.nQuaID)
end

function Network.CltPBProc.MCRecruitReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMingChen:RuGongReq(tData.nID)
end

function Network.CltPBProc.MCFengGuanReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:FengGuanReq()
end

function Network.CltPBProc.MCModNameReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:ModNameReq(tData.sName, tData.nType)
end

function Network.CltPBProc.OneKeyGiveTreasureReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:OneKeyGiveTreasureReq()
end

function Network.CltPBProc.MCAttrDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:AttrDetailReq()
end

function Network.CltPBProc.MCYaoYueReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:YaoYueReq(tData.nTimes, tData.bUseProp)
end

function Network.CltPBProc.MCUpgradeTalentReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:UpgradeTalentReq()
end

function Network.CltPBProc.MCFengJueReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:FengJueReq()
end

function Network.CltPBProc.MCSendGiftReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:SendGiftReq(tData.nPropID, tData.nPropNum)
end

function Network.CltPBProc.MCOneKeySendGiftReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:OneKeySendGiftReq()
end

