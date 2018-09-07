local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--抽奖类型
CDraw.tType =
{
	eDiamond = 1,	--钻石
	eGold = 2,		--金币
}

--抽奖次数
CDraw.tTimes = 
{
	eOne = 1,	--1次
	eTen = 2,	--10次
}

--根据幸运值计算权重
local function _CalcDrawWeight(tDrawConf, nLuckyPoint)
	local nPreWeight, nTotalWeight = 0, 0
	for nPos, tConf in ipairs(tDrawConf) do
		local nWeight = tConf.nWeight + nLuckyPoint * tConf.nLuckyWeighted 
		tConf.nMinWeight = nPreWeight + 1
		tConf.nMaxWeight = tConf.nMinWeight + nWeight - 1
		nPreWeight = tConf.nMaxWeight 
		nTotalWeight = nTotalWeight + nWeight
	end
	tDrawConf.nTotalWeight = nTotalWeight
end

--抽奖模块
function CDraw:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nDiamondLuckyPoint = 0
	self.m_nGoldLuckyPoint = 0
	self.m_nResetTime = os.time() --上次重置时间
end

function CDraw:LoadData(tData)
	self.m_nDiamondLuckyPoint = tData.nDLP
	self.m_nGoldLuckyPoint = tData.nGLP
	self.m_nResetTime = tData.nResetTime
end

function CDraw:SaveData()
	local tData = {}
	tData.nDLP = self.m_nDiamondLuckyPoint
	tData.nGLP = self.m_nGoldLuckyPoint
	tData.nResetTime = self.m_nResetTime
	return tData
end

function CDraw:GetType()
	return gtModuleDef.tDraw.nID, gtModuleDef.tDraw.sName
end

--检测重置
function CDraw:CheckReset()
	local nNowSec = os.time()
	local nResetWeekDay = ctDrawEtc[1].nResetWeekDay
	local bSameWeek = os.IsSameWeek(self.m_nResetTime, nNowSec, 0)
	local nLastResetWeekDay = os.WDay(self.m_nResetTime)
	local nNowWeekDay = os.WDay(nNowSec)

	if (not bSameWeek and nNowWeekDay >= nResetWeekDay) or (bSameWeek and nLastResetWeekDay < nResetWeekDay and nNowWeekDay >= nResetWeekDay) then
		self.m_nResetTime = nNowSec
		self.m_nDiamondLuckyPoint = 0
		self.m_nGoldLuckyPoint = 0
	end
end

--抽奖
function CDraw:Draw(nDrawType, nDrawTimes)
	self:CheckReset()
	local tDrawConf
	if nDrawType == self.tType.eDiamond then
		tDrawConf = ctDiamondDraw
	elseif nDrawType == self.tType.eGold then
		tDrawConf = ctGoldDraw
		assert(false, "金币抽奖未开放")
	else
		assert(false, "不支持抽奖类型:"..nDrawType)
	end

	if nDrawTimes == self.tTimes.eOne then
		self:OneDraw(tDrawConf, nDrawType)
	elseif nDrawTimes == self.tTimes.eTen then
		self:TenDraw(tDrawConf, nDrawType)
	else
		assert(false, "次数类型错误:", nDrawTimes)
	end
end

--单抽
function CDraw:OneDraw(tDrawConf, nDrawType)
	-- if self.m_oPlayer.m_oBagModule:GetFreeGridNum() < 1 then
	-- 	return self.m_oPlayer:ScrollMsg(string.format(ctLang[49], 1))
	-- end

	local nPrice
	local tSingleDrawCost = ctDrawEtc[1].tSingleDrawCost[1] 
	if nDrawType == self.tType.eDiamond then
		nPrice = tSingleDrawCost[1] 
		if self.m_oPlayer:GetMoney() < nPrice then
			return self.m_oPlayer:ScrollMsg(ctLang[4])
		end
	else
		nPrice = tSingleDrawCost[2] 
		if self.m_oPlayer:GetGold() < nPrice then
			return self.m_oPlayer:ScrollMsg(ctLang[12])
		end
	end
	assert(nPrice)

	if nDrawType == self.tType.eDiamond then
		_CalcDrawWeight(tDrawConf, self.m_nDiamondLuckyPoint)
	else
		_CalcDrawWeight(tDrawConf, self.m_nGoldLuckyPoint)
	end
	local nRnd = math.random(1, tDrawConf.nTotalWeight)

	local tConf
	for k, v in ipairs(tDrawConf) do
		if nRnd >= v.nMinWeight and nRnd <= v.nMaxWeight then
			tConf = v
			break
		end
	end
	assert(tConf)

	--购买贵金属说法
	local nPropID = ctDrawEtc[1].nNobleMetal
	self.m_oPlayer:AddItem(gtObjType.eProp, nPropID, 1, gtReason.eOneDraw)

	local nType, nID, nNum = table.unpack(tConf.tItem[1])
	self.m_oPlayer:AddItem(nType, nID, nNum, gtReason.eOneDraw)

	local nSyncLuckyPoint = 0
	local tLuckyPoint = ctDrawEtc[1].tLuckyPoint[1]
	local tMaxLuckyPoint = ctDrawEtc[1].tMaxLuckyPoint[1]
	if nDrawType == self.tType.eDiamond then
		self.m_oPlayer:SubMoney(nPrice, gtReason.eOneDraw)
		if tConf.bRare then
			self.m_nDiamondLuckyPoint = 0
		else
			self.m_nDiamondLuckyPoint = self.m_nDiamondLuckyPoint + tLuckyPoint[1]
			self.m_nDiamondLuckyPoint = math.min(self.m_nDiamondLuckyPoint, tMaxLuckyPoint[1])
		end
		nSyncLuckyPoint = self.m_nDiamondLuckyPoint
	else
		self.m_oPlayer:SubGold(nPrice, gtReason.eOneDraw)
		if tConf.bRare then
			self.m_nDiamondLuckyPoint = 0
		else
			self.m_nGoldLuckyPoint = self.m_nGoldLuckyPoint + tLuckyPoint[2]
			self.m_nGoldLuckyPoint = math.min(self.m_nGoldLuckyPoint, tMaxLuckyPoint[2])
		end
		nSyncLuckyPoint = self.m_nGoldLuckyPoint
	end
	local tSendData = {tPosList={tConf.nPos}, nLuckyPoint=nSyncLuckyPoint}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DrawRet", tSendData) 
	print("OneDraw***", tSendData)
