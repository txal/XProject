--人物经验心得
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropRoleExp:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropRoleExp:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropRoleExp:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropRoleExp:Use(nParam1)
	nParam1 = math.max(1, nParam1 or 0)
	local oRole = self.m_oModule.m_oRole
	if oRole:GetLevel() < 35 then
		return oRole:Tips(string.format("%s35级可用", self:GetName()))
	end

	local nMaxRoleExpProps = oRole:MaxRoleExpProps() 
	local nRemainRoleExpProps = nMaxRoleExpProps - oRole:GetRoleExpProps()
	if nRemainRoleExpProps <= 0 then
		return oRole:Tips(string.format("%s已达到当天可使用上限", self:GetName()))
	end
	local nUseNum = math.min(nParam1, nRemainRoleExpProps)
	local nAddExp = nUseNum*(200*oRole:GetLevel()+2500)
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nAddExp, "使用道具", true)
	oRole:SubItem(gtItemType.eProp, self:GetID(), nUseNum, "使用道具")
	oRole:AddRoleExpProps(nUseNum)
	oRole:Tips("使用道具成功")
end