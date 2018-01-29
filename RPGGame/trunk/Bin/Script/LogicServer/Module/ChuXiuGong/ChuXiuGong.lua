--储秀宫(三生殿)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CChuXiuGong.tDrawType = {
	eTLDraw = 1, 	--姻缘点单次结缘
	eYBOneDraw = 2, --元宝单次结缘
	eYBTenDraw = 3, --元宝10次结缘
}

function CChuXiuGong:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nLastFreeTime = 0 	--上次免费结缘时间
	self.m_nTLDrawTimes = 0 	--姻缘点结缘次数
	self.m_nYBDrawTimes = 0 	--元宝结缘次数
	self.m_nYBBaoDiTimes = 0 	--保底次数

	self.m_nTotalDraw = 0 		--全部抽奖次数(版署)
	self.m_nResetTime = os.time()
end

function CChuXiuGong:LoadData(tData)
	if not tData then
		return
	end
	self.m_nTLDrawTimes = tData.m_nTLDrawTimes
	self.m_nYBDrawTimes = tData.m_nYBDrawTimes
	self.m_nYBBaoDiTimes = tData.m_nYBBaoDiTimes or 0
	self.m_nLastFreeTime = tData.m_nLastFreeTime or os.time()

	self.m_nTotalDraw = tData.m_nTotalDraw or 0
	self.m_nResetTime = tData.m_nResetTime or os.time()
end

function CChuXiuGong:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nTLDrawTimes = self.m_nTLDrawTimes
	tData.m_nYBDrawTimes = self.m_nYBDrawTimes
	tData.m_nLastFreeTime = self.m_nLastFreeTime
	tData.m_nYBBaoDiTimes = self.m_nYBBaoDiTimes

	tData.m_nTotalDraw = self.m_nTotalDraw
	tData.m_nResetTime = self.m_nResetTime
	return tData
end

function CChuXiuGong:GetType()
	return gtModuleDef.tChuXiuGong.nID, gtModuleDef.tChuXiuGong.sName
end

function CChuXiuGong:Online()
	self:CheckRedPoint()
end

function CChuXiuGong:Offline()
	self:CancelFreeDrawTick()
end

--免费冷却时间
function CChuXiuGong:GetFreeCD()
	return math.max(0, self.m_nLastFreeTime+ctSSDEtcConf[1].nFreeTime-os.time())
end

--同步信息
function CChuXiuGong:SyncInfo()
	local tMsg = {}
	tMsg.nFreeCD = self:GetFreeCD()
	tMsg.nTiLiCD = self.m_oPlayer:GetTiLiRecoverCD()
	tMsg.nRareRemain = 10 - self.m_nYBDrawTimes % 10
	tMsg.nRemainTimes = self:GetRemainTimes()
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "CXGInfoRet", tMsg)
end

--是否第一次结缘
function CChuXiuGong:IsFirstDraw()
	return (self.m_nTLDrawTimes + self.m_nYBDrawTimes) <= 0
end

--检测次数重置
function CChuXiuGong:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nResetTime, 0) then
		self.m_nResetTime = os.time()
		self.m_nTotalDraw = 0
		self:MarkDirty(true)
	end
end

function CChuXiuGong:AddTimes(nTimes)
	do return end --非提审屏蔽
	self:CheckReset()
	self.m_nTotalDraw = self.m_nTotalDraw + nTimes
	self:MarkDirty(true)
end

function CChuXiuGong:CheckTimesLimit(nTimes)
	self:CheckReset()
	if self.m_nTotalDraw+nTimes > 20 then
		return self.m_oPlayer:Tips("剩余次数不足")
	end
	return true
end

function CChuXiuGong:GetRemainTimes()
	self:CheckReset()
	return math.max(0, 20-self.m_nTotalDraw)
end

