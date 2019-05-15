--神兽碎片兑换使用
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropPetChipConvert:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self, oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropPetChipConvert:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropPetChipConvert:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropPetChipConvert:Use(nParam1, bFlag)
	local oRole = self.m_oModule.m_oRole
	local oPetModel = oRole.m_oPet
	local tPropCfg = ctPropConf[self:GetID()]
	if not tPropCfg then return oRole:Tips("道具不存在哦") end
	local nPetID = tPropCfg.eParam()
	local tPet = ctPetInfoConf[nPetID]
	if not tPet then return oRole:Tips("宠物配置错误") end
	--宠物只能加单只
	local nPetNum
	nPetNum = nParam1
	local tPos = oPetModel:GetEmptyPos(nPetNum)

	--最低满足一个格子
	if #tPos < 1 then
		return oRole:Tips("宠物携带仓库已满，请放生后使用哦")
	else
		nPetNum = #tPos >= nPetNum and nPetNum or  nPetNum - #tPos
	end
	if self:GetNum() < nPetNum then
		return oRole:Tips("道具数量不足")
	end

	local oKnapsack = oRole.m_oKnapsack
	oKnapsack:SubGridItem(self:GetGrid(), self:GetID(), nPetNum, "使用道具消耗")
	local tPropExt = {}
	if bFlag then
		tPropExt.bFlag = true
	end
	tPropExt.bPropUse = true
	for i = 1, nPetNum, 1 do
		oRole:AddItem(gtItemType.ePet, nPetID, 1, "使用道具获得",false, false, tPropExt)
	end
end
