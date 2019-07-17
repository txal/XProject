--宠物模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxLife = 60000 --宠物寿命上限
local nForeverLife = -999
local tEquType = 14		--装备
local nCurType =  5		--虚拟货币类型
local nShenShouZhiLingID = 19012
function CPet:Ctor(oRole)
	--不用保存到数据库
	self.m_oRole = oRole

	--保存到数据库
	self.m_oPetMap = {} 	--宠物ID对象映射{[id]=obj,...}
	self.m_oPetSMap = {}	--宠物找回
	-- self.m_PetEquitList = {} 	--宠物身上装备列表 {[pos]= itemId,}
	self.m_nExpansionTimes = 0 	--扩充的次数
	-- self.m_tHideAttr = {}       --隐藏属性(1命中率;2闪避率;3暴击率;4抗暴率)
	-- self.m_tWearEqu = {}	
	self.m_bButton = false
	self.m_oPetXiSui = false
	self.m_nXiSuiTime = 0	     --洗髓时间间隔
	self.m_FastPetPos = 0
	self.m_nTmpPetPowerSum = 0
	self.m_bXiSui = false       --洗髓出变异宝宝标记
	self.m_bFirstGetPet = false
	self.m_nRecruitLevel = 0

	self.m_tYuShouData = {}             --御兽数据
	self.m_tYuShouData.nLevel = 0
	self.m_tYuShouData.nExp = 0
	self.m_tYuShouData.tAttrList = {}
end

function CPet:LoadData(tData)
	if not tData then
		return
	end
	--self.m_oPetMap = tData.m_oPetMap or {}
	self:InitPetData(tData.m_oPetMap)
	for nPos, tPetData in pairs(self.m_oPetMap) do
		if ctPetInfoConf[tPetData.nId] then
			tPetData.life = math.min(nMaxLife, tPetData.life)
			if not tPetData.tBaseAttr then
				tPetData.tBaseAttr = {}
				for _, v in pairs(gtBAT) do tPetData.tBaseAttr[v] = 0 end
				self:MarkDirty(true)
			end
			if not tPetData.tSKillList and tPetData.tKillList then
				tPetData.tSKillList = tPetData.tKillList
				tPetData.tKillList = nil
				self:MarkDirty(true)
			end
			if not tPetData.nDQBlood then
				tPetData.nDQBlood = tPetData.nDQBlood or tPetObj.tBaseAttr[gtBAT.eQX]
			end
			if not tPetData.ratingLevel then
				tPetData.ratingLevel = self:CalculatenPetLv(tPetData.nFighting)
				self:MarkDirty(true)
			end
		else
			LuaTrace("宠物配置已删除:", tPetData.nId)
			self.m_oPetMap[nPos] = nil
			self:MarkDirty(true)
		end
	end

	self.m_oPetSMap = tData.m_oPetSMap or {}
	self.m_PetEquitList = tData.m_PetEquitList or {}
	self.m_nExpansionTimes = tData.m_nExpansionTimes or 0
	self.m_bButton = tData.m_bButton or false
	self.m_nTmpPetPowerSum = tData.m_nTmpPetPowerSum or 0
	self.m_bFirstGetPet = tData.m_bFirstGetPet or false
	self.m_nRecruitLevel = tData.m_nRecruitLevel or 0

	self.m_tYuShouData = tData.m_tYuShouData or self.m_tYuShouData
	-- self:InitPetData(tData.m_oPetMap)
end

function CPet:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	--先把宠物仓库里的宠物信息清掉,里面可能有宠物装备信息
	self.m_oPetSMap = {}
	tData.m_oPetSMap = self.m_oPetSMap
	tData.m_nExpansionTimes = self.m_nExpansionTimes
	tData.m_PetEquitList = self.m_PetEquitList
	tData.m_bButton = self.m_bButton
	tData.m_nTmpPetPowerSum = self.m_nTmpPetPowerSum
	tData.m_bFirstGetPet = self.m_bFirstGetPet
	tData.m_nRecruitLevel = self.m_nRecruitLevel
	tData.m_oPetMap = self:HandleData(self.m_oPetMap)
	tData.m_tYuShouData = self.m_tYuShouData
	return tData
end

function CPet:GetType()
	return gtModuleDef.tPet.nID, gtModuleDef.tPet.sName
end

--玩家上线
function CPet:Online()
	self:AttrListReq()
	for nPos,tPetObj in pairs(self.m_oPetMap) do
		self:PetPlanInfoReq(nPos)
	end
end

--保存数据处理
function CPet:HandleData(tPetMap)
	local tPetList = {}
	for _, tPet in pairs(tPetMap or {}) do
		local tPetInfo = {}
		tPetInfo.sName = tPet.sName
		tPetInfo.nPetLv = tPet.nPetLv
		tPetInfo.nId 	= tPet.nId
		tPetInfo.nPos = tPet.nPos
		tPetInfo.nZy 	= tPet.nZy
		tPetInfo.exp = tPet.exp
		tPetInfo.qld = tPet.qld
		tPetInfo.nPetType = tPet.nPetType
		tPetInfo.nPlayerId = tPet.nPlayerId
		tPetInfo.status = tPet.status
		tPetInfo.nAdvanced = tPet.nAdvanced
		tPetInfo.sModelNumber = tPet.sModelNumber
		tPetInfo.czl = tPet.czl
		tPetInfo.life = tPet.life
		tPetInfo.nDQBlood = tPet.nDQBlood
		tPetInfo.nDQWorkHard = tPet.nDQWorkHard
		tPetInfo.jnpf = tPet.jnpf
		tPetInfo.nFighting = tPet.nFighting
		tPetInfo.ratingLevel = tPet.ratingLevel
		tPetInfo.tBaseAttr = tPet.tBaseAttr
		tPetInfo.tUmQfcAttr = tPet.tUmQfcAttr
		tPetInfo.tCurQfcAttr = tPet.tCurQfcAttr
		tPetInfo.nAutoPointState = self:GetAutoAddPoinState(tPet)
		tPetInfo.tSKillList = tPet.tSKillList
		tPetInfo.tAddPointList = tPet.tAddPointList
		tPetInfo.tEquitList = self:PetEquitData(tPet.tEquitList)
		tPetInfo.tHfsk = tPet.tHfsk
		tPetInfo.tPetAutoAddPointList = self:GetAutoAddPointList(tPet)
		tPetInfo.tRevive = tPet.tRevive

		tPetInfo.nManualSkill = tPet.nManualSkill
		tPetInfo.nAutoInst =  tPet.nAutoInst
		tPetInfo.nAutoSkill = tPet.nAutoSkill
		tPetInfo.nBattleCount = tPet.nBattleCount 
		table.insert(tPetList, tPetInfo)
	end
	return tPetList
end

function CPet:PetEquitData(tEquitList)
	local tPetEquList = {}
	for nEquipPartType, oPetEqu in pairs(tEquitList or {}) do
		tPetEquList[nEquipPartType] = oPetEqu:SaveData()
	end
	return tPetEquList
end

function CPet:InitPetData(tPetMap)
	for _, tPet in pairs(tPetMap or {}) do
		self:LoadEquitData(tPet)
		--觉醒数据
		if not tPet.tRevive then 
			tPet.tRevive = {}
			tPet.tRevive.nLevel = 0
			tPet.tRevive.nExp = 0
			self:MarkDirty(true)
		end
		self.m_oPetMap[tPet.nPos] = tPet
	end
	self:MarkDirty(true)
end

function CPet:LoadEquitData(tPet)
	for nEquipPartType, tPetEquData in pairs(tPet.tEquitList or {}) do
		local oPetEqu = self.m_oRole.m_oKnapsack:CreateProp(tPetEquData.m_nID, nEquipPartType)
		if oPetEqu then
			oPetEqu:LoadData(tPetEquData)
			tPet.tEquitList[nEquipPartType] = oPetEqu
		end
	end
end

function CPet:GetPetByPos(nPos) return self.m_oPetMap[nPos] end
-- tPropExt.bFlag
--添加宠物对象
function CPet:AddPetObj(petId,nNum, tPropExt)
	tPropExt = tPropExt or {}
	print("添加宠物对象")
	assert(nNum==1, "宠物只能加单个")
	if petId <= 0 then
		return self.m_oRole:Tips("宠物id错误")
	end
	local tPet = ctPetInfoConf[petId]
	if not tPet then
		return self.m_oRole:Tips("配置文件不存在")
	end

	local tPetLenlist =  self:GetEmptyPos(nNum)
	if #tPetLenlist < nNum then
		self:SendPetMail(petId)
	else
		local nPos = tPetLenlist[1]	
		local tPetTable = self:CreatePetObj(tPet, nPos)
		self.m_oPetMap[nPos] = tPetTable
		

		self:PetScoreChange()
		self:PetInfoChangeEvent()
		self:FirstGetPetCheck(tPetTable)
		self:MarkDirty(true)

		local tBattlePet = self:GetCombatPet()
		--如果当前没有参战宠物，新来的默认参战
		if tPropExt.bPropUse then
			if ctPetPropUseConf[petId] then
				self:UsePropPetHandle(tPetTable)
				if tPropExt.bFlag then
					self:CombatReq(petId, nPos, 2, false)
				end
			else
				self:PetChangeSend(tPetTable, nPos, 1)
			end
		else
			self:PetChangeSend(tPetTable, nPos, 1)
		end
		if not tBattlePet then
			self:CombatReq(petId, nPos, 2, false)
		end
		local nMaxFighting = self:MaxFighting()
		self.m_oRole:PushAchieve("宠物战力",{nValue = nMaxFighting})
	end
	return true
end

--如果宠物栏已经满了通过邮件形式发送给玩家
function CPet:SendPetMail(nPetID)
	assert(ctPetInfoConf[nPetID], string.format("宠物ID(%d)错误", nPetID))
	local tItemList = {{gtItemType.ePet,nPetID,1}} 
	CUtil:SendMail(self.m_oRole:GetServer(), "宠物栏已满", "宠物栏已满，请及时领取邮件", tItemList, self.m_oRole:GetID())
	self.m_oRole:Tips("宠物栏已满，请及时清理宠物栏")
end

--如果是第一次获得宠物,那么将自动设置加点操作
function CPet:FirstGetPetCheck(tPet, bFlag)
	if not self.m_bFirstGetPet or bFlag then
		local tPetCfg = ctPetInfoConf[tPet.nId]
		if not tPetCfg then return self.m_oRole:Tips("宠物配置不存在") end
		local tAddPointList = {}

		--这里只能用ipairs遍历,保持顺序s
		for _, tValue in ipairs(tPetCfg.tPushingPoint or {}) do
			table.insert(tAddPointList, tValue[1])
		end
		self:PetAutoAddPointReq(gtPetAutoPointState.eAutoState, tPet.nPos, tAddPointList)
	end
end

--获取剩余位置
function CPet:GetEmptyPos(nNum)
	if nNum <= 0 then
		return 
	end
	local tList = {}
	local nCount = 0
	local nEndPos = getCarryCap.eDefaultCcarry + self.m_nExpansionTimes * getCarryCap.eExpansionTimes 
	for nBegPos = 1, nEndPos, 1 do
		if self.m_oPetMap[nBegPos] == nil then
			table.insert(tList, nBegPos)
			nCount = nCount + 1
		end
		if nCount >= nNum then
			break
		end
	end
	return tList
end

--创建及初始化宠物对象
function CPet:CreatePetObj(tPetItem, nPos)
	local Item = tPetItem
	local ItemTb = {}
	ItemTb.sName = Item.sName

	local itemExp = ctPetLevelConf[Item.nPetLv].nNeedExp
	if not itemExp then
		print("配置文件不存在")
		return 
	end
	--策划要求所有宠物初始为零级
	--ItemTb.nPetLv = Item.nPetLv
	ItemTb.nPetLv = 0
	if bXiSuiState then
		ItemTb.nPetLv = Item.nPetLv
	end
	ItemTb.nId 	= Item.nPetId
	ItemTb.nPos = nPos
	ItemTb.nZy 	= false
	ItemTb.exp = 0
	ItemTb.qld = 0
	ItemTb.nPetType = Item.nPetType
	ItemTb.nPlayerId = self.m_oRole:GetID()
	ItemTb.status = 1
	ItemTb.nAdvanced = 0
	ItemTb.sModelNumber = Item.sModelNumber

	ItemTb.tRevive = {}
	ItemTb.tRevive.nLevel = 0
	ItemTb.tRevive.nExp = 0
	
	ItemTb.czl = self:GetGrowthRate(Item)
	self:PetBasicAttr(Item, ItemTb)
	self:PetAttrHandle(ItemTb, Item)
	self:PetClacAttr(ItemTb)
	ItemTb.nDQBlood = ItemTb.tBaseAttr[gtBAT.eQX]
	ItemTb.nDQWorkHard = ItemTb.tBaseAttr[gtBAT.eMF]

	--技能列表
	ItemTb.tSKillList = self:PetHandleSkills(Item.tMskill, Item.tTskill)
	ItemTb.tBaseAttr[gtBAT.eMZL] = 100
	ItemTb.tBaseAttr[gtBAT.eSBL] = 5
	ItemTb.tBaseAttr[gtBAT.eFSSB] = 0
	ItemTb.tBaseAttr[gtBAT.eKBL] = 3

	self:PetInfoChange(ItemTb)
	ItemTb.ratingLevel = self:CalculatenPetLv(ItemTb.nFighting)

	--宠物加点列表
	ItemTb.tAddPointList = {0,0,0,0,0}

	--加点方案设置
	ItemTb.tPetAutoAddPointList = {0,0,0,0,0}

	--是否启动自动加点状态
	ItemTb.nAutoPointState = 2

	--初始化装备列表
	ItemTb.tEquitList = {}

	return ItemTb
end

function CPet:GetGrowthRate(tPet)
	if tPet.nPetType == getPetType.eYS or tPet.nPetType == getPetType.eBB then
		return tPet.nChengZhangLv * (98 + math.random(4))/100
	else
		return tPet.nChengZhangLv
	end
end

function CPet:PetBasicAttr(Item, ItemTb)
	if Item.nPetType == getPetType.eYS or Item.nPetType == getPetType.eBB then
		-- --基本属性(体质,魔力,力量,耐力,敏捷)
		ItemTb.tBaseAttr = {}
		
		local Assigned = 50
		local pValue = math.floor(math.random(0,Assigned) *2/5)
		ItemTb.tBaseAttr[gtMAT.eTZ] = 10 + ItemTb.nPetLv + pValue 
		Assigned = Assigned - pValue

		pValue = math.floor(math.random(0,Assigned) *2/4)
		ItemTb.tBaseAttr[gtMAT.eML] = 10 + ItemTb.nPetLv + pValue 
		Assigned = Assigned - pValue

		pValue = math.floor(math.random(0,Assigned) *2/3)
		ItemTb.tBaseAttr[gtMAT.eLL] = 10 + ItemTb.nPetLv + pValue 
		Assigned = Assigned - pValue

		pValue = math.floor(math.random(0,Assigned) *2/2)
		ItemTb.tBaseAttr[gtMAT.eNL] = 10 + ItemTb.nPetLv + pValue 
		Assigned = Assigned - pValue
		ItemTb.tBaseAttr[gtMAT.eMJ] = 10 + ItemTb.nPetLv + Assigned 

		--实际值=基础值*(90+random(21))/100-等级*50
		ItemTb.life = Item.nLife * (90 + math.random(0,21))/100 - ItemTb.nPetLv * 50
	else
		ItemTb.tBaseAttr = {}
		ItemTb.tBaseAttr[gtMAT.eTZ] = 20 
		ItemTb.tBaseAttr[gtMAT.eML] = 20 
		ItemTb.tBaseAttr[gtMAT.eLL] = 20 
		ItemTb.tBaseAttr[gtMAT.eNL] = 20 
		ItemTb.tBaseAttr[gtMAT.eMJ] = 20 
		--神兽，圣兽直接为基础值
		ItemTb.life = Item.nLife
	end
end

