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

    xpcall(function() oFunc(self, nServer, nService, nSession, tArgs) end
    	, function(sErr)
	    	print(sErr)
	    	CRole:Tips(sErr, nServer, nSession)
	    end)
end

-----------------指令列表-----------------
--测试逻辑模块
CGMMgr["test"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	print(oRole)
end

--重载脚本
CGMMgr["reload"] = function(self, nServer, nService, nSession, tArgs)
	if #tArgs == 0 then
		local bRes = gfReloadAll()
		local sTips = "重载所有脚本 "..(bRes and "成功!" or "失败!")
		LuaTrace(sTips)
		CRole:Tips(sTips, nServer, nSession)

	elseif #tArgs == 1 then
		local sFileName = tArgs[1]
		local bRes = gfReloadScript(sFileName, "LogicServer")
		local sTips = "重载脚本 '"..sFileName.."' ".. (bRes and "成功!" or "失败!")
		LuaTrace(sTips)
		CRole:Tips(sTips, nServer, nSession)

	else
		assert(false, "reload 参数错误")
	end
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

	local nItemType, nItemID, nItemNum = tonumber(tArgs[1]), tonumber(tArgs[2]), tonumber(tArgs[3])
    if not (nItemType > 0 and nItemID > 0 and nItemNum) then
    	return oRole:Tips("参数错误")
    end
    local tConf = ctPropConf[nItemID]
    if not tConf then
    	return oRole:Tips("道具不存在:"..nItemID)
    end
	if oRole:AddItem(nItemType, nItemID, nItemNum, "GM") then
		oRole:Tips("添加物品成功")
	end
end

--添加所有物品
CGMMgr["itemall"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	for nID, tConf in pairs(ctPropConf) do
		oRole:AddItem(gtItemType.eProp, nID, 999)
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

--活动时间
CGMMgr["hdtime"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local nID = tonumber(tArgs[1]) or 0 
	local nMin =  tonumber(tArgs[2]) or 0
	local nSubID = tonumber(tArgs[3]) or 0
	local nExtID = tonumber(tArgs[4]) or 0
	local nEndTime = math.ceil(nMin+os.time()/60)*60
	goHDMgr:GMOpenAct(nID, os.time(), nEndTime, nSubID, nExtID)
end

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

--增加联盟经验
CGMMgr['addunionexp'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByCharID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入联盟")
	end
	local nExp = tonumber(tArgs[1]) or 0
	oUnion:AddExp(nExp, "GM", oRole)
	oRole:Tips(string.format("增加%d点联盟经验", nExp))
end

--增加联盟贡献
CGMMgr['addunioncontri'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByCharID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入联盟")
	end
	local nContri = tonumber(tArgs[1]) or 0
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(oRole:GetID())
	oUnionPlayer:AddUnionContri(nContri, "GM", oRole)
	oRole:Tips(string.format("增加%d点联盟贡献", nContri))
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
	local sCont = tArgs[1] or "empty"
	goTalk:SendSystemMsg(sCont)
end

--重置联盟宴会出战知己
CGMMgr['resetunfz'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	local oUnion = goUnionMgr:GetUnionByCharID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入联盟")
	end
	oUnion.m_oUnionParty:GMResetFZ(oRole)
end

--清空国库
CGMMgr['clrguoku'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	oRole.m_oGuoKu:GMClrGuoKu()
end

--清空聊天
CGMMgr['clrtalk'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goTalk:GMClearTalk(oRole)
end


goGMMgr = goGMMgr or CGMMgr:new()