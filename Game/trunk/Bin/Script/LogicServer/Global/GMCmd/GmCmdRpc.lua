local _sPassword = "5378"
local _nPasswordTime = 3600
gtAuthList = gtAuthList or {}
local function _CheckAuth(nSession)
	if gbDebug then
		return true
	end
	if os.time() - (gtAuthList[nSession] or 0) >= _nPasswordTime then
		gtAuthList[nSession] = nil
		return 
	end
	return true
end

local _tGMProc = {} --处理函数
function CltPBProc.GMCmdReq(nCmd, nSrc, nSession, tData)
	local tParam = string.Split(tData.sCmd, ' ')
	local sCmdName = assert(tParam[1])
	table.remove(tParam, 1)

	if sCmdName ~= "auth" and not _CheckAuth(nSession) then
		return LuaTrace("GM需要授权")
	end

	local oFunc = assert(_tGMProc[sCmdName], "GMCmd "..sCmdName.." not defined")
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	local nCharID, sCharName, sAccount = "", "", ""
	if oPlayer then
		nCharID, sCharName, sAccount = oPlayer:GetCharID(), oPlayer:GetName(), oPlayer:GetAccount()
	end
	LuaTrace("GMCmd:", tData.sCmd, sAccount, nCharID, sCharName)
	oFunc(nSession, tParam)
end

--授权
_tGMProc["auth"] = function(nSession, tParam)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	local sName = oPlayer and oPlayer:GetName() or ""	

	local sPwd = tParam[1] or ""
	if sPwd == _sPassword then
		gtAuthList[nSession] = os.time()
		LuaTrace("GM授权成功", sName)
	else
		LuaTrace("GM授权密码错误", sName)
	end
end

--重载脚本
_tGMProc["reload"] = function(nSession, tParam)
	if #tParam == 0 then
		local bRes = gfReloadAll()
		LuaTrace("reload all "..(bRes and "successful!" or "fail!"))

	elseif #tParam == 1 then
		local sFileName = tParam[1]
		local bRes = gfReloadScript(sFileName, "LogicServer")
		LuaTrace("reload '"..sFileName.."' ".. (bRes and "successful!" or "fail!"))

	else
		assert(false, "reload 参数错误")
	end
end

--重载脚本(指定服务ID)
_tGMProc["reloadtar"] = function(nSession, tParam)
	if #tParam == 1 then
		local nTarServer = tonumber(tParam[1])	
		if nTarServer == GlobalExport.GetServiceID() then
			_tGMProc["reload"](nSession, {})
		else
			Srv2Srv.GMCmdReq(nTarServer, nSession, {sCmd="reload"})
		end

	elseif #tParam == 2 then
		local nTarServer = tonumber(tParam[1])
		local sFileName = tParam[2]
		if nTarServer == GlobalExport.GetServiceID() then
			_tGMProc["reload"](nSession, {sFileName})
		else
			Srv2Srv.GMCmdReq(nTarServer, nSession, {sCmd="reload "..sFileName})
		end

	else
		assert(false, "reloadtar 参数错误")
	end
end

--输出指令耗时信息
_tGMProc["dumpcmd"] = function(nSession, tParam)
	goCmdMonitor:DupCmd()
end

--输出LUA表使用情况
_tGMProc["dumptable"] = function(nSession, tParam)
	goWatchDog:DumpTable()
end

--测试逻辑模块
_tGMProc["test"] = function(nSession, tParam)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then
		return
	end
	local oGamMgr = goGameMgr:GetGame(gtGameType.eGDMJ)
	oGamMgr:FreeRoomEnterReq(oPlayer, 1)
	oGamMgr:FreeRoomMatchReq(oPlayer, 1)

 --    local oHu = tGDMJConf:NewMJHu()
 --    -- local tHandMJ = {0x01, 0x01, 0x01, 0x02, 0x03, 0x03, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0xFF}
 --    -- local tHandMJ = {0x01, 0x09, 0x11, 0x19, 0x21, 0x29, 0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43, 0xFF}
 --    -- oRoom:_SortMJ(tHandMJ, 13)
 --    -- local nHu = oRoom:_IsHu(tHandMJ, 13, 0x18, oHu)
 --    -- print(nHu, "***")
 --    local tTypeMap = {[16]={[1]=20,[2]=21,[3]=22,[4]=22,[5]=23,[6]=24,},[32]={[1]=37,[2]=37,},[0]={[1]=2,[2]=2,[3]=3,[4]=3,[5]=4,[6]=4,},}
	-- print(oRoom:_IsHuNotGhost(tTypeMap, oHu), "***")
