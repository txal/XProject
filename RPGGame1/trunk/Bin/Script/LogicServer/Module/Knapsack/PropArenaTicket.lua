--竞技令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPropArenaTicket:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) --调用基类构造函数
end

function CPropArenaTicket:LoadData(tData)
	CPropBase.LoadData(self, tData) --基类数据
end

function CPropArenaTicket:SaveData()
	local tData = CPropBase.SaveData(self) --基类数据
	return tData
end

function CPropArenaTicket:Use(nParam1)
	local oRole = self.m_oModule.m_oRole
	nParam1 = 1
	if not nParam1 or nParam1 <= 0 then
		oRole:Tips("参数不正确")
		return
	end
	local nPropNum = self:GetNum()
	if nPropNum <= 0 then
		oRole:Tips("物品数量不足") --??应该不可能发生
		return
	end
	-- local nTotalKeep = oRole:ItemCount(gtItemType.eProp, self:GetID())
	-- if nTotalKeep <= 0 then
	-- 	oRole:Tips("物品数量不足") --??应该不可能发生
	-- 	return
	-- end
	local nUseNum = nParam1
	nUseNum = math.min(nUseNum, nPropNum)

	local nServerID = oRole:GetServer()

	--避免频繁回滚，做一个预检查
	local fnAddPreCheckCallback = function (bRet)
		if not bRet then
			oRole:Tips("使用失败")
			return
		end
		--先使用，防止连续多个请求，前面请求处于rpc调用期间，后续请求都通过检查
		if not self.m_oModule:SubGridItem(self:GetGrid(), self:GetID(), nUseNum, "背包使用") then 
			oRole:Tips("使用失败")
			return
		end

		local fnAddArenaChallCallback = function (bRet)
			if not bRet then --可能服务器挂掉, 需要给玩家回滚数据
				oRole:Tips("使用失败")
				oRole:AddItem(gtItemType.eProp, self:GetID(), nUseNum, "背包使用失败回滚")
				-- self:AddNum(nUseNum)
				-- self.m_oModule:OnItemModed(self:GetGrid())
				return
			end
			--do something
			--限时奖励
	        Network:RMCall("OnTATZSReq", nil, nServerID, goServerMgr:GetGlobalService(nServerID,20), 0, oRole:GetID(), nUseNum)
		end	

		Network:RMCall("ArenaAddChallReq", fnAddArenaChallCallback, nServerID, 
			goServerMgr:GetGlobalService(nServerID, 20), oRole:GetSession(), oRole:GetID(), nUseNum)
	end

	Network:RMCall("ArenaAddChallPreCheckReq", fnAddPreCheckCallback, nServerID, 
		goServerMgr:GetGlobalService(nServerID, 20), oRole:GetSession(), oRole:GetID())
end











