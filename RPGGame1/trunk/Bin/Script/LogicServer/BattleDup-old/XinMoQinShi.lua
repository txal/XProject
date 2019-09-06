--心魔侵蚀
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CXinMoQinShi:Ctor(nID, nType)
	print("创建心魔侵蚀副本", nID)
	self.m_nID = nID 						--战斗副本ID
	self.m_nType = nType 					--副本战斗类型
	self.m_tDupList = CUtil:WeakTable("v") 	--地图列表{地图对象,...}
	self.m_tRoleMap = CUtil:WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = CUtil:WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...}
	self.m_nMonsterConfID = 0				--被杀死的怪物的配置ID（用于发奖励）
	self.m_nCurrMonsterCount = 0			--当前怪物个数
	self.m_tStartMonsterMap = {}			--星数怪物映射
	self.m_nCurrStartBeKill = 0				--当前被杀的怪物的星数 
	self.m_nLastDupMixID = 0
	self:Init()
end

_ctRewardItemConf = {}			--怪物死亡奖励的物品{[怪物ID]={物品}}
_ctTotalWeight = {}				--怪物死亡奖励的物品权重{[怪物ID]=总权重}
local function _PreProRewardItemConf()
	for nMonsterConfID, tConf in pairs(ctXinMoQinShiItem) do
		if not _ctRewardItemConf[nMonsterConfID] then
			_ctRewardItemConf[nMonsterConfID] = {}
			table.insert(_ctRewardItemConf[nMonsterConfID], tConf)
		end
	end
end

local function _PreProCalTotalWeight()
	for nMonsterConfID, tItemConf in pairs(_ctRewardItemConf) do
		if not _ctTotalWeight[nMonsterConfID] then
			_ctTotalWeight[nMonsterConfID] = 0
		end
		for _, tConf in pairs(tItemConf)do
			_ctTotalWeight[nMonsterConfID] = _ctTotalWeight[nMonsterConfID] + tConf.nWeight
		end
	end
end
 _PreProRewardItemConf()
_PreProCalTotalWeight()

