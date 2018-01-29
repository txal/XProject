--出巡数据
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
-- local tEtcConf = ctChuXunEtcConf[1]
local tEtcConf = {}
local nMaxGroupFZ = 5 --1组妃子多少人
local nBucketGranularity = 10 --粒度
local nRecoverTime = tEtcConf.nGDRecTime --恢复次数间隔
local nMaxRecoverTimes = tEtcConf.nGDRecTimes --最大累积宫斗次数
local nMaxRecords = 30

CCXData.tBTType = {
	eGD = 1, 	--宫斗
	eFC = 2, 	--复仇
	eZB = 3, 	--抓捕
}

function CCXData:Ctor(oParent)
	self.m_oParent = oParent
	self.m_bDirty = false
	self.m_tXingGongMap = {} 	--行宫映射:{[charid]={[id]={fz={{fzid,yuanfen},...}},...},...}

	self.m_tChuXunMap = {} 		--出巡映射表
	self.m_tGDScoreBucket = {} 	--出巡宫斗积分桶(匹配用)
	self.m_nMaxBucket = 0 		--最大桶数

	self.m_tCurrTimesMap = {} 		--当前拥有宫斗次数映射
	self.m_tLastRecoverMap = {} 	--上次恢复时间映射
	self.m_nResetTime = os.time() 	--上次重置时间
	self.m_tGDTimesMap = {} 		--已出使次数

	self.m_tOfflineAwardMap = {} 	--离线奖励
	self.m_tGDRecordMap = {} 		--宫斗信息记录
	self.m_tCRRecordMap = {} 		--仇人信息记录
	self.m_tTJRecordMap = {} 		--通缉榜
	self.m_nWins = 0 				--连胜
	self.m_nLosts = 0 				--连败

	self.m_tCXTickMap = {} 			--出巡结束计时器{[charid]=tick,...}
	self.m_tGDTickMap = {} 			--可以宫斗计时器{[charid]=tick,...}
end

function CCXData:LoadData()
	print("加载宴会数据")
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sOfflineCXDB, "data")
	if sData == "" then
		return
	end

	local tData = cjson.decode(sData)
	for k, v in pairs(tData) do
		self[k] = v
	end

	self:OnLoaded()
end

function CCXData:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tXingGongMap = self.m_tXingGongMap
	tData.m_tChuXunMap = self.m_tChuXunMap
	tData.m_tGDScoreBucket = self.m_tGDScoreBucket
	tData.m_nMaxBucket = self.m_nMaxBucket

	tData.m_tCurrTimesMap = self.m_tCurrTimesMap
	tData.m_tLastRecoverMap = self.m_tLastRecoverMap
	tData.m_nResetTime = self.m_nResetTime
	tData.m_tGDTimesMap = self.m_tGDTimesMap

	tData.m_tOfflineAwardMap = self.m_tOfflineAwardMap
	tData.m_tGDRecordMap = self.m_tGDRecordMap
	tData.m_tCRRecordMap = self.m_tCRRecordMap
	tData.m_tTJRecordMap = self.m_tTJRecordMap
	tData.m_nWins = self.m_nWins
	tData.m_nLosts = self.m_nLosts

	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sOfflineCXDB, "data", cjson.encode(tData))
end

function CCXData:OnLoaded()
	self:InitRobot()
	for nCharID, tCXMap in pairs(self.m_tChuXunMap) do
		local nGDScore = self:GetGDScore()
		self:MaintainBucket(nCharID, nGDScore, nGDScore)
	end
end

function CCXData:OnRelease()
	for nCharID, nTick in pairs(self.m_tCXTickMap) do
		goTimerMgr:Clear(nTick)
	end	
	self.m_tCXTickMap = {}

	for nCharID, nTick in pairs(self.m_tGDTickMap) do
		goTimerMgr:Clear(nTick)
	end
	self.m_tGDTickMap = {}
end

function CCXData:IsDirty()
	return self.m_bDirty
end

function CCXData:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

--玩家上线
function CCXData:Online(oPlayer)
	local nCharID = oPlayer:GetCharID()
	--初始化次数
	self.m_tCurrTimesMap[nCharID] = self.m_tCurrTimesMap[nCharID] or nMaxRecoverTimes
	--初始化上次恢复时间
	self.m_tLastRecoverMap[nCharID] = self.m_tLastRecoverMap[nCharID] or os.time()

	--初始化行宫
	if not self.m_tXingGongMap[nCharID] then
		self.m_tXingGongMap[nCharID] = {}
	end
	local tXingGongMap = self.m_tXingGongMap[nCharID]
	for nID, tConf in pairs(ctXingGongConf) do
		if tConf.nYuanBao <= 0 and not tXingGongMap[nID] then
			self:CreateXingGong(oPlayer, nID)
		end
	end
	
	--检测恢复次数
	self:CheckRecover(oPlayer)

	--离线奖励
	local tOfflineAward = self.m_tOfflineAwardMap[nCharID] or {}
	for _, tAward in ipairs(tOfflineAward) do
		oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "宫斗上线结算")
	end
	self.m_tOfflineAwardMap[nCharID] = {}
	self:MarkDirty(true)

	--小红点
	if self:CheckOpen(oPlayer, true) then
		self:CheckCXRP(nCharID)
		self:CheckGDRP(nCharID)
	end
end

--累积恢复次数上限
function CCXData:MaxTimes()
	return nMaxRecoverTimes
end

--增加次数
function CCXData:AddTimes(oPlayer, nVal)
	local nCharID = oPlayer:GetCharID()
	self.m_tCurrTimesMap[nCharID] = math.min(self:MaxTimes(), math.max(0, self.m_tCurrTimesMap[nCharID]+nVal))
	self:MarkDirty(true)
end

--取下次恢复时间
function CCXData:GetRecoverTime(oPlayer)
	local nCharID = oPlayer:GetCharID()
	return math.max(0, (self.m_tLastRecoverMap[nCharID]+nRecoverTime-os.time()))
end

--次数恢复处理
function CCXData:CheckRecover(oPlayer)
	local nCharID = oPlayer:GetCharID()

	local nNowTime = os.time() 
	local nPassTime = nNowTime - self.m_tLastRecoverMap[nCharID]
	local nTimesAdd = math.floor(nPassTime / nRecoverTime) 
	if nTimesAdd > 0 then                                                                                                        
		self.m_tLastRecoverMap[nCharID] = self.m_tLastRecoverMap[nCharID] + nTimesAdd*nRecoverTime
		self:AddTimes(oPlayer, nTimesAdd)
		self:MarkDirty(true)
	end
end

--检测出使次数重置
function CCXData:CheckReset()
	local nNowSec = os.time()
	if not os.IsSameDay(nNowSec, self.m_nResetTime, 5*3600) then
		self.m_tGDTimesMap = {}
		self.m_nResetTime = nNowSec
		self:MarkDirty(true)
	end
end

