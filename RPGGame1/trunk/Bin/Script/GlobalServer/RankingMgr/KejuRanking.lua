--科举排行榜
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--比较函数
local function _fnDescSort(t1, t2)
	if t1[1] == t2[1] then
		return 0
	end
	if t1[1] > t2[1] then
		return 1
	end
	return -1
end

local function _fnDescSort2(t1,t2)
	if t1[1] ~= t2[1] then
		if t1[1] > t2[1] then
			return 1
		else
			return -1
		end
	else
		if t1[2] < t2[2] then
			return 1
		elseif t1[2] == t2[2] then
			return 0
		else
			return -1
		end
	end
	return 1
end

function CKejuRanking:Ctor(nID)
	self.m_nID = nID --排行榜ID
	self.m_tDirtyMap = {} 
	self.m_oRanking = CSkipList:new(_fnDescSort) --{nRoleID={nValue}, ...}					--乡试排行

	local nTimeStamp = os.WeekDayTime(os.time(),6,0) + 19 * 3600 + 60 * 50 -os.time()		--7点50结束，发奖励
	self.m_nRewardTick = GetGModule("TimerMgr"):Interval(nTimeStamp, function() self:RankReward() end)
	self.m_tTop100 = {}

	self.m_oTempleRanking = CSkipList:new(_fnDescSort2)
	local nTempleTimeStamp = os.WeekDayTime(os.time(),7,0)-os.time()						--周日0点结束，结算殿试
	self.m_nTempleRewardTick = GetGModule("TimerMgr"):Interval(nTempleTimeStamp,function () self:TempleRankReward() end)
end

function CKejuRanking:LoadData()
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())

	local tKeys = oSSDB:HKeys(gtDBDef.sKejuRankingDB)
	print("加载科举排行榜:", #tKeys)
	for _, sCharID in ipairs(tKeys) do
		local nRoleID = tonumber(sCharID)
		local sData = oSSDB:HGet(gtDBDef.sKejuRankingDB, nRoleID)
		local tData = cseri.decode(sData)
		if tData[1] then
			self.m_oRanking:Insert(nRoleID, tData)
		end
	end
end

function CKejuRanking:SaveData()
	for nRoleID, v in pairs(self.m_tDirtyMap) do
		local tData = self.m_oRanking:GetDataByKey(nRoleID)
		if tData then
			local tRealData = {tData[1]} --主意要转成数组
			goDBMgr:GetGameDB(gnServerID, "global",CUtil:GetServiceID()):HSet(gtDBDef.sKejuRankingDB, nRoleID, cseri.encode(tRealData))
		end
	end
	self.m_tDirtyMap = {}
end

function CKejuRanking:Release()
	GetGModule("TimerMgr"):Clear(self.m_nRewardTick)
	GetGModule("TimerMgr"):Clear(self.m_nTempleRewardTick)
	self:SaveData()
end

--排行奖励
function CKejuRanking:RankReward()
	GetGModule("TimerMgr"):Clear(self.m_nRewardTick)
	self.m_nRewardTick = nil

	--前nRankNum名玩家
	local tRanking = {}
	local function _fnTraverse(nRank, nRoleID, tData)
		tRanking[nRank] = {nRoleID = nRoleID,nValue = tData[1],nLevel=tData[2],sName = tData[3]}
	end
	self.m_oRanking:Traverse(1, 3, _fnTraverse)
	for nRank,tData in pairs(tRanking) do
		local sMailContent = "恭喜你，因为你在上周的科举乡试中排名进入前三，获得了特殊称谓奖励：“天子门生”。该称谓有效期一周。"
		local nRoleID = tData["nRoleID"]
		goMailMgr:SendMail("科举乡试", sMailContent,{}, nRoleID)

		local nAppeID = 6
		local tParam = {}
		local nNowTime = os.time()
		tParam.nExpiryTime = nNowTime + 7 * 24 * 3600

		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole then
			oRole:AddAppellation(nAppeID,tParam, 0)
			goLogger:EventLog(gtEvent.eKeJuRank,oRole,nRank)
		end
	end

	self.m_tTop100 = {}
	local function _fnTraverse(nRank, nRoleID, tData)
		self.m_tTop100[nRoleID] = nRank
	end
	self.m_oRanking:Traverse(1, 100, _fnTraverse)

	local tLogic = {}
	local tLogicOffline = {}
	for nRoleID,nRank in pairs(self.m_tTop100) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole then
			local nLogic = oRole:GetLogic()
			if not tLogic[nLogic] then
				tLogic[nLogic] = {}
			end
			tLogic[nLogic][nRoleID] = nRank
		else
			tLogicOffline[nRoleID] = nRank
		end
	end
	for nLogic,tJoinPlayer in pairs(tLogic) do
		Network:RMCall("JoinKejuDianshi", nil,gnServerID,nLogic,0,tJoinPlayer)
	end
end

function CKejuRanking:CanJoinKeju(nRoleID)
	if self.m_tTop100[nRoleID] then
		return true
	end
	return false
end


function CKejuRanking:TempleRankReward()
	GetGModule("TimerMgr"):Clear(self.m_nTempleRewardTick)
	self.m_nTempleRewardTick = nil
	self.m_tTop100 = {}

	--前nRankNum名玩家
	local tRanking = {}
	local function _fnTraverse(nRank, nRoleID, tData)
		tRanking[nRank] = {nRoleID = nRoleID,nValue = tData[1],nLevel=tData[2],sName = tData[3]}
	end
	self.m_oTempleRanking:Traverse(1,3,_fnTraverse)
	for nRank,tData in pairs(tRanking) do
		local sMailContent
		local nAppeID
		if nRank == 1 then
			sMailContent = "恭喜你，因为你在本周的御前殿试中排名第1，获得了特殊称谓奖励：“御前状元”。该称谓有效期一周。"
			nAppeID = 3
		elseif nRank == 2 then
			sMailContent = "恭喜你，因为你在本周的御前殿试中排名第2，获得了特殊称谓奖励：“御前榜眼”。该称谓有效期一周。"
			nAppeID = 4
		elseif nRank == 3 then
			sMailContent = "恭喜你，因为你在本周的御前殿试中排名第3，获得了特殊称谓奖励：“御前探花”。该称谓有效期一周。"
			nAppeID = 5
		end
		local nRoleID = tData.nRoleID
		goMailMgr:SendMail("科举殿试", sMailContent,{}, nRoleID)
		if nAppeID then
			local tParam = {}
			local nNowTime = os.time()
			tParam.nExpiryTime = nNowTime + 7 * 24 * 3600
			local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
			if oRole then
				oRole:AddAppellation(nAppeID,tParam, 0)
			end
		end
	end
end

--重置清理数据库
function CKejuRanking:ResetRanking()
	goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID()):HClear(gtDBDef.sKejuRankingDB)
	self.m_oRanking = CSkipList:new(_fnDescSort)
	self.m_tDirtyMap = {}
