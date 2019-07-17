--情缘关系
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--请注意，这个模块只是一个缓存数据，源数据在全局服
function CLoverModule:Ctor(oPlayer)
    self.m_oPlayer = oPlayer
    self.m_tLover = {}   --{nRoleID:{}, ...}
end

function CLoverModule:LoadData(tData)
	if not tData or self.m_oPlayer:IsRobot() then
		return
    end
    for k, v in pairs(tData.tLover) do 
        local tTemp = v or {}
        --此处后续数据扩展兼容
        self.m_tLover[k] = tTemp
    end
end

function CLoverModule:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
    local tData = {}
    tData.tLover = {}
    for k, v in pairs(self.m_tLover) do 
        local tTemp = v  
        --此处后续数据扩展兼容
        tData.tLover[k] = tTemp
    end
	return tData
end

function CLoverModule:GetType()
	return gtModuleDef.tLover.nID, gtModuleDef.tLover.sName
end

function CLoverModule:Online()
end

function CLoverModule:IsLover(nRoleID)
    if self.m_tLover[nRoleID] then 
        return true
    end
    return false
end

function CLoverModule:UpdateData(tData)
    if not tData then 
        return 
    end
    self.m_tLover = {}
    for nTarID, tLoverData in pairs(tData.tLoverList) do 
        self.m_tLover[nTarID] = tLoverData or {}
        if tLoverData.sName then 
            --暂时只处理之前已存在关系，但是没称谓的情况，不关心现有称谓的更新和删除，其他具体逻辑处处理

            local oRole = self.m_oPlayer
            local nKeyID = oRole.m_oAppellation:GetAppellationObjID(gtAppellationIDDef.eLover, nTarID)
            if not nKeyID or nKeyID <= 0 then 
                oRole:AddAppellation(gtAppellationIDDef.eLover, {tNameParam = {tLoverData.sName}}, nTarID)
            end
            -- --更新称号数据
            -- oRole:UpdateAppellation(gtAppellationIDDef.eLover, {tNameParam = {tLoverData.sName}}, nTarID)
        end
    end
    self:MarkDirty(true)
end

