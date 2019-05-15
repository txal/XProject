--背包中与装备相关函数
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--启灵珠道具ID
local nQilingzhuPropID = 28000
--镇灵石道具ID
local nZhenlingshiPropID = 28001
--幸运石道具
local nLuckyStonePropID = 28002

gtEquipmentPartTypeMap = {}  --{nPartType:{}, ...}
gtEquipmentSchoolMap = {}    --{nSchool:{nTpartType:{}, ...}, ...} --性别和等级未处理
for k, nSchoolID in pairs(gtSchoolType) do 
	gtEquipmentSchoolMap[nSchoolID] = {}
end
for nEquipID, tConf in pairs(ctEquipmentConf) do 
	local nPartType = tConf.nEquipPartType
	if tConf.nEquipSchool == 0 then --全门派通用
		for nSchoolID, tSchool in pairs(gtEquipmentSchoolMap) do 
			local tPartTbl =  tSchool[nPartType] or {} 
			tPartTbl[nEquipID] = tConf
			tSchool[nPartType] = tPartTbl
		end
	else 
		local tSchool = gtEquipmentSchoolMap[tConf.nEquipSchool]
		local tPartTbl =  tSchool[nPartType] or {} 
		tPartTbl[nEquipID] = tConf
		tSchool[nPartType] = tPartTbl
	end

	local tPartTbl = gtEquipmentPartTypeMap[nPartType] or {}
	tPartTbl[nEquipID] = tConf
	gtEquipmentPartTypeMap[nPartType] = tPartTbl
end


--取角色武器攻击
function CKnapsack:GetWeaponAtk()
	local oEqu = self:GetWeapon()
	if not oEqu then return 0 end
	local tBaseProperty = oEqu:GetBaseProperty()[gtBAT.eGJ]
	if not tBaseProperty then return 0 end
	return tBaseProperty.nEffectValue
end

--获取当前装备的物品对象
function CKnapsack:GetWeapon()
	local oEqu = self.m_tWearEqu[gtEquPart.eWeapon]
	if not oEqu then return end
	oEqu:CheckFuMoExpire()
	return oEqu
end

function CKnapsack:GetWearEquData()
	local tData = {}
	local tEqusList = {}
	for nPartType, oEqu in pairs(self.m_tWearEqu) do
		table.insert(tEqusList, oEqu:GetDetailInfo())
	end
	tData.tEqusList = tEqusList
	tData.tGemTips = self.m_tEquGemTips
	return tData
end

--获取身上穿戴装备详细信息
function CKnapsack:WearEquListReq()
	self.m_oRole:SendMsg("KnapsacWearEquListRet", self:GetWearEquData())
end

--获取取穿戴装备
function CKnapsack:GetWearEqu(nPart)
	if nPart then
		local oEqu = self.m_tWearEqu[nPart]
		if oEqu then oEqu:CheckFuMoExpire() end
		return oEqu
	end
	local oEqu = self.m_tWearEqu[gtEquPart.eWeapon]
	if oEqu then oEqu:CheckFuMoExpire() end
	return self.m_tWearEqu
end

function CKnapsack:GetWearGemLevel()
	local iLevel = 0
	for nPart, oItem in pairs(self.m_tWearEqu) do
		iLevel = iLevel + oItem:GemLevel()
	end
	return iLevel
end

function CKnapsack:GetWearStrengthLevel()
	local iLevel = 0
	for nPart, oItem in pairs(self.m_tWearEqu) do
		iLevel = iLevel + oItem:GetStrengthenLevel()
	end
	return iLevel
end

--获取穿戴的装备评分
function CKnapsack:CalcWearEquScore()
	local nScore = 0
	for nPartType, oEqu in pairs(self.m_tWearEqu) do
		nScore = nScore + oEqu:GetScore()
	end
	return nScore
end

function CKnapsack:CalcEquTriggerScore()
	local nScore = 0
	local tAttrList = self.m_tStrengthenTriggerData.tTriggerAttr
	for nAttrID, nAttrVal in pairs(tAttrList) do 
		nScore = nScore + GF.CalcAttrScore(nAttrID, nAttrVal)
	end

	tAttrList = self.m_tGemTriggerData.tTriggerAttr
	for nAttrID, nAttrVal in pairs(tAttrList) do 
		nScore = nScore + GF.CalcAttrScore(nAttrID, nAttrVal)
	end
	return nScore
end

--交换装备宝石和强化等级  --内部不会更新角色属性
function CKnapsack:SwapEquGemAndStrength(oNewEqu, oOldEqu)
	if not oOldEqu or not oNewEqu then 
		return 
	end
	if oOldEqu:GetPartType() ~= oNewEqu:GetPartType() then --防止外层逻辑错误
		return 
	end
	local bGem = false 
	local bStrength = false
	for k, tGemData in pairs(oOldEqu.tGem) do 
		if tGemData and tGemData.nGemID > 0 and tGemData.nLv > 0 then 
			bGem = true 
			break
		end
	end
	if oOldEqu.tStrengthen.nLv > 0 then 
		bStrength = true
	end 

	if bStrength then 
		-- print(string.format("替换(%d)和(%d)的强化等级", oNewEqu:GetID(), oOldEqu:GetID()))
		local tTempStrength = oNewEqu.tStrengthen
		oNewEqu.tStrengthen = oOldEqu.tStrengthen
		oOldEqu.tStrengthen = tTempStrength
	end

	if bGem then 
		-- print(string.format("替换(%d)和(%d)的宝石", oNewEqu:GetID(), oOldEqu:GetID()))
		--需要注意，新装备上， 可能镶嵌等级比旧装备高，没法转移到旧装备
		--旧装备镶嵌等级转移到新装备，也存在此类问题
		local nOldLimitGemLevel = oOldEqu:GetGemLevelLimit()
		local nNewLimitGemLevel = oNewEqu:GetGemLevelLimit()
		local nOldMaxGemLevel = 0
		local nNewMaxGemLevel = 0
		for k, tGemData in pairs(oOldEqu.tGem) do 
			if tGemData.nLv > nOldMaxGemLevel then 
				nOldMaxGemLevel = tGemData.nLv
			end
		end
		for k, tGemData in pairs(oNewEqu.tGem) do 
			if tGemData.nLv > nNewMaxGemLevel then 
				nNewMaxGemLevel = tGemData.nLv
			end
		end
		if nOldMaxGemLevel > nNewLimitGemLevel then 
			self.m_oRole:Tips("新装备镶嵌等级较低，无法进行宝石转移")
		elseif nNewMaxGemLevel > nOldLimitGemLevel then 
			self.m_oRole:Tips("旧装备镶嵌等级较低，无法进行宝石转移")
		else
			local tTempGem = oNewEqu.tGem
			oNewEqu.tGem = oOldEqu.tGem
			oOldEqu.tGem = tTempGem
		end
	end

	oNewEqu:UpdateAttr()
	oOldEqu:UpdateAttr()
	self:MarkDirty(true)
	self:UpdateEquTriggerAttr(true)
end

function CKnapsack:SwapEquGemAndStrengthConfirm(oNewEqu, oOldEqu)
	if not oOldEqu or not oNewEqu then 
		return 
	end
	if oOldEqu:GetPartType() ~= oNewEqu:GetPartType() then 
		return 
	end

	local bGem = false 
	local bStrength = false
	for k, tGemData in pairs(oOldEqu.tGem) do 
		if tGemData and tGemData.nGemID > 0 and tGemData.nLv > 0 then 
			bGem = true 
			break
		end
	end
	if oOldEqu.tStrengthen.nLv > 0 then 
		bStrength = true
	end 
	if not bGem and not bStrength then 
		return 
	end

	local fnConfirmCallback = function(tData) 
		if not tData then 
			return 
		end
		if tData.nSelIdx == 1 then  --取消
			return
		elseif tData.nSelIdx == 2 then  --确定
			self:SwapEquGemAndStrength(oNewEqu, oOldEqu)
			self.m_oRole:UpdateAttr()
			self:UpdateGemTips(true)
			self:WearEquListReq()
			self:SyncKnapsackItems()

		end
	end

	local sContent = ""
	local sContentTemplate = "是否将换下来的装备%s转移到新穿戴的装备上"
	if bGem and bStrength then 
		sContent = string.format(sContentTemplate, "强化等级和镶嵌的宝石")
	elseif bGem then
		sContent = string.format(sContentTemplate, "镶嵌的宝石")
	elseif bStrength then 
		sContent = string.format(sContentTemplate, "强化等级")
	end
	local tMsg = {sCont=sContent, tOption={"取消", "确定"}, nTimeOut=30}
	goClientCall:CallWait("ConfirmRet", fnConfirmCallback, self.m_oRole, tMsg)
end

--拆卸装备所有宝石，背包满，自动邮寄
function CKnapsack:RemoveEquGemAll(oEqu)
	assert(oEqu, "参数错误")
	if not oEqu:IsEquipment() then
		return self.m_oRole:Tips("目标道具不是装备")
	end

	local bGem = false
	for k, tGemData in pairs(oEqu.tGem) do 
		bGem = true
		self.m_oRole:AddItem(gtItemType.eProp, tGemData.nGemID, tGemData.nNum, 
			"宝石取下", false, true)
	end
	if bGem then 
		oEqu.tGem = {}
		oEqu:UpdateAttr()
		self:MarkDirty(true)
	end
end

