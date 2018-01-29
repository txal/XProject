--限时选秀
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxRankingNum = 200 			--最大200条几率返回
local nRankingUpdateTime = 3600		--排行榜更新时间

function CTimeDraw:Ctor(nID)
	CHDBase.Ctor(self, nID)
	self.m_nMCID = 0				--特殊知己ID	
	self:Init()
end

function CTimeDraw:Init()
	self.m_tIntegralMap = {}		--个人积分映射{[charid] = {times=0, Integral=0, LastFreeTime=0},...}

	self.m_nLastRankTime = 0 		--上次排行榜上报时间
	self.m_tIntegralRanking = {} 	--积分排行榜
	self.m_tBaoDiTimes = {} 		--保底次数{charid = times,...}
end

function CTimeDraw:LoadData()
	local nID = self:GetID()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sHuoDongDB, self:GetID())    
	if sData == "" then
		return
	end
	local tData = cjson.decode(sData)
	CHDBase.LoadData(self, tData)
	self.m_nMCID = tData.m_nMCID or 0
	
	self.m_tBaoDiTimes = tData.m_tBaoDiTimes
	self.m_tIntegralMap = tData.m_tIntegralMap
end

function CTimeDraw:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_nMCID = self.m_nMCID
	tData.m_tIntegralMap = self.m_tIntegralMap
	tData.m_tBaoDiTimes = self.m_tBaoDiTimes
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
end

--开启活动
function CTimeDraw:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)	
	LuaTrace("开启限时选秀活动", nStartTime, nEndTime, nAwardTime, nExtID)
	if self:GetPropByMC(nExtID) then 
		self.m_nMCID = nExtID
		self:MarkDirty(true)
		CHDBase.OpenAct(self, nStartTime, nEndTime, nAwardTime)	
	else
		return LuaTrace("限时选秀知己", nExtID, "没有对应的碎片道具")
	end
end

--玩家上线
function CTimeDraw:Online(oPlayer)
	self:SyncState(oPlayer)
end

--更新状态
function CTimeDraw:UpdateState()
	CHDBase.UpdateState(self)
end

--进入初始状态
function CTimeDraw:OnStateInit()
	print("限时选秀进入初始状态")
	self:SyncState()
end

--进入活动状态
function CTimeDraw:OnStateStart()
	print("限时选秀进入开始状态")
	--初始化
	self:Init()
	self:SyncState()
	self:MarkDirty(true)
end

--进入领奖状态
function CTimeDraw:OnStateAward()
	print("限时选秀进入领奖状态")
	self:SyncState()
end

--进入关闭状态
function CTimeDraw:OnStateClose()
	print("限时选秀进入关闭状态")
	self:UpdateRanking(true)
	self:PlayRaningAward()
	self:SyncState()
end

--是否免费
function CTimeDraw:GetDrawFreeTime(nCharID)
	self.m_tIntegralMap[nCharID] = self.m_tIntegralMap[nCharID] or {}
	self.m_tIntegralMap[nCharID].nLastFreeTime = self.m_tIntegralMap[nCharID].nLastFreeTime or 0
	local nRemainCD = math.max(0, self.m_tIntegralMap[nCharID].nLastFreeTime+ctTimeDrawEtcConf[1].nFreeTime-os.time())
	return nRemainCD  
end

--同步信息
function CTimeDraw:SyncState(oPlayer)
	local nStateTime = self:GetStateTime()
	local nBeginTime, nEndTime, nAwardTime = self:GetActTime() 		
	local nMyRank, nIntegral, nFreeTimeCD, nTimes = 0, 0, 0, 0

	if oPlayer then 
		local nCharID = oPlayer:GetCharID()
		
		self.m_tIntegralMap[nCharID] = self.m_tIntegralMap[nCharID] or {}
		self.m_tIntegralMap[nCharID].nTimes = self.m_tIntegralMap[nCharID].nTimes or 0
		self.m_tIntegralMap[nCharID].nIntegral = self.m_tIntegralMap[nCharID].nIntegral or 0
		self.m_tIntegralMap[nCharID].nLastFreeTime = self.m_tIntegralMap[nCharID].nLastFreeTime or 0

		nMyRank = self:GetPlayerRank(nCharID)
		nFreeTimeCD = self:GetDrawFreeTime(nCharID)
		nIntegral = self.m_tIntegralMap[nCharID].nIntegral or 0 
		nTimes = ctTimeDrawEtcConf[1].nTimes - self.m_tIntegralMap[nCharID].nTimes % 10
	end 

	local tMsg = {
		nID = self:GetID(),					--活动ID
		nTimes = nTimes,					--抽奖次数
		nIntegral = nIntegral,				--个人积分
		nMyRank = nMyRank, 	 				--我的排名
		nFreeTimeCD = nFreeTimeCD, 			--免费抽奖CD时间
		nStateTime = nStateTime, 			--活动时间
		nBeginTime = nBeginTime,			--活动开始时间
		nEndTime = nEndTime,				--活动结束时间
		nState = self:GetState(), 	 	 	--活动状态
		nMCID = self.m_nMCID,		  		--特殊知己
	}

	--同步指定玩家
	if oPlayer then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeDrawStateRet", tMsg)
	else
	--全服广播
		CmdNet.PBSrv2All("TimeDrawStateRet", tMsg)
	end
