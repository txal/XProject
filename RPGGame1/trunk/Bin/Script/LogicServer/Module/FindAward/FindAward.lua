--找回奖励
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CFindAward.tType = 
{
	eFree = 1, 		--免费领取
	eJinBi = 2, 	--金币领取
	eYuanBao = 3, 	--元宝领取	
}

local _tFingAward = {}
local function PreProcessFindAwardConf()
	for nID, tConf in pairs(ctFindAwardConf) do 
		_tFingAward[tConf.nTaskType] = _tFingAward[tConf.nTaskType] or {}
		table.insert(_tFingAward[tConf.nTaskType], tConf)
	end
end
PreProcessFindAwardConf()

function CFindAward:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tSetTaskTimes = {} 	--记录2日任务剩余次数 {[1]={[nTaskID]=nTimes,...}}
	self.m_nResetTime = 0	--重置时间
	self.m_tFingAward = {} 		--找回奖励数组
	self.m_nFindTimes = 0 		--总找回奖励次数
end 

function CFindAward:LoadData(tData)
	if tData then 
		self.m_tFingAward = tData.m_tFingAward
		self.m_nResetTime = tData.m_nResetTime
		self.m_tSetTaskTimes = tData.m_tSetTaskTimes
		self.m_nFindTimes = tData.m_nFindTimes or 0
	end
	if self.m_nResetTime <= 0 then
		self.m_nResetTime = os.time()
		self:MarkDirty(true)
	end
end

function CFindAward:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tFingAward = self.m_tFingAward
	tData.m_nResetTime = self.m_nResetTime
	tData.m_tSetTaskTimes = self.m_tSetTaskTimes
	tData.m_nFindTimes = self.m_nFindTimes
	return tData
end

function CFindAward:Online(bGM)
	local nCreateTime = self.m_oPlayer:GetCreateTime()
	local nNowTime = os.time()
	if not os.IsSameDay(nCreateTime, nNowTime, 0) then
		--上限推送
		self:FindAwardInfoReq()
	end
end

function CFindAward:FindCountCheck(nPassDays)

end

--获取当天参加的活动次数
function CFindAward:FindAwardInfo()
	local nCreateTime = self.m_oPlayer:GetCreateTime()
	local nNowTime = os.time()
	if not os.IsSameDay(nCreateTime, nNowTime, 0) then
		local nNowTime = os.time()
		local tActDataMap = self.m_oPlayer.m_oDailyActivity.m_tActDataMap
		local nCountComp = 0
		local tActData
		local tActDataList = {}

		if #self.m_tSetTaskTimes >= 2 then
			table.remove(self.m_tSetTaskTimes, 1)
		end 
		local nPassDays = os.PassDay(self.m_nResetTime, nNowTime, 0)
		local nCreateDays = os.PassDay(nCreateTime, nNowTime, 0)
		if nPassDays >= 2  then
			self.m_tSetTaskTimes = {}
			for nKey = 1, 2 do
				local tActDataList = self:GetMaxTwoDays()
				if next(tActDataList) then
					table.insert(self.m_tSetTaskTimes, tActDataList)
				end
			end
		elseif nPassDays == 1 then
			local tActDataList = self:GetTodayCount()
			if next(tActDataList) then
				table.insert(self.m_tSetTaskTimes, tActDataList)
			end
		end
		self.m_nResetTime = nNowTime
		self:MarkDirty(true)
		self:FindAwardInfoReq(1)
		print("找回任务奖励列表", self.m_tSetTaskTimes)
	end
end

function CFindAward:GetType()
	return gtModuleDef.tFindAward.nID, gtModuleDef.tFindAward.sName
end

function CFindAward:GetMaxTwoDays(nDays)
	local tActDataList = {}
	for nActID, tActConf in pairs(ctFATaskAwardConf) do
		if ctDailyActivity[nActID] and self.m_oPlayer:GetLevel() >= ctDailyActivity[nActID].nLevelLimit then
			local nTimesReward =  ctDailyActivity[nActID].nTimesReward
			local nOverFindTimes = nTimesReward 
			local nFindTimes = math.floor(nOverFindTimes / tActConf.nHuanshu)
			if nFindTimes > 0 then
				tActDataList[nActID] = nFindTimes
				self.m_nFindTimes = self.m_nFindTimes + nFindTimes
			end
		end	
	end
	return tActDataList
