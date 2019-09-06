--竞技场
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--[[
Comment:
	竞技场状态迁移  准备 -> 开启 -> 结算 -> 准备  (循环)
	在CArena:Tick函数里面的各个调用函数中进行状态间的迁移管理
	可以允许切换到一个未正式开始的赛季，但是赛季状态将是准备状态，不会变成开启状态，除非时间到达赛季开启时间
	不能切换到一个已结束的赛季(即配置的结束时间比当前时间戳小的赛季)
]]



--因为可能触发结算或者其他邮件，竞技场系统，需要在mailmgr模块之前进行停服前的数据处理
function CArena:Ctor()
	self.m_tRoleInfo = {}  --{nRoleID:RoleArenaInfo, ...}
	self.m_tDirtyQueue = CUniqCircleQueue:new() --Push时用RoleID做Key，防止在等待保存过程中，单个玩家数据多次Push，导致多次处理
	self.m_nTimer = nil  --模块全局调度timer

	self.m_nSeason = self:GetArenaSeasonByTime()  -- Load会覆盖，如果原来没数据，即新服第一次启动，没有load，则使用当前查找的这个作为当前赛季ID
	self.m_nSeasonState = gtArenaSeasonState.ePrepare --赛季状态，默认未开启，tick中会自动管理赛季状态
	--self.m_bOpen = true
	self.m_tSwitchSeasonQueue = nil

	self.m_nDailyResetStamp = os.time()
	self.m_bDirty = false

	self.m_nGMSwitchSeason = 0 --用于GM切换指定赛季，不存DB
	self.m_bSwithOpen = false  --GM切换后，新赛季是否马上开启，不存DB

	self.m_oRank = self:CreateNewRankInst()
	self.m_tBattleReqRecord = {}  --{nRoleID:ExpiryStamp, ...} --战斗请求列表

	---------------- DEBUG BEGIN ----------------
	self.m_nSavePrintStamp = 0
	---------------- DEBUG END ------------------
end

--获取当前竞技场赛季
function CArena:GetArenaSeason() return self.m_nSeason end

function CArena:GetSeasonStartTimeByConf(tConf)
	assert(tConf and type(tConf) == "table", "参数错误")
	local nStartStamp = os.MakeTime(tConf.tStartTime[1][1], tConf.tStartTime[1][2], tConf.tStartTime[1][3],
		tConf.tStartTime[1][4], tConf.tStartTime[1][5], tConf.tStartTime[1][6])
	return nStartStamp
end

function CArena:GetSeasonEndTimeByConf(tConf)
	assert(tConf and type(tConf) == "table", "参数错误")
	local nEndStamp = os.MakeTime(tConf.tEndTime[1][1], tConf.tEndTime[1][2], tConf.tEndTime[1][3],
		tConf.tEndTime[1][4], tConf.tEndTime[1][5], tConf.tEndTime[1][6])
	return nEndStamp
end

function CArena:GetSeasonEndCountdownByConf(tConf)
	assert(tConf and type(tConf) == "table", "参数错误")
	local nCountdown = 0	
	local nEndStamp = self:GetSeasonEndTimeByConf(tConf)
	local nCurTime = os.time()
	if nCurTime < nEndStamp then
		nCountdown = nEndStamp - nCurTime
	end
	return nCountdown
end

--根据指定时间获取该时间所属的赛季，主要用于新开的服务器赛季ID初始化，
--已开启了竞技场赛季的服务器，不依据这个来判断，而是直接以服务器记录的赛季ID数据自增管理,检查该赛季是否已结束
function CArena:GetArenaSeasonByTime(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	local tConfTbl = self:GetSeasonConfTbl()
	local tTargetConf = nil
	--不需要判断开始时间，如果开始时间比当前时间戳大，说明处于赛季未正式开启，如果当前时间比当前时间戳小，说明赛季已经开始
	for nSeasonID, tConf in pairs(tConfTbl) do --可能只配置了部分，并不是从1开始，允许策划将已过期不需要的赛季配置删除
		local nEndStamp = self:GetSeasonEndTimeByConf(tConf)
		if nTimeStamp <= nEndStamp then --根据结束时间来确定
			if not tTargetConf then
				tTargetConf = tConf
			elseif self:GetSeasonEndTimeByConf(tTargetConf) > nEndStamp then --找出一个结束时间距离指定时间戳最近的配置
				tTargetConf = tConf
			end
		end
	end
	assert(tTargetConf, "竞技场赛季时间错误，无法找到时间戳对应的赛季，请检查竞技场赛季配置, nTimeStamp:"..nTimeStamp)
	if not tConfTbl[tTargetConf.nSeasonID + 1] or not tConfTbl[tTargetConf.nSeasonID + 2] then --检查后续2个赛季配置是否有正常配置
		for k = 1, 5 do
			LuaTrace(string.format("请注意, 竞技场<%d>赛季将于<%d年%d月%d日%d时%d分%d秒>结束，请检查确认后续赛季配置！！", 
				tTargetConf.nSeasonID,
				tTargetConf.tEndTime[1][1], 
				tTargetConf.tEndTime[1][2], 
				tTargetConf.tEndTime[1][3], 
				tTargetConf.tEndTime[1][4], 
				tTargetConf.tEndTime[1][5],
				tTargetConf.tEndTime[1][6]))
		end
	end
	return tTargetConf.nSeasonID
end

--获取当前赛季结束时间戳
function CArena:GetCurSeasonEndTime()
	local tConf = self:GetSeasonConf()
	assert(tConf, "当前竞技场赛季未配置, SeasonID:"..self.m_nSeason)
	return self:GetSeasonEndTimeByConf(tConf)
end
--获取当前赛季开始时间戳
function CArena:GetCurSeasonStartTime()
	local tConf = self:GetSeasonConf()
	assert(tConf, "当前竞技场赛季未配置, SeasonID:"..self.m_nSeason)
	return self:GetSeasonStartTimeByConf(tConf)
end

function CArena:GetSeasonConfTbl() return ctArenaSeasonConf end
function CArena:GetSeasonConf(nSeasonID) 
	nSeasonID = nSeasonID or self.m_nSeason
	return ctArenaSeasonConf[nSeasonID] 
end
function CArena:GetSeasonState() return self.m_nSeasonState end
function CArena:SetSeasonState(nState) self.m_nSeasonState = nState end
function CArena:IsSwitchSeason() return self.m_nSeasonState == gtArenaSeasonState.eSwitchSeason end
function CArena:IsSeasonOpen() return self.m_nSeasonState == gtArenaSeasonState.eOpen end
--控制开关，便于GM控制和定制开放时间
function CArena:IsOpen() --当前是否开放 bool, sReason
	--[[
	if not self.m_bOpen then
		return false, "竞技场功能已关闭"
	end
	]]
	if self:IsSwitchSeason() then
		return false, "当前正在进行赛季结算，暂不开放"
	end
	if not self:IsSeasonOpen() then
		return false, "当前赛季未开始"
	end
	return true
end



function CArena:GetRankInst() return self.m_oRank end
function CArena:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CArena:IsDirty() return self.m_bDirty end
function CArena:GetRoleArenaInfo(nRoleID) return self.m_tRoleInfo[nRoleID] end
function CArena:IsSysOpen(oRole, bTips) 
	return oRole:IsSysOpen(39, bTips)
end

function CArena:SaveArenaSysData()
	if not self:IsDirty() then
		return
	end
	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local tData = {}
	tData.nSeason = self.m_nSeason
	tData.nSeasonState = self.m_nSeasonState
	--tData.bOpen = self.m_bOpen
	tData.nDailyResetStamp = self.m_nDailyResetStamp

	oDB:HSet(gtDBDef.sSvrArenaDB, "sysdata", cseri.encode(tData))
	self:MarkDirty(false)
end

function CArena:SaveArenaRoleData()
	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	--停服时，迭代查找所有的，防止中间有DB断开，导致有数据没保存到，但被Pop出了脏数据队列
	for k, oRoleArena in pairs(self.m_tRoleInfo) do
		if oRoleArena:IsDirty() then
			local tData = oRoleArena:SaveData() 
			oDB:HSet(gtDBDef.sRoleArenaDB, oRoleArena:GetRoleID(), cseri.encode(tData))
			oRoleArena:MarkDirty(false)
		end
	end
end

function CArena:LoadArenaSysData()
	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oDB:HGet(gtDBDef.sSvrArenaDB, "sysdata")
	if sData ~= "" then
		local tData = cseri.decode(sData)
		self.m_nSeason = tData.nSeason
		self.m_nSeasonState = tData.nSeasonState
		--self.m_bOpen = tData.bOpen
		self.m_nDailyResetStamp = tData.nDailyResetStamp or os.time()
	end
	if self.m_nSeasonState == gtArenaSeasonState.eSwitchSeason then
		if gtArenaSysConf.bSwitchExceptionStart then
			--tick中会尝试根据当前数据重新进行结算
			for k = 1, 5 do
				LuaTrace("请注意，竞技场结算状态不正确，加载时处于赛季结算状态")
			end
		else
			assert(false, "请注意，竞技场结算状态不正确，加载时处于赛季结算状态")
		end
	end
end

--这里依赖全局玩家模块数据加载完成
function CArena:LoadArenaRoleData()
	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local tKeys = oDB:HKeys(gtDBDef.sRoleArenaDB)
	for _, sRoleID in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sRoleArenaDB, sRoleID)
		local tData = cseri.decode(sData)
		local nRoleID = tData.nRoleID
		-- local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		local oRoleArena = CRoleArenaInfo:new(nRoleID)
		oRoleArena:LoadData(tData)
		self.m_tRoleInfo[nRoleID] = oRoleArena
		self:UpdateRankScore(oRoleArena) --重新建立排行榜
		--print("加载玩家竞技场数据成功, nRoleID:"..nRoleID)
	end
