--鬼谷残片使用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropGuiGuFragment:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self, oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropGuiGuFragment:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropGuiGuFragment:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropGuiGuFragment:Use(nNum)
	local oRole = self.m_oModule.m_oRole
	local tProp = ctPropConf[self:GetID()]
	if not tProp then
		return oRole:Tips("配置不存在")
	end
	local nGuiGuChip = oRole:ItemCount(gtItemType.eProp, self:GetID())
	local nCostNum = tProp.eParam1()
	if nGuiGuChip < nCostNum then return oRole:Tips("材料不足") end
	if nNum > 1 then
		if nNum ~= nGuiGuChip then return oRole:Tips("数据错误") end
		local nPropNum = math.modf(nNum/nCostNum)
		oRole:SubItem(gtItemType.eProp, self:GetID(), nPropNum * nCostNum, "使用道具消耗")
		for i = 1, nPropNum, 1  do
			local nFormatID = self:GetFormat()
			if nFormatID and ctPropConf[nFormatID] then
				oRole:AddItem(gtItemType.eProp, nFormatID, 1, "使用道具获得")
			end
		end
	else
		oRole:SubItem(gtItemType.eProp, self:GetID(), nCostNum, "使用道具消耗")
		local nFormatID = self:GetFormat()
		if nFormatID and ctPropConf[nFormatID] then
			oRole:AddItem(gtItemType.eProp, nFormatID, 1, "使用道具获得")
		end
	end
end

function CPropGuiGuFragment:GetFormat()
	local nWeight = 0
	for _, tFormat in pairs(ctFormationConf) do
		nWeight = nWeight + tFormat.nWeight
	end
	local rdValue = math.random(1, nWeight)
	local curValue = 0
	for nID, tFormat in pairs(ctFormationConf) do
		if nID ~= 0 then
	        curValue = curValue + tFormat.nWeight
	        if curValue >= rdValue then
	        	return nID
	         end
	     end
	 end
end