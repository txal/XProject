--宫斗排行榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--比较函数
local function _fnDescSort(t1, t2)
	if t1[2] == t2[2] then
		return 0
	end
	if t1[2] > t2[2] then
		return -1
	end
	return 1
end

local nAwardHour = 0 --周排行奖励结算时间(0点)
local nMaxAwardNum = 300 --排行奖励数量

function CGDRanking:Ctor(nID)
	self.m_nID = nID
	self.m_tDirtyMap = {} 
	self.m_oRanking = CSkipList:new(_fnDescSort) --{[nCharID]={sName,nValue}, ...}
	self.m_tGDValueMap = {} 	--宫斗映射{[nCharID]=nValue, ...}

	self.m_tLastWeekGD = {} 	--上周宫斗值
	self.m_tLastWeekRank = {} 	--上周排名(最多300名)
	self.m_nLastUpdateTime = os.time()
end

function CGDRanking:LoadData()
	--排行榜
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sGDRankingDB)
	print("加载宫斗排行榜:", #tKeys)
	for _, sCharID in ipairs(tKeys) do
		local nCharID = tonumber(sCharID)
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sGDRankingDB, nCharID)
		local tData = cjson.decode(sData)
		if tData[1] and tData[2] then
			self.m_oRanking:Insert(nCharID, tData)
		end
	end

	--排行奖励和上周宫斗
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sGDWeekAwardDB, "data")
	local tData = sData ~= "" and cjson.decode(sData) or {}
	self.m_tLastWeekRank = tData.m_tLastWeekRank or {}
	self.m_nLastUpdateTime = tData.m_nLastUpdateTime or os.time()
	self.m_tLastWeekGD = tData.m_tLastWeekGD or {}
	self.m_tGDValueMap = tData.m_tGDValueMap or {}
end

function CGDRanking:SaveData()
	if next(self.m_tDirtyMap) then
		--排行榜
		for nCharID, v in pairs(self.m_tDirtyMap) do
			local tData = self.m_oRanking:GetDataByKey(nCharID)
			if tData then
				local tRealData = {tData[1], tData[2]} --主意要转成数组
				goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sGDRankingDB, nCharID, cjson.encode(tRealData))
			end
		end
		self.m_tDirtyMap = {}

		--排行奖励和上周宫斗
		local tData = {}
		tData.m_tLastWeekRank = self.m_tLastWeekRank
		tData.m_nLastUpdateTime = self.m_nLastUpdateTime
		tData.m_tLastWeekGD = self.m_tLastWeekGD
		tData.m_tGDValueMap = self.m_tGDValueMap
		goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sGDWeekAwardDB, "data", cjson.encode(tData))
	end
end

function CGDRanking:OnRelease()
	self:SaveData()
end

--设置脏数据
function CGDRanking:MarkDirty(nCharID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nCharID] = bDirty
end

--更新数据
function CGDRanking:Update(nCharID, nValue)
	if nValue == 0 then return end

	--检测周排行
	self:CheckWeekAward()

	local nAddVal = nValue - (self.m_tLastWeekGD[nCharID] or 0)
	local nDiffVal = nValue - (self.m_tGDValueMap[nCharID] or 0)
	if nDiffVal ~= 0 then self.m_tGDValueMap[nCharID] = nValue end

	--更新排行榜
	local tData = self.m_oRanking:GetDataByKey(nCharID)
	if tData then
		if tData[2]	~= nAddVal then 
			self.m_oRanking:Remove(nCharID)
			tData[2] = nAddVal
			self.m_oRanking:Insert(nCharID, tData)
		end
	else
		tData = {"", nAddVal}
		self.m_oRanking:Insert(nCharID, tData)
	end
	self:MarkDirty(nCharID, true)

	if self:GetPlayerRank(nCharID) == 1 then 
	 	goBroadcast:SetBroadcast(60, 1, nCharID)
	end

	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(nCharID, gtTAType.eGD, nDiffVal)
    --日志
    local oOfflinePlayer= goOfflineDataMgr:GetPlayer(nCharID)
    goLogger:RankingLog(oOfflinePlayer, self.m_nID, nValue, oOfflinePlayer:GetRecharge())
