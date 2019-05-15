--客户端->服务器
function CltPBProc.ShiMenTaskReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    
    local oNpc = goNpcMgr:GetNpc(tData.nNpcID)
    if not oNpc then
        return oRole:Tips("NPC不存在")
    end
    oNpc:Trigger(oRole, CNpcTalk.tNpcType.eShiMenTask, tData)
end

