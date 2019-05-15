--客户端->服务器
function CltPBProc.BattleStartReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	if oRole:IsInBattle() then
		return oRole:Tips("在战斗中")
	end

	local nObjID = tData.nObjID or 0
	local nObjType = tData.nObjType == 0 and gtObjType.eMonster or tData.nObjType

	if nObjType == gtObjType.eMonster then
		local oMonster = goMonsterMgr:GetMonster(nObjID)
		if not oMonster then
			return oRole:Tips("怪物不存在")
		end
		if not oMonster:CheckCanBattle() then 
			oRole:Tips("不可挑战")
			return 
		end
		if oMonster:GetDupMixID() ~= oRole:GetDupMixID() then
			return oRole:Tips("怪物非法")
		end
		local nRolePosX, nRolePosY = oRole:GetPos()
		local nMonsterPosX, nMonsterPosY = oMonster:GetPos()
		local nDistance = GF.Distance(nRolePosX, nRolePosY, nMonsterPosX, nMonsterPosY)
		if nDistance > 160 then
			return oRole:Tips("距离非法(160pix)")
		end
		oRole:PVE(oMonster)
	else
		oRole:Tips("只能打怪哦")
	end
end

function CltPBProc.UnitInstReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:AddInstReq(oRole, tData)
end

function CltPBProc.BattleSkillListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:SkillListReq(oRole, tData.nUnitID)
end

function CltPBProc.BattlePropListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:PropListReq(oRole, tData.nUnitID)
end

function CltPBProc.RoundPlayFinishReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return
	end
	oBattle:RoundPlayFinishReq(oRole, tData.nUnitID)
end

function CltPBProc.BattlePetListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:PetListReq(oRole, tData.nUnitID)
end

function CltPBProc.BattleEscapeFinishReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:EscapeFinishReq(oRole, tData.nUnitID)
end

function CltPBProc.BattleAutoInstListReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:BattleAutoInstListReq(oRole, tData.nUnitID)
end

function CltPBProc.BattleSetAutoInstReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:BattleSetAutoInstReq(oRole, tData.nUnitID, tData.nInst, tData.nSkillID)
end

function CltPBProc.BattleCommandInfoReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:BattleCommandInfoReq(oRole, tData.nUnitID)
end

function CltPBProc.ChangeBattleCommandReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:ChangeBattleCommandReq(oRole, tData.nCmdID, tData.sCmdName)
end

function CltPBProc.SetBattleCommandReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nBattleID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nBattleID)
	if not oBattle then
		return oRole:Tips("战斗不存在:"..nBattleID)
	end
	oBattle:SetBattleCommandReq(oRole, tData.nCmdID, tData.nUnitID)
end
