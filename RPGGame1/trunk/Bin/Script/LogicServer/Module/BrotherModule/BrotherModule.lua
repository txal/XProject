--结拜关系
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--请注意，这个模块只是一个缓存数据，源数据在全局服
function CBrotherModule:Ctor(oPlayer)
    self.m_oPlayer = oPlayer
    self.m_tBrother = {}  --{roleid:{}, }
end

function CBrotherModule:LoadData(tData)
	if not tData or self.m_oPlayer:IsRobot() then
		return
    end
    for k, v in pairs(tData.tBrother) do 
        local tTemp = v or {}
        --此处后续新增数据兼容
        self.m_tBrother[k] = tTemp
    end
end

function CBrotherModule:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
    local tData = {}
    tData.tBrother = {}
    for k, v in pairs(self.m_tBrother) do 
        local tTemp = v 
        --此处后续新增数据兼容
        tData.tBrother[k] = tTemp
    end
    return tData
end

function CBrotherModule:GetType()
	return gtModuleDef.tBrother.nID, gtModuleDef.tBrother.sName
end

function CBrotherModule:Online()
end

function CBrotherModule:IsBrother(nRoleID)
    if self.m_tBrother[nRoleID] then 
        return true
    end
    return false
end

function CBrotherModule:UpdateData(tData)
    if not tData then 
        return 
    end
    self.m_tBrother = {}
    for nTarID, tBrotherData in pairs(tData.tBrotherList) do
        self.m_tBrother[nTarID] = tBrotherData or {}
        if tBrotherData.sName then 
            --暂时只处理之前已存在关系，但是没称谓的情况，不关心现有称谓的更新和删除，其他具体逻辑处处理

            local oRole = self.m_oPlayer
            if oRole:GetGender() == gtGenderDef.eMale then 
                local nErrKey = oRole.m_oAppellation:GetAppellationObjID(gtAppellationIDDef.eSister, nTarID)
                if nErrKey and nErrKey > 0 then 
                    oRole.m_oAppellation:RemoveAppellation(nErrKey, "错误称谓")
                end

                local nKeyID = oRole.m_oAppellation:GetAppellationObjID(gtAppellationIDDef.eBrother, nTarID)
                if not nKeyID or nKeyID <= 0 then 
                    oRole:AddAppellation(gtAppellationIDDef.eBrother, {tNameParam = {tBrotherData.sName}}, nTarID)
                end
                -- --更新称号数据
                -- oRole:UpdateAppellation(gtAppellationIDDef.eBrother, {tNameParam = {tBrotherData.sName}}, nTarID)
            else
                local nErrKey = oRole.m_oAppellation:GetAppellationObjID(gtAppellationIDDef.eBrother, nTarID)
                if nErrKey and nErrKey > 0 then 
                    oRole.m_oAppellation:RemoveAppellation(nErrKey, "错误称谓")
                end
                
                local nKeyID = oRole.m_oAppellation:GetAppellationObjID(gtAppellationIDDef.eSister, nTarID)
                if not nKeyID or nKeyID <= 0 then 
                    oRole:AddAppellation(gtAppellationIDDef.eBrother, {tNameParam = {tBrotherData.sName}}, nTarID)
                end
                -- --更新称号数据
                -- oRole:UpdateAppellation(gtAppellationIDDef.eSister, {tNameParam = {tBrotherData.sName}}, nTarID)
            end
        end
    end
    self:MarkDirty(true)
end

