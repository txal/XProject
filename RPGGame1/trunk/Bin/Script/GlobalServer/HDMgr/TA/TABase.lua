--限时活动子类基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--排行榜更新时候
local nRankUpdateTime = 3600
--排行榜条目上限
local nMaxRandNum = 100
--最大奖励等级
local nMaxAwardLv = 32

function CTABase:Ctor(oMgr, nID)
	CHDBase.Ctor(self, nID)     	--继承基类
	self.m_oMgr = oMgr
	self:Init()
end

function CTABase:Init()
	self.m_tRoleMap = {} 			--玩家列表:{[charid]=value}
	self.m_tAwardMap = {} 			--领奖请情况:{[charid]={[lv]=state, ...}, ...}

	--不保存	
	self.m_tRanking = {} 			--排行榜(定时更新)
	self.m_nLastRankTime = 0 		--上次排行时间
end

function CTABase:LoadData(tData)
	CHDBase.LoadData(self, tData)
	self.m_tRoleMap = tData.m_tRoleMap
	self.m_tAwardMap = tData.m_tAwardMap
end

function CTABase:SaveData()
	local tData = CHDBase.SaveData(self)
	tData.m_tRoleMap = self.m_tRoleMap
	tData.m_tAwardMap = self.m_tAwardMap
	return tData
end

--取名字
function CTABase:GetName()
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
function CTABase:UpdateVal(nRoleID, nVal)
	if not self:IsOpen() then
		return
	end
	if nVal == 0 then
		return
	end
	if not self.m_tRoleMap[nRoleID] then
		self.m_tRoleMap[nRoleID] = 0
	end
	self.m_tRoleMap[nRoleID] = math.min(gtGDef.tConst.nMaxInteger, self.m_tRoleMap[nRoleID]+nVal)
	self:MarkDirty(true)
	
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if self:CanGetAward(oRole) then
		self.m_oMgr:SyncState(oRole)
	end
end

--检测状态
function CTABase:CheckState(oRole)
	local nState = self:GetState(oRole)
	if nState == CHDBase.tState.eInit or nState == CHDBase.tState.eClose then
		return --oRole:Tips("活动已结束")
	end
	return true
end

--取进度信息
function CTABase:ProgressReq(oRole)
	if not self:CheckState(oRole) then
		return
	end

	local nID = self:GetID()
	local nRoleID = oRole:GetID()
	local nValue = self.m_tRoleMap[nRoleID] or 0
	local tAwardState = self.m_tAwardMap[nRoleID] or {}

	local tMsg = {nID=nID, nValue=nValue, tList={}}
	local tConf = ctTimeAwardConf[nID]
	for k = 1, nMaxAwardLv do
		local nTarValue = tConf["nValue"..k] or 0
		if nTarValue > 0 then
			local nAwardState = tAwardState[k] or 0
			if nAwardState == 0 and nValue >= nTarValue then
				nAwardState = 1
			end
			local tItem = {nAwardID=k, nAwardState=nAwardState}
			table.insert(tMsg.tList, tItem)
		end
	end
	Network.PBSrv2Clt(oRole:GetSession(), "TimeAwardProgressRet", tMsg)
end

--更新排行榜
function CTABase:UpdateRanking(bEnd)
	if os.time() - self.m_nLastRankTime >= nRankUpdateTime or bEnd then
		self.m_tRanking = {}
		self.m_nLastRankTime = os.time()
		for nRoleID, nValue in pairs(self.m_tRoleMap) do
			table.insert(self.m_tRanking, nRoleID)
		end
		table.sort(self.m_tRanking, function(v1, v2)
			local nVal1 = self.m_tRoleMap[v1]
			local nVal2 = self.m_tRoleMap[v2]
			if nVal1 == nVal2 then
				return v1 < v2
			end
			return nVal1 > nVal2
		end)
	end
end

--取我的排名
function CTABase:GetRank(nRoleID)
	local nRank, nValue = 0, 0
	if not self.m_tRoleMap[nRoleID] then
		return nRank, nValue
	end
	local function fnCmp(v1, v2)
		local nVal1 = self.m_tRoleMap[v1]    --值1
		local nVal2 = self.m_tRoleMap[v2]    --值2
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
	nRank = CBinarySearch:Search(self.m_tRanking, fnCmp, nRoleID)
	nValue = self.m_tRoleMap[nRoleID]
	return nRank, nValue
end