--检测开放
function CCXData:CheckOpen(oPlayer, bNoTips)
	local tConf = ctChuXunEtcConf[1]
	if not oPlayer.m_oDup:IsChapterPass(tConf.nChapter) then
		if not bNoTips then
			local sTips = string.format("通关第%d章: %s开启", tConf.nChapter, CDup:ChapterName(tConf.nChapter))
			oPlayer:Tips(sTips)
		end
		return 
	end
	return true
end

--取玩家行宫
function CCXData:GetXingGong(nCharID, nID)
	local tXingGongMap = self.m_tXingGongMap[nCharID] or {}
	return tXingGongMap[nID]
end

--建造行宫
function CCXData:CreateXingGong(oPlayer, nID)
	local nCharID = oPlayer:GetCharID()
	if self:GetXingGong(nCharID, nID) then
		return oPlayer:Tips("行宫已存在")
	end
	local tConf = ctXingGongConf[nID]
	if not tConf then
		return oPlayer:Tips("行宫不存在")
	end
	if oPlayer:GetYuanBao() < tConf.nYuanBao then
		return oPlayer:Tips("皇上，元宝不足")
	end
	oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nYuanBao, "建造行宫")

	--创建行宫
	local nCharID = oPlayer:GetCharID()
	local tXingGongMap = self.m_tXingGongMap[nCharID] or {}
	tXingGongMap[nID] = {tFZ={},nCXTime=0,nRobYLPer=0,nYL=0}
	self.m_tXingGongMap[nCharID] = tXingGongMap
	self:MarkDirty(true)
	self:SyncXingGong(oPlayer)
	return true
end

--建造行宫请求
function CCXData:CreateXingGongReq(oPlayer, nXGID)
	if not self:CheckOpen(oPlayer) then
		return
	end
	if self:CreateXingGong(oPlayer, nXGID) then
		return oPlayer:Tips("成功扩建行宫")
	end
end

--取妃子行宫
function CCXData:GetFZXingGong(oPlayer, nFZID)
	local nCharID = oPlayer:GetCharID()
	local tXingGongMap = self.m_tXingGongMap[nCharID]
	if not tXingGongMap then
		return 0
	end
	for nXGID, tXingGong in pairs(tXingGongMap) do
		for nIndex, tFZ in pairs(tXingGong.tFZ) do
			if tFZ.nFZID == nFZID then
				return nXGID
			end
		end
	end
	return 0
end

--检测缘分
function CCXData:CalcYuanFen(oPlayer, nXGID)
	local nCharID = oPlayer:GetCharID()
	local tXingGong = self:GetXingGong(nCharID, nXGID)
	if not tXingGong then
		return
	end

	--转换一下
	local tFZMap = {}
	local tYFList = {} --妃子所在缘分列表
	for _, tFZ in pairs(tXingGong.tFZ) do
		tFZ.nYuanFenAdd = 0
		tFZMap[tFZ.nFZID] = tFZ

		local tFZConf = ctFeiZiConf[tFZ.nFZID]
		for _, tYF in pairs(tFZConf.tYuanFen) do
			table.insert(tYFList, tYF[1])
		end
	end
	self:MarkDirty(true)

	--计算缘分
	for _, nYF in ipairs(tYFList) do
		local tConf = ctYuanFenConf[nYF]
		local nCount = 0
		for _, tFZ in pairs(tConf.tFZ) do
			if not tFZMap[tFZ.nFZID] then
				break
			end
			nCount = nCount + 1
		end
		if nCount == #tConf.tFZ then
			for _, tFZ in pairs(tConf.tFZ) do
				tFZMap[tFZ.nFZID].nYuanFenAdd = tFZMap[tFZ.nFZID].nYuanFenAdd + tConf.nGongDouAdd
			end
		end
	end
end

--行宫是否出巡中
function CCXData:IsChuXun(oPlayer, nXGID)
	local nCharID = oPlayer:GetCharID()
	local tXingGong = self:GetXingGong(nCharID, nXGID)
	if not tXingGong then
		return false, 0
	end
	local tConf = ctChuXunEtcConf[1]
	if tXingGong.nCXTime > 0 then
		return true, math.max(0, tXingGong.nCXTime+tConf.nCXTime-os.time())
	end
	return false, 0
end

--取行宫妃子数量
function CCXData:GetFZCount(oPlayer, nXGID)
	local nCharID = oPlayer:GetCharID()
	local tXingGong = self:GetXingGong(nCharID, nXGID)
	if not tXingGong then
		return 0
	end
	local nCount = 0
	for _, tFZ in pairs(tXingGong.tFZ) do
		nCount = nCount + 1
	end
	return nCount
end

--同步行宫信息
function CCXData:SyncXingGong(oPlayer, nXGID)
	self:CheckReset()
	self:CheckRecover(oPlayer)
	local nCharID = oPlayer:GetCharID()

	local tMsg = {}
	tMsg.nUsedGDTimes = self.m_tGDTimesMap[nCharID] or 0
	tMsg.nCurrGDTimes = self.m_tCurrTimesMap[nCharID] or 0
	tMsg.nRecoverTime = self:GetRecoverTime(oPlayer)

	--生成消息
	local function _MakeXingGongMsg(nXGID, tXingGong)
		local bCX, nCXCD = self:IsChuXun(oPlayer, nXGID)
		local nRobYL = math.floor(tXingGong.nYL*tXingGong.nRobYLPer)
		local tXGData = {nXGID=nXGID, nGongDou=0, bCX=bCX, nCXCD=nCXCD, tFZList={}, nYL=tXingGong.nYL, nRobYL=nRobYL}
		for k = 1, nMaxGroupFZ do
			local tFZ = tXingGong.tFZ[k]
			if tFZ then
				local nGongDou = math.floor(tFZ.nGongDou*(1+tFZ.nYuanFenAdd))
				local tInfo = {nFZID=tFZ.nFZID
					, sName=tFZ.sName
					, nGongDou=nGongDou
					, nYuanFenAdd=tFZ.nYuanFenAdd*100}
				tXGData.nGongDou = tXGData.nGongDou + nGongDou
				table.insert(tXGData.tFZList, tInfo)
			else
				table.insert(tXGData.tFZList, {nFZID=0})
			end
		end
		return tXGData
	end

	local tList = {}
	if nXGID then
		local tXingGong = self:GetXingGong(nCharID, nXGID)
		if not tXingGong then return end
		local tXGData = _MakeXingGongMsg(nXGID, tXingGong)
		table.insert(tList, tXGData)
	else
		local tXingGongMap = self.m_tXingGongMap[nCharID]
		for nXGID, tXingGong in pairs(tXingGongMap) do
			local tXGData = _MakeXingGongMsg(nXGID, tXingGong)
			table.insert(tList, tXGData)
		end
	end
	tMsg.tList = tList
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "XingGongInfoRet", tMsg)
end

