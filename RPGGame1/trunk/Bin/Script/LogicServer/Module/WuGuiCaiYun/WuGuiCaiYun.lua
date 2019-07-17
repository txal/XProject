--五鬼财运
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CWGCY:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nID = 1 					--当前目标ID
	self.m_nZhanLi = 0 				--今天总战力
	self.m_tWGCYAward = {} 			--已领奖励
	self.m_nResetTime = 0  			--重置时间
	self.m_nTotalOnlineTime = 0 	--总在线时长

	self.m_bOnline = false 			--是否在线
	self.m_nOnlineTime = 0 			--上线时间

	self.m_nCurStar = 0				--今日最高星数
	self.m_nTotalStar = 0			--总的星级,为了降低耦合度,不采用成就的星级
end 

function CWGCY:LoadData(tData)
	if tData then 
		self.m_nID = math.max(tData.m_nID or 0, 1)
		self.m_nZhanLi = tData.m_nZhanLi
		self.m_tWGCYAward = tData.m_tWGCYAward
		self.m_nResetTime = tData.m_nResetTime
		self.m_nTotalOnlineTime = tData.m_nTotalOnlineTime or 0
		self.m_bOnline = tData.m_bOnline or false
		self.m_nOnlineTime = tData.m_nOnlineTime or 0
		self.m_nTotalStar = tData.m_nTotalStar or 0
		self.m_nCurStar = tData.m_nCurStar
	end
end

function CWGCY:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_nZhanLi = self.m_nZhanLi
	tData.m_tWGCYAward = self.m_tWGCYAward
	tData.m_nResetTime = self.m_nResetTime
	tData.m_nTotalOnlineTime = self.m_nTotalOnlineTime
	tData.m_bOnline = self.m_bOnline
	tData.m_nOnlineTime = self.m_nOnlineTime
	tData.m_nTotalStar = self.m_nTotalStar
	tData.m_nCurStar = self.m_nCurStar

	return tData
end

function CWGCY:Online()
	self:CheckReset()
	--玩家首次登陆
	if self.m_nOnlineTime == 0 then
		self.m_nTotalOnlineTime = math.max(self.m_nTotalOnlineTime, 3*60)
	end
	self.m_bOnline = true
	self.m_nOnlineTime = os.time()
	self:MarkDirty(true)
	self:WuGuiCaiYunInfoReq()
end

function CWGCY:Offline()
	self.m_bOnline = false
	self.m_nTotalOnlineTime = self.m_nTotalOnlineTime+os.time()-self.m_nOnlineTime
	self:MarkDirty(true)
end

function CWGCY:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nResetTime, 0) then
		self.m_nID = 1
		self.m_tWGCYAward = {}
		self.m_nTotalOnlineTime = 0
		self.m_nResetTime = os.time()
		self.m_nZhanLi = math.max(self.m_oPlayer:GetPower(), self.m_nZhanLi) 
		self.m_nCurStar = self.m_oPlayer.m_oShenMoZhiData:GetAllStar()
		self:MarkDirty(true)
	end
end

function CWGCY:OnMinTimer()
	if not self.m_bOnline then 
		return
	end
	self:CheckReset()

	local tConf = ctWuGuiCaiYunConf[self.m_nID]
	if tConf and self:GetOnlineTimeCount() >= tConf.nTime then 
		self.m_nID = self.m_nID + 1
		self:WuGuiCaiYunInfoReq()
		self:MarkDirty(true)
	end
end

function CWGCY:GetType()
	return gtModuleDef.tWuGuiCaiYun.nID, gtModuleDef.tWuGuiCaiYun.sName
end

function CWGCY:PushWGCY(nStar)
	self.m_nTotalStar = self.m_nTotalStar + nStar
	print("星级累加哦---------------------", self.m_nTotalStar)
	self:MarkDirty(true)
end
--取玩家在线时间
function CWGCY:GetOnlineTimeCount()
	self:CheckReset()
	if self.m_bOnline then
		return self.m_nTotalOnlineTime+os.time()-self.m_nOnlineTime
	else
		return self.m_nTotalOnlineTime
	end
end

--五鬼财运界面请求
function CWGCY:WuGuiCaiYunInfoReq()
	local nOnlineTime = self:GetOnlineTimeCount()
	local tList = {}
	for nID, tConf in ipairs(ctWuGuiCaiYunConf) do 
		local nState = self.m_tWGCYAward[nID] or 0
		if nState == 0 then 
			nState = nOnlineTime >= tConf.nTime and 1 or 0
		end
		table.insert(tList, {nID=nID, nState=nState})
	end
	--local nTotalZL = self.m_oPlayer:GetPower()
	--self.m_nCurStar = self.m_nTotalStar
	local nStar = self.m_nCurStar
	local tMsg = {tList=tList, nOnlineTimeCount=nOnlineTime, nTotalZL= nStar}
	self.m_oPlayer:SendMsg("WuGuiCaiYunInfoRet", tMsg)
	print("WuGuiCaiYunInfoRet***", tMsg)
end

--领取五鬼财运奖励
function CWGCY:GetWuGuiCaiYunAwardReq(nID)
	local tConf = ctWuGuiCaiYunConf[nID]
	if not tConf then 
		return self.m_oPlayer:Tips("该奖励不存在")
	end
	if self:GetOnlineTimeCount() < tConf.nTime then 
		return self.m_oPlayer:Tips("未达领取条件")
	end
	if self.m_tWGCYAward[nID] then 
		return self.m_oPlayer:Tips("已经领取过奖励")
	end
	self.m_tWGCYAward[nID] = 2
	self:MarkDirty(true)

	local tAward = {}
	local nNum = tConf.eItemNum(self.m_nCurStar)
	local tProp = ctPropConf[tConf.nItemID]
	-- if tProp.nSubType == gtCurrType.eYinBi then 
	-- 	--nNum = math.min(nNum+self.m_nZhanLi, tConf.nLimit)
	-- 	nNum = math.min(nNum + self.m_nCurStar * tConf.nLimit , tConf.nLimit)
	-- end

	tAward[1] = {nID=tConf.nItemID, nNum=nNum}
	self.m_oPlayer:AddItem(gtItemType.eProp, tConf.nItemID, nNum, "五鬼财运奖励")
	self.m_oPlayer:SendMsg("GetWuGuiCaiYunAwardRet", {tAward=tAward})
	self:WuGuiCaiYunInfoReq()
	CEventHandler:OnGetOnlineGift(self.m_oPlayer)
end







