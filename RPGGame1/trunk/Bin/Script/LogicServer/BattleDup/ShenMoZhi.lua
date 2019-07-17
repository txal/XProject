--神魔志
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CShenMoZhi:Ctor(nID, nType)
	print("创建神魔志副本", nID)
	self.m_nID = nID 						--战斗副本ID
	self.m_nType = nType 					--副本战斗类型
	self.m_tDupList = CUtil:WeakTable("v") 	--地图列表{地图对象,...}
	self.m_tRoleMap = CUtil:WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = CUtil:WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...}
	self.m_bNotChallenge = false			--记录当前关卡是否有玩家未挑战过
	--不保存信息
	self:Init()
end

--初始化副本
function CShenMoZhi:Init()
	local tConf = ctBattleDupConf[self.m_nType]
	for _, tDup in ipairs(tConf.tDupList) do
		local oDup = goDupMgr:CreateDup(tDup[1])
	    oDup:SetAutoCollected(false) --设置非自动收集
		table.insert(self.m_tDupList, oDup)
	end
	for _, oDup in pairs(self.m_tDupList) do
		oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
		oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
		-- oDup:RegLeaderActivityCallback(function(oLuaObj, nInactivityTime) self:OnLeaderActivity(oLuaObj, nInactivityTime) end)
		-- oDup:RegLeaveTeamCallback(function(oLuaObj) self:OnLeaveTeam(oLuaObj) end )
		oDup:RegBattleEndCallback(function(...) self:OnBattleEnd(...) end )
	end

end

--销毁副本
function CShenMoZhi:Release() 
	print("神魔志副本被销毁", self.m_nID)
	for _, oDup in pairs(self.m_tDupList) do
		goDupMgr:RemoveDup(oDup:GetMixID())
	end
	self.m_tDupList = {}
	self.m_tRoleMap = {}
	self.m_tMonsterMap = {}
end

function CShenMoZhi:GetID() return self.m_nID end --战斗副本ID
function CShenMoZhi:GetType() return self.m_nType end --取副本战斗类型
function CShenMoZhi:GetConf() return ctBattleDupConf[self:GetType()] end
function CShenMoZhi:HasRole() return next(self.m_tRoleMap) end

--取地图ID
--@nIndex 副本中的第几个地图
function CShenMoZhi:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

--取地图对象
--@nIndex 副本中的第几个地图
function CShenMoZhi:GetDupObj(nIndex)
	return self.m_tDupList[nIndex]
end

