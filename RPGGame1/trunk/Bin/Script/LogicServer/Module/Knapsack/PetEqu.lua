local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPetEqu:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
	--自己数据

	self.m_nID = nID
	self.m_PetEquAttrList = {}
	self.m_tEquResetAttr = {}	--重置属性
	self:PetInitEqu(nID) --宠物装备属性--不同的装备有不同的作用,护符加技能,饰品加上限资质.....
end

function CPetEqu:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
	--自己数据
	self.m_PetEquAttrList = tData.PetEquAttrList

end 

function CPetEqu:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	--自己数据
	tData.m_nID = self.m_nID
	tData.PetEquAttrList = self.m_PetEquAttrList
	return tData
end

function CPetEqu:GetConf()
	return assert(ctPetHelmetConf[self.m_nID])
 end

 function CPetEqu:GetResetAttr()
 	return self.m_tEquResetAttr
 end

function CPetEqu:SetAttr(tAttr)
	if next(tAttr) then
		self.m_PetEquAttrList = tAttr
	end
end

function CPetEqu:ClearResetAttr()
	self.m_tEquResetAttr = {}
end

function CPetEqu:GetEquiAttr() return assert(self.m_PetEquAttrList) end
function CPetEqu:GetLevel(nID)
	return assert(ctPetHelmetConf[self.m_nID]).nLevel
end

