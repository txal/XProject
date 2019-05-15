--镇妖
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CZhenYao.tOpera = 
{
	eAllInfoReq = 1,
	eUseShuangBei = 2, 		--领取(用于消耗)
	eUnuseShuangBei = 3,	--冻结(储存)
	eAutoMacthing = 4,		--自动匹配
}

function CZhenYao:Ctor(nID, nType)
	print("创建镇妖副本", nID)
	self.m_nID = nID 						--战斗副本ID
	self.m_nType = nType 					--副本战斗类型
	self.m_tDupList = GF.WeakTable("v") 	--地图列表{地图对象,...}
	self.m_tRoleMap = GF.WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = GF.WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...}

	self.m_nAfterBattleTimer = 0			--战斗结束后时间计时器

	--不保存信息
	self:Init()
	self.m_nTotalWeight = 0					--所有奖品池总权重
	self.m_bSomeOneBecomeLeader = false		--是否有某人申请成为队长
	self.m_nLeaderID = 0					--队长ID
	self.m_bLeaderLeave = false				--是否是队长离开
	self.m_bIsAutoMatch = false				--是否自动匹配
	self.m_nLastDupMixID = 0				--上次的场景ID
	self.m_bIsTipsTouchMonster = false		--是否提示开始攻击怪物
	self:CalAwardWeight()
end

--初始化副本
function CZhenYao:Init()
	local tConf = ctBattleDupConf[self.m_nType]
	for _, tDup in ipairs(tConf.tDupList) do
		local oDup = goDupMgr:CreateDup(tDup[1])
	    oDup:SetAutoCollected(false) --设置非自动收集
		table.insert(self.m_tDupList, oDup)
	end
	for _, oDup in pairs(self.m_tDupList) do
		oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
		oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
		oDup:RegLeaderActivityCallback(function(oLuaObj, nLastPacketTime) self:OnLeaderActivity(oLuaObj, nLastPacketTime) end)
		oDup:RegLeaveTeamCallback(function(oLuaObj) self:OnLeaveTeam(oLuaObj) end )
		oDup:RegBattleEndCallback(function(...) self:OnBattleEnd(...) end )
		oDup:RegTeamChangeCallback(function(oLuaObj) self:OnTeamChange(oLuaObj) end)
		oDup:RegEnterCheckCallback(function(nRoleID, tRoleParam) return self:OnEnterCheck(nRoleID, tRoleParam) end)
		--oDup:RegObjAfterEnterCallback(function(oLuaObj) self:OnObjAfterEnter(oLuaObj) end)
	end
	--self:RegActTimer()	
end

--销毁副本
function CZhenYao:OnRelease() 
	print("镇妖副本被销毁", self.m_nID)
	for _, oDup in pairs(self.m_tDupList) do
		goDupMgr:RemoveDup(oDup:GetMixID())
	end
	self.m_tDupList = {}
	self.m_tRoleMap = {}
	self.m_tMonsterMap = {}
	goTimerMgr:Clear(self.m_nAfterBattleTimer)
	self.m_nAfterBattleTimer = nil
end

function CZhenYao:GetID() return self.m_nID end --战斗副本ID
function CZhenYao:GetType() return self.m_nType end --取副本战斗类型
function CZhenYao:GetConf() return ctBattleDupConf[self:GetType()] end
function CZhenYao:HasRole() return next(self.m_tRoleMap) end --是否有玩家

function CZhenYao:RegActTimer()
	goTimerMgr:Clear(self.m_nAfterBattleTimer)
	self.m_nAfterBattleTimer = goTimerMgr:Interval(60, function() self:CheckLeaderIsBattle() end)
end

