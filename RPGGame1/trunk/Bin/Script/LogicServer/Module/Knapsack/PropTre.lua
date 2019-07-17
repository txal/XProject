--珍宝道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropTre:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropTre:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropTre:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end
