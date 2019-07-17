--神器碎片使用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropArtifactChip:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self, oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropArtifactChip:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropArtifactChip:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropArtifactChip:Use(nParam1)
	local oRole = self.m_oModule.m_oRole
	--不能跨格子使用哦
	local nSumArtifactChip = oRole:ItemCount(gtItemType.eProp, self:GetID())
	print("数量", nParam1)
	local nArtifactChip = self:GetNum()
	local tProp = ctPropConf[self:GetID()]
	local nArtifactID = tProp.eParam1()
	if not nArtifactID then oRole:Tips("道具ID错误") end
	if not tProp then oRole:Tips("道具不存在") end
	local oKnapsack = oRole.m_oKnapsack
	local nNum = nParam1 * 10
	if nSumArtifactChip < nNum then
		return oRole:Tips("碎片数量不足")
	end
	local nFindNum = self:GetNum()
	if nFindNum > nNum then
		oKnapsack:SubGridItem(self:GetGrid(), self:GetID(), nNum, "使用道具消耗")
	else
		oKnapsack:SubGridItem(self:GetGrid(), self:GetID(), nFindNum, "使用道具消耗")
		oRole:SubItem(gtItemType.eProp, self:GetID(), nNum - nFindNum, "使用道具消耗")
	end
	oRole:AddItem(gtItemType.eProp,nArtifactID, nParam1, "使用道具获得" )
end