--初始化副本
function CXinMoQinShi:Init()
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

	--创建怪物
	local tMonster = ctXinMoQinShiMonConf[1].tMonster
	for nStart, tID in pairs(tMonster) do
		local nRand = math.random(1, #tID)
		local oMonster = self:CreateMonster(tID[nRand])

		--记录星数
		self.m_tStartMonsterMap[nStart] = oMonster:GetID()
	end
end

--销毁副本
function CXinMoQinShi:Release() 
	print("心魔侵蚀副本被销毁", self.m_nID)
	for _, oDup in pairs(self.m_tDupList) do
		goDupMgr:RemoveDup(oDup:GetMixID())
	end
	self.m_tDupList = {}
	self.m_tRoleMap = {}
	self.m_tMonsterMap = {}
	self.m_nMonsterConfID = 0
end

function CXinMoQinShi:GetID() return self.m_nID end --战斗副本ID
function CXinMoQinShi:GetType() return self.m_nType end --取副本战斗类型
function CXinMoQinShi:GetConf() return ctBattleDupConf[self:GetType()] end
function CXinMoQinShi:HasRole() return next(self.m_tRoleMap) end --是否有玩家

--取地图ID
--@nIndex 副本中的第几个地图
function CXinMoQinShi:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

--取地图对象
--@nIndex 副本中的第几个地图
function CXinMoQinShi:GetDupObj(nIndex)
	return self.m_tDupList[nIndex]
end

--对象进入副本
function CXinMoQinShi:OnObjEnter(oLuaObj, bReconnect)
	print("CXinMoQinShi:OnObjEnter***", bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj
		if self.m_nCurrStartBeKill > 0 then
			self.m_tStartMonsterMap[self.m_nCurrStartBeKill] = oLuaObj:GetID()
		end
		self:SyncDupInfo()
		self.m_nCurrMonsterCount = self.m_nCurrMonsterCount + 1
		if self.m_nCurrMonsterCount >= 9 then		--9只怪
			self:SendAllMonsterInfo()
		end

	--人物
	elseif nObjType == gtGDef.tObjType.eRole then
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
		oLuaObj:SetBattleDupID(self:GetID())
		self:SyncDupInfo(oLuaObj)
		if self.m_nCurrMonsterCount >= 9 then		--9只怪
			self:SendAllMonsterInfo(oLuaObj)
		end
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
			local nNpcID = ctDailyActivity[gtDailyID.eXinMoQinShi].nID
			local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30, nParam1=nNpcID}
			goClientCall:CallWait("ConfirmRet", function(tData)
				--我来帮你
				local tBattleDupConf = ctBattleDupConf[gtBattleDupType.eXinMoQinShi]
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
										oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, true)
										oLuaObj:GetTeam(function(nTeamID, tTeam)
											if nTeamID <= 0 then
												--确定便捷组队，若玩家没有队伍
												oLuaObj:CreateTeam(function(nTeamIDNew, tTeamNew)
													if not nTeamIDNew then
														return oLuaObj:Tips("创建队伍失败")
													else
														oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, true)
													end
												end)
											end
										end)

									else	
										--确定便捷组队，若玩家有队伍
										--查询可不可以合并队伍
										local function CheckCallBack(bCanJoinIn)
											if bCanJoinIn then
												local sCont = "当前有队伍有空位，是否加入队伍呢？"
												local tOption = {"接续匹配", "加入队伍"}
												local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10, nTimeOutSelIdx=1}
												goClientCall:CallWait("ConfirmRet", function(tData)
													if tData.nSelIdx == 1 then		--继续匹配
														oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, true)
													else	--加入队伍
														local function JoinMergeTeamCallBack(bIsMergeSucc)
															if not bIsMergeSucc then
																oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, true)
															end
														end
														Network:RMCall("JoinMergeTeamReq", JoinMergeTeamCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eXinMoQinShi)
													end
												end, oLuaObj, tMsg)
											else
												oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, true)
											end
										end
										Network:RMCall("CheckJoinMergeTeamReq", CheckCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eXinMoQinShi)										
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
													oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, true)
												else	--加入队伍
													local function JoinMergeTeamCallBack(bIsMergeSucc)
														if not bIsMergeSucc then
															oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, true)
														end
													end
													Network:RMCall("JoinMergeTeamReq", JoinMergeTeamCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eXinMoQinShi)
												end
											end, oLuaObj, tMsg)
										else
											oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, true)
										end
									end
									Network:RMCall("CheckJoinMergeTeamReq", CheckCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetTeamID(), gtBattleDupType.eXinMoQinShi)							
									--oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, false)
								end
							else
								--队员
								oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, false)
								oLuaObj:GetTeam(function(nTeamID, tTeam)
									if nTeamID > 0 then
										if tTeam[1].nRoleID ~= oLuaObj:GetID() then
											Network:RMCall("GotoLeader", nil,gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), {nBattleDupType=gtBattleDupType.eXinMoQinShi})
										end
									end
								end)
							end
						else
							--没队伍
							oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, false)
							oLuaObj:GetTeam(function(nTeamID, tTeam)
								if nTeamID > 0 then
									if tTeam[1].nRoleID ~= oLuaObj:GetID() then
										Network:RMCall("GotoLeader", nil,gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oLuaObj:GetSession(), oLuaObj:GetID(), {nBattleDupType=gtBattleDupType.eXinMoQinShi})
									end
								else
									oLuaObj:CreateTeam(function(nTeamID, tTeam)
										if not nTeamID then 
											return oRole:Tips("创建队伍失败")
										else
											oLuaObj:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, false)
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
function CXinMoQinShi:OnObjLeave(oLuaObj, nBattleID)
		print("CXinMoQinShi:OnObjLeave***")
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		print("怪物离开场景:", oLuaObj:GetConfID(), oLuaObj:GetName())
		self.m_tMonsterMap[oLuaObj:GetID()] = nil
		for nStart, nMonObjID in ipairs(self.m_tStartMonsterMap) do
			if nMonObjID == oLuaObj:GetID() then
				self.m_tStartMonsterMap[nStart] = nil
				self.m_nCurrStartBeKill = nStart
			end
		end
		self.m_nCurrMonsterCount = self.m_nCurrMonsterCount - 1
		self.m_nMonsterConfID = oLuaObj:GetConfID()
		local tMonster = ctXinMoQinShiMonConf[1].tMonster
		for _, tID in pairs(tMonster) do
			for nIndex, nMonsterID in pairs(tID) do
				if nMonsterID == self.m_nMonsterConfID then
					local nRand = math.random(1, #tID)
					self:CreateMonster(tID[nRand])
					return
				end
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
			-- 	goBattleDupMgr:DestroyBattleDup(self:GetID())
			-- end
		end

	end
end

--离开队伍则退出副本
function CXinMoQinShi:OnLeaveTeam(oLuaObj)
	print("CXinMoQinShi:OnLeaveTeam***")
	oLuaObj:EnterLastCity()
end

--队长活跃信息事件,30分钟无操作移出
function CXinMoQinShi:OnLeaderActivity(oLuaObj, nInactivityTime)
	print("CXinMoQinShi:OnLeaderActivity***", nInactivityTime)
	if not oLuaObj:IsLeader() then
		return LuaTrace("队长信息错误", debug.traceback())
	end
	if nInactivityTime >= 30*60 then
		oLuaObj:EnterLastCity()
	end
end

--取队长角色对象
function CXinMoQinShi:GetLeader()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsLeader() then
			return oRole
		end
	end
end

function CXinMoQinShi:OnEnterCheck(nRoleID, tRoleParam)
	--检查能不能进入副本
	-- if tRoleParam.nTeamID <= 0 then
	-- 	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	-- 	if oRole then
	-- 		oRole:Tips("没有队伍不能前往改副本")
	-- 	end
	-- 	return false
	-- end
	return true
end

--战斗结束
function CXinMoQinShi:OnBattleEnd(oLuaObj, tBTRes, tExData)
	print("CXinMoQinShi:OnBattleEnd***")
	local nObjType = oLuaObj:GetObjType() --gtObjType

	if nObjType == gtObjType.eMonster then
		if tBTRes.bWin then --怪物死亡
			self:SyncDupInfo()
		end

	elseif nObjType == gtGDef.tObjType.eRole and tBTRes.bWin then
		--判断奖励次数，奖励活跃值
		local tActData = oLuaObj.m_oDailyActivity.m_tActDataMap
		local nCompCount = tActData[gtDailyID.eXinMoQinShi][gtDailyData.eCountComp]
		if nCompCount < ctDailyActivity[gtDailyID.eXinMoQinShi].nTimesReward then
			oLuaObj.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eXinMoQinShi, "心魔侵蚀奖励活跃")
			self:BattleDupReward(oLuaObj, tExData)
			self:SyncDupInfo(oLuaObj)
		else
			oLuaObj.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eXinMoQinShi, "心魔侵蚀奖励活跃")
			self:SyncDupInfo(oLuaObj)
			return oLuaObj:Tips("今天击杀心魔侵蚀的怪物数量已达到上限，继续参与将没有收益")
		end

		--检查如果是队长加侠义值
		if oLuaObj:IsLeader() then
			local nRandNum = math.random(1, 100)
			if nRandNum <= ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nRewardXiaYiPer then
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
						local nXiaYi = nNum * ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nXiaYiReward
						oLuaObj:AddItem(gtItemType.eCurr, gtCurrType.eChivalry, nXiaYi, "心魔侵蚀侠义奖励")
					end
				end)
			end
		end
	end