function CZhenYao:CheckLeaderIsBattle()
	local oLeader = self:GetLeader()
	if oLeader then
		if not oLeader:IsInBattle() then
			goRemoteCall:Call("LeaveTeamAndKickReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID,110), oLeader:GetSession(), oLeader:GetID())
		end
	else
		--没找到队长，先清空计时器
		goTimerMgr:Clear(self.m_nAfterBattleTimer)
	end
end

--取地图ID
--@nIndex 副本中的第几个地图
function CZhenYao:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

--取地图对象
--@nIndex 副本中的第几个地图
function CZhenYao:GetDupObj(nIndex)
	return self.m_tDupList[nIndex]
end

--对象进入副本
function CZhenYao:OnObjEnter(oLuaObj, bReconnect)
	print("CZhenYao:OnObjEnter***", bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj
		self:SyncDupInfo()

	--人物
	elseif nObjType == gtObjType.eRole then
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
		oLuaObj.m_oDrawSpirit:SetTriggerLevelMax()
		oLuaObj:SetBattleDupID(self:GetID())
		self:SyncDupInfo(oLuaObj)

		--单号：5530 本版改动玩家先进入副本再发起询问组队事宜
		--当机器人进入场景时还没有进入队伍不会往下执行
		oLuaObj:GetTeam(function(nTeamID, tTeam)
			--队员进来检查一下归队人数，人数足够参数怪物
			 if nTeamID > 0 and (not oLuaObj:IsLeader()) then
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
			local nNpcID = ctDailyActivity[gtDailyID.eZhenYao].nID
			local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30, nParam1=nNpcID}
			goClientCall:CallWait("ConfirmRet", function(tData)
				--我来帮你
				local tBattleDupConf = ctBattleDupConf[gtBattleDupType.eZhenYao]
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
										oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
										oLuaObj:GetTeam(function(nTeamID, tTeam)
											if nTeamID <= 0 then
												--确定便捷组队，若玩家没有队伍
												oLuaObj:CreateTeam(function(nTeamIDNew, tTeamNew)
													if not nTeamIDNew then
														return oLuaObj:Tips("创建队伍失败")
													else
														oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
														self:CreateMonsterReq(oLuaObj)
													end
												end)
											end
										end)

									else	
										--确定便捷组队，若玩家有队伍
										--查询可不可以合并队伍
										self:CreateMonsterReq(oLuaObj)
										local function CheckCallBack(bCanJoinIn)
											if bCanJoinIn then
												local sCont = "当前有队伍有空位，是否加入队伍呢？"
												local tOption = {"接续匹配", "加入队伍"}
												local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10, nTimeOutSelIdx=1}
												goClientCall:CallWait("ConfirmRet", function(tData)
													if tData.nSelIdx == 1 then		--继续匹配
														oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
													else	--加入队伍
														local function JoinMergeTeamCallBack(bIsMergeSucc)
															if not bIsMergeSucc then
																oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
															end
														end
														goRemoteCall:CallWait("JoinMergeTeamReq", JoinMergeTeamCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eZhenYao)
													end
												end, oLuaObj, tMsg)
											else
												oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
											end
										end
										goRemoteCall:CallWait("CheckJoinMergeTeamReq", CheckCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eZhenYao)										
									end
								else
									oLuaObj:CreateTeam(function(nTeamID, tTeam)
										if not nTeamID then 
											return oRole:Tips("创建队伍失败")
										else
											self:CreateMonsterReq(oLuaObj)
										end
									end)
								end
							end, oLuaObj, tMsg)
						else	--归队任务大于3人开始副本流程
							self.m_bIsAutoMatch = true
							self:CreateMonsterReq(oLuaObj)
						end
					end)
				elseif tData.nSelIdx == 2 then	--便捷组队
					--[[oLuaObj:GetTeam(function(nTeamID, tTeam)
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
													oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
												else	--加入队伍
													local function JoinMergeTeamCallBack(bIsMergeSucc)
														if not bIsMergeSucc then
															oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
														end
													end
													goRemoteCall:CallWait("JoinMergeTeamReq", JoinMergeTeamCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eZhenYao)
												end
											end, oLuaObj, tMsg)
										else
											oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
										end
									end
									goRemoteCall:CallWait("CheckJoinMergeTeamReq", CheckCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eZhenYao)										
									--oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
								end
								self:CreateMonsterReq(oLuaObj)
							else
								--队员
								oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, false)
								oLuaObj:GetTeam(function(nTeamID, tTeam)
									if nTeamID > 0 then
										if tTeam[1].nRoleID ~= oLuaObj:GetID() then
											goRemoteCall:Call("GotoLeader",gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), {nBattleDupType=gtBattleDupType.eZhenYao})
										end
									end
								end)
							end
						else
							--没队伍
							oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, false)
							oLuaObj:GetTeam(function(nTeamID, tTeam)
								if nTeamID > 0 then
									if tTeam[1].nRoleID ~= oLuaObj:GetID() then
										goRemoteCall:Call("GotoLeader",gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), {nBattleDupType=gtBattleDupType.eZhenYao})
									end
								else
									oLuaObj:CreateTeam(function(nTeamID, tTeam)
										if not nTeamID then 
											return oRole:Tips("创建队伍失败")
										else
											self:CreateMonsterReq(oLuaObj)
											oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, false)
										end

									end)
								end
							end)
						end
					end)]]
					self:MatchTeamReq(oLuaObj)
				end
			end, oLuaObj, tMsg)
			
		end)
	end
end


