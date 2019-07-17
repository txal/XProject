--GM指令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGMMgr:Ctor()
	-- self.m_tAuthMap = {}
	-- self.m_sPassword = "5378"
	-- self.m_nPasswordTime = 3600

	self.m_nWhiteTimer = GetGModule("TimerMgr"):Interval(60, function() self:UpdateWhiteAccount() end)
	self.m_tWhiteAccountMap = {}
end

function CGMMgr:UpdateWhiteAccount()
	self.m_tWhiteAccountMap = {}

	local sql = "select accountname from whitelist limit 32;"
	local oMgrSql = goDBMgr:GetMgrMysql()
	oMgrSql:Query(sql)
	while oMgrSql:FetchRow() do
		local sAccount = oMgrSql:ToString("accountname")
		self.m_tWhiteAccountMap[sAccount] = 1
	end
end

function CGMMgr:Release()
	GetGModule("TimerMgr"):Clear(self.m_nWhiteTimer)
	self.m_nWhiteTimer = nil
end

--权限检测
function CGMMgr:CheckAuth(sAccount, bBrowser)
	if gbOpenGM or bBrowser then
		return true
	end
	if not self.m_tWhiteAccountMap[sAccount] then
		return false
	end
	return true

	-- local nSSKey = goGPlayerMgr:MakeSSKey(nServer, nSession)
	-- if os.time() - (self.m_tAuthMap[nSSKey] or 0) >= self.m_nPasswordTime then
	-- 	self.m_tAuthMap[nSSKey] = nil
	-- 	return 
	-- end
	-- return true
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd, bBrowser)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	local nRoleID, sRoleName, sAccount = 0, "", ""
	if oRole then
		nRoleID, sRoleName, sAccount = oRole:GetID(), oRole:GetName(), oRole:GetAccountName()
	end
	if not self:CheckAuth(sAccount, bBrowser) then
		if nServer < gnWorldServerID then
			CGRole:Tips("没有权限", nServer, nSession)
		end
		return LuaTrace("GM需要先授权")
	end

	LuaTrace(string.format("执行指令:%s [roleid:%d,rolename:%s,account:%s]", sCmd, nRoleID, sRoleName, sAccount))
	local oFunc = CGMMgr[sCmdName]
	if not oFunc then
		CGMMgr["lgm"](self, nServer, nService, nSession, tArgs)
		goLogger:EventLog(gtEvent.eGmCmd, oRole, sCmdName)
	else
		table.remove(tArgs, 1)
		local bRes = oFunc(self, nServer, nService, nSession, tArgs, bBrowser)
		goLogger:EventLog(gtEvent.eGmCmd, oRole, sCmdName)
		return bRes
	end
end

-----------------指令列表-----------------
--授权
CGMMgr["auth"] = function(self, nServer, nService, nSession, tArgs)
	local sPwd = tArgs[1] or ""
	local nSSKey = goGPlayerMgr:MakeSSKey(nServer, nSession)
	if sPwd == self.m_sPassword then
		self.m_tAuthMap[nSSKey] = os.time()
		LuaTrace("GM授权成功")
	else
		LuaTrace("GM授权密码错误")
	end
end

--设置新密码
CGMMgr["passwd"] = function(self, nServer, nService, nSession, tArgs)
	local sPasswd= tArgs[1] or ""
	if sPasswd == "" then
		return LuaTrace("密码不能为空")
	end
	self.m_sPassword = sPasswd
	return LuaTrace("GM密码设置成功")
end

