--GM指令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGMMgr:Ctor()
end

--收到GM指令
function CGMMgr:OnGMCmdReq(nServer, nService, nSession, sCmd)
	local tArgs = string.Split(sCmd, ' ')
	local sCmdName = assert(tArgs[1])

	local sInfo = string.format("执行指令:%s", sCmd)
	LuaTrace(sInfo)

	local oFunc = assert(CGMMgr[sCmdName], "找不到指令:["..sCmdName.."]")
	table.remove(tArgs, 1)
	oFunc(self, nServer, nService, nSession, tArgs)
end

-----------------指令列表-----------------
--重载脚本
CGMMgr["reload"] = function(self, nServer, nService, nSession, tArgs)
	if #tArgs == 0 then
		local bRes = gfReloadAll()
		LuaTrace("重载所有脚本 "..(bRes and "成功!" or "失败!"))

	elseif #tArgs == 1 then
		local sFileName = tArgs[1]
		local bRes = gfReloadScript(sFileName, "LogServer")
		LuaTrace("重载脚本 '"..sFileName.."' ".. (bRes and "成功!" or "失败!"))

	else
		_assert(false, "reload 参数错误")
	end
end


goGMMgr = goGMMgr or CGMMgr:new()