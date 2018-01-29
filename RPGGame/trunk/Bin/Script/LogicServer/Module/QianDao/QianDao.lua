--签到
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

CQianDao.tTriedState =
{
	eInit = 0,	--初始
	eFeed = 1,	--满足条件未领
	eClose = 2,	--已领取
}

CQianDao.tSignState =
{
	eInit = 0, 		--未签到
	eSigned = 1, 	--已签到
	eBuQian = 2, 	--已补签
}

function CQianDao:Ctor(oPlayer)
	self.m_oPlayer = oPlayer

	--奖励类型，ID，数量，特定VIP等级
	self.m_tSignDay = {}             --月签表{[1]=1,}
	self.m_tTiredSign = {}           --累签表

	self.m_nDayCount = 0  --累计天数
	self.m_nBuQianCount = 0 --补签次数
	self.m_nQDResetTime = os.time()  --月重置时间
end

function CQianDao:LoadData(tData)
	if not tData then
		return
	end
	self.m_nDayCount = tData.m_nDayCount
	self.m_nBuQianCount = tData.m_nBuQianCount or 0
	self.m_nQDResetTime = tData.m_nQDResetTime

	self.m_tSignDay = tData.m_tSignDay
	self.m_tTiredSign = tData.m_tTiredSign
end

function CQianDao:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tSignDay = self.m_tSignDay
	tData.m_tTiredSign = self.m_tTiredSign
	tData.m_nDayCount = self.m_nDayCount
	tData.m_nBuQianCount = self.m_nBuQianCount
	tData.m_nQDResetTime = self.m_nQDResetTime
	return tData
end

function CQianDao:GetType()
	return gtModuleDef.tQianDao.nID, gtModuleDef.tQianDao.sName
end

--玩家上线
function CQianDao:Online()
	--self:CheckRedPoint()
end

-- 检查是否已签到
function CQianDao:IsAlreadyQianDao()
	self:CheckQianDao()
	local tDate = os.date("*t",os.time())
	local nDay = tDate.day
	return (self.m_tSignDay[nDay] and true or false)
end

-- 重置签到
function CQianDao:CheckQianDao()
	if not os.IsSameMonth(os.time(), self.m_nQDResetTime, 0) then
		self.m_nQDResetTime = os.time()
		self.m_tTiredSign = {}
		self.m_tSignDay = {}
		self.m_nDayCount = 0
		self.m_nBuQianCount = 0
		self:MarkDirty(true)
	end
end

--签到事件
function CQianDao:OnSigned()
	for nID, tDays in ipairs(ctTiredSignConf) do
		local nDay = tDays.nDays
		if self.m_nDayCount >= nDay and not self.m_tTiredSign[nID] then
			self.m_tTiredSign[nID] = self.tTriedState.eFeed
			self:MarkDirty(true)
		end
	end
	self:InfoReq()
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond16, 1)
end

-- 补签
function CQianDao:RetroactiveReq(nTarDay)
	self:CheckQianDao()

	--当前时间
	local tDate = os.date("*t", os.time())
	local nDay = tDate.day
	local nMonth = tDate.month

	if nTarDay < 1 or nTarDay >= nDay then
		return self.m_oPlayer:Tips("参数错误")
	end

	if self.m_tSignDay[nTarDay] then
		return self.m_oPlayer:Tips("该天已签到")
	end

	--计算开服时间那天0点时间戳
	local nOpenServerTime = goServerMgr:GetOpenTime()
	local tOpenServerDay = os.date("*t", nOpenServerTime)
	tOpenServerDay.hour, tOpenServerDay.min, tOpenServerDay.sec = 0, 0, 0
	nOpenServerTime = os.time(tOpenServerDay)

	--必须大于开服时间
	tDate.day, tDate.hour, tDate.min, tDate.sec = nTarDay, 0, 0, 0
	local nTimeStamp = os.time(tDate)
	print(nTimeStamp, tOpenServerDay, "******")
	if nTimeStamp < nOpenServerTime then
		return self.m_oPlayer:Tips("参数错误")
	end

	--补签nTarDay这一天
	local nYuanBaoCount = self.m_oPlayer:GetYuanBao()       --获取玩家元宝数
	local nBuQianCount = self.m_nBuQianCount + 1
	local nYuanBao = ctBuQianEtcConf[nBuQianCount].nYuanBao --补签需消耗的元宝数
	if nYuanBaoCount < nYuanBao then 
		return self.m_oPlayer:Tips("元宝不足请充值")
	end

	self.m_nBuQianCount = nBuQianCount
	self.m_nDayCount = self.m_nDayCount + 1
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, "补签消耗元宝数")
	self.m_tSignDay[nTarDay] = self.tSignState.eBuQian
	self:MarkDirty(true)

	local nVIP = self.m_oPlayer:GetVIP()
	local tConf = ctQianDaoAwardConf[nMonth].tDayAward
	local tAward = tConf[nTarDay]
	local nNum = tAward[3]
	if tAward[4] > 0 then
		if nVIP >= tAward[4] then
			nNum = nNum*2
		end
	end
	
	local tList = {{nType=tAward[1], nID=tAward[2], nNum=nNum}}
	self.m_oPlayer:AddItem(tAward[1], tAward[2], nNum, "补签奖励")
	self:OnSigned()
	return tList