function CKnapsack:CheckWearPermit(nRoleConfID, nLevel, nEquID)
	local tRoleConf = ctRoleInitConf[nRoleConfID] 
	if not tRoleConf then 
		return false 
	end
	local tPropConf = ctPropConf[nEquID]
	if not tPropConf then 
		return false 
	end
	local tEquConf = ctEquipmentConf[nEquID] 
	if not tEquConf then 
		return false 
	end
	if tEquConf.nEquipLevel > nLevel then 
		return false 
	end
	if tEquConf.nEquipSchool > 0 
		and tEquConf.nEquipSchool ~= tRoleConf.nSchool then 
		return false 
	end
	if tEquConf.nEquipSexType > 0 
		and tEquConf.nEquipSexType ~= tRoleConf.nGender then 
		return false 
	end
	return true 
end

function CKnapsack:CheckCanWear(nEquID)
	assert(nEquID)
	local tPropConf = ctPropConf[nEquID]
	assert(tPropConf)
	if not ctEquipmentConf[nEquID] then 
		return false, "该道具不是装备"
	end
	local tEquConf = ctEquipmentConf[nEquID]
	if(self.m_oRole:GetLevel() < tEquConf.nEquipLevel) then
		return false, "未达到可穿戴等级，无法装备"
	end
	local nEquipSchool = tEquConf.nEquipSchool
	local nEquipSexType = tEquConf.nEquipSexType
	if nEquipSchool > 0 and self.m_oRole:GetSchool() ~= nEquipSchool then
		return false, "门派不符合，无法装备"
	end
	if nEquipSexType > 0 and self.m_oRole:GetGender() ~= nEquipSexType then
		return false, "性别不符合，无法装备"
	end
	return true
end

function CKnapsack:WearEqu(oEqu, bTips)
	assert(oEqu)
	local nGrid = oEqu:GetGrid()
	local bCanWear, sReason = self:CheckCanWear(oEqu:GetID())
	if not bCanWear then 
		if sReason then 
			self.m_oRole:Tips(sReason)
		end
		return 
	end

	local nEquipPartType = oEqu:GetConf().nEquipPartType
	local oOrignEqu = self.m_tWearEqu[nEquipPartType]

	self.m_tGridMap[nGrid] = nil
	self:OnItemRemoved(nGrid, 1)

	if oOrignEqu then
		oOrignEqu:SetGrid(nGrid)
		self.m_tGridMap[nGrid] = oOrignEqu
		self:OnItemAdded(nGrid, 1, false)
		self.m_oRole:SendMsg("KnapsacTakeOffEquRet", {nEquipPartType=nEquipPartType, nID=oOrignEqu:GetID()})
	end

	oEqu:SetGrid(0)
	oEqu:SetBind(true)
	self.m_tWearEqu[nEquipPartType] = oEqu
	self:MarkDirty(true)
	if bTips then 
		self.m_oRole:Tips(string.format("成功穿戴%s", oEqu:GetFormattedName())) 
	end
	if nEquipPartType == gtEquPart.eWeapon then
		self.m_oRole:FlushRoleView()
	end
	self.m_oRole:SendMsg("KnapsacWearEquRet", {nGrid=nGrid})
	self:UpdateEquTriggerAttr(true)

	local tData = {tLevelMap={}}
	for _, oEqu in pairs(self.m_tWearEqu) do
		tData.tLevelMap[oEqu.m_nLevel] = (tData.tLevelMap[oEqu.m_nLevel] or 0) + 1
	end
	CEventHandler:OnEquipEquipment(self.m_oRole, tData)
	return true
end

--穿装备
--格子数
function CKnapsack:WearEquReq(nGrid)
	local oEqu = self.m_tGridMap[nGrid]
	if not oEqu then 
		self.m_oRole:Tips("装备不存在")
		return 
	end

	local nEquipPartType = oEqu:GetConf().nEquipPartType
	local oOrignEqu = self.m_tWearEqu[nEquipPartType]
	if self:WearEqu(oEqu, true) then 
		self.m_oRole:UpdateAttr()
		self:SwapEquGemAndStrengthConfirm(oEqu, oOrignEqu)
	end

	if self.m_oRole:IsInBattle() then
		return self.m_oRole:Tips("装备属性将在战斗后生效")
	end
	self:UpdateGemTips(true)
	self.m_oRole:UpdateActGTEquStrength()
	self.m_oRole:UpdateActGTEquGemLv()
end

function CKnapsack:QuickWearEqu(nEquLevelLimit)
	local oRole = self.m_oRole

	local tWearEquList = {}  --{PartType:{oItem = oItem, nBaseScore = nBaseScore}}
	for k, v in pairs(gtEquPart) do 
		local oWearEqu = self:GetPropByBox(gtPropBoxType.eEquipment, v)
		if oWearEqu then 
			local nAttrScore = oWearEqu:GetBaseAttrScore()
			tWearEquList[v] = {oItem = oWearEqu, nBaseScore = nAttrScore}
		end
	end

	local tPartEquList = {}  --{PartType:{oItem = oItem, nBaseScore = nBaseScore}}
	for k, oItem in pairs(self.m_tGridMap) do 
		-- 判断下来源途径，只自动穿戴非制作的，防止意外情况，将玩家制作摆摊销售的装备穿戴绑定
		if oItem:IsEquipment() and oItem:GetLevel() < nEquLevelLimit 
			and oItem:GetSource() == gtEquSourceType.eShop then 
			local bCanWear = self:CheckCanWear(oItem:GetID())
			if bCanWear then
				local nPartType = oItem:GetPartType()
				local tOldData = tPartEquList[nPartType]
				local nAttrScore = oItem:GetBaseAttrScore()
				if not tOldData then 
					local tWearData = tWearEquList[nPartType]
					if not tWearData or tWearData.nBaseScore < nAttrScore then 
						tPartEquList[nPartType] = {oItem = oItem, nBaseScore = nAttrScore}
					end
				else
					if tOldData.nBaseScore < nAttrScore then 
						tPartEquList[nPartType] = {oItem = oItem, nBaseScore = nAttrScore}
					end
				end
			end
		end
	end

	if not next(tPartEquList) then 
		return 
	end

	local tAutoSaleList = {}
	for k, tItemData in pairs(tPartEquList) do 
		local oEqu = tItemData.oItem
		local nEquipPartType = oEqu:GetConf().nEquipPartType
		local oOrignEqu = self.m_tWearEqu[nEquipPartType]
		if self:WearEqu(oEqu) then 
			self:SwapEquGemAndStrength(oEqu, oOrignEqu)
			if oOrignEqu and oOrignEqu:CheckSale()
				and oOrignEqu:GetQualityLevel() < gtQualityColor.ePurple then 
				table.insert(tAutoSaleList, oOrignEqu)
			end
		end
	end
	oRole:Tips("一键穿戴成功")

	local nTotalSilverCoin = 0
	for k, oSaleEqu in pairs(tAutoSaleList) do 
		local nSaleSilverCoin = oSaleEqu:GetPropConf().nSellCopperPrice
		if nSaleSilverCoin > 0 then 
			if self:SubGridItem(oSaleEqu:GetGrid(), oSaleEqu:GetID(), 1, "快捷穿戴自动出售") then 
				nTotalSilverCoin = nTotalSilverCoin + nSaleSilverCoin
			end
		end
	end
	if nTotalSilverCoin > 0 then 
		self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nTotalSilverCoin, "快捷穿戴自动出售")
		self.m_oRole:Tips(string.format("换下的旧装备自动出售，获得了%d银币", nTotalSilverCoin))
	end
	self.m_oRole:UpdateAttr()
	self:UpdateGemTips(true)
	self:WearEquListReq()
end

--一键穿戴请求
function CKnapsack:QuickWearEquReq()
	local oRole = self.m_oRole
	local nLevelLimit = 60
	local nRoleLevel = oRole:GetLevel()
	if nRoleLevel >= nLevelLimit then
		return 
	end
	self:QuickWearEqu(nLevelLimit)
	self.m_oRole:UpdateActGTEquStrength()
end

--脱装备TakeOffEquReq
--装备部位
function CKnapsack:TakeOffEquReq(nEquipPartType)
	local oEqu = self.m_tWearEqu[nEquipPartType]
	-- assert(oEqu,"oEqu is nil")
	if not oEqu then --网络抖动会导致很多错误提示信息
		return 
	end
	local nGrid = self:GetEmptyGrid()
	if nGrid == -1 then
		return self.m_oRole:Tips("背包已满，脱装备失败")
	end
	oEqu:SetGrid(nGrid)
	self.m_tGridMap[nGrid] = oEqu
	self.m_tWearEqu[nEquipPartType] = nil
	self:MarkDirty(true)
	self:OnItemAdded(nGrid, 1, false)
	self.m_oRole:SendMsg("KnapsacTakeOffEquRet", {nEquipPartType=nEquipPartType, nID=oEqu:GetID()})
	if nEquipPartType == gtEquPart.eWeapon then
		self.m_oRole:FlushRoleView()
	end

	self:UpdateEquTriggerAttr(true)
	self.m_oRole:UpdateAttr()

	if self.m_oRole:IsInBattle() then
		return self.m_oRole:Tips("装备属性将在战斗后生效")
	end
	self:UpdateGemTips(true)
	self.m_oRole:UpdateActGTEquStrength()
	self.m_oRole:UpdateActGTEquGemLv()
end

--取身上装备主属性
function CKnapsack:GetEquMainAttr()
	local tMainAttr = {}
	for nPartType in pairs(self.m_tWearEqu) do
		local oEqu = self.m_tWearEqu[nPartType]
		if oEqu and oEqu:GetDurable() > 0 then
			--装备附加属性
			for k, v in pairs(oEqu.tAddProperty) do
				if k > 0 and k < 101 then  --旧的兼容下
					tMainAttr[k] = (tMainAttr[k] or 0) + v.nEffectValue
				end
			end
		end
	end
	return tMainAttr
