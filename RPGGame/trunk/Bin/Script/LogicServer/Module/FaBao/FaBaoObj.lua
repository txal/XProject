local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--法宝对象

--评分按照装备的方法来计算
local tPropertyConvertRate = {
	[gtBAT.eQX]=0.071,
	[gtBAT.eMF]=0.1,
	[gtBAT.eGJ]=0.408,
	[gtBAT.eFY]=0.476,
	[gtBAT.eLL]=1.428,
	[gtBAT.eSD]=1.428,
	[gtBAT.eFSGJ]=0.408,
	[gtMAT.eTZ]=1,
	[gtMAT.eML]=1,
	[gtMAT.eLL]=1,
	[gtMAT.eNL]=1,
	[gtMAT.eMJ]=1,
}

function CFaBaoObj:Ctor(oRole, nID, nGrid, tPropExt)
	local tConf = assert(ctFaBaoConf[nID], "找不到配置，法宝ID<"..nID..">的配置不存在")
	if not tPropExt then tPropExt = {} end
	self.m_oRole = oRole
	self.m_nID = nID
	self.m_nlevel = tPropExt.nLevel or tConf.nLevel
	self.m_Grade =  tPropExt.nGrade or tConf.nFaBaoGrade
	self.m_sName = tConf.sName
	self.m_nType = tConf.nFaBaopPartType
	self.m_nGrid = nGrid
	self.m_nFold = 1
	self.m_bBind = tPropExt.bBind or false
	self.m_nBuyPrice = tPropExt.nBuyPrice or 0
	self.m_bWear = false

	--法宝属性加成
	self.m_tBattleAttr = {}				--属性不存DB,加载的时候重新计算s
	self:UpdateAttr()
	self.m_nScore = self:CalcScore()
end

function CFaBaoObj:LoadData(tData)
	if not tData then
		return 
	end
	self.m_nID = tData.m_nID
	self.m_nGrid = tData.m_nGrid
	self.m_nlevel = tData.m_nlevel
	self.m_Grade = tData.m_Grade
	self.m_bBind = tData.m_bBind or false
	self.m_nFold = 1
	self.m_nBuyPrice = tData.m_nBuyPrice or 0
end

function CFaBaoObj:SaveData()
	local tData = {} 
	tData.m_nID = self.m_nID
	tData.m_nGrid = self.m_nGrid
	tData.m_nlevel = self.m_nlevel
	tData.m_Grade  = self.m_Grade
	tData.m_bBind = self.m_bBind
	tData.m_nFold = self.m_nFold
	tData.m_nBuyPrice = self.m_nBuyPrice
	return tData
end

function CFaBaoObj:GetBuyPrice()
	return self.m_nBuyPrice
end

function CFaBaoObj:SetbWear(bValue)
	self.m_bWear = bValue
end

function CFaBaoObj:GetbWear()
	return self.m_bWear
end

function CFaBaoObj:SetGrid(nGrid)
	self.m_nGrid = nGrid
end

function CFaBaoObj:GetPropConf() 
	return assert(ctPropConf[self.m_nID]) 
end

function CFaBaoObj:SetBuyPrice(nBuyPrice)
	self.m_nBuyPrice = nBuyPrice
end

function CFaBaoObj:MaxFold() 
	return self:GetPropConf().nFold
 end

function CFaBaoObj:EmptyNum() 
	return math.max(self:MaxFold() - self.m_nFold, 0) 
end

function CFaBaoObj:IsFull() return self.m_nFold >= self:MaxFold() end
function CFaBaoObj:GetType()
	return self.m_nType
end

function CFaBaoObj:AddNum(nNum)
	self.m_nFold = math.max(self.m_nFold + nNum, 0)
	print("堆叠数量", self.m_nFold)
end

function CFaBaoObj:GetID()
	return self.m_nID
end

function CFaBaoObj:GetName()
	return ctFaBaoConf[self.m_nID].sName
end

function CFaBaoObj:GetNum()
	return self.m_nFold
end

function CFaBaoObj:GetGrid()
	return self.m_nGrid
end

function CFaBaoObj:GetBattleAttr()
	self:UpdateAttr()
	return self.m_tBattleAttr
end

function CFaBaoObj:GetSkill()
	return self.m_nID
end

