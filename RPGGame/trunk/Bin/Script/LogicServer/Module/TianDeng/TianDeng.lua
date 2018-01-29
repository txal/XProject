--天灯祈福
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--预处理表
local function _PreProcessConf()
	local nTotalW, nPreW = 0, 0
	for nIndex, tConf in ipairs(ctTDQFAwardConf) do 
		tConf.nMinW = nPreW + 1
		tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
		nPreW = tConf.nMaxW
		nTotalW = nTotalW + tConf.nWeight
	end
	ctTDQFAwardConf.nTotalW = nTotalW
end
_PreProcessConf()

function CTianDeng:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nCDTime = 0
	self.m_nUseTimes = 0
	self.m_nResetTime = 0
	self.m_nTick = nil
end

function CTianDeng:LoadData(tData)
	if not tData then
		return
	end
	self.m_nCDTime = tData.m_nCDTime
	self.m_nUseTimes = tData.m_nUseTimes
	self.m_nResetTime = tData.m_nResetTime
end

function CTianDeng:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nCDTime = self.m_nCDTime
	tData.m_nUseTimes = self.m_nUseTimes
	tData.m_nResetTime = self.m_nResetTime
	return tData
end

function CTianDeng:GetType()
	return gtModuleDef.tTianDeng.nID, gtModuleDef.tTianDeng.sName
end

function CTianDeng:Online()
	self:TDQFInfoReq(true)
	self:CheckCDTimer()
end

function CTianDeng:Offline()
	goTimerMgr:Clear(self.m_nTick)
	self.m_nTick = nil
end

--注册新CD计时器
function CTianDeng:CheckCDTimer()
	goTimerMgr:Clear(self.m_nTick)
	self.m_nTick = nil

	local nCDTime = self.m_nCDTime - os.time()
	if nCDTime <= 0 then
		return
	end

	self.m_nTick = goTimerMgr:Interval(nCDTime, function() self:OnCDTimer() end)
end

--CD计时器到时
function CTianDeng:OnCDTimer()
	self:TDQFInfoReq()
	self:CheckCDTimer()
end

function CTianDeng:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nResetTime, 5*3600) then
		self.m_nCDTime = 0
		self.m_nUseTimes = 0
		self.m_nResetTime = os.time()
		self:MarkDirty(true)
	end
end

function CTianDeng:CheckOpen(bTips)
	local nChapter = ctTDQFEtcConf[1].nOpenChapter
	if not self.m_oPlayer.m_oDup:IsChapterPass(nChapter) then
		if bTips then
			self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
		end
		return
	end	
	return true
end

function CTianDeng:TDQFInfoReq(bOnline)
	if not self:CheckOpen(not bOnline) then
		return
	end
	self:CheckReset()
	local tMsg = {
		nCDTime = math.max(0, self.m_nCDTime-os.time())	,
		nRemainTimes = ctTDQFEtcConf[1].nDailyTimes - self.m_nUseTimes,
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "TDQFInfoRet", tMsg)
end

function CTianDeng:TDQFReq(bUserProp)
	if not self:CheckOpen(true) then
		return
	end

	self:CheckReset()
	if self.m_nUseTimes >= ctTDQFEtcConf[1].nDailyTimes then
		return self.m_oPlayer:Tips("剩余次数不足，请明日再来")
	end

	if bUserProp then
		if self.m_oPlayer:GetItemCount(gtItemType.eProp, ctTDQFEtcConf[1].nPropID) <= 0 then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(ctTDQFEtcConf[1].nPropID)))
		end
		self.m_oPlayer:SubItem(gtItemType.eProp, ctTDQFEtcConf[1].nPropID, 1, "天灯祈福")
		self.m_nCDTime = 0
		self:MarkDirty(true)
		self:TDQFInfoReq()
		self.m_oPlayer:Tips("清除冷却成功")
		return
	end

	if os.time() < self.m_nCDTime then
		return self.m_oPlayer:Tips("冷却时间中")
	end

	self.m_nCDTime = os.time() + ctTDQFEtcConf[1].nCDTime
	self.m_nUseTimes = self.m_nUseTimes + 1
	self:MarkDirty(true)
	self:CheckCDTimer()

	local tAward = {}
	local nRnd = math.random(1, ctTDQFAwardConf.nTotalW)
	for _, tConf in pairs(ctTDQFAwardConf) do
		if type(tConf) == "table" then
			if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
				table.insert(tAward, {nType=tConf.nType, nID=tConf.nID, nNum=tConf.nNum})
				self.m_oPlayer:AddItem(tConf.nType, tConf.nID, tConf.nNum, "天灯祈福")
				break
			end
		end
	end

	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "TDQFRet", {tAward=tAward})
	self:TDQFInfoReq()

	--成就	
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond22, 1)
	--任务
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond21, 1)
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond38, 1)
end

--GM重置
function CTianDeng:GMReset()
	self.m_nResetTime = 0
	self:CheckReset()
	self:CheckCDTimer()
end
