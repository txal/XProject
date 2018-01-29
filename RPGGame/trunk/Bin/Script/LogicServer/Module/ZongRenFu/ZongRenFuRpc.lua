function CltPBProc.HZListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZongRenFu:HZListReq()
end

function CltPBProc.HZModNameReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oHZ = oPlayer.m_oZongRenFu:GetObj(tData.nID)
	oHZ:ModName(tData.sName)
end

function CltPBProc.HZSpeedGrowUpReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oHZ = oPlayer.m_oZongRenFu:GetObj(tData.nID)
	oHZ:SpeedGrowUp(tData.nPropID, tData.nPropNum)
end

function CltPBProc.HZUpLearnEffReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oHZ = oPlayer.m_oZongRenFu:GetObj(tData.nID)
	oHZ:UpLearnEffReq()
end

function CltPBProc.HZLearnReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oHZ = oPlayer.m_oZongRenFu:GetObj(tData.nID)
	oHZ:LearnReq(tData.bUseProp)
end

function CltPBProc.HZFengJueReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oHZ = oPlayer.m_oZongRenFu:GetObj(tData.nID)
	oHZ:FengJueReq()
end

function CltPBProc.HZUnmarriedListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZongRenFu:UnmarriedListReq()
end

function CltPBProc.HZMarriedListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZongRenFu:MarriedListReq()
end

function CltPBProc.HZMarriedListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZongRenFu:MarriedListReq()
end

function CltPBProc.HZOpenGridReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZongRenFu:OpenGrid()
end

function CltPBProc.OneKeyLearnReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZongRenFu:OneKeyLearnReq()
end

function CltPBProc.OneKeyRecoverReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZongRenFu:OneKeyRecoverReq()
end

--联姻彩礼信息请求
function CltPBProc.HZCaiLiInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oHZ = oPlayer.m_oZongRenFu:GetObj(tData.nID)
	oHZ:CaiLiInfoReq()
end

--设置彩礼请求
function CltPBProc.HZSetCaiLiReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oHZ = oPlayer.m_oZongRenFu:GetObj(tData.nID)
	oHZ:SetCaiLiReq(tData.nCaiLiID)
end

--宗仁府信息请求
function CltPBProc.ZRFGridInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZongRenFu:GridInfoReq()
end
