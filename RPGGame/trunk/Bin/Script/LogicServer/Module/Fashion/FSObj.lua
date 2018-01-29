local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--特性个数
CFSObj.nMaxCharCount = 14
--时装对象
function CFSObj:Ctor(oModule, oPlayer, nID)
	self.m_oModule = oModule
	self.m_oPlayer = oPlayer

	self.m_nID = nID
	self.m_nLv = 1				--时装等级
	self.m_nSGLv = 0 			--强化等级 
	self.m_nSGExp = 0			--强化经验
	self.m_nADLv = 0 			--进阶等级

	self.m_tAttr = {} 			--总属性
	self.m_tChar = {} 			--总特性

	self:Init()
end

function CFSObj:Init()
	local tConf = ctFashionConf[self.m_nID]
	self.m_nADLv = tConf.nPj
	self:MarkDirty(true)
end

function CFSObj:LoadData(tData)
	for sKey, xVal in pairs(tData) do
		self[sKey] = xVal
		if sKey == "m_nADLv" and xVal == 0 then
			local tConf = ctFashionConf[self.m_nID]
			self[sKey] = tConf.nPj
		end
	end
end

function CFSObj:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_nLv = self.m_nLv
	tData.m_nSGLv = self.m_nSGLv
	tData.m_nSGExp = self.m_nSGExp
	tData.m_nADLv = self.m_nADLv

	tData.m_tAttr = self.m_tAttr
	tData.m_tChar = self.m_tChar

	return tData
end

function CFSObj:MarkDirty(bDirty)
	self.m_oModule:MarkDirty(bDirty)
end

function CFSObj:GetInfo()
	local tInfo = {}
	tInfo.nID = self.m_nID
	tInfo.nLv = self.m_nLv
	tInfo.nSGLv = self.m_nSGLv
	tInfo.nSGExp = self.m_nSGExp
	tInfo.nADLv = self.m_nADLv
	tInfo.tAttr = self.m_tAttr
	tInfo.tChar = self.m_tChar
	return tInfo
end

function CFSObj:GetID()
	return self.m_nID
end

function CFSObj:GetLv()
	return self.m_nLv
end

function CFSObj:GetSGLv()
	return self.m_nSGLv
end

function CFSObj:GetADLv()
	return self.m_nADLv
end

function CFSObj:GetAttr()
	return self.m_tAttr
end

function CFSObj:GetChar()
	return self.m_tChar
end

--更新属性
function CFSObj:UpdateAttr(bNotSync)
	local bChange = false

-- 智力= int（等级*等级*智力成长/1.25）+10+智力成长*2
-- 才力= int（等级*等级*才力成长/1.25）+10+才力成长*2
-- 魅力= int（等级*等级*魅力成长/1.25）+10+魅力成长*2
-- 武力= int（等级*等级*武力成长/1.25）+10+武力成长*2
	--属性
	local tConf = ctFashionConf[self.m_nID]
	for k = 1, 4 do
		local nOldAttr = self.m_tAttr[k] or 0
		local nGrowAttr = tConf["nAttr"..k]
		local nNewAttr = math.floor(self.m_nLv*self.m_nLv*nGrowAttr/1.25)+10+nGrowAttr*2
		if nNewAttr ~= nOldAttr then
			bChange = true
		end
		self.m_tAttr[k] = nNewAttr
	end

	--特性
	for k = 1, CFSObj.nMaxCharCount do
		local nOldChar = self.m_tChar[k] or 0
		local tChar = tConf["tChar"..k][1]
		local nNewChar = tChar[1]+self.m_nSGLv*self.m_nSGLv*tChar[2]
		if nNewChar ~= nOldChar then
			bChange = true
		end
		self.m_tChar[k] = nNewChar
	end

	if bChange then
		self:MarkDirty(true)
		self.m_oPlayer:UpdateGuoLi("时装属性变化")

		if not bNotSync then
			self.m_oModule:SyncFashion(self.m_nID)
		end
		return true
	end
end

--取强化等级上限
function CFSObj:MaxSGLv()
	return ctFashionAdvanceConf[self.m_nADLv].nSGLv
end

--取等级上限
function CFSObj:MaxLv()
	return ctFashionAdvanceConf[self.m_nADLv].nLv
end

