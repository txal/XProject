local _LG = _G
local _assert = assert
local _rawget = rawget
local _clock = os.clock
local _insert = table.insert

local _rpc_pack = NetworkExport.RpcPack
local _rpc_unpack = NetworkExport.RpcUnpack
local _send_exter = NetworkExport.SendExter 
local _send_inner = NetworkExport.SendInner
local _broadcast_inner = NetworkExport.BroadcastInner

local Network = Network
Network.RpcClt2Srv = Network.RpcClt2Srv or {sName = "RpcClt2Srv"}
Network.RpcSrv2Clt = Network.RpcSrv2Clt or {sName = "RpcSrv2Clt"}
Network.RpcSrv2Srv = Network.RpcSrv2Srv or {sName = "RpcSrv2Srv"}

--消息中心
local function _fnUnpackProxy(nSrcServer, nSrcService, nTarSession, sRpcType, sRpcFunc, ...)
    local nStartTime = _clock()

    local tRpcType = Network[sRpcType]
    _assert(tRpcType, string.format("Rpc type '%s' not exist", sRpcType))
    local oFunc = _rawget(tRpcType, sRpcFunc)
    _assert(oFunc, string.format("Rpc func '%s.%s' not exist", sRpcType, sRpcFunc))
    oFunc(nSrcServer, nSrcService, nTarSession, ...)

    -- goCmdMonitor:AddCmd(sRpcType.."."..sRpcFunc, _clock() - nStartTime)
end
RpcMessageCenter = function(nSrcServer, nSrcService, nTarSession, oPacket)
    _fnUnpackProxy(nSrcServer, nSrcService, nTarSession, _rpc_unpack(oPacket))
end

---------------------------------------客户端=>服务器----------------------------------------
--nToService:0逻辑服标识,x真实服务ID
--格式:Network.RpcClt2Srv.XXX(nTarService, nTarSession, ...)
local _tRpcInfo = {}
local _RpcClt2SrvMeta = {}
local function _fnRpcClt2SrvProxy(nPacketIdx, nTarService, nTarSession, ...)
    local oPacket = _rpc_pack(_tRpcInfo.sRpcType, _tRpcInfo.sRpcFunc, ...)
    _send_exter(gtMsgType.eLuaRpcMsg, oPacket, 0, nTarService, nTarSession, nPacketIdx)
end
_RpcClt2SrvMeta.__index = function(tRpcType, sFunc)
    _tRpcInfo.sRpcType = tRpcType.sName or "unknow"
    _tRpcInfo.sRpcFunc = sFunc
    return _fnRpcClt2SrvProxy
end
setmetatable(Network.RpcClt2Srv, _RpcClt2SrvMeta)

---------------------------------------服务器=>客户端------------------------------------------
--格式:Network.RpcSrv2Clt.XXX(nSessionID, ...)
local _tRpcInfo = {}
local _RpcSrv2CltMeta = {}
local function _fnRpcSrv2CltProxy(nTarServer, nTarSession, ...)
    local oPacket = _rpc_pack(_tRpcInfo.sRpcType, _tRpcInfo.sRpcFunc, ...)
    _send_exter(gtMsgType.eLuaRpcMsg, oPacket, nTarServer, nTarSession>>24, nTarSession, 0)
end
_RpcSrv2CltMeta.__index = function(tRpcType, sFunc)
    _tRpcInfo.sRpcType = tRpcType.sName or "unknow"
    _tRpcInfo.sRpcFunc = sFunc
    return _fnRpcSrv2CltProxy
end
setmetatable(Network.RpcSrv2Clt, _RpcSrv2CltMeta)

--------------------------------------服务器内部------------------------------------------------
--单发(异步)
--格式:Network.RpcSrv2Srv.XXX(nTarServer, nTarService, nTarSession, ...)
local _tRpcInfo = {}
local _tRpcSrv2SrvMeta = {}
local function _fnRpcSrv2SrvProxy(nTarServer, nTarService, nTarSession, ...)
    local oPacket = _rpc_pack(_tRpcInfo.sRpcType, _tRpcInfo.sRpcFunc, ...)
    _send_inner(gtMsgType.eLuaRpcMsg, oPacket, nTarServer, nTarService, nTarSession)
end
_tRpcSrv2SrvMeta.__index = function(tRpcType, sFunc)
    _tRpcInfo.sRpcType = tRpcType.sName or "unknow"
    _tRpcInfo.sRpcFunc = sFunc
    return _fnRpcSrv2SrvProxy
end
setmetatable(Network.RpcSrv2Srv, _tRpcSrv2SrvMeta)

--广播(异步)
--格式:Network.RpcSrv2Srv.BroadcastInner(sRpcFunc, tServiceList, ...): tServiceList:{{nTarServer, nTarService, nTarSession}, ...}
Network.RpcSrv2Srv.BroadcastInner = function(sRpcFunc, tServiceList, ...)
    assert(#tServiceList>0 and #tServiceList%3==0, "参数错误")
    local oPacket = _rpc_pack(Network.RpcSrv2Srv.sName, sRpcFunc, ...)
    _broadcast_inner(gtMsgType.eLuaRpcMsg, 0, oPacket, tServiceList)
end

--远程调用请求
Network.RpcSrv2Srv.RemoteCallReq = function(nTarServer, nTarService, nTarSession, nCallID, sCallFunc, ...)
    if nTarServer <= 0 or nTarService <= 0 then
        return 
    end
    local oPacket = _rpc_pack(Network.RpcSrv2Srv.sName, "RemoteCallDispatcher", nCallID, sCallFunc, ...)
    _send_inner(gtMsgType.eLuaRpcMsg, oPacket, nTarServer, nTarService, nTarSession)
end

--远程调用返回
Network.RpcSrv2Srv.RemoteCallRet = function(nTarServer, nTarService, nTarSession, nCallID, nCode, ...)
    if nTarServer <= 0 or nTarService <= 0 then
        return
    end
    local oPacket = _rpc_pack(Network.RpcSrv2Srv.sName, "RemoteCallCallback", nCallID, nCode, ...)
    _send_inner(gtMsgType.eLuaRpcMsg, oPacket, nTarServer, nTarService, nTarSession)

end