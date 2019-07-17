--法宝系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nFaBaoMaxGrid = 200	--法宝背包最大格子数

function CFaBao:Ctor(oRole)
	self.m_oRole = oRole
	self.m_bDirty = false
	self.m_oFaBaoMap = {}		--法宝对象 self.m_oFaBao[nGrid] = oFaBaoObj
	self.m_oFaBaoWerMap = {}	--法宝对象  self.m_tFaBaoWerMap[gtFaBaoPartType.eGold] = oFaBaoObj
	self.m_tFaBaoSuitAttr = {}	--套装属性  self.m_tSuiAttr[nSuitIndex] = {nPropID = 32507}
end

function CFaBao:LoadData(tData)
	if not tData then
		return 
	end

	--法宝背包
	for _,tItem in pairs(tData.m_oFaBaoMap) do
		local oProp = self:CreateFaBao(tItem.m_nID, tItem.m_nGrid)
		if oProp then
			oProp:LoadData(tItem)
			self.m_oFaBaoMap[tItem.m_nGrid] = oProp
		end
	end

	--法宝系统身上6个法宝对象
	for nPart, tItem in pairs(tData.m_oFaBaoWerMap) do
		local oProp = self:CreateFaBao(tItem.m_nID, tItem.m_nGrid)
		if oProp then
			oProp:LoadData(tItem)
			self.m_oFaBaoWerMap[nPart] = oProp
		end
	end

	self.m_tFaBaoSuitAttr = tData.m_tFaBaoSuitAttr or {}
end

function CFaBao:SaveData()
	-- print("保存法宝数据------")
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	--法宝背包
	tData.m_oFaBaoMap = {}
	for nGrid, oFaBao in pairs(self.m_oFaBaoMap) do
		tData.m_oFaBaoMap[nGrid] = oFaBao:SaveData()
	end

	--法宝六个位置对象
	tData.m_oFaBaoWerMap = {}
	for nPart, oFaBao in pairs(self.m_oFaBaoWerMap) do
		tData.m_oFaBaoWerMap[nPart] = oFaBao:SaveData()
	end
	tData.m_tFaBaoSuitAttr = self.m_tFaBaoSuitAttr
	return tData
end

--玩家上线同步背包道具
function CFaBao:Online()
	self:FaBaoAttrPageReq()
	self:SyncKnapsackItems()
end

function CFaBao:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CFaBao:IsDirty() return self.m_bDirty end
function CFaBao:OutFaBaoInfo() end

function CFaBao:ClearFaBaoMap()
	print("清除法宝信息------")
	self.m_oFaBaoMap = {}
	self:MarkDirty(true)
	self:SyncKnapsackItems()
end


