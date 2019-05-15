--仙侣赏赐道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CFairyReward:Ctor(oModule, nID, nGrid, bBind, tPropExt)
     --调用基类构造函数
     CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt)
end

function CFairyReward:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CFairyReward:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具(预留)
function CFairyReward:Use(nParam1)

end