--手动添加妃子
function CCXData:CXAddFZReq(oPlayer, nXGID, nFZID, nIndex)
	assert(nIndex >= 1 and nIndex <= 5)
	local nCharID = oPlayer:GetCharID()
	local tXingGong = self:GetXingGong(nCharID, nXGID)
	if not tXingGong then
		return oPlayer:Tips("行宫不存在")
	end
	if self:IsChuXun(oPlayer, nXGID) then
		return oPlayer:Tips("行宫出巡中")
	end
	--检测妃子是否在别的行宫中
	local nFZXG = self:GetFZXingGong(oPlayer, nFZID)
	if nFZXG > 0 and nFZXG ~= nXGID then
		return oPlayer:Tips("妃子已在别的行宫中")
	end
	--清除掉该行宫的该妃子
	for nIndex, tFZ in pairs(tXingGong.tFZ) do
		if tFZ.nFZID == nFZID then
			tXingGong.tFZ[nIndex] = nil
		end
	end
	
	local oFZ = oPlayer.m_oFeiZi:GetObj(nFZID)
	tXingGong.tFZ[nIndex] = {nFZID=nFZID, sName=oFZ:GetName(), nGongDou=oFZ:GetGongDou(), nYuanFenAdd=0}
	tXingGong.nYL = self:CalcYL(oPlayer, tXingGong)
	self:MarkDirty(true)

	self:CalcYuanFen(oPlayer, nXGID)
	self:SyncXingGong(oPlayer)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "CXAddFZRet", {nXGID=nXGID, nFZID=nFZID, nGrid=nIndex})

end

--手动移除妃子
function CCXData:CXRemoveFZReq(oPlayer, nXGID, nFZID)
	local nCharID = oPlayer:GetCharID()
	local tXingGong = self:GetXingGong(nCharID, nXGID)
	if not tXingGong then
		return
	end
	if self:IsChuXun(oPlayer, nXGID) then
		return
	end
	--检测妃子是否在别的行宫中
	local nFZXG = self:GetFZXingGong(oPlayer, nFZID)
	if nFZXG == 0 and nFZXG ~= nXGID then
		return oPlayer:Tips("妃子不在行宫中")
	end
	--清除掉该行宫的该妃子
	local nGrid = 0
	for nIndex, tFZ in pairs(tXingGong.tFZ) do
		if tFZ.nFZID == nFZID then
			tXingGong.tFZ[nIndex] = nil
			nGrid = nIndex
		end
	end
	tXingGong.nYL = self:CalcYL(oPlayer, tXingGong)
	self:MarkDirty(true)

	self:CalcYuanFen(oPlayer, nXGID)
	self:SyncXingGong(oPlayer)

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "CXRemoveFZRet", {nXGID=nXGID, nFZID=nFZID, nGrid=nGrid})
end

--智能添加妃子
function CCXData:CXAutoAddFZReq(oPlayer, nXGID)
	local nCharID = oPlayer:GetCharID()
	local tXingGong = self:GetXingGong(nCharID, nXGID)
	if not tXingGong then
		return oPlayer:Tips("行宫不存在")
	end
	if self:IsChuXun(oPlayer, nXGID) then
		return oPlayer:Tips("行宫出巡中")
	end
	--选出已经在行宫(非本行宫)的妃子
	local tExistFZMap = {}
	local tXingGongMap = self.m_tXingGongMap[nCharID]
	for nID, tTmpXG in pairs(tXingGongMap) do
		if nID ~= nXGID then
			for _, tFZ in ipairs(tTmpXG.tFZ) do
				tExistFZMap[tFZ.nFZID] = tFZ
			end
		end
	end
	--清除该行宫的妃子
	tXingGong.tFZ = {}
	self.m_tXingGongMap[nCharID][nXGID] = tXingGong
	self:MarkDirty(true)

	--筛选宫斗力最大的5个妃子
	local tFZList = {}
	local tFZMap = oPlayer.m_oFeiZi:GetFZMap()
	for nID, oFZ in pairs(tFZMap) do
		if not tExistFZMap[nID] then
			table.insert(tFZList, oFZ)
		end
	end
	table.sort(tFZList, function(oFZ1, oFZ2) return oFZ1:GetGongDou() > oFZ2:GetGongDou() end)
	if #tFZList <= 0 then
		return oPlayer:Tips("没有可上阵的妃子")
	end

	--添加妃子到行宫
	for k = 1, nMaxGroupFZ do
		local oFZ = tFZList[k]
		if oFZ then
			tXingGong.tFZ[k] = {nFZID=oFZ:GetID(), sName=oFZ:GetName(), nGongDou=oFZ:GetGongDou(), nYuanFenAdd=0}
		end
	end

	--计算缘分
	self:CalcYuanFen(oPlayer, nXGID)

	--计算银两
	tXingGong.nYL = self:CalcYL(oPlayer, tXingGong)
	self:MarkDirty(true)

	self:SyncXingGong(oPlayer)
end

--取宫斗积分
function CCXData:GetGDScore(nCharID)
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.eGDRanking)
	local nGDScore = oRanking:GetPlayerGD(nCharID)
	return nGDScore
end

--加减宫斗
function CCXData:AddGDScore(nCharID, nVal)
	local nOldGDScore = self:GetGDScore(nCharID)
	local nGDScore = math.max(0, math.min(nMAX_INTEGER, nOldGDScore+nVal))
	local oRanking = goRankingMgr:GetRanking(gtRankingDef.eGDRanking)
	oRanking:Update(nCharID, nGDScore)
	self:MaintainBucket(nCharID, nOldGDScore, nGDScore)
end

--记录出巡
function CCXData:RecordCX(oPlayer, nXGID)
	local nCharID = oPlayer:GetCharID()
	local tCXMap = self.m_tChuXunMap[nCharID] or {}
	tCXMap[nXGID] = true
	self.m_tChuXunMap[nCharID] = tCXMap
	self:MarkDirty(true)
	local nGDScore = self:GetGDScore(nCharID)
	self:MaintainBucket(nCharID, nGDScore, nGDScore)
end

--移除出巡
function CCXData:RemoveCX(oPlayer, nXGID)
	local nCharID = oPlayer:GetCharID()
	local tCXMap = self.m_tChuXunMap[nCharID] or {}
	if not tCXMap[nXGID] then
		return
	end
	tCXMap[nXGID] = nil
	self:MarkDirty(true)
	local nGDScore = self:GetGDScore(nCharID)
	self:MaintainBucket(nCharID, nGDScore, nGDScore)
end

--注册出巡及时器
function CCXData:RegisterCXTimer(nCharID, nSecTime)
	self:CancelCXTimer(nCharID)

	if nSecTime <= 0 then
		return
	end

	self.m_tCXTickMap[nCharID] = goTimerMgr:Interval(nSecTime, function() self:CheckCXRP(nCharID) end)
end

--取消出巡计时器
function CCXData:CancelCXTimer(nCharID)
	local nCXTick = self.m_tCXTickMap[nCharID]
	goTimerMgr:Clear(nCXTick)
	self.m_tCXTickMap[nCharID] = nil
end

