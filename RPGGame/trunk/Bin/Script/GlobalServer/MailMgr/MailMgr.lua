--邮件系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAutoSaveTime = 5*60
local nTaskUpdateTime = 3
local nServerID = gnServerID

function CMailMgr:Ctor()
	self.m_nAutoInc = 0
	self.m_bSentWelcomeMail = false
	self.m_tServerMailMap = {} --全服邮件{[mailid]={sSender,sTitle,sContent,tItems,nTime,tPullMap={},bForever=false}, ...}
	self.m_bDirty = false

	self.m_tRoleMailMap = {} --角色邮件{[roleid]={{nMailID,sSender,sTitle,tItems,nTime,nReaded}, ...}, ...}
	self.m_tDirtyRoleMap = {} --脏角色邮件{[roleid]=true,...}

	self.m_nSaveTimer = nil
	self.m_oMgrMysql = MysqlDriver:new()
	self.m_nTaskTimer = nil
end

function CMailMgr:LoadData()
	local oDB = goDBMgr:GetSSDB(nServerID, "global")

	--全局数据
	local sData = oDB:HGet(gtDBDef.sServerMailDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nAutoInc = tData.m_nAutoInc
		self.m_bSentWelcomeMail = tData.m_bSentWelcomeMail or false
		self.m_tServerMailMap = tData.m_tServerMailMap or self.m_tServerMailMap
	end

	--角色数据
	local tKeys = oDB:HKeys(gtDBDef.sRoleMailDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sRoleMailDB, sRoleID)
		self.m_tRoleMailMap[tonumber(sRoleID)] = cjson.decode(sData)
	end

	self:OnLoaded()	
end

function CMailMgr:SaveData()
	local oDB = goDBMgr:GetSSDB(nServerID, "global")

	--全局数据
	if self:IsDirty() then
		self:MarkDirty(0, false)

		local tData = {}
		tData.m_nAutoInc = self.m_nAutoInc
		tData.m_bSentWelcomeMail = self.m_bSentWelcomeMail
		tData.m_tServerMailMap = self.m_tServerMailMap
		oDB:HSet(gtDBDef.sServerMailDB, "data", cjson.encode(tData))
	end

	--角色数据
	for nRoleID, v in pairs(self.m_tDirtyRoleMap) do
		local tData = self.m_tRoleMailMap[nRoleID]
		oDB:HSet(gtDBDef.sRoleMailDB, nRoleID, cjson.encode(tData))
	end
	self.m_tDirtyRoleMap = {}

end

function CMailMgr:OnLoaded()
	--发送欢迎全服邮件
	if not self.m_bSentWelcomeMail then
		self.m_bSentWelcomeMail = true 
		self:MarkDirty(0, true)
		self:SendWelcomeMail()
	end
	self.m_nSaveTimer = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)

	--初始化数据库
	local tConf = gtMgrMysqlConf
	local bRes = self.m_oMgrMysql:Connect(tConf.sIP, tConf.nPort, tConf.sDBName, tConf.sUserName, tConf.sPassword, "utf8")
	assert(bRes, "连接数据库失败", tConf)
	LuaTrace("连接数据库成功", tConf)
	self.m_nTaskTimer = goTimerMgr:Interval(nTaskUpdateTime, function() self:OnTaskTimer() end)
end

function CMailMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = nil

	goTimerMgr:Clear(self.m_nTaskTimer)
	self.m_nTaskTimer = nil

	self:SaveData()
end

function CMailMgr:IsDirty()
	return self.m_bDirty
end

function CMailMgr:MarkDirty(nRoleID, bDirty)
	nRoleID = nRoleID or 0
	if nRoleID == 0 then
		self.m_bDirty = bDirty
	else
		self.m_tDirtyRoleMap[nRoleID] = bDirty
	end
end

function CMailMgr:SendWelcomeMail()
	local tConf = ctMailConf[1]
	if tConf.bInitMail then
		local tItemList = {}
		for _, tItem in ipairs(tConf.tInitMailAward) do
			if tItem[1] > 0 then
				table.insert(tItemList, tItem)
			end
		end
		self:SendServerMail("系统", tConf.sInitMailTitle, tConf.sInitMailCont, tItemList, true)
	end
end

function CMailMgr:GenMailID()
	self.m_nAutoInc = self.m_nAutoInc % nMAX_INTEGER + 1
	self:MarkDirty(0, true)
	return self.m_nAutoInc
end