function CZhenYao:MatchTeamReq(oLuaObj)
	assert(oLuaObj, "参数错误")
	local tBattleDupConf = ctBattleDupConf[gtBattleDupType.eZhenYao]
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
									oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
								else	--加入队伍
									local function JoinMergeTeamCallBack(bIsMergeSucc)
										if not bIsMergeSucc then
											oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
										end
									end
									goRemoteCall:CallWait("JoinMergeTeamReq", JoinMergeTeamCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eZhenYao)
								end
							end, oLuaObj, tMsg)
						else
							oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
						end
					end
					goRemoteCall:CallWait("CheckJoinMergeTeamReq", CheckCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eZhenYao)										
					--oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
				end
				self:CreateMonsterReq(oLuaObj)
			else
				--队员
				oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, false)
				oLuaObj:GetTeam(function(nTeamID, tTeam)
					if nTeamID > 0 then
						if tTeam[1].nRoleID ~= oLuaObj:GetID() then
							goRemoteCall:Call("GotoLeader",gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), {nBattleDupType=gtBattleDupType.eZhenYao})
						end
					end
				end)
			end
		else
			--没队伍
			oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, false)
			oLuaObj:GetTeam(function(nTeamID, tTeam)
				if nTeamID > 0 then
					if tTeam[1].nRoleID ~= oLuaObj:GetID() then
						goRemoteCall:Call("GotoLeader",gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), {nBattleDupType=gtBattleDupType.eZhenYao})
					end
				else
					oLuaObj:CreateTeam(function(nTeamID, tTeam)
						if not nTeamID then 
							return oRole:Tips("创建队伍失败")
						else
							self:CreateMonsterReq(oLuaObj)
							oLuaObj:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, false)
						end

					end)
				end
			end)
		end
	end)
end

--对象离开副本
function CZhenYao:OnObjLeave(oLuaObj, nBattleID)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = nil
		local oRole = self:GetLeader()
		if not oRole then
			--没有队长全部踢出副本
			--return LuaTrace("队长不存在")
			for _, oMember in pairs(self.m_tRoleMap) do
				goRemoteCall:Call("LeaveTeamAndKickReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID,110), oMember:GetSession(), oMember:GetID())
			end
			return
		else
			self:CreateMonsterReq(oRole)
		end

	--人物
	elseif nObjType == gtObjType.eRole then
		--如果是战斗离开副本,不用处理
		if nBattleID > 0 then

		else
			-- if oLuaObj:IsLeader() then
			-- 	goRemoteCall:Call("CancelTeamMatch", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), gtBattleDupType.eZhenYao)
			-- end
			oLuaObj:SetBattleDupID(0)
			self.m_tRoleMap[oLuaObj:GetID()] = nil
			--所有玩家离开就销毁副本
			-- if not next(self.m_tRoleMap) then
			-- 	goBattleDupMgr:DestroyBattleDup(self:GetID())
			-- end
		end

	end

end

--离开队伍则退出副本
function CZhenYao:OnLeaveTeam(oLuaObj)
	print("CZhenYao:OnLeaveTeam***")
	if oLuaObj:GetID() == self.m_nLeaderID then
		self.m_bLeaderLeave = true
	end
	--oLuaObj:EnterLastCity()
	if goFBTransitScene then
		goFBTransitScene:EnterFBTransitScene(oLuaObj)
	else
		local function CallBack(nMixID, nDupID)
			assert(ctDupConf[nDupID], "没有此场景配置")
			local tBornPos = ctDupConf[nDupID].tBorn[1]
			local nFace = ctDupConf[nDupID].nFace
			oLuaObj:EnterScene(nMixID, tBornPos[1],  tBornPos[2], -1, nFace)
		end
		goRemoteCall:CallWait("GetFBTransitSceneMixID", CallBack, oLuaObj:GetStayServer(), 101, oLuaObj:GetSession())
	end
end

--队长活跃信息事件
function CZhenYao:OnLeaderActivity(oLuaObj, nInactivityTime)
	-- do something
end

function CZhenYao:OnTeamChange(oLuaObj)
	-- do something
end

function CZhenYao:OnEnterCheck(nRoleID, tRoleParam)
	--检查能不能进入副本
	-- if tRoleParam.nTeamID <= 0 then
	-- 	return false
	-- end
	return true
end

--取队长角色对象
function CZhenYao:GetLeader()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsLeader() then
			return oRole
		end
	end
end

