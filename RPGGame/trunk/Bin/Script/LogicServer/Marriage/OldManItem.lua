--月老物品的刷新
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nOldManMonsterID = 44		--月老怪物

function COldManItem:Ctor(MarriageSceneMgr)
	self.m_oMarriageSceneMgr = MarriageSceneMgr
	self.m_tOldManItemList = {}	 --self.m_tOldManItemList[ID] = AOIID
	self.m_nGiftTimer = nil          --TODO
	self.m_nRefreshTimer = nil
	self.m_bOldManItemState = nil
	self:RegOnGiftTimer()
	self.m_tPickRecord = {}		--self.m_tPickRecord[nRoleID]
end

function COldManItem:OnRelease()
	self:ResetState()
end

function COldManItem:ResetState()
	self:CleanOldManItem()
	self:CleanOldManItemRefreshTimer()
	self:CleanOldManItemTimer()
end

function COldManItem:RegOnGiftTimer()
	self.m_nRefreshTimer = goTimerMgr:Interval(1, function () self:CheckOldManItemTimeOut() end)
end

function COldManItem:CheckOldManItemTimeOut()
	local tItemCfg = self:GetOldManCfg()
	assert(tItemCfg, "月老刷新物品道具配置错误")
	local nOpenTime = self:GetItemStamp(tItemCfg.nOpenTime)
	local nCloseTime = self:GetItemStamp(tItemCfg.nCloseTime)
	local nSec = os.time()
	if nSec >= nOpenTime and nSec < nCloseTime then
		if not self.m_bOldManItemState then
			local nLaveTime = nCloseTime - nSec
			local nLastTime = tItemCfg.nLastTime * 60
			nLaveTime = nLaveTime > nLastTime and nLastTime or nLaveTime
			self.m_nGiftTimer = goTimerMgr:Interval(nLaveTime, function () self:CloseOldManItemTimeOut() end)
			assert(self.m_nGiftTimer, "定时器错误")
			self.m_bOldManItemState = true
			--条件范围内刷新
			self:RefreshItem()
		end
	end
end

function COldManItem:CloseOldManItemTimeOut()
	self:CleanOldManItem()
	self:CleanOldManItemTimer()
	self.m_bOldManItemState = nil
	self.m_tPickRecord = {}
end

function COldManItem:IsPickRecord(nRoleID)
	assert(nRoleID, "参数错误")
	return self.m_tPickRecord[nRoleID]
end

function COldManItem:AddPickCount(nRoleID, nCount)
	self.m_tPickRecord[nRoleID] = (self.m_tPickRecord[nRoleID] or 0) + nCount
end

function COldManItem:GetItemStamp(nTime)
	assert(nTime, "时间错误")
    local nLastTime = math.max(nTime, 0) 
    local tDate = os.date("*t", os.time())
    if nLastTime >= 2400 then
        tDate.hour = 23
        tDate.min = 59
        tDate.sec = 59
    else
        tDate.hour = math.floor(nLastTime / 100)
        tDate.min = math.floor(nLastTime % 100)
        tDate.sec = 0
    end
   return os.MakeTime(tDate.year, tDate.month, tDate.day, tDate.hour, tDate.min, tDate.sec) 
end

