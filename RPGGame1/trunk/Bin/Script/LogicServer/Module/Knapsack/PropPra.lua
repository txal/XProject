--修炼道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropPra:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropPra:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropPra:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropPra:Use(nParam1)
	local oRole = self.m_oModule.m_oRole
	local oPractice = self.m_oModule.m_oRole.m_oPractice
	local nUseNum = math.max(1, nParam1 or 0)
	if self:GetNum() < nUseNum  then
		 return oRole:Tips("道具不足")
	 end
	oPractice:UsePropReq(nil, self:GetID(), nUseNum)
end