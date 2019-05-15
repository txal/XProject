--联盟经验冲榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CUnionExpCB:Ctor(nID)
	CCBBase.Ctor(self, nID)     --继承基类
end

function CUnionExpCB:GetRankingConf()
	return ctUnionExpRankingConf
end

function CUnionExpCB:GetAwardRanking()
	local tConf = ctMZCBEtcConf[1]
	return 1, tConf.nUnionExpAwardRanking
end

--检测奖励状态
function CUnionExpCB:CheckAwardState(nUnionID, nRoleID)
	local nMyRank = self:MyRank(nUnionID)
	local nMinRank, nMaxRank = self:GetAwardRanking()
	self.m_tAwardState[nRoleID] = self.m_tAwardState[nRoleID] or 0

	if self:GetState() == CHDBase.tState.eAward and self.m_tAwardState[nRoleID]==0 and nMyRank>=nMinRank and nMyRank<=nMaxRank then
		self.m_tAwardState[nRoleID] = CHDBase.tAwardState.eFeed
		self:MarkDirty(true)
	end
	return self.m_tAwardState[nRoleID]
end

--奖励列表, 返回值: 给玩家的奖励列表，帮派礼盒数量
function CUnionExpCB:GetRankAward(nRank, nPos)
	assert(nPos>=1 and nPos<=6, "帮派职位错误:"..nPos)

	local tList = {}
	local tRankingConf = self:GetRankingConf()

	local nUnionGiftBoxCount = 0
	for k=#tRankingConf, 1, -1 do 
		local tConf = tRankingConf[k]
		local tRank = tConf.tRanking[1]
		if nRank >= tRank[1] and nRank <= tRank[2] then 
			local tAward
			if self:GetOpenTimes() == 1 then
				tAward = tConf["tAward1"..nPos]
			else
				tAward = tConf["tAward2"..nPos]
			end
			for _, tItem in ipairs(tAward) do 
				if tItem[1] == gtItemType.eProp and tItem[2] == gnUnionGiftBoxPropID then 
					nUnionGiftBoxCount = nUnionGiftBoxCount + tItem[3]
				else
					table.insert(tList, {tItem[1], tItem[2], tItem[3]})
				end
			end
			break
		end
	end
	return tList, nUnionGiftBoxCount
end

function CUnionExpCB:GetFirstRank()
	local sFirstName = ""
	local nFirstValue = 0

	local tFirstRank = self.m_tTmpRanking[1]
	if tFirstRank then
		local oUnion = goUnionMgr:GetUnion(tFirstRank[1])
		if oUnion then
			sFirstName = oUnion:GetName()
			nFirstValue = tFirstRank[2] 
		end
	end
	return sFirstName, nFirstValue
end

--进入活动
function CUnionExpCB:InActivityReq(oRole)
	if self:GetState() == CHDBase.tState.eInit or self:GetState() == CHDBase.tState.eClose then
		return oRole:Tips("活动未开始或已结束")
	end
	local oUnion = goUnionMgr:GetUnionByRoleID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入帮派")
	end

	self:ProcessRanking()

	local nMyRank = self:MyRank(oUnion:GetID())
	local nAwardState = self:CheckAwardState(oUnion:GetID(), oRole:GetID())
	local sFirstName, nFirstValue = self:GetFirstRank()


	local nState = self:GetState()
	local _, _, nStateTime = self:GetStateTime()
	local tMsg = {
		nID=self:GetID(),
		nState=nState,
		nStateTime=nStateTime,
		nAwardState=nAwardState,
		sFirstName=sFirstName,
		nFirstValue=nFirstValue,
		nMyRank=nMyRank,
		nOpenTimes=self:GetOpenTimes(),
	  }
	oRole:SendMsg("CBInActivityRet", tMsg)
end

--冲榜榜单请求
function CUnionExpCB:RankingReq(oRole, nRankNum)
	if self:GetState() == CHDBase.tState.eInit or self:GetState() == CHDBase.tState.eClose then
		return oRole:Tips("活动已结束")
	end

	self:ProcessRanking()

	local oUnion = goUnionMgr:GetUnionByRoleID(oRole:GetID())
	if not oUnion then
		return oRole:Tips("请先加入帮派")
	end

	local nMinRank, nMaxRank = self:GetAwardRanking()
	nRankNum = math.max(1, math.min(nMaxRank, nRankNum))
	local nMyRank, nMyValue = self:MyRank(oUnion:GetID())

	local tRanking = {}
	for k=1, nRankNum do 
		local tRank = self.m_tTmpRanking[k]
		if tRank then
			local oTmpUnion = goUnionMgr:GetUnion(tRank[1])
			if oTmpUnion then
				table.insert(tRanking, {nRank=k, sName=oTmpUnion:GetName(), nValue=tRank[2]})
			end
		else
			break
		end
	end

	local tMsg = {
		nID = self:GetID(),
		tRanking = tRanking,
		nMyRank = nMyRank,
		nMyValue = nMyValue,
	}
	oRole:SendMsg("CBRankingRet", tMsg)
end

