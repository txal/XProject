--人物洗点
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--限制等级
local nLimitLevel = 40
--加点方案等级
local tLevelPlan = ctRolePotentialConf[1].tPlanOpenLv
--每个道具洗点数
local nPropPoten = 2
--洗点丹
local nWashProp = 10012

function CRoleWash:Ctor(oRole)
	self.m_oRole = oRole
	self.m_bResetAll = false --是否已经重置过所有属性点
	self.m_nSwitchNum = 0 --当天切换次数
	self.m_nSwitchTime = 0	--切换时间

	self.m_nPlan = 0 --当前方案
	self.m_tPlanMap = {} --方案已分配潜力点{[方案]={分配点},...}
	self.m_nTotalPoten = 0	--总潜力点

	self.m_bAutoAddPoten = false --自动加点
	self.m_tRecommandPlanMap = {}  	--推荐方案映射{[方案]={方案},...}
	self.m_tRecommandPlanIDMap = {}	--推荐方案ID映射
end

function CRoleWash:LoadData(tData)
	if tData then
		self.m_bResetAll = tData.m_bResetAll
		self.m_nSwitchNum = tData.m_nSwitchNum
		self.m_nSwitchTime = tData.m_nSwitchTime

		self.m_nPlan = tData.m_nPlan
		self.m_tPlanMap = tData.m_tPlanMap
		self.m_nTotalPoten = tData.m_nTotalPoten

		self.m_bAutoAddPoten = tData.m_bAutoAddPoten or self.m_bAutoAddPoten
		self.m_tRecommandPlanMap = tData.m_tRecommandPlanMap or {}
		self.m_tRecommandPlanIDMap = tData.m_tRecommandPlanIDMap or {}
	end
	self:OnLoaded(not tData)
end

function CRoleWash:OnLoaded(bCreate)
	--初始化潜力点
	if bCreate then
		local nSchool = self.m_oRole:GetSchool()
		local tBorn = ctRolePotentialConf[nSchool].tBorn[1]
		self.m_tPlanMap[1] = table.DeepCopy(tBorn, true)
		self.m_nPlan = 1
		self.m_nTotalPoten = 5
		self.m_bAutoAddPoten = false
		self:MarkDirty(true)
	end
	if not next(self.m_tRecommandPlanMap) then
		local nSchool = self.m_oRole:GetSchool()
		local tDefPlan = table.DeepCopy(ctRolePotentialConf[nSchool].tPlan[1], true)
		for k = 1, #tLevelPlan do
			self.m_tRecommandPlanMap[k] = table.DeepCopy(tDefPlan, true)
			self.m_tRecommandPlanIDMap[k] = 1
		end
		self:MarkDirty(true)
	end
end

function CRoleWash:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_bResetAll = self.m_bResetAll
	tData.m_nSwitchNum = self.m_nSwitchNum
	tData.m_nSwitchTime = self.m_nSwitchTime

	tData.m_nPlan = self.m_nPlan
	tData.m_tPlanMap = self.m_tPlanMap
	tData.m_nTotalPoten = self.m_nTotalPoten

	tData.m_bAutoAddPoten = self.m_bAutoAddPoten
	tData.m_tRecommandPlanMap = self.m_tRecommandPlanMap
	tData.m_tRecommandPlanIDMap = self.m_tRecommandPlanIDMap
	return tData
end

function CRoleWash:GetType()
	return gtModuleDef.tRoleWash.nID, gtModuleDef.tRoleWash.sName
end

--最多可洗至等级+10
function CRoleWash:MaxWash()
	return self.m_oRole:GetLevel()+10
end

