--PVP活动NPC管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGPVPActivityNpcMgr:Ctor()
    -- body
end

function CGPVPActivityNpcMgr:GetPVPActivityService(nActID)
    local tConf = ctPVPActivityConf[nActID]
    assert(tConf, "配置不存在")
    --首席争霸默认全部在一个逻辑服上，暂时不考虑跨多个逻辑服情况
    tSceneConf = ctDupConf[tConf.tSceneID[1][1]] 
    assert(tSceneConf)
    return tSceneConf.nLogic
end

function CGPVPActivityNpcMgr:Online(oRole) 
    local fnCheckCallback = function(bOpen, nActID) 
        if not bOpen then 
            return 
        end
        local tConf = ctPVPActivityConf[nActID]
        assert(tConf)
        local nNpcID = tConf.nNpcID

        local tMsg = {}
        tMsg.nType = 1
        tMsg.tNpcList = {nNpcID}
        oRole:SendMsg("PVPActivityNpcRet", tMsg)
        print(string.format("玩家上线，通知创建活动(%d) NPC(%d)", nActID, nNpcID or 0))
    end

    for nPVPActID, tConf in pairs(ctPVPActivityConf) do 
        local nService = self:GetPVPActivityService(nPVPActID)
        goRemoteCall:CallWait("PVPActivityCheckStatusReq", fnCheckCallback, 
            oRole:GetServer(), nService, 0, nPVPActID)
    end
end

function CGPVPActivityNpcMgr:BroadcastNpcMsg(tMsg, nServer) 
    --如果nServer是世界服ID，则全区通知，否则nServer全服通知
    if nServer >= 10000 then 
        CmdNet.PBSrv2All("PVPActivityNpcRet", tMsg)
    else
        CmdNet.PBSrv2Srv(nServer, "PVPActivityNpcRet", tMsg)
    end
end

--通知活动NPC需要创建
function CGPVPActivityNpcMgr:OnActivityOpen(nActID, nServer)
    local tConf = ctPVPActivityConf[nActID]
    assert(tConf)
    local nNpcID = tConf.nNpcID

    local tMsg = {}
    tMsg.nType = 1
    tMsg.tNpcList = {nNpcID}
    print(string.format("广播通知创建活动(%d) NPC(%d)", nActID, nNpcID or 0))
    self:BroadcastNpcMsg(tMsg, nServer)
end

--通知活动NPC需要销毁
function CGPVPActivityNpcMgr:OnActivityClose(nActID, nServer) 
    local tConf = ctPVPActivityConf[nActID]
    assert(tConf)
    local nNpcID = tConf.nNpcID

    local tMsg = {}
    tMsg.nType = 2
    tMsg.tNpcList = {nNpcID}
    print(string.format("广播通知销毁活动(%d) NPC(%d)", nActID, nNpcID or 0))
    self:BroadcastNpcMsg(tMsg, nServer)
end


goGPVPActivityNpcMgr = goGPVPActivityNpcMgr or CGPVPActivityNpcMgr:new()

