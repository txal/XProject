-- --队伍管理匹配部分
-- local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

-- -- 此副本内的便捷组队，只会匹配当前活动，也不需要玩家去选择
-- -- 点击按钮进入组队匹配状态，匹配状态下组成队伍或者再次点击便捷组队按钮会取消匹配
-- -- 如果玩家当前是未组队状态，则检查当前是否有空位的队伍。如果有，则向队伍发出申请。如果没有队伍，但有其他未组队的玩家，则将这些玩家创建成队伍，队伍最高级的人成为队长
-- -- 有多人可选择时，优先选择等级相近的人加入队伍
-- --清理现有匹配
-- function CTeamMgr:ClearOldMatch(nRoleID)
-- 	for nGameType, tGameMap in pairs(self.m_tMatchMap) do
-- 		if tGameMap[nRoleID] then tGameMap[nRoleID] = nil end
-- 	end
-- end

-- --取游戏匹配表
-- function CTeamMgr:GetGameMatchMap(nGameType)
-- 	if not self.m_tMatchMap[nGameType] then
-- 		self.m_tMatchMap[nGameType] = {}
-- 	end
-- 	return self.m_tMatchMap[nGameType]
-- end

-- --匹配请求
-- function CTeamMgr:MatchTeamReq(nRoleID, nGameType, sGameName)
-- 	--清理已有匹配
-- 	self:ClearOldMatch(nRoleID)
-- 	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)

-- 	--判断需不需要匹配
-- 	local oTeam = self:GetTeamByRoleID(nRoleID)
-- 	if oTeam and oTeam:IsFull() then
-- 		return oRole:Tips("队伍已满人无需匹配")
-- 	end
-- 	if oTeam and not oTeam:IsLeader(nRoleID) then
-- 		return oRole:Tips("队长才能操作")
-- 	end

-- 	if oTeam and oTeam:IsLeader(nRoleID) then
-- 		self.m_tBradcastInviteTimeMap = self.m_tBradcastInviteTimeMap or {}
-- 		local nLastSendTime = self.m_tBradcastInviteTimeMap[nRoleID] or 0
-- 		if os.time() - nLastSendTime < 60 then
-- 			return oRole:Tips(string.format("太频繁了，%s秒后再试", os.time()+60-nLastSendTime))
-- 		end
-- 		self.m_tBradcastInviteTimeMap[nRoleID] = os.time()

-- 		local tTalkConf = ctTalkConf["teaminvite"]
-- 		local sContent = string.format(tTalkConf.sContent, sGameName, oTeam:GetID())
-- 		GF.SendTeamTalk(nRoleID, sContent, false, true)
-- 	end

-- 	oRole:Tips("匹配进行中，请耐心等待。。。")
-- 	local tGameMap = self:GetGameMatchMap(nGameType)
-- 	tGameMap[nRoleID] = oRole:GetLevel()

-- 	local nMyLevel = oRole:GetLevel()

-- 	--进入匹配流程
-- 	local tTeamIDMap = {}
-- 	local tSingleRoleMap = {}
-- 	local tTeamWeightList = {}
-- 	for nTmpRoleID, nTmpLevel in pairs(tGameMap) do
-- 		local oTmpTeam = self:GetTeamByRoleID(nTmpRoleID)
-- 		if oTmpTeam then
-- 			if not oTmpTeam:IsLeader(nTmpRoleID) then
-- 				tGameMap[nTmpRoleID] = nil

-- 			elseif not tTeamIDMap[oTmpTeam:GetID()] then --可能有多个相同的队伍(单人点了匹配,然后加入别的队伍)
-- 				tTeamIDMap[oTmpTeam:GetID()] = true

