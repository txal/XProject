--家园系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert



function CFurniture:Ctor(nID)
	self.m_nID = nID
	self.m_nState = 0
end

function CFurniture:SaveData()
	local tData = {}
	tData.m_nState = self.m_nState
	return tData
end

function CFurniture:LoadData(tData)
	tData = tData or {}
	self.m_nState = tData.m_nState or self.m_nState
end

function CFurniture:GetID()
	return self.m_nID
end

function CFurniture:GetConfigData()
	return ctHouseFurnitureConf[self.m_nID]
end

function CFurniture:PackData()
	local tData = {}
	tData.nPos = self:GetFurnitureType()
	tData.nID = self:GetID()
	tData.nState = self.m_nState
	return tData
end

function CFurniture:GetName()
	local tData = self:GetConfigData()
	return tData["sName"]
end

function CFurniture:GetAssetScore()
	local tData = self:GetConfigData()
	return tData["nAssetScore"] or 0
end

--套装id
function CFurniture:GetSetID()
	local tData = self:GetConfigData()
	return tData["nSet"] or 0
end

function CFurniture:GetFurnitureType()
	local tData = self:GetConfigData()
	return tData["nType"]
end

function CFurniture:IsLock()
	if self.m_nState == 0 then
		return true
	end
	return false
end

function CFurniture:IsUnLock()
	if self.m_nState == 1 then
		return true
	end
	return false
end

function CFurniture:UnLock()
	self.m_nState = 1
end

function CFurniture:IsWield()
	if self.m_nState == 2 then
		return true
	end
	return false
end

function CFurniture:UnWield()
	self.m_nState = 1
end

function CFurniture:Wield()
	self.m_nState = 2
end

function CFurniture:GetBattleAttr()
	local tData = self:GetConfigData()
	local tBattleAttr = {}
	local tFurnitureAttr = tData["eFurnitureAttrFornula"]
	for _,tAttr in pairs(tFurnitureAttr) do
		local nAttr,nAdd = table.unpack(tAttr)
		if not tBattleAttr[nAttr] then
			tBattleAttr[nAttr] = 0
		end
		tBattleAttr[nAttr] = tBattleAttr[nAttr] + nAdd
	end
	return tBattleAttr
end

------------------植物----------------
function CPlant:Ctor(nID)
	self.m_nID = nID
	self.m_nShape = 0
	self.m_nGrow = 0
	self.m_tPartnerInfo = {}
	self.m_nGiftTime = 0
end

function CPlant:SaveData()
	local tData = {}
	tData.m_nShape = self.m_nShape
	tData.m_nGrow = self.m_nGrow
	tData.m_tPartnerInfo = self.m_tPartnerInfo
	tData.m_nGiftTime = self.m_nGiftTime
	return tData
end

function CPlant:LoadData(tData)
	tData = tData or {}
	self.m_nShape = tData.m_nShape or self.m_nShape
	self.m_nGrow = tData.m_nGrow or self.m_nGrow
	self.m_tPartnerInfo = tData.m_tPartnerInfo or self.m_tPartnerInfo
	self.m_nGiftTime = tData.m_nGiftTime or self.m_nGiftTime
end

function CPlant:GetID()
	return self.m_nID
end

function CPlant:SetShape(nShape)
	self.m_nShape = nShape
end

function CPlant:GetShape()
	return self.m_nShape
end

function CPlant:PackData()
	local tData = {}
	tData.nShape = self:GetShape()
	tData.nState = self:GetState()
	tData.nLeftTime = self:GetGiftTime()
	return tData
end

function CPlant:GetState()
	if not self:IsFull() then
		return 0
	else
		if self.m_nGiftTime == 0 then
			return 1
		end
		if self:GetGiftTime() > 0 then
			return 2
		else
			return 3
		end
	end
	return 0
end

--浇水
function CPlant:Water()
	self.m_nGrow = self.m_nGrow + 1
end

function CPlant:ResetGrow()
	self.m_nGrow = 0
	self.m_nGiftTime = 0
end

function CPlant:IsFull()
	if self.m_nGrow >= 3 then
		return true
	end
	return false
end

function CPlant:CanGive()
	if self.m_nGrow >= 3 then
		return true
	end
	return false
end

function CPlant:GetPartnerType()
	return self.m_tPartnerInfo["nPartnerID"]
end

function CPlant:SetPartnerData(tPartnerInfo)
	self.m_tPartnerInfo = tPartnerInfo
end

function CPlant:GetPartnerData()
	return self.m_tPartnerInfo
end

function CPlant:SetGiftTime()
	self.m_nGiftTime = os.time() + 60 * 30
end

function CPlant:GetGiftTime()
	local nTime = math.max(self.m_nGiftTime - os.time(),0)
	return nTime
end

--指令使用
function CPlant:ChangeGiftTime(nTime)
	self.m_nGiftTime = nTime
end