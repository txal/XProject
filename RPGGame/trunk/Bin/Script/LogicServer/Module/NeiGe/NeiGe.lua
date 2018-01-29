--兴圣宫绿篱(资产经营)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--库房类型
--名字
CNeiGe.tName = 
{
	[1] = "银两",
	[2] = "文化",
	[3] = "兵力",
}

local nRecoverTime = ctJLDEtcConf[1].nNGRecTime --次数恢复间隔
local nMinusYuanBao = ctJLDEtcConf[1].nNGMinPerYB --X分钟1元宝
function CNeiGe:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tCDTimeList = {{}, {}, {}} --每次冷却单独计算
	self.m_tRemainTime = {self:MaxTimes(1), self:MaxTimes(2), self:MaxTimes(3)}
	self.m_tRecoverTick = {}
end

function CNeiGe:GetType()
	return gtModuleDef.tNeiGe.nID, gtModuleDef.tNeiGe.sName
end

function CNeiGe:LoadData(tData)
	if tData then
		self.m_tCDTimeList = tData.m_tCDTimeList or self.m_tCDTimeList
		self.m_tRemainTime = tData.m_tRemainTime or self.m_tRemainTime
	else
		self:MarkDirty(true) --要保存出初数据(新号)
	end
end

function CNeiGe:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tCDTimeList = self.m_tCDTimeList
	tData.m_tRemainTime = self.m_tRemainTime
	return tData
end

--玩家上线
function CNeiGe:Online()
	self:OfflineRecover() 	--计算离线恢复
	self:CheckRedPoint() 	--检测小红点
end

--玩家下线
function CNeiGe:Offline()
	for _, v in pairs(self.m_tRecoverTick or {}) do
		goTimerMgr:Clear(v)
	end
	self.m_tRecoverTick = {}
end

--计算离线恢复的次数
function CNeiGe:OfflineRecover()
	local nTimeNow = os.time()
	for k = 1, 3 do
		self:CheckRecover(k)
	end
end

--检测恢复
function CNeiGe:CheckRecover(nType)
	local nNowSec = os.time()
	local tCDList = self.m_tCDTimeList[nType]

	local tRemainList = {}
	for _, nTimes in ipairs(tCDList) do
		if nTimes > nNowSec then
			table.insert(tRemainList, nTimes)
		end
	end

	if #tRemainList ~= #tCDList then
		self.m_tCDTimeList[nType] = tRemainList
		self:MarkDirty(true)
		--不能超过上限
		local nMaxRecover = self:MaxTimes(nType) - self.m_tRemainTime[nType]
		local nRecoverTimes = math.min(nMaxRecover, #tCDList-#tRemainList) 
		if nRecoverTimes > 0 then
			self:AddTimes(nType, nRecoverTimes, "恢复次数")
		end
		self:UpdateRecoverTimer(nType)
	end
end

--更新次数计时器
function CNeiGe:UpdateRecoverTimer(nType)
	goTimerMgr:Clear(self.m_tRecoverTick[nType])
	self.m_tRecoverTick[nType] = nil
	
	local nCDTime = self:GetCDTime(nType)
	if nCDTime > 0 then
		self.m_tRecoverTick[nType] = goTimerMgr:Interval(nCDTime, function()
			goTimerMgr:Clear(self.m_tRecoverTick[nType])
			self.m_tRecoverTick[nType] = nil
			self:CheckRedPoint()
		end)
	end
end

--经营次数上限
function CNeiGe:MaxTimes(nType)
	local nLevel = self.m_oPlayer:GetLevel()
	local tConf = assert(ctLevelConf[nLevel])
	local tTimes = {tConf.nYLTimes, tConf.nLCTimes, tConf.nBLTimes}
	local nMaxTimes = tTimes[nType]
	return nMaxTimes
end

--取剩余次数
function CNeiGe:RemainTimes(nType)
	self:CheckRecover(nType)
	return self.m_tRemainTime[nType]
end

--增加次数
function CNeiGe:AddTimes(nType, nTimes, sReason)
	self.m_tRemainTime[nType] = math.min(nMAX_INTEGER, math.max(0, self.m_tRemainTime[nType]+nTimes))
	self:MarkDirty(true)
	local nEventID = nTimes > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eNeiGeTimes, math.abs(nTimes), self:RemainTimes(nType))
	self:CheckRedPoint() --检测小红点
end

--取冷却时间
function CNeiGe:CDTime(nType)
	self:CheckRecover(nType)
	local tCDList = self.m_tCDTimeList[nType]
	if #tCDList <= 0 then return 0 end
	local nCDTime = tCDList[1]
	return (nCDTime-os.time())
end

--每次经营收益
function CNeiGe:CollectCount(nType)
	local tAttr = self.m_oPlayer:GetAttr()
	local nCount = tAttr[nType]
	return nCount
end

