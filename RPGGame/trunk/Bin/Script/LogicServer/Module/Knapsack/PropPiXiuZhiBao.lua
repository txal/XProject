--貔貅之宝
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropPiXiuZhiBao:Ctor(oModule, nID, nGrid, bBind, tPropExt)
     --调用基类构造函数
     CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt)
end

function CPropPiXiuZhiBao:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropPiXiuZhiBao:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropPiXiuZhiBao:Use(nParam1)
    local oRole = self.m_oModule.m_oRole
    local nPropID= self:GetID()
	assert(ctPropConf[nPropID], "该物品不存在")
    local fnRandJinDing = ctPropConf[nPropID].eParam
    local nNumJinDing = fnRandJinDing()
    oRole:AddItem(gtItemType.eProp, nPropID, -1, "使用白银貔貅之宝")
    oRole:AddItem(gtItemType.eCurr, gtCurrType.eJinDing, nNumJinDing, "使用白银貔貅之宝")
end