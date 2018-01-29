--小游戏惩治敌酋
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--活动状态
CChengZhiDiQiu.tState = 
{
	eInit = 0,  	--未开始
	ePlaying = 1, 	--进行中
	eEnd = 2, 		--已结束
}

function CChengZhiDiQiu:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self:Init()
end

function CChengZhiDiQiu:Init()
	self.m_nBXTime = 0 	                --使用鞭刑开始时间
	self.m_nZXTime = 0 	                --使用杖刑开始时间
	self.m_nLastTime = 0 		        --上次关闭活动界面时间
	self.m_nReparations = 0             --累积赔款
	self.m_nState = 0                   --开启关闭游戏界面状态(0.打开，1.关闭)
	self.m_nStartTime = 0				--开启时间
	--不保存
	self.m_nLastReportTime = os.time()	--上次上报时间
end

function CChengZhiDiQiu:LoadData(tData)
	if tData then 
		self.m_nBXTime = tData.m_nBXTime
		self.m_nZXTime = tData.m_nZXTime
		self.m_nLastTime = tData.m_nLastTime or 0
		self.m_nReparations = tData.m_nReparations or 0
		self.m_nState = tData.m_nState or 0
		self.m_nStartTime = tData.m_nStartTime or 0
	end
end

function CChengZhiDiQiu:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nBXTime = self.m_nBXTime
	tData.m_nZXTime = self.m_nZXTime
	tData.m_nLastTime = self.m_nLastTime
	tData.m_nReparations = self.m_nReparations
	tData.m_nState = self.m_nState
	tData.m_nStartTime = self.m_nStartTime
	return tData
end

function CChengZhiDiQiu:GetType()
	return gtModuleDef.tChengZhiDiQiu.nID, gtModuleDef.tChengZhiDiQiu.sName
end

--上线
function CChengZhiDiQiu:Online()
	self:SyncInfo()
end

--离线
function CChengZhiDiQiu:Offline()
	self:OffInterfaceReq()
end

--开始活动
function CChengZhiDiQiu:OpenAct()
	print("CChengZhiDiQiu:OpenAct***")
	self:Init()
	self.m_nStartTime = os.time()
	self:MarkDirty(true)
	self:SyncInfo()
end

--关闭界面
function CChengZhiDiQiu:OffInterfaceReq()
	if self.m_nState == 1 then
		self.m_nState = 0
		self.m_nLastTime = os.time()
		self:MarkDirty(true)
	end
end

--取活动时间区间
function CChengZhiDiQiu:GetOpenTime()
	local nStartTime = self.m_nStartTime 
	local nEndTime = os.MakeDayTime(nStartTime, ctPlayTimeEtcConf[1].nOpenDays)
	return nStartTime, nEndTime
end

--取活动状态
function CChengZhiDiQiu:GetState()
	local nStartTime, nEndTime = self:GetOpenTime()
	if os.time() < nStartTime then
		return self.tState.eInit, 0 --未开始
	end
	if os.time() >= nEndTime then
		return self.tState.eEnd, 0 --已结束
	end
	--进行中
	local nRemainTime = nEndTime - os.time()
	return self.tState.ePlaying, nRemainTime
end


--鞭刑效果剩余时间
function CChengZhiDiQiu:BXEffTime()
	local nEffectTime = ctZZDQTypeConf[2].nEff
	local nRemainTime = math.max(0, self.m_nBXTime+nEffectTime-os.time())
	return nRemainTime
end

--杖刑效果剩余时间
function CChengZhiDiQiu:ZXEffTime()
	local nEffectTime = ctZZDQTypeConf[3].nEff
	local nRemainTime = math.max(0, self.m_nZXTime+nEffectTime-os.time())
	return nRemainTime
end

--鞭刑CD剩余时间
function CChengZhiDiQiu:BXCDTime()
	local nCDTime = ctZZDQTypeConf[2].nCD
	local nRemainCD = math.max(0, self.m_nBXTime+nCDTime-os.time())
	return nRemainCD
end

--杖刑CD剩余时间
function CChengZhiDiQiu:ZXCDTime()
	local nCDTime = ctZZDQTypeConf[3].nCD
	local nRemainCD = math.max(0, self.m_nZXTime+nCDTime-os.time())
	return nRemainCD
end

--使用刑罚请求
function CChengZhiDiQiu:UseXFReq(nType)
	assert(nType==1 or nType==2, "刑罚类型错误")
	if self:GetState() == self.tState.ePlaying then
		if nType == 1 then --鞭刑
			if self:BXCDTime() > 0 then
				return self.m_oPlayer:Tips("鞭刑冷却中，不能使用")
			end

		elseif nType == 2 then --杖刑
			if self:ZXCDTime() > 0 then
				return self.m_oPlayer:Tips("杖刑冷却中，不能使用")
			end
		end
		
		--不能同时使用	
		if self:BXEffTime() > 0 or self:ZXEffTime() > 0 then
			return self.m_oPlayer:Tips("不能同时使用杖刑和鞭刑")
		end
		
		if nType == 1 then 
			self.m_nBXTime = os.time()
		elseif nType == 2 then
			self.m_nZXTime = os.time()
		end	
		self:MarkDirty(true)
		--任务
		self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond15, 1)
		self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond12, 1)
	end
	self:SyncInfo()
end

