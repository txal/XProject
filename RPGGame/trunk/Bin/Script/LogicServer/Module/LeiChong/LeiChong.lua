--累充模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--预处理表
local tMCList = {}
local function _PreProcessConf()
	--知己筛选
	for nMCID, tConf in pairs(ctMingChenConf) do
		if tConf.bDisplay then
			for nPropID, tConf in pairs(ctPropConf) do
				if tConf.nSubType == gtCurrType.eQinMi and tConf.nVal == nMCID then
					table.insert(tMCList, {nMCID, nPropID})
					break
				end
			end
		end
	end

	--权重计算
	local nTotalW, nPreW = 0, 0
	for nID, tConf in ipairs(ctLCGameAwardConf) do
		tConf.nMinW = nPreW + 1
		tConf.nMaxW = tConf.nMinW + tConf.nWeight - 1
		nPreW = tConf.nMaxW
		nTotalW = nTotalW + tConf.nWeight
	end
	ctLCGameAwardConf.nTotalW = nTotalW
end
_PreProcessConf()


function CLeiChong:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self:Init()
end

function CLeiChong:Init(nVersion)
	nVersion = nVersion or 0
	self.m_nVersion = nVersion

	self.m_nMCID = 0 			--知己ID
	self.m_nMCQMProp = 0		--知己对应亲密度道具
	self.m_nRefreshTimes = 0 	--刷新知己次数
	self.m_nBuyPropTimes = 0 	--购买按摩棒次数
	self.m_nUsePropTimes = 0 	--使用按摩棒次数
	self.m_nLastResetTime = 0 	--上次重置时间
end

function CLeiChong:LoadData(tData)
	if not tData then
		return
	end

	self.m_nVersion = tData.m_nVersion
	self.m_nMCID = tData.m_nMCID
	self.m_nMCQMProp = tData.m_nMCQMProp
	self.m_nRefreshTimes = tData.m_nRefreshTimes
	self.m_nBuyPropTimes = tData.m_nBuyPropTimes
	self.m_nUsePropTimes = tData.m_nUsePropTimes
	self.m_nLastResetTime = tData.m_nLastResetTime
end

function CLeiChong:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nVersion = self.m_nVersion
	tData.m_nMCID = self.m_nMCID
	tData.m_nMCQMProp = self.m_nMCQMProp
	tData.m_nRefreshTimes = self.m_nRefreshTimes
	tData.m_nBuyPropTimes = self.m_nBuyPropTimes
	tData.m_nUsePropTimes = self.m_nUsePropTimes
	tData.m_nLastResetTime = self.m_nLastResetTime
	return tData
end

function CLeiChong:GetType()
	return gtModuleDef.tLeiChong.nID, gtModuleDef.tLeiChong.sName
end

--活动是否开启
function CLeiChong:IsOpen(bTips)
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiChong)
	if oAct and oAct:IsOpen() then
		--活动版本不一致就重置数据
		local nVersion = oAct:GetVersion()
		if nVersion ~= self.m_nVersion then
			self:Init(nVersion)
			self:MarkDirty(true)
		end
		return true
	end
	if bTips then
		self.m_oPlayer:Tips("今天没有活动哦，请娘娘稍待几日")
	end
end

--取信息
function CLeiChong:LCInfoReq()
	if not self:IsOpen(true) then
		return 
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiChong)
	local nBegTime, nEndTime = oAct:GetActTime()
	local nRemainTime = oAct:GetStateTime()
	local nTimeRecharge = self.m_oPlayer.m_oVIP:GetTimeRecharge(nBegTime, nEndTime)	

	local tMsg = {nRemainTime=nRemainTime, nTimeRecharge=nTimeRecharge, nBeginTime=nBegTime, nEndTime=nEndTime, tList={}}	
	for nID, tConf in ipairs(ctLeiChongConf) do
		local nState = oAct:GetAwardState(self.m_oPlayer, nID)
		if nState == 0 then
			nState = nTimeRecharge >= tConf.nMoney and 1 or 0
		end
		local tInfo = {nID=nID, nState=nState}
		table.insert(tMsg.tList, tInfo)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LeiChongInfoRet", tMsg)
