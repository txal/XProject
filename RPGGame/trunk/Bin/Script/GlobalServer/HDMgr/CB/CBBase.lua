--冲榜基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CCBBase:Ctor(nID)
	CHDBase.Ctor(self, nID)     --继承基类
	self:Init()
end

function CCBBase:Init()
	self.m_tDiffValue = {} 		--涨幅值{[roleid]=value,...}
	self.m_tAwardState = {}   	--领奖状态{[roleid]=state,...}
	self.m_tTmpRanking = {}   	--中间排行结果每配置时间排一次
	self.m_nLastRankTime = 0  	--上次排序时间

	--不保存
	self.m_tTmpRankingMap = {} 	--中间徘徊结果映射
end

function CCBBase:DealLoadData(tData)
	CHDBase.LoadData(self, tData)
	self.m_tTmpRanking = tData.m_tTmpRanking
	self.m_tDiffValue = tData.m_tDiffValue
	self.m_tAwardState = tData.m_tAwardState
	for _, tRank in ipairs(self.m_tTmpRanking) do
		if type(tRank) ~= "table" then
			self.m_tTmpRanking = {}
			self.m_tTmpRankingMap = {}
			break
		else
			self.m_tTmpRankingMap[tRank[1]] = tRank
		end
	end
end

function CCBBase:LoadData()
	print("加载活动数据", self:GetName())
	local sData = goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID()):HGet(gtDBDef.sHuoDongDB, self:GetID()) 
	if sData == "" then return end

	local tData = cjson.decode(sData)
	-- CHDBase.LoadData(self, tData)
	-- self.m_tTmpRanking = tData.m_tTmpRanking
	-- self.m_tDiffValue = tData.m_tDiffValue
	-- self.m_tAwardState = tData.m_tAwardState

	-- for _, tRank in ipairs(self.m_tTmpRanking) do
	-- 	if type(tRank) ~= "table" then
	-- 		self.m_tTmpRanking = {}
	-- 		self.m_tTmpRankingMap = {}
	-- 		break
	-- 	else
	-- 		self.m_tTmpRankingMap[tRank[1]] = tRank
	-- 	end
	-- end
	self:DealLoadData(tData)
end

function CCBBase:GetSaveData() 
	local tData = CHDBase.SaveData(self)
	tData.m_tTmpRanking = self.m_tTmpRanking
	tData.m_tDiffValue = self.m_tDiffValue
	tData.m_tAwardState = self.m_tAwardState
	return tData
end

function CCBBase:SaveData()
	if not self:IsDirty() then
		return
	end               

	-- local tData = CHDBase.SaveData(self)
	-- tData.m_tTmpRanking = self.m_tTmpRanking
	-- tData.m_tDiffValue = self.m_tDiffValue
	-- tData.m_tAwardState = self.m_tAwardState
	local tData = self:GetSaveData()

	goDBMgr:GetSSDB(gnServerID, "global", GF.GetServiceID()):HSet(gtDBDef.sHuoDongDB, self:GetID(), cjson.encode(tData))
	self:MarkDirty(false)
end

function CCBBase:OpenAct(nBegTime, nEndTime, nAwardTime, nExtID, nExtID1)
	CHDBase.OpenAct(self, nBegTime, nEndTime, nAwardTime, nExtID, nExtID1)
end

--接口,子类实现,取能获得奖励的排名配置
function CCBBase:GetAwardRanking() end
--接口,子类实现,取排名奖励配置
function CCBBase:GetRankingConf() end

--取榜首名字和值
function CCBBase:GetFirstRank()
	local tRank = self.m_tTmpRanking[1] 
	if not tRank then
		return "", 0
	end
	local oRole = goGPlayerMgr:GetRoleByID(tRank[1])
	return oRole:GetName(), tRank[2]
end

--检测奖励状态
function CCBBase:CheckAwardState(nRoleID)
	local nMyRank = self:MyRank(nRoleID)
	local nMinRank, nMaxRank = self:GetAwardRanking()

	self.m_tAwardState[nRoleID] = self.m_tAwardState[nRoleID] or 0
	if self:GetState() == CHDBase.tState.eAward and self.m_tAwardState[nRoleID]==0 and nMyRank>=nMinRank and nMyRank<=nMaxRank then
		self.m_tAwardState[nRoleID] = CHDBase.tAwardState.eFeed
		self:MarkDirty(true)
	end
	return self.m_tAwardState[nRoleID]