--添加银两
function CChengZhiDiQiu:AddYinLiang(nYinLiang, sReason)
	local nMaxReparations = ctPlayTimeEtcConf[1].nMaxReparations
	if self.m_nReparations >= nMaxReparations then
		return
	end
	local nOrgReparations = self.m_nReparations
	self.m_nReparations = math.min(self.m_nReparations+nYinLiang, nMaxReparations)
	local nRealYinLiang = self.m_nReparations - nOrgReparations
	if nRealYinLiang > 0 then
		self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYinLiang, nRealYinLiang, sReason)
	end
	self:MarkDirty(true)
	return nRealYinLiang
end

function CChengZhiDiQiu:ReportYinLiangReq(nYinLiang, nXFType)
	assert(nYinLiang >= 0)
	assert(nXFType == 0 or nXFType == 1 or nXFType == 2, "刑罚类型错误")

	if self:GetState() == self.tState.ePlaying then
		if self.m_nReparations < ctPlayTimeEtcConf[1].nMaxReparations then
			local nMaxYinLiang = 0 		--可接受的最大银两数
			local nMaxClickPerSec = 20  --每秒点击最大可接受次数
			local nPassSecond = os.time() - self.m_nLastReportTime
			self.m_nLastReportTime = os.time()

			if nXFType == 0 then 
				nMaxYinLiang = (nPassSecond * nMaxClickPerSec * ctZZDQTypeConf[1].nYL)
			elseif nXFType == 1 then --暂时略掉效果判断
				nMaxYinLiang = (nPassSecond * nMaxClickPerSec * ctZZDQTypeConf[2].nYL)
		    elseif nXFType == 2 then --暂时略掉效果判断
				nMaxYinLiang = (nPassSecond * nMaxClickPerSec * ctZZDQTypeConf[3].nYL)
		    end

		    if nYinLiang > nMaxYinLiang then
		    	self.m_oPlayer:Tips("请不要点太快！")
		    	LuaTrace("银两超出最大值，有作弊嫌疑:", self.m_oPlayer:GetName(), nYinLiang, nXFType, nMaxYinLiang, nPassSecond)
		    else
		    	self:AddYinLiang(nYinLiang, "刑罚获得银两")
		    end

		else
			self.m_oPlayer:Tips("皇上, 赔款数额已达上限")

		end

	else
		self.m_oPlayer:Tips("活动已结束")

	end
	self:SyncInfo()
end  

--取下一等级银两
function CChengZhiDiQiu:NextLevelYinLiang()
	local nReparationsMax = 0
	for nID, tConf in ipairs(ctReparationsConf) do 
		nReparationsMax = tConf.nReparations
		if nReparationsMax > self.m_nReparations then
			break
		end
	end
	return nReparationsMax
end

--同步界面信息
function CChengZhiDiQiu:SyncInfo(nGetYinLiang)
	nGetYinLiang = nGetYinLiang or 0
	local nBeginTime, nEndTime = self:GetOpenTime()                   --获取活动开始时间和结束时间
	local nPlayTimeState, nRemainTime = self:GetState()               --获取活动状态和持续时间

	local tMsg = {}
	tMsg.nPlayTimeState = nPlayTimeState
	tMsg.nBeginTime = nBeginTime
	tMsg.nEndTime = nEndTime
	tMsg.nRemainTime = nRemainTime

	if nPlayTimeState == self.tState.ePlaying then
		--更新排行榜
		if self.m_nReparations > 0 then
			goRankingMgr.m_oCZDQRanking:Update(self.m_oPlayer, self.m_nReparations)
		end
		--下一级银两
		local nNextReparations = self:NextLevelYinLiang()

		local nBXRemainCD = self:BXCDTime()        	--获取鞭刑CD时间
		local nZXRemainCD = self:ZXCDTime()        	--获取杖刑CD时间
		local nBXEffTime = self:BXEffTime() 		--鞭刑剩余时间
		local nZXEffTime = self:ZXEffTime() 		--杖刑剩余时间
		tMsg.nReparationsMax = ctPlayTimeEtcConf[1].nMaxReparations
		tMsg.nNextReparations = nNextReparations
		tMsg.nReparations = self.m_nReparations
		tMsg.nBXRemainCD = nBXRemainCD
		tMsg.nZXRemainCD = nZXRemainCD
		tMsg.nBXEffTime = nBXEffTime
		tMsg.nZXEffTime = nZXEffTime
		tMsg.nGetYinLiang = nGetYinLiang
	end

	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "CZDQInfoRet", tMsg)
end

--界面显示
function CChengZhiDiQiu:InfoReq()
	local nGetYinLiang = 0
	if self:GetState() == self.tState.ePlaying then
		self.m_nState = 1 --进入游戏界面设为1状态
		self.m_nLastReportTime = os.time()
		local tConf = ctPlayTimeEtcConf[1]
		local nDouble = tConf.nDouble
		if self.m_nLastTime == 0 then                                 --第一次上线 
			local nBeginTime, nEndTime = self:GetOpenTime()           --获取活动开始时间和结束时间
			nGetYinLiang = (os.time()-nBeginTime)*nDouble
		else
			local tRange = tConf.tRange[1]
			local nPassTime = math.max(0, (os.time() - self.m_nLastTime)) 
			nGetYinLiang = math.max(1, math.floor(math.random(tRange[1], tRange[2])/100*nPassTime*nDouble)) --距离上次关闭活动界面获得的赔款
		end
		self:AddYinLiang(nGetYinLiang, "打开惩治敌酋界面获得银两")
		if self.m_nReparations >= ctPlayTimeEtcConf[1].nMaxReparations then
			self.m_oPlayer:Tips("皇上, 赔款数额已达上限")
		end
	end
	self:SyncInfo(nGetYinLiang)
end