end

--领取奖励
function CLeiChong:LCAwardReq(nID)
	if not self:IsOpen(true) then
		return
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiChong)
	local nState = oAct:GetAwardState(self.m_oPlayer, nID)
	if nState == 2 then
		return self.m_oPlayer:Tips("该奖励已经领取过了")
	end
	local nBegTime, nEndTime = oAct:GetActTime()
	local nTimeRecharge = oAct:GetTotalRecharge(self.m_oPlayer)

	local tConf = ctLeiChongConf[nID]
	if nTimeRecharge < tConf.nMoney then
		return self.m_oPlayer:Tips("未达到领取条件")
	end

	for _, tAward in ipairs(tConf.tAward) do 
		self.m_oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "累充奖励")
	end

	oAct:SetAwardState(self.m_oPlayer, nID, 2)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LeiChongAwardRet", {nID=nID})
	self:LCInfoReq()
	--小红点
	self:CheckRedPoint(self.m_oPlayer)
end

--刷新知己
function CLeiChong:LCGameRefreshFZ()
	local nIndex = math.random(#tMCList)
	self.m_nMCID = tMCList[nIndex][1]
	self.m_nMCQMProp = tMCList[nIndex][2]
	self.m_nUsePropTimes = 0

	self:MarkDirty(true)
end

--游戏信息返回
function CLeiChong:LCGameInfoReq()
	if not self:IsOpen(true) then
		return
	end
	self:LCGameCheckReset()
	local tConf = ctLeiChongEtcConf[1]

	local tMsg = {}
	tMsg.nMCID = self.m_nMCID
	tMsg.nPropID = tConf.nPropID
	tMsg.nPropNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, tConf.nPropID)
	tMsg.nBuyPropTimes = self.m_nBuyPropTimes
	tMsg.nRefreshTimes = self.m_nRefreshTimes
	tMsg.nUsePropTimes = self.m_nUsePropTimes
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LCGameInfoRet", tMsg)
end

--检测重置
function CLeiChong:LCGameCheckReset()
	if not os.IsSameDay(os.time(), self.m_nLastResetTime, 5*3600) then
		self:LCGameRefreshFZ()
		self.m_nRefreshTimes = 0
		self.m_nBuyPropTimes = 0
		self.m_nLastResetTime = os.time()
		self:MarkDirty(true)
	end
end

--主动刷新知己
function CLeiChong:LCGameRefreshReq()
	if not self:IsOpen(true) then
		return
	end
	self:LCGameCheckReset()

	local nRFTimes = math.min(self.m_nRefreshTimes+1, #ctFZRefreshConf)
	local tConf = ctFZRefreshConf[nRFTimes]
	if self.m_oPlayer:GetYuanBao() < tConf.nYuanBao then
		return self.m_oPlayer:YBDlg()
	end

	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nYuanBao, "累充活动刷新知己")
	self:LCGameRefreshFZ()
	self.m_nRefreshTimes = self.m_nRefreshTimes + 1
	self:MarkDirty(true)
	self:LCGameInfoReq()
end

--购买按摩棒
function CLeiChong:LCGameBuyPropReq()
	if not self:IsOpen(true) then
		return
	end
	self:LCGameCheckReset()

	local tConf = ctLeiChongEtcConf[1]
	if self.m_oPlayer:GetYinLiang() < tConf.nYinLiang then
		return self.m_oPlayer:Tips("银两不足")
	end
	if self.m_nBuyPropTimes >= tConf.nBuyLimit then
		return self.m_oPlayer:Tips("今日已达到购买上限")
	end
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYinLiang, tConf.nYinLiang, "购买按摩棒")
	self.m_nBuyPropTimes = self.m_nBuyPropTimes + 1
	self.m_oPlayer:AddItem(gtItemType.eProp, tConf.nPropID, 1, "购买按摩棒")
	self:MarkDirty(true)
	self:LCGameInfoReq()
	self.m_oPlayer:Tips(string.format("购买%s成功", CGuoKu:PropName(tConf.nPropID)))