end

--10连抽
function CDraw:TenDraw(tDrawConf, nDrawType)
	-- if self.m_oPlayer.m_oBagModule:GetFreeGridNum() < 10 then
	-- 	return self.m_oPlayer:ScrollMsg(string.format(ctLang[49], 10))
	-- end

	local nPrice
	local tMultiDrawCost = ctDrawEtc[1].tMultiDrawCost[1]
	if nDrawType == self.tType.eDiamond then
		nPrice = tMultiDrawCost[1]
		if self.m_oPlayer:GetMoney() < nPrice then
			return self.m_oPlayer:ScrollMsg(ctLang[4])
		end
	else
		nPrice = tMultiDrawCost[2]
		if self.m_oPlayer:GetGold() < nPrice then
			return self.m_oPlayer:ScrollMsg(ctLang[12])
		end
	end
	assert(nPrice)

	--购买贵金属说法
	local nPropID = ctDrawEtc[1].nNobleMetal
	self.m_oPlayer:AddItem(gtObjType.eProp, nPropID, 10, gtReason.eTenDraw)

	if nDrawType == self.tType.eDiamond then
		_CalcDrawWeight(tDrawConf, self.m_nDiamondLuckyPoint)
	else
		_CalcDrawWeight(tDrawConf, self.m_nGoldLuckyPoint)
	end

	local bRare = false
	local tPosList, tItemList = {}, {}
	for k = 1, 10 do
		local nRnd = math.random(1, tDrawConf.nTotalWeight)
		for k, v in ipairs(tDrawConf) do
			if nRnd >= v.nMinWeight and nRnd <= v.nMaxWeight then
				table.insert(tPosList, k)
				table.insert(tItemList, v.tItem[1])
				bRare = bRare or v.bRare
				break
			end
		end
	end
	assert(#tItemList == 10)

	for _, tItem in ipairs(tItemList) do
		local nType, nID, nNum = table.unpack(tItem)
		self.m_oPlayer:AddItem(nType, nID, nNum, gtReason.eTenDraw)
	end
	
	local nSyncLuckyPoint = 0
	local tLuckyPoint = ctDrawEtc[1].tLuckyPoint[1]
	local tMaxLuckyPoint = ctDrawEtc[1].tMaxLuckyPoint[1]
	if nDrawType == self.tType.eDiamond then
		self.m_oPlayer:SubMoney(nPrice, gtReason.eTenDraw)
		if bRare then
			self.m_nDiamondLuckyPoint = 0
		else
			self.m_nDiamondLuckyPoint = self.m_nDiamondLuckyPoint + tLuckyPoint[1] * 10
			self.m_nDiamondLuckyPoint = math.min(self.m_nDiamondLuckyPoint, tMaxLuckyPoint[1])
		end
		nSyncLuckyPoint = self.m_nDiamondLuckyPoint
	else
		self.m_oPlayer:SubGold(nPrice, gtReason.eTenDraw)
		if bRare then
			self.m_nGoldLuckyPoint = 0
		else
			self.m_nGoldLuckyPoint = self.m_nGoldLuckyPoint + tLuckyPoint[2] * 10
			self.m_nGoldLuckyPoint = math.min(self.m_nGoldLuckyPoint, tMaxLuckyPoint[2])
		end
		nSyncLuckyPoint = self.m_nGoldLuckyPoint
	end
	local tSendData = {tPosList=tPosList, nLuckyPoint=nSyncLuckyPoint}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DrawRet", tSendData)
end

function CDraw:DrawInfoReq()
	self:CheckReset()
	local tSendData = {nDiamondLuckyPoint=self.m_nDiamondLuckyPoint, nGoldLuckyPoint=self.m_nGoldLuckyPoint}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "DrawInfoRet", tSendData)
	print("DrawInfoReq***", tSendData)
end

function CDraw:DrawReq(nDrawType, nDrawTimes)
	self:Draw(nDrawType, nDrawTimes)
end