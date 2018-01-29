--限时活动子类基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--排行榜更新时候
local nRankUpdateTime = 3600
--排行榜条目上限
local nMaxRandNum = 200
--最大奖励等级
local nMaxAwardLv = 32

function CTABase:Ctor(oMgr, nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_oMgr = oMgr
	self:Init()
end

function CTABase:Init()
	self.m_tPlayerMap = {} 			--玩家列表:{[charid]=value}
	self.m_tAwardMap = {} 			--领奖请情况:{[charid]={[lv]=state, ...}, ...}

	--不保存	
	self.m_tRanking = {} 			--排行榜(定时更新)
	self.m_nLastRankTime = 0 		--上次排行时间
end

function CTABase:LoadData(tData)
	CHDBase.LoadData(self, tData)
	self.m_tPlayerMap = tData.m_tPlayerMap
	self.m_tAwardMap = tData.m_tAwardMap
end

function CTABase:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = CHDBase.SaveData(self)
	tData.m_tPlayerMap = self.m_tPlayerMap
	tData.m_tAwardMap = self.m_tAwardMap
	return tData
end

--取名字
function CTABase:GetActName()
	local tConf = ctTimeAwardConf[self:GetID()]
	return tConf.sName
end

--进入初始状态
function CTABase:OnStateInit()
	LuaTrace("限时奖励子活动:", self.m_nID, "进入初始状态")
	self.m_oMgr:SyncState()
end

--进入活动状态
function CTABase:OnStateStart()
	LuaTrace("限时奖励子活动:", self.m_nID, "进入开始状态")
	self:Init() --初始化
	self:MarkDirty(true)
	self.m_oMgr:SyncState()
end

--进入领奖状态
function CTABase:OnStateAward()
	LuaTrace("限时奖励子活动:", self.m_nID, "进入奖励状态")
	self:UpdateRanking(true)
	self.m_oMgr:SyncState()
end

--进入关闭状态
function CTABase:OnStateClose()
	LuaTrace("限时奖励子活动:", self.m_nID, "进入关闭状态")
	self.m_oMgr:SyncState()
	self:CheckAward()
end

--更新记录
function CTABase:UpdateVal(nCharID, nVal)
	if not self:IsOpen() then
		return
	end
	if nVal == 0 then
		return
	end
	if not self.m_tPlayerMap[nCharID] then
		self.m_tPlayerMap[nCharID] = 0
	end
	self.m_tPlayerMap[nCharID] = math.min(nMAX_INTEGER, self.m_tPlayerMap[nCharID]+nVal)
	self:MarkDirty(true)
	--小红点
	self:CheckRedPoint(nCharID)
end

--检测状态
function CTABase:CheckState(oPlayer)
	local nState = self:GetState(oPlayer)
	if nState == CHDBase.tState.eInit or nState == CHDBase.tState.eClose then
		return oPlayer:Tips("活动已结束")
	end
	return true
end

--取进度信息
function CTABase:ProgressReq(oPlayer)
	if not self:CheckState(oPlayer) then
		return
	end

	local nID = self:GetID()
	print("CTABase:ProgressReq***", nID)
	local nCharID = oPlayer:GetCharID()
	local nValue = self.m_tPlayerMap[nCharID] or 0
	local tAwardState = self.m_tAwardMap[nCharID] or {}

	local tMsg = {nID=nID, nValue=nValue, tList={}}
	local tConf = ctTimeAwardConf[nID]
	for k = 1, nMaxAwardLv do
		local nTarValue = tConf["nValue"..k] or 0
		if nTarValue > 0 then
			local nAwardID = k
			local nAwardState = tAwardState[k] or 0
			if nAwardState == 0 and nValue >= nTarValue then
				nAwardState = 1
			end
			local tItem = {nAwardID=nAwardID, nAwardState=nAwardState}
			table.insert(tMsg.tList, tItem)
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeAwardProgressRet", tMsg)
end

--更新排行榜
function CTABase:UpdateRanking(bEnd)
	if os.time() - self.m_nLastRankTime >= nRankUpdateTime or bEnd then
		self.m_nLastRankTime = os.time()
		self.m_tRanking = {}
		for nCharID, nValue in pairs(self.m_tPlayerMap) do
			table.insert(self.m_tRanking, nCharID)
		end
		table.sort(self.m_tRanking, function(v1, v2)
			local nVal1 = self.m_tPlayerMap[v1]
			local nVal2 = self.m_tPlayerMap[v2]
			if nVal1 == nVal2 then
				return v1 < v2
			end
			return nVal1 > nVal2
		end)
	end
end

--取我的排名
function CTABase:GetRank(nCharID)
	local nRank, nValue = 0, 0
	if not self.m_tPlayerMap[nCharID] then
		return nRank, nValue
	end
	local function fnCmp(v1, v2)
		local nVal1 = self.m_tPlayerMap[v1]    --值1
		local nVal2 = self.m_tPlayerMap[v2]    --值2
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
	nRank = CAlg:BinarySearch(self.m_tRanking, fnCmp, nCharID)
	nValue = self.m_tPlayerMap[nCharID]
	return nRank, nValue
end

--取排行榜信息
function CTABase:RankingReq(oPlayer, nRankNum)
	if not self:CheckState(oPlayer) then
		return
	end
	self:UpdateRanking()
	nRankNum = math.max(1, math.min(nRankNum, nMaxRandNum))
	local nCharID = oPlayer:GetCharID()
	local nMyRank, nMyValue = self:GetRank(nCharID)
	local tMsg = {nID=self:GetID(), nMyRank=nMyRank, nMyValue=nMyValue, tList={}}
	for k = 1, nRankNum do
		local nCharID = self.m_tRanking[k]
		if not nCharID then
			break
		end
		local tItem = {sName=goOfflineDataMgr:GetName(nCharID), nValue=self.m_tPlayerMap[nCharID], nRank=k}
		table.insert(tMsg.tList, tItem)
	end
	print("CTABase:RankingReq***", tMsg)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeAwardRankingRet", tMsg)
end

--领取奖励
function CTABase:AwardReq(oPlayer, nAwardID)
	if not self:CheckState(oPlayer) then
		return	
	end
	local nID = self:GetID()
	local nCharID = oPlayer:GetCharID()
	local tConf = ctTimeAwardConf[nID]
	local nTarValue = tConf["nValue"..nAwardID]
	if nTarValue <= 0 then
		return oPlayer:Tips("参数错误")
	end
	local tAwardState = self.m_tAwardMap[nCharID] or {}
	if (tAwardState[nAwardID] or 0) == 2 then
		return oPlayer:Tips("已领取过该奖励")
	end
	if (self.m_tPlayerMap[nCharID] or 0) < nTarValue then
		return oPlayer:Tips("未满足领奖条件")
	end
	tAwardState[nAwardID] = 2
	self.m_tAwardMap[nCharID] = tAwardState
	self:MarkDirty(true)

	if self:GetOpenTimes() > 1 then 	--普通开启
		for _, tItem in ipairs(tConf["tAward1_"..nAwardID]) do
			oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "消耗银两限时活动奖励")
		end
	else 								--首次开启
		for _, tItem in ipairs(tConf["tAward"..nAwardID]) do
			oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "消耗银两限时活动奖励")
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TimeAwardAwardRet", {nID=nID, nAwardID=nAwardID, nOpenTimes=self:GetOpenTimes()})
	self:ProgressReq(oPlayer)
	--小红点
	self:CheckRedPoint(nCharID)

	--电视
	if nAwardID >= 5 then
		local sNotice = string.format(ctLang[2], oPlayer:GetName(), self:GetActName())
		goTV:_TVSend(sNotice)
	end
