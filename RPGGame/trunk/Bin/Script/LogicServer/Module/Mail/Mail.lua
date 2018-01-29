local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nMaxMailCount = ctMailConf[1].nMaxMail --邮件上限

function CMail:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tMailMap = {} --[id]={charname, title, tItems, time, readed}
	self.m_nCount = 0
end

function CMail:LoadData(tData)
	if not tData then
		return
	end
	self.m_nCount = tData.m_nCount
	self.m_tMailMap = tData.m_tMailMap
end

function CMail:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nCount = self.m_nCount
	tData.m_tMailMap = self.m_tMailMap
	return tData
end

function CMail:GetType()
	return gtModuleDef.tMail.nID, gtModuleDef.tMail.sName
end

function CMail:Online()
	goMailMgr:PullServerMail(self.m_oPlayer)
	self:SyncMailList()
end

function CMail:_do_recv_mail(nCharID, tMailMap, nCount, nMailID, sSenderName, sTitle, tItems)
	assert(not tMailMap[nMailID], "邮件ID冲突")
	if nCount >= nMaxMailCount then
		local sMail = string.format("邮件满了 %s: %d %s %s %s", nCharID, nMailID, sSenderName, sTitle, cjson.encode(tItems))
		return LuaTrace(sMail)
	end
	tMailMap[nMailID] = {sSenderName, sTitle, tItems, os.time(), 0}
	return true
end

function CMail:RecvMail(nMailID, sSenderName, sTitle, tItems)
	if self:_do_recv_mail(self.m_oPlayer:GetCharID(), self.m_tMailMap, self.m_nCount, nMailID, sSenderName, sTitle, tItems) then
		self.m_nCount = self.m_nCount + 1
		self:MarkDirty(true)
		self:SyncMailList()
		return true
	end
end

function CMail:RecvMailOffline(nCharID, nMailID, sSenderName, sTitle, tItems)
    local _, sModuleName = self:GetType()
    local sData = goDBMgr:GetSSDB("Player"):HGet(sModuleName, nCharID)
    local tData = sData ~= "" and cjson.decode(sData) or {m_tMailMap={}, m_nCount=0}
    if self:_do_recv_mail(nCharID, tData.m_tMailMap, tData.m_nCount, nMailID, sSenderName, sTitle, tItems) then
		tData.m_nCount = tData.m_nCount + 1
		goDBMgr:GetSSDB("Player"):HSet(sModuleName, nCharID, cjson.encode(tData))
		return true
	end
end

--同步邮件列表
function CMail:SyncMailList()
	local tMailList = {}
	for nMailID, tMail in pairs(self.m_tMailMap) do
		local tInfo = {}
		tInfo.nMailID = nMailID
		tInfo.sSenderName = tMail[1]
		tInfo.sTitle = tMail[2]
		tInfo.tItems = {}
		for _, v in ipairs(tMail[3]) do
			table.insert(tInfo.tItems, {nType=v[1], nID=v[2], nNum=v[3]})
		end
		tInfo.nTime = tMail[4]
		tInfo.nReaded = tMail[5]
		table.insert(tMailList, tInfo)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "MailListRet", {tMailList=tMailList})
end

--删除邮件
function CMail:DelMailReq(nMailID)
	--删除指定
	if nMailID > 0 then
		local tMail = self.m_tMailMap[nMailID]
		if not tMail then
			return self.m_oPlayer:Tips("邮件不存在")
		end
		if #tMail[3] > 0 then
			return self.m_oPlayer:Tips("请先领取物品")
		end
		self.m_tMailMap[nMailID] = nil
		self.m_nCount = self.m_nCount - 1 
		self:MarkDirty(true)

		goMailMgr:DelMailBody(self.m_oPlayer:GetCharID(), nMailID)
		self:SyncMailList()

		self.m_oPlayer:Tips("删除邮件成功")
		return
	end

	--删除所有
	local nCount = self.m_nCount
	for nMailID, tMail in pairs(self.m_tMailMap) do
		if #tMail[3] <= 0 and tMail[5] > 0 then --删除没有物品且已读的
			self.m_tMailMap[nMailID] = nil
			self.m_nCount = self.m_nCount - 1
			goMailMgr:DelMailBody(self.m_oPlayer:GetCharID(), nMailID)
		end
	end
	if nCount ~= self.m_nCount then
		self:MarkDirty(true)
		self:SyncMailList()
		self.m_oPlayer:Tips("删除邮件成功")
	end
end

--领取物品
function CMail:MailItemsReq(nMailID)
	local tItemList = {}
	local function _get_mail_item_(tMail)
		for _, tItem in ipairs(tMail[3]) do
			if self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "领取邮件物品") then
				table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
			end
		end
		tMail[3], tMail[5] = {}, 1
		return true
	end

	local nGotNum = 0
	--领取指定
	if nMailID > 0 then
		local tMail = self.m_tMailMap[nMailID]
		if tMail and #tMail[3] > 0 then
			if _get_mail_item_(tMail) then
				nGotNum = nGotNum + 1
			end
		end
	--领取所有
	else
		for nMailID, tMail in pairs(self.m_tMailMap) do
			if #tMail[3] > 0 then
				if _get_mail_item_(tMail) then
					nGotNum = nGotNum + 1
				else
					break
				end
			end
		end
	end
	if nGotNum > 0 then
		self:MarkDirty(true)
		self:SyncMailList()
		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "MailItemsRet", {tItemList=tItemList})
	else
		self.m_oPlayer:Tips("没有可领取物品")
	end
end

--请求邮件列表
function CMail:MailListReq()
	self:SyncMailList()
end

--请求邮件体
function CMail:MailBodyReq(nMailID)
	local tMail = self.m_tMailMap[nMailID]
	if not tMail then
		return self.m_oPlayer:Tips("邮件不存在")
	end
	tMail[5] = 1
	self:MarkDirty(true)
	
	local sMailBody = goMailMgr:GetMailBody(self.m_oPlayer:GetCharID(), nMailID)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "MailBodyRet", {nMailID=nMailID, sMailBody=sMailBody})
end
