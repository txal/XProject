--GM指令
function CGMMgr:Ctor()
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nSession, sCmd)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	local nCharID, sCharName, sAccount = 0, "", ""
	if oPlayer then
		nCharID, sCharName, sAccount = oPlayer:GetCharID(), oPlayer:GetName(), oPlayer:GetAccount()
	end
	local sInfo = string.format("执行指令:%s [charid:%d,charname:%s,account:%s]", sCmd, nCharID, sCharName, sAccount)
	LuaTrace(sInfo)

	local oFunc = CGMMgr[sCmdName]
	if not oFunc then
		LuaTrace("找不到指令:["..sCmdName.."]")
		return CPlayer:Tips("找不到指令:["..sCmdName.."]", nSession)
	end
	table.remove(tArgs, 1)
    xpcall(function() oFunc(self, nSession, tArgs) end, function(sErr) print(sErr) CPlayer:Tips(sErr, nSession) end)
end

-----------------指令列表-----------------
--测试逻辑模块
CGMMgr["test"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oLiFanYuan:RandItem()
	print(oPlayer.m_oLiFanYuan.m_tSelectItem, "******")
	oPlayer.m_oFashion:GetFashion(1002)
end

--重载脚本
CGMMgr["reload"] = function(self, nSession, tArgs)
	if #tArgs == 0 then
		local bRes = gfReloadAll()
		local sTips = "重载所有脚本 "..(bRes and "成功!" or "失败!")
		LuaTrace(sTips)
		CPlayer:Tips(sTips, nSession)

	elseif #tArgs == 1 then
		local sFileName = tArgs[1]
		local bRes = gfReloadScript(sFileName, "LogicServer")
		local sTips = "重载脚本 '"..sFileName.."' ".. (bRes and "成功!" or "失败!")
		LuaTrace(sTips)
		CPlayer:Tips(sTips, nSession)

	else
		assert(false, "reload 参数错误")
	end
end

--输出指令耗时信息
CGMMgr["dumpcmd"] = function(self, nSession, tArgs)
	goCmdMonitor:DupCmd()
end

--输出LUA表使用情况
CGMMgr["dumptable"] = function(self, nSession, tArgs)
	goWatchDog:DumpTable()
end

--添加物品
CGMMgr["additem"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	if #tArgs < 3 then return oPlayer:Tips("参数错误") end

	local nItemType, nItemID, nItemNum = tonumber(tArgs[1]), tonumber(tArgs[2]), tonumber(tArgs[3])
    if not (nItemType > 0 and nItemID > 0 and nItemNum) then
    	return oPlayer:Tips("参数错误")
    end
    local tConf = ctPropConf[nItemID]
    if not tConf then
    	return oPlayer:Tips("道具不存在:"..nItemID)
    end
	if oPlayer:AddItem(nItemType, nItemID, nItemNum, "GM", true) then
		oPlayer:Tips("添加物品成功")
	end
end

--添加所有物品
CGMMgr["itemall"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	for nID, tConf in pairs(ctPropConf) do
		oPlayer:AddItem(gtItemType.eProp, nID, 999, "GM")
	end
end

--增加奏章
CGMMgr["addzz"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nVal = tonumber(tArgs[1]) or 0
	oPlayer.m_oZouZhang:AddZouZhang(nVal, "GM")
	oPlayer:Tips(string.format("增加%d奏章数", nVal))
end

--使用政务令
CGMMgr["usezwl"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nVal = tonumber(tArgs[1]) or 0
	oPlayer.m_oZouZhang:AddZouZhangTimesReq(nVal, "GM")
end

--增加请安折
CGMMgr["addqaz"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nVal = tonumber(tArgs[1]) or 0
	-- oPlayer.m_oQingAnZhe:AddQingAnZhe(nVal, "GM")
end

--增加寻访次数
CGMMgr["addxf"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nVal = tonumber(tArgs[1]) or 0
	oPlayer.m_oWeiFuSiFang:AddTiLi(nVal, "GM")
end


--设置VIP等级
CGMMgr["setvip"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nVIP = tonumber(tArgs[1]) or 0
	oPlayer:SetVIP(nVIP, "GM")
end

--通关副本
CGMMgr["duppass"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nDup = tonumber(tArgs[1])
	if oPlayer.m_oDup:GMDupPass(nDup) then
		oPlayer:Tips("通关关卡成功:"..nDup)
	end
end

--创建皇子
CGMMgr["createhz"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oMC = oPlayer.m_oMingChen:RandObj(1)[1]
	if not oMC then
		return oPlayer:Tips("没有知己不能生孩子")
	end
	local nSex = math.min(2, math.max(1, tonumber(tArgs[1]) or 1))
	local nTalentLv = math.min(5, math.max(1, tonumber(tArgs[2]) or 1))
	if oPlayer.m_oZongRenFu:Create(oMC:GetID(), nSex, false, nTalentLv) then
		return oPlayer:Tips("创建皇子成功")
	end
end

--打印属性
CGMMgr["dumpattr"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer:UpdateGuoLi("GM指令")
	oPlayer:Tips(tostring(oPlayer.m_tAttr))
end

--所有大臣升级
CGMMgr["mcupgrade"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nLv = tonumber(tArgs[1]) or 1
	for nID, oMC in pairs(oPlayer.m_oMingChen.m_tMingChenMap) do
		oMC:GMSetLv(nLv)
	end
end

--所有皇子升级
CGMMgr["hzupgrade"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nLv = tonumber(tArgs[1]) or nil
	for nID, oHZ in pairs(oPlayer.m_oZongRenFu.m_tHZMap) do
		oHZ:GMSetLv(nLv)
	end
end

--发送邮件
CGMMgr["sendmail"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local tItems = {{1,30501,10},{1,30502,10},{1,30503,10},{1,30504,10},{1,30505,10}}
	goMailMgr:SendServerMail("系统邮件", "测试邮件", "邮件测试水电费六角恐龙圣诞似懂非懂是", tItems, true)
	oPlayer:Tips("发送邮件成功")
end

--清除所有的全局邮件
CGMMgr['clssrvmail'] = function(self, nSession, tArgs)
	goMailMgr:GMClearTask()
end

--清空个人已读或没有物品邮件
--删除自身邮件clearmail  
--删除某人邮件clearmail nCharID
CGMMgr['clearmail'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nCharID = tonumber(tArgs[1]) or 0
	local nMailID = tonumber(tArgs[2]) or 0
	if nCharID ~= 0 then
		local oPlayerMail = goPlayerMgr:GetPlayerByCharID(nCharID)
		oPlayerMail.m_oMail:DelMailReq(nMailID)
	else
		oPlayer.m_oMail:DelMailReq(nMailID)
	end
	oPlayer:Tips("删除邮件成功")
end

--模拟充值
CGMMgr["gmrecharge"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nMoney = tonumber(tArgs[1]) or 0
	oPlayer.m_oVIP:GMRecharge(nMoney)
end

--活动时间
CGMMgr["hdtime"] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nID = tonumber(tArgs[1]) or 0 
	local nMin =  tonumber(tArgs[2]) or 0
	local nSubID = tonumber(tArgs[3]) or 0
	local nExtID = tonumber(tArgs[4]) or 0
	local nEndTime = math.ceil(nMin+os.time()/60)*60
	goHDMgr:GMOpenAct(nID, os.time(), nEndTime, nSubID, nExtID)
end

--完成主线任务
CGMMgr['mtask'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nID = tonumber(tArgs[1])
	oPlayer.m_oMainTask:GMCompleteTask(nID)
end

--生成主线任务
CGMMgr['inittask'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nID = tonumber(tArgs[1])
	oPlayer.m_oMainTask:GMInitTask(nID)
end

--增加联盟经验
CGMMgr['addunionexp'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oUnion = goUnionMgr:GetUnionByCharID(oPlayer:GetCharID())
	if not oUnion then
		return oPlayer:Tips("请先加入联盟")
	end
	local nExp = tonumber(tArgs[1]) or 0
	oUnion:AddExp(nExp, "GM", oPlayer)
	oPlayer:Tips(string.format("增加%d点联盟经验", nExp))
end

--增加联盟贡献
CGMMgr['addunioncontri'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oUnion = goUnionMgr:GetUnionByCharID(oPlayer:GetCharID())
	if not oUnion then
		return oPlayer:Tips("请先加入联盟")
	end
	local nContri = tonumber(tArgs[1]) or 0
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(oPlayer:GetCharID())
	oUnionPlayer:AddUnionContri(nContri, "GM", oPlayer)
	oPlayer:Tips(string.format("增加%d点联盟贡献", nContri))
end

--增加威望
CGMMgr['addww'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nNum = tonumber(tArgs[1]) or 0
	oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWeiWang, nNum, "GM")
	oPlayer:Tips(string.format("增加%d威望", nNum))
end

--怡红院
CGMMgr['resetyhy'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oYiHongYuan:Init()
	oPlayer:Tips("重置怡红院成功")
end

--怡红院加速
CGMMgr['yhyspeedup'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nSpeed = tonumber(tArgs[1]) or 0
	if nSpeed then 
		oPlayer.m_oYiHongYuan:AddSpeedReq(nSpeed)
		oPlayer:Tips("怡红院加速成功")
	end
end

--重置日常任务
CGMMgr['resetdt'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oDailyTask:GMReset()
	oPlayer:Tips("重置日常任务成功")
end

--系统消息
CGMMgr['systalk'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local sCont = tArgs[1] or "empty"
	goTalk:SendSystemMsg(sCont)
end

--重置军机处次数
CGMMgr['resetjjc'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJunJiChu:GMReset()
end

--军机处战斗测试
CGMMgr['jjcbattle'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nGMCharID = tonumber(tArgs[1]) or 0
	local oTarPlayer = goOfflineDataMgr:GetPlayer(nGMCharID)
	if not oTarPlayer then
		return oPlayer:Tips("目标玩家不存在")
	end
	if oPlayer:GetCharID() == nGMCharID then
		return oPlayer:Tips("不能打自己")
	end
	oPlayer.m_oJunJiChu:GMSetEnemy(nGMCharID)
	oPlayer:Tips("军机处设置敌人成功")
end

--SVN更新
CGMMgr['svnupdate'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end

	local linux = io.open("linux.txt", "r")	
	if not linux then
	    local f = io.popen("zsvnupdate.bat")
	    repeat
	        local cont = f:read("l")
	        if cont then print(cont) end
	    until(not cont)
	    f:close()
	else
		os.execute("sh ./zsvnupdate.sh > svnupdate.log")
	end
	CGMMgr["reload"](self, nSession, tArgs)
	oPlayer:Tips("执行svnupdate指令成功")
end

--重置联盟宴会出战知己
CGMMgr['resetunfz'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local oUnion = goUnionMgr:GetUnionByCharID(oPlayer:GetCharID())
	if not oUnion then
		return oPlayer:Tips("请先加入联盟")
	end
	oUnion.m_oUnionParty:GMResetFZ(oPlayer)
end

--清空国库
CGMMgr['clrguoku'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oGuoKu:GMClrGuoKu()
end

--结束宴会
CGMMgr['finishparty'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goOfflineDataMgr.m_oPartyData:GMFinishParty(oPlayer)
end

--清空奖励记录
CGMMgr['clrrecord'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goAwardRecordMgr:Init()
	oPlayer:Tips("清空所有奖励记")
end

--清空聊天
CGMMgr['clrtalk'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goTalk:GMClearTalk(oPlayer)
end

--添加宴会活跃值
CGMMgr['addactive'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nVal = tonumber(tArgs[1]) or 0
	oPlayer.m_oParty:AddActive(nVal, "添加活跃值")
	oPlayer:Tips(string.format("增加%d活跃值", nVal))
end

--增加技能点
CGMMgr['addsp'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	local nID = tonumber(tArgs[1]) or 0
	local nNum = tonumber(tArgs[2]) or 0
	local oObj = oPlayer.m_oMingChen:GetObj(nID)
	if not oObj then return oPlayer:Tips("知己不存在") end
	oObj:AddSKPoint(nNum, "GM")
	oPlayer:Tips("添加知己技能点成功")
end

--重置储秀宫次数
CGMMgr['resetxx'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oChuXiuGong:GMReset()
	oPlayer:Tips("重置储秀宫次数成功")
end

--重置天灯祈福
CGMMgr['resettd'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oTianDeng:GMReset()
	oPlayer:Tips("重置天灯祈福成功")
end

--重置游园
CGMMgr['resetyw'] = function(self, nSession, tArgs)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	oPlayer.m_oJingShiFang:GMReset()
	oPlayer:Tips("重置游园成功")
end


goGMMgr = goGMMgr or CGMMgr:new()