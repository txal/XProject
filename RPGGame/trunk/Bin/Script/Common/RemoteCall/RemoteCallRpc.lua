--远程调用消息中转中心
local _traceback = debug.traceback
local _xpcall = xpcall
local _rawget = rawget
local _clock = os.clock
local _Srv2Srv = Srv2Srv

--错误处理函数
local function fnError(sErr)
	LuaTrace(sErr, _traceback())
end

--分发辅助函数
local tRpcInfo = {}
local function _fnDispHelper(bRes, ...)
	local nCode = bRes and 0 or -1
	_Srv2Srv.RemoteCallRet(tRpcInfo.nSrcServer, tRpcInfo.nSrcService, tRpcInfo.nTarSession, tRpcInfo.nCallID, nCode, ...)
end

--远程调用请求
function Srv2Srv.RemoteCallDispatcher(nSrcServer, nSrcService, nTarSession, nCallID, sCallFunc, bNeedReturn, ...) 
	print("------remote call------", sCallFunc)
    local oFunc = _rawget(_Srv2Srv, sCallFunc)
	if not oFunc then
		if bNeedReturn then
			return _Srv2Srv.RemoteCallRet(nSrcServer, nSrcService, nTarSession, nCallID, -1,  "RPC函数未定义:"..sCallFunc)
		else
			return LuaTrace("RPC函数未定义:", sCallFunc)
		end
	end


	local nClock= _clock()

	if bNeedReturn then
		tRpcInfo.nCallID = nCallID
		tRpcInfo.nSrcServer = nSrcServer
		tRpcInfo.nSrcService = nSrcService
		tRpcInfo.nTarSession = nTarSession

		_fnDispHelper(_xpcall(oFunc, fnError, nSrcServer, nSrcService, nTarSession, ...))

	else
		oFunc(nSrcServer, nSrcService, nTarSession, ...)
		
	end

	--记录耗时
	goCmdMonitor:AddCmd(sCallFunc, _clock()-nClock)
end

--远程调用回调
function Srv2Srv.RemoteCallCallback(nSrcServer, nSrcService, nTarSession, nCallID, nCode, ...) 
	goRemoteCall:OnCallRet(nCallID, nCode, ...) 
end