end

--使用按摩棒
function CLeiChong:LCGameUsePropReq()
	if not self:IsOpen(true) then
		return
	end
	if self.m_nMCID == 0 or self.m_nMCQMProp == 0 then
		return self.m_oPlayer:Tips("挑选知己失败:"..self.m_nMCID..":"..self.m_nMCQMProp)
	end
	--游戏重置检测
	self:LCGameCheckReset()

	--使用按摩棒达到上限后,再使用按摩棒时刷出下1个知己,但是不同时按摩棒
	local tConf = ctLeiChongEtcConf[1]
	if self.m_nUsePropTimes >= tConf.nPropRefresh then
		self:LCGameRefreshFZ()
		self:LCGameInfoReq()
		return 
	end

	--使用按摩棒
	local nCurrNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, tConf.nPropID)
	if nCurrNum <= 0 then
		return self.m_oPlayer:Tips("按摩棒不足")
	end
	self.m_oPlayer:SubItem(gtItemType.eProp, tConf.nPropID, 1, "使用按摩棒")
	
	--概率亲密度
	--第5次奖励一定是该知己亲密度
	local tList = {}
	local nRnd = math.random(1, 100)
	if self.m_nUsePropTimes == tConf.nPropRefresh-1 or nRnd <= tConf.nQMRate*100 then
		local nGotQMNum = 1
		if self.m_nUsePropTimes == tConf.nPropRefresh-1 then --第5次3个亲密度,否则1个
			nGotQMNum = 3
		end

		self.m_oPlayer:AddItem(gtItemType.eProp, self.m_nMCQMProp, nGotQMNum, "使用按摩棒")
		table.insert(tList, {nType=gtItemType.eProp, nID=self.m_nMCQMProp, nNum=nGotQMNum})
	else
		local nRnd = math.random(1, ctLCGameAwardConf.nTotalW)
		for nIndex, tInfo in ipairs(ctLCGameAwardConf) do
			if nRnd >= tInfo.nMinW and nRnd <= tInfo.nMaxW then
				self.m_oPlayer:AddItem(tInfo.nType, tInfo.nID, tInfo.nNum, "使用按摩棒")
				table.insert(tList, {nType=tInfo.nType, nID=tInfo.nID, nNum=tInfo.nNum})
				break
			end
		end
	end
	self.m_nUsePropTimes = self.m_nUsePropTimes + 1
	self:MarkDirty(true)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LCGameUsePropRet", {tList=tList})
	self:LCGameInfoReq()
	--小红点
	self:CheckRedPoint(self.m_oPlayer)
end

--充值成功
function CLeiChong:OnRechargeSuccess(nMoney)
	if not self:IsOpen() then
		return
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiChong)
	oAct:OnRechargeSuccess(self.m_oPlayer, nMoney)
	self:CheckRedPoint(self.m_oPlayer)
end

--是否可领奖
function CLeiChong:CanGetAward()
	if not self:IsOpen() then
		return false
	end
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiChong)
	local nTimeRecharge = oAct:GetTotalRecharge(self.m_oPlayer)
	local nBegTime, nEndTime = oAct:GetActTime()
	for nID, tConf in ipairs(ctLeiChongConf) do
		local nState = oAct:GetAwardState(self.m_oPlayer, nID)
		if nState == 0 then
			if nTimeRecharge >= tConf.nMoney then
				return true
			end
		end
	end
	return false
end

--小红点
function CLeiChong:CheckRedPoint(oPlayer)
	local oAct = goHDMgr:GetHuoDong(gtHDDef.eLeiChong)
	oAct:SyncState(oPlayer)
end