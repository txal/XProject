local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--道具状态
CWorkShop.tState = 
{
	eInit = 0,		--未开始
	eStart = 1,		--进行中
	eFinish = 2,	--已结束
}

function CWorkShop:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nPropCount = 0
	self.m_tPropMap = {}	--{[nGridID]={nPropID,nTime},...}
	self.m_tWorkList = {}	--{{nPropID=nPropID,nStartTime=0,nState=self.tState.eInit},...}
	self.m_tSkillMap = {}	--{[id]={level,master},...}
	self:_init_skill_list()
	self.m_nWorkTick = nil
end

function CWorkShop:_init_skill_list()
	if not next(self.m_tSkillMap) then
		for k = gtCurrType.eSQMaster, gtCurrType.eSPXMaster do
			self.m_tSkillMap[k] = {1, 0}
		end
	end
end

function CWorkShop:OnRelease()
	self:_cancel_work_tick()
end

function CWorkShop:LoadData(tData)
	for nGridID, xProp in pairs(tData.tPropMap or {}) do
		local nPropID, tProp
		if type(xProp) == "table" then
			nPropID = xProp[1]
			tProp = xProp
		else
			nPropID = xProp
			tProp = {xProp, os.time()}
		end
		if ctWSPropConf[nPropID] then
			self.m_tPropMap[nGridID] = tProp
			self.m_nPropCount = self.m_nPropCount + 1
		elseif nPropID then
			LuaTrace("ctWSPropConf["..nPropID.."] not exist")
		end
	end
	for k, tWork in ipairs(tData.tWorkList or {}) do
		if ctWSPropConf[tWork.nPropID] then
			table.insert(self.m_tWorkList, tWork)
		else
			LuaTrace("ctWSPropConf["..tWork.nPropID.."] not exist")
		end
	end
	self.m_tSkillMap = tData.tSkillMap or self.m_tSkillMap
	self:_init_skill_list()
	self:OnLoaded()
end

function CWorkShop:OnLoaded()
	if #self.m_tWorkList <= 0 then
		return
	end
	local tWork = self.m_tWorkList[1]
	if tWork.nState ~= self.tState.eStart then
		self:CheckWorkState()
		return
	end

	local nNowSec = os.time()
	for k = 1, #self.m_tWorkList do
		local tWork = self.m_tWorkList[k]
		local tConf = assert(ctWSPropConf[tWork.nPropID])
		if tWork.nState == self.tState.eStart then
			local nFinishTime = tWork.nStartTime + tConf.nCostTime * 60
			if nNowSec >= nFinishTime then
				tWork.nState = self.tState.eFinish

				local tNxtWork = self.m_tWorkList[k + 1]
				if tNxtWork and tNxtWork.nState == self.tState.eInit then
					tNxtWork.nStartTime = nFinishTime
					tNxtWork.nState = self.tState.eStart
				else
					break
				end
			else
				break
			end
		end
	end
	self:CheckWorkState()
end

function CWorkShop:SaveData()
	local tData = {}
	tData.tPropMap = self.m_tPropMap
	tData.tWorkList = self.m_tWorkList
	tData.tSkillMap =  self.m_tSkillMap
	return tData
end

function CWorkShop:GetType()
	return gtModuleDef.tWorkShop.nID, gtModuleDef.tWorkShop.sName
end

function CWorkShop:FreeGridCount()
	return ctWSBagConf[1].nMaxGrid - self.m_nPropCount
end

function CWorkShop:FreeGridID()
	if self:FreeGridCount() <= 0 then
		return 0
	end
	for k = 1, ctWSBagConf[1].nMaxGrid do
		if not self.m_tPropMap[k] then
			return k
		end
	end
	return 0
end

function CWorkShop:AddProp(nPropID, nNum)
	assert(nNum >= 0)
	if nNum == 0 then
		return
	end
	assert(ctWSPropConf[nPropID], "工坊道具:"..nPropID.."不存在")
	local nFreedGridCount = self:FreeGridCount()
	if nFreedGridCount < nNum then
		self.m_oPlayer:ScrollMsg(ctLang[35])
		LuaTrace("工坊仓库已满", self.m_oPlayer:GetCharID(), nPropID, nNum)
		return
	end
	local tPropList = {}
	for k = 1, nNum do
		local nFreedGridID = self:FreeGridID()
		self.m_tPropMap[nFreedGridID] = {nPropID, os.time()}
		table.insert(tPropList, {nFreedGridID, nPropID})
	end
	self.m_nPropCount = self.m_nPropCount + nNum
	self:SyncPropList()
	self.m_oPlayer:SyncBagContainer()
	return tPropList
