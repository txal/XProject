--器灵经验丹（器灵精髓）
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropQiLingExpDan:Ctor(oModule, nID, nGrid, bBind, tPropExt)
    CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt)
end

function CPropQiLingExpDan:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropQiLingExpDan:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

--使用道具
function CPropQiLingExpDan:Use(nParam1)
    if nParam1 <= 0 then
        return
    end

    local oRole = self.m_oModule.m_oRole
    local nPropID= self:GetID()
    assert(ctPropConf[nPropID], "该物品不存在")
    --判断当前是否可以升阶
    local nCanUp = math.floor(oRole.m_oShiZhuang.m_nQiLingLevel / 10)
    local nCurrGrade = oRole.m_oShiZhuang.m_nQiLingGrade
    if nCurrGrade < nCanUp then
        return oRole:Tips("器灵升阶才能继续升级")
    end
    --判断当前是否可以升级
    local nCurrLevel = oRole.m_oShiZhuang.m_nQiLingLevel
    if nCurrLevel >= CShiZhuang:GetQiLingMaxLevel() then
        return oRole:Tips("器灵已达到最高级")
    end

    --计算升级所需经验
    local nCurrQiLingExp = oRole.m_oShiZhuang:GetQiLingExp()
    local nExp = ctQiLingLevelConf[nCurrLevel].nNeedExp - nCurrQiLingExp    --下一级需要的经验
    local nNextLevel = nCurrLevel + 1
    local nCurrGradeMaxLevel = nCurrGrade * 10 + 9
    local nUpNextGradeExp = nExp                        --升到下一阶所需总经验
    for i=nNextLevel, nCurrGradeMaxLevel, 1 do
        nUpNextGradeExp = nUpNextGradeExp + ctQiLingLevelConf[i].nNeedExp
    end
    local fnCalExp = ctPropConf[nPropID].eParam
    local nQiLingExp = fnCalExp()
    local nUpLevelNeed = math.ceil(nUpNextGradeExp / nQiLingExp)
    local nRealCost = 0
    if nParam1 <= nUpLevelNeed then
        nRealCost = nParam1
    else
        nRealCost = nUpLevelNeed
    end

    oRole:AddItem(gtItemType.eProp, nPropID, -nRealCost, "使用器灵经验丹")
    local sName = ctPropConf[nPropID].sName
    oRole:Tips(sName.."使用成功")
    oRole.m_oShiZhuang:AddQiLingExp(nQiLingExp * nRealCost)
end