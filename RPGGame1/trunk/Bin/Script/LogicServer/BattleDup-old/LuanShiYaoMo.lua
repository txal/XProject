--乱世妖魔
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLuanShiYaoMo:Ctor(nID, nType)
    print("创建乱世妖魔副本", nID, "类型：", nType)
    self.m_nID = nID
    self.m_nType = nType
    self.m_tDupList = CUtil:WeakTable("v") 	--地图列表{地图对象,...}
	self.m_tRoleMap = CUtil:WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = CUtil:WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...}

	--不保存信息
	self.m_nTotalWeight = 0					--所有奖品池总权重
	self.m_nLastDupMixID = 0
	self:Init()
end

function CLuanShiYaoMo:Init(nID, nType)
    local tConf = ctBattleDupConf[self.m_nType]
	for _, tDup in ipairs(tConf.tDupList) do
		local oDup = goDupMgr:CreateDup(tDup[1])
	    oDup:SetAutoCollected(false) --设置非自动收集
		table.insert(self.m_tDupList, oDup)
	end

	for _, oDup in pairs(self.m_tDupList) do
		oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
		oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
		oDup:RegLeaderActivityCallback(function(oLuaObj, nInactivityTime) self:OnLeaderActivity(oLuaObj, nInactivityTime) end)
		oDup:RegLeaveTeamCallback(function(oLuaObj) self:OnLeaveTeam(oLuaObj) end )
		oDup:RegBattleEndCallback(function(...) self:OnBattleEnd(...) end )
		oDup:RegEnterCheckCallback(function(nRoleID, tRoleParam) return self:OnEnterCheck(nRoleID, tRoleParam) end)
    end
    
    --初始化一个怪物
    self:CreateMonster()
end 

--销毁副本
function CLuanShiYaoMo:Release() 
	print("乱世妖魔副本被销毁", self.m_nID)
	for _, oDup in pairs(self.m_tDupList) do
		goDupMgr:RemoveDup(oDup:GetMixID())
	end
	self.m_tDupList = {}
	self.m_tRoleMap = {}
	self.m_tMonsterMap = {}
end

function CLuanShiYaoMo:GetID() return self.m_nID end --战斗副本ID
function CLuanShiYaoMo:GetType() return self.m_nType end --取副本战斗类型
function CLuanShiYaoMo:GetConf() return ctBattleDupConf[self:GetType()] end
function CLuanShiYaoMo:HasRole() return next(self.m_tRoleMap) end --是否有玩家

--取地图ID
--@nIndex 副本中的第几个地图
function CLuanShiYaoMo:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

--取地图对象
--@nIndex 副本中的第几个地图
function CLuanShiYaoMo:GetDupObj(nIndex)
	return self.m_tDupList[nIndex]
end