--普通结缘
function CChuXiuGong:TiLiDraw(bUseProp)
	if not self:CheckTimesLimit(1) then
		return
	end

	--使用三生石
	if bUseProp then
		local tTLProp = ctSSDEtcConf[1].tTLProp[1]
		if self.m_oPlayer:GetItemCount(tTLProp[1], tTLProp[2]) <= 0 then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tTLProp[2])))
		end
		self.m_oPlayer:SubItem(tTLProp[1], tTLProp[2], 1, "姻缘点结缘")
		local nAddTiLi = self.m_oPlayer:GetMaxTiLi()
		self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eTiLi, nAddTiLi, "使用三生石")
		
		--任务		
		self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond19, 1)
		return self.m_oPlayer:Tips("已回复所有姻缘点") --已恢复所有姻缘点
	end

	local tTLCost = ctSSDEtcConf[1].tTLOneCost[1]
	if self.m_oPlayer:GetTiLi() < tTLCost[3] then
		return self.m_oPlayer:Tips("姻缘点不足") --姻缘点不足
	end
	self.m_oPlayer:SubItem(tTLCost[1], tTLCost[2], tTLCost[3], "姻缘点结缘")

	--随机物品
	local tItem 
	local n = 0 --防止死循环
	local bRare = (self.m_nTLDrawTimes+1)%10 == 0
	repeat
		if self:IsFirstDraw() then
			tItem = goCXDropMgr:GetItem(0)
		else
			if bRare then
				tItem = goCXDropMgr:GetItem(3)
			else
				tItem = goCXDropMgr:GetItem(1)
			end
		end
		n = n + 1
	until (tItem or n >= 1024)

	local tAwardList = self:SendAward({tItem}, "姻缘点结缘")
	self.m_nTLDrawTimes = self.m_nTLDrawTimes + 1
	self:MarkDirty(true)

	--赠送道具
	local tTLYPProp = ctSSDEtcConf[1].tTLYPProp[1]
	if tTLYPProp[1] > 0 then
		self.m_oPlayer:AddItem(tTLYPProp[1], tTLYPProp[2], tTLYPProp[3], "姻缘点结缘")
	end

	--消息
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "CXGDrawRet", {tAwardList=tAwardList, nDrawType=self.tDrawType.eTLDraw})
	self:SyncInfo()

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond14, 1)
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond12, 1)
	--小红点
	self:CheckRedPoint()

	--增加次数
	self:AddTimes(1)
end

--是否免费
function CChuXiuGong:IsYuanBaoDrawFree()
	return (self:GetFreeCD() <= 0)
end

--元宝单次结缘
function CChuXiuGong:YuanBaoOneDraw()
	if not self:CheckTimesLimit(1) then
		return
	end

	if self:IsYuanBaoDrawFree() then
		self.m_nLastFreeTime = os.time()
		self:MarkDirty(true)

	else
		local tYBOneCost = ctSSDEtcConf[1].tYBOneCost[1]
		if self.m_oPlayer:GetYuanBao() < tYBOneCost[3] then
			return self.m_oPlayer:YBDlg()
		end
		self.m_oPlayer:SubItem(tYBOneCost[1], tYBOneCost[2], tYBOneCost[3], "元宝结缘")

	end

	--随机物品
	local tItem, tConf
	local bRare = (self.m_nYBDrawTimes+1)%10 == 0
	local nBDTimes = ctSSDEtcConf[1].nBDTimes

	local n = 0 --防止死循环
	repeat
		if self:IsFirstDraw() then
			tItem, tConf = goCXDropMgr:GetItem(0)
		else
			if nBDTimes > 0 and self.m_nYBBaoDiTimes == nBDTimes then
				tItem, tConf = goCXDropMgr:GetItem(5)
			elseif bRare then
				tItem, tConf = goCXDropMgr:GetItem(4)
			else
				tItem, tConf = goCXDropMgr:GetItem(2)
			end
		end
		n = n + 1
	until (tItem or n >= 1024)

	local tAwardList = self:SendAward({tItem}, "元宝单次结缘")
	self.m_nYBDrawTimes = self.m_nYBDrawTimes + 1
	self.m_nYBBaoDiTimes = self.m_nYBBaoDiTimes + 1
	if tConf.bBaoDi then --遇到保底置0
		self.m_nYBBaoDiTimes = 0
	end
	self:MarkDirty(true)

	--赠送道具
	local tYBYPProp = ctSSDEtcConf[1].tYBYPProp[1]
	if tYBYPProp[1] > 0 then
		self.m_oPlayer:AddItem(tYBYPProp[1], tYBYPProp[2], tYBYPProp[3], "元宝单次结缘")
	end

	local tMsg = {
		tAwardList = tAwardList,
		nDrawType = self.tDrawType.eYBOneDraw,
		nRareRemain = 10-self.m_nYBDrawTimes%10
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "CXGDrawRet", tMsg)
	self:SyncInfo()

	--任务
	--self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond9, 1)
	--小红点
	self:CheckRedPoint()

	--次数
	self:AddTimes(1)
end

