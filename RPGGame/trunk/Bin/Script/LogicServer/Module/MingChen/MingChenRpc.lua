function CltPBProc.MCUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nID)
	oMC:UpgradeReq()
end

function CltPBProc.MCOneKeyUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nID)
	oMC:OneKeyUpgradeReq()
end

function CltPBProc.SKUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:SkillUpgradeReq(tData.nSKID)
end

function CltPBProc.SKOneKeyUpgradeReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:SkillOneKeyUpgradeReq(tData.nSKID)
end

function CltPBProc.SKAdvanceReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:SkillAdvanceReq(tData.nSKID)
end

function CltPBProc.GiveTreasureReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nID)
	oMC:GiveTreasureReq(tData.nPropID, tData.nPropNum)
end

function CltPBProc.MCTrainReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nID)
	oMC:TrainReq()
end

function CltPBProc.QuaBreachReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:BreachReq(tData.nQuaID)
end

function CltPBProc.MCRecruitReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oMingChen:RuGongReq(tData.nID)
end

function CltPBProc.MCFengGuanReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:FengGuanReq()
end

function CltPBProc.MCModNameReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:ModNameReq(tData.sName, tData.nType)
end

function CltPBProc.OneKeyGiveTreasureReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:OneKeyGiveTreasureReq()
end

function CltPBProc.MCAttrDetailReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:AttrDetailReq()
end

function CltPBProc.MCYaoYueReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:YaoYueReq(tData.nTimes, tData.bUseProp)
end

function CltPBProc.MCUpgradeTalentReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:UpgradeTalentReq()
end

function CltPBProc.MCFengJueReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:FengJueReq()
end

function CltPBProc.MCSendGiftReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:SendGiftReq(tData.nPropID, tData.nPropNum)
end

function CltPBProc.MCOneKeySendGiftReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:GetObj(tData.nMCID)
	oMC:OneKeySendGiftReq()
end

