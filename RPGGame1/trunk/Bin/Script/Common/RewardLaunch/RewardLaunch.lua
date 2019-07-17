--奖励投放
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CRewardLaunch:Ctor(tCfgTbl)
	if not tCfgTbl then
		tCfgTbl = ctAwardPoolConf
	end
	self.m_tRewardConfTbl = tCfgTbl
	self.m_tRewardPool = {}  -- {PoolID : {nConfID : tConf, ...}, ...} --直接存配置内容引用，不存ID，简化逻辑
	self.m_tRewardPoolPick = {} --{nPoolID : {nPickNum, nCount}, ...} --统计并检查配置表选取数量及选项数是否正确
	self:Init()
end

function CRewardLaunch:Init()
	--对配置表做一些预处理操作，不对策划的配置ID顺序做假设
	for k, v in pairs(self.m_tRewardConfTbl) do
		if type(v) == "table" and v.nPoolID then
			local nPoolID = v.nPoolID
			local tPool = self:GetRewardPool(nPoolID)
			if not tPool then
				local tPoolList = {}
				self.m_tRewardPool[nPoolID] = tPoolList
				tPool = self.m_tRewardPool[nPoolID]				
			end
			tPool[k] = v

			local tPoolPickConf = self:GetRewardPoolPickConf(nPoolID)
			if not tPoolPickConf then
				local tPoolPick = {nPickNum = v.nPickNum, nCount = 0}
				self.m_tRewardPoolPick[nPoolID] = tPoolPick
				tPoolPickConf = self.m_tRewardPoolPick[nPoolID]
			end
			assert(tPoolPickConf.nPickNum == v.nPickNum, "奖池表配置不正确,选取数量不一致！！奖池ID:"..nPoolID)
			if v.nWeight > 0 then --只有权重大于0的才统计
				tPoolPickConf.nCount = tPoolPickConf.nCount + 1
			elseif v.nWeight < 0 then
				assert(false, "奖池表权重存在负数！配置ID:"..k)
			end
		end
	end
	for k, v in pairs(self.m_tRewardPoolPick) do
		if v.nPickNum > v.nCount then
			assert(false, "配置错误，奖池表可选择数量少于选取数量！奖池ID:"..k)
		end
	end
end

function CRewardLaunch:GetConfTbl() return self.m_tRewardConfTbl end
function CRewardLaunch:GetRewardPool(nPoolID) return self.m_tRewardPool[nPoolID] end
function CRewardLaunch:GetRewardPoolPickConf(nPoolID) return self.m_tRewardPoolPick[nPoolID] end
function CRewardLaunch:GetRewardPoolPickNum(nPoolID)
	local tPickConf = self:GetRewardPoolPickConf(nPoolID)
	assert(tPickConf, "奖池配置不存在")
	return tPickConf.nPickNum
end
function CRewardLaunch:GetRewardConf(nID) return self.m_tRewardConfTbl[nID] end

function CRewardLaunch:GetRewardList(nPoolID, nRoleLevel, nRoleConfID, nPickNum)
	assert(nPoolID > 0 and nRoleLevel >= 0 and nPickNum > 0, "参数错误")
	if not nRoleConfID or nRoleConfID < 0 then
		nRoleConfID = 0
	end
	local tPool = self:GetRewardPool(nPoolID)
	assert(tPool, "配置不存在")

	local fnGetWeight = function (tNode) return tNode.nWeight end

	local tCheckParam = {}
	tCheckParam.nRoleLevel = nRoleLevel
	tCheckParam.nRoleConfID = nRoleConfID	
	local fnRandCheck = function (tNode, tCheckParam)
		if tNode.nMinLv > tCheckParam.nRoleLevel or tNode.nMaxLv < tCheckParam.nRoleLevel then
			return false
		end
		if tCheckParam.nRoleConfID == 0 or tNode.tRoleLimit[1][1] == 0 then
			return true
		end
		for k, v in pairs(tNode.tRoleLimit) do
			if v[1] == tCheckParam.nRoleConfID then
				return true
			end
		end
		return false
	end

	local nRandNum = nPickNum
	local tResult = CWeightRandom:CheckNodeRandom(tPool, fnGetWeight, nRandNum, true, fnRandCheck, tCheckParam)
	if not tResult or #tResult ~= nRandNum then
		assert(false, "掉落出错，请检查掉落配置! nPoolID:"..nPoolID..", nRoleLevel:"..nRoleLevel..", nRoleConfID:"..nRoleConfID..", nPickNum"..nPickNum)
	end

	return tResult
end

