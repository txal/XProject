--活动管理器

local nAutoSaveTime = 5*60
function CHuoDongMgr:Ctor()
	self.m_nSaveTick = nil 		--保存计时器
	self.m_nMinTick = nil 		--分钟计时器
	self.m_tActivityMap = {} 	--活动映射
	self:Init()
end
 
function CHuoDongMgr:Init()
	self.m_tActivityMap[gtHDDef.eGLHB] = CGLHB:new(gtHDDef.eGLHB) 					--国力皇数榜
	self.m_tActivityMap[gtHDDef.eQMDHB] = CQMDHB:new(gtHDDef.eQMDHB)        		--亲密度皇榜
	self.m_tActivityMap[gtHDDef.eWWHB] = CWWHB:new(gtHDDef.eWWHB)            		--军机处皇榜(宫斗)
	self.m_tActivityMap[gtHDDef.eLMHB] = CLMHB:new(gtHDDef.eLMHB)           		--联盟经验皇榜

	self.m_tActivityMap[gtHDDef.eDayRecharge] = CGDayRecharge:new(gtHDDef.eDayRecharge) --日充值
	self.m_tActivityMap[gtHDDef.eTimeGift] = CTimeGift:new(gtHDDef.eTimeGift) 		--活动礼包
	self.m_tActivityMap[gtHDDef.eLeiDeng] = CGLeiDeng:new(gtHDDef.eLeiDeng) 		--累登活动
	self.m_tActivityMap[gtHDDef.eTimeAward] = CTimeAward:new(gtHDDef.eTimeAward) 	--限时奖励
	self.m_tActivityMap[gtHDDef.eWaBao] = CWaBao:new(gtHDDef.eWaBao) 				--挖宝活动(无邮件)
	self.m_tActivityMap[gtHDDef.eLeiChong] = CGLeiChong:new(gtHDDef.eLeiChong) 		--累充奖励
	self.m_tActivityMap[gtHDDef.eQiFu] = CQiFu:new(gtHDDef.eQiFu) 					--祈福活动(无邮件)

	self.m_tActivityMap[gtHDDef.eTimeDraw] = CTimeDraw:new(gtHDDef.eTimeDraw)		--限时选秀
	self.m_tActivityMap[gtHDDef.eShouLie] = CShouLie:new(gtHDDef.eShouLie) 			--狩猎活动
	self.m_tActivityMap[gtHDDef.eHuaKui] = CHuaKui:new(gtHDDef.eHuaKui) 			--花魁活动
	self.m_tActivityMap[gtHDDef.eDianDeng] = CDianDeng:new(gtHDDef.eDianDeng) 		--点灯活动
	self.m_tActivityMap[gtHDDef.eZaoRenQiangGuo] = CGZaoRenQiangGuo:new(gtHDDef.eZaoRenQiangGuo) --造人强国  
	self.m_tActivityMap[gtHDDef.eShenMiBaoXiang] = CGShenMiBaoXiang:new(gtHDDef.eShenMiBaoXiang) --神秘宝箱
end

--加载数据
function CHuoDongMgr:LoadData()
	print("加载活动数据------")
	for k, v in pairs(self.m_tActivityMap) do
		v:LoadData()
	end

	self:StartTick()
	self:OnMinEvent()
end

--注册定时保存
function CHuoDongMgr:StartTick()
	local nNextMinTime = os.NextMinTime(os.time())
	self.m_nMinTick = goTimerMgr:Interval(nNextMinTime, function() self:OnMinEvent() end)
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

--保存数据
function CHuoDongMgr:SaveData()
	for k, v in pairs(self.m_tActivityMap) do
		v:SaveData()
	end
end

--释放处理
function CHuoDongMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	goTimerMgr:Clear(self.m_nMinTick)
	
	for k, v in pairs(self.m_tActivityMap) do
		v:OnRelease()
	end
end

--分钟计时器
function CHuoDongMgr:OnMinEvent()
	goTimerMgr:Clear(self.m_nMinTick)

	local nNextMinTime = os.NextMinTime(os.time())
    LuaTrace("CHuoDongMgr:OnMinEvent***", os.date("%H:%M:%S", os.time()), nNextMinTime)
	self.m_nMinTick = goTimerMgr:Interval(nNextMinTime, function() self:OnMinEvent() end)

	--更新状态
	for nID, oAct in pairs(self.m_tActivityMap) do
		--为啥要用xpcall呢，因为要防止一个活动出错影响到其他活动的更新
	    xpcall(function() oAct:UpdateState() end, function(sErr) LuaTrace(sErr, debug.traceback()) end)
	end
end

--玩家上线
function CHuoDongMgr:Online(oPlayer)
	for k, v in pairs(self.m_tActivityMap) do
		v:Online(oPlayer)
	end
end

--取活动对象
function CHuoDongMgr:GetHuoDong(nID)
	return self.m_tActivityMap[nID]