--取指定方案已分配潜力点表,不指定则取当前方案
function CRoleWash:GetPotenPlan(nPlan)
	if nPlan then
		if not self.m_tPlanMap[nPlan] then
			self.m_tPlanMap[nPlan] = {0, 0, 0, 0, 0}
			self:MarkDirty(true)
		end
		return self.m_tPlanMap[nPlan]
	end

	if not self.m_tPlanMap[self.m_nPlan] then
		self.m_tPlanMap[self.m_nPlan] = {0, 0, 0, 0, 0}
		self:MarkDirty(true)
	end
	return self.m_tPlanMap[self.m_nPlan]
end

--取指定方案未分配潜力点,不指定则取当前方案
function CRoleWash:GetPotential(nPlan)
	local nPoten = 0
	local tPlan = self:GetPotenPlan(nPlan)
	for k = 1, #tPlan do
		nPoten = nPoten + (tPlan[k] or 0)
	end
	return (self.m_nTotalPoten-nPoten)
end

--添加潜力点
function CRoleWash:AddPotential(nPoten)
	self.m_nTotalPoten = self.m_nTotalPoten + nPoten
	local nRemainPoten = self:GetPotential(self.m_nPlan) 
	print("CRoleWash:AddPotential***", nRemainPoten, self.m_nTotalPoten)

    --计算潜力点,40级前自动加点,每级5点
    if (self.m_oRole:GetLevel() < nLimitLevel or self.m_bAutoAddPoten) and math.floor(nRemainPoten/5)>0 then

    	local nAddPoten = math.floor(nRemainPoten/5)*5 --取5的整数陪
    	local nSchool = self.m_oRole:GetSchool()
    	local tPlan = self:GetPotenPlan(self.m_nPlan)
    	local tRecommandPlan = self.m_tRecommandPlanMap[self.m_nPlan]
        for k = 1, #tRecommandPlan do
            tPlan[k] = tPlan[k] + math.floor(nAddPoten*tRecommandPlan[k]/5)
        end

    end

	self:MarkDirty(true)
    return self.m_nTotalPoten
end

--取除装备外主属性
function CRoleWash:GetMainAttrWithoutEqu()
	local tTmpAttr = {}
	local tMainAttr = self.m_oRole:GetMainAttr()
	local tEquMainAttr = self.m_oRole.m_oKnapsack:GetEquMainAttr()
	for k = 1, #tMainAttr do
		tTmpAttr[k] = tMainAttr[k] - (tEquMainAttr[k] or 0)
	end
	return tTmpAttr
end

--取主属性
function CRoleWash:GetMainAttrPoten(nPlan)
	local tTmpMainAttr = {}
	local tMainAttr = self.m_oRole:GetMainAttr()
	local tCurPotenAttr = self:GetPotenPlan(self.m_nPlan)
	local tNewPotenAttr = self:GetPotenPlan(nPlan)
	for k = 1, #tMainAttr do
		tTmpMainAttr[k] = tMainAttr[k] - (tCurPotenAttr[k] or 0) + (tNewPotenAttr[k] or 0)
	end
	return tTmpMainAttr
end

--取除潜力点外的结果属性
function CRoleWash:GetResAttrWithoutPoten()
	local tTmpResAttr = {}
	local tResAttr = self.m_oRole:GetResAttr()
	local tPotenMainAttr = self:GetPotenPlan(self.m_nPlan)
	for k = 1, 5 do --5个主属性
		local nMainAttr = tPotenMainAttr[k]
		for _, tAttr in ipairs(ctRoleAttrConf[k].tAttr) do
			tTmpResAttr[tAttr[1]] = tResAttr[tAttr[1]] - math.floor(tAttr[2]*nMainAttr)
		end
	end 
	return tTmpResAttr
end

--计算某个方案的结果属性
function CRoleWash:GetResAttrWithPoten(nPlan)
	if self.m_nPlan == nPlan then
		return self.m_oRole:GetResAttr()
	end
	local tResAttr = self:GetResAttrWithoutPoten()
	local tPotenMainAttr =self:GetPotenPlan(nPlan)
	for k = 1, 5 do --5个主属性
		local nMainAttr = tPotenMainAttr[k]
		for _, tAttr in ipairs(ctRoleAttrConf[k].tAttr) do
			tResAttr[tAttr[1]] = tResAttr[tAttr[1]] + math.floor(tAttr[2]*nMainAttr)
		end
	end 
	return tResAttr
