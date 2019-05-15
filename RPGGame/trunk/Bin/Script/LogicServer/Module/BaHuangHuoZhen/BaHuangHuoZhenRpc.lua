function CltPBProc.BaHuangHuoZhenPackingReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaHuangHuoZhen:PackingReq(tData.nBoxID, tData.tItemList)
end

function CltPBProc.BaHuangHuoZhenReceiveReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaHuangHuoZhen:ReceiveReq()
end


function CltPBProc.BaHuangHuoZhenBoxHelpReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaHuangHuoZhen:BoxHelpReq(tData.nBoxID)
end

function CltPBProc.BahuanghuozhenHelpPackingBoxReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaHuangHuoZhen:HelpPackingBoxReq( tData.nRoleID, tData.nBoxID, tData.tItemList)
end

function CltPBProc.BaHuangHuoZhenHelpPlayerBoxListReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaHuangHuoZhen:HelpPlayerBoxListReq( tData.nRoleID, tData.nBoxID)
end

function CltPBProc.BaHuangHuoZhenBoxListReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaHuangHuoZhen:BoxListReq()
end

function CltPBProc.BaHuangHuoZhenPickupTaskReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaHuangHuoZhen:PickupTaskReq()
end

function CltPBProc.BaHuangHuoZhenInfoTaskReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oBaHuangHuoZhen:TaskInfoReq(tData.nType)
end

--获取玩家八荒任务数据
function Srv2Srv.GetHelpRoleDataReq(nSrcServer, nSrcService, nTarSession, nRoleID,nHeleRoleID, nBoxID)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then
        local sTips = "玩家已经下线了哦"
        return sTips, {}
    end
    return oRole.m_oBaHuangHuoZhen:GetHelpRoleData(nRoleID, nHeleRoleID,nBoxID)
end

--帮助帮派好友装箱
function Srv2Srv.BaHuangHuoZhenHelpPackingBoxCheckReq(nSrcServer, nSrcService, nTarSession, nRoleID, nBoxID)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if oRole then
        return oRole.m_oBaHuangHuoZhen:HelpPackingBoxCheck(nRoleID, nBoxID)
    end
end

function Srv2Srv.HelpPackingBoxCheckHandleReq(nSrcServer, nSrcService, nTarSession, nRoleID, nHeleRoleID, nBoxID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    return oRole.m_oBaHuangHuoZhen:HelpPackingBoxCheckHandle(nHeleRoleID,nBoxID,tData)
end

function Srv2Srv.BaHuangHuoZhenSubItemReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local bRet = oRole.m_oBaHuangHuoZhen:SubItemCheck(tData.nID, tData.nNum)
    if bRet then
        oRole.m_oBaHuangHuoZhen:SetHasHelpTimes(1)
    end
    local tTempData = {}
    tTempData.sName = oRole:GetName()
    tTempData.nHelpTimes = oRole.m_oBaHuangHuoZhen:GetHasHelpTimes()
    tTempData.nServerID = oRole:GetServer()
    tTempData.nRoleID = oRole:GetID()
    tTempData.nDefauID = oRole.m_oPractice:GetDefauID()
    return bRet, tTempData
end
