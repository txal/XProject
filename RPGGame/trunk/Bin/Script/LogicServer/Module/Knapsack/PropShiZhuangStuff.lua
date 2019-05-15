--时装碎片
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropShiZhuangStuff:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropShiZhuangStuff:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropShiZhuangStuff:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropShiZhuangStuff:Use(nParam1)
	local oRole = self.m_oModule.m_oRole
	local PropConfID = self:GetID()
	local tPropConf = ctPropConf[PropConfID]
	if not tPropConf then return oRole:Tips("配置不存在") end
	local nStuffNum = tPropConf.eParam()
	local tItemList = {{gtItemType.eProp, PropConfID, nStuffNum},}
	local bCostSucc = oRole:CheckSubShowNotEnoughTips(tItemList, "时装碎片合成", true, true)
	if bCostSucc then
		local nPropID = tPropConf.eParam1()
		oRole:AddItem(gtItemType.eProp, nPropID, 1, "时装碎片所合成")
	end
end