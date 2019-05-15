--伙伴道具
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CPropPartner:Ctor(oModule, nID, nGrid, bBind, tPropExt)
    CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt)
end


function CPropPartner:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropPartner:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

function CPropPartner:Use(nParam1)
    local oRole = self.m_oModule.m_oRole
	nParam1 = 1  --单次只能使用一个
	if not nParam1 or nParam1 <= 0 then
		oRole:Tips("参数不正确")
		return
    end
    local nPropNum = self:GetNum()
	if nPropNum <= 0 then
		oRole:Tips("物品数量不足")
		return
	end
	local nUseNum = nParam1

    local tConf = self:GetPropConf()
    assert(tConf and tConf.eParam)
    local nPartnerID = tConf.eParam()
    local tPartnerConf = ctPartnerConf[nPartnerID]
    if not tPartnerConf then 
        oRole:Tips("配置错误，伙伴ID不存在")
        return 
    end

    if oRole.m_oPartner:FindPartner(nPartnerID) then 
        oRole:Tips(string.format("使用失败，%s 已招募", tPartnerConf.sName))
        return
    end

    local tPartnerConf = ctPartnerConf[nPartnerID]
	if not tPartnerConf then
		return
	end

	if oRole:GetLevel() < tPartnerConf.nRecruitLevel then
		oRole:Tips(string.format("%s需角色等级达到%d级方可招募", tPartnerConf.sName, tPartnerConf.nRecruitLevel))
		return
	end

    if not self.m_oModule:SubGridItem(self:GetGrid(), self:GetID(), nUseNum, "背包使用") then
        oRole:Tips("使用失败")
        return
    end
    oRole.m_oPartner:AddPartner(nPartnerID, "使用仙侣道具")
    local oPartner = oRole.m_oPartner:FindPartner(nPartnerID)
    assert(oPartner, "添加仙侣失败")
    oRole:Tips(string.format("成功招募 %s", tPartnerConf.sName))
end


