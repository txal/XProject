function CltPBProc.FZRuGongReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFeiZi:RuGongReq(tData.nID)
end

function CltPBProc.FZModNameReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFZ = oPlayer.m_oFeiZi:GetObj(tData.nID)
	oFZ:ModNameReq(tData.sName, tData.nType)
end

function CltPBProc.FZModDescReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFZ = oPlayer.m_oFeiZi:GetObj(tData.nID)
	oFZ:ModDescReq(tData.sDesc)
end

function CltPBProc.FZUpgradeStarReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFZ = oPlayer.m_oFeiZi:GetObj(tData.nID)
	oFZ:UpgradeStarReq()
end

function CltPBProc.FZLearnReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFZ = oPlayer.m_oFeiZi:GetObj(tData.nID)
	oFZ:LearnReq()
end

function CltPBProc.FZUpFeiWeiReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFZ = oPlayer.m_oFeiZi:GetObj(tData.nID)
	oFZ:UpFeiWeiReq()
end

function CltPBProc.FZNaShaReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFZ = oPlayer.m_oFeiZi:GetObj(tData.nID)
	oFZ:NaShaReq(tData.nTimes, tData.bUseProp)
end

function CltPBProc.FZGiveTreasureReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oFZ = oPlayer.m_oFeiZi:GetObj(tData.nID)
	oFZ:GiveTreasureReq(tData.nPropID, tData.nPropNum)
end

function CltPBProc.FZQingAnReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFeiZi:QingAnReq(tData.bUseProp)
end

function CltPBProc.ZRFGridInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFeiZi:ZRFGridInfoReq()
end

function CltPBProc.FZQingAnInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oFeiZi:QingAnInfoReq()
end
