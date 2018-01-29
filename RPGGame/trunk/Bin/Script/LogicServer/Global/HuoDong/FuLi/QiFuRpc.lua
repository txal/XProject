function CltPBProc.QiFuStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	oAct:SyncState(oPlayer)
end

function CltPBProc.QiFuPropListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	oAct:PropListReq(oPlayer)
end

function CltPBProc.QiFuBuyPropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	oAct:BuyPropReq(oPlayer, tData.nPropID)
end

function CltPBProc.QiFuUsePropReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	oAct:UsePropReq(oPlayer, tData.nPropID)
end

function CltPBProc.QiFuServerAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	oAct:ServerAwardReq(oPlayer)
end

function CltPBProc.QiFuGetServerAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	oAct:GetServerAwardReq(oPlayer)
end

function CltPBProc.QiFuExChangeListReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	oAct:ExChangeListReq(oPlayer)
end

function CltPBProc.QiFuExChangeItemReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	oAct:ExChangeItemReq(oPlayer, tData.nPropID)
end

function CltPBProc.QiFuRankingReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	if tData.nType == 1 then 
		oAct:PlayerRankingReq(oPlayer, tData.nRankNum)
	elseif tData.nType == 2 then 
		oAct:UnionRankingReq(oPlayer, tData.nRankNum)
	end
end

function CltPBProc.QiFuRankingAwardStateReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	if tData.nType == 1 then 
		oAct:PlayerRankingAwardStateReq(oPlayer)
	elseif tData.nType == 2 then 
		oAct:UnionRankingAwardStateReq(oPlayer)
	end
end 

function CltPBProc.QiFuGetRankAwardReq(nCmd, nSrc, nSession, tData)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eQiFu)
	if tData.nType == 1 then 
		oAct:GetPlayerRankAwardReq(oPlayer)
	elseif tData.nType == 2 then 
		oAct:GetUnionRankAwardReq(oPlayer)
	end
end