function CPetEqu:GetDetailInfo(nGrid)
	local tEquInfo = {}
	tEquInfo.tPetAccessories = 0
	local tEqu = ctPetHelmetConf[self.m_nID]
	if not tEqu then return end
	tEquInfo.tPetCollarHelmet = {}
	tEquInfo.tPetTalisman = {}
	if tEqu.nEquipPartType == gtPetEquPart.eCollar or tEqu.nEquipPartType == gtPetEquPart.eArmor then
		for nAttrID, nAttr in pairs(self.m_PetEquAttrList or {}) do
			tEquInfo.tPetCollarHelmet[#tEquInfo.tPetCollarHelmet+1] = {nAttrID = nAttrID, nAttrValue = nAttr}
		end
	elseif tEqu.nEquipPartType == gtPetEquPart.eTalisman then
		for _, nSkillID in pairs(self.m_PetEquAttrList or {}) do
			tEquInfo.tPetTalisman[#tEquInfo.tPetTalisman+1] = {nSkillID = nSkillID, nHFSKill = 1}
		end
	elseif tEqu.nEquipPartType == gtPetEquPart.eaccies then
		tEquInfo.tPetAccessories = tEqu.nPropertyLimit
	end
	tEquInfo.nID = self.m_nID
	tEquInfo.nType = tEqu.nEquipPartType
	tEquInfo.nLevel = tEqu.nLevel
	tEquInfo.nGrid = (nGrid or 0)
	print("tEquInfo========", tEquInfo)
	return tEquInfo
end

-- --装备位置定义
-- gtPetEquPart = 
-- {
-- 	eCollar= 1, 	--表示头盔
-- 	eArmor	= 2,	--表示为项圈
-- 	eTalisman = 3,	--表示护符
-- 	eaccies	= 4,	--表示饰品
-- }

--宠物初始化装备
function CPetEqu:PetInitEqu(nID, nGrid)
	local tItem = ctPetHelmetConf[nID]
	if not tItem then
		return
	end
	--不同装备做不同的处理
	if tItem.nEquipPartType == gtPetEquPart.eArmor then
   		 local nIndex = math.random(1,4)
		local nAttr = self:PetEquitAttrHandle(tItem.tAttr[nIndex][2], tItem.tBasePropertyFactor)
   		self.m_PetEquAttrList[tItem.tAttr[nIndex][1]] = nAttr
	elseif tItem.nEquipPartType == gtPetEquPart.eCollar then
		nAttr = self:PetEquitAttrHandle(tItem.tAttr[1][2], tItem.tBasePropertyFactor)
		self.m_PetEquAttrList[tItem.tAttr[1][1]] = nAttr
	elseif tItem.nEquipPartType == gtPetEquPart.eTalisman then
		self:SkillHandle(nID)
	end
end

--临时保留
function CPetEqu:SkillHandle(nID, bRest)
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
			--self:PetHFHandle(tHFCfg.tSkNd, tSkillList)
			local nID  = self:SkillFilter(tSkillList, tHFCfg.tSkNd, tHFCfg)
			tSkillList[#tSkillList+1] = nID
		end
	else
		if tHFCfg.nLevel == 3 then
			if nSkWon >= nRate then
				tSkillList[#tSkillList+1] = tHFCfg.tSkSt[math.random(1,#tHFCfg.tSkSt)][1]
			end
			if nTwo >= nRate then
				-- tSkillList[#tSkillList+1] = tHFCfg.tSkNd[math.random(1,#tHFCfg.tSkNd)][1]
				local nID = self:SkillFilter(tSkillList, tHFCfg.tSkNd, tHFCfg)
				tSkillList[#tSkillList+1] = nID
			end
		elseif tHFCfg.nLevel == 4 then

			if nSkWon >= nRate then
				tSkillList[#tSkillList+1] = tHFCfg.tSkSt[math.random(1,#tHFCfg.tSkSt)][1]
			end

			if nTwo >= nRate then
				--tSkillList[#tSkillList+1] = tHFCfg.tSkNd[math.random(1,#tHFCfg.tSkNd)][1]
				local nID = self:SkillFilter(tSkillList, tHFCfg.tSkNd, tHFCfg)
				tSkillList[#tSkillList+1] = nID
			end
		end
	end
	print("宠物护符属性列表", tSkillList)
	if bRest then
		return  tSkillList
	else
		self.m_PetEquAttrList = tSkillList
	end
end

--护符技能筛选
function CPetEqu:SkillFilter(tSkill, tSkillList, tHFCfg)
	--先找出从逻辑上排斥的技能
	if #tSkill <= 0 then return end
	local tTempSkill = {}
	local nSingle = math.modf(tSkill[1]%10)
	local nHundreads = math.modf(tSkill[1]/10%10)
	for _, tSkillCfg in pairs(tSkillList) do
		local nTempSingle = math.modf(tSkillCfg[1]%10)
		local nTempHundreads = math.modf(tSkillCfg[1]/10%10)
		if nSingle ~= nTempSingle and nHundreads ~= nTempHundreads then
			table.insert(tTempSkill, tSkillCfg[1])
		end
	end

	--筛选表现上出现排斥的技能
	local tTarSkill = {}
	for _, tSkillCfg in ipairs(tHFCfg.tConflictSkill) do
		tTarSkill[tSkillCfg[1]] = true
	end

	local nSkillID =  tSkill[1]
	local tTempSkill2 = {}
	if tTarSkill[nSkillID] then
		for _, nID in ipairs(tTempSkill) do
			if not tTarSkill[nID] then
				table.insert(tTempSkill2, nID)
			end
		end
	end

	local nRetID
	if next(tTempSkill2) then
		nRetID = tTempSkill2[math.random(1, #tTempSkill2)]
	else
		nRetID = tTempSkill[math.random(1, #tTempSkill)]
	end
	assert(nRetID, "护符技能错误")
	return nRetID
end

--宠物装备初始化
function CPetEqu:PetEquitAttrHandle(nAttr, tBasePropertyFactor)
	
	--tBasePropertyFactor={{65,100,100,},{25,120,130,},{10,140,150,},}
	local tTb = tBasePropertyFactor
	local tmz = {{math.floor(tTb[1][1]/1000), math.floor(tTb[1][2]/100),math.floor(tTb[1][3]/100)},{math.floor(tTb[2][1]/100),math.random(tTb[2][2]),math.floor(tTb[2][3]/100)},{1,tTb[3][2]}}
	local nAttrs = 0
	local tArate = tTb[math.random(1,#tmz)]
	nAttrs = math.random(math.floor(nAttr * tArate[2]/100), math.floor(nAttr * tArate[3]/100))
	return nAttrs
end

function CPetEqu:PetHFHandle(tConfList, tSkillList)
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