end

function CWorkShop:RemoveProp(nGridID)
	assert(self.m_tPropMap[nGridID])
	self.m_tPropMap[nGridID] = nil
	self.m_nPropCount = self.m_nPropCount - 1
	self.m_oPlayer:SyncBagContainer()
	self:SyncPropList()
end

function CWorkShop:PutWork(nGridID, bOneKey)
	if #self.m_tWorkList >= ctWSBagConf[1].nMaxWork then
		return
	end
	local tProp = self.m_tPropMap[nGridID]
	if not tProp then
		return
	end
	local nPropID = tProp[1]
	-- local tPropConf = assert(ctWSPropConf[nPropID])
	-- local nSkillLevel = self.m_tSkillMap[tPropConf.nType][1]
	-- local nNeedSkillLevel = math.max(0, tPropConf.nLevel * 10 - 15)
	-- if nSkillLevel < nNeedSkillLevel then
	-- 	return self.m_oPlayer:ScrollMsg(ctLang[16])
	-- end
	self:RemoveProp(nGridID)
	table.insert(self.m_tWorkList, {nPropID=nPropID,nStartTime=0,nState=self.tState.eInit})
	self:CheckWorkState()
	if not bOneKey then
		self:SyncWorkList()
	end
	return true
end

function CWorkShop:_cancel_work_tick()
	if self.m_nWorkTick then
		GlobalExport.CancelTimer(self.m_nWorkTick)
		self.m_nWorkTick = nil
	end
end

function CWorkShop:_register_work_tick(nIndex, nSecond)
	self:_cancel_work_tick()
	self.m_nWorkTick = GlobalExport.RegisterTimer(nSecond*1000, function() self:_work_timeout(nIndex) end)
end

function CWorkShop:_work_timeout(nIndex)
	self:CheckWorkState()
end

function CWorkShop:CheckWorkState()
	local nNowSec = os.time()
	for nIndex, tWork in ipairs(self.m_tWorkList) do
		local tPropConf = assert(ctWSPropConf[tWork.nPropID])
		if tWork.nState == self.tState.eStart then
			local nRemainTime = tWork.nStartTime + tPropConf.nCostTime * 60 - nNowSec
			if nRemainTime > 0 then
				self:_register_work_tick(nIndex, nRemainTime)
				return
			end
			tWork.nState = self.tState.eFinish
			self:_cancel_work_tick()

		elseif tWork.nState == self.tState.eInit then
			tWork.nState = self.tState.eStart
			tWork.nStartTime = nNowSec
			self:_register_work_tick(nIndex, tPropConf.nCostTime*60)
			return

		end
	end
end

--取消工作
function CWorkShop:CancelWork(nIndex)
	local tWork = self.m_tWorkList[nIndex]
	if not tWork then
		return
	end
	if tWork.nState ~= self.tState.eInit then
		return self.m_oPlayer:ScrollMsg(ctLang[17])
	end
	local nFreedGridCount = self:FreeGridCount()
	if nFreedGridCount <= 0 then
		return self.m_oPlayer:ScrollMsg(ctLang[10])
	end
	table.remove(self.m_tWorkList, nIndex)
	self:CheckWorkState()
	self:AddProp(tWork.nPropID, 1)

	self:SyncWorkList()
end

function CWorkShop:GenWSDropItem(nWSDropID)
	local tItemList = {}

	local tDropConf = ctWSDropConf[nWSDropID]
	if not tDropConf then
		return tItemList
	end

	local tAwardList = tDropConf.tAward
	if not tDropConf.nTotalWeight then
		local nPreWeight = 0
		tDropConf.nTotalWeight = 0
		for _, tAward in ipairs(tAwardList) do
			tAward.nMinWeight = nPreWeight + 1
			tAward.nMaxWeight = tAward.nMinWeight + tAward[1] - 1
			nPreWeight = tAward.nMaxWeight
			tDropConf.nTotalWeight = tDropConf.nTotalWeight + tAward[1]
		end
	end
	if tDropConf.nTotalWeight <= 0 then
		return tItemList
	end

	--随机一个
	if tDropConf.nType == 1 then
		local nRnd = math.random(1, tDropConf.nTotalWeight)	
		for _, tAward in ipairs(tAwardList) do
			if nRnd >= tAward.nMinWeight and nRnd <= tAward.nMaxWeight then
				table.insert(tItemList, {tAward[2], tAward[3], tAward[4]})
				break
			end
		end
	--分别随机
	elseif tDropConf.nType == 2 then
		for _, tAward in ipairs(tAwardList) do
			local nRnd = math.random(1, tDropConf.nTotalWeight)	
			if nRnd >= tAward.nMinWeight and nRnd <= tAward.nMaxWeight then
				table.insert(tItemList, {tAward[2], tAward[3], tAward[4]})
			end
		end
	end
	return tItemList