end

--检测分配宫女是否上限
function CTimeDraw:CheckGongNVLimit(oPlayer, bTips)
	return oPlayer.m_oChuXiuGong:CheckGongNvLimit(bTips)
end

--选秀单抽
function CTimeDraw:OneDraw(oPlayer)
	if not self:CheckGongNVLimit(oPlayer, true) then 
		return
	end

	local nCharID = oPlayer:GetCharID()
	if self:GetDrawFreeTime(nCharID) <= 0 then
		self.m_tIntegralMap[nCharID].nLastFreeTime = os.time()
	else
		local tOneToken = ctTimeDrawEtcConf[1].tOneToken[1]
		local nToken = oPlayer:GetItemCount(tOneToken[1], tOneToken[2])
		if nToken < tOneToken[3] then 
			local tYBOneCost = ctTimeDrawEtcConf[1].tYBOneCost[1]  
			if oPlayer:GetYuanBao() < tYBOneCost[3] then 
				return oPlayer:YBDlg()
			end
			oPlayer:SubItem(tYBOneCost[1], tYBOneCost[2], tYBOneCost[3], "限时选秀单抽")
		else
			oPlayer:SubItem(tOneToken[1], tOneToken[2], tOneToken[3], "选秀令选秀")
		end
	end

	--随机物品(1元宝，2珍稀库)
	local tItem, tInfo
	local bRare = (self.m_tIntegralMap[nCharID].nTimes+1)%10 == 0
	local tConf = ctTimeDrawEtcConf[1]
	local nTimes = tConf.nBaoDiTimes
	self.m_tBaoDiTimes[nCharID] = self.m_tBaoDiTimes[nCharID] or 0 
	local bBaoDi = (self.m_tBaoDiTimes[nCharID]+1)%nTimes == 0

	if bBaoDi then 
		tItem, tInfo = goTDDropMgr:GetItem(3)
	else	
		if bRare then 
			tItem, tInfo = goTDDropMgr:GetItem(2)
		else
			tItem, tInfo = goTDDropMgr:GetItem(1)
		end
	end
	local tAwardList = self:SendAward(oPlayer,{tItem}, "限时选秀单抽")
	self.m_tBaoDiTimes[nCharID] = (self.m_tBaoDiTimes[nCharID] or 0) + 1
	if tConf.bBaoDi then self.m_tBaoDiTimes[nCharID] = 0 end 	--抽到保底重置为0
	self.m_tIntegralMap[nCharID].nTimes = self.m_tIntegralMap[nCharID].nTimes + 1
	self.m_tIntegralMap[nCharID].nIntegral = (self.m_tIntegralMap[nCharID].nIntegral or 0) + ctTimeDrawEtcConf[1].nIntegral

	--银票
	local tYPProp = ctTimeDrawEtcConf[1].tYinPiao[1]
	oPlayer:AddItem(tYPProp[1], tYPProp[2], tYPProp[3], "限时选秀单抽")

	local tMsg = {
		tAwardList = tAwardList,
		nRareRemain = 10 - self.m_tIntegralMap[nCharID].nTimes%10
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeDrawRet", tMsg)
	self:MarkDirty(true)
	self:SyncState(oPlayer)

end

--选秀10抽
function CTimeDraw:TenDraw(oPlayer)
	if not self:CheckGongNVLimit(oPlayer, true) then 
		return
	end

	local tTenToken = ctTimeDrawEtcConf[1].tTenToken[1]
	local nToken = oPlayer:GetItemCount(tTenToken[1], tTenToken[2])
	if nToken < tTenToken[3] then 
		local tYBTenCost = ctTimeDrawEtcConf[1].tYBTenCost[1]  
		if oPlayer:GetYuanBao() < tYBTenCost[3] then 
			return oPlayer:YBDlg()
		end
		oPlayer:SubItem(tYBTenCost[1], tYBTenCost[2], tYBTenCost[3], "限时选秀10抽")
	else
		oPlayer:SubItem(tTenToken[1], tTenToken[2], tTenToken[3], "选秀令选秀")
	end

	--随机物品(1元宝，2珍稀库)
	local tItemList = {}
	local nCharID = oPlayer:GetCharID()
	local nIntegral = ctTimeDrawEtcConf[1].nIntegral
	for k = 1, 10 do
		local tItem, tConf
		local n = 0
		local tInfo = ctTimeDrawEtcConf[1]
		local nTimes = tInfo.nBaoDiTimes
		self.m_tBaoDiTimes[nCharID] = self.m_tBaoDiTimes[nCharID] or 0 
		local bBaoDi = (self.m_tBaoDiTimes[nCharID]+1)%nTimes == 0

		if bBaoDi then 
			tItem, tConf = goTDDropMgr:GetItem(3)
		else
			local bRare = (self.m_tIntegralMap[nCharID].nTimes+1)%10 == 0
			if bRare then
				tItem, tConf = goTDDropMgr:GetItem(2)
			else
				tItem, tConf = goTDDropMgr:GetItem(1)
			end
		end
		table.insert(tItemList, tItem)
		self.m_tBaoDiTimes[nCharID] = (self.m_tBaoDiTimes[nCharID] or 0) + 1
		if tConf.bBaoDi then self.m_tBaoDiTimes[nCharID] = 0 end  	--抽到保底重置为0
		self.m_tIntegralMap[nCharID].nTimes = self.m_tIntegralMap[nCharID].nTimes + 1
		self.m_tIntegralMap[nCharID].nIntegral = (self.m_tIntegralMap[nCharID].nIntegral or 0) + nIntegral  
	end
	local tAwardList = self:SendAward(oPlayer, tItemList, "限时选秀10抽")

	--银票
	local tYPProp = ctTimeDrawEtcConf[1].tYinPiao[1]
	oPlayer:AddItem(tYPProp[1], tYPProp[2], tYPProp[3]*10, "限时选秀10抽")

	local tMsg = {
		tAwardList = tAwardList,
		nRareRemain = 10 - self.m_tIntegralMap[nCharID].nTimes%10
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeDrawRet", tMsg)
	self:MarkDirty(true)
	self:SyncState(oPlayer)
end

--抽奖发放奖励处理
function CTimeDraw:SendAward(oPlayer, tItemList, sReason)
	local tAwardList = {}
	for _, tItem in ipairs(tItemList) do
		local tAward = {nType=tItem[1], nID=tItem[2], nNum=tItem[3], bExchange=false}
		if tItem[1] == gtItemType.eProp then
			if tItem[2] == -1 then         	--抽到特殊知己碎片
				tItem[2] = self:GetPropByMC(self.m_nMCID)
				tAward.nID = tItem[2]
			end			
			local tConf = assert(ctPropConf[tItem[2]])
			if tConf.nSubType == gtCurrType.eQinMi and tItem[3] == 1000 then
				local oMC = oPlayer.m_oMingChen:GetObj(tConf.nVal)
				if oMC then 						--知己已经存在则兑换成一定亲密度
					tAward.bExchange = true 		--是否转成亲密度
					tAward.nNum = ctMingChenConf[tConf.nVal].nExchangeQinMi
					oPlayer:AddItem(tItem[1], tItem[2], tAward.nNum, sReason)
				else
					oPlayer:AddItem(gtItemType.eFeiZi, tConf.nVal, 1, sReason)
				end
			else
				oPlayer:AddItem(tItem[1], tItem[2], tItem[3], sReason)
			end
		else
			oPlayer:AddItem(tItem[1], tItem[2], tItem[3], sReason)
		end
		table.insert(tAwardList, tAward)
	end
	return tAwardList
end

--限时选秀请求
function CTimeDraw:TimeDrawReq(oPlayer, nDrawType)
	assert(nDrawType==1 or nDrawType==2, "选项有误")
	if self:GetState() == CTimeDraw.tState.eInit or self:GetState() == CTimeDraw.tState.eClose then
		return oPlayer:Tips("活动已结束")
	end
	if nDrawType == 1 then
		self:OneDraw(oPlayer)
	else  
		self:TenDraw(oPlayer)
	end
end

--排行榜更新
function CTimeDraw:UpdateRanking(bEnd)
	if os.time() - self.m_nLastRankTime < nRankingUpdateTime and not bEnd then
		return 
	end
	self.m_nLastRankTime = os.time()
	self.m_tIntegralRanking = {}
	for nCharID, tConf in pairs(self.m_tIntegralMap) do
		if tConf.nIntegral ~= 0 then
			table.insert(self.m_tIntegralRanking, nCharID)
		end
	end
	
	table.sort(self.m_tIntegralRanking , function(v1, v2)
		local nVal1 = self.m_tIntegralMap[v1].nIntegral
		local nVal2 = self.m_tIntegralMap[v2].nIntegral

		if nVal1 == nVal2 then
			return v1 < v2
		end
		return nVal1 > nVal2
	end)
end

--取我的排名
function CTimeDraw:GetPlayerRank(nCharID)
	local nRank, nValue = 0, 0
	if not self.m_tIntegralMap[nCharID] then
		return nRank, nValue
	end
	local function fnCmp(v1, v2)
		local nVal1 = self.m_tIntegralMap[v1].nIntegral or 0  --值1
		local nVal2 = self.m_tIntegralMap[v2].nIntegral or 0  --值2
		if nVal1 == nVal2 then
			if v1 == v2 then
				return 0
			end
			if v1 > v2 then
				return 1
			else
				return -1
			end
		else
			if nVal1 > nVal2 then
				return -1
			else
				return 1
			end
		end 
	end 
	nRank = CAlg:BinarySearch(self.m_tIntegralRanking, fnCmp, nCharID, true)
	nValue = self.m_tIntegralMap[nCharID].nIntegral
	return nRank, nValue
end

--个人排行榜请求
function CTimeDraw:PlayerRankingReq(oPlayer, nRankNum)
	if self:GetState() == CTimeDraw.tState.eInit or self:GetState() == CTimeDraw.tState.eClose then
		return oPlayer:Tips("活动已结束")
	end
	self:UpdateRanking()
	local nCharID = oPlayer:GetCharID()
	local nRankNum = math.max(1, math.min(nRankNum, nMaxRankingNum))
	local nMyRank, nMyValue = self:GetPlayerRank(nCharID)
	local tMsg = {tRanking={}, nMyRank=nMyRank, sMyName="", nMyValue=nMyValue}
	for k = 1, nRankNum do
		local nTmpCharID = self.m_tIntegralRanking[k]
		if nTmpCharID then
			local tItem = {nRank=k, sName=goOfflineDataMgr:GetName(nTmpCharID), nValue=self.m_tIntegralMap[nTmpCharID].nIntegral}
			table.insert(tMsg.tRanking, tItem)
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeDrawRankingRet", tMsg)
	self:SyncState(oPlayer)
end

--通过知己ID取碎片ID
function CTimeDraw:GetPropByMC(nMCID)
	for _, tConf in pairs(ctPropConf) do
		if tConf.nType == gtPropType.eCurr and tConf.nSubType == gtCurrType.eQinMi then
			if tConf.nVal == nMCID then
				return tConf.nID
			end
		end
	end
end

--排行榜奖励发放
function CTimeDraw:PlayRaningAward()
	if self:GetState() == CTimeDraw.tState.eClose then 
		for nRank, nCharID in ipairs(self.m_tIntegralRanking) do 
			if nRank <= ctTimeDrawEtcConf[1].nRanking and self.m_tIntegralMap[nCharID].nIntegral >= ctTimeDrawEtcConf[1].nMinScore then 
				for k = #ctTimeDrawRanking, 1, -1 do
					local tConf = ctTimeDrawRanking[k]
					local tRank = tConf.tRank[1]
					if nRank >= tRank[1] and nRank <= tRank[2] then
						local nMCID, nItemID
						local tAward = tConf.tAward[1]
						if tAward[2] == -1 then 
							nMCID = self.m_nMCID
							nItemID = self:GetPropByMC(nMCID) 
						else
							nMCID = ctPropConf[tAward[2]].nVal
							nItemID = tAward[2]
						end
						local sName = ctMingChenConf[nMCID].sName
						local tList = {{tAward[1], nItemID, tAward[3]}}
						local sContent = string.format("恭喜您在限时结缘活动中积分排名第%d，获得 %s 亲密度+%d", nRank, sName, tAward[3])
						goMailMgr:SendMail("系统邮件", "限时结缘排名奖励", sContent, tList, nCharID)
					end
				end
			end
		end
	end
end

