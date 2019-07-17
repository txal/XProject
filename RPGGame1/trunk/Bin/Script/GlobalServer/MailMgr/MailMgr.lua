--邮件系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nTaskUpdateTime = 30
local nWelcomeMailVersion = ctMailConf[1].nVersion
function CMailMgr:Ctor()
	self.m_nAutoInc = 0
	self.m_nWelcomeMailVersion = 0
	self.m_tServerMailMap = {} 	--全服邮件{[mailid]={sSender,sTitle,sContent,tItems,nTime,tPullMap={},bForever=false}, ...}

	self.m_tRoleMailMap = {}	--角色邮件{[roleid]={{nMailID,sSender,sTitle,tItems,nTime,nReaded}, ...}, ...}
	self.m_tDirtyRoleMap = {}	--脏角色邮件{[roleid]=true,...}

	self.m_nSaveTimer = nil
	self.m_nTaskTimer = nil
end

function CMailMgr:LoadData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())

	--全局数据
	local sData = oDB:HGet(gtDBDef.sServerMailDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nAutoInc = tData.m_nAutoInc
		self.m_nWelcomeMailVersion = tData.m_nWelcomeMailVersion or 0
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
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	for nRoleID, v in pairs(self.m_tDirtyRoleMap) do
		if nRoleID == 0 then --全局数据
			local tData = {}
			tData.m_nAutoInc = self.m_nAutoInc
			tData.m_nWelcomeMailVersion = self.m_nWelcomeMailVersion
			tData.m_tServerMailMap = self.m_tServerMailMap
			oDB:HSet(gtDBDef.sServerMailDB, "data", cjson.encode(tData))
		else
			local tData = self.m_tRoleMailMap[nRoleID]
			oDB:HSet(gtDBDef.sRoleMailDB, nRoleID, cjson.encode(tData))
		end
	end
	self.m_tDirtyRoleMap = {}

end

function CMailMgr:OnLoaded()
	--发送欢迎全服邮件
	if self.m_nWelcomeMailVersion ~= nWelcomeMailVersion then
		self.m_nWelcomeMailVersion = nWelcomeMailVersion
		for nMailID, tMail in pairs(self.m_tServerMailMap) do
			if tMail.bForever then
				self.m_tServerMailMap[nMailID] = nil
			end
		end
		self:MarkDirty(0, true)
		self:SendWelcomeMail()
	end
	self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
	self.m_nTaskTimer = GetGModule("TimerMgr"):Interval(nTaskUpdateTime, function() self:OnTaskTimer() end)
end

function CMailMgr:Release()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = nil

	GetGModule("TimerMgr"):Clear(self.m_nTaskTimer)
	self.m_nTaskTimer = nil

	self:SaveData()
end

function CMailMgr:MarkDirty(nRoleID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyRoleMap[nRoleID] = bDirty
end

function CMailMgr:Online(oRole)
	self:PullServerMail(oRole)
	self:MailListReq(oRole)
end

function CMailMgr:GenMailID()
	self.m_nAutoInc = self.m_nAutoInc%gtGDef.tConst.nMaxInteger+1
	self:MarkDirty(0, true)
	return self.m_nAutoInc
end

function CMailMgr:CheckValid(sSender, sTitle, sContent, tItems)
	assert(sSender and sTitle and sContent and tItems, "参数非法")
	assert(string.len(sTitle) <= 16*3, "邮件标题过长,最多16个汉字")
	assert(string.len(sContent) <= 256*3, "邮件内容过长,最多256个汉字")
	assert(type(tItems) == "table", "物品格式错误")
	assert(#tItems <= gtGDef.tConst.nMaxMailItemLength, "最多支持附带15个物品")
end

function CMailMgr:SendWelcomeMail()
	local tConf = ctMailConf[1]
	if tConf.bInitMail then
		local tItemList = {}
		for _, tItem in ipairs(tConf.tInitMailAward) do
			if tItem[1] > 0 then table.insert(tItemList, tItem) end
		end
		self:SendServerMail(tConf.sInitMailTitle, tConf.sInitMailCont, tItemList, true)
	end
end

--发送玩家邮件
--@tItem 物品列表{{type,id,num,bind,propext}, oProp:SaveData(), ...}
function CMailMgr:SendMail(sTitle, sContent, tItems, nReceiver)
	local sSender = "系统"
	assert(nReceiver, "参数非法")
	self:CheckValid(sSender, sTitle, sContent, tItems)

	if CUtil:IsRobot(nReceiver) then
		return true
	end

	local oRole = goGPlayerMgr:GetRoleByID(nReceiver)
	if not oRole then
		LuaTrace("邮件目标角色不存在:", nReceiver)
		return 
	end

	if not self.m_tRoleMailMap[nReceiver] then
		self.m_tRoleMailMap[nReceiver] = {}
	end

	local nMailID = self:GenMailID()
	table.insert(self.m_tRoleMailMap[nReceiver], 1, {nMailID,sSender,sTitle,tItems,os.time(),0})
	self:MarkDirty(nReceiver, true)

	if #self.m_tRoleMailMap[nReceiver] > ctMailConf[1].nTips then
		oRole:Tips("邮件数量将满,为防止邮件奖励丢失,请及时清理邮件")
	end

	if #self.m_tRoleMailMap[nReceiver] > ctMailConf[1].nMaxMail then
		local tDropMail = table.remove(self.m_tRoleMailMap[nReceiver])
		self:DelMailBody(nReceiver, tDropMail[1])
	    goLogger:EventLog(gtEvent.eFullMail, oRole, tDropMail[2], tDropMail[3], cjson_raw.encode(tDropMail[4]), tDropMail[5])
	end
	
	self:MailListReq(oRole)
	goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID()):HSet(gtDBDef.sRoleMailBodyDB, nReceiver.."_"..nMailID, sContent)
    goLogger:EventLog(gtEvent.eSendMail, oRole, nReceiver, sSender, sTitle, sContent, cjson_raw.encode(tItems))
	return true
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
--@tItems 物品列表{{type,id,num,bind,propext}, Prop:SaveData(), ...}
function CMailMgr:SendServerMail(sTitle, sContent, tItems, bForever)
	local sSender = "系统"
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
			--第二天注册玩家不能收到第一天和之前的邮件

		elseif not tMail.tPullMap[nRoleID] then
			tMail.tPullMap[nRoleID] = 1
			self:MarkDirty(0, true)
			self:SendMail(tMail[2], tMail[3], tMail[4], nRoleID)

		end
	end
end

--删除邮件体
function CMailMgr:DelMailBody(nRoleID, nMailID)
    goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID()):HDel(gtDBDef.sRoleMailBodyDB, nRoleID.."_"..nMailID)
end

--取邮件体
function CMailMgr:GetMailBody(nRoleID, nMailID)
    return goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID()):HGet(gtDBDef.sRoleMailBodyDB, nRoleID.."_"..nMailID)