end

--获取奖励列表
function CWorkShop:_get_award_list(tPropConf)
	local tAwardList = {}	

	local nRndMaster = math.random(95, 105) --0.95-1.05随机
	local tMaster = tPropConf.tMaster[1]
	local nMasterNum = math.floor(tMaster[3] * nRndMaster * 0.01)
	if nMasterNum > 0 then
		table.insert(tAwardList, {tMaster[1], tMaster[2], nMasterNum})
	end

	local tBaseGold = tPropConf.tBaseGold[1]
	local nRndGold = math.random(90, 110)
	local nGoldNum = math.floor(tBaseGold[3] * nRndGold * 0.01)
	if nGoldNum > 0 then
		local tGoldAward = {tBaseGold[1], tBaseGold[2], nGoldNum}
		table.insert(tAwardList, tGoldAward)
	end

	local nDrawTimes = tPropConf.nDrawTimes
	local nFloorTimes = tPropConf.nFloorTimes
	local nFloorDropID	= tPropConf.nFloorDropID
	local nStandardDropID = tPropConf.nStandardDropID

	--保底奖励
	local tFloorDropConf = ctWSDropConf[nFloorDropID]
	if tFloorDropConf then
		for k = 1, nFloorTimes do
			local tItemList = self:GenWSDropItem(nFloorDropID)
			for _, tItem in ipairs(tItemList) do
				table.insert(tAwardList, tItem)
			end
		end
	end
	--标准奖励
	local tStandardDropConf = ctWSDropConf[nStandardDropID]
	if tStandardDropConf then
		for k = 1, nDrawTimes - nFloorTimes do
			local tItemList = self:GenWSDropItem(nStandardDropID)
			for _, tItem in ipairs(tItemList) do
				table.insert(tAwardList, tItem)
			end
		end
	end
	return tAwardList
end

--收获工作
function CWorkShop:GainWork(nIndex)
	local tWork = self.m_tWorkList[nIndex]
	if not tWork then
		return
	end
	local tPropConf = assert(ctWSPropConf[tWork.nPropID])
	local oBag = self.m_oPlayer.m_oBagModule
	if tPropConf.nDrawTimes > oBag:GetFreeGridNum() then	
	    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "BagFullRet", {})
		return
	end
	if tWork.nState ~= self.tState.eFinish then
		local nStartTime = tWork.nStartTime
		if tWork.nState == self.tState.eInit then
			nStartTime = os.time()
		end
		assert(nStartTime > 0)
		local nCostMoney = math.ceil(math.max(0, nStartTime + tPropConf.nCostTime * 60 - os.time()) / 60 / 20)
		if self.m_oPlayer:GetMoney() < nCostMoney then
			return self.m_oPlayer:ScrollMsg(ctLang[4])
		end
		self.m_oPlayer:SubMoney(nCostMoney, gtReason.eGainWork)
	end
	local tSendAwardList = {}
	local tAwardList = self:_get_award_list(tPropConf)	
	for _, tAward in ipairs(tAwardList) do
		local nType, nID, nNum = table.unpack(tAward)
		if nID > 0 then
			local tList = self.m_oPlayer:AddItem(nType, nID, nNum, gtReason.eGainWork)
			local oArm
			if nType == gtObjType.eArm then
				oArm = tList and #tList > 0 and tList[1][2]
			end
			local nColor = GF.GetItemColor(nType, nID, oArm)
			table.insert(tSendAwardList, {nType=nType, nID=nID, nNum=nNum, nColor=nColor})
		end
	end
	table.remove(self.m_tWorkList, nIndex)
	self:CheckWorkState()

	self:SyncWorkList()
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "WorkAwardListRet", {tAwardList=tSendAwardList})
end

--取下级技能需要熟练度
function CWorkShop:_get_next_master(nSkillLevel)
	local nLevel = self.m_oPlayer:GetLevel()
	local nNextMaster = math.floor(nSkillLevel ^ 2 * 13 + 999 + math.floor(nSkillLevel / 100) * 10000)
	return nNextMaster
end

