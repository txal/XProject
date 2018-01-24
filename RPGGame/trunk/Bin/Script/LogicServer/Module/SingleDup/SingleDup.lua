local _random, _insert, _floor, _max, _min, _time, _clock = _random, table.insert, math.floor, math.max, math.min, os.time, os.clock

CSingleDup.tDupState = 
{
	eOpen = 1, 	--开放未通关
	ePass = 2, 	--已通关
	eLock = 3,	--未解锁
}

function CSingleDup:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tChapterList = {} 	--{[chapter]={{nDupID=nDupID,nState=nState,nStar=nStar},...},...}
	self.m_tMopupDup = {nDupID=0}
	self.m_tChapterAward = {}	--已领取章节宝箱

	self.m_nCurrDupID = 0		--当前在打的关卡(不保存)
	self:Init()
end

function CSingleDup:GetType()
	return gtModuleDef.tSingleDup.nID, gtModuleDef.tSingleDup.sName
end

function CSingleDup:LoadData(tData)
	self.m_tChapterList = tData.tChapterList or {}
	self.m_tMopupDup = tData.tMopupDup or {nDupID=0}
	self.m_tChapterAward = tData.tChapterAward or {}
	self:Init()
end

function CSingleDup:SaveData()
	local tData = {}
	tData.tChapterList = self.m_tChapterList
	tData.tMopupDup = self.m_tMopupDup
	tData.tChapterAward = self.m_tChapterAward
	return tData
end

function CSingleDup:Offline()
	self.m_nCurrDupID = 0

	if self.m_nMopupTick then
		GlobalExport.CancelTimer(self.m_nMopupTick)
		self.m_nMopupTick = nil
	end
end

function CSingleDup:Online()
	--fix pd
	-- for k = 1, 2 do
	-- 	local tDupConfList = GetChapterDupConf()[k] or {}
	-- 	for _, tDupConf in ipairs(tDupConfList) do
	-- 		self:OnDupPass(tDupConf.nID, 1)
	-- 	end
	-- end

	local nTimeNow = _time()
	local nOfflineTime = self.m_oPlayer:Get("m_nOfflineTime")
	if self.m_tMopupDup.nDupID > 0 then
		local nPassMin = _floor((nTimeNow - nOfflineTime) / 60)
		if nPassMin > 0 then
			local nNormalBook = ctDupMopupConf[1].nNormalBook
			local tNBConf = assert(ctPropConf[nNormalBook])
			local nSuperBook = ctDupMopupConf[1].nSuperBook
			local tSBConf = assert(ctPropConf[nSuperBook])
			local nNBPassMin, nNBMulti = 0, 0
			local nSBPassMin, nSBMulti = 0, 0
			if self.m_tMopupDup[nNormalBook] then
				nNBPassMin = _min(nPassMin, _floor(_max(0, self.m_tMopupDup[nNormalBook] + tNBConf.tValue[2][1] - nOfflineTime) / 60))
				nNBMulti = tNBConf.tValue[1][1]
			end
			if self.m_tMopupDup[nSuperBook] then
				nSBPassMin = _min(nPassMin, _floor(_max(0, self.m_tMopupDup[nSuperBook] + tSBConf.tValue[2][1] - nOfflineTime) / 60))
				nSBMulti = tSBConf.tValue[1][1]
			end
			local tConf = ctSingleDup[self.m_tMopupDup.nDupID]
			local nWinRate = self:CalcWinRate(self.m_tMopupDup.nDupID)
			for _, tItem in ipairs(tConf.tMopupBase) do
				local nType, nItemID, nItemNum = table.unpack(tItem)
				local nBase = nPassMin * nItemNum * 1 * nWinRate / 6
				local nNB = nNBPassMin * nItemNum * nNBMulti * nWinRate / 6
				local nSB = nSBPassMin * nItemNum * nSBMulti * nWinRate / 6
				local nItemNum = _floor(nBase + nNB + nSB)
				if nItemNum > 0 then
					self.m_oPlayer:AddItem(nType, nItemID, nItemNum, gtReason.eDupMopupOffline)
				end
			end	
		end
		self:StartMopup()
	end
end

function CSingleDup:CreateDup(nDupID, nState, nStar)
	local tDup = {nDupID=nDupID, nState=nState, nStar=nStar}
	return tDup
end

function CSingleDup:Init()
	if #GetChapterDupConf() == 0 then
		return
	end
	if #self.m_tChapterList > 0 then
		return
	end
	local tChapter = {}
	self.m_tChapterList[1] = tChapter
	local tDupListConf = GetChapterDupConf()[1]
	for k = 1, 2 do
		local tDupConf = assert(tDupListConf[k])
		local nState = k == 1 and self.tDupState.eOpen or self.tDupState.eLock
		_insert(tChapter, self:CreateDup(tDupConf.nID, nState, 0))
	end
