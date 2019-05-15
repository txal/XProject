--多重确认框
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CltPBProc.MultiConfirmBoxReactReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
    local oRole = nil 
    if goGPlayerMgr then
		oRole = goGPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	else
		oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	end
    if not oRole then return end
    local nServiceID = tData.nService
    if nServiceID <= 0 then
    	return
    end
    if GF.GetServiceID() == nServiceID then
    	goMultiConfirmBoxMgr:RoleConfirmReactReq(tData.nConfirmBoxID, oRole:GetID(), tData.nSerialID, tData.nSelButton)
    else
		goRemoteCall:Call("MultiConfirmBoxReactReq", oRole:GetServer(), nServiceID, oRole:GetSession(), oRole:GetID(), tData)
    end
end


function Srv2Srv.MultiConfirmBoxReactReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    if not goMultiConfirmBoxMgr:IsInit() then --非法路由服务，客户端非法service参数引起的，不予处理
    	return
    end
    local oRole = nil
    if goGPlayerMgr then
		oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	else
		oRole = goPlayerMgr:GetRoleByID(nRoleID)
	end
    if not oRole then return end --一般逻辑服上发生，玩家在对话期间，切换了逻辑服，不予处理
    goMultiConfirmBoxMgr:RoleConfirmReactReq(tData.nConfirmBoxID, nRoleID, tData.nSerialID, tData.nSelButton)
end

