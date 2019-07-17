--夫妻系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--请注意，这个模块只是一个缓存数据，源数据在全局服
--每次角色上线，全局服都会同步一次数据缓存
function CSpouse:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nSpouseID = 0    --配偶ID
	self.m_nTimeStamp = 0
end

function CSpouse:LoadData(tData)
	if not tData or self.m_oPlayer:IsRobot() then
		return
	end
	self.m_nSpouseID = tData.nSpouseID
	self.m_nTimeStamp = tData.nTimeStamp or self.m_nTimeStamp
end

function CSpouse:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.nSpouseID = self.m_nSpouseID
	tData.nTimeStamp = self.m_nTimeStamp
	return tData
end

function CSpouse:GetType()
	return gtModuleDef.tSpouse.nID, gtModuleDef.tSpouse.sName
end

function CSpouse:Online()
end

--取丈夫/妻子ID  --请注意夫妻关系是跨服的
function CSpouse:GetSpouse()
	return self.m_nSpouseID
end

function CSpouse:GetMarriageStamp()
	return self.m_nTimeStamp 
end

function CSpouse:UpdateData(tData)
    if not tData then 
        return 
	end
	self.m_nSpouseID = tData.nSpouseID 
	self.m_nTimeStamp = tData.nTimeStamp or 0
	self:MarkDirty(true)
	
	--根据最新的缓存数据，刷新下角色的称谓相关数据
	if self.m_nSpouseID > 0 and tData.sSpouseName then 
		local oRole = self.m_oPlayer
		--更新夫妻称号
		local nAppeID = gtAppellationIDDef.eHusband
		if oRole:GetGender() ~= 1 then 
			nAppeID = gtAppellationIDDef.eWife
		end
		local nKeyID = oRole.m_oAppellation:GetAppellationObjID(nAppeID, self.m_nSpouseID)
		-- if nKeyID and nKeyID > 0 then 
		-- 	oRole:UpdateAppellation(nAppeID, {tNameParam = {tData.sSpouseName}}, self.m_nSpouseID)
		-- else
		-- 	oRole:AddAppellation(nAppeID, {tNameParam = {tData.sSpouseName}}, self.m_nSpouseID)
		-- end
		--暂时只处理之前已存在关系，但是没称谓的情况，不关心现有称谓的更新和删除，其他具体逻辑处处理
		if not nKeyID or nKeyID <= 0 then 
			oRole:AddAppellation(nAppeID, {tNameParam = {tData.sSpouseName}}, self.m_nSpouseID)
		end
	elseif self.m_nSpouseID <= 0 then 
		--TODO 暂时不处理
	end
end

function CSpouse:IsSpouse(nRoleID)
	if not nRoleID or nRoleID < 0 then 
		return false
	end
	local nSpouseID = self:GetSpouse()
	return nSpouseID == nRoleID
end