end

--取方案数量
function CRoleWash:MaxPlan()
	local nLevel = self.m_oRole:GetLevel()
	for k = #tLevelPlan, 1, -1 do
		if nLevel >= tLevelPlan[k][1] then
			return tLevelPlan[k][2]
		end
	end
	return 0
end

--检测切换方案重置
function CRoleWash:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nSwitchTime, 0) then
		self.m_nSwitchTime = os.time()
		self.m_nSwitchNum = 0
		self:MarkDirty(true)
	end
end

--切换方案消耗银币
function CRoleWash:SwitchCost()
	--银币消耗=当天已切换次数*单位元宝银币*5
	return (self.m_nSwitchNum*gnSilverRatio*5)
end

--系统开放检测
function CRoleWash:CheckSysOpen(bTips)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(52, bTips) then
		-- if bTips then
		-- 	self.m_oRole:Tips("加点系统未开启")
		-- end
		return
	end
	return true
end

--方案信息请求
function CRoleWash:PlanInfoReq(nPlan)
	if not self:CheckSysOpen() then
		return
	end

	nPlan = nPlan == 0 and self.m_nPlan or nPlan
	local tMsg = {
		nPlan = nPlan,
		nCurrPlan = self.m_nPlan,
		nMaxPlan = self:MaxPlan(),
		nPoten = self:GetPotential(nPlan),
		tMainAttr = self:GetMainAttrPoten(nPlan),
		tResAttr = {},

		tRecommandPlan = self.m_tRecommandPlanMap[nPlan],
		nRecommandPlan = self.m_tRecommandPlanIDMap[nPlan],
		bAutoAddPoten = self.m_bAutoAddPoten,
	}
	local tResAttr = self:GetResAttrWithPoten(nPlan)
	for nAttrID, nAttrVal in pairs(tResAttr) do
		table.insert(tMsg.tResAttr, {nAttrID=nAttrID, nAttrVal=nAttrVal})
	end
	-- print("CRoleWash:PlanInfoReq***", tMsg.tMainAttr, tMsg.tResAttr)
	self.m_oRole:SendMsg("RWPlanInfoRet", tMsg)
end

--保存配点请求
function CRoleWash:SavePlanReq(tPoten)
	if not self:CheckSysOpen(true) then
		return
	end

	--判断加点数是否正确
	local nRemainPoten = self:GetPotential()
	local nDispPoten = 0
	for k = 1, 5 do --5个主属性
		nDispPoten = nDispPoten + tPoten[k]
	end
	if nDispPoten <= 0 then
		return self.m_oRole:Tips("配点未变化")
	end
	if nDispPoten > nRemainPoten then
		return self.m_oRole:Tips("配点错误")
	end

	--分派潜力点
	local tPlan = self:GetPotenPlan(self.m_nPlan) 
	for k = 1, 5 do --5个主属性
		tPlan[k] = tPlan[k] + tPoten[k]
	end
	self:MarkDirty(true)

	--更新属性
	self.m_oRole:UpdateAttr()
	--同步属性
	self:PlanInfoReq(self.m_nPlan)
end

