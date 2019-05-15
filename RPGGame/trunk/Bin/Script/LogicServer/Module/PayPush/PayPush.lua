
local tPayPushEvent = 
{
	eLevel = 1,			--等级类型
	eLoginTimes = 2,	--登陆次数
}

local tPayPushType = 
{
	eSC = 1,	--首充
	eYK = 2,	--月卡
	eCZJJ = 3,	--成长基金
	eFLZK = 4, 	--福利周卡
}

local nMonthCardID = 9 --月卡ID
local nWeekCardID = 10 --周卡ID

function CPayPush:Ctor(oRole)
	self.m_oRole = oRole

	self.m_bDirty = false
	self.m_tPayPush = {} --self.m_tPayPush[id] = {}
	self.m_nLoginTimes = 0	--登陆次数
end

function CPayPush:OnRelease() end
function CPayPush:LoadData(tData)
	if not tData then
		return 
	end
	self.m_tPayPush = tData.m_tPayPush or {}
	self.m_nLoginTimes = tData.m_nLoginTimes or 0
 end
function CPayPush:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tPayPush = self.m_tPayPush
	tData.m_nLoginTimes = self.m_nLoginTimes
	return tData
 end

function CPayPush:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CPayPush:IsDirty() return self.m_bDirty end
function CPayPush:GetType()
 	return gtModuleDef.tPayPush.nID, gtModuleDef.tPayPush.sName
 end
function CPayPush:Online()
	self.m_nLoginTimes = self.m_nLoginTimes + 1
	self:Init()
end 

function CPayPush:Offline()
	self:RewardCheck()
end

function CPayPush:RewardCheck()
	local _SendMailReward = function (tItemList)
		GF.SendMail(self.m_oRole:GetServer(), "首次登陆奖励", "首次登陆奖励，请及时领取邮件", tItemList, self.m_oRole:GetID())
	end
	for nID, tItem in pairs(ctPayPushRewardConf) do
		if self.m_tPayPush[nID] and not self.m_tPayPush[nID].bReward then
			if self:PushCheck(nID) then
				--local tItemList = {}
				for _, tItemCfg in ipairs(tItem.tReward) do
					--table.insert(tItemList, {tItemCfg[1], tItemCfg[2], tItemCfg[3]})
					self.m_oRole:AddItem(tItemCfg[1], tItemCfg[2], tItemCfg[3], "首次登陆获得")
				end
				--_SendMailReward(tItemList)
			end
		end
	end
end

function CPayPush:BuyEvent(nID)
	local tData = self.m_tPayPush[nID]
	if tData then
		tData.bBuy =  true
		self:MarkDirty(true)
	end
end

function CPayPush:Init()
	for _, tCfg in pairs(ctPayPushConf) do
		if not self.m_tPayPush[tCfg.nID] then
			self.m_tPayPush[tCfg.nID] = {bBuy = false, nCount = 0} 	--是否购买对应的条件
		end
	end
	self:MarkDirty(true)
	self:PushCheck()
end


--nEventID 检测这个事件是否满足
function CPayPush:PushCheck(nEventID)
	if nEventID then
		if not self.m_tPayPush[nEventID] then
			 return
		 end
	end
	local nPayPushID 
	for nID, tData in pairs(self.m_tPayPush) do
		local tPushConf = ctPayPushConf[nID]
		if tPushConf then
			if tPushConf.nEventType == tPayPushEvent.eLevel and not tData.bBuy and tPushConf.nEventTimes == self.m_oRole:GetLevel()
				and (nEventID and nEventID == nID or tData.nCount == 0) then
				nPayPushID =  nID
				break
			elseif tPushConf.nEventType == tPayPushEvent.eLoginTimes and not tData.bBuy and tPushConf.nEventTimes == self.m_nLoginTimes and 
				(nEventID and nEventID == nID or tData.nCount == 0) then
				nPayPushID = nID
				break
			end
		end
	end
	
	if nEventID and nEventID == nPayPushID then
		return  true
	end

	if nPayPushID and self:CheckPushCond(nPayPushID) then
		local tMsg = {}
		tMsg.nID = nPayPushID

		self.m_tPayPush[nPayPushID].nCount =  self.m_tPayPush[nPayPushID].nCount + 1
		self:MarkDirty(true)
		self.m_oRole:SendMsg("PayPushIDRet", tMsg)
	end
end

function CPayPush:CheckPushCond(nPayPushID)
	if nPayPushID == 5 then --充值翻倍
		if self.m_oRole.m_oSysOpen:IsSysOpen(80) then
			return true
		end
	else
		return true
	end
end

function CPayPush:OnLevelChange(nOldLevel, nNewLevel)
	self:PushCheck()
 end


function CPayPush:PayPushReceiveRewardReq(nID)
	if not nID then return end
	local tItemCfg = ctPayPushRewardConf[nID]
	if not self.m_tPayPush[nID] then
		return 
	end
	if self.m_tPayPush[nID].bReward then
		return  self.m_oRole:Tips("领取过了哦")
	end
	if tItemCfg then
		for _, tItem in ipairs(tItemCfg.tReward) do
			self.m_oRole:AddItem(tItem[1], tItem[2], tItem[3], "推送领奖")
		end
		self.m_tPayPush[nID].bReward = true
		self:MarkDirty(true)
		local tMsg = {nID = nID}
		self.m_oRole:SendMsg("PayPushReceiveRewardRet", tMsg)
	end
end