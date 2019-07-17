--仙侣碎片
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropPartnerDebris:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropPartnerDebris:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropPartnerDebris:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropPartnerDebris:Use(nParam1)
	local oRole = self.m_oModule.m_oRole
	local PropConfID = self:GetID()
	local tPropConf = ctPropConf[PropConfID]
	if not tPropConf then return oRole:Tips("配置不存在") end
	local nStuffNum = tPropConf.eParam()
	assert(nStuffNum > 0, "策划请注意，仙侣碎片兑换数量配置错误")
	local tItemList = {{gtItemType.eProp, PropConfID, nStuffNum},}
	local bCostSucc = oRole:CheckSubShowNotEnoughTips(tItemList, "仙侣碎片合成", true, true)
	if bCostSucc then
		local nPartnerID = tPropConf.eParam1()
		oRole.m_oPartner:AddPartner(nPartnerID, "仙侣碎片合成")
	end
end