--对象进入副本
function CLuanShiYaoMo:OnObjEnter(oLuaObj, bReconnect)
	print("CLuanShiYaoMo:OnObjEnter***", bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj
		self:SyncDupInfo()	--有角色战斗结束后奖励同步

	--人物
	elseif nObjType == gtGDef.tObjType.eRole then
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
		oLuaObj:SetBattleDupID(self:GetID())
		self:SyncDupInfo(oLuaObj)
		--单号：5530 本版改动玩家先进入副本再发起询问组队事宜
		oLuaObj:GetTeam(function(nTeamID, tTeam)
			--队员进来检查一下归队人数，人数足够参数怪物
			if oLuaObj:GetTeamID() > 0 and (not oLuaObj:IsLeader()) then
				return		--队员进入在此return  队长才往下执行
			end

			--判断是不是副本中场景切换
			if self.m_nLastDupMixID ~= 0 then 
				return
			end
			local oRoleCurrDup = oLuaObj:GetCurrDupObj()
			self.m_nLastDupMixID = oRoleCurrDup:GetMixID()

			local sCont = "听说草庙村惨案之后，冤魂难以超生，吸引四方鬼物汇集，为祸一方。我一个人忙不过来，你帮我一把如何？"
			local tOption = {"我来帮你", "便捷组队"}
			local nNpcID = ctDailyActivity[gtDailyID.eLuanShiYaoMo].nID
			local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30, nParam1=nNpcID}
			goClientCall:CallWait("ConfirmRet", function(tData)
				--我来帮你
				local tBattleDupConf = ctBattleDupConf[gtBattleDupType.eLuanShiYaoMo]
				if tData.nSelIdx == 1 then	--我来帮你
					--是队长并且归队的任务至少3个以上开始镇妖
					oLuaObj:GetTeam(function(nTeamID, tTeam)
						local nReturnCount = 0
						if nTeamID > 0 then
							for _, tRole in ipairs(tTeam) do
								if not tRole.bLeave then nReturnCount = nReturnCount+1 end
							end
						end
						if nReturnCount < tBattleDupConf.nTeamMembs then
							--队员小于3人
							local sCont = "此任务需要三人以上队伍，是否加入便捷组队？"
							local tOption = {"取消", "确定"}
							local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10, nTimeOutSelIdx=2}
							goClientCall:CallWait("ConfirmRet", function(tData)
								if tData.nSelIdx == 2 then	
									--确定便捷组队
									if oLuaObj:GetTeamID() <= 0 then	
										oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
										oLuaObj:GetTeam(function(nTeamID, tTeam)
											if nTeamID <= 0 then
												--确定便捷组队，若玩家没有队伍
												oLuaObj:CreateTeam(function(nTeamIDNew, tTeamNew)
													if not nTeamIDNew then
														return oLuaObj:Tips("创建队伍失败")
													else
														oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
														--self:CreateMonster()
													end
												end)
											end
										end)

									else	
										--确定便捷组队，若玩家有队伍
										--查询可不可以合并队伍
										--self:CreateMonster()
										local function CheckCallBack(bCanJoinIn)
											if bCanJoinIn then
												local sCont = "当前有队伍有空位，是否加入队伍呢？"
												local tOption = {"接续匹配", "加入队伍"}
												local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10, nTimeOutSelIdx=1}
												goClientCall:CallWait("ConfirmRet", function(tData)
													if tData.nSelIdx == 1 then		--继续匹配
														oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
													else	--加入队伍
														local function JoinMergeTeamCallBack(bIsMergeSucc)
															if not bIsMergeSucc then
																oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
															end
														end
														Network:RMCall("JoinMergeTeamReq", JoinMergeTeamCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eLuanShiYaoMo)
													end
												end, oLuaObj, tMsg)
											else
												oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
											end
										end
										Network:RMCall("CheckJoinMergeTeamReq", CheckCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eLuanShiYaoMo)										
									end
								else
									oLuaObj:CreateTeam(function(nTeamID, tTeam)
										if not nTeamID then 
											return oRole:Tips("创建队伍失败")
										end
									end)
								end
							end, oLuaObj, tMsg)
						else	--归队任务大于3人开始副本流程
							self.m_bIsAutoMatch = true
							--self:CreateMonster()
						end
					end)
				elseif tData.nSelIdx == 2 then	--便捷组队
					oLuaObj:GetTeam(function(nTeamID, tTeam)
						if nTeamID > 0 then
							--有队伍
							if oLuaObj:IsLeader() then
								--队长
								if #tTeam >= 5 then
									return oLuaObj:Tips("队伍已满员，无需组队")
								else
									--如果是队长队员人数也不够就询问是否合并
									local function CheckCallBack(bCanJoinIn)
										if bCanJoinIn then
											local sCont = "当前有队伍有空位，是否加入队伍呢？"
											local tOption = {"接续匹配", "加入队伍"}
											local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10, nTimeOutSelIdx=1}
											goClientCall:CallWait("ConfirmRet", function(tData)
												if tData.nSelIdx == 1 then		--继续匹配
													oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
												else	--加入队伍
													local function JoinMergeTeamCallBack(bIsMergeSucc)
														if not bIsMergeSucc then
															oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
														end
													end
													Network:RMCall("JoinMergeTeamReq", JoinMergeTeamCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eLuanShiYaoMo)
												end
											end, oLuaObj, tMsg)
										else
											oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
										end
									end
									Network:RMCall("CheckJoinMergeTeamReq", CheckCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eLuanShiYaoMo)		
								end
							else
								--队员
								oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, false)
								oLuaObj:GetTeam(function(nTeamID, tTeam)
									if nTeamID > 0 then
										if tTeam[1].nRoleID ~= oLuaObj:GetID() then
											Network:RMCall("GotoLeader", nil,gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), {nBattleDupType=gtBattleDupType.eLuanShiYaoMo})
										end
									end
								end)
							end
						else
							--没队伍
							oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, false)
							oLuaObj:GetTeam(function(nTeamID, tTeam)
								if nTeamID > 0 then
									if tTeam[1].nRoleID ~= oLuaObj:GetID() then
										Network:RMCall("GotoLeader", nil,gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), {nBattleDupType=gtBattleDupType.eLuanShiYaoMo})
									end
								else
									oLuaObj:CreateTeam(function(nTeamID, tTeam)
										if not nTeamID then 
											return oRole:Tips("创建队伍失败")
										else
											oLuaObj:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, false)
										end

									end)
								end
							end)
						end
					end)
				end
			end, oLuaObj, tMsg)
			
		end)
	end
