--升级礼包
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CUpgradeBag:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tUpgradeBag = {} 		--成长礼包状态 {[nID] = nState}}
	self.m_nFinish = 0 				--领取完成次数
end 

function CUpgradeBag:LoadData(tData)
	if tData then 
		self.m_tUpgradeBag = tData.m_tUpgradeBag
		self.m_nFinish = tData.m_nFinish or 0
	end
end

function CUpgradeBag:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
		tData.m_tUpgradeBag = self.m_tUpgradeBag
		tData.m_nFinish = self.m_nFinish
	return tData
end

function CUpgradeBag:Online()
	if self.m_nFinish < #ctUpgradeBagConf then 	
		self:UpgradeBagInfoReq()
	end
end

function CUpgradeBag:GetType()
	return gtModuleDef.tUpgradeBag.nID, gtModuleDef.tUpgradeBag.sName
end

--等级变化
function CUpgradeBag:OnRoleLevelChange(nNewLevel)
	for k=#ctUpgradeBagConf, 1, -1 do 
		local tConf = ctUpgradeBagConf[k]
		if nNewLevel >= tConf.nNeedLv then 
			local nState = self.m_tUpgradeBag[nID] or 1
			if nState == 1 then
				return self:UpgradeBagInfoReq()
			end
		end
	end
end

--成长礼包界面请求
function CUpgradeBag:UpgradeBagInfoReq()
	local tList = {}
	local nLevel = self.m_oPlayer:GetLevel()
	for nID, tConf in ipairs(ctUpgradeBagConf) do 
		local nState = self.m_tUpgradeBag[nID] or 0
		if nState == 0 then 
			nState = nLevel >= tConf.nNeedLv and 1 or 0
		end
		table.insert(tList, {nID=nID, nState=nState})
	end
	local tMsg = {tList=tList}
	self.m_oPlayer:SendMsg("UpgradeBagInfoRet", tMsg)
end

--领取成长礼包奖励
function CUpgradeBag:GetUpgradeBagAwardReq(nID)
	local nLevel = self.m_oPlayer:GetLevel()
	local tConf = ctUpgradeBagConf[nID]
	if nLevel < tConf.nNeedLv then 
		return self.m_oPlayer:Tips("等级不足，请继续努力")
	end
	if self.m_tUpgradeBag[tConf.nID] then 
		return self.m_oPlayer:Tips("已经领取过奖励")
	end
	self.m_tUpgradeBag[tConf.nID] = 2
	self.m_nFinish = self.m_nFinish + 1
	self:MarkDirty(true)
	local tAward = {}
	local tItemList = {}
	for _, tItem in ipairs(tConf.tAward) do 
		table.insert(tAward, {nID=tItem[1], nNum = tItem[2]})
		self.m_oPlayer:AddItem(gtItemType.eProp, tItem[1], tItem[2], "成长礼包奖励")
	end

	local tMsg = {tAward=tAward}
	self.m_oPlayer:SendMsg("GetUpgradeBagAwardRet", tMsg)
	self:UpgradeBagInfoReq()
end

function CUpgradeBag:UpgradeReset()
	self.m_tUpgradeBag = {}
	self:UpgradeBagInfoReq()
	self.m_oPlayer:Tips("重置成功")
	self:MarkDirty(true)
end