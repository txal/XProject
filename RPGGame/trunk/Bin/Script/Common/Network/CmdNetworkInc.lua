protobuf = require("Common/Network/protobuf")
parser = require("Common/Network/parser")

local _clock = os.clock
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
CmdMessageCenter = function(nCmd, nSrc, nSession, xPacket)
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
        assert(false, "非法指令号"..nCmd)
    end
    local tProto = tProtoType[nCmd]
    if tProto then
        local sCmdName, sProto = tProto[2], tProto[3]
        if CmdNet.bServer then
            LuaTrace("---message---", sCmdName, sProto)
        end
        local fnProc = tProcType[sCmdName]
        if not fnProc then
            if CmdNet.bServer then
                LuaTrace("Cmd:"..nCmd.." proc not define!!!")
            end
            return
        end
        if gbInnerServer then
            xpcall(function() fnProc(nCmd, nSrc, nSession, fnDecoder(sProto, xPacket)) end
                , function(sErr) 
                    local oPlayer = goPlayerMgr:GetPlayerBySession(nSession)
                    if oPlayer then
                        sErr = string.format("角色ID:%d 账号:%s error:%s", oPlayer:GetCharID(), oPlayer:GetAccount(), sErr)
                    end
                    LuaTrace(sErr)
                    LuaTrace(debug.traceback())
                    CPlayer:Tips(sErr, nSession) 
                end)
        else
            fnProc(nCmd, nSrc, nSession, fnDecoder(sProto, xPacket)) 
        end
    else
        local sTips = "Cmd:"..nCmd.." proto not register!!!"
        LuaTrace(sTips)
        if gbInnerServer then
            CPlayer:Tips(sTips, nSession)
        end
    end

    goCmdMonitor:AddCmd(nCmd, _clock() - nStartTime)
end

-------自定义-------
function CmdNet.Srv2Clt(nSessionID, sCmdName, ...)
    if nSessionID <= 0 then
        return
    end
    local tProto = assert(tCltCmdRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local oPacket = _cmd_pack(sProto, ...)
    _send_exter(nCmd, oPacket, nSessionID>>24, nSessionID)
end

function CmdNet.Clt2Srv(nPacketIdx, nSessionID, sCmdName, ...)
    if nSessionID <= 0 then
        return
    end
    local tProto = assert(tCltCmdReq[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sCmdName, sProto, nService = table.unpack(tProto)
    local oPacket = _cmd_pack(sProto, ...)
    _send_exter(nCmd, oPacket, nService, nSessionID, nPacketIdx)
end

--广播若干客户端
function CmdNet.BroadcastExter(tSessionID, sCmdName, ...)
    if #tSessionID <= 0 then
        return
    end
    local tProto = assert(tCltCmdRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local oPacket = _cmd_pack(sProto, ...)
    _broadcast_exter(nCmd, oPacket, tSessionID)
end

--服务器到服务器
function CmdNet.Srv2Srv(sCmdName, nToService, nToSession, ...)
    local tProto = assert(tSrvSrvCmd[sCmdName], "sCmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local oPacket = _cmd_pack(sProto, ...)
    _send_inner(nCmd, oPacket, nToService, nToSession)
end


-------------Bsr----------
function CmdNet.Srv2Bsr(nSessionID, sCmdName, ...)
    if nSessionID <= 0 then
        return
    end
    local tProto = assert(tBsrCmdRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local oPacket = _cmd_pack(sProto, ...)
    _send_exter(nCmd, oPacket, nSessionID>>24, nSessionID)
end


-------------PB----------
function CmdNet.PBSrv2Clt(nSessionID, sCmdName, tData) 
    if nSessionID <= 0 then
        return
    end
    local tProto = assert(tCltPBRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local sData = pbc_encode(sProto, tData)
    local oPacket = _pb_pack(sData)
    _send_exter(nCmd, oPacket, nSessionID>>24, nSessionID)
end

function CmdNet.PBClt2Srv(nPacketIdx, nSessionID, sCmdName, tData) 
    if nSessionID <= 0 then
        return
    end
    local tProto = assert(tCltPBReq[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sCmdName, sProto, nService = table.unpack(tProto)
    local sData = pbc_encode(sProto, tData)
    local oPacket = _pb_pack(sData)
    _send_exter(nCmd, oPacket, nService, nSessionID, nPacketIdx)
end

--广播若干客户端
function CmdNet.PBBroadcastExter(tSessionID, sCmdName, tData)
    if #tSessionID <= 0 then
        return
    end
    local tProto = assert(tCltPBRet[sCmdName], "CmdName '"..sCmdName.."' proto not register")
    local nCmd, sProto = tProto[1], tProto[3]
    local sData = pbc_encode(sProto, tData)
    local oPacket = _pb_pack(sData)
    _broadcast_exter(nCmd, oPacket, tSessionID)
end

--广播所有客户端
function CmdNet.PBSrv2All(sCmdName, tData) 
    local tProto = assert(tCltPBRet[sCmdName], "sCmdName '"..sCmdName.."' proto not register")
    local tService = {}
    for nService, tConf in pairs(gtNetConf.tGateService) do
        table.insert(tService, nService)
    end
    if #tService <= 0 then
        return
    end
    local nRawCmd, sProto = tProto[1], tProto[3]
    local sData = pbc_encode(sProto, tData)
    local oPacket = _pb_pack(sData)
    local nBroadcastCmd = tSrvSrvCmd["BroadcastGate"][1]
    _broadcast_inner(nBroadcastCmd, nRawCmd, oPacket, tService)
end



-----------------------------注册协议相关----------------------------
local function CmdCheck(nCmd, sCmdName, sProto, bReq)
    assert(nCmd and sCmdName and sProto)
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
        assert(false, "非法指令号"..nCmd)
    end
    assert(not tRegType[nCmd], "命令号重复注册"..nCmd)
    assert(not tRegType[sCmdName], "命令名重复注册"..sCmdName)
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

