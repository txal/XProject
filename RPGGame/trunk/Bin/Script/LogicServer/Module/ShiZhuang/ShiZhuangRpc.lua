--客户端->服务器
function CltPBProc.ShiZhuangAllInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:AllInfoReq()
end

function CltPBProc.ShiZhuangPutOnReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:PutOnReq(tData.nPosType, tData.nShiZhuangID)
end

function CltPBProc.ShiZhuangPutOffReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:PutOff(tData.nPosType)
end

function CltPBProc.ShiZhuangWashReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:WashReq(tData.nShiZhuangID, tData.bIsUseGold)
end

function CltPBProc.ShiZhuangAttrReplaceReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:AttrReplaceReq(tData.nShiZhuangID)
end

function CltPBProc.QiLingUpGradeReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:QiLingUpGrade()
end

function CltPBProc.QiLingAllInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:QiLingInfoReq()
end

function CltPBProc.ShiZhuangActReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:ShiZhuangActReq(tData.nShiZhuangID)
end
function CltPBProc.QiLingAutoUpLevelReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:QiLingAutoUpLevel()
end

function CltPBProc.ShiZhuangYuQiInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:SyncYuQiData()
end

function CltPBProc.ShiZhuangYuQiLevelUpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:YuQiLevelUpReq()
end

function CltPBProc.ShiZhuangXianYuInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:SyncXianYuData()
end

function CltPBProc.ShiZhuangXianYuLevelUpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:XianYuLevelUpReq()
end

function CltPBProc.ShiZhuangStrengthReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oShiZhuang:StrengthLevelUpReq(tData.nID, tData.nPropID, tData.nPropNum)
end
