--GM指令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nServerID = gnServerID

function CGMMgr:Ctor()
	self.m_tAuthMap = {}
	self.m_sPassword = "5378"
	self.m_nPasswordTime = 3600
end

--权限检测
function CGMMgr:CheckAuth(nServer, nService, nSession, bBrowser)
	if gbDebug or bBrowser then
		return true
	end
	local nSSKey = goGPlayerMgr:MakeSSKey(nServer, nSession)
	if os.time() - (self.m_tAuthMap[nSSKey] or 0) >= self.m_nPasswordTime then
		self.m_tAuthMap[nSSKey] = nil
		return 
	end
	return true
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd, bBrowser)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	if sCmdName ~= "auth" and not self:CheckAuth(nServer, nService, nSession, bBrowser) then
		return LuaTrace("GM需要授权")
	end

	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	local nRoleID, sRoleName, sAccount = 0, "", ""
	if oRole then
		nRoleID, sRoleName, sAccount = oRole:GetID(), oRole:GetName(), oRole:GetAccountName()
	end

	local sInfo = string.format("执行指令:%s [roleid:%d,rolename:%s,account:%s]", sCmd, nRoleID, sRoleName, sAccount)
	LuaTrace(sInfo)

	local oFunc = CGMMgr[sCmdName]
	if not oFunc then
		CGMMgr["lgm"](self, nServer, nService, nSession, tArgs)
	else
		table.remove(tArgs, 1)
		oFunc(self, nServer, nService, nSession, tArgs)
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
	for _, tConf in pairs(gtServerConf.tLogicService) do
		goRemoteCall:Call("GMCommandReq", nServerID, tConf.nID, nSession, sCmd)
	end
	for _, tConf in pairs(gtWorldConf.tLogicService) do
		goRemoteCall:Call("GMCommandReq", nServerID, tConf.nID, nSession, sCmd)
	end
end

--发送到LOG的GM
CGMMgr["rgm"] = function(self, nServer, nService, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	for _, tConf in pairs(gtServerConf.tLogService) do
		goRemoteCall:Call("GMCommandReq", nServerID, tConf.nID, nSession, sCmd)
	end
end

--发送到WGLOBAL的GM
CGMMgr["wgm"] = function(self, nServer, nService, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	for _, tConf in pairs(gtWorldConf.tGlobalService) do
		goRemoteCall:Call("GMCommandReq", nServerID, tConf.nID, nSession, sCmd)
	end
end

--发送到LOGIN的GM
CGMMgr["agm"] = function(self, nServer, nService, nSession, tArgs)
	local sCmd = table.concat(tArgs, " ")
	for _, tConf in pairs(gtServerConf.tLoginService) do
		goRemoteCall:Call("GMCommandReq", nServerID, tConf.nID, nSession, sCmd)
	end
end

-- 测试逻辑
CGMMgr["gtest"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
end

--重载脚本
CGMMgr["reload"] = function(self, nServer, nService, nSession, tArgs)
	local sScript = tArgs[1] or ""
	if sScript == "" then
		local bRes = gfReloadAll()
		LuaTrace("重载所有脚本 "..(bRes and "成功!" or "失败!"))
	else
		local bRes = gfReloadScript(sScript, "GlobalServer")
		LuaTrace("重载 '"..sScript.."' ".. (bRes and "成功!" or "失败!"))
	end
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

--SVN更新
CGMMgr['svnupdate'] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end

	local linux = io.open("linux.txt", "r")	
	if not linux then
	    local f = io.popen("zsvnupdate.bat")
	    repeat
	        local cont = f:read("l")
	        if cont then
	        	print(cont)
	        end
	    until(not cont)
	    f:close()
	else
		os.execute("sh ./zsvnupdate.sh > svnupdate.log")
	end
	self:OnGMCmdReq(nServer, nSession, "reload")
	self:OnGMCmdReq(nServer, nSession, "lgm reload")
	self:OnGMCmdReq(nServer, nSession, "rgm reload")
	self:OnGMCmdReq(nServer, nSession, "wgm reload")
	oRole:Tips("执行svnupdate指令成功")
end

--发送邮件
CGMMgr["sendmail"] = function(self, nServer, nService, nSession, tArgs)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goMailMgr:SendServerMail("系统", "测试邮件", "邮件测试", {}, true)
	oRole:Tips("发送邮件成功")
end

--清除所有的全局邮件
CGMMgr['rmsrvmail'] = function(self, nServer, nService, nSession, tArgs)
	local nMailID = tonumber(tArgs[1]) or 0
	goMailMgr:GMDelServerMail(nMailID)
end


goGMMgr = goGMMgr or CGMMgr:new()