end

function CFindAward:GetTodayCount()
	local tActDataList = {}
	local tActDataMap = self.m_oPlayer.m_oDailyActivity.m_tActDataMap
	for nActID, tActConf in pairs(ctFATaskAwardConf) do
		tActData = tActDataMap[nActID]
		if tActData and ctDailyActivity[nActID] and self.m_oPlayer:GetLevel() >= ctDailyActivity[nActID].nLevelLimit then
			nCountComp = tActData[gtDailyData.eCountComp]
			local nTimesReward =  ctDailyActivity[nActID].nTimesReward
			local nOverFindTimes = nTimesReward - nCountComp
			local nFindTimes = math.floor(nOverFindTimes / tActConf.nHuanshu)
			if nFindTimes > 0 then
				tActDataList[nActID] = nFindTimes
				self.m_nFindTimes = self.m_nFindTimes + nFindTimes
			end
		end	
	end
	return tActDataList
end
--保存任务剩余次数
function CFindAward:SetTaskRemainTimes(nType, nTimes)
	local tConf = assert(ctFATaskAwardConf[nType], "活动任务ID不存在"..nType)
	if nTimes > 0 then 	
		self.m_tRemainTimes[nType] = math.min(nTimes, tConf.nEveryDayTimes) 
		self:MarkDirty(true)
	end
end

--取等级区间位置
function CFindAward:GetLevelLocation(nType, nLevel)
	for k=#_tFingAward[nType], 1, -1 do 
		local tRank = _tFingAward[nType][k].tLevel 
		if tRank[1][1] <= nLevel then 
			return k 
		end
	end
end

--找回奖励界面请求
function CFindAward:FindAwardInfoReq(nTarType)
	if nTarType then
		if nTarType ~= CFindAward.tType.eFree and nTarType ~= CFindAward.tType.eYuanBao then
			return self.m_oPlayer:Tips("找回类型错误")
		end
	end
	local nCreateTime = self.m_oPlayer:GetCreateTime()
	local nNowTime = os.time()
	if not os.IsSameDay(nCreateTime, nNowTime, 0) then
		local function _InfoReq(nTarType)
			local tList = {}
			local tFindActData = self:HandleFindTimes()
			for nType, nCountComp in pairs(tFindActData or {}) do 
				local nPlayLv = self.m_oPlayer:GetLevel()
				local nLocation = self:GetLevelLocation(nType, nPlayLv)
			 	local tTaskCfg =  ctFATaskAwardConf[nType]
				if nLocation and tTaskCfg then
					local nTimes = nCountComp
					local tInfo = _tFingAward[nType][nLocation]
					local nState = nTimes > 0 and 1 or 0
					local nPetExp = (tTaskCfg.ePetExp(nPlayLv))* (ctFATaskAwardConf[nType].tRewadPercentage[1][nTarType]/100)		--宠物经验
					local nPlayerExp = (tTaskCfg.ePlayerExp(nPlayLv))* (ctFATaskAwardConf[nType].tRewadPercentage[1][nTarType]/100)	--玩家经验
					local nPrice = 0
					local tItem = {}
					if nTarType == CFindAward.tType.eFree then 
						tItem = tInfo.tFreeAward

					--TODD,删掉金币找回
					-- elseif nTarType == CFindAward.tType.eJinBi then 
					-- 	nPrice = tInfo.nCostJB
					-- 	tItem = tInfo.tJBAward

					elseif nTarType == CFindAward.tType.eYuanBao then 
						nPrice = tInfo.nCostYB
						tItem = tInfo.tYBAward
					end 
					local tAward = {}
					for _, tTem in ipairs(tItem) do
						table.insert(tAward, {nItemID=tTem[1], nItemNum=tTem[2]})
					end
					table.insert(tList, {nType=nType, nTimes=nTimes, nState=nState, nPlayerExp=nPlayerExp, nPetExp=nPetExp, nPrice=nPrice, tAward=tAward})
				end
			end
			return {nTarType=nTarType, tList=tList}
		end

		local tFindAward = {} 
		if nTarType then 
			tFindAward[1] = _InfoReq(nTarType)
		else
			for k=1, 3, 1 do 
				if k ~= 2 then
					table.insert(tFindAward, _InfoReq(k))
				end
			end
		end
		local tMsg = {tFindAward=tFindAward, nFindTimes = self.m_nFindTimes}
		self.m_oPlayer:SendMsg("FindAwardInfoRet", tMsg)
	end
