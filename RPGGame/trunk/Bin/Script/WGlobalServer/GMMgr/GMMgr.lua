--GM指令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nServerID = gnServerID
function CGMMgr:Ctor()
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	local nRoleID, sRoleName, sAccount = 0, "", ""
	if oRole then
		nRoleID, sRoleName, sAccount = oRole:GetID(), oRole:GetName(), oRole:GetAccountName()
	end

	local sInfo = string.format("执行指令:%s [roleid:%d,rolename:%s,account:%s]", sCmd, nRoleID, sRoleName, sAccount)
	LuaTrace(sInfo)

	local oFunc = CGMMgr[sCmdName]
	local oFunc = assert(CGMMgr[sCmdName], "找不到指令:["..sCmdName.."]")
	table.remove(tArgs, 1)
	oFunc(self, nServer, nService, nSession, tArgs)
end

-----------------指令列表-----------------
-- 测试逻辑
CGMMgr["wtest"] = function(self, nServer, nService, nSession, tArgs)
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
		local bRes = gfReloadScript(sScript, "WGlobalServer")
		LuaTrace("重载 '"..sScript.."' ".. (bRes and "成功!" or "失败!"))
	end
end


goGMMgr = goGMMgr or CGMMgr:new()