end

--取身上装备战斗属性
function CKnapsack:GetEquBattleAttr()
	local tBattleAttr = {}
	for nPartType in pairs(self.m_tWearEqu) do
		local oEqu = self.m_tWearEqu[nPartType]
		if oEqu and oEqu:GetDurable() > 0 then
			--装备基础属性
			for k, v in pairs(oEqu.tBaseProperty) do
				tBattleAttr[k] = (tBattleAttr[k] or 0) + v.nEffectValue
			end
			--装备附加属性
			for k, v in pairs(oEqu.tAddProperty) do
				if k > 100 then --兼容下旧属性
					tBattleAttr[k] = (tBattleAttr[k] or 0) + v.nEffectValue
				end
			end
			--宝石属性
			for _, tGemData in pairs(oEqu.tGem) do 
				for k, v in pairs(tGemData.tAttrList) do 
					tBattleAttr[v.nAttrID] = (tBattleAttr[v.nAttrID] or 0) + v.nAttrVal
				end
			end
		end
	end
	--附魔属性
	local oWeapon = self:GetWeapon()
	if oWeapon then
		local tFuMoAttrMap = oWeapon:GetFuMoAttrMap(true) --防止触发循环调用
		for nAttrID, tAttr in pairs(tFuMoAttrMap) do
			tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) + tAttr[1]
		end
	end
	--共鸣属性
	for nAttrID, nAttrVal in pairs(self.m_tStrengthenTriggerData.tTriggerAttr) do 
		tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) + nAttrVal
	end
	for nAttrID, nAttrVal in pairs(self.m_tGemTriggerData.tTriggerAttr) do 
		tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) + nAttrVal
	end

	return tBattleAttr
end

--执行修复
function CKnapsack:DoFixEqu(oEqu)
	local nOldDurable = oEqu:GetDurable()
	--加满耐久
	oEqu:FixDurable()
	self:MarkDirty(true)
	--返回
	self.m_oRole:SendMsg("KnapsacFixEquRet", {nID=oEqu:GetID(), nDurable=oEqu:GetMaxDurable()})

	--身上装备,并且旧耐久是0,则更新角色属性
	if oEqu:IsWearing() and nOldDurable == 0 and nOldDurable ~= oEqu:GetDurable() then
		self.m_oRole:UpdateAttr()
	end
	return true
end

--装备维修请求
function CKnapsack:FixEquReq()
	local tEquList = {}
	local nTotalPrice = 0 
	local nLessDurableEqu = 0

	--背包
	-- for nGrid, oProp in pairs(self.m_tGridMap) do
	-- 	if oProp:IsEquipment() and oProp:GetDurable() < oProp:GetMaxDurable() then
	-- 		nTotalPrice = nTotalPrice + oProp:GetFixPrice()
	-- 		table.insert(tEquList, oProp)
	-- 		if oProp:GetDurable() <= 50 then
	-- 			nLessDurableEqu = nLessDurableEqu + 1
	-- 		end
	-- 	end
	-- end

	--身上
	if not next(self.m_tWearEqu) then
		return self.m_oRole:Tips("请先穿上装备")
	end
	for _, oEqu in pairs(self.m_tWearEqu) do
		if oEqu:GetDurable() < oEqu:GetMaxDurable() then
			nTotalPrice = nTotalPrice + oEqu:GetFixPrice()
			table.insert(tEquList, oEqu)
			if oEqu:GetDurable() <= 50 then
				nLessDurableEqu = nLessDurableEqu + 1
			end
		end
	end
	if #tEquList <= 0 then
		return self.m_oRole:Tips("所有装备完好无损，无需修理")
	end

--[[ 	local sCont = string.format("您要消耗%d银币修理全部装备吗？", nTotalPrice)
	local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=30}
	goClientCall:CallWait("ConfirmRet", function(tData)
		if tData.nSelIdx == 1 then return end

		if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eYinBi, nTotalPrice, "所有装备修理扣除") then
			return self.m_oRole:YinBiTips()
		end
		
		for _, oEqu in pairs(tEquList) do
			self:DoFixEqu(oEqu)
		end

	end, self.m_oRole, tMsg) ]]
	if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eYinBi, nTotalPrice, "所有装备修理扣除") then
		return self.m_oRole:YinBiTips()
	end
	
	for _, oEqu in pairs(tEquList) do
		self:DoFixEqu(oEqu)
	end
	self.m_oRole:Tips("所有装备维修成功")
end

--装备单个维修请求
--格子id
function CKnapsack:FixSingleEquReq(nGrid, nPartType)
	local oEqu = self.m_tGridMap[nGrid] or self.m_tWearEqu[nPartType]
	if not oEqu then
		return
	end

	--判定是否是装备类型
	if not oEqu:IsEquipment() then
		return
	end

	--判定耐久是否满
	if oEqu:GetDurable() >= oEqu:GetMaxDurable() then
		return self.m_oRole:Tips("装备耐久度已满，无需修复")
	end

	--单个修复
	local nPrice = oEqu:GetFixPrice()
	local sCont = string.format("是否花费%d银币修复%s的耐久度", nPrice, oEqu:GetName())
	local tMsg = {sCont=sCont, tOption={"取消", "修复耐久度"}, nTimeOut=30}
	goClientCall:CallWait("ConfirmRet", function(tData)
		if tData.nSelIdx == 1 then return end

		if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eYinBi, nPrice, "单装备修理扣除") then
			return self.m_oRole:YinBiTips()
		end
		self:DoFixEqu(oEqu)
		self.m_oRole:Tips("维修装备成功")

	end, self.m_oRole, tMsg)
end


--获取空闲格子id
function CKnapsack:GetEmptyGrid()
	for k = 1, self.m_nGridNum do
		if not self.m_tGridMap[k] then
			return k
		end
	end
	return -1
end

