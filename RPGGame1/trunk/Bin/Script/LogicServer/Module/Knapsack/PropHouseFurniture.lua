--喜糖
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropHouseFurniture:Ctor(oModule, nID, nGrid, bBind, tPropExt)
    CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt)
end


function CPropHouseFurniture:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropHouseFurniture:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

function CPropHouseFurniture:Use(nParam1)
	local nServerID = gnWorldServerID
	local nServiceID = goServerMgr:GetGlobalService(gnWorldServerID, 111)

	local fnCheckCallback = function (bLock)
		if not bLock then
			local oRole = self.m_oModule.m_oRole
			oRole:Tips("已经拥有了这个类型家具，不能再次使用")
			return
		else
			self:TrueUse()
		end
	end
	local oRole = self.m_oModule.m_oRole
	local nRoleID = oRole:GetID()
	local nFurnitureID = self:GetPropConf().eParam()
	Network.oRemoteCall:CallWait("HouseFurnitureIsLock", fnCheckCallback, gnWorldServerID, nServiceID, 0, nRoleID,nFurnitureID)
end

function CPropHouseFurniture:TrueUse()
	local nUseNum = 1
	local oRole = self.m_oModule.m_oRole
	local nPropID = self:GetID()
	if not self.m_oModule:SubGridItem(self:GetGrid(), nPropID, nUseNum, "背包使用") then
        oRole:Tips("使用失败")
        return
    end
    
	local fnCallback = function (bSucc)
		if bSucc then
			return
		else
			oRole:AddItem(gtItemType.eProp, nPropID, nUseNum, "家园解锁家具失败回溯")
		end
	end
	local nServiceID = goServerMgr:GetGlobalService(gnWorldServerID, 111)
	local nRoleID = oRole:GetID()
	local nFurnitureID = self:GetPropConf().eParam()
	Network.oRemoteCall:CallWait("HouseUnLockFurniture", fnCallback, gnWorldServerID, nServiceID, 0, nRoleID,nFurnitureID)
end