--领取奖励
function CUnionExpCB:GetAwardReq(oRole)
	if self:GetState() ~= CHDBase.tState.eAward then
		return oRole:Tips("未到领奖时间")
	end
	local nRoleID = oRole:GetID()
	local oMyUnion = goUnionMgr:GetUnionByRoleID(nRoleID)
	if not oMyUnion then
		return oRole:Tips("请先加入帮派")
	end
	if self.m_tAwardState[nRoleID] == CHDBase.tAwardState.eClose then 
		return oRole:Tips("已领取过奖励")
	end
	if self.m_tAwardState[nRoleID] ~= CHDBase.tAwardState.eFeed then 
		return oRole:Tips("未达领奖条件")
	end
	self.m_tAwardState[nRoleID] = CHDBase.tAwardState.eClose   --已领取
	self:MarkDirty(true)
	goCBMgr:SyncState(oRole)
	
	local tItemList = {}
	local nMyRank = self:MyRank(oMyUnion:GetID())
	local nMyPos = oMyUnion:GetPos(nRoleID)
	local tAward, nUnionGiftBoxCount = self:GetRankAward(nMyRank, nMyPos)
	for _, tItem in ipairs(tAward) do 
		table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end

	if nUnionGiftBoxCount > 0 then 
		oRole:AddUnionGiftBox(gtUnionGiftBoxReason.eUnionExpCB, nUnionGiftBoxCount)
	end
	oRole:AddItem(tItemList, self:GetName(), function(bRet)
		if bRet then
			oRole:SendMsg("CBGetAwardRet", {tList=tItemList, nAwardState=self.m_tAwardState[nRoleID]})
			--日志
			local nValue = self.m_tDiffValue[nRoleID] or 0
			goLogger:ActivityLog(oRole, self:GetID(), self:GetName(), {}, tAward, nValue, nMyRank, self:GetOpenTimes())
		end
	end)
end

--是否能领取奖励
function CUnionExpCB:CanGetAward(oRole)
	if self:GetState() ~= CHDBase.tState.eAward then
		return false
	end
	local oUnion = goUnionMgr:GetUnionByRoleID(oRole:GetID())
	if not oUnion then
		return false
	end
	if self:CheckAwardState(oUnion:GetID(), oRole:GetID()) == CHDBase.tAwardState.eFeed then
		return true 
	end
	return false
end

--处理称号
function CCBBase:CheckTitle()
	local nUnionID = self.m_tTmpRanking[1]
	local oUnion = goUnionMgr:GetUnion(nUnionID)
	local nTitle = gtCBTitle[self:GetID()]
	if oUnion and nTitle then
		goHallFame:AddTitle(nTitle, oUnion:GetMengZhu())
	end
end

--进入领奖状态
function CUnionExpCB:OnStateAward()
	print("活动:", self.m_nID, "进入奖励状态")
	self:ProcessRanking(true) 
	for _, tRank in ipairs(self.m_tTmpRanking) do
		local oUnion = goUnionMgr:GetUnion(tRank[1])
		if oUnion then
			local tMemberMap = oUnion:GetMemberMap()
			for nRoleID, v in pairs(tMemberMap) do
				self:CheckAwardState(nUnionID, nRoleID)
			end
		end
	end
	goCBMgr:OnStateAward()
	self:CheckTitle()
end  

--进入关闭状态
function CUnionExpCB:OnStateClose()
	print("活动:", self.m_nID, "进入关闭状态")
	self:CheckCloseAward()
	goCBMgr:OnStateClose()
end

--检测未领奖的玩家,然后发奖
function CUnionExpCB:CheckCloseAward()
	local tConf = ctMZCBEtcConf[1]
	local nMinRank, nMaxRank = self:GetAwardRanking()
	for k = nMinRank, nMaxRank do
		local nUnionID = self.m_tTmpRanking[k]
		local oUnion = goUnionMgr:GetUnion(nUnionID)
		if oUnion then
			local tMemberMap = oUnion:GetMemberMap()
			for nRoleID, v in pairs(tMemberMap) do
				if self.m_tAwardState[nRoleID] == CHDBase.tAwardState.eFeed then
					local nUnionPos = oUnion:GetPos(nRoleID)
					local oRole = goGPlayerMgr:GetRoleByID(nRoleID)	
					local sCont = string.format("您在%s活动中获得第%d名，获得了以下奖励，请查收。", self:GetName(), k)

					local tAward, nUnionGiftBoxCount = self:GetRankAward(k, nUnionPos)
					GF.SendMail(oRole:GetServer(), self:GetName().."奖励", sCont, tAward, nRoleID) 
					if nUnionGiftBoxCount > 0 then 
						oRole:AddUnionGiftBox(gtUnionGiftBoxReason.eUnionExpCB, nUnionGiftBoxCount)
					end
					self.m_tAwardState[nRoleID] = CHDBase.tAwardState.eClose
					self:MarkDirty(true)
				end
			end
		end
	end
end

function CUnionExpCB:UpdateValue(nUnionID, nDiffValue)
	if nDiffValue == 0 then
		return
	end
	if self:GetState() ~= CHDBase.tState.eStart then
		return
	end
	if not goUnionMgr:GetUnion(nUnionID) then
		return
	end
	self.m_tDiffValue[nUnionID] = (self.m_tDiffValue[nUnionID] or 0) + nDiffValue

	--<=0不上榜
	if self.m_tDiffValue[nUnionID] <= 0 then
		self.m_tDiffValue[nUnionID] = nil
	end
	
	self:MarkDirty(true)
end