--制造装备请求
--制造装备id
--bMoneyAdd是否用元宝补齐材料
function CKnapsack:MakeEquReq(nID, bMoneyAdd)
	if not self.m_oRole:IsSysOpen(62, true) then 
		-- self.m_oRole:Tips("功能未开启")
		return 
	end
	local tMakeEqu = ctEquipmentMakeConf[nID]
	assert(tMakeEqu, "config is nil")
	local nServerLevel = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	if tMakeEqu.nLv > nServerLevel+5 then
		return self.m_oRole:Tips("服务器等级不足")
	end
	if tMakeEqu.nSchool > 0 and self.m_oRole:GetSchool() ~= tMakeEqu.nSchool then
		return self.m_oRole:Tips("门派不同")
	end
	if tMakeEqu.nGender > 0 and self.m_oRole:GetGender() ~= tMakeEqu.nGender then
		return self.m_oRole:Tips("性别不同")
	end
	local nRoleLevel = self.m_oRole:GetLevel()
	local nMakeLimitLevel = math.max(30, (math.floor(nRoleLevel / 10) + 1) * 10)
	if tMakeEqu.nLv > nMakeLimitLevel then
		return self.m_oRole:Tips("角色等级不足")
	end

	local tCostList = {}
	for _, tMaterial in ipairs(tMakeEqu.tSmithMaterialsStr) do 
		if tMaterial[1] > 0 and tMaterial[2] > 0 then 
			table.insert(tCostList, {gtItemType.eProp, tMaterial[1], tMaterial[2]})
		end
	end
	assert(#tCostList > 0, string.format("装备打造ID(%d)材料配置不正确", nID))

	--判断有无空位
	local nGrid = self:GetEmptyGrid()
	if(nGrid == -1) then
		return self.m_oRole:Tips("背包已满")
	end

	--扣除货币
	local nPrice = 500 * tMakeEqu.nLv
	assert(nPrice > 0, "打造装备银币消耗数量错误")
	table.insert(tCostList, {gtItemType.eCurr, gtCurrType.eYinBi, nPrice})

	local fnSubCallback = function(bSucc, nYuanbao)
		if not bSucc then 
			return 
		end
		local tPropExt = {nSource=gtEquSourceType.eManu, sProducer = self.m_oRole:GetName()}
		self.m_oRole:AddItem(gtItemType.eProp, nID, 1, "装备打造", nil, false, tPropExt)
		self:MarkDirty(true)
	end
	self.m_oRole:SubItemByYuanbao(tCostList, "装备打造", fnSubCallback, not bMoneyAdd)
end

function CKnapsack:CheckProp(nID, nNum)
	return self:ItemCount(nID) >= nNum
end

--检查装备空的宝石格子
function CKnapsack:CheckEquEmptyGemPos(oEqu)
	if not oEqu then 
		return false 
	end
	local nRoleLevel = self.m_oRole:GetLevel()
	if not oEqu.tGem[1] then 
		return true 
	end
	if not oEqu.tGem[2] and nRoleLevel >= 60 then 
		return true 
	end
	if not oEqu.tGem[3] and nRoleLevel >= 80 then 
		return true 
	end
	return false
end

function CKnapsack:GetEquValidGemID(nEquID)
	assert(nEquID > 0)
	local tPropConf = ctPropConf[nEquID]
	assert(tPropConf)

	local tEquConf = ctEquipmentConf[nEquID]
	assert(tEquConf)
	local nPartType = tEquConf.nEquipPartType
	local tGemTbl = {}
	for k, tGemConf in pairs(ctGemConf) do 
		for _, tTemp in ipairs(tGemConf.tPartType) do 
			if tTemp[1] == nPartType then 
				table.insert(tGemTbl, tGemConf.nID)
				break
			end
		end
	end
	return tGemTbl
end

function CKnapsack:UpdateGemTips(bSync)
	--获得宝石道具，需要触发更新
	--装备更换，需要触发更新
	--角色等级变化，需要触发更新

	local tBagGemRecord = nil
	local nRoleLevel = self.m_oRole:GetLevel()
	local bOldTips = self.m_tEquGemTips.bTips
	self.m_tEquGemTips.bTips = false
	self.m_tEquGemTips.tPos = {}

	for nPartType, oEqu in pairs(self.m_tWearEqu) do 
		if self:CheckEquEmptyGemPos(oEqu) then 
			if not tBagGemRecord then --统计背包中存在的宝石
				tBagGemRecord = {} 
				for _, oTempItem in pairs(self.m_tGridMap) do 
					local nItemID = oTempItem:GetID()
					if ctGemConf[nItemID] then 
						tBagGemRecord[nItemID] = (tBagGemRecord[nItemID] or 0) + oTempItem:GetNum()
					end
				end
			end

			local tValidGemTbl = self:GetEquValidGemID(oEqu:GetID())
			for k, nGemID in pairs(tValidGemTbl) do 
				if tBagGemRecord[nGemID] then
					self.m_tEquGemTips.bTips = true
					table.insert(self.m_tEquGemTips.tPos, nPartType)
					break
				end
			end
		end
	end

	if bOldTips ~= self.m_tEquGemTips.bTips and bSync then 
		self:SyncGemTips()
	end
end

function CKnapsack:SyncGemTips()
	self.m_oRole:SendMsg("KnapsackGemTipsRet", self.m_tEquGemTips)
	print(">>>>>>>> 通知装备宝石镶嵌小红点 <<<<<<<<<")
	-- self.m_oRole:Tips("宝石镶嵌小红点变化")
end

--宝石镶嵌请求
--位置id[1-3],装备部位,宝石id
--bMoneyAdd是否用元宝补齐材料
function CKnapsack:GemReq(nBoxType, nBoxParam, nPosID, nGemID, bMoneyAdd)
	if not self.m_oRole:IsSysOpen(63, true) then 
		-- self.m_oRole:Tips("功能未开启")
		return 
	end
	if not nBoxType or not nBoxParam or not nPosID or not nGemID then
		print("宝石镶嵌参数错误")
		return
	end
	local oEqu = self:GetPropByBox(nBoxType, nBoxParam)
	if not oEqu then
		return self.m_oRole:Tips("道具不存在")
	end
	if not oEqu:IsEquipment() then
		return self.m_oRole:Tips("目标道具不是装备")
	end
 
	if nPosID <= 0 or nPosID > 3 then  --恶意客户端
		self.m_oRole:Tips("宝石镶嵌位置不合法")
		local sPrintContent = string.format("宝石镶嵌位置不合法，角色ID <%d>, nPosID <%d>, nGemID <%d>",
			self.m_oRole:GetID(), nPosID, nGemID)
		print(sPrintContent)
		return
	end

	local nMaxLevel = math.floor(oEqu:GetLevel()/10 + 2)
	local tGemData = oEqu.tGem[nPosID]
	local nLv = 1   --目标等级
	if tGemData then 
		if tGemData.nLv >= nMaxLevel then 
			return self.m_oRole:Tips("已达最大镶嵌等级")
		end
		nLv = math.max(tGemData.nLv + 1, 1)
		if nGemID ~= tGemData.nGemID then 
			return self.m_oRole:Tips("只能镶嵌同种类宝石")
			-- nGemID = tGemData.nGemID
		end
	end

	if not ctGemConf[nGemID] then
		self.m_oRole:Tips("宝石ID非法")
		return
	end
	if nPosID == 2 and self.m_oRole:GetLevel() < 60 then
		return self.m_oRole:Tips("60级开放")
	end
	if nPosID == 3 and self.m_oRole:GetLevel() < 80 then
		return self.m_oRole:Tips("80级开放")
	end

	local nPartType = oEqu:GetPartType()
	local bPartLimit = true
	local tGemConf = ctGemConf[nGemID]
	for _, tPartType in ipairs(tGemConf.tPartType) do
		if tPartType[1] == nPartType then
			bPartLimit = false
			break
		end
	end

	if bPartLimit then
		local sTipsContent = string.format("%s只能镶嵌在", ctPropConf[nGemID].sName)
		for k, v in ipairs(tGemConf.tPartType) do
			if k ~= 1 then
				sTipsContent = sTipsContent.."、"
			end
			sTipsContent = sTipsContent..gtEquPartName[v[1]]
		end
		sTipsContent = sTipsContent.."上"
		return self.m_oRole:Tips(sTipsContent)
	end

	local nLimitLevel = oEqu:GetGemLevelLimit()
	local tGemData = oEqu.tGem[nPosID]
	local nLv = 1   --目标等级
	if tGemData then 
		if tGemData.nLv >= nLimitLevel then 
			return self.m_oRole:Tips("已达最大镶嵌等级")
		end
		nLv = math.max(tGemData.nLv + 1, 1)
	end


	local nNum = 2^(nLv - 1)

	local tCostList = {{gtItemType.eProp, nGemID, nNum}, }

	local fnSubCallback = function(bSuccess, nYuanBao)
		if not bSuccess then 
			return 
		end

		if nYuanBao > 0 then
			self.m_oRole:Tips(string.format("花费%d元宝，镶嵌成功", nYuanBao))
		else
			self.m_oRole:Tips("镶嵌成功")
		end
		-- self.m_oRole:SubItem(gtItemType.eProp, nGemID, nCostNum, "装备镶嵌")
		if tGemData then 
			tGemData.nLv = nLv
			tGemData.nNum = tGemData.nNum + nNum
		else
			oEqu.tGem[nPosID] = {nGemID=nGemID, nNum=nNum, nLv = nLv, tAttrList = {}}
		end
		oEqu:UpdateAttr()  --UpdateAttr中计算宝石附带属性
		self:MarkDirty(true)
		self:UpdateEquTriggerAttr(true)
		self.m_oRole:UpdateAttr()
		local iLevel = self:GetWearGemLevel()
		self.m_oRole:PushAchieve("宝石镶嵌总等级",{nValue = iLevel})
		self:UpdateGemTips(true)
		self:SendPropDetailInfo(oEqu, nBoxType, nBoxParam) 
		--统计各等级宝石数量保存在目标任务数据中
		local tData = {}
		tData.tLevelMap = self:GetEachEquGemCount()
		CEventHandler:OnGem(self.m_oRole, tData)

		local tMsg = {}
		tMsg.nBoxType = nBoxType
		tMsg.nBoxParam = nBoxParam
		tMsg.nPosID = nPosID
		tMsg.tEquData = oEqu:GetDetailInfo()
		self.m_oRole:SendMsg("KnapsacGemRet", tMsg)
		self.m_oRole:UpdateActGTEquGemLv()
	end

	self.m_oRole:SubItemByYuanbao(tCostList, "装备镶嵌", fnSubCallback, not bMoneyAdd)
end

--宝石取下请求
--位置id[1-3]装备部位
function CKnapsack:RemoveGemReq(nBoxType, nBoxParam, nPosID)
	local oEqu = self:GetPropByBox(nBoxType, nBoxParam)
	if not oEqu then
		return self.m_oRole:Tips("道具不存在")
	end
	if not oEqu:IsEquipment() then
		return self.m_oRole:Tips("目标道具不是装备")
	end
	if nPosID <= 0 or nPosID > 3 then
		return self.m_oRole:Tips("宝石孔不合法")
	end
	if not oEqu.tGem[nPosID] then
		return self.m_oRole:Tips("该位置没有镶嵌宝石")
	end
	local tConf = oEqu.tGem[nPosID]
	self.m_oRole:AddItem(gtItemType.eProp, tConf.nGemID, tConf.nNum, "宝石取下", false, true)

	oEqu.tGem[nPosID] = nil
	oEqu:UpdateAttr()
	self:MarkDirty(true)
	self:UpdateEquTriggerAttr(true)
	self.m_oRole:UpdateAttr()
	local iLevel = self:GetWearGemLevel()
	self.m_oRole:PushAchieve("宝石镶嵌总等级",{nValue = iLevel})
	self:UpdateGemTips(true) 
	self:SendPropDetailInfo(oEqu, nBoxType, nBoxParam) 
	local tData = {}
	tData.tLevelMap = self:GetEachEquGemCount()
	CEventHandler:OnGem(self.m_oRole, tData)
	self.m_oRole:UpdateActGTEquGemLv()

	local tMsg = {}
	tMsg.nBoxType = nBoxType
	tMsg.nBoxParam = nBoxParam
	tMsg.nPosID = nPosID
	tMsg.tEquData = oEqu:GetDetailInfo()
	self.m_oRole:SendMsg("knapsacRemoveGemRet", tMsg)
end

function CKnapsack:OnEquStrengthenLevelUp(oEqu, bStorageMode, nOldLevel, nNewLevel)
	assert(nOldLevel >= 0 and nNewLevel > 0 and nNewLevel > nOldLevel, "参数错误")
	bStorageMode = bStorageMode and true or false 
	self.m_oRole:PushAchieve("装备强化总等级",{nValue = nNewLevel - nOldLevel})

	for k = nOldLevel + 1, nNewLevel do 
		local tData = {}
		tData.bIsHearsay = true
		tData.nEquID = oEqu:GetID()
		tData.nStrenghtenLevel = k
		CEventHandler:OnEquStrenghten(self.m_oRole, tData)
	end

	self:UpdateEquTriggerAttr(true)
end

--装备强化
--强化石 -> 启灵珠
--定灵玉 -> 镇灵石
--幸运符 -> 幸运石
--积累模式下，可以选择指定数量的启灵珠、镇灵石或者幸运石进行补足(如果当前存在该道具，则不可补足)，每次三选一
--冒险模式下，必须需要最够数量的启灵珠(数量由配置指定，玩家不可选)，元宝补足会默认补足启灵珠
--冒险模式下，可以选择是否使用镇灵石和幸运石(在选择使用的情况下，如果开启了元宝补足，如果补足，则会使用元宝不足，幸运石不足数量，由玩家指定)
function CKnapsack:StrengthenEquipment(nBoxType, nBoxParam, bStorageMode, nQilingzhu, nZhenlingshi, nLuckyStone, bMoneyAdd)
	print("CKnapsack:StrengthenEquipment***", nBoxType, nBoxParam, bStorageMode, nQilingzhu, nZhenlingshi, nLuckyStone, bMoneyAdd)
	nQilingzhu = math.max(nQilingzhu or 0, 0)
	nZhenlingshi = math.max(nZhenlingshi or 0, 0)
	nLuckyStone = math.max(nLuckyStone or 0, 0)

	local oEqu = self:GetPropByBox(nBoxType, nBoxParam)
	if not oEqu then
		return self.m_oRole:Tips("道具不存在")
	end
	if not oEqu:IsEquipment() then
		return self.m_oRole:Tips("目标道具不是装备")
	end

	local tStrengthen = oEqu.tStrengthen
	if tStrengthen==nil then tStrengthen = {nLv=0,nScore=0} end
	if tStrengthen.nLv >= gnEquipmentMaxStrengthenLv then
		self.m_oRole:Tips("当前已达最高强化等级")
		return
	end
	local tEquStrengthenConf = ctEquipmentStrengthenConf[tStrengthen.nLv]
	assert(tEquStrengthenConf,"tEquStrengthenConf is nil")

	local nRoleLevel = self.m_oRole:GetLevel()
	if nRoleLevel < tEquStrengthenConf.nGrade then
		return self.m_oRole:Tips(string.format("强化等级达到当前上限，%d级开启下一阶段", tEquStrengthenConf.nGrade))
	end

	--只有冒险模式，道具使用增加强化等级限制
	if not bStorageMode then 
		if nZhenlingshi > 0 and tStrengthen.nLv < 4 then
			return self.m_oRole:Tips(string.format("强化达到4级才能使用%s", ctPropConf[nZhenlingshiPropID].sName))
		end
		if nLuckyStone > 0 and tStrengthen.nLv < 11 then
			return self.m_oRole:Tips(string.format("强化达到11级才能使用%s", ctPropConf[nLuckyStonePropID].sName))
		end
	end

	if bStorageMode then
		if not (nQilingzhu > 0 or nZhenlingshi > 0 or nLuckyStone > 0) then
			self.m_oRole:Tips("请选择一个强化道具")
		end
	else  --冒险模式，自动调整启灵珠和镇灵石数量
		nQilingzhu = tEquStrengthenConf.nQHS --忽略客户端的参数
		if nZhenlingshi > 0 then --如果使用了镇灵石，忽略客户端参数具体数量，直接使用配置的保底数量
			nZhenlingshi = tEquStrengthenConf.nDYL
		end
		if nLuckyStone > 0 then
			--计算100%成率情况下，需要的幸运石最大数量，如果超过，自动降低
			assert(tEquStrengthenConf.nRate > 0, "装备强化幸运石概率数值配置错误, ID:"..tEquStrengthenConf.nID)
			local nMaxLuckStone = math.ceil((100 - tEquStrengthenConf.nBaseRate) / tEquStrengthenConf.nRate)
			nLuckyStone = math.min(nLuckyStone, nMaxLuckStone)
		end
	end	

	local tItemList = {}
	--银币
	if not bStorageMode then  --只有冒险模式会消耗银币
		local nSilverCoinCost = tEquStrengthenConf.eSilver(oEqu:GetLevel())
		if nSilverCoinCost > 0 then
			table.insert(tItemList, {gtItemType.eCurr, gtCurrType.eYinBi, nSilverCoinCost})
		end
	end

	local nMaxLimitLevel = 0
	for k = 0, gnEquipmentMaxStrengthenLv - 1 do --默认依次递增，不考虑配置异常情况
		local tStrengthenConf = ctEquipmentStrengthenConf[k]
		if nRoleLevel >= tStrengthenConf.nGrade then 
			nMaxLimitLevel = k + 1
		else
			break 
		end
	end
	assert(tStrengthen.nLv < nMaxLimitLevel)

	--积累模式下，每次只消耗一种
	if bStorageMode then
		--计算强化到最高级，需要的积分
		local nMaxAddScore = 0
		for i = tStrengthen.nLv, nMaxLimitLevel - 1 do 
			nMaxAddScore = nMaxAddScore + ctEquipmentStrengthenConf[i].nScore
		end
		nMaxAddScore = nMaxAddScore - tStrengthen.nScore
		assert(nMaxAddScore, "策划请注意，配置表强化需求积分数值可能更改不正确") --调小数值也会出现

		if nQilingzhu > 0 then
			nZhenlingshi = 0
			nLuckyStone = 0
			--如果当前使用的道具超过升到最高级需要的积分，则修正道具数量
			assert(tEquStrengthenConf.nScore1 > 0, "配置错误")
			nQilingzhu = math.min(math.ceil(nMaxAddScore/tEquStrengthenConf.nScore1), nQilingzhu) 
		elseif nZhenlingshi > 0 then
			nLuckyStone = 0
			assert(tEquStrengthenConf.nScore2 > 0, "配置错误")
			nZhenlingshi = math.min(math.ceil(nMaxAddScore/tEquStrengthenConf.nScore2), nZhenlingshi) 
		else
			assert(tEquStrengthenConf.nScore3 > 0, "配置错误")
			nLuckyStone = math.min(math.ceil(nMaxAddScore/tEquStrengthenConf.nScore3), nLuckyStone)
		end
	end

	local tCostList = {}
	if nQilingzhu > 0 then
		table.insert(tCostList, {gtItemType.eProp, nQilingzhuPropID, nQilingzhu})
	end
	if nZhenlingshi > 0 then
		table.insert(tCostList, {gtItemType.eProp, nZhenlingshiPropID, nZhenlingshi})
	end
	if nLuckyStone > 0 then
		table.insert(tCostList, {gtItemType.eProp, nLuckyStonePropID, nLuckyStone})
	end

	local fnSubCallback = function(bSubSucc)
		if not bSubSucc then 
			return 
		end
		local bSuccess = false
		local nLv = tStrengthen.nLv 
		local nOldLv = nLv
		local nScore = 0
		if bStorageMode then
			nScore = nQilingzhu * tEquStrengthenConf.nScore1 
				+ nZhenlingshi * tEquStrengthenConf.nScore2 
				+ nLuckyStone * tEquStrengthenConf.nScore3

			nScore = nScore + tStrengthen.nScore
			local nNextLevelScore = tEquStrengthenConf.nScore
			while nScore >= nNextLevelScore do
				nLv = nLv + 1
				nScore = nScore - nNextLevelScore 
				if nLv >= gnEquipmentMaxStrengthenLv then 
					break
				end
				nNextLevelScore = ctEquipmentStrengthenConf[nLv].nScore
			end
			bSuccess = true
		else
			local nRandom = math.random(100)
			local nRate = tEquStrengthenConf.nBaseRate + nLuckyStone * tEquStrengthenConf.nRate
			if nRandom <= nRate then
				nLv = tStrengthen.nLv + 1 
				bSuccess = true
			elseif nZhenlingshi < tEquStrengthenConf.nDYL then --没有使用镇灵石
				nLv = tStrengthen.nLv - 1
			end
			nScore = 0  --不论是否强化成功，只要使用冒险模式进行强化，积分都会清空
		end
		oEqu:SetBind(true)  --强化操作触发绑定
		tStrengthen = {nLv=nLv,nScore=nScore}
		oEqu.tStrengthen = tStrengthen
		self:MarkDirty(true)
		--重新计算结果属性
		oEqu:UpdateAttr()
		--正在穿戴就更新角色属性
		if oEqu:IsWearing() then
			self.m_oRole:UpdateAttr()
		end

		local tRetData = {}
		tRetData.bSuccess = bSuccess
		local tDetail = {}
		tDetail.nType = oEqu:GetType()
		tDetail.nBoxType = nBoxType
		tDetail.nBoxParam = nBoxParam
		if oEqu:GetType() == gtPropType.eEquipment then
			tDetail.tEqu = oEqu:GetDetailInfo()
		end
		tRetData.tEqu = tDetail
		self.m_oRole:SendMsg("KnapsacStrengthenEquRet", tRetData)
		self:SyncKnapsackItems()
		if nLv > nOldLv then --放在最后，防止回调错误，干扰正常逻辑
			self:OnEquStrengthenLevelUp(oEqu, bStorageMode, nOldLv, nLv)
		end
		self.m_oRole:UpdateActGTEquStrength()
	end

	self.m_oRole:SubItemByYuanbao(tCostList, "装备强化", fnSubCallback, not bMoneyAdd)
end

function CKnapsack:StrengthenEquReq(nBoxType, nBoxParam, bStorageMode, nQilingzhu, nZhenlingshi, nLuckyStone, bMoneyAdd)
	if not self.m_oRole:IsSysOpen(61, true) then 
		-- self.m_oRole:Tips("功能未开启")
		return 
	end
	local oEqu = self:GetPropByBox(nBoxType, nBoxParam)
	if not oEqu then
		return self.m_oRole:Tips("道具不存在")
	end
	if not oEqu:IsEquipment() then
		return self.m_oRole:Tips("目标道具不是装备")
	end

	local oRole = self.m_oRole
	local fnConfirmCallback = function(tData)
		if tData.nSelIdx == 1 then  --取消
			return
		elseif tData.nSelIdx == 2 then  --确定
			self:StrengthenEquipment(nBoxType, nBoxParam, bStorageMode, 
				nQilingzhu, nZhenlingshi, nLuckyStone, bMoneyAdd)
		end
	end

	if not oEqu:IsBind() then 
		local sCont = "强化后装备将变为绑定，是否继续？"
		local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=30}
		goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
	else
		self:StrengthenEquipment(nBoxType, nBoxParam, bStorageMode, 
		nQilingzhu, nZhenlingshi, nLuckyStone, bMoneyAdd)
	end
