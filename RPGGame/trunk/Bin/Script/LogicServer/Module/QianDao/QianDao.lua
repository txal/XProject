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
	eSigned = 1, 	--可签到
	eFinish = 2, 	--已签
	eBuQian = 3, 	--可补签
}

function CQianDao:Ctor(oRole)
	self.m_oRole = oRole

	--奖励类型，ID，数量，特定VIP等级
	self.m_tSignDay = {}             --月签表{[1]=1,}
	self.m_tTiredSign = {}           --累签表

	self.m_nDayCount = 0  --累计天数
	self.m_nBuQianCount = 0 --补签次数
	self.m_nQDResetTime = os.time()  --月重置时间
end

function CQianDao:LoadData(tData)
	if tData then
		self.m_nDayCount = tData.m_nDayCount
		self.m_nBuQianCount = tData.m_nBuQianCount or 0
		self.m_nQDResetTime = tData.m_nQDResetTime
		self.m_tSignDay = tData.m_tSignDay or {}
		self.m_tTiredSign = tData.m_tTiredSign or {}
	end
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

--上线后
function CQianDao:AfterOnline()
	self:CheckQianDao()
	if not self:IsAlreadyQianDao() then
		self:MonthSignReq()
		self.m_oRole:Tips("自动签到成功")
	end
	self:InfoReq()
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
		self:CheckTriedMailAward()

		self.m_nQDResetTime = os.time()
		self.m_tTiredSign = {}
		self.m_tSignDay = {}
		self.m_nDayCount = 0
		self.m_nBuQianCount = 0
		self.m_nYuanBaoCount = 0
		self:MarkDirty(true)
	end
end

--签到事件
function CQianDao:OnSigned()
	for nID, tDays in ipairs(ctTiredSignConf) do
		if self.m_nDayCount >= tDays.nDays and not self.m_tTiredSign[nID] then
			self.m_tTiredSign[nID] = self.tTriedState.eFeed
			self:MarkDirty(true)
		end
	end
	self:InfoReq()
end

--计算开服时间那天0点时间戳
function CQianDao:GetOpenServerTime()
	local nOpenServerTime = goServerMgr:GetOpenTime(self.m_oRole:GetServer())
	local tOpenServerDay = os.date("*t", nOpenServerTime)
	tOpenServerDay.hour, tOpenServerDay.min, tOpenServerDay.sec = 0, 0, 0
	nOpenServerTime = os.time(tOpenServerDay)
	return nOpenServerTime
end

--取累计签到次数
function CQianDao:GetLeiQianCount()
	return self.m_nDayCount
end

--补签次数
function CQianDao:GetBuQianTimes()
	local nBuQianCount = 0
	local nTotalYuanBao = self.m_oRole.m_oVIP:GetTotalYuanBao()
	for k=#ctBuQianConf, 1, -1 do 
		local tConf = ctBuQianConf[k]
		if nTotalYuanBao > tConf.nYuanBao then 
			nBuQianCount = tConf.nBuQianCount
			break
		end
	end
	nBuQianCount = nBuQianCount + 5 --每个月免费赠送5次补签次数
	local nRemailTimes = math.max(0, nBuQianCount-self.m_nBuQianCount)
	return nRemailTimes
end

-- 补签
function CQianDao:RetroactiveReq(nID)
	self:CheckQianDao()
	local nTarDay = nID
	if self:GetBuQianTimes() <= 0 then 
		return self.m_oRole:Tips("该月补签次数不足")
	end

	--当前时间
	local tDate = os.date("*t", os.time())
	local nDay = tDate.day
	local nMonth = tDate.month
	local nOpenServerTime = self:GetOpenServerTime()		
	if nDay <= nTarDay then
		return self.m_oRole:Tips("无可补签日期")
	end
	if self.m_tSignDay[nTarDay] then
		return self.m_oRole:Tips("今日已经签到")
	end


	--补签nTarDay这一天
	self.m_nDayCount = self.m_nDayCount + 1
	self.m_nBuQianCount = self.m_nBuQianCount + 1
	self.m_tSignDay[nTarDay] = self.tSignState.eFinish
	self:MarkDirty(true)

	local tConf = ctQianDaoAwardConf[nMonth].tDayAward
	local tAward = tConf[nTarDay]
	local nNum = tAward[3]
	local tList = {{nType=tAward[1], nID=tAward[2], nNum=nNum}}
	self.m_oRole:AddItem(tAward[1], tAward[2], nNum, "补签奖励")
	self:OnSigned()
	return tList
end

