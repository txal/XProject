local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CArmItem:Ctor(oBagModule)
	self.m_oBagModule = oBagModule
	CItemBase.Ctor(self, gtObjType.eArm)

	self.m_nExp = 0
	self.m_nLevel = 0
	self.m_tAttrInit = {}
	self.m_tAttrGrow = {}
	self.m_tFeature = {}

	self.m_nMaxLevel = 0
	self.m_nBreakLevel = 0
	self.m_bVariation = false

end

--创建和加载时调用
function CArmItem:Init(nAutoID, nConfID, nLevel, nExp, tAttrInit, tAttrGrow, tFeature)
	CItemBase.Init(self, nAutoID, nConfID, 1)

	self.m_nExp = nExp
	self.m_nLevel = nLevel
	self.m_tAttrInit = tAttrInit
	self.m_tAttrGrow = tAttrGrow
	self.m_tFeature = tFeature
end

--加载装备调用
function CArmItem:Load(tData)
	assert(tData.nObjType == gtObjType.eArm)
	tData.nAutoID = tData.nAutoID or self.m_oBagModule:GenAutoID()

	--因为特性类型后来加上,所以旧数据需要转换
	for k, v in ipairs(tData.tFeature) do
		if type(v) ~= "table" then tData.tFeature[k] = {v, gtFeatureType.eNor} end
	end

	self:Init(tData.nAutoID, tData.nConfID, tData.nLevel, tData.nExp, tData.tAttrInit, tData.tAttrGrow, tData.tFeature)

	self.m_nMaxLevel = tData.nMaxLevel
	self.m_nBreakLevel = tData.nBreakLevel
	self.m_bVariation = tData.nVariation and tData.nVariation ~= 0 or false
end

function CArmItem:Pack()
	local tData = {}
	tData.nAutoID = self.m_nAutoID
	tData.nConfID = self.m_nConfID
	tData.nObjType = self.m_nObjType
	tData.nExp = self.m_nExp
	tData.nLevel = self.m_nLevel
	tData.tAttrInit = self.m_tAttrInit
	tData.tAttrGrow = self.m_tAttrGrow
	tData.tFeature = self.m_tFeature
	tData.nMaxLevel = self.m_nMaxLevel or 0
	tData.nBreakLevel = self.m_nBreakLevel or 0
	tData.nVariation = self.m_bVariation and 1 or 0
	return tData
end

function CArmItem:GetExp() return self.m_nExp end
function CArmItem:GetLevel() return self.m_nLevel end
function CArmItem:GetGrowAttr() return self.m_tAttrGrow end
function CArmItem:GetInitAttr() return self.m_tAttrInit end
function CArmItem:GetFeature() return self.m_tFeature end
function CArmItem:GetMaxLevel() return self.m_nMaxLevel end
function CArmItem:GetBreakLevel() return self.m_nBreakLevel end

function CArmItem:SetExp(nExp) self.m_nExp = nExp end
function CArmItem:SetLevel(nLevel) self.m_nLevel = nLevel end
function CArmItem:SetInitAttr(tAttrInit) self.m_tAttrInit = tAttrInit end
function CArmItem:SetGrowAttr(tAttrGrow) self.m_tAttrGrow = tAttrGrow end
function CArmItem:SetFeature(tFeature) self.m_tFeature = tFeature end
function CArmItem:SetMaxLevel(nMaxLevel) self.m_nMaxLevel = nMaxLevel end
function CArmItem:SetBreakLevel(nBreakLevel) self.m_nBreakLevel = nBreakLevel end
function CArmItem:SetVariation(bVar) self.m_bVariation = bVar end
function CArmItem:GetVariation() return self.m_bVariation end

function CArmItem:GetName()
	local tArmConf = ctArmConf[self.m_nConfID]
	return tArmConf.sName
end

function CArmItem:GetAttrColor()
	local tAttrColor = {}

	local tInitLimit = self:GetConf().tInitLimit[1]
	for k = 1, 3 do
		local nInitAttr = self.m_tAttrInit[k]
		local nLimitAttr = tInitLimit[k]
		tAttrColor[k] = 1
		if nInitAttr >= math.floor(nLimitAttr*0.9) then
			tAttrColor[k] = 5

		elseif nInitAttr >= math.floor(nLimitAttr*0.8) then
			tAttrColor[k] = 4

		elseif nInitAttr >= math.floor(nLimitAttr*0.7) then
			tAttrColor[k] = 3

		elseif nInitAttr >= math.floor(nLimitAttr*0.6) then
			tAttrColor[k] = 2

		elseif nInitAttr >= math.floor(nLimitAttr*0.5) then
			tAttrColor[k] = 1

		end
	end
	return tAttrColor
end

