--客户端->服务器
function CltPBProc.EverydayGiftInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oEverydayGift:EverydayGiftInfoReq()
end

function CltPBProc.EverydayGiftGetReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oEverydayGift:GetEverydayGiftReq(tData.nMoney)
end
function CltPBProc.EverydayGiftSeleReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oEverydayGift:SelectGift(tData.nMoney, tData.nGiftID)
end