function CCXData:CheckCXRP(nCharID)
	self:CancelCXTimer(nCharID)

	local tEtcConf = ctChuXunEtcConf[1]
	local nMinCD = 0
	local tXingGongMap = self.m_tXingGongMap[nCharID]
	for nID, tXingGong in pairs(tXingGongMap) do
		if tXingGong.nCXTime > 0 then
			local nCD = math.max(0, tXingGong.nCXTime+tEtcConf.nCXTime-os.time())
			if nCD <= 0 then
				CRedPoint:MarkRedPointAnyway(nCharID, gtRPDef.eFinishCX, 1)
				return
			elseif nMinCD == 0 or nCD < nMinCD then
				nMinCD = nCD
			end
		end
	end
	if nMinCD > 0 then
		self:RegisterCXTimer(nCharID, nMinCD)
	else
		CRedPoint:MarkRedPointAnyway(nCharID, gtRPDef.eFinishCX, 0)
	end
end

--计算银两
function CCXData:CalcYL(oPlayer, tXingGong)
	local nYinLiang = 0
	local nYLParam = ctChuXunEtcConf[1].nYLParam
	for _, tFZ in pairs(tXingGong.tFZ) do
		local oFZ = oPlayer.m_oFeiZi:GetObj(tFZ.nFZID)
		nYinLiang = nYinLiang + math.floor((oFZ:GetNengLi()*(1+oFZ:GetQinMi()/2.5/100))*nYLParam)
	end
	return nYinLiang
end

--普通出巡信息请求
function CCXData:ChuXunReq(oPlayer, nXGID)
	local nCharID = oPlayer:GetCharID()
	if not self:CheckOpen(oPlayer) then
		return
	end
	if self:IsChuXun(oPlayer, nXGID) then
		return oPlayer:Tips("皇上，该行宫正在出巡中")
	end
	if self:GetFZCount(oPlayer, nXGID) < nMaxGroupFZ then
		return oPlayer:Tips("皇上，不足5位妃子不能出巡")
	end
	local tXingGong = self:GetXingGong(nCharID, nXGID)
	tXingGong.nCXTime = os.time()

	--计算银两
	tXingGong.nYL = self:CalcYL(oPlayer, tXingGong)
	self:MarkDirty(true)

	self:RecordCX(oPlayer, nXGID)
	self:SyncXingGong(oPlayer)

	self:CheckCXRP(nCharID)

	--活动
	goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(oPlayer:GetCharID(), gtTAType.eCX, 1)
end

--结束出巡请求
function CCXData:FinishChuXunReq(oPlayer, nXGID)
	-- 出巡获得的总银两数=（妃子A能力*（1+（妃子A亲密度/2.5）%））*24
	-- +（妃子B能力*（1+（妃子B亲密度/2.5）%））*24
	-- +（妃子C能力*（1+（妃子C亲密度/2.5）%））*24
	-- +（妃子D能力*（1+（妃子D亲密度/2.5）%））*24
	-- +（妃子E能力*（1+（妃子E亲密度/2.5）%））*24
	local nCharID = oPlayer:GetCharID()
	local tXingGong = self:GetXingGong(nCharID, nXGID)	
	if not tXingGong then
		return
	end
	local bCX, nCD = self:IsChuXun(oPlayer, nXGID)
	if not bCX then
		return oPlayer:Tips("行宫非出巡状态")
	end
	if nCD > 0 then
		return oPlayer:Tips("出巡未结束")
	end

	local nYinLiang = tXingGong.nYL
	nYinLiang = math.floor(nYinLiang*(1-tXingGong.nRobYLPer))
	oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYinLiang, nYinLiang, "普通出巡结束")
	tXingGong.nCXTime = 0
	tXingGong.nRobYLPer = 0
	tXingGong.nYL = 0
	tXingGong.tFZ = {}
	self:MarkDirty(true)

	self:RemoveCX(oPlayer, nXGID)
	self:SyncXingGong(oPlayer)
	oPlayer:IconTips(gtCurrProp[gtCurrType.eYinLiang], nYinLiang)

	self:CheckCXRP(nCharID)
end

--根据连胜/败匹配玩家
function CCXData:MatchEnemy(oPlayer)
	local nCharID = oPlayer:GetCharID()

	---------计算宫斗积分加权范围
	--加权
	local nWinsAdd = math.max(0, self.m_nWins-2)
	local nLostsAdd = math.max(0, self.m_nLosts-2)

	--计算区间
	local nTotalW, nPreW = 0, 0
	for _, tConf in ipairs(ctChuXunMatchConf) do
		local nWeight = tConf.nBaseWeight+nWinsAdd*tConf.nWinsAdd+nLostsAdd*tConf.nLostsAdd
		tConf.nWeight = nWeight
		tConf.nMinW = nPreW + 1
		tConf.nMaxW = tConf.nMinW + nWeight - 1
		nPreW = tConf.nMaxW
		nTotalW = nTotalW + nWeight
	end

	--拿到宫斗力区间
	local tRang = {}
	local nRnd = math.random(1, nTotalW)
	for _, tConf in ipairs(ctChuXunMatchConf) do
		if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
			tRang[1] = tConf.tRang[1][1]
			tRang[2] = tConf.tRang[1][2]
			break
		end
	end

	local nGDScore = self:GetGDScore(nCharID)
	tRang[1] = math.max(0, tRang[1] + nGDScore)
	tRang[2] = math.max(0, tRang[2] + nGDScore)

	---------从宫斗积分桶匹配目标玩家
	local nMinBucket = math.ceil(tRang[1] / nBucketGranularity)
	local nMaxBucket = math.min(self.m_nMaxBucket, math.ceil(tRang[2] / nBucketGranularity))
	while nMinBucket >= 0 and nMaxBucket <= self.m_nMaxBucket do
		local tCharList = {}
		for k = nMinBucket, nMaxBucket do
			local tBucket = self.m_tGDScoreBucket[k]
			if tBucket then
				for nTmpCharID, v in pairs(tBucket) do
					if nCharID ~= nTmpCharID then
						table.insert(tCharList, nTmpCharID)
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

--是否有出巡的行宫
function CCXData:HasChuXun(nCharID)
	local tCXMap = self.m_tChuXunMap[nCharID]
	if not tCXMap or not next(tCXMap) then
		return false
	end
	return true
end

--更新宫斗积分匹配桶
function CCXData:MaintainBucket(nCharID, nOrgGD, nNewGD)
	--移除旧的位置
	local nOrgBucket = math.ceil(nOrgGD / nBucketGranularity)
	local tOrgBucket = self.m_tGDScoreBucket[nOrgBucket]
	if tOrgBucket and tOrgBucket[nCharID] then
		tOrgBucket[nCharID] = nil
	end
	if not self:HasChuXun(nCharID) then
		return
	end
	--加到新的位置
	local nBucket = math.ceil(nNewGD / nBucketGranularity)
	self.m_tGDScoreBucket[nBucket] = self.m_tGDScoreBucket[nBucket] or {}
	self.m_tGDScoreBucket[nBucket][nCharID] = nNewGD
	self.m_nMaxBucket = math.max(self.m_nMaxBucket, nBucket)
	self:MarkDirty(true)
end