end

--<=x耐久的穿戴装备列表
function CKnapsack:GetDurableWearEqu(nLimitDurable)
	local tEquList = {}
	for _, oEqu in pairs(self.m_tWearEqu) do
		if oEqu:GetDurable() <= nLimitDurable then
			table.insert(tEquList, oEqu)
		end
	end
	return tEquList
end

--战斗结束
function CKnapsack:OnBattleResult(tBTRes)
	if self.m_oRole:IsRobot() then return end
	local oWeapon = self:GetWearEqu(gtEquPart.eWeapon) 
	if oWeapon then
		local nOldDurable = oWeapon:GetDurable()
		local nSubDurable = math.ceil((tBTRes.nAtkCount or 0) / 20)
		oWeapon:AddDurable(-nSubDurable)
		self:MarkDirty(true)
		--耐久变0了 
		if oWeapon:GetDurable() <= 0 and nOldDurable ~= oWeapon:GetDurable() then
			self.m_oRole:UpdateAttr()
		end
	end
	for k = gtEquPart.eHat, gtEquPart.eShoes do
		local oEqu = self:GetWearEqu(k)
		if oEqu then
			local nOldDurable = oEqu:GetDurable()
			local nSubDurable = math.ceil((tBTRes.nBeAtkCount or 0) / 15)
			oEqu:AddDurable(-nSubDurable)
			self:MarkDirty(true)
			--耐久变0了
			if oEqu:GetDurable() <= 0 and nOldDurable ~= oEqu:GetDurable() then
				self.m_oRole:UpdateAttr()
			end
		end
	end
