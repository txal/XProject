function CltPBProc.TalkReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goTalk:TalkReq(oRole, tData.nChannel, tData.sCont, tData.bXMLMsg and true or false)
end

function CltPBProc.ShieldRoleReq(nCmd, nServer, nService, nSession, tData)
	local oRole = goGPlayerMgr:GetRoleBySS(nServer, nSession)
	if not oRole then return end
	goTalk:ShieldRoleReq(oRole, tData.nTarRoleID, tData.nType)
end




-------服务器内部
--系统频道
function Srv2Srv.SendSystemTalkReq(nSrcServer, nSrcService, nTarSession, sTitle, sContent)
	goTalk:SendSystemMsg(sContent, sTitle)
end

--队伍频道
function Srv2Srv.SendTeamTalkReq(nSrcServer, nSrcService, nTarSession, nRoleID, sContent, bSys)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	goTalk:SendTeamMsg(oRole, sContent, bSys)
end

--联盟频道
function Srv2Srv.SendUnionTalkReq(nSrcServer, nSrcService, nTarSession, nRoleID, sContent)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	goTalk:SendUnionMsg(oRole, sContent)
end

--传闻频道
function Srv2Srv.SendHearsayTalkReq(nSrcServer, nSrcService, nTarSession, sContent)
	goTalk:SendHearsayMsg(sContent)
end

--世界频道
function Srv2Srv.SendWorldTalkReq(nSrcServer, nSrcService, nTarSession, nRoleID, sContent, bSys)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	goTalk:SendWorldMsg(oRole, sContent, bSys)
end

--联盟解散
function Srv2Srv.OnUnionDismissReq(nSrcServer, nSrcService, nTarSession, nUnionID)
	goTalk:OnUnionDismiss(nUnionID)
end