function CFaBaoObj:GetConf()
	if ctFaBaoConf[self.m_nID] then
		return ctFaBaoConf[self.m_nID]
	end
end

function CFaBaoObj:GetAttrFixParam()
	return ctRoleModuleAttrFixParamConf[102].nFixParam
end


function CFaBaoObj:UpdateAttr()
	local tConf = self:GetConf()
	if not tConf then
		print("配置文件不存在*********nID", self.m_nID)
		return 
	end
	-- self.m_tBattleAttr = {}
	-- for nKey, tItem in pairs(tConf.eFaBaoAttrFornula) do
	-- 	if tItem[1] > 1 then
	-- 		self.m_tBattleAttr[tItem[1]] = (self.m_tBattleAttr[tItem[1]] or 0) + math.floor(tItem[2](self:GetIlv()))
	-- 	end
	-- end

	-- local nParam = math.floor(self:GetIlv()*155*self:GetAttrFixParam())
	local nParam = self:CalcPropertyScore()
	self.m_tBattleAttr = self.m_oRole:CalcModuleGrowthAttr(nParam) or {}
end

function CFaBaoObj:UpdateLevel(nLevel)
	self.m_nlevel = nLevel
	self:UpdateAttr()
end

function CFaBaoObj:GetIlv()
	return self.m_nlevel * self.m_Grade
end

function CFaBaoObj:GetCostInfo()
	return ctFaBaoCostConf[self.m_nlevel]
end
function CFaBaoObj:GetLevel()
	return self.m_nlevel
end

function CFaBaoObj:GetStars()
	return self.m_Grade
end

function CFaBaoObj:GetBind()
	return self.m_bBind
end

function CFaBaoObj:GetScore()
	self.m_nScore = self:CalcScore()
	
	return self.m_nScore or 0
end
function CFaBaoObj:GetAttr()
	local tAttrList = {}
	for nBAT, nAttr in pairs(self.m_tBattleAttr) do
		tAttrList[#tAttrList+1] = {nBAT = nBAT,  nAttr = nAttr}
	end
	return tAttrList
end

--法宝评分计算
function CFaBaoObj:CalcScore()
	return self:CalcPropertyScore() + self:GetTrickScore()
end

function CFaBaoObj:GetTrickScore()
	return  ctFaBaoConf[self.m_nID].nScore
end
function CFaBaoObj:CalcAttrScore(nAttrID, nAttrVal)
	local nConvertRate = tPropertyConvertRate[nAttrID]
	if not nConvertRate then 
		return 0
	end
	return math.floor(nAttrVal * nConvertRate)
end

-- function CFaBaoObj:GemtBattleAttrScore(tBattleAttr)
-- 	local nPropertyScore = 0
-- 	for nProperty, nValue in pairs(tBattleAttr) do
-- 		nPropertyScore = nPropertyScore +  GF.CalcAttrScore(nProperty, nValue)
-- 	end
-- 	return nPropertyScore
-- end

--属性评分
function CFaBaoObj:CalcPropertyScore()
	-- local nPropertyScore = self:GemtBattleAttrScore(self.m_tBattleAttr)
	-- return nPropertyScore
	return math.floor(self:GetIlv()*155*self:GetAttrFixParam())
end

function CFaBaoObj:GetInfo()
	local tInfo = {}
	tInfo.nID = self.m_nID
	tInfo.nLevel = self:GetLevel()
	tInfo.nGrid = self.m_nGrid
	tInfo.nStars = self:GetStars()
	tInfo.sName = self:GetName()
	tInfo.nType = self:GetType()
	tInfo.nScore = self:GetScore()
	tInfo.bBind = self.m_bBind or false
	tInfo.bWear = self.m_bWear
	tInfo.nFold = self.m_nFold
	tInfo.tAttrList = self:GetAttr()
	return tInfo
end
function CFaBaoObj:GetFaBaoInfo()
	local tFaBao  = {}
	tFaBao.nID = self.m_nID
	tFaBao.nType = 3
	tFaBao.nGrid = self.m_nGrid
	tFaBao.nFold = self.m_nFold
	tFaBao.bBind = self.m_bBind
	tFaBao.nQualityLevel = ctPropConf[self.m_nID].nQuality
	tFaBao.nKey = 0
	return tFaBao
end