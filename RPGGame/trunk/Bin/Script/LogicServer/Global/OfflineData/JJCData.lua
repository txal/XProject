local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--军机处全局数据
local nBucketGranularity = 10 	--粒度

function CJJCData:Ctor(oParent)
	self.m_oParent = oParent
	self.m_bDirty = false

	self.m_tMCGroupMap = {}
	self.m_tMCGroupMark = {}
	self.m_tWeiWangBucket = {} 	--威望BUCKET(粒度10)
	self.m_nMaxBucket = 0  		--BUCKET数量

	self.m_nNoticeID = 0		--公告ID
	self.m_tJJCNoticeMap = {} 	--公告榜
	self.m_tTongJiMap = {} 		--通缉榜:{[charid]={sCharName="",nTJTimes=0,nWWRank=0,nGuoLi=0,nTime=0,nLostWW=0}}
end

function CJJCData:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sOfflineJJCDB, "data")
	if sData == "" then return end
	local tData = cjson.decode(sData)

	--军机处使节团数据
	self.m_tMCGroupMap = tData.m_tMCGroupMap
	--军机处使节团标记
	for nCharID, v in pairs(tData.m_tMCGroupMark) do
		if nCharID >= gnBaseCharID then --过滤调机器人 
			self.m_tMCGroupMark[nCharID] = v
		end
	end

	--玩家威望BUCKET
	self.m_nMaxBucket = tData.m_nMaxBucket or 0
	for nBucket, tMap in pairs(tData.m_tWeiWangBucket or {}) do
		self.m_tWeiWangBucket[nBucket] = self.m_tWeiWangBucket[nBucket] or {}
		for nCharID, nWeiWang in pairs(tMap) do
			if nCharID >= gnBaseCharID then --过滤调机器人
				self.m_tWeiWangBucket[nBucket][nCharID] = nWeiWang
			end
		end
	end

	--军机处公告
	self.m_nNoticeID = tData.m_nNoticeID or 0
	self.m_tJJCNoticeMap = tData.m_tJJCNoticeMap

	--军机处通缉榜
	self.m_tTongJiMap = tData.m_tTongJiMap

	--加载完成
	self:OnLoaded()
end

--加载完成
function CJJCData:OnLoaded()
	self:InitRobot()
end

function CJJCData:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tMCGroupMap = self.m_tMCGroupMap
	tData.m_tMCGroupMark = self.m_tMCGroupMark

	tData.m_tWeiWangBucket = self.m_tWeiWangBucket
	tData.m_nMaxBucket = self.m_nMaxBucket

	tData.m_nNoticeID = self.m_nNoticeID
	tData.m_tJJCNoticeMap = self.m_tJJCNoticeMap

	tData.m_tTongJiMap = self.m_tTongJiMap
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sOfflineJJCDB, "data", cjson.encode(tData))
end

function CJJCData:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CJJCData:IsDirty()
	return self.m_bDirty
end

function CJJCData:OnRelease()
end

