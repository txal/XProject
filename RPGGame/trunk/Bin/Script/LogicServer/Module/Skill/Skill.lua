--门派技能(法术)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--技能表预处理
local _ctSkillConf = {}
local function _ProcessConf()
	for nID, tConf in pairs(ctSkillConf) do
		_ctSkillConf[tConf.nSchool] = _ctSkillConf[tConf.nSchool] or {}
		table.insert(_ctSkillConf[tConf.nSchool], tConf)
	end
	for nSchool, tConfList in pairs(_ctSkillConf) do
		table.sort(tConfList, function(t1, t2) return t1.nLearn<t2.nLearn end)
	end
end
_ProcessConf()

--构造函数
function CSkill:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tSkillMap = {}  --门派技能
	self.m_tBattleAttr = {} --战斗属性
end

function CSkill:LoadData(tData)
	if tData then
		self.m_tSkillMap = tData.m_tSkillMap or self.m_tSkillMap
		self.m_tBattleAttr = tData.m_tBattleAttr or self.m_tBattleAttr
	end

	--处理旧数据，策划可能更改配置
	local nSchool = self.m_oRole:GetSchool()
	local tConfList = _ctSkillConf[nSchool]
	local tConfMap = {}
	for _, tConf in pairs(tConfList) do 
		tConfMap[tConf.nID] = tConf
	end

	local tRemoveList = {}
	for nSkillID, tSkill in pairs(self.m_tSkillMap) do 
		if not tConfMap[nSkillID] then 
			table.insert(tRemoveList, nSkillID)
		end
	end
	for _, nSkillID in ipairs(tRemoveList) do 
		self.m_tSkillMap[nSkillID] = nil
		self:MarkDirty(true)
	end
	if self:IsDirty() then 
		self:UpdateAttr()
	end
	--暂时只删除旧的，不处理新增的

	self:OnLoaded()
end

function CSkill:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tSkillMap = self.m_tSkillMap
	tData.m_tBattleAttr = self.m_tBattleAttr
	return tData
end

function CSkill:GetType()
	return gtModuleDef.tSkill.nID, gtModuleDef.tSkill.sName
end

--加载数据完毕
function CSkill:OnLoaded()
	--默认激活第一个法术,5级
	local nSchool = self.m_oRole:GetSchool()
	local tConf = _ctSkillConf[nSchool][1]
	self:AddSkill(tConf.nID, 5)
end

function CSkill:OnSysOpen()
	self:ListReq()
end

function CSkill:IsSysOpen(bTips)
	return self.m_oRole.m_oSysOpen:IsSysOpen(21, bTips)
end

