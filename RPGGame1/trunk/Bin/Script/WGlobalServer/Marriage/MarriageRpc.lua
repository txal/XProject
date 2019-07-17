--婚姻系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--请求玩家婚姻数据
function Network.CltPBProc.RoleMarriageDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:MarriageDataReq(oRole)
end

--结婚离婚操作数据请求
function Network.CltPBProc.MarriageActionDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:MarriageActionDataReq(oRole)
end

--玩家结婚条件检查请求
function Network.CltPBProc.MarryPermitDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:MarryPermitDataReq(oRole, tData.nTarRoleID)
end

--离婚条件检查请求
function Network.CltPBProc.DivorcePermitDataReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:DivorcePermitDataReq(oRole)
end

--离婚请求
function Network.CltPBProc.MarriageDivorceReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:DivorceReq(oRole)
end

--取消离婚请求
function Network.CltPBProc.MarriageDivorceCancelReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:DivorceCancelReq(oRole)
end

--赠送贺礼请求
function Network.CltPBProc.MarriageGiftSendReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:SendMarriageBlessGift(oRole, tData.nRoleID, tData.nCoupleID, tData.nGiftLevel)
end

--结婚询问条件检查请求
function Network.CltPBProc.MarriageAskCheckReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:MarriageAskCheckReq(oRole, tData.nTarRoleID)
end

--发起结婚询问请求
function Network.CltPBProc.MarriageAskReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goMarriageMgr:MarriageAskReq(oRole, tData.nTarRoleID)
end


------------------ Svr2Svr --------------------
function Network.RpcSrv2Srv.MarriageWeddingReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTarID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    local bCanMarry, tCheckList = goMarriageMgr:CheckMarry(nRoleID, nTarID)
    local bLover = false
    if bCanMarry then 
        bLover = goLoverRelationMgr:IsLover(nRoleID, nTarID)
    end
	return bCanMarry, bLover
end

function Network.RpcSrv2Srv.MarriageMarryReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTarID)
    return goMarriageMgr:Marry(nRoleID, nTarID)
end


function Network.RpcSrv2Srv.MarriageCheckPalanquinRentReq(nSrcServer, nSrcService, nTarSession, nRoleID, nTarID)
    local bCanRent, sContent, tCouple = goMarriageMgr:CheckPalanquinRent(nRoleID)
    return bCanRent, sContent, tCouple
end

--同步婚姻数据到逻辑服
function Network.RpcSrv2Srv.SyncMarriageCacheReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
    if not oRole then return end
    goMarriageMgr:SyncLogicCache(nRoleID, nSrcServer, nSrcService, nTarSession)
end

--花轿游览开始
function Network.RpcSrv2Srv.MarriagePalanquinStartNoticeReq(nSrcServer, nSrcService, nTarSession, nRoleID)
    goMarriageMgr:PalanquinStartNotice(nRoleID)
end

