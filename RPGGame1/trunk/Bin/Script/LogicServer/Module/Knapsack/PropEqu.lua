--装备
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local  tAddPropertyFunc = {
	-- [gtBAT.eGJ] = function(nLv, nRatio) return math.ceil((nLv*5.7+22.5)/5 * nRatio) end,
	-- [gtBAT.eLL] = function(nLv, nRatio) return math.ceil((nLv*1.65+7.5)/5 * nRatio) end,
	-- [gtBAT.eMF] = function(nLv, nRatio) return math.ceil((nLv*7.5+1)/5 * nRatio) end,
	-- [gtBAT.eQX] = function(nLv, nRatio) return math.ceil((nLv*4.5+15)/5 * nRatio) end,
	-- [gtBAT.eFY] = function(nLv, nRatio) return math.ceil((nLv*4.5+37.5)/5 * nRatio) end,
	-- [gtBAT.eSD] = function(nLv, nRatio) return math.ceil((nLv*0.6+6)/5 * nRatio) end,
}

--装备品质值 [1 - 5][白、绿、蓝、紫、橙]
-- gtQualityColor

function CPropEqu:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
	local tConf = ctEquipmentConf[nID]
	self.m_nLevel = tConf.nEquipLevel						--装备等级
	local bLegend = tConf.bLegend

	self.m_nDurable = tConf.nDurable(self.m_nLevel)			--耐久
	self.m_nSource = tPropExt.nSource or gtEquSourceType.eShop  --出处 
	if self.m_nSource == gtEquSourceType.eTest then --外网模式下，不允许获得测试道具
		-- if not gbInnerServer then 
		-- 	self.m_nSource = 1
		-- end
		local oRole = self.m_oModule.m_oRole
		LuaTrace(string.format("debugtrace:玩家id(%d)名称(%s)获得测试道具%d", 
			oRole:GetID(), oRole:GetName(), nID))
		LuaTrace(debug.traceback())
	end

	if bLegend then 
		self:SetBind(true) --神兵，强制绑定
	end
	self.m_nQualityLevel = self:GenQualityLevel()           --品质等级 
	if tPropExt and tPropExt.nQuality and not bLegend then 
		for k, v in pairs(gtQualityColor) do 
			if v == tPropExt.nQuality then --必须是一个合法的品质
				self.m_nQualityLevel = tPropExt.nQuality
				break
			end
		end
	end
	self.tBaseProperty = self:CreateBaseProperty()				--基础属性
	self.tAddProperty = self:CreateAddProperty(true)				--附加属性
	self.tGem = {}											--宝石{nPos:{nGemID, nNum, nLv, tAttrList = {{nAttrID, nAttrVal}, ...}, }, ...}
	self.m_nBaseScore = self:GetBaseAttrScore()             --基础评分
	self.m_nScore = self:CalcScore()						--评分
	self.m_sProducer = tPropExt.sProducer or ""             --制作人
	-- self.m_nQualityValue = self:CalcQualityValue()			--品质值  --废弃不用
	self.tStrengthen = {nLv=0,nScore=0}						--强化
	self.m_nNextStrengthenScore = self:CalcNextStrengthenScore()
	self.m_nIdeStatus = 0									--鉴定状态
	self.m_tFuMoAttrMap = {} 								--附魔数据{[属性ID]={属性值,过期时间},...}
end