--不同宠物进行不同的属性计算
function CPet:PetAttrHandle(ItemTb, tPet)
--上线物质计算,当前物质计算
	if tPet.nPetType == getPetType.eYS or tPet.nPetType == getPetType.eBB then
		local tSlist1 = {}
		local tDlist2 = {}
		local nSx = 0
		local nDq = 0
		nSx = math.floor(tPet.nGongJiZiZhi * (0.87 + math.random(0,20)/100))
		nDq = math.floor(tPet.nGongJiZiZhi 	* (0.82 + math.random(0,7)/100))
		if nDq >= nSx then
			nDq =nSx
		end	
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nFangYuZiZhi * (0.87 + math.random(0,20)/100))
		nDq = math.floor(tPet.nFangYuZiZhi * (0.82 + math.random(0,7)/100))
		if nDq >= nSx then
			nDq = nSx
		end

		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nTiLiZiZhi * (0.87 + math.random(0,20)/100))
		nDq = math.floor(tPet.nTiLiZiZhi * (0.82 + math.random(0,7)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nFaLiZiZhi * (0.87 + math.random(0,20)/100))
		nDq = math.floor(tPet.nFaLiZiZhi * (0.82 + math.random(0,7)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nSuDuZiZhi * (0.87 + math.random(0,20)/100))
		nDq = math.floor(tPet.nSuDuZiZhi * (0.82 + math.random(0,7)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		ItemTb.tUmQfcAttr = tSlist1
		ItemTb.tCurQfcAttr = tDlist2
	elseif tPet.nPetType == getPetType.EBY and tPet.nPetLv <= 45 then
		local tSlist1 = {}
		local tDlist2 = {}
		local nSx = 0
		local nDq = 0
		nSx = math.floor(tPet.nGongJiZiZhi  * (1.05 + math.random(0,6)/100))
		nDq = math.floor(tPet.nGongJiZiZhi 	* (0.98 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq =nSx
		end	
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nFangYuZiZhi 	* (1.05 + math.random(0,6)/100))
		nDq = math.floor(tPet.nFangYuZiZhi	* (0.98 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nTiLiZiZhi * (1.05 + math.random(0,6)/100))
		nDq = math.floor(tPet.nTiLiZiZhi * (0.98 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq
		
		nSx = math.floor(tPet.nFaLiZiZhi * (1.05 + math.random(0,6)/100))
		nDq = math.floor(tPet.nFaLiZiZhi * (0.98 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nSuDuZiZhi  * (1.05 + math.random(0,6)/100))
		nDq = math.floor(tPet.nSuDuZiZhi * (0.98 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		ItemTb.tUmQfcAttr = tSlist1
		ItemTb.tCurQfcAttr = tDlist2
	elseif tPet.nPetType == getPetType.EBY and tPet.nPetLv > 45 then
		local tSlist1 = {}
		local tDlist2 = {}
		local nSx = 0
		local nDq = 0
		nSx = math.floor(tPet.nGongJiZiZhi 	* (1.03 + math.random(0,6)/100))
		nDq = math.floor(tPet.nGongJiZiZhi 		* (0.95 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq =nSx
		end	
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nFangYuZiZhi 	* (1.03 + math.random(0,6)/100))
		nDq = math.floor(tPet.nFangYuZiZhi	* (0.95 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nTiLiZiZhi * (1.03 + math.random(0,6)/100))
		nDq = math.floor(tPet.nTiLiZiZhi * (0.95 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq
		
		nSx = math.floor(tPet.nFaLiZiZhi 	* (1.03 + math.random(0,6)/100))
		nDq = math.floor(tPet.nFaLiZiZhi	* (0.95 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		nSx = math.floor(tPet.nSuDuZiZhi * (1.03 + math.random(0,6)/100))
		nDq = math.floor(tPet.nSuDuZiZhi * (0.95 + math.random(0,3)/100))
		if nDq >= nSx then
			nDq = nSx
		end
		tSlist1[#tSlist1+1] = nSx
		tDlist2[#tDlist2+1] = nDq

		ItemTb.tUmQfcAttr = tSlist1
		ItemTb.tCurQfcAttr = tDlist2
	else
		--圣兽和神兽上线物质,当前物资直接为基础值
		local tSlist = {}
		local tDlist = {}
		tSlist[#tSlist+1] = tPet.nGongJiZiZhi 
		tSlist[#tSlist+1] = tPet.nFangYuZiZhi
		tSlist[#tSlist+1] = tPet.nTiLiZiZhi 
		tSlist[#tSlist+1] = tPet.nFaLiZiZhi
		tSlist[#tSlist+1] = tPet.nSuDuZiZhi 

		tDlist[#tDlist+1] = tPet.nGongJiZiZhi
		tDlist[#tDlist+1] = tPet.nFangYuZiZhi
		tDlist[#tDlist+1] = tPet.nTiLiZiZhi
		tDlist[#tDlist+1] = tPet.nFaLiZiZhi
		tDlist[#tDlist+1] = tPet.nSuDuZiZhi 

		ItemTb.tUmQfcAttr = tSlist
		ItemTb.tCurQfcAttr = tDlist
	end

end

function CPet:PetClacAttr(ItemTb)

	local tOldBaseAttr = table.DeepCopy(ItemTb.tBaseAttr)
	--计算结果属性
	--气血--INT((体力资质*(等级*5+等级*等级/100)+体质*5*成长率)/1000+90)
	ItemTb.tBaseAttr[gtBAT.eQX] = math.floor(((ItemTb.tCurQfcAttr[3] * (ItemTb.nPetLv * 5 + ItemTb.nPetLv * ItemTb.nPetLv/100) + ItemTb.tBaseAttr[gtMAT.eTZ] * 5 * ItemTb.czl)/1000 + 90))

	--INT(等级*10+魔力*2+力量*2)
	ItemTb.tBaseAttr[gtBAT.eMF] = math.floor(ItemTb.nPetLv * 10 + ItemTb.tBaseAttr[gtMAT.eML] * 2 + ItemTb.tBaseAttr[gtMAT.eLL] * 2)

	--INT(((攻击资质*等级*2*(成长率/2000+0.7)+力量*0.75*成长率)/1000+50)*4/3)
	ItemTb.tBaseAttr[gtBAT.eGJ] = math.floor((((ItemTb.tCurQfcAttr[1] * ItemTb.nPetLv * 2 * (ItemTb.czl/2000 + 0.7) + ItemTb.tBaseAttr[gtMAT.eLL] * 0.75*ItemTb.czl)/1000 + 50) * 4/3))

	--INT((防御资质*等级*1.75*(成长率/2000+0.7)+耐力*1.5*成长率)/1000)
	ItemTb.tBaseAttr[gtBAT.eFY] = math.floor((ItemTb.tCurQfcAttr[2] * ItemTb.nPetLv * 1.75  * (ItemTb.czl/2000 + 0.7) + ItemTb.tBaseAttr[gtMAT.eNL] * 1.5 * ItemTb.czl)/1000+15)
	--INT(速度资质*(体质*10%+魔力*10%+力量*10%+耐力*10%+敏捷*70%)/1000*(成长率/2000+0.5))
	ItemTb.tBaseAttr[gtBAT.eSD]= math.floor((ItemTb.tCurQfcAttr[5] * (ItemTb.tBaseAttr[gtMAT.eTZ] * 0.1 + ItemTb.tBaseAttr[gtMAT.eML] * 0.1 + ItemTb.tBaseAttr[gtMAT.eLL] * 0.1 + ItemTb.tBaseAttr[gtMAT.eNL] * 0.1 + ItemTb.tBaseAttr[gtMAT.eMJ] * 0.7)/1000 * (ItemTb.czl/2000 + 0.5)))
	--INT((体质*10%+魔力*70%+力量*40%+耐力*10%)*(成长率/2000+0.6)+法力资质/1000*等级)
	ItemTb.tBaseAttr[gtBAT.eLL] = math.floor(((ItemTb.tBaseAttr[gtMAT.eTZ] * 0.1 + ItemTb.tBaseAttr[gtMAT.eML] * 0.7 + ItemTb.tBaseAttr[gtMAT.eLL] * 0.4 + ItemTb.tBaseAttr[gtMAT.eNL] * 0.1) * (ItemTb.czl /2000 + 0.6) + ItemTb.tCurQfcAttr[4]/1000 * ItemTb.nPetLv))

	local nGrowthID = self:GetReviveGrowthID()
	local nReviveRatio = ctRoleGrowthConf[nGrowthID].nParam
	local nReviveLevel = ItemTb.tRevive.nLevel
	local nReviveAdd = nReviveRatio * nReviveLevel 
	
	local tAttrType = {gtBAT.eQX, gtBAT.eMF, gtBAT.eGJ, gtBAT.eFY, gtBAT.eSD, gtBAT.eLL}
	for _, nAttrID in pairs(tAttrType) do
		ItemTb.tBaseAttr[nAttrID] = math.floor(ItemTb.tBaseAttr[nAttrID] * (ctPetEtcConf[1].nAttrAdj + nReviveAdd))
	end
	--没打过战斗的，一直是满血蓝
	if (ItemTb.nBattleCount or 0) == 0 then
		ItemTb.nDQBlood = ItemTb.tBaseAttr[gtBAT.eQX]
		ItemTb.nDQWorkHard = ItemTb.tBaseAttr[gtBAT.eMF]
	end

end

function CPet:GetPetBaseAttr(nPos)
	if not self.m_oPetMap[nPos] then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	return self.m_oPetMap[nPos].tBaseAttr
end

--技能评分计算,包括护符技能
function CPet:SkillsScore(tPet)
	local jnpf = 0
	local petnPetLv = 0
	for _,tSkill in ipairs(tPet.tSKillList or {}) do
		if ctPetSkillConf[tSkill.nId] and (ctPetSkillConf[tSkill.nId].nSkType == getPetSkillsClassify.eAdvanced or ctPetSkillConf[tSkill.nId].nSkType == getPetSkillsClassify.eSpecial) then
			jnpf = jnpf + 600
		elseif ctPetSkillConf[tSkill.nId] and ctPetSkillConf[tSkill.nId].nSkType == getPetSkillsClassify.eLowlevel then
			jnpf = jnpf + 300
		end
	end

	for _, nSkillID in ipairs(tPet.tHfsk or {}) do
		if ctPetSkillConf[nSkillID] and (ctPetSkillConf[nSkillID].nSkType == getPetSkillsClassify.eAdvanced or ctPetSkillConf[nSkillID].nSkType == getPetSkillsClassify.eSpecial) then
			jnpf = jnpf + 600
		elseif ctPetSkillConf[nSkillID] and ctPetSkillConf[nSkillID].nSkType == getPetSkillsClassify.eLowlevel then
			jnpf = jnpf + 300
		end
	end
	return jnpf
end

function CPet:PetSum(tList)
	local nValue = 0
	for key, nVa  in ipairs(tList) do
		nValue = nValue + nVa 
	end
	return nValue
end

--计算宠物评分级别
function CPet:CalculatenPetLv(SkillsScore)
	print("SkillsScore----->", SkillsScore)
	local jnpf = SkillsScore
	local petnPetLv
	if jnpf >= 19500 then
		petnPetLv = "SSSS"
	elseif jnpf >= 18000 and jnpf < 19500 then
		petnPetLv = "SSSS"
	elseif jnpf >= 15500 and jnpf < 18000 then
		petnPetLv = "SSS"
	elseif jnpf >= 13500 and jnpf < 15500 then
		petnPetLv = "SS"
	elseif jnpf >= 12500 and jnpf < 13500 then
		petnPetLv = "A"
	elseif jnpf >= 11500 and jnpf < 12500 then
		petnPetLv = "B"
	elseif jnpf >= 10500 and jnpf < 11500 then
		petnPetLv = "C"
	elseif jnpf >= 9500 and jnpf < 10500 then
		petnPetLv = "D"
	elseif jnpf < 9500 then
		petnPetLv = "E"
	end
	return petnPetLv
end

function CPet:GetGrade(nPos)
	local tPet = self.m_oPetMap[nPos]
	if not tPet then
		return ""
	end
	return tPet.ratingLevel
end

--洗髓处理
function CPet:XiSuiHandle(tPet, tPetCfg)
	tPet.czl = tPetCfg.nChengZhangLv * (98 + math.random(4))/100
	tPet.nPetType = tPetCfg.nPetType
	self:PetAttrHandle(tPet, tPetCfg)

	tPet.tSKillList = self:PetHandleSkills(tPetCfg.tMskill, tPetCfg.tTskill)


	self:PetInfoChange(tPet, true)
end

function CPet:PetInfoChange(tPet, bXiSuiState)
	--技能评分计算
	--∑当前资质*10+∑技能评分*100+成长率*100000+等级*500+∑宠物装备属性
	local zZSum = self:PetSum(tPet.tCurQfcAttr)
	local nSkillScore = self:SkillsScore(tPet)
	tPet.jnpf = math.floor(zZSum*10 + self:SkillsScore(tPet) * 100 + (tPet.czl/1000) * 100000  + tPet.nPetLv * 500) + self:AddPetEquScore(tPet)
	--战力计算
	tPet.nFighting = zZSum +  self:SkillsScore(tPet) + 5000
	tPet.ratingLevel = self:CalculatenPetLv(tPet.nFighting)

	if not bXiSuiState then
		--事件(战力就是总评分)
		self:PetScoreChange()
		self:PetInfoChangeEvent()
	end
	local nPos = tPet.nPos
	if self.m_oPetMap[nPos] then
		local nMaxFighting = self:MaxFighting()
		self.m_oRole:PushAchieve("宠物战力",{nValue = nMaxFighting})
	end
end

function CPet:PetInfoChangeEvent()
	self.m_oRole:UpdateActGTPetPower()
	self.m_oRole:UpdateActGTPetSkillPower()
end

--添加宠物装备属性评分战力
function CPet:AddPetEquScore(tPet)
	assert(tPet, "宠物数据错误")
	local tBattleAttr = {}
	local nScore = 0
	for _, oPetEqu in pairs(tPet.tEquitList or {}) do
		--TODD,只有头盔跟项圈有属性加成，其他都是技能,资质
		if oPetEqu:GetConf().nEquipPartType == gtPetEquPart.eCollar or oPetEqu:GetConf().nEquipPartType == gtPetEquPart.eArmor then
			for nAttrID, nValue in pairs(oPetEqu.m_PetEquAttrList or {}) do
				tBattleAttr[nAttrID] = (tBattleAttr[nAttrID] or 0) +  nValue
			end
		end
	end

	for nAttrID, nAttrVal in pairs(tBattleAttr) do 
		nScore = nScore + CUtil:CalcAttrScore(nAttrID, nAttrVal)
	end
	return nScore
end

--技能处理及及初始化  --改动此函数时注意检查下，竞技场机器人模块有使用到
function CPet:PetHandleSkills(Mskills, tTskill)
	local skillTb = {}
	if Mskills then
		for k ,skillsId in ipairs(Mskills) do
			if ctPetSkillConf[skillsId[1]] then
				skillTb[#skillTb+1] = { nId = skillsId[1], nFalg = false}
			end	
		end
	end

	if tTskill then
		for _, stb in ipairs(tTskill) do
			if ctPetSkillConf[stb[1]] then
				local ret = stb[2]
				local rdValue = math.random(1,100)
				if ret >= rdValue then
					skillTb[#skillTb+1] = {nId = stb[1], nFalg = false}
				end
			end
		end
	end
	return skillTb
end

--宠物属性页面请求
function CPet:AttrListReq()
	local tMsg = {tPetObjList = {}, nMaxLimit = self:GetPetMaxCpy(), nBattlePos = self:PetCombat() or 0,
	bButton = self.m_nButton or false, nRecruitLevel = self.m_nRecruitLevel}	
	for nKey, tPetObj in pairs(self.m_oPetMap) do
		if tPetObj then
			local tPetObj = self:PetInfoHandle(tPetObj)
			tMsg.tPetObjList[#tMsg.tPetObjList+1] = tPetObj
		end
	end
	self.m_oRole:SendMsg("PetAttrListRet", tMsg)
end

function CPet:PetInfoHandle(tPetObj)
		local tPetList = {}
		local tInfo = {}
		if tPetObj then
			tInfo.nID = tPetObj.nId
			tInfo.nPos = tPetObj.nPos
			tInfo.sName = tPetObj.sName
			tInfo.sRatings = tPetObj.ratingLevel
			tInfo.nType = tPetObj.nPetType
			tInfo.nScore = tPetObj.jnpf	--策划要求改为显示总评分而不是技能评分
			--tInfo.nScore = tPetObj.nFighting
			tInfo.nBlood = tPetObj.tBaseAttr[gtBAT.eQX]
			tInfo.nWorkHard = tPetObj.tBaseAttr[gtBAT.eMF]
			tInfo.nExp = tPetObj.exp
			tInfo.nStatus = tPetObj.status
			tInfo.nLevel = tPetObj.nPetLv
			tInfo.nQld = tPetObj.qld
			tInfo.nPlayerId = tPetObj.nPlayerId
			tInfo.nModelNumber = tPetObj.sModelNumber
			tInfo.nDQBlood = tPetObj.nDQBlood
			tInfo.nDQWorkHard = tPetObj.nDQWorkHard
			tInfo.nZy = tPetObj.nZy
			tInfo.nFighting = tPetObj.nFighting
			tInfo.nAdvanced = tPetObj.nAdvanced
			tInfo.nAutoAddPointState = self:GetAutoAddPoinState(tPetObj)

			local tReviveData = {}
			tReviveData.nLevel = tPetObj.tRevive.nLevel
			tReviveData.nExp = tPetObj.tRevive.nExp
			tInfo.tReviveData = tReviveData
			
			tPetList.tBasalList = tInfo

			tPetList.tEquitList = self:GetPetEquit(tPetObj.tEquitList, tPetObj.nPos)
			tPetList.tSkillList = self:GetPetSKill(tPetObj)

			local tAttrLIst = {}
			tAttrLIst.nGJ =  tPetObj.tBaseAttr[gtBAT.eGJ]
			tAttrLIst.nFY = tPetObj.tBaseAttr[gtBAT.eFY]
			tAttrLIst.nSD = tPetObj.tBaseAttr[gtBAT.eSD]

			tAttrLIst.nLingLi = tPetObj.tBaseAttr[gtBAT.eLL]
	
			tAttrLIst.nLife = tPetObj.life
			tAttrLIst.nCZL = tPetObj.czl
			tAttrLIst.nDQGJZZ = tPetObj.tCurQfcAttr[1]
			tAttrLIst.nSXGJZZ =  tPetObj.tUmQfcAttr[1]
			tAttrLIst.nDQFYZZ = tPetObj.tCurQfcAttr[2]
			tAttrLIst.nSXFYZZ =	tPetObj.tUmQfcAttr[2]
			tAttrLIst.nDQTLZZ = tPetObj.tCurQfcAttr[3]
			tAttrLIst.nSXTLZZ = tPetObj.tUmQfcAttr[3]  
			tAttrLIst.nDQFLZZ = tPetObj.tCurQfcAttr[4]
			tAttrLIst.nSXFLZZ = tPetObj.tUmQfcAttr[4]
			tAttrLIst.nDQSDZZ = tPetObj.tCurQfcAttr[5]
			tAttrLIst.nSXSDZZ = tPetObj.tUmQfcAttr[5]
			tPetList.tAttrLIst = tAttrLIst
			tPetList.tPetAddPointList = self:GetPetAddPointList(tPetObj)
			tPetList.tPetAutoAddPointList = self:GetAutoAddPointList(tPetObj)
		end
		return tPetList
end

function CPet:GetPetEquit(tEquitList, nPos)
	local tList = {}
	for nEquipPartType, oPetEqu in pairs(tEquitList or {}) do
		tList[#tList+1] = oPetEqu:GetDetailInfo()
	end
	return tList
end

function CPet:GetPetAddPointList(tPetObj)
	if not tPetObj.tAddPointList then
		tAddPointList = {0,0,0,0,0}
	end

	local tPoint = {}
	-- for nKey, nValue in ipairs(tAddPointList) do
	-- 	if nValue then
	-- 		tPoint[nKey] = nValue
	-- 	end
	-- end

	for i =gtMAT.eTZ, gtMAT.eMJ, 1 do
		 tPoint[i] = tPetObj.tBaseAttr[i]
	end
	return tPoint
end

function CPet:GetAutoAddPointList(tPetObj)
	local tPetAutoAddPointList = {}
	if not tPetObj.tPetAutoAddPointList then
		tPetObj.tPetAutoAddPointList = {0,0,0,0,0}
	end
	tPetAutoAddPointList = tPetObj.tPetAutoAddPointList
	return tPetAutoAddPointList
end

function CPet:SetAutoAddPointList(tPetObj,tPlan, nState)
	tPetObj.tPetAutoAddPointList = tPlan
end

function CPet:GetAutoAddPoinState(tPetObj)
	local nAutoPointState = 2
	if not tPetObj.nAutoPointState then
		tPetObj.nAutoPointState = 2
	end
	nAutoPointState = tPetObj.nAutoPointState
	return nAutoPointState
end

function CPet:GetPetHFSkill(tHFSkillList)
	local tSkillList = {}
	if not tHFSkillList or next(tHFSkillList) == nil then
		return tSkillList
	end
	for _, nSkillID in ipairs(tHFSkillList) do
		tSkillList[#tSkillList+1] = {nID = nSkillID, nFlag = false}
	end
	return tSkillList
end


function CPet:PetChangeSend(tPetObj, nPos, nType)
	local tMsg = {tPetObjList = {}, nPos = nPos, nType = nType}
	if nType == 1 then
		local tPetObj = self:PetInfoHandle(tPetObj)
		tMsg.tPetObjList = tPetObj
		self.m_oRole:SendMsg("PetChangeMsgRet", tMsg)
	elseif nType == 2 then
		local tMsg = {nPos = nPos, nType = nType}
		self.m_oRole:SendMsg("PetChangeMsgRet", tMsg)

	elseif nType == 3 then
		local tMsg = {tPetObjList = {}, nPos = nPos, nType = nType}
		tMsg.tPetObjList = self:PetInfoHandle(tPetObj)
		self.m_oRole:SendMsg("PetChangeMsgRet", tMsg)
	end
end

--删除指定格子宠物
function CPet:SubGridPet(nGrid,sReason)
	assert(sReason, "请说明原因")
	local tPet = self.m_oPetMap[nGrid]
	if not tPet then
		return LuaTrace("宠物不存在", nGrid)
	end
	local nPetID = tPet.nId
	self.m_oPetMap[nGrid] = nil
	self:PetChangeSend(tPet, nGrid, 2)
	self:PetScoreChange()
	self:MarkDirty(true)
	goLogger:AwardLog(gtEvent.eSubItem, sReason, self.m_oRole, gtItemType.ePet, nPetID, 1, 0) 
	return true
end

function CPet:GetPetSKill(tPet)
	if not tPet then
		return 
	end
	local tSk = {}
	for _, tSkil1 in ipairs(tPet.tSKillList or {}) do
		tSk[#tSk+1] = {nID = tSkil1.nId, nFlag = tSkil1.nFalg, nType = 1}
	end

	for _, nSkillID in ipairs(tPet.tHfsk or {}) do
		tSk[#tSk+1] = {nID = nSkillID, nFlag = false, nType = 2}
	end

	return tSk
end

function CPet:GetPetMaxCpy()
	local n = 7
	return n + self.m_nExpansionTimes
end

--宠物放生
function CPet:ReleaseReq(nId, nPos )
	if nPos <= 0 then
		return 
	end
	if self.m_oRole:IsInBattle() then
		return self.m_oRole:Tips("战斗中不能放生宠物")
	end
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end

	if tItem.nPetType == getPetType.eMythicalAanimals or tItem.nPetType == getPetType.eTherion then
		return self.m_oRole:Tips("圣兽和神兽不能放生")
	end

	if tItem.status == gtSTT.eCZ then
		return self.m_oRole:Tips("该宠物处于参战状态,不能放生")
	end

	if not ctPetInfoConf[tItem.nId] then
		return 
	end
	if tItem.sName ~= ctPetInfoConf[tItem.nId].sName then
		return self.m_oRole:Tips("需要将宠物的名称改为默认名才能放生")
	end
	local tReward = {19005,19006,19007,19008,19009}
	if not tItem.nZy then
		local sCont = "放生该宠物将无法找回，是否确认放生？"
		local tOption = {"取消", "确定"}
		local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
		local fnPetEnterReleaseCallBack = function (tData)
			if tData.nSelIdx == 2 then
				--不是专有的直接释放,不保存
				local nReward = tReward[math.random(1,#tReward)]
				if tItem.nPetLv >= 40 then
					self.m_oRole:AddItem(gtItemType.eProp, nReward, 1, "放生获得")
				end
				self:SubGridPet(nPos, "宠物放生消耗")
				self:MarkDirty(true)
			end
		end
		goClientCall:CallWait("ConfirmRet", fnPetEnterReleaseCallBack, self.m_oRole, tMsg)

	else
		local sCont = "放生该宠物将无法找回，是否确认放生？"
		local tOption = {"取消", "确定"}
		local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
		local fnPetEnterReleaseCallBack = function (tData)
			if tData.nSelIdx == 2 then
				--专有需要保存，以后找回
				local nReward = tReward[math.random(1,#tReward)]
				if tItem.nPetLv >= 40 then
					self.m_oRole:AddItem(gtItemType.eProp, nReward, 1, "放生获得")
				end
				self.m_oPetSMap[#self.m_oPetSMap+1] = tItem
				self:SubGridPet(nPos, "宠物放生消耗")
				self:MarkDirty(true)
			end
		end
		goClientCall:CallWait("ConfirmRet", fnPetEnterReleaseCallBack, self.m_oRole, tMsg)
	end
end

function CPet:PetEquAttr()
	local tAttr = {}
	for nPos, tAttr in pairs(self.m_tPetWearEquitList) do
		if self.m_tEquitAttrList[nPos] then
			tAttr[nPos] = tAttr
			self.m_tEquitAttrList[nPos] = nil
		end
	end
	return tAttr
end

function CPet:RenamedReq(nId, nPos, sNewName)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	local sTmpName = CUtil:FilterSpecChars(sNewName)
	if sTmpName ~= sNewName then
		return self.m_oRole:Tips("名字不允许包含特殊字符")
	end
	if ctPetInfoConf[nId].sName == sNewName then
		tItem.sName = sNewName
		local tMsg = {sNewName = tItem.sName,nPos = nPos}
		self.m_oRole:SendMsg("PetRenamedRet", tMsg)
	else
		local function fnCallback(bRes)
		bRes = bRes == nil and true or bRes
		if bRes then
			return self.m_oRole:Tips("输入的名字中包含违禁字")
		end
		tItem.sName = sNewName
		self:MarkDirty(true)
		local tMsg = {sNewName = tItem.sName,nPos = nPos}
		self.m_oRole:SendMsg("PetRenamedRet", tMsg)
	end
		CUtil:HasBadWord(sNewName, fnCallback)
	end
end

--宠物进阶请求
function CPet:AdvancedReq(nPos, nType)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	if tItem.nPetType ~= getPetType.eTherion and  tItem.nPetType ~= getPetType.eMythicalAanimals then
		return self.m_oRole:Tips("必须是神兽或者圣兽才能进阶哦")
	end
	
	--屏蔽这个判断
	-- if self.m_oRole:GetLevel() < 65 then
	-- 	return self.m_oRole:Tips("玩家65级开放宠物进化系统")
	-- end
	local tAdvancedCost = ctPetAdvancedConf[tItem.nPetType]
	assert(tAdvancedCost, "道具配置错误")

	local tLevel = tAdvancedCost.tLevel
	local tCost = tAdvancedCost.tCost
	if not tLevel[tItem.nAdvanced+1] then
		return self.m_oRole:Tips("宠物已达到最高阶段")
	end
	if tItem.nPetLv < tLevel[tItem.nAdvanced+1][1] then
	 	return self.m_oRole:Tips("宠物等级不足")
	 end
	 local tCostItem = tCost[tItem.nAdvanced+1]
	 assert(tCostItem, "宠物进阶配置错误" .. tItem.nAdvanced+1)
	local tItemList = {}
	local bUseYuanBao =  true
	if nType == 2 then
		bUseYuanBao = false
	end
	tItemList[#tItemList+1] = {gtItemType.eProp,tCostItem[1], tCostItem[2]}
	local fnSubPropCallback = function (bRet)
		if not bRet then return end
		for i = 1, 5, 1 do
			tItem.tUmQfcAttr[i] = tItem.tUmQfcAttr[i] + tAdvancedCost.nAddQualification
			tItem.tCurQfcAttr[i] = tItem.tCurQfcAttr[i] + tAdvancedCost.nAddQualification
		end
		tItem.nAdvanced = tItem.nAdvanced + 1
		self.m_oRole:Tips(string.format("进化成功，所有资质增加了%d点", tAdvancedCost.nAddQualification))
		self:PetInfoChange(tItem)
		--属性更新
		self:PetUpdateAttr(tItem, 3, nPos)
		local tMsg = {nPos = nPos, nCurAdvanced = tItem.nAdvanced}
		self.m_oRole:SendMsg("PetAdvancedRet", tMsg)
		local tData = {}
		tData.bIsHearsay = true
		tData.nGrade = tItem.nAdvanced
		tData.sPetName = tItem.sName
		CEventHandler:OnPetUpGrade(self.m_oRole, tData)
		self:MarkDirty(true)
	end
	self.m_oRole:SubItemByYuanbao(tItemList,"宠物进化消耗" ,fnSubPropCallback, bUseYuanBao)
end

--宠物参战请求
--@bBattle 战斗中寿命<=50自动休息
function CPet:CombatReq(nId, nPos, nFlag, bBattle)

	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	if tItem.nPetLv - self.m_oRole.m_nLevel >= 10 then
		return self.m_oRole:Tips("该宠物已高于你10级，不能参战")
	end

	if tItem.life ~= nForeverLife and tItem.life <= 50 and nFlag == 2 then
		return self.m_oRole:Tips("宠物寿命小于50将不能出战")
	end

	if self.m_oRole:GetLevel() < ctPetInfoConf[nId].nPetLv then
		return self.m_oRole:Tips("玩家等级达到" .. ctPetInfoConf[nId].nPetLv .. "级才可以申请出战")
	end
	--战斗中不能休息
	if tItem.status == 2 and nFlag == 1 then
		if not bBattle and self.m_oRole:IsInBattle() then
			return self.m_oRole:Tips("战斗中宠物不能休息")
		end
	end

	--把之前参战的宠物标记去掉
	local nTPos = self:PetCombat()
	if self.m_oPetMap[nTPos] then
		self.m_oPetMap[nTPos].status = 1
	end

	tItem.nZy = true
	tItem.status = nFlag
	self:MarkDirty(true)
	local tMsg = {nFlag = nFlag, nPos = nPos}
	self.m_oRole:SendMsg("PetCombatRet", tMsg)
end

function CPet:PetCombat()
	local nPos = 0
	for Pos, tPet in pairs(self.m_oPetMap) do
		if tPet.status == 2 then
			nPos = Pos
			break
		end
	end
	return nPos
end

function CPet:GetCombatPet()
	for Pos, tPet in pairs(self.m_oPetMap) do
		if tPet.status == 2 then
			return tPet
		end
	end
end

--扩充玩家宠物携带列表
function CPet:CarryEpReq()
	local nCount = self.m_nExpansionTimes * getCarryCap.eExpansionTimes + getCarryCap.eDefaultCcarry
	if nCount >= getCarryCap.eMaxCarry then
		self.m_oRole:Tips(string.format("最多扩冲到%d个携带栏位", getCarryCap.eMaxCarry))
		return 
	end
	local tCostCfg = ctPetExtendConf[self.m_nExpansionTimes +1]
	if not tCostCfg then return end
	local nFlag = false
	local nCostNum = self.m_oRole:ItemCount(gtItemType.eProp,tCostCfg.tCost[1][1])
	local nCostYuanBao
	local nYuanBaoType = gtCurrType.eAllYuanBao
	local fnSubPropCallback = function (bRet)
		if not bRet then return end
		self.m_nExpansionTimes = self.m_nExpansionTimes + 1
		self:MarkDirty(true)
		local nCount = self.m_nExpansionTimes * getCarryCap.eExpansionTimes + getCarryCap.eDefaultCcarry
		self.m_oRole:Tips("你可以携带" .. nCount .. "只宠物了" )
		local tMsg = {}
		tMsg.nCount = nCount
		self.m_oRole:SendMsg("PetCarryEpRet", tMsg)
	end
	local tItemCostList = {{gtItemType.eProp, tCostCfg.tCost[1][1], tCostCfg.tCost[1][2]}}
	self.m_oRole:SubItemByYuanbao(tItemCostList, "宠物扩充消耗", fnSubPropCallback, false)
end

--宠物加点请求
function CPet:AddPointReq(nId, nPos, tList)
	if not tList then
		return 
	end

	local tPet = self.m_oPetMap[nPos]
	if not tPet then
		return self.m_oRole:Tips("宠物信息不存在")
	end

	local nSum = self:tBaseAttrSum(tList)

	if nSum > tPet.qld or nSum <= 0 then
		return self.m_oRole:Tips("潜力点不足")
	end

	tPet.qld = tPet.qld - nSum
	self:PetAddPoint(tPet.tBaseAttr, tPet.tAddPointList,tList)
	self:MarkDirty(true)
	--属性更新
	self:PetUpdateAttr(tPet, 3, nPos)
	local tMsg = {}
	tMsg.nFlag = 1
	tMsg.nPos = nPos
	self.m_oRole:SendMsg("PetAddPointRet", tMsg)

end

function CPet:tBaseAttrSum(tBaseAttr)
	local nValue = 0
	for nKey, nVa in ipairs(tBaseAttr or {}) do
		if nVa then
			nValue = nValue + nVa 
		end
	end
	return nValue 
end

function CPet:PetAddPoint(tBaseAttr, tAddPointList, tList)
	for nKey, nValue in pairs(tList) do
		if tBaseAttr[nKey] then
			tBaseAttr[nKey] = tBaseAttr[nKey] + nValue
			if not tAddPointList[nKey] then
				tAddPointList[nKey] = nValue
			end
			tAddPointList[nKey] =  tAddPointList[nKey] + nValue
		end
	end
end


--宠物自动加点请求
function CPet:PetAutoAddPoint(nState, nPos, tList)
	local tPet = self.m_oPetMap[nPos]
	if not tPet then return self.m_oRole:Tips("宠物信息不存在") end
	local nPoinNum = self:tBaseAttrSum(tList)
	local tPetCfg = ctPetInfoConf[tPet.nId]
	local tPoint = tList
	if not tPetCfg then return self.m_oRole:Tips("宠物配置不存在") end
	if nState == gtPetAutoPointState.eAutoState then
		tPet.nAutoPointState = nState
		if nPoinNum < tPetCfg.nAddPoint then
			local sTips = "分配满%d点才行哦"
			return self.m_oRole:Tips(string.format(sTips, tPetCfg.nAddPoint))
		end
		tPet.tPetAutoAddPointList = tPoint or {0,0,0,0,0}
		if tPet.qld >= tPetCfg.nAddPoint then
			self:AutoAddPoint(tPet, nPos)
			--属性更新
			self:PetUpdateAttr(tPet, 3, nPos)
		end
		self.m_bFirstGetPet = true
		self:MarkDirty(true)
	elseif nState == gtPetAutoPointState.eNoAutoState then
		tPet.nAutoPointState = nState
		tPoint = {}
		self:MarkDirty(true)
	end
	local tMsg = {}
	tMsg.nState = tPet.nAutoPointState
	tMsg.nPos = nPos
	tMsg.tList = tPoint
	self.m_oRole:SendMsg("PetAutoAddPointRet", tMsg)
end

function CPet:AutoAddPoint(tPet, nPos)
	local tPetCfg = ctPetInfoConf[tPet.nId]
	if not tPetCfg then return self.m_oRole:Tips("配置错误") end
	local nAddPoint = tPetCfg.nAddPoint
	local nAutoNum = self:tBaseAttrSum(tPet.tPetAutoAddPointList)
	if nAutoNum < nAddPoint then return  end
	if tPet.qld >= nAutoNum then
		local nNum = math.modf(tPet.qld/nAutoNum)
		tPet.qld = tPet.qld - nNum * nAutoNum
		for i = 1, nNum, 1 do
			for nKey, nValue in pairs(tPet.tPetAutoAddPointList or {}) do
				tPet.tBaseAttr[nKey] = tPet.tBaseAttr[nKey] + nValue
				tPet.tAddPointList[nKey] =  (tPet.tAddPointList[nKey] or 0 ) + nValue
			end
		end
	end
end

function CPet:PetPlanInfoReq(nPos,nPlan)
	local tPetObj = self.m_oPetMap[nPos]
	if not tPetObj then
		return 
	end
	local tAddPointList = self:GetAutoAddPointList(tPetObj)
	self.m_oRole:SendMsg("PetPlanInfoRet",{nPos = nPos,tList = tAddPointList,nState = tPetObj.nAutoPointState})
end

function CPet:PetAutoAddPointReq(nState,nPos,tPlan)
	local tPetObj = self.m_oPetMap[nPos]
	if not tPetObj then
		return 
	end
	self:SetAutoAddPointList(tPetObj,tPlan)
	self:PetAutoAddPoint(1, nPos,tPlan)
	self.m_oRole:SendMsg("PetPlanInfoRet",{tList = tPlan,nPos = nPos,nState = nState})
end

--便捷打书
function CPet:PetSkipTipsReq(nValue)
	self.m_bButton = nValue or false
	local tMsg = {bFlag= self.m_bButton} 
	self:MarkDirty(true)
	self.m_oRole:SendMsg("PetSkipTipsRet",tMsg)
end

--技能铭记取消请求
function CPet:CancelSkillRememberReq(nId, nPos, nSkillId)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return 
	end

	local tSKill = self:SkillFind(tItem.tSKillList, nSkillId)
	if not tSKill then
		return 
	end

	if not tSKill.nFalg then
		 return self.m_oRole:Tips("此技能没有铭记")
	end

	tSKill.nFalg = false
	local tMsg = {}
	tMsg.nFlag = true
	tMsg.nPos = nPos
	tMsg.nSkillID = nSkillId
	self:MarkDirty(true)
	print("tMsg-->", tMsg)
	self.m_oRole:SendMsg("PetCancelSkillRememberRet", tMsg)
end

--function CRole:AddItem(nItemType, nItemID, nItemNum, sReason, bRawExp, bBind, tPropExt)
--购买宠物请求(兑换)
function CPet:PetBuyReq(nPetID)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(40, true) then
		-- return self.m_oRole:Tips("宠物买卖系统尚未开启")
		return
	end
	local tPetLenlist =  self:GetEmptyPos(1)
	if #tPetLenlist < 1 then
		return self.m_oRole:Tips("宠物携带仓库已满，请放生后购买")
	end
	local tPet = ctPetInfoConf[nPetID]
	if not tPet then return end
	local nFlag = false
	local bBaoBaoFlag = false

	local tBuyCost = tPet.tBuyCost
	local tItemCostList = {}
	local  bShenShouZhiLingID
	for _, tCost in ipairs(tBuyCost) do
		if tCost[1] < 1 or tCost[2] <  1 then
			assert("道具配置错误")
		end
		local tProp = ctPropConf[tCost[1]]
		assert(tProp, "配置错误" .. tCost[1])
		if tProp.nType == nCurType then
			tItemCostList[#tItemCostList+1] = {gtItemType.eCurr, tProp.nSubType, tCost[2]}
		else
			tItemCostList[#tItemCostList+1] = {gtItemType.eProp, tCost[1], tCost[2]}                    
		end
		if tCost[1] == nShenShouZhiLingID then
			bShenShouZhiLingID = true
		end
	end
	local _PetBuy = function ()
		self.m_oRole:Tips("购买成功")
		self.m_oRole:AddItem(gtItemType.ePet, nPetID,1,"宠物购买获得")

		--传闻
		local tData = {}
		tData.bIsHearsay = true
		tData.nType = tPet.nPetType
		tData.nPetID = nPetID
		CEventHandler:OnGotPet(self.m_oRole, tData)
	end
	if bShenShouZhiLingID then
		local bRet = self.m_oRole:CheckSubItemList(tItemCostList, "宠物兑换消耗")
		if not bRet then return end
		_PetBuy()
	else
		local fnSubPropCallback = function (bRet)
			if not bRet then return end
			_PetBuy()
		end
		self.m_oRole:SubItemByYuanbao(tItemCostList, "宠物购买消耗", fnSubPropCallback, false)
	end
end

--宠物合成
function CPet:SynthesisReq(nZID, nFID, nZPos, nFPos, nBDType, bFlag, bYuanBaoBuy)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(53, true) then
		-- return self.m_oRole:Tips("宠物合成系统尚未开启")
		return
	end
	local tZItem = self.m_oPetMap[nZPos]
	local tFItem  = self.m_oPetMap[nFPos]
	if not tZItem then 
		return self.m_oRole:Tips("主宠不存在哦")
	end
	if not bYuanBaoBuy then
		if not tFItem then
			return self.m_oRole:Tips("副宠不存在哦")
		end

		if tFItem.status == 2 then
			return self.m_oRole:Tips("宠物参战状态不能合成操作")
		end
		if #tFItem.tSKillList < 1 then
			return self.m_oRole:Tips("副宠必须是至少具有1个技能的变异,宝宝类型的宠物.神兽,圣兽不能作为副宠")
		end

		if tFItem.nPetType == getPetType.eTherion or tFItem.nPetType == getPetType.eMythicalAanimals then
			return self.m_oRole:Tips("神兽,圣兽不能作为副宠")
		end
	end
	if tZItem.nPetType ==  getPetType.eYS then
		return self.m_oRole:Tips("主宠必须是神兽，圣兽，变异，宝宝类型的宠物")
	end
	if bYuanBaoBuy then
		if #tZItem.tSKillList == 0 then
			return self.m_oRole:Tips("主宠无技能时，无法元宝购买副宠")
		end
	end
	local _fnComposite = function (nSkillNum, tSkill, nMinJiID)
		local nGL  = self:GetSkillGl(nZID, nFID)
		tZItem.tSKillList = self:SKIllHandel( tSkill,nMinJiID, nGL, nBDType)
		self:PetInfoChange(tZItem)

		if not bYuanBaoBuy then
			self:SubGridPet(nFPos, "宠物合成消耗")

		end
		self:PetChangeSend(tZItem,nZPos, 3)
		self:MarkDirty(true)
		local sTips1 = "本次合成触发了合成保底，为您的宠物保留了%d个技能"
		local sTips2 = "宠物合成成功"
		self.m_oRole:Tips(sTips2)
		self.m_oRole:Tips(string.format(sTips1, #tZItem.tSKillList))
	
		local tData = {}
		tData.bIsHearsay = true
		tData.nSkillNum = #tZItem.tSKillList
		CEventHandler:OnPetCompose(self.m_oRole, tData)

		local tMsg = {nFlag = 1}
		self.m_oRole:SendMsg("PetSynthesisRet", tMsg)
	end

	local _fnNoYuanBaoBuy = function (nSkillNum, tSkill, nMinJiID)
		local tCostCfg = PetComposeUnderscore[nSkillNum].tCompostiteDan
		if not tCostCfg then return end
		local nCostID = tCostCfg[1][1]
		local nCostNum = tCostCfg[1][2]
		local nCostYuanBao = 0
		local bUseYuanBao = true
		local tItemCostList = {}
		if bFlag then
			bUseYuanBao = false
		else
			bUseYuanBao = true
		end
		--判断有没有保底
		if nBDType >= 1 and nBDType <= 2 then
			local nBDCostID
			local nBDCostNum
			if nBDType == 1 then
				nBDCostID = PetComposeUnderscore[nSkillNum].tElementaryNum[1][1]
				nBDCostNum = PetComposeUnderscore[nSkillNum].tElementaryNum[1][2]
			elseif nBDType == 2 then
				nBDCostID = PetComposeUnderscore[nSkillNum].tAdvancedNum[1][1]
				nBDCostNum = PetComposeUnderscore[nSkillNum].tAdvancedNum[1][2]
			end
			assert(nBDCostID or nBDCostNum , "合成保底配置错误")
			table.insert(tItemCostList, {gtItemType.eProp, nBDCostID, nBDCostNum})
		end
		--增加元宝不足
		local fnSubPropCallback = function (bRet)
			if not bRet then return end
			_fnComposite(nSkillNum, tSkill, nMinJiID)
		end
		if bYuanBaoBuy then
			local nCostYuanBao = PetComposeUnderscore[nSkillNum].nBuyCostYuanBao
			table.insert(tItemCostList, {gtItemType.eCurr, gtCurrType.eAllYuanBao, nCostYuanBao})
		end
		table.insert(tItemCostList, {gtItemType.eProp, nCostID, nCostNum})
		self.m_oRole:SubItemByYuanbao(tItemCostList, "宠物合成消耗", fnSubPropCallback, bUseYuanBao)
	end

	if bYuanBaoBuy then
		local fnGetPetSkillCallback = function (tSkillList)
			if not tSkillList or not next(tSkillList) then
				return
			end
			local tTempSkill = {}
			local tfPetSkill = {}
			--TODD筛选出跟主宠不宠物的技能
			for _, tSkill in ipairs(tZItem.tSKillList) do
				for nID, tItem in pairs(tSkillList) do
					local tProp = ctPropConf[nID]
					if tProp then
						if tSkill.nId == tProp.eParam() then
							tSkillList[nID] = nil
						end
					end
				end
			end

			for _, tSkill in pairs(tSkillList) do
				table.insert(tTempSkill, tSkill)
			end
			local fnCom = function (tItem1, tItem2)
				return tItem1.nPrice < tItem2.nPrice
			end
			table.sort(tTempSkill,fnCom)
			local nNum = 0
			local tOverSkill = {}
			for _, tSKill in ipairs(tTempSkill) do
				table.insert(tOverSkill, tSKill)
				nNum = nNum + 1
				if nNum == 20 then
					break
				end
			end
			local nSkillNum = #tZItem.tSKillList
			for  i = 1, nSkillNum , 1 do 
				local nSkillIndex = math.random(1, #tOverSkill)
				local nPropID = tOverSkill[nSkillIndex].nID
				assert(nPropID, "技能ID错误")
				local tSkillProp = ctPropConf[nPropID]
				assert(tSkillProp, "技能道具书错误")
				local nSkillID = tSkillProp.eParam()
				assert(ctPetSkillConf[nSkillID], "宠物技能配置错误" .. nSkillID)
				table.insert(tfPetSkill, {nId = nSkillID, nFalg = false})
				table.remove(tOverSkill,nSkillIndex)
			end
			local nSkillNum, tSkill, nMinJiID = self:GetSkillNum(tZItem.tSKillList,tfPetSkill )
			_fnNoYuanBaoBuy(nSkillNum, tSkill, nMinJiID)
		end
		 local nServerID = self.m_oRole:GetServer() 
	    local nTarService = goServerMgr:GetGlobalService(nServerID, 20)
		Network.oRemoteCall:CallWait("GetChamberCoreSkillReq",fnGetPetSkillCallback, nServerID, nTarService, 0)
	else
		local nSkillNum, tSkill, nMinJiID = self:GetSkillNum(tZItem.tSKillList, tFItem.tSKillList)
		_fnNoYuanBaoBuy(nSkillNum, tSkill, nMinJiID)
	end
end

function CPet:GetCost(nPetLv, nPetType)
	for nLevel, tCostCfg in pairs(ctPetComposeCost) do
		if tCostCfg.nPetType== nPetType and (nPetType == getPetType.eTherion or nPetType == getPetType.eMythicalAanimals) then
			return tCostCfg.tCost
		elseif (tCostCfg.nPetType== nPetType and nPetLv == tCostCfg.nLevel) or (nPetType == getPetType.EBY and nPetLv == tCostCfg.nLevel) then
			return tCostCfg.tCost
		end
	end 
end

function CPet:SKIllHandel(tList, nMinJiID, nGL, nBDType)
	print("nBDType------->", nBDType)
	if not tList then return end
	local _fnGuarntee = function (tList, nMinJiID, nGL, nBDType)
		local tSkillList = {}
		local tBDSkillConf = tList
		local tSkill = {}
		local tTmpSk = {}
		local bMaxNum = false
		local nSkillMaxNum = nMinJiID and 9 or 10
		for i = 1, #tList, 1 do
			local nRet = math.random(1,100)
			if nGL >= nRet then
				tSkill[#tSkill+1] = {nId = tList[i], nFalg = false}
			else
				tTmpSk[#tTmpSk+1] = tList[i]
			end
			--TODD.加一个技能达到Max控制,最大为10个，包括铭记的技能
			if #tSkill >= nSkillMaxNum then
				bMaxNum = true
				break
			end
		end

		--计算保底数量
		local nBDNUm = 0
		if nBDType == 1 then
			nBDNUm = math.floor(#tList /2)
		else
			nBDNUm = math.floor(#tList /2 +1)
		end
		local nCount = 0
		--判断触发保底
		if #tSkill < nBDNUm and #tTmpSk > 0 and not bMaxNum then
			local n = nBDNUm - #tSkill
			local nFalg = true
			while (nFalg) do
				local nIndex = math.random(1,#tTmpSk)
				local nSkill = tTmpSk[nIndex]
				if not self:SkillHeavy(tSkill, nSkill) then
					nCount =  nCount + 1
					tSkill[#tSkill+1] = {nId = nSkill, nFalg = false}
					if #tSkill >= nSkillMaxNum then
						break
					end
					table.remove(tTmpSk, nIndex)
					--防止死循环产生
					if #tTmpSk < n - nCount then
						nFalg = false
					end
				end
				if nCount == n then
					nFalg = false
				end
			end
		end
		--添加铭记技能
		if nMinJiID then
			tSkill[#tSkill+1] = {nId = nMinJiID, nFalg = true}
		end
		print("保底技能列表", tSkill)
		return tSkill
	end

	local _fnNoGuarntee = function (tList, nMinJiID, nGL)
		local tSkill = {}
		for i = 1, #tList, 1 do
			local nRet = math.random(1,100)
			if nGL >= nRet then
				tSkill[#tSkill+1] = {nId = tList[i], nFalg = false}
			end
		end

		--添加铭记技能
		if nMinJiID then
			tSkill[#tSkill+1] = {nId = nMinJiID, nFalg = true}
		end
		return tSkill
	end
	if nBDType > 0  and nBDType < 3 then
		return  _fnGuarntee(tList, nMinJiID, nGL, nBDType)
	else
		return _fnNoGuarntee(tList, nMinJiID, nGL)
	end
end

function CPet:SkillPy(tList, nMinJiID, nGL)
	if not tList then return end
	local tSkill = {}
	for i = 1, #tList, 1 do
		local nRet = math.random(1,100)
		if nGL >= nRet then
			tSkill[#tSkill+1] = {nId = tList[i], nFalg = false}
		end
	end

	--添加铭记技能
	if nMinJiID then
		tSkill[#tSkill+1] = {nId = nMinJiID, nFalg = true}
	end
	return tSkill
end
function CPet:SkillHeavy(tSkillList, nSkill)
	for i = 1, #tSkillList, 1 do
		if tSkillList[i].nId == nSkill then
			return true
		end
	end
end

function CPet:GetSkillGl(nZId, zFId)
	local tZItem = ctPetInfoConf[nZId]
	local tFItem = ctPetInfoConf[zFId]
	local nFLevel = tFItem and tFItem.nPetLv or 0
	local nZGL
	local nZX
	if tZItem.nPetType == getPetType.eTherion or tZItem.nPetType == getPetType.eMythicalAanimals then
		nZX = 0
		nZGL = 20 + nZX
	else
		local nPetLv = nFLevel - ctPetInfoConf[nZId].nPetLv
		if nPetLv ~= 0 then
			nZGL = 20 + (self:GetPetProbaility(nPetLv) or 0)  
		else
			nZGL = 20
		end
	end
	return nZGL
end

--根据副宠等级减主宠携带等级,取对应的技能遗传概率
function CPet:GetPetProbaility(nPetLv)
	if not nPetLv then return  end
	for i = 1 , #ctPetComposeCost, -1 do
		if nPetLv >= 100 and ctPetComposeCost[i].nProbability[1][1] == 100 then
			return ctPetComposeCost[i].nProbability[1][3]

		elseif nPetLv >= ctPetComposeCost[i].nProbability[1][1] and 
		   nPetLv <= ctPetComposeCost[i].nProbability[1][2] then
		   return ctPetComposeCost[i].nProbability[1][3]
		 end
	end
end

function CPet:GetSkillNum(tZSkills, tFSkills)
	if not tFSkills then return end
	local t = {}
	local nMinJiID 
	if tZSkills then
		for _, tZSkill in ipairs(tZSkills) do
			if tZSkill.nFalg == true then
				nMinJiID = tZSkill.nId
			else
				t[tZSkill.nId] = true
			end
		end
	end
	if tFSkills then
		for _, tFSkill in ipairs(tFSkills) do
			if not t[tFSkill.nId] then
				t[tFSkill.nId] = true
			end
		end
	end
	local tt = {}
	for nSkillId, _ in pairs(t) do
		tt[#tt+1] = nSkillId
	end
	return #tt, tt, nMinJiID
end

--宠物洗髓
function CPet:XiSuiReq(nID, nPos, nType)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return 
	end

	if nType < 1 and nType > 2 then
		return 
	end
	if tItem.nPetType == getPetType.eTherion or tItem.nPetType == getPetType.eMythicalAanimals then
		return self.m_oRole:Tips("圣兽和神兽以及特殊宠物无法使用洗宠功能")
	end

	if self.m_nXiSuiTime + 1 >= os.time() then
		return self.m_oRole:Tips("两次操作时间必须间隔一秒")
	end
	if self.m_bXiSui and tItem.nPetType ~= getPetType.EBY then
		local sCont = "当前洗髓出变异宝宝，是否继续洗髓?"
		local tOption = {"取消", "确定"}
		local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
		local fnPetEnterReleaseCallBack = function (tData)
			if tData.nSelIdx == 2 then
				self:PetXiSuiHandle(nID, tItem, nPos, nType)
				self.m_bXiSui = false
			end
		end
		goClientCall:CallWait("ConfirmRet", fnPetEnterReleaseCallBack, self.m_oRole, tMsg)
	else
		self:PetXiSuiHandle(nID, tItem, nPos, nType)
	end
end

function CPet:PetXiSuiHandle(nID, tItem, nPos, nType)
	local nXDLevel = ctPetInfoConf[nID].nPetLv
	-- local tXSCfg = ctPetXiSuiConf[nXDLevel]
	local tXiSuiCfg
	local fnXiSuiYuanBao
	tXiSuiCfg,fnXiSuiYuanBao= self:GetXiSuiCost(nXDLevel, tItem.nPetType)
	if not tXiSuiCfg or not fnXiSuiYuanBao then return end
	local nCostPropID = tXiSuiCfg[1][1]
	local nCostPropNum = tXiSuiCfg[1][2]
	local nPropNum = self.m_oRole:ItemCount(gtItemType.eProp, nCostPropID)
	local nFalg = false
	local bUseYuanBao = true
	if nType == 2 then
		bUseYuanBao = false
	else
		bUseYuanBao = true
	end
	local fnSubPropCallback = function (bRet)
		if not bRet then return end
		--百分之2的概率成为变异宠物
		local nProbability = ctPetXiSuiConf[nXDLevel].nProbability
		local nRet = math.random(1,100)
		local tItemPet = ctPetInfoConf[nID]
		if not tItemPet then return end

		local tPet = table.DeepCopy(tItemPet)
		local nOldPetType = tItem.nPetType
		if tItem.nPetType ~= getPetType.EBY then
			if nRet <= nProbability then
				tPet.nPetType = getPetType.EBY
				self.m_bXiSui = true
				self.m_oRole:Tips("洗髓出变异宝宝")
			end
		else
			tPet.nPetType = tItem.nPetType
		end
		tPet.nPetLv = tItem.nPetLv
		local tEquitList 
		if next(tItem.tEquitList or {}) then
			tEquitList = self:PetEquitData(tItem.tEquitList)
			tItem.tEquitList = {}
		end

		local oPet = table.DeepCopy(tItem)
		if tEquitList then
			self:PetEquitSwap(oPet, tItem, tEquitList)
		end
		self:XiSuiHandle(oPet, tPet)
		if oPet then
			self.m_oPetXiSui = oPet
			local tMsg = self:PetHandel(oPet)
			self.m_oRole:SendMsg("PetXiSuiRet", tMsg)
			print("洗髓消息返回", tMsg.tBasalList)
		end
		--记录洗髓时间
		self.m_nXiSuiTime = os.time()
		local tData = {}
		if nOldPetType ~= getPetType.EBY and tPet.nPetType == getPetType.EBY then
			tData.bIsHearsay = true
		else
			tData.bIsHearsay = false
		end
		tData.nPetType = tPet.nPetType
		tData.sPetName = tItem.sName
		CEventHandler:OnPetWashAttr(self.m_oRole, tData)
	end
	local tItemCostList = {{gtItemType.eProp, nCostPropID, nCostPropNum}}
	self.m_oRole:SubItemByYuanbao(tItemCostList, "宠物洗髓消耗", fnSubPropCallback, bUseYuanBao)
end

--如果宠物洗髓前有装备对象,现将装备脱下
function CPet:PetEquitSwap(oPet, tPet, tEquitList)
	for nEquipPartType, tPetEquData in pairs(tEquitList or {}) do
		local oPetEqu = self.m_oRole.m_oKnapsack:CreateProp(tPetEquData.m_nID, nEquipPartType)
		if oPetEqu then
			oPetEqu:LoadData(tPetEquData)
			tPet.tEquitList[nEquipPartType] = oPetEqu
			oPet.tEquitList[nEquipPartType] = oPetEqu
		end
	end
end

function CPet:GetXiSuiCost(nPetLv, nPetType)
	local tXiSuiCfg = ctPetXiSuiConf[nPetLv]
	if not tXiSuiCfg then return end
	if nPetType == getPetType.EBY then
		return tXiSuiCfg.AdvancedCost,tXiSuiCfg.eAdvancedCostYunBao
	else
		return tXiSuiCfg.tCost,tXiSuiCfg.eCostYunBao
	end
end

function CPet:PetXiSuiSavaReq(nType)
	if not self.m_oPetXiSui or not self.m_oPetMap[self.m_oPetXiSui.nPos] then return end
	-- if self.m_oPetMap[self.m_oPetXiSui.nPos].status == 2 then
	-- 	return self.m_oRole:Tips("目标宠物处于参战状态，不能进行洗宠操作")
	-- end
	--1保存宠物属性,2不保存宠物属性
	if nType == 1 then
		self.m_oPetMap[self.m_oPetXiSui.nPos] = self.m_oPetXiSui
		self:MarkDirty(true)
		local oPet = self.m_oPetXiSui
		local nPos =  self.m_oPetXiSui.nPos
		self.m_oPetXiSui = false
		self.m_bXiSui = false
		self:PetInfoChange(self.m_oPetMap[nPos])
		self:PetChangeSend(oPet, nPos, 3)
	else
		--释放掉宠物信息
		self.m_oPetXiSui = false
		self.m_bXiSui = false
	end
	
	local tMsg = {}
	self.m_oRole:SendMsg("PetXiSuiSavaRet", tMsg)
end

--请求洗髓宠物信息
function CPet:PetXiSuiPetReq()
	if self.m_oPetXiSui then
		local tMsg = self:PetHandel(self.m_oPetXiSui)
		self.m_oRole:SendMsg("PetXiSuiRet", tMsg)
	end
end

function CPet:PetHandel(tPetObj)
	local tPetList = {}
	local tMsg = {}
	local tInfo = {}
	if tPetObj then
		tInfo.nID = tPetObj.nId
		tInfo.nPos = tPetObj.nPos
		tInfo.sName = tPetObj.sName
		tInfo.sRatings = tPetObj.ratingLevel
		tInfo.nType = tPetObj.nPetType
		tInfo.nScore = tPetObj.jnpf	--策划要求改为显示总评分而不是技能评分
		--tInfo.nScore = tPetObj.nFighting
		tInfo.nBlood = tPetObj.tBaseAttr[gtBAT.eQX]
		tInfo.nWorkHard = tPetObj.tBaseAttr[gtBAT.eMF]
		tInfo.nExp = tPetObj.exp
		tInfo.nStatus = tPetObj.status
		tInfo.nLevel = tPetObj.nPetLv
		tInfo.nQld = tPetObj.qld
		tInfo.nPlayerId = tPetObj.nPlayerId
		tInfo.nModelNumber = tPetObj.sModelNumber
		tInfo.nDQBlood = tPetObj.nDQBlood
		tInfo.nDQWorkHard = tPetObj.nDQWorkHard
		tInfo.nZy = tPetObj.nZy
		tInfo.nFighting = tPetObj.nFighting
		tInfo.nAdvanced = tPetObj.nAdvanced
		tInfo.nAutoAddPointState = tPetObj.nAutoPointState or 2
		
		tMsg.tBasalList = tInfo
		tMsg.tSkillList = self:GetPetSKill(tPetObj)

		local tAttrLIst = {}
		tAttrLIst.nGJ =  tPetObj.tBaseAttr[gtBAT.eGJ]
		tAttrLIst.nFY = tPetObj.tBaseAttr[gtBAT.eFY]
		tAttrLIst.nSD = tPetObj.tBaseAttr[gtBAT.eSD]

		tAttrLIst.nLingLi = tPetObj.tBaseAttr[gtBAT.eLL]

		tAttrLIst.nLife = tPetObj.life
		tAttrLIst.nCZL = tPetObj.czl
		tAttrLIst.nDQGJZZ = tPetObj.tCurQfcAttr[1]
		tAttrLIst.nSXGJZZ =  tPetObj.tUmQfcAttr[1]
		tAttrLIst.nDQFYZZ = tPetObj.tCurQfcAttr[2]
		tAttrLIst.nSXFYZZ =	tPetObj.tUmQfcAttr[2]
		tAttrLIst.nDQTLZZ = tPetObj.tCurQfcAttr[3]
		tAttrLIst.nSXTLZZ = tPetObj.tUmQfcAttr[3]  
		tAttrLIst.nDQFLZZ = tPetObj.tCurQfcAttr[4]
		tAttrLIst.nSXFLZZ = tPetObj.tUmQfcAttr[4]
		tAttrLIst.nDQSDZZ = tPetObj.tCurQfcAttr[5]
		tAttrLIst.nSXSDZZ = tPetObj.tUmQfcAttr[5]
		tMsg.tAttrLIst = tAttrLIst
	end
	return tMsg
end

--添加经验
function CPet:AddExpReq(nPos, nProIdType)
	local tPetObj = self.m_oPetMap[nPos]
	if not tPetObj then
		return 
	end
	local nJinYanProID = 19000
	local nFlag = false
	local tProps = ctPropConf[nJinYanProID]
	if not tProps then
		return self.m_oRole:Tips("道具不存在")
	end
	if tPetObj.nPetLv - self.m_oRole:GetLevel() >= 5 then
		return self.m_oRole:Tips("已高于人物5级,不能使用")
	end
	local bUseYuanBao = true
	if nProIdType == 2 then
		bUseYuanBao = false
	end
	local tItemCostList = {{gtItemType.eProp, nJinYanProID, 1}}
	local fnSubPropCallback = function (bRet)
		if not bRet then return end
		--宠物经验心得获得经验量=10000+服务器等级*服务器等级*6+宠物等级*50
		local nExp = tProps.eParam(goServerMgr:GetServerLevel(self.m_oRole:GetServer()), tPetObj.nPetLv)
		local nCount = 0
		local nPetLv = tPetObj.nPetLv
		local nTempLevel = tPetObj.nPetLv
		tPetObj.exp = tPetObj.exp + nExp
		for nLevel = nPetLv, #ctPetLevelConf, 1 do
			if tPetObj.exp >= ctPetLevelConf[nLevel].nNeedExp then
				nCount = nCount + 1
				tPetObj.exp = tPetObj.exp - ctPetLevelConf[nLevel].nNeedExp
			else
				break
			end
		end
		local nUpdateLevel = (nCount + nPetLv) - self.m_oRole:GetLevel()
		if nUpdateLevel >= 5 then
			  local nOverLevel = (nCount + nPetLv) - (self.m_oRole:GetLevel() + 5)
			 	nCount = nCount - nOverLevel
		end
		--属性更新
		for _, nKey in pairs(gtMAT) do
			tPetObj.tBaseAttr[nKey] = tPetObj.tBaseAttr[nKey] + 1 * nCount
		end
		tPetObj.qld = tPetObj.qld + 5 * nCount
		tPetObj.nPetLv = tPetObj.nPetLv + nCount

		if nTempLevel ~= tPetObj.nPetLv then
			if tPetObj.nAutoPointState == gtPetAutoPointState.eAutoState then
				self:AutoAddPoint(tPetObj, nPos)
			end
		end

		if nCount ~= 0 then
			self:PetInfoChange(tPetObj)
		end
		self:MarkDirty(true)
		self:PetUpdateAttr(tPetObj,3, nPos)

		--属性更新
		self.m_oRole:SendMsg("PetAddExpRet", {nExp = nExp, nPos = nPos})
	end
	self.m_oRole:SubItemByYuanbao(tItemCostList, "宠物经验心消耗", fnSubPropCallback, bUseYuanBao)
end

--添加寿命
function CPet:AddLifeReq(nId, nPos, tItemList)
	print("tItemList+++++++++++++", tItemList)
	local tPet = self.m_oPetMap[nPos]
	if not tPet then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	if not tItemList then
		return self.m_oRole:Tips("道具数据错误")
	end

	if tPet.life == nForeverLife then
		return self.m_oRole:Tips("永生宠物不需要补充寿命哦")
	end
	if tPet.life >= nMaxLife then
		return self.m_oRole:Tips("宠物寿命已满不需要补充哦")
	end
	local nLife = 0
	local tGrid = {}
	local nNum = 0
	for _, tItem in pairs(tItemList) do
		local nItemNum = self.m_oRole.m_oKnapsack:ItemCount(tItem.nID)
		-- if not oProp then return self.m_oRole:Tips("道具错误") end
		if nItemNum < tItem.nNum then
			return self.m_oRole:Tips("道具数量不足")
		end

		local nAddLife = ctPropConf[tItem.nID].eParam()
		local nSurpLife = nMaxLife - tPet.life
		local nTmpLife = tItem.nNum * nAddLife
		if nTmpLife > nSurpLife then
			for i = 1, tItem.nNum, 1 do
				if nSurpLife <= nNum * nAddLife then
					nNum = i
					break
				end
			end
			nLife = nLife + nNum * nAddLife
			tPet.life = math.min(nMaxLife, tPet.life+nNum * nAddLife)
			--self.m_oRole.m_oKnapsack:SubGridItem(tItem.nGrid, oProp:GetID(),nNum, "添加寿命消耗")
			self.m_oRole:SubItem(gtItemType.eProp, tItem.nID, tItem.nNum, "添加寿命消耗")
		else
			nLife = nLife + nTmpLife
			tPet.life = math.min(nMaxLife, tPet.life+nTmpLife)
			--self.m_oRole.m_oKnapsack:SubGridItem(tItem.nGrid, oProp:GetID(), tItem.nNum, "添加寿命消耗")
			self.m_oRole:SubItem(gtItemType.eProp, tItem.nID, tItem.nNum, "添加寿命消耗")
			if tPet.life >= nMaxLife then
				break
			end
		end
	end
	self:MarkDirty(true)
	--属性更新
	local sTips = "使用成功,寿命+%d"
	--local sTips = "<color=#40d9ff>使用成功,寿命+%d</on></color>"
	self.m_oRole:Tips(string.format(sTips, nLife))
	local tMsg = {nLife = nLife, nPos = nPos}
	self:PetChangeSend(tPet, nPos, 3)
	self.m_oRole:SendMsg("PetAddLifeRet", tMsg)
end

--副本,以防改需求
function CPet:PetAddLifeReq1(nId, nPos)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	local tProps = ctPropConf[nProId]
	if not tProps then
		return self.m_oRole:Tips("道具不存在")
	end

	if tItem.life == nForeverLife then
		return self.m_oRole:Tips("永生宠物不需要补充寿命哦")
	end
	if tItem.life >= nMaxLife then
		return self.m_oRole:Tips("宠物寿命已满不需要补充哦")
	end
	local nSurpLife = nMaxLife - tItem.life
	local nAddLife = tProps.eParam()
	local nTmpLife = nNum * nAddLife
	if nTmpLife > nSurpLife then
		for i = 1, nNum, 1 do
			if nSurpLife <= nNum * nAddLife then
				nNum = i
				break
			end
		end
	end
	assert(nNum > 0, "数据错误")
	local nRet = self.m_oRole:CheckSubItem(gtItemType.eProp, nProId, nNum, "添加寿命消耗")
	if not nRet then
		return 
	end
	local nLife = nNum * nAddLife
	tItem.life = math.min(nMaxLife, tItem.life+nLife)
	self:MarkDirty(true)
	--属性更新
	local tMsg = {nLife = nLife, nPos = nPos}
	self.m_oRole:SendMsg("PetAddLifeRet", tMsg)
	self:PetChangeSend(tItem, nPos, 3)
end

--添加成长
function CPet:AddGUReq(nId, nPos)
	local tPet = self.m_oPetMap[nPos]
	if not tPet then return self.m_oRole:Tips("宠物不存在") end
	local nPropID = 19013	--成长道具ID

	local tPetItem = ctPetInfoConf[tPet.nId]
	local tProp = ctPropConf[nPropID]
	if tPet.czl == tPetItem.nChengZhangLv * 1.02 then
		return self.m_oRole:Tips("恭喜，这只宠物成长已经是最好的啦")
	end
	local tItemCostList = {{gtItemType.eProp, nPropID, 1}}
	local bUseYuanBao = false
	local fnSubPropCallback = function (bRet)
		if not bRet then return end
		local nCzl = tProp.eParam()
		tPet.czl =  tPet.czl +  nCzl * 1000
		if tPet.czl >= tPetItem.nChengZhangLv * 1.02 then
			tPet.czl = tPetItem.nChengZhangLv * 1.02
		end
		print("添加成长")
		self:PetInfoChange(tPet)
		self:PetUpdateAttr(tPet, 3, nPos)
		self:MarkDirty(true)
		--属性更新
		local tMsg = {nGu = nCzl, nPos = nPos}
		self.m_oRole:SendMsg("PetAddGURet", tMsg)
	end
	self.m_oRole:SubItemByYuanbao(tItemCostList, "添加成长消耗", fnSubPropCallback, bUseYuanBao)
end

--副本,以防改需求
function CPet:AddGUReq1(nId, nPos, nType, nProId, nNum)
	local tItem = self.m_oPetMap[nPos]
	local tProcfg = ctPropConf[nProId]
	if not tItem and not tProcfg then
		return 
	end
	local nPropID = 19013	--成长道具ID
	local tProps = ctPropConf[nProId]
	if not tProps then
		return self.m_oRole:Tips("道具不存在")
	end

	local tPetItem = ctPetInfoConf[nId]
	if not tPetItem then
		return  
	end

	if tItem.czl == tPetItem.chengzhangnPetLv * 1.02 then
		self.m_oRole:Tips("恭喜，这只宠物成长已经是最好的啦")
	end

	local nGu = tPetItem.chengzhangnPetLv * 1.02 - tItem.czl
	local nCzl = nNum * 0.003
	local nCount = nNum
	if nCzl > nGu then
		for i = 1, #nNum, 1 do
			if nGu <= i * 0.003 then
				nCount = i
				break
			end
		end
	end

	local nResult = self.m_oRole:CheckSubItem(gtItemType.eProp, nProId, nCount, "添加成长消耗")
	if not nResult then
		return 
	end

	tItem.czl =  tItem.czl +  nCzl
	if tItem.czl >= tPetItem.chengzhangnPetLv * 1.02 then
		tItem.czl = tPetItem.chengzhangnPetLv * 1.02
	end
	self:MarkDirty(true)
	--属性更新
	local tMsg = {nGu = nCzl, nPos = nPos}
	self.m_oRole:SendMsg("PetAddGURet", tMsg)
end

--洗點
function CPet:WashPointReq(nId, nPos, nProId, nType)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end

	local tPetCfg = ctPetCostConf[1]
	if not tPetCfg then
		return self.m_oRole:Tips("配置文件不存在")
	end
	local nAttr = 0
	for nKey, nVa in pairs(tItem.tAddPointList) do
		nAttr = nAttr + nVa
	end
	if nAttr <= 0 then 
		return self.m_oRole:Tips("当前没有可返还的潜力点,不用进行洗点操作")
	end
	local tCostCfg = tPetCfg.tCost
	local function _PetXiSuiHandle()
		local nValue = 0
		--扣道具成功
		for nKey, nVa in pairs(tItem.tAddPointList) do
			if tItem.tBaseAttr[nKey] then
				tItem.tBaseAttr[nKey] = tItem.tBaseAttr[nKey] - nVa
				nValue = nValue + nVa
				tItem.tAddPointList[nKey] = 0
			end
		end
		tItem.qld = tItem.qld + nValue
		self:PetUpdateAttr(tItem, 3, nPos)
		local tMsg = {}
		tMsg.nFlag = 1
		tMsg.nPos = nPos
		self.m_oRole:SendMsg("PetWashPointRet", tMsg)
		self:MarkDirty(true)
		--属性更新
	end

	local function fnSubPropCallback(bRet)
		if not bRet then return end
		_PetXiSuiHandle()
	end

	if nType == 1 then
		if self.m_oRole:ItemCount(gtItemType.eProp, tCostCfg[1][1]) < tCostCfg[1][2] then
			return  self.m_oRole:Tips("道具不足")
		end
		self.m_oRole:SubItem(gtItemType.eProp, tCostCfg[1][1], tCostCfg[1][2], "宠物洗点消耗")
		_PetXiSuiHandle()

	elseif nType == 2 then
		local tItemCostList = {{gtItemType.eProp, tCostCfg[1][1], tCostCfg[1][2]}}
		self.m_oRole:SubItemByYuanbao(tItemCostList, "洗点消耗", fnSubPropCallback, false)
	end
end

--宠物技能学习
function CPet:SillLearnReq(nId, nPos, nSkillId, nType)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	local nPoss =nPos 
	 if not ctPetSkillConf[nSkillId] then
	 	return self.m_oRole:Tips("技能不存在")
	end
	local nFalg = self:SkillCheck(tItem.tSKillList, nSkillId)
	if nFalg then
		return self.m_oRole:Tips("你已经学会了此技能")
	end
	local tProps = ctPropConf[ctPetSkillConf[nSkillId].nPropID]
	if not tProps then
		return
	end
	local nFalg = false
	if nType == 1 then
		local nRet = self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eJinBi, tProps.nSilverPrice, "学习技能消耗")
		if not nRet then
			return 
		end
		nFalg = true

	elseif nType == 2 then
		local nRet = self.m_oRole:CheckSubItem(gtItemType.eCurr,tProps.nYuanBaoType, tProps.nBuyPrice, "学习技能消耗")
		if not nRet then
			return self.m_oRole:YuanBaoTips() 
		end
		nFalg = true

	elseif nType == 3 then
		local nRet = self.m_oRole:CheckSubItem(gtItemType.eProp, ctPetSkillConf[nSkillId].nPropID, 1, "学习技能消耗")
		if not nRet then
			return 
		end
		nFalg = true
	end
	self:LearnSkill(nPos, tItem, nSkillId)
end

function CPet:LearnSkill(nPetPos, tItem, nSkillId)
	local nNewId = 0
	local nYWId  = 0
	local nId
	local nPos
	local nSkilNum = #tItem.tSKillList
	if nSkilNum >= 0 and nSkilNum < 4 then
		local nPb =  self:PetProbability(nSkilNum)
		local nRan = math.random(1,100)
		local nRet = false
		if nPb >= nRan then
			nRet = true
		end
		if nRet then
			tItem.tSKillList[#tItem.tSKillList+1] = {nId = nSkillId, nFalg = false}
			nNewId = nSkillId
		else
			--查找有没有铭记的技能
			nPos,nId = self:PetRememberFind(tItem.tSKillList)
			nPos =  self:SkilOblivion(tItem.tSKillList, nId, nPos)
			if nPos then
				nYWId = tItem.tSKillList[nPos].nId
				nNewId = nSkillId
				tItem.tSKillList[nPos] = {nId = nSkillId, nFalg = false}
			else
				table.insert(tItem.tSKillList, {nId  = nSkillId, nFalg = false})
			end
		end
	else
		if nSkilNum >= 4 then
			nPos,nId = self:PetRememberFind(tItem.tSKillList)
			nPos = self:SkilOblivion(tItem.tSKillList, nId, nPos)
				if nPos then
				nYWId = tItem.tSKillList[nPos].nId
				nNewId = nSkillId
				tItem.tSKillList[nPos] = {nId = nSkillId, nFalg = false}
			else
				table.insert(tItem.tSKillList, {nId  = nSkillId, nFalg = false})
			end
		end
	end
	
	self:PetInfoChange(tItem)
	self:MarkDirty(true)

	--属性更新
	local tMsg =  {nXId = nNewId, nYId = nYWId, nPos = nPetPos}
	self.m_oRole:SendMsg("PetSillLearnRet",tMsg)
	self:PetChangeSend(tItem, nPetPos, 3)

	if self.m_oRole:IsInBattle() then
		return self.m_oRole:Tips("操作在战斗结束后生效")
	end
	CEventHandler:OnPetLearnSkill(self.m_oRole, {})
end

--快速学习技能
function CPet:FastLearnSkillReq(nPropID, nPos, nPrice)
	local tPet = self.m_oPetMap[nPos]
	if not tPet then return self.m_oRole:Tips("宠物信息不存在") end
	 local nSklillID
	 if ctPropConf[nPropID] then 
	 	nSklillID = ctPropConf[nPropID].eParam()
	 end
	 if not ctPetSkillConf[nSklillID] then
	 	return self.m_oRole:Tips("技能不存在")
	 end
	 local nFalg = self:SkillCheck(tPet.tSKillList, nSklillID)
	if nFalg then
		return self.m_oRole:Tips("你已经学会了此技能")
	end
	self.m_FastPetPos = nPos
	local nServerID = self.m_oRole:GetServer()
	local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)
	Network.oRemoteCall:Call("BuyShopPriceReq", nServerID, nGlobalLogic, 0, self.m_oRole:GetID(),101,nPropID, 1, "PetSomeMethodSkillReq")
end

function CPet:SomeMethod(nPropID)
	 local nSklillID
	 if ctPropConf[nPropID] then 
	 	nSklillID = ctPropConf[nPropID].eParam()
	 end
	 if not ctPetSkillConf[nSklillID] then
	 	return self.m_oRole:Tips("技能不存在")
	 end
	 local tPet = self.m_oPetMap[self.m_FastPetPos] 
	 if not tPet then return end
	 self:LearnSkill(self.m_FastPetPos, tPet, nSklillID)
	 self.m_FastPetPos = 0
end

function CPet:SkilOblivion(tList, nId, nPos)
	local tSlist = {}
	local nTmpPos 
	for nKey, tSk in ipairs(tList) do
		if nKey ~= nPos and tSk.nId ~= nId then
			table.insert(tSlist, tSk.nId)
		end
	end
	if #tSlist == 0 then
		return 
	end
	local nSkid = tSlist[math.random(1, #tSlist)]
	for nKey, tSk in ipairs(tList) do
		if tSk.nId == nSkid then
			nTmpPos = nKey
			break
		end
	end
	return nTmpPos
end

function CPet:PetRememberFind(tSkill)
	local nPos
	local nId
	if tSkill then
		for nkey, tSk in ipairs(tSkill) do
			if tSk.nFalg == true then
				nPos = nkey
				nId =  tSk.nId
				break
			end
		end
	end
	return nPos, nId
end
function CPet:PetProbability(nNum)
	if nNum == 0 then
		return 100
	elseif nNum == 1 then
		return 20
	elseif nNum == 2 then
		return 10
	elseif nNum == 3 then
		return 3
	end
end

--炼骨请求
function CPet:LianGuReq(nId, nPos, nProId, nType,nNum)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	local tProps = ctPropConf[nProId]
	if not tProps then
		return self.m_oRole:Tips("道具不存在")
	end

	if nType <= 0 and nType > 5 then
		return 
	end

	if tItem.tCurQfcAttr[nType] >= tItem.tUmQfcAttr[nType] then
		return self.m_oRole:Tips("宠物"..getQualiName[nType].."资质已达上限了")
	end
	local nValue = tItem.tUmQfcAttr[nType] - tItem.tCurQfcAttr[nType]
	if nValue < nNum then
		nNum = nValue
	end

	if self.m_oRole:ItemCount(gtItemType.eProp, nProId) < nNum then
		return self.m_oRole:Tips("道具不足")
	end
	self.m_oRole:SubItem(gtItemType.eProp, nProId, nNum, "宠物炼骨消耗")
	tItem.tCurQfcAttr[nType] = tItem.tCurQfcAttr[nType] + nNum * 1
	if tItem.tCurQfcAttr[nType] > tItem.tUmQfcAttr[nType] then
		tItem.tCurQfcAttr[nType] = tItem.tUmQfcAttr[nType]
	end
	self:PetInfoChange(tItem)
	self:MarkDirty(true)

	self:PetChangeSend(tItem,nPos, 3)
	--属性更新
	local sTips = "%s资质丹使用成功,%s资质+%d"
	self.m_oRole:Tips(string.format(sTips, getQualiName[nType], getQualiName[nType], nNum * 1))
	local tMsg = {nQf = nNum * 1, nNum = nNum, nPos = nPos, nType = nType}
	self.m_oRole:SendMsg("PetLianGuRet", tMsg)
	CEventHandler:OnPetLianGu(self.m_oRole, {})
	--消耗资质丹	
	local nServer = self.m_oRole:GetServer()
    Network.oRemoteCall:Call("OnTAZZDReq", nServer, goServerMgr:GetGlobalService(nServer,20), 0, self.m_oRole:GetID(), nNum)
end

--添加宠物经验
function CPet:AddExp(nExp, sReason, bNotSync)
	local tPetObj
	local nPos
	for Pos, tPet in pairs(self.m_oPetMap) do
		if tPet and tPet.status == 2 then
			tPetObj = tPet
			nPos = Pos
		end
	end
	if not tPetObj then
		return 
	end
	if tPetObj.nPetLv - self.m_oRole:GetLevel() >= 5 then
		if not bNotSync then
			self.m_oRole:Tips("宠物已经超过你5级，将无法获得经验")
		end
		return
	end

	self:AddExpUpdate(tPetObj, nPos, nExp)

	--发送获得物品聊天频道信息
	local nIntExp = math.floor(nExp)
    CUtil:SendItemTalk(self.m_oRole, "getpetexp", {tPetObj.nId, ctPropConf:GetCurrProp(gtCurrType.ePetExp), nIntExp}, bNotSync)
    --日志
    goLogger:AwardLog(gtEvent.eAddItem, sReason or "", self.m_oRole, gtItemType.eCurr, gtCurrType.ePetExp, nExp, nPos, tPetObj.nPetLv)
end

--重新计算属性
function CPet:PetUpdateAttr(ItemTb, nType, nPos)
	if nType == 3 then
		self:PetClacAttr(ItemTb)
		self:MarkDirty(true)
		self:PetChangeSend(ItemTb, nPos, nType)
	else
		self:PetChangeSend(ItemTb, nPos, 3)
	end
end

function CPet:SkillFindMinJi(tSKillList)
	if tSKillList then
		for key, tSK in ipairs(tSKillList) do
			if tSK.nFalg == true then
				return true, tSK.nId
			end
		end
	end
end

--宠物技能铭记
function CPet:SkillRememberReq(nId, nPos, nSkillId, nType)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end

	local nHFSkill = self:GetHFSkill(tItem, nSkillId)
	if nHFSkill then return self.m_oRole:Tips("护符技能不能铭记") end

	--查找有没有铭记的技能
	local bMInJI = false 
	local nMinJiID
	bMInJI,nMinJiID = self:SkillFindMinJi(tItem.tSKillList)
	 if not ctPetSkillConf[nSkillId] then
	 	return self.m_oRole:Tips("技能不存在")
	end

	--检查宠物有没有此技能
	local tSk = self:SkillFind(tItem.tSKillList, nSkillId)
	if not tSk then
		return self.m_oRole:Tips("宠物没有此技能")
	end

	if tSk.nFalg then
		return self.m_oRole:Tips("此技能已经铭记，不用重复铭记")
	end
	if bMInJI then
		local sName = tItem.sName
		local nNum = 60
		local nCostYinBi = 10000 * nNum
		local sCont = sName .. "已经铭记了" ..ctPetSkillConf[nMinJiID].sName .. "技能,是否消耗".. nNum .."万银币替换为" .. ctPetSkillConf[nSkillId].sName .."技能" 
		local tOption = {"否", "是"}
		local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
		local fnSkillMinJICallBack = function (tData)
		print("tData.", tData)
			if tData.nSelIdx == 2 then
				if self.m_oRole:GetYinBi() < nCostYinBi then return self.m_oRole:YinBiTips() end
				self.m_oRole:SubItem(gtItemType.eCurr, gtCurrType.eYinBi, nCostYinBi, "技能铭记消耗")
				local tSkill = self:SkillFind(tItem.tSKillList, nSkillId)
				tSkill.nFalg = true

				local tSkill2 = self:SkillFind(tItem.tSKillList, nMinJiID)
				tSkill2.nFalg  = false

				--先推送取消铭记
				local tMsg = {nFlag = tSkill2.nFalg, nPos = nPos, nSkillID = nMinJiID}
				print("铭记返回1", tMsg)
				self.m_oRole:SendMsg("PetCancelSkillRememberRet", tMsg)
				local tMsg = {nFlag = tSkill.nFalg, nPos = nPos, nSkillID = nSkillId}
				print("铭记返回", tMsg)
				self.m_oRole:SendMsg("PetSkillRememberRet", tMsg)
			end
		end
		goClientCall:CallWait("ConfirmRet", fnSkillMinJICallBack, self.m_oRole, tMsg)
	else
		local tCost = ctPetCostConf[5].tCost
		if not ctPropConf[tCost[1][1]] then
			return 
		end
		if not tCost then
			return self.m_oRole:Tips("配置文件不存在")
		end

		local nFalg = false
		local nYuanBao =  ctPropConf[tCost[1][1]].nBuyPrice
		if nType == 1 then

			if self.m_oRole:ItemCount(gtItemType.eProp, tCost[1][1]) < tCost[1][2] then
				return self.m_oRole:Tips("道具不足")
			end
			local nRet = self.m_oRole:SubItem(gtItemType.eProp, tCost[1][1], tCost[1][2], "技能铭记消耗")
			nFalg = true
		elseif nType == 2 then
			local bRet =  self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nYuanBao, "技能铭记消耗")
			if not bRet then
				return self.m_oRole:YuanBaoTips()
			end
			nFalg = true
		end
		--扣道具成功
		if not nFalg then
			return 
		end
		tSk.nFalg = true

		self:MarkDirty(true)
		local tMsg = {nFlag = tSk.nFalg, nPos = nPos, nSkillID = nSkillId}
		self.m_oRole:SendMsg("PetSkillRememberRet", tMsg)
	end
end

function CPet:SkillFind(tSlist, nSkID)
	local tItem 
	if tSlist then
		for key, tSK in ipairs(tSlist) do
			if tSK.nId == nSkID then
				tItem = tSK
				break
			end
		end
	end
	return tItem
end

function CPet:SkillCheck(sSkilList, SkilId)
	local nFalg = false
	if not sSkilList then return end
	for key, tSkill in ipairs(sSkilList) do
		if tSkill.nId == SkilId then
			nFalg = true
			break
		end
	end
	return nFalg
end

--获取护符技能
function CPet:GetHFSkill(tPet, nSkillID)
	for _, nSkID in ipairs(tPet.tHfsk or {}) do
		if nSkID == nSkillID then
			return  nSkillID
		end
	end
end

--宠物穿戴装备
function CPet:WearEquitReq(nPos, nGrid)
	-- if not self.m_oRole.m_oSysOpen:IsSysOpen(44, true) then
	-- 	--return self.m_oRole:Tips("宠物20级才可以穿戴装备")
	--	return
	-- end
	local tPetInfo = self.m_oPetMap[nPos]
	if not tPetInfo then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	if tPetInfo.nPetLv < 20 then
		return self.m_oRole:Tips("宠物20级才可以穿戴装备")
	end
	local tPetCfg = ctPetInfoConf[tPetInfo.nId]
	assert(tPetCfg, "宠物配置错误" .. tPetInfo.nId )
	local tEquit = self.m_oRole.m_oKnapsack:GetItem(nGrid)
	if not tEquit then
		return self.m_oRole:Tips("装备不存在")
	end

	--饰品特殊判断,nEquiSubType大于0表示饰品类型
	 if tEquit:GetConf().nEquiSubType > 0 then
	 	if tEquit:GetConf().nEquiSubType > 1 then
	 		--TODD 神兽，圣兽类型饰品
	 		if tPetInfo.nPetType ~= tEquit:GetConf().nEquiSubType then
	 			return self.m_oRole:Tips("宠物类型跟装备类型不一致哦")
	 		end
	 	else
	 		--TODD 宝宝类型饰品
	 		if tPetCfg.nPetLv ~= tEquit:GetConf().nLevel then
	 			return self.m_oRole:Tips("必须穿戴宠物携带等级对应的装备哦")
	 		end
	 	end
	 end 
	if not tPetInfo.tEquitList then
		tPetInfo.tEquitList = {}
	end
	local oWerEqut = tPetInfo.tEquitList[tEquit:GetConf().nEquipPartType]
	tPetInfo.tEquitList[tEquit:GetConf().nEquipPartType] = tEquit
	self:GetPetEquitAttr(tPetInfo, tEquit:GetConf().nEquipPartType, tEquit.m_PetEquAttrList, tEquit:GetConf().nPropertyLimit, oWerEqut)
	self.m_oRole.m_oKnapsack:SubGridItem(nGrid, tEquit:GetID(), 1, "穿戴装备")
	self:PetChangeSend(tPetInfo, nPos, 3)
	self:MarkDirty(true)
end

function CPet:GetPetEquitAttr(tPet, nType, tAttrLIst, nPropertyLimit, oWerEqut)
	if nType == 1 or nType == 2 then
		--项圈跟头盔
		if oWerEqut then
			for nAttrID, nAttr in pairs(oWerEqut.m_PetEquAttrList or {}) do
				if tPet.tBaseAttr[nAttrID] then
					tPet.tBaseAttr[nAttrID] = tPet.tBaseAttr[nAttrID] - nAttr
				end
			end
		end

		for gtBAT, nAttr in pairs(tAttrLIst) do
			if tPet.tBaseAttr[gtBAT] then
				print("tPet.tBaseAttr[gtBAT]前", tPet.tBaseAttr[gtBAT])
				 tPet.tBaseAttr[gtBAT] =  tPet.tBaseAttr[gtBAT] + nAttr
				 print("tPet.tBaseAttr[gtBAT]后", tPet.tBaseAttr[gtBAT])
			end
		end
		self:PetInfoChange(tPet)
		self:MarkDirty(true)
	elseif nType == 3 then
		--护符
		tPet.tHfsk = {}
		for i = 1, #tAttrLIst, 1 do
			tPet.tHfsk[#tPet.tHfsk+1] = tAttrLIst[i]
		end
		self:PetInfoChange(tPet)
	else
		--饰品
		local nTmpPropertyLimit = 0
		local tEquitCfg
		if oWerEqut then
			tEquitCfg = ctPetHelmetConf[oWerEqut:GetID()]
		end
		
		if tEquitCfg then
			nTmpPropertyLimit = tEquitCfg.nPropertyLimit
		end
		
		for i = 1, #tPet.tUmQfcAttr, 1 do
			tPet.tUmQfcAttr[i] = tPet.tUmQfcAttr[i] - nTmpPropertyLimit
			tPet.tUmQfcAttr[i] = tPet.tUmQfcAttr[i] + nPropertyLimit
		end
		self:MarkDirty(true)
	end
end

--装备合成请求
function CPet:PetEquitCptReq(nZGrid, nFGrid)
	if not self.m_oRole.m_oSysOpen:IsSysOpen(45, true) then
		-- return self.m_oRole:Tips("装备合成系统尚未开启")
		return
	end
	local tZProp = self.m_oRole.m_oKnapsack:GetItem(nZGrid)
	local tFProp = self.m_oRole.m_oKnapsack:GetItem(nFGrid)
	if not tZProp or not tFProp then
		return self.m_oRole:Tips("玩家没有对应的装备")
	end

	local tZItem = ctPetHelmetConf[tZProp:GetID()]
	local tFItem = ctPetHelmetConf[tFProp:GetID()]
	if not tZItem or not tFItem then
		return self.m_oRole:Tips("装备不存在")
	end

	if tZItem.nEquipPartType > 3 or tFItem.nEquipPartType > 3 then
		return self.m_oRole:Tips("饰品装备不能用于合成")
	end
	if tZItem.nLevel ~= tFItem.nLevel or tZItem.nEquipPartType ~= tFItem.nEquipPartType then
		return self.m_oRole:Tips("参与合成的所有装备需要等级和部位都相同")
	end
	local nAttr = 0
	if tZItem.nEquipPartType ==  gtPetEquPart.eTalisman then
		tAttr = self:PetTalisman(tZProp, tFProp)
		tZProp.m_PetEquAttrList = tAttr
		self.m_oRole.m_oKnapsack:SubGridItem(nFGrid, tFProp:GetID(), 1, "装备合成消耗")
		self:MarkDirty(true)
		local tMsg = {}
		tMsg.nID = tZProp:GetID()
		tMsg.nLevel = tZItem.nLevel
		tMsg.nPos = tZProp:GetGrid()
		self.m_oRole:Tips("合成成功,你获得了一个全新的" .. tZProp:GetName())
		self.m_oRole:SendMsg("PetEquitCptRet", tMsg)
	else
		local nIndex 
		nIndex, nAttr = self:PetEquit(tZItem, tFItem)
		if nIndex and nAttr then
			tZProp.m_PetEquAttrList = {}
			tZProp.m_PetEquAttrList[nIndex] = nAttr

			self:MarkDirty(true)
		end
		self.m_oRole.m_oKnapsack:SubGridItem(nFGrid, tFProp:GetID(), 1, "装备合成消耗")
		local tMsg = {}
		tMsg.nID = tZProp:GetID()
		tMsg.nLevel = tZItem.nLevel
		tMsg.nPos = tZProp:GetGrid()
		self.m_oRole:Tips("合成成功,你获得了一个全新的" .. tZProp:GetName())
		self.m_oRole:SendMsg("PetEquitCptRet", tMsg)
	end
end

function CPet:PetEquit(tItemId1, tItemId2)
	--装备不同做不同的处理
	if tItemId1.nEquipPartType == gtPetEquPart.eArmor and tItemId2.nEquipPartType == gtPetEquPart.eArmor then
		return  self:PetCollar(tItemId1, tItemId2)
	elseif tItemId1.nEquipPartType == gtPetEquPart.eCollar and tItemId2.nEquipPartType == gtPetEquPart.eCollar then
		return self:PetHelmet(tItemId1, tItemId2)
	end
end

--头盔合成
function CPet:PetHelmet(tEquit)
	 local nNewId = 0
	local nAttr = tEquit.tAttr[1][2]
	nAttr = self:PetEquitAttrHandle(nAttr,tEquit)
	return tEquit.tAttr[1][1],nAttr
end

--项圈合成
function CPet:PetCollar(tEquit)
	local tNewId = 0
	local nAttrIndex = math.random(1,4)
	local nAttr = tEquit.tAttr[nAttrIndex][2]
	nAttr = self:PetEquitAttrHandle(nAttr, tEquit)
	return tEquit.tAttr[nAttrIndex][1] ,nAttr
end

--护符合成
function CPet:PetTalisman(tZProp, tFProp)
	local nZSkLen = #tZProp.m_PetEquAttrList
	local nFSkLen = #tFProp.m_PetEquAttrList
	local nPbIndex = self:GetHFSkllPb(nZSkLen+nFSkLen)
	--t = {20%,80% --20为双的概率,80为单的概率}
	local tGl = {[1] = {20, 80}, [2] = {70, 30}, [3] = {100, 0}}
	tGl = tGl[nPbIndex]
	local tHFCfg = ctPetHFConf[tZProp:GetID()]
	if not tHFCfg then
		return 
	end
	local nRate = math.random(1,100)
	local tSkil1 = {}
	local tSk = {}
	local tSkType = tHFCfg.tSkType
	local tSkillList = {}
	if tGl[1] >= nRate then
		--两个技能
		tSkillList[#tSkillList+1] = tHFCfg.tSkNd[math.random(1,#tHFCfg.tSkNd)][1]
		self:PetHFHandle(tHFCfg.tSkNd, tSkillList)
	else
		tSkillList[#tSkillList+1] = tHFCfg.tSkSt[math.random(1,#tHFCfg.tSkSt)][1]
	end
	return tSkillList
end

function CPet:PetHFHandle(tConfList, tSkillList)
	local tTmpConfList = table.DeepCopy(tConfList, true)
	local tTmpSkillMap = {}
	for _, nSkillID in pairs(tSkillList) do tTmpSkillMap[nSkillID]=1 end

	while #tTmpConfList > 0 do
		local nIndex = math.random(#tTmpConfList)
		local nSkID = tTmpConfList[nIndex][1]
		if tTmpSkillMap[nSkID] then
			table.remove(tTmpConfList, nIndex)
		else
			table.insert(tSkillList, nSkID)
			break
		end
	end
end

function CPet:GetHFSkllPb(nLen)
	if nLen == 2 then
		return 1
	elseif nLen == 3 then
		return 2
	elseif nLen == 4 then
		return 3
	end
end

--护符重置
function CPet:PetTalismanResetReq(nID, nPos, bFlag, nType, nUseType)
	if nUseType == 1 then
		self:HFEquReset(ID, nPos, bFlag, nType)
	elseif nUseType == 2 then
		self:HFResetSavaReq(nID, nPos, nType)
	end
end

function CPet:HFEquReset(nID, nPos, bFlag, nType)
	--1为背包护符,2为宠物身上护符
	local oPetEqu
	local tPet
	if nType == 1 then
		oPetEqu = self.m_oRole.m_oKnapsack:GetItem(nPos)
	else
		tPet = self.m_oPetMap[nPos]
		if not tPet then
			return self.m_oRole:Tips("宠物数据错误")
		end
		oPetEqu = tPet.tEquitList[gtPetEquPart.eTalisman]
	end
	if not oPetEqu then return self.m_oRole:Tips("护符装备不存在") end
	local nEquitId = oPetEqu:GetID()

	local tEquiCfg = ctPetHFConf[nEquitId]
	local tCost = tEquiCfg.tCost[1]
	local nItemID = tCost[1]
	local nItemNum = tCost[2]
	assert(ctPropConf[nItemID], "道具配置错误" .. nItemID)
	local fnSubPropCallback = function (bRet)
		if not bRet then return end
		-- oPetEqu.m_PetEquAttrList = self:SKillHFHandle(nEquitId)
		--oPetEqu.m_tEquResetAttr =  --self:SKillHFHandle(nEquitId)
		oPetEqu.m_tEquResetAttr = oPetEqu:SkillHandle(nEquitId, true)
		local tMsg = {tSkillList = {}, nUseType = 1}
		for _, nSkillID in ipairs(oPetEqu.m_tEquResetAttr or {}) do
			table.insert(tMsg.tSkillList, {nSkillID = nSkillID})
		end
		self.m_oRole:SendMsg("PetTalismanResetRet", tMsg)
		self.m_oRole:Tips("重置成功")
		if nType == 2 then
			self:PetHFSkill(tPet, nPos, oPetEqu)
		end
		self:MarkDirty(true)
	end
	local bUseYuanBao = true
	if bFlag then
		bUseYuanBao = false
	end
	local tItemCostList = {{gtItemType.eProp, nItemID, nItemNum}}
	self.m_oRole:SubItemByYuanbao(tItemCostList, "护符重置消耗", fnSubPropCallback, bUseYuanBao)
end

function CPet:PetHFSkill(tPet, nPos, oPetEqu)
	tPet.tHfsk = {}
	for _, nID in ipairs(oPetEqu.m_PetEquAttrList or {}) do
		tPet.tHfsk[#tPet.tHfsk+1] = nID
	end
	self:PetInfoChange(tPet)
	self:PetChangeSend(tPet, nPos, 3)
end


--护符重置保存请求
function CPet:HFResetSavaReq(nEquitId, nGrid, nType)
	local _EquAttrChange = function (oPetEqu,  nGrid, tPet)
		oPetEqu:SetAttr(oPetEqu:GetResetAttr())
		oPetEqu:ClearResetAttr()
		if nType == 2 then
			self:PetHFSkill(tPet, nGrid, oPetEqu)
		end
		local tMsg = {nUseType = 2, tSkillList = {}}
		for _, nSkillID in ipairs(oPetEqu.m_PetEquAttrList or {}) do
			table.insert(tMsg.tSkillList, {nSkillID = nSkillID})
		end
		self.m_oRole:SendMsg("PetTalismanResetRet", tMsg)
		self.m_oRole:Tips("重置成功")
	end

	local oPetEqu
	local tPet
	if nType == 2 then
		tPet = self:GetPetGrid(nGrid)
		assert(tPet, "宠物信息不存在" .. nGrid)
		oPetEqu = tPet.tEquitList[gtPetEquPart.eTalisman]
		assert(oPetEqu,"宠物装备信息不存在")
		
	elseif nType == 1 then
		oPetEqu = self.m_oRole.m_oKnapsack:GetItem(nGrid)
		assert(oPetEqu, "宠物装备信息不存在")
	end
	if next(oPetEqu:GetResetAttr()) then
		_EquAttrChange(oPetEqu, nGrid, tPet)
	end
end

function CPet:SKillHFHandle(nID)
	local tHFCfg = ctPetHFConf[nID]
	assert(tHFCfg, "护符装备配置错误" .. nID)
	local tSkType = tHFCfg.tSkType
	local nSkWon = tSkType[1][1]
	local nTwo = tSkType[2][1]
	local tSkillList = {}
	local nRate = math.random(1,100)
	if tHFCfg.nLevel == 1 or tHFCfg.nLevel == 2 then
		if nSkWon >= nRate then
			tSkillList[#tSkillList+1] = tHFCfg.tSkNd[math.random(1,#tHFCfg.tSkNd)][1]
		end
		if nTwo >= nRate then
			self:PetHFHandle(tHFCfg.tSkNd, tSkillList)
		end
	else
		if tHFCfg.nLevel == 3 then
			if nSkWon >= nRate then
				tSkillList[#tSkillList+1] = tHFCfg.tSkSt[math.random(1,#tHFCfg.tSkSt)][1]
			end
			if nTwo >= nRate then
				tSkillList[#tSkillList+1] = tHFCfg.tSkNd[math.random(1,#tHFCfg.tSkNd)][1]
			end
		elseif tHFCfg.nLevel == 4 then

			if nSkWon >= nRate then
				tSkillList[#tSkillList+1] = tHFCfg.tSkSt[math.random(1,#tHFCfg.tSkSt)][1]
			end

			if nTwo >= nRate then
				tSkillList[#tSkillList+1] = tHFCfg.tSkNd[math.random(1,#tHFCfg.tSkNd)][1]
			end
		end
	end
	return tSkillList
end
--宠物装备初始化
function CPet:PetEquitAttrHandle(nAttr, tEqu)
	--tBasePropertyFactor={{65,100,100,},{25,120,130,},{10,140,150,},}
	local tTb = tEqu.tBasePropertyFactor
	local tmz = {{math.floor(tTb[1][1]/1000), math.floor(tTb[1][2]/100),math.floor(tTb[1][3]/100)},
	{math.floor(tTb[2][1]/100),math.random(tTb[2][2]),math.floor(tTb[2][3]/100)},{1,tTb[3][2]}}

	local nAttrs = 0
	local tArate = tTb[math.random(1,#tmz)]
	nAttrs = math.random(math.floor(nAttr * tArate[2]/100), math.floor(nAttr * tArate[3]/100))
	return nAttrs
end

function CPet:GetPetList()
	--取所有宠物的Pos
	local tPosList = {}
	for nPos, tPet in pairs(self.m_oPetMap) do
		if tPet then
			tPosList[#tPosList+1] = nPos
		end
	end
	return tPosList
end

function CPet:GetBattleData(nPetPos)
	if not self.m_oPetMap[nPetPos] then
		return print("宠物信息不存在") 
	end
	local tPet = self.m_oPetMap[nPetPos]
	if tPet.life ~= nForeverLife and tPet.life <= 50 then
		return LuaTrace("宠物寿命<=50不能出战")
	end
	--恢复气血和蓝
	if self.m_oRole.m_oRoleState:GetBaoShiTimes() > 0 then
		self:RecoverMPHP(nPetPos)
	end
	
    local tBTData = {}
    --基本信息 
    tBTData.nObjID = tPet.nId
    tBTData.nObjType = gtObjType.ePet
    tBTData.sObjName = tPet.sName
    tBTData.nRoleID = self.m_oRole:GetID()
    tBTData.sModel = tPet.sModelNumber
    tBTData.nLevel = tPet.nPetLv
    tBTData.nPos = tPet.nPos
    tBTData.nExp = tPet.exp
    tBTData.nNextExp = ctPetLevelConf[tPet.nPetLv].nNeedExp
    tBTData.sGrade = self:GetGrade(nPetPos)

    --战斗属性
    tBTData.tBattleAttr = {}
    for _, v in pairs(gtBAT) do
    	tBTData.tBattleAttr[v] = tPet.tBaseAttr[v] or 0
    end

    --HP/MP上限
    tBTData.nMaxHP = tBTData.tBattleAttr[gtBAT.eQX]
    tBTData.nMaxMP = tBTData.tBattleAttr[gtBAT.eMF]
    
    --当前HP/MP
    tBTData.tBattleAttr[gtBAT.eQX] = tPet.nDQBlood
    tBTData.tBattleAttr[gtBAT.eMF] = tPet.nDQWorkHard

	--自动战斗
	tBTData.bAuto = true
	--武器攻击
	tBTData.nWeaponAtk = self:GetWeaponAtk()

	--宠物
	tBTData.tPetMap = {}
	--道具列表
	tBTData.tPropList = {}

	--主动被动技能
	tBTData.tActSkillMap,tBTData.tPasSkillMap = self:GetSKill(tPet.tSKillList, tPet.nPetLv, tPet.tHfsk)
	
	--修炼系统
	tBTData.tPracticeMap = self.m_oRole.m_oPractice:GetPracticeMap()

	tBTData.nAutoInst = tPet.nAutoInst or 0
	tBTData.nAutoSkill = tPet.nAutoSkill or 0
	tBTData.nManualSkill = tPet.nManualSkill or 0

    return tBTData
end
function CPet:GetWeaponAtk(tEquitList)
	local nValue = 0
	return nValue
end

--竞技场机器人模块也有用到，改动时请注意下
function CPet:GetSKill(tSkillList, nPetLv, tHfsk)
	local tActSkillMap = {} --主动技能
	local tPasSkillMap = {} --被动技能
	tSkillList = self:SkillMerge(tSkillList, tHfsk)
	for i = 1, #tSkillList, 1 do
		local nSkillID = tSkillList[i].nId
		local tSkillConf = ctPetSkillConf[nSkillID] 
		if tSkillConf and  tSkillConf.nActiveSkill == 1 then
			tActSkillMap[nSkillID] = {nLevel = nPetLv, sName = tSkillConf.sName}

		elseif tSkillConf and tSkillConf.nActiveSkill == 0 then
			tPasSkillMap[nSkillID] = {nLevel = nPetLv, sName = tSkillConf.sName}

			--如果同时有低级和高级技能，只有高级技能起效
			if tPasSkillMap[nSkillID-100] then
				tPasSkillMap[nSkillID-100] = nil
			end
			if tPasSkillMap[nSkillID+100] then
				tPasSkillMap[nSkillID] = nil
			end
		end
	end

	--冲突无效技能
	for nSkillID, tSkill in pairs(tPasSkillMap) do
		if tSkill then
			local tSkillConf = ctPetSkillConf[nSkillID] 
			for _, tConflictSkill in ipairs(tSkillConf.tConflictSkill) do
				--当在遍历过程中你给表中并不存在的域赋值(即使赋值为nil)， next 的行为是未定义的。 然而你可以去修改那些已存在的域。 特别指出，你可以清除一些已存在的域。
				if tPasSkillMap[tConflictSkill[1]] then
					tPasSkillMap[tConflictSkill[1]] = nil
				end
			end
		end
	end

	return tActSkillMap, tPasSkillMap
end

--GM
function CPet:OutPetInfo()
end

function CPet:SkillMerge(tSkillList, tHFSkill)
	local tTempSkill = {}
	for _, tSkill in ipairs(tSkillList or {}) do
		table.insert(tTempSkill, tSkill)
	end
	--nId = skillsId[1], nFalg = false}
	for _, nSkillID in ipairs(tHFSkill or {}) do
		table.insert(tTempSkill, {nId = nSkillID, nFalg = false})
	end
	return tTempSkill
end

function CPet:AddCiShu()
	self.m_nExpansionTimes = self.m_nExpansionTimes + 1
	self:MarkDirty(true)
	self.m_oRole:SaveData()
end

function CPet:ClearPetMap()
	self.m_oPetMap = {}
	self.m_oRole.m_tPVEActData = {}
	self:AttrListReq()
	self:MarkDirty(true)
	self.m_oRole:Tips("清除成功")
end

function CPet:CmdAddExp(nPos, nExp)
	local tPetObj = self.m_oPetMap[nPos]
	if not tPetObj then
		return 
	end
	self:AddExpUpdate(tPetObj, nPos, nExp)
	
end

function CPet:AddExpUpdate(tPetObj, nPos, nExp)
	local nPetLv = tPetObj.nPetLv
	local nLv = tPetObj.nPetLv
	tPetObj.exp = tPetObj.exp + nExp
	for nLevel = nPetLv, #ctPetLevelConf, 1 do
		if tPetObj.exp >= ctPetLevelConf[nLevel].nNeedExp then 
			if ctPetLevelConf[nLevel+1] then
				tPetObj.nPetLv = ctPetLevelConf[nLevel+1].nLevel
				tPetObj.exp = tPetObj.exp - ctPetLevelConf[nLevel].nNeedExp
				if tPetObj.nPetLv - self.m_oRole:GetLevel() >= 5 then
					break
				end
			end
		else
			break
		end
	end
	
	if tPetObj.nPetLv ~= nLv then
		--属性更新
		for _, nKey in pairs(gtMAT) do
			tPetObj.tBaseAttr[nKey] = tPetObj.tBaseAttr[nKey] + 1 * (tPetObj.nPetLv - nLv)
		end

		tPetObj.qld = tPetObj.qld + 5 * (tPetObj.nPetLv - nLv)
		if tPetObj.nAutoPointState == gtPetAutoPointState.eAutoState then
			self:AutoAddPoint(tPetObj, nPos)
		end
		self:PetInfoChange(tPetObj)
		self:MarkDirty(true)
		self:PetUpdateAttr(tPetObj,3, nPos)
	else
		self:MarkDirty(true)
		self:PetUpdateAttr(tPetObj,2, nPos)

	end
end

function CPet:DeletePet(nPos)
	if not self.m_oPetMap[nPos] then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	self.m_oPetMap[nPos] = nil
	self:MarkDirty(true)
	self:PetChangeSend(self.m_oPetMap[nPos], nPos, 2)
end


function CPet:AddLife(nPos, nValue)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end
	tItem.life = math.min(nMaxLife, tItem.life+nValue)
	self:MarkDirty(true)
	self:PetChangeSend(tItem, nPos, 3)
end

function CPet:AddPLayerLv(nLevel)
	self.m_oRole.m_nLevel = self.m_oRole.m_nLevel + nLevel
	self:MarkDirty(true)
end

function CPet:Advanced(nPos)
	local tItem = self.m_oPetMap[nPos]
	if not tItem then
		return self.m_oRole:Tips("宠物信息不存在")
	end

	if self.m_oRole:GetLevel() < 65 then
		return self.m_oRole:Tips("玩家65级开放宠物进化系统")
	end

	if tItem.AdvancedNum > 2 then
		return self.m_oRole:Tips("进阶次数达到最高")
	end
	local tAdvancedCost = ctPetAdvancedConf[tItem.nPetType]
	local tLevel = tAdvancedCost.tLevel
	local tCost = tAdvancedCost.tCost
	if tItem.nPetLv < tLevel[tItem.AdvancedNum] then
		return self.m_oRole:Tips("宠物等级不足")
	end
	for i = 1, 5, 1 do
		tItem.tUmQfcAttr[i] = tItem.tUmQfcAttr[i] + 50
		tItem.tCurQfcAttr[i] = tItem.tCurQfcAttr[i] + 50
	end
	local zZSum = self:PetSum(tItem.tCurQfcAttr)
	tItem.nFighting = zZSum + self:SkillsScore(tItem) + 5000
	self:PetInfoChange(tItem)
	self:MarkDirty(true)
	--属性更新
	self:PetUpdateAttr(ItemTb, 3, nPos)
end

--恢复MPHP
function CPet:RecoverMPHP(nPosID)
	local tPet = self.m_oPetMap[nPosID]
	if not tPet then
		return
	end
	local bChange = false
	if tPet.nDQBlood ~= tPet.tBaseAttr[gtBAT.eQX] then
		tPet.nDQBlood = tPet.tBaseAttr[gtBAT.eQX]
		self:MarkDirty(true)
		bChange = true
	end
	if tPet.nDQWorkHard ~= tPet.tBaseAttr[gtBAT.eMF] then
		tPet.nDQWorkHard = tPet.tBaseAttr[gtBAT.eMF]
		self:MarkDirty(true)
		bChange = true
	end
	if bChange then
		self:PetChangeSend(tPet, nPosID, 3)
	end
end

--战斗结束
function CPet:OnBattleEnd(nPosID, tBTRes, tExtData)
	local tPet = self.m_oPetMap[nPosID]
	if not tPet then
		return LuaTrace("宠物不存在")
	end
    tExtData = tExtData or {}
	tPet.nDQBlood = tBTRes.nHP
	tPet.nDQWorkHard = tBTRes.nMP
	tPet.nManualSkill = tBTRes.nManualSkill
	tPet.nAutoInst = tBTRes.nAutoInst
	tPet.nAutoSkill = tBTRes.nAutoSkill
	tPet.nBattleCount = (tPet.nBattleCount or 0) + 1
	self:MarkDirty(true)

    --饱食度相关
    if self.m_oRole.m_oRoleState:CheckSubBaoShi(tBTRes.nBattleID, tExtData.nBattleDupType) then
		self:RecoverMPHP(nPosID)
    end

	--非永生宠物在非PVP玩法中扣除寿命
	if tPet.life ~= nForeverLife and tBTRes.nBattleType == gtBTT.ePVE then
		if tBTRes.nHP == 0 then	
			tPet.life = math.max(0, tPet.life-50)
		else
			tPet.life = math.max(0, tPet.life-1)
		end
		self:MarkDirty(true)
		if tPet.life <= 50 then
			self:CombatReq(tPet.nId, tPet.nPos, 1, true)
		end
		self:PetChangeSend(tPet, tPet.nPos, 3)
	end
end

--战斗开始
function CPet:OnBattleBegin(nPosID, nBattleID)
end

function CPet:MaxFighting()
	local nMaxFighting = 0
	for nPos, tPetData in pairs(self.m_oPetMap) do
		if tPetData.jnpf > nMaxFighting then
			nMaxFighting = tPetData.jnpf
		end
	end
	return nMaxFighting
end

--宠物总评分变化
function CPet:PetScoreChange()
	local tList = {}
	for nPos, tPet in pairs(self.m_oPetMap) do
		table.insert(tList, tPet)
	end
	table.sort(tList, function(t1, t2) return t1.jnpf>t2.jnpf end)

	local tMaxPet
	local nOldTmpPetPowerSum = self.m_nTmpPetPowerSum

	self.m_nTmpPetPowerSum = 0
	for k = 1, 3 do --最高战力的3个宠物
		local tPet = tList[k]
		if tPet then
			if k == 1 then
				tMaxPet = tPet
			end
			self.m_nTmpPetPowerSum = self.m_nTmpPetPowerSum + tPet.jnpf
		end
	end
	self.m_nTmpPetPowerSum = math.floor(self.m_nTmpPetPowerSum)

	if tMaxPet then
		local nServerID = self.m_oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID, 20)
		Network.oRemoteCall:Call("PetScoreChangeReq", nServerID, nServiceID, 0, self.m_oRole:GetID(), tMaxPet.nPos, tMaxPet.sName, tMaxPet.jnpf)
	end

	if nOldTmpPetPowerSum ~= self.m_nTmpPetPowerSum then
		self:MarkDirty(true)
		self.m_oRole:UpdateColligatePower()
	end
end

--取最高的3个宠物战力和
function CPet:GetPetPowerSum(nNum)
	assert(nNum == 3, "宠物数量错误")
	return (self.m_nTmpPetPowerSum or 0)
end

function CPet:GetMaxPetSkillPower()
	local nMaxFighting = 0
	for _, tPet in pairs(self.m_oPetMap) do
		local nFighting = self:SkillsScore(tPet)
		if nFighting > nMaxFighting then
			nMaxFighting = nFighting
		end
	end
	return nMaxFighting
end

function CPet:GetMaxPetPower()
	local nMaxFighting = 0
	for _, tPet in pairs(self.m_oPetMap) do
		if tPet.jnpf > nMaxFighting then
			nMaxFighting = tPet.jnpf
		end
	end
	return nMaxFighting
end

function CPet:PetTalismanPBReq(nZGrid, nFGrid)
	local tZProp = self.m_oRole.m_oKnapsack:GetItem(nZGrid)
	local tFProp = self.m_oRole.m_oKnapsack:GetItem(nFGrid)
	if not tZProp or not tFProp then
		return self.m_oRole:Tips("玩家没有对应的装备")
	end
	local nZSkLen = #tZProp.m_PetEquAttrList
	local nFSkLen = #tFProp.m_PetEquAttrList
	local nPbIndex = self:GetHFSkllPb(nZSkLen+nFSkLen)
	--t = {20%,80% --20为双的概率,80为单的概率}
	local tGl = {[1] = {20, 80}, [2] = {70, 30}, [3] = {100, 0}}
	tGl = tGl[nPbIndex]
	local nProbability = tGl[1] or 0
	local tMsg = {nProbability = nProbability}
	self.m_oRole:SendMsg("PetTalismanPBRet",  tMsg)
end

--使用道具并上阵
function CPet:PetPropUSEReq(nPropID)
	local oProp = self.m_oRole.m_oKnapsack:GetItem(nPropID)
	if oProp:GetPropConf().nType ~= 38 then
		return self.m_oRole:Tips("道具类型错误")
	end
	oProp:Use(1, true)
end


--直接使用道具表配置属性
function CPet:UsePropPetHandle(tPet)
	local tPetCfg =  ctPetPropUseConf[tPet.nId]
	if not tPetCfg then
		return 
	end
	local tPetInfoCfg = ctPetInfoConf[tPet.nId]
	tPet.czl = tPetCfg.nGrowthRate
	tPet.nPetLv = tPetCfg.nLevel
	tPet.qld = tPet.nPetLv * 5

	self:PetBasicAttr(tPetInfoCfg, tPet)
	self:PetQualification(tPet, tPetCfg)
	self:PetSkillProp(tPet, tPetCfg)


	self:PetClacAttr(tPet)
	self:PetInfoChange(tPet)
	self:FirstGetPetCheck(tPet, true)
	self:MarkDirty(true)
	self:PetChangeSend(tPet, tPet.nPos, 1)
end

function CPet:PetQualification(tPet, tPetCfg)
	for nKey = 1, 5 do
		tPet.tCurQfcAttr[nKey] =  tPetCfg.tCurrentQualification[nKey][1] or tPet.tCurQfcAttr[nKey]
		tPet.tUmQfcAttr[nKey] = tPetCfg.tUpperLimitQualification[nKey][1] or tPet.tUmQfcAttr[nKey]
	end
end

function CPet:PetSkillProp(tPet, tPetCfg)
	local tSkill = tPetCfg.tSkill
	local tTmpSkill = {}
	for _, tSkillList in ipairs(tSkill) do
		tTmpSkill[#tTmpSkill+1] = { nId = tSkillList[1], nFalg = false}
	end
	tPet.tSKillList = tTmpSkill
end


function CPet:GetPetGrid(nGrid)
	return self.m_oPetMap[nGrid]
end

--招募信息保存
function CPet:PetSavaRecruitReq(nRecruitLevel)
	assert(nRecruitLevel or nRecruitLevel > 0, "招募信息参数错误"..nRecruitLevel)
	self.m_nRecruitLevel = nRecruitLevel
	self:MarkDirty(true)
end

function CPet:GetYuShouGrowthID()
	return 4
end

function CPet:IsYuShouSysOpen(bTips)
	return self.m_oRole:IsSysOpen(93, bTips)
end

function CPet:GetYuShouLevel()
	return self.m_tYuShouData and self.m_tYuShouData.nLevel or 0
end

function CPet:GetYuShouLimitLevel()
	local nID = self:GetYuShouGrowthID()
	return math.min(self.m_oRole:GetLevel(), ctRoleGrowthConf.GetConfMaxLevel(nID))
end

function CPet:SetYuShouLevel(nLevel)
	local nID = self:GetYuShouGrowthID()
	assert(nLevel > 0 and nLevel <= ctRoleGrowthConf.GetConfMaxLevel(nID))
	self.m_tYuShouData.nLevel = nLevel
	self:MarkDirty(true)
end

function CPet:GetYuShouExp()
	return self.m_tYuShouData and self.m_tYuShouData.nExp or 0
end

function CPet:GetYuShouAttr()
	if not self:IsYuShouSysOpen() then 
		return {} 
	end
	return self.m_tYuShouData.tAttrList or {} 
end

function CPet:GetYuShouAttrRatio()
	local nID = self:GetYuShouGrowthID()
	local tConf = ctRoleGrowthConf[nID]
	return tConf.nRatio or 1
end

function CPet:GetYuShouScore()
	if not self:IsYuShouSysOpen() then 
		return 0 
	end
	return math.floor(self:GetYuShouLevel()*1000*self:GetYuShouAttrRatio())
end

function CPet:UpdateYuShouAttr()
	local nParam = self:GetYuShouScore()
	self.m_tYuShouData.tAttrList = self.m_oRole:CalcModuleGrowthAttr(nParam) or {}
end

function CPet:OnYuShouLevelChange()
	self:UpdateYuShouAttr()
	self.m_oRole:UpdateAttr()
end

function CPet:AddYuShouExp(nAddExp)
	local nID = self:GetYuShouGrowthID()
	local nCurLevel = self:GetYuShouLevel()
	local nLimitLevel = self:GetYuShouLimitLevel()
	local nCurExp = self:GetYuShouExp()
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	self:SetYuShouLevel(nTarLevel)
	self.m_tYuShouData.nExp = nTarExp
	self:MarkDirty(true)
	if nCurLevel ~= nTarLevel then 
		self:OnYuShouLevelChange()
	end
end

function CPet:SyncYuShouData()
	local tMsg = {}
	tMsg.nLevel = self.m_tYuShouData.nLevel
	tMsg.nExp = self.m_tYuShouData.nExp
	tMsg.tAttrList = {}
	for nAttrID, nAttrVal in pairs(self.m_tYuShouData.tAttrList) do 
		table.insert(tMsg.tAttrList, {nAttrID = nAttrID, nAttrVal = nAttrVal})
	end
	tMsg.nScore = self:GetYuShouScore()
	self.m_oRole:SendMsg("PetYuShouInfoRet", tMsg)
end

function CPet:YuShouLevelUpReq()
	if not self:IsYuShouSysOpen(true) then 
		return 
	end
	local oRole = self.m_oRole
	local nGrowthID = self:GetYuShouGrowthID()
	local nCurLevel = self:GetYuShouLevel()
	local nLimitLevel = self:GetYuShouLimitLevel()
	local nCurExp = self:GetYuShouExp()
	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	if nCurLevel >= nLimitLevel then 
		oRole:Tips("已达到当前限制等级，请先提升角色等级")
		return 
	end

	local nMaxAddExp = ctRoleGrowthConf.GetMaxAddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp)
	if nMaxAddExp <= 0 then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	local tCost = ctRoleGrowthConf.GetExpItemCost(nGrowthID, nMaxAddExp)
	assert(next(tCost))
	local nItemType = tCost[1]
	local nItemID = tCost[2]
	local nMaxItemNum = tCost[3]
	assert(nItemType > 0 and nItemID > 0 and nMaxItemNum > 0)
	local nKeepNum = oRole:ItemCount(nItemType, nItemID)
	if nKeepNum <= 0 then 
		oRole:Tips("材料不足，无法升级")
		return 
	end
	local nCostNum = math.min(nKeepNum, nMaxItemNum)
	local nAddExp = ctRoleGrowthConf.GetItemExp(nGrowthID, nItemType, nItemID, nCostNum)
	assert(nAddExp and nAddExp > 0)

	local tCost = {{nItemType, nItemID, nCostNum}, }
	if not oRole:CheckSubShowNotEnoughTips(tCost, "宠物御兽升级", true) then 
		return 
	end
	self:AddYuShouExp(nAddExp)
	self:SyncYuShouData()

	local nResultLevel = self:GetYuShouLevel()
	local sContent = nil 
	local sModuleName = "御兽"
	local sPropName = ctPropConf:GetFormattedName(nItemID) --暂时只支持道具
	if nResultLevel > nCurLevel then 
		local sTemplate = "消耗%d个%s, %s等级提升到%d级"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nResultLevel)
	else
		local sTemplate = "消耗%d个%s, %s增加%d经验"
		sContent = string.format(sTemplate, nCostNum, sPropName, sModuleName, nAddExp)
	end
	if sContent then 
		oRole:Tips(sContent)
	end

	local tMsg = {}
	tMsg.nOldLevel = nCurLevel
	tMsg.nCurLevel = self:GetYuShouLevel()
	oRole:SendMsg("PetYuShouLevelUpRet", tMsg)
end

-----------------------------------------------------
--宠物觉醒
function CPet:GetReviveGrowthID()
	return 10
end

function CPet:IsReviveSysOpen(bTips)
	return self.m_oRole:IsSysOpen(99, bTips)
end

function CPet:GetReviveLimitLevel()
	local nID = self:GetReviveGrowthID()
	return ctRoleGrowthConf.GetConfMaxLevel(nID)
end

function CPet:OnReviveLevelUp(nPet)
	local oPet = self:GetPetByPos(nPet)
	if not oPet then 
		return 
	end
	self:PetUpdateAttr(oPet, 3, nPet)
end

function CPet:AddReviveExp(nPet, nAddExp)
	local oPet = self:GetPetByPos(nPet)
	assert(oPet)
	local nGrowthID = self:GetReviveGrowthID()
	local nCurLevel = oPet.tRevive.nLevel
	local nLimitLevel = self:GetReviveLimitLevel()
	local nCurExp = oPet.tRevive.nExp
	local nTarLevel, nTarExp = ctRoleGrowthConf.AddExp(nGrowthID, nCurLevel, nLimitLevel, nCurExp, nAddExp)
	oPet.tRevive.nLevel = nTarLevel
	oPet.tRevive.nExp = nTarExp
	self:MarkDirty(true)
	self:OnReviveLevelUp(nPet)
end

function CPet:ReviveLevelUpReq(nPet, nPropID, nPropNum)
	if nPet <= 0 or nPropID <= 0 or nPropNum <= 0 then 
		self.m_oRole:Tips("参数不合法")
		return 
	end
	if not self:IsReviveSysOpen(true) then 
		return
	end
	local oRole = self.m_oRole
	local oPet = self:GetPetByPos(nPet)
	if not oPet then 
		oRole:Tips("宠物不存在")
		return 
	end
	if nPropNum <= 0 then 
		oRole:Tips("参数错误")
		return
	end
	local nGrowthID = self:GetReviveGrowthID()
	local tGrowthConf = ctRoleGrowthConf[nGrowthID]
	assert(tGrowthConf)
	local bItemValid = false
	local nSingleExp = 0
	for _, tItem in ipairs(tGrowthConf.tExpProp) do 
		local nItemType = tItem[1]
		local nItemID = tItem[2]
		local nAddExp  = tItem[3]
		if nItemType > 0 and nPropID > 0 and nPropID == nItemID then 
			bItemValid = true
			nSingleExp = nAddExp
			break
		end
	end
	if not bItemValid then 
		oRole:Tips("道具不合法")
		return 
	end
	assert(nSingleExp > 0, "配置错误")

	local nCurLevel = oPet.tRevive.nLevel
	local nLimitLevel = self:GetReviveLimitLevel()
	local nCurExp = oPet.tRevive.nExp

	local tOldData = {}
	tOldData.nLevel = nCurLevel
	tOldData.nExp = nCurExp

	if nCurLevel >= ctRoleGrowthConf.GetConfMaxLevel(nGrowthID) then 
		oRole:Tips("当前已达最高等级")
		return 
	end
	-- if nCurLevel >= nLimitLevel then 
	-- 	oRole:Tips("已达到当前限制等级，请先提升角色等级")
	-- 	return 
	-- end

	local nTotalAddExp = nPropNum * nSingleExp
	local nTotalExp = nTotalAddExp + nCurExp

	local nMaxAddExp = 0
	local tLevelConfList = ctRoleGrowthConf.GetLevelConfList(nGrowthID)
	for k = nCurLevel + 1, nLimitLevel do 
		local tLevelConf = tLevelConfList[k]
		assert(tLevelConf)
		nMaxAddExp = nMaxAddExp + tLevelConf.nExp
		if nTotalExp <= nMaxAddExp then 
			break
		end
	end
	if nMaxAddExp < nTotalExp then 
		local nAllowed = nMaxAddExp - nCurExp
		nPropNum = math.min(math.ceil(nAllowed/nSingleExp), nPropNum) --经验溢出, 修正下数量
	end
	assert(nPropNum > 0)

	local tCost = {gtItemType.eProp, nPropID, nPropNum}
	local tCostList = {}
	table.insert(tCostList, tCost)
	if not oRole:CheckSubShowNotEnoughTips(tCostList, "宠物觉醒", true) then 
		return 
	end
	local nTotalAddExp = nPropNum * nSingleExp
	self:AddReviveExp(nPet, nTotalAddExp)

	local tMsg = {}
	tMsg.nPetPos = nPet
	tMsg.nPropID = nPropID
	tMsg.nPropNum = nPropNum

	tMsg.tOldData = tOldData
	local tCurData = {}
	tCurData.nLevel = oPet.tRevive.nLevel
	tCurData.nExp = oPet.tRevive.nExp
	tMsg.tCurData = tCurData
	self.m_oRole:SendMsg("PetReviveLevelUpRet", tMsg)
end

function CPet:GMGetAllPetInfo()
	local tPet = {}
	for nPos, tPetObj in pairs(self.m_oPetMap) do
		local tPetInfo = {}
		tPetInfo.nID = tPetObj.nId
		tPetInfo.nPos = tPetObj.nPos
		tPetInfo.sName = tPetObj.sName
		tPetInfo.sRatings = tPetObj.ratingLevel
		tPetInfo.nType = tPetObj.nPetType
		tPetInfo.nScore = tPetObj.jnpf
		tPetInfo.nBlood = tPetObj.tBaseAttr[gtBAT.eQX]
		tPetInfo.nWorkHard = tPetObj.tBaseAttr[gtBAT.eMF]
		tPetInfo.nExp = tPetObj.exp
		tPetInfo.nStatus = tPetObj.status
		table.insert(tPet, tPetInfo)
	end
	return tPet
end

function CPet:GMDeletePet(nPos)
	if not self.m_oPetMap[nPos] or self.m_oPetMap[nPos].status == gtSTT.eCZ then
		 return false
	 end
	 return self:SubGridPet(nPos, "GM指令消耗")
end