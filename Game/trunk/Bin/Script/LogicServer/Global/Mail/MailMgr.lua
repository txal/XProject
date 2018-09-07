local sMailBodyDB = "MailBodyDB"
function CMailMgr:Ctor()
	self.m_nAutoInc = 0
end

function CMailMgr:LoadData()
	local sData = goSSDB:HGet(sMailBodyDB, "AutoInc")
	if sData ~= "" then
		self.m_nAutoInc = GlobalExport.Str2Tb(sData).nAutoInc
	end
end

function CMailMgr:SaveData()
	local tData = {nAutoInc=self.m_nAutoInc}
	goSSDB:HSet(sMailBodyDB, "AutoInc", GlobalExport.Tb2Str(tData))
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
	assert(sSenderName and sTitle and sContent and tItems and sReceiverCharID)
	assert(string.len(sTitle) <= 32*3, "邮件标题过长,最多32个汉字")
	assert(string.len(sContent) <= 256*3, "邮件内容过长,最多256个汉字")
	assert(#tItems <= 3, "最多支持附带3个物品")
	local bRes = false
	local nMailID = self:_gen_mail_id()
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sReceiverCharID)
	if oPlayer then
		bRes = oPlayer.m_oMail:RecvMail(nMailID, sSenderName, sTitle, tItems)
	else
		bRes = CMail:RecvMailOffline(sReceiverCharID, nMailID, sSenderName, sTitle, tItems)
	end
	if bRes then
	    goSSDB:HSet(sMailBodyDB, sReceiverCharID.."_"..nMailID, sContent)
	end
	return bRes
end

function CMailMgr:DelMailBody(sCharID, nMailID)
    goSSDB:HDel(sMailBodyDB, sCharID.."_"..nMailID)
end

function CMailMgr:GetMailBody(sCharID, nMailID)
    return goSSDB:HGet(sMailBodyDB, sCharID.."_"..nMailID)
end


goMailMgr = goMailMgr or CMailMgr:new()