--道具刷新
function COldManItem:RefreshItem()
	local tItemCfg = ctOldManItemConf[44]
	assert(tItemCfg, "月老刷新物品道具配置错误")
	local nOldManNum = tItemCfg.nRefreshItemNum
	local nWeddingNpc = tItemCfg.nOldManNpcID   --月老  --TODO
	local tNpcConf = ctNpcConf[nWeddingNpc]
	assert(tNpcConf)
	local tNpcPos = tNpcConf.tPos[1]
	local tDupConf = goMarriageSceneMgr:GetScene():GetConf()
	assert(tDupConf)
	local nRadius = 400
	local nEdgeDistance = 150 --靠近地图边界范围限定
	assert(tDupConf.nWidth >= (100 + 2*nEdgeDistance))
	assert(tDupConf.nHeight >= (100 + 2*nEdgeDistance))
	local nPosXMin = math.floor(math.max(nEdgeDistance, tNpcPos[1] - nRadius))
	local nPosXMax = math.floor(math.min(tDupConf.nWidth - nEdgeDistance, tNpcPos[1] + nRadius))
	local nPosYMin = math.floor(math.max(nEdgeDistance, tNpcPos[2] - nRadius))
	local nPosYMax = math.floor(math.min(tDupConf.nHeight - nEdgeDistance, tNpcPos[2] + nRadius))
	print("====================================")
	print(string.format("月老道具刷新半径 X(%d, %d), Y(%d, %d)", 
		nPosXMin, nPosXMax, nPosYMin, nPosYMax))
	print("====================================")

	--刷新月老物品
	for k = 1, nOldManNum do
		local nPosX = math.random(nPosXMin, nPosXMax)
		local nPosY = math.random(nPosYMin, nPosYMax)
		local oOldMan = goMonsterMgr:CreatePublicNpcWithEnter(gtMonType.eOldManNpc, tItemCfg.nID, 
			goMarriageSceneMgr:GetSceneMixID(), nPosX, nPosY)
		if oOldMan then
			local nOldManID = oOldMan:GetID()
			self.m_tOldManItemList[nOldManID] = oOldMan:GetAOIID()
			print(string.format("刷新月老道具NPC 第%d个, ID:%d", k, nOldManID))
		end
	end
	local oScene = goMarriageSceneMgr:GetScene()
	assert(oScene, "场景丢失")
	oScene:BroadcastScene(-1, "MarriageWeddingCandyNotifyRet", {})
	CEventHandler:OldManItemRefresh({})
end

function COldManItem:RemoveOldMan(nOldManID)
	goMonsterMgr:RemoveMonster(nOldManID)
	self.m_tOldManItemList[nOldManID] = nil
	print(string.format("移除月老道具NPC, ID:%d", nOldManID))
end

--释放
function COldManItem:CleanOldManItem()
	for k, v in pairs(self.m_tOldManItemList) do
		goMonsterMgr:RemoveMonster(k)
		print(string.format("移除月老物品NPC, ID:%d", k))
	end
	self.m_tOldManItemList = {}
	self.m_tPickRecord = {}
	print(">>>>>>>>>> 移除所有月老物品 <<<<<<<<<<")
end

function COldManItem:CleanOldManItemTimer()
	if self.m_nGiftTimer then
		goTimerMgr:Clear(self.m_nGiftTimer)
		self.m_nGiftTimer = nil
	end
end

function COldManItem:CleanOldManItemRefreshTimer()
	if self.m_nRefreshTimer then
		goTimerMgr:Clear(self.m_nRefreshTimer)
		self.m_nRefreshTimer = nil
	end
end

function COldManItem:GetOldManItemState()
	return self.m_bOldManItemState
end

function COldManItem:SetOldManItemState(bValue)
	self.m_bOldManItemState = bValue
end

function COldManItem:GetOldManCfg()
	local tItemCfg = ctOldManItemConf[44]
	assert(tItemCfg, "月老刷新物品道具配置错误")
	return tItemCfg
end

function COldManItem:PickItemState(oRole, nAOIID, nMonsterID, oDup)
	if not self.m_oMarriageSceneMgr:PickCheck(oRole, nAOIID, nMonsterID, oDup) then
		return
	end
	if self:IsPickRecord(oRole:GetID()) then
		oRole:Tips("这一批礼物您已经领过了，给别人留点吧")
	end
	local bState = true
	if self:IsPickRecord(oRole:GetID()) then
		bState = false
	end
	local tMsg = {bState = bState, nAOIID = nAOIID,nMonsterID = nMonsterID}
	oRole:SendMsg("MarriagePickItemStateRet",tMsg)
end