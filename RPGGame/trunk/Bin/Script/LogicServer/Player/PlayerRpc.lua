--角色信息请求
function CltPBProc.RoleInfoReq(nCmd, nSrcServer, nSrcService, nTarSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nSrcServer, nTarSession)
	if not oRole then return end

	local tInfo = {}
    CmdNet.PBSrv2Clt("RoleInfoRet", SrcServer, nTarSession, {tInfo=tInfo})
end

---------------服务器内部----------------
--更新角色摘要数据(登录服务)
function Srv2Srv.UpdateRoleSummaryReq(nSrcServer, nSrcService, nTarSession, nAccountID)
	goPlayerMgr:UpdateRoleSummaryReq(nAccountID)
end

--角色上线通知(登录服务)
function Srv2Srv.RoleOnlineReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID)
	goPlayerMgr:OnlineReq(nSrcServer, nTarSession, nAccountID, nRoleID)
end

--角色下线通知(登录服务)
function Srv2Srv.RoleOfflineReq(nSrcServer, nSrcService, nTarSession, nAccountID)
	goPlayerMgr:OfflineReq(nAccountID)
end

--道具数量请求(GLOBAL服务)
function Srv2Srv.RoleGetItemReq(nSrcServer, nSrcService, nTarSession, nAccountID)
end

--道具数量增减(GLOBAL服务)
function Srv2Srv.RoleAddItemReq(nSrcServer, nSrcService, nTarSession, nAccountID)
end