--发送到LOGIC的GM
CGMMgr["lgm"] = function(self, nServer, nService, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	local sFlag = tArgs[1] == "reload" and tArgs[2] or nil
	local tList = goServerMgr:GetLogicServiceList()
	for _, tConf in pairs(tList) do
		if sFlag == "local" then
			if tConf.nServer == gnServerID then
				table.remove(tArgs, 2)
				sCmd = table.concat(tArgs, " ")
				Network.oRemoteCall:Call("GMCommandReq", tConf.nServer, tConf.nID, nSession, sCmd)
			end
		else
			Network.oRemoteCall:Call("GMCommandReq", tConf.nServer, tConf.nID, nSession, sCmd)
		end
	end
end

--发送到LOG的GM
CGMMgr["rgm"] = function(self, nServer, nService, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	local tList = goServerMgr:GetLogServiceList()
	for _, tConf in pairs(tList) do
		Network.oRemoteCall:CallWait("GMCommandReq", function(bRes) 
			if tArgs[1] == "reload" then
				if not bRes then
					CGRole:Tips("日志服 重载脚本失败", gnServerID, nSession)	
				else
					CGRole:Tips("日志服 重载脚本成功", gnServerID, nSession)	
				end
			end
		end,tConf.nServer, tConf.nID, nSession, sCmd)
	end
end

--发送到WGLOBAL的GM
CGMMgr["wgm"] = function(self, nServer, nService, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	local nServiceID1 = goServerMgr:GetGlobalService(gnWorldServerID, 110)
	Network.oRemoteCall:Call("GMCommandReq", gnWorldServerID, nServiceID1, nSession, sCmd)
end

--发送到WGLOBAL2的GM
CGMMgr["wgm2"] = function (self,nServer,nService,nSession,tArgs)
	local sCmd = table.concat(tArgs, " ")
	local nServiceID2 = goServerMgr:GetGlobalService(gnWorldServerID, 111)
	Network.oRemoteCall:Call("GMCommandReq", gnWorldServerID, nServiceID2, nSession, sCmd)
end

--发送到LOGIN的GM
CGMMgr["agm"] = function(self, nServer, nService, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	local nServiceID = goServerMgr:GetLoginService(gnServerID)
	Network.oRemoteCall:Call("GMCommandReq", gnServerID, nServiceID, nSession, sCmd)
end

-- 测试逻辑
CGMMgr["test"] = function(self, nServer, nService, nSession, tArgs)
	--local tBugFix = {19962, 23660}
	local tBugFix = {113724, 113723}
	for _, nRoleID in ipairs(tBugFix) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole and oRole:IsOnline() then
			CGMMgr["lgm"](self, oRole:GetStayServer(), oRole:GetLogic(), 0, {"test", nRoleID})
		else
	        local sData = goDBMgr:GetSSDB(gnServerID, "user", nRoleID):HGet(gtDBDef.sRoleDB, nRoleID)
	        if sData ~= "" then
		        local tData = cjson.decode(sData) 
		        tData.m_nYuanBao = 0
		        tData.m_nBYuanBao = 0
		        local sData = cjson.encode(tData)
		        goDBMgr:GetSSDB(gnServerID, "user", nRoleID):HSet(gtDBDef.sRoleDB, nRoleID, sData)
				LuaTrace("处理玩家刷元宝", oRole:GetID(), oRole:GetName()) 
			else
				LuaTrace("玩家不存在", nRoleID)
		    end
		end
	end
end

--重载脚本
CGMMgr["reload"] = function(self, nServer, nService, nSession, tArgs)
	local sScript = tArgs[1] or ""
	local bRes, sTips = false, ""
	if sScript == "" then
		bRes = gfReloadAll("GlobalServer")
		sTips = "重载所有脚本 "..(bRes and "成功!" or "失败!")
	else
		bRes = gfReloadScript(sScript, "GlobalServer")
		sTips = "重载 '"..sScript.."' ".. (bRes and "成功!" or "失败!")
	end
	LuaTrace(sTips)
	CGRole:Tips("本地全局 "..sTips, gnServerID, nSession)	
	return bRes
end

--重载所有服务脚本
CGMMgr["reloadall"] = function(self, nServer, nService, nSession, tArgs, bBrowser)
	self:OnGMCmdReq(nServer, nService, nSession, "wgm reloadall", bBrowser)
end

--发送公告
CGMMgr["sendnotice"] = function(self, nServer, nService, nSession, tArgs)
	local nID = tonumber(tArgs[1]) or 0 	--公告ID(随意)
	local nKeep = tonumber(tArgs[2]) or 0 	--持续时间(秒)
	local nIntval = tonumber(tArgs[3]) or 0	--间隔(秒)
	local sContent = tonumber(tArgs[4]) or 0 	--公告内容(秒)
	if goNoticeMgr:GMSendNotice(nID, os.time(), os.time()+nKeep, nIntval, sContent) then
		return CGRole:Tips("发送公告成功", nServer, nSession)
	end
	return CGRole:Tips("发送公告失败", nServer, nSession)
end

--GIT更新
CGMMgr['svnupdate'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local tBanList = {
		[7]={[7]=true, }, 
	}
	
	if gbInnerServer and tBanList[gnGroupID] then
		if tBanList[gnGroupID][gnServerID] then  
			oRole:Tips("当前服务器禁止执行该命令！")
			return 
		end
	end

	if io.FileExist("../linux.txt") then
		os.execute("sh ../svnupdate.sh > ../svnupdate.log")
	else
	    local f = io.popen("..\\svnupdate.bat")
	    repeat
	        local cont = f:read("l")
	        if cont then
	        	print(cont)
	        end
	    until(not cont)
	    f:close()
	end
	
	CGMMgr["reloadall"](self, nServer, nService, nSession, tArgs)
	oRole:Tips("执行svnupdate指令成功")
end

--发送邮件
CGMMgr["sendmail"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPropType = tonumber(tArgs[1]) or 0
	local nPropID = tonumber(tArgs[2]) or 0
	local nPropNum = tonumber(tArgs[3]) or 0
	local tConf = ctPropConf[nPropID]
	if not tConf then
		return oRole:Tips("道具不存在")
	end
	local tItemList = {}
	if nPropID > 0 and nPropNum > 0 then
		tItemList = {{nPropType,nPropID,nPropNum},{nPropType,nPropID,nPropNum},{nPropType,nPropID,nPropNum}}
	end
	goMailMgr:SendServerMail("测试邮件", "邮件测试", tItemList, true)
	oRole:Tips("发送邮件成功")
end

--清除全局邮件
CGMMgr['clrsrvmail'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nMailID = tonumber(tArgs[1]) or 0
	goMailMgr:GMDelServerMail(nMailID)
	oRole:Tips("清空全服邮件成功")
end

--清除角色邮件
CGMMgr['clrmail'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nMailID = tonumber(tArgs[1]) or 0
	goMailMgr:GMDelMail(oRole, nMailID)
	oRole:Tips("清空角色邮件成功")
end



--商城
CGMMgr['SysMallInfo'] = function(self, nServer, nService, nSession, tArgs)
	print("系统商城信息**************")
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if tonumber(tArgs[1]) == 1 then
		goMallMar:GetSubShop(101):FindItem(1500)
	elseif tonumber(tArgs[1]) == 2 then
		--print("goMallMar:GetSubShop(101)", goMallMar:GetSubShop(101))
		goMallMar:GetSubShop(101):AddChamberCoreItem()
	elseif tonumber(tArgs[1]) == 3 then
		goMallMar:GetSubShop(101):FastBuyListReq(oRole, 101,1102)
	end
end

--添加商会道具
CGMMgr['addchambercoreItem'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goMallMar:GetSubShop(101):AddChamberCoreItem()
	oRole:Tips("添加商会道具成功")
end

--修改商会价格
CGMMgr['modifychambercorepropparice'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPropID = tonumber(tArgs[1])
	goMallMar:GetSubShop(101):modifyPropParice(nPropID)
	oRole:Tips("价格刷新成功")
end

--批量修改商会价格
CGMMgr['batchupdateprice'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	goMallMar:GetSubShop(101):AllmodifyPropParice()
	if oRole then
		oRole:Tips("道具价格刷新成功")
	end
end

--添加竞技场挑战次数
CGMMgr["addarenachall"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oRoleArena = goArenaMgr:GetRoleArenaInfo(oRole:GetID())
	if not oRoleArena then
		oRole:Tips("当前角色尚未参与竞技场")
		return
	end
	local nCount = tonumber(tArgs[1])
	if not nCount or type(nCount) ~= "number" then
		oRole:Tips("参数不正确，请附带需要添加的挑战次数")
		return
	end
	oRoleArena:AddChallenge(nCount)
	goArenaMgr:SyncRoleInfo(oRole)
end

--挑战竞技场机器人
CGMMgr["arenarobot"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local oRoleArena = goArenaMgr:GetRoleArenaInfo(oRole:GetID())
	if not oRoleArena then
		-- oRole:Tips("当前角色尚未参与竞技场")
		-- return
		goArenaMgr:InsertRoleArenaData(oRole)
		oRoleArena = goArenaMgr:GetRoleArenaInfo(oRole:GetID())
	end
	local nTargetID = tonumber(tArgs[1])
	if not nTargetID or not ctArenaRobotConf[nTargetID] then
		oRole:Tips("参数不正确，请输入正确的机器人ID")
		return
	end

	if goArenaMgr.m_tBattleReqRecord[nRoleID] then
		oRole:Tips("操作频繁") --不响应
		return
	end

	local nTimeStamp = os.time() + 5  --5秒超时
	goArenaMgr.m_tBattleReqRecord[nRoleID] = nTimeStamp

	local fnArenaCheckCallback = function (bRet, sReason)
		if not bRet then
			if sReason then
				oRole:Tips(sReason)
			end
			return
		end
		if not goArenaMgr.m_tBattleReqRecord[nRoleID] then
			oRole:Tips("请求超时")
			return
		end
		goArenaMgr.m_tBattleReqRecord[nRoleID] = nil

		if not goArenaMgr:IsOpen() then --再次检查下，防止极端情况，rpc调用期间，状态发生了切换
			oRole:Tips("当前未开放")
			return
		end
		--发起战斗请求
		local  tEnemyData = {}
		tEnemyData.nEnemyID = nTargetID
		tEnemyData.nServerLevel = goServerMgr:GetServerLevel(gnServerID)
		Network.oRemoteCall:Call("ArenaBattleReq", oRole:GetStayServer(), oRole:GetLogic(), 
			oRole:GetSession(), oRole:GetID(), tEnemyData, goArenaMgr:GetArenaSeason())
	end
	--取玩家当前所在逻辑服
	Network.oRemoteCall:CallWait("ArenaBattleCheckReq", fnArenaCheckCallback, oRole:GetStayServer(), 
		oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), nTargetID)
end

--添加竞技场积分
CGMMgr["addarenascore"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oRoleArena = goArenaMgr:GetRoleArenaInfo(oRole:GetID())
	if not oRoleArena then
		oRole:Tips("当前角色尚未参与竞技场")
		return
	end
	local nAddScore = tonumber(tArgs[1])
	if not nAddScore then
		oRole:Tips("参数不正确，请附带要添加的竞技场积分数量")
		return
	end
	oRoleArena:AddScore(nAddScore)
	goArenaMgr:SyncRoleInfo(oRole)
end

--赛季切换 Arg[1]赛季ID, Arg[2]是否切换后直接开启新赛季，如果有提供且大于0，则马上开启，否则处于准备状态，直到配置的开启时间才开启
CGMMgr["switcharena"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nNewSeason = tonumber(tArgs[1])
	if not nNewSeason or nNewSeason < 1 then
		oRole:Tips("参数不正确，竞技场赛季需大于0")
		return
	end
	if goArenaMgr:IsSwitchSeason() then
		oRole:Tips("当前正在进行竞技场赛季结算，无法切换竞技场赛季")
		return
	end
	local tArenaSeasonConf = CArena:GetSeasonConf(nNewSeason)
	if not tArenaSeasonConf then
		local sComment = string.format("赛季<%d>在竞技场赛季配置表中不存在", nNewSeason)
		oRole:Tips(sComment)
		return
	end
	if goArenaMgr:GetArenaSeason() == nNewSeason then
		local sComment = string.format("赛季<%d>和当前赛季一致，无需切换", nNewSeason)
		oRole:Tips(sComment)
		return
	end

	--当前功能实现及竞技场赛季状态迁移
	--可以切换到一个当前尚未到达开启时间的新赛季(即开启时间比当前时间戳大)
	--但不能切换到一个当前已经结束了的赛季(即结束时间比当前时间戳小)
	local nEndStamp = CArena:GetSeasonEndTimeByConf(tArenaSeasonConf)
	local nCurTime = os.time()
	if nEndStamp < nCurTime then
		local sComment = string.format("赛季<%d>的结束时间小于当前时间，无法切换", nNewSeason)
		oRole:Tips(sComment)
		return
	end
	if (nEndStamp - nCurTime) < (10 * 60) then --防止数据过多，赛季结算超时
		local sComment = string.format("赛季<%d>的结束时间离当前不足10分钟，无法切换", nNewSeason)
		oRole:Tips(sComment)
		return
	end

	--第二个参数，用于控制是否马上开启新赛季
	--可能目标赛季，在切换后，当前未到达开启时间，则会处于赛季准备状态
	local bOpenNow = false
	local nOpenNowFlag = tonumber(tArgs[2])
	if nOpenNowFlag and nOpenNowFlag > 0 then
		bOpenNow = true
	end

	goArenaMgr:SetSeasonState(gtArenaSeasonState.eSwitchSeason) --将状态切换为赛季结算，会自动进行后续结算操作
	goArenaMgr.m_nGMSwitchSeason = nNewSeason
	goArenaMgr.m_bSwithOpen = bOpenNow
	goArenaMgr:MarkDirty(true)

	oRole:Tips("操作成功，开始切换到赛季"..nNewSeason)
end

CGMMgr["arenarobot"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goArenaMgr:GMMatchRobot(oRole)
end

--获取竞技场奖励 Arg[1]奖励类型 Arg[2]奖励等级(如果没有，可不提供，没提供，则用缺省值)
CGMMgr["getarenareward"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oRoleArena = goArenaMgr:GetRoleArenaInfo(oRole:GetID())
	if not oRoleArena then
		oRole:Tips("当前角色尚未参与竞技场")
		return
	end
	local nRewardType = tonumber(tArgs[1])
	if not nRewardType or type(nRewardType) ~= "number" then
		oRole:Tips("奖励类型不正确")
		return
	end
	local bValid = false
	for k, v in pairs(gtArenaRewardType) do
		if v == nRewardType then
			bValid = true
		end
	end
	if not bValid then
		oRole:Tips("奖励类型不正确")
		return
	end

	local nRewardLevel = tonumber(tArgs[2])
	if gtArenaRewardType.eArenaLevelBox == nRewardType then
		if not nRewardLevel or type(nRewardLevel) ~= "number" then
			nRewardLevel = 5
		else
			nRewardLevel = math.max(math.min(nRewardLevel, 5), 0)
		end
		print("nRewardLevel:"..nRewardLevel)
	end
	oRoleArena:SetArenaRewardState(nRewardType, gtArenaRewardState.eAchieved, nRewardLevel)
	goArenaMgr:GetArenaReward(oRole, nRewardType)
	oRole:Tips("领取竞技场奖励成功")
end

--增加帮派经验
CGMMgr['addunionexp'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByRoleID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入帮派")
	end
	local nExp = tonumber(tArgs[1]) or 0
	oUnion:AddExp(nExp, "GM", oRole)
	oRole:Tips(string.format("增加%d点帮派经验", nExp))
end

--增加帮派贡献
CGMMgr['addunioncontri'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByRoleID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入帮派")
	end
	local nContri = tonumber(tArgs[1]) or 0
	local oUnionRole = goUnionMgr:GetUnionRole(oRole:GetID())
	oUnionRole:AddUnionContri(nContri, "GM")
	oRole:Tips(string.format("增加%d点帮派贡献", nContri))
end

--减少帮派活跃度
CGMMgr['addunionactivity'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByRoleID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入帮派")
	end
	local nActivity = tonumber(tArgs[1]) or 0
	oUnion:AddActivity(nActivity, "GM", oRole)
	oRole:Tips(string.format("增加%d点帮派活跃度", nActivity))
end
CGMMgr['combindunion'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nRes = goUnionMgr:CombindUnion()
	if nRes == -1 then
		return oRole:Tips("没有要合并帮派")
	end
	if nRes == -2 then
		return oRole:Tips("没有满足条件的目标帮派")
	end
	return oRole:Tips(string.format("成功合并帮派数:%d", nRes))
end
CGMMgr['unionretire'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByRoleID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入帮派")
	end
	oUnion:OnHourTimer()
end

--成就系统
CGMMgr['achieve'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nOperaType = tonumber(tArgs[1]) or 0
	if nOperaType == 1 then
		oRole:PushAchieve("成就测试2",{nValue = 1})
	end
end

--开启活动
CGMMgr['openact'] = function(self, nServer, nService, nSession, tArgs, bBrowser)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole and not bBrowser then return end
	local nID = tonumber(tArgs[1]) or 0 
	local nMin =  tonumber(tArgs[2]) or 0
	local nSubID = tonumber(tArgs[3]) or 0
	local nExtID = tonumber(tArgs[4]) or 1
	local nExtID1 = tonumber(tArgs[5]) or 10001
	local nEndTime = math.ceil(nMin+os.time()/60)*60
	goHDMgr:GMOpenAct(nID, nSubID, os.time(), nEndTime, nil, nExtID, nExtID1)
	if oRole then 
		oRole:Tips("指令执行成功")
	end
end

--关闭活动
CGMMgr['closeact'] = function(self, nServer, nService, nSession, tArgs, bBrowser)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole and not bBrowser then return end
	local nID = tonumber(tArgs[1]) or 0 
	local nSubID = tonumber(tArgs[2]) or 0
	goHDMgr:GMOpenAct(nID, nSubID, os.time(), os.time(), 0, 0, 0)
	return true
end

--关闭所有活动
CGMMgr['closeallact'] = function(self, nServer, nService, nSession, tArgs, bBrowser)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole and not bBrowser then return end
	for nID, tConf in pairs(ctHuoDongConf) do
		local oAct = goHDMgr:GetActivity(nID)
		if oAct then
			if tConf.bSubAct then
				for nSubID, tConf in pairs(ctTimeAwardConf) do
					goHDMgr:GMOpenAct(nID, nSubID, os.time(), os.time(), 0, 0, 0)
				end
			else
				goHDMgr:GMOpenAct(nID, 0, os.time(), os.time(), 0, 0, 0)
			end
		elseif tConf.bCrossServer then
			goHDMgr:GMOpenAct(nID, 0, os.time(), os.time(), 0, 0, 0)
		end
	end
	if oRole then 
		oRole:Tips("关闭所有活动成功")
	end
end

--开启所有活动
CGMMgr['openallact'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nActTime = tonumber(tArgs[1]) or 7*3600*24
	for nID, tConf in pairs(ctHuoDongConf) do
		local oAct = goHDMgr:GetActivity(nID)
		if oAct then
			if tConf.bSubAct then
				for nSubID, tConf in pairs(ctTimeAwardConf) do
					goHDMgr:GMOpenAct(nID, nSubID, os.time(), os.time()+nActTime, 0, 1, 0)
				end
			else
				goHDMgr:GMOpenAct(nID, 0, os.time(), os.time()+nActTime, 0, 1, 0)
			end
		elseif tConf.bCrossServer then
			goHDMgr:GMOpenAct(nID, 0, os.time(), os.time()+nActTime, 0, 1, 0)
		end
	end
end

--零元活动测试
CGMMgr["zeroact"] = function (self, nServer, nService, nSession, tArgs)
	local nActID = tonumber(tArgs[1])
	local nType = tonumber(tArgs[2])
	local oAct = goHDMgr:GetActivity(gtHDDef.eZeroYuan)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if oAct then
		if nType == 1 then
			oAct:InfoReq(oRole)
		elseif nType == 2 then
			oAct:BuyQualificattionsReq(oRole, tonumber(tArgs[3]))
		elseif nType == 3 then
			oAct:AwardReq(oRole, tonumber(tArgs[3]))
		elseif nType == 4 then
			oAct:ClearRoleActData(oRole)
		elseif nType == 5 then
		oAct:SyncState(oRole)
		end
	end
end

CGMMgr["union"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nRoleID = oRole:GetID()
	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end
		local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
		if not oUnion then return end
		oUnion:UnionOpenGiftBoxReq(oRole)
	elseif nOperaType ==2 then
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end
		local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
		if not oUnion then return end
		local tRoleID = {oRole:GetID()}
		oUnion:UnionDispatchGiftReq(oRole,tRoleID)
	elseif nOperaType == 3 then
		local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
		if not oRole then return end
		local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
		if not oUnion then return end
		oUnion:UnionEnterSceneReq(oRole)
	elseif nOperaType == 4 then
		local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
		if not oRole then return end
		local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
		if not oUnion then return end
		oUnion:Dismiss()
	elseif nOperaType == 5 then
		local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
		if oUnionRole then
			oUnionRole:MarkDirty(true)
			oUnionRole.m_nDispatchGiftBoxTime = 0
		end
	elseif nOperaType == 6 then
		local oUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
		if not oUnion then return end
		oUnion:ResetBoxData()
	end
end

--防止操作错误，单独加一项接口
CGMMgr["uniondismiss"] = function (self,nServer,nService,nSession,tArgs,bBrowser)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole and not bBrowser then return end
	local nUnionID = tonumber(tArgs[1])
	if not nUnionID or nUnionID <= 0 then
		return 
	end
	local oUnion = goUnionMgr:GetUnion(nUnionID)
	if not oUnion then 
		return
	end
	oUnion:Dismiss()
	print("成功解散帮派:"..nUnionID)
end

CGMMgr['exchangeact'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nOpera = tonumber(tArgs[1])
	local nActID = tonumber(tArgs[2])
	local nExchangeID = tonumber(tArgs[3])
	if nOpera == 1 then			--请求信息
		goExchangeActivityMgr:ExchangeInfoReq(oRole)
	elseif nOpera == 2 then		--兑换
		goExchangeActivityMgr:ExchangeReq(oRole, nActID, nExchangeID)
	elseif nOpera == 3 then		--活动开启
		local oAct = goExchangeActivityMgr.m_tActivityMap[nActID]
		oAct.m_nBeginTimestamp = os.time()
		oAct.m_nEndTimestamp = oAct.m_nBeginTimestamp + 86400
		oAct:MarkDirty(true)
		oAct:CheckState()
	elseif nOpera == 4 then		--活动关闭
		local oAct = goExchangeActivityMgr.m_tActivityMap[nActID]
		oAct.m_nEndTimestamp = os.time()
		oAct:MarkDirty(true)
		oAct:CheckState()
	elseif nOpera == 5 then
		goExchangeActivityMgr:GMViewActState()
	elseif nOpera == 6 then
		goExchangeActivityMgr:ExchangeActClickReq(oRole, nActID)
	end
end

CGMMgr['yyhd'] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end

	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then
		local tData = {
			nID = tonumber(tArgs[2])
		}
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end

		local oAct = goHDMgr:GetActivity(tData.nID)
		if oAct then
			oAct:SyncState(oRole)
		else
			--全服团购首充
			if tData.nID == gtHDDef.eTC then
				Network.oRemoteCall:Call("ActYYStateReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
			end
		end
	elseif nOperaType == 2 then
		local tData = {
			nID = tonumber(tArgs[2])
		}
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end
		local oAct = goHDMgr:GetActivity(tData.nID)
		if oAct then
			oAct:InfoReq(oRole)
		else
			if tData.nID == gtHDDef.eTC then
				Network.oRemoteCall:Call("ActYYInfoReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
			end
		end
	elseif nOperaType == 3 then
		if #tArgs < 3 then
			return oRole:Tips("参数错误")
		end
		local tData = {
			nID = tonumber(tArgs[2]),
			nRewardID = tonumber(tArgs[3]),
		}
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end
		local oAct = goHDMgr:GetActivity(tData.nID)
		if oAct then
			oAct:AwardReq(oRole, tData.nRewardID)
		else
			if tData.nID == gtHDDef.eTC then
				Network.oRemoteCall:Call("ActYYAwardReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
			end
		end
	elseif nOperaType == 4 then
		local tSCConf = ctSCConf
		print("---------yyhd-----------",tSCConf)
	elseif nOperaType == 11 then
		local oAct = goHDMgr:GetActivity(tonumber(tArgs[2]))
		if oAct then
			oAct:CheckAward()
		end
	end
end

CGMMgr["rank"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end

	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then
		local nRank = tonumber(tArgs[2])
		local oRank = goRankingMgr:GetRanking(nRank)
		if not oRank then
			return oRole:Tips("参数错误")
		end
		oRank:NewDay()
	elseif nOperaType == 2 then
		goRankingMgr:NewDay()
	end
end

CGMMgr["resetrank"] = function (self,nServer,nService,nSession,tArgs)
	goRankingMgr:GMResetRanking()
end

--重置循环活动
CGMMgr["resethdcircle"] = function (self,nServer,nService,nSession,tArgs, bBrowser)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole and not bBrowser then return end
	goHDCircle:GMReset(oRole)
	return true
end

--设置时间
CGMMgr['mtime'] = function(self, nSession, tArgs)
	-- local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	-- if not oPlayer then return end
	-- local year = tonumber(tArgs[1])
	-- local month = tonumber(tArgs[2])
	-- local day  = tonumber(tArgs[3])
	-- local hour = tonumber(tArgs[4]) or 0
	-- local min = tonumber(tArgs[5]) or 0
	-- local sec = tonumber(tArgs[6]) or 0
	-- if not year or not month or not day then
	-- 	return
	-- end
	-- local sCmd = string.format('date -s "%d-%d-%d %d:%d:%d"', year, month, day, hour, min, sec)
	-- print(os.execute(sCmd))
	-- local sTime = os.date("%c", os.time())
	-- oPlayer:Tips("执行指令成功，当前时间: "..sTime)
end

CGMMgr["cb"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end

	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then
		local tData = {}
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end
		goCBMgr:SyncState(oRole)
		Network.oRemoteCall:Call("SyncCBState", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
	elseif nOperaType == 2 then
		local tData = {
			nID = tonumber(tArgs[2])
		}
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end
		if tData.nID < 10 or tData.nID > 20 then
			return oRole:Tips("不是冲榜活动，协议发错了？")
		end
		local oAct = goHDMgr:GetActivity(tData.nID)
		if oAct then
			oAct:InActivityReq(oRole)
		else
			--全服活动
			if table.InArray(tData.nID,{gtHDDef.eServerRechargeCB,gtHDDef.eServerResumYBCB}) then
				Network.oRemoteCall:Call("CBInActivityReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
			else
				oRole:Tips("活动:"..tData.nID.."不存在")
			end
		end
	elseif nOperaType == 3 then
		local tData = {
			nID = tonumber(tArgs[2]),
			nRankNum = 50,
		}
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end 
		if tData.nID < 10 or tData.nID > 20 then
			return oRole:Tips("不是冲榜活动，协议发错了？")
		end
		local oAct = goHDMgr:GetActivity(tData.nID)
		if oAct then
			oAct:RankingReq(oRole, tData.nRankNum)
		else
			--全服活动
			if table.InArray(tData.nID,{gtHDDef.eServerRechargeCB,gtHDDef.eServerResumYBCB}) then
				Network.oRemoteCall:Call("CBRankingReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
			else
				oRole:Tips("活动:"..tData.nID.."不存在")
			end
		end
	elseif nOperaType == 4 then
		local tData = {
			nID = tonumber(tArgs[2])
		}
		local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end
		if tData.nID < 10 or tData.nID > 20 then
			return oRole:Tips("不是冲榜活动，协议发错了？")
		end
		local oAct = goHDMgr:GetActivity(tData.nID)
		if oAct then
			oAct:GetAwardReq(oRole)
		else
			--全服活动
			if table.InArray(tData.nID,{gtHDDef.eServerRechargeCB,gtHDDef.eServerResumYBCB}) then
				Network.oRemoteCall:Call("CBGetAwardReq", gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0,oRole:GetID(),tData)
			else
				oRole:Tips("活动:"..tData.nID.."不存在")
			end 
		end
	elseif nOperaType == 11 then
		local nID = tonumber(tArgs[2])
		local oAct = goHDMgr:GetActivity(nID)
		if oAct then
			oAct:OnStateClose()
		end
	end
end