--启用方案
function CRoleWash:UsePlanReq(nPlan)
	assert(nPlan>=1 and nPlan<=tLevelPlan[#tLevelPlan][2], "方案非法:"..nPlan)
	if not self:CheckSysOpen(true) then
		return
	end

	local nMaxPlan = self:MaxPlan()
	if nPlan > nMaxPlan then
		return self.m_oRole:Tips(string.format("该加点方案需要%d级才能使用", tLevelPlan[nPlan][1]))
	end

	if self.m_nPlan == nPlan then
		return self.m_oRole:Tips("已经是当前方案")
	end

	--检测重置
	self:CheckReset()

	local function _fnSwitchPlan()
		--切换方案
		self.m_nPlan = nPlan
		self.m_nSwitchNum = self.m_nSwitchNum + 1
		self:MarkDirty(true)

		--更新属性
		self.m_oRole:UpdateAttr()
		--同步
		self:PlanInfoReq(self.m_nPlan)
		self.m_oRole:Tips("切换加点方案成功")
	end

	if self.m_nSwitchNum == 0 then
		local sCont = "每天第一次切换加点免费，确认要切换吗？"
		local tMsg = {sCont=sCont, tOption={"取消", "确认"}, nTimeOut=30}

		goClientCall:CallWait("ConfirmRet", function(tData)
			if tData.nSelIdx == 1 then return end
			if self.m_nPlan == nPlan then return end

			_fnSwitchPlan()

		end, self.m_oRole, tMsg)
	else
		local nCost = self:SwitchCost()
		local sCont = string.format("是否花费%d银币进行切换", nCost)

		local tMsg = {sCont=sCont, tOption={"取消", "确认"}, nTimeOut=5}
		goClientCall:CallWait("ConfirmRet", function(tData)
			if tData.nSelIdx == 1 then return end
			if self.m_nPlan == nPlan then return end
			
			if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCost, "切换加点方案") then
				return self.m_oRole:YinBiTips()
			end
			_fnSwitchPlan()

		end, self.m_oRole, tMsg)

	end
end

--取可重置的点数
function CRoleWash:GetResetPoten()
	local nMaxWash = self:MaxWash()
	local tMainAttr = self:GetMainAttrWithoutEqu()
	local tResetPoten = {}
	for k = 1, #tMainAttr do
		tResetPoten[k] = math.max(0, tMainAttr[k]-nMaxWash)
	end
	return tResetPoten
end

--洗点信息请求
function CRoleWash:ResetInfoReq()
	if not self:CheckSysOpen(true) then
		return
	end
	-- if self.m_oRole:GetLevel() < nLimitLevel then
	-- 	return self.m_oRole:Tips(string.format("洗点需要人物等级达到%d级", nLimitLevel))
	-- end
	local tMsg = {
		nPoten = self:GetPotential(),
		tMainAttr = self.m_oRole:GetMainAttr(),
		tResetPoten = self:GetResetPoten(),
		bFreeResetAll = not self.m_bResetAll,
	}
	self.m_oRole:SendMsg("RWResetInfoRet", tMsg)
end

--洗点请求
--@nAttrType 0表示全部重置
--@nYuanBao 是否用元宝
function CRoleWash:ResetReq(nAttrType, bYuanBao)
	assert(nAttrType >= 0 and nAttrType <= 5, "属性类型错误")
	if not self:CheckSysOpen(true) then
		return
	end
	-- if self.m_oRole:GetLevel() < nLimitLevel then
	-- 	return self.m_oRole:Tips(string.format("洗点需要人物等级达到%d级", nLimitLevel))
	-- end
	
	--策划改了需求，不能洗单条属性了
	if nAttrType ~= 0 then
		return self.m_oRole:Tips("不能洗单条属性了哦")
	end

	local tResetPoten = self:GetResetPoten()
	local nResetPoten = 0
	for _, v in pairs(tResetPoten) do
		nResetPoten = nResetPoten + v
	end
	if nResetPoten <= 0 then
		return self.m_oRole:Tips("当前没有可以洗点的属性")
	end

	--重置所有
	if nAttrType == 0 then
		local function _fnResetSuccess()
			--重置点数
			self.m_bResetAll = true
			self.m_tPlanMap[self.m_nPlan] = {0, 0, 0, 0, 0}
			self:MarkDirty(true)

			--设置基础属性
			local tBaseAttr = {}
			local nLevel = self.m_oRole:GetLevel()
			for k = 1, 5 do
				tBaseAttr[k] = nLevel+10
			end
			self.m_oRole:SetBaseAttr(tBaseAttr)
			self.m_oRole:Tips("重置成功，你现在可以重新分配属性点了")
			
			self.m_oRole:UpdateAttr()
			self:PlanInfoReq(self.m_nPlan)
			self:ResetInfoReq()
		end

		if not self.m_bResetAll then
			--这里客户端弹了
			-- local tMsg = {sCont="角色达到40级可免费重置所有属性点一次，确认要继续进行吗？", tOption={"确认", "取消"}, nTimeOut=30}
			-- goClientCall:CallWait("ConfirmRet", function(tData)
			-- 	if tData.nSelIdx == 2 then
			-- 		return
			-- 	end
			-- 	_fnResetSuccess()
			-- end, self.m_oRole, tMsg)
			_fnResetSuccess()

		else
			if bYuanBao then --扣除元宝
				local nBuyPrice = ctPropConf[nWashProp].nBuyPrice
				if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nBuyPrice, "洗点属性") then
					return self.m_oRole:YuanBaoTips()
				end
			else --扣除道具
				if not self.m_oRole:CheckSubItem(gtItemType.eProp, nWashProp, 1, "洗点属性") then
					return self.m_oRole:Tips(string.format("%s不足", CKnapsack:PropName(nWashProp)))
				end
			end
			_fnResetSuccess()

		end

	else
		-- local nWashPoten = tResetPoten[nAttrType]
		-- if nWashPoten <= 0 then
		-- 	return self.m_oRole:Tips("该属性当前没有可洗点数")
		-- end
		-- if bYuanBao then
		-- 	local nPrice = 10
		-- 	if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nPrice, "洗点属性:"..nAttrType) then
		-- 		return self.m_oRole:YuanBaoTips()
		-- 	end
		-- else
		-- 	--扣除道具
		-- 	if not self.m_oRole:CheckSubItem(gtItemType.eProp, nWashProp, 1, "洗点属性:"..nAttrType) then
		-- 		return self.m_oRole:Tips(string.format("%s不足", CKnapsack:PropName(nWashProp)))
		-- 	end
		-- end
		-- --重置点数
		-- local tPlan = self.m_tPlanMap[self.m_nPlan]
		-- local nPotenGet = math.min(nWashPoten, nPropPoten)
		-- tPlan[nAttrType] = tPlan[nAttrType] - nPotenGet
		-- self:MarkDirty(true)

		-- self.m_oRole:Tips(string.format("洗点成功，扣除了%d点%s，你获得了%d点潜力点", nPotenGet, gtMATName[nAttrType], nPotenGet))
		return

	end
end

--设置自动加点方案和自动加点
function CRoleWash:SetRecommandPlanReq(tRecommandPlan, nRecommandPlan, bAutoAddPoten)
	assert(#tRecommandPlan == 5, "参数错误")
	if not self:CheckSysOpen(true) then
		return
	end
	-- if self.m_oRole:GetLevel() < nLimitLevel then
	-- 	return self.m_oRole:Tips(string.format("%d级开启加点功能", nLimitLevel))
	-- end

	local nPlanPoten = 0
	for _, v in ipairs(tRecommandPlan) do
		nPlanPoten = nPlanPoten + v
	end
	if not (nPlanPoten == 5 or nPlanPoten == 0) then
		return self.m_oRole:Tips("加点方案配置错误")
	end

	self.m_tRecommandPlanMap[self.m_nPlan] = tRecommandPlan
	self.m_tRecommandPlanIDMap[self.m_nPlan] = nRecommandPlan
	self.m_bAutoAddPoten = bAutoAddPoten
	self:MarkDirty(true)
	self:PlanInfoReq(self.m_nPlan)
	print("CRoleWash:SetRecommandPlanReq***", self.m_tRecommandPlanMap)
end
