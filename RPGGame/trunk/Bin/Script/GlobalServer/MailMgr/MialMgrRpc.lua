function CltPBProc.MailListReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMailMgr:MailListReq(oRole)
end

function CltPBProc.MailBodyReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMailMgr:MailBodyReq(oRole, tData.nMailID)
end

function CltPBProc.DelMailReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMailMgr:DelMailReq(oRole, tData.nMailID)
end

function CltPBProc.MailItemsReq(nCmd, nSrc, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMailMgr:MailItemsReq(oRole, tData.nMailID)
end
