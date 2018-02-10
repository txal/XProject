local nLogicService = next(gtNetConf.tLogicService) --逻辑服ID

function CBrowser:Ctor()
end

function CBrowser:BrowserReq(nSession, tData)
	local sMethod, tData = tData.method, tData.data
	LuaTrace("CBrowser["..sMethod.."]***", tData)
	local oFunc = CBrowser[sMethod]
	if oFunc then
		xpcall(oFunc, function(sErr)
			LuaTrace(sErr)
			CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode({error=sErr}))
		end, self, nSession, tData)
	else
		local sErr = "方法不存在: "..sMethod
		CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode({error=sErr}))
		LuaTrace(sErr)
	end
end

--修改属性
CBrowser["moduser"] = function (self, nSession, tData)
	local nCharID = tonumber(tData.charid)
	local oPlayer = goGPlayerMgr:GetPlayerByCharID(nCharID)
	if oPlayer then
		Srv2Srv.GMModUserReq(oPlayer:GetServer(), oPlayer:GetLogicService(), nSession, tData)
	else
		local tMsg = {data=true}
		local oSSDB = goDBMgr:GetSSDB("Player")
		local sPlayerData = oSSDB:HGet(gtDBDef.sRoleDB, nCharID)
		if sPlayerData ~= "" then
			local tPlayerData = cjson.decode(sPlayerData)
			tPlayerData.m_nYuanBao = tData.yuanbao
			tPlayerData.m_nYinLiang = tData.yinliang
			tPlayerData.m_nWeiWang = tData.weiwang 
			tPlayerData.m_nWaiJiao = tData.waijiao
			tPlayerData.m_nVIP = tData.vip
			oSSDB:HSet(gtDBDef.sRoleDB, nCharID, cjson.encode(tPlayerData))
		else
			tMsg.data = false
			tMsg.error = "角色不存在"
		end
		CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
	end
end
function CBrowser:OnModUserRet(nBsrSession, bRes)
--逻辑服返回
	local tMsg = {data=bRes}
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nBsrSession, cjson.encode(tMsg))
end

--踢下线
CBrowser["kickuser"] = function (self, nSession, tData)
	local nCharID = tonumber(tData.charid)
	local oPlayer = goGPlayerMgr:GetPlayerByCharID(nCharID)
	local bRes = false
	if oPlayer then
		bRes = true
		if oPlayer:IsOnline() then
			local nTarServer = oPlayer:GetServer()
			local nTarSession = oPlayer:GetSession()
			CmdNet.Srv2Srv("KickClient", nTarServer, nTarSession>>nSERVICE_SHIFT, nTarSession)
		end
	end
	local tMsg= {data=bRes}
	CmdNet.Srv2Bsr(nSession, "BrowserRet", cjson.encode(tMsg))
end

--封号/解封/禁言
CBrowser["banuser"] = function (self, nSession, tData)
	local sAccount = tData.account
	local bRes = false
	local oSSDB = goDBMgr:GetSSDB("Player")
	local sAccountData = oSSDB:HGet(gtDBDef.sAccountDB, sAccount)
	if sAccountData ~= "" then
		bRes = true
		local tAccountData = cjson.decode(sAccountData)
		if tData.state ~= tAccountData.nState then
			tAccountData.nState = tData.state
			oSSDB:HSet(gtDBDef.sAccountDB, sAccount, cjson.encode(tAccountData))
		end
	end
	local tMsg = {data=bRes}
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
end

--取玩家模块数据
function CBrowser:GetModuleData(sModuleName, nCharID)
	print("CBrowser:GetModuleData***", sModuleName, nCharID)
    local sData = goDBMgr:GetSSDB("Player"):HGet(sModuleName, nCharID)
    if sData == "" then return {} end
    return cjson.decode(sData)
end

--玩家信息
CBrowser["memberinfo"] = function (self, nSession, tData)
	print("CBrowser[memberinfo]***", tData)
	local tMemberMap = {}
	local oSSDB = goDBMgr:GetSSDB("Player")
	for _, nCharID in ipairs(tData) do
		nCharID = tonumber(nCharID)
		local sPlayerData = oSSDB:HGet(gtDBDef.sRoleDB, nCharID)
		if sPlayerData ~= "" then
			local tInfo = {nState=0, nYuanBao=0, nYinLiang=0, nGuoLi=0, nWeiWang=0, nWaiJiao=0, nVIP=0, bOnline=false}
			local tPlayerData = cjson.decode(sPlayerData)

			tInfo.nYuanBao = tPlayerData.m_nYuanBao
			tInfo.nYinLiang = tPlayerData.m_nYinLiang
			tInfo.nGuoLi = tPlayerData.m_nGuoLi or 0
			tInfo.nWeiWang = tPlayerData.m_nWeiWang or 0
			tInfo.nWaiJiao = tPlayerData.m_nWaiJiao or 0
			tInfo.nVIP = tPlayerData.m_nVIP or 0
			local oPlayer = goGPlayerMgr:GetPlayerByCharID(nCharID)
			tInfo.bOnline = oPlayer and oPlayer:IsOnline() or false
			--宗人府席位 寝宫数 冷宫厢房数 子嗣数 银库上限 粮库上限 兵营上限
			tInfo.nZRFGrid = self:GetModuleData("ZongRenFu", nCharID).m_nGrids or ctHZEtcConf[1].nInitPos
			tInfo.nQGGrid = self:GetModuleData("JingShiFang", nCharID).m_nOpenGrid or 1
			tInfo.nLGGrid = self:GetModuleData("LengGong", nCharID).m_nOpenGrid or 1
			tInfo.nZSNum = self:GetModuleData("OfflineDataDB", nCharID).m_nChildNum or 0
			local tNGLv = self:GetModuleData("NeiGe", nCharID).m_tLv or {1,1,1}
			tInfo.nMaxYK = 0
			tInfo.nMaxLC = 0
			tInfo.nMaxBY = 0

			--玩家状态
			local nSource = tPlayerData.m_nSource or 0
			local sAccount = tPlayerData.m_sAccount or ""
			local sKey = nSource == 0 and sAccount or nSource.."_"..sAccount
			local sAccountData = oSSDB:HGet(gtDBDef.sAccountDB, sKey)
			if sAccountData ~= "" then
				local tAccountData = cjson.decode(sAccountData)
				tInfo.nState = tAccountData.nState or 0
			end
			tMemberMap[nCharID] = tInfo
		end
	end
	local tMsg = {data={tMemberMap, goGPlayerMgr:GetOnlineCount()}}
	CmdNet.Srv2Bsr("BrowserRet", gnServer, nSession, cjson_raw.encode(tMsg))