end

--取会话列表
function CXinMoQinShi:GetSessionList()
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
function CXinMoQinShi:SyncDupInfo(oRole)
	local tMsg = {tMonster={nDupMixID=0, nDupID=0, nMonObjID=0, nMonsterPosX=0, nMonsterPosY=0, nMonsterConfID=0}, tDupList={}}
	local nMonsterID = next(self.m_tMonsterMap)
	local oMonster = self.m_tMonsterMap[nMonsterID]
	local nMonsterCount = 0
	for _, oMonster in pairs(self.m_tMonsterMap) do
		nMonsterCount = nMonsterCount + 1
	end
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
		tMsg.nCompTimes = oRole.m_oDailyActivity:GetRecData(gtDailyID.eXinMoQinShi)[gtDailyData.eCountComp]		
		oRole:SendMsg("BattleDupInfoRet", tMsg)
	else
		for nIndex, oRole in pairs(self.m_tRoleMap) do
			tMsg.nCompTimes = oRole.m_oDailyActivity:GetRecData(gtDailyID.eXinMoQinShi)[gtDailyData.eCountComp] 
			oRole:SendMsg("BattleDupInfoRet", tMsg)
		end
		-- local tSessionList = self:GetSessionList()
		-- Network.PBBroadcastExter("BattleDupInfoRet", tSessionList, tMsg)
	end
end

function CXinMoQinShi:SendAllMonsterInfo(oRole)
	local tMsg = {tMonsterList={}}
	for nStart, nMonObjID in ipairs(self.m_tStartMonsterMap) do
		local info = {}
		local oMonster = self.m_tMonsterMap[nMonObjID]
		info.nMonObjID = oMonster:GetID()
		local oDup = oMonster:GetDupObj()
		info.nDupMixID = oDup:GetMixID()
		info.nDupID = oDup:GetDupID()
		info.nMonsterPosX, info.nMonsterPosY = oMonster:GetPos()
		info.nMonsterConfID = oMonster:GetConfID()
		table.insert(tMsg.tMonsterList, info)
	end
	if oRole then
		oRole:SendMsg("XinMoQinShiMonListRet", tMsg)
	else
		local tSessionList = self:GetSessionList()
		Network.PBBroadcastExter("XinMoQinShiMonListRet", tSessionList, tMsg)
	end