--增加技能熟练度
function CWorkShop:AddMaster(nCurrType, nNum)
	assert(nNum >= 0)
	if nNum == 0 then
		return
	end 
	local bLevelChange = false
	local tSkill = self.m_tSkillMap[nCurrType]
	assert(tSkill, "技能"..nCurrType.." 不存在")
	if tSkill[1] >= ctWSBagConf[1].nMaxSkillLevel then
		local nNextMaster = self:_get_next_master(tSkill[1])
		if tSkill[2] >= nNextMaster - 1 then
			return self.m_oPlayer:ScrollMsg(ctLang[11])			
		end
		tSkill[2] = math.min(nNextMaster - 1, tSkill[2] + nNum)
	else
		tSkill[2] = tSkill[2] + nNum
		for k = tSkill[1] + 1, ctWSBagConf[1].nMaxSkillLevel do
			local nNextMaster = self:_get_next_master(tSkill[1])
			if tSkill[2] >= nNextMaster then
				tSkill[1] = k
				tSkill[2] = tSkill[2] - nNextMaster
				if tSkill[1] >= ctWSBagConf[1].nMaxSkillLevel then
					tSkill[2] = math.min(self:_get_next_master(tSkill[1])-1, tSkill[2])
				end
				bLevelChange = true
			else
				break
			end
		end
	end
	self:SyncSkillList()
	if bLevelChange then
		self.m_oPlayer:UpdateBattleAttr()
	end
end

function CWorkShop:SyncWorkList()
	local tWorkList = {}
	local nTotalTime = 0
	for k, v in ipairs(self.m_tWorkList) do
		local tWork = {}
		tWork.nPropID = v.nPropID
		tWork.nWorkState = v.nState
		tWork.nRemainTime = 0
		local nCostTime = ctWSPropConf[v.nPropID].nCostTime * 60
		if v.nState == self.tState.eInit then
			tWork.nRemainTime = nCostTime
			nTotalTime = nTotalTime + tWork.nRemainTime

		elseif v.nState == self.tState.eStart then
			tWork.nRemainTime = math.max(0, v.nStartTime + nCostTime - os.time())
			nTotalTime = nTotalTime + tWork.nRemainTime

		end
		table.insert(tWorkList, tWork)
	end
	local tData = {tWorkList=tWorkList, nTotalTime=nTotalTime}
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "WorkListRet", tData)
end

function CWorkShop:SyncPropList()
	local tPropList = {}
	for k, v in pairs(self.m_tPropMap) do
		local tProp = {nGridID=k, nPropID=v[1], nTime=v[2]}	
		table.insert(tPropList, tProp)
	end
	table.sort(tPropList, function(t1, t2) return t1.nTime < t2.nTime end)
	local tData = {tPropList=tPropList, nCurPropCount=self.m_nPropCount, nMaxPropCount=ctWSBagConf[1].nMaxGrid}
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "PropListRet", tData)
end

function CWorkShop:SyncSkillList()
	local tSkillList = {}
	for nID, tSkill in pairs(self.m_tSkillMap) do
		local tInfo = {nID=nID, nLevel=tSkill[1], nCurExp=tSkill[2], nNxtExp=self:_get_next_master(tSkill[1])}
		table.insert(tSkillList, tInfo)
	end
	table.sort(tSkillList, function(t1, t2) return t1.nID < t2.nID end)
	local tData = {tSkillList=tSkillList}
    CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "SkillListRet", tData)
end

function CWorkShop:WorkShopInfoReq()
	self:SyncWorkList()	
	self:SyncPropList()	
	self:SyncSkillList()
end	

function CWorkShop:PutWorkReq(nGridID)
	self:PutWork(nGridID)
end

--1键维修
function CWorkShop:OneKeyPutWorkReq()
	local tPropList = {}
	for nGridID, tProp in pairs(self.m_tPropMap) do
		table.insert(tPropList, {nGridID, tProp[2]})
	end
	table.sort(tPropList, function(t1, t2) return t1[2] < t2[2] end)
	local nPutNum = 0
	for _, v in ipairs(tPropList) do
		if not self:PutWork(v[1], true) then
			break
		end
		nPutNum = nPutNum + 1
	end
	if nPutNum > 0 then
		self:SyncWorkList()
	else
		self.m_oPlayer:ScrollMsg(ctLang[58])
	end
end

function CWorkShop:CancelWorkReq(nIndex)
	self:CancelWork(nIndex)
end

function CWorkShop:GainWorkReq(nIndex)
	self:GainWork(nIndex)
end

function CWorkShop:GetAttrAdd(nCurrType)
	local tAttrAdd = {0, 0, 0}
	local tSkill = assert(self.m_tSkillMap[nCurrType])
	local nLevel = tSkill[1]
	--攻，防，血
	tAttrAdd[1] = 4 * nLevel + 0
	tAttrAdd[2] = 1 * nLevel + 0
	tAttrAdd[3] = 17 * nLevel + 0
	return tAttrAdd
end