--初始化机器人
function CCXData:InitRobot()
	print("初始化出巡机器人")
	for nID, tConf in pairs(ctChuXunRobotConf) do
		assert(nID < gnBaseCharID, "机器人ID非法")
		self.m_tChuXunMap[nID] = {true}
		self:MaintainBucket(nID, 0, tConf.nGDScore)
	end
end

--取消宫斗计时器
function CCXData:CancelGDTimer(nCharID)
	local nTick = self.m_tGDTickMap[nCharID]
	goTimerMgr:Clear(nTick)
	self.m_tGDTickMap[nCharID] = nil
end

--注册宫斗计时器
function CCXData:RegisterGDTimer(nCharID, nSecTime)
	self:CancelGDTimer(nCharID)
	self.m_tGDTickMap[nCharID] = goTimerMgr:Interval(nSecTime, function() self:CheckGDRP(nCharID) end)
end

--检测宫斗小红点
function CCXData:CheckGDRP(nCharID)
	self:CancelGDTimer(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oPlayer then
		return
	end
	if self:CanGongDou(oPlayer, false, true) then
		oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eCanGD, 1)
	else
		oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eCanGD, 0)
	end
	local nRecTime = self:GetRecoverTime(oPlayer)
	if nRecTime > 0 then
		self:RegisterGDTimer(nCharID, nRecTime)
	end
end

--是否可以宫斗
function CCXData:CanGongDou(oPlayer, bUseProp, bNoTips)
	if not self:CheckOpen(oPlayer, bNoTips) then
		return
	end
	self:CheckReset()
	self:CheckRecover(oPlayer)
	local nCharID = oPlayer:GetCharID()
	if self.m_tCurrTimesMap[nCharID] <= 0 then
		if not bNoTips then
			oPlayer:Tips("皇上，没有可出使次数")
		end
		return 
	end
 	local tConf = ctChuXunEtcConf[1]
	if not bUseProp and (self.m_tGDTimesMap[nCharID] or 0) >= tConf.nGDTimes then
		if not bNoTips then
			oPlayer:Tips("皇上，今天出使次数已用完")
		end
		return
	end
	if not self:HasChuXun(nCharID) then
		if not bNoTips then
			oPlayer:Tips("皇上，请先设置出巡的队伍才能进行宫斗")
		end
		return 
	end
	return true
end

--添加离线奖励
function CCXData:AddOfflineAward(nCharID, tAward)
	if not self.m_tOfflineAwardMap[nCharID] then
		self.m_tOfflineAwardMap[nCharID]= {}
	end
	table.insert(self.m_tOfflineAwardMap[nCharID], tAward)
	self:MarkDirty(true)
end

--添加宫斗信息
function CCXData:AddGDRecord(nCharID, tInfo)
	local tRecord = self.m_tGDRecordMap[nCharID]
	if not tRecord then
		tRecord = {}	
		self.m_tGDRecordMap[nCharID] = tRecord
		self:MarkDirty(true)
	end
	table.insert(tRecord, 1, tInfo)
	if #tRecord > nMaxRecords then
		table.remove(tRecord)
	end
	self:MarkDirty(true)
end

--添加仇人
function CCXData:AddCRRecord(nCharID, tInfo)
	local tRecord = self.m_tCRRecordMap[nCharID]
	if not tRecord then
		tRecord = {}	
		self.m_tCRRecordMap[nCharID] = tRecord
		self:MarkDirty(true)
	end
	table.insert(tRecord, 1, tInfo)
	if #tRecord > 50 then
		table.remove(tRecord)
	end
	self:MarkDirty(true)
end

--移除仇人
function CCXData:ClearCRRecord(nCharID, nTarCharID)
	local tRecord = self.m_tCRRecordMap[nCharID]
	if not tRecord then
		return
	end
	local tNewRecord = {}
	for _, v in ipairs(tRecord) do
		if v.nSrcCharID ~= nTarCharID then
			table.insert(tNewRecord, v)
		end
	end
	self.m_tCRRecordMap[nCharID] = tRecord
	self:MarkDirty(true)
end

--添加通缉次数
function CCXData:AddTJRecord(nCharID)
	local sCharName = goOfflineDataMgr:GetName(nCharID)
	local tRecord = self.m_tTJRecordMap[nCharID]
	if not tRecord then
		tRecord = {sCharName=sCharName, nTJTimes=0, nLostGD=0, nTime=os.time(), nGDRank=0}
		self.m_tTJRecordMap[nCharID] = tRecord
	end
	tRecord.nTJTimes = tRecord.nTJTimes + 1
	tRecord.nGDRank = goRankingMgr:GetRanking(gtRankingDef.eGDRanking):GetPlayerRank(nCharID)
	self:MarkDirty(true)
end

--减通缉次数
function CCXData:SubTJRecord(nCharID, nLostGD)
	local tRecord = self.m_tTJRecordMap[nCharID]
	if not tRecord then return end
	local nGDConst = 30

	tRecord.nLostGD = tRecord.nLostGD + nLostGD
	if tRecord.nLostGD >= nGDConst then
		tRecord.nTJTimes = tRecord.nTJTimes - 1
		tRecord.nLostGD = tRecord.nLostGD - nGDConst
		if tRecord.nTJTimes <= 0 then
			self.m_tTJRecordMap[nCharID] = nil
		end
	end
	self:MarkDirty(true)
end

