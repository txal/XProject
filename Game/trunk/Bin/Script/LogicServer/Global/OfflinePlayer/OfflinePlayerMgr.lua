--离线玩家管理器
local sOfflinePlayerDB = "OfflinePlayerDB"
local nAutoSaveTick = 5*60*1000

function COfflinePlayerMgr:Ctor()
	self.m_tPlayerMap = {}	--{charid=offlineplayer,...}
	self.m_tDirtyMap = {}
	self.m_nSaveTick = nil
end

function COfflinePlayerMgr:LoadData()
	local tKeys = goSSDB:HKeys(sOfflinePlayerDB)
	for _, sKey in ipairs(tKeys) do
		local sData = goSSDB:HGet(sOfflinePlayerDB, sKey)
		local tData = cjson.decode(sData)
		local oOfflinePlayer = COfflinePlayer:new()
		oOfflinePlayer:LoadData(tData)
		self.m_tPlayerMap[oOfflinePlayer:Get("m_nCharID")] = oOfflinePlayer
	end
	self:AutoSave()
end

function COfflinePlayerMgr:SaveData()
	print("COfflinePlayerMgr:SaveData***")
	if not next(self.m_tDirtyMap) then
		return
	end
	for nCharID in pairs(self.m_tDirtyMap) do
		local oObj = self.m_tPlayerMap[nCharID]
		if oObj then
			local tData =oObj:PackData()
			goSSDB:HSet(sOfflinePlayerDB, nCharID, cjson.encode(tData))
		end
	end
	self.m_tDirtyMap = {}
end

function COfflinePlayerMgr:OnRelease()
	self:SaveData()
	if self.m_nSaveTick then
		GlobalExport.CancelTimer(self.m_nSaveTick)
		self.m_nSaveTick = nil
	end
end

--定时保存
function COfflinePlayerMgr:AutoSave()
	self.m_nSaveTick = GlobalExport.RegisterTimer(nAutoSaveTick, function() self:SaveData() end)
end

--脏标记
function COfflinePlayerMgr:MarkDirty(nCharID, bDirty)
	if bDirty then
		self.m_tDirtyMap[nCharID] = true
	else
		self.m_tDirtyMap[nCharID] = nil
	end
end

--取离线玩家
function COfflinePlayerMgr:GetPlayer(nCharID)
	return self.m_tPlayerMap[nCharID]
end

--玩家上线
function COfflinePlayerMgr:Online(oPlayer)
	local nCharID = oPlayer:GetCharID()
	if self:GetPlayer(nCharID) then
		return
	end
	local oOfflinePlayer = COfflinePlayer:new()
	oOfflinePlayer.m_nCharID = nCharID
	oOfflinePlayer.m_sName = oPlayer:GetName()
	oOfflinePlayer.m_nRoleID = oPlayer:GetRoleID()
	oOfflinePlayer.m_nLevel = oPlayer:GetLevel()
	oOfflinePlayer.m_nVIP = oPlayer:GetVIP()
	self.m_tPlayerMap[nCharID] = oOfflinePlayer
	self:MarkDirty(nCharID, true)
end

--更新等级
function COfflinePlayerMgr:OnLevelChange(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local oOfflinePlayer = self:GetPlayer(nCharID)
	if not oOfflinePlayer then
		return
	end
	oOfflinePlayer:Set("m_nLevel", oPlayer:GetLevel())
	self:MarkDirty(nCharID, true)
end

--更新VIP等级
function COfflinePlayerMgr:OnVIPChange(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local oOfflinePlayer = self:GetPlayer(nCharID)
	if not oOfflinePlayer then
		return
	end
	oOfflinePlayer:Set("m_nVIP", oPlayer:GetVIP())
	self:MarkDirty(nCharID, true)
end

goOfflinePlayerMgr = goOfflinePlayerMgr or COfflinePlayerMgr:new()
