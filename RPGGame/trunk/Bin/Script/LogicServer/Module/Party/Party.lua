--宴会模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--兑换预处理
local function PreProccessExchange()
	local nTotalW, nPreW = 0, 0
	for nIndex, tConf in ipairs(ctPartyExchangeConf) do
		tConf.nMinW = nPreW + 1
		tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
		nPreW = tConf.nMaxW
		nTotalW = nTotalW + tConf.nWeight
	end
	ctPartyExchangeConf.nTotalW = nTotalW
end
PreProccessExchange()

function CParty:Ctor(oPlayer)
	self.m_oPlayer = oPlayer

	self.m_nJoinTimes = 0 			--参加宴会次数
	self.m_nOpenTimes = 0 			--开启宴会次数
	self.m_nResetTime = os.time()	--重置时间

	self.m_tGoodsList = {} 			--物品列表
	self.m_nRefreshTimes = 0 		--刷新次数

	self.m_nScore = 0 	--积分
	self.m_nActive = 0 	--活跃

	--不保存
	self.m_nHourTick = nil
end

function CParty:GetType()
	return gtModuleDef.tParty.nID, gtModuleDef.tParty.sName
end

function CParty:LoadData(tData)
	if not tData then
		return
	end

	self.m_nOpenTimes = tData.m_nOpenTimes
	self.m_nJoinTimes = tData.m_nJoinTimes
	self.m_nResetTime = tData.m_nResetTime

	self.m_tGoodsList = tData.m_tGoodsList
	self.m_nRefreshTimes = tData.m_nRefreshTimes

	self.m_nScore = tData.m_nScore
	self.m_nActive = tData.m_nActive
end

function CParty:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nOpenTimes = self.m_nOpenTimes or 0
	tData.m_nJoinTimes = self.m_nJoinTimes
	tData.m_nResetTime = self.m_nResetTime

	tData.m_tGoodsList = self.m_tGoodsList
	tData.m_nRefreshTimes = self.m_nRefreshTimes

	tData.m_nScore = self.m_nScore
	tData.m_nActive = self.m_nActive
	return tData
end

--玩家上线
function CParty:Online()
	if #self.m_tGoodsList <= 0 or not self.m_tGoodsList[1].nAutoIndex then
		self:RefreshGoods()
	end
	self:RegisterHourTimer()
end

--玩家下线
function CParty:Offline()
	self:CancelHourTimer()
end

function CParty:CancelHourTimer()
	goTimerMgr:Clear(self.m_nHourTick)
	self.m_nHourTick = nil
end

function CParty:RegisterHourTimer()
	self:CancelHourTimer()
	local nHourTime = os.NextHourTime(os.time())
	self.m_nHourTick = goTimerMgr:Interval(nHourTime, function() self:OnHourTimer() end)
end

--每整小时执行
function CParty:OnHourTimer()
	self:RegisterHourTimer()
	local tDate = os.date("*t", os.time())
	local tConf = ctPartyEtcConf[1]
	local tRefreshHour = tConf.tRefreshHour[1]
	for _, nHour in ipairs(tRefreshHour) do
		if tDate.hour == nHour then
			self:RefreshGoods()
			break
		end
	end
end

--重置次数
function CParty:CheckReset()
	if not os.IsSameDay(self.m_nResetTime, os.time(), 0) then
		self.m_nOpenTimes = 0
		self.m_nJoinTimes = 0
		self.m_nRefreshTimes = 0
		self.m_nResetTime = os.time()
		self:MarkDirty(true)
	end
end

--剩余赴宴次数
function CParty:GetRemainTimes()
	self:CheckReset()
	return ctPartyEtcConf[1].nJoinTimes - self.m_nJoinTimes
end

--最大赴宴次数
function CParty:MaxTimes()
	return ctPartyEtcConf[1].nJoinTimes 
end

--增加参加宴会次数
function CParty:AddJoinTimes(nVal)
	self:CheckReset()
	self.m_nJoinTimes = math.min(nMAX_INTEGER, math.max(0, self.m_nJoinTimes+nVal))
	self:MarkDirty(true)
end

--取宴会积分
function CParty:GetScore()
	return self.m_nScore
end

--取宴会活跃
function CParty:GetActive()
	return self.m_nActive
end

function CParty:AddOpenTimes(nVal)
	self:CheckReset()
	self.m_nOpenTimes = self.m_nOpenTimes + nVal
	self:MarkDirty(true)
end

function CParty:GetOpenTimes()
	self:CheckReset()
	return self.m_nOpenTimes
end

