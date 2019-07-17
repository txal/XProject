------客户端服务器
function Network.CltPBProc.GiftPropReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goCGiftMgr:GiftPropReq(oRole, tData.nTarRoleID, tData.tItemList, tData.nType)
end

function Network.CltPBProc.GiftGetRecordInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goCGiftMgr:GiftGetRecordInfoReq(oRole)
end

function Network.CltPBProc.GiftGetSendNumReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    goCGiftMgr:GiftGetSendNumReq(oRole, tData.nRoleID)
end