-- 				if oTmpTeam:IsFull() then
-- 					tGameMap[nTmpRoleID] = nil
-- 				else
-- 					local nWeight = math.ceil(1000 / (math.abs(nMyLevel - oTmpTeam:GetAvgLevel()) * 2 + 1))
-- 					table.insert(tTeamWeightList, {nTmpRoleID, nWeight, oTmpTeam})
-- 				end
-- 			else
-- 				tGameMap[nTmpRoleID] = nil
-- 			end
-- 		else
-- 			tSingleRoleMap[nTmpRoleID] = nTmpLevel
-- 		end
-- 	end
-- 	print(nGameType, "待匹配房间数", #tTeamWeightList)

-- 	--将没有队伍的玩家加入队伍
-- 	table.sort(tTeamWeightList, function(t1, t2) return t1[2]<t2[2] end)
-- 	for nTmpRoleID, nTmpLevel in pairs(tSingleRoleMap) do
-- 		if #tTeamWeightList <= 0 then
-- 			break
-- 		end

-- 		local tTeam = tTeamWeightList[#tTeamWeightList]
-- 		if tTeam[3]:Join(nTmpRoleID) then
-- 			if tTeam[3]:IsFull() then
-- 				table.remove(tTeamWeightList)
-- 				tGameMap[tTeam[1]] = nil
-- 			end
-- 		end
		
-- 		tGameMap[nTmpRoleID] = nil
-- 		tSingleRoleMap[nTmpRoleID] = nil
-- 	end

-- 	--处理单独玩家
-- 	local tRoleList = {}
-- 	for nTmpRoleID, nTmpLevel in pairs(tSingleRoleMap) do
-- 		table.insert(tRoleList, {nTmpRoleID, nTmpLevel})
-- 	end
-- 	table.sort(tRoleList, function(t1, t2) return t1[2]<t2[2] end)

-- 	local nMaxLoop = 1024 --防止死循环
-- 	while #tRoleList >= 3 and nMaxLoop > 0 do
-- 		nMaxLoop = nMaxLoop - 1	
-- 		local tLeader = table.remove(tRoleList)
-- 		local oTeam = self:CreateTeam(tLeader[1])
-- 		if not oTeam then
-- 			tGameMap[tLeader[1]] = nil
-- 		else
-- 			while #tRoleList > 0 do
-- 				local tRole = table.remove(tRoleList)
-- 				oTeam:Join(tRole[1], false)
-- 				if oTeam:IsFull() then
-- 					break
-- 				end
-- 			end
-- 			if not oTeam:IsFull() then
-- 				tGameMap[tLeader[1]] = tLeader[2]
-- 			end
-- 		end
-- 	end
-- 	self:SyncTeamMatchInfo(nRoleID)
-- end

-- function CTeamMgr:SyncTeamMatchInfo(nRoleID)
-- 	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
-- 	if not oRole or not oRole:IsOnline() then 
-- 		return 
-- 	end
-- 	local nRoleGameType = 0
-- 	for nGameType, tGameMap in pairs(self.m_tMatchMap) do
-- 		if tGameMap[nRoleID] then 
-- 			nRoleGameType = nGameType
-- 			break
-- 		end
-- 	end

-- 	local tMsg = {}
-- 	tMsg.nGameType = nRoleGameType
-- 	oRole:SendMsg("TeamMatchInfoRet", tMsg)
-- end

--匹配请求
function CTeamMgr:MatchTeamReq(nRoleID, nGameType, sGameName, bSys)
	self:GetMatchMgr():JoinMatchReq(nRoleID, nGameType, sGameName, bSys)
end

function CTeamMgr:SyncTeamMatchInfo(nRoleID) 
	self:GetMatchMgr():SyncRoleMatchInfo(nRoleID)
end

function CTeamMgr:CancelTeamMatchReq(nRoleID)
	self:GetMatchMgr():RemoveMatchReq(nRoleID)
end

function CTeamMgr:CancelSpecifyTeamMatchReq(nRoleID, nGameType)
	self:GetMatchMgr():RemoveSpecifyGameMatchReq(nRoleID, nGameType)
end


