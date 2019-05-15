--------服务器内部
-- function Srv2Srv.SendMailReq(nSrcServer, nSrcService, nTarSession, sTitle, sContent, tItemList, nTarRoleID)
--     return goMailMgr:SendMail(sTitle, sContent, tItemList, nTarRoleID)
-- end

--怪物战斗结束刷新请求通知
function Srv2Srv.UpdateMonsterReq(nSrcServer, nSrcService, nTarSession, nRoleID, nYaoShouID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return  goYaoShouTuXiMgr:UpdateMonster(nYaoShouID)
end

--获取妖兽的战斗状态
function Srv2Srv.GetYaoShouBattleStatus(nSrcServer, nSrcService, nTarSession, nRoleID, nYaoShouID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	 return goYaoShouTuXiMgr:GetYaoShouBattleStatus(nYaoShouID)
end

--设置妖兽战斗状态
function Srv2Srv.SetYaoShouBattleStatusReq(nSrcServer, nSrcService, nTarSession, nRoleID, nYaoShouID, bStatus)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oYaoShou = goYaoShouTuXiMgr:GetYaoShou(nYaoShouID)
	oYaoShou:SetBattleStatus(bStatus)
end

--获取妖兽信息
function Srv2Srv.GetYaoShouInfoReq(nSrcServer, nSrcService, nTarSession, nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	return goYaoShouTuXiMgr:GetYaoShouInfo()
end