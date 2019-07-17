--阵法
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--初始
local nInitFmt = 8 
--上限
local nMaxFmt = 8
--格子价钱
CFormation._nGridPrice = 200

--构造函数
function CFormation:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tFormationMap = {}  	--阵法映射{[编号]={nLevel=等级,nExp=经验},...}
	self.m_nMaxFmt = nInitFmt 	--阵法上限
	self.m_nUseFmt = 0 	--当前使用的阵法
end

function CFormation:LoadData(tData)
	if tData then
		self.m_tFormationMap = tData.m_tFormationMap or self.m_tFormationMap
		self.m_nMaxFmt = math.max(nMaxFmt, (self.m_nMaxFmt or 0))
		self.m_nUseFmt = tData.m_nUseFmt or self.m_nUseFmt
	end
	self:OnLoaded()
end

function CFormation:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tFormationMap = self.m_tFormationMap
	tData.m_nMaxFmt = self.m_nMaxFmt
	tData.m_nUseFmt = self.m_nUseFmt
	return tData
end

function CFormation:GetType()
	return gtModuleDef.tFormation.nID, gtModuleDef.tFormation.sName
end

--加载数据完毕
function CFormation:OnLoaded()
end

--角色上线
function CFormation:Online()
	self:FmtListReq()
end

function CFormation:MaxFmt() return self.m_nMaxFmt end
function CFormation:GetFmt(nFmtID) return self.m_tFormationMap[nFmtID] end
function CFormation:GetUseFmt()
	if self.m_nUseFmt == 0 then
		return 0, 0
	end
	local tFmt = self.m_tFormationMap[self.m_nUseFmt]
	return self.m_nUseFmt, tFmt.nLevel
end

--当前阵法数量
function CFormation:FmtNum()
	local nCount = 0
	for nID, tFmt in pairs(self.m_tFormationMap) do
		nCount = nCount + 1
	end
	return nCount
end

