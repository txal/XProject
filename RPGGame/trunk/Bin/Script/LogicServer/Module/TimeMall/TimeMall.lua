--限时特卖
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CTimeMall:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nResetTime = os.time() 	--上次重置时间
	self.m_tBuyMap = {} 	--购买记录
end

function CTimeMall:LoadData(tData)
	if not tData then return end
	self.m_nResetTime = tData.m_nResetTime
	self.m_tBuyMap = tData.m_tBuyMap
end

function CTimeMall:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	
	local tData = {}
	tData.m_tBuyMap = self.m_tBuyMap
	tData.m_nResetTime = self.m_nResetTime
	return tData
end

function CTimeMall:GetType()
	return gtModuleDef.tTimeMall.nID, gtModuleDef.tTimeMall.sName
end

--检测重置
function CTimeMall:CheckReset()
	local nNowSec = os.time()
	if not os.IsSameDay(nNowSec, self.m_nResetTime, 0) then
		self.m_nResetTime = nNowSec
		self.m_tBuyMap = {}
		self:MarkDirty(true)
	end
end

--取信息
function CTimeMall:InfoReq()
	self:CheckReset()
	local tList = {}
	for nID, nTimes in pairs(self.m_tBuyMap) do
		local tInfo = {nID=nID, nTimes=nTimes}
		table.insert(tList, tInfo)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "TimeMallInfoRet", {tList=tList})
end

--领取奖励
function CTimeMall:BuyReq(nID)
	self:CheckReset()
	local nVIP = self.m_oPlayer:GetVIP()
	local tConf = ctTimeMallConf[nID]
	if nVIP < tConf.nVIP then
		return self.m_oPlayer:Tips("VIP等级不足")
	end
	local tDisPrice = tConf.tDisPrice[1]
	local nCurrCount = self.m_oPlayer:GetItemCount(tDisPrice[1], tDisPrice[2])
	if nCurrCount < tDisPrice[3] then
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tDisPrice[2])))
	end
	local nBuyTimes = self.m_tBuyMap[nID] or 0
	if nBuyTimes >= tConf.nDayLimit then
		return self.m_oPlayer:Tips("今天商品已售罄")
	end
	local tItem = tConf.tItem[1]
	self.m_oPlayer:SubItem(tDisPrice[1], tDisPrice[2], tDisPrice[3], "商城-"..CGuoKu:PropName(tItem[2]))
	self.m_tBuyMap[nID] = (self.m_tBuyMap[nID] or 0) + 1
	self:MarkDirty(true)
	
	self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "限时特卖:"..nID)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "TimeMallBuyRet", {nID=nID})
	self:InfoReq()
end
