function CltPBProc.CZDQInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oChengZhiDiQiu:InfoReq()
end

function CltPBProc.CZDQUseXFReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oChengZhiDiQiu:UseXFReq(tData.nType)
end

function CltPBProc.CZDQOffInterfaceReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oChengZhiDiQiu:OffInterfaceReq()
end

function CltPBProc.CZDQReportYinLiangReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oChengZhiDiQiu:ReportYinLiangReq(tData.nYinLiang, tData.nXFType)
end
