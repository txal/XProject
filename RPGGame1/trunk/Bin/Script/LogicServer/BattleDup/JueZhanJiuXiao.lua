--决战九霄
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CJueZhanJiuXiao:Ctor(nID, nType)
	print("创建决战九霄副本", nID)
	self.m_nID = nID or 201						--战斗副本ID
	self.m_nType = nType 					--副本战斗类型
	self.m_tDupList = CUtil:WeakTable("v") 	--地图列表{地图对象,...}
	self.m_tRoleMap = CUtil:WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = CUtil:WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...}
	--self.m_nMonsterConfID = 0				--被杀死的怪物的配置ID（用于发奖励）
	self.m_nFlag = false
	self.m_nMonsterIndex = 1				--目前打到第几个Boss
	self.m_nTime = 0						--领奖的时间戳
	self.m_nTotalWeight = 0					--所有商品的总权重
	self.m_tItemList = {}					--战斗结束翻牌奖励物品
	self.m_nFanPaFlag = false				--翻牌标记
	self.m_nMinTimer = 0
	self.m_nMinTimerS = 0
	self.m_nSwitchDupTimer = nil
	self.m_PinTuRet = {}
	self.m_nCount = 0
	self.m_nOverTime = 0

	self.m_nImageID = 0					--当前拼图ID
	self.m_tRoleImageID = {}			--玩家拼图ID
	self:Init()
	self.m_nOpenTime = os.time()		--开始时间,用于提示副本完后提示用时多少
	self.m_nTeamID = 0

	self.m_nLastTaskID = 0				--记录上一次的关卡ID
	self.m_nPinTuTimer = 0
end

function CJueZhanJiuXiao:Init()
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
    end
    self:CalAwardWeight()
  	self:RegActTimer()
end

--销毁副本
function CJueZhanJiuXiao:Release()
	print("决战九霄副本被销毁", self.m_nID)
	for _, oDup in pairs(self.m_tDupList) do
		goDupMgr:RemoveDup(oDup:GetMixID())
	end
	 self.m_nMinTimer = GetGModule("TimerMgr"):Clear(self.m_nMinTimer)
	 self.m_nOverTime = GetGModule("TimerMgr"):Clear(self.m_nOverTime)
	 self.m_nMinTimerS = GetGModule("TimerMgr"):Clear(self.m_nMinTimerS)
	 self.m_nPinTuTimer = GetGModule("TimerMgr"):Clear( self.m_nPinTuTimer)
	 self.m_nSwitchDupTimer = GetGModule("TimerMgr"):Clear(self.m_nSwitchDupTimer)
	 self.m_nOverTime = nil
	 self.m_nMinTimer = nil
	 self.m_nMinTimerS = nil
	 self.m_nPinTuTimer = nil
	 self.m_nSwitchDupTimer = nil
	 self.m_tDupList = {}
	 self.m_tRoleMap = {}
	 self.m_tMonsterMap = {}
end

function CJueZhanJiuXiao:GetID() return self.m_nID end --战斗副本ID
function CJueZhanJiuXiao:GetType() return self.m_nType end --取副本战斗类型
function CJueZhanJiuXiao:GetConf() return ctBattleDupConf[self:GetType()] end
function CJueZhanJiuXiao:HasRole() return next(self.m_tRoleMap) end --是否有玩家

function CJueZhanJiuXiao:GetItemConf()
	for nTaskId, tItemConf in pairs(ctJueZhanJiuXiao) do
		return tItemConf
	end
end

--取地图对象
--@nIndex 副本中的第几个地图
function CJueZhanJiuXiao:GetDupObj(nIndex)
	return self.m_tDupList[nIndex]
end


--取地图ID
--@nIndex 副本中的第几个地图
function CJueZhanJiuXiao:GetDupMixID(nIndex)
	local oDup = self.m_tDupList[nIndex]
	return oDup:GetMixID()
end

