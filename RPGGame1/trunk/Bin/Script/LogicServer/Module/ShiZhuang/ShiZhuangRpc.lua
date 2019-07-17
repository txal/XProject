--客户端->服务器
function Network.CltPBProc.ShiZhuangAllInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:AllInfoReq()
end

function Network.CltPBProc.ShiZhuangPutOnReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:PutOnReq(tData.nPosType, tData.nShiZhuangID)
end

function Network.CltPBProc.ShiZhuangPutOffReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:PutOff(tData.nPosType)
end

function Network.CltPBProc.ShiZhuangWashReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:WashReq(tData.nShiZhuangID, tData.bIsUseGold)
end

function Network.CltPBProc.ShiZhuangAttrReplaceReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:AttrReplaceReq(tData.nShiZhuangID)
end

function Network.CltPBProc.QiLingUpGradeReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:QiLingUpGrade()
end

function Network.CltPBProc.QiLingAllInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:QiLingInfoReq()
end

function Network.CltPBProc.ShiZhuangActReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:ShiZhuangActReq(tData.nShiZhuangID)
end
function Network.CltPBProc.QiLingAutoUpLevelReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:QiLingAutoUpLevel()
end

function Network.CltPBProc.ShiZhuangYuQiInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:SyncYuQiData()
end

function Network.CltPBProc.ShiZhuangYuQiLevelUpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:YuQiLevelUpReq()
end

function Network.CltPBProc.ShiZhuangXianYuInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:SyncXianYuData()
end

function Network.CltPBProc.ShiZhuangXianYuLevelUpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:XianYuLevelUpReq()
end

function Network.CltPBProc.ShiZhuangStrengthReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:StrengthLevelUpReq(tData.nID, tData.nPropID, tData.nPropNum)
end
