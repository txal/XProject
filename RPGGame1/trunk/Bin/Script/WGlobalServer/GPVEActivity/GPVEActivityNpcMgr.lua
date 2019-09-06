--PVE活动NPC管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGPVEActivityNpcMgr:Ctor()

end

function CGPVEActivityNpcMgr:GetPVEActivityService(nActID)
    tSceneConf = ctDupConf[10400] 
    assert(tSceneConf)
    return tSceneConf.nLogic
end

function CGPVEActivityNpcMgr:Online(oRole) 
    local fnCheckCallback = function(bOpen, tAct) 
        if not bOpen then 
            return 
        end
        local tNpcList = {}
        for _, tActData in ipairs(tAct or {}) do
            tNpcList[#tNpcList+1] = tActData.nNpcID
        end
        local tMsg = {}
        tMsg.nType = 1
        tMsg.tNpcList = tNpcList
        oRole:SendMsg("PVPActivityNpcRet", tMsg)
        print(string.format("玩家上线，通知创建活动(%d) NPC(%d)", tAct[1].nACtivivtyId, tAct[1].nNpcID))
    end

    local nService = self:GetPVEActivityService()
    Network:RMCall("PVEActivityCheckStatusReq", fnCheckCallback, oRole:GetServer(), nService, 0)
end

function CGPVEActivityNpcMgr:BroadcastNpcMsg(tMsg, nServer) 
    Network.PBSrv2All("PVPActivityNpcRet", tMsg)
end

--通知活动NPC需要创建
function CGPVEActivityNpcMgr:OnActivityOpen(nActID, nNpcID, nServer)
    local tMsg = {}
    tMsg.nType = 1
    tMsg.tNpcList = {nNpcID}
    print(string.format("广播通知创建活动(%d) NPC(%d)", nActID, nNpcID))
    self:BroadcastNpcMsg(tMsg, nServer)
end

--通知活动NPC需要销毁
function CGPVEActivityNpcMgr:OnActivityClose(nActID, nNpcID, nServer)
    local tMsg = {}
    tMsg.nType = 2
    tMsg.tNpcList = {nNpcID}
    print(string.format("广播通知销毁活动(%d) NPC(%d)", nActID, nNpcID))
    self:BroadcastNpcMsg(tMsg, nServer)
end