--战斗结束
function CZhenYao:OnBattleEnd(oLuaObj, tBTRes, tExtData)
	local nObjType = oLuaObj:GetObjType() --gtObjType

	self.m_nLeaveBattleTimeStamp = os.time()
	if nObjType == gtObjType.eMonster then
		if tBTRes.bWin then --怪物没死亡
			--怪物没死发送协议
			self:SyncDupInfo()
			--self:RegActTimer()	
		end
		
	elseif nObjType == gtObjType.eRole and tBTRes.bWin then
		if oLuaObj:IsLeader() then
			--self:RegActTimer()			--60秒检查，是否进入下一场战斗		
		end
		--判断奖励次数，奖励活跃值
		oLuaObj:PushAchieve("镇妖次数",{nValue = 1})
		local nCompCount = oLuaObj.m_oDailyActivity.m_tActDataMap[gtDailyID.eZhenYao][gtDailyData.eCountComp]
		local nRewardTimes = ctDailyActivity[gtDailyID.eZhenYao].nTimesReward	
		if nCompCount < nRewardTimes then
			oLuaObj.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eZhenYao, "镇妖奖励活跃")			
			self:BattleDupReward(oLuaObj, tExtData)
			self:SyncDupInfo(oLuaObj)
		else
			self:BattleDupReward(oLuaObj, tExtData)		--50次以后也有奖励经验等
			CEventHandler:OnCompZhenYao(oLuaObj, {})
			oLuaObj.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eZhenYao, "完成镇妖")	
			self:SyncDupInfo(oLuaObj)			
			return --oLuaObj:Tips("您今天已完成"..nRewardTimes.."，无法获得奖励")
		end

		--检查如果是队长加侠义值
		if oLuaObj:IsLeader() then
			local nRandNum = math.random(1, 100)
			if nRandNum <= ctDailyBattleDupConf[gtDailyID.eZhenYao].nRewardXiaYiPer then
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
						local nXiaYi = nNum * ctDailyBattleDupConf[gtDailyID.eZhenYao].nXiaYiReward
						oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.eChivalry, nXiaYi, "镇妖侠义奖励")
					end
				end)
			end
		end
	end
end

--取会话列表
function CZhenYao:GetSessionList()
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
function CZhenYao:SyncDupInfo(oRole)
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
		tMsg.nCompTimes = oRole.m_oDailyActivity:GetRecData(gtDailyID.eZhenYao)[gtDailyData.eCountComp]
		oRole:SendMsg("BattleDupInfoRet", tMsg)
	else
		for nIndex, oRole in pairs(self.m_tRoleMap) do
			tMsg.nCompTimes = oRole.m_oDailyActivity:GetRecData(gtDailyID.eZhenYao)[gtDailyData.eCountComp] 
			oRole:SendMsg("BattleDupInfoRet", tMsg)
		end
	end
	--PrintTable(tMsg)
end