--生成装备品质
function CPropEqu:GenQualityLevel() 
	if self:IsLegend() then 
		return gtQualityColor.eOrange
	end
	local nQualityLevel = gtQualityColor.eWhite
	local tEquipmentFromConf = ctEquipmentFromConf[self.m_nSource]
	if not tEquipmentFromConf then 
		return nQualityLevel
	end
	local fnGetWeight = function(tNode) return tNode[2] end
	local tResult = CWeightRandom:Random(tEquipmentFromConf.tBasePropertyFactor, 
		fnGetWeight, 1, true)
	assert(tResult and #tResult == 1, "获取品质出错")
	local tBaseFactor =  tResult[1]
	nQualityLevel = tBaseFactor[1]
	nQualityLevel = math.max(math.min(nQualityLevel, 5), 1)
	return nQualityLevel
end

function CPropEqu:CreateBaseProperty()
	local nEquID = self:GetID()
	local tEquipConf = ctEquipmentConf[nEquID]
	local nScale = tEquipConf.nFactor/100

	local tBaseProperty = {}
	local nPartType = self:GetPartType()
	local tBasePropertyConf = ctEquipmentPropertyConf[nPartType].tBaseProperty
	local tFactor = self:GetBasePropertyFactor()
	assert(tFactor)
	for k, tValue in pairs(tBasePropertyConf) do
		local eColor, nRatio = tFactor[1], math.random(tFactor[3], tFactor[4])/100
		local nEffectValue = math.floor((self.m_nLevel * tValue[2] + tValue[3]) * nRatio * nScale)
		tBaseProperty[tValue[1]] = {eColor=eColor, nEffectValue=nEffectValue, nEffectBaseValue=nEffectValue}
	end
	return tBaseProperty
end

function CPropEqu:GetBasePropertyFactor()
	local nQualityLevel = self:GetQualityLevel()
	local tEquipmentFromConf = ctEquipmentFromConf[self.m_nSource]
	if not tEquipmentFromConf then
		return {gtQualityColor.eWhite, 1.0, 100, 100, 0}
	end
	local tBasePropertyFactor = tEquipmentFromConf.tBasePropertyFactor
	for k, v in ipairs(tBasePropertyFactor) do 
		if v[1] == nQualityLevel then 
			local tFact = table.DeepCopy(v)
			if self:IsLegend() then 
				tFact[3] = tFact[4] --神兵品质，总是最高
			end
			return tFact
		end
	end
end

function CPropEqu:CreateAddProperty(bCreate)
	local nQualityLevel = self:GetQualityLevel() or gtQualityColor.eWhite
	--每件装备在生成时，只会生成一个附加属性，附加属性的颜色和装备品质有关（如橙色装备生成一条橙色附加属性，白色装备不生成附加属性
	local tAddProperty = {}
	if nQualityLevel == gtQualityColor.eWhite then
		return  tAddProperty
	end
	local tFactor = self:GetBasePropertyFactor()
	local nAddPropertyNum = tFactor[6]
	local nPartType = self:GetPartType()
	local tAddPropertyConf = ctEquipmentPropertyConf[nPartType].tAddProperty

	local fnGetWeight = function(tNode) return tNode[2] end
	local tResult = CWeightRandom:Random(tAddPropertyConf, fnGetWeight, nAddPropertyNum, true)
	assert(tResult and #tResult == nAddPropertyNum, "数据错误")
	local nEquLv = self:GetLevel()
	if bCreate and self:IsLegend() then --神兵创建时，按照0级计算
		nEquLv = 0 
	end
	for k, tPropertyConf in pairs(tResult) do 
		local tAddFactor = self:GetAddPropertyFactor(nQualityLevel)
		local nAttrID = tPropertyConf[1]
		local fnAttrFunc = tAddPropertyFunc[nAttrID]
		if fnAttrFunc then
			--随机取波动系数值
			local nRatio = (math.random(tAddFactor[4], tAddFactor[5])/100)
			local eColor = tAddFactor[1]
			local nEffectValue = fnAttrFunc(nEquLv, nRatio)
			tAddProperty[nAttrID] = {eColor = eColor, nEffectValue = nEffectValue, nEffectBaseValue = nEffectValue}
		end
	end
	return tAddProperty
end

--根据对应品质直接取对应品质的属性
function CPropEqu:GetAddPropertyFactor(nQualityLevel)
	local tEquipmentFromConf = ctEquipmentFromConf[self.m_nSource]
	if not tEquipmentFromConf then
		return {gtQualityColor.eWhite, 0, 0}
	end
	for _, tAttr in pairs(tEquipmentFromConf.tAddPropertyFactor) do
		if tAttr[1] == nQualityLevel then
			return tAttr
		end
	end
	-- local fnGetWeight = function(tNode) return tNode[3] end
	-- local tResult = CWeightRandom:Random(tEquipmentFromConf.tAddPropertyFactor, 
	-- 	fnGetWeight, 1, true)
	-- assert(tResult and #tResult == 1, "获取品质出错")
	-- return tResult[1]
end

function CPropEqu:CalcScore()
	-- if self.m_nSource == gtEquSourceType.eTest then 
	-- 	return 100   --测试装备，强制设为100分
	-- end
	--fix pd 特技评分，特效评分
	return self:CalcPropertyScore() + self:CalcGemScore()
end

function CPropEqu:CalcNextStrengthenScore()
	if self.tStrengthen.nLv >= gnEquipmentMaxStrengthenLv then  --已到最高强化等级
		return self:CalcScore()
	end
	local nNextStrengthenLv = self.tStrengthen.nLv + 1
	local tEquStrengthenConf = ctEquipmentStrengthenConf[nNextStrengthenLv]

	local tTempProperty = table.DeepCopy(self.tBaseProperty)
	local nExtraAddRatio = 1   --每强化一级, 额外增加1点属性
	for nAttrID, tAttr in pairs(tTempProperty) do
		tAttr.nEffectValue = math.floor(tAttr.nEffectBaseValue * (1+tEquStrengthenConf.nAddRate) 
			+ math.floor(nExtraAddRatio * nNextStrengthenLv))
	end
	local nPropertyScore = self:GetBasePropertyScore(tTempProperty)
	nPropertyScore = nPropertyScore + self:GetAddPropertyScore(self.tAddProperty)
	nPropertyScore = nPropertyScore + self:CalcGemScore()
	return nPropertyScore
end

function CPropEqu:GetNextStrengthenScore() return self.m_nNextStrengthenScore end

function CPropEqu:GetBaseAttrScore()
	local nPropertyScore = 0
	for nAttrID, tValue in pairs(self.tBaseProperty) do
		nPropertyScore = nPropertyScore + self:CalcAttrScore(nAttrID, tValue.nEffectBaseValue)
	end
	-- for nAttrID, tValue in pairs(self.tAddProperty) do
	-- 	nPropertyScore = nPropertyScore + self:CalcAttrScore(nAttrID, tValue.nEffectBaseValue)
	-- end
	return nPropertyScore
end

function CPropEqu:UpdateScore()
	local nOldScore = self:GetScore()
	local nOldNextStrengthenScore = self:GetNextStrengthenScore()
	local nNewScore = self:CalcScore()
	local nNextStrengthenScore = self:CalcNextStrengthenScore()

	self.m_nBaseScore = self:GetBaseAttrScore()
	if nNewScore ~= nOldScore then
		self:SetScore(nNewScore)
		self:MarkDirty()
	end
	if nOldNextStrengthenScore ~= nNextStrengthenScore then
		self.m_nNextStrengthenScore = nNextStrengthenScore
		self:MarkDirty()
	end
end

function CPropEqu:UpdateAttr()
	--基础属性  (附加属性不会受到强化影响)
	--策划新需求，每强化一级，在原有基础上，额外增加1点属性
	local tStrengthen = self.tStrengthen
	local nStrengthenLv = tStrengthen.nLv or 0
	local nExtraAddRatio = 1   --每强化一级, 额外增加1点属性
	local tEquStrengthenConf = ctEquipmentStrengthenConf[nStrengthenLv]
	for nAttrID, tAttr in pairs(self.tBaseProperty) do
		tAttr.nEffectValue = math.floor(tAttr.nEffectBaseValue * (1+tEquStrengthenConf.nAddRate)) 
			+ math.floor(nStrengthenLv * nExtraAddRatio)
	end

	--宝石属性
	for _, tGemData in pairs(self.tGem) do
		local tGemConf = ctGemConf[tGemData.nGemID]
		tGemData.tAttrList = {}
		if tGemConf then
			--为了客户端数据显示一致，使用有序序列table
			for _, v in ipairs(tGemConf.tAttr) do  --支持单宝石附带多种属性
				local tAttr = {}
				tAttr.nAttrID = v[1]
				tAttr.nAttrVal = v[2](tGemData.nLv)
				table.insert(tGemData.tAttrList, tAttr)
			end
		else
			for k = 1, 5 do
				LuaTrace("策划请注意，宝石配置不存在，可能被删除，宝石ID:", v.nGemID)
			end
		end
	end
	self:UpdateScore()
	-- self:UpdateQuality()   --最后更新下品质
	-- self:MarkDirty()
end

function CPropEqu:CalcAttrScore(nAttrID, nAttrVal)
	-- local nConvertRate = gtEquAttrConvertRate[nAttrID]
	-- if not nConvertRate then 
	-- 	return 0
	-- end
	-- return math.floor(nAttrVal * nConvertRate)
	return CUtil:CalcAttrScore(nAttrID, nAttrVal)
end

function CPropEqu:GetBasePropertyScore(tBaseProperty)
	local nPropertyScore = 0
	for nProperty, tValue in pairs(tBaseProperty) do
		nPropertyScore = nPropertyScore + self:CalcAttrScore(nProperty, tValue.nEffectValue)
	end
	return nPropertyScore
end

function CPropEqu:GetAddPropertyScore(tAddProperty)
	local nPropertyScore = 0
	for nProperty, tValue in pairs(tAddProperty) do
		nPropertyScore = nPropertyScore + self:CalcAttrScore(nProperty, tValue.nEffectValue)
	end
	return nPropertyScore
end

--检查附加属性条数是否达到上限
function CPropEqu:IsAddPropertyMax()
	local tFactor = self:GetBasePropertyFactor()
	assert(tFactor)
	local nAddPropertyNum = tFactor[5]
	local nAttrNum = 0
	for _, _ in pairs(self:GetAddProperty() or {}) do
		nAttrNum = nAttrNum + 1
	end
	return nAttrNum >= nAddPropertyNum 
end

--属性评分
function CPropEqu:CalcPropertyScore()
	local nPropertyScore = self:GetBasePropertyScore(self.tBaseProperty)
	nPropertyScore = nPropertyScore + self:GetAddPropertyScore(self.tAddProperty)
	return nPropertyScore
end

function CPropEqu:CalcGemScore()
	local nGemScore = 0
	for i=1,3 do 
		local tGemData = self.tGem[i]
		--{nPos:{nGemID, nNum, nLv, tAttrList = {{nAttrID, nAttrVal}, ...}, }, ...}
		if tGemData then
			for _, tAttr in ipairs(tGemData.tAttrList) do
				nGemScore = nGemScore + self:CalcAttrScore(tAttr.nAttrID, tAttr.nAttrVal)
			end
		end
	end
	return nGemScore
end

-- function CPropEqu:CalcQualityValue()
-- 	--只有装备生成时及重铸时会影响到品质
-- 	--也就是目前，只有装备的基础属性值会影响到品质，强化的是根据基础属性值额外附加的，宝石是另外的额外计算的
-- 	local nAttrBaseValScore = 0   --属性基础值评分
-- 	for nAttrID, tAttrData in pairs(self.tBaseProperty) do 
-- 		nAttrBaseValScore = nAttrBaseValScore + self:CalcAttrScore(nAttrID, tAttrData.nEffectBaseValue)
-- 	end
-- 	for nAttrID, tAttrData in pairs(self.tAddProperty) do 
-- 		nAttrBaseValScore = nAttrBaseValScore + self:CalcAttrScore(nAttrID, tAttrData.nEffectBaseValue)
-- 	end
-- 	--属性品质
-- 	local tEquQualityConf = self:GetEquQualityConf()
-- 	local nPropertyQuality = (nAttrBaseValScore - tEquQualityConf.nBaseValue(self.m_nLevel)) / tEquQualityConf.nRangeValue(self.m_nLevel)
-- 	local nQuality = nPropertyQuality * tEquQualityConf.nAttr * 1000  + (1*1) * tEquQualityConf.nTrick + (1*1) * tEquQualityConf.nEffect
-- 	--fix pd 特技，特效
-- 	return math.floor(nQuality)
-- end

-- function CPropEqu:UpdateQuality()
-- 	local nOldQuality = self:GetQuality()
-- 	local nNewQuality = self:CalcQualityValue()
-- 	if nOldQuality ~= nNewQuality then 
-- 		self.m_nQualityValue = nNewQuality
-- 		self:MarkDirty()
-- 	end
-- end

function CPropEqu:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
	--装备自己的数据

	self.m_nDurable = tData.nDurable			--耐久度
	self.m_nSource = tData.nSource or self.m_nSource  --装备来源
	self.m_nIdeStatus = tData.nStatus			--鉴定状态
	self.tBaseProperty = tData.tBaseProperty	--基础属性
	for nProperty, tProperty in pairs(self.tBaseProperty) do
		if not tProperty.nEffectBaseValue then
			tProperty.nEffectBaseValue = tProperty.nEffectValue
			self:MarkDirty()
		end
	end
	self.tAddProperty = tData.tAddProperty		--附加属性
	for nProperty, tProperty in pairs(self.tAddProperty) do
		if not tProperty.nEffectBaseValue then
			tProperty.nEffectBaseValue = tProperty.nEffectValue
			self:MarkDirty()
		end
	end

	self.m_nBaseScore = tData.nBaseScore or self.m_nBaseScore
	self.m_nScore = tData.nScore				--评分
	self.m_nQualityLevel = tData.nQualityLevel or self.m_nQualityLevel  --品质等级
	-- self.m_nQualityValue = tData.nQualityValue  --品质值
	self.m_sProducer = tData.sProducer			--制作人
	self.tGem =  tData.tGem or {}				--宝石
	for k, v in pairs(self.tGem) do
		v.nLv = v.nLv or 1
	end
	self.tStrengthen = tData.tStrengthen			--强化
	self.m_tFuMoAttrMap = tData.tFuMoAttrMap or {}	--附魔符
	
	self:UpdateAttr()
end

function CPropEqu:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	--装备自己的数据
	tData.nDurable = self.m_nDurable
	tData.nSource = self.m_nSource
	tData.nStatus = self.m_nIdeStatus
	tData.tBaseProperty = self.tBaseProperty
	tData.tAddProperty = self.tAddProperty
	tData.nBaseScore = self.m_nBaseScore
	tData.nScore = self.m_nScore
	tData.nQualityLevel = self.m_nQualityLevel
	-- tData.nQualityValue = self.m_nQualityValue
	tData.sProducer = self.m_sProducer
	tData.tGem = self.tGem
	tData.tStrengthen = self.tStrengthen
	tData.tFuMoAttrMap = self.m_tFuMoAttrMap
	return tData
end


function CPropEqu:GetConf() return assert(ctEquipmentConf[self.m_nID]) end
function CPropEqu:IsEquipment() return true end
function CPropEqu:GetLevel() return self:GetConf().nEquipLevel end
function CPropEqu:GetDurable() return self.m_nDurable end
function CPropEqu:GetMaxDurable() return self:GetConf().nDurable(self:GetLevel()) end
function CPropEqu:IsLegend() return self:GetConf().bLegend end  --是否为神兵
function CPropEqu:GetSource() return self.m_nSource end
function CPropEqu:GetScore() return self.m_nScore end
function CPropEqu:GetBaseScore() return self.m_nBaseScore end 
function CPropEqu:GetProducer() return self.m_sProducer end
function CPropEqu:GetPartType() return self:GetConf().nEquipPartType end
function CPropEqu:GetEquQualityConf() return assert(ctEquipmentQualityConf[self:GetPartType()]) end
function CPropEqu:GetFixPrice() return math.ceil(self:GetConf().nSalePrice*(1-self:GetDurable()/self:GetMaxDurable())) end
-- function CPropEqu:GetQuality() return self.m_nQualityValue end
function CPropEqu:GetQualityLevel() return self.m_nQualityLevel end
function CPropEqu:GetBaseProperty() return self.tBaseProperty end
function CPropEqu:GetAddProperty() return self.tAddProperty end
function CPropEqu:GetStrengthenLevel() return self.tStrengthen.nLv end

function CPropEqu:SetLevel(nLevel) self.m_nLevel = nLevel end
function CPropEqu:SetDurable(nDurable) self.m_nDurable = nDurable end
function CPropEqu:AddDurable(nDurable) 
	if nDurable <= 0 and self:IsLegend() then --神兵不消耗耐久度
		return 
	end
	self.m_nDurable = math.max(self.m_nDurable + nDurable, 0)
	self:MarkDirty()
end
function CPropEqu:FixDurable() 
	self.m_nDurable = self:GetMaxDurable()
	self:MarkDirty()
end

function CPropEqu:SetScore(nScore) self.m_nScore = nScore end
function CPropEqu:SetProducer(sProducer) self.m_sProducer = sProducer end
function CPropEqu:IsWearing() return (self:GetGrid() == 0) end
function CPropEqu:MarkDirty()
	if self.m_oModule then 
		self.m_oModule:MarkDirty(true)
	end
end

function CPropEqu:GetGemLevelLimit()
	return math.floor(self:GetLevel()/10 + 2)
end

function CPropEqu:CheckGem()
	local bGem = false
	for k, tGemData in pairs(self.tGem) do 
		if tGemData.nLv > 0 then 
			bGem = true 
			break 
		end
	end
	return bGem
end

--被从角色身上删除时，被删除前调用
function CPropEqu:OnRemovedFromRole()
	self.m_oModule:RemoveEquGemAll(self)
end

function CPropEqu:CheckSale()
	local bSell, sReason = CPropBase.CheckSale(self)
	if not bSell then 
		return bSell, sReason
	end
	if self:CheckGem() then 
		return false, "请先将宝石卸下"
	end
	return true
end

function CPropEqu:GetDetailInfo()
	local tInfo = {}
	tInfo.nID = self.m_nID
	tInfo.bBind = self.m_bBind
	tInfo.nLevel = self.m_nLevel
	tInfo.nDurable = self.m_nDurable
	tInfo.nMaxDurable = self:GetMaxDurable()
	tInfo.nStatus = self.m_nIdeStatus
	tInfo.nQualityLevel = self:GetQualityLevel()
	tInfo.nScore = self.m_nScore
	tInfo.sProducer = self.m_sProducer
	if self.tStrengthen.nLv < gnEquipmentMaxStrengthenLv then --达到最高强化等级，不发送此数据
		tInfo.nNextStrengthenScore = self:GetNextStrengthenScore()
	end

	local tResAttrList = {}
	for nID,tProperty in pairs(self.tBaseProperty) do
		table.insert(tResAttrList, {nID=nID,nColor=tProperty.eColor,nEffectValue=tProperty.nEffectValue, nEffectBaseValue=tProperty.nEffectBaseValue})
	end
	tInfo.tResAttrList = tResAttrList

	local tMainAttrList = {}
	for nID,tProperty in pairs(self.tAddProperty) do
		table.insert(tMainAttrList, {nID=nID,nColor=tProperty.eColor,nEffectValue=tProperty.nEffectValue})
	end
	tInfo.tMainAttrList = tMainAttrList

	local tGemAttrList = {}
	for nPosID,tProperty in pairs(self.tGem) do
		local tGemData = {}
		tGemData.nPosID = nPosID
		tGemData.nGemID = tProperty.nGemID
		tGemData.nNum = tProperty.nNum
		tGemData.nLv = tProperty.nLv
		local tGemAttr = {}
		for k, v in ipairs(tProperty.tAttrList) do 
			local tAttr = {}
			tAttr.nAttrID = k
			tAttr.nAttrVal = v
			table.insert(tGemAttr, tAttr)
		end
		tGemData.tAttrList = tGemAttr
		table.insert(tGemAttrList, tGemData)
	end
	tInfo.tGemList = tGemAttrList

	tInfo.tStrengthen = {nLv=self.tStrengthen.nLv,nScore=self.tStrengthen.nScore}

	local tFuMoAttrList  = {}
	local tFuMoAttrMap = self:GetFuMoAttrMap()
	for nID, tAttr in pairs(tFuMoAttrMap) do
		table.insert(tFuMoAttrList, {nAttrID=nID, nAttrVal=tAttr[1], nExpireTime=tAttr[2]})
	end
	tInfo.tFuMoAttrList = tFuMoAttrList
	tInfo.nKey = self:GetKey()
	tInfo.nBaseScore = self:GetBaseAttrScore()
	return tInfo
end

-- --出售
-- function CPropEqu:Sell(nNum, nType)
-- 	local oRole = self.m_oModule.m_oRole
-- 	-- if self:GetLevel() >= 50 then --策划改需求了
-- 	-- 	return oRole:Tips(string.format("50以上装备不能出售"))
-- 	-- end
-- 	CPropBase.Sell(self, nNum, nType)
-- end

--检测附魔过期
function CPropEqu:CheckFuMoExpire(bNotUpdate)
	local bFuMoChange = false
	local nNowTime = os.time()
	for nAttrID, tAttr in pairs(self.m_tFuMoAttrMap) do
		if nNowTime >= tAttr[2] then
			bFuMoChange = true
			self.m_tFuMoAttrMap[nAttrID] = nil
			self:MarkDirty()
		end
	end
	if bFuMoChange and self:IsWearing() and not bNotUpdate then
		self.m_oModule.m_oRole:UpdateAttr()
	end
	return self.m_tFuMoAttrMap
end

--取附魔属性
function CPropEqu:GetFuMoAttrMap(bNotUpdate)
	return self:CheckFuMoExpire(bNotUpdate)
end

function CPropEqu:GetFuMoAttr(nAttrID)
	return self.m_tFuMoAttrMap[nAttrID]
end

--移除附魔属性
function CPropEqu:RemoveFuMoAttr(nAttrID, bNotUpdate)
	self:CheckFuMoExpire(bNotUpdate)
	
	if not self.m_tFuMoAttrMap[nAttrID] then
		return
	end
	self.m_tFuMoAttrMap[nAttrID] = nil
	self:MarkDirty()

	if self:IsWearing() and not bNotUpdate then
		self.m_oModule.m_oRole:UpdateAttr()
	end
end

--增加附魔属性
function CPropEqu:AddFuMoAttr(nAttrID, nAttrVal, nExpireTime)
	self:CheckFuMoExpire(true)
	self.m_tFuMoAttrMap[nAttrID] = {nAttrVal, nExpireTime}
	self:MarkDirty()
	if self:IsWearing() then
		self.m_oModule.m_oRole:UpdateAttr()
	end
end

function CPropEqu:GemLevel()
	local nLevel = 0
	for k, v in pairs(self.tGem) do
		nLevel = nLevel + v.nLv
	end
	return nLevel
end

function CPropEqu:ReMake(nType)
	if nType == 1 then
		self.tBaseProperty = self:CreateBaseProperty()
	elseif nType == 2 then
		self.tAddProperty = self:CreateAddProperty()
	end
	self:UpdateAttr()
	self:MarkDirty()
	if self:IsWearing() then
		self.m_oModule.m_oRole:UpdateAttr()
	end
end

function CPropEqu:GetInfo()
	local tInfo = CPropBase.GetInfo(self)
	tInfo.nStrengthenLevel = self:GetStrengthenLevel()
	tInfo.nBaseScore = self:GetBaseScore()
	return tInfo
end

-- function CPropEqu:OnLegendEquLevelChange(nLevel) 
-- 	if not self:IsLegend() then 
-- 		return 
-- 	end	
-- 	--调整等级和耐久度，重新计算属性
-- 	--这里不更新角色属性，统一外层更新
-- 	local nTarLevel = math.floor(nLevel / 10) * 10 
-- 	if self.m_nLevel == nTarLevel then 
-- 		return  
-- 	end
-- 	self.m_nLevel = nTarLevel
-- 	self:FixDurable() 
-- 	self.tBaseProperty = self:CreateBaseProperty()
-- 	self:MarkDirty() 
-- end

--神兵升级属性复制
function CPropEqu:LegendEquAttrCopy(oTarEqu)
	oTarEqu.tAddProperty = self.tAddProperty
	oTarEqu.m_nSource = self.m_nSource
	oTarEqu.tGem = self.tGem
	oTarEqu.m_sProducer = self.m_sProducer
	oTarEqu.tStrengthen = self.tStrengthen
	oTarEqu.m_nIdeStatus = self.m_nIdeStatus
	oTarEqu.m_tFuMoAttrMap = self.m_tFuMoAttrMap
end

function CPropEqu:GetUndulateQuality(nModulus)
	local nQualityLevel
	if nModulus <= 0.6 then
		nQualityLevel = gtQualityColor.eWhite
	elseif nModulus >= 0.61 and nModulus <= 0.7 then
		nQualityLevel = gtQualityColor.eGreen
	elseif nModulus >= 0.71 and nModulus <= 0.8 then
		nQualityLevel = gtQualityColor.eBlue
	elseif nModulus >= 0.81 and nModulus <= 0.9 then
		nQualityLevel = gtQualityColor.ePurple
	elseif nModulus >=  0.91 then
		nQualityLevel = gtQualityColor.eOrange
	end
	nQualityLevel = nQualityLevel and nQualityLevel or gtQualityColor.eWhite
	return nQualityLevel
end

function CPropEqu:ResetPropertyHandle(nAttrID, nQualityLevel, nAttrVal)
	local tAddProperty = self:GetAddProperty()
	local nEffectBaseValue = self:HandleAttrBase(nAttrID, 1)
	tAddProperty[nAttrID] = {eColor = nQualityLevel, nEffectValue = nAttrVal, nEffectBaseValue = nEffectBaseValue}
	self:UpdateAttr()
	self:MarkDirty(true)
	return true
end

--移除附加属性
function CPropEqu:RemoveAddProperty(nAttrID)
	tAddProperty = self:GetAddProperty()
	tAddProperty[nAttrID] = nil
	self:UpdateAttr()
	self:MarkDirty(true)
	return  true
end

function CPropEqu:HandleAttrBase(nAttrID,nRatio)
	local fnAttrFunc = tAddPropertyFunc[nAttrID]
	assert(fnAttrFunc, string.format("附加属性计算函数错误<%d>", nAttrID))
	-- local tAddFactor = self:GetAddPropertyFactor(self:GetQualityLevel())
	local nEffectValue = fnAttrFunc(self:GetLevel(), nRatio)
	return nEffectValue
end

function CPropEqu:GetBaseAttr(nAttrID)
	return self:HandleAttrBase(nAttrID, 1)
end

--神兵等级提升附加属行颜色变化
function CPropEqu:AddPropertAttrChange()
	local tAddProperty = self:GetAddProperty()
	for nAttrID, tAttr in pairs(tAddProperty) do
		local nV1, nV2
		local nAttrBaseVal = self:GetBaseAttr(nAttrID)
		local nModulus = 0.1
		if tAttr.nEffectValue ~= 0 and nAttrBaseVal ~= 0 then
			nV1, nV2 = math.modf(tAttr.nEffectValue / nAttrBaseVal)
			nModulus = nV1 + tonumber(string.format("%.2f",nV2))
		end
		local nQualityLevel = self:GetUndulateQuality(nModulus)
		tAttr.eColor = nQualityLevel
	end
	self:MarkDirty(true)
end