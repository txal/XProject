--客户端->服务器

function CltPBProc.OpenKejuDataReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oKeju:OpenKeJu(tData.nKejuType)
end

function CltPBProc.AnswerKejuQuestionReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oKeju:AnswerQuestion(tData.nQuestionID,tData.nAnswerNo)
end

function CltPBProc.CloseKejuQuestion(nCmd, nServer, nService, nSession, tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer, nSession)
    if not oRole then return end
    oRole.m_oKeju:CloseKeJu(tData.nKejuType)
end

function CltPBProc.KejuAskHelpReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKeju:KejuAskHelp(tData.nQuestionID)
end

function CltPBProc.KejuAnswerHelpQuestionReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	local nAskerID = tData.nAskerID
	local nServerID = oRole:GetServer()
	local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
	local tHelpData = {
		nAnswerID = oRole:GetID(),
		sAnswerName = oRole:GetName(),
		nQuestionID = tData.nQuestionID,
		nAnswerNo = tData.nAnswerNo,
	}
	goRemoteCall:Call("KejuAnswerHelpQuestionReq",nServerID,nServiceID,0,nAskerID,tHelpData)
	--[[
	local nAskerID = tData.nAskerID
	local oAskRole = goPlayerMgr:GetRoleByID(nAskerID)
	if oAskRole then
		local nQuestionID = tData.nQuestionID
		local nAnswerNo = tData.nAnswerNo
		local nHelpRoleID = oRole:GetID()
		local sRoleName = oRole:GetName()
		oAskRole.m_oKeju:KejuAnswerHelpQuestion(nHelpRoleID,sRoleName,nQuestionID,nAnswerNo)
	end
	]]
end

function CltPBProc.KejuAskHelpDataReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end
	oRole.m_oKeju:KejuAskHelpData(tData.nQuestionID)
end

function CltPBProc.KejuHelpQuestionDataReq(nCmd,nServer,nService,nSession,tData)
	local oRole = goPlayerMgr:GetRoleBySS(nServer,nSession)
	if not oRole then return end

	local nServerID = oRole:GetServer()
	local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
	local nRoleID = oRole:GetID()
	goRemoteCall:Call("KejuHelpQuestionDataReq",nServerID,nServiceID,0,nRoleID,tData)
	--[[
	local nTarRoleID = tData.nRoleID
	local nQuestionID = tData.nQuestionID
	local oTargetRole = goPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTargetRole then return end
	oTargetRole.m_oKeju:KejuHelpQuestionDataReq(oRole,nQuestionID)
	]]
end

-----------------------服务器内部--------------------------
function Srv2Srv.JoinKejuDianshi(nSrcServer,nSrcService,nTarSession,tJoinPlayer)
    tJoinPlayer = tJoinPlayer or {}
    for nRoleID,_ in pairs(tJoinPlayer) do
        local oRole = goPlayerMgr:GetRoleByID(nRoleID)
        if oRole then
        	oRole.m_oTimeData.m_oToday:Add("JoinDianShi",1)
        	oRole.m_oTimeData.m_oToday:Add("JoinDianshiCnt",1)
            oRole.m_oKeju:JoinDianshi()
        end
    end
end

function Srv2Srv.KejuAnswerHelpQuestionReq(nSrcServer,nSrcService,nTarSession,nRoleID,tData)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local nAnswerID = tData.nAnswerID
	local sAnswerName = tData.sAnswerName
	local nQuestionID = tData.nQuestionID
	local nAnswerNo = tData.nAnswerNo
	oRole.m_oKeju:KejuAnswerHelpQuestion(nAnswerID,sAnswerName,nQuestionID,nAnswerNo)
end

function Srv2Srv.KejuHelpQuestionDataReq(nSrcServer,nSrcService,nTarSession,nRoleID,nHelpRoleID,nQuestionID)
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	local tData = oRole.m_oKeju:KejuHelpQuestionDataReq(nHelpRoleID,nQuestionID)
	return tData
end