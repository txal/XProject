local _insert = table.insert
local _clock = os.clock
local _rpc_pack = NetworkExport.RpcPack
local _rpc_unpack = NetworkExport.RpcUnpack
local _send_exter = NetworkExport.SendExter 
local _send_inner = NetworkExport.SendInner

Clt2Srv = Clt2Srv or {sName = "Clt2Srv"}
Srv2Clt = Srv2Clt or {sName = "Srv2Clt"}
Srv2Srv = Srv2Srv or {sName = "Srv2Srv"}

--消息中心
local function _fnUnpackProxy(nSrc, nSession, sRpcType, sRpcFunc, ...)
    local nStartTime = _clock()

    local tRpcType = _G[sRpcType]
    assert(tRpcType, string.format("Rpc type '%s' not exist", sRpcType))
    local oFunc = rawget(tRpcType, sRpcFunc)
    assert(oFunc, string.format("Rpc func '%s.%s' not exist", sRpcType, sRpcFunc))
    oFunc(nSrc, nSession, ...)

    goCmdMonitor:AddCmd(sRpcType.."."..sRpcFunc, _clock() - nStartTime)
end
RpcMessageCenter = function(nSrc, nSession, oPacket)
    _fnUnpackProxy(nSrc, nSession, _rpc_unpack(oPacket))
end

---------------------------------------客户端=>服务器----------------------------------------
--nToService:0逻辑服标识,x真实服务ID
--格式:Clt2Srv.XXX(nToService, nSessionID, ...)
local tClt2SrvMeta = {}
local tRpcInfo = {}
local function _fnClt2SrvProxy(nPacketIdx, nToService, nToSessionID, ...)
    local oPacket = _rpc_pack(tRpcInfo.sRpcType, tRpcInfo.sRpcFunc, ...)
    _send_exter(gtMsgType.eLuaRpcMsg, oPacket, nToService, nToSessionID, nPacketIdx)
    --print("SendExter:", nToService, nToSessionID, table.unpack(tParam))
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
local function _fnSrv2CltProxy(nSessionID, ...)
    local oPacket = _rpc_pack(tRpcInfo.sRpcType, tRpcInfo.sRpcFunc, ...)
    _send_exter(gtMsgType.eLuaRpcMsg, oPacket, nSessionID>>24, nSessionID)
    --print("SendExter:", nSessionID, table.unpack(tParam))
end
tSrv2CltMeta.__index = function(tRpcType, sFunc)
    tRpcInfo.sRpcType = tRpcType.sName or "unknow"
    tRpcInfo.sRpcFunc = sFunc
    return _fnSrv2CltProxy
end
setmetatable(Srv2Clt, tSrv2CltMeta)

--------------------------------------服务器内部------------------------------------------------
--格式:Srv2Srv.XXX(nToService, nToSession, ...)
local tInternalMeta = {}
local tRpcInfo = {}
local function _fnInternalProxy(nToService, nToSession, ...)
    local oPacket = _rpc_pack(tRpcInfo.sRpcType, tRpcInfo.sRpcFunc, ...)
    _send_inner(gtMsgType.eLuaRpcMsg, oPacket, nToService, nToSession)
    --print("SendInner:", nToService, tParam, tRpcType, sFunc)
end
tInternalMeta.__index = function(tRpcType, sFunc)
    tRpcInfo.sRpcType = tRpcType.sName or "unknow"
    tRpcInfo.sRpcFunc = sFunc
    return _fnInternalProxy
end
setmetatable(Srv2Srv, tInternalMeta)