end

--奖励列表
function CCBBase:GetRankAward(nRoleID, nRank)
	local tRankingConf = self:GetRankingConf()

	local tList = {}
	for k=#tRankingConf, 1, -1 do 
		local tConf = tRankingConf[k]
		local tRank = tConf.tRanking[1]
		if nRank >= tRank[1] and nRank <= tRank[2] then 
			local tAward
			if self:GetOpenTimes() == 1 then
				tAward = tConf.tAward1  		--首次开启
			else
				tAward = tConf.tAward2			--非首次开启
			end 
			for _, tItem in ipairs(tAward) do 
				table.insert(tList, {tItem[1], tItem[2], tItem[3]})
			end

			if tConf.nExtraAwardLimit and self.m_tDiffValue[nRoleID] >= tConf.nExtraAwardLimit then 
				for _, tItem in ipairs(tConf.tExtraAward) do 
					if tItem[1] > 0 and tItem[2] > 0 and tItem[3] > 0 then 
						table.insert(tList, {tItem[1], tItem[2], tItem[3]})
					end
				end
			end
			break
		end
	end
	return tList
end

--我的排名
function CCBBase:MyRank(nKey)
	if not self.m_tTmpRankingMap[nKey] then
		return 0, 0
	end
	local function fnCmp(t1, t2)
		if t1[2] == t2[2] then
			if t1[1] == t2[1] then return 0 end
			if t1[1] > t2[1] then return 1 end
			return -1
		else
			if t1[2] > t2[2] then return -1 end
			return 1
		end
	end
	local nRank = CBinarySearch:Search(self.m_tTmpRanking, fnCmp, self.m_tTmpRankingMap[nKey])
	local tRank = self.m_tTmpRanking[nRank]
	if tRank then
		return nRank, tRank[2]
	end
	return 0, 0
end

--获取上榜条件值
function CCBBase:GetRankLimitValue()
	return 0
end

--冲榜榜单处理
function CCBBase:ProcessRanking(bEnd)
	if self:GetState() == self.tState.eStart or bEnd then
		local tConf = ctMZCBEtcConf[1]
		if os.time() - self.m_nLastRankTime >= tConf.nRankingUpdateTime or bEnd then --每段时间生产临时排行结果
			self.m_nLastRankTime = os.time()

			self.m_tTmpRanking = {}
			self.m_tTmpRankingMap = {}
			local nRankLimitVal = self:GetRankLimitValue()
			for nKey, nValue in pairs(self.m_tDiffValue) do
				if nValue >= nRankLimitVal then 
					local tRank = {nKey, nValue}
					self.m_tTmpRankingMap[nKey] = tRank 
					table.insert(self.m_tTmpRanking, tRank)
				end
			end

			table.sort(self.m_tTmpRanking, function(t1, t2)
				if t1[2] == t2[2] then
					return t1[1] < t2[1]
				end
				return t1[2] > t2[2]
			end)
			self:MarkDirty(true)
		end
	end
end

--进入活动,子类按需覆盖
function CCBBase:InActivityReq(oRole)
	if self:GetState() == CHDBase.tState.eInit or self:GetState() == CHDBase.tState.eClose then
		return oRole:Tips("活动未开始或已结束")
	end

	self:ProcessRanking()

	local nMyRank, nMyValue = self:MyRank(oRole:GetID())
	local nAwardState = self:CheckAwardState(oRole:GetID())
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
		nMyValue=nMyValue,
		nOpenTimes=self:GetOpenTimes(),
	}
	oRole:SendMsg("CBInActivityRet", tMsg)
	print("InActivityReq***", self:GetName(), tMsg)
end