function CSkill:GetConf(nID) return ctSkillConf[nID] end
function CSkill:GetSkill(nID) return self.m_tSkillMap[nID] end
function CSkill:GetLevel(nID) return self.m_tSkillMap[nID].nLevel end
function CSkill:GetName(nID) return self:GetConf(nID).sName end
function CSkill:MaxLevel() return math.min(#ctSkillLevelConf, self.m_oRole:GetLevel()+5) end
function CSkill:GetSkillMap() return self.m_tSkillMap end
function CSkill:GetBattleAttr() return self.m_tBattleAttr end

--取主技能
function CSkill:GetMainSkill()
	local nSchool = self.m_oRole:GetSchool()
	local tConf = _ctSkillConf[nSchool][1]
	return self.m_tSkillMap[tConf.nID]
end

--激活技能
function CSkill:AddSkill(nID, nLevel)
	nLevel = nLevel or 0
	if self.m_tSkillMap[nID] then
		return
	end
	self.m_tSkillMap[nID] = {nID=nID, nLevel=nLevel}
	self:MarkDirty(true)

	if nLevel > 0 then
		local tData = {}	
		tData.tSkillLevelMap = {}		
		for i=1, nLevel do
			tData.tSkillLevelMap[i] = (tData.tSkillLevelMap[i] or 0) + 1
		end
		CEventHandler:OnSchoolSkillChange(self.m_oRole, tData)		
	end
	self:UpdateAttr()
end

--上线
function CSkill:Online()
	self:ListReq()
end

--银币变化事件
function CSkill:OnYinBiChange()
	if not self:IsSysOpen() then
		return
	end

	for nID, tSkill in pairs(self.m_tSkillMap) do
		if self:CheckCond(nID) then
			self:ListReq()
			break
		end
	end
end

--角色等级变化
function CSkill:OnRoleLevelChange(nLevel)
	local nSchool = self.m_oRole:GetSchool()
	local tConfList = _ctSkillConf[nSchool]
	for _, tConf in ipairs(tConfList) do
		if nLevel >= tConf.nLearn then
			self:AddSkill(tConf.nID)
		end
	end
	self:ListReq()
end

--更新结果属性
function CSkill:UpdateAttr()
	self.m_tBattleAttr = {}
	for nID, tSkill in pairs(self.m_tSkillMap) do
		local tConf = ctSkillConf[nID]
		if tConf.tBattleAttr[1][1] > 0 then
			for _, tAttr in ipairs(tConf.tBattleAttr) do
				self.m_tBattleAttr[tAttr[1]] = (self.m_tBattleAttr[tAttr[1]] or 0) + math.max(0, math.floor(tConf.fnEffVal(tSkill.nLevel)))
			end
		end
	end
	self:MarkDirty(true)
	self.m_oRole:UpdateAttr()
end

--技能列表请求
function CSkill:ListReq()
	local nSchool = self.m_oRole:GetSchool()
	local tConfList = _ctSkillConf[nSchool]
	local tMsg = {tList={}, nServerLevel=goServerMgr:GetServerLevel(self.m_oRole:GetServer())}
	for _, tConf in ipairs(tConfList) do
		local tInfo = {nID=tConf.nID, nMaxLevel=self:MaxLevel(), nLevel=0, nCost=0, nOwn=self.m_oRole:GetYinBi(), bOpen=false, bCanUpgrade=false}
		local tSkill = self.m_tSkillMap[tConf.nID]
		if tSkill then
			tInfo.bOpen = true
			tInfo.nLevel = tSkill.nLevel
			tInfo.nCost = self:UpgradeCost(tConf.nID)
			tInfo.bCanUpgrade = self:CheckCond(tConf.nID)
		end
		table.insert(tMsg.tList, tInfo)
	end
	self.m_oRole:SendMsg("SkillListRet", tMsg)
end

--取升级消耗
function CSkill:UpgradeCost(nID)
	local nLevel = self:GetLevel(nID)
	local nCost = ctSkillLevelConf[nLevel].nCost
	local nServerLevel = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	--由于所学习的技能等级超过服务器等级+5，继续学习将消耗正常学习的1.5倍
	if nLevel >= nServerLevel+5 then
		nCost = math.floor(nCost * 1.5)
	end
	return nCost
end

--升级条件检测
function CSkill:CheckCond(nID, bTips)
	if not self:IsSysOpen() then
		return false
	end
	local nLevel = self:GetLevel(nID)
	if nLevel >= self:MaxLevel() then
		if bTips then
			self.m_oRole:Tips("技能已达学习上限，你无法继续学习")
		end
		return false
	end

	local tSkill = self:GetSkill(nID)
	local tMainSkill = self:GetMainSkill()
	if tMainSkill ~= tSkill and tSkill.nLevel >= tMainSkill.nLevel then
		if bTips then
			self.m_oRole:Tips("次技能不能超过主技能等级，你无法继续学习")
		end
		return false
	end
	local nCost = self:UpgradeCost(nID)
	if self.m_oRole:ItemCount(gtItemType.eCurr, gtCurrType.eYinBi) < nCost then
		if bTips then	
			self.m_oRole:YinBiTips()
		end
		return false
	end
	return true
end

--技能升级请求
function CSkill:UpgradeReq(nID, bOnekey)
	if not self:IsSysOpen(true) then
		-- return self.m_oRole:Tips("门派技能系统未开启")
		return
	end

	local tSkill = self:GetSkill(nID)
	if not tSkill then
		return self.m_oRole:Tips("技能不存在")
	end

	local nLevel = self:GetLevel(nID)
	local nServerLevel = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	if nLevel >= nServerLevel+5 and not bOnekey then
		local sCont = "由于所学习的技能等级超过服务器等级+5，继续学习将消耗正常学习的1.5倍，是否继续学习？"
		local tMsg = {sCont=sCont, tOption={"取消", "确认"}, nTimeOut=30}
		goClientCall:CallWait("ConfirmRet", function(tData)
			if tData.nSelIdx == 1 then
				return
			end

			if not self:CheckCond(nID, true) then
				return
			end

			local nCost = self:UpgradeCost(nID)
			self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCost, "技能升级")

			tSkill.nLevel = tSkill.nLevel + 1
			self:MarkDirty(true)

			--更新玩家属性
			self:UpdateAttr()
			self:ListReq()

		end, self.m_oRole, tMsg)
		
	else
		if not self:CheckCond(nID, true) then
			return
		end
		local nCost = self:UpgradeCost(nID)
		self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCost, "技能升级", nil, nil, bOnekey)

		tSkill.nLevel = tSkill.nLevel + 1
		self:MarkDirty(true)

		--更新玩家属性
		if not bOnekey then
			self:UpdateAttr()
			self:ListReq()
			--门派技能升级的目标任务，此只处理单击升级的情况，一键升级的由一键升级函数里处理
			local tData = {}
			tData.tSkillLevelMap = {}
			tData.tSkillLevelMap[tSkill.nLevel] = (tData.tSkillLevelMap[tSkill.nLevel] or 0) + 1
			CEventHandler:OnSchoolSkillChange(self.m_oRole, tData)
		end

	end
	return true