--宴会积分
function CParty:AddScore(nVal, sReason)
	assert(sReason)
	self.m_nScore = math.max(0, math.min(nMAX_INTEGER, self.m_nScore+nVal))
	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
    goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.ePartyScore, nVal, self.m_nScore)
	self:MarkDirty(true)

	local oRanking = goRankingMgr:GetRanking(gtRankingDef.ePartyRanking)
	oRanking:Update(self.m_oPlayer, self.m_nScore)
end

--宴会活跃
function CParty:AddActive(nVal, sReason)
	assert(sReason)
	self.m_nActive = math.max(0, math.min(nMAX_INTEGER, self.m_nActive+nVal))
	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
    goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.ePartyActive, nVal, self.m_nActive)
	self:MarkDirty(true)
end

--刷新物品
function CParty:RefreshGoods()
	local nAutoIndex = 0
	self.m_tGoodsList = {}
	for k = 1, 6 do
		local nRnd = math.random(1, ctPartyExchangeConf.nTotalW)
		for nIndex, tConf in ipairs(ctPartyExchangeConf) do
			if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
				nAutoIndex = nAutoIndex + 1
				table.insert(self.m_tGoodsList, {nAutoIndex=nAutoIndex, nIndex=nIndex, nExcTimes=0})
				break
			end
		end
	end
	self:MarkDirty(true)
end

--刷新物品请求
function CParty:PartyRefreshGoodsReq()
	self:CheckReset()
	local tConf = ctPartyEtcConf[1]
	if self.m_nRefreshTimes >= tConf.nRefreshTimes then
		return self.m_oPlayer:Tips("刷新次数已达上限，请明日再来")
	end
	if self.m_oPlayer:GetYuanBao() < tConf.nRefreshYuanBao then
		return self.m_oPlayer:YBDlg()
	end
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nRefreshYuanBao, "宴会刷新物品")
	self.m_nRefreshTimes = self.m_nRefreshTimes + 1
	self:RefreshGoods()
	self:PartyGoodsListReq()
	self:MarkDirty(true)
end

--距离下一刷新点时间
function CParty:GetNextRefreshTime()
	local nMinTime = nMAX_INTEGER
	local tConf = ctPartyEtcConf[1]
	local tRefreshHour = tConf.tRefreshHour[1]
	for _, nHour in ipairs(tRefreshHour) do
		local nNextTime = os.NextHourTime1(nHour)
		if nNextTime < nMinTime then
			nMinTime = nNextTime
		end
	end
	return nMinTime
end

--请求物品列表
function CParty:PartyGoodsListReq()
	self:CheckReset()

	local tList = {}
	for _, tGoods in ipairs(self.m_tGoodsList) do
		local tConf = ctPartyExchangeConf[tGoods.nIndex]
		table.insert(tList, {nAutoIndex=tGoods.nAutoIndex, nIndex=tGoods.nIndex, nRemainTimes=tConf.nLimit-tGoods.nExcTimes})
	end
	local tConf = ctPartyEtcConf[1]
	local nRemainRefreshTimes = math.max(0, tConf.nRefreshTimes-self.m_nRefreshTimes)
	local nNextRefreshTime = self:GetNextRefreshTime()
	local tMsg = {tList=tList, nActive=self.m_nActive, nRemainRefreshTimes=nRemainRefreshTimes, nNextRefreshTime=nNextRefreshTime}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "PartyGoodsListRet", tMsg)
end

--兑换物品
function CParty:PartyExchangeGoodsReq(nAutoIndex)
	self:CheckReset()

	local tTarGoods = nil
	for _, tGoods in ipairs(self.m_tGoodsList) do
		if tGoods.nAutoIndex == nAutoIndex then	
			tTarGoods = tGoods
			break
		end
	end
	if not tTarGoods then
		return self.m_oPlayer:Tips("商品不存在")
	end

	local tConf = assert(ctPartyExchangeConf[tTarGoods.nIndex])
	if self.m_nActive < tConf.nActive then
		return self.m_oPlayer:Tips("兑换所需积分不足，请娘娘拥有足够积分再试")
	end

	if tTarGoods.nExcTimes >= tConf.nLimit then
		return self.m_oPlayer:Tips("已无可兑换次数，请娘娘明日再来")
	end

	tTarGoods.nExcTimes = tTarGoods.nExcTimes + 1
	self:MarkDirty(true)

	self:AddActive(-tConf.nActive, "宴会兑换物品")
	self.m_oPlayer:AddItem(tConf.nType, tConf.nID, tConf.nNum, "宴会兑换物品")
	
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "PartyExchangeGoodsRet", {nIndex=tTarGoods.nIndex})
	self:PartyGoodsListReq()
end