--元宝10次结缘
function CChuXiuGong:YuanBaoTenDraw()
	if not self:CheckTimesLimit(10) then
		return
	end

	local tYBTenCost = ctSSDEtcConf[1].tYBTenCost[1]
	if self.m_oPlayer:GetYuanBao() < tYBTenCost[3] then
		return self.m_oPlayer:YBDlg()
	end
	self.m_oPlayer:SubItem(tYBTenCost[1], tYBTenCost[2], tYBTenCost[3], "元宝结缘")

	--随机物品
	local tItemList = {}
	local nBDTimes = ctSSDEtcConf[1].nBDTimes
	for k = 1, 10 do
		local tItem, tConf
		local bRare = (self.m_nYBDrawTimes+1)%10 == 0

		local n = 0
		repeat
			if self:IsFirstDraw() then
				tItem, tConf = goCXDropMgr:GetItem(0)
			else
				if nBDTimes > 0 and self.m_nYBBaoDiTimes == nBDTimes then
					tItem, tConf = goCXDropMgr:GetItem(5)
				elseif bRare then
					tItem, tConf = goCXDropMgr:GetItem(4)
				else
					tItem, tConf = goCXDropMgr:GetItem(2)
				end
			end
			n = n + 1
		until (tItem or n >= 1024)

		table.insert(tItemList, tItem)
		self.m_nYBDrawTimes = self.m_nYBDrawTimes + 1
		self.m_nYBBaoDiTimes = self.m_nYBBaoDiTimes + 1

		if tConf.bBaoDi then
			self.m_nYBBaoDiTimes = 0
		end

	end
	local tAwardList = self:SendAward(tItemList, "元宝10次结缘")
	self:MarkDirty(true)

	--赠送道具
	local tYBYPProp = ctSSDEtcConf[1].tYBYPProp[1]
	if tYBYPProp[1] > 0 then
		self.m_oPlayer:AddItem(tYBYPProp[1], tYBYPProp[2], tYBYPProp[3]*10, "元宝10次结缘")
	end

	local tMsg = {
		tAwardList = tAwardList,
		nDrawType = self.tDrawType.eYBTenDraw,
		nRareRemain = 10-self.m_nYBDrawTimes%10
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "CXGDrawRet", tMsg)
	self:SyncInfo()

	--任务
	--self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond9, 10)
	--次数
	self:AddTimes(10)
end

--发放奖励
function CChuXiuGong:SendAward(tItemList, sReason)
	local tAwardList = {}
	for _, tItem in ipairs(tItemList) do 
		local tAward = {nType=tItem[1], nID=tItem[2], nNum=tItem[3], bExchange=false}
		if tItem[1] == gtItemType.eProp then
			local tConf = assert(ctPropConf[tItem[2]])
			if tConf.nSubType == gtCurrType.eQinMi and tItem[3] == 1000 then
				local oMC = self.m_oPlayer.m_oMingChen:GetObj(tConf.nVal)
				if oMC then --知己已经存在则兑换成一定亲密度
					tAward.bExchange = true --是否转成亲密度
					tAward.nNum = ctMingChenConf[tConf.nVal].nQinMiExchange
					self.m_oPlayer:AddItem(tAward.nType, tAward.nID, tAward.nNum, sReason)

				else
					self.m_oPlayer:AddItem(gtItemType.eMingChen, tConf.nVal, 1, sReason)

					--电视
					local tMCConf = ctMingChenConf[tConf.nVal]
					local tPingJiName = {[1] = "佳才", [2] = "豪杰", [3] = "天骄"}
					if tPingJiName[tMCConf.nPingJi] then
						local sNotice = string.format(ctLang[3], self.m_oPlayer:GetName(), tPingJiName[tMCConf.nPingJi], tMCConf.sName)
						goTV:_TVSend(sNotice)	
					end
				end
			else
				self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], sReason)
			end
		else
			self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], sReason)
		end
		table.insert(tAwardList, tAward)
	end
	return tAwardList
end

--结缘请求
function CChuXiuGong:DrawReq(nDrawType, bUseProp)
	if nDrawType == self.tDrawType.eTLDraw then
		self:TiLiDraw(bUseProp)
	elseif nDrawType == self.tDrawType.eYBOneDraw then
		self:YuanBaoOneDraw()
	elseif nDrawType == self.tDrawType.eYBTenDraw then
		self:YuanBaoTenDraw()
	end
end

--注册免费次数计时器
function CChuXiuGong:RegFreeDrawTick()
	self:CancelFreeDrawTick()

	local nCD = self:GetFreeCD()
	if nCD <= 0 then
		return
	end

	self.m_nFreeDrawTick = goTimerMgr:Interval(nCD, function() self:CheckRedPoint() end)
end

--取消免费次数计时器
function CChuXiuGong:CancelFreeDrawTick()
	goTimerMgr:Clear(self.m_nFreeDrawTick)
	self.m_nFreeDrawTick = nil
end

--检测小红点
function CChuXiuGong:CheckRedPoint()
	--姻缘点结缘
	local tTLCost = ctSSDEtcConf[1].tTLOneCost[1]
	if self.m_oPlayer:GetTiLi() < tTLCost[3] then
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eCXGTLDraw, 0)
	else
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eCXGTLDraw, 1)
	end
	
	--元宝结缘
	if self:IsYuanBaoDrawFree() then
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eCXGYBDraw, 1)
		self:CancelFreeDrawTick()
	else
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eCXGYBDraw, 0)
		self:RegFreeDrawTick()
	end
end

--重置储秀宫次数
function CChuXiuGong:GMReset()
	self.m_nResetTime = 0
	self:MarkDirty(true)
end