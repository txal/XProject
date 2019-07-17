--浏览器指令
function CBrowser:Ctor()
end

function CBrowser:BrowserReq(nSession, tData)
	local sMethod, tData = tData.method, tData.data
	LuaTrace("CBrowser["..sMethod.."]***", tData)
	local oFunc = CBrowser[sMethod]
	if oFunc then
		xpcall(oFunc, function(sErr)
			LuaTrace(sErr, debug.traceback())
			Srv2Bsr("BrowserRet", gnServerID, nSession, cjson_raw.encode({data=false, error=sErr}))
		end, self, nSession, tData)
	else
		local sErr = "方法不存在: "..sMethod
		Srv2Bsr("BrowserRet", gnServerID, nSession, cjson_raw.encode({error=sErr}))
		LuaTrace(sErr)
	end
end

--响应
function CBrowser:SendMsg(nSession, tData)
	assert(nSession and tData, "参数错误")
	Srv2Bsr("BrowserRet", gnServerID, nSession, cjson_raw.encode(tData))
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

function CBrowser:GetRoleData(nServer, nRoleID)
	local oDB = goDBMgr:GetSSDB(nServer, "user", nRoleID)
	local sData = oDB:HGet(gtDBDef.sRoleDB, nRoleID)
	if sData == "" then return {} end
	return cjson.decode(sData)
end

function CBrowser:GetAccountData(nServer, nAccountID)
	local oDB = goDBMgr:GetSSDB(nServer, "user", nAccountID)
	local sData = oDB:HGet(gtDBDef.sAccountDB, nAccountID)
	if sData == "" then return {} end
	return cjson.decode(sData)
end

--修改属性
CBrowser["moduser"] = function (self, nSession, tData)
	-- local nRoleID = tData.roleid
	-- local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	-- Network.oRemoteCall:CallWait("ModUserReq", function(nRoleID)
	-- 	Srv2Bsr("BrowserRet", gnServerID, nSession, cjson.encode({data=true}))
	-- end, oRole:GetServer(), oRole:GetLogic(), oRole:GetSession(), nRoleID, tData)
end

