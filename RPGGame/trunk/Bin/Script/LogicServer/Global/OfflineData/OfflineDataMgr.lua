local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--离线玩家管理器
local nAutoSaveTime = 5*60

function COfflineDataMgr:Ctor()
	self.m_tPlayerMap = {}	--{charid=OfflineData,...}
	self.m_tDirtyMap = {} 	--玩家离线数据脏数据

	self.m_oJJCData = CJJCData:new(self) --军机处数据
	self.m_oPartyData = CPartyData:new(self) --宴会数据
	self.m_oGSGData = CGSGData:new(self) --国史馆
	self.m_nSaveTick = nil
end

function COfflineDataMgr:LoadData()
	--玩家离线数据
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sOfflineDataDB)
	print("加载离线玩家数据:", #tKeys)
	for _, sKey in ipairs(tKeys) do
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sOfflineDataDB, sKey)
		local tData = cjson.decode(sData)
		if tData.m_nCharID then
			local oOfflineData = COfflineData:new()
			oOfflineData:LoadData(tData)
			local nCharID = oOfflineData:Get("m_nCharID")
			self.m_tPlayerMap[nCharID] = oOfflineData
		end
	end

	------其他数据------
	self.m_oJJCData:LoadData()
	self.m_oPartyData:LoadData()
	self.m_oGSGData:LoadData()

	--定时保存
	self:AutoSave()
end

function COfflineDataMgr:SaveData()
	print("COfflineDataMgr:SaveData***")
	
	--玩家离线数据
	for nCharID in pairs(self.m_tDirtyMap) do
		local oObj = self.m_tPlayerMap[nCharID]
		if oObj then
			local tData =oObj:SaveData()
			goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sOfflineDataDB, nCharID, cjson.encode(tData))
		end
	end
	self.m_tDirtyMap = {}

	------其他数据------
	self.m_oJJCData:SaveData()
	self.m_oPartyData:SaveData()
	self.m_oGSGData:SaveData()
end

function COfflineDataMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
	self:SaveData()

	self.m_oJJCData:OnRelease()
	self.m_oPartyData:OnRelease()
	self.m_oGSGData:OnRelease()

end

--定时保存
function COfflineDataMgr:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

--脏标记
function COfflineDataMgr:MarkDirty(nCharID, bDirty)
	assert(nCharID, "玩家ID不能为空")
	bDirty = bDirty and true or nil
	self.m_tDirtyMap[nCharID] = bDirty
end

--取离线玩家
function COfflineDataMgr:GetPlayer(nCharID)
	return self.m_tPlayerMap[nCharID]
end

--玩家上线
function COfflineDataMgr:Online(oPlayer)
	local nCharID = oPlayer:GetCharID()
	if not self:GetPlayer(nCharID) then
		local oOfflineData = COfflineData:new()
		oOfflineData.m_nCharID = nCharID
		oOfflineData.m_nVIP = oPlayer:GetVIP()
		oOfflineData.m_sName = oPlayer:GetName()
		oOfflineData.m_nWeiWang = oPlayer:GetWeiWang()
		self.m_tPlayerMap[nCharID] = oOfflineData
		self:MarkDirty(nCharID, true)
		self.m_oJJCData:UpdateWeiWang(oPlayer, oPlayer:GetWeiWang(), oPlayer:GetWeiWang())
	end
	self.m_oPartyData:Online(oPlayer)
	self.m_oGSGData:Online(oPlayer)
end

--更新VIP等级
function COfflineDataMgr:UpdateVIP(oPlayer, nVIP)
	local nCharID = oPlayer:GetCharID()
	local oOfflineData = self:GetPlayer(nCharID)
	if not oOfflineData then
		return
	end
	if oOfflineData.m_nVIP == nVIP then
		return
	end
	oOfflineData.m_nVIP = nVIP
	self:MarkDirty(nCharID, true)
end

--更新威望
function COfflineDataMgr:UpdateWeiWang(oPlayer, nVal)
	local nCharID = oPlayer:GetCharID()
	local oOfflineData = self:GetPlayer(nCharID)
	if not oOfflineData then
		return
	end
	local nOldWW = oOfflineData.m_nWeiWang
	oOfflineData.m_nWeiWang = nVal
	self:MarkDirty(nCharID, true)

	--军机处
	self.m_oJJCData:UpdateWeiWang(oPlayer, nOldWW, nVal)
end

--更新等级
function COfflineDataMgr:UpdateLevel(oPlayer, nVal)
	local nCharID = oPlayer:GetCharID()
	local oOfflineData = self:GetPlayer(nCharID)
	if not oOfflineData then
		return
	end
	oOfflineData.m_nLevel = nVal
	self:MarkDirty(nCharID, true)

end

--改名
function COfflineDataMgr:ModName(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local oOfflineData = self:GetPlayer(nCharID)
	if not oOfflineData then
		return
	end
	oOfflineData:Set("m_sName", oPlayer:GetName())
	self:MarkDirty(nCharID, true)
end

--取名字(可以改名惹的祸)
function COfflineDataMgr:GetName(nCharID)
	local oOfflineData = self:GetPlayer(nCharID)
	if not oOfflineData then
		return "不存在"
	end
	return oOfflineData.m_sName or "数据错误"
end

--更新皇子数量
function COfflineDataMgr:UpdateChildNum(oPlayer, nChildNum)
	local nCharID = oPlayer:GetCharID()
	local oOfflineData = self:GetPlayer(nCharID)
	if not oOfflineData then
		return
	end
	if oOfflineData.m_nChildNum == nChildNum then
		return
	end
	oOfflineData.m_nChildNum = nChildNum
	self:MarkDirty(nCharID, true)
end

--更新已通关的章节
function COfflineDataMgr:UpdateChapter(oPlayer, nChapter)
	local nCharID = oPlayer:GetCharID()
	local oOfflineData = self:GetPlayer(nCharID)
	if not oOfflineData then
		return
	end
	if oOfflineData.m_nChapter == nChapter then
		return
	end
	oOfflineData.m_nChapter = nChapter
	self:MarkDirty(nCharID, true)
end

--更新充值
function COfflineDataMgr:UpdateRecharge(oPlayer, nRecharge)
	local nCharID = oPlayer:GetCharID()
	local oOfflineData = self:GetPlayer(nCharID)
	if not oOfflineData then
		return
	end
	if oOfflineData.m_nRecharge == nRecharge then
		return
	end
	oOfflineData.m_nRecharge = nRecharge
	self:MarkDirty(nCharID, true)
end


goOfflineDataMgr = goOfflineDataMgr or COfflineDataMgr:new()