--月签到
function CQianDao:MonthSignReq()
	self:CheckQianDao()

	if self:IsAlreadyQianDao() then
		return self.m_oRole:Tips("今天已签到过") 
	end

	local tDate = os.date("*t", os.time())
	local nDay = tDate.day
	local nMonth = tDate.month

	self.m_nDayCount = self.m_nDayCount + 1
	self.m_tSignDay[nDay] = self.tSignState.eFinish
	CEventHandler:OnSignIn(self.m_oRole, {})	
	self:MarkDirty(true)

	local tConf = ctQianDaoAwardConf[nMonth].tDayAward       --奖励表
	local tAward = tConf[nDay]
	local nNum = tAward[3]
	local tList = {{nType=tAward[1], nID=tAward[2], nNum=nNum}}
	self.m_oRole:AddItem(tAward[1], tAward[2], nNum, "月签奖励")
	self:OnSigned()
	return tList
end

-- 界面显示
function CQianDao:InfoReq()
	self:CheckQianDao() 
	local tList = {}                         	--月签表
	local tTirt = {}                         	--累签表

	local nMonthDays = os.MonthDays(os.time())  --这个月份的天数
	local tDate = os.date("*t", os.time())
	local nDay = tDate.day 						--日
	local nMonth = tDate.month                  --月份

	local nBuQianCount = self:GetBuQianTimes()    --补签次数
	local nQianDaoState = self.m_tSignDay[nDay] and 0 or 1
	local nTiredSignDays = self:GetLeiQianCount()  	--累签天数
	local nBuQianDays = 0
	for k=1, nDay do 
		tDate.day, tDate.hour, tDate.min, tDate.sec = k, 0, 0, 0 --0点时间
		local nTimeStamp = os.time(tDate)
		local nState = self.m_tSignDay[k] and self.m_tSignDay[k] or self.tSignState.eBuQian
		if k == nDay then 
			nState = self.m_tSignDay[k] or self.tSignState.eSigned
		end
		if nState == self.tSignState.eBuQian then
			nBuQianDays = nBuQianDays + 1
		end
		local tInfo = {nID=k, nState=nState}
		table.insert(tList, tInfo)
	end

	if nBuQianDays > 0 and nQianDaoState == 0 then 
		nQianDaoState = self.tSignState.eBuQian
	end

	for nID, nState in pairs(self.m_tTiredSign) do 
		local tTmp = {nID=nID, nState=nState}
		table.insert(tTirt, tTmp)
	end
	local tMsg = {tList=tList, tTirt=tTirt, nTiredSignDays=nTiredSignDays, nMonthDays=nMonthDays, nMonth=nMonth, nDay=nDay, nBuQianCount=nBuQianCount, nQianDaoState=nQianDaoState}
	self.m_oRole:SendMsg("QDInfoRet", tMsg)
end

--签到奖励
function CQianDao:QianDaoAwardReq(tID)
	local tList = nil
	local tDate = os.date("*t", os.time())
	local nDay = tDate.day
	if nDay == tID[1] then 
		tList = self:MonthSignReq()
	else	
		tList = self:RetroactiveReq(tID[1])
	end
	if not tList then
		return
	end
	-- self.m_oRole:SendMsg("QDAwardRet", {tList=tList})
	self:InfoReq()
end

--累签
function CQianDao:TiredSignAwardReq(nID)
	self:CheckQianDao()
	--达成条件领取
	if self.m_tTiredSign[nID] ~= self.tTriedState.eFeed then
		return self.m_oRole:Tips("未达领取条件") 
	end

	self.m_tTiredSign[nID] = self.tTriedState.eClose
	local tList = {}
	local tAward = ctTiredSignConf[nID].tAward
	for nID, tItem in ipairs(tAward) do 
		table.insert(tList, {nType=gtItemType.eProp, nID=tItem[1], nNum=tItem[2]})
		self.m_oRole:AddItem(gtItemType.eProp, tItem[1], tItem[2], "累签奖励")
	end
	self:MarkDirty(true)
	self:InfoReq()
	return tList
end

--累签邮件奖励
function CQianDao:CheckTriedMailAward()
	local tItemMap = {}
	for nID, nState in pairs(self.m_tTiredSign) do
		if nState == CQianDao.tTriedState.eFeed then
			local tConf = ctTiredSignConf[nID]
			for _, tItem in pairs(tConf.tAward) do
				tItemMap[tItem[1]] = (tItemMap[tItem[1]] or 0) + tItem[2]
			end
			self.m_tTiredSign[nID] = CQianDao.tTriedState.eClose
			self:MarkDirty(true)
		end
	end
	if not next(tItemMap) then
		return
	end
	local tItemList = {}
	for nID, nNum in pairs(tItemMap) do
		table.insert(tItemList, {gtItemType.eProp, nID, nNum})
	end
	GF.SendMail(self.m_oRole:GetServer(), "累天签到奖励", "未领取的累天签到奖励，请注意查收", tItemList, self.m_oRole:GetID())
end