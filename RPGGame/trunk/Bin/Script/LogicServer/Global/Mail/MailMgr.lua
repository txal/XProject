--邮件系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nAutoSaveTime = 5*60

function CMailMgr:Ctor()
	self.m_nAutoInc = 0
	self.m_bSendInitMail = false
	self.m_tServerMailMap = {} --全服邮件 
	self.m_bDirty = false
	self.m_nSaveTick = nil
end

function CMailMgr:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sMailBodyDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nAutoInc = tData.m_nAutoInc
		self.m_bSendInitMail = tData.m_bSendInitMail or false
		self.m_tServerMailMap = tData.m_tServerMailMap or self.m_tServerMailMap
	end
	self:OnLoaded()	
end

function CMailMgr:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nAutoInc = self.m_nAutoInc
	tData.m_bSendInitMail = self.m_bSendInitMail
	tData.m_tServerMailMap = self.m_tServerMailMap
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sMailBodyDB, "data", cjson.encode(tData))
end

function CMailMgr:OnLoaded()
	if not self.m_bSendInitMail then
		self.m_bSendInitMail = true 
		self:MarkDirty(true)
		self:SendWelcomeMail()
	end
end

function CMailMgr:IsDirty()
	return self.m_bDirty
end

function CMailMgr:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CMailMgr:AutoSve()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CMailMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil

	self:SaveData()
end

function CMailMgr:SendWelcomeMail()
	local tConf = ctMailConf[1]
	if tConf.bInitMail then
		local tAwardList = {}
		for _, tItem in ipairs(tConf.tInitMailAward) do
			if tItem[1] > 0 then
				table.insert(tAwardList, tItem)
			end
		end
		self:SendServerMail("系统", tConf.sInitMailTitle, tConf.sInitMailCont, tAwardList, true)
	end
end

function CMailMgr:_gen_mail_id()
	self.m_nAutoInc = self.m_nAutoInc % nMAX_INTEGER + 1
	self:SaveData()
	return self.m_nAutoInc
end

function CMailMgr:CheckValid(sSenderName, sTitle, sContent, tItems)
	assert(sSenderName and sTitle and sContent and tItems, "参数非法")
	assert(string.len(sTitle) <= 16*3, "邮件标题过长,最多16个汉字")
	assert(string.len(sContent) <= 128*3, "邮件内容过长,最多128个汉字")
	assert(type(tItems) == "table", "物品格式错误")
	assert(#tItems <= 15, "最多支持附带15个物品")
end

--发送玩家邮件
function CMailMgr:SendMail(sSenderName, sTitle, sContent, tItems, nReceiverCharID)
	assert(nReceiverCharID, "参数非法")
	self:CheckValid(sSenderName, sTitle, sContent, tItems)

	if not goOfflineDataMgr:GetPlayer(nReceiverCharID) then
		return LuaTrace("玩家不存在:", nReceiverCharID, type(nReceiverCharID))
	end

	local bRes = false

	local nMailID = self:_gen_mail_id()
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nReceiverCharID)
	if oPlayer then
		bRes = oPlayer.m_oMail:RecvMail(nMailID, sSenderName, sTitle, tItems)
	else
		bRes = CMail:RecvMailOffline(nReceiverCharID, nMailID, sSenderName, sTitle, tItems)
	end

	if bRes then
	    goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sMailBodyDB, nReceiverCharID.."_"..nMailID, sContent)
	    goLogger:EventLog(gtEvent.eSendMail, nil, nReceiverCharID, sSenderName, sTitle, sContent, cjson.encode(tItems))
	end

	return bRes
end

--检测全服邮件过期
function CMailMgr:CheckServerMailExpire()
	local nExpireTime = ctMailConf[1].nExpireTime*24*3600
	for nID, tMail in pairs(self.m_tServerMailMap) do
		if tMail[5] + nExpireTime <= os.time() and not tMail.bForever then
			self.m_tServerMailMap[nID] = nil
			self:MarkDirty(true)
			LuaTrace("全服邮件过期:", tMail)
		end
	end
end

--发送全服邮件
function CMailMgr:SendServerMail(sSenderName, sTitle, sContent, tItems, bForever)
	self:CheckServerMailExpire()
	self:CheckValid(sSenderName, sTitle, sContent, tItems)

	local nMailID = self:_gen_mail_id()
	local tMail = {sSenderName, sTitle, sContent, tItems, os.time(), 0, tPullMap={}, bForever=bForever}
	self.m_tServerMailMap[nMailID] = tMail
	self:MarkDirty(true)

	--发在线的
	for nCharID, oPlayer in pairs(goPlayerMgr.m_tCharIDMap) do
		self:PullServerMail(oPlayer)
	end
	return true
end

--在线玩家拉取全服邮件
function CMailMgr:PullServerMail(oPlayer)
	self:CheckServerMailExpire()
	local nCharID = oPlayer:GetCharID()
	local nCreateTime = oPlayer:GetCreateTime()

	for nID, tMail in pairs(self.m_tServerMailMap) do
		if not tMail.bForever and not os.IsSameDay(nCreateTime, tMail[5], 0) and tMail[5] < nCreateTime then
			--第二天注册玩家不能领取第一天的奖励
		else
			if not tMail.tPullMap[nCharID] then
				tMail.tPullMap[nCharID] = 1
				self:MarkDirty(true)
				self:SendMail(tMail[1], tMail[2], tMail[3], tMail[4], nCharID)
			end
		end
	end
end

--删除邮件体
function CMailMgr:DelMailBody(nCharID, nMailID)
    goDBMgr:GetSSDB("Player"):HDel(gtDBDef.sMailBodyDB, nCharID.."_"..nMailID)
end

--取邮件体
function CMailMgr:GetMailBody(nCharID, nMailID)
    return goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sMailBodyDB, nCharID.."_"..nMailID)
end

--GM清理全局邮件
function CMailMgr:GMClearTask(nMailID)
	if nMailID then
		self.m_tServerMailMap[nMailID] = {}
	else
		self.m_tServerMailMap = {}
	end
	self:MarkDirty(true)
end


goMailMgr = goMailMgr or CMailMgr:new()