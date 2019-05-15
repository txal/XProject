local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--GM指令
function CGMMgr:Ctor()
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	local nRoleID, sRoleName, sAccount = 0, "", ""
	local sInfo = string.format("执行指令:%s [roleid:%d,rolename:%s,account:%s]", sCmd, nRoleID, sRoleName, sAccount)
	LuaTrace(sInfo)

	local oFunc = assert(CGMMgr[sCmdName], "找不到指令:["..sCmdName.."]")
	table.remove(tArgs, 1)
	return oFunc(self, nServer, nService, nSession, tArgs)
end

-----------------指令列表-----------------
CGMMgr["test"] = function(self, nServer, nService, nSession, tArgs)
	local oAccount = goLoginMgr:GetAccountByID(nAccountID)
	for nAccountID, oAccount in pairs(goLoginMgr.m_tAccountIDMap) do
		print(nAccountID, oAccount.m_tRoleSummaryMap)
	end
	goLoginMgr:AccountOffline(112713)
end

--重载脚本
CGMMgr["reload"] = function(self, nServer, nService, nSession, tArgs)
	local bRes, sTips = false, ""
	if #tArgs == 0 then
		bRes = gfReloadAll("LoginServer")
		sTips = "重载所有脚本 "..(bRes and "成功!" or "失败!")

	elseif #tArgs == 1 then
		local sFileName = tArgs[1]
		bRes = gfReloadScript(sFileName, "LoginServer")
		sTips = "重载脚本 '"..sFileName.."' ".. (bRes and "成功!" or "失败!")

	end
	LuaTrace(sTips)
	CLAccount:Tips("登录服 "..sTips, gnServerID, nSession)	
	return bRes
end


goGMMgr = goGMMgr or CGMMgr:new()