function CArmItem:GetColor()
	--1, 2, 3, 4, 5 白 绿 蓝 紫 橙
	local tConf = self:GetConf()
	if tConf.nType == gtArmType.eDecoration then
		local nRare = self:RareStar()
		return math.max(1, math.min(nRare, 5))

	else
		return (tConf.nColor or 1)
		-- local nQuality = self:CalcQuality()
		-- local nColor = 1
		-- if nQuality >= 55 then
		-- 	nColor = 5
		-- elseif nQuality >= 40 then
		-- 	nColor = 4
		-- elseif nQuality >= 25 then
		-- 	nColor = 3
		-- elseif nQuality >= 10 then
		-- 	nColor = 2
		-- else
		-- 	nColor = 1
		-- end
		-- return nColor
	end
end

--计算缘分加成(百分数,加到战斗属性上)
function CArmItem:CalcMasterAdd()
	local tMasterAdd = {}
	local tArmConf = ctArmConf[self.m_nConfID]
	if tArmConf.nType == gtArmType.eDecoration or tArmConf.nType == gtArmType.eMate then
		return tMasterAdd 
	end
	local tMaster = tArmConf.tMaster
	for k = 1, #tMaster do
		local tAddConf = tMaster[k]
		if tAddConf[1] > 0 then
			local nFeatureID, nAttrID, nAttrVal = table.unpack(tAddConf)
			for _, v in ipairs(self.m_tFeature) do
				if nFeatureID == v[1] then
					tMasterAdd[nAttrID] = (tMasterAdd[nAttrID] or 0) + nAttrVal
				end
			end
		end
	end
	return tMasterAdd
end

--饰品附加属性
function CArmItem:GetExtAttr()
	local tExtAttr = {}
	if self:GetType() ~= gtArmType.eDecoration then
		return tExtAttr
	end
	local tArmConf = self:GetConf()
	for _, tConf in ipairs(tArmConf.tExtAttr) do
		local nAttrID, nValue = tConf[1], tConf[2]
		if nAttrID > 0 and nValue > 0 then
			tExtAttr[nAttrID] = nValue
		end
	end
	return tExtAttr
end

--计算战斗属性
function CArmItem:CalcBattleAttr(nLevel)
	nLevel = nLevel or self.m_nLevel 
	local tBattleAttr = {0, 0, 0}
	local tArmConf = ctArmConf[self.m_nConfID]
	if tArmConf.nType == gtArmType.eDecoration then
		local tInitLimit, tGrowLimit = tArmConf.tInitLimit[1], tArmConf.tGrowLimit[1]
		for k = 1, 3 do
			tBattleAttr[k] = math.floor(tInitLimit[k] + (nLevel - 1) * (tGrowLimit[k] * 0.1))
		end
		--饰品附加属性(百分数10000倍)
		local tExtAttr = self:GetExtAttr()
		for nAttrID, nAttrVal in pairs(tExtAttr) do
			tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) + nAttrVal
		end
	else
		local tMasterAdd, tWorkShopAdd = {}, {}
		--材料没有缘分加成和工坊加成
		if tArmConf.nType ~= gtArmType.eMate then
			local oWorkShop = self.m_oBagModule.m_oPlayer.m_oWorkShop
			local function _get_skill_id()
				if tArmConf.nType == gtArmType.eGun then
					return tArmConf.nSubType + gtCurrType.eSQMaster - 1
				elseif tArmConf.nType == gtArmType.eBomb then
					return gtCurrType.eSLMaster
				else
					assert(false, "类型不支持")
				end
			end
			tMasterAdd = self:CalcMasterAdd()
			tWorkShopAdd = oWorkShop:GetAttrAdd(_get_skill_id())
		end	
		for k = 1, 3 do
			tBattleAttr[k] = self.m_tAttrInit[k] + (nLevel - 1) * (self.m_tAttrGrow[k] * 0.1)
			tBattleAttr[k] = tBattleAttr[k] + (tWorkShopAdd[k] or 0)
			tBattleAttr[k] = math.floor(tBattleAttr[k] * (1 + (tMasterAdd[k] or 0) * 0.0001))
		end
	end
	return tBattleAttr
end