end

function CArena:CreateNewRankInst()
	local fnRoleArenaRankCmp = function (tL, tR) -- -1排前面, 1排后面
		if tL.nScore ~= tR.nScore then
			return tL.nScore > tR.nScore and -1 or 1
		end
		if tL.nScoreChangeStamp ~= tR.nScoreChangeStamp then
			return tL.nScoreChangeStamp < tR.nScoreChangeStamp and -1 or 1
		end
		if tL.nRoleID ~= tR.nRoleID then
			return tL.nRoleID < tR.nRoleID and -1 or 1
		end
		return 0
	end
	local oRank = CRBRank:new(fnRoleArenaRankCmp, nil, nil, nil, true)
	return oRank
end

function CArena:GetRoleScore(nRoleID)
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArena then 
		return 0
	end
	return oRoleArena:GetScore()
end

--停服的时候调用
function CArena:SaveData()
	self:ProcArenaSeasonChangeOnClose() --先处理所有未处理完的数据，在这个过程中，会重新产生很多脏数据
	self:SaveArenaSysData()
	self:SaveArenaRoleData() --保存所有玩家单个数据
end

function CArena:LoadData()
	self:LoadArenaSysData()
	self:LoadArenaRoleData() --加载玩家数据，并建立排行榜
end

function CArena:Init()
	self:LoadData()
	self.m_nTimer = GetGModule("TimerMgr"):Interval(1, function () self:Tick() end)
end

function CArena:Release()
	if self.m_nTimer then
		GetGModule("TimerMgr"):Clear(self.m_nTimer)
		self.m_nTimer = nil
	end
	self:SaveData()
end

function CArena:TickSave(nTimeStamp)
	--每x秒保存一次，根据当前需要保存数量自动调整每秒保存的数据量，对数据库写入分布更均匀
	--避免跨天等情况，数据写入高峰，导致服务阻塞
	local nDirtyNum = self.m_tDirtyQueue:Count()
	nTimeStamp = nTimeStamp or os.time()
	if math.abs(nTimeStamp - self.m_nSavePrintStamp) >= 180 then --每3分钟打印一次
		self.m_nSavePrintStamp = nTimeStamp
		print("当前等待保存的<竞技场>数据数量:"..nDirtyNum)
	end

	if nDirtyNum <= 0 then
		return
	end

	local nMaxSaveNum = gtArenaSysConf.nMaxSecSaveNum           --单次保存的最大数量
	local nDefaultSaveNum = gtArenaSysConf.nDefaultSecSaveNum   --默认单次保存数量
	local nTargetTime = gtArenaSysConf.nTargetSaveTime          --全部保存完的目标时间
	local nSaveNum  = nDefaultSaveNum

	local nTargetNum = math.ceil(nDirtyNum / nTargetTime)	
	if nTargetNum > nDefaultSaveNum then --在目标时间无法保存完，需要加快保存速度
		if nMaxSaveNum >= nTargetNum then
			--做一个补偿，在数据较多情况下，比理想情况稍微保存快一点
			local nCompensation = math.ceil(2 * nMaxSaveNum / (math.abs(nMaxSaveNum - nTargetNum) + 1))
			nTargetNum = nTargetNum + nCompensation
		else
			LuaTrace(string.format("\n请注意，当前<竞技场>待保存数据<%d>,\n目标保存速度<%d>,\n已超过预设最大保存速度<%d>\n", 
				nDirtyNum, nTargetNum, nMaxSaveNum))
		end
		nSaveNum = math.max(math.min(nTargetNum, nMaxSaveNum), nDefaultSaveNum)
	end
	
	nSaveNum = math.min(nSaveNum, nDirtyNum) --可能当前脏数据的总数量比默认值低

	local oDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	for i = 1, nSaveNum do
		local oRoleArena = self.m_tDirtyQueue:Head()
		if oRoleArena then
			local tData = oRoleArena:SaveData()
			oDB:HSet(gtDBDef.sRoleArenaDB, oRoleArena:GetRoleID(), cseri.encode(tData))
			oRoleArena:MarkDirty(false)
			--print("保存竞技场数据成功，nRoleID:"..oRoleArena:GetRoleID())
		end
		self.m_tDirtyQueue:Pop()
	end
end