end

--检测周排行奖励
function CGDRanking:CheckWeekAward()
	local nNowSec = os.time()
	if not os.IsSameWeek(self.m_nLastUpdateTime, nNowSec, nAwardHour*3600) then
		self.m_nLastUpdateTime = nNowSec
		self:DoWeekAward()
		self:MarkDirty(0, true)
	end
end

--周排行奖励
function CGDRanking:DoWeekAward()
	LuaTrace("CGDRanking:DoWeekAward***")
	--记录当前宫斗 和 发放奖励
	local tLastWeekRank = {}
	local function _fnTraverse(nRank, nCharID, tData)
		if nRank <= nMaxAwardNum then
			local tAward
			for _, tConf in pairs(ctChuXunAwardConf) do
				local tRanking = tConf.tRanking[1]
				if nRank >= tRanking[1] and nRank <= tRanking[2] then
					tAward = tConf.tAward
					break
				end
			end
			if #tAward > 0 and tAward[1][1] > 0 then
				goMailMgr:SendMail("大学士", "浩荡出巡排名奖励", "您上周的宫斗积分排名为第"..nRank.."名，获得以下奖励。",
					table.DeepCopy(tAward), nCharID)
			end
			table.insert(tLastWeekRank, {nRank=nRank, sName=goOfflineDataMgr:GetName(nCharID), nValue=tData[2]})
		end
		self.m_tLastWeekGD[nCharID] = (self.m_tGDValueMap[nCharID] or 0)
	end
	local nTotal = self.m_oRanking:GetCount()
	self.m_oRanking:Traverse(1, nTotal, _fnTraverse)

	self.m_tLastWeekRank = tLastWeekRank
	self:ResetRanking()
	self:MarkDirty(0, true)
	goLogger:EventLog(gtEvent.eGDWeekAward, nil, "出巡周排行奖励发放")
end

--取某个玩家排名
function CGDRanking:GetPlayerRank(nCharID)
	local nRank = self.m_oRanking:GetRankByKey(nCharID)
	return nRank
end

--取玩家宫斗表
function CGDRanking:GetPlayerGDMap()
	return self.m_tGDValueMap
end

--取某个玩家宫斗
function CGDRanking:GetPlayerGD(nCharID)
	return (self.m_tGDValueMap[nCharID] or 0)
end

--重置清理数据库
function CGDRanking:ResetRanking()
	goDBMgr:GetSSDB("Player"):HClear(gtDBDef.sGDRankingDB)
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

--排行榜请求(0总排行;1本周排行;2上周排行)
function CGDRanking:GDRankingReq(oPlayer, nRankNum, nType)
	self:CheckWeekAward() --检测周排行奖励

	local tMsg
	if nType == 2 then --上周排行
		tMsg = {nType=nType, tRanking=self.m_tLastWeekRank}

	else --总排行/本周排行
		local nCharID = oPlayer:GetCharID()
		nRankNum = math.max(1, math.min(nMaxAwardNum, nRankNum))

		--我的排名
		local nMyRank = self:GetPlayerRank(nCharID)
		local tMyData = self.m_oRanking:GetDataByKey(nCharID)
		local nMyValue = tMyData and tMyData[2] or 0

		--前nRankNum名玩家
		local tRanking = {}
		local function _fnTraverse(nRank, nCharID, tData)
			local tRank = {nRank=nRank, sName=goOfflineDataMgr:GetName(nCharID), nValue=tData[2]}
			table.insert(tRanking, tRank)
		end
		self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)
		tMsg = {
			nType = nType,
			tRanking = tRanking,
			nMyRank = nMyRank,
			nMyValue = nMyValue,
			sMyName = oPlayer:GetName(),
			nAwardTime = os.WeekDayTime(os.time(), 1, nAwardHour*3600) - os.time(),
		}
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "GDRankingRet", tMsg)
	print("CGDRanking:GDRankingReq***", nRankNum, nType, #tMsg.tRanking)
end