function CRewardLaunch:GetRewardListByPoolList(tPoolIDList, nRoleLevel, nRoleConfID)
	assert(#tPoolIDList > 0, "参数错误")
	local tResultList = {}
	for k, v in pairs(tPoolIDList) do
		if v > 0 then
			local nPickNum = self:GetRewardPoolPickNum(v)
			local tTemp = self:GetRewardList(v, nRoleLevel, nRoleConfID, nPickNum)
			assert(tTemp and #tTemp > 0, "掉落错误")
			for _, tReward in pairs(tTemp) do
				table.insert(tResultList, tReward)
			end
		end
	end
	return tResultList
end

--堆叠奖励 --多个的情况下
--返回值{ index:{nItemType, nItemID, nItemNum }, ...}
function CRewardLaunch:RewardStuff(tRewardList) 
	assert(tRewardList and #tRewardList > 0, "参数错误")
	local tStuffList = {}  -- { {nItemType, nItemID, nItemNum }, ...}
	for _, tReward in pairs(tRewardList) do
		local tTarget = nil
		for _, tStuff in ipairs(tStuffList) do
			if tStuff.nItemType == tReward.nItemType and tStuff.nItemID == tReward.nItemID then
				tTarget = tStuff
				break
			end
		end
		if not tTarget then
			tTarget = {}
			tTarget.nItemType = tReward.nItemType
			tTarget.nItemID = tReward.nItemID
			tTarget.nItemNum = tReward.nItemNum
			table.insert(tStuffList, tTarget)
		else
			tTarget.nItemNum = tTarget.nItemNum + tReward.nItemNum
		end
	end
	return tStuffList
end

--直接掉落
--其他是否绑定，或者来源等功能的支持，后续需要再扩展，直接通过掉落配置来确定这些
function CRewardLaunch:Launch(oRole, nPoolID, sReason)
	assert(oRole and nPoolID > 0 and sReason, "参数错误")
	local nRoleConfID = oRole:GetConfID()
	local nLevel = oRole:GetLevel()
	local nPickNum = self:GetRewardPoolPickNum(nPoolID)
 	local tRewardList = self:GetRewardList(nPoolID, nLevel, nRoleConfID, nPickNum)
	local tStuffList = self:RewardStuff(tRewardList)
	for _, tStuff in ipairs(tStuffList) do  --TODO 当前不支持在非逻辑服调用
		oRole:AddItem(tStuff.nItemType, tStuff.nItemID, tStuff.nItemNum, sReason)
	end
end

-- tPoolIDList = {PoolID, ...}
function CRewardLaunch:LaunchList(oRole, tPoolIDList, sReason)
	assert(oRole and tPoolIDList and sReason, "参数错误")
	local nRoleConfID = oRole:GetConfID()
	local nLevel = oRole:GetLevel()
	local tRewardList = self:GetRewardListByPoolList(tPoolIDList, nLevel, nRoleConfID)
	local tStuffList = self:RewardStuff(tRewardList)
	for _, tStuff in ipairs(tStuffList) do  --TODO 当前不支持在非逻辑服调用
		oRole:AddItem(tStuff.nItemType, tStuff.nItemID, tStuff.nItemNum, sReason)
	end
end

--通过邮件发送掉落  nPoolIDList = {PoolID, ...}
function CRewardLaunch:MailLaunch(nRoleID, nServerID, tPoolIDList, nRoleLevel, nRoleConfID, sReason, sTitle, sContent)
	assert(nRoleID > 0 and nServerID > 0 and tPoolIDList and nRoleLevel > 0 and sReason, "参数错误")
	local nRoleConfID = nRoleConfID
	local nLevel = nRoleLevel
	local tRewardList = self:GetRewardListByPoolList(tPoolIDList, nLevel, nRoleConfID)
	local tStuffList = self:RewardStuff(tRewardList)
	local tMailItemList = {}
	for _, tStuff in ipairs(tStuffList) do
		local tMailItem = {}
		tMailItem[1] = tStuff.nItemType
		tMailItem[2] = tStuff.nItemID
		tMailItem[3] = tStuff.nItemNum
		table.insert(tMailItemList, tMailItem)
	end
	CUtil:SendMail(nServerID, sTitle, sContent, tMailItemList, nRoleID)
end

--tPoolIDList = {PoolID, ...}
function CRewardLaunch:MailLaunchByRole(oRole, tPoolIDList, sReason, sTitle, sContent)
	assert(oRole and tPoolIDList and sReason and sTitle and sContent, "参数错误")
	local nRoleID = oRole:GetID()
	local nServerID = oRole:GetServer()
	local nRoleLevel = oRole:GetLevel()
	local nRoleConfID = oRole:GetConfID()
	return self:MailLaunch(nRoleID, nServerID, tPoolIDList, nRoleLevel, nRoleConfID, sReason, sTitle, sContent)
end


goRewardLaunch = CRewardLaunch:new(ctAwardPoolConf)  --通用掉落