end

--获取每件装备每个宝石等级的宝石数量
function CKnapsack:GetEachEquGemCount()
	local tLevelMap = {}		--{[level]=coutn}
	for nPart, oItem in pairs(self.m_tWearEqu) do
		for k, v in pairs(oItem.tGem) do
			local nOldCount = tLevelMap[v.nLv] or 0
			tLevelMap[v.nLv] = nOldCount + 1
		end
	end
	return tLevelMap
end

function CKnapsack:PropEquipReMake(nBoxType,nBoxParam,nType,bMoneyAdd, nTransferAttrID, nTarAttrID)
	if not self.m_oRole:IsSysOpen(64, true) then 
		-- self.m_oRole:Tips("功能未开启")
		return 
	end
	if not nBoxType or not nBoxParam or not nType or not nTransferAttrID then
		self.m_oRole:Tips("参数错误1")
		return
	end
	local oEqu = self:GetPropByBox(nBoxType, nBoxParam)
	if not oEqu then
		return self.m_oRole:Tips("道具不存在")
	end
	if not oEqu:IsEquipment() then
		return self.m_oRole:Tips("目标道具不是装备")
	end
	local nPartType = oEqu:GetPartType()
	local oWearEqu = self.m_tWearEqu[nPartType]
	if not oWearEqu then
		return self.m_oRole:Tips("装备栏没有对应部位的装备哦")
	end

	if oEqu:GetQualityLevel() == gtQualityColor.eWhite then
		self.m_oRole:Tips("还不能进行装备转移哦")
		return
	end

	local sReason, nHandleType = self:PropertyTransferCheck(oEqu, oWearEqu,nTransferAttrID, nTarAttrID, nType)
	if sReason and type(sReason) == "string" then
		return self.m_oRole:Tips(sReason)
	end
	local bRet = self:TransferAttr(oEqu, oWearEqu,nTransferAttrID, nTarAttrID, nType)
	if not bRet then return end
	self:MarkDirty(true)
	self.m_oRole:Tips("装备转移成功")
	self.m_oRole:SendMsg("PropEquipReMakeRet", {})
	self:SendPropDetailInfo(oWearEqu,gtPropBoxType.eEquipment,oWearEqu:GetPartType())
	self:SendPropDetailInfo(oEqu,nBoxType,nBoxParam) 
end

--附加属性装备转移条件检测
function CKnapsack:PropertyTransferCheck(oEqu, oWearEqu, nTransferAttrID, nTarAttrID)
	local tEqutAddProperty = oEqu:GetAddProperty()
	local tWearAddProperty = oWearEqu:GetAddProperty()
	if not tEqutAddProperty[nTransferAttrID] then
		return "转移装备没有该属性哦"
	end
	if tWearAddProperty[nTransferAttrID] and tWearAddProperty[nTransferAttrID].nEffectValue > 
		tEqutAddProperty[nTransferAttrID].nEffectValue then
		return "目标属性高于转移属性,不能进行转移哦"
	elseif nTarAttrID ~= 0 then
		if not tWearAddProperty[nTarAttrID] then
			return string.format("目标装备么有此属性<%d>", nTarAttrID)
		end
	end
end

function CKnapsack:TransferAttr(oEqu, oWearEqu, nTransferAttrID, nTarAttrID, nType)
	local tEqutAddProperty = oEqu:GetAddProperty()
	local tWearAddProperty = oWearEqu:GetAddProperty()
	local tAddransferAttr =  tEqutAddProperty[nTransferAttrID] 
	local nEquLevel = oWearEqu:GetLevel()
	local nAttrBaseVal = oWearEqu:GetBaseAttr(nTransferAttrID)
	assert(nAttrBaseVal, "装备附加属性配置错误")
	local nV1, nV2 = math.modf(tAddransferAttr.nEffectValue / nAttrBaseVal)
	nModulus = nV1 + tonumber(string.format("%.2f",nV2))
	local nQualityLevel = oWearEqu:GetUndulateQuality(tonumber(nModulus))
	if nTarAttrID == 0 then
		 if oWearEqu:IsAddPropertyMax() then
			return self.m_oRole:Tips("附加属性达到上限了哦")
		end
		oWearEqu:ResetPropertyHandle(nTransferAttrID, nQualityLevel, tAddransferAttr.nEffectValue)
		oEqu:RemoveAddProperty(nTransferAttrID)
	else
		if tWearAddProperty[nTransferAttrID] then
			oEqu:RemoveAddProperty(nTransferAttrID)
		 	oWearEqu:ResetPropertyHandle(nTransferAttrID, nQualityLevel, tAddransferAttr.nEffectValue)
		else
			oWearEqu:ResetPropertyHandle(nTransferAttrID, nQualityLevel, tAddransferAttr.nEffectValue)
			oWearEqu:RemoveAddProperty(nTarAttrID)
			oEqu:RemoveAddProperty(nTransferAttrID)
		end
	end
	self.m_oRole:UpdateAttr()
	return true
end

