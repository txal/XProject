--礼包兑换
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--类型
CKeyExchange.tType = {
	eDuoRenYiKey = 1, 	--多人对一KEY
	eYiRenDuoKey = 2, 	--一人多KEY
	eYiRenYiKey = 3, 	--一人一KEY
}

function CKeyExchange:Ctor()
	self.m_tOnePersonOneKey = {} --{[nRoleID..nGiftID]} = true --true 已经使用过了
	self.m_oMgrSQL = nil
	self.m_bDirty = false
	self.m_nAutoSaveTimer = nil
end

function CKeyExchange:LoadData()
	local sData = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID()):HGet(gtDBDef.sKeyExchangeDB, "data")
	if sData ~= "" then
		local tData = cseri.decode(sData)
		self.m_tOnePersonOneKey = tData.m_tOnePersonOneKey or self.m_tOnePersonOneKey
	end
	self:AutoSave()

	local tConf = gtMgrSQL
	local oMgrSQL = MysqlDriver:new()
	local bRes = oMgrSQL:Connect(tConf.ip, tConf.port, tConf.db, tConf.usr, tConf.pwd, "utf8")
	assert(bRes, "连接数据库失败:"..tostring(tConf))
	self.m_oMgrSQL = oMgrSQL
end

function CKeyExchange:SaveData()
	if not self:IsDirty() then
		return
	end
	local tData = {m_tOnePersonOneKey=self.m_tOnePersonOneKey}
	goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID()):HSet(gtDBDef.sKeyExchangeDB, "data", cseri.encode(tData))
	self:MarkDirty(false)
end

--定时保存
function CKeyExchange:AutoSave()
	GetGModule("TimerMgr"):Clear(self.m_nAutoSaveTimer)
	self.m_nAutoSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

function CKeyExchange:Release()
	GetGModule("TimerMgr"):Clear(self.m_nAutoSaveTimer)
	self.m_nAutoSaveTimer = nil
	self:SaveData()
end

function CKeyExchange:IsDirty() return self.m_bDirty end
function CKeyExchange:MarkDirty(bDirty) self.m_bDirty = bDirty end

--兑换
function CKeyExchange:ExchangeReq(oRole, sCDKey)
	local nRoleID = oRole:GetID()

	local sSql = "select giftid,server,charlist,type,starttime,endtime,award from cdkeycode,cdkeytype where cdkeycode.giftid=cdkeytype.id and `key`='%s';"
	sSql = string.format(sSql, sCDKey)

	if not self.m_oMgrSQL:Query(sSql) then
		return oRole:Tips("查询兑换码失败")	
	end
	if not self.m_oMgrSQL:FetchRow() then
		return oRole:Tips("兑换码不存在")	
	end

	local nGiftID, nServer, nType, nStartTime, nEndTime = self.m_oMgrSQL:ToInt32("giftid", "server", "type", "starttime", "endtime")
	local sCharList, sAward = self.m_oMgrSQL:ToString("charlist", "award")
	if nServer > 0 and nServer ~= oRole:GetServer() then 
		return oRole:Tips("兑换码在该服无效")
	end
	--类型列表
	local tTypeList = {}
	for k, v in pairs(self.tType) do
		table.insert(tTypeList, v)
	end
	if not table.InArray(nType, tTypeList) then
		return oRole:Tips("兑换码类型错误:"..nType..","..tostring(tTypeList))
	end
	local nTimeNow = os.time()
	if nTimeNow < nStartTime or nTimeNow >= nEndTime then
		return oRole:Tips("兑换码已过期")
	end

	local tAward = cjson_raw.decode(sAward)
	if #tAward <= 0 then
		return oRole:Tips("礼包奖励不存在")
	end

	local tCharList = sCharList=="" and {} or cjson_raw.decode(sCharList)
	if nType == self.tType.eYiRenYiKey then --一人一KEY
		if #tCharList > 0 then
			return oRole:Tips("该兑换码已经被使用了")
		end

		if self.m_tOnePersonOneKey[nRoleID.."-"..nGiftID] then
			return oRole:Tips("您已经兑换过该礼包")
		end

		self.m_tOnePersonOneKey[nRoleID.."-"..nGiftID] = true
		self:MarkDirty(true)

	else
		if nType == self.tType.eDuoRenYiKey then
			if table.InArray(nRoleID, tCharList) then
				return oRole:Tips("您已经使用过该兑换码")
			end
		elseif nType == self.tType.eYiRenDuoKey then
			if #tCharList > 0 then
				return oRole:Tips("该兑换码已经被使用了")
			end
		end
	end

	table.insert(tCharList, nRoleID)
	local sSql = string.format("update cdkeycode set charlist='%s',time=%d where `key`='%s';", cjson_raw.encode(tCharList), os.time(), sCDKey)
	if not self.m_oMgrSQL:Query(sSql) then
		return oRole:Tips("更新兑换码失败")
	end

	local tItemList = {}
	for _, tItem in ipairs(tAward) do
		table.insert(tItemList, {nType=tItem[1],nID=tItem[2],nNum=tItem[3]})
	end
	oRole:AddItem(tItemList, "兑换码兑换:"..sCDKey)
	oRole:Tips("兑换成功")
end
