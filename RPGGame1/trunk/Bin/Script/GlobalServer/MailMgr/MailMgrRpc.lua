function Network.CltPBProc.MailListReq(nCmd, Server, Service, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
    if not oRole then return end
    goMailMgr:MailListReq(oRole)
end

function Network.CltPBProc.MailBodyReq(nCmd, Server, Service, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
    if not oRole then return end
    goMailMgr:MailBodyReq(oRole, tData.nMailID)
end

function Network.CltPBProc.DelMailReq(nCmd, Server, Service, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
    if not oRole then return end
    goMailMgr:DelMailReq(oRole, tData.nMailID)
end

function Network.CltPBProc.MailItemsReq(nCmd, Server, Service, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(Server, nSession)
    if not oRole then return end
    goMailMgr:MailItemsReq(oRole, tData.nMailID)
end


--------服务器内部
function Network.RpcSrv2Srv.SendMailReq(nSrcServer, nSrcService, nTarSession, sTitle, sContent, tItemList, nTarRoleID)
    return goMailMgr:SendMail(sTitle, sContent, tItemList, nTarRoleID)
end

--获取小于Max邮件的数量
function Network.RpcSrv2Srv.GetLaveMailNumReq(nSrcServer, nSrcService, nTarSession, nTarRoleID)
    return goMailMgr:GetLaveMailNum(nTarRoleID)
end