end

--定时取发邮件任务
function CMailMgr:OnTaskTimer()
	local sSql = "select id,title,content,receiver,itemlist from sendmail where serverid in(0,%d) and state=0 and sendtime<=%d;"
	sSql = string.format(sSql, gnServerID, os.time())
	local oMysql = goDBMgr:GetMgrMysql()
	if not oMysql:Query(sSql) then
		return
	end
	local sUpdateSql = "update sendmail set state=1 where id=%d;"
	while oMysql:FetchRow() do
		local nID = oMysql:ToInt32("id")
		local sTitle, sContent, sReceiver, sItemList = oMysql:ToString("title", "content", "receiver", "itemlist")
		local tItemList = cjson_raw.decode(sItemList)
		local xReceiver = sReceiver == "" and 0 or cjson_raw.decode(sReceiver)
		--全服邮件
		if xReceiver == 0 then	
			self:SendServerMail(sTitle, sContent, tItemList)
		--个人邮件
		else
			for _, nRoleID in pairs(xReceiver) do
				self:SendMail(sTitle, sContent, tItemList, nRoleID)
			end
		end
		oMysql:Query(string.format(sUpdateSql, nID))
	end
end

--同步邮件列表
function CMailMgr:MailListReq(oRole)
	local tList = {}

	local nRoleID = oRole:GetID()
	local nExpireTime = ctMailConf[1].nExpireTime*24*3600

	local tNewMailList = {}
	local tRoleMailList = self.m_tRoleMailMap[nRoleID] or {}
	for _, tMail in ipairs(tRoleMailList) do
		if os.time()-tMail[5] < nExpireTime then
			local tInfo = {}
			tInfo.nMailID = tMail[1]
			tInfo.sSender = tMail[2]
			tInfo.sTitle = tMail[3]
			tInfo.nTime = tMail[5]
			tInfo.nReaded = tMail[6]
			tInfo.tItemList = {}
			for _, tItem in ipairs(tMail[4]) do
				if tItem.m_nID then --背包物品
					table.insert(tInfo.tItemList, {nType=gtItemType.eProp, nID=tItem.m_nID, nNum=tItem.m_nFold})

				else --非背包物品
					table.insert(tInfo.tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})

				end
			end
			table.insert(tList, tInfo)
			table.insert(tNewMailList, tMail)
		else
			LuaTrace(oRole:GetID(), oRole:GetName(), "邮件过期", tMail)
		end
	end
	self.m_tRoleMailMap[nRoleID] = tNewMailList
	self:MarkDirty(true)

	oRole:SendMsg("MailListRet", {tList=tList})
end

