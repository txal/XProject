

--亲密关系相关
function CHoneyRelationship:Ctor(oRole)
    self.m_oRole = oRole
    self.m_tQingyiData = {}                 --情谊数据
	self.m_tQingyiData.nLevel = 0
	self.m_tQingyiData.nExp = 0
    self.m_tQingyiData.tAttrList = {}
end

function CHoneyRelationship:GetType()
    return gtModuleDef.tHoneyRelationship.nID, gtModuleDef.tHoneyRelationship.sName
end

function CHoneyRelationship:LoadData(tData)
    if tData then 
        self.m_tQingyiData = tData.m_tQingyiData or self.m_tQingyiData
    end
    
    self:UpdateQingyiAttr()
end

function CHoneyRelationship:SaveData()
    local tData = {}
    tData.m_tQingyiData = self.m_tQingyiData

    return tData
end

---------------------------------------------------
--情义数据
function CHoneyRelationship:GetQingyiGrowthID()
	return 8
end

function CHoneyRelationship:IsQingyiSysOpen(bTips)
	return self.m_oRole:IsSysOpen(97, bTips)
end

function CHoneyRelationship:GetQingyiLevel()
	return self.m_tQingyiData and self.m_tQingyiData.nLevel or 0
end

function CHoneyRelationship:GetQingyiLimitLevel()
	local nID = self:GetQingyiGrowthID()
	return math.min(self.m_oRole:GetLevel() * 8, ctRoleGrowthConf.GetConfMaxLevel(nID))
end

function CHoneyRelationship:SetQingyiLevel(nLevel)
	local nID = self:GetQingyiGrowthID()
	assert(nLevel > 0 and nLevel <= ctRoleGrowthConf.GetConfMaxLevel(nID))
	self.m_tQingyiData.nLevel = nLevel
	self:MarkDirty(true)
end

function CHoneyRelationship:GetQingyiExp()
	return self.m_tQingyiData and self.m_tQingyiData.nExp or 0
end

function CHoneyRelationship:GetQingyiAttr()
	if not self:IsQingyiSysOpen() then 
		return {} 
	end
	return self.m_tQingyiData.tAttrList or {}
end

function CHoneyRelationship:GetQingyiAttrRatio()
	local nID = self:GetQingyiGrowthID()
	local tConf = ctRoleGrowthConf[nID]
	return tConf.nRatio or 1
end

function CHoneyRelationship:GetQingyiScore()
	if not self:IsQingyiSysOpen() then 
		return 0 
	end
	return math.floor(self:GetQingyiLevel()*1000*self:GetQingyiAttrRatio())
end

function CHoneyRelationship:UpdateQingyiAttr()
	-- local nParam = self:GetQingyiLevel()*1000*1
	local nParam = self:GetQingyiScore()
	self.m_tQingyiData.tAttrList = self.m_oRole:CalcModuleGrowthAttr(nParam) or {}
end

function CHoneyRelationship:OnQingyiLevelChange()
	self:UpdateQingyiAttr()
	self.m_oRole:UpdateAttr()
end

function CHoneyRelationship:AddQingyiExp(nAddExp)
	local nID = self:GetQingyiGrowthID()
	local nCurLevel = self:GetQingyiLevel()
	local nLimitLevel = self:GetQingyiLimitLevel()
	local nCurExp = self:GetQingyiExp()
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	self:SetQingyiLevel(nTarLevel)
	self.m_tQingyiData.nExp = nTarExp
	self:MarkDirty(true)
	if nCurLevel ~= nTarLevel then 
		self:OnQingyiLevelChange()
	end
end

function CHoneyRelationship:SyncQingyiData()
	local tMsg = {}
	tMsg.nTotalLevel = self.m_tQingyiData.nLevel
	tMsg.nExp = self.m_tQingyiData.nExp
	tMsg.tAttrList = {}
	for nAttrID, nAttrVal in pairs(self.m_tQingyiData.tAttrList) do 
		table.insert(tMsg.tAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tMsg.nScore = self:GetQingyiScore()
	self.m_oRole:SendMsg("RoleRelationshipQingyiInfoRet", tMsg)
end

function CHoneyRelationship:QingyiLevelUpReq()
	if not self:IsQingyiSysOpen(true) then 
		return 
	end
	local oRole = self.m_oRole
	local nGrowthID = self:GetQingyiGrowthID()
	local nCurLevel = self:GetQingyiLevel()
	local nLimitLevel = self:GetQingyiLimitLevel()
	local nCurExp = self:GetQingyiExp()
	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	if nCurLevel >= nLimitLevel then 
		oRole:Tips("已达到当前限制等级，请先提升角色等级")
		return 
	end

	local nMaxAddExp = ctRoleGrowthConf.GetMaxAddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp)
	if nMaxAddExp <= 0 then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	local tCost = ctRoleGrowthConf.GetExpItemCost(nGrowthID, nMaxAddExp)
	assert(next(tCost))
	local nItemType = tCost[1]
	local nItemID = tCost[2]
	local nMaxItemNum = tCost[3]
	assert(nItemType > 0 and nItemID > 0 and nMaxItemNum > 0)
	local nKeepNum = oRole:ItemCount(nItemType, nItemID)
	if nKeepNum <= 0 then 
		oRole:Tips("材料不足，无法升级")
		return 
	end
	local nCostNum = math.min(nKeepNum, nMaxItemNum)
	local nAddExp = ctRoleGrowthConf.GetItemExp(nGrowthID, nItemType, nItemID, nCostNum)
	assert(nAddExp and nAddExp > 0)

	local tCost = {{nItemType, nItemID, nCostNum}, }
	if not oRole:CheckSubShowNotEnoughTips(tCost, "缘分情义升级", true) then 
		return 
	end
	self:AddQingyiExp(nAddExp)
	self:SyncQingyiData()

	local nResultLevel = self:GetQingyiLevel()
	local sContent = nil 
	local sModuleName = "情义"
	local sPropName = ctPropConf:GetFormattedName(nItemID) --暂时只支持道具
	if nResultLevel > nCurLevel then 
		local sTemplate = "消耗%d个%s, %s等级提升到%d级"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nResultLevel)
	else
		local sTemplate = "消耗%d个%s, %s增加%d经验"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nAddExp)
	end
	if sContent then 
		oRole:Tips(sContent)
	end


	local tMsg = {}
	tMsg.nOldLevel = nCurLevel
	tMsg.nCurLevel = self:GetQingyiLevel()
	oRole:SendMsg("RoleRelationshipQingyiLevelUpRet", tMsg)
end

