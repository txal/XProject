--客户端->服务器
function CltPBProc.ShiLianTaskAccepReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiLianTask:TaskAccepReq()
end

function CltPBProc.ShiLianTaskCommitReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiLianTask:TaskCommitReq(tData.nNpcID, tData.nItemID, tData.nCommitNum, tData.nGridID, tData.bUseJinBi)
end