--取冷却时间
function CNeiGe:GetCDTime(nType)
	local tAttr = self.m_oPlayer:GetAttr()
	local nCDTime = math.min(math.floor(tAttr[1]/30000)+1, 30)*60
	return nCDTime
end

--添加冷却时间
function CNeiGe:AddCDList(nType, nTimes, bOneKey)
	self:AddTimes(nType, -nTimes, bOneKey and "一键经营" or "经营")

	local nRemainTimes = self:RemainTimes(nType)
	local tCDList = self.m_tCDTimeList[nType]
	for k = 1, nTimes do
		if #tCDList+nRemainTimes >= self:MaxTimes(nType) then
			break
		end
		local nCDTime = self:GetCDTime(nType)
		local nPreCD = tCDList[#tCDList] or os.time()
		table.insert(tCDList, nPreCD+nCDTime)
	end
	self:MarkDirty(true)
	self:UpdateRecoverTimer(nType)
end

--移除冷却时间
function CNeiGe:DelCDList(nType)
	local tCDList = self.m_tCDTimeList[nType]
	if #tCDList <= 0 then return end

	local nCDTime = table.remove(tCDList, 1)
	local nIntval = nCDTime - os.time()
	for k = 1, #tCDList do
		tCDList[k] = tCDList[k] - nIntval
	end
	self:MarkDirty(true)
	--不能超过上限
	if self.m_tRemainTime[nType] < self:MaxTimes(nType) then
		self:AddTimes(nType, 1, "经营加速")
	end
	self:UpdateRecoverTimer(nType)
end

--银两
function CNeiGe:CollectYL(nTimes, bOneKey)
	if nTimes <= 0 then
		return
	end
	if self:RemainTimes(1) < nTimes then
		return self.m_oPlayer:Tips("经营次数不足")
	end

	local nZhuFu = self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eCYHT)
	if nZhuFu <= 0 then nZhuFu = 1 end 	--神迹祝福

	local nCount = 0
	local nRawCount = self:CollectCount(1)
	if nTimes == 1 then
		nCount = nRawCount*nZhuFu
	else --1键经营的话只有1次触发神迹
		nCount = nRawCount*nZhuFu + (nTimes-1)*nRawCount
	end

	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYinLiang, nCount, "资产经营")
	--添加冷却时间
	self:AddCDList(1, nTimes, bOneKey)
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond7, nTimes)
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond4, nTimes)
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond6, nTimes)
	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eJYYL, nTimes)
	return true
end

--文化
function CNeiGe:CollectWH(nTimes, bOneKey)
	if nTimes <= 0 then
		return self.m_oPlayer:Tips("没有可经营次数")
	end
	if self:RemainTimes(2) < nTimes then
		return self.m_oPlayer:Tips("经营次数不足")
	end
	local nCount = self:CollectCount(2) * nTimes
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWenHua, nCount, "资产经营")
	--添加冷却时间
	self:AddCDList(2, nTimes, bOneKey)
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond8, nTimes)
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond5, nTimes)
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond7, nTimes)
	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eJYWH, nTimes)
	return true
end

--兵力
function CNeiGe:CollectBL(nTimes, bOneKey)
	if nTimes <= 0 then
		return
	end
	if self:RemainTimes(3) < nTimes then
		return self.m_oPlayer:Tips("经营次数不足")
	end
	local nCount = self:CollectCount(3) * nTimes
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eBingLi, nCount, "资产经营")
	--添加冷却时间
	self:AddCDList(3, nTimes, bOneKey)
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond9, nTimes)
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond6, nTimes)
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond8, nTimes)
	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eJYBL, nTimes)
	return true
end

--加速
function CNeiGe:CancelCD(nType)
	local nRemainTimes = self:RemainTimes(nType)
	if nRemainTimes > 0 then
		return self.m_oPlayer:Tips("还有次数无需加速")
	end
	local nCDTime = self:CDTime(nType)
	local nYuanBao = math.ceil(nCDTime / (nMinusYuanBao*60))
	if self.m_oPlayer:GetYuanBao() < nYuanBao then
		return self.m_oPlayer:YBDlg()
	end
	local sReason = CNeiGe.tName[nType]
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, sReason.."经营加速")
	self:DelCDList(nType)
	self:MarkDirty(true)
	return true
end

--界面信息同步
function CNeiGe:SyncInfo()
	local tCurr = {self.m_oPlayer:GetYinLiang(), self.m_oPlayer:GetWenHua(), self.m_oPlayer:GetBingLi()} --当前库存
	local tRemTimes = {self:RemainTimes(1), self:RemainTimes(2), self:RemainTimes(3)} --剩余次数
	local tMaxTimes = {self:MaxTimes(1), self:MaxTimes(2), self:MaxTimes(3)} --最大次数
	local tCDTime = {self:CDTime(1), self:CDTime(2), self:CDTime(3)} --冷却时间
	local tCollectCount = {self:CollectCount(1), self:CollectCount(2), self:CollectCount(3)} --效果
	local tMsg = {
		tCollectCount = tCollectCount,
		tRemTimes = tRemTimes,
		tMaxTimes = tMaxTimes,
		tCDTime = tCDTime,
		tCurr = tCurr,
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "NeiGeInfoRet", tMsg)
end

