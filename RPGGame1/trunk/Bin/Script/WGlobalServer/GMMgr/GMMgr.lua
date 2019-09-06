--GM指令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nServerID = gnServerID
function CGMMgr:Ctor()
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	local nRoleID, sRoleName, sAccount = 0, "", ""
	if oRole then
		nRoleID, sRoleName, sAccount = oRole:GetID(), oRole:GetName(), oRole:GetAccountName()
	end

	local sInfo = string.format("执行指令:%s [roleid:%d,rolename:%s,account:%s]", sCmd, nRoleID, sRoleName, sAccount)
	LuaTrace(sInfo)

	local oFunc = CGMMgr[sCmdName]
	if not CGMMgr[sCmdName] then 
		LuaTrace("找不到指令:["..sCmdName.."]")
		return oRole:Tips("找不到指令:["..sCmdName.."]")
	end
	-- local oFunc = assert(CGMMgr[sCmdName], "找不到指令:["..sCmdName.."]")
	local oFunc = CGMMgr[sCmdName]
	table.remove(tArgs, 1)
	return oFunc(self, nServer, nService, nSession, tArgs)
end

-----------------指令列表-----------------
-- 测试逻辑
CGMMgr["test"] = function(self, nServer, nService, nSession, tArgs)
	NetworkExport.DumpPacket()
end

--重载脚本
CGMMgr["reload"] = function(self, nServer, nService, nSession, tArgs)
	local sScript = tArgs[1] or ""
	local bRes, sTips = false, ""
	if sScript == "" then
		bRes = gfReloadAll("WGlobalServer")
		sTips = "重载所有脚本 "..(bRes and "成功!" or "失败!")
	else
		bRes = gfReloadScript(sScript, "WGlobalServer")
		sTips = "重载 '"..sScript.."' ".. (bRes and "成功!" or "失败!")
	end
	LuaTrace(sTips)
	CGRole:Tips("世界全局 "..sTips, nServer, nSession)
	return bRes
end

CGMMgr["reloadall"] = function(self, nServer, nService, nSession, tArgs)
	--GLOBAL服务
	local tList = goServerMgr:GetGlobalServiceList()
	for _, tConf in pairs(tList) do
		if tConf.nServer ~= gnWorldServerID then
			Network:RMCall("GMCommandReq", nil, tConf.nServer, tConf.nID, nSession, "lgm reload local")
			Network:RMCall("GMCommandReq", nil, tConf.nServer, tConf.nID, nSession, "rgm reload")
			Network:RMCall("GMCommandReq", nil, tConf.nServer, tConf.nID, nSession, "agm reload")
			Network:RMCall("GMCommandReq", nil, tConf.nServer, tConf.nID, nSession, "reload")
		elseif tConf.nID ~= CUtil:GetServiceID() then
			Network:RMCall("GMCommandReq", nil, tConf.nServer, tConf.nID, nSession, "reload", nServer)
		end
	end
	--自己
	self:OnGMCmdReq(nServer, nService, nSession, "reload")

	--世界LOGIC服务
	local tList = goServerMgr:GetLogicServiceList()
	for _, tConf in pairs(tList) do
		Network:RMCall("GMCommandReq", nil, tConf.nServer, tConf.nID, nSession, "reload")
	end
end