end

--设置等级
_tGMProc["setlevel"] = function(nSession, tParam)
	local nLevel = tonumber(tParam[1]) or 0
	nLevel = math.max(1, math.min(#ctPlayerLevelConf, nLevel))
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	oPlayer:SetLevel(nLevel)
end

--增加金币
_tGMProc["addgold"] = function(nSession, tParam)
	local nNum = tonumber(tParam[1]) or 0
	if nNum == 0 then return end 
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if nNum > 0 then
		oPlayer:AddGold(nNum, gtReason.eNone, true)
	else
		oPlayer:SubGold(math.abs(nNum), gtReason.eNone, true)
	end
end

--增加钻石
_tGMProc["adddiamond"] = function(nSession, tParam)
	local nNum = tonumber(tParam[1]) or 0
	if nNum == 0 then return end
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if nNum > 0 then
		oPlayer:AddDiamond(nNum, gtReason.eNone, true)
		oPlayer.m_oVIP:GMRecharge(nNum*10)
	else
		oPlayer:SubDiamond(math.abs(nNum), gtReason.eNone, true)
	end
end

--增加房卡
_tGMProc["addcard"] = function(nSession, tParam)
	local nNum = tonumber(tParam[1]) or 0
	if nNum == 0 then return end
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if nNum > 0 then
		oPlayer:AddCard(nNum, true)
	else
		oPlayer:SubCard(nNum, true)
	end
end

--增加物品
_tGMProc["additem"] = function(nSession, tParam)
	local nType, nItem, nNum = tonumber(tParam[1]) or 0, tonumber(tParam[2]) or 0, tonumber(tParam[3]) or 0
	assert(nType > 0 and nItem > 0 and nNum > 0)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	oPlayer:AddItem(nType, nItem, nNum, gtReason.eNone)
end

--所有物品都增加
_tGMProc["itemall"] = function(nSession, tParam)
	local nNum = tonumber(tParam[1]) or 0
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	for nPropID, tPropConf in pairs(ctPropConf) do
		oPlayer:AddItem(gtItemType.eProp, nPropID, nNum, gtReason.eNone)
	end
	for nArmID, tArmConf in pairs(ctArmConf) do
		oPlayer:AddItem(gtItemType.eArm, nArmID, 1, gtReason.eNone)
	end
	for nWSPropID, tWSPropConf in pairs(ctWSPropConf) do
		oPlayer:AddItem(gtItemType.eWSProp, nWSPropID, 1, gtReason.eNone)
	end
end

--清空背包
_tGMProc["clearbag"] = function(nSession, tParam)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	oPlayer.m_oBagModule:RemoveAllBagItem()
end

--开放所有背包格子
_tGMProc["openbag"] = function(nSession, tParam)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	oPlayer.m_oBagModule.m_nOpenGrid =ctBagConf[1].nMaxGrid
end

--系统聊天
_tGMProc["testsyschat"] = function(nSession, tParam)
	goTalk:SendSystemMsg(tParam[1] or "none")
end

--发送邮件测试
_tGMProc["testmail"] = function(nSession, tParam)
	local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then 
		return
	end
	local sCharName, nPropID, nPropNum = tParam[1], tonumber(tParam[2]), tonumber(tParam[3])
	local nCharID = goPlayerMgr:GetCharIDFromDB(sCharName)
	if not nCharID then
		return oPlayer:Tips("目标玩家不存在")
	end
	local tItems = {}
	if nPropID and (nPropNum or 0) > 0 then
		if not ctPropConf[nPropID] then
			return oPlayer:Tips("道具:"..nPropID.."不存在,只支持发送道具")
		end
		table.insert(tItems, {gtItemType.eProp, nPropID, nPropNum})
	end
	if goMailMgr:SendMail(oPlayer:GetName(), "测试", "测试内容", tItems, nCharID) then
		oPlayer:Tips("发送邮件成功")
	else
		oPlayer:Tips("发送邮件失败")
	end
end