--计算品质(星级)
function CArmItem:CalcQuality()
	local tArmConf = assert(ctArmConf[self.m_nConfID])
	if tArmConf.nType == gtArmType.eDecoration then
		return self:RareStar()
	else
		local nInitStar = self:InitStar()
		local nGrowStar = self:GrowStar()
		local nFeatureStar = self:FeatureStar()
		local nRareStar = self:RareStar()
		local nTotalStar = nInitStar + nGrowStar + nFeatureStar + nRareStar 
		return nTotalStar	
	end
 end

 --初始属性星级
 function CArmItem:InitStar()
 	local tArmConf = assert(ctArmConf[self.m_nConfID])
	if tArmConf.nType == gtArmType.eDecoration then
		return 0
	end
	local tAttrColor = self:GetAttrColor()
	local nStar = 0
 	for k = 1, 3 do
 		nStar = nStar + math.max(0, tAttrColor[k] - 2)
 	end
 	return nStar
 end

 --成长星级
 function CArmItem:GrowStar()
 	local tArmConf = assert(ctArmConf[self.m_nConfID])
	if tArmConf.nType == gtArmType.eDecoration then
		return 0
	end
	local tGrowLimit = tArmConf.tGrowLimit[1]
 	local nStar = 0
 	for k = 1, 3 do
 		nStar = nStar + math.floor(math.max(0, (self.m_tAttrGrow[k] / tGrowLimit[k] - 0.1) / (1 - 0.1) * 20))
 	end
 	return nStar
 end

 --特性星级
 function CArmItem:FeatureStar()
 	local tArmConf = assert(ctArmConf[self.m_nConfID])
	if tArmConf.nType ~= gtArmType.eGun then
		return 0
	end
	local nFeatureStar = 0
	for _, v in ipairs(self.m_tFeature) do
		local tConf =  ctGunFeatureConf[v[1]]
		--nLevel<=2 为低级 >2 为高级
		nFeatureStar = nFeatureStar + (tConf.nLevel <= 2 and 1 or 3)
	end
	return nFeatureStar
 end

 --珍稀度星级
 function CArmItem:RareStar()
	local tArmConf = assert(ctArmConf[self.m_nConfID])
	return tArmConf.nRare
 end

--装备等级信息
function CArmItem:GetLevelInfo()
	local nCurrExp = self:GetExp()
	local nConfID = self:GetConfID()
	local nCurrLevel = self:GetLevel()
	local nMaxLevel = #ctArmUpgradeConf
	if nCurrLevel >= nMaxLevel then
		return nCurrLevel, nCurrExp, -1
	else
		local nNextExp = ctArmUpgradeConf[nCurrLevel+1].nExp
		return nCurrLevel, nCurrExp, nNextExp
	end
end

--装备详细信息
function CArmItem:GetDetail()
	local tConf = self:GetConf()
	local nArmType = tConf.nType

	local tInfo = {}
	tInfo.nArmID = tConf.nID
	local nLevel, nCurrExp, nNextExp = self:GetLevelInfo()
	tInfo.nLevel = nLevel
	tInfo.nCurrExp = nCurrExp
	tInfo.nNextExp = nNextExp
	tInfo.nArmStar = self:CalcQuality()
	tInfo.tCurrAttr = {}
	local tBattleAttr = self:CalcBattleAttr()
	tInfo.tCurrAttr = {tBattleAttr[1], tBattleAttr[2], tBattleAttr[3]}

	if nArmType == gtArmType.eDecoration then
		tInfo.tExtAttr = {}
		local tExtAttr = self:GetExtAttr()
		for nAttrID, nAttrVal in pairs(tExtAttr) do
			table.insert(tInfo.tExtAttr, nAttrID)
			table.insert(tInfo.tExtAttr, nAttrVal)
		end
		tInfo.nSuitID = tConf.nSuitID
		tInfo.tActArmID = {}
		local tSuitConf = ctDecorationSuitConf[tInfo.nSuitID]
		if tSuitConf then
			local tSlotArmMap = self.m_oBagModule:GetSlotArmMap()
			for nSlotID, oArm in pairs(tSlotArmMap) do
				local tConf = oArm:GetConf()
				if tConf.nType == gtArmType.eDecoration then
					for _, nArmID in ipairs(tSuitConf.tArmID[1]) do
						if oArm:GetConfID() == nArmID then	
							table.insert(tInfo.tActArmID, nArmID)	
							break
						end
					end
				end
			end
		end
	else
		tInfo.nRareStar = self:RareStar()
		tInfo.tInitAttr = self.m_tAttrInit
		tInfo.nInitStar = self:InitStar()
		tInfo.tGrowAttr = self.m_tAttrGrow
		tInfo.nGrowStar = self:GrowStar()
		tInfo.tFeature = {}
		for k, v in ipairs(self.m_tFeature) do
			tInfo.tFeature[k] = {nID=v[1], nType=v[2]}
		end
		tInfo.nFeatureStar = self:FeatureStar()
	end
	return tInfo
end

function CArmItem:CalcFeatureAttr(tFeature)
	local tFTType = gtFeatureAttrType
	local tAttrFeatrue = {tFTType.eCritRate, tFTType.eCritHurt, tFTType.eCritCounter} --修改属性的特性类型

	local tFeatureAttr = {}
	for _, nFTID in ipairs(tFeature) do
		local tFTConf = assert(ctGunFeatureConf[nFTID])
		if not tFeatureAttr[tFTConf.nType] then
			tFeatureAttr[tFTConf.nType] = {}
		end
		if table.InArray(tFTConf.nType, tAttrFeatrue) then
			tFeatureAttr[tFTConf.nType][1] = tFTConf.nVal1
		else
			tFeatureAttr[tFTConf.nType][1] = (tFeatureAttr[tFTConf.nType][1] or 0) + tFTConf.nVal1
		end
		tFeatureAttr[tFTConf.nType][2] = (tFeatureAttr[tFTConf.nType][2] or 0) + tFTConf.nVal2
	end
	return tFeatureAttr
end