end

function CSingleDup:GetDupData(nDupID)
	local tDupConf = assert(ctSingleDup[nDupID])
	local nChapter = tDupConf.nChapter
	local tChapter = self.m_tChapterList[nChapter]
	local nTarIdx, tTarDup
	for nIndex, tDup in ipairs(tChapter or {}) do
		if nDupID == tDup.nDupID then
			nTarIdx,tTarDup = nIndex, tDup
			break
		end
	end
	return tTarDup, nTarIdx, tChapter
end

function CSingleDup:GetPreDupData(nDupIdx, nDupID)
	local nChapter = ctSingleDup[nDupID].nChapter
	local tChapter = self.m_tChapterList[nChapter]
	if not tChapter then
		return
	end
	if tChapter[nDupIdx-1] then
		return tChapter[nDupIdx-1], nChapter
	end
	local nPreChapter = nChapter - 1
	local tPreChapter = self.m_tChapterList[nPreChapter]
	if tPreChapter then
		return tPreChapter[#tPreChapter], nPreChapter
	end
end

function CSingleDup:GetNextDupConf(nDupIdx, nDupID)
	local nChapter = ctSingleDup[nDupID].nChapter
	local tDupConfList = GetChapterDupConf[nChapter]
	local nNextDupIdx = nDupIdx + 1
	if tDupConfList[nNextDupIdx] then
		return tDupConfList[nNextDupIdx], nNextDupIdx 
	end
	local tNextDupConfList = GetChapterDupConf()[nChapter+1]
	if tNextDupConfList then
		return tNextDupConfList[1], 1
	end
end

function CSingleDup:OnDupPass(nDupID, nStar)
	print("CSingleDup:OnDupPass***", nDupID, nStar)
	local tTarDup, nTarIdx, tChapter = self:GetDupData(nDupID) 
	if not tTarDup then
		return
	end
	local bFirstPass = false
	if tTarDup.nState == self.tDupState.ePass then
		tTarDup.nStar = _max(tTarDup.nStar, nStar)

	elseif tTarDup.nState == self.tDupState.eOpen then
		tTarDup.nStar = nStar
		tTarDup.nState = self.tDupState.ePass
		bFirstPass = true

	else
		assert(false, "关卡状态错误:"..nDupID)
	end
	if self.m_tMopupDup.nDupID == 0 then
		self.m_tMopupDup.nDupID = nDupID
		self:StartMopup()
	end

	--奖励
	local tItemList = {}
	local tDupConf = assert(ctSingleDup[nDupID])
	local tDropItem = DropMgr:GenDropItem(tDupConf.nDupID)
	--首通额外奖励
	if bFirstPass then
		for _, tItem in ipairs(tDupConf.tFirstPass) do
			if tItem[1] > 0 then
				table.insert(tDropItem, tItem)
			end
		end
	end
	for _, tItem in ipairs(tDropItem) do
		local nType, nID, nNum = table.unpack(tItem)
		if nID > 0 then
			local tList = self.m_oPlayer:AddItem(nType, nID, nNum, gtReason.eDupPass) or {}
			local oArm
			if nType == gtObjType.eArm then
				oArm = tList and #tList > 0 and tList[1][2]
			end
			local nColor = GF.GetItemColor(nType, nID, oArm)	
			_insert(tItemList, {nType=nType, nID=nID, nNum=nNum, nColor=nColor})
		end
	end	
	local tData = {nDupID=nDupID, bWin=true, nStar=nStar, tItemList=tItemList}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DupAwardRet", tData)

	--检测新副本开放
	local nLastChapter = #self.m_tChapterList
	local tLastChapter = self.m_tChapterList[nLastChapter]
	local nLastDupIdx = #tLastChapter
	local tLastDup = tLastChapter[nLastDupIdx]	

	local tNewDupConfList = {}
	if tLastDup.nState == self.tDupState.eLock then
		local tPreDup = self:GetPreDupData(nLastDupIdx, tLastDup.nDupID)
		if tPreDup then
			assert(tPreDup.nState ~= self.tDupState.eLock)
			if tPreDup.nState == self.tDupState.eOpen then
				return
			end
		end
		tLastDup.nState = self.tDupState.eOpen
		local tNextDupConf = self:GetNextDupConf(nLastDupIdx, tLastDup.nDupID)
		if tNextDupConf then
			_insert(tNewDupConfList, tNextDupConf)
		end

	elseif tLastDup.nState == self.tDupState.eOpen then
		local tNextDupConf = self:GetNextDupConf(nLastDupIdx, tLastDup.nDupID)
		if tNextDupConf then
			_insert(tNewDupConfList, tNextDupConf)
		end

	elseif tLastDup.nState == self.tDupState.ePass then 
		local tNextDupConf, nNextDupIdx = self:GetNextDupConf(nLastDupIdx, tLastDup.nDupID)
		if tNextDupConf then
			_insert(tNewDupConfList, tNextDupConf)
			local tNextDupConf = self:GetNextDupConf(nNextDupIdx, tNextDupConf.nDupID)
			if tNextDupConf then
				_insert(tNewDupConfList, tNextDupConf)
			end
		end

	end
	assert(tLastDup.nState ~= self.tDupState.eLock)
	for nIdx, tDupConf in ipairs(tNewDupConfList) do
		local nChapter = tDupConf.nChapter
		if not self.m_tChapterList[nChapter] then
			self.m_tChapterList[nChapter] = {}
		end
		local nState
		if tLastDup.nState == self.tDupState.eOpen then
			nState = self.tDupState.eLock
		else
			nState = nIdx == 1 and self.tDupState.eOpen or self.tDupState.eLock
		end
		_insert(self.m_tChapterList[nChapter], self:CreateDup(tDupConf.nID, nState, 0))
	end
end

function CSingleDup:DupBegin(nDupID)
	if self.m_nCurrDupID > 0 then
		return
	end
	local tDupConf = assert(ctSingleDup[nDupID], "单人副本"..nDupID.."不存在")
	if self.m_oPlayer:GetLevel() < tDupConf.nLevelLimit then
		return
	end
	local tTarDup, nTarIdx, tChapter = self:GetDupData(nDupID) 
	if not tTarDup then
		return
	end
	if not tTarDup or tTarDup.nState == self.tDupState.eLock or tTarDup.nStar >= 3 then
		return
	end
	self.m_nCurrDupID = nDupID

	self.m_oPlayer:UpdateBattleAttr()
	local oBagModule = self.m_oPlayer:GetModule(CBagModule:GetType())
	local tSendData = {tWeaponList=oBagModule:GetWeaponList()}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DupBeginRet", tSendData)

	goLogger:EventLog(gtEvent.eDupBegin, self.m_oPlayer, nDupID, tTarDup.nState, tTarDup.nStar)
end

function CSingleDup:DupEnd(nDupID, nStar)
	assert(nStar >= 0 and nStar <= 3, nDupID..":"..nStar)
	if self.m_nCurrDupID <= 0 or nDupID ~= self.m_nCurrDupID then
		return
	end
	self.m_nCurrDupID = 0
	print("CSingleDup:DupEnd***", nDupID, nStar)
	if nStar > 0 then
		self:OnDupPass(nDupID, nStar)
	else
		local tData = {nDupID=nDupID,bWin=false,nStar=0,tItemList={}}
		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DupAwardRet", tData)
	end
	
	goLogger:EventLog(gtEvent.eDupEnd, self.m_oPlayer, nDupID, nStar)
end

function CSingleDup:SyncChapterInfo(nChapter)
	local tChapter
	if nChapter == 0 then
		local nLastChapter = #self.m_tChapterList
		local tLastChapter = self.m_tChapterList[nLastChapter]
		local nLastDupIdx = #tLastChapter
		local tLastDup = tLastChapter[nLastDupIdx]
		if tLastDup.nState == self.tDupState.eOpen or tLastDup.nState == self.tDupState.ePass then
			nChapter = nLastChapter
			tChapter = tLastChapter
		else
			local tPreDupData, nPreChapter = self:GetPreDupData(nLastDupIdx, tLastDup.nDupID)
			assert(nPreChapter)
			nChapter = nPreChapter
			tChapter = self.m_tChapterList[nChapter] 
		end
	else
		tChapter = self.m_tChapterList[nChapter]
	end
	assert(tChapter)
	local nCurrStar = 0
	local tDupList = {}
	for _, tDup in ipairs(tChapter) do
		_insert(tDupList, tDup)		
		nCurrStar = nCurrStar + tDup.nStar
	end
	local nMaxStar = #GetChapterDupConf()[nChapter] * 3
	local tChapterAward = self.m_tChapterAward[nChapter] or {}

	local tData = {tDupList=tDupList, nCurrChapter=nChapter, nMaxChapter=#self.m_tChapterList
		, nCurrStar=nCurrStar, nMaxStar=nMaxStar, tChapterAward=tChapterAward}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ChapterInfoRet", tData)
end

function CSingleDup:StartMopup()
	if self.m_tMopupDup.nDupID <= 0 then
		return
	end
	if self.m_nMopupTick then
		GlobalExport.CancelTimer(self.m_nMopupTick)
	end
	self.m_nMopupTick = GlobalExport.RegisterTimer(ctDupMopupConf[1].nCalcTime*1000, function() self:MopupTimeout() end)
end

function CSingleDup:CalcWinRate(nDupID)
	local tDup = self:GetDupData(nDupID)
	if not tDup then
		return 0
	end
	if tDup.nStar >= 3 then
		return 1
	end
	if tDup.nStar >= 2 then
		return 0.75
	end
	if tDup.nStar >= 1 then
		return 0.5
	end
	return 0
end

function CSingleDup:CalcMuliple()
	local nNormalBook = ctDupMopupConf[1].nNormalBook
	local tNBConf = ctPropConf[nNormalBook]
	local nSuperBook = ctDupMopupConf[1].nSuperBook
	local tSBConf = ctPropConf[nSuperBook]
	local nMutiple = 0
	local nNowTime = _time()
	local nNBExpireTime = self.m_tMopupDup[nNormalBook] or 0
	if nNBExpireTime > nNowTime then
		nMutiple = nMutiple + tNBConf.tValue[1][1]
	end
	local nSBExpireTime = self.m_tMopupDup[nSuperBook] or 0
	if nSBExpireTime > nNowTime then
		nMutiple = nMutiple + tSBConf.tValue[1][1]
	end
	return nMutiple
end

function CSingleDup:MopupTimeout()
	print("CSingleDup:MopupTimeout***")
	if self.m_nMopupTick then
		GlobalExport.CancelTimer(self.m_nMopupTick)
	end
	self.m_nMopupTick = GlobalExport.RegisterTimer(ctDupMopupConf[1].nCalcTime*1000, function() self:MopupTimeout() end)

	local tConf = ctSingleDup[self.m_tMopupDup.nDupID]
	for _, tItem in ipairs(tConf.tMopupBase) do
		local nType, nItemID, nItemNum = table.unpack(tItem)
		local nItemNum = _floor(nItemNum * (1 + self:CalcMuliple()) * self:CalcWinRate(self.m_tMopupDup.nDupID))
		if nItemNum > 0 then
			self.m_oPlayer:AddItem(nType, nItemID, nItemNum, gtReason.eDupMopup)
		end
	end
end

function CSingleDup:SetMopupDup(nDupID)
	local tDup = self:GetDupData(nDupID)
	if not tDup or tDup.nState ~= self.tDupState.ePass then
		return
	end
	self.m_tMopupDup.nDupID = nDupID
	self.m_oPlayer:ScrollMsg(ctLang[1])
end

function CSingleDup:UseProp(nPropID)
	local nTimeNow = _time()
	local nNormalBook = ctDupMopupConf[1].nNormalBook
	local nSuperBook = ctDupMopupConf[1].nSuperBook	
	if nPropID == nNormalBook or nPropID == nSuperBook then
		local nKeepTime = ctPropConf[nPropID].tValue[2][1]
		local nExpireTime = self.m_tMopupDup[nPropID] or 0
		if nExpireTime <= nTimeNow then
			nExpireTime = nTimeNow + nKeepTime
		else
			nExpireTime = nExpireTime + nKeepTime
		end
		self.m_tMopupDup[nPropID] = nExpireTime

	else
		assert(false, "道具使用错误")
	end
end

function CSingleDup:GetChapterAward(nChapter, nAwardID)
	local tChapterAward = self.m_tChapterAward[nChapter] or {}
	for _, nGotAwardID in ipairs(tChapterAward) do
		if nAwardID == nGotAwardID then
			return
		end
	end
	local tChapter = self.m_tChapterList[nChapter]
	if not tChapter then
		return
	end
	local nChapterStar = 0
	for _, tDup in ipairs(tChapter) do
		nChapterStar = nChapterStar + tDup.nStar 
	end
	local tItemList = {}
	local tChapterConf = assert(ctChapterConf[nChapter])
	local tAward = assert(tChapterConf.tAward[nAwardID])
	if nChapterStar < tAward[1] then
		return
	end
	local tDropItem = DropMgr:GenDropItem(tAward[2])
	for _, tItem in ipairs(tDropItem) do
		local nType, nID, nNum = table.unpack(tItem)
		if nID > 0 then
			local tList = self.m_oPlayer:AddItem(nType, nID, nNum, gtReason.eChapterAward)
			local oArm
			if nType == gtObjType.eArm then
				oArm = tList and #tList > 0 and tList[1][2]
			end
			local nColor = GF.GetItemColor(nType, nID, oArm)	
			_insert(tItemList, {nType=nType,nID=nID,nNum=nNum,nColor=nColor})
		end
	end	
	_insert(tChapterAward, nAwardID)
	self.m_tChapterAward[nChapter] = tChapterAward

	local tData = {tChapterAward=tChapterAward, tItemList=tItemList}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "GetChapterAwardRet", tData)
end
