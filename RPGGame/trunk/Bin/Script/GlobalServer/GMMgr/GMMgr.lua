--GM指令
function CGMMgr:Ctor()
	self.m_tAuthMap = {}
	self.m_sPassword = "5378"
	self.m_nPasswordTime = 3600
end

--权限检测
function CGMMgr:CheckAuth(nSession, bBrowser)
	if gbDebug or bBrowser then
		return true
	end
	if os.time() - (self.m_tAuthMap[nSession] or 0) >= self.m_nPasswordTime then
		self.m_tAuthMap[nSession] = nil
		return 
	end
	return true
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nSession, sCmd, bBrowser)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	if sCmdName ~= "auth" and not self:CheckAuth(nSession, bBrowser) then
		return LuaTrace("GM需要授权")
	end

	local oPlayer = goGPlayerMgr:GetPlayerBySession(nSession)
	local nCharID, sCharName, sAccount = 0, "", ""
	if oPlayer then
		nCharID, sCharName, sAccount = oPlayer:GetCharID(), oPlayer:GetName(), oPlayer:GetAccount()
	end
	local sInfo = string.format("执行指令:%s [charid:%d,charname:%s,account:%s]", sCmd, nCharID, sCharName, sAccount)
	LuaTrace(sInfo)

	local oFunc = CGMMgr[sCmdName]
	if not oFunc then
		CGMMgr["lgm"](self, nSession, tArgs)
	else
		table.remove(tArgs, 1)
		oFunc(self, nSession, tArgs)
	end
end

-----------------指令列表-----------------
--授权
CGMMgr["auth"] = function(self, nSession, tArgs)
	local sPwd = tArgs[1] or ""
	if sPwd == self.m_sPassword then
		self.m_tAuthMap[nSession] = os.time()
		LuaTrace("GM授权成功")
	else
		LuaTrace("GM授权密码错误")
	end
end

--设置新密码
CGMMgr["passwd"] = function(self, nSession, tArgs)
	local sPasswd= tArgs[1] or ""
	if sPasswd == "" then
		return LuaTrace("密码不能为空")
	end
	self.m_sPassword = sPasswd
	return LuaTrace("GM密码设置成功")
end

--发送到LogicServer的GM
CGMMgr["lgm"] = function(self, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	for nLogic, tConf in pairs(gtNetConf.tLogicService) do
		Srv2Srv.GMCommandReq(nLogic, nSession, sCmd)
	end
end

--发送到LogServer的GM
CGMMgr["rgm"] = function(self, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	for nService, tConf in pairs(gtNetConf.tLogService) do
		Srv2Srv.GMCommandReq(nService, nSession, sCmd)
	end
end

-- 测试逻辑
CGMMgr["gtest"] = function(self, nSession, tArgs)
	local oPlayer = goGPlayerMgr:GetPlayerBySession(nSession)
	if not oPlayer then return end
	goGiftExchange:SMBXDescReq(oPlayer, 2)
	goGiftExchange:ExchangeReq(oPlayer, "abc")
end

--重载脚本
CGMMgr["reload"] = function(self, nSession, tArgs)
	local sScript = tArgs[1] or ""
	if sScript == "" then
		local bRes = gfReloadAll()
		LuaTrace("重载所有脚本 "..(bRes and "成功!" or "失败!"))
	else
		local bRes = gfReloadScript(sScript, "GlobalServer")
		LuaTrace("重载 '"..sScript.."' ".. (bRes and "成功!" or "失败!"))
	end
end

--打印玩家信息
CGMMgr["ponline"] = function(self, nSession, tArgs)
	goGPlayerMgr:PrintOnline()
end

--发送公告
CGMMgr["sendnotice"] = function(self, nSession, tArgs)
	local nID = tonumber(tArgs[1]) or 0 	--公告ID(随意)
	local nKeep = tonumber(tArgs[2]) or 0 	--持续时间(秒)
	local nIntval = tonumber(tArgs[3]) or 0	--间隔(秒)
	local sCont = tonumber(tArgs[4]) or 0 	--公告内容(秒)
	if goNoticeMgr:GMSendNotice(nID, os.time(), os.time()+nKeep, nIntval, sCont) then
		return CGPlayer:Tips("发送公告成功", nSession)
	end
	return CGPlayer:Tips("发送公告失败", nSession)
end


goGMMgr = goGMMgr or CGMMgr:new()