--强化请求
function CFSObj:StrengthReq(tItemList)
	local nChapter = ctFashionEtcConf[1].nStrengthChapter
	if not self.m_oPlayer.m_oDup:IsChapterPass(nChapter) then
		self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
		return
	end	
	--检测等级上限
	if self.m_nSGLv >= #ctFashionStrengthConf then
		return self.m_oPlayer:Tips("已达到最大强化等级")
	end

	if self.m_nSGLv >= self:MaxSGLv() then
		return self.m_oPlayer:Tips("请先提升品质等级")
	end

	--检测道具
	local tItemMap = {}
	for _, tItem in ipairs(tItemList) do
		if not ctFashionStrengthProp[tItem.nID] then
			return self.m_oPlayer:Tips(string.format("%s不是强化材料", CGuoKu:PropName(tItem.nID)))
		end
		if self.m_oPlayer:GetItemCount(gtItemType.eProp, tItem.nID)	< tItem.nNum then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tItem.nID)))
		end
		tItemMap[tItem.nID] = tItem.nNum
	end

	--扣道具
	local nOldExp = self.m_nSGExp
	for nID, nNum in pairs(tItemMap) do
		self.m_oPlayer:SubItem(gtItemType.eProp, nID, nNum, "时装强化")
		self.m_nSGExp = self.m_nSGExp + ctFashionStrengthProp[nID].nExp * nNum
	end

	--检测升级
	local nMaxSGLv = math.min(self:MaxSGLv(), #ctFashionStrengthConf)
	for k = self.m_nSGLv, nMaxSGLv-1 do
		local tConf = ctFashionStrengthConf[k]
		if self.m_nSGExp >= tConf.nExp then
			self.m_nSGExp = self.m_nSGExp - tConf.nExp
			self.m_nSGLv = k + 1
		end
	end
	self:MarkDirty(true)

	--同步信息
	if not self:UpdateAttr() then
		self.m_oModule:SyncFashion(self.m_nID)
	end

	--任务
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond20, 1)
    self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond46, 1)
end

--进阶请求
function CFSObj:AdvanceReq()
	local nChapter = ctFashionEtcConf[1].nAdvanceChapter
	if not self.m_oPlayer.m_oDup:IsChapterPass(nChapter) then
		self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
		return
	end	
	--检测进阶上限
	if self.m_nADLv >= #ctFashionAdvanceConf then
		return self.m_oPlayer:Tips("已达到最大进阶等级")
	end

	--检测道具
	local tConsume = ctFashionAdvanceConf[self.m_nADLv].tConsume
	for _, tItem in ipairs(tConsume) do
		if self.m_oPlayer:GetItemCount(tItem[1], tItem[2]) < tItem[3] then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tItem[2])))
		end
	end

	--扣道具
	for _, tItem in ipairs(tConsume) do
		self.m_oPlayer:SubItem(tItem[1], tItem[2], tItem[3], "时装进阶")
	end

	self.m_nADLv = self.m_nADLv + 1
	self:MarkDirty(true)

	--同步信息
	self.m_oModule:SyncFashion(self.m_nID)
	self.m_oPlayer:Tips("进阶成功")

	--任务
    self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond45, 1)
end

--升级请求
function CFSObj:UpgradeReq()
	local nChapter = ctFashionEtcConf[1].nUpgradeChapter
	if not self.m_oPlayer.m_oDup:IsChapterPass(nChapter) then
		self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
		return
	end	
	if self.m_nLv >= #ctFashionLvConf then
		return self.m_oPlayer:Tips("已达到最大等级")
	end
	if self.m_nLv >= self:MaxLv() then
		return self.m_oPlayer:Tips("请先提升品质等级")
	end

	local tLvConf = ctFashionLvConf[self.m_nLv]
	if self.m_oPlayer:GetYinLiang() < tLvConf.nYL then
		return self.m_oPlayer:Tips("银两不足")
	end

	--扣道具
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYinLiang, tLvConf.nYL, "时装升级")
	self.m_nLv = self.m_nLv + 1
	self:MarkDirty(true)

	if not self:UpdateAttr() then
		self.m_oModule:SyncFashion(self.m_nID)
	end
	self.m_oPlayer:Tips("升级成功")

	--任务
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond22, 1)
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond15, self.m_nID, self.m_nLv, true)
end