end

--对象离开副本
function CLuanShiYaoMo:OnObjLeave(oLuaObj, nBattleID)
    print("CLuanShiYaoMo:OnObjLeave***")
    local nObjType = oLuaObj:GetObjType() --gtObjType
    --怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = nil
		local oLeader = self:GetLeader()
		if not oLeader then
			--没有队长，退全部踢出
			for _, oMember in pairs(self.m_tRoleMap) do
				Network:RMCall("LeaveTeamAndKickReq", nil, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID,110), oMember:GetSession(), oMember:GetID())
			end
			return
		else
			local nCompCount = oLeader.m_oDailyActivity.m_tActDataMap[gtDailyID.eLuanShiYaoMo][gtDailyData.eCountComp]
			local nRewardTimes = ctDailyActivity[gtDailyID.eLuanShiYaoMo].nTimesReward
			if (nCompCount+1) < nRewardTimes then		--nCompCount+1:本次是第几次完成 0-9次才刷怪
				self:CreateMonster()
			end 
		end

    --人物
    elseif nObjType == gtGDef.tObjType.eRole then
        if nBattleID > 0 then --如果是战斗离开副本,不用处理
        else
            oLuaObj:SetBattleDupID(0)
            self.m_tRoleMap[oLuaObj:GetID()] = nil
            --所有玩家离开就销毁副本
            -- if not next(self.m_tRoleMap) then
            --     goBattleDupMgr:DestroyBattleDup(self:GetID())
            -- end
        end

    end
end

--离开队伍则退出副本
function CLuanShiYaoMo:OnLeaveTeam(oLuaObj)
	print("CLuanShiYaoMo:OnLeaveTeam***")
	oLuaObj:EnterLastCity()
end

--队长活跃信息事件,30分钟无操作移出
function CLuanShiYaoMo:OnLeaderActivity(oLuaObj, nInactivityTime)
	print("CLuanShiYaoMo:OnLeaderActivity***", nInactivityTime)
	if not oLuaObj:IsLeader() then
		return LuaTrace("队长信息错误", debug.traceback())
	end
	if nInactivityTime >= 30*60 then
		oLuaObj:EnterLastCity()
	end
end

--取队长角色对象
function CLuanShiYaoMo:GetLeader()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsLeader() then
			return oRole
		end
	end
end