function CFaBao:AddFaBao(nID, nNum ,bBind, tPropExt)
	print("添加法宝........", nID)
	print("法宝数量--------------", nNum)
	if nNum <= 0 then
		return
	end
	local tFaBaoInfoList = {}
	if not tPropExt then tPropExt = {} end
	tPropExt.bBind = bBind
	 local tGridList = self:GetEmptyPos(nNum)
	 local tmpFaBao
	 for _, nGrid in ipairs(tGridList or {}) do
		 local oFaBao = self:CreateFaBao(nID, nGrid ,tPropExt)
		 if oFaBao then
			self.m_oFaBaoMap[nGrid] = oFaBao
			table.insert(tFaBaoInfoList, oFaBao:GetInfo())
			tmpFaBao = oFaBao
		 end
	end	
	if #tGridList < nNum then
		self.m_oRole:Tips("法宝背包已满，请及时领取邮件")
		local tItemList = {{gtItemType.eFaBao,nID,nNum - #tGridList ,bBind,tPropExt}} 
		CUtil:SendMail(self.m_oRole:GetServer(), "法宝背包已满", "法宝背包已满，请及时领取邮件", tItemList, self.m_oRole:GetID())
	end

	--法宝背包满的情况下,通过邮件发送吧
	if tmpFaBao then
		self:SendProp(tmpFaBao, nNum)
	end
	self:FaBaoAddSend(tFaBaoInfoList)
	self:MarkDirty(true)
	 return true
end

function CFaBao:FaBaoAddSend(tFaBaoInfoList)
	if next(tFaBaoInfoList) then
		local tMsg = {tFaBaoInfoList = tFaBaoInfoList }
		self.m_oRole:SendMsg("FaBaoAddRet", tMsg)
	end
end

function CFaBao:FaBaoRemoveSend(tRemoveGrid)
	if next(tRemoveGrid) then
		local tMsg = {tRemoveGrid = tRemoveGrid}
		self.m_oRole:SendMsg("FaBaoPropRemoveRet", tMsg)
	end
end

function CFaBao:SendProp(oFaBao, nNum)
	local tFBInfo = oFaBao:GetFaBaoInfo()
	tFBInfo.bNew = true
	tFBInfo.bIsSync = true
	tFBInfo.nFold = nNum

	local tMsg = {nType=3, tItemList={tFBInfo}}
	self.m_oRole:SendMsg("KnapsackItemAddRet", tMsg)
end
function CFaBao:GetConf(nID) return ctFaBaoConf[nID] end
function CFaBao:GetType()
	return gtModuleDef.tFaBao.nID, gtModuleDef.tFaBao.sName
end

 function CFaBao:CreateFaBao(nID, nGrid,tPropExt)
 	if not tPropExt then tPropExt = {} end
 	local oFaBao = CFaBaoObj:new(self.m_oRole, nID, nGrid, tPropExt)
 	if oFaBao then
 		return oFaBao
 	end
 end

function CFaBao:GetEmptyPos(nNum)
	local tGridList = {}
	for nTGrid = 1, nFaBaoMaxGrid, 1 do
		if self.m_oFaBaoMap[nTGrid] == nil then
		 	tGridList[#tGridList+1] = nTGrid
		end

		if #tGridList == nNum then
			return tGridList
		end
	end
	return tGridList
end

--穿法宝请求
function CFaBao:FaBaoWearReq(nGrid, nType)
	local tRemoveGrid = {}
	local tAddInfoList = {}
	if nGrid <= 0 then return end
	local oFaBao =  self.m_oFaBaoMap[nGrid]
	if not oFaBao then
		return self.m_oRole:Tips("法宝对象不存在")
	end

	if self.m_oRole:GetLevel() < oFaBao:GetLevel() then
		return self.m_oRole:Tips("玩家等级不足")
	end

	--如果该部位已经有法宝则先脱下
	local nPartType = oFaBao:GetConf().nFaBaopPartType
	local _SwapFaBao = function (oWerFaBao, oFaBao)
		self.m_oFaBaoMap[nGrid] = nil
		local tGridList = self:GetEmptyPos(1)
		if not tGridList[1] then
			return self.m_oRole:Tips("法宝背包容量不足,清理后再穿")
		end
		oWerFaBao:SetGrid(tGridList[1])
		oFaBao:SetbWear(true)
		self.m_oFaBaoMap[tGridList[1]] = oWerFaBao
		self.m_oFaBaoWerMap[nPartType] = oFaBao
		table.insert(tRemoveGrid, nGrid)
		table.insert(tAddInfoList, oWerFaBao:GetInfo())
	end

	local oWerFaBao = self.m_oFaBaoWerMap[nPartType]
	if self.m_oFaBaoWerMap[nPartType] then
		if nType == 1 then
			local nWerLevel = oWerFaBao:GetLevel()
			local oFaBaoLevel = oFaBao:GetLevel()
			oFaBao:UpdateLevel(nWerLevel)
			oWerFaBao:UpdateLevel(oFaBaoLevel)
			_SwapFaBao(oWerFaBao, oFaBao)

		else
			_SwapFaBao(oWerFaBao, oFaBao)
		end
	else
		self.m_oFaBaoWerMap[nPartType] = oFaBao
		self.m_oFaBaoMap[nGrid] = nil
		oFaBao:SetbWear(true)
		table.insert(tRemoveGrid, nGrid)
		self:FaBaoRemoveSend(tRemoveGrid)
	end
	self:FaBaoSetCheck(oFaBao:GetID(), 1)
	self.m_oRole:UpdateAttr()
	self.m_oRole:UpdateActGTMagicEquPower()
	self:FaBaoRemoveSend(tRemoveGrid)
	self:FaBaoAddSend(tAddInfoList)
	self:FaBaoAttrPageReq()
	self:MarkDirty(true)
	local tMsg = {bFlag = true}
	self.m_oRole:SendMsg("FaBaoWearRet", tMsg)

	local tData = {}
	tData.tFaBaoLevelCountMap = {}			--{[nFaBaolevel]=nCount}
	for nPartType, oFaBao in pairs(self.m_oFaBaoWerMap) do
		local nFaBaoLevel = oFaBao:GetLevel()
		local nOldCount = tData.tFaBaoLevelCountMap[nFaBaoLevel] or 0
		tData.tFaBaoLevelCountMap[nFaBaoLevel] = nOldCount + 1
	end
	CEventHandler:OnEquFaBao(self.m_oRole, tData)

	if self.m_oRole:IsInBattle() then
		return self.m_oRole:Tips("法宝属性将在战斗后生效")
	end

end


--卸法宝请求
function CFaBao:FaBaoTakeOffReq(nGrid)
	if nGrid <= 0 then return end
	if not self.m_oFaBaoWerMap[nGrid] then
		return 
	end
	local tGridList = self:GetEmptyPos(1)
	if not tGridList[1] then
		return self.m_oRole:Tips("法宝背包容量不足,清理后再卸")
	end
	local nStars = self.m_oFaBaoWerMap[nGrid]:GetStars()
	local  nFaBaoID =  self:GetConf(self.m_oFaBaoWerMap[nGrid]:GetID()).nID
	if nStars == 6 then
		self:FaBaoSetCheck(nFaBaoID, 2)
	end
	local oFaBao = self.m_oFaBaoWerMap[nGrid]
	oFaBao:SetGrid(tGridList[1])
	self.m_oFaBaoMap[tGridList[1]] = self.m_oFaBaoWerMap[nGrid]
	if self.m_oRole:IsInBattle() then
		return self.m_oRole:Tips("法宝属性将在战斗后生效")
	end
	self.m_oFaBaoWerMap[nGrid] = nil
	self.m_oRole:UpdateAttr()
	self.m_oRole:UpdateActGTMagicEquPower()
	self:FaBaoAttrPageReq()
	self:SyncKnapsackItems()
	local tMsg = {bFlag = true, nGrid = nGrid}
	print("脱消息返回-----", tMsg)

	self.m_oRole:SendMsg("FaBaoTakeOffRet", tMsg)
	self:MarkDirty(true)

	local tData = {}
	tData.tFaBaoLevelCountMap = {}			--{[nFaBaolevel]=nCount}
	for nPartType, oFaBao in pairs(self.m_oFaBaoWerMap) do
		local nFaBaoLevel = oFaBao:GetLevel()
		local nOldCount = tData.tFaBaoLevelCountMap[nFaBaoLevel] or 0
		tData.tFaBaoLevelCountMap[nFaBaoLevel] = nOldCount + 1
	end
	CEventHandler:OnEquFaBao(self.m_oRole, tData)
end

--套装检查
function CFaBao:FaBaoSetCheck(nFaBaoID, nType)
	self.m_tFaBaoSuitAttr = {}
	for _, oFaBao in pairs(self.m_oFaBaoWerMap) do
		if ctFaBaoConf[oFaBao:GetID()].nSuitIndex > 0 then
			self.m_tFaBaoSuitAttr[ctFaBaoConf[oFaBao:GetID()].nSuitIndex] = (self.m_tFaBaoSuitAttr[ctFaBaoConf[oFaBao:GetID()].nSuitIndex] or 0) + 1
		end
	end
	self:MarkDirty(true)
end

-- --法宝祭炼请求
function CFaBao:FaBaoFeastReq(nGrid, bOnekey)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(49, true) then
		return
	end
	if nGrid <= 0 then return end
	local oFaBao = self.m_oFaBaoWerMap[nGrid]

	if not oFaBao then
		return self.m_oRole:Tips("对象不存在")
	end
	local tConf = ctFaBaoCostConf[oFaBao:GetLevel()]
	if not tConf then return end
	--人物需达到XX级，才能继续祭炼
	if tConf.nRolelevel > self.m_oRole:GetLevel() then
		return self.m_oRole:Tips("人物需达到" ..tConf.nRolelevel.. "级，才能继续祭炼")
	end
	local nCostItemID = tConf.nFeastStoneID
	local nCostItemNum = tConf.nFaBaoFeastStone
	local nCostYinBi = tConf.nFaBaoYinBi
	if self.m_oRole:GetYinBi() < nCostYinBi then
		return self.m_oRole:YinBiTips()
	end
	if bOnekey then
		local nCurFeastStone = self.m_oRole:ItemCount(gtItemType.eProp,nCostItemID)
		if nCurFeastStone < nCostItemNum then
			self.m_oRole:Tips("法宝祭炼石不足")
			return self.m_oRole:PropTips(nCostItemID)
		end
	end

	local _fnFaBaoUpdate = function ()
		oFaBao:UpdateLevel(tConf.nLevel+1)
		self:MarkDirty(true)
	end
	if not bOnekey then
		local fnSubPropCostCallback = function (bRet)
			if not bRet then return end
			_fnFaBaoUpdate()
			self.m_oRole:UpdateAttr()
			self.m_oRole:UpdateActGTMagicEquPower()
			self:FaBaoAttrPageReq()

			local tData = {}
			tData.tFaBaoLevelCountMap = {}			--{[nFaBaolevel]=nCount}
			for nPartType, oFaBao in pairs(self.m_oFaBaoWerMap) do
				local nFaBaoLevel = oFaBao:GetLevel()
				local nOldCount = tData.tFaBaoLevelCountMap[nFaBaoLevel] or 0
				tData.tFaBaoLevelCountMap[nFaBaoLevel] = nOldCount + 1
			end
			CEventHandler:OnEquFaBao(self.m_oRole, tData)	
		end
		local tItemCostList = {{gtItemType.eProp, nCostItemID, nCostItemNum}}
		tItemCostList[#tItemCostList+1] = {gtItemType.eCurr, gtCurrType.eYinBi, nCostYinBi}
		self.m_oRole:SubItemByYuanbao(tItemCostList, "法宝升级消耗", fnSubPropCostCallback, false)
	else
		self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostYinBi, "法宝一键升级", nil, nil, bOnekey)
		self.m_oRole:SubItem(gtItemType.eProp, nCostItemID, nCostItemNum, "法宝一键升级")
		_fnFaBaoUpdate()
	end
	return true
end

--一键升级(若等级相同，则优先选择星级较高。若星级相同则按照属性类型进行选择：金木水火风(5491))
function CFaBao:OnekeyUpgradeReq()
	if not self.m_oRole.m_oSysOpen:IsSysOpen(49, true) then
		return
	end
	local tFaBaoGridList = {}
	local nOldYinBi = self.m_oRole:GetYinBi()
	local nPropID = self:GetnFeastStoneID()
	local nPropNum = self.m_oRole.m_oKnapsack:ItemCount(nPropID)
	local nRolelevel = self.m_oRole:GetLevel()
	local nCount = 0
	local tUpgradeResMap = {}
	local tTargetData = {tFaBaoLevelCountMap = {}}
	for nPartType, oFaBao in pairs(self.m_oFaBaoWerMap) do
		local tConf = ctFaBaoCostConf[oFaBao:GetLevel()]
		if not tConf then return end
		--人物需达到XX级，才能继续祭炼
		if nRolelevel >= tConf.nRolelevel then
			table.insert(tFaBaoGridList, oFaBao)
		end
	end
	if #tFaBaoGridList < 1 then
		return self.m_oRole:Tips("没有可升级的法宝哦")
	end
	while #tFaBaoGridList > 0 do
		local fnComp = function (t1, t2)
			if t1:GetLevel() == t2:GetLevel() then
				if t1:GetStars() == t2:GetStars() then
					return  t1:GetType() < t2:GetType()
				end
				return t1:GetStars() > t2:GetStars()
			end	
			return t1:GetLevel() < t2:GetLevel()
		end
		table.sort(tFaBaoGridList, fnComp)
		local oUpdateFaBao = tFaBaoGridList[1]
		local nPartType = ctFaBaoConf[oUpdateFaBao:GetID()].nFaBaopPartType
		if not self:FaBaoFeastReq(nPartType, true) then
			break
		end

		nCount = nCount + 1
		tUpgradeResMap[oUpdateFaBao:GetID()] = oUpdateFaBao:GetLevel()

		--用旧的等级和新等级记录每一级升级过程(写在这里主要是为了不在每一级升级成功给客户端发协议)
		tTargetData.tFaBaoLevelCountMap[oUpdateFaBao:GetLevel()] = (tTargetData.tFaBaoLevelCountMap[oUpdateFaBao:GetLevel()] or 0) + 1

		--当前角色等级小于法宝升级则移除
		local tConf = ctFaBaoCostConf[oUpdateFaBao:GetLevel()]
		if nRolelevel < tConf.nRolelevel then
			table.remove(tFaBaoGridList, 1)
		end
		if #tFaBaoGridList < 1 then
			break
		end
	end
	--法宝升级成功
	if nCount > 0 then
		self.m_oRole:UpdateAttr()
		self.m_oRole:UpdateActGTMagicEquPower()
		self:FaBaoAttrPageReq()
        self.m_oRole.m_oKnapsack:SyncCachedMsg()

		--减轻客户端压力,所以在这里发送银币及道具消耗消耗（BT没有"subitem")
  --       local nSubYinBi = nOldYinBi - self.m_oRole:GetYinBi()
  --       local nYinBiID = ctPropConf:GetCurrProp(gtCurrType.eYinBi)
		-- CUtil:SendItemTalk(self.m_oRole, "subitem", {nYinBiID, nSubYinBi})
		CEventHandler:OnEquFaBao(self.m_oRole, tTargetData)
	end
end

--法宝合成
--bFlag--是否使用元宝补足
--tItemList为空的时候自动补足一星法宝
function CFaBao:FaBaoCompositeReq(tItemList, bFlag)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(49, true) then
		return
	end
	if not tItemList then return end
	if not bFlag then
		if #tItemList < 5 or #tItemList > 5 then
			return 
		end
	end
	local tFaBaoList = {}
	local nFaBaoGrade
	local tCostCfg
	local nMaxLevel = 0
	local nCostYinBi = 0
	local nCostFeastStone = 0
	local nFeastStoneID 
	local tFaBaoComposeProbability
	local tRemoveGrid = {} 
	local nNewFaBaoID 
	local nCostFaBaoID= self:FindShopFaBaoID()
	for _, nGrid in ipairs(tItemList) do
		assert(self.m_oFaBaoMap[nGrid], "法宝对象不存在" .. nGrid)
		if self.m_oFaBaoMap[nGrid] then
			if not nFaBaoGrade then
				 nFaBaoGrade = self.m_oFaBaoMap[nGrid]:GetStars()
				 --1级的时候消耗为0,特殊处理一波
				if  self.m_oFaBaoMap[nGrid]:GetLevel() == 1 then
					nCostFeastStone = 0
					nCostYinBi = 0
				else
					 nCostFeastStone = ctFaBaoCostConf[self.m_oFaBaoMap[nGrid]:GetLevel() - 1].nSumFaBaoFeastStone
				 	 nCostYinBi = ctFaBaoCostConf[self.m_oFaBaoMap[nGrid]:GetLevel() -1].nSumFaBaoYinBi
				end
				 nMaxLevel = self.m_oFaBaoMap[nGrid]:GetLevel()
				 tFaBaoComposeProbability = ctFaBaoConf[self.m_oFaBaoMap[nGrid]:GetID()].tFaBaoComposeProbability
			else
				if nFaBaoGrade ~= self.m_oFaBaoMap[nGrid]:GetStars() then
					return self.m_oRole:Tips("五个法宝星级必须一样")
				end
				if nMaxLevel < self.m_oFaBaoMap[nGrid]:GetLevel() then
					nMaxLevel = self.m_oFaBaoMap[nGrid]:GetLevel()
				end
				if  self.m_oFaBaoMap[nGrid]:GetLevel() == 1 then
					nCostFeastStone = nCostFeastStone + 0
					nCostYinBi = nCostYinBi + 0
				else
					 nCostFeastStone = nCostFeastStone + ctFaBaoCostConf[self.m_oFaBaoMap[nGrid]:GetLevel() - 1].nSumFaBaoFeastStone
				 	nCostYinBi = nCostYinBi + ctFaBaoCostConf[self.m_oFaBaoMap[nGrid]:GetLevel() -1].nSumFaBaoYinBi
				end
				-- nCostFeastStone =  nCostFeastStone +  ctFaBaoCostConf[self.m_oFaBaoMap[nGrid]:GetLevel()].nSumFaBaoFeastStone
				-- nCostYinBi = nCostYinBi + ctFaBaoCostConf[self.m_oFaBaoMap[nGrid]:GetLevel()].nSumFaBaoYinBi
			end
			if bFlag then
				 -- if nFaBaoGrade ~= 1 then
				 -- 	return self.m_oRole:Tips("只有1星法宝才可以补足哦")
				 -- end
			end
		end
	end
	if #tItemList <= 0 then
		tFaBaoComposeProbability = ctFaBaoConf[nCostFaBaoID].tFaBaoComposeProbability
		nFaBaoGrade = ctFaBaoConf[nCostFaBaoID].nFaBaoGrade
		nMaxLevel = ctFaBaoConf[nCostFaBaoID].nLevel
	end
	if nFaBaoGrade > self:GetMaxComResetStar() then
		return self.m_oRole:Tips(string.format("法宝星级不能高于%d星哦", self:GetMaxComResetStar()))
	end

	for _, tConf in ipairs(tFaBaoComposeProbability) do
		if tConf[1] == nFaBaoGrade then
			tCostCfg = tConf
			break
		end
	end

	if self.m_oRole:GetYinBi() < tCostCfg[3] * 10000 then
		return self.m_oRole:YinBiTips()
	end
	--nMakeNum 元宝补足的法宝个数
	local  _FaBaoHandle = function (nMakeNum)
		local nRan = math.random(1,100)
		nFaBaoGrade = nFaBaoGrade and nFaBaoGrade or 1
		if nRan <= tCostCfg[2] then
			for _, nGrid in ipairs(tItemList) do
				local nRet =  self:SubGridItem(self.m_oFaBaoMap[nGrid]:GetGrid(), "法宝合成消耗", true)
				if not nRet then
					return self.m_oRole:Tips("法宝合成失败")
				end
				table.insert(tRemoveGrid, nGrid)
			end
			nNewFaBaoID = self:GetNewFaBao(nFaBaoGrade)
			assert(nNewFaBaoID, "新法宝ID错误")
			if not nNewFaBaoID then return end
			local tPropExt = {nLevel = nMaxLevel}
			local nOverYinBi = nMaxLevel > 1 and ctFaBaoCostConf[nMaxLevel-1].nSumFaBaoYinBi or 0
			local nOverFeastone = nMaxLevel > 1 and ctFaBaoCostConf[nMaxLevel-1].nSumFaBaoFeastStone or 0
			nCostYinBi = nCostYinBi - nOverYinBi
			nCostFeastStone = nCostFeastStone - nOverFeastone
			nFeastStoneID = self:GetnFeastStoneID()
			self.m_oRole:AddItem(gtItemType.eProp, nFeastStoneID, nCostFeastStone, "法宝合成获得")
			self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostYinBi, "法宝合成获得")

			if next(tRemoveGrid) then
				self:FaBaoRemoveSend(tRemoveGrid)
			end
			if nNewFaBaoID then
				local tPropExt = {nLevel = nMaxLevel}
				self.m_oRole:AddItem(gtItemType.eFaBao, nNewFaBaoID, 1, "法宝合成获得", false, false, tPropExt)
			end
			local tMsg = {}
			tMsg.nID = nNewFaBaoID
			tMsg.nYinBi = nCostYinBi
			tMsg.bFlag = true
			tMsg.nFeastStone = nCostFeastStone
			print("成功消息返回", tMsg)
			self.m_oRole:SendMsg("FaBaoCompositeRet", tMsg)
		else
			nCostFeastStone = 0
			nCostYinBi  = 0
			local nBet = 25
			local nCount = 0
			local tCostItemList = {}
			local tList = {}
			nFeastStoneID = self:GetnFeastStoneID()
			for _, nGrid in ipairs(tItemList) do
				--nFeastStoneID = 
				local nRan = math.random(1,100)
				if nRan <= nBet then
					nCount = nCount + 1
					tList[#tList+1] = {nGrid = nGrid}
					tCostItemList[#tCostItemList+1] = {nID = self.m_oFaBaoMap[nGrid]:GetID()}
				else
					local nOverYinBi = 0
					local nOverFeastone = 0
					if self.m_oFaBaoMap[nGrid]:GetLevel() == 1 then
						nOverYinBi = nOverYinBi +  self.m_oFaBaoMap[nGrid]:GetStars() * 10000
						nOverFeastone = 0
						tCostItemList[#tCostItemList+1] = {nID = 4}
					else
						nOverYinBi = ctFaBaoCostConf[self.m_oFaBaoMap[nGrid]:GetLevel()- 1].nSumFaBaoYinBi + self.m_oFaBaoMap[nGrid]:GetStars() * 10000
						nOverFeastone = ctFaBaoCostConf[self.m_oFaBaoMap[nGrid]:GetLevel()-1].nSumFaBaoFeastStone
						tCostItemList[#tCostItemList+1] = {nID = nFeastStoneID}
					end
					nCostYinBi = nCostYinBi + nOverYinBi
					nCostFeastStone = nCostFeastStone + nOverFeastone
					self:SubGridItem(nGrid,"法宝合成消耗", true)
					table.insert(tRemoveGrid, nGrid)
				end
			end

			--元宝补足的必定返回一万银币
			if bFlag then
				nCostYinBi = nCostYinBi + nMakeNum * 10000 * nFaBaoGrade
			end
			self.m_oRole:AddItem(gtItemType.eProp, nFeastStoneID, nCostFeastStone, "法宝合成获得")
			self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostYinBi, "法宝合成获得")
			if next(tRemoveGrid) then
				self:FaBaoRemoveSend(tRemoveGrid)
			end
			local tMsg = {}
			tMsg.nYinBi = nCostYinBi
			tMsg.nFeastStone = nCostFeastStone
			tMsg.nNum = nCount
			tMsg.bFlag =  false
			tMsg.tCostItemList = tCostItemList 
			tMsg.ItemList = tList
			print("失败消息返回----", tMsg)
			self.m_oRole:SendMsg("FaBaoCompositeRet", tMsg)
		end
		self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eYinBi, tCostCfg[3] * 10000, "法宝合成消耗")
		CEventHandler:OnFaBaoCompose(self.m_oRole, {})
	end

	--使用元宝补足
	if #tItemList < 5 then
		local nStar = nFaBaoGrade and nFaBaoGrade or 1
		local nCostYuanBao = ctFaBaoCompositeConf[nStar].nCostYuanBao * (5 - #tItemList)
		local bRet = self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nCostYuanBao, "法宝合成消耗")
		if not bRet then return end
		_FaBaoHandle(5 - #tItemList)
	else
		_FaBaoHandle(5 - #tItemList)
	end

end


function CFaBao:FindShopFaBaoID()
	local nItemID
	for _, tItem in pairs(ctCommerceItem) do
		if tItem.nTradeMenuId == 1600 then
			nItemID = tItem.nId
			break
		end
	end
	assert(nItemID, "商会法宝配置错误")
	return nItemID
end

function CFaBao:FaBaoFind(nFaBaoID)
	for _, oFaBao in pairs(self.m_oFaBaoMap) do
		if oFaBao:GetID() == nFaBaoID then
			return true
		end
	end
end

function CFaBao:GetnFeastStoneID()
	for _, tConf in pairs(ctFaBaoCostConf) do
		return tConf.nFeastStoneID
	end
end

function CFaBao:GetMaxComResetStar()
	local nFaBaoID = next(ctFaBaoConf)
	return ctFaBaoConf[nFaBaoID].nMaxCompResetStar
end

--删除指定格子法宝
function CFaBao:SubGridItem(nGrid,sReason,bFlag)
	assert(sReason, "请说明原因")
	local tRemoveGrid = {}
	local oProp = self.m_oFaBaoMap[nGrid]
	if not oProp then
		return LuaTrace("道具不存在", nGrid)
	end
	local nPropID =  oProp:GetID()
	self.m_oFaBaoMap[nGrid] = nil
	table.insert(tRemoveGrid, nGrid)
	if not bFlag then 
		self:FaBaoRemoveSend(tRemoveGrid)
	end
	self:MarkDirty(true)
	goLogger:AwardLog(gtEvent.eSubItem, sReason, self.m_oRole, gtItemType.eFaBao, nPropID, 1, 0) 
	return true
end

function CFaBao:GetNewFaBao(nFaBaoGrade)
	local tItemList = {}
	nFaBaoGrade = nFaBaoGrade +1
	local nWeight, tFaBaoList = self:GetFaBaoWeight(nFaBaoGrade)
	if nWeight <= 0 or not next(tFaBaoList) then return end
	local nRanValue = 0
	local nCurValue = math.random(1, nWeight)
	for _, nFaBaoID in ipairs(tFaBaoList) do
		if ctFaBaoConf[nFaBaoID] then
			nRanValue = nRanValue + ctFaBaoConf[nFaBaoID].nWeights
			if nRanValue >= nCurValue then
				return nFaBaoID
			end
		end
	end
end

--法宝重置请求
function CFaBao:FaBaoResetReq(tResetList)
	if #tResetList < 2 then return end
	local tRemoveGrid = {}
	local oFaBao1 = self.m_oFaBaoMap[tResetList[1]]
	local oFaBao2 = self.m_oFaBaoMap[tResetList[2]]
	if not oFaBao2 or not oFaBao1 then
		return self.m_oRole:Tips("法宝对象不存在")
	end
	if oFaBao1:GetStars() < self:GetMaxComResetStar()
		 or oFaBao2:GetStars() < self:GetMaxComResetStar() then
		return self.m_oRole:Tips(string.format("只有大于等于%d星法宝才能进行重置", self:GetMaxComResetStar()))
	end
	local tConf =  self:GetConf(oFaBao2:GetID())
	if not tConf then return self.m_oRole:Tips("配置文件不存在") end
	local tCostCfg  =tConf.tFaBaoReset 
	local nCostYinBi =tCostCfg[1][2] * 10000
	if  nCostYinBi <= 0 then return end
	if self.m_oRole:GetYinBi() < nCostYinBi then
		return self.m_oRole:YinBiTips()
	end
	local nRet1 = self:SubGridItem(oFaBao1:GetGrid(), "法宝重置消耗", true)
	local nRet2 = self:SubGridItem(oFaBao2:GetGrid(), "法宝重置消耗", true)
	table.insert(tRemoveGrid, oFaBao1:GetGrid())
	table.insert(tRemoveGrid, oFaBao2:GetGrid())
	if not nRet2 or not nRet1 then
		return self.m_oRole:Tips("法宝重置失败")
	end
	self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostYinBi, "法宝重置消耗")

	local nLevel
	if oFaBao2:GetLevel() < oFaBao1:GetLevel() then
		nLevel = oFaBao1:GetLevel()
	else
		nLevel = oFaBao2:GetLevel()
	end
	local nNewFaBaoID = self:RandomGetFaBao(oFaBao1:GetID(), oFaBao2:GetID())
	local PropExt = {}
	PropExt.nLevel = nLevel
	--返还法宝消耗的材料
	local nCostYinBi = ctFaBaoCostConf[oFaBao1:GetLevel()].nSumFaBaoYinBi + ctFaBaoCostConf[oFaBao2:GetLevel()].nSumFaBaoYinBi
	local nSumFaBaoFeastStone = ctFaBaoCostConf[oFaBao1:GetLevel()].nSumFaBaoFeastStone + ctFaBaoCostConf[oFaBao2:GetLevel()].nSumFaBaoFeastStone
	self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostYinBi, "法宝重置获得")
	self.m_oRole:AddItem(gtItemType.eProp, ctFaBaoCostConf[oFaBao1:GetLevel()].nFeastStoneID, nSumFaBaoFeastStone, "法宝重置获得")

	self:FaBaoRemoveSend(tRemoveGrid)
	self.m_oRole:AddItem(gtItemType.eFaBao, nNewFaBaoID, 1, "法宝重置获得",false,false,PropExt)
	local tMsg = {}
	tMsg.nID = nNewFaBaoID
	tMsg.nYinBi = nCostYinBi
	tMsg.nFeastStone = nSumFaBaoFeastStone
	self.m_oRole:SendMsg("FaBaoResetRet", tMsg)

	print("法宝重置消息返回", tMsg)
end

function CFaBao:RandomGetFaBao(nID1, nID2)
	if not ctFaBaoConf[nID1] or not ctFaBaoConf[nID2] then
		return 
	end
	local nFaBaoGrade = ctFaBaoConf[nID1].nFaBaoGrade
	local tItemList = {}
	for _, tItem in pairs(ctFaBaoConf) do
		if tItem.nFaBaoGrade == nFaBaoGrade and tItem.nID ~= ctFaBaoConf[nID1].nID and tItem.nFaBaoAttr ~=  ctFaBaoConf[nID1]. nFaBaoAttr and 
									 tItem.nID ~= ctFaBaoConf[nID2].nID and tItem.nFaBaoAttr ~=  ctFaBaoConf[nID2]. nFaBaoAttr then
			tItemList[#tItemList+1] = tItem.nID
		end
	end
	return tItemList[math.random(1,#tItemList)]
end

function CFaBao:GetFaBaoWeight(nStars)
	local nWeight = 0
	local tFaBaoList = {}
	for _, tFaBao in pairs(ctFaBaoConf) do
		if tFaBao.nFaBaoGrade == nStars then
			nWeight = nWeight + tFaBao.nWeights
			table.insert(tFaBaoList, tFaBao.nID)
		end
	end
	return nWeight, tFaBaoList
end

function CFaBao:GetBattleAttr()
	local tBattleAttr = {}
	for _, oFaBao in pairs(self.m_oFaBaoWerMap) do
		for nBAT, nAttr in pairs(oFaBao:GetBattleAttr()) do
			tBattleAttr[nBAT] = (tBattleAttr[nBAT] or 0) + nAttr
		end
	end
	
	--套装属性
	local SuitBattleAttr = self:GetSuitBattleAttr()
	if SuitBattleAttr then
		for nAttrID, nSetAttr in pairs(SuitBattleAttr) do
			tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) + nSetAttr
		end
	end
	return tBattleAttr
end

function CFaBao:CalcAttrScore()
	local nScore = 0
	local tAttrList = self:GetBattleAttr()
	for nAttrID, nAttrVal in pairs(tAttrList) do 
		nScore = nScore + CUtil:CalcAttrScore(nAttrID, nAttrVal)
	end

	for _, oFaBao in pairs(self.m_oFaBaoWerMap) do
		nScore = nScore + (ctFaBaoConf[oFaBao:GetID()] and ctFaBaoConf[oFaBao:GetID()].nScore or 0)
	end
	return nScore
end

function CFaBao:GetSuitBattleAttr()
	local tBattleAttr = {}
	local tSui2
	local tSui3
	for nSuitIndex, nSui in pairs(self.m_tFaBaoSuitAttr) do
		if ctFaBaoSuit[nSuitIndex] then
			local tmpBattleAttr = {}
			if nSui ==2 then
				tSui2 = ctFaBaoSuit[nSuitIndex].tAttrActTwo
			elseif nSui == 3 then
				tSui2 = ctFaBaoSuit[nSuitIndex].tAttrActTwo
				tSui3 = ctFaBaoSuit[nSuitIndex].tAttrActThree

			end

			if tSui2 then
				for _, tAttr in ipairs(tSui2) do
					--tBattleAttr[tAttr[1]] = (tBattleAttr[tAttr[1]] or 0) + tAttr[2]
					tmpBattleAttr[tAttr[1]] = (tmpBattleAttr[tAttr[1]] or 0) + tAttr[2]
				end
			end

			if tSui3 then
				--清除2套装的属性
				tmpBattleAttr = {}
				for _, tAttr in ipairs(tSui3) do
					tmpBattleAttr[tAttr[1]] = (tmpBattleAttr[tAttr[1]] or 0) + tAttr[2]
				end
			end
			
			for nAttrID, nAttrVal in pairs(tmpBattleAttr) do
				tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) + nAttrVal
			end
			tSui2 = nil
			tSui3 = nil
		end
	end
	return tBattleAttr
end

--属性页面请求
function CFaBao:FaBaoAttrPageReq()
	local tMsg = {tTotalAttrList = {},tFaBaoInfoList = {}}
	local tAttr = {}
	local tFaBaoAttrList = {}
	for _, oFaBao in pairs(self.m_oFaBaoWerMap) do
		tFaBaoAttrList = {}
		for nBAT, nAttr in pairs(oFaBao:GetBattleAttr()) do
			tAttr[nBAT] = (tAttr[nBAT] or 0) + nAttr
			tFaBaoAttrList[#tFaBaoAttrList+1] = {nBAT = nBAT, nAttr = nAttr}
		end
		local nSuitCount = 0
		if oFaBao:GetStars() >= ctFaBaoConf[oFaBao:GetID()].nMaxCompResetStar then
			nSuitCount = self:GetSuitInfo(oFaBao:GetID())
			tMsg.tFaBaoInfoList[#tMsg.tFaBaoInfoList+1] = {nID = oFaBao:GetID(), nLevel = oFaBao:GetLevel(), 
			nStars = oFaBao:GetStars(),tAttrList = tFaBaoAttrList, nCostFeastStone = oFaBao:GetCostInfo() and oFaBao:GetCostInfo().nFaBaoFeastStone or 0,
			nCostYinBi =  oFaBao:GetCostInfo() and oFaBao:GetCostInfo().nFaBaoYinBi or 0, nType = oFaBao:GetType(), nSuitCount = nSuitCount or 0, nScore = oFaBao:GetScore(), bBind = oFaBao:GetBind(),
			 bWear = oFaBao:GetbWear()} 
		else
			tMsg.tFaBaoInfoList[#tMsg.tFaBaoInfoList+1] = {nID = oFaBao:GetID(), nLevel = oFaBao:GetLevel(), 
			nStars = oFaBao:GetStars(),tAttrList = tFaBaoAttrList, nCostFeastStone = oFaBao:GetCostInfo() and  oFaBao:GetCostInfo().nFaBaoFeastStone  or 0,
			nCostYinBi = oFaBao:GetCostInfo() and oFaBao:GetCostInfo().nFaBaoYinBi or 0, nType = oFaBao:GetType(), nScore = oFaBao:GetScore(), bBind = oFaBao:GetBind(), bWear = oFaBao:GetbWear()} 
		end	
	end

	--添加套装属性
	local tSuitAttr = self:GetSuitBattleAttr()
	for nAttrID,  nAttr in pairs(tSuitAttr) do
		tAttr[nAttrID] = (tAttr[nAttrID] or 0) + nAttr
	end

	--六个法宝属性
	for nBAT, nAttr in pairs(tAttr) do
		tMsg.tTotalAttrList[#tMsg.tTotalAttrList+1] = {nBAT = nBAT, nAttr = nAttr}
	end

	tMsg.nCurFeastStone = self.m_oRole:ItemCount(gtItemType.eProp,ctFaBaoCostConf[1].nFeastStoneID) or 0
	tMsg.nCurYinBi = self.m_oRole:GetYinBi()
	self.m_oRole:SendMsg("FaBaoAttrPageRet", tMsg)
	--print("法宝属性页面消息返回", tMsg)
end

function CFaBao:GetSuitInfo(nID)
	local nSuitIndex =ctFaBaoConf[nID].nSuitIndex
	if not nSuitIndex then return end
	return self.m_tFaBaoSuitAttr[nSuitIndex]
end

--同步法宝背包道具
function CFaBao:SyncKnapsackItems()
	local tMsg = {tFaBaoInfoList = {}}
	for nGrid, oFaBao in pairs(self.m_oFaBaoMap) do
		tMsg.tFaBaoInfoList[#tMsg.tFaBaoInfoList+1] = oFaBao:GetInfo()
	end
	self.m_oRole:SendMsg("FaBaoKnapsackItemListRet", tMsg)
end

--取法宝技能
function CFaBao:GetFaBaoSkill()
	local tFaBaoSkillMap = {}
	for _, oFaBao in pairs(self.m_oFaBaoWerMap) do
		tFaBaoSkillMap[oFaBao:GetID()] = {nLevel = oFaBao:GetLevel(), sName = oFaBao:GetName()}
	end
	return tFaBaoSkillMap
end

--获取法宝背包剩余容量
function CFaBao:GetOverNum()
	local nNum = 0
	for nTGrid = 1, nFaBaoMaxGrid, 1 do
		if self.m_oFaBaoMap[nTGrid] == nil then
			nNum = nNum + 1
		end
	end
	return nNum
end

function CFaBao:GetFaBao(nGrid)
	local oFaBao = self.m_oFaBaoMap[nGrid]
	if oFaBao then
		local tData = oFaBao:SaveData()
		return tData
	end
end

function CFaBao:GetFaBaoListData(nPropID)
	local tPropData = {}
	for _, oFaBao in pairs(self.m_oFaBaoMap) do
		if oFaBao:GetID() == nPropID then
			table.insert(tPropData, oFaBao:SaveData())
		end
	end
	return tPropData
end

function CFaBao:FaBaoFalgReq(bFlag, nGrid)
	local oFaBao = self.m_oFaBaoMap[nGrid]
	if not oFaBao then
		return self.m_oRole:Tips("法宝对象不存在")
	end
	oFaBao:SetbWear(bFlag)
	local tMsg = {}
	tMsg.bFlag = bFlag
	tMsg.nGrid = nGrid
	self.m_oRole:SendMsg("FaBaoFalgRet", tMsg)
end

function CFaBao:GetFaBaoCount(nID)
	local nNum = 0
	for _, oFaBao in pairs(self.m_oFaBaoMap) do
		if oFaBao:GetID() == nID then
			nNum = nNum + 1
		end
	end
end

function CFaBao:CheckSubFaBao(tItemList, sReason)
    assert(tItemList and sReason, "参数错误")
    if #tItemList == 0 then
        return true
    end

    local bEnough = true
    for _, tItem in pairs(tItemList) do
        if tItem.nNum <= 0 then 
            LuaTrace("物品数量错误")
            return false 
        end
     end

    for _, tItem in pairs(tItemList) do
        self:SubItemFaBao(tItem.nID, tItem.nNum, sReason)
    end
    return true
end

function CFaBao:SubItemFaBao(nID,  nNum, sReason)
	local nCount = 0
	for nGrid, oFaBao in pairs(self.m_oFaBaoMap) do
		if oFaBao:GetID() == nID then
			self:SubGridItem(nGrid, sReason)
			nCount = nCount + 1
			if nCount == nNum then
				break
			end
		end
	end
end

function CFaBao:GetSumFaBaoScore()
	local nScore = 0
	for _, oFaBao in pairs(self.m_oFaBaoWerMap) do
		nScore = nScore + oFaBao:GetScore()
	end
	return nScore
end