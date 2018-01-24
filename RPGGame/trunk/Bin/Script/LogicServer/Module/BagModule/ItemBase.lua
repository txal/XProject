function CItemBase:Ctor(nObjType)
	assert(nObjType)
	self.m_nObjType = nObjType
	self.m_nAutoID = 0	--自增ID
	self.m_nConfID = 0
	self.m_nNum = 0
end

function CItemBase:Init(nAutoID, nConfID, nNum)
	assert(nAutoID and nConfID and nNum)
	self.m_nAutoID = nAutoID
	self.m_nConfID = nConfID
	self.m_nNum = math.max(1, math.min(nNum, nMAX_INTEGER))
end

function CItemBase:GetAutoID()
	return self.m_nAutoID
end

function CItemBase:GetConfID()
	return self.m_nConfID
end

function CItemBase:GetConf()
	if self.m_nObjType == gtObjType.eArm then
		return assert(ctArmConf[self.m_nConfID])

	elseif self.m_nObjType == gtObjType.eProp then
		return assert(ctPropConf[self.m_nConfID])
		
	else
		assert(false, "类型不支持:"..self.m_nObjType)

	end
end

function CItemBase:GetObjType()
	return self.m_nObjType
end

function CItemBase:GetType()
	local tConf = self:GetConf()
	return tConf.nType
end

function CItemBase:GetCount()
	return self.m_nNum
end