end

--一键奖励
function CFindAward:OneKeyFindAwardReq(bUseZY, nTarType)
	if nTarType ~= CFindAward.tType.eFree and nTarType ~= CFindAward.tType.eYuanBao then
		return self.m_oPlayer:Tips("找回类型错误")
	end
	local tActDataList = self:HandleFindTimes()
	if not tActDataList then return end
	if next(tActDataList) == nil then return end
	if self.m_nFindTimes <= 0 then 
		return self.m_oPlayer:Tips("找回奖励次数不足")
	end
	if nTarType ~= CFindAward.tType.eFree then
		if not self:HandleCost(nTarType) then return end
	end
	local nPlayerExp = 0
	local nPetExp = 0
	local tList = {}
	local nPlayLv = self.m_oPlayer:GetLevel()--
	local nSubShuangBei = 0
	local tItemList = {}
	for nType, nTimes in pairs(tActDataList) do 
		local nLocation = self:GetLevelLocation(nType, nPlayLv)
		if nLocation and nTimes > 0 then
			local nTmpPlayerExp, nTmpPetExp = self:GetReardExp(nType, nTimes, nTarType)
			nPetExp = nPetExp + nTmpPetExp
			nPlayerExp = nPlayerExp + nTmpPlayerExp
			local tInfo = _tFingAward[nType][nLocation]
			local tAward = self:GetReard(tInfo, nTarType)
			local nItemNum = tAward[1][2]*nTimes
			tList[#tList+1] = {nItemID = tAward[1][1], nItemNum = nItemNum}
			table.insert(tItemList, {gtItemType.eProp, tAward[1][1], nItemNum, "找回奖励"})
		end
	end
	self:PropCheck(tItemList)
	self:ClearCount()
	self.m_nFindTimes = 0
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eExp, nPlayerExp,"找回奖励获得")
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "找回奖励获得")
	self:MarkDirty(true)
	local tMsg = {tList=tList, nPlayerExp = nPlayerExp, nPetExp = nPetExp}
	self.m_oPlayer:SendMsg("FindAwardGetAwardRet", tMsg)
	self:FindAwardInfoReq(nTarType)
end

function CFindAward:GetReard(tFindAward, nType)
	local tAward
	if nType == CFindAward.tType.eFree then
		tAward = tFindAward.tFreeAward
	elseif nType ==  CFindAward.tType.eJinBi then
		tAward = tFindAward.tJBAward
	elseif nType ==  CFindAward.tType.eYuanBao then
		tAward = tFindAward.tYBAward
	end
	return tAward
end

--计算总的消耗
function CFindAward:HandleCost(nTarType)
	local nCostNum = 0
	local nCurType
	local bRet = false
	local tActDataList = self:HandleFindTimes()
	local nPlayLv = self.m_oPlayer:GetLevel()
	for nType, nTimes in pairs(tActDataList or {}) do 
		local nLocation = self:GetLevelLocation(nType, nPlayLv)
		if nLocation and nTimes > 0 then
			--先处理扣道具
			local tInfo = _tFingAward[nType][nLocation]
			local tAward = tInfo.tFreeAward
			local nCostCurr = self:GetCostCurr(tInfo, nTarType)
			nCostNum = nCostNum + nCostCurr * nTimes
		end
	end
	if nTarType == CFindAward.tType.eJinBi then
		bRet = self.m_oPlayer:CheckSubItem(gtItemType.eCurr, gtCurrType.eJinBi, nCostNum, "找回奖励消耗")
		if not bRet then return  self.m_oPlayer:JinBiTips() end
	elseif nTarType == CFindAward.tType.eYuanBao then
		local nBYB = self.m_oPlayer:GetBYuanBao()
		if nBYB < nCostNum then
			bRet = self.m_oPlayer:CheckSubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nCostNum - nBYB, "找回奖励消耗")
			if not bRet then return self.m_oPlayer:YuanBaoTips() end
			self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eBYuanBao, nBYB, "找回奖励消耗")
		else
			bRet = self.m_oPlayer:CheckSubItem(gtItemType.eCurr, gtCurrType.eBYuanBao, nCostNum, "找回奖励消耗")
		end
	end
	return true