end

function CKejuRanking:ResetTempleRanking()
	self.m_oTempleRanking = CSkipList:new(_fnDescSort2)
end

--设置脏数据
function CKejuRanking:MarkDirty(nRoleID, bDirty)  
	bDirty = bDirty and true or nil
	self.m_tDirtyMap[nRoleID] = bDirty
end

--更新数据
function CKejuRanking:Update(nRoleID, tData)
	print("更新数据科举排行", nRoleID, tData)
	local nValue = tData[1]
	local tOldData = self.m_oRanking:GetDataByKey(nRoleID)
	if tOldData then
		if tOldData[1]	== nValue then return end
		self.m_oRanking:Remove(nRoleID)
	end
	self.m_oRanking:Insert(nRoleID, tData)
	self:MarkDirty(nRoleID, true)
end

--更新殿试数据
function CKejuRanking:UpdateTemple(nRoleID,tData)
	print("更新数据科举殿试排行", nRoleID, tData)
	local nValue = tData[1]
	local tOldData = self.m_oTempleRanking:GetDataByKey(nRoleID)
	if tOldData then
		if tData[1] == tOldData[1] and tData[2] == tOldData[2] then return end
		self.m_oTempleRanking:Remove(nRoleID)
	end
	self.m_oTempleRanking:Insert(nRoleID, tData)
	self:MarkDirty(nRoleID, true)
end

--取某个玩家排名
function CKejuRanking:GetPlayerRank(nRoleID)
	local nRank = self.m_oRanking:GetRankByKey(nRoleID)
	return nRank
end

--取某个玩家的值
function CKejuRanking:GetPlayerValue(nRoleID)
	local tData = self.m_oRanking:GetDataByKey(nRoleID)
	return (tData and tData[1] or 0)
end

function CKejuRanking:GetPlayerData(nRoleID)
	local tData = self.m_oRanking:GetDataByKey(nRoleID)
	return tData
end

--排行榜请求
function CKejuRanking:RankingReq(oRole, nRankNum)
	print("KejuRankingReq***")

	local nRoleID = oRole:GetID()
	nRankNum = math.max(1, math.min(CRankingBase.nMaxViewNum, nRankNum))

	--我的排名
	local nMyRank = self:GetPlayerRank(nRoleID)
	local tMyData = self.m_oRanking:GetDataByKey(nRoleID)
	local nMyValue = tMyData and tMyData[1] or 0

	--前nRankNum名玩家
	local tRanking = {}
	local function _fnTraverse(nRank, nCharID, tData)
		local oRole = goGPlayerMgr:GetRoleByID(nCharID)
		local nLevel, sName = 1, ""
		if oRole then 
			nLevel = oRole:GetLevel()
			sName = oRole:GetName()
		end
		local tRank = {nRank=nRank, nValue=tData[1], sName=sName, nLevel=nLevel}
		table.insert(tRanking, tRank)
	end
	self.m_oRanking:Traverse(1, nRankNum, _fnTraverse)

	local tMsg = {
		tRanking = tRanking,
		nMyRank = nMyRank,
		sMyName = oRole:GetName(),
		nMyValue = nMyValue,
	}
	print("KejuRankingReq***", tMsg)
	return tMsg
end