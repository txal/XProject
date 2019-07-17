--基金系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CFund.tFundType = 
{
	eGrowth = 11, 	--成长基金
	eSenior = 12, 	--变强基金
}

--基金预处理
local _FundConf = {}
local function PreProcessFundConf()
	for _, tConf in ipairs(ctFundConf) do
		_FundConf[tConf.nType] = _FundConf[tConf.nType] or {}
		table.insert(_FundConf[tConf.nType], tConf)
	end
end
PreProcessFundConf()

function CFund:Ctor(oRole)
	self.m_oRole = oRole
	self.m_tFund = {} 		--基金状态 {[type]={[nID] = nState}}
	self.m_tProgress = {}   --进度{[ntype]=nCount}
	self.m_tFinish = {} 	--是否完成
end 

function CFund:LoadData(tData)
	if tData then 
		self.m_tFund = tData.m_tFund
		self.m_tProgress = tData.m_tProgress
		self.m_tFinish = tData.m_tFinish or {}
	end
end

function CFund:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tFund = self.m_tFund
	tData.m_tProgress = self.m_tProgress
	tData.m_tFinish = self.m_tFinish
	return tData
end

function CFund:Online()
	self:FundAwardProgressReq()
end

function CFund:GetType()
	return gtModuleDef.tFund.nID, gtModuleDef.tFund.sName
end

--等级变化
function CFund:OnRoleLevelChange(nNewLevel)
	if self.m_tFund[CFund.tFundType.eGrowth] then
		if self.m_tFund[CFund.tFundType.eSenior] then 
			self:Progress(CFund.tFundType.eSenior, nNewLevel)
		else	
			self:Progress(CFund.tFundType.eGrowth, nNewLevel)
		end
	end
end

--是否购可以购买基金
function CFund:CanBuyFund(nID, bTips)
	if nID == CFund.tFundType.eGrowth then
		if self.m_tFund[CFund.tFundType.eGrowth] then 
			if bTips then self.m_oRole:Tips(string.format("%s 已购买过",ctRechargeConf[nID].sName)) end
			return
		end
	elseif nID == CFund.tFundType.eSenior then
		if not self.m_tFund[CFund.tFundType.eGrowth] or not self:GetFinish(CFund.tFundType.eGrowth) then 
			if bTips then self.m_oRole:Tips(string.format("请先购买并完成%s",ctRechargeConf[CFund.tFundType.eGrowth].sName)) end
			return
		end
		if self.m_tFund[CFund.tFundType.eSenior] then 
			if bTips then self.m_oRole:Tips(string.format("%s 已购买过",ctRechargeConf[nID].sName)) end
			return
		end
	end
	return true
end

--购买基金成功
function CFund:OnRechargeSuccess(nID)
	--系统频道
	local function _fnCheckSysTalk(nID)
		local tRechConf = ctRechargeConf[nID]
		local tTalkConf = ctTalkConf["buyfund"]
		if not (tRechConf and tTalkConf) then
			return
		end
		CUtil:SendSystemTalk("系统", string.format(tTalkConf.sContent, self.m_oRole:GetName(), tRechConf.sName))
	end

	if nID == CFund.tFundType.eGrowth then
		if not self:CanBuyFund(nID, true) then
			return
		end
		self.m_tFund[CFund.tFundType.eGrowth] = self.m_tFund[CFund.tFundType.eGrowth] or {}
		local nVal = self.m_oRole:GetLevel()
		self:Progress(CFund.tFundType.eGrowth, nVal)
		local nAwardID = _FundConf[nID][1].nID
		self.m_tFund[nID][nAwardID] = 2 --配置表第一条记录只是显示用
		-- self:GetAwardReq(nAwardID)
		self.m_oRole:Tips(string.format("购买 %s 成功", ctRechargeConf[nID].sName))
		self.m_oRole.m_oPayPush:BuyEvent(3)
		_fnCheckSysTalk(nID)

	elseif nID == CFund.tFundType.eSenior then 
		if not self:CanBuyFund(nID, true) then
			return
		end
		self.m_tFund[CFund.tFundType.eSenior] = self.m_tFund[CFund.tFundType.eSenior] or {}
		local nVal = self.m_oRole:GetLevel()
		self:Progress(CFund.tFundType.eSenior, nVal)
		local nAwardID = _FundConf[nID][1].nID
		-- self:GetAwardReq(nAwardID)
		self.m_tFund[nID][nAwardID] = 2 --配置表第一条记录只是显示用
		self.m_oRole:Tips(string.format("购买 %s 成功", ctRechargeConf[nID].sName))
		_fnCheckSysTalk(nID)
		
	end 
	self:MarkDirty(true)
