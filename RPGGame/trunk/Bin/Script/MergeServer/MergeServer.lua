--目标DB
local nTarServer = 1
local sTarDBIP = "127.0.0.1"
local nTarDBPort =	20001

local sWorldSSDBIP = "127.0.0.1"
local nWorldSSDBPort = 20000

local sTarMysqlIP = "127.0.0.1"
local nTarMysqlPort = 3306
local sTarMysqlDB = "m2bt_s1_backup"
local sTarMysqlUsr = "root"
local sTarMysqlPwd = "123456"

--源DB
local tSrcDB = {
	{ip="127.0.0.1", port=20004, server=4, mysqlip="127.0.0.1", mysqlport=3306, mysqldb="m2bt_s4_backup", mysqlusr="root", mysqlpwd="123456"},
}

--目标DB连接
local oTarDB = SSDBDriver:new()
oTarDB:Connect(sTarDBIP, nTarDBPort)

--世界服DB
local oWorldDB = SSDBDriver:new()
oWorldDB:Connect(sWorldSSDBIP, nWorldSSDBPort)

--源DB连接
local tSrcDBObj = {}
for _, tDB in ipairs(tSrcDB) do
	local oSrcDB = SSDBDriver:new()
	oSrcDB:Connect(tDB.ip, tDB.port)
	local tDBObj = {tDB.server, oSrcDB}
	table.insert(tSrcDBObj, tDBObj)
end

--添加服务器标识
local function _AddServerFlag(sData, nSrcServer)
	assert(sData and nSrcServer, "参数错误")
	if string.find(sData, "_%[%d+%]") then --已经合过服
		return sData
	end
	sData = string.format("%s_[%d]", sData, nSrcServer)
	return sData
end

local _tMergeProc = {}
_tMergeProc["HallFameDB"] = function() return true end --名人堂[GLOBAL](已废弃)
_tMergeProc["TimeAwardDB"] = function() return true end --限时奖励[GLOBAL](已废弃)
_tMergeProc["NpcMgrDB"] = function() return true end --Npc保存数据(用目标服务器数据)
_tMergeProc["UnionEtcDB"] = function() return true end --联盟杂项[GLOBAL](不用单独处理,在UnionDB中顺带处理了)
_tMergeProc["SvrArenaDB"] = function() return true end --服务器竞技场数据DB[GLOBAL(用目标服务器数据)]
_tMergeProc["HDCircleDB"] = function() return true end --循环活动数据[GLOBAL](用目标服务器数据)
_tMergeProc["NoticeDB"] = function() return true end --滚动公告[GLOBAL](用目标服务器数据)
_tMergeProc["ServerMailDB"] = function() return true end    --服务器邮件DB[GLOBAL](不用单独处理,在RoleMailDB中顺带处理了)
_tMergeProc["RoleMailBodyDB"] = function() return true end  --角色邮件体DB[GLOBAL](不用单独处理,在RoleMailDB中顺带处理了)

--世界服不处理
_tMergeProc["PlayerIDDB"] = function() return true end			--角色/账号ID数据库[CENTER]
_tMergeProc["RoleNameDB"] = function() return true end      	--唯一角色名数据库[CENER]
_tMergeProc["MarriageSysDB"] = function() return true end        --婚姻系统数据DB[WGLOBAL]
_tMergeProc["MarriageCoupleDB"] = function() return true end  --婚姻对象数据DB[WGLOBAL]
_tMergeProc["RoleMarriageDB"] = function() return true end      --角色婚姻数据DB[WGLOBAL]
_tMergeProc["BrotherSysDB"] = function() return true end          --结拜系统数据DB[WGLOBAL]
_tMergeProc["RoleBrotherDB"] = function() return true end        --角色结拜数据DB[WGLOBAL]
_tMergeProc["LoverSysDB"] = function() return true end              --情缘系统数据DB[WGLOBAL]
_tMergeProc["RoleLoverDB"] = function() return true end            --角色情缘数据DB[WGLOBAL]
_tMergeProc["MentorshipDB"] = function() return true end          --师徒系统数据DB[WGLOBAL]
_tMergeProc["RoleMentorshipDB"] = function() return true end      --角色师徒数据DB[WGLOBAL]
_tMergeProc["HouseDB"] = function() return true end  					--家园对象数据DB[WGLOBAL2]
_tMergeProc["HouseEtcDB"] = function() return true end  			--家园杂项数据DB[WGLOBAL2]
_tMergeProc["TalkDB"] = function() return true end 					--聊天系统[WGLOBAL]
_tMergeProc["TeamDB"] = function() return true end 					--队伍数据[WGLBOAL]
_tMergeProc["TeamEtcDB"] = function() return true end 			--队伍杂项数据[WGLOBAL]
_tMergeProc["FriendDataDB"] = function() return true end 		--好友数据[WGLOBAL]
_tMergeProc["StrangerDataDB"] = function() return true end 	--陌生人数据[WGLOBAL]
_tMergeProc["FriendEtcDB"] = function() return true end 		--好友系统杂项[WGLOBAL]
_tMergeProc["GiftDB"] = function() return true end 					--全局赠送系统[WGLOBAL]
_tMergeProc["RoleGiftDB"] = function() return true end          --赠送系统玩家数据[WGLOBAL]
_tMergeProc["InviteDB"] = function() return true end 				 --邀请[WGLOBAL]
_tMergeProc["BackstageDB"] = function() return true end 		--后台配置[CENTER]


