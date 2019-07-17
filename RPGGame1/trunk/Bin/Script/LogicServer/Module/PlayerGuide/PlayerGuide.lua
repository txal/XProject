--新手引导数据
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--这个模块功能，目前废弃


gtGuideConf = {}
for k, tConf in pairs(ctGuideConf) do 
    gtGuideConf[tConf.nGuideId] = 1
end


function CPlayerGuide:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
    self.m_nGuideID = 1
end

function CPlayerGuide:LoadData(tData)
    if not tData then 
        return 
    end
    self.m_nGuideID = tData.nGuideID
end

function CPlayerGuide:SaveData()
    if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
    tData.nGuideID = self.m_nGuideID
	return tData
end

function CPlayerGuide:GetType()
	return gtModuleDef.tPlayerGuide.nID, gtModuleDef.tPlayerGuide.sName
end

function CPlayerGuide:SetGuideDataReq(nGuideID)
    if not nGuideID then 
        return 
    end
    if not gtGuideConf[nGuideID] then 
        return self.m_oPlayer:Tips(string.format("引导ID(%d)不存在", nGuideID))
    end
    self.m_nGuideID = nGuideID
    self:MarkDirty(true)
end

function CPlayerGuide:SyncGuideData()
    local tMsg = {}
    tMsg.nGuideID = self.m_nGuideID
    self.m_oPlayer:SendMsg("PlayerGuideDataRet", tMsg)
end

function CPlayerGuide:Online()
    -- self:SyncGuideData() --功能废弃
end




