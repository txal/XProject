--威望排行榜(宫斗)
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

local nAwardHour = 5 --周排行奖励结算时间(5点)
local nMaxAwardNum = 300 --排行奖励数量

function CWWRanking:Ctor(nID)
	self.m_nID = nID
	self.m_tDirtyMap = {} 
	self.m_oRanking = CSkipList:new(_fnDescSort) --{[nCharID]={sName,nValue}, ...}
	self.m_tWWValueMap = {} 	--威望映射{[nCharID]=nValue, ...}

	self.m_tLastWeekWW = {} 	--上周威望值
	self.m_tLastWeekRank = {} 	--上周排名(最多300名)
	self.m_nLastUpdateTime = os.time()
end

function CWWRanking:LoadData()
	--排行榜
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sWWRankingDB)
	print("加载威望排行榜:", #tKeys)
	for _, sCharID in ipairs(tKeys) do
		local nCharID = tonumber(sCharID)
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sWWRankingDB, nCharID)
		local tData = cjson.decode(sData)
		if tData[1] and tData[2] then
			self.m_oRanking:Insert(nCharID, tData)
		end
	end

	--排行奖励和上周威望
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sWWWeekAwardDB, "weekaward")
	local tData = sData ~= "" and cjson.decode(sData) or {}
	self.m_tLastWeekRank = tData.m_tLastWeekRank or {}
	self.m_nLastUpdateTime = tData.m_nLastUpdateTime or os.time()
	self.m_tLastWeekWW = tData.m_tLastWeekWW or {}
	self.m_tWWValueMap = tData.m_tWWValueMap or {}
end

function CWWRanking:SaveData()
	if next(self.m_tDirtyMap) then
		--排行榜
		for nCharID, v in pairs(self.m_tDirtyMap) do
			local tData = self.m_oRanking:GetDataByKey(nCharID)
			if tData then
				local tRealData = {tData[1], tData[2]} --主意要转成数组
				goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sWWRankingDB, nCharID, cjson.encode(tRealData))
			end
		end
		self.m_tDirtyMap = {}

		--排行奖励和上周威望
		local tData = {}
		tData.m_tLastWeekRank = self.m_tLastWeekRank
		tData.m_nLastUpdateTime = self.m_nLastUpdateTime
		tData.m_tLastWeekWW = self.m_tLastWeekWW
		tData.m_tWWValueMap = self.m_tWWValueMap
		goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sWWWeekAwardDB, "weekaward", cjson.encode(tData))
	end
end

function CWWRanking:OnRelease()
	self:SaveData()
end

--设置脏数据
function CWWRanking:MarkDirty(nCharID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyMap[nCharID] = bDirty
end

--更新数据
function CWWRanking:Update(nCharID, nValue)
	print("CWWRanking:Update***", nCharID, nValue)
	if nValue == 0 then
		return
	end

	--检测周排行
	self:CheckWeekAward()

	local nAddVal = nValue - (self.m_tLastWeekWW[nCharID] or 0)
	local nDiffVal = nValue - (self.m_tWWValueMap[nCharID] or 0)
	if nDiffVal ~= 0 then self.m_tWWValueMap[nCharID] = nValue end

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
	 	goBroadcast:SetBroadcast(37, 1, nCharID)
	end

	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(nCharID, gtTAType.eWW, nDiffVal)
    --日志
    local oOfflinePlayer= goOfflineDataMgr:GetPlayer(nCharID)
    goLogger:RankingLog(oOfflinePlayer, self.m_nID, nValue, oOfflinePlayer:GetRecharge())
end

--检测周排行奖励
function CWWRanking:CheckWeekAward()
	local nNowSec = os.time()
	if not os.IsSameWeek(self.m_nLastUpdateTime, nNowSec, nAwardHour*3600) then
		self.m_nLastUpdateTime = nNowSec
		self:DoWeekAward()
		self:MarkDirty(0, true)
	end
end

--周排行奖励
function CWWRanking:DoWeekAward()
	LuaTrace("CWWRanking:DoWeekAward***")
	--记录当前威望 和 发放奖励
	local tLastWeekRank = {}
	local function _fnTraverse(nRank, nCharID, tData)
		if nRank <= nMaxAwardNum then
			local tAward
			for _, tConf in pairs(ctJunJiChuAwardConf) do
				local tRange = tConf.tRange[1]
				if nRank >= tRange[1] and nRank <= tRange[2] then
					tAward = tConf.tAward
					break
				end
			end
			if #tAward > 0 and tAward[1][1] > 0 then
				goMailMgr:SendMail("系统邮件", "宫斗积分周排行奖励", "您在上周的宫斗积分排行中获得第"..nRank.."名，获得了以下奖励，请查收。",
					table.DeepCopy(tAward), nCharID)
			end
			table.insert(tLastWeekRank, {nRank=nRank, sName=goOfflineDataMgr:GetName(nCharID), nValue=tData[2]})
		end
		self.m_tLastWeekWW[nCharID] = (self.m_tWWValueMap[nCharID] or 0)
	end
	local nTotal = self.m_oRanking:GetCount()
	self.m_oRanking:Traverse(1, nTotal, _fnTraverse)

	self.m_tLastWeekRank = tLastWeekRank
	self:MarkDirty(0, true)

	self:ResetRanking()
	goLogger:EventLog(gtEvent.eWWWeekAward, nil, "宫斗积分周排行奖励发放")
end

--取某个玩家排名
function CWWRanking:GetPlayerRank(nCharID)
	local nRank = self.m_oRanking:GetRankByKey(nCharID)
	return nRank
end

--取某玩家威望表
function CWWRanking:GetPlayerWWMap()
	return self.m_tWWValueMap
end

--取某个玩家威望
function CWWRanking:GetPlayerWW(nCharID)
	return (self.m_tWWValueMap[nCharID] or 0)
end

--重置清理数据库
function CWWRanking:ResetRanking()
	goDBMgr:GetSSDB("Player"):HClear(gtDBDef.sWWRankingDB)
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

--排行榜请求(0总排行;1本周排行;2上周排行)
function CWWRanking:WWRankingReq(oPlayer, nRankNum, nType)
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
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "WWRankingRet", tMsg)
	print("CWWRanking:WWRankingReq***", nRankNum, nType, #tMsg.tRanking)
end
