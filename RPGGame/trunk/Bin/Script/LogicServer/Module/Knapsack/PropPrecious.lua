--宝物类道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPrecious:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	print("宝物类道具+++++++++++++++")
	CPropBase.Ctor(self, oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPrecious:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPrecious:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPrecious:Use()
	local oRole = self.m_oModule.m_oRole
end
