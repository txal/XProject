--师徒关系
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--请注意，这个模块只是一个缓存数据，源数据在全局服
function CMentorshipModule:Ctor(oPlayer)
    self.m_oPlayer = oPlayer
    self.m_bUpgraded = false
    self.m_tMentorship = {}    --{nRoleID:{nStatus, bUpgrade, ...}, ...}
end

function CMentorshipModule:LoadData(tData)
	if not tData or self.m_oPlayer:IsRobot() then
		return
    end
    self.m_bUpgraded = tData.bUpgraded or self.m_bUpgraded
    for k, v in pairs(tData.tMentorship) do 
        local tTemp = v
        if tTemp and tTemp.nStatus then --错误数据，直接扔了  
            --后续扩展新增数据兼容
            self.m_tMentorship[k] = tTemp
        end
    end
end

function CMentorshipModule:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
    local tData = {}
    tData.bUpgraded = self.m_bUpgraded
    tData.tMentorship = {}
    for k, v in pairs(self.m_tMentorship) do 
        local tTemp = v  
        --后续扩展新增数据兼容
        tData.tMentorship[k] = tTemp
    end
	return tData
end

function CMentorshipModule:GetType()
	return gtModuleDef.tMentorship.nID, gtModuleDef.tMentorship.sName
end

function CMentorshipModule:Online()
end

function CMentorshipModule:UpdateData(tData)
    if not tData then 
        return 
    end
    self.m_bUpgraded = tData.bUpgraded or false
    self.m_tMentorship = {}
    for nTarID, tMentorData in pairs(tData.tMentorshipList) do
        self.m_tMentorship[nTarID] = tMentorData

        --对方是自己的师父，即自己是徒弟的情况下
        if tMentorData.sName and tMentorData.nStatus == gtMentorshipStatus.eMaster then 
            --暂时只处理之前已存在关系，但是没称谓的情况，不关心现有称谓的更新和删除，其他具体逻辑处处理
            local oRole = self.m_oPlayer

            local nAppeID = gtAppellationIDDef.eApprentice
            local nRemoveID = gtAppellationIDDef.eUpgradedApprentice
            if self.m_bUpgraded then 
                nAppeID = gtAppellationIDDef.eUpgradedApprentice
                nRemoveID = gtAppellationIDDef.eApprentice
            end
            local nKeyID = oRole.m_oAppellation:GetAppellationObjID(nAppeID, nTarID)
            if not nKeyID or nKeyID <= 0 then 
                oRole:AddAppellation(nAppeID, {tNameParam = {tMentorData.sName}}, nTarID)
            end
            oRole:RemoveAppellation(nRemoveID, nTarID)
            --更新称号数据
            -- oRole:UpdateAppellation(gtAppellationIDDef.eApprentice, {tNameParam = {tMentorData.sName}}, nTarID)
            -- oRole:UpdateAppellation(gtAppellationIDDef.eUpgradedApprentice, {tNameParam = {tMentorData.sName}}, nTarID)
        end
    end
    self:MarkDirty(true)
end

function CMentorshipModule:GetMasterID()  --获取师父id
    for k, v in pairs(self.m_tMentorship) do 
        if v.nStatus == gtMentorshipStatus.eMaster then 
            return k
        end
    end
    return 0
end

function CMentorshipModule:IsMaster(nRoleID)
    if not nRoleID or nRoleID <= 0 then 
        return false
    end
    local nMasterID = self:GetMasterID()
    if not nMasterID or nMasterID <= 0 then 
        return false
    end
    return nMasterID == nRoleID
end

function CMentorshipModule:IsApprentice(nRoleID)
    if not nRoleID or nRoleID <= 0 then 
        return false
    end
    for k, v in pairs(self.m_tMentorship) do 
        if k == nRoleID and v.nStatus == gtMentorshipStatus.eApprentice then 
            return true
        end
    end
    return false
end

function CMentorshipModule:IsMentorship(nRoleID)
    return (self:IsMaster(nRoleID) or self:IsApprentice(nRoleID))
end

