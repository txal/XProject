--错误捕捉函数
local function fnError(sErr)
	LuaTrace(sErr, debug.traceback())
end

--分发辅助函数
local tRpcInfo = {}
local function _fnDispHelp(bRes, ...)
	local nCode = bRes and 0 or -1
	Srv2Srv.RemoteCallRet(tRpcInfo.nSrcServer, tRpcInfo.nSrcService, tRpcInfo.nTarSession, tRpcInfo.nCallID, nCode, ...)
end

--远程调用请求(需要返回)
function Srv2Srv.RemoteCallDisp(nSrcServer, nSrcService, nTarSession, nCallID, sCallFunc, bNeedReturn, ...) 
	local oFunc = Srv2Srv[sCallFunc]
	if not oFunc then
		if bNeedReturn then
			return Srv2Srv.RemoteCallRet(nSrcServer, nSrcService, nTarSession, nCallID, -1,  "RPC函数未定义:"..sCallFunc)
		else
			return LuaTrace("RPC函数未定义:", sCallFunc)
		end
	end
	if bNeedReturn then
		tRpcInfo.nCallID = nCallID
		tRpcInfo.nSrcServer = nSrcServer
		tRpcInfo.nSrcService = nSrcService
		tRpcInfo.nTarSession = nTarSession
		_fnDispHelp(xpcall(oFunc, fnError, nSrcServer, nSrcService, nTarSession, ...))

	else
		oFunc(nSrcServer, nSrcService, nTarSession, ...)
		
	end
end

--远程调用返回
function Srv2Srv.RemoteCallRet(nSrcServer, nSrcService, nTarSession, nCallID, nCode, ...) 
	goRemoteCall:OnCallRet(nTarSession, nCallID, nCode, ...) 
end