--冲榜榜单请求,子类按需重写
function CCBBase:RankingReq(oRole, nRankNum)
	if self:GetState() == CHDBase.tState.eInit or self:GetState() == CHDBase.tState.eClose then
		return oRole:Tips("活动已结束")
	end

	self:ProcessRanking() 

	local nMinRank, nMaxRank = self:GetAwardRanking()
	nRankNum = math.max(1, math.min(nMaxRank, nRankNum))
	local nMyRank, nMyValue = self:MyRank(oRole:GetID())

	local tRanking = {}
	for k=1, nRankNum do 
		local tRank = self.m_tTmpRanking[k]
		if tRank then
			local oUnion = goUnionMgr:GetUnionByRoleID(tRank[1])
			local sExtName = oUnion and oUnion:GetName() or ""
			table.insert(tRanking, {nRank=k, sName=goGPlayerMgr:GetRoleByID(tRank[1]):GetName(), nValue=tRank[2], sExtName=sExtName})
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
	print("RankingReq***", self:GetName(), tMsg)
end

--领取奖励请求,子类按需重写
function CCBBase:GetAwardReq(oRole)
	if self:GetState() ~= CHDBase.tState.eAward then
		return oRole:Tips("未到领奖时间")
	end

	local nRoleID = oRole:GetID()
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
	local nMyRank = self:MyRank(oRole:GetID())
	local tAward = self:GetRankAward(nRoleID, nMyRank)
	for _, tItem in ipairs(tAward) do 
		table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
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

--是否能领取奖励,子类按需覆盖
function CCBBase:CanGetAward(oRole)
	if self:GetState() ~= CHDBase.tState.eAward then
		return false
	end
	if self:CheckAwardState(oRole:GetID()) == CHDBase.tAwardState.eFeed then
		return true 
	end
	return false
end

--玩家上线
function CCBBase:Online(oRole)
	goCBMgr:Online(oRole, self:GetID())
end

--更新活动状态
function CCBBase:UpdateState()
	CHDBase.UpdateState(self)
end

--进入初始状态
function CCBBase:OnStateInit()
	print("活动:", self.m_nID, "进入初始状态")
	goCBMgr:OnStateInit()
end

--进入活动状态
function CCBBase:OnStateStart()
	print("活动:", self.m_nID, "进入开始状态")
	self:Init()
	goCBMgr:OnStateStart()
end

--处理称号
function CCBBase:CheckTitle()
	local nRoleID = self.m_tTmpRanking[1]
	local nTitle = gtCBTitle[self:GetID()]
	if nRoleID and nTitle then
		goHallFame:AddTitle(nTitle, nRoleID)
	end
end

--进入领奖状态
function CCBBase:OnStateAward()
	print("活动:", self.m_nID, "进入奖励状态")
	self:ProcessRanking(true) 
	for _, tRank in ipairs(self.m_tTmpRanking) do
		self:CheckAwardState(tRank[1])
	end
	goCBMgr:OnStateAward()
	self:CheckTitle()
end  

--进入关闭状态
function CCBBase:OnStateClose()
	print("活动:", self.m_nID, "进入关闭状态")
	self:CheckCloseAward()
	goCBMgr:OnStateClose()
end

--检测未领奖的玩家,然后发奖
function CCBBase:CheckCloseAward()
	local nMinRank, nMaxRank = self:GetAwardRanking()
	for k = nMinRank, nMaxRank do
		local tRank = self.m_tTmpRanking[k]
		if tRank then
			local nRoleID = tRank[1]
			if self.m_tAwardState[nRoleID] == CHDBase.tAwardState.eFeed then
				self.m_tAwardState[nRoleID] = CHDBase.tAwardState.eClose
				self:MarkDirty(true)

				local oRole = goGPlayerMgr:GetRoleByID(nRoleID)	
				local sCont = string.format("您在%s活动中获得第%d名，获得了以下奖励，请查收。", self:GetName(), k)
				GF.SendMail(oRole:GetServer(), self:GetName().."奖励", sCont, self:GetRankAward(nRoleID, k), nRoleID)
			end
		end
	end
end

function CCBBase:UpdateValue(nRoleID, nDiffValue)
	if nDiffValue == 0 then
		return
	end
	if self:GetState() ~= CHDBase.tState.eStart then
		return
	end
	self.m_tDiffValue[nRoleID] = (self.m_tDiffValue[nRoleID] or 0) + nDiffValue

	--<=0不上榜
	if self.m_tDiffValue[nRoleID] <= 0 then
		self.m_tDiffValue[nRoleID] = nil
	end

	self:MarkDirty(true)
end