end

--累签
function CQianDao:TiredSign(nID)
	self:CheckQianDao()
	--达成条件领取
	if self.m_tTiredSign[nID] ~= self.tTriedState.eFeed then
		return  
	end

	self.m_tTiredSign[nID] = self.tTriedState.eClose
	local tList = {}
	local tAward = ctTiredSignConf[nID].tAward
	for nID, tConf in ipairs(tAward) do 
		local tItem = {nType=tConf[1], nID=tConf[2], nNum=tConf[3]}
		table.insert(tList, tItem)
		self.m_oPlayer:AddItem(tConf[1], tConf[2], tConf[3], "累签奖励")
	end

	self:MarkDirty(true)
	self:InfoReq()
	return tList
end

--月签到
function CQianDao:MonthSignReq()
	self:CheckQianDao()

	if self:IsAlreadyQianDao() then
		return self.m_oPlayer:Tips("今天已签到过") 
	end

	local tDate = os.date("*t", os.time())
	local nDay = tDate.day
	local nMonth = tDate.month

	self.m_nDayCount = self.m_nDayCount + 1
	self.m_tSignDay[nDay] = self.tSignState.eSigned
	self:MarkDirty(true)

	local tConf = ctQianDaoAwardConf[nMonth].tDayAward       --奖励表
	local tAward = tConf[nDay]
	local nVIP = self.m_oPlayer:GetVIP()
	local nNum = tAward[3]
	if tAward[4] > 0 then
		if nVIP >= tAward[4] then 
			nNum = nNum*2
		end
	end

	local tList = {{nType=tAward[1], nID=tAward[2], nNum=nNum}}
	self.m_oPlayer:AddItem(tAward[1], tAward[2], nNum, "月签奖励")
	self:OnSigned()
	return tList
end

-- 界面显示
function CQianDao:InfoReq()
	self:CheckQianDao() 
	--self:CheckRedPoint() --检测小红点

	local nMonthDays = os.MonthDays(os.time())  --这个月份的天数
	local tDate = os.date("*t", os.time())
	local nDay = tDate.day
	local nMonth = tDate.month                  --月份
	local nBuQianCount = self.m_nBuQianCount    --补签次数
	local nQianDaoState = self.m_tSignDay[nDay] and 0 or 1

	local tList = {}                         	--月签表
	local tTirt = {}                         	--累签表
	local nTiredSignDays = self.m_nDayCount  	--累签天数
	
	for nID, nState in pairs(self.m_tSignDay) do 
		local tInfo = {nID=nID, nState=nState}
		table.insert(tList, tInfo)
	end

	for nID, nState in pairs(self.m_tTiredSign) do 
		local tTmp = {nID=nID, nState=nState}
		table.insert(tTirt, tTmp)
	end
	local tMsg = {tList=tList, tTirt=tTirt, nTiredSignDays=nTiredSignDays, nMonthDays=nMonthDays, nMonth=nMonth, nDay=nDay, nBuQianCount=nBuQianCount, nQianDaoState=nQianDaoState}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "QDInfoRet", tMsg)
end

--签到奖励
function CQianDao:QianDaoAwardReq(nSelect, nID)
	local tList = nil
	if nSelect == 1 then               --月签
		tList = self:MonthSignReq()	
	elseif nSelect == 2 then           --补签
		tList = self:RetroactiveReq(nID)
	else 
		tList = self:TiredSign(nID)    --累签
	end

	if tList == nil then
		return
	end
	local tMsg = {tList=tList}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "QDAwardRet", tMsg)
	--self:CheckRedPoint() --检测小红点
end

--检测小红点
function CQianDao:CheckRedPoint()
	if not self:IsAlreadyQianDao() then
		return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eQianDao, 1)
	end
	for k, v in pairs(self.m_tTiredSign) do
		if v == self.tTriedState.eFeed then
			return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eQianDao, 1)
		end
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eQianDao, 0)
end