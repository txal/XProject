--神器系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
function CArtifact:Ctor(oRole)
	--print("创建神器系统**************")
	self.m_oRole = oRole
	self.m_oArtifact = {}	--神器对象self.m_oArtifact[ID] = CArtifactOBJ
	self.m_nCurArtifactID = 0	--当前使用神器ID
end

function CArtifact:LoadData(tData)
	if not tData then return end
	for _, tArtifact in pairs(tData.m_oArtifact or {}) do
		local oArtifact = CArtifactObj:new(self, tArtifact.m_nID)
		if oArtifact then
			oArtifact:LoadData(tArtifact)
			self.m_oArtifact[tArtifact.m_nID] = oArtifact
		end
	end

	self.m_nCurArtifactID = tData.nCurArtifactID
 end

function CArtifact:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)
	
	local tData = {}
	tData.m_oArtifact = {}
	for nID, oArtifact in pairs(self.m_oArtifact) do
		tData.m_oArtifact[nID] = oArtifact:SaveData()
	end

	tData.nCurArtifactID = self.m_nCurArtifactID
	return tData
end

function CArtifact:IsSysOpen(bTips)
 	return self.m_oRole.m_oSysOpen:IsSysOpen(54, bTips)
end

function CArtifact:Release() end
function CArtifact:Online()
	-- if self:IsSysOpen() then
		self:ArtifactListReq()
	-- end
	self.m_oRole:FlushRoleView()
end
function CArtifact:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CArtifact:IsDirty() return self.m_bDirty end

function CArtifact:GetType() 
	return gtModuleDef.tArtifact.nID, gtModuleDef.tArtifact.sName 
end

function CArtifact:GetPropCfg(nID)
	return ctPropConf[nID]
end

--获取神器
function CArtifact:GetArtifact(nID)
	return self.m_oArtifact[nID]
end

--获取当前使用的神器
function CArtifact:GetoArtifact()
	return self.m_oArtifact[self.m_nCurArtifactID]
end

--获取基础属性
function CArtifact:GetBattleAttr()
	local tBattleAttr = {}
	local  tAttr = {}
	for nID, oArtifact in pairs(self.m_oArtifact) do
		tAttr = oArtifact:GetBattleAttr()
		if tAttr then
			for nAttrID, nAttr in pairs(tAttr) do
				tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) + nAttr
			end
		end
	end
	return tBattleAttr
end

function CArtifact:CalcAttrScore()
	local nScore = 0
	local tAttrList = self:GetBattleAttr()
	for nAttrID, nAttrVal in pairs(tAttrList) do 
		nScore = nScore + CUtil:CalcAttrScore(nAttrID, nAttrVal)
	end
    return nScore
end