--添加友好度
CGMMgr["addfriendhoney"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if not (tArgs[1] and tArgs[2]) then 
		return oRole:Tips("参数错误")
	end
	local nTarRoleID, nDegrees = tonumber(tArgs[1]), tonumber(tArgs[2])
	assert(nTarRoleID and nDegrees)
	goFriendMgr:GMAddDegrees(oRole, nTarRoleID, nDegrees)
end

--赠送
CGMMgr["Gift"] = function(self, nServer, nService, nSession, tArgs)
print("************************************")
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	-- local  tList = {1}
	-- oRole:GetPropDataList(tList, function(tDataList)
	-- 	local tItemList = {}
	-- 	for k , tProp in pairs(tDataList) do
	-- 		tItemList[#tItemList+1] = {nGrid = tProp.m_nGrid, nSendNum = 1, nPropID = tProp.m_nID}
	-- 	end
	-- 	goCGiftMgr:GiftPropReq(oRole,11114,tItemList, 1)
	-- end)

	local GiftGetSendNumReq
	--goCGiftMgr:RecordInfoReq(oRole)
	--goCGiftMgr:GiftGetSendNumReq(oRole, tonumber(tArgs[1]))
	goCGiftMgr:GiftGetRecordInfoReq(oRole)
	
end

CGMMgr["house"] = function (self,nServer,nService,nSession,tArgs)
end

--删除师徒关系
CGMMgr["removementorship"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nRoleID  = oRole:GetID()
	local nTarID = tonumber(tArgs[1])
	if not nTarID or nTarID <= 0 then 
		return oRole:Tips("参数错误")
	end
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	if not oTarRole then 
		return oRole:Tips("目标玩家不存在")
	end
    local oRoleMentorship = goMentorshipMgr:GetRoleMentorship(nRoleID)
	assert(oRoleMentorship)
	local oMentorship = oRoleMentorship:GetMentorship(nTarID)
    if not oMentorship then 
        return oRole:Tips("和目标玩家不存在师徒关系")
    end
    local oTarMentorship = goMentorshipMgr:GetRoleMentorship(nTarID)
    assert(oTarMentorship)
    oRoleMentorship:RemoveMentorship(nTarID, false, nTimeStamp)
    oTarMentorship:RemoveMentorship(nRoleID, false, nTimeStamp)
    oRole:Tips(string.format("你已经解除了和%s的师徒关系", oTarRole:GetName()))
    oRoleMentorship:MarkDirty(true)
    oTarMentorship:MarkDirty(true)
    goMentorshipMgr:SyncRoleMentorshipData(nRoleID)
    goMentorshipMgr:SyncRoleMentorshipData(nTarID)
end

--删除师徒关系
CGMMgr["marriageclean"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nRoleID  = oRole:GetID()
	local oCouple = goMarriageMgr:GetCoupleByRoleID(nRoleID)
	if not oCouple then 
		local oRoleMarr = goMarriageMgr:GetRoleMarriage(nRoleID)
		assert(oRoleMarr)
		oRoleMarr.m_nLastDivorceStamp = 0
		oRoleMarr.m_tMarriageRecord = {}
		oRoleMarr.m_tBlessGiftRecord = {}
		oRoleMarr:MarkDirty(true)
		return oRole:Tips("已清理当前婚姻关系限制")
	end
	local nHusbandID = oCouple:GetHusbandID()
	local nWifeID = oCouple:GetWifeID()
	local oHusbandMarr = goMarriageMgr:GetRoleMarriage(nHusbandID)
	local oWifeMarr = goMarriageMgr:GetRoleMarriage(nWifeID)

	local nCoupleID = oCouple:GetID()
	goMarriageMgr:DealDivorce(nCoupleID)
	goMarriageMgr.m_tDivorceList[nCoupleID] = nil   --防止在离婚期间清理，没清理离婚数据
	if oHusbandMarr then 
		oHusbandMarr.m_nLastDivorceStamp = 0
	end
	if oWifeMarr then 
		oWifeMarr.m_nLastDivorceStamp = 0
	end
	oRole:Tips("清理婚姻关系数据成功")
end

--删除师徒关系
CGMMgr["mentorshipdailyreset"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goMentorshipMgr:DailyReset()
	oRole:Tips("师徒数据跨天清理成功")
end

--队伍匹配测试
CGMMgr["teammatchtest"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local tRoleList = {}
	for nRoleID, oTempRole in pairs(goGPlayerMgr.m_tRoleIDMap) do
		table.insert(tRoleList, nRoleID)
		if #tRoleList >= 100 then 
			break
		end
	end
	for _, nRoleID in ipairs(tRoleList) do 
		local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
		if oTeam then
			local oTempRole = goGPlayerMgr:GetRoleByID(nRoleID)
			oTeam:QuitReq(oTempRole)
		end
	end

	local tTeamList = {}
	local tSingleList = {}
	for _, nRoleID in ipairs(tRoleList) do 
		local nRandom = math.random(100)
		if nRandom < 30 then 
			-- local oTempRole = goGPlayerMgr:GetRoleByID(nRoleID)
			-- goTeamMgr:CreateTeamReq(oTempRole)
			local oTeam = goTeamMgr:CreateTeam(nRoleID)
			if oTeam then 
				table.insert(tTeamList, oTeam)
			end
		elseif nRandom < 65 then 
			--随机加入一个已创建的队伍
			if #tTeamList > 0 then 
				local nIndex = math.random(1, #tTeamList)
				local oTeam = tTeamList[nIndex]
				if oTeam then 
					if not oTeam:Join(nRoleID, true) then 
						table.insert(tSingleList, nRoleID)
					end
				end
			end
		else
			table.insert(tSingleList, nRoleID)
		end
	end
	LuaTrace("============= DEBUG ==============")
	LuaTrace(string.format("队伍数量:%d", #tTeamList))
	LuaTrace(string.format("单人玩家数量:%d", #tSingleList))
	LuaTrace("============= DEBUG ==============")
	for k = 1, (#tTeamList + #tSingleList) do 
		local nOp = math.random(100)
		local nTypeRand = math.random(100)
		local nGameType = 1
		local sGameName = "test1111"
		if nTypeRand > 50 then 
			nGameType = 2
			sGameName = "test2222"
		end
		if (nOp < 50 and #tSingleList > 0) or #tTeamList < 1 then 
			local nRoleID = tSingleList[1]
			goTeamMgr:MatchTeamReq(nRoleID, nGameType, sGameName)
			table.remove(tSingleList, 1)
		else
			local oTeam = tTeamList[1]
			goTeamMgr:MatchTeamReq(oTeam:GetLeader().nRoleID, nGameType, sGameName)
			table.remove(tTeamList, 1)
		end
	end

	for _, nRoleID in ipairs(tRoleList) do 
		local oTeam = goTeamMgr:GetTeamByRoleID(nRoleID)
		if oTeam then
			local oTempRole = goGPlayerMgr:GetRoleByID(nRoleID)
			oTeam:QuitReq(oTempRole)
		end
	end
end

--队伍匹配
CGMMgr["teammatch"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nGameType = tonumber(tArgs[1])
	if not nGameType then return end
	local oTeamMatch = goTeamMgr:GetMatchMgr()
    if not oTeamMatch then 
        return 
	end
	oTeamMatch:ClientJoinMatchReq(oRole:GetID(), nGameType)
end

--检查获取玩家队伍状态 方便DEBUG用
CGMMgr["teamstatus"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
	print(">>>>>>> 玩家队伍状态 <<<<<<<<")
	if not oTeam then 
		print("玩家当前没有队伍")
		return 
	end
	local oLeader = oTeam:GetLeaderRole()
	local tRole = oTeam:GetRole(oRole:GetID())
	print(string.format("队伍ID(%d), 暂离状态(%s), 队长(%d)(%s)", oTeam:GetID(), 
		tostring(tRole.bLeave), oLeader:GetID(), oLeader:GetName()))
end

--结婚礼物测试
CGMMgr["marriagegift"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nTarID = tonumber(tArgs[1])
	if not nTarID then return end
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	if not oTarRole then 
		return oRole:Tips("目标玩家不存在")
	end
	local oCouple = goMarriageMgr:GetCoupleByRoleID(nTarID)
	if not oCouple then 
		return oRole:Tips("目标玩家不存在夫妻关系")
	end
	goMarriageMgr:SendMarriageBlessGift(oRole, nTarID, oCouple:GetID(), 1)
end

--测试删除机器人
CGMMgr["removerobot"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nRobotID = tonumber(tArgs[1])
	if not nRobotID then 
		oRole:Tips("参数不正确")
		return 
	end
	local oRobot = goGPlayerMgr:GetRoleByID(nRobotID)
	if not oRobot then 
		oRole:Tips("机器人不存在")
		return 
	end
	if not oRobot:IsRobot() then 
		oRole:Tips("目标不是机器人")
		return 
	end
	goGRobotMgr:RemoveRobot(nRobotID)
end
