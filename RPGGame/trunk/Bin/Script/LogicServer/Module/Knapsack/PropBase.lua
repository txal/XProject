function CPropBase:Ctor(nSysID, nGrid)
	self.m_nSysID = nSysID
	self.m_nGrid = nGrid
	self.m_nNum = 0
end

function CPropBase:LoadData(tData)
	self.m_nSysID = tData.m_nSysID
	self.m_nGrid = tData.m_nGrid
	self.m_nNum = tData.m_nNum
end

function CPropBase:SaveData()
	local tData = {}
	tData.m_nSysID = self.m_nSysID
	tData.m_nGrid = self.m_nGrid
	tData.m_nNum = self.m_nNum
	return tData
end

function CPropBase:GetType()
	local tConf = self:GetConf()
	return tConf.nType
end

function CPropBase:GetSubType()
	local tConf = self:GetConf()
	return tConf.nSubType
end

function CPropBase:GetSysID()
	return self.m_nSysID
end

function CPropBase:GetConf()
	return assert(ctPropConf[self.m_nSysID])
end

function CPropBase:GetName()
	local tConf = self:GetConf()
	return tConf.sName
end

function CPropBase:GetGrid()
	return self.m_nGrid
end

--是否已经不可折叠
function CPropBase:IsFull()
	return self.m_nNum >= CGuoKu.nMaxFoldNum
end

--获取数量
function CPropBase:GetNum()
	return self.m_nNum
end

--设置数量
function CPropBase:SetNum(nNum)
	self.m_nNum = nNum
end

--增加数量
function CPropBase:AddNum(nNum)
	assert(nNum >= 0)
	self.m_nNum = self.m_nNum + nNum
end

--扣除数量
function CPropBase:SubNum(nNum)
	assert(nNum >= 0)
	self.m_nNum = self.m_nNum - nNum
end

--剩余多少可叠加数量
function CPropBase:EmptyNum()
	return CGuoKu.nMaxFoldNum - self.m_nNum
end

function CPropBase:GetInfo()
	local tInfo = {}
	tInfo.nSysID = self.m_nSysID
	tInfo.nGrid = self.m_nGrid
	tInfo.nNum = self.m_nNum
	return tInfo
end