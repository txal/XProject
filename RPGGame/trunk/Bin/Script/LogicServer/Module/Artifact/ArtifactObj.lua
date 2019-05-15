local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--神器对象

function CArtifactObj:Ctor(oRole, nID)
	local tConf = assert(ctArtifactConf[nID], "找不到配置,神器ID<"..nID..">的配置不存在")
	self.m_oRole = oRole
	self.m_nID = nID                          	--神器ID
	self.m_nlevel = tConf.nLevel      			--等级
	self.m_nStar = tConf.nArtifactStar	        --星级
	self.m_sName = tConf.sName                  --神器名    
	self.m_nCurAdvancedExp = 0                  --当前进阶经验
	self.m_tBattleAttr = {}                     --基础属性,不存DB   
	self:UpdateAttr()    
end

function CArtifactObj:LoadData(tData)
	if not tData then
		return 
	end
	print(" tData.nCurAdvancedExp----",  tData.m_nCurAdvancedExp)
	self.m_nID = tData.m_nID
	self.m_nlevel = tData.m_nlevel
	self.m_nStar = tData.m_nStar
	self.m_nCurAdvancedExp = tData.m_nCurAdvancedExp or 0
	self:UpdateAttr()
end

function CArtifactObj:SaveData()
	local tData = {} 
	tData.m_nID = self.m_nID
	tData.m_nlevel = self.m_nlevel
	tData.m_nStar  = self.m_nStar
	tData.m_nCurAdvancedExp = self.m_nCurAdvancedExp
	return tData
end

function CArtifactObj:GetInfo()
	local tArtifactInfo = {}
	tArtifactInfo.nID = self.m_nID
	tArtifactInfo.nLevel = self.m_nlevel
	tArtifactInfo.nStar = self.m_nStar
	tArtifactInfo.nCurAdvancedExp = self.m_nCurAdvancedExp
	tArtifactInfo.nCostAdvancedExp = self:GetStarInfo()
	tArtifactInfo.tArtifactAttr = self:GetAttrInfo()
	--print("单个神器信息", tArtifactInfo)
	return tArtifactInfo
end

function CArtifactObj:GetID()
	return self.m_nID
end
function CArtifactObj:GetStarInfo()
	local  tArtifactCfg = ctAscendingStarConf[self.m_nStar]
	local nUpdateStarExp = 0
	if tArtifactCfg then
		nUpdateStarExp = tArtifactCfg.nAdvancedExp
	end
	return nUpdateStarExp
end

function CArtifactObj:GetLevel()
	return self.m_nlevel
end

function CArtifactObj:GetName()
	return self.m_sName
end

function CArtifactObj:SetLevel(nLevel)
	self.m_nlevel = self.m_nlevel + (nLevel or 0)
end

function CArtifactObj:GetStar()
	return self.m_nStar
end

function CArtifactObj:UpdateAttr()
	self.m_tBattleAttr = self:GetBattleAttr()
end

function CArtifactObj:SetStar(nValue)
	self.m_nStar = self.m_nStar + (nValue or 0)
end

function CArtifactObj:GetMaxStar()
	return ctAscendingStarConf[self.m_nStar].nMAxStar
end
function CArtifactObj:GetMaxLevel()
	return ctAscendingStarConf[self.m_nStar].nMaxLevel
end

function CArtifactObj:GetAttrInfo()
	local tAttrList = {}
	for nAttrID, nAttr in pairs(self.m_tBattleAttr) do
		 tAttrList[#tAttrList+1] = {nAttrID = nAttrID, nAttrValue = nAttr, nMaxAttrValue = self:GetMaxAttr(nAttrID) or 0}
	end
	return tAttrList
end

--获取属性上限值
function CArtifactObj:GetMaxAttr(nAttrID)
	local tArtifact = self:GetConf()
	local tAttrCfg
	local nMaxLevel = self:GetMaxLevel()
	if not tArtifact or not nAttrID then return end
	for i = 1, 10, 1 do
		tAttrCfg = tArtifact["tAttr" .. i]
		if not tAttrCfg then break end
		if tAttrCfg[1][1] and  tAttrCfg[1][1] ~= 0 and tAttrCfg[1][1] == nAttrID then
			return tAttrCfg[1][2](nMaxLevel)
		end
	end
end

function CArtifactObj:GetUpgradeCost()
	if ctArtifactUpgradeConf[self.m_nlevel] then
		return ctArtifactUpgradeConf[self.m_nlevel].tCost
	end
end

function CArtifactObj:GetAscendingStarCost()
	if self.m_nStar < 1 then return end
	return ctAscendingStarConf[self.m_nStar]
end

function CArtifactObj:GetAdvancedExp()
	return self.m_nCurAdvancedExp
end

function CArtifactObj:AddAdvancedExp(nValue)
	self.m_nCurAdvancedExp = math.max(self.m_nCurAdvancedExp + nValue, 0)
	--self.m_nCurAdvancedExp = math.max(self.m_nCurAdvancedExp, 0)
end
function CArtifactObj:GetConf()
	return ctArtifactConf[self.m_nID]
end

--基础属性计算
function CArtifactObj:GetBattleAttr()
	local tArtifact = self:GetConf()
	if not tArtifact then return end
	local tBattleAttr = {}
	for i = 1, 10, 1 do
		local tAttrCfg = tArtifact["tAttr" .. i]
		if not tAttrCfg then break end
		if tAttrCfg[1][1] and tAttrCfg[1][1] > 0 then
			tBattleAttr[tAttrCfg[1][1]] = (tBattleAttr[tAttrCfg[1][1]] or 0) + tAttrCfg[1][2](self.m_nlevel)
		end
	end
	return tBattleAttr
end