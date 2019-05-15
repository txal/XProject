--PVE准备大厅
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nJueZhanJiuXiaoRanking = 5	--前五名可以获得称谓奖励
local nHunDunShiLianRanking = 3		--前三名可以称谓奖励
local nJueZhanJiuXiaoAppellationID = 28		--决战九霄奖励称谓ID
local nHunDunShiLianAppellationID = 15     	--混沌试炼奖励称谓ID

local _PVEBattleDupType = {}
local function PVEBattleDupType()
	local tJueZhanJiuXiao = ctDailyActivity[gtDailyID.eJueZhanJiuXiao]
	if tJueZhanJiuXiao then
		local tOptist = tJueZhanJiuXiao.tOpenList
		for _, tValue in pairs(tOptist or {}) do
			_PVEBattleDupType[tValue[1]] = gtDailyID.eJueZhanJiuXiao
		end
	end

	local tHunDunShiLian = ctDailyActivity[gtDailyID.eHunDunShiLian]
	if tHunDunShiLian then
		local tOptist = tHunDunShiLian.tOpenList
		for _, tValue in pairs(tOptist or {}) do
			_PVEBattleDupType[tValue[1]] = gtDailyID.eHunDunShiLian
		end
	end
end
PVEBattleDupType()

local nSceReadySceneID = 10400 --准备场景ID
function CPVEActivityMgr:Ctor(nID, nType)
	print("PVE准备", nID)
	self.m_oRole = nil
	self.m_nID = nID 
	self.m_nType = nType or 200
	self.m_nPerpareTime = 0 	--活动准备时间
	self.m_oPlayerMap = {} 		--大厅玩家信息
	self.m_nStartTime = 0		--活动正式开启时间	
	self.m_nHourTimer= 0
	self.m_tDupList = GF.WeakTable("v") 	--地图列表{地图对象,...  --ID
	self.m_tRoleMap = GF.WeakTable("v") 	--角色映射{[角色编号]=角色对象,...}
	self.m_tMonsterMap = GF.WeakTable("v")  --怪物映射{[怪物编号]=怪物对象,...
	self.m_nfalg = false
	self.m_bState = false 
	self:Init()
	--self:Tick()
	self.m_nDupType = self:GetActivityID()
	self.m_nActivityStamp = 0
	self.m_nActivityEndStamp = 0
	self.m_nRankingTimer = false 			--结算定时器

	self.m_nActEndTimer = 0 				--活动结束定时器
	self.m_tPVEAppellationData = {}			--记录玩家跟称谓相关的数据
	self.m_tPVERoleData = {}				--用一个单独的容器记录玩家已经记录,存roleID,防止玩家退队处理
	self.m_nTimer = false
	self.m_tActState = {}					--self.m_tActState[nActID] = false
	self:RegTick()
	--self:InitActState()
	self.m_nCurrGmOpenActID = 0
	self.m_nGMOpenActEndTimer = nil 		--GM开启活动持续的时间,时间到后自动回复当前正常活动检测中
	self.m_nReadyTime = 0 					--单位分钟
end

function CPVEActivityMgr:Init()
	--准备场景只有一个地图
	local tDupConf = assert(ctDupConf[10400], "副本不存在:"..10400)
	if GF.GetServiceID() == tDupConf.nLogic then
		local oDup = goDupMgr:CreateDup(10400)
		print(">>>>>>>>>>>>>>>>>>创建PVE大厅")
		oDup:SetAutoCollected(false)
		table.insert(self.m_tDupList, oDup)
		for _, oDup in pairs(self.m_tDupList) do
			oDup:RegObjEnterCallback(function(oLuaObj, bReconnect) self:OnObjEnter(oLuaObj, bReconnect) end)
			oDup:RegObjLeaveCallback(function(oLuaObj, nBattleID) self:OnObjLeave(oLuaObj, nBattleID) end)
			oDup:RegObjAfterEnterCallback(function(oLuaObj, nBattleID) self:ObjAfterEnter(oLuaObj, nBattleID) end)
			
	    end
	end
end

function CPVEActivityMgr:GetType() return  self.m_nType end		--取战斗副本类型
function CPVEActivityMgr:GetID() return self.m_nID end 			--副本战斗ID
function CPVEActivityMgr:HasRole() return next(self.m_tRoleMap) end --是否有玩家
function CPVEActivityMgr:GetConf() return ctDailyActivity[self.m_nDupType] end

--TODD，保持时时性一，一秒钟我检查一下
function CPVEActivityMgr:RegTick()
	if self:IsSceneLogic() then
		self.m_nTimer = goTimerMgr:Interval(1, function() self:CheckActOpen() end)
		assert(self.m_nTimer, "定时器错误")
	end
end


--不是准备场景的所在的逻辑服就不创建注册器了
function CPVEActivityMgr:IsSceneLogic()
	local nCurService = GF.GetServiceID()
	local nTarService = self:GetReadySceneServiceID(nSceReadySceneID)
	if nCurService == nTarService then
        return true
    else
      	return false
     end
end

function CPVEActivityMgr:InitActState()
	local nACtivivtyId = self:GetActivityID()
	self.m_tActState[nACtivivtyId] = false
end

--是否过了准备时间
function CPVEActivityMgr:IsActOpen()
	local nSec = os.time()
	if nSec < self.m_nActivityStamp +  self.m_nReadyTime * 60 then
		return false
	end
	return true
end

function CPVEActivityMgr:CheckActOpen()
	local nACtivivtyId = self:GetActivityID()
	local nOpenTime = ctDailyActivity[nACtivivtyId].nOpenTime
    local nCloseTime = ctDailyActivity[nACtivivtyId].nCloseTime
    local nCurrHour = os.date("%H")
    local nCurrMin = os.date("%M")
    local nCurrTime = tonumber(nCurrHour .. nCurrMin)
   	--TODD如果指令开启了活动,那么这里不执行检测，直到活动时间结束,因为这里开启的活动可能不是今天所开的活动
   --print(self.m_nCurrGmOpenActID)
   	if self.m_nCurrGmOpenActID == 0 then
	    if nCurrTime >= nOpenTime and  nCurrTime < nCloseTime then
	    	if not self.m_tActState[nACtivivtyId] then
	    		self.m_tActState[nACtivivtyId] = true
	    		self.m_nActivityStamp = os.time()
	    		self.m_nReadyTime = 5
	    		self:NotifyActivityOpen()
	    	end
	    else
	    	if self.m_tActState[nACtivivtyId] then
	    		self.m_tActState[nACtivivtyId] = nil
	    		self:NotifyActivityClose()
	    	end
	    	
	    end
	end
end

function CPVEActivityMgr:PVEActivityCheckStatusReq()
	local bOpenState = false
	local tActData = {}
	for nACtivivtyId, bOpen in pairs(self.m_tActState) do
		bOpenState = bOpen
		local nNpcID = ctDailyActivity[nACtivivtyId].nID
		assert(nNpcID >= 0, string.format("%s活动NPC配置错误", ctDailyActivity[nACtivivtyId].sActivityName))
		local tAct = {nACtivivtyId = nACtivivtyId, nNpcID = nNpcID}
		table.insert(tActData, tAct)
	end
	return bOpenState, tActData
end

function CPVEActivityMgr:GetActOpenData()
	local nACtivivtyId = self:GetActivityID()
	return self.m_tActState[nACtivivtyId]
end

function CPVEActivityMgr:GetActNpcID()
	local nACtivivtyId = self:GetActivityID()
	local nNpcID = ctDailyActivity[nACtivivtyId].nID
	assert(nNpcID >= 0, string.format("%s活动NPC配置错误", ctDailyActivity[nACtivivtyId].sActivityName))
	return nNpcID
end

function CPVEActivityMgr:NotifyActivityOpen() 
	goRemoteCall:Call("GPVEActivityOpenNotify", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, 
		self:GetActivityID(), self:GetActNpcID(), gnServerID)
end

function CPVEActivityMgr:NotifyActivityClose() 
	print(string.format("活动(%d)结束，通知销毁NPC", self:GetActivityID()))
	goRemoteCall:Call("GPVEActivityCloseNotify", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, 
		self:GetActivityID(), self:GetActNpcID(), gnServerID)
end


function CPVEActivityMgr:ISGMOpenAct()
	return self.m_nCurrGmOpenActID ~= 0 and true or false
end

--对象进入准备大厅
function CPVEActivityMgr:OnObjEnter(oLuaObj, bReconnect)
	print("CPVE:OnObjEnter***", bReconnect)
	local nObjType = oLuaObj:GetObjType() --gtObjType
	--怪物
	if nObjType == gtObjType.eMonster then
		self.m_tMonsterMap[oLuaObj:GetID()] = oLuaObj
		self:SyncDupInfo()
	--人物
	elseif nObjType == gtObjType.eRole then
		if bReconnect then
			self:ObjAfterEnter(oLuaObj)
		end
	end
end

--玩家离线后再次登录检查,时间过了就踢出大厅
function CPVEActivityMgr:ActOpenCloseCheck(oRole)

	--TODD...GM开启的开启的活动不做一下条件检查
	if  self.m_nCurrGmOpenActID == 0 then
		local nACtivivtyId = self:GetActivityID()
		local nOpenTime = ctDailyActivity[nACtivivtyId].nOpenTime
		local nCloseTime = ctDailyActivity[nACtivivtyId].nCloseTime
		local nCurrHour = os.date("%H")
		local nCurrMin = os.date("%M")
		local nCurrTime = tonumber(nCurrHour .. nCurrMin)
		--满足这个条件,主动把玩家踢出装备场景
		if nCurrTime < nOpenTime or nCurrTime >= nCloseTime then
		   	print("满足条件,把玩家踢出大厅", oRole:GetID())
		   	 oRole:SetBattleDupID(0)
		      self.m_tRoleMap[oRole:GetID()] = nil
		      oRole:EnterLastCity()
		      return
		end 
	end
   	return true
end

function CPVEActivityMgr:GetActOpenState()
	local nACtivivtyId = self:GetActivityID()
	local nOpenTime = ctDailyActivity[nACtivivtyId].nOpenTime
    local nCloseTime = ctDailyActivity[nACtivivtyId].nCloseTime
    local nCurrHour = os.date("%H")
    local nCurrMin = os.date("%M")
    local nCurrTime = tonumber(nCurrHour .. nCurrMin)
    if nCurrTime >= nOpenTime and nCurrTime < nCloseTime then
    	self.m_tActState[nACtivivtyId] = true
    else
    	self.m_tActState[nACtivivtyId] = nil
    end
    return self.m_tActState[nACtivivtyId]
end


--对象进入成功检查,在条件范围内才给他推送信息
function CPVEActivityMgr:ObjAfterEnter(oLuaObj)
	if self:ActOpenCloseCheck(oLuaObj) then
		self:PushTime(oLuaObj)
		self.m_tRoleMap[oLuaObj:GetID()] = oLuaObj
		oLuaObj:SetBattleDupID(self:GetID())
		self:SyncDupInfo(oLuaObj)
		self:InitStamp()
	end
end

function CPVEActivityMgr:InitStamp()
	if not self.m_nRankingTimer then
		local nOverMis = CDailyActivity:GetEndStamp(self:GetActivityID())
		if self:ISGMOpenAct() then
			assert(self.m_nActivityEndStamp > os.time() , "GM开启时间错误")
			--TODD--nOverMis = self.m_nActivityEndStamp * 60副本玩法时间
			nOverMis = self.m_nActivityEndStamp - os.time()
		else
			assert(nOverMis > os.time(), "活动结束时间错误" .. nOverMis)
			nOverMis = nOverMis - os.time()
		end
		print("活动结算时间+++++++++++++++++++++++++", nOverMis)
		self.m_nRankingTimer = goTimerMgr:Interval(nOverMis, function() self:PVEActSettle() end)
		assert(self.m_nRankingTimer, "创建定时器错误")
	end
end

--获取每日开启活动ID
function CPVEActivityMgr:GetActivityID()
	if self.m_nCurrGmOpenActID ~= 0 then
		return self.m_nCurrGmOpenActID
	end
	local nWDay = os.WDay(os.time())
	return _PVEBattleDupType[nWDay]
end

function CPVEActivityMgr:PushTime(oRole)
	--开启时间检查
	local nACtivivtyId = self:GetActivityID()
	local nOpenTime = ctDailyActivity[nACtivivtyId].nOpenTime
    local nCloseTime = ctDailyActivity[nACtivivtyId].nCloseTime                                 
    local nCurrHour = os.date("%H")
    local nCurrMin = os.date("%M")
    local nCurrTime = tonumber(nCurrHour .. nCurrMin)
    local nDownTime = nOpenTime + 5
    local tMsg = {sName = sName}
    local sName = self:GetCheckpoinName() or ""
    if self.m_nCurrGmOpenActID == 0 then
		if nCurrTime < nDownTime then
			local nOverMin =  nDownTime - nCurrTime
			local nOverMis = 60 - os.date("%S")
			if nOverMin > 1 then
				nOverMis = nOverMis + (nOverMin - 1) * 60
			end
			tMsg ={nSec = nOverMis, nStatus = 1, sName = sName}
		else
			tMsg ={nStatus = 2, sName = sName}
		end
	else
		--TODD,GM开启情况下读GM设置的
		local nOverMis = self.m_nActivityStamp + self.m_nReadyTime * 60
		if nOverMis > os.time() then
			tMsg ={nSec = nOverMis - os.time(), nStatus = 1, sName = sName}
		else
			tMsg ={nStatus = 2, sName = sName}
		end
	end
	print("倒计时推送", tMsg)
	oRole:SendMsg("PVEStartTimeRet", tMsg)
end

function CPVEActivityMgr:GetCheckpoinName()
	local nDupID =  self:GetDupCofID()
	if nDupID then
		local sName = ctMonsterConf[nDupID].sName
		return sName
	end
end

function CPVEActivityMgr:GetDupCofID()
	local nActID = self:GetActivityID()
	if nActID == gtDailyID.eJueZhanJiuXiao then
		for nTaskId, tItemConf in pairs(ctJueZhanJiuXiao) do
			return tItemConf.nBattleGroup
		end
	elseif nActID == gtDailyID.eHunDunShiLian then
		local tDupConf = ctBattleDupConf[nActID]
		return tDupConf.tMonster[1][1]
	end
end

function CPVEActivityMgr:OnObjLeaveReq()
	self.m_tRoleMap[oRole:GetID()] = nil
     oLuaObj:SetBattleDupID(0)
end

--对象离开准备大厅
function CPVEActivityMgr:OnObjLeave(oLuaObj, nBattleID)
    print("对象离开准备大厅:OnObjLeave***")
    local nObjType = oLuaObj:GetObjType() --gtObjType
    --怪物
    if nObjType == gtObjType.eMonster then
        self.m_tMonsterMap[oLuaObj:GetID()] = nil

    --人物
    elseif nObjType == gtObjType.eRole then
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

--同步场景信息
function CPVEActivityMgr:SyncDupInfo(oRole)
	local tMsg = {tMonster={nDupMixID=0, nDupID=0, nMonObjID=0, nMonsterPosX=0, nMonsterPosY=0}, tDupList={}}
	local nMonsterID = next(self.m_tMonsterMap)
	local oMonster = self.m_tMonsterMap[nMonsterID]
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
		CmdNet.PBBroadcastExter("BattleDupInfoRet", tSessionList, tMsg)
	end
end

--取会话列表
function CPVEActivityMgr:GetSessionList()
	local tSessionList = {}
	for _, oRole in pairs(self.m_tRoleMap) do
		if not oRole:IsRobot() and oRole:IsOnline() then
			table.insert(tSessionList, oRole:GetServer())
			table.insert(tSessionList, oRole:GetSession())
		end
	end
	return tSessionList
end

function CPVEActivityMgr:GetDupID()
	local oDup = self.m_tDupList[1]
	return oDup:GetMixID()
end

function CPVEActivityMgr:EnterReadyDupReq(oRole)
	local nACtivivtyId = 10400
	local nDupnLogic = ctDupConf[nACtivivtyId].nLogic
	if not nDupnLogic then
		return 
	end

	local _fnEnterDupCheck = function (nDupMixID)
		assert(nDupMixID, "副本唯一ID错误")
		local tConf = assert(ctDupConf[GF.GetDupID(nDupMixID)])
		oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
	end

	if GF.GetServiceID() == nDupnLogic then
		local bReturnTeam,nDupMixID, sReason = self:EnterDupCheck(oRole:GetLevel())
		if not bReturnTeam then
			return oRole:Tips(sReason)
		end
		_fnEnterDupCheck(nDupMixID)
	else
		local fnGetDupSecneCallBack = function (bReturnTeam, nDupMixID, sReason)
			if not bReturnTeam then 
				return oRole:Tips(sReason)
			end
			_fnEnterDupCheck(nDupMixID)
		end
	 	local nTarService = nDupnLogic
		goRemoteCall:CallWait("PVEActivityEnterCheckReq", fnGetDupSecneCallBack, oRole:GetServer(), nTarService, 0, oRole:GetLevel())
	end
end

function CPVEActivityMgr:EnterDupCheck(nLevel)
	local nActID = self:GetActivityID()
	assert(nActID, "活动ID错误")
	local tDupConf = ctDailyActivity[nActID]
	if not tDupConf then return false,0, "副本配置错误" end
	if self.m_nCurrGmOpenActID == 0 then
			--开启时间检查
		local nOpenTime = ctDailyActivity[nActID].nOpenTime
	    local nCloseTime = ctDailyActivity[nActID].nCloseTime
	    local nCurrHour = os.date("%H")
	    local nCurrMin = os.date("%M")
	    local nCurrTime = tonumber(nCurrHour .. nCurrMin)
	    local bOpenFalg = false
	    if nCurrTime >= nOpenTime or nCurrTime > nCloseTime then
	        if nCurrTime > nCloseTime then  --活动时间结束设置活动结束
	           return false,0, "活动尚未开启"
	        end
	        bOpenFalg = true
	    end
	    if not bOpenFalg then return false, 0, "活动尚未开启"end
		local nWDay = os.WDay(os.time())
		local bFalg = false
		for _, tConf in pairs(tDupConf.tOpenList) do
			if tConf[1] == nWDay then
				bFalg = true
				break
			end
		end
		if not bFalg then return false,0, "该副本今日没有开放" end
	end
	local nLevelLimit = tDupConf.nLevelLimit
	if nLevel < nLevelLimit then
		return false,0, "您的等级不够" .. nLevelLimit .."级,请升到" ..nLevelLimit .."级再来吧"
	end
	return true, self:GetDupID(),""
end

function CPVEActivityMgr:EnterCheckReq(nLevel)
	return self:EnterDupCheck(nLevel)
end

function CPVEActivityMgr:OnRelease()
	 goTimerMgr:Clear(self.m_nRankingTimer)
	 self.m_nRankingTimer = nil
	goTimerMgr:Clear(self.m_nTimer)
	self.m_nTimer = nil
	goTimerMgr:Clear(self.m_nGMOpenActEndTimer)
	self.m_nGMOpenActEndTimer = nil
end

function CPVEActivityMgr:SetDupType(nDupType)
	if not nDupType then return end
	self.m_nDupType = nDupType
end

function CPVEActivityMgr:GetOpenLevel()
	local nACtivivtyId = self:GetActivityID()
	local nOpenLevel = ctDailyActivity[nACtivivtyId].nOpenLimit
	return nOpenLevel
end

--PVE副本结算,按照完成时间排序(数据放到管理器来处理，这样就不用为每一个活动在每一个对应的逻辑服上创建一个管理器)
function CPVEActivityMgr:PVEActSettle()
	 goTimerMgr:Clear(self.m_nRankingTimer)
	 self.m_nRankingTimer = nil
	local tActData =  self.m_tPVEAppellationData
	local tPVEData = {}
	local fnCmp = function(tTeam1, tTeam2) 
		return tTeam1.nCompleteTime > tTeam2.nCompleteTime
	end
	for nTeamID, tData in pairs(tActData or {}) do
		if tData.nCompleteTime ~= 0 then
			table.insert(tPVEData, tData)
		end
	end
	--处理一下相同时间完成的情况
	table.sort(tPVEData, fnCmp)
	local nCurRankingCount = 0
	local nSunRankingCount,AppellationID = self:GetRankingCount()
	local bState = false
	local tParam = self:GetAppellationTime()
	local tAppeData = 
		{
			nOpType = gtAppellationOpType.eAdd, 
			nConfID = AppellationID, 
			tParam = tParam, 
			nSubKey = 0,
		}
	for nKey, tRoleActData in ipairs(tPVEData) do
		for _, tRoleData in pairs(tRoleActData.tRoleData or {}) do
			if not  tRoleData.bLeave then
				local oRole = goPlayerMgr:GetRoleByID(tRoleData.nRoleID)
				if oRole then 
					oRole:AppellationUpdate(tAppeData)
				else
					goRemoteCall:Call("AppellationUpdateReq", gnWorldServerID, 
						goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, tRoleData.nRoleID, tAppeData)
				end
			end
		end
		--处理排名相同的情况
		if not tPVEData[nKey - 1] then
			nCurRankingCount = nCurRankingCount + 1 
		elseif tPVEData[nKey - 1] and tPVEData[nKey - 1].nCompleteTime ~= tPVEData[nKey].nCompleteTime then
			nCurRankingCount = nCurRankingCount + 1 
		end
		if nCurRankingCount >= nSunRankingCount then
			break
		end
	end
	self.m_tPVEAppellationData = {}
	self.m_tPVERoleData = {}

	--活动结束踢出在场景的玩家
	self:ActEnd()
end

function CPVEActivityMgr:ActEnd()
	--强制结束战斗，然后在销毁副本
	for nRoleID, oRole in pairs(self.m_tRoleMap) do
		local nBattleID = oRole:GetBattleID()
		if nBattleID > 0 then
			local oBattle = goBattleMgr:GetBattle(nBattleID)
			if oBattle then
				oBattle:ForceFinish()
			end
		end
		oRole:EnterLastCity()
	end
end

function CPVEActivityMgr:GetRankingCount()
	local nACtivivtyId = self:GetActivityID()
	if nACtivivtyId == gtDailyID.eJueZhanJiuXiao then
		return nJueZhanJiuXiaoRanking, nJueZhanJiuXiaoAppellationID
	elseif nACtivivtyId == gtDailyID.eHunDunShiLian then
		return nHunDunShiLianRanking, nHunDunShiLianAppellationID
	end
end

function CPVEActivityMgr:GetReadySceneServiceID(nMapID)
	assert(nMapID > 0,  "参数错误")
	local tDupConf = ctDupConf[nMapID]
	assert(tDupConf, "配置文件错误" .. nMapID)
	return tDupConf.nLogic
end

--获取限时称谓时间
function CPVEActivityMgr:GetAppellationTime()
	local nACtivivtyId = self:GetActivityID()
	local tActData = ctDailyActivity[nACtivivtyId]
	local nNowTime = os.time()
	local nCloseTime = tActData.nOpenTime
	local nHour, nMin = math.modf(nCloseTime/100)
	local tParam = {}
	local nWDay = os.WDay(nNowTime)
	local nDayTimes = 0
	nWDay = nWDay >= 7 and 1 or nWDay + 1
	for i = 1, 7, 1 do
		nDayTimes = nDayTimes + 1
		if _PVEBattleDupType[nWDay] == nACtivivtyId then
			break
		end
		nWDay = nWDay + 1
	end
	local nZreoSec = os.ZeroTime(nNowTime)
	local nOverSec = (nZreoSec + 24 * 3600) - nNowTime
	if nDayTimes > 1 then
		local nTmpDay = nDayTimes - 1
		nOverSec = nOverSec + (nTmpDay * 24 * 3600) + (nHour * 3600 + (nMin * 100) * 60)
	else
		nOverSec = nOverSec + (nHour * 3600 + (nMin * 100) * 60)
	end
	tParam.nExpiryTime = nOverSec + nNowTime
	return tParam
end

function CPVEActivityMgr:EnterBattleDupReq(oRole)
	if not self:IsActOpen() then
		return oRole:Tips("活动处于准备时间哦")
	end
	self.m_nDupType = self:GetActivityID()
	local tDupConf = ctDailyActivity[self.m_nDupType]
	if not tDupConf then
		return oRole:Tips("副本配置错误")
	end
	if self.m_nDupType == 203 then return oRole:Tips("该副本没有开放") end
	local oDup = oRole:GetCurrDupObj()
	if oDup:GetConf().nBattleType == self.m_nDupType then
		return oRole:Tips(gtPVEBattleDupName[self.m_nDupType])
	end
	local tBattleDupConf = ctBattleDupConf[self.m_nDupType]

	--创建副本回调
	local fnCreateBattleDupCallBack = function(nDupMixID)
		  local tConf = assert(ctDupConf[GF.GetDupID(nDupMixID)])
		  oRole:EnterScene(nDupMixID, tConf.tBorn[1][1], tConf.tBorn[1][2], -1, tConf.nFace)
	end

	--获取队伍回调
	local fnGetTeamCallBack = function (nTeamID, tTeam)
		--当前没有队伍
		--自己是队长
		local nReturnCount =0
		for _, tRole in pairs(tTeam or {}) do
			if not tRole.bLeave then nReturnCount = nReturnCount+1 end
		end
		if nReturnCount < tBattleDupConf.nTeamMembs then
			--队员小于3人
			local sCont = string.format("此任务需要%d人以上队伍，是否加入便捷组队？", tBattleDupConf.nTeamMembs)
			local tOption = {"取消", "确定"}
			local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10, nTimeOutSelIdx=1}
			goClientCall:CallWait("ConfirmRet", function(tData)
				if tData.nSelIdx == 2 then	
					self:ConvenientTeam(oRole)
				end
			end, oRole, tMsg)
		else	--归队任务大于3人开始副本流程
			goBattleDupMgr:CreateBattleDup(self.m_nDupType, fnCreateBattleDupCallBack)		
		end
	end
	oRole:GetTeam(fnGetTeamCallBack)
end

function CPVEActivityMgr:MatchTeamReq(oRole, nType)
	--创建队伍
	if nType == 1 then
		--判断当前有没有队伍
		local fnJoinTeamCallBack = function(nTeamID, tTeam)
			  if nTeamID == 0 then
			  	--当前没有队伍
			  	local fnCreateTeamCallBack = function(nTeamID, tTeam)
			  		  if nTeamID == 0 then
			  		  	oRole:Tips("创建队伍失败")
			  		  end
			  	end
			  	oRole:CreateTeam(fnCreateTeamCallBack)

			  else
			  	oRole:Tips("你已经有队伍了，不用重复创建")
			  end
		end
		oRole:GetTeam(fnJoinTeamCallBack)
		
	--便捷组队
	elseif nType == 2 then
		self:ConvenientTeam(oRole)
	end
end

--便捷组队
function CPVEActivityMgr:ConvenientTeam(oRole)
	--确定便捷组队
	local sActivityName = ctDailyActivity[self:GetActivityID()].sActivityName
	local tBattleDupConf = ctBattleDupConf[self:GetActivityID()]
	self.m_nDupType = self:GetActivityID()
	if oRole:GetTeamID() <= 0 then	
		oRole:MatchTeam(self.m_nDupType, tBattleDupConf.sName, true)
		oRole:GetTeam(function(nTeamID, tTeam)
			if nTeamID <= 0 then
				--确定便捷组队，若玩家没有队伍
				oRole:CreateTeam(function(nTeamIDNew, tTeamNew)
					if not nTeamIDNew then
						return oRole:Tips("创建队伍失败")
					else
						oRole:MatchTeam(self.m_nDupType, tBattleDupConf.sName, true)
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
				local tOption = {"继续匹配", "加入队伍"}
				local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=10, nTimeOutSelIdx=1}
				goClientCall:CallWait("ConfirmRet", function(tData)
					if tData.nSelIdx == 1 then		--继续匹配
						oRole:MatchTeam(self.m_nDupType, tBattleDupConf.sName, true)
					else	--加入队伍
						local function JoinMergeTeamCallBack(bIsMergeSucc)
							if not bIsMergeSucc then
								oRole:MatchTeam(self.m_nDupType, tBattleDupConf.sName, true)
							end
						end
						goRemoteCall:CallWait("JoinMergeTeamReq", JoinMergeTeamCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oRole:GetSession(), oRole:GetTeamID(), self.m_nDupType)
					end
				end, oRole, tMsg)
			else
				oRole:MatchTeam(self.m_nDupType, tBattleDupConf.sName, true)
			end
		end
		goRemoteCall:CallWait("CheckJoinMergeTeamReq", CheckCallBack, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), oRole:GetSession(), oRole:GetTeamID(), self.m_nDupType)										
	end
end

function CPVEActivityMgr:ReturnTeamCheck(oRole)
	local nActID = self:GetActivityID()
	local tActData = ctDailyActivity[nActID]
	if not tActData then return false end
	if oRole:GetLevel() < tActData.nLevelLimit then
		return false, string.format("队长正在参与%s，您等级低于%d级，归队失败", tActData.sActivityName,tActData.nLevelLimit)
	end
	if not oRole:IsSysOpen(tActData.nSysOpenID) then
		-- return false,string.format("队长正在参与%s，暂未对你开放哦,归队失败", tActData.sActivityName)
		return false, string.format("队长正在参与%s，%s，归队失败", tActData.sActivityName, oRole:SysOpenTips(tActData.nSysOpenID))
	end
	return true
end

--参加活动条件检查
function CPVEActivityMgr:JoinActConditionCheck(oRole)
	local bReturn, sReason = self:ReturnTeamCheck(oRole)
	if not bReturn and sReason then
		return oRole:Tips(sReason)
	end
	return bReturn
end


function CPVEActivityMgr:SettlementActData(nTeamID, tData)
	local tActData =  self.m_tPVEAppellationData[nTeamID]
	if not tActData then 
		tActData = {}
		tActData.nCompleteTime = 0
		tActData.tRoleData = {}
	end
	if tActData.tRoleData[tData.nRoleID] then
		return
	end
	tActData.tRoleData[tData.nRoleID] = tData
	self.m_tPVEAppellationData[nTeamID] = tActData
end

function CPVEActivityMgr:GetSettlementActData(nTeamID)
	return self.m_tPVEAppellationData[nTeamID]
end

function CPVEActivityMgr:PVEDataChange(nTeamID, tRoleActData)
	print("玩家退出称谓数据", tRoleActData)
	local tActData = self.m_tPVEAppellationData[nTeamID]
	if not tActData then return end
	if tActData.nCompleteTime > 0 then return end
	for _, tRoleData in pairs(tActData.tRoleData or {}) do
		if tRoleData.nRoleID == tRoleActData.nRoleID then
			tRoleData.bLeave = tRoleActData.bLeave
			break
		end
	end
end


--防止重复给玩家计入奖励对象
function CPVEActivityMgr:RemoveRoleData(nTeamID, nCompleteTime)
	local _RemoveRoleData = function (nTeamID, nRoleID)
		local tPVEData = self.m_tPVEAppellationData[nTeamID]
		tPVEData.tRoleData[nRoleID] = nil
	end

	local tPVEData = self.m_tPVEAppellationData[nTeamID]
	if not tPVEData then return end
	for _, tRoleActData in pairs(tPVEData.tRoleData) do
		if self.m_tPVERoleData[tRoleActData.nRoleID] then
			_RemoveRoleData(nTeamID, tRoleActData.nRoleID)
		else
			self.m_tPVERoleData[tRoleActData.nRoleID] = true
		end
	end
end

function CPVEActivityMgr:PVEDataCheckReq(nTeamID, nCompleteTime)
	print("限时活动完成记录数据", nCompleteTime)
	if nCompleteTime <= 0 then return end
	if not self.m_nRankingTimer then return end
	local tActData =  self.m_tPVEAppellationData[nTeamID]
	if not tActData then return end
	tActData.nCompleteTime = nCompleteTime or 0
	self:RemoveRoleData(nTeamID, nCompleteTime)
end

function CPVEActivityMgr:ClearPVEData(oRole)
	oRole:ResetPVEData()
	oRole:Tips("清除成功")
end

function CPVEActivityMgr:OpenAct(nActID, nReadyTime, nEndTime)
	local sReason
	if not nActID then 
		return "活动ID错误"
	end
	if not ctDailyActivity[nActID] then
		return "活动ID错误"
	end

	if not self:ISPVEAct(nActID) then
		return "该活动不是PVE类型"
	end

	if self.m_tActState[nActID] then
		local nOverSec = self.m_nActivityEndStamp - os.time()
		local nHour, nMin, nSec = os.SplitTime(nOverSec)
		return string.format("当前活动已经开启了,剩余持续时间为%d分%d秒", nMin, nSec)
	end
	if self.m_nCurrGmOpenActID ~= 0 then
		local sActivityName = ctDailyActivity[self.m_nCurrGmOpenActID].sActivityName
		return string.format("当前已经开启了%s活动哦，关闭后再开启新的活动哦", sActivityName)
	end
	local nEndTime = nEndTime

	--TODD活动持续时间，这个时间跟里面战斗副本时间一致,最多开启一个小时
	local nNowTime = os.time()
	local nMin = nEndTime > 60 and 60 or nEndTime
	self.m_nActivityEndStamp = nMin * 60 + nNowTime + nReadyTime * 60
	self.m_nActivityStamp = os.time()
	self.m_nReadyTime = nReadyTime
	self.m_nCurrGmOpenActID = nActID
	self.m_tActState[self.m_nCurrGmOpenActID] = true
	self:NotifyActivityOpen()
	self.m_nGMOpenActEndTimer = goTimerMgr:Interval(self.m_nActivityEndStamp - os.time(), function() self:GMOpenActEnd() end)
	assert(self.m_nGMOpenActEndTimer, "定时器错误")
	sReason ="开启活动成功,持续时间为" .. nEndTime .."分钟"
	return sReason
end

function CPVEActivityMgr:GMOpen(nActID, nReadyTime, nEndTime, oRole)
	local nTarService= goPVEActivityMgr:GetReadySceneServiceID(10400)
	--TODD判断当前开启的活动是不是跟管理器在同一个逻辑服
	if nTarService == GF.GetServiceID() then
		 local sReason= self:OpenAct(nActID, nReadyTime, nEndTime)
		 if sReason and type(sReason) == "string" then
		 	return oRole:Tips(sReason)
		 end
	else
		 local fnOpenActCallBack = function (sReason)
		 	if sReason then
		 		oRole:Tips(sReason)
		 	end
		 end
		 goRemoteCall:CallWait("PVEOpenActReq",fnOpenActCallBack, GF.GetServiceID(), nTarService, 0, oRole:GetID(), nActID, nReadyTime, nEndTime)
	end
end

function CPVEActivityMgr:ISPVEAct(nACtivivtyId)
	for _, nActID in pairs(_PVEBattleDupType) do
		if nActID == nACtivivtyId then
			return true
		end
	end
	return false
end

function CPVEActivityMgr:GMOpenActEnd()
	if self.m_nGMOpenActEndTimer then
		goTimerMgr:Clear(self.m_nGMOpenActEndTimer)
		self.m_nGMOpenActEndTimer = nil
	end

	local nDupType = self.m_nCurrGmOpenActID
	--释放结算定时器
	if self.m_nRankingTimer then
		 goTimerMgr:Clear(self.m_nRankingTimer)
		 self.m_nRankingTimer = nil
	end

	--结算称谓数据
	self:PVEActSettle()

	--TODD时间到以后把当前活动恢复到初始状态
	self.m_tActState[self.m_nCurrGmOpenActID] = nil
	self:NotifyActivityClose()
	self.m_nCurrGmOpenActID = 0 
	self.m_nActivityEndStamp = 0
	self.m_nActivityStamp = 0
	self.m_nReadyTime = 0

	--调用一下副本玩法管理器。销毁指定类型的的副本
	local tDupList = ctBattleDupConf[nDupType].tDupList
	if tDupList[1][1] <= 0 then
		return LuaTrace("副本玩法配置不存在:"..nDupType)
	end

	--副本在当前逻辑服
	local tDupConf = assert(ctDupConf[tDupList[1][1]])
	if tDupConf.nLogic == GF.GetServiceID() then
		goBattleDupMgr:DestroyAssignTypeBattleDup(nDupType)
	else
		--不在当前逻辑服
		local nServerID = tDupConf.nLogic>=100 and gnWorldServerID or nServerID
		goRemoteCall:Call("DestroyAssignTypeBattleDupReq", nServerID, tDupConf.nLogic, 0, nDupType)
	end
end

function CPVEActivityMgr:GetActEndTime()
	return self.m_nActivityEndStamp
end

function CPVEActivityMgr:GetISGMOpenAct()
	return self:ISGMOpenAct(), self:GetActEndTime()
end


function CPVEActivityMgr:GMClose(nActID, oRole)
	local nTarService= goPVEActivityMgr:GetReadySceneServiceID(10400)
	if nTarService == GF.GetServiceID() then
		local sReason = self:CloseAct(nActID)
		if sReason then 
			oRole:Tips(sReason)
		end
	else
		 local fnCloseActCallBack = function (sReason)
		 	if sReason then
		 		oRole:Tips(sReason)
		 	end
		 end
		 goRemoteCall:CallWait("PVECloseActReq",fnCloseActCallBack, GF.GetServiceID(), nTarService, 0, nActID)
	end
end

function CPVEActivityMgr:CloseAct(nActID)
	if not nActID then 
		return "活动ID错误"
	end
	if not ctDailyActivity[nActID] then
		return "活动ID错误"
	end

	if not self.m_tActState[nActID] then
		return "当前活动已经关闭了"
	end
	self:GMOpenActEnd()
	return "活动关闭成功"
end



goPVEActivityMgr = goPVEActivityMgr or CPVEActivityMgr:new()
