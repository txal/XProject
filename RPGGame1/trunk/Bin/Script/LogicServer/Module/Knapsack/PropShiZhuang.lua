--时装道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropShiZhuang:Ctor(oModule, nID, nGrid, bBind, tPropExt)
    CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropShiZhuang:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropShiZhuang:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropShiZhuang:Use(nParam1)
    local oRole = self.m_oModule.m_oRole
    local nPropID= self:GetID()
	assert(ctPropConf[nPropID], "该物品不存在")
    oRole:AddItem(gtItemType.eProp, nPropID, -1, "背包主动使用")
    oRole.m_oShiZhuang:ActShiZhuang(nPropID)
end