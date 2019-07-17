--离开副本
function Network.CltPBProc.LeaveBattleDupReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goBattleDupMgr:LeaveBattleDupReq(oRole)
end


------服务器内部
--创建战斗副本请求[LOGIC]
function Network.RpcSrv2Srv.WCreateBatteDupReq(nSrcServer, nSrcService, nTarSession, nType)
	return goBattleDupMgr:CreateBattleDup(nType, nil, true)
end

--队长活跃信息同步[WGLBOAL]
function Network.RpcSrv2Srv.TeamLeaderActivityRet(nSrcServer, nSrcService, nTarSession, nRoleID, nInactivityTime)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oDup = oRole:GetCurrDupObj()
	if oDup then
		local tDupConf = oDup:GetConf()
		if tDupConf.nBattleType > 0 then
			oDup:OnLeaderActivity(oRole, nInactivityTime)
		end
	end
end

--GM开启,关闭调用[WGLBOAL]
function Network.RpcSrv2Srv.DestroyAssignTypeBattleDupReq(nSrcServer, nSrcService, nTarSession, nType)
	return goBattleDupMgr:DestroyAssignTypeBattleDup(nType)
end
