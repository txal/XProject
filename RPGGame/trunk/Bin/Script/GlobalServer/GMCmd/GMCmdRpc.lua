local _tGMProc = {} --处理函数

function Srv2Srv.GMCmdReq(nSrc, nSession, tData)
	local tParam = string.Split(tData.sCmd, ' ')
	local sCmdName = assert(tParam[1])
	table.remove(tParam, 1)

	local oFunc = assert(_tGMProc[sCmdName], "GMCmd "..sCmdName.." not defined")
	LuaTrace("GMCmd:", tData.sCmd)
	oFunc(nSession, tParam)
end

--重载脚本
_tGMProc["reload"] = function(nSession, tParam)
	local sScript = tParam[1] or ""
	if sScript == "" then
		local bRes = gfReloadAll()
		LuaTrace("reload all "..(bRes and "successful!" or "fail!"))
	else
		local bRes = gfReloadScript(sScript, "GlobalServer")
		LuaTrace("reload '"..sScript.."' ".. (bRes and "successful!" or "fail!"))
	end
end

--测试逻辑模块
_tGMProc["test"] = function(nSession, tParam)
end