--创建怪物
function CLuanShiYaoMo:CreateMonster()
    local tBattleDupConf = self:GetConf()
	local tMonster = tBattleDupConf.tMonster
	local nMonConfID= tMonster[math.random(#tMonster)][1]
	local oDup = self.m_tDupList[math.random(#self.m_tDupList)]

	local tMapConf = oDup:GetMapConf()
	local nPosX = math.random(600, tMapConf.nWidth - 600)	
	local nPosY = math.random(600, tMapConf.nHeight - 600)

	goMonsterMgr:CreateMonster(nMonConfID, oDup:GetMixID(), nPosX, nPosY)
end

--战斗结束
function CLuanShiYaoMo:OnBattleEnd(oLuaObj, tBTRes, tExtData)
	print("CLuanShiYaoMo:OnBattleEnd***")
	local nObjType = oLuaObj:GetObjType() --gtObjType

	if nObjType == gtObjType.eMonster then
		if tBTRes.bWin then --怪物没死亡
			self:SyncDupInfo()
		end

	elseif nObjType == gtGDef.tObjType.eRole and tBTRes.bWin then
		--判断奖励次数，奖励活跃值
		local nCompCount = oLuaObj.m_oDailyActivity.m_tActDataMap[gtDailyID.eLuanShiYaoMo][gtDailyData.eCountComp]
		local nRewardTimes = ctDailyActivity[gtDailyID.eLuanShiYaoMo].nTimesReward
		if nCompCount < nRewardTimes then
			oLuaObj.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eLuanShiYaoMo, "乱世妖魔奖励活跃")
			self:BattleDupReward(oLuaObj, tExtData)
			self:SyncDupInfo(oLuaObj)	
			
			--检查如果是队长加侠义值
			if oLuaObj:IsLeader() then
				local nRandNum = math.random(1, 100)
				if nRandNum <= ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nRewardXiaYiPer then
					oLuaObj:GetTeam(function(nTeamID, tTeam)
						--计算等级加侠义值
						if nTeamID > 0 and #tTeam > 1 then  --除了自己还有其他人
							local nNum = 0
							for _, tRole in pairs(tTeam) do
								local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
								if oRole then
									if oLuaObj:GetLevel() - oRole:GetLevel() > 10 then
										nNum = nNum + 1
									end
								end
							end
							local nXiaYi = nNum * ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nXiaYiReward
							oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.eChivalry, nXiaYi, "乱世妖魔侠义奖励")
						end

					end)
				end
				-- if nCompCount+1 >= nRewardTimes then				--nCompCount+1完成一次+1
				-- 	Network:RMCall("LeaveTeamAndKickReq", nil, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID,110), oLuaObj:GetSession(), oLuaObj:GetID())
				-- end
			end
		else
			oLuaObj.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eLuanShiYaoMo, "乱世妖魔奖励活跃")
			self:BattleDupReward(oLuaObj)
			self:SyncDupInfo(oLuaObj)	
			-- CEventHandler:OnCompLuanShiYaoMo(oLuaObj, {})
			oLuaObj:Tips("今天击杀乱世妖魔的怪物数量已达到上限，继续参与将没有收益")
			if oLuaObj:IsLeader() then		--有可能作为队员参加，在副本里面被提升为队长
				local nCompTimes = oLuaObj.m_oDailyActivity.m_tActDataMap[gtDailyID.eLuanShiYaoMo][gtDailyData.eCountComp]
				if nCompTimes >= nRewardTimes then
					Network:RMCall("LeaveTeamAndKickReq", nil, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID,110), oLuaObj:GetSession(), oLuaObj:GetID())
				end
			end
			return 
		end
		CEventHandler:OnCompLuanShiYaoMo(oLuaObj, {})
		if oLuaObj:GetTeamID() <=  0 then
			oLuaObj:EnterLastCity()
		end

	end
end

function CLuanShiYaoMo:OnEnterCheck(nRoleID, tRoleParam)
	--检查能不能进入副本
	-- if tRoleParam.nTeamID <= 0 then
	-- 	return false
	-- end
	return true
end

--取会话列表
function CLuanShiYaoMo:GetSessionList()
	local tSessionList = {}
	for _, oRole in pairs(self.m_tRoleMap) do
		if not oRole:IsRobot() and oRole:IsOnline() then
			table.insert(tSessionList, oRole:GetServer())
			table.insert(tSessionList, oRole:GetSession())
		end
	end
	return tSessionList
end

--同步场景信息
function CLuanShiYaoMo:SyncDupInfo(oRole)
	local tMsg = {tMonster={nDupMixID=0, nDupID=0, nMonObjID=0, nMonsterPosX=0, nMonsterPosY=0, nMonsterConfID=0}, tDupList={}}
	local nMonsterID = next(self.m_tMonsterMap)
	local oMonster = self.m_tMonsterMap[nMonsterID]
	if oMonster then
		tMsg.tMonster.nMonObjID = oMonster:GetID()
		local oDup = oMonster:GetDupObj()
		tMsg.tMonster.nDupMixID = oDup:GetMixID()
		tMsg.tMonster.nDupID = oDup:GetDupID()
		tMsg.tMonster.nMonsterPosX, tMsg.tMonster.nMonsterPosY = oMonster:GetPos()
		tMsg.tMonster.nMonsterConfID = oMonster:GetConfID()
	end
	for _, oDup in ipairs(self.m_tDupList) do
		table.insert(tMsg.tDupList, {nDupMixID=oDup:GetMixID(), nDupID=oDup:GetDupID()})
	end
	if oRole then
		tMsg.nCompTimes = oRole.m_oDailyActivity:GetRecData(gtDailyID.eLuanShiYaoMo)[gtDailyData.eCountComp]		
		oRole:SendMsg("BattleDupInfoRet", tMsg)
	else
		for nIndex, oRole in pairs(self.m_tRoleMap) do
			tMsg.nCompTimes = oRole.m_oDailyActivity:GetRecData(gtDailyID.eLuanShiYaoMo)[gtDailyData.eCountComp] 
			oRole:SendMsg("BattleDupInfoRet", tMsg)
		end
		-- local tSessionList = self:GetSessionList()
		-- Network.PBBroadcastExter("BattleDupInfoRet", tSessionList, tMsg)
	end
	--PrintTable(tMsg)