end

--充值商品列表
CBrowser["productlist"] = function (self, nSession, tData)
	local tProductList = {}
	for nID, tConf in pairs(ctRechargeConf) do
		local tItem = {nID=nID, sName=tConf.sName, nMoney=tConf.nMoney, sProduct=tConf.sProduct}
		table.insert(tProductList, tItem)
	end
	local tMsg = {data=tProductList}
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
end

--执行指令
CBrowser["gmcmd"] = function (self, nSession, tData)
	local sCmd = "do "..tData.cmd .." end"
	local oFunc, sErr = load(sCmd)
	local tMsg = {data=true}
	if not oFunc then
		tMsg.error = sErr
		tMsg.data = false
	else
		oFunc()
	end
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
end

--发送邮件
CBrowser["sendmail"] = function (self, nSession, tData)
	local tMsg = {data=true}
	tData.target = tonumber(tData.target)
	if not tData.title or not tData.content or (not tData.target and not tData.server) then
		tMsg.data = false
		tMsg.error = "邮件格式错误"
		return CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
	end
	if tData.itemlist then
		local itemlist = cjson.decode(tData.itemlist)
		if #itemlist > 15 then
			tMsg.data = false
			tMsg.error = "最多支持15个物品"
			return CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
		end
		tData.itemlist = itemlist
	end
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
	-- Srv2Srv.GMSendMailReq(nLogicService, 0, tData)
end

--发送公告
CBrowser["pubnotice"] = function (self, nSession, tData)
	local tMsg = {data=true}
	tData.id = tonumber(tData.id) or 0
	tData.content = tData.content or ""
	if tData.id <= 0 or tData.content == "" or not (tData.starttime and tData.endtime and tData.interval) then
		tMsg.data = false
		tMsg.error = "公告格式错误"
		return CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
	end
	if not goNoticeMgr:GMSendNotice(tData.id, tData.starttime, tData.endtime, tData.interval, tData.content) then
		tMsg.data = false
		tMsg.error = "发送公告失败"
	end
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode(tMsg))
end

--删除公告
CBrowser["delnotice"] = function (self, nSession, tData)
	tData.id = tonumber(tData.id) or 0
	goNoticeMgr:RemoveNotice(tData.id)
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode({data=true}))
end

--开启活动
CBrowser["openact"] = function (self, nSession, tData)
	-- Srv2Srv.GMOpenActReq(nLogicService, 0, tData)
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode({data=true}))
end

--活动列表
CBrowser["hdlist"] = function (self, nSession, tData)
	local tBigList = {}
	for nID, tConf in pairs(ctHuoDongConf) do
		table.insert(tBigList, {nID=nID, sName=tConf.sName, nAwardTime=tConf.nAwardTime})
	end
	local tSubList = {[9]={}} --限时活动子活动
	for nID, tConf in pairs(ctTimeAwardConf) do
		if tConf.nValue1 > 0 then
			table.insert(tSubList[9], {nID=nID, sName=tConf.sName, nAwardTime=tConf.nAwardTime})
		end
	end
	local tData = {bigActList=tBigList, subActList=tSubList}
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson_raw.encode({data=tData}))
end

--取妃子列表
CBrowser["fzlist"] = function (self, nSession, tData)
	local tList = {}
	-- for nID, tConf in pairs(ctFeiZiConf) do
	-- 	table.insert(tList, {nID=nID, sName=tConf.sName})
	-- end
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode({data=tList}))
end

--非货币道具
CBrowser["djlist"] = function (self, nSession, tData)
	local tList = {}
	for nID, tConf in pairs(ctPropConf) do
		if tConf.nType ~= 1 then
			table.insert(tList, {nID=nID, sName=tConf.sName})
		end
	end
	CmdNet.Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode({data=tList}))
end

goBrowser = goBrowser or CBrowser:new()