end

--一键升级请求
function CSkill:OnekeyUpgradeReq()
	if not self:IsSysOpen(true) then
		-- return self.m_oRole:Tips("门派技能系统未开启")
		return
	end

	local tLessSrvLvList = {} --小于服务器等级+5
	local tMaxSrvLvList = {} --大于等于服务器等级+5

	local nServerLevel = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	for nID, tSkill in pairs(self.m_tSkillMap) do
		if tSkill.nLevel < self:MaxLevel() then
			if tSkill.nLevel < nServerLevel+5 then
				table.insert(tLessSrvLvList, tSkill)
			else
				table.insert(tMaxSrvLvList, tSkill)
			end
		end
	end

	local tSkillList = #tLessSrvLvList > 0 and tLessSrvLvList or tMaxSrvLvList
	if #tSkillList <= 0 then
		return self.m_oRole:Tips("没有可升级的技能")
	end

	local tTargetData = {}
	tTargetData.tSkillLevelMap = {}
	local function _fnUpgradeLoop()
		local tUpgradeResMap = {} --结果表

		local nCount = 0
		local nLoop = 2048 --防止死循环
		while nLoop > 0 do
			nLoop = nLoop - 1

			--优先学习等级最低的技能，如果等级相同则优先主技能
			table.sort(tSkillList, function(t1, t2)
				if t1.nLevel == t2.nLevel then
					return t1.nID < t2.nID
				end
				return t1.nLevel<t2.nLevel
			end)

			--升级
			local tSkill = tSkillList[1]
			local nOldSkillLevel = tSkill.nLevel
			if not self:UpgradeReq(tSkill.nID, true) then
				break
			end
			nCount = nCount + 1
			tUpgradeResMap[tSkill.nID] = tSkill.nLevel

			--用旧的等级和新等级记录每一级升级过程(写在这里主要是为了不在每一级升级成功给客户端发协议)
			tTargetData.tSkillLevelMap[tSkill.nLevel] = (tTargetData.tSkillLevelMap[tSkill.nLevel] or 0) + 1
			
			--如果是小于服务器等级+5的技能升级,则移除已达到服务器等级+5的技能
			if tSkillList == tLessSrvLvList then
				if tSkill.nLevel >= nServerLevel+5 then
					table.remove(tSkillList, 1)
				end
			end

			--处理完成
			if #tSkillList <= 0 then
				break
			end
		end

		--有技能升级成功
		if nCount > 0 then
			self:UpdateAttr()
			self:ListReq()

			for nID, nLevel in pairs(tUpgradeResMap) do
				local tSkillConf = ctSkillConf[nID]
				self.m_oRole:Tips(string.format("%s技能成功升级到了%d级", tSkillConf.sName, nLevel))
			end
	        self.m_oRole.m_oKnapsack:SyncCachedMsg()
		end
	end

	if tSkillList == tMaxSrvLvList then
		local sCont = "由于所学习的技能等级超过服务器等级+5，继续学习将消耗正常学习的1.5倍，是否继续学习？"
		local tMsg = {sCont=sCont, tOption={"取消", "确认"}, nTimeOut=30}
		goClientCall:CallWait("ConfirmRet", function(tData)
			if tData.nSelIdx == 1 then
				return
			end
			_fnUpgradeLoop()
			CEventHandler:OnSchoolSkillChange(self.m_oRole, tTargetData)
		end, self.m_oRole, tMsg)

	else
		_fnUpgradeLoop()
		CEventHandler:OnSchoolSkillChange(self.m_oRole, tTargetData)
	end

