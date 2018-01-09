function CPropItem:Ctor(oBagModule)
	self.m_oBagModule = oBagModule
	CItemBase.Ctor(self, gtObjType.eProp)
end

--创建和加载时调用
function CPropItem:Init(nAutoID, nConfID, nNum)
	CItemBase.Init(self, nAutoID, nConfID, nNum)
end

function CPropItem:Pack()
	local tData = {}
	tData.nAutoID = self.m_nAutoID
	tData.nConfID = self.m_nConfID
	tData.nObjType = self.m_nObjType
	tData.nNum = self.m_nNum
	return tData
end

function CPropItem:Load(tData)
	assert(tData.nObjType == gtObjType.eProp)
	tData.nAutoID = tData.nAutoID or self.m_oBagModule:GenAutoID() --后来增加的
	self:Init(tData.nAutoID, tData.nConfID, tData.nNum)
end

function CPropItem:AddNum(nNum)
	assert(nNum > 0)
	self.m_nNum = math.min(nMAX_INTEGER, self.m_nNum + nNum)
end

function CPropItem:SubNum(nNum)
	assert(nNum > 0)
	self.m_nNum = math.max(0, self.m_nNum - nNum)
end

function CPropItem:IsFull()
	local tConf = self:GetConf()
	if tConf.nCollapse == 1 then
		return self.m_nNum >= 1
	end
end

function CPropItem:GetColor()
	local tConf = self:GetConf()
	return tConf.nColor
end
