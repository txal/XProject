--烹饪道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropCoo:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropCoo:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropCoo:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

function CPropCoo:GetStar() return self:GetPropConf().eParam() end
function CPropCoo:GetSubType() return self:GetPropConf().nSubType end

function CPropCoo:Use(nParam1)
	local nSubType = self:GetSubType()
	if nSubType == gtCookType.eJHJ or nSubType == gtCookType.eCPRZ then
		self:UseBaoShi(nParam1)
	end
end

--饱食类道具
function CPropCoo:UseBaoShi(nParam1)
	local oModule = self.m_oModule
	local oRole = self.m_oModule.m_oRole
	local nAddBaoShi = self:GetPropConf().eParam()
	if nAddBaoShi <= 0 then
		return oRole:Tips("使用道具失败,配置错误?")
	end
	local nCurrTimes = oRole.m_oRoleState:GetBaoShiTimes()
	local nMaxTimes = oRole.m_oRoleState:MaxBaoShiTimes()
	if nCurrTimes >= nMaxTimes then
		return oRole:Tips("你的饱食度已满使用失败")
	end
	local nNewTimes = oRole.m_oRoleState:AddBaoShiTimes(nAddBaoShi)
	oRole:SubItem(gtItemType.eProp, self:GetID(), 1, "使用道具")
	return oRole:Tips(string.format("使用道具成功，增加饱食度%d点", nNewTimes-nCurrTimes))
end
