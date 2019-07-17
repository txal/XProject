function Network.CltPBProc.RankingListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oRanking = goRankingMgr:GetRanking(tData.nRankID)
	if not oRanking:CheckSysOpen(oRole, true) then
		return 
	end
	oRanking:RankingReq(oRole, tData.nRankNum)
	print("Network.CltPBProc.RankingListReq***", tData.nRankID)
end

function Network.CltPBProc.RankingCongratReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oRanking = goRankingMgr:GetRanking(tData.nRankID)
	if not oRanking.CongratReq then
		return oRole:Tips("排行榜"..tData.nRankID.."不支持祝贺")
	end
	if not oRanking:CheckSysOpen(oRole, true) then
		return
	end
	oRanking:CongratReq(oRole)
end







-----服务器内部
------推送科舉答題信息
function Network.RpcSrv2Srv.PushKejuRank(nSrcServer, nSrcService, nTarSession,nRoleID,nKejuType,tData)
	local oRank = goRankingMgr:GetRanking(gtRankingDef.eKejuRanking)
	if not oRank then return end

	if nKejuType == 3 then
		oRank:Update(nRoleID,tData)
	end
	if nKejuType == 4 then
		oRank:UpdateTemple(nRoleID,tData)
	end
end

function Network.RpcSrv2Srv.KejuRankingCheckJoinDianshiReq(nSrcServer,nSrcService,nTarSession,nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oRank = goRankingMgr:GetRanking(gtRankingDef.eKejuRanking)
	local bCanJoin = false
	if oRank then
		bCanJoin = oRank:CanJoinKeju(nRoleID)
	end
	return bCanJoin
end


function Network.RpcSrv2Srv.KejuRankingTest(nSrcServer,nSrcService,nTarSession,nOperaType,nRoleID,tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.eKejuRanking)
	if not oRanking then return end
	if nOperaType == 1 then
		oRanking:RankReward()
	elseif nOperaType == 2 then
		oRanking:TempleRankReward()
	elseif nOperaType == 3 then
		oRanking:ResetRanking()
	elseif nOperaType == 4 then
		oRanking:RankingReq(oRole, tData.nRankNum)
	end
end

--最高宠物评分变化
function Network.RpcSrv2Srv.PetScoreChangeReq(nSrcServer, nSrcService, nTarSession, nRoleID, nPetPos, sPetName, nValue)
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.ePetScoreRanking)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole or oRole:IsRobot() then 
		return 
	end
	print("Srv2Srv.PetScoreChangeReq***", nPetPos, sPetName, nValue)
	oRanking:Update(nRoleID, nPetPos, sPetName, nValue)
end

--家园资产评分变化
function Network.RpcSrv2Srv.HouseAssetsChangeReq(nSrcServer, nSrcService, nTarSession, nRoleID, nValue)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole or oRole:IsRobot() then 
		return 
	end
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.eHouseAssetsRanking)
	oRanking:Update(nRoleID, nValue)
end

--竞技场积分变化
function Network.RpcSrv2Srv.ArenaScoreChangeReq(nSrcServer, nSrcService, nTarSession, nRoleID, nValue)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole or oRole:IsRobot() then 
		return 
	end
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.eArenaScoreRanking)
	oRanking:Update(nRoleID, nValue)
end

--人气变化
function Network.RpcSrv2Srv.PopularityChangeReq(nSrcServer, nSrcService, nTarSession, nRoleID, nValue)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole or oRole:IsRobot() then 
		return 
	end
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.eWeekPopularityRanking)
	oRanking:Update(nRoleID, nValue)
end

--总好友度变化
function Network.RpcSrv2Srv.FriendDegreeChangeReq(nSrcServer, nSrcService, nTarSession, nRoleID, nValue)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole or oRole:IsRobot() then 
		return 
	end
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.eFriendDegreeRanking)
	oRanking:Update(nRoleID, nValue)
end
