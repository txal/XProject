--药品道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropMed:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropMed:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropMed:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--取品质
function CPropMed:GetStar() return self:GetPropConf().eParam() end
--取子类
function CPropMed:GetSubType() return self:GetPropConf().nSubType end
--取逻辑ID
function CPropMed:GetLogicID() return self:GetPropConf().nLogicID end