--对象进入副本
function CJueZhanJiuXiao:OnObjEnter(oLuaObj, bReconnect)
	print("CJueZhanJiuXiao:OnObjEnter***", bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj
		self:SyncDupInfo()

	--人物
	elseif nObjType == gtGDef.tObjType.eRole then
		print("yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy")
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
		oLuaObj:SetBattleDupID(self:GetID())
		self:AutoCreatrMonster(oLuaObj)
		self:SyncDupInfo(oLuaObj)
		self:DupInfoUpdate(oLuaObj)
		self:CheckRoleNum(oLuaObj)	
	end
end

--对象进入副本的时候主动创建怪物
function CJueZhanJiuXiao:AutoCreatrMonster(oRole)
	assert(oRole, "参数错误")
	if not oRole:IsLeader() then
		return
	end
	if next(self.m_tMonsterMap) then
		return
	end
	self:CreateMonsterReq(oRole)
end

--是否全部通关
function CJueZhanJiuXiao:IsClearance()
	if self.m_nMonsterIndex == 0 then
		return true
	end
	return 
end

function CJueZhanJiuXiao:SwitchMap()
	GetGModule("TimerMgr"):Clear(self.m_nSwitchDupTimer)
	self.m_nSwitchDupTimer = nil
	local oRole = self:GetLeader()

	local nDupIndex =  self:GetDupIndex(oRole)
	local oDup = self.m_tDupList[nDupIndex]
	if oDup then
		if oDup:GetMixID() == oRole:GetDupMixID() then
			self:CreateMonsterReq(oRole)
		else
			if oRole then
				self:SwitchMapReq(oRole)
			end
		end
	end

end

--对象离开副本
function CJueZhanJiuXiao:OnObjLeave(oLuaObj, nBattleID)
	print("CJueZhanJiuXiao:OnObjLeave***")
	 local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
	    self.m_tMonsterMap[oLuaObj:GetID()] = nil
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

--队长活跃信息事件,30分钟无操作移出
function CJueZhanJiuXiao:OnLeaderActivity(oLuaObj, nInactivityTime)
	print("CJueZhanJiuXiao:OnLeaderActivity***", nInactivityTime)
	if not oLuaObj:IsLeader() then
		return LuaTrace("队长信息错误", debug.traceback())
	end
	if nInactivityTime >= 30*60 then
		oLuaObj:EnterLastCity()
	end
end

--离开队伍则回到组队大厅
function CJueZhanJiuXiao:OnLeaveTeam(oLuaObj)
	print("CJueZhanJiuXiao:OnLeaveTeam***")
	---oLuaObj:EnterLastCity()
	self:EnterBattleDupReq(oLuaObj)
end


--取队长角色对象
function CJueZhanJiuXiao:GetLeader()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsLeader() then
			return oRole
		end
	end
end

function CJueZhanJiuXiao:PVELeaveCheck(oRole)
	self:LeaveDupCheck(oRole)
end

--战斗结束
function CJueZhanJiuXiao:OnBattleEnd(oLuaObj, tBTRes, tExtData)
	print("CJueZhanJiuXiao:OnBattleEnd***")
	local nObjType = oLuaObj:GetObjType() --gtObjType
	if nObjType == gtObjType.eMonster then
		if not tBTRes.bWin then --怪物死亡
			print("怪物死了啊**********")
			self.m_nMinTimer = GetGModule("TimerMgr"):Interval(6, function() self:AutoReceiveReward() end)
			self.m_nFanPaFlag = true
			self.m_nLastTaskID = self.m_nMonsterIndex
			self.m_nMonsterIndex = ctJueZhanJiuXiao[self.m_nMonsterIndex].nNextTask
			if self.m_nMonsterIndex == 0 then
				self:CompleteCheck()
			end
			--self:DupInfoUpdate()
			local nMonsterID = next(self.m_tMonsterMap)
			if nMonsterID then
				goMonsterMgr:RemoveMonster(nMonsterID)
			end
			self:SyncDupInfo()

		end
	elseif nObjType == gtGDef.tObjType.eRole and tBTRes.bWin then
		local tMsg = {nSec= 0}
		oLuaObj:SendMsg("PVEFlopSendClientRet", tMsg)
		self:DupInfoUpdate(oLuaObj)
		self:BattleDupReward(oLuaObj)
		--self:CheckRewardComplete(oLuaObj)
	end
end

--取会话列表
function CJueZhanJiuXiao:GetSessionList()
	local tSessionList = {}
	for _, oRole in pairs(self.m_tRoleMap) do
		if not oRole:IsRobot() and oRole:IsOnline() then
			table.insert(tSessionList, oRole:GetServer())
			table.insert(tSessionList, oRole:GetSession())
		end
	end
	return tSessionList
end

--注册活动结束定时器
function CJueZhanJiuXiao:RegActTimer()
	local nOverMis = CDailyActivity:GetEndStamp(gtDailyID.eJueZhanJiuXiao)
	assert(nOverMis > os.time(), "活动结束时间错误" .. nOverMis)
	nOverMis = nOverMis - os.time()
    self.m_nOverTime  = GetGModule("TimerMgr"):Interval(nOverMis, function() self:ActEnd() end)
end

--活动结束强制销毁副本
function CJueZhanJiuXiao:ActEnd()
	GetGModule("TimerMgr"):Clear(self.m_nOverTime)
	self.m_nOverTime = nil
	--强制结束战斗，然后在销毁副本
	for nRoleID, oRole in pairs(self.m_tRoleMap) do
		local nBattleID = oRole:GetBattleID()
		if nBattleID > 0 then
			local oBattle = goBattleMgr:GetBattle(nBattleID)
			if oBattle then
				oBattle:ForceFinish()
			end
		end
	end
	goBattleDupMgr:DestroyBattleDup(self:GetID())
end

--获取拼图ID
function CJueZhanJiuXiao:GetImageID(oRole)
	local tImageID = {1,2,3,4}
	local tRoleImageID = self.m_tRoleImageID[oRole:GetID()]
	if not tRoleImageID then
		local nImageID = tImageID[math.random(1,#tImageID)]
		self.m_tRoleImageID[oRole:GetID()] = {nImageID = nImageID, nImageIDState = nImageID}
		return self.m_tRoleImageID[oRole:GetID()].nImageID
	else
		if tRoleImageID.nImageID == tRoleImageID.nImageIDState then
			return tRoleImageID.nImageID
		else
			for nKey, nValue in ipairs(tImageID) do
			 	if nValue == tRoleImageID.nImageID then
			 		table.remove(tImageID, nKey)
			 		break
			 	end
			end
			tRoleImageID.nImageID = tImageID[math.random(1,#tImageID)]
			tRoleImageID.nImageIDState = tRoleImageID.nImageID
			return tRoleImageID.nImageID
		end
	end

end

--副本信息改变下发
function CJueZhanJiuXiao:DupInfoUpdate(oRole)
	if self.m_nMonsterIndex == 0 then
		return
	end
	if self.m_nMonsterIndex == 1 then
		tBattleDupConf = self:GetItemConf()
		self.m_nMonsterIndex  = tBattleDupConf.nTaskId
	end
	local tMsg = {}
	tMsg.nID = self.m_nID
	tMsg.nCheckpoint = self.m_nMonsterIndex
	tMsg.sCheckpointName = ctJueZhanJiuXiao[self.m_nMonsterIndex].nTaskName
	if oRole then
		print("副本信息改变下发", tMsg)
		oRole:SendMsg("PVEDupInfoUpdateRet", tMsg)
	else
		for _, oRole in pairs(self.m_tRoleMap) do
			print("副本信息改变下发", tMsg)
			oRole:SendMsg("PVEDupInfoUpdateRet", tMsg)
		end
	end
end

--同步场景信息
function CJueZhanJiuXiao:SyncDupInfo(oRole)
	local tMsg = {tMonster={nDupMixID=0, nDupID=0, nMonObjID=0, nMonsterPosX=0, nMonsterPosY=0}, tDupList={}}
	local nMonsterID = next(self.m_tMonsterMap)
	local oMonster = self.m_tMonsterMap[nMonsterID]
	local nMonsterCount = 0
	for _, oMonster in pairs(self.m_tMonsterMap) do
		nMonsterCount = nMonsterCount + 1
	end
	print(">>>>>>>>>>>>>>>>>>决战九霄怪物", nMonsterCount)
	if oMonster then
		tMsg.tMonster.nMonObjID = oMonster:GetID()
		local oDup = oMonster:GetDupObj()
		tMsg.tMonster.nDupMixID = oDup:GetMixID()
		tMsg.tMonster.nDupID = oDup:GetDupID()
		tMsg.tMonster.nMonsterPosX, tMsg.tMonster.nMonsterPosY = oMonster:GetPos()
	end
	for _, oDup in ipairs(self.m_tDupList) do
		table.insert(tMsg.tDupList, {nDupMixID=oDup:GetMixID(), nDupID=oDup:GetDupID()})
	end
	if oRole then
		oRole:SendMsg("BattleDupInfoRet", tMsg)
	else
		local tSessionList = self:GetSessionList()
		Network.PBBroadcastExter("BattleDupInfoRet", tSessionList, tMsg)
	end
end



--创建怪物
function CJueZhanJiuXiao:CreateMonsterReq(oRole)
	print("CJueZhanJiuXiao:CreateMonsterReq***")
	if not oRole:IsLeader() then
		return oRole:Tips("队长才能操作")
	end
	if next(self.m_tMonsterMap) then
		return oRole:Tips("怪物已经出现")
	end

	local tBattleDupConf
 	if self.m_nMonsterIndex == 1 then
		tBattleDupConf = self:GetItemConf()
		self.m_nMonsterIndex  = tBattleDupConf.nTaskId
	end
	if self.m_nMonsterIndex == 0 then
		return oRole:Tips("该副本已经全部通关")
	end
	tBattleDupConf = ctJueZhanJiuXiao[self.m_nMonsterIndex]
	--判断是不是拼图
	if tBattleDupConf.nTaskType == 0 then
		print("拼图哦")
		if self.m_nFlag then
			local tPuzzleData = self.m_PinTuRet[oRole:GetID()]
			if tPuzzleData and tPuzzleData.bFalg then
				return oRole:Tips("你已完成拼图，请耐心等待队友完成拼图")
			end
		end
		self.m_nFlag = true

		self.m_PinTuRet = {}
		--只给归队玩家发送拼图消息
		local nSec = os.time() + 90
		GetGModule("TimerMgr"):Clear(self.m_nMinTimerS)
		self.m_nMinTimerS = nil
		local fnGetTeamCallBack = function (nTeamID, tTeam)
			for _, tRole in pairs(tTeam) do
				if not tRole.bLeave then
					local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
					if oRole then
						self.m_PinTuRet[oRole:GetID()] = {bFalg = false}
						local tMsg = {nTaskId = tBattleDupConf.nTaskId, nSec = nSec, nImageID = self:GetImageID(oRole)}
						oRole:SendMsg("PVEDupPinTuSendClientRet", tMsg)
					end
				end
			end
		end
		oRole:GetTeam(fnGetTeamCallBack)
		self.m_nPinTuTimer = GetGModule("TimerMgr"):Interval(30, function() self:AutoRobot() end)
		self.m_nMinTimerS = GetGModule("TimerMgr"):Interval(93, function() self:PinTuResuiTiming() end)
	else
		local nDupIndex =  self:GetDupIndex(oRole)
		local oDup = self.m_tDupList[nDupIndex]
		if oDup then
			local tMonster = ctMonsterConf[tBattleDupConf.nBattleGroup]
			if not tMonster then
				return
			end
			local nPosX = tMonster.tPos[1][1]
			local nPosY = tMonster.tPos[1][2]
			local tMsg = {}
			for nRoleID, oRole in pairs(self.m_tRoleMap) do
				oRole:SendMsg("PVENavigateRet",tMsg)
			end
			goMonsterMgr:CreateMonster(tBattleDupConf.nBattleGroup, oDup:GetMixID(), nPosX, nPosY)
			oRole:Tips(string.format("怪物物出现在%s！", oDup:GetName()))
			--self:SwitchMapReq(oRole)
		end
	end
end

function CJueZhanJiuXiao:AutoRobot()
	self.m_nPinTuTimer = GetGModule("TimerMgr"):Clear(self.m_nPinTuTimer)
	self.m_nPinTuTimer = nil
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsRobot() then
			self:PinTuResuitReq(oRole, 1, true)
			break
		end
	end
end

--点击破解机关请求
function CJueZhanJiuXiao:ClickCrackOrganReq(oRole)
	local fnCrackOrganCallBack = function(nTeamID, tTeam)
		if nTeamID <= 0 then
			return oRole:Tips("请先组队伍")
		end
		if tTeam[1].nRoleID ~= oRole:GetID() then
			return oRole:Tips("队长才能攻击")
		end

		local tBattleDupConf = self:GetConf()
		local nReturnCount = 0
		for _, tRole in pairs(tTeam) do
			if not tRole.bLeave then nReturnCount = nReturnCount+1 end
		end
		if nReturnCount < tBattleDupConf.nTeamMembs then
			return oRole:Tips(string.format("归队人数不足%d人", tBattleDupConf.nTeamMembs))
		end

		--检查人员等级
		local bAllCanJoin = true
		local sStr = ""
		for _, tRole in ipairs(tTeam) do 
			local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oRole then
				if oRole.m_nLevel < ctDailyBattleDupConf[gtBattleDupType.eJueZhanJiuXiao].nAccpLimit then
					sStr = sStr .. oRole.m_sName .. ", "
					bAllCanJoin = false
				end
			end
		end

		if not bAllCanJoin then
			local sTips = sStr .. "等级不足30级"
			return oRole:Tips(sTips)				
		end
		local tMsg = {}
		oRole:SendMsg("ClickCrackOrganRet", tMsg{bFlag = true})
		self.m_nMinTimerS = GetGModule("TimerMgr"):Interval(90 , function() self:PinTuResuiTiming() end)
	end
	oRole:GetTeam(fnCrackOrganCallBack)
end

function CJueZhanJiuXiao:PinTuResuiTiming()
	GetGModule("TimerMgr"):Clear(self.m_nMinTimerS)
	self.m_nMinTimerS = nil
	local bFalg = false
	local sName = " "
	for nRoleID, tData in pairs(self.m_PinTuRet) do
		oRole = goPlayerMgr:GetRoleByID(nRoleID)
		if oRole and not tData.bFalg then
			sName = sName .. oRole:GetName()..","
			bFalg = true
		end

	end
	if bFalg then
		sName = sName .. "玩家没有完成拼图"
		for nRoleID, oRole in pairs(self.m_tRoleMap) do
			oRole:Tips(sName)
		end
	end
	self.m_PinTuRet = {}
	self.m_nCount = 0
	self.m_nFlag = false
end

--拼图结果返回处理
--bRobot --机器人特殊处理一波
function CJueZhanJiuXiao:PinTuResuitReq(oRole, nResuit, bRobot)
	if not self.m_nFlag then
		return oRole:Tips("拼图超时,请重新请求配拼图")
	end
	local nRet = 1
	if nResuit ~= nRet then
		return oRole:Tips("拼图不正确")
	end
	if bRobot then
		self:RobotPuzzleHandle()
	else
		local tPuzzleData = self.m_PinTuRet[oRole:GetID()]
		if not tPuzzleData then
			return 
		end
		if tPuzzleData.bFalg then
			return oRole:Tips("你已经拼图完成")
		end
		tPuzzleData.bFalg = true
	end
	local bFalg = false
	local bRoleOffline = false
	--策划需求修改,计算归队的
	local fnGetTeamCallBack = function (nTeamID, tTeam)
		--TODD，防止RPC调用期间玩家下线
		local nRetuenTeam = 0	--归队人数
		for _, tRole in pairs(tTeam) do
			if not tRole.bLeave then
				bRoleOffline = true
				local tPuzzleData = self.m_PinTuRet[tRole.nRoleID]
				if tPuzzleData and not tPuzzleData.bFalg then
					--检查有无归队的玩家没有完成拼图
					bFalg = true
					break
				end
			end
		end
		if not bRoleOffline or bFalg then
			return
		end
	    --下发奖励
		local tMsg = {nSec= 0}
		self.m_nLastTaskID = self.m_nMonsterIndex
		self.m_nMonsterIndex = ctJueZhanJiuXiao[self.m_nMonsterIndex].nNextTask
		for nRoleID, tRoleData in pairs(self.m_PinTuRet) do
			local oRole = goPlayerMgr:GetRoleByID(nRoleID)
			if oRole and tRoleData.bFalg then
				oRole:SendMsg("PVECloseBrandRet", {})
				oRole:SendMsg("PVEFlopSendClientRet", tMsg)
				self:BattleDupReward(oRole)
				local tRoleImageID = self.m_tRoleImageID[oRole:GetID()]
				if tRoleImageID then
					tRoleImageID.nImageIDState = 0
				end
			end
		end
		self.m_nMinTimer = GetGModule("TimerMgr"):Interval(6, function() self:AutoReceiveReward(true) end)
		self.m_nFanPaFlag = true
		self.m_nCount = 0
		GetGModule("TimerMgr"):Clear(self.m_nMinTimerS)
		self.m_nMinTimerS = nil
		self:DupInfoUpdate()
	end
	oRole:GetTeam(fnGetTeamCallBack)
end

function CJueZhanJiuXiao:RobotPuzzleHandle()
	for _, oRole in pairs(self.m_tRoleMap) do
		if oRole:IsRobot() then
			local tPuzzleData = self.m_PinTuRet[oRole:GetID()]
			if tPuzzleData and not tPuzzleData.bFalg then
				tPuzzleData.bFalg = true
			end
		end
	end
end

--攻击怪物
function CJueZhanJiuXiao:AttackMonsterReq(oRole, nMonObjID)
	local oMonster = self.m_tMonsterMap[nMonObjID]
	if not oMonster then
		return oRole:Tips("怪物不存在")
	end

	oRole:GetTeam(function(nTeamID, tTeam)
		if nTeamID <= 0 then
			return oRole:Tips("请先组队伍")
		end
		if tTeam[1].nRoleID ~= oRole:GetID() then
			return oRole:Tips("队长才能攻击")
		end

		local tBattleDupConf = self:GetConf()
		local nReturnCount = 0
		for _, tRole in pairs(tTeam) do
			if not tRole.bLeave then nReturnCount = nReturnCount+1 end
		end
		if nReturnCount < tBattleDupConf.nTeamMembs then
			return oRole:Tips(string.format("归队人数不足%d人", tBattleDupConf.nTeamMembs))
		end

		--检查人员等级
		local bAllCanJoin = true
		local sStr = ""
		for _, tRole in ipairs(tTeam) do 
			local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
			if oRole then
				if oRole.m_nLevel < ctDailyBattleDupConf[gtBattleDupType.eJueZhanJiuXiao].nAccpLimit then
					sStr = sStr .. oRole.m_sName .. ", "
					bAllCanJoin = false
				end
			end
		end
		if not bAllCanJoin then
			local sTips = sStr .. "等级不足30级"
			return oRole:Tips(sTips)				
		end

		oRole:PVE(oMonster, {nBattleDupType=gtBattleDupType.eJueZhanJiuXiao})
	end)
end

--进入副本请求,可能会切换服务进程
function CJueZhanJiuXiao:EnterBattleDupReq(oRole)
	if not oRole:IsSysOpen(29, true) then
		-- return oRole:Tips("活动尚未开启")
		return	
	end
	goPVEActivityMgr:EnterReadyDupReq(oRole)
end

function CJueZhanJiuXiao:BattleDupReward(oRole)
	if not oRole then return end
	--判断玩家有没有重复领取
	local bRet = self:RewardCheck(oRole, false)
	if bRet then return end
	--经验奖励
	local fnRoleExp = ctDailyBattleDupConf[gtDailyID.eJueZhanJiuXiao].fnRoleExpReward
	local fnPetExp = ctDailyBattleDupConf[gtDailyID.eJueZhanJiuXiao].fnPetExpReward
	local nRoleLevel = oRole:GetLevel()
	local nRoleExp = fnRoleExp(nRoleLevel)
	if oRole:IsLeader() then
		nRoleExp = nRoleExp + nRoleExp * (ctDailyBattleDupConf[gtDailyID.eJueZhanJiuXiao].nDuiZhang/100)
	end
	local tPet = oRole.m_oPet:GetCombatPet()
	if tPet then
		local nPetExp = fnPetExp(tPet.nPetLv)
		oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "决战九霄副本奖励")
	end
	local fSilverNum = ctDailyBattleDupConf[gtDailyID.eJueZhanJiuXiao].fnSilverReward
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "决战九霄副本奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, fSilverNum(), "决战九霄副本奖励")

end

function CJueZhanJiuXiao:CalAwardWeight()
	local tRewardPool = ctDailyBattleDupConf[gtDailyID.eJueZhanJiuXiao].tItemAward
	for key, tItemPool in pairs(tRewardPool) do 
		self.m_nTotalWeight = self.m_nTotalWeight + tItemPool[1]
	end
end

--时间到了自动翻牌
function CJueZhanJiuXiao:AutoReceiveReward(bFalg)
	GetGModule("TimerMgr"):Clear(self.m_nMinTimer)
	self.m_nMinTimer = nil
	self.m_nFanPaFlag = false
	--找出没有翻牌子的格子
	local tTmp = {} 
	for i = 1, 5, 1 do
		if not self.m_tItemList[i] then
			tTmp[#tTmp+1] = i
		end
	end
	local tRoleList = {}
	local nIndex = 1
	local tRoleData
	tRoleData = bFalg and self.m_PinTuRet or self.m_tRoleMap
	for nRoleID, tRole in pairs(tRoleData or {}) do
		local oRole = goPlayerMgr:GetRoleByID(nRoleID)
		if oRole then
			if bFalg and oRole then
				if tRole.bFalg then
					if self:RewardHandle(oRole, nIndex, tTmp) then
						nIndex =  nIndex + 1
					end
				end
			else
				--玩家处于暂离状态,则不给奖励
				local fnGetTeamCallBack = function (nTeamID, tTeam)
					--当前没有队伍
					for _, tRole in pairs(tTeam) do
						local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
						if not tRole.bLeave and oRole then
							if self:RewardHandle(oRole, nIndex, tTmp) then
							 	nIndex =  nIndex + 1
							end
						end
					end
					self:SendRewardComplete()
					self.m_PinTuRet = {}
					self.m_tItemList = {}

					local oRole = self:GetLeader()
					if oRole and not self:IsClearance() then
						-- self:SwitchMapReq(oRole)
						self.m_nSwitchDupTimer = GetGModule("TimerMgr"):Interval(3, function() self:SwitchMap() end)
					end

				end
				oRole:GetTeam(fnGetTeamCallBack)
				break
			end
		end
	end
	if bFalg then
		self:SendRewardComplete()
		self.m_PinTuRet = {}
		self.m_tItemList = {}

		print("kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkk222222222222222222222222222222")
		local oRole = self:GetLeader()
		if oRole and not self:IsClearance() then
			--self:SwitchMapReq(oRole)
			self.m_nSwitchDupTimer = GetGModule("TimerMgr"):Interval(3, function() self:SwitchMap() end)
		end
	end

end


--奖励处理
function CJueZhanJiuXiao:RewardHandle(oRole, nIndex, tTmp)
	local bRet = self:RewardCheck(oRole, true)
	if not bRet then
		tItem = self:GetRewardItem(oRole)
		if tItem then
			self.m_tItemList[tTmp[nIndex]] = {nGrid = tTmp[nIndex] ,nRoleID = oRole:GetID(), nRoleName = oRole:GetName(),
			ItemID = tItem[1].nItemID, nNum = tItem[1].nItemNum}
			oRole:AddItem(gtItemType.eProp, tItem[1].nItemID, tItem[1].nItemNum, "决战九霄副本奖励")
			local tData = {}
			tData.bIsHearsay = true
			tData.nItemID = tItem[1].nItemID
			CEventHandler:OnCompJueZhanJiuXiao(oRole, tData)

			local tMsg = {tList = {}}
			for nID, tItem in pairs(self.m_tItemList) do
				tMsg.tList[#tMsg.tList+1] = {nGrid = tItem.nGrid, nRoleName = tItem.nRoleName, nID = tItem.ItemID, nNum = tItem.nNum}
			end

			for nID, oRole in pairs(self.m_tRoleMap) do
				oRole:SendMsg("PVEClickRewardRet", tMsg)
				--self:CheckRewardComplete(oRole)
			end
			return true
		end
	end	
end

function CJueZhanJiuXiao:FindPlayerInfo(nRoleID)
	for _, tItem in pairs(self.m_tItemList) do
		if nRoleID == tItem.nRoleID then
			return true
		end
	end
end

--玩家点击翻牌
function CJueZhanJiuXiao:ClickFlopReq(oRole, nID)
	--采用新的判断条件

	local tItemList = {}
	if self.m_tItemList[nID] then
		return  oRole:Tips("该奖励已被玩家领取")
	end
	
	local bRet = self:RewardCheck(oRole, true)
	if bRet then return oRole:Tips("你今日已经领取了该奖励哦") end
	if not self.m_nFanPaFlag then return end
	local tItem = self:GetRewardItem(oRole)
	if tItem then
		self.m_tItemList[nID] = { nGrid = nID ,nRoleID = oRole:GetID(), nRoleName = oRole:GetName(),ItemID = tItem[1].nItemID, nNum = tItem[1].nItemNum}

		oRole:AddItem(gtItemType.eProp, tItem[1].nItemID, tItem[1].nItemNum, "决战九霄副本奖励")
		local tData = {}
		tData.bIsHearsay = true
		tData.nItemID = tItem[1].nItemID
		CEventHandler:OnCompJueZhanJiuXiao(oRole, tData)
		local tMsg = {tList = {}}
		for nID, tItem in pairs(self.m_tItemList) do
			tMsg.tList[#tMsg.tList+1] = {nGrid = tItem.nGrid, nRoleName = tItem.nRoleName, nID = tItem.ItemID, nNum = tItem.nNum}
		end

		for nID, oRole in pairs(self.m_tRoleMap) do
			oRole:SendMsg("PVEClickRewardRet", tMsg)
			--self:CheckRewardComplete(oRole)
		end
	end
end

--玩家是否领取过该关卡奖励检测
function CJueZhanJiuXiao:RewardCheck(oRole, bBattleReward)
	--玩家已经领取该关卡的奖励,不能再次发放奖励
	local tActData = oRole:GetPVEActData(gtDailyID.eJueZhanJiuXiao)
	if not tActData then
		if bBattleReward then
			oRole:SetPVEActData(gtDailyID.eJueZhanJiuXiao, self.m_nLastTaskID)
		end
	elseif not os.IsSameDay(os.time(), tActData.nResetTime, 0) then
		--检查时间重置
		if bBattleReward then
			oRole:ResetPVEData()
			oRole:SetPVEActData(gtDailyID.eJueZhanJiuXiao, self.m_nLastTaskID)
		end
	else
		if tActData[self.m_nLastTaskID] then
			return true
		end
		if bBattleReward then
			oRole:SetPVEActData(gtDailyID.eJueZhanJiuXiao, self.m_nLastTaskID)
		end
	end
end

function CJueZhanJiuXiao:SendRewardComplete()
	for _, oRole in pairs(self.m_tRoleMap) do
		self:CheckRewardComplete(oRole)
	end
end
--TODD,检查玩家当当天有没有全部通关奖励
function CJueZhanJiuXiao:CheckRewardComplete(oRole)
	tActData = oRole:GetPVEActData(gtDailyID.eJueZhanJiuXiao)
	if not tActData then
		return false
	end

	 if not os.IsSameDay(os.time(), tActData.nResetTime, 0) then
	 	return false
	end

	for nTaskId, _ in pairs(ctJueZhanJiuXiao) do
		if not tActData[nTaskId] then
			return false
		end
	end
	--TODD
	oRole:SendMsg("PVERewardCompleteRet", {})
end
function CJueZhanJiuXiao:FindItemInfo(nID)
	for i = 1, #self.m_tItemList, 1 do
		if tItemList[i].nID == nID then
			return tItemList[i]
		end
	end
end

--策划要求前八关使用副本自身的奖励库,九关使用神兽乐园奖励库
function CJueZhanJiuXiao:GetRewardItem(oRole)
	local nRandPool = math.random(1, self.m_nTotalWeight)
	local tRewardPool
	if ctJueZhanJiuXiao[self.m_nLastTaskID+1] and ctJueZhanJiuXiao[self.m_nLastTaskID+1].nNextTask == 0 then
		print("第九关使用神兽乐园的奖励库********************")
		tRewardPool = ctDailyBattleDupConf[gtDailyID.eShenShouLeYuan].tItemAward
	else
		tRewardPool = ctDailyBattleDupConf[gtDailyID.eJueZhanJiuXiao].tItemAward
	end
	local nRewardPoolID

	--根据权重找到是那个物品池
	for key, tItemPool in ipairs(tRewardPool) do
		if nRandPool <= tItemPool[1] then
			nRewardPoolID = tItemPool[2]
			break
		else
			nRandPool = nRandPool - tItemPool[1]
		end
	end

	if not nRewardPoolID then
		return 
	end

    local function fnGetWeight (tNode) return tNode.nWeight end
    local nRewardCount = 1
	local tItemList = ctAwardPoolConf.GetPool(nRewardPoolID, oRole:GetLevel(), oRole:GetConfID())
	local tReward = CWeightRandom:Random(tItemList, fnGetWeight, nRewardCount, false)
	--根据权重拿到物品
	return tReward
end

--点击怪物
function CJueZhanJiuXiao:TouchMonsterReq(oRole, nMonObjID)
	local oMonster = self.m_tMonsterMap[nMonObjID]
	if not oMonster then
		return oRole:Tips("怪物不存在")
	end

	oRole:GetTeam(function(nTeamID, tTeam)
		if nTeamID <= 0 then
			return oRole:Tips("请先组队伍")
		end
		if tTeam[1].nRoleID ~= oRole:GetID() then
			return oRole:Tips("队长才能攻击")
		end

		local tBattleDupConf = self:GetConf()
		local nReturnCount = 0
		for _, tRole in pairs(tTeam) do
			if not tRole.bLeave then nReturnCount = nReturnCount+1 end
		end
		if nReturnCount < tBattleDupConf.nTeamMembs then
			--return oRole:Tips(string.format("归队人数不足%d人", tBattleDupConf.nTeamMembs))
			local sCont = "人数不够，是否便捷组队？"
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
			local sStr = ""
			local tDailyDupConf = ctDailyBattleDupConf[gtBattleDupType.eJueZhanJiuXiao]
			assert(tDailyDupConf, "决战九霄日程配置错误")
			for _, tRole in ipairs(tTeam) do 
				local oRole = goPlayerMgr:GetRoleByID(tRole.nRoleID)
				if oRole then
					if oRole.m_nLevel < tDailyDupConf.nAccpLimit then
						sStr = sStr .. oRole.m_sName .. ", "
						bAllCanJoin = false
					end
				end
			end
			if not bAllCanJoin then
				local sTips = sStr .. "等级不足" .. tDailyDupConf.nAccpLimit .."级"
				return oRole:Tips(sTips)				
			end
			oRole:PVE(oMonster, {nBattleDupType=gtBattleDupType.eJueZhanJiuXiao})
		end
	end)
end

--玩家进入进入指定场景
function CJueZhanJiuXiao:SwitchMapReq(oRole)
	if not oRole:IsLeader() then
		return oRole:Tips("队长才能操作")
	end
	local tDupCfg = self:GetConf()
	assert(tDupCfg, string.format("决战九霄副本配置不存在(%d)ID", self:GetType()))
	local nDupIndex = self:GetDupIndex()
	if nDupIndex > #self.m_tDupList then
		nDupIndex  = nDupIndex - #self.m_tDupList
	end
	local oDup = self.m_tDupList[nDupIndex]
	local tDupCfg = ctDupConf[CUtil:GetDupID(oDup:GetMixID())]
	if not tDupCfg then return end
	print("ggggggggggggggggggggggggggggggggggggggggggggggggggggggggggggg")
	local tMsg = {}
	tMsg.nIndex = self.m_nMonsterIndex
	oRole:SendMsg("PVESwitchMapRet", tMsg)
	oRole:EnterScene(oDup:GetMixID(), tDupCfg.tBorn[1][1], tDupCfg.tBorn[1][2], -1, tDupCfg.nFace)
end

function CJueZhanJiuXiao:GetDupIndex(oRole)
	local tBattleDupConf = self:GetBattleDupCfg(oRole)
	if not tBattleDupConf then
		return oRole:Tips("配置不存在")
	end

	local tDupCfg = self:GetConf()
	assert(tDupCfg, string.format("决战九霄副本配置不存在(%d)ID", self:GetType()))
	local nDupIndex
	for nKey, tMonster in ipairs(tDupCfg.tMonster) do
		if tMonster[1] == tBattleDupConf.nBattleGroup then
			nDupIndex = nKey
			break
		end
	end
	if nDupIndex > #self.m_tDupList then
		nDupIndex = nDupIndex - #self.m_tDupList
		if nDupIndex > #self.m_tDupList then
			nDupIndex = 1
		end
	end
	return nDupIndex
end

function CJueZhanJiuXiao:GetBattleDupCfg(oRole)
	local tBattleDupConf = ctJueZhanJiuXiao[self.m_nMonsterIndex]
	if not tBattleDupConf then return end
	if self.m_nMonsterIndex == 0 then
		return oRole:Tips("该副本已经全部通关")
	end

	if tBattleDupConf.nBattleGroup == 0 then
		return oRole:Tips("拼图不用切换场景哦")
	end
	return tBattleDupConf
end

--记录进入玩家
function CJueZhanJiuXiao:CheckRoleNum(oRole)
	self.m_nTeamID = oRole:GetTeamID()
    local tRoleActData = {}
	tRoleActData.nRoleID = oRole:GetID()
	tRoleActData.nServerID = oRole:GetServer()
	tRoleActData.nLevel = oRole:GetLevel()
	tRoleActData.bLeave = false
    local bRet, nTarService= self:RecordActData()
    if bRet then
         Network.oRemoteCall:Call("PVESetSettlementActDataReq", oRole:GetServer(), 
            nTarService, 0, oRole:GetID(), self.m_nTeamID,  tRoleActData)
    else
        goPVEActivityMgr:SettlementActData(self.m_nTeamID,  tRoleActData)
    end
end

--离开副本检查
function CJueZhanJiuXiao:LeaveDupCheck(oRole)
	 local bRet,nTarService = self:RecordActData()
    local tRoleData = {}
    tRoleData.nRoleID = oRole:GetID()
    tRoleData.bLeave = true
    if bRet then
          Network.oRemoteCall:Call("PVEDataChangeReq", oRole:GetServer(), 
                nTarService, 0,  oRole:GetID(), self.m_nTeamID, tRoleData)
    else
        goPVEActivityMgr:PVEDataChange(self.m_nTeamID, tRoleData)
    end
end

--副本全部通关检查
function CJueZhanJiuXiao:CompleteCheck()
	local nCurrTime = os.time()
	local nCompleteTime = nCurrTime - self.m_nOpenTime
    local tRoleData = {tActData = {}}
	for _, oRole in pairs(self.m_tRoleMap) do
		local tRoleActData = {}
		tRoleActData.nServerID = oRole:GetServer()
		tRoleActData.nRoleID = oRole:GetID()
		tRoleActData.nLevel = oRole:GetLevel()
        table.insert(tRoleData.tActData,tRoleActData)
		local nHour, nMin, nSec = os.SplitTime(nCompleteTime)
		oRole:Tips("您本次副本完成时间是" .. nMin .. "分钟" ..nSec .."秒")
	end
    tRoleData.nCompleteTime = nCompleteTime
    local bRet, nTarService = self:RecordActData()
    if bRet then
        Network.oRemoteCall:Call("PVEDataCheckReq",tRoleData.tActData[1].nServerID, 
                    nTarService, 0,  tRoleData.tActData[1].nRoleID, self.m_nTeamID, nCompleteTime)
    else
        goPVEActivityMgr:PVEDataCheckReq(self.m_nTeamID, nCompleteTime)
    end
end

function CJueZhanJiuXiao:RecordActData()
    local nMapID = self.m_nCurrSceneID
	local nCurService = CUtil:GetServiceID()

	local nTarService = goPVEActivityMgr:GetReadySceneServiceID(10400)
	if nCurService ~= nTarService then
        return true, nTarService
	else
        return false, nTarService
	end
end

