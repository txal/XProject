--邮件系统
local sMAIL_BODY_DB = "MailBodyDB"

function CMailMgr:Ctor()
	self.m_nAutoInc = 0
end

function CMailMgr:LoadData()
	local sData = goSSDB:HGet(sMAIL_BODY_DB, "AutoInc")
	if sData ~= "" then
		self.m_nAutoInc = cjson.decode(sData).nAutoInc
	end
end

function CMailMgr:SaveData()
	local tData = {nAutoInc=self.m_nAutoInc}
	goSSDB:HSet(sMAIL_BODY_DB, "AutoInc", cjson.encode(tData))
end

function CMailMgr:OnRelease()
	self:SaveData()
end

function CMailMgr:_gen_mail_id()
	if not self.m_nAutoInc then
		self:LoadData()
	end
	self.m_nAutoInc = self.m_nAutoInc % nMAX_INTEGER + 1
	self:SaveData()
	return self.m_nAutoInc
end

function CMailMgr:SendMail(sSenderName, sTitle, sContent, tItems, sReceiverCharID)
	print("SendMail***", sSenderName, sTitle, sContent, tItems, sReceiverCharID)
	assert(sSenderName and sTitle and sContent and tItems and sReceiverCharID, "参数非法")
	assert(string.len(sTitle) <= 32*3, "邮件标题过长,最多32个汉字")
	assert(string.len(sContent) <= 256*3, "邮件内容过长,最多256个汉字")
	assert(#tItems <= 3, "最多支持附带3个物品")
	local bRes = false
	local nMailID = self:_gen_mail_id()
	local oPlayer = goPlayerMgr:GetPlayerByCharID(sReceiverCharID)
	if oPlayer then
		bRes = oPlayer.m_oMail:RecvMail(nMailID, sSenderName, sTitle, tItems)
	else
		bRes = CMail:RecvMailOffline(sReceiverCharID, nMailID, sSenderName, sTitle, tItems)
	end
	if bRes then
	    goSSDB:HSet(sMAIL_BODY_DB, sReceiverCharID.."_"..nMailID, sContent)
	    goLogger:EventLog(gtEvent.eSendMail, nil, sReceiverCharID, sSenderName, sTitle, sContent, cjson.encode(tItems))
	end
	return bRes
end

function CMailMgr:DelMailBody(nCharID, nMailID)
    goSSDB:HDel(sMAIL_BODY_DB, nCharID.."_"..nMailID)
end

function CMailMgr:GetMailBody(nCharID, nMailID)
    return goSSDB:HGet(sMAIL_BODY_DB, nCharID.."_"..nMailID)
end


goMailMgr = goMailMgr or CMailMgr:new()