--神器列表请求
function CArtifact:ArtifactListReq()
	local tArtifactList = {}
	for _, oArtifact in pairs(self.m_oArtifact) do
		tArtifactList[#tArtifactList+1] = oArtifact:GetInfo()
	end
	local tMsg = {}
	tMsg.tArtifactList = tArtifactList
	tMsg.nCurArtifactID = self.m_nCurArtifactID or 0
	print("神器", tMsg.nCurArtifactID)
	self.m_oRole:SendMsg("ArtifactListRet", tMsg)
end

--激活检测
function CArtifact:Activation(nID)
	local tArtifact = self:GetConf(nID)
	if not tArtifact then return self.m_oRole:Tips("配置文件不存在") end
	local oArtifact = CArtifactObj:new(self, nID)
	if oArtifact then
		self.m_oArtifact[nID] = oArtifact
		--神器列表刷新
		self:ArtifactListReq()
		self.m_oRole:UpdateAttr()
		self.m_oRole:UpdateActGTGodEquPower()
		self:MarkDirty(true)
	end
end

function CArtifact:USEArtivaion(nID,  nType)
	if not self:IsSysOpen(true) then
		return
	end
	local tArtifact = self:GetPropCfg(nID)
	if not tArtifact then
		return 
	end
	--nType为1使用神器,为2使用神器碎片激活
	local nArtifactID = nID
	if nType == 1 then
		if tArtifact.nType ~= gtPropType.eArtifact then
			return self.m_oRole:Tips("道具不是神器类型")
		end
		if self:GetArtifact(nArtifactID) then
			return self.m_oRole:Tips("该神器已经激活")
		end
		local bRet = self.m_oRole:CheckSubItem(gtItemType.eProp, nID, 1, "神器使用")
		if not bRet then
	 		return self.m_oRole:Tips("道具不足")
	  	end
	elseif nType == 2 then
		if tArtifact.nType ~= gtPropType.eArtifactChip then
			return self.m_oRole:Tips("道具不是神器碎片类型")
		end
		nArtifactID = tArtifact.eParam1()
		if not nArtifactID then return end
		if not self:GetConf(nArtifactID) then return end
		if self:GetArtifact(nArtifactID) then
			return self.m_oRole:Tips("该神器已经激活")
		end
		if not tArtifact.eParam() then
			return
		end
		local bRet = self.m_oRole:CheckSubItem(gtItemType.eProp, nID, tArtifact.eParam(), "神器激活消耗")
		if not bRet then return self.m_oRole:Tips("道具不足") end
	else
		return 
	end
	
	self:Activation(nArtifactID)
	local tMsg = {nArtifactID = nArtifactID}
	self.m_oRole:SendMsg("ArtifactUseRet", tMsg)
end

function CArtifact:GetConf(nID)
	return ctArtifactConf[nID]
end

--神器升级请求
function CArtifact:ArtifactUpgradeReq(nID, bType)
	if not self:IsSysOpen(true) then
		return
	end
	local oArtifact = self.m_oArtifact[nID]
	if not oArtifact then return self.m_oRole:Tips("神器不存在") end
	if oArtifact:GetLevel() >= oArtifact:GetMaxLevel() then
		return self.m_oRole:Tips("神器属性已经升到上限，请先进阶神器星级")
	end

	--优先使用道具，然后元宝补足
	local tUpgradeCost = oArtifact:GetUpgradeCost()
	if not tUpgradeCost then return self.m_oRole:Tips("神器等级达到上限了") end
	local tPropCfg = ctPropConf[tUpgradeCost[1][1]]
	if not tPropCfg then return self.m_oRole:Tips("配置不存在") end

	local nCurPropNum = self.m_oRole:ItemCount(gtItemType.eProp, tUpgradeCost[1][1])
	local bFlag = false
	local _ArtifactHandle = function ()
		oArtifact:SetLevel(1)
		oArtifact:UpdateAttr()
		self.m_oRole:UpdateAttr()
		self.m_oRole:UpdateActGTGodEquPower()
		self:MarkDirty(true)
		local tMsg = {nLevel = oArtifact:GetLevel(), nArtifactID = oArtifact:GetID()}
		print("升级消息返回推送", tMsg)
		self.m_oRole:SendMsg("ArtifactUpgradeRet", tMsg)
		self:ArtifactListReq()
		--self:ArtifactChange(oArtifact:GetID())
	end

	if bType then
		--元宝补足
		local fnSubPropCostCallback = function (bRet)
			if not bRet then return end
			_ArtifactHandle()
		end
		local tItemCostList = {{gtItemType.eProp, tUpgradeCost[1][1], tUpgradeCost[1][2]}}
		self.m_oRole:SubItemByYuanbao(tItemCostList, "神器升级消耗", fnSubPropCostCallback, false)
	else
		if nCurPropNum < tUpgradeCost[1][2] then
			return self.m_oRole:Tips("道具不足")
		end
		self.m_oRole:SubItem(gtItemType.eProp, tUpgradeCost[1][1], tUpgradeCost[1][2], "神器升级消耗")
		_ArtifactHandle()
	end
end

--添加经验请求
function CArtifact:ArtifactAddExpReq(nArtifactID, tItemCostList)
	if not nArtifactID or not tItemCostList or not next(tItemCostList) then
		return self.m_oRole:Tips("参数错误")
	end
	local tSubItemList = {}
	local oArtifact = self.m_oArtifact[nArtifactID]
	if not oArtifact then return self.m_oRole:Tips("神器不存在") end
	local nTotalExp = 0
	for _, tItem in ipairs(tItemCostList) do
		local tProp = ctPropConf[tItem.nPropID]
		assert(tProp, string.format("道具配置不存在<%d>", tItem.nPropID))
		if tItem.nNum < 1 then
			return self.m_oRole:Tips("道具数量错误")
		end
		nTotalExp = tProp.eParam() *tItem.nNum
		table.insert(tSubItemList, {gtItemType.eProp, tItem.nPropID, tItem.nNum})
	end
	local bRet = self.m_oRole:CheckSubItemList(tSubItemList, "神器增加进阶经验消耗")
	if not bRet then return self.m_oRole:Tips("道具不足") end
	oArtifact:AddAdvancedExp(nTotalExp)
	local tMsg = {}
	tMsg.nCurAdvancedExp = oArtifact:GetAdvancedExp()
	tMsg.nArtifactID = oArtifact:GetID()
	self:MarkDirty(true)
	print("添加进阶经验返回", tMsg)
	local sTips = "使用成功,%s神器经验+%d"
	self.m_oRole:Tips(string.format(sTips, oArtifact:GetName(), nTotalExp))
	self.m_oRole:SendMsg("ArtifactAddExpRet", tMsg)
end

--神器升星请求
function CArtifact:ArtifactAscendingStarReq(nID)
	if not self:IsSysOpen(true) then
		return
	end
	local oArtifact = self.m_oArtifact[nID]
	if not oArtifact then return self.m_oRole:Tips("神器不存在") end
	local AscendingStarCfg = oArtifact:GetAscendingStarCost()
	if not AscendingStarCfg then return end
	if self.m_oRole:GetLevel() < AscendingStarCfg.nRoleLevel then
		return self.m_oRole:Tips("角色等级不足")
	end
	if oArtifact:GetAdvancedExp() < AscendingStarCfg.nAdvancedExp then
		return self.m_oRole:Tips("进阶经验不足")
	end
	if oArtifact:GetStar() == oArtifact:GetMaxStar() then
		return self.m_oRole:Tips("当前已经是最大星级了。请进阶其他的神器吧")
	end
	--流水
	oArtifact:AddAdvancedExp(-AscendingStarCfg.nAdvancedExp)
	oArtifact:SetStar(1)
	self:MarkDirty(true)
	self.m_oRole:FlushRoleView()
	self.m_oRole:UpdateAttr()
	self.m_oRole:UpdateActGTGodEquPower()
	local tMsg = {}
	tMsg.nStar = oArtifact:GetStar()
	tMsg.nArtifactID = oArtifact:GetID()
	print("神器升级消息推送", tMsg)
	self.m_oRole:SendMsg("ArtifactAscendingStarRet", tMsg)
	--self:ArtifactListReq()
	self:ArtifactChange(oArtifact:GetID())
end

--单个神器信息改变推送
function CArtifact:ArtifactChange(nArtifactID)
	local oArtifact = self.m_oArtifact[nArtifactID]
	if not oArtifact then return end
	local tMsg = {}
	tMsg.tArtifact = oArtifact:GetInfo()
	print("神器信息改变推送", tMsg)
	self.m_oRole:SendMsg("ArtifactChangeRet", tMsg)
end


function CArtifact:ArtifactUseShapeReq(nArtifactID)
	if not self:IsSysOpen(true) then
		return
	end
	if not nArtifactID then return end
	if not self.m_oArtifact[nArtifactID] then
		self.m_oRole:Tips("该神器没有激活")
	end
	self.m_nCurArtifactID = nArtifactID
	local tMsg = {}
	tMsg.nArtifactID = self.m_nCurArtifactID
	self:MarkDirty(true)
	print("神器--------------------", tMsg)
	self.m_oRole:SendMsg("ArtifactUseShapeRet", tMsg)
	self.m_oRole:FlushRoleView()
 end

  function CArtifact:ArtifactCallUseShapeReq(nArtifactID)
  	if not self:IsSysOpen(true) then
		return
	end
  	if not nArtifactID then return end
	if not self.m_oArtifact[nArtifactID] then
		self.m_oRole:Tips("该神器没有激活")
	end
	if self.m_nCurArtifactID ~= nArtifactID then
		return self.m_oRole:Tips("神器没有使用,不用取消")	
	end
	self.m_nCurArtifactID = 0
	self.m_oRole:FlushRoleView()
	self:MarkDirty(true)
	local tMsg = {}
	tMsg.nArtifactID = nArtifactID
	self.m_oRole:SendMsg("ArtifactCallUseShapeRet", tMsg)
  end