------客户端服务器
function CltPBProc.RoleInfoReq(nCmd, nServer, nService, nSession, tData)
    local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole:RoleInfoReq(tData.nTarRoleID)
end

------服务器内部------
--角色上线通知
function Srv2Srv.GRoleOnlineReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
	goGPlayerMgr:RoleOnlineReq(nRoleID, tData)
end

--角色下线通知
function Srv2Srv.GRoleOfflineReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
	goGPlayerMgr:RoleOfflineReq(nRoleID, tData)
end

--角色属性更新通知
function Srv2Srv.GRoleUpdateReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
    goGPlayerMgr:RoleUpdateReq(nRoleID, tData)
end

--战斗结束
-- function Srv2Srv.OnBattleEndReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
-- 	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
-- 	if not oRole then return end
-- 	oRole:OnBattleEnd(tData)
-- end

--系统开启
function Srv2Srv.OnSysOpenReq(nSrcServer, nSrcService, nTarSession, nRoleID, nSysID, tSysData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:OnSysOpen(nSysID, tSysData)
end

--系统开启批量通知
function Srv2Srv.OnSysOpenListReq(nSrcServer, nSrcService, nTarSession, nRoleID, tSysOpenList)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	for nSysID, tSysData in pairs(tSysOpenList) do 
		oRole:OnSysOpen(nSysID, tSysData)
	end
end

--系统关闭
function Srv2Srv.OnSysCloseReq(nSrcServer, nSrcService, nTarSession, nRoleID, nSysID, tSysData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:OnSysClose(nSysID, tSysData)
end

--增加帮贡
function Srv2Srv.AddUnionContriReq(nSrcServer, nSrcService, nTarSession, nRoleID, nItemNum, sReason)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:AddUnionContri(nItemNum, sReason)
end

--增加帮派经验
function Srv2Srv.AddUnionExpReq(nSrcServer, nSrcService, nTarSession, nRoleID, nItemNum, sReason)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:AddUnionExp(nItemNum, sReason)
end

--状态变化
function Srv2Srv.GRoleActStateUpdateReq(nSrcServer, nSrcService, nTarSession, nRoleID, nState)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:SetActState(nState)
end

--活跃值变化
function Srv2Srv.GRoleActiveNumChangeReq(nSrcServer, nSrcService, nTarSession, nRoleID, nVal)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:OnActiveNumChange(nVal)
end

function Srv2Srv.KejuAnswerHelpQuestionReq(nSrcServer,nSrcService,nTarSession,nRoleID,tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:KejuAnswerHelpQuestionReq(tData)
end

function Srv2Srv.KejuHelpQuestionDataReq(nSrcServer,nSrcService,nTarSession,nRoleID,tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local nTarRoleID = tData.nRoleID
	local nQuestionID = tData.nQuestionID
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTarRole then return end
	oTarRole:KejuHelpQuestionDataReq(oRole,nQuestionID)
end

function Srv2Srv.AppellationUpdateReq(nSrcServer, nSrcService, nTarSession, nRoleID, tData)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:AppellationUpdate(tData)
end

function Srv2Srv.GetHelpRoleDataReq(nSrcServer, nSrcService, nTarSession, nRoleID, nHelpRoleID,nBoxID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oTarRole = goGPlayerMgr:GetRoleByID(nHelpRoleID)
	if not oTarRole then return end
	oTarRole:BaHuangHuoZhenTaskInfoReq(oRole, nBoxID)
end

function Srv2Srv.HelpPackingBoxReq(nSrcServer, nSrcService, nTarSession, nRoleID, nHelpRoleID,nBoxID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oTarRole = goGPlayerMgr:GetRoleByID(nHelpRoleID)
	if not oTarRole then return end
	oTarRole:BaHuangHuoZhenHelpPackingBoxReq(oRole, nBoxID)
end

function Srv2Srv.PushHelpRoleBoxReq(nSrcServer, nSrcService, nTarSession, nRoleID, nHelpRoleID,tMsg, sReason)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local oTarRole = goGPlayerMgr:GetRoleByID(nHelpRoleID)
	if not oTarRole then return end
	oRole:BaHuangHuoZhenPushHelpRoleBoxReq(oTarRole, tMsg, sReason)
end

function Srv2Srv.AccountRoleDeleteNotify(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID)
	return goGPlayerMgr:AccountRoleDeleteNotify(nAccountID, nRoleID)
end

function Srv2Srv.OnRoleRechargeSuccess(nSrcServer, nSrcService, nTarSession, nRoleID, nID, nMoney, nYuanBao, nBYuanBao, nTime)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then 
		LuaTrace(string.format("没有找到玩家(%d), 充值nID(%d), nMoney(%d), nYuanBao(%d), nBYuanBao(%d), nTime(%d)", 
			nRoleID, nID, nMoney, nYuanBao, nBYuanBao, nTime))
		return 
	end
	oRole:OnRechargeSuccess(nID, nMoney, nYuanBao, nBYuanBao, nTime)
end

--@bBind 是否绑定元宝
function Srv2Srv.OnRoleYuanBaoChange(nSrcServer, nSrcService, nTarSession, nRoleID, nYuanBao, bBind)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	oRole:OnYuanBaoChange(nYuanBao, bBind)
end

function Srv2Srv.AsyncEnterScene(nSrcServer, nSrcService, nTarSession, nRoleID)
	print(string.format("角色(%d) 异步进入场景事件", nRoleID))
	return true
end

