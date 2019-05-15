--赠送对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGift:Ctor(oGiftMgr, nRoleID)
	self.m_oGiftMgr = oGiftMgr
	self.m_nRoleID = nRoleID
	self.m_tRecieveList = {}  --{nPropID:nNum, ...}
	self.m_tGiftList = {} 	-- self.m_tGiftList[nRoleID] = {nGiftNum = nGiftNum}
	self.m_tRecord = {}		--玩家赠送记录 self.m_tRecord = {[1]} = {nGiftTime = time, nPropID =  1000, nPropNum = 1, nRoleID = nRoleID, sRoleName = sRoleName}
	self.m_bDirty = false
end
	
function CGift:LoadData(tData)
	if tData then
		self.m_tGiftList = tData.m_tGiftList or {}
		self.m_tRecieveList = tData.m_tRecieveList or {}
		self.m_tRecord = tData.m_tRecord or {}
	end
end

function CGift:SaveData()
	local tData = {}
	tData.m_nRoleID = self.m_nRoleID
	tData.m_tRecieveList = self.m_tRecieveList
	tData.m_tGiftList = self.m_tGiftList
	tData.m_tRecord = self.m_tRecord
	return tData
end

--获取玩家赠送道具个数
function CGift:GetGiftNum(nTarRoleID)
	-- if not self.m_tGiftList[nTarRoleID] then
	-- 	self.m_tGiftList[nTarRoleID] = {nGiftNum = 0}
	-- 	return 	self.m_tGiftList[nTarRoleID].nGiftNum
	-- else
	-- 	return self.m_tGiftList[nTarRoleID].nGiftNum
	-- end
	--发生赠送关系时，才添加赠送记录
	local tTarRoleSendNum = self.m_tGiftList[nTarRoleID]
	if not tTarRoleSendNum then 
		return 0
	end
	return tTarRoleSendNum.nGiftNum or 0
end

function CGift:GetRecord()
	return self.m_tRecord
end

--增加赠送次数
function CGift:AddGiftNum(nTarRoleID, nNum)
	if not self.m_tGiftList[nTarRoleID] then
		self.m_tGiftList[nTarRoleID] = {nGiftNum = nNum or 0}
	else
		self.m_tGiftList[nTarRoleID].nGiftNum = self.m_tGiftList[nTarRoleID].nGiftNum + nNum 
	end
	self:MarkDirty(true)
end

--副本,预留
function CGift:GetRecordInfo1()
	local tGiftList = {}
	for _, tRecord in ipairs(self.m_tRecord) do
		local tInfo = {}
		tInfo.nGiftTime = os.date("%Y-%m-%d %H:%M:%S",tRecord.nGiftTime)
		tInfo.nPropID = tRecord.nPropID
		tInfo.nPropNum = tRecord.nPropNum
		tInfo.nRoleID = tRecord.nRoleID
		tInfo.sRoleName = tRecord.sRoleName
		tGiftList[#tGiftList+1] = tInfo
	end
	return tGiftList
end

--获取玩家赠送记录信息
function CGift:GetRecordInfo()
	local tGiftList = {}
	for k, tRecord in ipairs(self.m_tRecord) do
		local tInfo = {}
		tInfo.nRoleID = tRecord.nRoleID
		tInfo.sRoleName = tRecord.sRoleName
		tInfo.nGiftTime = os.date("%Y-%m-%d %H:%M:%S",tRecord.nGiftTime)
		tInfo.tItemList = {}
		for _, tItem in ipairs(tRecord.tItemList) do
			tInfo.tItemList[#tInfo.tItemList+1] = {nPropID = tItem.nPropID, nPropNum = tItem.nPropNum, nPropName = ctPropConf[tItem.nPropID].sName}
		end
		tGiftList[#tGiftList+1] = tInfo
	end
	return tGiftList
end

function CGift:GetRecordInfo1()
	
end

--添加赠送记录信息
function CGift:AddRecord(oRole, tItemList)
	local tRecord = {}
	tRecord.sRoleName = oRole:GetName()
	tRecord.nRoleID =  oRole:GetID()
	tRecord.nGiftTime = os.time()
	tRecord.tItemList = {}
	for k , tItem in pairs(tItemList) do
		tRecord.tItemList[#tRecord.tItemList+1] = {nPropID = tItem.nPropID, nPropNum = tItem.nSendNum}
	end

	--50份记录满了以后,删掉时间最久的那一份
	if #self.m_tRecord >= 50 then 
		table.remove(self.m_tRecord, 1)
	end
	table.insert(self.m_tRecord, tRecord)
	self:MarkDirty(true)
end

function CGift:ItemGiftCount(nPropID, nNum)
	assert(nPropID > 0 and nNum)
	self.m_tRecieveList[nPropID] = (self.m_tRecieveList[nPropID] or 0) + nNum
	self:MarkDirty(true)
end

function CGift:GetGiftCount(nPropID)
	local nNum = self.m_tRecieveList[nPropID]
	return nNum or 0
end

function CGift:OnRelease() end

function CGift:MarkDirty(bDirty)
	self.m_bDirty = bDirty
	if self.m_bDirty then 
		goCGiftMgr.m_tDirtyMap[self.m_nRoleID] = self.m_nRoleID
	end
end
function CGift:IsDirty() return self.m_bDirty end

function CGift:GetID() return self.m_nRoleID end

function CGift:DailyReset()
	local bDirty = false
	if next(self.m_tGiftList) then 
		self.m_tGiftList = {}
		bDirty = true
	end
	if next(self.m_tRecieveList) then 
		self.m_tRecieveList = {}
		bDirty = true
	end
	if bDirty then 
		self:MarkDirty(true)
	end
end