--下令宫斗
function CCXData:StartGDReq(oPlayer, nSrcXGID, bUseProp)
	if not self:CheckOpen(oPlayer) then
		return
	end
	if bUseProp then
		local nPropID = ctChuXunEtcConf[1].nGDProp
		local nPackCount = oPlayer:GetItemCount(gtItemType.eProp, nPropID)
		if nPackCount <= 0 then return oPlayer:Tips("宫斗令不足") end
		oPlayer:SubItem(gtItemType.eProp, nPropID, 1, "使用宫斗令")
		self:AddTimes(oPlayer, 1)
	end
	if not self:CanGongDou(oPlayer, bUseProp) then
		return
	end
	local nSrcCharID = oPlayer:GetCharID()
	if not self:IsChuXun(oPlayer, nSrcXGID) then
		return oPlayer:Tips("行宫ID错误")
	end
	local nTarCharID = self:MatchEnemy(oPlayer)
	if not nTarCharID then
		return oPlayer:Tips("匹配玩家失败")
	end

	--攻方妃子
	local sSrcCharName = oPlayer:GetName()
	local nSrcGDScore = self:GetGDScore(nSrcCharID)

	local tSrcFZ = {}
	local tXingGong = self:GetXingGong(nSrcCharID, nSrcXGID)
	for k = 1, nMaxGroupFZ do
		local tFZ = tXingGong.tFZ[k]
		local nGongDou = math.floor(tFZ.nGongDou*(1+tFZ.nYuanFenAdd))
		tSrcFZ[k] = {nFZID=tFZ.nFZID, sName=tFZ.sName, nGongDou=nGongDou, nBlood=nGongDou}
	end

	--守方妃子
	local sTarCharName = ""
	local nTarGDScore = 0

	local tTarFZ = {}
	local nTarXGID = 0

	if nTarCharID < gnBaseCharID then --机器人
		print("宫斗匹配到机器人")
		nTarXGID = 1
		local tConf = ctChuXunRobotConf[nTarCharID]
		for nIndex, tFZ in ipairs(tConf.tFZ) do
			tTarFZ[nIndex] = {nFZID=tFZ[1], nGongDou=tFZ[2], nBlood=tFZ[2]}
			tTarFZ[nIndex].sName = ctFeiZiConf[tFZ[1]].sName
		end
		sTarCharName = tConf.sName
		nTarGDScore = tConf.nGDScore

	else --玩家
		self:UpdateFZAttr(nTarCharID)

		local tList = {}
		local tXGMap = self.m_tXingGongMap[nTarCharID]
		for nXGID, v in pairs(tXGMap) do
			table.insert(tList, nXGID)
		end
		if #tList <= 0 then
			return oPlayer:Tips("皇上，对方不在出巡中")
		end
		nTarXGID = tList[math.random(#tList)]
		local tXingGong = self:GetXingGong(nTarCharID, nTarXGID)
		for k = 1, nMaxGroupFZ do
			local tFZ = tXingGong.tFZ[k]
			local nGongDou = math.floor(tFZ.nGongDou*(1+tFZ.nYuanFenAdd))
			tTarFZ[k] = {nFZID=tFZ.nFZID, sName=tFZ.sName, nGongDou=nGongDou, nBlood=nGongDou}
		end
		sTarCharName = goOfflineDataMgr:GetName(nTarCharID)
		nSrcGDScore = self:GetGDScore(nTarCharID)

	end
	self:AddTimes(oPlayer, -1)
	self.m_tGDTimesMap[nSrcCharID] = (self.m_tGDTimesMap[nSrcCharID] or 0) + 1
	self:MarkDirty(true)
	self:DoBattle(self.tBTType.eGD
		, nSrcCharID, sSrcCharName, nSrcGDScore, nSrcXGID, tSrcFZ
		, nTarCharID, sTarCharName, nTarGDScore, nTarXGID, tTarFZ)
	
	--任务
	oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond23, 1)

	self:CheckGDRP(nSrcCharID)
end

function CCXData:DoBattle(nBTType
	, nSrcCharID, sSrcCharName, nSrcGDScore, nSrcXGID, tSrcFZ
	, nTarCharID, sTarCharName, nTarGDScore, nTarXGID, tTarFZ)
	--战斗过程
	local nRounds = 0 		--回合数
	local tRounds = {} 		--回合数据
	local nMaxRounds = 32 	--最大回合数
	local tResGrid = {} 	--记录分出胜负的格子

	local nSrcWins = 0 		--攻方胜利次数
	local nTarWins = 0 		--守方胜利次数

	local tSrcAward = {0, 0, 0} --宫斗积分,修习卷轴,势力
	local tTarAward = {0, 0, 0}

	local tWinAward = ctChuXunEtcConf[1].tWinAward[1]
	local tLostAward = ctChuXunEtcConf[1].tLostAward[1]
	local function _MakeAward(tAward, bWin)
		if bWin then
			tAward[1] = tAward[1] + tWinAward[1]
			tAward[2] = tAward[2] + tWinAward[2]
			tAward[3] = tAward[3] + tWinAward[3]
		else
			tAward[1] = tAward[1] + tLostAward[1]
			tAward[2] = tAward[2] + tLostAward[2]
			tAward[3] = tAward[3] + tLostAward[3]
		end
		return tAward
	end	

	while nRounds < nMaxRounds do
		nRounds = nRounds + 1
		tRounds[nRounds] = {nRounds=nRounds, tBattle={}}
		for k = 1, nMaxGroupFZ do
			local tSFZ = tSrcFZ[k]
			local tTFZ = tTarFZ[k]
			if not tResGrid[k] then
				--攻方数值
				local nSrcGD = tSFZ.nGongDou
				--守方数值
				local nTarGD = tTFZ.nGongDou

				--攻方伤害
				local nSrcHurt = math.floor(math.random(95, 105)/100*nSrcGD*0.2)
				local nOrgTarBlood = tTFZ.nBlood
				tTFZ.nBlood = math.max(0, tTFZ.nBlood-nSrcHurt)
				print("守方扣血:", nSrcHurt, nSrcGD)

				--守方伤害
				local nTarHurt = math.floor(math.random(95, 105)/100*nTarGD*0.2)
				local nOrgSrcBlood = tSFZ.nBlood
				tSFZ.nBlood = math.max(0, tSFZ.nBlood-nTarHurt)
				print("攻方扣血:", nTarHurt, nTarGD)

				local nWin = 0
				if tSFZ.nBlood > 0 and tTFZ.nBlood == 0 then
					tSFZ.bWin = true
					tTFZ.bWin = false
					nSrcWins = nSrcWins + 1
					tResGrid[k] = true
					nWin = 1

					tSrcAward = _MakeAward(tSrcAward, true)
					tTarAward = _MakeAward(tTarAward, false)

				elseif tSFZ.nBlood == 0 and tTFZ.nBlood >= 0 then
					tSFZ.bWin = false
					tTFZ.bWin = true
					nTarWins = nTarWins + 1
					tResGrid[k] = true
					nWin = 2

					tSrcAward = _MakeAward(tSrcAward, false)
					tTarAward = _MakeAward(tTarAward, true)

				elseif nRounds == nMaxRounds then
					if tSFZ.nBlood > tTFZ.nBlood then
						tSFZ.bWin = true
						tTFZ.bWin = false
						nSrcWins = nSrcWins + 1
						tResGrid[k] = true
						nWin = 1

						tSrcAward = _MakeAward(tSrcAward, true)
						tTarAward = _MakeAward(tTarAward, false)

					else
						tSFZ.bWin = false
						tTFZ.bWin = true
						nTarWins = nTarWins + 1
						tResGrid[k] = true
						nWin = 2

						tSrcAward = _MakeAward(tSrcAward, false)
						tTarAward = _MakeAward(tTarAward, true)

					end

				end

				--回合数据
				local tRound = {nGrid=k,
					nSrcID=tSFZ.nFZID, sSrcName=tSFZ.sName,
					nTarID=tTFZ.nFZID, sTarName=tTFZ.sName,
					nSrcBlood=nOrgSrcBlood, nTarBlood=nOrgTarBlood,
					nSrcBloodRemain=tSFZ.nBlood, nTarBloodRemain=tTFZ.nBlood,
					nWin=nWin,
				}
				table.insert(tRounds[nRounds].tBattle, tRound)
			end
		end
		local nResultCount = 0
		for k = 1, nMaxGroupFZ do
			if tResGrid[k] then
				nResultCount = nResultCount + 1
			end
		end
		if nResultCount >= nMaxGroupFZ then
			break
		end
	end

	--计算掠夺百分比
	local nRobYLPer = 0
	if nSrcWins >= 5 then
		nRobYLPer = 0.2
	elseif nSrcWins >= 4 then
		nRobYLPer = 0.15
	elseif nSrcWins >= 3 then
		nRobYLPer = 0.1
	end
	local nRobYL = 0
	--非机器人记录掠夺信息
	if nTarCharID >= gnBaseCharID then
		local tXingGong = self:GetXingGong(nTarCharID, nTarXGID)
		tXingGong.nRobYLPer = tXingGong.nRobYLPer + nRobYLPer
		self:MarkDirty(true)
		nRobYL = math.floor(tXingGong.nYL*nRobYLPer)
	end

	--计算奖励
	local nProp1 = 32020 	--修习转轴
	local nProp2 = 10011 	--势力
	--攻方奖励
	local oSrcPlayer = goPlayerMgr:GetPlayerByCharID(nSrcCharID)
	self:AddGDScore(nSrcCharID, tSrcAward[1]) --宮斗积分
	oSrcPlayer:AddItem(gtItemType.eProp, nProp1, tSrcAward[2], "宮斗结算")
	oSrcPlayer:AddItem(gtItemType.eProp, nProp2, tSrcAward[3], "宮斗结算")
	if nRobYL > 0 then
		oSrcPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYinLiang, nRobYL, "宮斗结算")
	end

	--守方奖励
	if nTarCharID >= gnBaseCharID then --非机器人
		self:AddGDScore(nTarCharID, tTarAward[1])
		local oTarPlayer = goPlayerMgr:GetPlayerByCharID(nTarCharID)
		if oTarPlayer then
			oTarPlayer:AddItem(gtItemType.eProp, nProp1, tTarAward[2], "宮斗结算")
			oTarPlayer:AddItem(gtItemType.eProp, nProp2, tTarAward[3], "宮斗结算")
		else
			self:AddOfflineAward(nTarCharID, {gtItemType.eProp, nProp1, tTarAward[2]})
			self:AddOfflineAward(nTarCharID, {gtItemType.eProp, nProp2, tTarAward[3]})
		end
	end

	--生成结果
	local tResult = {
		nRobYL = nRobYL,
		nGDScore = tSrcAward[1],
		tPropList = {{nID=nProp1,nNum=tSrcAward[2]},{nID=nProp2,nNum=tSrcAward[3]}}, 
		nRobYLPer = nRobYLPer*100,
		tFZList = {},
	}
	for k = 1, nMaxGroupFZ do
		local tFZ= tSrcFZ[k]
		local tInfo = {nFZID=tFZ.nFZID, bWin=tFZ.bWin}
		table.insert(tResult.tFZList, tInfo)
	end

	--宫斗/仇人信息
	if nTarCharID >= gnBaseCharID then
		local tInfo = {nTime=os.time(), sSrcCharName=sSrcCharName, bWin=nTarWins>=nSrcWins, nRobYL=nRobYL, tResult=tTarAward, tFZList=tResult.tFZList}
		self:AddGDRecord(nTarCharID, tInfo)
		--仇人相关	
		if nBTType == self.tBTType.eGD then --宫斗
			if nRobYL > 0 then
				local tEnemy = {nTime=os.time(), nSrcCharID=nSrcCharID, sSrcCharName=sSrcCharName, nRobYL=nRobYL, nGDScore=self:GetGDScore()}
				self:AddCRRecord(nTarCharID, tEnemy)
			end
		elseif nBTType == self.tBTType.eFC then --复仇
			if nRobYL > 0 then
				self:ClearCRRecord(nSrcCharID, nTarCharID)
			end
		elseif nBTType == self.tBTType.eZB then --抓捕
			if tTarAward[1] < 0 then
				self:SubTJRecord(nTarCharID, math.abs(tTarAward[1]))
			end
		end
	end

	--消息
	local tMsg = {nSrcXGID=nSrcXGID, sSrcCharName=sSrcCharName, nSrcGDScore=nSrcGDScore,
		nTarXGID=nTarXGID, sTarCharName=sTarCharName, nTarGDScore=nTarGDScore,
		tRounds=tRounds, nSrcWins=nSrcWins, nTarWins=nTarWins, tResult=tResult}
	CmdNet.PBSrv2Clt(oSrcPlayer:GetSession(), "CXBattleRet", tMsg)
	print("DoBattle****", tMsg.tRounds)
