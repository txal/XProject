local os, math = os, math

CBox.tBoxType = 
{
	eFree = 1,
	eSenior = 2,
}

function CBox:Ctor(oPlayer)
	self.m_oPlayer = oPlayer

	self.m_tFreeBoxList = {}
	self:InitFreeBox()

	self.m_tSeniorBox = {nKills=0, nGot=0, nGotTime=0}
end

function CBox:GetType()
	return gtModuleDef.tBox.nID, gtModuleDef.tBox.sName
end

function CBox:LoadData(tData)
	self.m_tFreeBoxList = tData.tFreeBoxList
	self.m_tSeniorBox = tData.tSeniorBox
	self.m_tSeniorBox.nGot = tData.tSeniorBox.nGot or 0
end

function CBox:SaveData()
	local tData = {}
	tData.tFreeBoxList = self.m_tFreeBoxList
	tData.tSeniorBox = self.m_tSeniorBox
	return tData
end

function CBox:InitFreeBox()
	assert(#self.m_tFreeBoxList == 0)
	local nNowSec = os.time()
	for k = 1, ctBoxEtcConf[1].nFreeBoxNum do
		local nStartTime = nNowSec + (k - 1) * ctBoxEtcConf[1].nFreeBoxTime
		self.m_tFreeBoxList[k] = {nStartTime=nStartTime} 
	end
end

--领奖
function CBox:GetFreeBoxAward()
	local nNowSec = os.time()
	local tFreeBox = assert(self.m_tFreeBoxList[1])
	if nNowSec - tFreeBox.nStartTime >= ctBoxEtcConf[1].nFreeBoxTime then
		tFreeBox = assert(self.m_tFreeBoxList[2])
		local nStartTime = math.max(nNowSec, tFreeBox.nStartTime + ctBoxEtcConf[1].nFreeBoxTime)
		self.m_tFreeBoxList[1] = tFreeBox
		self.m_tFreeBoxList[2] = {nStartTime = nStartTime}

		self:FreeBoxAward()
		self:SyncBoxInfo()
		return
	end
	self.m_oPlayer:ScrollMsg(ctLang[36])
end

--取掉落ID
function CBox:GetWSDropID(tBoxConf)
	if not tBoxConf.nTotoalWeight then
		local nPreWeight = 0
		tBoxConf.nTotoalWeight = 0
		for _, tDrop in ipairs(tBoxConf.tWSDropID) do
			tDrop.nMinWeight = nPreWeight + 1
			tDrop.nMaxWeight = tDrop.nMinWeight + tDrop[1] - 1
			nPreWeight = tDrop.nMaxWeight
			tBoxConf.nTotoalWeight = tBoxConf.nTotoalWeight + tDrop[1]
		end
		tBoxConf.nTotoalWeight = math.max(1, tBoxConf.nTotoalWeight)
	end

	local nWSDropID = 0
	local nRnd = math.random(1, tBoxConf.nTotoalWeight)
	for _, tDrop in ipairs(tBoxConf.tWSDropID) do
		if nRnd >= tDrop.nMinWeight and nRnd <= tDrop.nMaxWeight then
			nWSDropID = tDrop[2]
			break
		end
	end

	return nWSDropID
end

--免费宝箱发奖
function CBox:FreeBoxAward()
	local nFameLevel = self.m_oPlayer.m_oGVGModule:GetFameLevel()
	nFameLevel = math.max(1, math.min(nFameLevel, #ctFreeBoxConf))
	local tBoxConf = assert(ctFreeBoxConf[nFameLevel])
	local nWSDropID = self:GetWSDropID(tBoxConf)
	local tGoldRange = tBoxConf.tGoldRange[1]
	local nGoldNum = math.random(tGoldRange[1], tGoldRange[2]) 
	local tGoldAward = {gtObjType.eProp, tBoxConf.nGoldID, nGoldNum}
	self:_add_award_(tBoxConf.nDrawTimes, nWSDropID, tGoldAward, gtReason.eFreeBoxAward, self.tBoxType.eFree)
end

--添加奖励到背包
function CBox:_add_award_(nDrawTimes, nWSDropID, tGoldAward, nReason, nBoxType)
	assert(nDrawTimes and nWSDropID and tGoldAward and nReason and nBoxType)

	local tAwardList = {}
	for k = 1, nDrawTimes do
		local tItemList = CWorkShop:GenWSDropItem(nWSDropID)
		for _, tItem in ipairs(tItemList) do
			table.insert(tAwardList, tItem)
		end
	end
	table.insert(tAwardList, tGoldAward)

	local tSendAwardList = {}
	for _, tAward in ipairs(tAwardList) do
		local nType, nID, nNum = table.unpack(tAward)
		if nID > 0 then
			local tList = self.m_oPlayer:AddItem(nType, nID, nNum, gtReason.eFreeBoxAward)
			local oArm
			if nType == gtObjType.eArm then
				oArm = tList and #tList > 0 and tList[1][2]
			end
			local nColor = GF.GetItemColor(nType, nID, oArm)
			table.insert(tSendAwardList, {nType=nType, nID=nID, nNum=nNum, nColor=nColor})
		end
	end
	print("Box award****", tSendAwardList)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "GetBoxAwardRet", {nBoxType=nBoxType, tAwardList=tSendAwardList})
end

--高级版宝箱发奖
function CBox:SeniorBoxAward()
	local nFameLevel = self.m_oPlayer.m_oGVGModule:GetFameLevel()
	nFameLevel = math.max(1, math.min(nFameLevel, #ctSeniorBoxConf))
	local tBoxConf = assert(ctSeniorBoxConf[nFameLevel])
	local nWSDropID = self:GetWSDropID(tBoxConf)
	local tGoldRange = tBoxConf.tGoldRange[1]
	local nGoldNum = math.random(tGoldRange[1], tGoldRange[2]) 
	local tGoldAward = {gtObjType.eProp, tBoxConf.nGoldID, nGoldNum}
	self:_add_award_(tBoxConf.nDrawTimes, nWSDropID, tGoldAward, gtReason.eSeniorBoxAward, self.tBoxType.eSenior)
end

--领取高级宝箱
function CBox:GetSeniorBoxAward()
	self:CheckSeniorBoxState()
	if self.m_tSeniorBox.nGot == 1 then
		return
	end
	if self.m_tSeniorBox.nKills >= ctBoxEtcConf[1].nSeniorBoxKills then
		self.m_tSeniorBox.nKills = 0
		self.m_tSeniorBox.nGot = 1
		self.m_tSeniorBox.nGotTime = os.time()

		self:SeniorBoxAward()
		self:SyncBoxInfo()
		return
	end
	self.m_oPlayer:ScrollMsg(ctLang[37])
end

--高级宝箱信息
function CBox:CheckSeniorBoxState()
	local nSeniorBoxCD = 0
	if self.m_tSeniorBox.nGot == 1 then
		local nNowSec = os.time()
		local nRefreshTime = os.MakeDayTime(self.m_tSeniorBox.nGotTime, 1, ctBoxEtcConf[1].nSeniorBoxRefreshTime, 0, 0)
		nSeniorBoxCD = math.max(0, nRefreshTime - nNowSec)
		if nSeniorBoxCD <= 0 then
			self.m_tSeniorBox.nGot = 0
			self.m_tSeniorBox.nGotTime = 0
			self.m_tSeniorBox.nKills = 0
		end
	end
	local nKills = nSeniorBoxCD > 0 and 0 or math.min(self.m_tSeniorBox.nKills, ctBoxEtcConf[1].nSeniorBoxKills)
	return nSeniorBoxCD, nKills
end

--同步宝箱信息
function CBox:SyncBoxInfo()
	local nSeniorBoxCD, nSeniorBoxKills = self:CheckSeniorBoxState()
	local tSendData = {nSeniorBoxCD=nSeniorBoxCD,nSeniorBoxKills=nSeniorBoxKills}

	local nNowSec = os.time()
	for k, tFreeBox in ipairs(self.m_tFreeBoxList) do
		local nFreeBoxCD = math.max(0, tFreeBox.nStartTime + ctBoxEtcConf[1].nFreeBoxTime - nNowSec)
		tSendData["nFreeBoxCD"..k] = nFreeBoxCD
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BoxInfoRet", tSendData)
end

--取宝箱信息
function CBox:BoxInfoReq()
	self:SyncBoxInfo()
end

--领取宝箱
function CBox:GetBoxAwardReq(nBoxType)
	if nBoxType == self.tBoxType.eFree then
		self:GetFreeBoxAward()
	else
		self:GetSeniorBoxAward()
	end
end

--击杀回调
function CBox:AddKills()
	self:CheckSeniorBoxState()
	self.m_tSeniorBox.nKills = self.m_tSeniorBox.nKills + 1
	print("AddKills***", self.m_tSeniorBox.nKills)
end