--对象进入副本
function CShenMoZhi:OnObjEnter(oLuaObj, bReconnect)
	print("CShenMoZhi:OnObjEnter***", bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj

	--人物
	elseif nObjType == gtGDef.tObjType.eRole then
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
		oLuaObj:SetBattleDupID(self:GetID())
	end
end

--对象离开副本
function CShenMoZhi:OnObjLeave(oLuaObj, nBattleID)
	print("CShenMoZhi:OnObjLeave***")
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = nil

	--人物
	elseif nObjType == gtGDef.tObjType.eRole then
		if nBattleID > 0 then --如果是战斗离开副本,不用处理
		else
			self.m_tRoleMap[oLuaObj:GetID()] = nil
			oLuaObj:SetBattleDupID(0)
			--所有玩家离开就销毁副本
			if not next(self.m_tRoleMap) then
				goBattleDupMgr:DestroyBattleDup(self:GetID())
			end
		end
	end
end

--进入副本请求,可能会切换服务进程(这时未创建副本)
function CShenMoZhi:EnterBattleDupReq(oRole)
	local oDup = oRole:GetCurrDupObj()
	if oDup:GetConf().nBattleType == gtBattleDupType.eShenMoZhi then
		return oRole:Tips("已经在神魔志副本中")
	end
	local tBattleDupConf = ctBattleDupConf[gtBattleDupType.eShenMoZhi]

	goBattleDupMgr:CreateBattleDup(gtBattleDupType.eShenMoZhi, function(nDupMixID)
	    local tConf = assert(ctDupConf[CUtil:GetDupID(nDupMixID)])
		oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
	end)
end

function CShenMoZhi:BattleDupMatchTeam(oRole)
	local tBattleDupConf = ctBattleDupConf[gtBattleDupType.eShenMoZhi]
	oRole:GetTeam(function(nTeamID, tTeam)
		if nTeamID > 0 and #tTeam >= 5 then
			return oRole:Tips("队伍已满员，无需组队")
		end
		oRole:MatchTeam(gtBattleDupType.eShenMoZhi, tBattleDupConf.sName)
	end)
end

function CShenMoZhi:ChallengeStart(oRole,nGuanQiaID)
	local tConfig = ctShenMoZhiConf[nGuanQiaID]
	local nOpenLevel = tConfig.nOpenLv
	local nMonConfID = tConfig.nFightID
	local nType = oRole.m_oShenMoZhiData:GetTypeByGuanQia(nGuanQiaID)
	if not nType then
		return
	end
	-- if oRole:GetTeamID() > 0 and not oRole:IsLeader() then 
	-- 	return oRole:Tips("只有队长可以操作")
	-- end
	oRole:GetTeam(function(nTeamID, tTeam)
		if nType <= 1 then
			if nTeamID and nTeamID > 0 then
				return oRole:Tips("该难度只可单人挑战")
			end
		else
			-- if not nTeamID or nTeamID <=0 then
			-- 	return oRole:Tips("难度较高，请三人以上组队挑战")
			-- end
			-- local nReturnCount = 0
			-- for _, tRole in pairs(tTeam) do
			-- 	if not tRole.bLeave then nReturnCount = nReturnCount+1 end
			-- 	if nGuanQiaID > 15 then
			-- 		local oTeamRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
			-- 		if oTeamRole and oTeamRole:GetLevel() < nOpenLevel then
			-- 			return oRole:Tips(string.format("%s的等级不足%d级",oTeamRole:GetName(),nOpenLevel))
			-- 		end
			-- 	end
			-- end
			-- if nReturnCount < 3 then
			-- 	return oRole:Tips("难度较高，请三人以上组队挑战")
			-- end

			local _EnterDupCheck = function (tRole)
				if not tRole.bLeave then 
					if nGuanQiaID > 15 then
						local oTeamRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
						if oTeamRole and oTeamRole:GetLevel() < nOpenLevel then
							return string.format("%s的等级不足%d级",oTeamRole:GetName(),nOpenLevel)
						end
					end
				end
			end
			if nTeamID and tTeam then 
				for _, tRole in pairs(tTeam) do
					--策划要求改成，有队伍的情况下，队员属于暂离状态下,队员自己可以发起挑战，归队的情况下必须有队长发起
					if not oRole:IsLeader() then
						if tRole.nRoleID == oRole:GetID() then
							if not tRole.bLeave then
								return oRole:Tips("只有队长才能发起挑战哦")
							end
							local sTips = _EnterDupCheck(tRole)
							if sTips then
								return oRole:Tips(sTips)
							end
							break
						end
					else
						local sTips = _EnterDupCheck(tRole)
						if sTips then
							return oRole:Tips(sTips)
						end
					end
				end
			end
			--TODD,组队副本的时候进行检查
			self:CheckCurrGuanQiaNotChallenge(nGuanQiaID)
		end
		self.m_nCurGuanQia = nGuanQiaID
		local oMonster = goMonsterMgr:CreateInvisibleMonster(nMonConfID)
		oRole:PVE(oMonster, {nBattleDupType=gtBattleDupType.eShenMoZhi, nGuanQiaID=nGuanQiaID})
	end)
end

--TODD,检查是否有玩家未挑战当前关卡
function CShenMoZhi:CheckCurrGuanQiaNotChallenge(nGuanQiaID)
	self.m_bNotChallenge = false
	--防止精确性，取归队玩家的数据
	local fnGetTeamCallBack = function (nTeamID, tTeam)
		if not nTeamID or nTeamID == 0 then
			return 
		end
		for _, tRole in pairs(tTeam) do
			local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
			if not tRole.bLeave and oRole then
				if not oRole.m_oShenMoZhiData:HasPass(nGuanQiaID) then
					self.m_bNotChallenge = true
					break
				end
			end
		end
	end
	local nRoleID = next(self.m_tRoleMap)
	if nRoleID and goPlayerMgr:GetRoleByID(nRoleID) then
		local oRole = goPlayerMgr:GetRoleByID(nRoleID)
		oRole:GetTeam(fnGetTeamCallBack)
	end
end

function CShenMoZhi:HasNoPassPlayer(nGuanQiaID)
	return self.m_bNotChallenge
end

function CShenMoZhi:GetStar(bWin,nRound)
	if not bWin then
		return 0
	end
	local nStar = 1
	if nRound <= 6 then
		nStar = nStar + 1
	end
	if nRound <= 3 then
		nStar = nStar + 1
	end
	return nStar
end

function CShenMoZhi:GetConfigData(nGuanQiaID)
	local tConfig = ctShenMoZhiConf[nGuanQiaID]
	return tConfig
end

--战斗结束
function CShenMoZhi:OnBattleEnd(oLuaObj, tBTRes, tExtData)
	local nGuanQiaID = self.m_nCurGuanQia
	local nObjType = oLuaObj:GetObjType()
	if nObjType == gtGDef.tObjType.eRole and tBTRes.bWin then
		local oRole = oLuaObj
		local nRound = tBTRes.nRound
		local nStar = self:GetStar(true,nRound)
		--if nGuanQiaID and oRole:IsLeader() and self:HasNoPassPlayer(nGuanQiaID) and oRole.m_oShenMoZhiData:HasPass(nGuanQiaID) then
		if nGuanQiaID and self:HasNoPassPlayer(nGuanQiaID) and oRole.m_oShenMoZhiData:HasPass(nGuanQiaID) then
			oRole:GetTeam(function(nTeamID, tTeam)
				if nTeamID > 0 and #tTeam > 1 then
					local sKey = "SmzHelp"
					local nCnt = oRole.m_oTimeData.m_oToday:Query(sKey,0)
					if nCnt < 5 then
						oRole.m_oTimeData.m_oToday:Add(sKey,1)
						local nXiaYi = ctDailyBattleDupConf[gtDailyID.eShenMoZhi].nXiaYiReward
						oRole:AddItem(gtItemType.eCurr, gtCurrType.eChivalry, nXiaYi, "神魔志侠义奖励")
						local nItemID = 11331
						oRole:AddItem(gtItemType.eProp, nItemID, 1, "神魔志侠义奖励")
					end
				end
			end)
		end
		if not oRole.m_oShenMoZhiData:HasPass(nGuanQiaID) then
			self:GiveFirstReward(oRole,nGuanQiaID)
		end
		local nType = ctShenMoZhiConf[nGuanQiaID].nType		
		local nOldStar = oRole.m_oShenMoZhiData:GetChapterStar(nType, ctShenMoZhiConf[nGuanQiaID].nChapter)
		oRole.m_oShenMoZhiData:PassGuanQia(nGuanQiaID,nStar)
		local nNewStar = oRole.m_oShenMoZhiData:GetChapterStar(nType, ctShenMoZhiConf[nGuanQiaID].nChapter)
		oRole.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eShenMoZhi,"神魔志")
		local tData = {tPassMap = {}} --tPassMap:{[nType]=nGuanQiaID}
		assert(nType > 0, "神魔志关卡类型错误, ID: "..nGuanQiaID)
		tData.nType = nType
		tData.tPassMap[nType] = nGuanQiaID
		tData.bIsHearsay = nOldStar ~= nNewStar and true or false
		tData.nChapter = ctShenMoZhiConf[nGuanQiaID].nChapter
		tData.nStar = oRole.m_oShenMoZhiData:GetChapterStar(nType, tData.nChapter)
		CEventHandler:OnCompShenMoZhi(oRole, tData)
	end
end

function CShenMoZhi:GiveFirstReward(oRole,nGuanQiaID)
	local tData = self:GetConfigData(nGuanQiaID)
	local fnRoleExp = tData.fnRoleExpReward
    local fnGold = tData.fnGoldReward
    local fnSilver = tData.fnSilverReward
    local nRoleLevel = oRole:GetLevel()

    local nGold = fnGold(nRoleLevel)
    local nSilver = fnSilver(nRoleLevel)
    local nRoleExp = fnRoleExp(nRoleLevel)
    oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "神魔志奖励")
    oRole:AddItem(gtItemType.eCurr, gtCurrType.eJinBi, nGold, "神魔志奖励")
    oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nSilver, "神魔志奖励")
end