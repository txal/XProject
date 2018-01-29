---------------服务器内部-------------
--GM指令
function Srv2Srv.GMCommandReq(nSrc, nSession, sCmd)
	goGMMgr:OnGMCmdReq(nSession, sCmd)
end

--修改属性请求
function Srv2Srv.GMModUserReq(nSrc, nSession, nBsrSession, tData)
	goGMMgr:OnModUserReq(nBsrSession, tData)
end

--开启活动请求
function Srv2Srv.GMOpenActReq(nSrc, nSession, tData)
	goHDMgr:GMOpenAct(tData.actid, tData.stime, tData.etime, tData.subactid, tData.extid, tData.extid1, tData.awardtime)
end

--发送邮件请求
function Srv2Srv.GMSendMailReq(nSrc, nSession, tData)
	if tData.target then
		goMailMgr:SendMail("系统邮件", tData.title, tData.content, tData.itemlist, tData.target)
	else
		goMailMgr:SendServerMail("系统邮件", tData.title, tData.content, tData.itemlist)
	end
end