function CArena:CleanExpiryBattleReq(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	local tRemoveList = {}
	for k, v in pairs(self.m_tBattleReqRecord) do --这个列表正常最多只会存在几十个数据
		if v <= nTimeStamp then
			table.insert(tRemoveList, k)
		end
	end
	for k, v in ipairs(tRemoveList) do
		self.m_tBattleReqRecord[v] = nil
	end
end

function CArena:GetRankAppellation(nRank)
	if not nRank or nRank < 1 then 
		return 0
	end
	local tTarCfg = goRankRewardCfg:GetRankRewardConf(5, nRank)
	if not tTarCfg then 
		return 0
	end
	return tTarCfg.nAppellation
end

function CArena:DealSwitchSeason(oRoleArena, nRank)
	assert(oRoleArena and nRank, "参数错误")
	--这里只处理奖励发放，暂时不处理其他的
	--当前只有赛季宝箱需要处理
	oRoleArena:SetArenaRewardState(gtArenaRewardType.eArenaLevelBox, gtArenaRewardState.eAchieved, oRoleArena:GetArenaLevel())
	-- 数据重置在OnSwitchSeasonEnd中处理

	local nRoleID = oRoleArena:GetRoleID()
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local nAppellation = self:GetRankAppellation(nRank)
	if oRole and nAppellation and nAppellation > 0 then 
		local nLastSeasonAppe = oRoleArena.m_nAppellation
		if nLastSeasonAppe > 0 then 
			oRole:RemoveAppellation(nLastSeasonAppe, 0)
		end
		local tAppeData = 
		{
			nOpType = gtAppellationOpType.eAdd, 
			nConfID = nAppellation, 
			tParam = {nArenaSeason = self:GetArenaSeason()}, 
			nSubKey = 0,
		}
		oRole:AppellationUpdate(tAppeData)
		oRoleArena.m_nAppellation = nAppellation
	end
	oRoleArena:MarkDirty(true)
end

function CArena:OnSwitchSeasonEnd() --赛季结算结束
	print("竞技场赛季结算<完成>, 准备初始化新赛季数据")
	self.m_tSwitchSeasonQueue = nil
	local bOpenNow = false --是否马上开启
	if self.m_nGMSwitchSeason > 0 then --GM指定切换的情况下
		self.m_nSeason = self.m_nGMSwitchSeason
		self.m_nGMSwitchSeason = 0
		if self.m_bSwithOpen then
			self.m_bSwithOpen = false
			bOpenNow = true
		end
	else
		self.m_nSeason = self.m_nSeason + 1   --赛季ID自增1
	end
	if bOpenNow then
		self:SetSeasonState(gtArenaSeasonState.eOpen) --将状态直接指定为开启状态
	else
		self:SetSeasonState(gtArenaSeasonState.ePrepare) --将状态切换成下赛季准备状态
	end

	self.m_oRank = self:CreateNewRankInst() --重新引用新的排行榜
	for nRoleID, oRoleArena in pairs(self.m_tRoleInfo) do
		oRoleArena:SeasonReset() --将所有玩家数据置为新赛季
		self:UpdateRankScore(oRoleArena)
	end
	self:MarkDirty(true)
	print("新赛季数据初始化完成")
end

function CArena:ProcArenaSeasonChangeOnClose()
	--如果有外部进程触发服务器关闭，则会调用，结算剩余的所有未完成结算的数据
	if not self:IsSwitchSeason() then
		return
	end
	assert(self.m_tSwitchSeasonQueue, "状态不一致，停服异常，赛季结算状态，结算队列为nil")
	LuaTrace("停服时，竞技场赛季结算未完成，继续结算...")
	while self.m_tSwitchSeasonQueue:Count() > 0 do
		local nRank, nRoleID = self.m_tSwitchSeasonQueue:Pop()
		local oRoleArena = self:GetRoleArenaInfo(nRoleID)
		self:DealSwitchSeason(oRoleArena, nRank)
	end
	self:OnSwitchSeasonEnd()
end

--检查并设置当前赛季是否结束	
function CArena:CheckArenaSeasonEnd(nTimeStamp)
	if not self:IsSeasonOpen() then
		return
	end
	nTimeStamp = nTimeStamp or os.time()
	local nEndTime = self:GetCurSeasonEndTime()
	if nEndTime >= nTimeStamp then
		return
	end
	print("<竞技场> 赛季结束，准备进行赛季结算")
	self:SetSeasonState(gtArenaSeasonState.eSwitchSeason) --切换为赛季结算状态
	self:MarkDirty(true)
end

function CArena:TickArenaSeasonChange()
	if not self:IsSwitchSeason() then
		return
	end
	--避免阻塞其他服务，必须分批次进行，整个服所有参与过竞技场玩法的玩家都要结算，而且结算奖励可能会发送邮件，也会触发数据库写入
	if not self.m_tSwitchSeasonQueue then --nil
		--避免后续修改，结算过程中有其他玩家插入到排行榜中
		print("竞技场开始赛季结算，正在准备结算数据...")
		local oRankInst = self:GetRankInst()
		self.m_tSwitchSeasonQueue = CUniqCircleQueue:new() --应该不会超过10W数据

		-- 直接迭代查询排名，数据较多情况下，性能会比较差，开发机测试，10万数据，循环查询10000次索引，耗时接近460ms
		-- for k, v in pairs(self.m_tRoleInfo) do
		-- 	local nRank = oRankInst:GetRankByKey(k)
		-- 	self.m_tSwitchSeasonQueue:Push(k, nRank)
		-- end

		--依据排行榜优化迭代来结算，可加快执行速度，否则每次查询排名，10万左右数据量，排名数据查询性能相差约10倍
		--GetIndex平均耗时 N*log(N, 2), Traverse,每个节点只会被处理2次,为2N
		--如果出现数据不正确，玩家数据不在排行榜中，可能导致，有玩家数据，无法结算到
		local fnTraverseCallback = function(nDataIndex, nRank, nRoleID, tData) 
			self.m_tSwitchSeasonQueue:Push(nRoleID, nRank)
		end
		oRankInst:TraverseByDataIndex(1, oRankInst:GetCount(), fnTraverseCallback)
		--暂时不考虑，结算过程中，服务器异常关闭的情况(正常关闭，会继续进行结算)
		return --直接退出，如果数据多，这里可能会耗费点时间，下一次tick，再继续结算
	end

	print("竞技场赛季结算中...")
	if self.m_tSwitchSeasonQueue:Count() > 0 then
		--设置单次结算数量, ssdb, set qps网上数据显示4W左右
		local nDefaultSwitchNum = math.min(1000, self.m_tSwitchSeasonQueue:Count())
		--目前只有很简单的逻辑，只关联竞技场宝箱奖励设置，直接设置最大，单个循环处理完
		--local nDefaultSwitchNum = self.m_tSwitchSeasonQueue:Count() --直接设置最大
		for k = 1, nDefaultSwitchNum do
			local nRank, nRoleID = self.m_tSwitchSeasonQueue:Pop()
			local oRoleArena = self:GetRoleArenaInfo(nRoleID)
			self:DealSwitchSeason(oRoleArena, nRank)
		end
		return --直接退出，如果没有数据，下一个循环再执行关闭
	end
	if self.m_tSwitchSeasonQueue:Count() <= 0 then
		self:OnSwitchSeasonEnd()
	end
	self:MarkDirty(true)
end

function CArena:DailyReset(nTimeStamp)
	if self:IsSwitchSeason() then --赛季结算时，不进行日常结算
		return
	end
	nTimeStamp = nTimeStamp or os.time()
	if os.IsSameDay(self.m_nDailyResetStamp, nTimeStamp, 0) then
		return
	end

	print("竞技场每日结算开始...")
	local nStartTime = os.clock()

	local nTotalCount = 0
	local nRewardCount = 0
	local oRankInst = self:GetRankInst()
	local sMailTitle = "竞技场奖励"
	local sMailContentTemplate = "今天你的竞技场奖杯为%d，并获得了数量%d竞技币奖励。请继续加油！" 

	--依据排行榜优化迭代来结算，可加快执行速度，否则每次查询排名，10万左右数据量，排名数据查询性能相差约10倍
	--GetIndex平均耗时 N*log(N, 2), Traverse,每个节点只会被处理2次,为2N
	--如果出现数据不正确，玩家数据不在排行榜中，可能导致，有玩家数据，无法结算到
	local fnTraverseCallback = function(nDataIndex, nRank, nRoleID, tData) 
		local oRoleArena = self:GetRoleArenaInfo(nRoleID)
		if nRank > 0 and oRoleArena:GetDailyBattleCount() >= 3 then --大于3场才给奖励
			local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
			local nLevel = oRole:GetLevel()
			local nArenaCoinNum = gtArenaSysConf.fnDailyArenaCoin(nRank, nLevel, oRoleArena:GetScore())
			local nExtraArenaCoinNum = gtArenaSysConf.fnDailyExtraArenaCoin(nRank)
			nArenaCoinNum = nArenaCoinNum + nExtraArenaCoinNum
			if nArenaCoinNum > 0 then
				local sMailContent = string.format(sMailContentTemplate, oRoleArena:GetScore(), nArenaCoinNum)
				local tMailItemList = {}
				local tMailItem = {}
				tMailItem[1] = gtItemType.eProp
				tMailItem[2] = ctPropConf:GetCurrProp(gtCurrType.eArenaCoin)
				tMailItem[3] = nArenaCoinNum
				table.insert(tMailItemList, tMailItem)
				--发送邮件奖励
				goMailMgr:SendMail(sMailTitle, sMailContent, tMailItemList, nRoleID)
			end
			nRewardCount = nRewardCount + 1
		end
		nTotalCount = nTotalCount + 1
		oRoleArena:DailyReset()
	end
	oRankInst:TraverseByDataIndex(1, oRankInst:GetCount(), fnTraverseCallback)
	
	-- for nRoleID, oRoleArena in pairs(self.m_tRoleInfo) do
	-- 	if oRoleArena:GetDailyBattleCount() >= 3 then --大于3场才给奖励
	-- 		local nRank = oRankInst:GetRankByKey(nRoleID)
	-- 		if nRank > 0 then
	-- 			local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	-- 			local nLevel = oRole:GetLevel()
	-- 			local nArenaCoinNum = gtArenaSysConf.fnDailyArenaCoin(nRank, nLevel, oRoleArena:GetScore())
	-- 			local nExtraArenaCoinNum = gtArenaSysConf.fnDailyExtraArenaCoin(nRank)
	-- 			nArenaCoinNum = nArenaCoinNum + nExtraArenaCoinNum
	-- 			if nArenaCoinNum > 0 then
	-- 				local sMailContent = string.format(sMailContentTemplate, oRoleArena:GetScore(), nArenaCoinNum)
	-- 				local tMailItemList = {}
	-- 				local tMailItem = {}
	-- 				tMailItem[1] = gtItemType.eProp
	-- 				tMailItem[2] = ctPropConf:GetCurrProp(gtCurrType.eArenaCoin)
	-- 				tMailItem[3] = nArenaCoinNum
	-- 				table.insert(tMailItemList, tMailItem)
	-- 				--发送邮件奖励
	-- 				goMailMgr:SendMail(sMailTitle, sMailContent, tMailItemList, nRoleID)
	-- 			end
	-- 			nRewardCount = nRewardCount + 1
	-- 		end
	-- 	end
	-- 	nTotalCount = nTotalCount + 1
	-- 	oRoleArena:DailyReset()
	-- end
	self.m_nDailyResetStamp = nTimeStamp
	self:MarkDirty(true)
	print("竞技场每日结算完成")
	local nEndTime = os.clock()
	local nTimeCost = math.ceil((nEndTime - nStartTime) * 1000)
	local sDebugInfo = string.format("竞技场每日结算共处理<%d>条数据，获得奖励玩家<%d>人，用时<%d>ms", 
		nTotalCount, nRewardCount, nTimeCost)
	print(sDebugInfo)
end

function CArena:CheckArenaSeasonStart(nTimeStamp)
	if self.m_nSeasonState ~= gtArenaSeasonState.ePrepare then --非赛季前准备状态，不检查
		return
	end
	nTimeStamp = nTimeStamp or os.time()
	local nStartTime = self:GetCurSeasonStartTime()
	if nStartTime > nTimeStamp then
		return
	end
	print("<竞技场> 新赛季开始")
	self:SetSeasonState(gtArenaSeasonState.eOpen)
	self:MarkDirty(true)
	--[[
	--新赛季开始，初始化所有旧数据
	self.m_oRank = self:CreateNewRankInst() --重新引用新的排行榜
	for nRoleID, oRoleArena in pairs(self.m_tRoleInfo) do
		oRoleArena:SeasonReset()
		self:UpdateRankScore(oRoleArena)
	end
	]]
end

function CArena:Tick()
	self:DailyReset() --每日奖励结算，放在最开始处理，防止赛季结算或其他将数据清理了

	self:CheckArenaSeasonEnd()  --检查并设置是否赛季结算
	self:TickArenaSeasonChange() --赛季结算，分批次处理，结算完成赛季状态置为下个赛季准备状态

	self:SaveArenaSysData()
	self:TickSave()
	self:CleanExpiryBattleReq()
	
	self:CheckArenaSeasonStart() --检查并设置，是否新赛季开启
end

--给玩家添加竞技场货币
function CArena:AddArenaCoin(oRole, nNum, sReason, fnCallBack)
	assert(oRole and nNum and sReason, "参数错误")
	local nServer = oRole:GetStayServer()
	local nService = oRole:GetLogic()
	local nSession = oRole:GetSession()
	local nRoleID = oRole:GetID()
	if fnCallBack then
		Network:RMCall("AddArenaCoinReq", fnCallBack, nServer, nService, nSession, nRoleID, nNum, sReason)
	else
		Network:RMCall("AddArenaCoinReq", nil, nServer, nService, nSession, nRoleID, nNum, sReason)
	end
end

function CArena:InsertRoleArenaData(oRole) --插入用户竞技场数据
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	--local nRoleConfID = oRole:GetConfID()
	local oRoleArena = CRoleArenaInfo:new(nRoleID)
	self.m_tRoleInfo[nRoleID] = oRoleArena

	local tRankData = oRoleArena:GetRankData()
	self:UpdateRankScore(oRoleArena)

	self:Match(oRoleArena) --创建时进行一次玩家匹配，必须在插入到排行榜之后进行
	oRoleArena:MarkDirty(true) --新创建的，做一次存档
	--print("插入用户竞技场数据, nRoleID:"..nRoleID)
end

--玩家竞技场数据，必须在匹配前，插入到排行榜中 
--bTargetRobot，是否只匹配机器人，GM测试用
function CArena:Match(oRoleArena, bTargetRobot)
	assert(oRoleArena, "参数错误")
	local oRankInst = self:GetRankInst()
	local nRankNum = oRankInst:GetCount()
	assert(nRankNum >= 1, "排行榜数据错误，请检查")
	local nRoleID = oRoleArena:GetRoleID()
	local nRank = oRankInst:GetRankByKey(nRoleID)
	assert(nRank > 0 and nRank <= nRankNum, "Match -> 请注意，玩家数据未插入到排行榜，或者排行榜数据错误")
	local nParamM, nParamN = 0, 0
	if nRank >= 1 and nRank <= 50 then
		nParamM = 10
		nParamN = 20
	elseif nRank >= 51 and nRank <= 100 then
		nParamM = 15
		nParamN = 30
	elseif nRank >= 101 and nRank <= 500 then
		nParamM = 20
		nParamN = 40
	elseif nRank >= 501 and nRank <= 1000 then
		nParamM = 25
		nParamN = 50
	else -- > 1000
		nParamM = 30
		nParamN = 60
	end
	local nRankMin = math.max(nRank - nParamM, 1)
	local nRankMax = math.min(nRank + nParamN, nRankNum)

	local nMatchNum = 4 --总的匹配个数
	local nRoleNum = math.min(nMatchNum, nRankMax - nRankMin)
	local nRobotNum = nMatchNum - nRoleNum
	local tRandList = {} -- {iIndex:nRoleID, ...}1 - 5个元素

	if bTargetRobot then 
		nRoleNum = 0 
		nRobotNum = nMatchNum 
	end

	if nRoleNum > 0 then 
		--给这个玩家匹配竞技场玩家
		local tTempList = {} --当前最大90个数据，没啥影响
		for k = nRankMin, nRankMax do
			if k ~= nRank then
				table.insert(tTempList, k)
			end
		end
		for k = 1, nRoleNum do
			local nIndex = math.random(1, #tTempList)
			local nKey, tData = oRankInst:GetElementByRank(tTempList[nIndex])
			table.insert(tRandList, nKey)
			table.remove(tTempList, nIndex)
		end
	end
	if nRobotNum > 0 then
		local tRobotTbl = ctArenaRobotConf
		local fnGetWeight = function (tNode) return 10 end
		local tResultList = CWeightRandom:Random(tRobotTbl, fnGetWeight, nRobotNum, true)
		if not tResultList or #tResultList ~= nRobotNum then
			assert(false, "匹配机器人随机结果错误")
			return
		end
		for k, v in pairs(tResultList) do
			table.insert(tRandList, v.nID)
		end
	end

	--要求结果随机排序
	local tMatchList = {}
	for k = 1, nMatchNum do
		local nIndex = math.random(1, #tRandList)
		table.insert(tMatchList, tRandList[nIndex])
		table.remove(tRandList, nIndex)
	end
	oRoleArena.m_tMatchRole = tMatchList
	oRoleArena.m_nMatchStamp = os.time()
	oRoleArena:MarkDirty(true)
end

--每日连胜公告
function CArena:TriggerBroadcastByDailyWin(oRoleArena)
	assert(oRoleArena, "参数错误")
	local oRole = goGPlayerMgr:GetRoleByID(oRoleArena:GetRoleID())
	assert(oRole, "数据错误")
	local nWinKeep = oRoleArena:GetDailyWinKeep()
	local sAnnounceTemplate = "%s在竞技场获得%d连胜，所向披靡！"
	--直接用等于判断，避免连胜每次都通告，具体看策划后续要求
	if nWinKeep == gtArenaSysConf.nDailyWinKeepAnnounce then
		local sAnnounceContent = string.format(sAnnounceTemplate, oRole:GetName(), nWinKeep)
		CUtil:SendSystemTalk("系统", sAnnounceContent)
	end
end

function CArena:GetRankByRoleID(nRoleID)
	assert(nRoleID and nRoleID >= 10000, "参数错误")
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	assert(oRoleArena, "玩家竞技场数据不存在")
	return oRoleArena:GetRank()
end

function CArena:GetPBRankDataByRoleID(nRoleID)
	assert(nRoleID and nRoleID >= 10000, "参数错误")
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	assert(oRoleArena, "玩家竞技场数据不存在")
	--return oRoleArena:GetPBRankData()
	local nRank = self:GetRankByRoleID(nRoleID)
	return self:GetPBRankDataByRank(nRoleID, nRank)
end

function CArena:UpdateRankScore(oRoleArena)
	assert(oRoleArena, "参数错误")
	local nRoleID = oRoleArena:GetRoleID()
	local oRankInst = self:GetRankInst()
	--先删除再插入
	oRankInst:Remove(nRoleID)
	local tRankData = oRoleArena:GetRankData()
	oRankInst:Insert(nRoleID, tRankData)

	-- goRankingMgr.m_oArenaRanking:Update(nRoleID, tRankData.nScore)
end

function CArena:OnChallengeEnd(oRoleArena, bWin, nEnemyScore)
	oRoleArena:CountBattle(bWin)
	local nRoleID = oRoleArena:GetRoleID()
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	assert(oRole, "数据错误")
	local nRoleLv = oRole:GetLevel()
	local nRoleExp = nil
	local nPetExp = nil
	local nSilverCoin = nil
	local nArenaCoin = nil
	if bWin then
		nRoleExp = gtArenaSysConf.fnWinRoleExp(nRoleLv)
		nPetExp = gtArenaSysConf.fnWinPetExp(nRoleLv)
		nSilverCoin = gtArenaSysConf.fnWinSilverCoin(nRoleLv)
		nArenaCoin = gtArenaSysConf.nWinArenaCoinNum
		if oRoleArena:GetArenaRewardState(gtArenaRewardType.eDailyFirstWin) == gtArenaRewardState.eNotAchieve then
			oRoleArena:SetArenaRewardState(gtArenaRewardType.eDailyFirstWin, gtArenaRewardState.eAchieved)
		end
		--失败，目前不扣除分数
		local nRoleScore = oRoleArena:GetScore()
		local nAddScore = gtArenaSysConf.fnActiveWinScore(nRoleScore, nEnemyScore)
		oRoleArena:AddScore(nAddScore)
		self:UpdateRankScore(oRoleArena)
	else
		nRoleExp = gtArenaSysConf.fnFailRoleExp(nRoleLv)
		nPetExp = gtArenaSysConf.fnFailPetExp(nRoleLv)
		nSilverCoin = gtArenaSysConf.fnFailSilverCoin(nRoleLv)
		nArenaCoin = gtArenaSysConf.nFailArenaCoinNum
	end
	if oRoleArena.m_nDailyBattleCount >= gtArenaSysConf.nDailyJoinBattleRewardCount then
		if oRoleArena:GetArenaRewardState(gtArenaRewardType.eDailyJoinBattle) == gtArenaRewardState.eNotAchieve then
			oRoleArena:SetArenaRewardState(gtArenaRewardType.eDailyJoinBattle, gtArenaRewardState.eAchieved)
		end
	end
	local tReward = {}
	tReward.nRoleExp = nRoleExp
	tReward.nPetExp = nPetExp
	tReward.nSilverCoin = nSilverCoin
	tReward.nArenaCoin = nArenaCoin
	Network:RMCall("ArenaAddBattleRewardReq", nil, oRole:GetStayServer(), oRole:GetLogic(), 
		oRole:GetSession(), oRole:GetID(), tReward)
	self:TriggerBroadcastByDailyWin(oRoleArena)
end

function CArena:OnDefenceEnd(oRoleArena, bWin, nChallengeScore)
	oRoleArena:CountDefence(bWin)
	if not bWin then --防守失败需要扣除积分
		local nScoreNum = gtArenaSysConf.fnPassiveFailScore(nChallengeScore, oRoleArena:GetScore())
		oRoleArena:AddScore(-nScoreNum)
		self:UpdateRankScore(oRoleArena)
	end
end

function CArena:IsRobot(nID)
	if nID <= gtGDef.tConst.nArenaConfRobotIDMax then
		return true
	end
	return false
end

function CArena:GetRobotConf(nID) 
	return ctArenaRobotConf[nID] 
end

function CArena:GetRobotConf(nRobotID) return ctArenaRobotConf[nRobotID] end

function CArena:GetRobotMatchData(nRobotID)
	assert(nRobotID > 0 and nRobotID < 10000, "参数错误")
	local tRobotConf = CArena:GetRobotConf(nRobotID)
	assert(tRobotConf, "机器人配置不存在")
	local tRetData = {}
	--[[
	message ArenaMatchRoleData
	{
		required int32 nRoleID = 1;          // 玩家ID
		required int32 nGender = 2;          // 性别
		required int32 nSchool = 3;          // 门派
		required string sHeader = 4;         // 头像
		required int32 nLevel = 5;           // 玩家等级
		required int32 nScore = 6;           // 竞技场积分
		required int32 nArenaLevel = 7;      // 竞技场段位
		required string sArenaLevelName = 8; // 段位名称
	}
	]]
	tRetData.nRoleID = nRobotID
	-- tRetData.nRoleConfID = tRobotConf.nRoleConfID
	local tRoleConf = ctRoleInitConf[tRobotConf.nRoleConfID]
	assert(tRoleConf, "玩家初始配置不存在")
	tRetData.nGender = tRoleConf.nGender
	tRetData.nSchool = tRoleConf.nSchool
	tRetData.sHeader = tRoleConf.sHeader
	tRetData.nLevel = tRobotConf.nRobotLv --goServerMgr:GetServerLevel(gnServerID)
	tRetData.nScore = gtArenaSysConf.nDefaultScore
	tRetData.nArenaLevel = CRoleArenaInfo:GetArenaLevelByScore(tRetData.nScore)
	tRetData.sArenaLevelName = ctArenaLevelConf[tRetData.nArenaLevel].sLevelName
	return tRetData
end

function CArena:OnRoleBattleEnd(oRole, nEnemyID, nArenaSeason, bWin)
	if self:GetArenaSeason() ~= nArenaSeason or not self:IsSeasonOpen() then --直接丢弃结果，防止干扰数据
		print("赛季不匹配，战斗结果丢弃")
		return
	end
	-- if bWin and oRole:IsOnline() then 
	-- 	oRole:Tips("战斗胜利")
	-- end
	local nRoleID = oRole:GetID()
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	assert(oRoleArena, "数据错误")
	local nRoleScore = oRoleArena:GetScore()

	local oEnemyArena = nil
	local nEnemyScore = gtArenaSysConf.nDefaultScore
	if not CArena:IsRobot(nEnemyID) then
		oEnemyArena = self:GetRoleArenaInfo(nEnemyID)
		assert(oEnemyArena, "数据错误")
		nEnemyScore = oEnemyArena:GetScore()
	end

	self:OnChallengeEnd(oRoleArena, bWin, nEnemyScore)
	if oEnemyArena then
		self:OnDefenceEnd(oEnemyArena, not bWin, nRoleScore)
	end

	if bWin then --如果胜利，刷新匹配列表
		self:Match(oRoleArena)
		local tData = {}
		tData.bIsHearsay = true
		tData.nKeepTimes = oRoleArena:GetDailyWinKeep()
		Network:RMCall("OnArenaWin", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), tData)
	end
	--[[
	//竞技场战斗结果返回
	message ArenaBattleResultRet
	{
		required int32 nEnemyID = 1;       // 对手ID
		required string sEnemyName = 2;    // 对手名字
		required int32 nEnemyGender = 3;   // 对手性别
		required int32 nEnemySchool = 4;   // 对手门派
		required string sEnemyHeader = 5;  // 对手头像
		required int32 nEnemyLevel = 6;    // 对手等级
		required int32 nEnemyOldScore = 7;    // 对手原来积分
		required int32 nEnemyNewScore = 8;    // 对手当前积分
		required bool bWin = 9;            // 战斗结果
		required bool nOldScore = 10;      // 原积分
		required bool nNewScore = 11;      // 当前积分
		optional ArenaRoleInfoRet tRoleData = 12; //玩家当前的竞技场数据
	}
	]]
	--self:SyncRoleInfo(oRole)
	local tRetData = {}
	tRetData.nEnemyID = nEnemyID
	if CArena:IsRobot(nEnemyID) then
		local tRobotConf = CArena:GetRobotConf(nEnemyID)
		assert(tRobotConf, "机器人配置不存在")
		tRetData.sEnemyName = tRobotConf.sName
		local tRoleConf = ctRoleInitConf[tRobotConf.nRoleConfID]
		assert(tRoleConf, "玩家初始配置不存在")
		tRetData.nEnemyGender = tRoleConf.nGender
		tRetData.nEnemySchool = tRoleConf.nSchool
		tRetData.sEnemyHeader = tRoleConf.sHeader
		tRetData.nEnemyLevel = tRobotConf.nRobotLv --goServerMgr:GetServerLevel(gnServerID)
		tRetData.nEnemyOldScore = gtArenaSysConf.nDefaultScore
		tRetData.nEnemyNewScore = gtArenaSysConf.nDefaultScore
	else
		local oEnemy = goGPlayerMgr:GetRoleByID(nEnemyID)
		assert(oEnemy, "数据错误")
		tRetData.sEnemyName = oEnemy:GetName()
		tRetData.nEnemyGender = oEnemy:GetGender()
		tRetData.nEnemySchool = oEnemy:GetSchool()
		tRetData.sEnemyHeader = oEnemy:GetHeader()
		tRetData.nEnemyLevel = oEnemy:GetLevel()
		tRetData.nEnemyOldScore = nEnemyScore
		tRetData.nEnemyNewScore = oEnemyArena:GetScore()
	end
	tRetData.bWin = bWin
	tRetData.nOldScore = nRoleScore
	tRetData.nNewScore = oRoleArena:GetScore()
	tRetData.tRoleData = oRoleArena:GetPBData()
	oRole:SendMsg("ArenaBattleResultRet", tRetData)
	--print("ArenaBattleResultRet:", tRetData)
	self:SyncRoleInfo(oRole)
end

function CArena:BattleReq(oRole, nTargetID) --必须先调用获取玩家竞技场数据，请求到数据，否则不会创建玩家竞技场数据
	assert(oRole and nTargetID, "参数错误")
	local nRoleID = oRole:GetID()

	local bOpen, sCloseReason = self:IsOpen()
	if not bOpen then
		if sCloseReason then
			oRole:Tips(sCloseReason)
		end
		return
	end
	local oRoleArenaInfo = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArenaInfo then
		oRole:Tips("当前未参与竞技场玩法")
		return
	end

	--因为需要向逻辑服查询玩家当前状态是否正常，防止玩家出现短时连续多次发送请求
	if self.m_tBattleReqRecord[nRoleID] then
		oRole:Tips("操作频繁") --不响应
		return
	end

	if not oRoleArenaInfo:CheckEnemyIDValid(nTargetID) then
		oRole:Tips("目标玩家不合法")
		return
	end

	if oRoleArenaInfo:ChallengeCount() < 1 then
		oRole:Tips("当前挑战次数不足")
		return
	end

	local nTimeStamp = os.time() + 5  --5秒超时
	self.m_tBattleReqRecord[nRoleID] = nTimeStamp

	local fnArenaCheckCallback = function (bRet, sReason)
		if not bRet then
			if sReason then
				oRole:Tips(sReason)
			end
			self.m_tBattleReqRecord[nRoleID] = nil
			return
		end
		if not self.m_tBattleReqRecord[nRoleID] then
			oRole:Tips("请求超时")
			return
		end
		self.m_tBattleReqRecord[nRoleID] = nil

		if not self:IsOpen() then --再次检查下，防止极端情况，rpc调用期间，状态发生了切换
			oRole:Tips("当前未开放")
			return
		end
		--发起战斗请求
		oRoleArenaInfo:AddChallenge(-1) 
		local  tEnemyData = {}
		tEnemyData.nEnemyID = nTargetID
		local tRobotConf = self:GetRobotConf(nTargetID)
		if tRobotConf then 
			tEnemyData.nEnemyLevel = tRobotConf.nRobotLv --goServerMgr:GetServerLevel(gnServerID)
		end
		Network:RMCall("ArenaBattleReq", nil, oRole:GetStayServer(), oRole:GetLogic(), 
			oRole:GetSession(), oRole:GetID(), tEnemyData, self:GetArenaSeason())
	end
	--取玩家当前所在逻辑服
	Network:RMCall("ArenaBattleCheckReq", fnArenaCheckCallback, oRole:GetStayServer(), 
		oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), nTargetID) --需要异步处理,携带nEnemyID
end

------------------------------------------
function CArena:GetRoleArenaDataReq(oRole)
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	if oRoleArena then --已经存在，直接返回
		if #oRoleArena.m_tMatchRole <= 0 then  --赛季结算后，没刷新此数据，新赛季第一次获取，重新匹配下
			self:Match(oRoleArena)
		end
		self:SyncRoleInfo(oRole)
		return
	end

	local fnCheckSysOpenCallback = function (bRet)
		if not bRet then
			oRole:Tips("当前未达到竞技场参与条件")
			return
		end
		--[[
		if self:IsSwitchSeason() then --竞技场结算时，暂时不给玩家插入并返回新数据
			oRole:Tips("当前正在进行竞技场赛季结算，请稍后再试")
			return
		end
		--竞技场如果处于赛季结算状态，是根据缓存数据进行结算的，并不会对新插入数据进行结算
		--结算期间插入的数据，可能赛季等数据状态并不正确，结算完成后，所有数据都会进行统一重置
		]]

		--生成并同步数据
		local oRoleArena = self:GetRoleArenaInfo(nRoleID)
		if not oRoleArena then
			self:InsertRoleArenaData(oRole)
		end
		self:SyncRoleInfo(oRole)
		self:SyncRankData(oRole, 1) --第一次打开，才会进入这里，派发下排行榜数据
	end
	Network:RMCall("ArenaSysOpenCheckReq", fnCheckSysOpenCallback, oRole:GetStayServer(), 
		oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
end


function CArena:SyncRoleInfo(oRole)
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleArenaInfo = self:GetRoleArenaInfo(nRoleID)
	assert(oRoleArenaInfo, "玩家竞技场数据不存在")
	local tRetData = oRoleArenaInfo:GetPBData()
	oRole:SendMsg("ArenaRoleInfoRet", tRetData)
	--如果活动开启时, 玩家没参与竞技场, 则显示的积分0, 后续玩家参加竞技场时
	--同步玩家数据时, 尝试更新下活动竞技场积分, 否则数值会显示不正确
	oRole:UpdateActGTArenaScore() 
end

function CArena:GetPBRankDataByRank(nRoleID, nRank)
	--直接填充nRank值，省去中间根据key值查找rank值的计算
	assert(nRoleID > 0 and nRank > 0, "参数错误")
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	assert(oRoleArena and oRole, "数据错误")
	--[[
	//竞技场排行榜数据
	message ArenaRoleRankData
	{
		required int32 nRoleID = 1;         // 角色ID
		required string sRoleName = 2;      // 角色姓名
		required int32 nGender = 3;         // 性别
		required int32 nSchool = 4;         // 门派
		required string sHeader = 5;        // 头像
		required int32 nLevel = 6;          // 角色等级
		required int32 nScore = 7;          // 积分	
		required int32 nRank = 8;           // 名次
	}
	]]
	local tRetData = {}
	tRetData.nRoleID = nRoleID
	tRetData.sRoleName = oRole:GetName()
	--tRetData.nRoleConfID = oRole:GetConfID()
	tRetData.nGender = oRole:GetGender()
	tRetData.nSchool = oRole:GetSchool()
	tRetData.sHeader = oRole:GetHeader()
	tRetData.nLevel = oRole:GetLevel()
	tRetData.nScore = oRoleArena:GetScore()
	tRetData.nRank = nRank
	return tRetData
end

function CArena:PrintRankData(tData)
	assert(tData, "参数错误")
	print("========== Arena Rank Data DEBGU ==========")
	print("ArenaRankDataRet:")
	print("MaxPageNum:"..tData.nMaxPageNum)
	print("nPageNum:"..tData.nPageNum)
	print("RoleRank:", tData.tRoleRank)
	print("RankPageData:")
	for k, v in ipairs(tData.tRankPageData) do
		print(v)
	end
	print("========== Arena Rank Data DEBGU ==========")
end

function CArena:SyncRankData(oRole, nPageNum)
	assert(oRole and nPageNum > 0, "参数错误")
	if self:IsSwitchSeason() then
		oRole:Tips("当前竞技场赛季结算期间，请稍后再试")
		return
	end
	if gtArenaSysConf.bRankDebug then
		self:DebugSyncRankData(oRole, nPageNum)
		return
	end

	--[[
	//竞技场排行榜数据响应  
	message ArenaRankDataRet    
	{
		required int32 nMaxPageNum = 1;  // 当前排行榜最大页表数量
		required int32 nPageNum = 2;  // 排行榜页表序号
		repeated ArenaRoleRankData tRankPageData = 3;  // 排行榜数据
		optional ArenaRoleRankData tRoleRank = 4; // 角色自己的排行榜数据
	}
	]]
	local nRoleID = oRole:GetID()
	local oRoleArenaInfo = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArenaInfo then
		self:GetRoleArenaDataReq(oRole)
		return
	end
	local oRankInst = self:GetRankInst()


	local nPageDataNum = 30   --默认每页30条数据
	local nRankTotalNum = oRankInst:GetCount()
	local nMaxPageNum = math.ceil(nRankTotalNum / nPageDataNum)

	local tRetData = {}
	tRetData.nMaxPageNum = nMaxPageNum
	tRetData.nPageNum = nPageNum
	tRetData.tRankPageData = {}

	if nMaxPageNum > 0 then
		local nStartDataIndex = nPageDataNum * (nPageNum - 1) + 1
		if nStartDataIndex > nRankTotalNum then
			oRole:Tips("没有更多数据")
			return
		end
		local nEndDataIndex = math.min(nPageDataNum * nPageNum, nRankTotalNum)
		local fnTraverseCallback = function(nDataIndex, nRank, nRoleID, tData) 
			local tPBRankData = self:GetPBRankDataByRank(nRoleID, nRank)
			table.insert(tRetData.tRankPageData, tPBRankData)
		end
		oRankInst:TraverseByDataIndex(nStartDataIndex, nEndDataIndex, fnTraverseCallback)

	end
	local nSelfRank = oRankInst:GetRankByKey(nRoleID)
	local tSelfRankData = self:GetPBRankDataByRank(nRoleID, nSelfRank)
	tRetData.tRoleRank = tSelfRankData
	oRole:SendMsg("ArenaRankDataRet", tRetData)
	--self:PrintRankData(tRetData)
end

function CArena:DebugGetPBRankDataByRank(nRoleID, nRank)
	assert(nRoleID > 0 and nRank > 0, "参数错误")
	local tRetData = {}
	tRetData.nRoleID = nRoleID
	tRetData.sRoleName = "DEBUG"..nRank
	local nRoleConfID = nRank % 10 + 1
	local tRoleConf = ctRoleInitConf[nRoleConfID]
	tRetData.nGender = tRoleConf.nGender
	tRetData.nSchool = tRoleConf.nSchool
	tRetData.sHeader = tRoleConf.sHeader
	tRetData.nLevel = 50
	tRetData.nScore = 1000
	tRetData.nRank = nRank
	return tRetData
end

function CArena:DebugSyncRankData(oRole, nPageNum)
	assert(oRole and nPageNum > 0, "参数错误")
	if self:IsSwitchSeason() then
		oRole:Tips("当前竞技场赛季结算期间，请稍后再试")
		return
	end
	--[[
	//竞技场排行榜数据响应  
	message ArenaRankDataRet    
	{
		required int32 nMaxPageNum = 1;  // 当前排行榜最大页表数量
		required int32 nPageNum = 2;  // 排行榜页表序号
		repeated ArenaRoleRankData tRankPageData = 3;  // 排行榜数据
		optional ArenaRoleRankData tRoleRank = 4; // 角色自己的排行榜数据
	}
	]]
	local nRoleID = oRole:GetID()
	local oRoleArenaInfo = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArenaInfo then
		self:GetRoleArenaDataReq(oRole)
		return
	end
	local oRankInst = self:GetRankInst()


	local nPageDataNum = 30   --默认每页30条数据
	local nRankTotalNum = oRankInst:GetCount()
	local nDebugPageNumMin = 5
	local nMaxPageNum = math.max(math.ceil(nRankTotalNum / nPageDataNum), nDebugPageNumMin)
	local nDebugMaxNum = nDebugPageNumMin * nPageDataNum
	local nEndMax = math.max(nDebugMaxNum, nRankTotalNum)

	local tRetData = {}
	tRetData.nMaxPageNum = nMaxPageNum
	tRetData.nPageNum = nPageNum
	tRetData.tRankPageData = {}

	if nMaxPageNum > 0 then
		local nStartRank = nPageDataNum * (nPageNum - 1) + 1
		if nStartRank > nEndMax then
			oRole:Tips("没有更多数据")
			return
		end
		local nEndRank = math.min(nPageDataNum * nPageNum, nEndMax)
		for i = nStartRank, nEndRank do
			if i > nRankTotalNum then  --假数据
				local nBaseDebugID = 1000000000
				local nDebugRoleID = nBaseDebugID + i
				local tPBRankData = self:DebugGetPBRankDataByRank(nDebugRoleID, i)
				table.insert(tRetData.tRankPageData, tPBRankData)
			else
				local nKey, tRankData = oRankInst:GetElementByRank(i)
				assert(nKey and tRankData, "数据错误")
				local tPBRankData = self:GetPBRankDataByRank(nKey, i)
				table.insert(tRetData.tRankPageData, tPBRankData)
			end
		end
	end
	local nSelfRank = oRankInst:GetRankByKey(nRoleID)
	local tSelfRankData = self:GetPBRankDataByRank(nRoleID, nSelfRank)
	tRetData.tRoleRank = tSelfRankData
	oRole:SendMsg("ArenaRankDataRet", tRetData)
	self:PrintRankData(tRetData)
end

function CArena:FlushMatchReq(oRole)
	assert(oRole, "参数错误")
	if self:IsSwitchSeason() then
		oRole:Tips("当前竞技场赛季结算期间，请稍后再试")
		return
	end
	local nRoleID = oRole:GetID()
	local oRoleArenaInfo = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArenaInfo then
		print("找不到竞技场数据", nRoleID)
		return
	end
	local bUseMoney = false
	if oRoleArenaInfo:GetFreeFlushMatchCount() <= 0 then 
		bUseMoney = true
	end
	-- local nMatchCountdown = oRoleArenaInfo:GetMatchFlushCountdown()
	-- if nMatchCountdown > 0 then
	-- 	oRole:Tips("当前无法刷新，还需等待"..nMatchCountdown.."秒")
	-- 	return
	-- end
	local fnSubCallback = function(bRet)
		if not bRet then 
			oRole:Tips("元宝不足，刷新失败")
			return
		end
		self:Match(oRoleArenaInfo)
		if not bUseMoney then 
			oRoleArenaInfo:AddFreeFlushMatchCount(-1)
		end
		self:SyncRoleInfo(oRole)
	end

	if bUseMoney then
		local tItem = {nType = gtItemType.eCurr, nID = gtCurrType.eAllYuanBao, 
			nNum = ctArenaSysConf.nFlushMatchCost.nVal}
		oRole:SubItemShowNotEnoughTips({tItem}, "竞技场刷新", true, false, fnSubCallback)
	else
		fnSubCallback(true)
	end
end

function CArena:CheckArenaRewardTypeValid(nRewardType)
	for k, v in pairs(gtArenaRewardType) do
		if v == nRewardType then
			return true
		end
	end
	return false
end

function CArena:GetDailyFirstWinRewardList()
	return ctArenaDailyReward[1].tReward
end

function CArena:GetDailyJoinRewardList()
	return ctArenaDailyReward[2].tReward
end

function CArena:GetArenaLevelRewardList(nLevel)
	return ctArenaLevelConf[nLevel].tRewardBox
end

--返回一个tablelist，包含所有掉落id
function CArena:GetRewardByType(nRewardType, nLevel) --nLevel针对赛季宝箱有效
	if nRewardType == gtArenaRewardType.eDailyFirstWin then
		return self:GetDailyFirstWinRewardList(), "竞技场每日首胜奖励"
	elseif nRewardType == gtArenaRewardType.eDailyJoinBattle then
		return self:GetDailyJoinRewardList(), "竞技场每日参与奖励"
	elseif nRewardType == gtArenaRewardType.eArenaLevelBox and nLevel then
		assert(nLevel, "参数错误")
		return self:GetArenaLevelRewardList(nLevel), "竞技场赛季宝箱奖励"
	else
		assert("不合法的参数类型")
	end
end

function CArena:GetArenaReward(oRole, nRewardType)
	assert(oRole, "参数错误")
	if self:IsSwitchSeason() then
		oRole:Tips("当前竞技场赛季结算期间，无法领取")
		return
	end
	if not self:CheckArenaRewardTypeValid(nRewardType) then
		oRole:Tips("不合法的奖励类型")
		return
	end
	local nRoleID = oRole:GetID()
	local oRoleArenaInfo = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArenaInfo then
		print("找不到竞技场数据", nRoleID)
		return
	end
	local nState, nBoxLevel = oRoleArenaInfo:GetArenaRewardState(nRewardType)
	if nState == gtArenaRewardState.eNotAchieve then
		oRole:Tips("当前未达成领取条件")
		return
	elseif nState == gtArenaRewardState.eRecieved then
		oRole:Tips("奖励已领取")
		return
	end

	local tConfRewardList, sReason = self:GetRewardByType(nRewardType, nBoxLevel)
	if #tConfRewardList <= 0 then
		LuaTrace("请注意，奖励列表不存在，已退出")
		return
	end

	--转换下结果
	local tRewardList = {}
	local tAddList = {}
	for k, v in ipairs(tConfRewardList) do
		if v[1] > 0 and v[2] > 0 then
			local tTempAdd = {nType = gtItemType.eProp, nID = v[1], nNum = v[2]}
			--[[
			message ArenaRewardData
			{
				required int32 nRewardID = 1;   // 奖励ID
				required int32 nRewardNum = 2;  // 奖励数量
			}
			]]
			local tTempRet = {nRewardID = v[1], nRewardNum = v[2]}
			table.insert(tAddList, tTempAdd)
			table.insert(tRewardList, tTempRet)
		end
	end

	local fnAddItemCallBack = function (bRet)
		if not bRet then
			LuaTrace("奖励发放失败", nRoleID, nRewardType)
			return
		end
		--更改奖励状态
		oRoleArenaInfo:SetArenaRewardState(nRewardType, gtArenaRewardState.eRecieved)
		local tRetData = {}
		tRetData.nRewardType = nRewardType
		tRetData.tRewardList = tRewardList
		oRole:SendMsg("ArenaRewardReceiveRet", tRetData)
		--print("ArenaRewardReceiveRet:", tRetData)
		self:SyncRoleInfo(oRole)
	end
	if #tAddList > 0 then
		oRole:AddItem(tAddList, sReason, fnAddItemCallBack)
	else
		print("请注意，没有可添加的奖励，已退出")
	end
end

--元宝购买竞技场挑战次数
function CArena:PurchaseChallengeReq(oRole, nAddNum)
	assert(oRole, "参数错误")
	-- nAddNum = 1 --固定1次

	if not nAddNum or nAddNum <= 0 then
		oRole:Tips("非法数据")
		return
	end
	local nRoleID = oRole:GetID()
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArena then
		print("竞技场数据不存在", nRoleID)
		return
	end
	local bCanPurchase, nCanAddCount, nCost = oRoleArena:CheckCanPurchChallenge()
	if not bCanPurchase then
		-- oRole:Tips("今日已达购买上限，请使用竞技令兑换")
		oRole:Tips("今日已达购买上限")
		return
	end
	nAddNum = math.min(nAddNum, nCanAddCount) --修正到当前可购买的最大数量
	assert(nAddNum > 0, "数据错误")
	local nTotalCost = nCost * nAddNum
	local fnCostCallBack = function (bRet)
		if not bRet then
			oRole:YuanBaoTips()
			return
		end
		oRoleArena:AddChallenge(nAddNum)
		oRoleArena.m_nDailyChallPurchCount = oRoleArena.m_nDailyChallPurchCount + nAddNum
		oRoleArena:MarkDirty(true)

		local tRetData = {}
		tRetData.nAddNum = nAddNum
		tRetData.nCurChallenge = oRoleArena.m_nChallenge
		oRole:SendMsg("ArenaAddChallengeRet", tRetData)
		--print("ArenaAddChallengeRet", tRetData)
	end

	local tSubList = {}
	local tCostData = {nType = gtItemType.eCurr, nID = gtCurrType.eAllYuanBao, nNum = nTotalCost}
	table.insert(tSubList, tCostData)
	oRole:SubItem(tSubList, "元宝购买竞技场挑战次数", fnCostCallBack)
end

function CArena:AddChallengePreCheck(oRole)
	assert(oRole, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArena then
		oRole:Tips("请先参与竞技场")
		return false
	end
	--检查是否可以使用元宝购买
	local bCanPurchase = oRoleArena:CheckCanPurchChallenge()
	if bCanPurchase then 
		oRole:Tips("每日元宝购买次数用完后，方可使用竞技令兑换")
		return false
	end
	return true
end

function CArena:AddChallengeReq(oRole, nNum)
	assert(oRole and nNum, "参数错误")
	local nRoleID = oRole:GetID()
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArena then
		oRole:Tips("请先参与竞技场")
		return false
	end
	oRoleArena:AddChallenge(nNum)
	oRole:Tips(string.format("增加挑战次数%d次", nNum))
	--self:SyncRoleInfo(oRole)
	return true
end

function CArena:Online(oRole)
	self:UpdateAppellation(oRole)
end

--只针对在线玩家，更新竞技场称谓
function CArena:UpdateAppellation(oRole)
	if not oRole or not oRole:IsOnline() then 
		return 
	end
	local nRoleID = oRole:GetID()
	local oRoleArena = self:GetRoleArenaInfo(nRoleID)
	if not oRoleArena then 
		return 
	end
	local nAppeConfID = oRoleArena.m_nAppellation
	local tAppeParam = {}
	local nSubKey = 0

	local nServer = oRole:GetStayServer()
	local nService = oRole:GetLogic()
	local nSession = oRole:GetSession()
	local nRoleID = oRole:GetID()
	Network:RMCall("UpdateArenaAppellation", nil, nServer, nService, nSession, nRoleID, nAppeConfID, tAppeParam, nSubKey)
end

function CArena:GMMatchRobot(oRole) 
	if not oRole or not oRole:IsOnline() then 
		return 
	end 
	if not self:IsSysOpen(oRole, true) then 
		return 
	end
	if self:IsSwitchSeason() then
		oRole:Tips("当前正在进行竞技场赛季结算，无法刷新匹配机器人")
		return
	end 
	local oRoleArena = self:GetRoleArenaInfo(oRole:GetID())
	if not oRoleArena then 
		oRole:Tips("请先参与竞技场玩法")
		return 
	end 
	self:Match(oRoleArena, true) 
	self:SyncRoleInfo(oRole)
end
