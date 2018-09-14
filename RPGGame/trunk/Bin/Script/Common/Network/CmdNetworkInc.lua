protobuf = require("Common/Network/protobuf")
parser = require("Common/Network/parser")

local tServerConf = gtServerConf

local _pairs = pairs
local _assert = assert
local _clock = os.clock
local _insert = table.insert

local _cmd_pack = NetworkExport.CmdPack
local _cmd_unpack = NetworkExport.CmdUnpack
local _pb_pack = NetworkExport.PBPack
local _send_exter = NetworkExport.SendExter 
local _send_inner = NetworkExport.SendInner
local _broadcast_exter = NetworkExport.BroadcastExter
local _broadcast_inner = NetworkExport.BroadcastInner

local tSysCmdDef = {126, 1024}      --系统指令段
local tCltCmdDef = {1025, 8000}     --客户端服务器(自定义)指令段
local tCltPBCmdDef = {8001, 40000}  --客户端服务器(protobuf)指令段
local tSrvCmdDef = {40001, 50000}   --服务器间指令段
local tBsrCmdDef = {50001, 50100}   --浏览器服务器指令端

local tCltCmdReq, tCltCmdRet = {}, {}
local tCltPBReq, tCltPBRet = {}, {}
local tBsrCmdReq, tBsrCmdRet = {}, {}
local tSrvSrvCmd = {}

CmdNet = CmdNet or {bServer=true}
CltPBProc = CltPBProc or {}         --客户端PB包处理
CltCmdProc = CltCmdProc or {}       --客户端CMD包处理
SrvCmdProc = SrvCmdProc or {}       --服务端CMD包处理
BsrCmdProc = BsrCmdProc or {}       --浏览器CMD包处理

--@xPacket 可能是Packet对象或者字符串(PB)
CmdMessageCenter = function(nCmd, nSrcServer, nSrcService, nTarSession, xPacket)
    local nStartTime = _clock()

    local tProtoType, tProcType, fnDecoder
    if nCmd >= tCltPBCmdDef[1] and nCmd <= tCltPBCmdDef[2] then
        tProtoType = CmdNet.bServer and tCltPBReq or tCltPBRet
        tProcType = CltPBProc
        fnDecoder = pbc_decode

    elseif (nCmd >= tSrvCmdDef[1] and nCmd <= tSrvCmdDef[2]) or (nCmd >= tSysCmdDef[1] and nCmd <= tSysCmdDef[2]) then
        tProtoType = tSrvSrvCmd
        tProcType = SrvCmdProc
        fnDecoder = _cmd_unpack

    elseif nCmd >= tCltCmdDef[1] and nCmd <= tCltCmdDef[2] then
        tProtoType = CmdNet.bServer and tCltCmdReq or tCltCmdRet 
        tProcType = CltCmdProc
        fnDecoder = _cmd_unpack

    elseif nCmd >= tBsrCmdDef[1] and nCmd <= tBsrCmdDef[2] then
        tProtoType = CmdNet.bServer and tBsrCmdReq or tBsrCmdRet 
        tProcType = BsrCmdProc
        fnDecoder = _cmd_unpack

    else
        _assert(false, "非法指令号"..nCmd)
    end
    local tProto = tProtoType[nCmd]
    if tProto then
        local sCmdName, sProto = tProto[2], tProto[3]
        if CmdNet.bServer then
            LuaTrace("---cmd message---", sCmdName, sProto)
        end
        local fnProc = tProcType[sCmdName]
        if not fnProc then
            if CmdNet.bServer then
                LuaTrace("Cmd:"..nCmd.." proc not define!!!")
            end
            return
        end
        if gbInnerServer then
            xpcall(function() fnProc(nCmd, nSrcServer, nSrcService, nTarSession, fnDecoder(sProto, xPacket)) end
                , function(sErr) 
                    local nKey = nSrcServer << 32 | nTarSession
                    local oPlayer = goPlayerMgr:GetPlayerBySession(nKey)
                    if oPlayer then
                        sErr = string.format("角色ID:%d 账号:%s error:%s", oPlayer:GetCharID(), oPlayer:GetAccount(), sErr)
                    end
                    LuaTrace(sErr, debug.traceback())
                    CPlayer:Tips(sErr, nKey) 
                end)
        else
            fnProc(nCmd, nSrcServer, nSrcService, nTarSession, fnDecoder(sProto, xPacket)) 
        end
    else
        local sTips = "Cmd:"..nCmd.." proto not register!!!"
        LuaTrace(sTips)
        if gbInnerServer then
            CPlayer:Tips(sTips, nSrcServer<<32|nTarSession)
        end
    end

    goCmdMonitor:AddCmd(nCmd, _clock() - nStartTime)
end