end

--取宫斗信息列表
function CCXData:GDInfoListReq(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tRecord = self.m_tGDRecordMap[nCharID] or {}
	local tList = {}
	for _, v in ipairs(tRecord) do
		table.insert(tList, v)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "GDInfoListRet", {tList=tList})
end

--取仇人列表
function CCXData:CRInfoListReq(oPlayer, nType)
	local nCharID = oPlayer:GetCharID()
	local tRecord = self.m_tCRRecordMap[nCharID] or {}
	local tList = {}
	for _, v in ipairs(tRecord) do
		local tCopy = table.DeepCopy(v)
		tCopy.bHasCX = self:HasChuXun(v.nSrcCharID)
		print("CCXData:CRInfoListReq***", tCopy)
		table.insert(tList, tCopy)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "CRInfoListRet", {tList=tList, nType=nType})
end

--复仇请求
function CCXData:CXFuChouReq(oPlayer, nSrcXGID, nTarCharID)
	if not self:IsChuXun(oPlayer, nSrcXGID) then
		return oPlayer:Tips("皇上，请先设置出巡的队伍才能进行复仇")
	end
	local nProp = 32030 --宣战书 
	if oPlayer:GetItemCount(gtItemType.eProp, nProp) <= 0 then
		return oPlayer:Tips("宣战书不足")
	end
	oPlayer:SubItem(gtItemType.eProp, nProp, 1, "出巡复仇")

	--攻方妃子
	local nSrcCharID = oPlayer:GetCharID()
	local sSrcCharName = oPlayer:GetName()
	local nSrcGDScore = self:GetGDScore(nSrcCharID)

	local tSrcFZ = {}
	local tXingGong = self:GetXingGong(nSrcCharID, nSrcXGID)
	for k = 1, nMaxGroupFZ do
		local tFZ = tXingGong.tFZ[k]
		local nGongDou = math.floor(tFZ.nGongDou*(1+tFZ.nYuanFenAdd))
		tSrcFZ[k] = {nFZID=tFZ.nFZID, sName=tFZ.sName, nGongDou=nGongDou, nBlood=nGongDou}
	end

	--守方妃子
	self:UpdateFZAttr(nTarCharID)
	local sTarCharName = goOfflineDataMgr:GetName(nTarCharID)
	local nTarGDScore = self:GetGDScore(nTarCharID)
	local nTarXGID = 0
	local tTarFZ = {}

	local tList = {}
	local tXGMap = self.m_tXingGongMap[nTarCharID]
	for nXGID, tXingGong in pairs(tXGMap) do
		if tXingGong.nCXTime > 0 then
			table.insert(tList, nXGID)
		end
	end
	if #tList <= 0 then
		return oPlayer:Tips("皇上，对方不在出巡中")
	end
	nTarXGID = tList[math.random(#tList)]
	local tXingGong = self:GetXingGong(nTarCharID, nTarXGID)
	for k = 1, nMaxGroupFZ do
		local tFZ = tXingGong.tFZ[k]
		local nGongDou = math.floor(tFZ.nGongDou*(1+tFZ.nYuanFenAdd))
		tTarFZ[k] = {nFZID=tFZ.nFZID, sName=tFZ.sName, nGongDou=nGongDou, nBlood=nGongDou}
	end
	self:DoBattle(self.tBTType.eFC
		, nSrcCharID, sSrcCharName, nSrcGDScore, nSrcXGID, tSrcFZ
		, nTarCharID, sTarCharName, nTarGDScore, nTarXGID, tTarFZ)
end

--取通缉列表
function CCXData:CXTJListReq(oPlayer)
	local tList = {}
	for nCharID, tRecord in pairs(self.m_tTJRecordMap) do
		local tInfo = {}
		tInfo.nCharID = nCharID
		tInfo.sCharName = tRecord.sCharName
		tInfo.nTJTimes = tRecord.nTJTimes
		tInfo.nGDRank = tRecord.nGDRank
		tInfo.nTime = tRecord.nTime
		tInfo.nLostGD = (100*tRecord.nTJTimes)-tRecord.nLostGD
		tInfo.bHasCX = self:HasChuXun(nCharID)
		table.insert(tList, tInfo)
		if #tList >= nMaxRecords then break end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "CXTJListRet", {tList=tList})
end

--抓捕请求
function CCXData:CXCatchReq(oPlayer, nSrcXGID, nTarCharID)
	if oPlayer:GetCharID() == nTarCharID then
		return oPlayer:Tips("不能抓捕自己")
	end
	if not self:IsChuXun(oPlayer, nSrcXGID) then
		return oPlayer:Tips("皇上，请先设置出巡的队伍才能进行复仇")
	end
	local nProp = 32030 --宣战书 
	if oPlayer:GetItemCount(gtItemType.eProp, nProp) <= 0 then
		return oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nProp)))
	end
	oPlayer:SubItem(gtItemType.eProp, nProp, 1, "出巡抓捕")

	--攻方妃子
	local nSrcCharID = oPlayer:GetCharID()
	local sSrcCharName = oPlayer:GetName()
	local nSrcGDScore = self:GetGDScore(nSrcCharID)

	local tSrcFZ = {}
	local tXingGong = self:GetXingGong(nSrcCharID, nSrcXGID)
	for k = 1, nMaxGroupFZ do
		local tFZ = tXingGong.tFZ[k]
		local nGongDou = math.floor(tFZ.nGongDou*(1+tFZ.nYuanFenAdd))
		tSrcFZ[k] = {nFZID=tFZ.nFZID, sName=tFZ.sName, nGongDou=nGongDou, nBlood=nGongDou}
	end

	--守方妃子
	self:UpdateFZAttr(nTarCharID)
	local sTarCharName = goOfflineDataMgr:GetName(nTarCharID)
	local nTarGDScore = self:GetGDScore(nTarCharID)
	local nTarXGID = 0
	local tTarFZ = {}

	local tList = {}
	local tXGMap = self.m_tXingGongMap[nTarCharID]
	for nXGID, tXingGong in pairs(tXGMap) do
		if tXingGong.nCXTime > 0 then
			table.insert(tList, nXGID)
		end
	end
	if #tList <= 0 then
		return oPlayer:Tips("皇上，对方不在出巡中")
	end
	nTarXGID = tList[math.random(#tList)]
	local tXingGong = self:GetXingGong(nTarCharID, nTarXGID)
	for k = 1, nMaxGroupFZ do
		local tFZ = tXingGong.tFZ[k]
		local nGongDou = math.floor(tFZ.nGongDou*(1+tFZ.nYuanFenAdd))
		tTarFZ[k] = {nFZID=tFZ.nFZID, sName=tFZ.sName, nGongDou=nGongDou, nBlood=nGongDou}
	end
	self:DoBattle(self.tBTType.eZB
		, nSrcCharID, sSrcCharName, nSrcGDScore, nSrcXGID, tSrcFZ
		, nTarCharID, sTarCharName, nTarGDScore, nTarXGID, tTarFZ)	
end

--通缉玩家请求
function CCXData:CXTongJiReq(oPlayer, nTarCharID)
	if oPlayer:GetCharID() == nTarCharID then
		return oPlayer:Tips("不能通缉自己")
	end
	local nProp = 31202 --通缉令
	if oPlayer:GetItemCount(gtItemType.eProp, nProp) <= 0 then
		return oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nProp)))
	end
	oPlayer:SubItem(gtItemType.eProp, nProp, 1, "出巡通缉玩家")
	self:AddTJRecord(nTarCharID)
	oPlayer:Tips(string.format("%s已被通缉", goOfflineDataMgr:GetName(nTarCharID)))