end

--GM后台开启活动调用(nExtID:轮次ID, nExtID1:道具/妃子ID)
function CHuoDongMgr:GMOpenAct(nActID, nStartTime, nEndTime, nSubActID, nExtID, nExtID1, nAwardTime)
	assert(nStartTime <= nEndTime, "时间区间非法")
	print("CHuoDongMgr:GMOpenAct***", nActID, nStartTime, nEndTime)
	if not ctHuoDongConf[nActID] then
		return LuaTrace("活动:", nActID, "不存在")
	end
	if not self.m_tActivityMap[nActID] then
		return LuaTrace("活动:", nActID, "未实现")
	end
	if nActID == gtHDDef.eTimeAward then --限时奖励有子活动 
		local nAwardTime = nAwardTime or ctTimeAwardConf[nSubActID].nAwardTime
		self.m_tActivityMap[nActID]:OpenAct(nSubActID, nStartTime, nEndTime, nAwardTime)
		local oSubAct = self.m_tActivityMap[nActID]:GetObj(nSubActID)
		return oSubAct:GetActTime()
	
	elseif nActID == gtHDDef.eTimeDraw then  	--限时选秀活动(nExtID1为特殊妃子ID)
		local nAwardTime = nAwardTime or ctHuoDongConf[nActID].nAwardTime
		self.m_tActivityMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID1)
		return self.m_tActivityMap[nActID]:GetActTime()
	
	elseif nActID == gtHDDef.eTimeGift then  	--礼包活动(nExtID为礼包轮次, nExtID1为礼包物品替换ID)
		local nAwardTime = nAwardTime or ctHuoDongConf[nActID].nAwardTime
		self.m_tActivityMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
		return self.m_tActivityMap[nActID]:GetActTime()
	
	elseif nActID == gtHDDef.eDayRecharge then  --日充活动(nExtID1为日充物品替换ID)
		local nAwardTime = nAwardTime or ctHuoDongConf[nActID].nAwardTime
		self.m_tActivityMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID1)
		return self.m_tActivityMap[nActID]:GetActTime()

	elseif nActID == gtHDDef.eLeiDeng then  	--累登活动(nExtID为累登轮次)
		local nAwardTime = nAwardTime or ctHuoDongConf[nActID].nAwardTime
		self.m_tActivityMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID)
		return self.m_tActivityMap[nActID]:GetActTime()
			
	else
		local nAwardTime = nAwardTime or ctHuoDongConf[nActID].nAwardTime
		self.m_tActivityMap[nActID]:OpenAct(nStartTime, nEndTime, nAwardTime, nExtID, nExtID1)
		return self.m_tActivityMap[nActID]:GetActTime()
	end
end

--取某活动的状态
function CHuoDongMgr:GetActState(nActID, nSubActID)
	if nActID == gtHDDef.eTimeAward then 
		local oSubAct = self.m_tActivityMap[nActID]:GetObj(nSubActID)
		if not oSubAct then
			return 0
		end
		return oSubAct:GetState()
	end
	return self.m_tActivityMap[nActID]:GetState()
end

--循环活动开启
function CHuoDongMgr:HDCirclActOpen(tList)
	local tSuccList = {}
	for _, tData in ipairs(tList) do
		local nIndex = tData.nIndex
		local nActID = tData.nActID
		local nSubActID = tData.nSubActID
		local nExtID = tData.nExtID
		local nExtID1 = tData.nExtID1
		local nBeginTime = os.time()
		local tEndTime = tData.tEndTime
		local nEndTime = nBeginTime+tEndTime[1]*24*3600+tEndTime[2]*3600+tEndTime[3]*60

		local nState = self:GetActState(nActID, nSubActID)
		if nState == CHDBase.tState.eStart or nState == CHDBase.tState.eAward then
			LuaTrace("CHuoDongMgr:HDCirclActOpen开启循环活动失败(活动进行中)", nState, tData)
		else
			local nBeginTime1, nEndTime1, nAwardTime1 = self:GMOpenAct(nActID, nBeginTime, nEndTime, nSubActID, nExtID, nExtID1)
			if nBeginTime1 and nEndTime1 and nAwardTime1 then
				table.insert(tSuccList, {nIndex=nIndex, nBeginTime=nBeginTime1, nEndTime=nEndTime1, nAwardTime=nAwardTime1})
				LuaTrace("CHuoDongMgr:HDCirclActOpen开始循环活动成功", tData)
			else
				LuaTrace("CHuoDongMgr:HDCirclActOpen开始循环活动失败", tData)
			end
		end
	end
	if #tSuccList > 0 then
		Srv2Srv.HDCircleOpenRet(gtNetConf:GlobalService(), 0, tSuccList)
	end
end

goHDMgr = goHDMgr or CHuoDongMgr:new()
