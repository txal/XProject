--法宝碎片使用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropFaBaoChip:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self, oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropFaBaoChip:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropFaBaoChip:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropFaBaoChip:Use()
	local oRole = self.m_oModule.m_oRole
	local tProp = ctPropConf[self:GetID()]
	if not tProp then return oRole:Tips("配置不存在") end
	local nArtifactChip = oRole:ItemCount(gtItemType.eProp, self:GetID())
	if nArtifactChip < tProp.eParam()then
		return oRole:Tips("碎片数量不足") 
	end
	if not tProp then oRole:Tips("道具不存在") end
	local nFaBaoID = tProp.eParam1()
	if not nFaBaoID then oRole:Tips("道具ID错误") end
	oRole:SubItem(gtItemType.eProp, self:GetID(), 10, "使用道具消耗")
	oRole:AddItem(gtItemType.eFaBao, nFaBaoID, 1, "使用道具获得")
end
	