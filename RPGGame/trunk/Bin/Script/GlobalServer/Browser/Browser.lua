--浏览器指令
local nServerID = gnServerID

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
		CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode({error=sErr}))
		LuaTrace(sErr)
	end
end

--修改属性
CBrowser["moduser"] = function (self, nSession, tData)
	local nRoleID = tData.roleid
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	goRemoteCall.CallWait("ModUserReq", function(nRoleID)
		CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode({data=true}))
	end, oRole:GetServer(), oRole:GetLogic(), oRole:GetSession(), nRoleID, tData)
end

--踢下线
CBrowser["kickuser"] = function (self, nSession, tData)
	local nRoleID = tData.roleid
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)

	local bRes = false
	if oRole:IsOnline()	 then
		bRes = true
		local nTarServer = oPlayer:GetServer()
		local nTarSession = oPlayer:GetSession()
		CmdNet.Srv2Srv("KickClient", nTarServer, nTarSession>>nSERVICE_SHIFT, nTarSession)
	end
	CmdNet.Srv2Bsr(nSession, "BrowserRet", cjson.encode({data=bRes}))
end

--封号/解封/禁言
CBrowser["banuser"] = function (self, nSession, tData)
	local nRoleID = tData.roleid
	local nState = tData.state

	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local nAccountID = oRole:GetAccountID()

	local bRes = false
	local oDB = goDBMgr:GetSSDB(oRole:GetServer(), "user", nAccountID)
	local sAccountData = oDB:HGet(gtDBDef.sAccountDB, nAccountID)
	if sAccountData ~= "" then
		bRes = true
		local tAccountData = cjson.decode(sAccountData)
		if nState ~= tAccountData.m_nState then
			tAccountData.m_nState = nState
			oDB:HSet(gtDBDef.sAccountDB, nAccountID, cjson.encode(tAccountData))
		end
	end
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode({data=bRes}))
end

--取玩家模块数据
function CBrowser:GetModuleData(sModuleName, nRoleID)
	print("CBrowser:GetModuleData***", sModuleName, nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local oDB = goDBMgr:GetSSDB(oRole:GetServer(), "user", nRoleID)
    local sData = oDB:HGet(sModuleName, nRoleID)
    if sData == "" then return {} end
    return cjson.decode(sData)
end

--玩家信息
CBrowser["memberinfo"] = function (self, nSession, tData)
	local tMemberMap = {}
	for _, nRoleID in ipairs(tData) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local oDB = goDBMgr:GetSSDB(oRole:GetServer(), "user", nRoleID)
		local sRoleData = oSSDB:HGet(gtDBDef.sRoleDB, nRoleID)
		if sRoleData ~= "" then
			local tInfo = {}
			local tRoleData = cjson.decode(sRoleData)

			tMemberMap[nRoleID] = tInfo
		end
	end
	local tMsg = {data={tMemberMap, goGPlayerMgr:GetOnlineCount()}}
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson_raw.encode(tMsg))
end

--充值商品列表
CBrowser["productlist"] = function (self, nSession, tData)
	local tProductList = {}
	for nID, tConf in pairs(ctRechargeConf) do
		local tItem = {nID=nID, sName=tConf.sName, nMoney=tConf.nMoney, sProduct=tConf.sProduct}
		table.insert(tProductList, tItem)
	end
	local tMsg = {data=tProductList}
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode(tMsg))
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
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode(tMsg))
end

--发送公告
CBrowser["pubnotice"] = function (self, nSession, tData)
	local tMsg = {data=true}

	local nID = tData.id
	local sContent = tData.content or ""
	local nStartTime = tData.starttime
	local nEndTime = tData.endtime
	local nInterval = tData.interval

	if nID <= 0 or sContent == "" or not (nStartTime and nEndTime and nInterval) then
		tMsg.data = false
		tMsg.error = "公告格式错误"
		return CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode(tMsg))
	end

	if not goNoticeMgr:GMSendNotice(nID, nStartTime, nEndTime, nInterval, sContent) then
		tMsg.data = false
		tMsg.error = "发送公告失败"
	end
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode(tMsg))
end

--删除公告
CBrowser["delnotice"] = function (self, nSession, tData)
	local nID = tData.id
	goNoticeMgr:RemoveNotice(nID)
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode({data=true}))
end

--开启活动
CBrowser["openact"] = function (self, nSession, tData)
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode({data=true}))
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
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson_raw.encode({data=tData}))
end

--非货币道具
CBrowser["proplist"] = function (self, nSession, tData)
	local tList = {}
	CmdNet.Srv2Bsr("BrowserRet", nServerID, nSession, cjson.encode({data=tList}))
end

goBrowser = goBrowser or CBrowser:new()