-------自定义-------
function CmdNet.Srv2Clt(sCmdName, nTarServer, nTarSession, ...)
    if nTarServer <= 0 or nTarSession <= 0 then
        return
    end
    local tProto = _assert(tCltCmdRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local oPacket = _cmd_pack(sProto, ...)
    _send_exter(nCmd, oPacket, nTarServer, nTarSession>>24, nTarSession, 0)
end

function CmdNet.Clt2Srv(sCmdName, nPacketIdx, nTarSession, ...)
    _assert(nTarSession>0, "参数错误:"..nTarSession)
    local tProto = _assert(tCltCmdReq[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sCmdName, sProto, nService = table.unpack(tProto)
    local oPacket = _cmd_pack(sProto, ...)
    _send_exter(nCmd, oPacket, 0, nService, nTarSession, nPacketIdx)
end

--广播若干客户端tTarSession:{server,session,server,session,...}
function CmdNet.BroadcastExter(sCmdName, tTarSession, ...)
    _assert(#tTarSession>0 and #tTarSession%2==0, "参数错误")
    local tProto = _assert(tCltCmdRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local oPacket = _cmd_pack(sProto, ...)
    _broadcast_exter(nCmd, oPacket, tTarSession)
end

--服务器内部
function CmdNet.Srv2Srv(sCmdName, nTarServer, nTarService, nTarSession, ...)
    _assert(nTarServer>0 and nTarService>0 and nTarSession>=0, "参数错误")
    local tProto = _assert(tSrvSrvCmd[sCmdName], "sCmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local oPacket = _cmd_pack(sProto, ...)
    _send_inner(nCmd, oPacket, nTarServer, nTarService, nTarSession)
end


-------------BSR----------
function CmdNet.Srv2Bsr(sCmdName, nTarServer, nTarSession, ...)
    _assert(nTarServer>0 and nTarSession>0, "参数错误:"..nTarServer..":"..nTarSession)
    local tProto = _assert(tBsrCmdRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local oPacket = _cmd_pack(sProto, ...)
    _send_exter(nCmd, oPacket, nTarServer, nTarSession>>24, nTarSession, 0)
end


-------------PB----------
function CmdNet.PBSrv2Clt(sCmdName, nTarServer, nTarSession, tData) 
    if nTarServer <= 0 or nTarSession <= 0 then
        return
    end
    _assert(nTarServer>0 and nTarSession>0, "参数错误:"..nTarServer..":"..nTarSession)
    local tProto = _assert(tCltPBRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local sData = pbc_encode(sProto, tData)
    local oPacket = _pb_pack(sData)
    _send_exter(nCmd, oPacket, nTarServer, nTarSession>>24, nTarSession, 0)
end

function CmdNet.PBClt2Srv(sCmdName, nPacketIdx, nTarSession, tData) 
    _assert(nTarSession>0, "参数错误:"..nTarSession)
    local tProto = _assert(tCltPBReq[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sCmdName, sProto, nService = table.unpack(tProto)
    local sData = pbc_encode(sProto, tData)
    local oPacket = _pb_pack(sData)
    _send_exter(nCmd, oPacket, 0, nService, nTarSession, nPacketIdx)
end

--广播若干客户端:tTarSession:{server,session,server,session,...}
function CmdNet.PBBroadcastExter(sCmdName, tTarSession, tData)
    _assert(#tTarSession>0 and #tTarSession%2==0, "参数错误")
    local tProto = _assert(tCltPBRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local sData = pbc_encode(sProto, tData)
    local oPacket = _pb_pack(sData)
    _broadcast_exter(nCmd, oPacket, tTarSession)
end

--广播所有客户端
function CmdNet.PBSrv2All(sCmdName, tData) 
    local tProto = _assert(tCltPBRet[sCmdName], "sCmdName '"..sCmdName.."' proto not register")

    --网关服务列表
    local tTarService = {}
    for _, tConf in _pairs(tServerConf.tGateService) do
        _insert(tTarService, {tConf.nServer, tConf.nID, 0})
    end
    if #tTarService <= 0 then
        return
    end

    local nRawCmd, sProto = tProto[1], tProto[3]
    local sData = pbc_encode(sProto, tData)
    local oPacket = _pb_pack(sData)
    local nBroadcastCmd = tSrvSrvCmd["BroadcastGate"][1]
    _broadcast_inner(nBroadcastCmd, nRawCmd, oPacket, tTarService)
end



-----------------------------注册协议相关----------------------------
local function CmdCheck(nCmd, sCmdName, sProto, bReq)
    _assert(nCmd and sCmdName and sProto)
    local tRegType
    if nCmd >= tCltCmdDef[1] and nCmd <= tCltCmdDef[2] then
        tRegType = bReq and tCltCmdReq or tCltCmdRet
    elseif nCmd >= tCltPBCmdDef[1] and nCmd <= tCltPBCmdDef[2] then
        tRegType = bReq and tCltPBReq or tCltPBRet
    elseif (nCmd >= tSrvCmdDef[1] and nCmd <= tSrvCmdDef[2]) or (nCmd >= tSysCmdDef[1] and nCmd <= tSysCmdDef[2]) then
        tRegType = tSrvSrvCmd
    elseif nCmd >= tBsrCmdDef[1] and nCmd <= tBsrCmdDef[2] then
        tRegType = bReq and tBsrCmdReq or tBsrCmdRet
    else
        _assert(false, "非法指令号"..nCmd)
    end
    _assert(not tRegType[nCmd], "命令号重复注册"..nCmd)
    _assert(not tRegType[sCmdName], "命令名重复注册"..sCmdName)
    return tRegType 
end

--注册请求消息
function RegCmdReq(nCmd, sCmdName, sProto, nService)
    nService = nService or 0 
    local tRegType = CmdCheck(nCmd, sCmdName, sProto, true)
    local tCmd = {nCmd, sCmdName, sProto, nService}
    tRegType[nCmd] = tCmd
    tRegType[sCmdName] = tCmd
end
RegPBReq = RegCmdReq
RegBsrCmdReq = RegCmdReq

--注册返回消息
function RegCmdRet(nCmd, sCmdName, sProto, nService)
    nService = nService or 0 
    local tRegType = CmdCheck(nCmd, sCmdName, sProto)
    local tCmd = {nCmd, sCmdName, sProto, nService}
    tRegType[nCmd] = tCmd
    tRegType[sCmdName] = tCmd
end
RegPBRet = RegCmdRet
RegBsrCmdRet = RegCmdRet

--注册服务器间消息
function RegSrvSrvCmd(nCmd, sCmdName, sProto)
    local tRegType = CmdCheck(nCmd, sCmdName, sProto)
    local tCmd = {nCmd, sCmdName, sProto}
    tRegType[nCmd] = tCmd
    tRegType[sCmdName] = tCmd
end