end

--创建怪物
function CXinMoQinShi:CreateMonster(nMonsterID)
	print("CXinMoQinShi:CreateMonsterReq***")

	local oDup = self.m_tDupList[math.random(#self.m_tDupList)]
	local tMapConf = oDup:GetMapConf()
	local nPosX = math.random(300, tMapConf.nWidth - 300)	
	local nPosY = math.random(300, tMapConf.nHeight - 300)
	local oMonster = goMonsterMgr:CreateMonster(nMonsterID, oDup:GetMixID(), nPosX, nPosY)
	return oMonster
end

--攻击怪物
function CXinMoQinShi:TouchMonsterReq(oRole, nMonObjID)
	local oMonster = self.m_tMonsterMap[nMonObjID]
	if not oMonster then
		return oRole:Tips("怪物不存在")
	end
	if oRole:GetTeamID() > 0 and not oRole:IsLeader() then 
		return oRole:Tips("只有队长可以操作")
	end

	local nMonsterConfID = oMonster:GetConfID()
    local sCont = "嘿嘿……我最喜欢掌控人心……快来吧……你们也来加入我吧！"
    local tOption = {"进入战斗", "快捷组队", "暂时撤退"}
    local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30, nParam1=nMonsterConfID}	

    goClientCall:CallWait("ConfirmRet", function(tData)
		if tData.nSelIdx == 1 then	--进入战斗
            oRole:GetTeam(function(nTeamID, tTeam)
	            -- if nTeamID <= 0 then
	            --     return oRole:Tips("请先组队伍")
				-- end

				-- --检查人数
				local tBattleDupConf = self:GetConf()
	            local nReturnCount = 0
	            for _, tRole in pairs(tTeam or {}) do
	                if not tRole.bLeave then nReturnCount = nReturnCount+1 end
	            end
	            if nReturnCount < tBattleDupConf.nTeamMembs then
	                return oRole:Tips(string.format("队伍归队人数不足%d人", tBattleDupConf.nTeamMembs))
	            end
				
				--检查人员等级
				local bAllCanJoin = true
				--local nLevelLimit = ctDailyBattleDupConf[gtBattleDupType.eXinMoQinShi].nAccpLimit
				local sStr = ""
				if nTeamID > 0 and tTeam then 
					for _, tRole in ipairs(tTeam) do 
						if not tRole.bLeave then 
							local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
							if oRole then
								-- if oRole.m_nLevel < nLevelLimit then
								-- 	sStr = sStr .. oRole.m_sName .. ", "
								-- 	bAllCanJoin = false
								-- end
								local tConf = self:GetConf()
								if not oRole.m_oDailyActivity:CheckCanJoinAct(tConf.nDailyActID) then
									sStr = sStr .. oRole.m_sName .. ", "
									bAllCanJoin = false
								end
							end
						end
					end
				end
				if not bAllCanJoin then
					return oRole:Tips(sStr.."未能参加活动")				
				end

	            if tTeam[1].nRoleID ~= oRole:GetID() then
					return oRole:Tips("队长才能攻击")
				else
					local nCompCount = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eXinMoQinShi][gtDailyData.eCountComp]
					local nRewardTimes = ctDailyActivity[gtDailyID.eXinMoQinShi].nTimesReward
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
					nBattleDupType=gtBattleDupType.eXinMoQinShi, 
					bHadLoverRela=bHadLoverRela,
					bHadBrotherRela = bHadBrotherRela,
					bHadCoupleRela = bHadCoupleRela,
					bHadShiTuRela = bHadShiTuRela,
				}
				oRole:PVE(oMonster, tExData)
			end)
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
							oRole:MatchTeam(gtBattleDupType.eXinMoQinShi, tBattleDupConf.sName, false)
						end
					end
				end
			end)
		else
			return	--暂时退避
		end 
	end, oRole, tMsg)
end

--进入副本请求,可能会切换服务进程(这时未创建副本)
function CXinMoQinShi:EnterBattleDupReq(oRole)
	local oDup = oRole:GetCurrDupObj()
	if oDup:GetConf().nBattleType == gtBattleDupType.eXinMoQinShi then
		return oRole:Tips("已经在心魔侵蚀副本中")
	end

	local function EnterFB(nDupMixID)
		local tConf = assert(ctDupConf[CUtil:GetDupID(nDupMixID)])
		oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
	end
	goBattleDupMgr:CreateBattleDup(gtBattleDupType.eXinMoQinShi, EnterFB)