function CMailMgr:CheckValid(sSender, sTitle, sContent, tItems)
	assert(sSender and sTitle and sContent and tItems, "参数非法")
	assert(string.len(sTitle) <= 16*3, "邮件标题过长,最多16个汉字")
	assert(string.len(sContent) <= 128*3, "邮件内容过长,最多128个汉字")
	assert(type(tItems) == "table", "物品格式错误")
	assert(#tItems <= 15, "最多支持附带15个物品")
end

--发送玩家邮件
function CMailMgr:SendMail(sSender, sTitle, sContent, tItems, nReceiver)
	assert(nReceiver, "参数非法")
	self:CheckValid(sSender, sTitle, sContent, tItems)

	local oRole = goPlayerMgr:GetRoleByID(nReceiver)
	if not oRole then
		return LuaTrace("角色不存在:", nReceiver)
	end

	if not self.m_tRoleMailMap[nReceiver] then
		self.m_tRoleMailMap[nReceiver] = {}
	end
	local nMailID = self:GenMailID()
	table.insert(self.m_tRoleMailMap[nReceiver], 1, {nMailID,sSender,sTitle,tItems,os.time(),0})
	if #self.m_tRoleMailMap[nReceiverID] > ctMailConf[1].nMaxMail then
		local tDropMail = table.remove(self.m_tRoleMailMap[nReceiverID])
		self:DelMailBody(nReceiver, tDropMail[1])
	end
	self:MarkDirty(nReceiver, true)

	goDBMgr:GetSSDB(nServerID, "global"):HSet(gtDBDef.sRoleMailBodyDB, nReceiver.."_"..nMailID, sContent)
    goLogger:EventLog(gtEvent.eSendMail, oRole, nReceiver, sSender, sTitle, sContent, cjson.encode(tItems))

	return bRes
end

--检测全服邮件过期
function CMailMgr:CheckServerMailExpire()
	local nExpireTime = ctMailConf[1].nExpireTime*24*3600
	for nID, tMail in pairs(self.m_tServerMailMap) do
		if os.time() >= tMail[5] + nExpireTime and not tMail.bForever then
			self.m_tServerMailMap[nID] = nil
			self:MarkDirty(0, true)
			LuaTrace("全服邮件过期:", tMail)
		end
	end
end

--发送全服邮件
function CMailMgr:SendServerMail(sSender, sTitle, sContent, tItems, bForever)
	self:CheckServerMailExpire()
	self:CheckValid(sSender, sTitle, sContent, tItems)

	local nMailID = self:GenMailID()
	self.m_tServerMailMap[nMailID] = {sSender,sTitle,sContent,tItems,os.time(),tPullMap={},bForever=bForever}
	self:MarkDirty(0, true)

	--发在线的
	local tRoleSSMap = goGPlayerMgr:GetRoleSSMap()
	for nSSKey, oRole in pairs(tRoleSSMap) do
		self:PullServerMail(oRole)
	end
	return true
end

--在线玩家拉取全服邮件
function CMailMgr:PullServerMail(oRole)
	self:CheckServerMailExpire()
	local nRoleID = oRole:GetID()
	local nCreateTime = oRole:GetCreateTime()

	for nID, tMail in pairs(self.m_tServerMailMap) do
		if not tMail.bForever and not os.IsSameDay(nCreateTime, tMail[5], 0) and nCreateTime > tMail[5] then
			--第二天注册玩家不能收到第一天之前的邮件
		else
			if not tMail.tPullMap[nRoleID] then
				tMail.tPullMap[nRoleID] = 1
				self:MarkDirty(0, true)
				self:SendMail(tMail[1], tMail[2], tMail[3], tMail[4], nRoleID)
			end
		end
	end
end

--删除邮件体
function CMailMgr:DelMailBody(nRoleID, nMailID)
    goDBMgr:GetSSDB(nServerID, "global"):HDel(gtDBDef.sRoleMailBodyDB, nRoleID.."_"..nMailID)
end

--取邮件体
function CMailMgr:GetMailBody(nRoleID, nMailID)
    return goDBMgr:GetSSDB(nServerID, "global"):HGet(gtDBDef.sRoleMailBodyDB, nRoleID.."_"..nMailID)
end

--定时取发邮件任务
function CMailMgr:OnTaskTimer()
	local sSql = "select id,title,content,receiver,itemlist from sendmail where serverid=%d and state=0 and sendtime<=%d;"
	sSql = string.format(sSql, nServerID, os.time())
	if not self.m_oMgrMysql:Query(sSql) then
		return
	end
	local sUpdateSql = "update sendmail set state=1 where id=%d;"
	while self.m_oMgrMysql:FetchRow() do
		local nID = self.m_oMgrMysql:ToInt32("id")
		local sTitle, sContent, sReceiver, sItemList = self.m_oMgrMysql:ToString("title", "content", "receiver", "itemlist")
		local tItemList = cjson.decode(sItemList)
		local nReceiver = sReceiver ~= "" and tonumber(sReceiver) or nil
		--全服邮件
		if not nReceiver then	
			self:SendServerMail("系统", sTitle, sContent, tItemList)
		--个人邮件
		else
			self:SendMail("系统", sTitle, sContent, tItemList, nReceiver)
		end
		self.m_oMgrMysql:Query(string.format(sUpdateSql, nID))
	end
end


--同步邮件列表
function CMailMgr:MailListReq(oRole)
	local tList = {}

	local nRoleID = oRole:GetID()
	local tRoleMailList = self.m_tRoleMailMap[nRoleID] or {}
	for _, tMail in ipairs(tRoleMailList) do
		local tInfo = {}
		tInfo.nMailID = tMail[1]
		tInfo.sSender = tMail[2]
		tInfo.sTitle = tMail[3]
		tInfo.tItemList = {}
		for _, tItem in ipairs(tMail[4]) do
			table.insert(tInfo.tItemList, {nType=v[1], nID=v[2], nNum=v[3]})
		end
		tInfo.nTime = tMail[5]
		tInfo.nReaded = tMail[6]
		table.insert(tList, tInfo)
	end
	CmdNet.PBSrv2Clt(oRole:GetServer(), oRole:GetSession(), "MailListRet", {tList=tList})
end

--去角色邮件
function CMailMgr:GetRoleMail(nRoleID, nMailID)
	local tRoleMailList = self.m_tRoleMailMap[nRoleID] or {}
	for nIndex, tMail in ipairs(tRoleMailList) do
		if tMail[1] == nMailID then
			return nIndex, tMail
		end
	end
end

--删除邮件
function CMailMgr:DelMailReq(oRole, nMailID)
	--删除指定
	local nRoleID = oRole:GetID()
	local tRoleMailList = self.m_tRoleMailMap[nRoleID] or {}

	if nMailID > 0 then
		local nIndex, tMail = self:GetRoleMail(nRoleID, nMailID)
		if not tMail then
			return oRole:Tips("邮件不存在")
		end
		if #tMail[4] > 0 then
			return oRole:Tips("请先领取物品")
		end
		table.remove(tRoleMailList, nIndex)
		self:MarkDirty(nRoleID, true)
		goLogger:EventLog(gtEvent.eDelMail, oRole, nMailID)

		self:DelMailBody(nRoleID, nMailID)
		self:MailListReq(oRole)
		oRole:Tips("删除邮件成功")
	end

	--删除所有
	local tNewRoleMailList = {}
	for _, tMail in ipairs(tRoleMailList) do
		--删除没有物品且已读的
		if #tMail[4] <= 0 and tMail[6] > 0 then
			goMailMgr:DelMailBody(nRoleID, tMail[1])
			goLogger:EventLog(gtEvent.eDelMail, oRole, tMail[1])
		else
			table.insert(tNewRoleMailList, tMail)
		end
	end
	if #tNewRoleMailList ~= #tRoleMailList then
		self.m_tRoleMailMap[nRoleID] = tNewRoleMailList
		self:MarkDirty(nRoleID, true)
		self:MailListReq(oRole)
		oRole:Tips("删除邮件成功")
	end
end

--领取物品
function CMailMgr:MailItemsReq(oRole, nMailID)
	local nRoleID = oRole:GetID()

	local tItemMap = {}
	local function _GetMailItem(tMail)
		for _, tItem in ipairs(tMail[4]) do
			tItemMap[tItem[2]] = (tItemMap[tItem[2]] or 0) + tItem[3]
		end
		tMail[4], tMail[6] = {}, 1
		goLogger:EventLog(gtEvent.eGetMail, oRole, tMail[1])
		return true
	end

	local nCount = 0
	--领取指定
	if nMailID > 0 then
		local nIndex, tMail = self:GetRoleMail(nRoleID, nMailID)
		if tMail and #tMail[4] > 0 then
			if _GetMailItem(tMail) then
				nCount = nCount + 1
			end
		end

	--领取所有
	else
		local tRoleMailList = self.m_tRoleMailMap[nRoleID] or {}
		for _, tMail in ipairs(tRoleMailList) do
			if #tMail[4] > 0 then
				if _GetMailItem(tMail) then
					nCount = nCount + 1
				else
					break
				end
			end
		end
	end
	if nCount > 0 then
		self:MarkDirty(nRoleID, true)

		local tList = {}
		for nID, nNum in pairs(tItemMap) do
			table.insert(tList, {nType=gtItemType.eProp, nID=nID, nNum=nNum})
		end
		oRole:AddItem(tList, "领取邮件")
		CmdNet.PBSrv2Clt(oRole:GetServer(), oRole:GetSession(), "MailItemsRet", {tList=tList})
		self:MailListReq(oRole)
	else
		oRole:Tips("没有可领取物品")
	end
end

--请求邮件体
function CMailMgr:MailBodyReq(oRole, nMailID)
	local nRoleID = oRole:GetID()
	local nIndex, tMail = self:GetRoleMail(nRoleID, nMailID)
	if not tMail then
		return oRole:Tips("邮件不存在")
	end
	tMail[6] = 1
	self:MarkDirty(nRoleID, true)
	
	local sMailBody = self:GetMailBody(nRoleID, nMailID)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "MailBodyRet", {nMailID=nMailID, sMailBody=sMailBody})
end

--GM清理全局邮件
function CMailMgr:GMDelServerMail(nMailID)
	nMailID = nMailID or 0
	if nMailID > 0 then
		self.m_tServerMailMap[nMailID] = {}
	else
		self.m_tServerMailMap = {}
	end
	self:MarkDirty(true)
end


goMailMgr = goMailMgr or CMailMgr:new()