--取角色邮件
function CMailMgr:GetRoleMail(nRoleID, nMailID)
	local tRoleMailList = self.m_tRoleMailMap[nRoleID] or {}
	for nIndex, tMail in ipairs(tRoleMailList) do
		if tMail[1] == nMailID then
			return nIndex, tMail
		end
	end
end

--删除邮件
function CMailMgr:DelMailReq(oRole, nMailID, bForce)
	--删除指定
	local nRoleID = oRole:GetID()
	local tRoleMailList = self.m_tRoleMailMap[nRoleID] or {}

	if nMailID > 0 then
		local nIndex, tMail = self:GetRoleMail(nRoleID, nMailID)
		if not tMail then
			return oRole:Tips("邮件不存在")
		end
		if not bForce and #tMail[4] > 0 then
			return oRole:Tips("请先领取物品")
		end
		table.remove(tRoleMailList, nIndex)
		self:MarkDirty(nRoleID, true)
		goLogger:EventLog(gtEvent.eDelMail, oRole, nMailID)

		self:DelMailBody(nRoleID, nMailID)
		self:MailListReq(oRole)
		oRole:Tips("删除邮件成功")
		return
	end

	--删除所有
	local tNewRoleMailList = {}
	for _, tMail in ipairs(tRoleMailList) do
		--删除没有物品且已读的
		if bForce or (#tMail[4] <= 0 and tMail[6] > 0) then
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

	--领取指定
	if nMailID > 0 then
		local nIndex, tMail = self:GetRoleMail(nRoleID, nMailID)
		if tMail and #tMail[4] > 0 then
			oRole:SendMailAward(tMail[4], function(bRes, tList)
				if not bRes then
					return
				end
				tMail[4] = {}
				tMail[6] = 1
				self:MarkDirty(nRoleID, true)
				self:MailListReq(oRole)
				oRole:SendMsg("MailItemsRet", {tList=tList})
			    goLogger:EventLog(gtEvent.eGetMail, oRole, tMail[1])
			end)
		end

	--领取所有
	else
		local k = 1
		local nCount = 0
		local tAwardList = {}
		local tRoleMailList = self.m_tRoleMailMap[nRoleID] or {}
		local function _SendMailAward(fnCallback)
			local tMail = tRoleMailList[k]
			if not tMail then
				return fnCallback(nCount, tAwardList)
			end

			if #tMail[4] > 0 then
				oRole:SendMailAward(tMail[4], function(bRes, tList)
					if not bRes then
						return
					end
					tMail[4] = {}
					tMail[6] = 1
					self:MarkDirty(nRoleID, true)
				    goLogger:EventLog(gtEvent.eGetMail, oRole, tMail[1])

				    for _, tItem in ipairs(tList) do
				    	table.insert(tAwardList, tItem)
				    end
				    nCount = nCount + 1

				    k = k + 1
				    _SendMailAward(fnCallback)
				end, true)
			else
				k = k + 1
				_SendMailAward(fnCallback)
			end
		end
		_SendMailAward(function(nCount, tAwardList)
			if nCount > 0 then
				self:MailListReq(oRole)
				oRole:SyncKnapsackCacheMsg()
				oRole:SendMsg("MailItemsRet", {tList=tAwardList})
			else
				oRole:Tips("没有可领取物品")
			end
		end)
	end
end

--请求邮件体
function CMailMgr:MailBodyReq(oRole, nMailID)
	local nRoleID = oRole:GetID()
	local nIndex, tMail = self:GetRoleMail(nRoleID, nMailID)
	if not tMail then
		return oRole:Tips("邮件内容不存在")
	end
	tMail[6] = 1
	self:MarkDirty(nRoleID, true)
	
	local sMailBody = self:GetMailBody(nRoleID, nMailID)
	oRole:SendMsg("MailBodyRet", {nMailID=nMailID, sMailBody=sMailBody})
end

--GM清理全局邮件
function CMailMgr:GMDelServerMail(nMailID)
	nMailID = nMailID or 0
	if nMailID > 0 then
		self.m_tServerMailMap[nMailID] = {}
	else
		self.m_tServerMailMap = {}
	end
	self.m_nWelcomeMailVersion = 0
	self:MarkDirty(0, true)
end

--GM清理邮件
function CMailMgr:GMDelMail(oRole, nMailID)
	nMailID = nMailID or 0
	if nMailID > 0 then
		self:DelMailReq(oRole, nMailID, true)
	else
		self:DelMailReq(oRole, 0, true)
	end
end

--(判断邮件是否满)
function CMailMgr:GetLaveMailNum(nReceiver)
	local nMaxMail = ctMailConf[1].nMaxMail
	if not self.m_tRoleMailMap[nReceiver] then
		return false
	else
		local nCurMailNum = #self.m_tRoleMailMap[nReceiver]
		return nCurMailNum >= nMaxMail and true or false
	end
end
