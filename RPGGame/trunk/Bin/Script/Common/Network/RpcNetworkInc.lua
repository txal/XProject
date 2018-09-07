local _assert = assert
local _rawget = rawget
local _clock = os.clock
local _insert = table.insert
local _LG = _G

local _rpc_pack = NetworkExport.RpcPack
local _rpc_unpack = NetworkExport.RpcUnpack
local _send_exter = NetworkExport.SendExter 
local _send_inner = NetworkExport.SendInner
local _broadcast_inner = NetworkExport.BroadcastInner

Clt2Srv = Clt2Srv or {sName = "Clt2Srv"}
Srv2Clt = Srv2Clt or {sName = "Srv2Clt"}
Srv2Srv = Srv2Srv or {sName = "Srv2Srv"}

--消息中心
local function _fnUnpackProxy(nSrcServer, nSrcService, nTarSession, sRpcType, sRpcFunc, ...)
    local nStartTime = _clock()

    LuaTrace("------rpc message------", sRpcType, sRpcFunc)
    local tRpcType = _LG[sRpcType]
    _assert(tRpcType, string.format("Rpc type '%s' not exist", sRpcType))
    local oFunc = _rawget(tRpcType, sRpcFunc)
    _assert(oFunc, string.format("Rpc func '%s.%s' not exist", sRpcType, sRpcFunc))
    oFunc(nSrcServer, nSrcService, nTarSession, ...)

    goCmdMonitor:AddCmd(sRpcType.."."..sRpcFunc, _clock() - nStartTime)
end
RpcMessageCenter = function(nSrcServer, nSrcService, nTarSession, oPacket)
    _fnUnpackProxy(nSrcServer, nSrcService, nTarSession, _rpc_unpack(oPacket))
end

---------------------------------------客户端=>服务器----------------------------------------
--nToService:0逻辑服标识,x真实服务ID
--格式:Clt2Srv.XXX(nTarService, nTarSession, ...)
local tClt2SrvMeta = {}
local tRpcInfo = {}
local function _fnClt2SrvProxy(nPacketIdx, nTarService, nTarSession, ...)
    local oPacket = _rpc_pack(tRpcInfo.sRpcType, tRpcInfo.sRpcFunc, ...)
    _send_exter(gtMsgType.eLuaRpcMsg, oPacket, 0, nTarService, nTarSession, nPacketIdx)
end
tClt2SrvMeta.__index = function(tRpcType, sFunc)
    tRpcInfo.sRpcType = tRpcType.sName or "unknow"
    tRpcInfo.sRpcFunc = sFunc
    return _fnClt2SrvProxy
end
setmetatable(Clt2Srv, tClt2SrvMeta)

---------------------------------------服务器=>客户端------------------------------------------
--格式:Srv2Clt.XXX(nSessionID, ...)
local tSrv2CltMeta = {}
local tRpcInfo = {}
local function _fnSrv2CltProxy(nTarServer, nTarSession, ...)
    local oPacket = _rpc_pack(tRpcInfo.sRpcType, tRpcInfo.sRpcFunc, ...)
    _send_exter(gtMsgType.eLuaRpcMsg, oPacket, nTarServer, nTarSession>>24, nTarSession, 0)
end
tSrv2CltMeta.__index = function(tRpcType, sFunc)
    tRpcInfo.sRpcType = tRpcType.sName or "unknow"
    tRpcInfo.sRpcFunc = sFunc
    return _fnSrv2CltProxy
end
setmetatable(Srv2Clt, tSrv2CltMeta)

--------------------------------------服务器内部------------------------------------------------
--单发(异步)
--格式:Srv2Srv.XXX(nTarServer, nTarService, nTarSession, ...)
local tInternalMeta = {}
local tRpcInfo = {}
local function _fnInternalProxy(nTarServer, nTarService, nTarSession, ...)
    local oPacket = _rpc_pack(tRpcInfo.sRpcType, tRpcInfo.sRpcFunc, ...)
    _send_inner(gtMsgType.eLuaRpcMsg, oPacket, nTarServer, nTarService, nTarSession)
end
tInternalMeta.__index = function(tRpcType, sFunc)
    tRpcInfo.sRpcType = tRpcType.sName or "unknow"
    tRpcInfo.sRpcFunc = sFunc
    return _fnInternalProxy
end
setmetatable(Srv2Srv, tInternalMeta)

--广播(异步)
--格式:Srv2Srv.Broadcast(sRpcFunc, tServiceList, ...): tServiceList:{{nTarServer, nTarService, nTarSession}, ...}
Srv2Srv.Broadcast = function(sRpcFunc, tServiceList, ...)
    assert(#tServiceList>0 and #tServiceList%3==0, "参数错误")
    local oPacket = _rpc_pack(Srv2Srv.sName, sRpcFunc, ...)
    _broadcast_inner(gtMsgType.eLuaRpcMsg, 0, oPacket, tServiceList)
end

--远程调用请求
Srv2Srv.RemoteCallReq = function(nTarServer, nTarService, nTarSession, nCallID, sCallFunc, ...)
    local oPacket = _rpc_pack(Srv2Srv.sName, "RemoteCallDispatcher", nCallID, sCallFunc, ...)
    _send_inner(gtMsgType.eLuaRpcMsg, oPacket, nTarServer, nTarService, nTarSession)
end

--远程调用返回
Srv2Srv.RemoteCallRet = function(nTarServer, nTarService, nTarSession, nCallID, nCode, ...)
    local oPacket = _rpc_pack(Srv2Srv.sName, "RemoteCallCallback", nCallID, nCode, ...)
    _send_inner(gtMsgType.eLuaRpcMsg, oPacket, nTarServer, nTarService, nTarSession)
end