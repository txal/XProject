--首席争霸管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CUnionArenaMgr:Ctor(nActivityID)
	print("开始创建<帮战>活动管理器")
	CPVPActivityMgrBase.Ctor(self, nActivityID)
	self.m_tMatchUnion = {}
	self.m_tMatchEmpty = {}
end

function CUnionArenaMgr:OnActivityStart()
	print("<帮战>活动开始，开始创建实例")
	
	self.m_tMatchUnion = {}
	self.m_tMatchEmpty = {}

	local tPackServer = {}
	local tAllUnionData = {}
	local tServerList = {}

	local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
		if tConf.nServer ~= gnWorldServerID and 
			math.abs(os.time() - goServerMgr:GetOpenZeroTime(tConf.nServer)) > 7*24*3600 then
    		tServerList[tConf.nServer] = tConf
    	end
	end

	local fCallback = function (tRet)
		local nServerID = tRet.nServerID
		local tRetUnionData = tRet.tUnionData or {}
		for nUnionID, tUnionData in pairs(tRetUnionData) do
			tAllUnionData[nUnionID] = tUnionData
		end
		tPackServer[nServerID] = tRetUnionData
		tServerList[nServerID] = nil
		if next(tServerList) then 
			return 
		end
		if not next(tPackServer) then 
			return 
		end
		self:OnActivityStart2(tAllUnionData,tPackServer)
	end

	--获取所有联盟信息
	local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
    for nServerID, tConf in pairs(tServerList) do
    	Network:RMCall("PackUnionArenaData",fCallback,tConf.nServer,tConf.nID,0)
	end
	CPVPActivityMgrBase.OnActivityStart(self) --帮战这个比较特殊，这里还没创建帮战活动实例
end

function CUnionArenaMgr:OnActivityStart2(tAllUnionData, tServerUnion)
	local tMatchUnion, tArenaUnion, tMatchEmpty = self:Match(tAllUnionData)
	for nServerID,tServerUnionData in pairs(tServerUnion) do
		local tServerMatchUnionData = {}
		for nUnionID,_ in pairs(tServerUnionData) do
			tServerMatchUnionData[nUnionID] = tMatchUnion[nUnionID] or 0
		end
		--TODO 后续如果这里数据过大，也需要优化
		Network:RMCall("MatchUnionArena", nil,nServerID,goServerMgr:GetGlobalService(nServerID, 20),0,tServerMatchUnionData)
	end
	--匹配对应关系,A->B,B->A
	self.m_tMatchUnion = tMatchUnion
	self.m_tMatchEmpty = tMatchEmpty

	local nOpenTime = self:GetOpenTime()
	local nEndTime = self:GetEndTime()
	local nPrepareLastTime = self:GetPrepareLastTime()
	local nActivityID = self:GetActivityID()
	local tSceneConf = CPVPActivityMgr:GetActivitySceneConf(nActivityID)
	assert(tSceneConf, "找不到配置")

	local tArenaRecord = {}
	for nUnionID,nEnemyUnionID in pairs(tArenaUnion) do
		if nUnionID >= 0 and nEnemyUnionID > 0 and not tArenaRecord[nUnionID] and not tArenaRecord[nEnemyUnionID] then
			tArenaRecord[nUnionID] = true
			tArenaRecord[nEnemyUnionID] = true
			local oInst = CUnionArena:new(self, nActivityID, tSceneConf.nID, nUnionID,nEnemyUnionID, nOpenTime, nEndTime, nPrepareLastTime)
			self.m_tInstMap[nUnionID] = oInst
			local tUnion = {nUnionID,nEnemyUnionID}
			for _,nInstUnionID in pairs(tUnion) do
				local tUnionData = tAllUnionData[nInstUnionID]
				oInst:AddUnionData(nInstUnionID,tUnionData)
			end
		end
	end
end

