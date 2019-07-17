--竞技场逻辑服功能
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert



------------Svr2Svr-------------
function Network.RpcSrv2Srv.ArenaSysOpenCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local bOpen = oRole.m_oSysOpen:IsSysOpen(39)
	return bOpen
end

function Network.RpcSrv2Srv.ArenaBattleCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID, nEnemyID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	if oRole:IsInBattle() then
		return false, "当前正在战斗中，无法挑战"
	end
	local oCurDup = oRole:GetCurrDupObj()
	if not oCurDup then
		return false, "场景不正确"
	end
	if oRole:GetTeamID() > 0 then
		return false, "竞技场为个人玩法，请退出队伍后再尝试"
	end
	local tDupConf = oCurDup:GetConf()
	if tDupConf.nType ~= CDupBase.tType.eCity then
		-- return false, "正在进行其他活动，无法发起挑战"

		local fnSceneProc = function(tData)
			if not tData then 
				return 
			end
			if tData.nSelIdx == 1 then
                return
			elseif tData.nSelIdx == 2 then
				oRole:SetTarActFlag(gtRoleTarActFlag.eArena, {nEnemyID = nEnemyID})
				print(oRole:GetTarActFlag())
				oRole:EnterLastCity()
			end
		end
		local tMsg = {sCont="是否确定离开当前活动场景？", tOption={"取消", "确定"}, nTimeOut=30}
        goClientCall:CallWait("ConfirmRet", fnSceneProc, oRole, tMsg)
		return false
	end
	return true
end

function Network.RpcSrv2Srv.ArenaBattleReq(nSrcServer, nSrcService, nTarSession, nRoleID, tEnemyData, nArenaSeason)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	if oRole:IsInBattle() then
		oRole:Tips("正在战斗中，无法参与竞技场")
		return
	end
	local nEnemyID = tEnemyData.nEnemyID
	local tAsyncData = {} --在玩家战斗结束时，根据此数据发起结算
	tAsyncData.nArenaSeason = nArenaSeason
	tAsyncData.nEnemyID = nEnemyID
	local tExtData = {}
	tExtData.bArenaBattle = true
	tExtData.tArenaData = tAsyncData

	local oArenaTar = nil
	local tTarBTData = nil
	if CArenaRobot:IsRobot(nEnemyID) then
		oArenaTar = CArenaRobot:new(nEnemyID, tEnemyData.nEnemyLevel)
		assert(oArenaTar, "创建竞技场战斗对象失败")
		tTarBTData = oArenaTar:GetBattleData()
	else
		--目前竞技场不跨服，目标玩家必然和发起挑战玩家同服
		oArenaTar = CArenaNpc:new(oRole:GetServer(), nEnemyID)
		assert(oArenaTar, "创建竞技场战斗对象失败")
		tTarBTData = oArenaTar:GetBattleData()
		oArenaTar:Release()
	end
	oArenaTar = nil

	-- tTarBTData.bAuto = true  --强制设置为自动战斗
	oRole:PVPArena(tTarBTData, tExtData, 30)
	oRole.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eArena, "参加竞技场")
	oRole:PushAchieve("竞技场次数",{nValue = 1})
	CEventHandler:OnJoinArenaBattle(oRole, {})
end

function Network.RpcSrv2Srv.AddArenaCoinReq(nSrcServer, nSrcService, nTarSession, nRoleID, nNum, sReason)
	assert(nRoleID > 0 and nNum and sReason, "参数错误")
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return oRole:AddItem(gtItemType.eCurr, gtCurrType.eArenaCoin, nNum, sReason)
end

function Network.RpcSrv2Srv.ArenaAddBattleRewardReq(nSrcServer, nSrcService, nTarSession, nRoleID, tReward)
	assert(nRoleID > 0 and tReward, "参数错误")
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local nRoleExp = tReward.nRoleExp
	local nPetExp = tReward.nPetExp
	local nSilverCoin = tReward.nSilverCoin
	local nArenaCoin = tReward.nArenaCoin

	local sReason = "竞技场战斗奖励"
	if nRoleExp and nRoleExp ~= 0 then
		oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, sReason)
	end
	local oBattlePet = oRole.m_oPet:GetCombatPet()
	if oBattlePet and nPetExp and nPetExp ~= 0 then
		oRole.m_oPet:AddExp(nPetExp)
	end
	if nSilverCoin and nSilverCoin > 0 then
		oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nSilverCoin, sReason)
	end
	if nArenaCoin and nArenaCoin ~= 0 then
		oRole:AddItem(gtItemType.eCurr, gtCurrType.eArenaCoin, nArenaCoin, sReason)
	end
end