end

function CXinMoQinShi:BattleDupReward(oRole, tExData)
	--判断
	if not oRole then return end
	local nTotalComp = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eXinMoQinShi][gtDailyData.eCountComp]
	if nTotalComp <= 0 then return end
	local nRewardLimit = ctDailyActivity[gtDailyID.eXinMoQinShi].nTimesReward
	if nTotalComp > nRewardLimit then
		oRole:Tips("超过击杀数量上限，无法获取奖励")
	end

	--经验奖励
	local fnRoleExp = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].fnRoleExpReward
	local fnPetExp = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].fnPetExpReward
	local fnSilver = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].fnSilverReward
	local nTemp = nTotalComp % 10
	local nHuanShu = nTemp ~= 0 and nTemp or 10
	local nRoleLevel = oRole:GetLevel()
	local nRoleExp = fnRoleExp(nRoleLevel, nHuanShu)
	local nPetExp = fnPetExp(nRoleLevel, nHuanShu)
	local nSilverNum = fnSilver(gnSilverRatio, nHuanShu, nRoleLevel)
	local nGoleNum = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nGoldReward

	local nShuangBeiAdded = 0
	local nLeaderAdded = 0
	local nRelaAdded = 0
	local nShouHuAdded = 0
	local nXinHunAdded = 0

	local nCompCount = oRole.m_oDailyActivity.m_tActDataMap[gtDailyID.eXinMoQinShi][gtDailyData.eCountComp]
	local nRewardTimes = ctDailyActivity[gtDailyID.eXinMoQinShi].nTimesReward	

	if oRole:IsLeader() then
		nLeaderAdded = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nDuiZhang
	end

	local nQingYuanAdd = 0
	local nJieYiAdd = 0
	local nCoupleAdd = 0
	local nShiTuAdd = 0
	local nXinHunAdd = 0

	local nTeamMember = oRole:GetTeamNum()	
	if tExData.bHadLoverRela then
		nQingYuanAdd = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nQingYuan or 0
	end
	if tExData.bHadBrotherRela then
		nJieYiAdd = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nJieYi
	end
	if tExData.bHadCoupleRela then
		nCoupleAdd = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nCouple
	end
	if tExData.bHadShiTuRela then
		nShiTuAdd = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nShiTu
	end

	if oRole.m_oRoleState:IsMarriageBlessEffectActive() then
		nXinHunAdd = ctDailyBattleDupConf[gtDailyID.eXinMoQinShi].nXinHun
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

	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nFinalRoleExp, "心魔侵蚀副本奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nFinalPetExp, "心魔侵蚀副本奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nFinalYinYuan, "心魔侵蚀副本奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eJinBi, nGoleNum, "心魔侵蚀副本奖励")
	
	--星数物品奖励ID
	local nTotalWeight = _ctTotalWeight[self.m_nMonsterConfID]
	local nRandNum = math.random(1, nTotalWeight)
	local nPoolID = 0
	local nRandTimes = 0
	for _, tConf in pairs(_ctRewardItemConf[self.m_nMonsterConfID]) do
		if nRandNum <= tConf.nWeight then
			nPoolID = tConf.tRewardItem[1][1]
			nRandTimes = tConf.tRewardItem[1][2]
			break
		else
			nRandNum = nRandNum -  tConf.nWeight
		end
	end
	local tRewardItemList = {}
	local tPool = ctAwardPoolConf.GetPool(nPoolID, oRole:GetLevel())
	local function GetWeight(tNode)
		return tNode.nWeight
	end
	local tItemList = CWeightRandom:Random(tPool, GetWeight, nRandTimes, false) 
	for _, tItem in pairs(tItemList) do
		oRole:AddItem(gtItemType.eProp, tItem.nItemID, tItem.nItemNum, "心魔侵蚀副本奖励")
		local tItem = {tItem.nItemID, tItem.nItemNum}
		table.insert(tRewardItemList, tItem)
	end

	oRole:PushAchieve("心魔侵蚀次数",{nValue = 1})
	local tData = {}
	tData.bIsHearsay = true
	tData.tItemIDList = tRewardItemList
	tData.nStar = ctXinMoQinShiItem[self.m_nMonsterConfID].nStar
	CEventHandler:OnCompXinMoQinShi(oRole, tData)
end