--踢下线
CBrowser["kickuser"] = function (self, nSession, tData)
	local nRoleID = tonumber(tData.roleid)
	print("CBrowser[kickuser]***", nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	oRole:KickOffline()
	self:SendMsg(nSession, {data=true})
end

--封号/禁言/解封
CBrowser["banuser"] = function (self, nSession, tData)
	print("CBrowser[banuser]***", tData)
	local nRoleID = tonumber(tData.roleid)
	local nState = tonumber(tData.state)

	local bStateValid = false
	for k, v in pairs(gtAccountState) do
		if nState == v then
			bStateValid = true
			break
		end
	end

	if not bStateValid then
		self:SendMsg(nSession, {data=false, error="状态错误"})
	end

	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		self:SendMsg(nSession, {data=false, error="角色不存在"})
		return
	end
	
	Network.oRemoteCall:CallWait("UpdateAccountValueReq", function(bRes)
		self:SendMsg(nSession, {data=bRes})
	end, oRole:GetServer(), goServerMgr:GetLoginService(oRole:GetServer()), oRole:GetSession(), oRole:GetAccountID(), {m_nAccountState=nState})
end

--玩家信息
CBrowser["memberinfo"] = function (self, nSession, tData)
	local tMemberMap = {}
	for _, sRoleID in ipairs(tData) do
		local nRoleID = tonumber(sRoleID)
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole then
			local tRoleData = self:GetRoleData(oRole:GetServer(), nRoleID)
			local tInfo = {
			    yuanbao = (tRoleData.m_nYuanBao or 0)+(tRoleData.m_nBYuanBao or 0),  --元宝(绑+非绑)
			    jinbi = tRoleData.m_nJinBi or 0,       --金币
			    yinbi = tRoleData.m_nYinBi or 0,       --银币
			    power = tRoleData.m_nPower or 0,  		--战斗力
			    level = oRole:GetLevel(), 				--等级
			    online = oRole:IsOnline(),  			--是否在线
			}
			local tAccountData = self:GetAccountData(oRole:GetServer(), oRole:GetAccountID())
			tInfo.state = tAccountData.m_nAccountState
			tMemberMap[nRoleID] = tInfo
		end
	end
	self:SendMsg(nSession, {data={tMemberMap, goGPlayerMgr:GetCount()}})
end

--充值商品列表
CBrowser["productlist"] = function (self, nSession, tData)
	local tProductList = {}
	for nID, tConf in pairs(ctRechargeConf) do
		local tItem = {nID=nID, sName=tConf.sName, nMoney=tConf.nMoney, sProduct=tConf.sProduct}
		table.insert(tProductList, tItem)
	end
	self:SendMsg(nSession, {data=tProductList})
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
	self:SendMsg(nSession, tMsg)
end

--发送公告
CBrowser["pubnotice"] = function (self, nSession, tData)
	local tMsg = {data=true}

	local nID = tData.id
	local sContent = tData.content or ""
	local nStartTime = tData.starttime
	local nEndTime = tData.endtime
	local nInterval = tData.interval

	if nID <= 0 or sContent == "" or nInterval < 0 or not (nStartTime and nEndTime) then
		tMsg.data = false
		tMsg.error = "公告格式错误"
		return self:SendMsg(nSession, tMsg)
	end

	if not goNoticeMgr:BrowserSendNotice(nID, nStartTime, nEndTime, nInterval, sContent) then
		tMsg.data = false
		tMsg.error = "发送公告失败"
	end
	self:SendMsg(nSession, tMsg)
end

--删除公告
CBrowser["delnotice"] = function (self, nSession, tData)
	local nID = tData.id
	goNoticeMgr:RemoveNotice(nID)
	self:SendMsg(nSession, {data=true})
end

--开启活动
CBrowser["openact"] = function (self, nSession, tData)
	tData.awardtime = nil --不需要后台传领奖时间过来了

	local tActConf = ctHuoDongConf[tData.actid]
	if not tActConf then
		return self:SendMsg(nSession, {data=true, error="活动配置不存在:"..tData.actid})
	end

	if tActConf.bCrossServer then
		Network.oRemoteCall:CallWait("GMOpenAct", function(bRes)
			if bRes then
				return self:SendMsg(nSession, {data=true})
			end
			return self:SendMsg(nSession, {data=false, error="请查看日志"})

		end, gnWorldServerID, goServerMgr:GetGlobalService(gnWorldServerID, 110), 0 , tData.actid, tData.subactid, tData.stime, tData.etime, tData.awardtime, tData.extid, tData.extid1)

	else
		if goHDMgr:GMOpenAct(tData.actid, tData.subactid, tData.stime, tData.etime, tData.awardtime, tData.extid, tData.extid1) then
			return self:SendMsg(nSession, {data=true})
		end
		return self:SendMsg(nSession, {data=false, error="请查看日志"})
		
	end
end

--活动列表
CBrowser["hdlist"] = function (self, nSession, tData)
	local tBigList = {}
	for nID, tConf in pairs(ctHuoDongConf) do
		if not tConf.bClose then
			table.insert(tBigList, {nID=nID, sName=tConf.sName, nAwardTime=tConf.nAwardTime, bRounds=tConf.bRounds, bProps=tConf.bProps})
		end
	end
	--限时奖励活动子活动
	local tSubList = {[gtHDDef.eTimeAward]={}}
	if not ctHuoDongConf[gtHDDef.eTimeAward].bClose then
		for nID, tConf in pairs(ctTimeAwardConf) do
			if tConf.nValue1 > 0 then
				table.insert(tSubList[gtHDDef.eTimeAward], {nID=nID, sName=tConf.sName, nAwardTime=tConf.nAwardTime})
			end
		end
	end
	local tData = {bigActList=tBigList, subActList=tSubList}
	self:SendMsg(nSession, {data=tData})
end

--非货币道具
CBrowser["proplist"] = function (self, nSession, tData)
	local tList = {}
	self:SendMsg(nSession, {data=tList})
end

--取需要后台配置的活动列表
CBrowser["backstageconflist"] = function (self, nSession, tData)
	self:SendMsg(nSession, {data=false, error="已废弃"})
end

--取游戏内配置表
CBrowser["getbackstageconf"] = function (self, nSession, tData)
end

--设置游戏配置表
CBrowser["setbackstageconf"] = function (self, nSession, tData)
end

--删除游戏配置表
CBrowser["delbackstageconf"] = function (self, nSession, tData)
end

--取事件列表
CBrowser["gmevents"] = function (self, nSession, tData)
	self:SendMsg(nSession, {data=gtEventGM})
end

--获取玩家宠物信息
CBrowser["getpetinfo"] = function (self, nSession, tData)
	local nRoleID = tData.roleid
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local fnSendMsg = function (tData)
		self:SendMsg(nSession, {data=tData or {}})
	end
	if not oRole then
		fnSendMsg()
	else
	Network.oRemoteCall:CallWait("GMGetPetInfoReq", function (tData)
		fnSendMsg(tData)
	end, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
	end
end

--删除玩家宠物
CBrowser["deletepet"] = function (self, nSession, tData)
	local nRoleID = tData.roleid
	local nPos = tData.pos
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	Network.oRemoteCall:CallWait("GMDeletePetReq",function (bFlag)
		self:SendMsg(nSession, {data=bFlag})
	end,  oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), nPos)
end