--取排行榜信息
function CTABase:RankingReq(oRole, nRankNum)
	if not self:CheckState(oRole) then
		return
	end
	self:UpdateRanking()
	nRankNum = math.max(1, math.min(nRankNum, nMaxRandNum))
	local nRoleID = oRole:GetID()
	local nMyRank, nMyValue = self:GetRank(nRoleID)
	local tMsg = {nID=self:GetID(), nMyRank=nMyRank, nMyValue=nMyValue, tList={}}
	for k = 1, nRankNum do
		local nRoleID = self.m_tRanking[k]
		if not nRoleID then
			break
		end
		local oTmpRole = goGPlayerMgr:GetRoleByID(nRoleID)	
		local tItem = {sName=oTmpRole:GetName(), nValue=self.m_tRoleMap[nRoleID], nRank=k}
		table.insert(tMsg.tList, tItem)
	end
	oRole:SendMsg("TimeAwardRankingRet", tMsg)
end

--领取奖励
function CTABase:AwardReq(oRole, nAwardID)
	if not self:CheckState(oRole) then
		return	
	end
	local nID = self:GetID()
	local nRoleID = oRole:GetID()
	local tConf = ctTimeAwardConf[nID]
	local nTarValue = tConf["nValue"..nAwardID]
	if nTarValue <= 0 then
		return oRole:Tips("参数错误")
	end
	
	local tAwardState = self.m_tAwardMap[nRoleID] or {}
	self.m_tAwardMap[nRoleID] = tAwardState
	if (tAwardState[nAwardID] or 0) == 2 then
		return oRole:Tips("已领取过该奖励")
	end
	if (self.m_tRoleMap[nRoleID] or 0) < nTarValue then
		return oRole:Tips("未满足领奖条件")
	end
	tAwardState[nAwardID] = 2
	self:MarkDirty(true)

	local tAward = nil
	local tItemList = {}
	if self:GetOpenTimes() == 1 then 	--首次开启
		tAward = tConf["tAward1_"..nAwardID]
		for _, tItem in ipairs(tAward) do
			table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
		end
	else 								--非首次开启
		tAward = tConf["tAward2_"..nAwardID]
		for _, tItem in ipairs(tAward) do
			table.insert(tItemList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
		end
	end
	oRole:AddItem(tItemList, "限时活动奖励:"..nID, function(bRet)
		if bRet then
			oRole:SendMsg("TimeAwardAwardRet", {nID=nID, nAwardID=nAwardID, nOpenTimes=self:GetOpenTimes()})
			self:ProgressReq(oRole)
			self.m_oMgr:SyncState(oRole)

			--日志
			local nValue = self.m_tRoleMap[nRoleID] or 0
			goLogger:ActivityLog(oRole, self.m_oMgr:GetID(), self.m_oMgr:GetName(), {}, tAward, nValue, nAwardID, self:GetOpenTimes(), self:GetID(), self:GetName())
		end
	end)
end

--是否能领取奖励
function CTABase:CanGetAward(oRole)
	local nState = self:GetState()
	if nState == CHDBase.tState.eInit or nState == CHDBase.tState.eClose then
		return false
	end
	local nID = self:GetID()
	local tConf = ctTimeAwardConf[nID]
	local nRoleID = oRole:GetID()
	local nValue = self.m_tRoleMap[nRoleID] or 0
	local tAwardState = self.m_tAwardMap[nRoleID] or {}
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
	for nRoleID, nValue in pairs(self.m_tRoleMap) do
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole and nValue > 0 then
			self.m_tAwardMap[nRoleID] = self.m_tAwardMap[nRoleID]  or {}
			local tAwardMap = self.m_tAwardMap[nRoleID]

			for k = 1, nMaxAwardLv do
				local nTarValue = tConf["nValue"..k] or 0
				if nTarValue > 0 then
					local nAwardState = tAwardMap[k] or 0
					if nAwardState == 0 and nValue >= nTarValue then
						tAwardMap[k] = 2
						self:MarkDirty(true)
						
						local tList
						if nOpenTimes == 1 then --首次开启
							tList = table.DeepCopy(tConf["tAward1_"..k])
						else --非首次
							tList = table.DeepCopy(tConf["tAward2_"..k])
						end
						local sCont = string.format("您在%s活动中获得了以下奖励，请查收。", self:GetName())
						CUtil:SendMail(oRole:GetServer(), "限时奖励活动奖励", sCont, tList, nRoleID)
					end
				end
			end
		end
	end
end
