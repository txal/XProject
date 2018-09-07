local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CRedPoint.tType = 
{
	eReform = 1,	--改造
	eCompose = 2,	--合成
	eUpgrade = 3,	--升级
}

function CRedPoint:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tReformArmMap = {}	--改造小红点
	self.m_tComposeArmMap = {}	--合成小红点
	self.m_tUpgradeArmMap = {}	--升级小红点
end

function CRedPoint:LoadData(tData)
end

function CRedPoint:SaveData()
end

function CRedPoint:GetType()
	return gtModuleDef.tRedPoint.nID, gtModuleDef.tRedPoint.sName
end

function CRedPoint:Online()
	self:UpdateArmRedPoint()
end

--背包中特性道具特性列表
function CRedPoint:_get_bag_feature_list_()
	local tFeatureList = {}
	local oBag = self.m_oPlayer.m_oBagModule
	local tGridMap = oBag:GetGridItemMap()
	for nGrid, oItem in pairs(tGridMap)	do
		if oItem:GetObjType() == gtObjType.eProp and oItem:GetType() == gtPropType.eFeature then
			local tConf = oItem:GetConf()
			table.insert(tFeatureList, tConf.nSubType)
		end
	end
	return tFeatureList
end

--改造小红点检测
function CRedPoint:UpdateReformArm()
	self.m_tReformArmMap = {}
	local tBagFeatureList = self:_get_bag_feature_list_()
	local oBag = self.m_oPlayer.m_oBagModule
	local tSlotMap = oBag:GetSlotArmMap()
	for nSlot, oArm in pairs(tSlotMap) do
		if oArm:GetType() == gtArmType.eGun then
			local tArmFeatureMap = {}
			for _, v in ipairs(oArm:GetFeature()) do
				tArmFeatureMap[v[1]] = v[2]
			end
			for _, v in ipairs(tBagFeatureList) do
				if not tArmFeatureMap[v] then
					self.m_tReformArmMap[oArm:GetAutoID()] = true
					break
				end
			end
		end
	end
end

--合成小红点检测(检测同名装备/已穿装备)
function CRedPoint:UpdateComposeArm()
	self.m_tComposeArmMap ={}
	local oBag = self.m_oPlayer.m_oBagModule
	--装备栏中可合成
	local tSlotMap = oBag:GetSlotArmMap()
	for nSlot, oArm in pairs(tSlotMap) do
		if #oBag:GetComposeSubArmList(oArm) > 0 then
			self.m_tComposeArmMap[oArm:GetAutoID()] = true
		end
	end
	--背包中最高品质且可合成装备
	local tMaxQualityMap = {}
	local tItemMap = oBag:GetGridItemMap()
	for nGrid, oItem in pairs(tItemMap) do
		local nObjType = oItem:GetObjType()
		if nObjType == gtObjType.eArm then
			local nType = oItem:GetType()
			if nType == gtArmType.eGun or nType == gtArmType.eBomb then
				local sName = oItem:GetName()
				local oMaxItem = tMaxQualityMap[sName]
				if (not oMaxItem or oItem:CalcQuality() > oMaxItem:CalcQuality()) and #oBag:GetComposeSubArmList(oItem) > 0 then
					tMaxQualityMap[sName] = oItem
				end
			end
		end
	end
	for sName, oArm in pairs(tMaxQualityMap) do
		self.m_tComposeArmMap[oArm:GetAutoID()] = true
	end
end	

--升级小红点检测
function CRedPoint:UpdateUpgradeArm()
	self.m_tUpgradeArmMap = {}
	local nRoleLevel = self.m_oPlayer:GetLevel()
	local oBag = self.m_oPlayer.m_oBagModule
	local tSlotMap = oBag:GetSlotArmMap()
	for nSlot, oArm in pairs(tSlotMap) do
		if oArm:GetLevel() < nRoleLevel then
			self.m_tUpgradeArmMap[oArm:GetAutoID()] = true
		end
	end
end	

function CRedPoint:UpdateArmRedPoint()
	self:UpdateReformArm()
	self:UpdateComposeArm()
	self:UpdateUpgradeArm()
	self:SyncArmRedPoint()
end

function CRedPoint:SyncArmRedPoint()
	local tReformArm = {}
	for nItemID, v in pairs(self.m_tReformArmMap) do
		table.insert(tReformArm, nItemID)
	end

	local tComposeArm = {}
	for nItemID, v in pairs(self.m_tComposeArmMap) do
		table.insert(tComposeArm, nItemID)
	end

	local tUpgradeArm = {}
	for nItemID, v in pairs(self.m_tUpgradeArmMap) do
		table.insert(tUpgradeArm, nItemID)
	end

	local tSendData = {tReformArm=tReformArm, tComposeArm=tComposeArm, tUpgradeArm=tUpgradeArm}
	print("CRedPoint:SyncArmRedPoint***", tSendData)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ArmRedPointSyncRet", tSendData)
end

function CRedPoint:OnPutOffArm()
	self:UpdateArmRedPoint()
end

function CRedPoint:OnPutOnArm()
	self:UpdateArmRedPoint()
end

function CRedPoint:OnItemAdded()
	self:UpdateArmRedPoint()
end

function CRedPoint:OnItemRemoved()
	self:UpdateArmRedPoint()
end

function CRedPoint:OnLevelChange()
	self:UpdateArmRedPoint()
end

function CRedPoint:OnArmUpgrade()
	self:UpdateArmRedPoint()
end