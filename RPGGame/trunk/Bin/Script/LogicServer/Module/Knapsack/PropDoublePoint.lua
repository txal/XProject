--双倍点数道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropDoublePoint:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropDoublePoint:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropDoublePoint:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropDoublePoint:Use(nParam1)
	local oRole = self.m_oModule.m_oRole
	local nLevel = oRole:GetLevel()
	local nPropID= self:GetID()
	assert(ctPropConf[nPropID], "该物品不存在")
	-- if nLevel < ctPropConf[nPropID].nLevelLowerLimit or nLevel > ctPropConf[nPropID].nLevelUpperLimit then
	-- 	return oRole:Tips("等级限制不能使用该物品")
	-- end

	local nUseTimes = oRole.m_oShuangBei.m_nUseShuangbeiDanTimes
	local nUseWeekLimit = oRole.m_oShuangBei:GetMaxUseShuangBeiDan()
	if nUseTimes >= nUseWeekLimit then
		return oRole:Tips("双倍丹使用达到每周使用次数上限")
	end

	oRole.m_oShuangBei:SetUseShuangBeiDanTime()
	oRole:AddItem(gtItemType.eProp, nPropID, -1, "使用双倍点数丹")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eShuangBei, ctPropConf[nPropID].eParam(), "使用双倍点数丹")
	oRole:Tips("获得"..ctPropConf[nPropID].eParam().."点双倍点数")
	oRole.m_oShuangBei:AddShuangBeiDanTimes(1)
end