_tMergeProc["RoleDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tKeys = oSrcDB:HKeys(sDBName)	
	for _, sRoleID in pairs(tKeys) do
		if not GF.IsRobot(tonumber(sRoleID)) then
			--角色数据
			local sData = oSrcDB:HGet(sDBName, sRoleID)
			local tData = cjson.decode(sData)
			tData.m_sAccountName = _AddServerFlag(tData.m_sAccountName, nSrcServer)
			oTarDB:HSet(sDBName, sRoleID, cjson.encode(tData))

			--模块数据
			for _, tModule in pairs(gtModuleDef) do
				local sData = oSrcDB:HGet(tModule.sName, sRoleID)
				if sData ~= "" then
					oTarDB:HSet(tModule.sName, sRoleID, sData)
				end
			end
		end
	end
	return true
end

_tMergeProc["AccountDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tKeys = oSrcDB:HKeys(sDBName)	
	for _, sAccountID in pairs(tKeys) do
		local sData = oSrcDB:HGet(sDBName, sAccountID)
		local tData = cjson.decode(sData)
		tData.m_sName = _AddServerFlag(tData.m_sName, nSrcServer)
		tData.m_nServer = nTarServer
		oTarDB:HSet(sDBName, sAccountID, cjson.encode(tData))
	end
	return true
end

_tMergeProc["AccountNameDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tKeys = oSrcDB:HKeys(sDBName)	
	for _, sKey in pairs(tKeys) do
		local sData = oSrcDB:HGet(sDBName, sKey)
		local tData = cjson.decode(sData)
		if tData.sAccount then
			tData.sAccount = _AddServerFlag(tData.sAccount, nSrcServer)
		else
			assert(tData.nAccountID, "数据错误:"..tostring(tData))
			sKey = _AddServerFlag(sKey, nSrcServer)
		end
		local sData = cjson.encode(tData)
		oTarDB:HSet(sDBName, sKey, sData)
	end
	return true
end

_tMergeProc["RoleMailDB"] = function(sDBName, oSrcDB, nSrcServer)
	local sData = oTarDB:HGet("ServerMailDB", "data")
	local tData = cjson.decode(sData)
	local nMaxID = tData.m_nAutoInc

	local tKeys = oSrcDB:HKeys(sDBName)
	for _, sRoleID in ipairs(tKeys) do
		local tMailList = {}
		local sData = oSrcDB:HGet(sDBName, sRoleID)
		local tData = cjson.decode(sData)
		for _, tMail in pairs(tData) do
			if #tMail[4] > 0 then
				local nOldID = tMail[1]
				nMaxID = nMaxID + 1
				tMail[1] = nMaxID
				table.insert(tMailList, tMail)

				local sBody = oSrcDB:HGet("RoleMailBodyDB", sRoleID.."_"..nOldID)
				oTarDB:HSet("RoleMailBodyDB", sRoleID.."_"..nMaxID, sBody)
			end
		end
		if #tMailList > 0 then
			oTarDB:HSet(sDBName, sRoleID, cjson.encode(tMailList))
		end
	end
	tData.m_nAutoInc = nMaxID
	tData.m_tServerMailMap = {} --清空全服邮件,避免合进来的玩家重新获得邮件
	oTarDB:HSet("ServerMailDB", "data", cjson.encode(tData))
	return true
end

_tMergeProc["GlobalRoleDB"] = function(sDBName, oSrcDB, nSrcServer)
	local sGlobalDBName = sDBName.."_20"
	local sWorldDBName110 = sDBName.."_110"
	local sWorldDBName111 = sDBName.."_111"

	local tKeys = oSrcDB:HKeys(sGlobalDBName)
	for _, sRoleID in pairs(tKeys) do
		if not GF.IsRobot(tonumber(sRoleID)) then
			local sData = oSrcDB:HGet(sGlobalDBName, sRoleID)
			local tData = cjson.decode(sData)
			tData.m_sAccountName = _AddServerFlag(tData.m_sAccountName, nSrcServer)
			tData.m_nServer = nTarServer
			oTarDB:HSet(sGlobalDBName, sRoleID, cjson.encode(tData))

			local sData = oWorldDB:HGet(sWorldDBName110, sRoleID)
			if sData ~= "" then
				local tData = cjson.decode(sData)
				tData.m_sAccountName = _AddServerFlag(tData.m_sAccountName, nSrcServer)
				tData.m_nServer = nTarServer
				oWorldDB:HSet(sWorldDBName110, sRoleID, cjson.encode(tData))
			end

			local sData = oWorldDB:HGet(sWorldDBName111, sRoleID)
			if sData ~= "" then
				local tData = cjson.decode(sData)
				tData.m_sAccountName = _AddServerFlag(tData.m_sAccountName, nSrcServer)
				tData.m_nServer = nTarServer
				oWorldDB:HSet(sWorldDBName111, sRoleID, cjson.encode(tData))
			end
		end
	end
	return true
end

_tMergeProc["RoleMarketDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tKeys = oSrcDB:HKeys(sDBName)
	for _, sRoleID in pairs(tKeys) do
		local sData = oSrcDB:HGet(sDBName, sRoleID)
		oTarDB:HSet(sDBName, sRoleID, sData)
	end
	return true
end

_tMergeProc["RoleArenaDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tKeys = oSrcDB:HKeys(sDBName)
	for _, sRoleID in pairs(tKeys) do
		if not GF.IsRobot(tonumber(sRoleID)) then
			local sData = oSrcDB:HGet(sDBName, sRoleID)
			oTarDB:HSet(sDBName, sRoleID, sData)
		end
	end
	return true
end

_tMergeProc["UnionDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tNameMap = {}
	local tKeys = oTarDB:HKeys(sDBName)
	for _, sUnionID in pairs(tKeys) do
		local sData = oTarDB:HGet(sDBName, sUnionID)
		local tData = cjson.decode(sData)
		tNameMap[tData.m_sName] = true
	end
	local sData = oTarDB:HGet("UnionEtcDB", "data")
	local tData = cjson.decode(sData)
	local nShowID = tData.m_nAutoShowID

	local tKeys = oSrcDB:HKeys(sDBName)
	for _, sUnionID in pairs(tKeys) do
		local sData = oSrcDB:HGet(sDBName, sUnionID)
		local tData = cjson.decode(sData)
		if tNameMap[tData.m_sName] then
			tData.m_sName = string.format("%s[%d服]", tData.m_sName, nSrcServer)
		end
		nShowID = nShowID + 1
		tData.m_nShowID = nShowID
		oTarDB:HSet(sDBName, sUnionID, cjson.encode(tData))
	end

	tData.m_nAutoShowID = nShowID
	local sData = cjson.encode(tData)
	oTarDB:HSet("UnionEtcDB", "data", sData)
	return true
end

_tMergeProc["UnionRoleDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tKeys = oSrcDB:HKeys(sDBName)
	for _, sRoleID in pairs(tKeys) do
		local sData = oSrcDB:HGet(sDBName, sRoleID)
		oTarDB:HSet(sDBName, sRoleID, sData)
	end
	return true
end

local function _MergeNormalAct(tActID, sDBName, oSrcDB, nSrcServer)
	local tTarActMap = {}
	local tSrcActMap = {}
	for _, nActID in pairs(tActID) do
		local nTarState = -1
		local sTarData = oTarDB:HGet(sDBName, nActID)
		local tTarData = cjson.decode(sTarData)		
		if tTarData.m_nState == CHDBase.tState.eStart or tTarData.m_nState == CHDBase.tState.eAward then
			tTarActMap[nActID] = tTarData
			nTarState = tTarData.m_nState
		end
		local nSrcState = -1
		local sSrcData = oSrcDB:HGet(sDBName, nActID)
		local tSrcData = cjson.decode(sSrcData)		
		if tSrcData.m_nState == CHDBase.tState.eStart or tSrcData.m_nState == CHDBase.tState.eAward then
			tSrcActMap[nActID] = tSrcData
			nSrcState = tSrcData.m_nState
		end
		if nTarState ~= nSrcState then
			return LuaTrace("活动进度不同步，不能合服:", nSrcServer, nTarServer, nActID, nSrcState, nTarState)
		end
	end

	--单个活动合并函数
	local tActMergeProc = {}
	tActMergeProc[11] = function(tTarData, tSrcData)
		assert(tTarData and tSrcData, "参数错误")
		for nRoleID, nValue in pairs(tSrcData.m_tDiffValue) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tDiffValue[nRoleID] = nValue
			end
		end
		for _, tRank in ipairs(tSrcData.m_tTmpRanking) do
			if not GF.IsRobot(tRank[1]) then
				table.insert(tTarData.m_tTmpRanking, tRank)
			end
		end
		table.sort(tTarData.m_tTmpRanking, function(t1, t2)
			if t1[2] == t2[2] then
				return t1[1] < t2[1]
			end
			return t1[2] > t2[2]
		end)
		return tTarData
	end
	tActMergeProc[12] = tActMergeProc[11]
	tActMergeProc[13] = tActMergeProc[11]
	tActMergeProc[15] = tActMergeProc[11]
	tActMergeProc[17] = tActMergeProc[11]
	tActMergeProc[18] = tActMergeProc[11]
	tActMergeProc[31] = function(tTarData, tSrcData)
		for nRoleID, tValue in pairs(tSrcData.m_tAwardMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tAwardMap[nRoleID] = tValue
			end
		end
		for nRoleID, nValue in pairs(tSrcData.m_tLastLogin) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tLastLogin[nRoleID] = nValue
			end
		end
		for nRoleID, nValue in pairs(tSrcData.m_tLoginCount) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tLoginCount[nRoleID] = nValue
			end
		end
		return tTarData
	end
	tActMergeProc[32] = function(tTarData, tSrcData)
		for nRoleID, tValue in pairs(tSrcData.m_tAwardMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tAwardMap[nRoleID] = tValue
			end
		end
		for nRoleID, nValue in pairs(tSrcData.m_tRechargeMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRechargeMap[nRoleID] = nValue
			end
		end
		return tTarData
	end
	tActMergeProc[33] = function(tTarData, tSrcData)
		for nRoleID, tValue in pairs(tSrcData.m_tAwardMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tAwardMap[nRoleID] = tValue
			end
		end
		for nRoleID, tValue in pairs(tSrcData.m_tRechargeMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRechargeMap[nRoleID] = tValue
			end
		end
		for nRoleID, nValue in pairs(tSrcData.m_tMoneyMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tMoneyMap[nRoleID] = nValue
			end
		end
		return tTarData
	end
	tActMergeProc[34] = function(tTarData, tSrcData)
		for nRoleID, tValue in pairs(tSrcData.m_tAwardMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tAwardMap[nRoleID] = tValue
			end
		end
		for nRoleID, tValue in pairs(tSrcData.m_tRechargeMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRechargeMap[nRoleID] = tValue
			end
		end
		for nRoleID, nValue in pairs(tSrcData.m_tMoneyMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tMoneyMap[nRoleID] = nValue
			end
		end
		return tTarData
	end
	tActMergeProc[35] = function(tTarData, tSrcData)
		for nRoleID, tValue in pairs(tSrcData.m_tAwardMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tAwardMap[nRoleID] = tValue
			end
		end
		for nRoleID, nValue in pairs(tSrcData.m_tResumeYBMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tResumeYBMap[nRoleID] = nValue
			end
		end
		return tTarData
	end
	tActMergeProc[36] = function(tTarData, tSrcData)
		for nRoleID, tValue in pairs(tSrcData.m_tAwardMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tAwardMap[nRoleID] = tValue
			end
		end
		for nRoleID, nValue in pairs(tSrcData.m_tRechargeMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRechargeMap[nRoleID] = nValue
			end
		end
		return tTarData
	end
	tActMergeProc[37] = function(tTarData, tSrcData)
		for nRoleID, tValue in pairs(tSrcData.m_tRoleActData) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRoleActData[nRoleID] = tValue
			end
		end
		return tTarData
	end
	tActMergeProc[38] = function(tTarData, tSrcData)
		for nRoleID, nValue in pairs(tSrcData.m_tRoleRecordMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRoleRecordMap[nRoleID] = nValue
			end
		end
		return tTarData
	end

	for nActID, tData in pairs(tSrcActMap) do
		assert(tActMergeProc[nActID], "合并函数不存在:"..nActID)
		local tTarData = tActMergeProc[nActID](tTarActMap[nActID], tData)
		oTarDB:HSet(sDBName, nActID, cjson.encode(tTarData))
	end
	return true
end

local function _MergeGrowthAct(tActID, sDBName, oSrcDB, nSrcServer)
	local tTarActMap = {}
	local tSrcActMap = {}
	for _, nActID in pairs(tActID) do
		local nTarState = -1
		local sTarData = oTarDB:HGet(sDBName, nActID)
		local tTarData = cjson.decode(sTarData)		
		if tTarData.m_nState == CHDBase.tState.eStart or tTarData.m_nState == CHDBase.tState.eAward then
			tTarActMap[nActID] = tTarData
			nTarState = tTarData.m_nState
		end
		local nSrcState = -1
		local sSrcData = oSrcDB:HGet(sDBName, nActID)
		local tSrcData = cjson.decode(sSrcData)		
		if tSrcData.m_nState == CHDBase.tState.eStart or tSrcData.m_nState == CHDBase.tState.eAward then
			tSrcActMap[nActID] = tSrcData
			nSrcState = tSrcData.m_nState
		end
		if nTarState ~= nSrcState then
			return LuaTrace("活动进度不同步，不能合服:", nSrcServer, nTarServer, nActID, nSrcState, nTarState)
		end
	end

	--单个活动合并函数
	local tActMergeProc = {}
	tActMergeProc[101] = function(tTarData, tSrcData)
		assert(tTarData and tSrcData, "参数错误")
		for nRoleID, xValue in pairs(tSrcData.m_tRoleMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRoleMap[nRoleID] = xValue
			end
		end
		for nRoleID, xValue in ipairs(tSrcData.m_tRechargeMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRechargeMap[nRoleID] = xValue
			end
		end
		for nRoleID, xValue in ipairs(tSrcData.m_tTargetRankAwardMap) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tTargetRankAwardMap[nRoleID] = xValue
			end
		end
		for nRoleID, xValue in ipairs(tSrcData.m_tTargetAwardRecord) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tTargetAwardRecord[nRoleID] = xValue
			end
		end
		for nRoleID, xValue in ipairs(tSrcData.m_tRechargeAwardRecord) do
			if not GF.IsRobot(nRoleID) then
				tTarData.m_tRechargeAwardRecord[nRoleID] = xValue
			end
		end
		return tTarData
	end
	tActMergeProc[102] = tActMergeProc[101]
	tActMergeProc[103] = tActMergeProc[101]
	tActMergeProc[104] = tActMergeProc[101]
	tActMergeProc[105] = tActMergeProc[101]
	tActMergeProc[106] = tActMergeProc[101]
	tActMergeProc[107] = tActMergeProc[101]
	tActMergeProc[108] = tActMergeProc[101]
	tActMergeProc[109] = tActMergeProc[101]
	tActMergeProc[110] = tActMergeProc[101]
	tActMergeProc[111] = tActMergeProc[101]
	tActMergeProc[112] = tActMergeProc[101]
	tActMergeProc[113] = tActMergeProc[101]
	tActMergeProc[114] = tActMergeProc[101]
	tActMergeProc[115] = tActMergeProc[101]

	for nActID, tData in pairs(tSrcActMap) do
		assert(tActMergeProc[nActID], "合并函数不存在:"..nActID)
		local tTarData = tActMergeProc[nActID](tTarActMap[nActID], tData)
		oTarDB:HSet(sDBName, nActID, cjson.encode(tTarData))
	end
	return true
end
_tMergeProc["HuoDongDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tNormalAct = {}
	local tGrowthAct = {}
	for nID, tConf in pairs(ctHuoDongConf) do
		if not tConf.bClose and not tConf.bCrossServer then
			if nID < 101 then
				table.insert(tNormalAct, nID)
			else
				table.insert(tGrowthAct, nID)
			end
		end
	end
	local bRes = _MergeNormalAct(tNormalAct, sDBName, oSrcDB, nSrcServer)
	if bRes then
		bRes = _MergeGrowthAct(tGrowthAct, sDBName, oSrcDB, nSrcServer)
	end
	return bRes
end

_tMergeProc["GrowthTargetActDB"] = function(sDBName, oSrcDB, nSrcServer)
	local sTarData = oTarDB:HGet(sDBName, "GrowthTargetShop")
	local tTarData = sTarData == "" and {m_tItemRecordMap={}} or cjson.decode(sTarData)

	local sSrcData = oSrcDB:HGet(sDBName, "GrowthTargetShop")
	if sSrcData == "" then
		return
	end
	local tSrcData = cjson.decode(sSrcData)
	for nIndex, tRoleData in pairs(tSrcData.m_tItemRecordMap) do
		tTarData.m_tItemRecordMap[nIndex] = tTarData.m_tItemRecordMap[nIndex] or {}
		for nRoleID, nCount in pairs(tRoleData) do
			tTarData.m_tItemRecordMap[nIndex][nRoleID] = nCount
		end
	end
	oTarDB:HSet(sDBName, "GrowthTargetShop", cjson.encode(tTarData))
	return true
end

_tMergeProc["ShopDB"] = function(sDBName, oSrcDB, nSrcServer)
	local sSrcData = oSrcDB:HGet(sDBName,"data")
	local tSrcData = sSrcData == "" and {} or cjson.decode(sSrcData)

	local sTarData = oTarDB:HGet(sDBName, "data")
	local tTarData = sTarData == "" and {} or cjson.decode(sTarData)

	local _fnInsert = function(tTarList, tSrcList)
		for nKey, tData in pairs(tSrcList or {}) do
			tTarList[nKey] = tData
		end
	end

	for nShopType, tShopData in pairs(tSrcData) do
		tTarData[nShopType] = tTarData[nShopType] or {}
		if nShopType == gtShopType.eShop then
			tTarData[nShopType].m_tFirstBuyTime = tShopData.m_tFirstBuyTime or {}
			tTarData[nShopType].m_tAllreadyBuy = tTarData[nShopType].m_tAllreadyBuy or {}
			for nLimBuyType, tShopBuyData in pairs(tShopData.m_tAllreadyBuy or {}) do
				if not tTarData[nShopType].m_tAllreadyBuy[nLimBuyType] then
					tTarData[nShopType].m_tAllreadyBuy[nLimBuyType] = {}
				end
				_fnInsert(tTarData[nShopType].m_tAllreadyBuy[nLimBuyType], tShopBuyData)
			end

		elseif nShopType == gtShopType.eCSpecial then
			tTarData[nShopType].m_tPlayerShop = tTarData[nShopType].m_tPlayerShop or {}
			tTarData[nShopType].m_tUpdateNum = tTarData[nShopType].m_tUpdateNum or {}
			_fnInsert(tTarData[nShopType].m_tPlayerShop, tShopData.m_tPlayerShop)
			_fnInsert(tTarData[nShopType].m_tUpdateNum, tShopData.m_tUpdateNum)
			if not tTarData[nShopType].m_nResetTime then
				tTarData[nShopType].m_nResetTime = tShopData.m_nResetTime
			end

		elseif nShopType == gtShopType.eCBuy then
			tTarData[nShopType].m_tFirstBuyTime = tTarData[nShopType].m_tFirstBuyTime or {}
			tTarData[nShopType].m_tAllreadyBuy = tTarData[nShopType].m_tAllreadyBuy or {}
			if not tTarData[nShopType].m_tFirstBuyTime[1] and tShopData.m_tFirstBuyTime[1] then
				tTarData[nShopType].m_tFirstBuyTime[1] = tShopData.m_tFirstBuyTime[1]
			end
			_fnInsert(tTarData[nShopType].m_tAllreadyBuy, tShopData.m_tAllreadyBuy)

		elseif nShopType == gtShopType.eChamberCore then
			tTarData[nShopType].m_tPlayers = tTarData[nShopType].m_tPlayers or {}
			_fnInsert(tTarData[nShopType].m_tPlayers, tShopData.m_tPlayers)
		end
	end
	oTarDB:HSet(sDBName,  "data", cjson.encode(tTarData))
	return true
end


_tMergeProc["RankingDB"] = function(sDBName, oSrcDB, nSrcServer)
	for _, nRankID in pairs(gtRankingDef) do
		local sTmpDBName = sDBName.."_"..nRankID
		local tKeys = oSrcDB:HKeys(sTmpDBName)
		for _, sTmpID in pairs(tKeys) do
			oTarDB:HSet(sTmpDBName, sTmpID, oSrcDB:HGet(sTmpDBName, sTmpID))
		end
	end
	return true
end

_tMergeProc["RankingEtcDB"] = function(sDBName, oSrcDB, nSrcServer)
	local sTarData = oTarDB:HGet(sDBName, gtRankingDef.eColligatePowerRanking)
	local tTarData = cjson.decode(sTarData)

	local sSrcData = oSrcDB:HGet(sDBName, gtRankingDef.eColligatePowerRanking)
	if sSrcData ~= "" then
		local tSrcData = cjson.decode(sSrcData)
		for nRoleID, bRes in pairs(tSrcData.m_tCongratMap) do
			tTarData.m_tCongratMap[nRoleID] = bRes
		end
	end
	oTarDB:HSet(sDBName, gtRankingDef.eColligatePowerRanking, cjson.encode(tTarData))
	return true
end

_tMergeProc["KejuRankingDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tKeys = oSrcDB:HKeys(sDBName)
	for _, sID in pairs(tKeys) do
		oTarDB:HSet(sDBName, sID, oSrcDB:HGet(sDBName, sID))
	end
	return true
end

_tMergeProc["ExchangeActDB"] = function(sDBName, oSrcDB, nSrcServer)
	local tKeys = oTarDB:HKeys(sDBName)
	local tTarDataMap = {}
	for _, sID in pairs(tKeys) do
		local sData = oTarDB:HGet(sDBName, sID)
		if sData ~= "" then
			tTarDataMap[sID] = cjson.decode(sData)
		end
	end

	local tSrcKeys = oTarDB:HKeys(sDBName)
	for _, sID in pairs(tSrcKeys) do
		local sData = oSrcDB:HGet(sDBName, sID)
		if sData ~= "" then
			local tSrcData = cjson.decode(sData)
			if tTarDataMap[sID] then
				for nRoleID, tInfo in pairs(tSrcData.m_tRoleInfoMap) do
					tTarDataMap[sID].m_tRoleInfoMap[nRoleID] = tInfo
				end
			else
				tTarDataMap[sID] = tSrcData
			end
		end
	end
	for sID, tData in pairs(tTarDataMap) do
		oTarDB:HSet(sDBName, sID, cjson.encode(tData))
	end
	return true
end

_tMergeProc["KeyExchangeDB"] = function(sDBName, oSrcDB, nSrcServer)
	local sData = oTarDB:HGet(sDBName, "data")	
	local tData = {m_tOnePersonOneKey={}}
	if sData ~= "" then
		tData = cjson.decode(sData)
	end

	local sSrcData = oSrcDB:HGet(sData, "data")
	if sSrcData ~= "" then
		local tSrcData = cjson.decode(sSrcData)
		for k, v in pairs(tSrcData.m_tOnePersonOneKey or {}) do
			tData.m_tOnePersonOneKey[k] = v
		end
	end
	oTarDB:HSet(sDBName, "data", cjson.encode(tData))
	return true
end


--合并DB
function MergeSSDB(bTest)
	if bTest then
		LuaTrace("merge ssdb test------")
		local metatable = getmetatable(oTarDB)
		metatable.HSet_backup = metatable.HSet
		metatable.HSet = function() end

		local metatablew = getmetatable(oWorldDB)
		metatablew.HSet_backup = metatablew.HSet
		metatablew.HSet = function() end
	else
		LuaTrace("merge ssdb true------")
		local metatable = getmetatable(oTarDB)
		if metatable.HSet_backup then
			metatable.HSet = metatable.HSet_backup
		end

		local metatablew = getmetatable(oWorldDB)
		if metatablew.HSet_backup then
			metatablew.HSet = metatablew.HSet_backup
		end
	end

	for _, tDB in ipairs(tSrcDBObj) do
		local nSrcServer = tDB[1]
		local oSrcDB = tDB[2]

		local bSuccess = true
		for _, sDBName in pairs(gtDBDef) do
			LuaTrace("merge server db:", nSrcServer, sDBName)
			local fnProc = assert(_tMergeProc[sDBName], "数据库未处理:"..sDBName)
			if not fnProc(sDBName, oSrcDB, nSrcServer) then
				bSuccess = false
				break
			end
		end
		if bSuccess then
			LuaTrace(nSrcServer, "服合并完成")
		else
			LuaTrace(nSrcServer, "服合并失败")
		end
	end
	LuaTrace("合服处理完毕")
end


local tMergeMysql = {}
tMergeMysql["account"] = function(oTarMysql, oSrcMysql, nSrcServer)
	local sql = "select * from account;";
	oSrcMysql:Query(sql)
	while oSrcMysql:FetchRow() do
		local source, accountid, accountstate, vip, time = oSrcMysql:ToInt32("source", "accountid", "accountstate", "vip", "time")
		local accountname = oSrcMysql:ToString("accountname")
		accountname = _AddServerFlag(accountname, nSrcServer)
		oTarMysql:Query(string.format("insert into account set source=%d,accountid=%d,accountstate=%d,vip=%d,time=%d,accountname='%s';", source, accountid, accountstate, vip, time, accountname))
	end
end

tMergeMysql["role"] = function(oTarMysql, oSrcMysql, nSrcServer)
	local sql = "select * from role;";
	oSrcMysql:Query(sql)
	while oSrcMysql:FetchRow() do
		local accountid, charid, level, gender, school, logintime, online, yuanbao, bindyuanbao, power, time
		= oSrcMysql:ToInt32("accountid", "charid", "level", "gender", "school", "logintime", "online", "yuanbao", "bindyuanbao", "power", "time")
		local rolename, imgheader = oSrcMysql:ToString("rolename", "imgheader")
		oTarMysql:Query(string.format("insert into role set accountid=%d,charid=%d,level=%d,gender=%d,school=%d,logintime=%d,online=%d,yuanbao=%d,bindyuanbao=%d,power=%d,time=%d,rolename='%s',imgheader='%s';"
		, accountid, charid, level, gender, school, logintime, online, yuanbao, bindyuanbao, power, time, rolename, imgheader))
	end
end

tMergeMysql["online"] = function(oTarMysql, oSrcMysql, nSrcServer)
	local sql = "select * from online;";
	oSrcMysql:Query(sql)
	while oSrcMysql:FetchRow() do
		local accountid, charid, level, vip, type, keeptime, time = oSrcMysql:ToInt32("accountid", "charid", "level", "vip", "type", "keeptime", "time")
		oTarMysql:Query(string.format("insert into online set accountid=%d,charid=%d,level=%d,vip=%d,type=%d,keeptime=%d,time=%d;", accountid, charid, level, vip, type, keeptime, time))
	end
end

tMergeMysql["yuanbao"] = function(oTarMysql, oSrcMysql, nSrcServer)
	local sql = "select * from yuanbao;";
	oSrcMysql:Query(sql)
	while oSrcMysql:FetchRow() do
		local accountid, charid, level, vip, yuanbao, curryuanbao, bind, time = oSrcMysql:ToInt32("accountid", "charid", "level", "vip", "yuanbao", "curryuanbao", "bind", "time")
		local reason = oSrcMysql:ToString("reason")
		oTarMysql:Query(string.format("insert into yuanbao set accountid=%d,charid=%d,level=%d,vip=%d,yuanbao=%d,curryuanbao=%d,bind=%d,reason='%s',time=%d;", accountid, charid, level, vip, yuanbao, curryuanbao, bind, reason, time))
	end
end

tMergeMysql["task"] = function(oTarMysql, oSrcMysql, nSrcServer)
	local sql = "select * from `task`;";
	oSrcMysql:Query(sql)
	while oSrcMysql:FetchRow() do
		local accountid, charid, school, level, vip, type, taskid, time  = oSrcMysql:ToInt32("accountid", "charid", "school", "level", "vip", "type", "taskid", "time")
		oTarMysql:Query(string.format("insert into `task` set accountid=%d,charid=%d,level=%d,vip=%d,type=%d,taskid=%d,school=%d,time=%d;", accountid, charid, level, vip, type, taskid, school, time))
	end
end

tMergeMysql["union"] = function(oTarMysql, oSrcMysql, nSrcServer)
	local sql = "select * from `union`;";
	oSrcMysql:Query(sql)
	while oSrcMysql:FetchRow() do
		local unionid, displayid, unionlevel, leaderid, createtime = oSrcMysql:ToInt32("unionid", "displayid", "unionlevel", "leaderid", "createtime")
		local unionname, leadername = oSrcMysql:ToString("unionname", "leadername")
		oTarMysql:Query(string.format("select 1 from `union` where unionname='%s';", unionname))
		if oTarMysql:NumRows() > 0 then
			unionname = string.format("%s[%d]服", unionname, nSrcServer)
		end
		oTarMysql:Query(string.format("insert into `union` set unionid=%d,displayid=%d,unionname='%s',unionlevel=%d,leaderid=%d,leadername='%s',createtime=%d;", unionid, displayid, unionname, unionlevel, leaderid, leadername, createtime))
	end
end

tMergeMysql["unionmember"] = function(oTarMysql, oSrcMysql, nSrcServer)
	local sql = "select * from unionmember;";
	oSrcMysql:Query(sql)
	while oSrcMysql:FetchRow() do
		local roleid, unionid, position, jointime, leavetime, currcontri, totalcontri, daycontri =  oSrcMysql:ToInt32("roleid", "unionid", "position", "jointime", "leavetime", "currcontri", "totalcontri", "daycontri")
		local rolename = oSrcMysql:ToString("rolename")
		oTarMysql:Query(string.format("insert into unionmember set roleid=%d,rolename='%s',unionid=%d,position=%d,jointime=%d,leavetime=%d,currcontri=%d,totalcontri=%d,daycontri=%d;", roleid, rolename, unionid, position, jointime, leavetime, currcontri, totalcontri, daycontri))
	end
end

--合并Mysql
function MergeMysql(bTest)
	local oTarMysql = MysqlDriver:new() 
	oTarMysql:Connect(sTarMysqlIP, nTarMysqlPort, sTarMysqlDB, sTarMysqlUsr, sTarMysqlPwd, "utf8")

	if bTest then
		LuaTrace("merge mysql test------")
		local metatable = getmetatable(oTarMysql)
		metatable.Query_backup = metatable.Query
		metatable.Query = function() end
	else
		LuaTrace("merge mysql true------")
		local metatable = getmetatable(oTarDB)
		if metatable.Query_backup then
			metatable.Query = metatable.Query_backup
		end
	end
	for _, srv in ipairs(tSrcDB) do
		local oSrcMysql = MysqlDriver:new() 
		oSrcMysql:Connect(srv.mysqlip, srv.mysqlport, srv.mysqldb, srv.mysqlusr, srv.mysqlpwd, "utf8")
		for mysqldb, func in pairs(tMergeMysql) do
			func(oTarMysql, oSrcMysql, srv.server)
		end
		LuaTrace(srv.server, "服合并Mysql成功")
	end
	LuaTrace("全部Mysql处理完成")
end
