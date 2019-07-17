--材料类
function CPropCL:Ctor(oModule, nSysID, nGrid)
	CPropBase.Ctor(self, nSysID, nGrid)
	self.m_oModule = oModule
end

function CPropCL:LoadData(tData)
	CPropBase.LoadData(self, tData)
end

function CPropCL:SaveData()
	local tData = CPropBase.SaveData(self)
	return tData
end

--出售道具
function CPropCL:Sell(nNum)
	assert(nNum > 0, "参数错误")
	local oRole = self.m_oModule.m_oRole
	if self:GetNum() < nNum then
		return oRole:Tips("道具不足")
	end
	local tConf = self:GetConf()
	self.m_oModule:SubGridItem(self:GetSysID(), self:GetGrid(), nNum, "使用道具")

	local tAwardMap = {}
	for k = 1, nNum do
		for _, tItem in ipairs(tConf.tSellAward) do
			if tItem[1] > 0 then
				local sKey = tItem[1]..tItem[2]
				if not tAwardMap[sKey] then
					tAwardMap[sKey] = {nType=tItem[1], nID=tItem[2], nNum=0}
				end
				tAwardMap[sKey].nNum = tAwardMap[sKey].nNum + tItem[3]
			end
		end
	end

	for _, tItem in pairs(tAwardMap) do
		oRole:AddItem(tItem.nType, tItem.nID, tItem.nNum, "出售道具")
	end
	return true
end