end

--进度记录
function CFund:Progress(nType, nVal)
	if self.m_tFund[nType] and not self.m_tFinish[nType] then
		self.m_tProgress[nType] = nVal

	elseif self.m_tFund[nType] and self.m_tFinish[CFund.tFundType.eGrowth] then
		self.m_tProgress[nType] = nVal
	end
	self:FundAwardProgressReq()
	self:MarkDirty(true)
end 

--取基金表
function CFund:GetFund() return self.m_tFund end

--取基金完成状态
function CFund:GetFinish(nType) return self.m_tFinish[nType] end

--基金物品表
function CFund:FundAwardProgressReq()
	local function _GetFund(nTarType)
		local tInfo = {nType=nTarType, bBuy=false, bFinish=false, nProgress=0, tFund={}}
		local nCount = 0
		for _, tConf in ipairs(_FundConf[nTarType]) do 
			local nState = 0 
			if self.m_tFund[nTarType] then
				tInfo.nProgress = self.m_tProgress[nTarType] or 0
				tInfo.bBuy = true
				nState = self.m_tFund[nTarType][tConf.nID] or 0
				if nState == 0 then
					nState = (self.m_tProgress[nTarType] or 0) >= tConf.nTarget and 1 or 0
				elseif nState == 2 then 
					nCount = nCount + 1
				end
			end
			table.insert(tInfo.tFund, {nID=tConf.nID, nState=nState})
		end
		if nCount == #_FundConf[nTarType] then 
			tInfo.bFinish = true
			if not self.m_tFinish[nTarType] then
				self.m_tFinish[nTarType] = true
				self:MarkDirty(true)
			end
		end
		if nTarType==CFund.tFundType.eGrowth and tInfo.bFinish then 
			return _GetFund(CFund.tFundType.eSenior)
		end
		return tInfo
	end
	local tList = {}
	tList = _GetFund(CFund.tFundType.eGrowth)
	local tMsg = tList
	self.m_oRole:SendMsg("FundAwardProgressRet", tMsg)
end

--领取基金奖励
function CFund:GetAwardReq(nID)
	local tItem = ctFundConf[nID]
	if not tItem then 
		return self.m_oRole:Tips("奖励ID有误:", nID)
	end
	local nType = tItem.nType
	if not self.m_tFund[nType] then 
		return self.m_oRole:Tips("请购买基金")
	end

	if self.m_tFund[nType][nID] == 2 then 
		return self.m_oRole:Tips("奖励已领取")
	end

	if (self.m_tProgress[nType] or 0) < ctFundConf[nID].nTarget then
		return self.m_oRole:Tips("未满足领取条件")	
	end
	
	-- local tMsg = {tAward={}}
	self.m_tFund[nType][nID] = 2
	for _, tConf in ipairs(tItem.tAward) do 
		self.m_oRole:AddItem(tConf[1], tConf[2], tConf[3], "基金奖励")
		-- table.insert(tMsg.tAward, {nType=tConf[1], nID=tConf[2], nNum=tConf[3]})
	end
	self:MarkDirty(true)
	-- self.m_oRole:SendMsg("FundAwardRet", tMsg)
	self:FundAwardProgressReq(nType)
end

--GM重置基金
function CFund:GMResetFund(nType)
	if nType == 1 then 
		self.m_tFund[CFund.tFundType.eGrowth] = nil
		self.m_tFinish[CFund.tFundType.eGrowth] = nil
		self.m_tProgress[CFund.tFundType.eGrowth] = nil
	else
		self.m_tFund[CFund.tFundType.eSenior] = nil
		self.m_tFinish[CFund.tFundType.eSenior] = nil
		self.m_tProgress[CFund.tFundType.eSenior] = nil
	end
	self.m_oRole:Tips("重置成功")
end