--经营请求
function CNeiGe:CollectReq(nType)
	assert(nType >= 1 and nType <= 3)
	self:CheckRecover(nType)

	local bRet = false
	if nType == 1 then
		bRet = self:CollectYL(1)
	elseif nType == 2 then
		bRet = self:CollectWH(1)
	elseif nType == 3 then
		bRet = self:CollectBL(1)
	end
	if bRet then
		self:SyncInfo()
	end
end

--1键经营请求
function CNeiGe:OneKeyCollectReq(nType)
	assert(nType >= 0 and nType <= 3, "类型错误")

	local bRes = false
	if nType == 0 then
		local nRemainTimes = self:RemainTimes(1)
		local bYLRes = self:CollectYL(nRemainTimes, true)
		bRes = bRes or bYLRes

		local nRemainTimes = self:RemainTimes(2)
		local bWHRes = self:CollectWH(nRemainTimes, true)
		bRes = bRes or bWHRes

		local nRemainTimes = self:RemainTimes(3)
		local bBLRes = self:CollectBL(nRemainTimes, true)
		bRes = bRes or bBLRes

	elseif nType == 1 then
		local nRemainTimes = self:RemainTimes(1)
		bRes = self:CollectYL(nRemainTimes, true)

	elseif nType == 2 then
		local nRemainTimes = self:RemainTimes(2)
		bRes = self:CollectWH(nRemainTimes, true)

	elseif nType == 3 then
		local nRemainTimes = self:RemainTimes(3)
		bRes = self:CollectBL(nRemainTimes, true)

	end

	if bRes then
		self:SyncInfo()
		--任务
		-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond3, 1)
	end
end

--加速请求
function CNeiGe:CancelCDReq(nType)
	self:CheckRecover(nType)
	if self:CancelCD(nType) then
		self:SyncInfo()
	end
end

--恢复经营次数请求
function CNeiGe:NGRecoverReq(nType, nNum)
	if self:RemainTimes(nType) > 0 then
		return self.m_oPlayer:Tips("当前有次数不能恢复")
	end
	nNum = math.min(nNum, self:MaxTimes(nType))
	local nCurrNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, ctJLDEtcConf[1].nNGPropID)
	if nNum > nCurrNum then
		return self.m_oPlayer:Tips("经营令不足")
	end
	self.m_oPlayer:SubItem(gtItemType.eProp, ctJLDEtcConf[1].nNGPropID, nNum, "经营令恢复次数")
	self:AddTimes(nType, nNum, "经营令恢复次数")
	self.m_oPlayer:Tips("经营次数+"..nNum)
	self:SyncInfo()
end

--一键恢复经营次数请求
function CNeiGe:NGOneKeyRecoverReq()
	local nCount = 0
	for k = 1, 3 do
		local nRemainTimes = self:RemainTimes(k)
		if nRemainTimes == 0 then
			local nMaxNum = self:MaxTimes(k)
			local nCurrNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, ctJLDEtcConf[1].nNGPropID)
			local nRecNum = math.min(nMaxNum, nCurrNum)
			if nRecNum <= 0 then
				self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(ctJLDEtcConf[1].nNGPropID)))
				break
			end
			self.m_oPlayer:SubItem(gtItemType.eProp, ctJLDEtcConf[1].nNGPropID, nRecNum, "经营令恢复次数")
			self:AddTimes(k, nRecNum, "经营令恢复次数")
			self.m_oPlayer:Tips(string.format("%s经营次数+%d", CNeiGe.tName[k], nRecNum))
			nCount = nCount + 1
		end
	end
	if nCount > 0 then
		self:SyncInfo()
	else
		self.m_oPlayer:Tips("没有经营次数才可恢复")
	end
end

--检测小红点
function CNeiGe:CheckRedPoint()
	print("CNeiGe:CheckRedPoint***")
	for nType = 1, 3 do 
		if self:RemainTimes(nType) > 0 then
			return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eNeiGe, 1)
		end
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eNeiGe, 0)
end

--国家等阶变化
function CNeiGe:OnLevelChange()
	for k = 1, 3 do
		self:CheckRecover(k)
		local nMaxTimes = self:MaxTimes(k)
		local nRemainTimes = self:RemainTimes(k)
		local nTmpRemainTimes = nMaxTimes - #self.m_tCDTimeList[k]
		if nRemaintTimes ~= nTmpRemainTimes then
			self.m_tRemainTime[k] = nTmpRemainTimes
			self:MarkDirty(true)
		end
	end
end