end

function CFindAward:GetCostCurr(tInfo, nTarType)
	if nTarType == CFindAward.tType.eJinBi then
		return tInfo.nCostJB
	elseif nTarType == CFindAward.tType.eYuanBao then
		return tInfo.nCostYB
	end
end

function CFindAward:GetReardExp(nTaskID, nTimes, nTarType)
	local tConf = ctFATaskAwardConf[nTaskID]
	local nRoleExp = 0
	local nPetExp = 0
	local nSubShuangBei = 0
	nPlayLv = self.m_oPlayer:GetLevel()
	nRoleExp = nRoleExp + tConf.ePlayerExp(nPlayLv) *  (tConf.tRewadPercentage[1][nTarType]/100)
	nPetExp = nPetExp + tConf.ePetExp(nPlayLv) *  (tConf.tRewadPercentage[1][nTarType]/100)
	return nRoleExp *nTimes ,nPetExp * nTimes
end

--领取奖励请求
function CFindAward:FindAwardGetAwardReq(nTarType, nType, bUseZY, bYB)
	if nTarType ~= CFindAward.tType.eFree and nTarType ~= CFindAward.tType.eYuanBao then
		return self.m_oPlayer:Tips("找回类型错误")
	end
	local tActData = self:HandleFindTimes()
	if not tActData[nType] then
		return self.m_oPlayer:Tips("数据错误")
	end	
	if tActData[nType] < 1 then
		return self.m_oPlayer:Tips("该奖励次数不足")
	end
	local nNum = 1
	local tList = {nPlayerExp=0, nPetExp=0, tItem={}}
	local tAward = {}
	local nPlayLv = self.m_oPlayer:GetLevel()
	if nTarType == CFindAward.tType.eFree then 
		local nLocation = self:GetLevelLocation(nType, nPlayLv)
		local tInfo = _tFingAward[nType][nLocation]
		tAward = tInfo.tFreeAward
	elseif nTarType == CFindAward.tType.eYuanBao then 
		local nLocation = self:GetLevelLocation(nType, nPlayLv)
		local tInfo = _tFingAward[nType][nLocation]
		local nPrice = tInfo.nCostYB
		local nBYB = self.m_oPlayer:GetBYuanBao()		
		--优先使用绑定元宝,不足使用非绑定元宝补足
		if not self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nPrice, "找回奖励消耗") then 
			return self.m_oPlayer:YuanBaoTips()
		end
		tAward = tInfo.tYBAward
	end 
	self:SubItemCount(nType)
	self.m_nFindTimes = self.m_nFindTimes - 1
	self:MarkDirty(true)
	local tConf = ctFATaskAwardConf[nType]
	local nPlayerExp = (tConf.ePlayerExp(nPlayLv))*nNum * (ctFATaskAwardConf[nType].tRewadPercentage[1][nTarType]/100)	--玩家经验
	local nPetExp = (tConf.ePetExp(nPlayLv))*nNum * (ctFATaskAwardConf[nType].tRewadPercentage[1][nTarType]/100)		--宠物经验
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eExp, nPlayerExp, "找回奖励获得")
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "找回奖励获得")
	local tItemList = {}
	for _, tInfo in ipairs(tAward) do 
		local nItemNum = tInfo[2]*nNum
		table.insert(tList.tItem, {nItemID=tInfo[1], nItemNum=nItemNum})
		table.insert(tItemList, {gtItemType.eProp, tInfo[1], nItemNum, "找回奖励"})
	end
	self:PropCheck(tItemList)
	local tMsg = {tList=tList, nPlayerExp = nPlayerExp, nPetExp = nPetExp}
	self.m_oPlayer:SendMsg("FindAwardGetAwardRet", tMsg)
	self:FindAwardInfoReq(nTarType)
