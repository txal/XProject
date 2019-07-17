--GM指令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGMMgr:Ctor()
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	local nRoleID, sRoleName, sAccount = 0, "", ""
	if oRole then
		nRoleID, sRoleName, sAccount = oRole:GetID(), oRole:GetName(), oRole:GetAccountName()
	end
	local sInfo = string.format("执行指令:%s [roleid:%d,rolename:%s,account:%s]", sCmd, nRoleID, sRoleName, sAccountName)
	LuaTrace(sInfo)

	local oFunc = CGMMgr[sCmdName]
	if not oFunc then
		LuaTrace("找不到指令:["..sCmdName.."]")
		return CRole:Tips("找不到指令:["..sCmdName.."]", nServer, nSession)
	end
	table.remove(tArgs, 1)

	return oFunc(self, nServer, nService, nSession, tArgs)
    -- xpcall(function() oFunc(self, nServer, nService, nSession, tArgs) end, function(sErr)
    -- 	print(sErr, debug.traceback())
    -- 	CRole:Tips(sErr, nServer, nSession)
    -- end)
end

-----------------指令列表-----------------
--测试逻辑模块
CGMMgr["test"] = function(self, nServer, nService, nSession, tArgs)
	NetworkExport.DumpPacket()
end

--测试战斗
CGMMgr["tbt"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then
		return
	end
	local tDupConf = oRole:GetDupConf()
	local nID = oRole:GetBattleID()
	local oBattle = goBattleMgr:GetBattle(nID)
	if oBattle then
		oBattle:ForceFinish()
	else
		oRole:SetBattleID(0)
	end
	local oMonster = goMonsterMgr:GetMonsterByConfID(999)
	oRole:PVE(oMonster)
end

--测试活动
CGMMgr["JoinAct"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then
		return
	end
	if tonumber(tArgs[1]) == 1 then
		local nID = tonumber(tArgs[1])
		oRole.m_oDailyActivity:JoinAct(201)
	elseif tonumber(tArgs[1]) == 2 then
		goPVEActivityMgr:EnterBattleDupReq(oRole)
	elseif tonumber(tArgs[1]) == 3 then
		goPVEActivityMgr:Start()
	end
end

--测试战斗
CGMMgr["PVE"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then
		return
	end
	
	if tonumber(tArgs[1]) == 1 then
		goPVEActivityMgr:EnterReadyDupReq(oRole)
	elseif tonumber(tArgs[1]) == 2 then
		goPVEActivityMgr:EnterBattleDupReq(oRole)
	elseif tonumber(tArgs[1]) == 3 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:CreateMonsterReq(oRole)
	elseif tonumber (tArgs[1]) == 4 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		local nMonsterID = next(oBattleDup.m_tMonsterMap)
		print("怪物----->", nMonsterID)
		oBattleDup:AttackMonsterReq(oRole, nMonsterID)
	elseif tonumber(tArgs[1]) == 5 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:ClickFlopReq(oRole, tonumber(tArgs[2]) or 1)
	elseif tonumber(tArgs[1]) == 6 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:PinTuResuitReq(oRole, tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 7 then
		goPVEActivityMgr:MatchTeamReq(oRole, 2)
	elseif tonumber(tArgs[1]) == 8 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:PinTuResuitReq(oRole,1)
	elseif tonumber(tArgs[1]) == 9 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:ChallengeStart(oRole,1)
	elseif tonumber(tArgs[1]) == 10 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:SwitchMapReq(oRole, tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 11 then
		goPVEActivityMgr:SetDupType(tonumber(tArgs[2]))
		
	elseif tonumber(tArgs[1]) == 12 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:Settlement()
	elseif tonumber(tArgs[1]) == 13 then
		goPVEActivityMgr:PVEActSettle()
	elseif tonumber(tArgs[1]) == 14 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:GMOut(oRole)
	elseif tonumber(tArgs[1]) == 15 then
		print("结算数据", goPVEActivityMgr.m_tPVEAppellationData)
	elseif tonumber(tArgs[1]) == 16 then
		goPVEActivityMgr:ClearPVEData(oRole)
	elseif tonumber(tArgs[1]) == 17 then
		goPVEActivityMgr:GMOpen(tonumber(tArgs[2]), oRole)
	elseif tonumber(tArgs[1]) == 18 then
		goPVEActivityMgr:GMClose(tonumber(tArgs[2]),oRole)
	end
end

--
CGMMgr["openpveact"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nActivityID = tonumber(tArgs[1])
	if not nActivityID then
		return oRole:Tips("活动ID错误")
	end
	--TODD准备时间默认五分钟
	local nReadyTime = tonumber(tArgs[2])

	nReadyTime = nReadyTime and nReadyTime or 5
	nReadyTime = nReadyTime > 5 and 5 or nReadyTime
	if nReadyTime < 1 then
		return oRole:Tips("准备时间错误")
	end

	local nEndMin = tonumber(tArgs[3])
	nEndMin = nEndMin and nEndMin or 60
	if nEndMin < 1 then
		return oRole:Tips("开启时间错误")
	end
	goPVEActivityMgr:GMOpen(nActivityID, nReadyTime, nEndMin, oRole)
end

--关闭限时活动
CGMMgr["closepveact"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nActivityID = tonumber(tArgs[1])
	if not nActivityID then
		return oRole:Tips("活动ID错误")
	end
	goPVEActivityMgr:GMClose(nActivityID,oRole)
end

--清除PVE相关信息
CGMMgr["clearpve"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_tPVEActData = {}
end

--测试战斗
CGMMgr["pvp"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nTarRoleID = tonumber(tArgs[1])	
	local oTarRole = goPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTarRole then
		return oRole:Tips("目标不在线")
	end
	local oBattle = goBattleMgr:GetBattle(oRole:GetBattleID())
	if oBattle then
		oBattle:ForceFinish()
	end
	oRole:PVP(oTarRole)
end


--服务器等级
CGMMgr["serverlv"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole:Tips("服务器等级:"..goServerMgr:GetServerLevel(oRole:GetServer()))
end

--重载脚本
CGMMgr["reload"] = function(self, nServer, nService, nSession, tArgs)
	local bRes, sTips = false, ""
	if #tArgs == 0 then
		bRes = gfReloadAll("LogicServer")
		sTips = "重载所有脚本 "..(bRes and "成功!" or "失败!")

	elseif #tArgs == 1 then
		local sFileName = tArgs[1]
		bRes = gfReloadScript(sFileName, "LogicServer")
		sTips = "重载脚本 '"..sFileName.."' ".. (bRes and "成功!" or "失败!")

	end
	LuaTrace(sTips)
	CRole:Tips("逻辑服"..sTips, nServer, nSession)
	return bRes
end

--输出指令耗时信息
CGMMgr["dumpcmd"] = function(self, nServer, nService, nSession, tArgs)
	goCmdMonitor:DupCmd()
end

--输出LUA表使用情况
CGMMgr["dumptable"] = function(self, nServer, nService, nSession, tArgs)
	goWatchDog:DumpTable()
end

--添加物品
CGMMgr["additem"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if #tArgs < 3 then return oRole:Tips("参数错误") end

	local nItemType, nItemID, nItemNum, nBind = tonumber(tArgs[1]), tonumber(tArgs[2]), tonumber(tArgs[3]), (tonumber(tArgs[4]) or 0)
    if not (nItemType > 0 and nItemID > 0 and nItemNum) then
    	print("参数错误:", nItemType, nItemID, nItemNum)
    	return oRole:Tips("参数错误")
    end
	local bItemTypeExist = false
	for k, v in pairs(gtItemType) do
    	if v == nItemType then
    		bItemTypeExist = true
    		break
    	end
    end
    if not bItemTypeExist then
    	return oRole:Tips("不存在的物品类型:"..nItemType)
    end
    if nItemType == gtItemType.eProp then
	    local tConf = ctPropConf[nItemID]
	    if not tConf then
	    	return oRole:Tips("道具不存在:"..nItemID)
	    end
    elseif nItemType == gtItemType.eCurr then
    	local bCurrExist = false
    	for k, v in pairs(gtCurrType) do
    		if v == nItemID then
    			bCurrExist = true
    			break
    		end
    	end
    	if not bCurrExist then
    		return oRole:Tips("不存在的货币类型:"..nItemID)
    	end	
    end
	if oRole:AddItem(nItemType, nItemID, nItemNum, "GM", false, nBind==1) then
		oRole:Tips("添加物品成功")
	end
end

--添加测试道具
CGMMgr["addtestitem"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if #tArgs < 3 then return oRole:Tips("参数错误") end

	local nItemType, nItemID, nItemNum = tonumber(tArgs[1]), tonumber(tArgs[2]), tonumber(tArgs[3])
    if not (nItemType > 0 and nItemID > 0 and nItemNum) then
    	print("参数错误:", nItemType, nItemID, nItemNum)
    	return oRole:Tips("参数错误")
    end
	local bItemTypeExist = false
	for k, v in pairs(gtItemType) do
    	if v == nItemType then
    		bItemTypeExist = true
    		break
    	end
    end
    if not bItemTypeExist then
    	return oRole:Tips("不存在的物品类型:"..nItemType)
	end
	
	local tPropExt = {}
    if nItemType == gtItemType.eProp then
	    local tConf = ctPropConf[nItemID]
	    if not tConf then
	    	return oRole:Tips("道具不存在:"..nItemID)
		end
		if ctEquipmentConf[nItemID] then 
			-- if not gbInnerServer then 
			-- 	oRole:Tips("当前为外网模式，无法获得测试装备")
			-- end
			-- tPropExt.nSource = gbInnerServer and gtEquSourceType.eTest or gtEquSourceType.eShop
			tPropExt.nSource = gtEquSourceType.eTest
			if not ctEquipmentFromConf[tPropExt.nSource] then 
				tPropExt.nSource =  gtEquSourceType.eShop
			end
		end
    elseif nItemType == gtItemType.eCurr then
    	local bCurrExist = false
    	for k, v in pairs(gtCurrType) do
    		if v == nItemID then
    			bCurrExist = true
    			break
    		end
    	end
    	if not bCurrExist then
    		return oRole:Tips("不存在的货币类型:"..nItemID)
    	end	
	end
	if oRole:AddItem(nItemType, nItemID, nItemNum, "GM测试道具", nil, true, tPropExt) then
		oRole:Tips("添加物品成功")
	end
end

--添加所有物品
CGMMgr["itemall"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	for nID, tConf in pairs(ctPropConf) do
		oRole:AddItem(gtItemType.eProp, nID, 99, "GM")
	end
end

--通关副本
CGMMgr["duppass"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
end

--模拟充值
CGMMgr["gmrecharge"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nID = tonumber(tArgs[1]) or 0
	oRole.m_oVIP:GMRecharge(nID)
end

--vip
CGMMgr["vip"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if tonumber(tArgs[1]) == 1 then
		oRole.m_oVIP:RechargeRebateAwardReq(tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 2 then
		oRole.m_oVIP:RechargeRebateAwardInfoReq()
	end
end

-- --活动时间
-- CGMMgr["hdtime"] = function(self, nServer, nService, nSession, tArgs)
-- 	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
-- 	if not oRole then return end
-- 	local nID = tonumber(tArgs[1]) or 0
-- 	local nMin =  tonumber(tArgs[2]) or 0
-- 	local nSubID = tonumber(tArgs[3]) or 0
-- 	local nExtID = tonumber(tArgs[4]) or 0
-- 	local nEndTime = math.ceil(nMin+os.time()/60)*60
-- 	goHDMgr:GMOpenAct(nID, os.time(), nEndTime, nSubID, nExtID)
-- end

--完成主线任务
CGMMgr['mtask'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nID = tonumber(tArgs[1])
	oRole.m_oMainTask:GMCompleteTask(nID)
end

--生成主线任务
CGMMgr['inittask'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nID = tonumber(tArgs[1])
	oRole.m_oMainTask:GMInitTask(nID)
end

--重置日常任务
CGMMgr['resetdt'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oDailyTask:GMReset()
	oRole:Tips("重置日常任务成功")
end

--系统消息
CGMMgr['systalk'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local sTitle = tArgs[1] or "系统"
	local sContent = tArgs[2] or "消息测试"
	CUtil:SendSystemTalk(sTitle, sContent)
end

--重置帮派宴会出战知己
CGMMgr['resetunfz'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByCharID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入帮派")
	end
	oUnion.m_oUnionParty:GMResetFZ(oRole)
end

--清空聊天
CGMMgr['clrtalk'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goTalk:GMClearTalk(oRole)
end

--任务系统
CGMMgr['task'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	
	local nOperaType = tonumber(tArgs[1])
	local nTaskType = tonumber(tArgs[2])
	local nTaskID = tonumber(tArgs[3])

	if nOperaType == 1 then		--设置任务
		local tParam
		if nTaskType == CTaskSystem.tTaskType.ePrinTask then
			tParam = oRole.m_oTaskSystem.m_tCurrPrinTaskParam
			oRole.m_oTaskSystem.m_nCurrPrinTaskID = nTaskID
		elseif nTaskType == CTaskSystem.tTaskType.eBranchTask then
			tParam = oRole.m_oTaskSystem.m_tCurrBranchTaskParam
			oRole.m_oTaskSystem.m_nCurrBranchTaskID = nTaskID
		end
		tParam.nNpcID = 0
		tParam.nTaskStatus = 0
		tParam.nProgressNum = 0
		tParam.bIsRewarded = false
		oRole.m_oTaskSystem:MarkDirty(true)
		oRole.m_oTaskSystem:SendAllTaskInfo()
	end
end


--法宝系统
CGMMgr['addFaBao'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	print("法宝系统----")
	if not oRole then return end
	if tonumber(tArgs[1]) == 1 then
		local nFaBaoID =tonumber(tArgs[2])
		oRole.m_oFaBao:AddFaBao(nFaBaoID)
	elseif tonumber(tArgs[1]) == 2 then
		oRole.m_oFaBao:OutFaBaoInfo()
		oRole.m_oFaBao:SyncKnapsackItems()
	elseif tonumber(tArgs[1]) == 3 then
		oRole.m_oFaBao:ClearFaBaoMap()
	elseif tonumber(tArgs[1]) == 4 then
		oRole.m_oFaBao:FaBaoFeastReq(tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 5 then
		oRole.m_oFaBao:FaBaoWearReq(tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 6 then
		print("oRole.m_oFaBao.m_oFaBaoWerMap", oRole.m_oFaBao.m_oFaBaoWerMap)
	elseif tonumber(tArgs[1]) == 7 then
		oRole.m_oFaBao:FaBaoAttrPageReq()
	elseif tonumber(tArgs[1]) == 8 then
		local t = {}
		t[1] = 1
		t[2] = 2
		oRole.m_oFaBao:FaBaoResetReq(t)
	elseif tonumber(tArgs[1]) == 9 then
		local t = {1,2,3,4,5}
		oRole.m_oFaBao:FaBaoCompositeReq(t)
	end
end

CGMMgr['clearfabao'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFaBao:ClearFaBaoMap()
end
--妖兽突袭
CGMMgr['YaoShou'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if tonumber(tArgs[1]) == 1 then
		oRole.m_oYaoShouTuXi:SendYaoShouInfo()
	elseif tonumber(tArgs[1]) == 2 then
		local nYaoShouID = tonumber(tArgs[2])
		oRole.m_oYaoShouTuXi:yaoshouAttacReq(nYaoShouID)
	elseif tonumber(tArgs[1]) == 3 then
		oRole.m_oYaoShouTuXi:ClearYaoShouData()
	elseif tonumber(tArgs[1]) == 4 then
	
	end
end

--宠物系统
CGMMgr['addPetObj'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPetId =tonumber(tArgs[1])
	print("nPetId----", nPetId)
	oRole.m_oPet:AddPetObj(nPetId, 1)
end


CGMMgr['pet'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPetId = tArgs[1] or 0
	if tonumber(tArgs[1]) == 2 then
		oRole.m_oPet:PetXiSuiSavaReq()
	elseif tonumber(tArgs[1]) == 3 then
		local nPropID = 17001
		local nPetPos = 1
		oRole.m_oPet:FastLearnSkill(nPropID, nPetPos)
	elseif tonumber(tArgs[1]) == 4 then
		local nPetId = tonumber(tArgs[2])
		local nPetNum = 1
		oRole.m_oPet:PetBuyReq(nPetId)
	elseif tonumber(tArgs[1]) == 5 then
		oRole.m_oPet:AddGUReq(111,1)
	elseif tonumber(tArgs[1]) == 6 then
		oRole.m_oPet:AddLifeReq(1,1,21061)
	elseif tonumber(tArgs[1]) == 7 then
		--穿装备
		local nGrid = tonumber(tArgs[2])
		local nPos = tonumber(tArgs[3])
		oRole.m_oPet:WearEquitReq(nGrid, nPos)
	elseif tonumber(tArgs[1]) == 8 then
		local nZGrid = tonumber(tArgs[2])
		local nFGrid = tonumber(tArgs[3])
		oRole.m_oPet:PetEquitCptReq(nZGrid, nFGrid)
	elseif tonumber(tArgs[1]) == 9 then
		oRole.m_oKnapsack:PropDetailReq(tonumber(tArgs[2]), tonumber(tArgs[3]))
	elseif tonumber(tArgs[1]) == 10 then
		oRole.m_oPet:AddLifeReq(111,1, tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 11 then

	end
end

--自动加点
CGMMgr['autoaddpoint'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPetId = tArgs[1] or 0
	local nstate = tonumber(tArgs[1])
	local tlist = {2,2,2,0,0}
	local nPos = tonumber(tArgs[2])
	oRole.m_oPet:PetAutoAddPointReq(nstate, nPos, tlist)
end

--八荒火阵
CGMMgr['bahuang'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if tonumber(tArgs[1]) == 1 then
		local nBoxID = tonumber(tArgs[2])
		--宝箱求助
		oRole.m_oBaHuangHuoZhen:BoxHelpReq(nBoxID)
	elseif tonumber(tArgs[1]) == 2 then
		oRole.m_oBaHuangHuoZhen:SendBoxHelp(tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 3 then
		--帮助装箱
		oRole.m_oBaHuangHuoZhen:HelpPackingBoxReq(tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 4 then
		--自动生成箱子
		oRole.m_oBaHuangHuoZhen:TaskCompleteHandle()
	elseif tonumber(tArgs[1]) == 5 then
		--获取箱子列表''
		oRole.m_oBaHuangHuoZhen:BoxListReq()
	elseif tonumber(tArgs[1]) == 6 then
		--接取任务
		oRole.m_oBaHuangHuoZhen:PickupTaskReq()
	elseif tonumber(tArgs[1]) == 7 then
		--装箱请求
		oRole.m_oBaHuangHuoZhen:PackingReq(tonumber(tArgs[2]))
	elseif tonumber(tArgs[1]) == 8 then
		--领取奖励
		oRole.m_oBaHuangHuoZhen:ReceiveReq()

	elseif tonumber(tArgs[1]) == 9 then
		--请求任务信息
		oRole.m_oBaHuangHuoZhen:TaskInfoReq()
	elseif tonumber(tArgs[1]) == 10 then
		oRole.m_oBaHuangHuoZhen:ResettAct()
	elseif tonumber(tArgs[1]) == 11 then
		oRole.m_oBaHuangHuoZhen:TestAddItem()
	end
end

CGMMgr['updatebagReset'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oUpgradeBag:UpgradeReset()
end


CGMMgr['addCiShu'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPetId = tArgs[1] or 0
	oRole.m_oPet:AddCiShu()
end

CGMMgr['clearPetMap'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPet:ClearPetMap()
end


CGMMgr['addExp'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPos = tonumber(tArgs[1])
	local nValue = tonumber(tArgs[2])
	assert(nPos and nValue, "参数错误")
	oRole.m_oPet:AddExp(nValue)
end

CGMMgr['addLife'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPos = tonumber(tArgs[1])
	local nValue = tonumber(tArgs[2])
	oRole.m_oPet:AddLife(nPos, nValue)
end
CGMMgr['addSpeed'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPos = tonumber(tArgs[1])
	local nValue = tonumber(tArgs[2])
	oRole.m_oPet:AddSpeed(nPos, nValue)
end
CGMMgr['deletePet'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPos = tonumber(tArgs[1])
	oRole.m_oPet:DeletePet(nPos)
end

--神器
CGMMgr['Artifact'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nValue = tonumber(tArgs[1])
	if nValue == 1 then
		oRole.m_oArtifact:ArtifactListReq()
	elseif nValue == 2 then
		oRole.m_oArtifact:ArtifactAddExpReq(tonumber(tArgs[2]), tonumber(tArgs[3]))
	elseif nValue == 3 then
		oRole.m_oArtifact:ArtifactAscendingStarReq(tonumber(tArgs[2]))
	elseif nValue == 4 then
		oRole.m_oArtifact:ArtifactUpgradeReq(tonumber(tArgs[2]))
	elseif nValue == 5 then
		oRole.m_oArtifact:ArtifactCallUseShapeReq(tonumber(tArgs[2]))
	elseif nValue == 6 then
		print("神器使用了啊-----------------")
		oRole.m_oArtifact:USEArtivaion(tonumber(tArgs[2]), tonumber(tArgs[3]))
	elseif nValue == 7 then
		oRole.m_oArtifact:Cmd()
	end
end 

--师门任务
CGMMgr['shimen'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local tData = {}
	tData.nOperaType = tonumber(tArgs[1])
	tData.nNpcID = tonumber(tArgs[2])
	tData.nItemID = tonumber(tArgs[3])
	tData.nGatherStatus = tonumber(tArgs[4])

	local oNpc = goNpcMgr:GetNpc(tData.nNpcID)
	if not oNpc then
        return oRole:Tips("NPC不存在")
	end
	oNpc:Trigger(oRole, CNpcTalk.tNpcType.eShiMenTask, tData)
end

--系统商城
CGMMgr['OutMallInfo'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	print("888888888888888888")
	-- local oSubShop = goMallMar:GetSubShop(101)
	-- oSubShop:FastBuyListReq(1102)
	-- print("goMallMar---->", goMallMar)
	-- print("goMailMgr----->", goMailMgr)
	--goMallMar:OutMallInfo()
end

--测试生活技能
CGMMgr['life'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	print("邮件附体了-----------------", goMailMgr)
	if not oRole then return end
	if tonumber(tArgs[1]) == 1 then
		oRole.m_oAssistedSkill:OutSkillInfo()
	elseif tonumber(tArgs[1]) == 2 then
	oRole.m_oAssistedSkill:ListReq()
	elseif tonumber(tArgs[1]) == 3 then
		oRole.m_oAssistedSkill:UpgradeReq(2004)
	elseif tonumber(tArgs[1]) == 4 then
		oRole.m_oAssistedSkill:UpgradeReq(1117)
	elseif tonumber(tArgs[1]) == 5 then
		oRole.m_oAssistedSkill:SkillManufactureItem(2001,24001)
	elseif tonumber(tArgs[1]) == 6 then
		oRole.m_oAssistedSkill:SkillManufactureItem(2004)
	elseif tonumber(tArgs[1]) == 7 then
		--活力兑换界面
		oRole.m_oAssistedSkill:VitalityPagReq()
	elseif tonumber(tArgs[1]) == 8 then
		--活力制造
		oRole.m_oAssistedSkill:VitalityMakeReq(tonumber(tArgs[2]),  tonumber(tArgs[3]))
	elseif tonumber(tArgs[1]) == 9 then
		oRole.m_oAssistedSkill:AddVitalityReq()
	end
end

--日程
CGMMgr['daily'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local tData = {}
	tData.nOperaType = tonumber(tArgs[1])
	tData.nParam1 = tonumber(tArgs[2])

	if tData.nOperaType == 5 then
		oRole.m_oDailyActivity:ResetData()
		local nDayIndex = os.WDay(os.time())		
		oRole.m_oDailyActivity:SendAllInfo(nDayIndex)
	elseif tData.nOperaType == 1 then 		--开启可参加活动
		oRole.m_oDailyActivity:SetRecordData(tData.nParam1, gtDailyData.ebCanJoin, true)
	elseif tData.nOperaType == 2 then
		oRole.m_oDailyActivity:GetShareGameRewardReq()
	elseif tData.nOperaType == 3 then
		oRole.m_oDailyActivity:ShareGameRewardStatusReq()
	end
	--oRole.m_oDailyActivity:Operation(tData)
end

--镇妖
CGMMgr['zhenyao'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local tData = {}
	tData.nOperaType = tonumber(tArgs[1])

	if tData.nOperaType == 1 then		--创建怪物
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:CreateMonsterReq(oRole)
		
	elseif tData.nOperaType == 2 then	--攻击怪物
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		local nMonsterID = next(oBattleDup.m_tMonsterMap)
		oBattleDup:AttackMonsterReq(oRole, nMonsterID)

	elseif tData.nOperaType == 3 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:ExpBuffOpera(oRole, 1)

	elseif tData.nOperaType == 4 then
		CZhenYao:EnterBattleDupReq(oRole)

	elseif tData.nOperaType == 5 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:BecomeLeaderReq(oRole)

	elseif tData.nOperaType == 6 then
		goFBTransitScene:EnterFBTransitScene(oRole)
	elseif tData.nOperaType == 7 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:BecomeLeaderReq(oRole)
	end
end

--乱世妖魔
CGMMgr['luanshi'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local tData = {}
	tData.nOperaType = tonumber(tArgs[1])

	if tData.nOperaType == 1 then		--点击怪物
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		local nMonsterID = next(oBattleDup.m_tMonsterMap)
		oBattleDup:TouchMonsterReq(oRole, nMonsterID)
	end
end

--心魔侵蚀
CGMMgr['xinmo'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local tData = {}
	tData.nOperaType = tonumber(tArgs[1])

	if tData.nOperaType == 1 then		--点击怪物
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		local nMonsterID = next(oBattleDup.m_tMonsterMap)
		oBattleDup:TouchMonsterReq(oRole, nMonsterID)
	end
end

--清理背包
CGMMgr["clrpack"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:GMClrKnapsack()
end

--挂机
CGMMgr["guaji"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nOpera = tonumber(tArgs[1])
	local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())	
	if nOpera == 1 then 					--进入挂机场景
		goBattleDupMgr:EnterBattleDupReq(oRole, gtBattleDupType.eGuaJi)
	elseif nOpera == 2 then				--离开关机场景
		goBattleDupMgr:LeaveBattleDupReq(oRole)
	elseif nOpera == 3 then    --动画结束
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
	    if oBattleDup and oBattleDup.GuaJiBattleEndNoticeReq then
	        oBattleDup:GuaJiBattleEndNoticeReq(oRole)
	    end
    elseif nOpera == 4 then    --挑战boss
	    if oBattleDup and oBattleDup.ChallengeBoss then
	        oBattleDup:ChallengeBoss(oRole)
		end
	elseif nOpera == 5 then    --选择自动战斗
	    if oBattleDup and oBattleDup.SetAutoBattle then
	        oBattleDup:SetAutoBattle(oRole, true)
		end
	elseif nOpera == 6 then
		if oBattleDup and oBattleDup.StartNoticReq then
	        oBattleDup:StartNoticReq(oRole)
		end
	end
end

--挂机关卡设置
CGMMgr["guajilevel"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nSeq = math.floor(tonumber(tArgs[1]) or 1)
	if nSeq <= 0 then 
		oRole:Tips("关卡参数错误")
		return
	end
	if oRole:IsInBattle() then 
		oRole:Tips("战斗中，无法设置挂机关卡")
		return 
	end
	if not ctGuaJiConf:GetGuanQiaConf(nSeq) then 
		oRole:Tips("关卡参数错误")
		return
	end
	oRole.m_oGuaJi:SetTargetGuanQia(nSeq, 0)
	oRole.m_oGuaJi:SendGuanQiaInfo()
	local sContent = string.format("已设置挂机关卡为 %d", nSeq)
	oRole:Tips(sContent)
end

--清理无效战斗
CGMMgr["cleardeadbattle"] = function(self, nServer, nService, nSession, tArgs)
	goBattleMgr:ClearBattle()
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if oRole then oRole:Tips("清理无效战斗成功") end
end

--神兽乐园
CGMMgr["shenshou"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	--local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
	local nOpera = tonumber(tArgs[1])
	local nChalType = tonumber(tArgs[2])
	if nOpera == 1 then	--产生NPC怪物
		oBattleDup:CreateMonsterReq(oRole)

	elseif nOpera == 2 then	--触碰NPC怪物
		local nMonsterID = next(oBattleDup.m_tMonsterMap)
		oBattleDup:TouchMonsterReq(oRole, nMonsterID)

	elseif nOpera == 3 then	--请求进入神兽乐园
		CShenShouLeYuan:EnterBattleDupReq(oRole)

	elseif nOpera == 4 then
		local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
		if not oRole then return end
		goBattleDupMgr:LeaveBattleDupReq(oRole)

	elseif nOpera == 5 then
		oRole.m_oShenShouLeYuanModule:Opera(nChalType)
	end
end

--PVP活动开启
CGMMgr["pvpactivityrestart"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nActivityID = tonumber(tArgs[1])
	if not nActivityID then
		oRole:Tips("参数不正确!请检查活动ID")
		return
	end
	local bExist = false
	for k, v in pairs(ctPVPActivityConf) do
		if k == nActivityID then
			bExist = true
			break
		end
	end
	if not bExist then
		oRole:Tips("PVP活动ID不正确")
		return
	end
	local nPrepareLastTime = tonumber(tArgs[2]) --准备时长
	local nLastTime = tonumber(tArgs[3]) --活动持续时间，单位分钟

	local fnRestartCallback = function (bRet, sReason)
		if not bRet then
			if sReason then
				oRole:Tips(sReason)
			end
			return 
		end
		oRole:Tips("活动开启成功")
	end

	local nTarServiceID = goPVPActivityMgr:GetActivityServiceID(nActivityID)
	if CUtil:GetServiceID() == nTarServiceID then
		local bRet, sReason = goPVPActivityMgr:GMRestart(nActivityID, nPrepareLastTime, nLastTime)
		fnRestartCallback(bRet, sReason)
	else
		Network.oRemoteCall:CallWait("PVPActivityGMRestart", fnRestartCallback, nServer, nTarServiceID, 0, nActivityID, nPrepareLastTime, nLastTime)
	end
end

--重新计算角色属性
CGMMgr["calcroleattr"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole:UpdateAttr()
end

--时装
CGMMgr["shizhuang"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nOpera = tonumber(tArgs[1])
	local nPosType = tonumber(tArgs[2])
	local nShiZhuangID = tonumber(tArgs[3])
	if nOpera == 1 then		--穿戴时装
		oRole.m_oShiZhuang:PutOnReq(nPosType, nShiZhuangID)
	elseif nOpera == 2 then	--卸下时装
		oRole.m_oShiZhuang:PutOff(nPosType)
	elseif nOpera == 3 then	--时装洗练
		oRole.m_oShiZhuang:WashReq(nShiZhuangID, false)
	elseif nOpera == 4 then --洗练属性替换
		oRole.m_oShiZhuang:AttrReplaceReq(nShiZhuangID)
	elseif nOpera == 5 then --器灵升阶
		oRole.m_oShiZhuang:QiLingUpGrade()
	elseif nOpera == 6 then --时装所有信息
		oRole.m_oShiZhuang:AllInfoReq()
	elseif nOpera == 7 then --器灵所有信息
		oRole.m_oShiZhuang:QiLingInfoReq()
	elseif nOpera == 8 then --设置器灵升级品阶
		oRole.m_oShiZhuang.m_nQiLingLevel = nPosType
		oRole.m_oShiZhuang.m_nQiLingGrade = nShiZhuangID
		oRole.m_oShiZhuang:MarkDirty(true)
	elseif nOpera == 9 then	--激活时装
		oRole.m_oShiZhuang:ShiZhuangActReq(nShiZhuangID)
	end
end

--天帝宝物
CGMMgr["goldbox"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nOpera = tonumber(tArgs[1])
	local nParam1 = tonumber(tArgs[2])
	local oNpc = goNpcMgr:GetNpc(5201)
	if not oNpc then
        return oRole:Tips("NPC不存在")
	end

	if nOpera == 1 then	--打开宝箱
		oNpc:OpenGoldBox(oRole, nParam1, true)
	elseif nOpera == 2 then	--福缘兑换

		oNpc:FuYuanExchangeReq(oRole, nParam1)
	elseif nOpera == 3 then	--添加福缘值
		oRole:AddFuYuan(nParam1)
	end
end

--宝图任务
CGMMgr["baotu"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nOpera = tonumber(tArgs[1])

	if nOpera == 1 then		--挖宝坐标请求
		oRole.m_oBaoTu:WaBaoPosReq(1)
	elseif nOpera == 2 then		--挖宝开始
		oRole.m_oBaoTu:WaBaoStatus(1, 1)
	elseif nOpera == 3 then		--挖宝结束
		oRole.m_oBaoTu:WaBaoStatus(1, 2)
	elseif nOpera == 4 then		--宝图合成
		oRole.m_oBaoTu:MapCompReq(false)
	elseif nOpera == 5 then		--所有信息
		oRole.m_oBaoTu:SendBaoTuPosList()
	end
end

CGMMgr["addarenacoin"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nAddCoin = tonumber(tArgs[1])
	if not nAddCoin then
		oRole:Tips("参数不正确，请附带要添加的竞技币数量")
		return
	end
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eArenaCoin, nAddCoin, "GM添加")
end

CGMMgr["partnerstonecollect"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nCollectPropID = tonumber(tArgs[1])
	local nGrid = tonumber(tArgs[2])
	local nCount = tonumber(tArgs[3])
	local bMax = tonumber(tArgs[4]) and true or false
	if not nCollectPropID or not nGrid or not nCount then
		oRole:Tips("参数错误，(灵石ID)(采集格子)(采集次数)(是否最大)")
		return
	end
	oRole.m_oPartner:CollectPartnerStone(nCollectPropID, nGrid, nCount, bMax)
end

CGMMgr["shangjin"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nOpera = tonumber(tArgs[1])
	local nParam1 = tonumber(tArgs[2])

	if nOpera == 1 then				--所有信息
		oRole.m_oShangJinTask:AllTaskReq()
	elseif nOpera == 2 then			--刷新任务
		oRole.m_oShangJinTask:TaskRefreshReq(true)
	elseif nOpera == 3 then			--接取任务
		oRole.m_oShangJinTask:TaskAccepReq(nParam1)
	elseif nOpera == 4 then			--请求攻击
		oRole.m_oShangJinTask:ShangJinAttReq()	
	elseif nOpera == 5 then			--清空任务数据
		for nTaskID, _ in pairs(oRole.m_oShangJinTask.m_tTaskList) do
			oRole.m_oShangJinTask.m_tTaskList[nTaskID] = nil
		end
		oRole.m_oShangJinTask.m_nCurrTaskID = 0
		oRole.m_oShangJinTask.m_nCompTimes = 0
		oRole.m_oShangJinTask.m_nLastResetTimeStamp = os.time()
		local tTaskList = oRole.m_oShangJinTask:CalTask()
		oRole.m_oShangJinTask:ClearTask()
		oRole.m_oShangJinTask:SetTaskList(tTaskList)
		oRole.m_oShangJinTask:SendShangJinAllInfo()
		oRole.m_oShangJinTask:MarkDirty(true)

	elseif nOpera == 6 then			--当前接受任务
		oRole.m_oShangJinTask:SendShangJinTask()
	elseif nOpera == 7 then			--元宝完成
		oRole.m_oShangJinTask:UseYuanBaoComp(nParam1)
	end
end

--成就系统
CGMMgr['achieve'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	
	local nOperaType = tonumber(tArgs[1]) or 0
	if nOperaType == 1 then
		oRole.m_oAchieve:PushAchieve("累计登录天数",{nValue = 1})
	elseif nOperaType == 2 then
		oRole.m_oAchieve:GetAchieveRewardReq(1)
	elseif nOperaType == 3 then
		oRole.m_oAchieve:GetAchieveRewardReq(2)
	elseif nOperaType == 4 then
		oRole.m_oAchieve:GetAchieveRewardReq(3)
	elseif nOperaType == 5 then
		local nID = oRole:GetID()
		local sData = goDBMgr:GetSSDB(nServer, "user", nID):HGet("Achieve", nID)
		oRole.m_oAchieve:MarkDirty(true)
		print("database achieve data",sData)
		print("now achieve data",oRole.m_oAchieve:SaveData())
	end
end

--试炼任务
CGMMgr['shilian'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	
	local nOperaType = tonumber(tArgs[1])
	local nNpcID = tonumber(tArgs[2])
	local nItemID = tonumber(tArgs[3])
	local nNum = tonumber(tArgs[4])		
	if nOperaType == 1 then
		oRole.m_oShiLianTask:TaskAccepReq()
	elseif nOperaType == 2 then
		oRole.m_oShiLianTask:TaskCommitReq(nNpcID, nItemID, nNum, nil, true)
	elseif nOperaType == 3 then		--设置完成次数
		oRole.m_oShiLianTask.m_nCompTimes = nNum
		oRole.m_oShiLianTask:MarkDirty(true)
		oRole.m_oShiLianTask:SendTaskInfo()
	end
end

--神魔志
CGMMgr['smz'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nOperaType = tonumber(tArgs[1]) or 0
	if nOperaType == 1 then
		local tData = {
			nType = 1,
			nChapter = 1,
		}
		oRole.m_oShenMoZhiData:OpenShenMoZhiReq(tData)
	elseif nOperaType == 2 then
	    local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
	    if not oBattleDup then return end
	    local nGuanQiaID = tonumber(tArgs[2]) or 0
		oBattleDup:ChallengeStart(oRole,nGuanQiaID)
	elseif nOperaType == 3 then
		local tData = {
			nType = 1,
			nChapter = 1,
			nStar = tonumber(tArgs[2] or 0),
		}
		oRole.m_oShenMoZhiData:ShenMoZhiStarRewardReq(tData)
	elseif nOperaType == 4 then
		local nID = oRole:GetID()
		local sData = goDBMgr:GetSSDB(nServer, "user", nID):HGet("ShenMoZhi", nID)
		oRole.m_oShenMoZhiData:MarkDirty(true)
		print("shenmozhi data",sData)
		print("now shenmozhi data",oRole.m_oShenMoZhiData:SaveData())
	elseif nOperaType == 5 then
		local nID = oRole:GetID()
		local sData = goDBMgr:GetSSDB(nServer, "user", nID):HGet("TimeData", nID)
		oRole.m_oTimeData:MarkDirty(true)
		print("time data",sData)
		print("now time data",oRole.m_oShenMoZhiData:SaveData())
	elseif nOperaType == 10 then
		CShenMoZhi:EnterBattleDupReq(oRole)
	elseif nOperaType == 11 then
		local nButtleID = oRole:GetBattleID()
		local oButtle = goBattleMgr:GetBattle(nButtleID)
		if oButtle then
			oButtle:SetBattleEnd(1)
			oButtle:BattleResult()
		end
	end
end

--科舉
CGMMgr['keju'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	
	local nOperaType = tonumber(tArgs[1]) or 0
	local nKejuType = 1
	if nOperaType == 1 then
		if #tArgs > 1 then
			nKejuType = tonumber(tArgs[2]) or 0
		end
		oRole.m_oKeju:OpenKeJu(nKejuType)
	elseif nOperaType == 2 then
		oRole.m_oKeju:CloseKeJu(nKejuType)
	elseif nOperaType == 3 then
		local nQuestion = tonumber(tArgs[2] or 0)
		local nAnswerID = tonumber(tArgs[3] or 0)
		oRole.m_oKeju:AnswerQuestion(nQuestion,nAnswerID)
	elseif nOperaType == 4 then
	elseif nOperaType == 5 then
		local nID = oRole:GetID()
		local sData = goDBMgr:GetSSDB(nServer, "user", nID):HGet("TimeData", nID)
		oRole.m_oTimeData:MarkDirty(true)
		print("time data",sData)
		print("now time data",oRole.m_oShenMoZhiData:SaveData())
	elseif nOperaType == 6 then
		oRole.m_oTimeData.m_oToday:ClearData()
	elseif nOperaType == 7 then
		local fnCallback = function (tData)
			print("hcdebug-------------------------",tData)
		end
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		Network.oRemoteCall:CallWait("KejuRankingReq", fnCallback, nServerID, nServiceID, 0,oRole:GetID(),100)
	elseif nOperaType == 11 then
		local nQuestionID = tonumber(tArgs[2] or 0)
		oRole.m_oKeju:KejuAskHelp(nQuestionID)
	elseif nOperaType == 12 then
		local nAskerID = 10062
		local nQuestionID = tonumber(tArgs[2] or 0)
		local nAnswerID = tonumber(tArgs[3] or 0)

		local nHelpRoleID = oRole:GetID()
		local sRoleName = oRole:GetName()
		oRole.m_oKeju:KejuAnswerHelpQuestion(nAskerID,oRole:GetName(),nQuestionID,nAnswerID)
	elseif nOperaType == 13 then
		local nQuestionID = tonumber(tArgs[2] or 0)
		oRole.m_oKeju:KejuAskHelpData(nQuestionID)
	elseif nOperaType == 20 then
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		Network.oRemoteCall:Call("KejuRankingTest", nServerID, nServiceID, 0,1,oRole:GetID())
	elseif nOperaType == 21 then
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		Network.oRemoteCall:Call("KejuRankingTest", nServerID, nServiceID, 0,1,oRole:GetID())
	elseif nOperaType == 22 then
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		Network.oRemoteCall:Call("KejuRankingTest", nServerID, nServiceID, 0,2,oRole:GetID())
	elseif nOperaType == 23 then
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		Network.oRemoteCall:Call("KejuRankingTest", nServerID, nServiceID, 0,3,oRole:GetID())
	elseif nOperaType == 24 then
		local tData = {
			nRoleID = oRole:GetID(),
			nQuestionID = 1, 
		}
		local nTarRoleID = tData.nRoleID
		local nQuestionID = tData.nQuestionID
		local oTargetRole = goPlayerMgr:GetRoleByID(nTarRoleID)
		if not oTargetRole then return end
		oTargetRole.m_oKeju:KejuHelpQuestionDataReq(oRole,nQuestionID)
	elseif nOperaType == 100 then
		if #tArgs < 2 then
			return
		end
		local nQuestionID = tonumber(tArgs[2]) or 1
		oRole.m_oKeju:GMOpenKeJu(nQuestionID)
	end
end

--只能进入主场景
CGMMgr["scene"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nSceneID = tonumber(tArgs[1])
	if not nSceneID then 
		return oRole:Tips("请输入正确的场景ID")
	end
	local tConf = ctDupConf[nSceneID]
	if not tConf then 
		return oRole:Tips("场景配置不存在，请检查场景ID")
	end
	oRole:EnterScene(nSceneID, tConf.tBorn[1][1], tConf.tBorn[1][2], 0, 1)
end

--进入最后主城
CGMMgr["lastcity"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole:EnterLastCity()
end

--增加基金进度(购买了的基金才会增加)
CGMMgr['fundprogress'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nNewLevel = tonumber(tArgs[1])
	oRole.m_oFund:OnRoleLevelChange(nNewLevel)
end

--重置基金
CGMMgr['resetfund'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nType = tonumber(tArgs[1]) or 1
	oRole.m_oFund:GMResetFund(nType)
end

--生成找回奖励
CGMMgr['addfindaward'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nDays = tonumber(tArgs[1]) or 1	--天数
	oRole.m_oFindAward:GMAddFindTimes(nDays)
end

--找回奖励刷新
CGMMgr['find'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oFindAward:ZeroUpdate()
end
--微端下载测试
CGMMgr['wddown'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oWDDownload:OnWDDownloaded()
	oRole:Tips("操作成功")
end
--微端下载重置
CGMMgr['wdreset'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oWDDownload:GMReset()
end

--双倍点
CGMMgr['shuangbei'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	
	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then						--双倍点信心
		oRole.m_oShuangBei:GMPrintShuangBei()
	elseif nOperaType == 2 then					--领取双倍点(用于消耗)
		oRole.m_oShuangBei:UseShuangbei()
		oRole.m_oShuangBei:GMPrintShuangBei()
	elseif nOperaType == 3 then					--冻结双倍点(储存)
		oRole.m_oShuangBei:UnuseShuangbei()		
		oRole.m_oShuangBei:GMPrintShuangBei()
	end
end

--测试用，清理当前背包所有道具 --从装备上自动取下的宝石，仍然会被保留
CGMMgr['cleanbag'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local tRemovedList = {}
	for k, v in pairs(oRole.m_oKnapsack.m_tGridMap) do 
		table.insert(tRemovedList, v)
	end
	for k, v in ipairs(tRemovedList) do
		oRole.m_oKnapsack:SubGridItem(v:GetGrid(), v:GetID(), v:GetNum(), "GM清理背包")
	end
end

--进入副本中转场景
CGMMgr['fbtransit'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then
		goFBTransitScene:EnterFBTransitScene(oRole)		
	elseif nOperaType == 2 then
		goBattleDupMgr:LeaveBattleDupReq(oRole)
		--oRole:EnterLastCity()
	end
end

CGMMgr['drawspirit'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	-- if not oRole.m_oDrawSpirit:IsSysOpen() then 
	-- 	oRole.m_oSysOpen.m_tOpenSysMap[55] = gtSysOpenFlag.eOpen
	-- 	oRole.m_oSysOpen:MarkDirty(true)
	-- 	oRole.m_oDrawSpirit:OnSysOpen()
	-- end
	-- oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, 100000, "GM测试")
	-- oRole:AddItem(gtItemType.eCurr, gtCurrType.eDrawSpirit, 1000000, "GM测试")
	-- oRole:AddItem(gtItemType.eCurr, gtCurrType.eMagicPill, 1000000, "GM测试")
	-- oRole:AddItem(gtItemType.eCurr, gtCurrType.eEvilCrystal, 1000000, "GM测试")
	-- oRole.m_oDrawSpirit:SyncDrawSpiritData()
	-- oRole.m_oDrawSpirit:SyncSpiritNum()
	-- oRole.m_oDrawSpirit:SyncTriggerLevel()
	-- for k = 1, 10 do 
	-- 	oRole.m_oDrawSpirit:LevelUpReq()
	-- end
	-- local nCount = 0
	-- GetGModule("TimerMgr"):Interval(1, 
	-- 	function(nTimerID)
	-- 		nCount = nCount + 1
	-- 		if nCount >= 30 then 
	-- 			GetGModule("TimerMgr"):Clear(nTimerID)
	-- 		end
	-- 		for k = 1, 5 do 
	-- 			oRole.m_oDrawSpirit:SetTriggerLevelReq(40)
	-- 			oRole.m_oDrawSpirit:BattleTrigger()
	-- 		end
	-- 	end
	-- )
	oRole.m_oDrawSpirit:SetTriggerLevelReq(40)
	oRole.m_oDrawSpirit:BattleTrigger()
end

--目标任务
CGMMgr['targettask'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local nOperaType = tonumber(tArgs[1])
	local nTaskID = tonumber(tArgs[2])
	if nOperaType == 1 then
		oRole.m_oTargetTask:SendTargetTaskInfo(false)
	elseif nOperaType == 2 then
		oRole.m_oTargetTask:GetReward()
	elseif nOperaType == 3 then
		for i=1, 50 do
			if oRole:GetLevel() < 25 then
				oRole:AddItem(1, 7, 1000000, "gm命令")
			else
				break
			end
		end
		oRole:MarkDirty(true)
		oRole.m_oTargetTask:SetNextTask(nTaskID)
		oRole.m_oSysOpen:OnTargetTaskCommit()
	elseif nOperaType == 4 then
		oRole.m_oTargetTask:BattleTrainReq()
	end
end

CGMMgr["joinpvp"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nActivityID = gtDailyID.eUnionArena
	if #tArgs > 0 then
		nActivityID = tonumber(tArgs[1])
	end
	goPVPActivityMgr:EnterReq(oRole,gtDailyID.eUnionArena)
end

CGMMgr["testman"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if #tArgs < 0 then
		oRole:Tips("参数错误")
		return
	end
	local nTestMan = tonumber(tArgs[1] or 0)
	oRole:SetTestMan(nTestMan)
	oRole:GlobalRoleUpdate({m_nTestMan = nTestMan})
end

--节日活动
CGMMgr["holidayact"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then
		oRole.m_oHolidayActMgr:SendAllActInfo()
	end
end

--学富五车
CGMMgr["xuefuwuche"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oAnswer = oRole.m_oHolidayActMgr.m_tActObjList[801]
	if not oAnswer then return end
	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then
		oAnswer:SendActAllInfo()
	end
end

--江湖历练
CGMMgr["experience"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oExperience = oRole.m_oHolidayActMgr.m_tActObjList[802]
	if not oExperience then return end
	local nOperaType = tonumber(tArgs[1])
	local nparam1 = tonumber(tArgs[2])
	local nparam2 = tonumber(tArgs[3])	
	if nOperaType == 1 then			--查看信息
		oExperience:SendTaskInfo()
	elseif nOperaType == 2 then
		oExperience:AcceptTaskReq()
	elseif nOperaType == 3 then
		oExperience:CommitTaskReq(nparam1, nparam2)
	end
end

--尊师考验
CGMMgr["teachtest"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oTeachTest = oRole.m_oHolidayActMgr.m_tActObjList[803]
	if not oTeachTest then return end
	local nOperaType = tonumber(tArgs[1])
	local nparam1 = tonumber(tArgs[2])
	local nparam2 = tonumber(tArgs[3])	
	if nOperaType == 1 then			--查看信息
		oTeachTest:JoinTeachTestReq()
	elseif nOperaType == 2 then
		local oBattleDup = goBattleDupMgr:GetBattleDup(oRole:GetBattleDupID())
		oBattleDup:AttackMonsterReq(oRole, nparam1)
	end
end

CGMMgr["palanquin"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goMarriageSceneMgr:PalanquinRentReq(oRole)
end

CGMMgr["dumpscene"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oDup = oRole:GetCurrDupObj()
	oDup:DumpSceneObjInfo()
end

CGMMgr["adduniongift"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if not oRole:GetUnionID() then
		return
	end
	if #tArgs<1 then
		oRole:Tips("参数错误")
		return
	end
	local nType = 1
	local nCnt = tonumber(tArgs[1] or 0)
	local nUnionID = oRole:GetUnionID()
	local nServerID = oRole:GetServer()
	local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
	Network.oRemoteCall:Call("AddUnionGiftBoxCnt",nServerID,nServiceID,0,nUnionID,nType,nCnt)
end

--角色当前所在逻辑服
CGMMgr["currentlogic"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local tDupConf = oRole:GetDupConf()
	oRole:Tips("当前逻辑服 "..tDupConf.nLogic)
end

CGMMgr["addbaoshi"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nTimes = tonumber(tArgs[1]) or 0
	oRole.m_oRoleState:AddBaoShiTimes(nTimes)
	oRole:Tips("增加饱食度成功:"..nTimes)
end

CGMMgr["addbaoshi"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nTimes = tonumber(tArgs[1]) or 0
	oRole.m_oRoleState:AddBaoShiTimes(nTimes)
	oRole:Tips("增加饱食度成功:"..nTimes)
end

CGMMgr["openall"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oSysOpen:GMOpenAll()
end

CGMMgr["appellation"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nAppeConfID = tonumber(tArgs[1])
	if not nAppeConfID or nAppeConfID < 1 then 
		return oRole:Tips("请填写一个正确的称谓ID")
	end
	local tAppeConf = ctAppellationConf[nAppeConfID]
	if not tAppeConf then 
		return oRole:Tips("称谓配置不存在")
	end
	if tAppeConf.nType ~= 1 and tAppeConf.nType ~= 2 then 
		return oRole:Tips("该称谓不是一个普通称谓，无法通过GM命令添加")
	end
	local nID = oRole.m_oAppellation:GetAppellationObjID(nAppeConfID, 0)
    if nID then 
        return oRole:Tips("称谓已存在") 
    end
	oRole:AddItem(gtItemType.eAppellation, nAppeConfID, 1, "GM添加")
	oRole:Tips("称谓添加成功")
end

CGMMgr["quickwear"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack:QuickWearEquReq()
end

CGMMgr["splittest"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local tSrc = {100, 200, 300, 400, 500}
	local nTotalNum = 1999999999
	local nSplitNum = tonumber(tArgs[1])
	if not nSplitNum or nSplitNum < 1 then 
		oRole:Tips("请输入正确的分割粒度参数")
		return 
	end
	local fnGetWeight = function(tNode) return tNode end
	local nStartTime = os.clock()
	for k = 1, 20 do 
		print("------------ DEBUG BEGIN ------------")
		local tResult = CWeightRandom:WeightSplit(tSrc, fnGetWeight, nTotalNum, nSplitNum)
		print(tResult)
		local nSumCheck = 0
		for k, v in pairs(tResult) do 
			nSumCheck = nSumCheck + v
		end
		print("nSumCheck:", nSumCheck)
		print("------------ DEBUG END --------------")
	end
	local nEndTime = os.clock()
	print("总耗时:", math.ceil((nEndTime - nStartTime) * 1000)) 
end

CGMMgr["recruittipsclose"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oPartner:CloseRecruitTips()
end

--删除当前账号角色
CGMMgr["deleterole"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if oRole:IsInBattle() then 
		oRole:Tips("角色正在战斗中，请先退出战斗！")
		return 
	end
	local nRoleID = oRole:GetID()
	local fnConfirmCallback = function(tData)
		if tData.nSelIdx == 1 then  --取消
			return
		elseif tData.nSelIdx == 2 then  --确定
			oRole = goPlayerMgr:GetRoleByID(nRoleID)
			if not oRole then 
				return 
			end
			if oRole:IsInBattle() then --反之战斗回调数据，上报数据到登录服相关账号
				oRole:Tips("角色正在战斗中，请先退出战斗！")
				return 
			end
			-- oRole:Tips("开始删除角色")
			Network.oRemoteCall:Call("DeleteRoleReq", oRole:GetServer(), goServerMgr:GetLoginService(oRole:GetServer()), 
				oRole:GetSession(), oRole:GetAccountID(), oRole:GetID())
		end
	end

	local sCont = "是否确定删除角色？"
	local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=30}
	goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
end

CGMMgr["rbtree"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	_RBTreeTest()
end

CGMMgr["multirbtree"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if not gbInnerServer then 
		return 
	end
	_MultiRBTreeTest()
end

CGMMgr["skiplist"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if not gbInnerServer then 
		return 
	end
	_SkipListTest()
end

CGMMgr["rbrank"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if not gbInnerServer then 
		return 
	end
	_RBRankTest()
end

CGMMgr["willopen"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nOperaType = tonumber(tArgs[1])
	if nOperaType == 1 then			--查看当前信息
		oRole.m_oWillOpen:WillOpenInfoReq()
	elseif nOperaType == 2 then		--领取奖励
		oRole.m_oWillOpen:GetRewardReq()
	elseif nOperaType == 3 then
		
	end
end

CGMMgr["everydaygift"] = function (self,nServer,nService,nSession,tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nOperaType = tonumber(tArgs[1])
	local nMoney = tonumber(tArgs[2])
	if nOperaType == 1 then					--请求信息
		oRole.m_oEverydayGift:EverydayGiftInfoReq()
	elseif nOperaType == 2 then				--领取每日礼包
		oRole.m_oEverydayGift:GetEverydayGiftReq(nMoney)
	end
end

CGMMgr["proptips"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if not tArgs[1] then 
		return oRole:Tips("请输入道具ID")
	end
	local nPropID = tonumber(tArgs[1])
	if not nPropID then 
		return oRole:Tips("请输入道具ID")
	end
	if not ctPropConf[nPropID] then 
		return oRole:Tips("道具不存在") 
	end
	local sTips = ctPropConf:GetFormattedName(nPropID)
	oRole:Tips(string.format("测试%s提示", sTips))
end

CGMMgr["randdiff"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nMin = tonumber(tArgs[1])
	local nMax = tonumber(tArgs[2])
	local nNum = tonumber(tArgs[3])
	if not nMin or not nMax or not nNum or nNum < 1 then 
		oRole:Tips("输入数据错误")
		return 
	end
	if nMin > nMax or nMax - nMin < nNum - 1 then 
		oRole:Tips("输入数据错误")
		return 
	end
	print(">>>>>>>>> RandDiffNum <<<<<<<<<")
	print(string.format("nMin(%d), nMax(%d), nNum(%d)", nMin, nMax, nNum))
	local nBeginTime = os.clock()
	local tRandResult = CUtil:RandDiffNum(nMin, nMax, nNum)
	local nEndTime = os.clock()
	print(string.format("执行完毕, 耗时(%d)ms", math.ceil((nEndTime - nBeginTime)*1000)))

	print(tRandResult)
	local tCheckList = {}
	for k, nVal in ipairs(tRandResult) do 
		if tCheckList[nVal] then 
			print("数据错误，存在重复数据!!!!")
			oRole:Tips("随机结果错误！存在重复数据！")
			break
		else 
			tCheckList[nVal] = k
		end
	end
	print(">>>>>>>>>>>  END  <<<<<<<<<<<<")
end

CGMMgr["randdiffiterator"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nMin = tonumber(tArgs[1])
	local nMax = tonumber(tArgs[2])
	if not nMin or not nMax then 
		oRole:Tips("输入数据错误")
		return 
	end
	if nMin > nMax then 
		oRole:Tips("输入数据错误")
		return 
	end
	print(">>>>>>>>> RandDiffIterator <<<<<<<<<")
	print(string.format("nMin(%d), nMax(%d)", nMin, nMax))
	local nBeginTime = os.clock()
	local tRandResult = {}
	for nRandVal, tCacheList, tSwapList in CUtil:RandDiffIterator(nMin, nMax) do 
		table.insert(tRandResult, nRandVal)
	end
	local nEndTime = os.clock()
	print(string.format("执行完毕, 共随机(%d)个数据, 耗时(%d)ms", #tRandResult, 
		math.ceil((nEndTime - nBeginTime)*1000)))

	print(tRandResult)
	local tCheckList = {}
	for k, nVal in ipairs(tRandResult) do 
		if tCheckList[nVal] then 
			print("数据错误，存在重复数据!!!!")
			oRole:Tips("随机结果错误！存在重复数据！")
			break
		else 
			tCheckList[nVal] = k
		end
	end
	print(">>>>>>>>>>>  END  <<<<<<<<<<<<")
end

CGMMgr["matchhelper"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	_TestMatchHelper()
end

CGMMgr["rbmatch"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	_TestRBMatch()
end

CGMMgr["querypropprice"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nPropID = tonumber(tArgs[1])
	local nCurrType = tonumber(tArgs[2])
	if not nPropID or nPropID <= 0 or not nCurrType or nCurrType <= 0 then 
		oRole:Tips("请输入正确的查询数据")
		return 
	end
	if not ctPropConf[nPropID] then 
		oRole:Tips("道具ID错误")
		return
	end
	if not gtCurrName[nCurrType] then 
		oRole:Tips("货币类型错误")
		return
	end

	local tItemList = {}
	table.insert(tItemList, 
		{nItemType = gtItemType.eProp, nItemID = nPropID, nCurrType = nCurrType})

	local fnQueryCallback = function(bSucc, tPriceList) 
		if not bSucc then 
			print("查询价格失败")
		else
			print("查询价格成功")
			print(string.format("补足价格(%d) (%s)", tPriceList[1].nPrice, gtCurrName[nCurrType]))
		end
		print(">>>>>>>>>>>  END  <<<<<<<<<<<<")
	end

	print(">>>>>>>>> QueryPropPrice <<<<<<<<<")
	print(string.format("开始查询(%d)(%s)价格", nPropID, ctPropConf:PropName(nPropID)))
	oRole:QueryItemPrice(tItemList, true, fnQueryCallback)
end

CGMMgr["cleansaleyuanbao"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oKnapsack.m_nDailySaleYuanbaoNum = 0
	oRole:MarkDirty(true)
	oRole:Tips("清理数据成功")
end

CGMMgr["addmarriagesuit"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oRoleState:AddMarriageSuit()
	oRole.m_oRoleState:SyncState()
end

CGMMgr["addmarriagebless"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	-- local nTarRoleID = tonumber(tArgs[1])
	-- if not nTarRoleID or nTarRoleID <= 0 then 
	-- 	oRole:Tips("参数错误，请输入正确的角色ID")
	-- 	return 
	-- end
	-- local oTarRole = goPlayerMgr:GetRoleByID(nTarRoleID)
	-- if not oTarRole then 
	-- 	oRole:Tips("对方角色必须在线且位于同一逻辑服")
	-- 	return 
	-- end
	oRole.m_oRoleState:AddMarriageBless()
	-- oTarRole.m_oRoleState:AddMarriageBless()
	oRole:Tips("成功添加新婚buff")
	oRole.m_oRoleState:SyncState()
end

CGMMgr["removebattle"] = function (self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	if not oRole:IsInBattle() then 
		oRole:Tips("当前未处于战斗状态")
		return 
	end

	local oBattle = goBattleMgr:GetBattle(oRole:GetBattleID())
	if oBattle then
		goBattleMgr:GMRemoveBattle(oRole:GetBattleID(), oRole:GetID())
	end
end