end

--点击怪物
function CLuanShiYaoMo:TouchMonsterReq(oRole, nMonObjID)
	local oMonster = self.m_tMonsterMap[nMonObjID]
	if not oMonster then
		return oRole:Tips("怪物不存在")
	end

	local tBattleDupConf = self:GetConf()
	oRole:GetTeam(function(nTeamID, tTeam)
		if nTeamID <= 0 then
			-- return oRole:Tips("请先组队伍")
			local _fnCreateTeam = function ()
				oRole:CreateTeam(function(nTeamIDNew, tTeamNew)
					if not nTeamIDNew then
						return oLuaObj:Tips("创建队伍失败")
					else
						oRole:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
					end
				end)
			end

			if tBattleDupConf.nTeamMembs > 1 then
				local sCont = string.format("此任务需要%d人以上队伍，是否加入便捷组队？", tBattleDupConf.nTeamMembs)
				local tOption = {"取消", "确定"}
				local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10, nTimeOutSelIdx=2}
				goClientCall:CallWait("ConfirmRet", function(tData)
					if tData.nSelIdx == 2 then
						_fnCreateTeam()
					end
				end, oRole,tMsg)
			else
				_fnCreateTeam()
			end
		else
			if not oRole:IsLeader() then
				return oRole:Tips("队长才能发起攻击")
			end

			local nMonsterConfID = oMonster:GetConfID()
			local sCont = "破坏……混乱……鲜血……哈哈哈，我们最爱的乱世！"
			local tOption = {"进入战斗", "快捷组队", "暂时撤退"}
			local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=20, nParam1=nMonsterConfID, nTimeOutSelIdx=1}

			goClientCall:CallWait("ConfirmRet", function(tData)
				if tData.nSelIdx == 1 then	--进入战斗
					local nReturnCount = 0
					for _, tRole in pairs(tTeam) do
						if not tRole.bLeave then nReturnCount = nReturnCount+1 end
					end
			
					if nReturnCount < tBattleDupConf.nTeamMembs then
						-- local sStr = string.format("归队人数不足%d人，不能挑战怪物", tBattleDupConf.nTeamMembs)
						-- return oRole:Tips(sStr)
						local sCont = string.format("归队人数未达%d人，是否便捷组队？", tBattleDupConf.nTeamMembs)
						local tOption = {"取消", "确定"}
						local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10}
						goClientCall:CallWait("ConfirmRet", function(tData)
							if tData.nSelIdx == 2 then
								oRole:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, true)
								return
							end
						end, oRole, tMsg)
					else
						--检查人员等级
						local bAllCanJoin = true
						--local nLevelLimit = ctBattleDupConf[gtBattleDupType.eLuanShiYaoMo].nAccpLimit
						local sStr = ""
						for _, tRole in pairs(tTeam) do 
							local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
							if oRole then
								--TODO
							end
						end
						-- if not bAllCanJoin then
						-- 	return oRole:Tips(sStr.."未能参加活动")				
						-- end

						if tTeam[1].nRoleID ~= oRole:GetID() then
							return oRole:Tips("队长才能发起攻击")
						else
							local nCompCount = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eLuanShiYaoMo][gtDailyData.eCountComp]
							local nRewardTimes = ctDailyActivity[gtDailyID.eLuanShiYaoMo].nTimesReward
							if nCompCount >= nRewardTimes then
								return oRole:Tips("你今天允许挑战次数已用完")
							end
						end

						local tBattleDupConf = self:GetConf()
						local nReturnCount = 0
						for _, tRole in pairs(tTeam) do
							if not tRole.bLeave then nReturnCount = nReturnCount+1 end
						end
						--分析队伍成员是否存在夫妻，结拜，情人等关系，用于传入结算奖励
						local bHadLoverRela = false
						local bHadBrotherRela = false
						local bHadCoupleRela = false
						local bHadShiTuRela = false
						local bHadXinHunBuff = false
						for nKey = 1, nReturnCount-1 do
							for nNext = nKey+1, nReturnCount do
								local nRoleID = tTeam[nKey].nRoleID
								local oRole = goPlayerMgr:GetRoleByID(nRoleID)
								if oRole then
									local nNextRoleID = tTeam[nNext].nRoleID
									if oRole:IsLover(nNextRoleID) then		--情缘关系
										bHadLoverRela = true
									end
									if oRole:IsBrother(nNextRoleID) then		--结拜关系
										bHadBrotherRela = true
									end
									if oRole:IsSpouse(nNextRoleID) then				--夫妻关系
										bHadCoupleRela = true
									end
									if oRole:IsMentorship(nNextRoleID) then				--师徒关系
										bHadShiTuRela = true
									end
								end
								if bHadLoverRela and bHadBrotherRela  and bHadCoupleRela and bHadShiTuRela then
									break
								end
							end
						end

						local tExData = 
						{
							nMemberNum=nReturnCount, 
							nBattleDupType=gtBattleDupType.eLuanShiYaoMo, 
							bHadLoverRela=bHadLoverRela,
							bHadBrotherRela = bHadBrotherRela,
							bHadCoupleRela = bHadCoupleRela,
							bHadShiTuRela = bHadShiTuRela,
						}
						oRole:PVE(oMonster, tExData)
					end
				elseif tData.nSelIdx == 2 then	--便捷组队
					local tBattleDupConf = ctBattleDupConf[gtBattleDupType.eXinMoQinShi]
					oRole:GetTeam(function(nTeamID, tTeam)
						if nTeamID > 0 then
							--有队伍
							if oRole:IsLeader() then
								--队长
								if #tTeam >= 5 then
									return oRole:Tips("队伍已满员，无需组队")
								else
									oRole:MatchTeam(gtBattleDupType.eLuanShiYaoMo, tBattleDupConf.sName, false)
								end
							end
						end
					end)		
				else
					return	--暂时退避
				end 
			end, oRole, tMsg)
		end
	end)