--离线时更新大臣使团
function CJJCData:UpdateMCGroup(oPlayer, tMCGroup)
	assert(#tMCGroup >= 4, "使团数据错误[商农政军]")
	local nCharID = oPlayer:GetCharID()
	self.m_tMCGroupMap[nCharID] = tMCGroup
	self:MarkDirty(true)

	local nWeiWang = oPlayer:GetWeiWang()
	self:MaintainBucket(nCharID, nWeiWang, nWeiWang)
end

--取使节团
function CJJCData:GetMCGroup(nTarCharID, nTarGroup)
	if not self.m_tMCGroupMap[nTarCharID] then
		return {}
	end
	local tMCGroup = self.m_tMCGroupMap[nTarCharID][nTarGroup]
	if not tMCGroup then
		LuaTrace(nTarCharID, "军机处使节团数据为空:"..nTarGroup)
		return {}
	end
	return table.DeepCopy(tMCGroup)
end

--是否设置过使节团(至少有一个大臣)
function CJJCData:HasMCGroup(nCharID) return self.m_tMCGroupMark[nCharID] end

--标识设置了使节团(至少有一个大臣)
function CJJCData:MarkMCGroup(oPlayer)
	local nCharID = oPlayer:GetCharID()
	if self.m_tMCGroupMark[nCharID] then
		return
	end
	self.m_tMCGroupMark[nCharID] = 1
	self:MarkDirty(true)
	local nWeiWang = oPlayer:GetWeiWang()
	self:MaintainBucket(nCharID, nWeiWang, nWeiWang)
end

--更新威望
function CJJCData:UpdateWeiWang(oPlayer, nOldWW, nNewWW)
	local nCharID = oPlayer:GetCharID()
	self:MaintainBucket(nCharID, nOldWW, nNewWW)
end

--维护威望桶
function CJJCData:MaintainBucket(nCharID, nOrgWW, nNewWW)
	--没有过使节团(至少有一个大臣)，不需要维护匹配桶
	if not self.m_tMCGroupMark[nCharID] then
		return
	end
	--移除旧的位置
	local nOrgBucket = math.ceil(nOrgWW / nBucketGranularity)
	local tOrgBucket = self.m_tWeiWangBucket[nOrgBucket]
	if tOrgBucket and tOrgBucket[nCharID] then
		tOrgBucket[nCharID] = nil
	end
	--加到新的位置
	local nBucket = math.ceil(nNewWW / nBucketGranularity)
	self.m_tWeiWangBucket[nBucket] = self.m_tWeiWangBucket[nBucket] or {}
	self.m_tWeiWangBucket[nBucket][nCharID] = nNewWW
	self.m_nMaxBucket = math.max(self.m_nMaxBucket, nBucket)
	self:MarkDirty(true)
end

--匹配使节团
function CJJCData:MatchMCGroup(nExceptID, nMinWW, nMaxWW)
	print("CJJCData:MatchMCGroup***", nExceptID, nMinWW, nMaxWW)
	local nMinBucket = math.ceil(nMinWW / nBucketGranularity)
	local nMaxBucket = math.min(self.m_nMaxBucket, math.ceil(nMaxWW / nBucketGranularity))
	while nMinBucket >= 0 and nMaxBucket <= self.m_nMaxBucket do
		local tCharList = {}
		for k = nMinBucket, nMaxBucket do
			local tBucket = self.m_tWeiWangBucket[k]
			if tBucket then
				for nCharID, v in pairs(tBucket) do
					if nCharID ~= nExceptID then
						table.insert(tCharList, nCharID)
					end
				end
			end
		end
		--匹配到玩家
		if #tCharList > 0 then
			return tCharList[math.random(#tCharList)]
		end
		--已经是边界
		if nMinBucket == 0 and nMaxBucket == self.m_nMaxBucket then
			return
		end
		--扩大匹配范围
		nMinBucket = math.max(0, nMinBucket-1)
		nMaxBucket = math.min(self.m_nMaxBucket, nMaxBucket+1)
	end
end

--生成NOTICE编号
function CJJCData:GenNoticeID()
	self.m_nNoticeID = (self.m_nNoticeID % nMAX_INTEGER) + 1
	self:MarkDirty(true)
	return self.m_nNoticeID
end

--取军机处公告
function CJJCData:GetJJCNotice(nID) return self.m_tJJCNoticeMap[nID] end
--取军机处公告列表
function CJJCData:GetJJCNoticeMap() return self.m_tJJCNoticeMap end
--设置军机处公告列表
function CJJCData:SetJJCNoticeMap(tMap)
	self.m_tJJCNoticeMap = tMap
	self:MarkDirty(true)
end

--添加军机处公告
function CJJCData:AddJJCNotice(tNotice)
	tNotice.nID = self:GenNoticeID()
	self.m_tJJCNoticeMap[tNotice.nID] = tNotice
	self:MarkDirty(true)
end

--计算公告威望&清理军机处公告
function CJJCData:SubJJCNotice(nID, nLostWW)
	local tNotice = self:GetJJCNotice(nID)
	if not tNotice then return end
	local nWWConst = CJunJiChu.nCancelNoticeWW 

	tNotice.nLostWW = (tNotice.nLostWW or 0) + nLostWW
	if tNotice.nLostWW >= nWWConst then self.m_tJJCNoticeMap[nID] = nil end
	self:MarkDirty(true)
end

--取被通缉玩家
function CJJCData:GetTongJi(nCharID) return self.m_tTongJiMap[nCharID] end
--取被通缉榜
function CJJCData:GetTongJiMap() return self.m_tTongJiMap end

--添加通缉
function CJJCData:AddTongJi(nCharID, sCharName)
	local tTongJi = self.m_tTongJiMap[nCharID]
	if not tTongJi then
		tTongJi = {sCharName=sCharName, nTJTimes=0, nLostWW=0, nTime=os.time(), nGuoLi=0, nWWRank=0}
		self.m_tTongJiMap[nCharID] = tTongJi
	end
	tTongJi.nTJTimes = tTongJi.nTJTimes + 1
	tTongJi.nGuoLi = goRankingMgr.m_oGLRanking:GetPlayerGuoLi(nCharID)
	tTongJi.nWWRank = goRankingMgr.m_oWWRanking:GetPlayerRank(nCharID)
	self:MarkDirty(true)
end

--计算威望&减通缉
function CJJCData:SubTongJi(nCharID, nLostWW)
	local tTongJi = self.m_tTongJiMap[nCharID]
	if not tTongJi then return end
	local nWWConst = CJunJiChu.nCanelTJNeedWW 

	tTongJi.nLostWW = tTongJi.nLostWW + nLostWW
	if tTongJi.nLostWW >= nWWConst then
		tTongJi.nTJTimes = tTongJi.nTJTimes - 1
		tTongJi.nLostWW = tTongJi.nLostWW - nWWConst
		if tTongJi.nTJTimes <= 0 then
			self.m_tTongJiMap[nCharID] = nil
		end
	end
	self:MarkDirty(true)
end

--初始化机器人
function CJJCData:InitRobot()
	print("初始化军机处机器人")
	for nID, tConf in pairs(ctJunJiChuRobotConf) do
		assert(nID < gnBaseCharID, "机器人ID非法")
		self.m_tMCGroupMark[nID] = 1
		self:MaintainBucket(nID, 0, tConf.nWW)
	end
end