end

--战斗技能映射
function CSkill:GetBattleSkillMap()
	local tSkillMap = {}
	for nID, tSkill in pairs(self.m_tSkillMap) do
		local tSkillConf = ctSkillConf[nID]
		if tSkillConf.nType ~= gtSKT.eFZ then
			tSkillMap[nID] = {nLevel=tSkill.nLevel, sName=self:GetName(nID)}
		end
	end
	return tSkillMap

	-- local tSkillMap = {}
	-- local nSchool = self.m_oRole:GetSchool()
	-- local tSkillList = _ctSkillConf[nSchool]
	-- for _, tSkillConf in pairs(tSkillList) do
	-- 	if tSkillConf.nType ~= gtSKT.eFZ then
	-- 		tSkillMap[tSkillConf.nID] = {nLevel=10, sName=self:GetName(tSkillConf.nID)}
	-- 	end
	-- end
	-- return tSkillMap
end

--制造附魔符
function CSkill:ManufactureItemReq(nID)
	local tItemConf = ctFuMoSkillConf[self.m_oRole:GetSchool()]
	if not tItemConf then
		return 
	end
	print("self.m_oRole:GetSchool()", self.m_oRole:GetSchool())
	local nFuMoSkillID = tItemConf.nSkillID
	if not self:GetConf(nFuMoSkillID) then
		return self.m_oRole:Tips("配置不存在")
	end
	if nID ~= nFuMoSkillID then
		return self.m_oRole:Tips("该技能不制造附魔符")
	end
	if self.m_tSkillMap[nFuMoSkillID].nLevel < self:GetConf(nFuMoSkillID).nLearn then
		return self.m_oRole:Tips("该技能需要" .. self:GetConf(nFuMoSkillID).nLearn .. "等级才能使用")
	end
	local nCostVitality = tItemConf.eProduceCostVitalityFormula(self.m_tSkillMap[nFuMoSkillID].nLevel)

	if self.m_oRole:GetVitality() < nCostVitality then
		return self.m_oRole:Tips("活力不足")
	end
	self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eVitality, nCostVitality, "制造附魔符消耗")
	local nStar = tItemConf.eItemLevelFormula(self.m_tSkillMap[nFuMoSkillID].nLevel)
	nStar = math.modf(nStar)
	local nItemID  = tItemConf["nSubProducts" .. nStar]
	if nItemID then
		self.m_oRole:AddItem(gtItemType.eProp, nItemID, 1, "附魔符制造获得")
	end
end

--计算技能评分
function CSkill:CalcSkillScore()
	local nTotalLevel = 0	
	for nSkillID, tSkill in pairs(self.m_tSkillMap) do
		nTotalLevel = nTotalLevel + tSkill.nLevel
	end
    return (nTotalLevel * 150)
end