--添加阵法
function CFormation:AddFmt(nFmtID)
	if self.m_tFormationMap[nFmtID] then
		return LuaTrace("已拥有阵法", nFmtID)
	end
	--替换
	local nReplaceFmt = 0
	if self:FmtNum() >= self:MaxFmt() then
		local tFmtList = {}	
		for nID, tFmt in pairs(self.m_tFormationMap) do
			table.insert(tFmtList, nID)
		end
		nReplaceFmt = tFmtList[math.random(#tFmtList)]
		self.m_tFormationMap[nReplaceFmt] = nil
		self.m_tFormationMap[nFmtID] = {nLevel=1, nExp=0}
		if self.m_nUseFmt == nReplaceFmt then
			self.m_nUseFmt = nFmtID
		end
	--增加
	else
		self.m_tFormationMap[nFmtID] = {nLevel=1, nExp=0}
	end
	local tData = {tLevelMap = {}}
	local nLevel = self.m_tFormationMap[nFmtID].nLevel
	tData.tLevelMap[nLevel] = 1
	CEventHandler:OnFaZhenUpLevel(self.m_oRole, tData)
	self:MarkDirty(true)
	self:FmtListReq()
	self.m_oRole:UpdateActGTFormationLv()
	return nReplaceFmt
end

--通过阵法ID和等级取阵法加成
function CFormation:GetAttrAddByFmtAndLv(nFmt, nLv)
	local tBattleAttr = {}
	local tFmtLvList = _ctFormationLevelConf[nFmt]
	if not tFmtLvList then
		return tBattleAttr
	end

	--格子阵法加成
	local tConf = tFmtLvList[nLv]
	for k = 1, 10 do
		local tAttrAdd = tConf["tPos"..k]
		if tAttrAdd then
			tBattleAttr[k] = tBattleAttr[k] or {}
			for _, tAttr in ipairs(tAttrAdd) do
				tBattleAttr[k][tAttr[1]] = (tBattleAttr[k][tAttr[1]] or 0) + tAttr[2]
			end
		end
	end
	return tBattleAttr
end

--取阵法属性加成
function CFormation:GetAttrAdd()
	local tFmt = self:GetFmt(self.m_nUseFmt)
	if not tFmt then return {} end
	return self:GetAttrAddByFmtAndLv(self.m_nUseFmt, tFmt.nLevel)
end

--阵法列表请求
function CFormation:FmtListReq()
	local tList = {}
	for nID, tFmt in pairs(self.m_tFormationMap) do
		local tInfo = {nID=nID, nLevel=tFmt.nLevel, nExp=tFmt.nExp, nNextExp=ctFormationLevelConf[tFmt.nLevel].nExp}
		table.insert(tList, tInfo)
	end
	local tMsg = {nUseFmt=self.m_nUseFmt, tList=tList, nMaxFmt=self.m_nMaxFmt}
	self.m_oRole:SendMsg("FmtListRet", tMsg)
end

--购买上限请求
function CFormation:FmtBuyReq()
	if self.m_nMaxFmt >= nMaxFmt then
		return self.m_oRole:Tips("已达到阵法数量上限，开启失败")
	end
	if not self.m_oRole:CheckSubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, self._nGridPrice, "开启阵法") then
		return self.m_oRole:YuanBaoTips()
	end
	self.m_nMaxFmt = self.m_nMaxFmt + 1
	self:MarkDirty(true)
	self:FmtListReq()
	return true
end

--启用阵法请求
function CFormation:FmtUseReq(nFmtID)
	print("CFormation:FmtUseReq***", nFmtID)
	if not self.m_tFormationMap[nFmtID] then
		return
	end
	if self.m_nUseFmt == nFmtID then
		self.m_nUseFmt = 0
		self.m_oRole:Tips("阵法已关闭")
	else
		self.m_nUseFmt = nFmtID
		self.m_oRole:Tips("阵法开启成功")
	end
	self:MarkDirty(true)
	self:FmtListReq()
end

--计算升满级需要经验数
function CFormation:CalcFullGradeExpCost(nFmtID, tFmt)
	local nExpCost = 0
	for k=tFmt.nLevel, #_ctFormationLevelConf[nFmtID]-1 do
		local tConf = _ctFormationLevelConf[nFmtID][k]
		nExpCost = nExpCost + tConf.nExp
	end
	return nExpCost
end

--阵法提升
function CFormation:FmtUpgradeReq(nFmtID, tPropList)
	local tFmt = self:GetFmt(nFmtID)
	if not tFmt then
		return
	end

	if tFmt.nLevel >= #_ctFormationLevelConf[nFmtID] then
		return self.m_oRole:Tips("阵法等级已达上限")
	end

	local nFullGradeExpCost = self:CalcFullGradeExpCost(nFmtID, tFmt)

	--扣道具加经验
	local nExpAdd = 0
	local tItemList = {}
	for _, tProp in ipairs(tPropList) do
		local tPropConf = ctPropConf[tProp.nID]
		if (tPropConf.nType == gtPropType.eFmt and tProp.nID == nFmtID) or tPropConf.nType == gtPropType.eFmtChip then
			nFullGradeExpLack = nFullGradeExpCost - (tFmt.nExp + nExpAdd)
			local nNeedPropNum = math.ceil(nFullGradeExpLack / tPropConf.eParam())
			if nNeedPropNum <= 0 then
				return
			end

			nNeedPropNum = math.min(tProp.nNum, nNeedPropNum)
			table.insert(tItemList, {gtItemType.eProp, tProp.nID, nNeedPropNum})
			nExpAdd = nExpAdd + tPropConf.eParam() * nNeedPropNum
		end
	end

	if #tItemList <= 0 then
		return self.m_oRole:Tips("道具类型错误")
	end

	if not self.m_oRole:CheckSubItemList(tItemList, "阵法提升") then
		return self.m_oRole:Tips("道具不足，使用失败")
	end


	tFmt.nExp = tFmt.nExp + nExpAdd
	self.m_oRole:Tips(string.format("使用成功，增加%d经验", nExpAdd))

	local tData = {}
	tData.tLevelMap = {}
	local nOldLevel = tFmt.nLevel
	for k=tFmt.nLevel, #_ctFormationLevelConf[nFmtID]-1 do
		local tConf = _ctFormationLevelConf[nFmtID][k]
		if tFmt.nExp >= tConf.nExp then
			tFmt.nLevel = k + 1
			tFmt.nExp = tFmt.nExp - tConf.nExp
			tData.tLevelMap[k] = 1
		end
	end
	self:MarkDirty(true)
	self:FmtListReq()
	CEventHandler:OnFaZhenUpLevel(self.m_oRole, tData)
	self.m_oRole:UpdateActGTFormationLv()
end

function CFormation:GetLvSum()
	local nSum = 0
	for k, tFormation in pairs(self.m_tFormationMap) do 
		nSum = nSum + tFormation.nLevel
	end
	return nSum
end

