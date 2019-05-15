--物品信息查询
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


--道具查询
function CltPBProc.ItemQueryReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goItemQueryMgr:QueryReq(oRole:GetID(), tData.nRoleID, 
        tData.nItemType, tData.nKey, tData.nMsgStamp)
end


--角色基本信息查询
function CltPBProc.RoleInfoQueryReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
    if not oRole then return end
    goItemQueryMgr:RoleInfoQueryReq(oRole:GetID(), tData.nRoleID, tData.nTimeStamp)
end