end

function CFindAward:PropCheck(tItemList)
	local oKnapaskModel = self.m_oPlayer.m_oKnapsack
	local tPropList = {}
	local tGiftList = {}
	for _, tItem in ipairs(tItemList) do
		local tItemCfg = ctPropConf[tItem[2]]
		assert(tItemCfg, "配置文件不存在")
		if tItemCfg.nType == gtPropType.eGift then
			local tGiftConf = assert(ctGiftConf[tItem[2]], "礼包配置不存在")
			if tGiftConf.bUse then --获得即直接使用的礼包
				bBind = true  --获取即开启的礼包，强制设为绑定，背包格子不足时，将变成绑定道具投放到背包或者邮箱
				local oTempGift = oKnapaskModel:CreateProp(tItem[2], 0, bBind, tPropExt) --创建一个和玩家背包关联的临时道具
				local tPropList = oTempGift:Open(tItem[3], true)
				if #tPropList > 0 then
					table.insert(tGiftList, tPropList)
				end
				-- for k = 1, tItem[3] do 
				-- 	local tPropList = oTempGift:Open(true)
				-- 	if #tPropList > 0 then
				-- 		table.insert(tGiftList, tPropList)
				-- 	end
				-- end
			end
		else
			table.insert(tPropList, tItem)
		end
	end
	self:PropIsFullCheck(tGiftList)
	self:PropAward(tPropList)
end

--礼包道具合并
function CFindAward:GiftPropMerge(tItemList)
	local tTmepList = {}
	local function _CheckItem(tItemList, tProp)
		local bFalg
		for _, tItem in ipairs(tItemList) do
			if tItem.nID == tProp.nID and (tItem.bBind == tProp.bBind) then
				tItem.nNum = tItem.nNum + tProp.nNum
				bFalg = true
				break
			end 
		end
		if not bFalg then
			table.insert(tTmepList, tProp)
		end
	end

	for _, tItem in ipairs(tItemList) do
		for _, tProp in ipairs(tItem) do
			_CheckItem(tTmepList, tProp)
		end
	end
	return tTmepList
end


function CFindAward:PropIsFullCheck(tItemList, bFalg)
	if not bFalg then
		tItemList = self:GiftPropMerge(tItemList)
	end
	local function _SendMaill(tMaillList)
		CUtil:SendMail(self.m_oPlayer:GetServer(), "背包已满", "背包已满，请及时领取邮件", tMaillList, self.m_oPlayer:GetID())
		self.m_oPlayer:Tips("背包已满,背包已满，请及时领取邮件")
	end 
	if #tItemList > 0 then
		local tMaillList = {}
		for _, tItem in ipairs(tItemList) do
			if tItem.nType == gtItemType.eCurr then
				self.m_oPlayer:AddItem(tItem.nType, tItem.nID, tItem.nNum, "开礼包", false, tItem.bBind, tItem.tPropExt)

			elseif tItem.nType == gtItemType.eProp and ctPropConf[tItem.nID] and ctPropConf[tItem.nID].nType ~= gtPropType.eCurr then
				local nNum =self.m_oPlayer.m_oKnapsack:GetRemainCapacity(tItem.nID, tItem.bBind)
				if nNum > 1 then
					nNum = nNum > tItem.nNum and tItem.nNum or nNum
					self.m_oPlayer:AddItem(tItem.nType, tItem.nID, tItem.nNum, "开礼包", false, tItem.bBind, tItem.tPropExt)
					tItem.nNum= tItem.nNum - nNum
					if tItem.nNum > 0 then
						table.insert(tMaillList, {tItem.nType, tItem.nID, tItem.nNum, tItem.bBind or false, tItem.tPropExt})
						if #tMaillList == 15 then
							_SendMaill(tMaillList)
							tMaillList = {}
						end
					end
				else
					table.insert(tMaillList, {tItem.nType, tItem.nID, tItem.nNum, tItem.bBind or false, tItem.tPropExt})
					if #tMaillList == 15 then
						_SendMaill(tMaillList)
						tMaillList = {}
					end
				end
			else
				self.m_oPlayer:AddItem(tItem.nType, tItem.nID, tItem.nNum, "开礼包", false, tItem.bBind, tItem.tPropExt)
			end
		end
		if #tMaillList > 0 then
			_SendMaill(tMaillList)
		end
	end
