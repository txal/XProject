--离线任务(全服性质的任务保存在这里,玩家上线的时候来拉取)
local nAutoSaveTime = 5*60

function COfflineTask:Ctor()
	self.m_tLianYinMap = {} --{[nID..nCharID...}  	--全服联姻

	self.m_bDirty = false
	self.m_nSaveTick = nil
end

function COfflineTask:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sOfflineTaskDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_tLianYinMap = tData.m_tLianYinMap
	end
	self:AutoSave()
end

function COfflineTask:SaveData()
	if not self.m_bDirty then
		return
	end
	self.m_bDirty = false

	local tData = {}
	tData.m_tLianYinMap = self.m_tLianYinMap
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sOfflineTaskDB, "data", cjson.encode(tData))
end

function COfflineTask:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil

	self:SaveData()
end

--定时保存
function COfflineTask:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

--脏标记
function COfflineTask:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

----------------联姻-----------------
--取联姻任务
function COfflineTask:GetLianYinTask()
	self:CheckLianYinTask()
	return self.m_tLianYinMap
end

--增加联姻任务
function COfflineTask:AddLianYinTask(oPlayer, tHZData)
	self:CheckLianYinTask()
	local sKey = tHZData.nID..tHZData.nCharID
	if self.m_tLianYinMap[sKey] then
		return oPlayer:Tips("该皇子已有全服联姻请求")
	end
	self.m_tLianYinMap[sKey] = tHZData
	self:MarkDirty(true)
	return true
end

--检测联姻过期
function COfflineTask:CheckLianYinTask()
	local nLYTime = ctHZEtcConf[1].nLYTime
	for sKey, tHZData in pairs(self.m_tLianYinMap) do
		if tHZData.nTime + nLYTime <= os.time() then
			self.m_tLianYinMap[sKey] = nil
			self:MarkDirty(true)
		end
	end
end

--标记联姻已处理
function COfflineTask:MarkLianYin(sKey, nCharID)
	local tHZData = self.m_tLianYinMap[sKey]
	if not tHZData then
		return 
	end
	tHZData.tPullMap = tHZData.tPullMap or {}
	tHZData.tPullMap[nCharID] = 1
	self:MarkDirty(true)
end

--移除全服联姻请求
function COfflineTask:RemoveLianYin(sKey)
	if self.m_tLianYinMap[sKey] then
		self.m_tLianYinMap[sKey] = nil
		self:MarkDirty(true)
	end
end

goOfflineTask = goOfflineTask or COfflineTask:new()