--创建怪物
function CZhenYao:CreateMonsterReq(oRole)
	print("CZhenYao:CreateMonsterReq***")
	
	local oLeader = oRole
	if not oRole:IsLeader() then
		--return oRole:Tips("队长才能操作")
		oLeader = self:GetLeader()
		if not oLeader then
			for _, oMember in pairs(self.m_tRoleMap) do
				goRemoteCall:Call("LeaveTeamAndKickReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID,110), oMember:GetSession(), oMember:GetID())
			end
			return
		end
	end
	if next(self.m_tMonsterMap) then
		return oLeader:Tips("怪物已经出现")
	end
	
	local tBattleDupConf = self:GetConf()
	local tMonster = tBattleDupConf.tMonster
	local nMonConfID= tMonster[math.random(#tMonster)][1]
	local oDup = self.m_tDupList[math.random(#self.m_tDupList)]
	local nRolePosX, nRolePosY = oLeader:GetPos()
	local nRoleDupMixID = oLeader:GetDupMixID()
	local bIsSameDup = oDup:GetMixID() == nRoleDupMixID and true or false
	local nTargetDupID = oDup:GetDupID()
	local nPointType = tBattleDupConf.nPointType
	local nPosX	
	local nPosY
	local tPosPool = ctRandomPoint.GetPool(nPointType, oLeader:GetLevel())
	assert(next(tPosPool), "镇妖怪物随机坐标点为空")
	local tMapPosPool = {}
	for _, tConf in pairs(tPosPool) do			--抽某地图的随机点
		if tConf.nDupID == nTargetDupID then
			table.insert(tMapPosPool, tConf)
		end
	end
	local function GetPosWeight(tNode)
		return 1
	end
	for i=1, 50 do
		local tPosConfList = CWeightRandom:Random(tMapPosPool, GetPosWeight, 1, false)
		nPosX = tPosConfList[1].tPos[1][1]	
		nPosY = tPosConfList[1].tPos[1][2]
		local nDisX = math.abs(nRolePosX - nPosX)
		local nDisY = math.abs(nRolePosY - nPosY)
		if not bIsSameDup then break end --不同场景不用判断距离
		if nDisX^2 + nDisY^2 > 200^2 then break end
	end
	goMonsterMgr:CreateMonster(nMonConfID, oDup:GetMixID(), nPosX, nPosY)
	oLeader:Tips(string.format("鬼物出现在%s！", oDup:GetName()))
end

--攻击怪物
function CZhenYao:TouchMonsterReq(oRole, nMonObjID)
	local oMonster = self.m_tMonsterMap[nMonObjID]
	if not oMonster then
		return oRole:Tips("怪物不存在")
	end

	oRole:GetTeam(function(nTeamID, tTeam)
		if nTeamID <= 0 then
			return oRole:Tips("请先组队伍")
		end

		-- --检查人员等级
		-- local bAllCanJoin = true
		-- local nLevelLimit = ctDailyBattleDupConf[gtBattleDupType.eZhenYao].nAccpLimit
		-- local sStr = ""
		-- for _, tRole in pairs(tTeam) do 
		-- 	local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
		-- 	if oRole then
		-- 		if oRole.m_nLevel < nLevelLimit then
		-- 			sStr = sStr .. oRole.m_sName .. ", "
		-- 			bAllCanJoin = false
		-- 		end
		-- 	end
		-- end
		-- if not bAllCanJoin then
		-- 	return oRole:Tips(sStr.."等级不足"..nLevelLimit.."级")				
		-- end

		if tTeam[1].nRoleID ~= oRole:GetID() then
			return oRole:Tips("队长才能攻击")
		end

		local tBattleDupConf = self:GetConf()
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
					oRole:MatchTeam(gtBattleDupType.eZhenYao, tBattleDupConf.sName, true)
					return
				end
			end, oRole, tMsg)
		else
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
				nBattleDupType=gtBattleDupType.eZhenYao, 
				bHadLoverRela=bHadLoverRela,
				bHadBrotherRela = bHadBrotherRela,
				bHadCoupleRela = bHadCoupleRela,
				bHadShiTuRela = bHadShiTuRela,
			}
			goTimerMgr:Clear(self.m_nAfterBattleTimer)
			oRole:PVE(oMonster, tExData)
		end
	end)
	
end

--进入副本请求,可能会切换服务进程(这时未创建副本)
function CZhenYao:EnterBattleDupReq(oRole)
	local oDup = oRole:GetCurrDupObj()
	if oDup:GetConf().nBattleType == gtBattleDupType.eZhenYao then
		return oRole:Tips("已经在镇妖副本中")
	end

	--要判断是不是队员，是队员不给进
	local function EnterFB(nDupMixID)
		local tConf = assert(ctDupConf[GF.GetDupID(nDupMixID)])
		oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
	end
	goBattleDupMgr:CreateBattleDup(gtBattleDupType.eZhenYao, EnterFB)
end

function CZhenYao:BattleDupReward(oRole, tExData)
	if not oRole then return end
	local nTotalComp = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eZhenYao][gtDailyData.eCountComp]
	if nTotalComp <= 0 then return end

	local nRewardLimit = ctDailyActivity[gtDailyID.eZhenYao].nTimesReward
	local fnRoleExp = ctDailyBattleDupConf[gtDailyID.eZhenYao].fnRoleExpReward
	local fnPetExp = ctDailyBattleDupConf[gtDailyID.eZhenYao].fnPetExpReward
	local fnSilver = ctDailyBattleDupConf[gtDailyID.eZhenYao].fnSilverReward
	local nTemp = nTotalComp % 10
	local nHuanShu = 0
	 
	--环数在有奖励范围内正常取环数，超过默认取1环
	local nRoleLevel = oRole:GetLevel()
	if nTotalComp <= nRewardLimit then
		nHuanShu = nTemp ~= 0 and nTemp or 10
	else
		nHuanShu = 1
	end

	local nRoleExp = fnRoleExp(nRoleLevel, nHuanShu)
	local nPetExp = fnPetExp(nRoleLevel, nHuanShu)
	local nSilverNum = fnSilver(nHuanShu, nRoleLevel)

	local nShuangBeiAdded = 0
	local nLeaderAdded = 0
	local nRelaAdded = 0
	local nShouHuAdded = 0
	local nXinHunAdded = 0

	local nCompCount = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eZhenYao][gtDailyData.eCountComp]
	local nRewardTimes = ctDailyActivity[gtDailyID.eZhenYao].nTimesReward	

	--没超过50次，同时双倍点数足够才有双倍加成
	-- if nCompCount < nRewardTimes then
	-- 	if oRole.m_oShuangBei:GetUseShuangbei() >= ctShuangBeiConf[1].nCostZhenYao then
	-- 		nShuangBeiAdded = ctDailyBattleDupConf[gtDailyID.eZhenYao].nShuangBei / 100
	-- 		oRole:AddItem(gtItemType.eCurr, gtCurrType.eShuangBei, -(ctShuangBeiConf[1].nCostZhenYao), "镇妖消耗双倍点")			
	-- 	end
	-- end

	if oRole:IsLeader() then
		nLeaderAdded = ctDailyBattleDupConf[gtDailyID.eZhenYao].nDuiZhang
	end

	local nQingYuanAdd = 0
	local nJieYiAdd = 0
	local nCoupleAdd = 0
	local nShiTuAdd = 0
	local nXinHunAdd = 0
	if tExData.bHadLoverRela then
		nQingYuanAdd = ctDailyBattleDupConf[gtDailyID.eZhenYao].nQingYuan or 0
	end
	if tExData.bHadBrotherRela then
		nJieYiAdd = ctDailyBattleDupConf[gtDailyID.eZhenYao].nJieYi
	end
	if tExData.bHadCoupleRela then
		nCoupleAdd = ctDailyBattleDupConf[gtDailyID.eZhenYao].nCouple
	end
	if tExData.bHadShiTuRela then
		nShiTuAdd = ctDailyBattleDupConf[gtDailyID.eZhenYao].nShiTu
	end

	if oRole.m_oRoleState:IsMarriageBlessEffectActive() then
		nXinHunAdd = ctDailyBattleDupConf[gtDailyID.eZhenYao].nXinHun
	end

	nRelaAdded = nJieYiAdd > nShiTuAdd and nJieYiAdd or nShiTuAdd
	nRelaAdded = nRelaAdded > nQingYuanAdd and nRelaAdded or nQingYuanAdd
	nRelaAdded = nRelaAdded > nCoupleAdd and nRelaAdded or nCoupleAdd

	local bMarriageBless, nMarriageBlessAddRatio = oRole.m_oRoleState:IsMarriageBlessEffectActive(gtBattleDupType.eZhenYao)
	if bMarriageBless then 
		nXinHunAdded = nMarriageBlessAddRatio
		assert(nXinHunAdded >= 0)
	end
	--print(">>>>>>>>>>>>>>关系加成", nRelaAdded)

	--单号：5358
	--3.结婚后7天内，夫妻双方获得“新婚祝福”的buff（暂定编号621），当夫妻2人在同一个队伍并且完成部分玩法时（镇妖、神魔志（精英、英雄），乱世、心魔、九霄、混沌），则整个队伍的玩家也可以获得经验加成
	--有奖励环数内和无奖励环数的经验等奖励
	local nFinalRoleExp = 0
	local nFinalPetExp = 0
	local nFinalYinYuan = 0
	local tItemIDList = {}

	local nTeamMember = oRole:GetTeamNum()
	if nCompCount < nRewardTimes then
	--if 0 < oRole.m_oShuangBei:GetUseShuangbei() then		--有奖励环数内有几率奖励物品
		local sStr = string.format("基础经验:%f, 双倍加成：%f, 队长加成：%f, 关系加成：%f, 守护加成：%f, 新婚加成：%f, 队员人数：%f\n", 
		nRoleExp, nShuangBeiAdded, nLeaderAdded, nRelaAdded, nShouHuAdded, nXinHunAdded, nTeamMember)
		print(">>>>>>>>>>>>>>>"..sStr)

		--屏蔽双倍加成			
		-- nFinalRoleExp = nRoleExp * (1 + nShuangBeiAdded + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded) * (50+nTeamMember * 10) / 100		--双倍奖励
		-- nFinalPetExp = nPetExp * (1 + nShuangBeiAdded + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded) * (50+nTeamMember * 10) / 100
		nFinalRoleExp = math.floor(nRoleExp * ((100 + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded + 100) / 100) * (50+nTeamMember * 10) / 100)		--双倍奖励
		nFinalPetExp = math.floor(nPetExp * ((100 + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded + 100) / 100) * (50+nTeamMember * 10) / 100)
		nFinalYinYuan = nSilverNum 
		-- if nShuangBeiAdded > 0 then
		-- 	nFinalYinYuan = nSilverNum * 2
		-- end

		--随机，判断是否能获得物品奖励
		local nRandNum = math.random(1, 100)	--获得物品奖励机率
		--if oRole.m_oDailyActivity.m_bIsShuangBei then	--双倍加成下的概率
			if nRandNum <= ctDailyBattleDupConf[gtDailyID.eZhenYao].nShuangBeiRewardPer then		--9.29策划决定有没有双倍点统一用这个概率
				local nItemID, nNum = self:GetRewardItem(oRole)
				oRole:AddItem(gtItemType.eProp, nItemID,nNum, "镇妖奖励")
				local tItem = {nItemID, nNum} 
				table.insert(tItemIDList,tItem)
			end

		-- else
		-- 	if nRandNum <= ctDailyBattleDupConf[gtDailyID.eZhenYao].nRewardItemPer then
		-- 		local nItemID, nNum = self:GetRewardItem(oRole)
		-- 		oRole:AddItem(gtItemType.eProp, nItemID, nNum, "镇妖奖励") 
		-- 		local tItem = {nItemID, nNum}
		-- 		table.insert(tItemIDList, tItem)
		-- 	end
		-- end
	
	else
		--nRoleExp * (1 + nShuangBeiAdded + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded) * (50+tExData.nMemberNum * 10) / 100 此为文档所说的正常的
		nFinalRoleExp = math.floor(nRoleExp * ((100 + nShuangBeiAdded + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded) / 100) * (50+nTeamMember * 10) / 100*0.2)
		nFinalPetExp = math.floor(nPetExp * ((100 + nShuangBeiAdded + nLeaderAdded + nRelaAdded + nShouHuAdded + nXinHunAdded)/100) * (50+nTeamMember * 10) / 100*0.2)
		nFinalYinYuan = math.floor(nSilverNum * 0.2)

		--50次之内保持原来正常设定，次数超过50次之后，不再出原来奖励池的奖励，改为8%几率出帮派诏令1个。
		local nRandNum = math.random(1, 100)	--获得物品奖励机率
		if nRandNum <= ctDailyBattleDupConf[gtDailyID.eZhenYao].nShuangBeiRewardPer then
			oRole:AddItem(gtItemType.eProp, 10007, 1, "镇妖奖励")
		end
	end

	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nFinalRoleExp, "镇妖奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nFinalPetExp, "镇妖奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nFinalYinYuan, "镇妖奖励")

	local tData = {}
	tData.bIsHearsay = true
	tData.tItemIDList = tItemIDList or {}
	--print(tData.tItemIDList)
	CEventHandler:OnCompZhenYao(oRole, tData)	

	--试炼任务传说时间
	local oShiLianTask = oRole.m_oShiLianTask
	local nShiLianTaskID = oShiLianTask.m_nTaskID
	if nShiLianTaskID <= 0 then return end
	local nValidTime = oShiLianTask.m_nChuanShuoTimeStamp
	local nShiLianTaskType = ctShiLianTaskConf[nShiLianTaskID].nTaskType
	if nShiLianTaskType == CShiLianTask.Type.eCommit and os.time() <= nValidTime then
		if oShiLianTask.m_bWasDrop then return end 
		local nRandNum = math.random(100)
		if nRandNum > ctShiLianOtherConf[1].nDropPer then return end
		local nItemID = ctShiLianTaskConf[nShiLianTaskID].tCommitItem[1][1]
		oRole:AddItem(gtItemType.eProp, nItemID, 1, "试炼任务传说时间巡逻掉落")
		oShiLianTask:SetWasDrop(true)
	end