end

function CFindAward:PropAward(tItemList)
	local tTmepList = {}
	local _PropCheck = function (tItemList, tItem)
		local bFalg
		for _, tProp in ipairs(tItemList) do
			if tProp.nID == tItem[2] and (tProp.bBind or false == tItem[6] or false) then
				tProp.nNum = tItem.nNum + tItem[3]
				bFalg = true
				break
			end 
		end
		if not bFalg then
			table.insert(tTmepList, {nType = tItem[1], nID = tItem[2], nNum = tItem[3]})
		end
	end

	for _, tItem in ipairs(tItemList) do
		_PropCheck(tTmepList, tItem)
	end
	self:PropIsFullCheck(tTmepList, true)
end

--GM生成找回奖励次数
function CFindAward:GMAddFindTimes(nDays)
	if nDays then 
		self.m_tSetTaskTimes = {}
		nDays = math.max(1, math.min(2, nDays))	
		for k=1, nDays do 
			self.m_tSetTaskTimes[k] = self.m_tSetTaskTimes[k] or {}
			for nID, tFind in pairs(ctFATaskAwardConf) do 
				self.m_tSetTaskTimes[k][nID] = (self.m_tSetTaskTimes[k][nID] or 0) + tFind.nEveryDayTimes
			end
		end
		self:MarkDirty(true)
		self.m_oPlayer:Tips("生成成功")
		self:Online(true)
	end
end

--处理找回次数
function CFindAward:HandleFindTimes()
	local tFindTimes = {}
	local tFindActListOne = self.m_tSetTaskTimes[1]
	local tFindActListTwo = self.m_tSetTaskTimes[2]
	for nActID, nCountComp in pairs(tFindActListOne or {}) do
		tFindTimes[nActID] = nCountComp
	end
	for nActID, nCountComp in pairs(tFindActListTwo or {}) do
		tFindTimes[nActID] = (tFindTimes[nActID] or 0) + nCountComp
	end
	return tFindTimes
end

--扣次数
function CFindAward:SubItemCount(nTaskID)
	local tFindActListOne = self.m_tSetTaskTimes[1]
	local tFindActListTwo = self.m_tSetTaskTimes[2]
	--优先扣第二天的数据
	if tFindActListTwo and tFindActListTwo[nTaskID] and tFindActListTwo[nTaskID] >= 1 then
		tFindActListTwo[nTaskID] = tFindActListTwo[nTaskID] - 1
	elseif tFindActListOne and tFindActListOne[nTaskID] and tFindActListOne[nTaskID] >= 1 then
		tFindActListOne[nTaskID] = tFindActListOne[nTaskID] - 1
	end
	self:MarkDirty(true)
end

function CFindAward:ClearCount()
	local tFindActListOne = self.m_tSetTaskTimes[1]
	local tFindActListTwo = self.m_tSetTaskTimes[2]
	
	for nTaskID, nCountComp in pairs(tFindActListOne or {}) do
		tFindActListOne[nTaskID] = 0
	end

	for nTaskID, nCountComp in pairs(tFindActListTwo or {}) do
		tFindActListTwo[nTaskID] = 0
	end
	self:MarkDirty(true)
end

--凌晨刷新(测试用)
function CFindAward:ZeroUpdate()
	self:FindAwardInfo()

	--调用日程模块刷新数据
	self.m_oPlayer.m_oDailyActivity:ResetData()
	--self.m_oPlayer.m_oDailyActivity:CheckCanJoin()
	self.m_oPlayer:Tips("找回奖励刷新成功")
end