function CKnapsack:ExchangeLegendEqu(nEquID) 
	-- if true then --功能屏蔽
	-- 	return 
	-- end
	local oRole = self.m_oRole
	if not nEquID or type(nEquID) ~= "number" then 
		return oRole:Tips("参数错误") 
	end
	local tEquConf = ctEquipmentConf[nEquID]
	if not tEquConf then 
		return oRole:Tips("参数错误") 
	end
	if not tEquConf.bLegend then 
		return oRole:Tips("目标道具不是神兵")
	end
	if not self:CheckCanWear(nEquID) then 
		oRole:Tips("无法穿戴该神兵，无法兑换")
		return 
	end

	local tExchangeConf = ctGodEquExchangeConf[nEquID]
	assert(tExchangeConf)
	local tCost = {}
	for k, v in pairs(tExchangeConf.tMaterial) do --防止策划配错表，做个检查
		if v[1] > 0 and v[2] > 0 and v[3] > 0 then 
			table.insert(tCost, v)
		end
	end
	assert(#tCost > 0, "策划请注意，配置错误")
	if not oRole:CheckSubShowNotEnoughTips(tCost, "神兵兑换", true) then 
		return 
	end
	local nTarID = self:GetTarLegendEqu(nEquID, oRole:GetLevel())  --实际获得的道具ID
	oRole:AddItem(gtItemType.eProp, nTarID, 1, "神兵兑换", nil, true)
	self.m_tLegendEquExchangeRecord[nEquID] = (self.m_tLegendEquExchangeRecord[nEquID] or 0) + 1
	self:MarkDirty(true)
	oRole:Tips("兑换成功")

	local sContentTmp = ctTalkConf["exchangelegendequ"].sContent
	local sContent = string.format(sContentTmp, oRole:GetFormattedName(), 
		ctPropConf:GetFormattedName(nTarID))
	GF.SendHearsayMsg(sContent)

	self:LegendEquExchangeInfoReq()
end

function CKnapsack:GetTarLegendEqu(nSrcID, nLevel)
	local tConf = ctGodEquUpgradeConf[nSrcID]
	if not tConf then --可能已达最高等级
		return nSrcID
	end
	local tPreConf = nil
	while tConf do 
		if tConf.nLevel > nLevel then 
			break 
		end
		tPreConf = tConf
		tConf = ctGodEquUpgradeConf[tConf.nTarEqu]
	end

	if tPreConf and tPreConf.nEquID > 0 then 
		return tPreConf.nTarEqu
	end
	return nSrcID 
end

function CKnapsack:ExchangeLegendEquReq(nEquID) 
	local oRole = self.m_oRole
	if not nEquID or type(nEquID) ~= "number" then 
		return oRole:Tips("参数错误") 
	end
	local tEquConf = ctEquipmentConf[nEquID]
	if not tEquConf then 
		return oRole:Tips("参数错误") 
	end
	if not ctGodEquExchangeConf[nEquID] then 
		oRole:Tips("错误的兑换参数")
		return 
	end

	local fnConfirmCallback = function(tData) 
		if tData.nSelIdx == 1 then  --取消
			return
		elseif tData.nSelIdx == 2 then  --确定
			self:ExchangeLegendEqu(nEquID)
		end
	end
	local nTarID = self:GetTarLegendEqu(nEquID, oRole:GetLevel())
	local nKeepNum = self:ItemCountAll(nTarID) 
	if nKeepNum > 0 then 
		local sCont = string.format("当前已拥有%d件%s，是否确定继续兑换？", 
			nKeepNum, ctPropConf:GetFormattedName(nEquID))
		local tMsg = {sCont=sCont, tOption={"取消", "确定"}, nTimeOut=30}
		goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
	else 
		self:ExchangeLegendEqu(nEquID)
	end
end

--神兵升级
function CKnapsack:UpdateLegendEquLevel(oEqu, nBoxType, nGridID) 
	-- if true then --功能屏蔽
	-- 	return 
	-- end
	local nLevel = self.m_oRole:GetLevel()
	local nEquID = oEqu:GetID()
	local nTarID = self:GetTarLegendEqu(nEquID, nLevel)
	if nTarID == nEquID or nTarID <= 0 then 
		return 
	end
	local sReason = "神兵升级"
	local oTarEqu = self:CreateProp(nTarID, 0, true, nil)
	oTarEqu:AddNum(1)
	self:CleanBoxGrid(nBoxType, nGridID)
	goLogger:AwardLog(gtEvent.eSubItem, sReason, self.m_oRole, gtItemType.eProp, nEquID, 1, self:ItemCount(nEquID)) 
	self:SetItemToBox(oTarEqu, nBoxType, nGridID)
	goLogger:AwardLog(gtEvent.eAddItem, sReason, self.m_oRole, gtItemType.eProp, nEquID, 1, self:ItemCount(nTarID))
	oEqu:LegendEquAttrCopy(oTarEqu)
	oEqu:AddPropertAttrChange()
	oTarEqu:UpdateAttr()
	self:MarkDirty(true)
end

function CKnapsack:CheckLegendEquUpgrade()
	local tEquList = {}
	for _, oProp in pairs(self.m_tGridMap) do 
		if oProp:IsEquipment() and oProp:IsLegend() then 
			table.insert(tEquList, oProp)
		end
	end
	for _, oProp in ipairs(tEquList) do 
		self:UpdateLegendEquLevel(oProp, gtPropBoxType.eBag, oProp:GetGrid())
	end
	tEquList = {}
	for _, oProp in pairs(self.m_tWearEqu) do 
		if oProp:IsEquipment() and oProp:IsLegend() then 
			table.insert(tEquList, oProp)
		end
	end
	for _, oProp in ipairs(tEquList) do 
		self:UpdateLegendEquLevel(oProp, gtPropBoxType.eEquipment, oProp:GetPartType())
	end
	tEquList = {}
	for _, oProp in pairs(self.m_tStoGridMap) do 
		if oProp:IsEquipment() and oProp:IsLegend() then 
			table.insert(tEquList, oProp)
		end
	end
	for _, oProp in ipairs(tEquList) do 
		self:UpdateLegendEquLevel(oProp, gtPropBoxType.eStorage, oProp:GetGrid())
	end
	if #tEquList > 0 then --装备栏发生变化，则刷新下装备列表
		self:WearEquListReq()
	end
	tEquList = {}
end

function CKnapsack:LegendEquExchangeInfoReq() 
	local tMsg = {}
	tExchangeInfo = {}
	for nEquID, nCount in pairs(self.m_tLegendEquExchangeRecord) do 
		table.insert(tExchangeInfo, {nEquID = nEquID, nCount = nCount})
	end
	tMsg.tExchangeInfo = tExchangeInfo
	self.m_oRole:SendMsg("KnapsacLegendEquExchangeInfoRet", tMsg)
end

--更新装备强化共鸣等级
function CKnapsack:UpdateStrengthenTriggerAttr()
	local bWearAll = true 
	local nMinLevel = nil
	local nMinEquLevel = nil

	local tEquStrengthenMap = {}
	for _, nPartType in pairs(gtEquPartType) do 
		local oEqu = self:GetWearEqu(nPartType)
		if not oEqu then 
			bWearAll = false 
		else
			local nStrengthenLevel = oEqu:GetStrengthenLevel()
			if not nMinLevel then 
				nMinLevel = nStrengthenLevel
			elseif nMinLevel > nStrengthenLevel then 
				nMinLevel = nStrengthenLevel
			end
			tEquStrengthenMap[nPartType] = nStrengthenLevel

			local nEquLevel = oEqu:GetLevel()
			if not nMinEquLevel then 
				nMinEquLevel = nEquLevel
			elseif nMinEquLevel > nEquLevel then 
				nMinEquLevel = nEquLevel
			end
		end
	end

	local tStrengthenData = self.m_tStrengthenTriggerData
	if bWearAll and ctStrengthenTriggerAttrConf[1].nTriggerLv <= nMinLevel then 
		local nTriggerID = 0
		local nTriggerLevel = 0
		for _, tConf in ipairs(ctStrengthenTriggerAttrConf) do 
			if tConf.nTriggerLv <= nMinLevel and nTriggerLevel <= tConf.nTriggerLv then 
				nTriggerID = tConf.nID
				nTriggerLevel = tConf.nTriggerLv
			end
		end
		tStrengthenData.nTriggerID = nTriggerID
		tStrengthenData.tTriggerAttr = {}
		local tConf = ctStrengthenTriggerAttrConf[tStrengthenData.nTriggerID]
		tStrengthenData.tTriggerAttr = self.m_oRole:CalcModuleGrowthAttr(tConf.nPower) or {}
	else
		tStrengthenData.nTriggerID = 0
		tStrengthenData.tTriggerAttr = {}
	end

	local nMaxID = #ctStrengthenTriggerAttrConf
	if tStrengthenData.nTriggerID == nMaxID then 
		tStrengthenData.nNextLevelActiveNum = 0
	else
		local nNextTriggerID = tStrengthenData.nTriggerID + 1
		local nNextLevel = ctStrengthenTriggerAttrConf[nNextTriggerID].nTriggerLv
		local nPartNum = 0
		for k, nPartType in pairs(gtEquPartType) do 
			if tEquStrengthenMap[nPartType] and tEquStrengthenMap[nPartType] >= nNextLevel then 
				nPartNum = nPartNum + 1
			end
		end
		tStrengthenData.nNextLevelActiveNum = nPartNum
	end
end

--更新宝石共鸣等级
function CKnapsack:UpdateGemTriggerAttr()
	local bGemMountAll = true 
	local nMinLevel = nil
	local nMinEquLevel = nil

	local tEquGemMap = {} --{nPartType:{nGemIndex:nLevel, ...}, ...}
	for _, nPartType in pairs(gtEquPartType) do 
		local oEqu = self:GetWearEqu(nPartType)
		if not oEqu then 
			bGemMountAll = false 
			break 
		else
			local tEquGemData = {}
			local tEquGem = oEqu.tGem
			for k = 1, 3 do 
				local tGem = tEquGem[k]
				if not tGem or tGem.nLv < 1 then 
					bGemMountAll = false
					tEquGemData[k] = 0
				else
					if not nMinLevel then 
						nMinLevel = tGem.nLv
					elseif nMinLevel > tGem.nLv then 
						nMinLevel = tGem.nLv
					end
					tEquGemData[k] = tGem.nLv

					local nEquLevel = oEqu:GetLevel()
					if not nMinEquLevel then 
						nMinEquLevel = nEquLevel
					elseif nMinEquLevel > nEquLevel then 
						nMinEquLevel = nEquLevel
					end
				end
			end
			tEquGemMap[nPartType] = tEquGemData
		end
	end

	local tGemTriggerData = self.m_tGemTriggerData
	if bGemMountAll and ctGemTriggerAttrConf[1].nTriggerLv <= nMinLevel then 
		local nTriggerID = 0
		local nTriggerLevel = 0
		for _, tConf in ipairs(ctGemTriggerAttrConf) do 
			if tConf.nTriggerLv <= nMinLevel and nTriggerLevel <= tConf.nTriggerLv then 
				nTriggerID = tConf.nID
				nTriggerLevel = tConf.nTriggerLv
			end
		end
		tGemTriggerData.nTriggerID = nTriggerID
		local tConf = ctGemTriggerAttrConf[tGemTriggerData.nTriggerID]
		tGemTriggerData.tTriggerAttr = self.m_oRole:CalcModuleGrowthAttr(tConf.nPower) or {}
	else
		tGemTriggerData.nTriggerID = 0
		tGemTriggerData.tTriggerAttr = {}
	end

	local nMaxID = #ctGemTriggerAttrConf
	if tGemTriggerData.nTriggerID == nMaxID then 
		tGemTriggerData.nNextLevelActiveNum = 0
	else
		local nNextTriggerID = tGemTriggerData.nTriggerID + 1
		local nNextLevel = ctGemTriggerAttrConf[nNextTriggerID].nTriggerLv
		local nGemNum = 0
		for k, nPartType in pairs(gtEquPartType) do 
			local tEquGemData = tEquGemMap[nPartType]
			if tEquGemData then 
				for k, nGemLevel in pairs(tEquGemData) do 
					if nGemLevel >= nNextLevel then 
						nGemNum = nGemNum + 1
					end
				end
			end
		end
		tGemTriggerData.nNextLevelActiveNum = nGemNum
	end
end

function CKnapsack:SyncEquTriggerAttr()
	local tMsg = {}

	local tStrengthenData = {}
	local nCurStrengthID = self:GetEquStrengthenTriggerID()
	tStrengthenData.nStrengthenTriggerID = nCurStrengthID
	tStrengthenData.nNextLevelActiveNum = self.m_tStrengthenTriggerData.nNextLevelActiveNum

	local tStrengthAttrList = {}
	for nAttrID, nAttrVal in pairs(self:GetEquStrengthenTriggerAttr()) do 
		table.insert(tStrengthAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tStrengthenData.tAttrList = tStrengthAttrList

	local tNextStrengthAttr = {}
	if nCurStrengthID ~= #ctStrengthenTriggerAttrConf then 
		local tNextConf = ctStrengthenTriggerAttrConf[nCurStrengthID + 1]
		if tNextConf then --计算量很小, 实时计算发给前端
			tNextStrengthAttr = self.m_oRole:CalcModuleGrowthAttr(tNextConf.nPower) or {}
		end
	end
	local tMsgNextStrengthAttrList = {}
	for nAttrID, nAttrVal in pairs(tNextStrengthAttr) do 
		table.insert(tMsgNextStrengthAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tStrengthenData.tNextLevelAttrList = tMsgNextStrengthAttrList

	tMsg.tStrengthenData = tStrengthenData

	local tGemData = {}
	local nCurGemID = self:GetEquGemTriggerID()
	tGemData.nGemTriggerID = nCurGemID
	tGemData.nNextLevelActiveNum = self.m_tGemTriggerData.nNextLevelActiveNum

	local tGemAttrList = {}
	for nAttrID, nAttrVal in pairs(self:GetEquGemTriggerAttr()) do 
		table.insert(tGemAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tGemData.tAttrList = tGemAttrList

	local tNextGemAttr = {}
	if nCurGemID ~= #ctGemTriggerAttrConf then 
		local tNextConf = ctGemTriggerAttrConf[nCurGemID + 1]
		if tNextConf then --计算量很小, 实时计算发给前端
			tNextGemAttr = self.m_oRole:CalcModuleGrowthAttr(tNextConf.nPower) or {}
		end
	end
	local tMsgNextGemAttrList = {}
	for nAttrID, nAttrVal in pairs(tNextGemAttr) do 
		table.insert(tMsgNextGemAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tGemData.tNextLevelAttrList = tMsgNextGemAttrList

	tMsg.tGemData = tGemData
	self.m_oRole:SendMsg("KnapsackEquTriggerAttrRet", tMsg)
end

--更新装备强化和宝石共鸣属性
function CKnapsack:UpdateEquTriggerAttr(bSync)
	local nOldStrengthen = self:GetEquStrengthenTriggerID()
	local nOldGem = self:GetEquGemTriggerID()
	self:UpdateStrengthenTriggerAttr()
	self:UpdateGemTriggerAttr()
	local nNewStrengthen = self:GetEquStrengthenTriggerID()
	local nNewGem = self:GetEquGemTriggerID()

	if nNewStrengthen ~= nOldStrengthen and nNewStrengthen > 0 then 
		local nStrengthenLv = ctStrengthenTriggerAttrConf[nNewStrengthen].nTriggerLv
		local sContentTmp = ctTalkConf["strengthentriggerattr"].sContent
		local sContent = string.format(sContentTmp, nStrengthenLv)
		self.m_oRole:Tips(sContent)
	end
	if nNewGem ~= nOldGem and nNewGem > 0 then 
		local nGemLv = ctGemTriggerAttrConf[nNewGem].nTriggerLv
		local sContentTmp = ctTalkConf["gemtriggerattr"].sContent
		local sContent = string.format(sContentTmp, nGemLv)
		self.m_oRole:Tips(sContent)
	end
	if nNewStrengthen ~= nOldStrengthen or nNewGem ~= nOldGem then 
		self:MarkDirty(true)
		self.m_oRole:UpdateAttr()
	end

	if bSync then 
		-- if nNewStrengthen ~= nOldStrengthen and nNewStrengthen > 0 then 
		-- 	local nStrengthenLv = ctStrengthenTriggerAttrConf[nNewStrengthen].nTriggerLv
		-- 	local sContentTmp = ctTalkConf["strengthentriggerattr"].sContent
		-- 	local sContent = string.format(sContentTmp, nStrengthenLv)
		-- 	self.m_oRole:Tips(sContent)
		-- end
		-- if nNewGem ~= nOldGem and nNewGem > 0 then 
		-- 	local nGemLv = ctGemTriggerAttrConf[nNewGem].nTriggerLv
		-- 	local sContentTmp = ctTalkConf["gemtriggerattr"].sContent
		-- 	local sContent = string.format(sContentTmp, nGemLv)
		-- 	self.m_oRole:Tips(sContent)
		-- end
		self:SyncEquTriggerAttr()
	end
end

function CKnapsack:TransferDataReq(nPartType)
	local tGridList =  self:AutoSellEqut(nPartType, true)
	self.m_oRole:SendMsg("knapsacTransferkRet", {tGrid = tGridList})
end

--重铸界面出售请求
function CKnapsack:RecastSellReq(nBoxType, nBoxParam)
	assert(nBoxType or nBoxParam, "参数错误")
	if nBoxType ~= gtPropBoxType.eEquipment then
		return self.m_oRole:Tips("请发送装备栏装备哦")
	end
	local oEqu = self:GetPropByBox(nBoxType, nBoxParam)
	if not oEqu then
		return self.m_oRole:Tips("道具不存在")
	end

	if not oEqu:IsEquipment() then
		return self.m_oRole:Tips("目标道具不是装备")
	end
	local nPartType= oEqu:GetPartType()
	local oWearEqu = self:GetPropByBox(gtPropBoxType.eEquipment, nPartType)
	assert(oWearEqu, "当前部位没有装备不能出售哦")
	self:AutoSellEqut(nPartType)
end

function CKnapsack:AutoSellEqut(nPartType, bReturn)
	local oWearEqu = self.m_tWearEqu[nPartType]
	local tAutoSaleList = {}
	local tGridList = {}
	local tSubGridList = {}
	local nTotalSilverCoin = 0
	local tItemList = {}
	if oWearEqu then
		local tWearAddProperty = oWearEqu:GetAddProperty()
		for nGrid, oItem in pairs(self.m_tGridMap) do
			local bFlag = false
			if oItem:IsEquipment() and oItem:GetPartType() == nPartType then
				for nAttrID, tAttr in pairs(oItem:GetAddProperty()) do
					if tWearAddProperty[nAttrID] then
						if tAttr.nEffectValue > tWearAddProperty[nAttrID].nEffectValue then
							bFlag = true
							break
						end
					end
					if not tWearAddProperty[nAttrID] then
						bFlag = true
						break
					end
				end
				if not bFlag then
					if not bReturn then
						table.insert(tItemList, {nID = oItem:GetID(), nGrid = oItem:GetGrid(), nType = 2, nNum = oItem:GetNum()})
					end
				else
					table.insert(tGridList, oItem:GetGrid())
				end
			end
		end
	end
	local nCurrType
	local _fnGetSumPrice = function (tItemList)
		local nTotalCurr = 0
		for _, tItem in ipairs(tItemList) do
			nTotalCurr = nTotalCurr + tItem.nPrice
		end
		return nTotalCurr
	end
	if #tItemList > 0 then
		local fnEnterSellEqutCallback = function(tData)
			if tData.nSelIdx == 2 then
				self:PropListSellReq(tItemList)
				self.m_oRole:Tips("出售成功")
				self.m_oRole:Tips("已将所有无可转移附加属性的装备出售")
			end
		end

		local fnPriceCallback = function(bSucc, tItemList, tPriceList)
			if not bSucc or not tPriceList then 
				return 
			end

			nCurrType = tPriceList[1] and tPriceList[1].nCurrType
			if not nCurrType then return end
			local nTotalCurr= _fnGetSumPrice(tPriceList)
			local sCurrName = gtCurrName[nCurrType] and gtCurrName[nCurrType] or "货币"
			if nCurrType == gtCurrType.eBYuanBao then
				if sCurrName ~= "绑定元宝" then
					sCurrName = "绑定元宝"
				end
				if self:GetDailySaleYuanbaoRemainNum() <= 0 then 
					nCurrType = gtCurrType.eYinBi
					nTotalCurr = nTotalCurr * gnSaleSilverRatio
					sCurrName = gtCurrName[nCurrType]
				end
			end
			local sCont = string.format("是否将背包中所有不满足转移条件的同部位装备快速回收？共%d件装备可回收%d%s", #tItemList, nTotalCurr, sCurrName)
			local tOption = {"取消", "确定"}
			local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
			goClientCall:CallWait("ConfirmRet", fnEnterSellEqutCallback, self.m_oRole, tMsg)
		end
		self:QueryItemListSalePrice(tItemList, fnPriceCallback)
	else
		if not bReturn then
			self.m_oRole:Tips("当前没有满足出售条件的装备，无法进行快速出售")
		end
	end
	return tGridList
end