function CUnionArenaMgr:Match(tAllUnionData)											
	local tMatchUnion = {}  --匹配信息
	local tArenaUnion = {}

	local fnCmp = function(tDataL, tDataR) 
		if tDataL.nLevel ~= tDataR.nLevel then 
			return tDataL.nLevel > tDataR.nLevel and -1 or 1 
		end
		if tDataL.nActivity ~= tDataR.nActivity then 
			return tDataL.nActivity > tDataR.nActivity and -1 or 1 
		end
		return tDataL.nUnionID < tDataR.nUnionID and -1 or 1
	end
	local oRBTree = CRBTree:new(fnCmp)
	for nUnionID, tUnionData in pairs(tAllUnionData) do 
		oRBTree:Insert(nUnionID, tUnionData)
	end

	--匹配
	while oRBTree:Count() >= 2 do 
		local nUnionID, tUnionData = oRBTree:GetByIndex(1)
		local nEnemyID
		local nCheckCount = math.min(oRBTree:Count() - 1, 5)  --最多检查5个
		for k = 1, nCheckCount do 
			local nEnemyUnionID, tEnemyData = oRBTree:GetByIndex(k + 1)
			if not tUnionData.tFightArenaRecord[nEnemyUnionID] then 
				nEnemyID = nEnemyUnionID
				break
			end
			if not nEnemyID then 
				nEnemyID = nEnemyUnionID
			else
				--比较下最近匹配到的时间戳
				if tUnionData.tFightArenaRecord[nEnemyID] >= 
					tUnionData.tFightArenaRecord[nEnemyUnionID] then 
					nEnemyID = nEnemyUnionID
				end
			end
		end

		oRBTree:Remove(nUnionID)
		oRBTree:Remove(nEnemyID)

		tMatchUnion[nUnionID] = nEnemyID
		tMatchUnion[nEnemyID] = nUnionID

		tArenaUnion[nUnionID] = nEnemyID
		tArenaUnion[nEnemyID] = nUnionID
	end

	local tMatchEmpty = {}
	local fnEmptyCallback = function(nDataRank, nDataIndex, nKey, tData) 
		tMatchEmpty[nKey] = tData
	end
	if oRBTree:Count() > 0 then --当前只会存在最多一个，兼容后续可能改动，暂时按照通用处理
		oRBTree:TraverseByDataRank(1, oRBTree:Count(), fnEmptyCallback)
	end

	return tMatchUnion, tArenaUnion, tMatchEmpty
end

function CUnionArenaMgr:GetActivityInst(nUnionID)
	local oInst = self.m_tInstMap[nUnionID]
	if oInst then
		return oInst
	end
	local nEnemyUnionID = self.m_tMatchUnion[nUnionID]
	if nEnemyUnionID then
		return self.m_tInstMap[nEnemyUnionID]
	end
end

function CUnionArenaMgr:GetInst(nUnionID)
	assert(nUnionID and nUnionID > 0, "参数错误")
	return self:GetActivityInst(nUnionID)
end

function CUnionArenaMgr:ValidJoin(oRole)
	local nUnionID = oRole:GetUnionID()
	if not nUnionID or nUnionID <= 0 then
		return false
	end
	local nJoinTime = oRole:GetUnionJoinTime()
	if os.time() - nJoinTime < 3 * 24 * 3600 and oRole:GetTestMan() ~= 99 then
		return false
	end
	return true
end

