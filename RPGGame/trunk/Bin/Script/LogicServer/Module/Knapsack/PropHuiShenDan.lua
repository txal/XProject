--回神丹
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropHuiShenDan:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self, oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropHuiShenDan:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropHuiShenDan:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

function CPropHuiShenDan:Use(nParam1)
	local tConf = self:GetPropConf()
	local nAddVal = tConf.eParam()
	self.m_oModule.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eVitality, nAddVal, "使用道具")
	self.m_oModule.m_oRole:SubItem(gtItemType.eProp, self:GetID(), 1, "使用道具")
	self.m_oModule.m_oRole:Tips("使用道具成功")
end