end

--进入副本请求,可能会切换服务进程(这时未创建副本)
function CLuanShiYaoMo:EnterBattleDupReq(oRole)
	local oDup = oRole:GetCurrDupObj()
	if oDup:GetConf().nBattleType == gtBattleDupType.eLuanShiYaoMo then
		return oRole:Tips("已经在乱世副本中")
	end
	
	local function EnterFB(nDupMixID)
		local tConf = assert(ctDupConf[CUtil:GetDupID(nDupMixID)])
		oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
	end
	goBattleDupMgr:CreateBattleDup(gtBattleDupType.eLuanShiYaoMo, EnterFB)
end

function CLuanShiYaoMo:BattleDupReward(oRole, tExData)
	--判断
	if not oRole then return end
	local nTotalComp = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eLuanShiYaoMo][gtDailyData.eCountComp]
	if nTotalComp <= 0 then return end
	local nRewardLimit = ctDailyActivity[gtDailyID.eLuanShiYaoMo].nTimesReward
	if nTotalComp >= nRewardLimit then
		return oRole:Tips("您今天已击杀10个乱世妖魔，无法获得奖励")
	end

	--经验奖励
	local fnRoleExp = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].fnRoleExpReward
	local fnPetExp = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].fnPetExpReward
	local fnSilver = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].fnSilverReward
	local nTemp = nTotalComp % 10
	local nHuanShu = nTemp ~= 0 and nTemp or 10
	local nRoleLevel = oRole:GetLevel()
	local nRoleExp = fnRoleExp(nRoleLevel, nHuanShu)
	local nPetExp = fnPetExp(nRoleLevel, nHuanShu)
	local nSilverNum = fnSilver(gnSilverRatio, nHuanShu, nRoleLevel)
	local nGoleNum = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nGoldReward

	local nShuangBeiAdded = 0
	local nLeaderAdded = 0
	local nRelaAdded = 0
	local nShouHuAdded = 0
	local nXinHunAdded = 0

	local nCompCount = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eLuanShiYaoMo][gtDailyData.eCountComp]
	local nRewardTimes = ctDailyActivity[gtDailyID.eLuanShiYaoMo].nTimesReward	

	if oRole:IsLeader() then
		nLeaderAdded = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nDuiZhang
	end

	local nQingYuanAdd = 0
	local nJieYiAdd = 0
	local nCoupleAdd = 0
	local nShiTuAdd = 0
	local nXinHunAdd = 0

	local nTeamMember = oRole:GetTeamNum()	
	if tExData.bHadLoverRela then
		nQingYuanAdd = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nQingYuan or 0
	end
	if tExData.bHadBrotherRela then
		nJieYiAdd = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nJieYi
	end
	if tExData.bHadCoupleRela then
		nCoupleAdd = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nCouple
	end
	if tExData.bHadShiTuRela then
		nShiTuAdd = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nShiTu
	end

	if oRole.m_oRoleState:IsMarriageBlessEffectActive() then
		nXinHunAdd = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nXinHun
	end

	nRelaAdded = nJieYiAdd > nShiTuAdd and nJieYiAdd or nShiTuAdd
	nRelaAdded = nRelaAdded > nQingYuanAdd and nRelaAdded or nQingYuanAdd
	nRelaAdded = nRelaAdded > nCoupleAdd and nRelaAdded or nCoupleAdd
	nRelaAdded = nRelaAdded > nXinHunAdd and nRelaAdded or nXinHunAdd
	--print(">>>>>>>>>>>>>>关系加成", nRelaAdded)

	--单号：5358
	--3.结婚后7天内，夫妻双方获得“新婚祝福”的buff（暂定编号621），当夫妻2人在同一个队伍并且完成部分玩法时（镇妖、神魔志（精英、英雄），乱世、心魔、九霄、混沌），则整个队伍的玩家也可以获得经验加成
	--有奖励环数内和无奖励环数的经验等奖励
	local nFinalRoleExp = 0
	local nFinalPetExp = 0
	local nFinalYinYuan = 0

	nFinalRoleExp = nRoleExp * ((100 + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded + 100)/100) * (50+nTeamMember * 10) / 100		--双倍奖励
	nFinalPetExp = nPetExp * ((100 + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded + 100)/100) * (50+nTeamMember * 10) / 100
	nFinalYinYuan = nSilverNum
	
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nFinalRoleExp, "乱世妖魔副本奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nFinalPetExp, "乱世妖魔副本奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nFinalYinYuan, "乱世妖魔副本奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eJinBi, nGoleNum, "乱世妖魔副本奖励")	

	--有机率奖励物品
	local nRandNum = math.random(1, 100)
	if nRandNum <= ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].nRewardItemPer then
		local tRewardPool = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].tItemAward
		local function GetAwardPoolWeight(tNode)
			return tNode[1]
		end
		local tAwardPool = CWeightRandom:Random(tRewardPool, GetAwardPoolWeight, 1, false)
		local tRewardItemList = ctAwardPoolConf.GetPool(tAwardPool[1][2], nRoleLevel, oRole:GetConfID())

		local function GetItemWeight(tNode)
			return tNode.nWeight
		end
		local tRewardItem = CWeightRandom:Random(tRewardItemList, GetItemWeight, 1, false)
		assert(next(tRewardItem), "没有奖励物品")
		oRole:AddItem(gtItemType.eProp, tRewardItem[1].nItemID, tRewardItem[1].nItemNum, "乱世妖魔奖励")

		--传闻
		-- local tData = {}
		-- tData.bIsHearsay = true
		-- tData.nItemID = tRewardItem[1].nItemID
		-- CEventHandler:OnCompLuanShiYaoMo(oRole, tData) --?? wtf??

		local nAddItemID = tRewardItem[1].nItemID
		local sRoleName = oRole:GetName()
		local tHearsayConf = ctHearsayConf["fbluanshidrop"]
		assert(tHearsayConf, "没有传闻配置")
		for _, tHearsayCond in pairs(tHearsayConf.tParam) do
			if nAddItemID== tHearsayCond[1] then
				local sCont = string.format(tHearsayConf.sHearsay, sRoleName, ctPropConf[nAddItemID].sName)
				CUtil:SendHearsayMsg(sCont)
			end
		end
	end
end

function CLuanShiYaoMo:CalAwardWeight()
	local tRewardPool = ctDailyBattleDupConf[gtDailyID.eLuanShiYaoMo].tItemAward
	for key, tItemPool in pairs(tRewardPool) do 
		self.m_nTotalWeight = self.m_nTotalWeight + tItemPool[1]
	end
end