end

--发送副本特殊面板信息
function CZhenYao:SendExpBuffInfo(oRole, bIsLeader)
	local tMsg = {}
	tMsg.nUseShuangbei = 0 --oRole.m_oShuangBei.m_nUseShuangbei
	tMsg.nUnuseShuangbei = 0 --oRole.m_oShuangBei.m_nUnuseShuangbei
	tMsg.bIsLeader = bIsLeader
	tMsg.bHadRelation = false		--lkx todo还没接入关系加成
	tMsg.bAutoMatch = self.m_bIsAutoMatch
	tMsg.nLeaderAdd = 0
	tMsg.nRelaBuffNum = 0
	
	local nTotalAdded = 0
	-- if oRole.m_oShuangBei.m_nUseShuangbei > 0 then
	-- 	nTotalAdded = nTotalAdded + ctDailyBattleDupConf[gtDailyID.eZhenYao].nShuangBei
	-- end

	if tMsg.bIsLeader then
		local nLeaderAdd = ctDailyBattleDupConf[gtDailyID.eZhenYao].nDuiZhang
		tMsg.nLeaderAdd = nLeaderAdd
		nTotalAdded = nTotalAdded + nLeaderAdd
	end

	if tMsg.bHadRelation then
		--要判断是那种关系，加最高的
		nTotalAdded = nTotalAdded + 0 --ctDailyBattleDupConf[gtDailyID.eZhenYao].nJieYI
		tMsg.nRelaBuffNum = 0
	end
	
	oRole:GetTeam(function(nTeamID, tTeam)
		if nTeamID > 0 and #tTeam > 0 then
			tMsg.nMemberNum = #tTeam
			tMsg.bMemberEnougt = (#tTeam == 5)
			local nMemberAdded = (tMsg.nMemberNum - 1) * 5	--队伍人数加成
			tMsg.nTeamAdd = nMemberAdded
			nTotalAdded = nTotalAdded + nMemberAdded
			tMsg.nTotalBuffNum = nTotalAdded
			tMsg.bHadTeam = true
		else
			tMsg.nMemberNum = 0
			tMsg.bMemberEnougt = false
			tMsg.nTotalBuffNum = 0
			tMsg.bHadTeam = false
			tMsg.nTeamAdd = 0
		end
		oRole:SendMsg("DupBuffOperaRet", tMsg)
	end)
end

function CZhenYao:ExpBuffOpera(oRole, nOperaType)
	if CZhenYao.tOpera.eAllInfoReq == nOperaType then
		--self:SendExpBuffInfo(oRole, oRole:IsLeader())
		
	elseif CZhenYao.tOpera.eUseShuangBei == nOperaType then				--领取(用于消耗)
		-- oRole.m_oShuangBei:UseShuangbei()
		-- self:SendExpBuffInfo(oRole, oRole:IsLeader())

	elseif CZhenYao.tOpera.eUnuseShuangBei == nOperaType then			--冻结(储存)
		-- oRole.m_oShuangBei:UnuseShuangbei()
		-- self:SendExpBuffInfo(oRole, oRole:IsLeader())		

	elseif CZhenYao.tOpera.eAutoMacthing == nOperaType then				--是否自动匹配
		self.m_bIsAutoMatch = not self.m_bIsAutoMatch
		oRole:GetTeam(function(nTeamID, tTeam)
			if nTeamID > 0 and #tTeam >= 5 then
				return oRole:Tips("队伍已满员")
			end
			oRole:MatchTeam(gtBattleDupType.eZhenYao, self:GetConf().sName, false)
			--self:SendExpBuffInfo(oRole, oRole:IsLeader())
		end)
	end
end

--计算所有奖励池总权重
function CZhenYao:CalAwardWeight()
	local tRewardPool = ctDailyBattleDupConf[gtDailyID.eZhenYao].tItemAward
	for key, tItemPool in pairs(tRewardPool) do 
		self.m_nTotalWeight = self.m_nTotalWeight + tItemPool[1]
	end
end

function CZhenYao:GetRewardItem(oRole)
	local tRewardPool = ctDailyBattleDupConf[gtDailyID.eZhenYao].tItemAward
	local function GetPoolWeight()
		return 1
	end
	local tPool = CWeightRandom:Random(tRewardPool, GetPoolWeight, 1, false)
	local nPoolID = tPool[1][2]
	local tRewardPool = ctAwardPoolConf.GetPool(nPoolID, oRole:GetLevel(), oRole:GetConfID()) 
	local function GetItemWeight(tNode)
		return tNode.nWeight
	end
	local tItem = CWeightRandom:Random(tRewardPool, GetItemWeight, 1, false)
	local nItemID = tItem[1].nItemID
	local nItemNum = tItem[1].nItemNum
	assert(nItemID > 0 and nItemNum > 0, "奖励物品有误")
	return nItemID, nItemNum
end

function CZhenYao:BecomeLeaderReq(oRole)
	-- do something
end

function CZhenYao:Leave(oRole)
	-- if not oRole then return end

	-- if oRole:GetTeamID() <= 0 or not oRole:IsLeader() then 
	-- 	local nPreDupMixID = oRole:GetDupMixID()
	-- 	local nRoleID = oRole:GetID()
	-- 	local fnConfirmCallback = function (tData)
	-- 		oRole = goPlayerMgr:GetRoleByID(nRoleID)
	-- 		if not oRole then return end  --回调期间，角色离开了当前逻辑服
	-- 		if tData.nSelIdx == 2 then 
	-- 			--防止玩家选择过程中，队长切换到当前逻辑服其他场景，玩家跟随离开了当前场景
	-- 			local nCurDupMixID = oRole:GetDupMixID()
	-- 			if nPreDupMixID == nCurDupMixID then 
	-- 				if goFBTransitScene then
	-- 					goFBTransitScene:EnterFBTransitScene(oRole)
	-- 				else
	-- 					local function CallBack(nMixID, nDupID)
	-- 						assert(ctDupConf[nDupID], "没有此场景配置")
	-- 						local tBornPos = ctDupConf[nDupID].tBorn[1]
	-- 						local nFace = ctDupConf[nDupID].nFace
	-- 						oRole:EnterScene(nMixID, tBornPos[1],  tBornPos[2], -1, nFace)
	-- 					end
	-- 					goRemoteCall:CallWait("GetFBTransitSceneMixID", CallBack, oRole:GetStayServer(), 101, oRole:GetSession())
	-- 				end
	-- 			end
	-- 		end
	-- 	end

	-- 	local sTipsContent = "是否确定离开当前副本"
	-- 	local tMsg = {sCont=sTipsContent, tOption={"取消", "确定"}, nTimeOut=15}
	-- 	goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
	-- else --在队伍并且是队长
	-- 	local fnLeaderConfirm = function(tData)
	-- 		if tData.nSelIdx == 2 then 
	-- 			--镇妖玩家离开队伍回调事件中，会自动将玩家移除出当前场景
	-- 			oRole:QuitTeam()
	-- 		end
	-- 	end
	-- 	local sTipsContent = "是否退出副本，并且离开队伍？"
	-- 	local tMsg = {sCont=sTipsContent, tOption={"取消", "确定"}, nTimeOut=15}
	-- 	goClientCall:CallWait("ConfirmRet", fnLeaderConfirm, oRole, tMsg)
	-- end
end
