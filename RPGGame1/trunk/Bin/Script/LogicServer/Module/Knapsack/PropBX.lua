--普通宝箱类
function CPropBX:Ctor(oModule, nSysID, nGrid)
	CPropBase.Ctor(self, nSysID, nGrid)
	self.m_oModule = oModule
end

function CPropBX:LoadData(tData)
	CPropBase.LoadData(self, tData)
end

function CPropBX:SaveData()
	local tData = CPropBase.SaveData(self)
	return tData
end

--使用宝箱
function CPropBX:Use(nNum)
	assert(nNum > 0, "参数错误")
	local oRole = self.m_oModule.m_oRole
	if self:GetNum() < nNum then
		return oRole:Tips("道具不足")
	end
	self.m_oModule:SubGridItem(self:GetSysID(), self:GetGrid(), nNum, "使用道具")

	local tAwardMap = {}
	local tConf = self:GetConf()
	for k = 1, nNum do
		local tItemList = ctBoxConf.GetDropItem(tConf.nID)
		for _, tItem in ipairs(tItemList) do
			local sKey = tItem[1]..tItem[2]
			if not tAwardMap[sKey] then
				tAwardMap[sKey] = {nType=tItem[1], nID=tItem[2], nNum=0}
			end
			tAwardMap[sKey].nNum = tAwardMap[sKey].nNum + tItem[3]
		end
	end

	local tAwardList = {}
	for _, tItem in pairs(tAwardMap) do
		table.insert(tAwardList, tItem)
		oRole:AddItem(tItem.nType, tItem.nID, tItem.nNum, "使用道具")
	end
	Network.PBSrv2Clt(oRole:GetSession(), "GuoKuUseItemRet", {nPropID=tConf.nID, nPropNum=nNum, tAwardList=tAwardList})
	return true
end