--请注意，这里不能使用语法糖的self及活动实例相关数据，玩家分布在不同的逻辑服上，并不确保处于活动所在逻辑服
function CUnionArenaMgr:EnterCheck(oRole, nActivityID, fnCallback) 
	local fnInnerCallback = function(bRet, sReason, nDupMixID) 
		if fnCallback then 
			fnCallback(bRet, sReason, nDupMixID)
		end
	end

	if not oRole:IsSysOpen(34) then 
		fnInnerCallback(false, oRole.m_oSysOpen:SysOpenTips(34))
		return 
	end
	local tConf = ctPVPActivityConf[nActivityID]
	assert(tConf, "配置数据错误")
	if oRole:GetLevel() < tConf.nLimitLevel then
		local sReason = string.format("需等级达到%d级方可参与", tConf.nLimitLevel)
		fnInnerCallback(false, sReason)
		return
	end
	local nOpenTime = goServerMgr:GetOpenZeroTime(oRole:GetServer())
	if os.time() <= (nOpenTime + 7*24*3600) then --开服7天之后，才开放
		fnInnerCallback(false, "开服7天后开启跨服帮战")
		return 
	end
	local nRoleID = oRole:GetID()
	if not self:ValidJoin(oRole) then
		-- oRole:Tips("只有加入帮派3天的帮众才可以参加")
		fnInnerCallback(false, "只有加入帮派3天的帮众才可以参加")
		return
	end
	local nUnionID = oRole:GetUnionID()
	local bTeam = tConf.bTeamPermit
	local nRoleTeamID = oRole:GetTeamID()
	if not bTeam then
		if nRoleTeamID > 0 then
			fnInnerCallback(false, "当前活动不允许组队进入，请先离队")
			return 
		end
	else
		if nRoleTeamID > 0 then
			oRole:GetTeam(function(nTeamID, tTeam)
				tTeam = tTeam or {}
				for _, tRole in pairs(tTeam) do
					local nTeamRoleID = tRole.nRoleID
					local oTeamRole = goPlayerMgr:GetRoleByID(nTeamRoleID)
					if oTeamRole and oTeamRole:GetUnionID() ~= nUnionID then
						-- oRole:Tips("不同帮派的玩家不能组队")
						fnInnerCallback(false, "不同帮派的玩家不能组队")
						return
					end
					if oTeamRole and not self:ValidJoin(oTeamRole) then
						-- oRole:Tips("只有加入帮派3天的帮众才可以参加")
						fnInnerCallback(false, "只有加入帮派3天的帮众才可以参加")
						return
					end
				end
				self:InstEnterCheck(nRoleID, nActivityID, fnCallback)
			end)
			return
		end
		self:InstEnterCheck(nRoleID, nActivityID, fnCallback)
	end
end

function CUnionArenaMgr:InstEnterCheck(nRoleID, nActivityID, fnCallback) 
	local fnInnerCallback = function(bRet, sReason, nDupMixID) 
		if fnCallback then 
			fnCallback(bRet, sReason, nDupMixID)
		end
	end

	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then 
		fnCallback(false)
		return 
	end

	local nCurService = CUtil:GetServiceID()
	local nTarService = CPVPActivityMgr:GetActivityServiceID(nActivityID)
	if nCurService ~= nTarService then
		Network:RMCall("PVPActivityEnterCheckReq", fnInnerCallback, oRole:GetServer(), 
					nTarService, 0, nActivityID, nRoleID, oRole:GetUnionID())
	else
		--调用本服的
		local bRet, sTipsCon, nSceneMixID = goPVPActivityMgr:EnterCheckReq(nActivityID, nRoleID,nUnionID)
		fnInnerCallback(bRet, sTipsCon, nSceneMixID)
	end

end

function CUnionArenaMgr:GetMatchedUnion(nUnionID) 
	return self.m_tMatchUnion[nUnionID]
end

--是否匹配轮空
function CUnionArenaMgr:IsMatchEmpty(nUnionID)
	-- local nMatchedUnion = self.m_tMatchUnion[nUnionID]
	-- if nMatchedUnion and nMatchedUnion <= 0 then 
	-- 	return true 
	-- else 
	-- 	return false 
	-- end
	if self.m_tMatchEmpty[nUnionID] then 
		return true 
	end
	return false
end

--是否有参与过匹配
function CUnionArenaMgr:IsJoinMatch(nUnionID) 
	if not self.m_tMatchUnion[nUnionID] and not self.m_tMatchEmpty[nUnionID] then 
		return false
	end
	return true 
end

