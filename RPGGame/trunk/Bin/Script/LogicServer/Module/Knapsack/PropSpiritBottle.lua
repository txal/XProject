--灵气瓶
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CPropSpiritBottle:Ctor(oModule, nID, nGrid, bBind, tPropExt)
    CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt)
end


function CPropSpiritBottle:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropSpiritBottle:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

function CPropSpiritBottle:Use(nParam1)
    local oRole = self.m_oModule.m_oRole
    if not oRole.m_oDrawSpirit:IsSysOpen(true) then 
        return 
    end
	nParam1 = 1  --单次只能使用一个
	if not nParam1 or nParam1 <= 0 then
		oRole:Tips("参数不正确")
		return
    end
    local nPropNum = self:GetNum()
	if nPropNum <= 0 then
		oRole:Tips("物品数量不足") --??应该不可能发生
		return
	end
	local nUseNum = nParam1
    nUseNum = math.min(nUseNum, nPropNum)

    local tConf = self:GetPropConf()
    assert(tConf and tConf.eParam)
    if not self.m_oModule:SubGridItem(self:GetGrid(), self:GetID(), nUseNum, "背包使用") then
        oRole:Tips("使用失败")
        return
    end
    local nSpiritNum = tConf.eParam()
    if nSpiritNum then 
        oRole:AddItem(gtItemType.eCurr, gtCurrType.eDrawSpirit, nSpiritNum, "背包使用")
        oRole:Tips(string.format("获得灵气%d", nSpiritNum))
    end
end





