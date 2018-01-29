function CltPBProc.ZRQGStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eZaoRenQiangGuo)
	oAct:SyncState()
end

function CltPBProc.ZRQGInfoReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZaoRenQiangGuo:InfoReq()
end

function CltPBProc.ZRQGUseDYReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZaoRenQiangGuo:UseDYReq(tData.nType)
end

function CltPBProc.ZRQGOffInterfaceReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)  
	if not oPlayer then return end
	oPlayer.m_oZaoRenQiangGuo:OffInterfaceReq()
end

function CltPBProc.ZRQGReportSoldierReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oZaoRenQiangGuo:ReportSoldierReq(tData.nSoldiers, tData.nType)
end