end

--出巡信息请求
function CCXData:XingGongInfoReq(oPlayer)
	self:UpdateFZAttr(oPlayer:GetCharID())
	self:SyncXingGong(oPlayer)
end

--更新行宫妃子宫斗值和名字
function CCXData:UpdateFZAttr(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oPlayer then return end

	local tXGMap = self.m_tXingGongMap[nCharID]
	for nID, tXG in pairs(tXGMap) do
		for _, tFZ in pairs(tXG.tFZ) do
			local oFZ = oPlayer.m_oFeiZi:GetObj(tFZ.nFZID)
			local sName = oFZ:GetName()
			local nGongDou = oFZ:GetGongDou()
			if tFZ.sName ~= sName or tFZ.nGongDou ~= nGongDou then
				tFZ.sName = sName
				tFZ.nGongDou = nGongDou
				self:MarkDirty(true)
			end
		end
	end
end

--取排行通缉列表
function CCXData:RankingTJListReq(oPlayer)
	if not self:CheckOpen(oPlayer) then
		return
	end
	local tList = {}
	local function _fnTraverse(nRank, nCharID, tData)
		local tInfo = {nRank=nRank, nCharID=nCharID, nGDScore=tData[2], sCharName=goOfflineDataMgr:GetName(nCharID)}
		table.insert(tList, tInfo)
	end
	goRankingMgr.m_oGDRanking.m_oRanking:Traverse(1, nMaxRecords, _fnTraverse)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "CXRankingTJListRet", {tList=tList})
end

--GM重置次数
function CCXData:GMReset(oPlayer)
	local nCharID = oPlayer:GetCharID()
	self.m_tGDTimesMap[nCharID] = 0
	self:AddTimes(oPlayer, self:MaxTimes())
	self:MarkDirty(true)
	oPlayer:Tips("重置次数成功")
end

--GM清除出巡CD
function CCXData:GMClearChuXun(oPlayer)
	local tEtcConf = ctChuXunEtcConf[1]
	local nCharID = oPlayer:GetCharID()
	local tXingGongMap = self.m_tXingGongMap[nCharID]
	for nID, tXingGong in pairs(tXingGongMap) do
		if tXingGong.nCXTime > 0 then
			tXingGong.nCXTime = os.time() - tEtcConf.nCXTime
			self:MarkDirty(true)
		end
	end
end