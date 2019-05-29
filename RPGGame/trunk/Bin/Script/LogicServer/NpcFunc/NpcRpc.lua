--天帝宝物 访问NpcGoldBox
function CltPBProc.OpenGoldBoxReq(nCmd, nServer, Srevice, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oNpc = goNpcMgr:GetNpc(tData.nNpcID)
    if not oNpc then
        return oRole:Tips("NPC不存在")
    end

    oNpc:OpenGoldBox(oRole, tData.nOpenTimes, tData.bUseGold)
end

function CltPBProc.FuYuanExchangeReq(nCmd, nServer, Srevice, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end

    local oNpc = goNpcMgr:GetNpc(tData.nNpcID)
    if not oNpc then
        return oRole:Tips("NPC不存在")
    end

    oNpc:FuYuanExchangeReq(oRole, tData.nExchangeID)
end


function CltPBProc.GoldBoxReq(nCmd, nServer, Srevice, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    local oNpc = goNpcMgr:GetNpc(tData.nNpcID)
    if not oNpc then
        return oRole:Tips("NPC不存在")
    end

    oNpc:GoldBoxReq(oRole)
end