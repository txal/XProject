--消耗类
function CPropXH:Ctor(oModule, nSysID, nGrid)
	CPropBase.Ctor(self, nSysID, nGrid)
	self.m_oModule = oModule
end

function CPropXH:LoadData(tData)
	CPropBase.LoadData(self, tData)
end

function CPropXH:SaveData()
	local tData = CPropBase.SaveData(self)
	return tData
end

--使用道具不返回
function CPropXH:UseRaw(nNum, tAwardMap)
	assert(nNum > 0, "参数错误")

	local oRole = self.m_oModule.m_oRole
	if self:GetNum() < nNum then
		return oRole:Tips("道具不足")
	end
	self.m_oModule:SubGridItem(self:GetSysID(), self:GetGrid(), nNum, "使用道具")

	tAwardMap = tAwardMap or {}
	local tConf = self:GetConf()
	for k = 1, nNum do
		for _, tItem in ipairs(tConf.tOpenAward) do
			local sKey = tItem[1]..tItem[2]
			if not tAwardMap[sKey] then
				tAwardMap[sKey] = {nType=tItem[1], nID=tItem[2], nNum=0}
			end
			tAwardMap[sKey].nNum = tAwardMap[sKey].nNum + tItem[3]
		end
	end

	return tAwardMap
end

--使用道具
function CPropXH:Use(nNum, tAwardMap)
	assert(nNum > 0, "参数错误")
	tAwardMap = self:UseRaw(nNum, tAwardMap)
	if not tAwardMap then
		return
	end
	local oRole = self.m_oModule.m_oRole

	local tAwardList = {}
	for _, tItem in pairs(tAwardMap) do
		table.insert(tAwardList, tItem)
		oRole:AddItem(tItem.nType, tItem.nID, tItem.nNum, "使用道具")
	end

	Network.PBSrv2Clt(oRole:GetSession(), "GuoKuUseItemRet", {nPropID=self:GetSysID(), nPropNum=nNum, tAwardList=tAwardList})
	return true
end