end

--是否能领取奖励
function CTABase:CanGetAward(oPlayer)
	local nState = self:GetState()
	if nState == CHDBase.tState.eInit or nState == CHDBase.tState.eClose then
		return false
	end
	local nID = self:GetID()
	local tConf = ctTimeAwardConf[nID]
	local nCharID = oPlayer:GetCharID()
	local nValue = self.m_tPlayerMap[nCharID] or 0
	local tAwardState = self.m_tAwardMap[nCharID] or {}
	for k = 1, nMaxAwardLv do
		local nTarValue = tConf["nValue"..k] or 0
		if nTarValue > 0 then
			local nAwardState = tAwardState[k] or 0
			if nAwardState == 0 and nValue >= nTarValue then
				return true
			end
		end
	end
	return false
end

--检测活动借宿发奖
function CTABase:CheckAward()
	local nID = self:GetID()
	local tConf = ctTimeAwardConf[nID]
	local nOpenTimes = self:GetOpenTimes()
	for nCharID, nValue in pairs(self.m_tPlayerMap) do
		if nValue > 0 then
			self.m_tAwardMap[nCharID] = self.m_tAwardMap[nCharID]  or {}
			local tAwardMap = self.m_tAwardMap[nCharID]

			for k = 1, nMaxAwardLv do
				local nTarValue = tConf["nValue"..k] or 0
				if nTarValue > 0 then
					local nAwardState = tAwardMap[k] or 0
					if nAwardState == 0 and nValue >= nTarValue then
						tAwardMap[k] = 2
						self:MarkDirty(true)
						
						local tList
						if nOpenTimes > 1 then 	--普通开启
							tList = table.DeepCopy(tConf["tAward1_"..k])
						else --首次开启
							tList = table.DeepCopy(tConf["tAward"..k])
						end
						goMailMgr:SendMail("系统邮件", "限时奖励活动奖励"
							, string.format("您在%s活动中获得了以下奖励，请查收。", self:GetActName()), tList, nCharID)
					end
				end
			end
		end
	end
end

--小红点处理
function CTABase:CheckRedPoint(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oPlayer then
		return
	end
	self.m_oMgr:SyncState(oPlayer)
end
