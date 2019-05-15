--科舉答題
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert



function CKeJu:Ctor(oRole)
    self.m_oRole = oRole
    self.m_bDirty = false

    self.m_nID = 0
    self.m_tQuestion = {}
end

function CKeJu:LoadData(tData)
	tData = tData or {}
	self.m_nID = tData.m_nID or self.m_nID
end

function CKeJu:SaveData()
	if not self:IsDirty() then
        return
    end
    self:MarkDirty(false)
    local tData = {}
	tData.m_nID = self.m_nID
	return tData
end

function CKeJu:Online()
	local nKejuType = 4
	if self:IsOpenKeju(nKejuType) then
		local oToday = self.m_oRole.m_oTimeData.m_oToday
		local nRoleID = self.m_oRole:GetID()
		if oToday:Query("CheckJoinDianShi",0) <= 0 then
			oToday:Add("CheckJoinDianShi",1)
			if oToday:Query("JoinDianshi",0) >= 1 then
				return
			end
			local fnCallback = function (bCanJoin)
				if not bCanJoin then
					return
				end
				self:CheckJoinDianShi()
			end
			local nServerID = self.m_oRole:GetServer()
			local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
			goRemoteCall:CallWait("KejuRankingCheckJoinDianshiReq", fnCallback, nServerID, nServiceID, 0,nRoleID)
		end
	end
end

function CKeJu:CheckJoinDianShi()
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	oToday:Add("JoinDianShi",1)
    oToday:Add("JoinDianshiCnt",1)
	self:JoinDianshi()
end

function CKeJu:GetType(oRole)
    return gtModuleDef.tKeJu.nID, gtModuleDef.tKeJu.sName
end

function CKeJu:IsSysOpen(nOpenID, bTips)
	local nDialyType = 0
    if nOpenID == 1 then
        nDialyType = 111
    elseif nOpenID == 2 then
        nDialyType = 112
    elseif nOpenID == 3 then
		nDialyType = 113
		return false --TODO 暂时屏蔽
	else
		return false
    end
    local tActCfg = ctDailyActivity[nDialyType]
    assert(tActCfg, "科举配置错误--ID:".. nDialyType )
    local nSysOpenID = tActCfg.nSysOpenID
	return self.m_oRole.m_oSysOpen:IsSysOpen(nSysOpenID, bTips)
end

function CKeJu:GetAnswerTime(nKejuType)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	local sKey = "KejuLeftTime"
	local tTime = oToday:Query(sKey,{})
	local nTime = tTime[nKejuType]
	if not nTime then
		nTime = 60 * 20
		tTime[nKejuType] = nTime
		oToday:Set(sKey,tTime)
	end
	return nTime or 60 * 20
end

function CKeJu:SetAnswerTime(nKejuType,nTime)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	local sKey = "KejuLeftTime"
	local tTime = oToday:Query(sKey,{})
	tTime[nKejuType] = nTime
	oToday:Set(sKey,tTime)
end

function CKeJu:GetAnswerStartTime(nType)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	local tStartTime = oToday:Query("KejuStartTime",{})
	local nStartTime = tStartTime[nType]
	if not nStartTime then
		nStartTime = os.time()
		tStartTime[nType] = nStartTime
		oToday:Set("KejuStartTime",tStartTime)
	end
	return nStartTime
end

function CKeJu:SetAnswerStartTime(nType)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	local tStartTime = oToday:Query("KejuStartTime",{})
	tStartTime[nType] = os.time()
	oToday:Set("KejuStartTime",tStartTime)
end

function CKeJu:GetDayLeftAnswerTime(nType)
	local nNowTime = os.time()
	local nTime = os.NextDayTime(nNowTime,0,0,0)
	return nTime
end

function CKeJu:GetLeftAnswerTime(nType)
	if nType == 1 or nType == 2 then
		return self:GetDayLeftAnswerTime(nType)
	end
	local nStartTime = self:GetAnswerStartTime(nType)
	local nAnswerTime = self:GetAnswerTime(nType)
	local nTime = nStartTime + nAnswerTime - os.time()
	nTime = math.max(math.min(nTime,60*20),0)
	return nTime
end

function CKeJu:GetConfigData(nType)
	nType = nType or 0
	local tData = {}
	for nID,tConf in pairs(ctKejuQuestionConf) do
		if tConf.nType == nType or nType == 0 then
			tData[nID] = tConf
		end
	end
	return tData
end

function CKeJu:GenerateID()
	self.m_nID = self.m_nID + 1
	if self.m_nID >= 1000000000 then
		self.m_nID = 1
	end
	return self.m_nID
end

function CKeJu:AddAnswerQuestionCnt(nType,nCnt)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	nCnt = nCnt or 1
	local sKey = "KejuAnswerQuestionCnt"
	local tAnswerQuestionCnt = oToday:Query(sKey,{})
	if not tAnswerQuestionCnt[nType] then
		tAnswerQuestionCnt[nType] = 0
	end
	tAnswerQuestionCnt[nType] = tAnswerQuestionCnt[nType] +nCnt
	oToday:Set(sKey,tAnswerQuestionCnt)
end
   
function CKeJu:GetAnswerQuestionCnt(nType)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	local tAnswerQuestionCnt = oToday:Query("KejuAnswerQuestionCnt",{})
	return tAnswerQuestionCnt[nType] or 0
end

function CKeJu:AddAnswerQuestionRightCnt(nType,nCnt)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	nCnt = nCnt or 1
	local sKey = "KejuAnswerQuestionRightCnt"
	local tAnswerQuestionRightCnt = oToday:Query(sKey,{})
	if not tAnswerQuestionRightCnt[nType] then
		tAnswerQuestionRightCnt[nType] = 0
	end
	tAnswerQuestionRightCnt[nType] = tAnswerQuestionRightCnt[nType] + nCnt
	oToday:Set(sKey,tAnswerQuestionRightCnt)
end

function CKeJu:GetAnswerQuestionRightCnt(nType)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	local tAnswerQuestionRightCnt = oToday:Query("KejuAnswerQuestionRightCnt",{})
	return tAnswerQuestionRightCnt[nType] or 0
end

function CKeJu:CreateQuestion(nType)
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	local sKey = "KejuRandQuestionRecord"
	local tQuestionRecordData = oToday:Query(sKey,{})

	local tRecordList = tQuestionRecordData[nType] or {}
	local tRecordMap = {}
	for _, nQuestionID in ipairs(tRecordList) do 
		tRecordMap[nQuestionID] = true
	end

	local tKeys = table.Keys(self:GetConfigData(nType))
	local nQuestionCount = #tKeys
	assert(nQuestionCount > 0, "配置错误")
	local nKey = 0
	local tRandList, tRandMap = GF.RandDiffNum(1, nQuestionCount, nQuestionCount)
	for k, nIndex in ipairs(tRandList) do 
		if not tRecordList[tKeys[nIndex]] then 
			nKey = tKeys[nIndex] 
			break
		end
	end
	if nKey <= 0 then --题库不够，所有的都已随机到
		local nIndex = math.random(#tKeys)
		local nKey = tKeys[nIndex]
	end

	table.insert(tRecordList, nKey)
	tQuestionRecordData[nType] = tRecordList
	oToday:Set(sKey, tQuestionRecordData)

	local nID = self:GenerateID()
	self:MarkDirty(true)
	local oQuestion = CQuestion:new(nType,nID,nKey)
	return oQuestion
end

function CKeJu:GMCreateQuestion(nQuestionID)
	local tConf = ctKejuQuestionConf[nQuestionID]
	local nType = tConf["nType"]
	local nID = self:GenerateID()
	self:MarkDirty(true)
	local oQuestion = CQuestion:new(nType,nID,nQuestionID)
	return oQuestion
end

function CKeJu:GetLimitQuestionCnt(nKejuType)
	if nKejuType== 1 or nKejuType == 2 then
		return 10
	else
		return 20
	end
end

function CKeJu:GetQuestionObj(nQuestionID)
	return self.m_tQuestion[nQuestionID]
end

function CKeJu:GetQuestionByType(nKejuType)
	for nQuestionID,oQuestion in pairs(self.m_tQuestion) do
		if oQuestion:GetKejuType() == nKejuType then
			return oQuestion
		end
	end
end

function CKeJu:IsOpenKeju(nKejuType)
	local nHour = os.Hour()
	if nKejuType == 1 and nHour >=10 and nHour <=24 then
		return true
	end
	local nTime = os.time()
	local nWeek = os.WDay(nTime)
	local nTodayZero = os.ZeroTime(nTime)
	local nStartTime = nTodayZero + 17 * 3600 + 1800
	local nEndTime = nTodayZero + 19 * 3600 + 60 * 50
	if nKejuType == 2 and nTime > nStartTime and nHour <=24 then
		return true
	end
	if true then 
		return false --TODO暂时屏蔽
	end
	if nWeek == 6 then
		if nKejuType == 3 and nTime >= nStartTime and nTime <= nEndTime then
			return true
		end
		if nKejuType == 4 and nTime > nEndTime and nHour <=  24 then
			return true
		end
	end
	return false
end

function CKeJu:PackRewardData(nKejuType)
	local tMsg = {}
	local tReward = self.m_oRole.m_oTimeData.m_oToday:Query("KejuReward",{})
	local tRewardData = tReward[nKejuType] or {}
	for nCurrency,nAddCnt in pairs(tRewardData) do
		table.insert(tMsg,{nCurrency=nCurrency,nAddCnt=nAddCnt})
	end
	return tMsg
end

function CKeJu:JoinKeJu(nKejuType)
	nKejuType = nKejuType or 1
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	local tFinish = oToday:Query("KejuFinish",{})
	if tFinish[nKejuType] then
		return self.m_oRole:Tips("活动已完成")
	end
	self:OpenKeJu(nKejuType)
end

function CKeJu:OpenKeJu(nKejuType)
	local oRole = self.m_oRole
	if not self:IsSysOpen(nKejuType, true) then
		-- return oRole:Tips("该系统尚未开启")
		return
	end
	local oQuestion = self:GetQuestionByType(nKejuType)
	if not oQuestion then
		oQuestion = self:CreateQuestion(nKejuType)
		self.m_tQuestion[oQuestion:GetQuestionID()] = oQuestion
	end
	self:SetAnswerStartTime(nKejuType)
	local tMsg = {}
	tMsg.nKejuType = nKejuType
	tMsg.nLeftTime = self:GetLeftAnswerTime(nKejuType)
	tMsg.nAnswerCnt = self:GetAnswerQuestionCnt(nKejuType)
	tMsg.nAnswerRightCnt = self:GetAnswerQuestionRightCnt(nKejuType)
	tMsg.tQuestionData = oQuestion:PackData()
	tMsg.tHelpData = self:PackAskHelpData(oQuestion)
	tMsg.tReward = self:PackRewardData(nKejuType)
	self.m_oRole:SendMsg("OpenKejuDataRet",tMsg)
end

function CKeJu:GMOpenKeJu(nQuestionID)
	local tConf = ctKejuQuestionConf[nQuestionID]
	if not tConf then
		self.m_oRole:Tips("参数错误")
		return
	end
	local nKejuType = tConf["nType"]
	local oQuestion = self:GetQuestionByType(nKejuType)
	if not oQuestion then
		oQuestion = self:GMCreateQuestion(nQuestionID)
		self.m_tQuestion[oQuestion:GetQuestionID()] = oQuestion
	end
	self:SetAnswerStartTime(nKejuType)
	local tMsg = {}
	tMsg.nKejuType = nKejuType
	tMsg.nLeftTime = self:GetLeftAnswerTime(nKejuType)
	tMsg.nAnswerCnt = self:GetAnswerQuestionCnt(nKejuType)
	tMsg.nAnswerRightCnt = self:GetAnswerQuestionRightCnt(nKejuType)
	tMsg.tQuestionData = oQuestion:PackData()
	tMsg.tHelpData = self:PackAskHelpData(oQuestion)
	tMsg.tReward = self:PackRewardData(nKejuType)
	self.m_oRole:SendMsg("OpenKejuDataRet",tMsg)
end

function CKeJu:CloseKeJu(nKejuType)
	local oQuestion = self:GetQuestionByType(nKejuType)
	if oQuestion then
		local nQuestionID = oQuestion:GetQuestionID()
		self.m_tQuestion[nQuestionID] = nil

		local oToday = self.m_oRole.m_oTimeData.m_oToday
		local sKey = "KejuRandQuestionRecord"
		local tQuestionRecordData = oToday:Query(sKey,{})
		local tRecordList = tQuestionRecordData[nKejuType]
		if tRecordList and tRecordList[#tRecordList] == nQuestionID then 
			table.remove(tRecordList, #tRecordList)
			oToday:Set(sKey, tQuestionRecordData)
		end
	end

	if nKejuType ~=1 and nKejuType ~= 2 then
		local nLeftTime = self:GetLeftAnswerTime(nKejuType)
		local nLimitCnt = self:GetLimitQuestionCnt(nKejuType)
		if self:GetAnswerQuestionCnt(nKejuType) < nLimitCnt then
			self:SetAnswerTime(nKejuType,nLeftTime)
		end
		local sMsg = string.format("答题暂停，剩余时间%s",self:GetSecond2String(nLeftTime))
		self.m_oRole:Tips(sMsg)
	end
end

function CKeJu:GetSecond2String(nSec)
    local nLeftSec = math.floor(nSec % 60)
    local nMin = math.floor((nSec / 60)  % 60)
    local nHour = math.floor(nSec / 3600)
    local sMsg = ""
    if nHour > 0 then
        sMsg = string.format("%s%02d时",sMsg,nHour)
    end
    if nHour > 0 or nMin > 0 then
        sMsg = string.format("%s%02d分钟",sMsg,nMin)
    end
    sMsg = string.format("%s%02d秒",sMsg,nLeftSec)
    return sMsg
end

function CKeJu:GetDailyActivityType(nKejuType)
	if nKejuType == 1 then
		return 111
	elseif nKejuType == 2 then
		return 112
	elseif nKejuType == 3 then
		return 113
	end
end

function CKeJu:RecordReward(nKejuType,nOldYinBi,nOldExp,nYinBi,nExp)
	local nAddYinBi = math.max(nYinBi-nOldYinBi,0)
	local nAddExp = math.max(nExp-nOldExp,0)
	
	local tReward = self.m_oRole.m_oTimeData.m_oToday:Query("KejuReward",{})
	if not tReward[nKejuType] then
		tReward[nKejuType] = {}
	end
	if not tReward[nKejuType][gtCurrType.eYinBi] then
		tReward[nKejuType][gtCurrType.eYinBi] = 0
	end
	if not tReward[nKejuType][gtCurrType.eExp] then
		tReward[nKejuType][gtCurrType.eExp] = 0
	end
	tReward[nKejuType][gtCurrType.eYinBi] = tReward[nKejuType][gtCurrType.eYinBi] + nAddYinBi
	tReward[nKejuType][gtCurrType.eExp] = tReward[nKejuType][gtCurrType.eExp] + nAddExp
	self.m_oRole.m_oTimeData.m_oToday:Set("KejuReward",tReward)
end

function CKeJu:AnswerQuestion(nQuestionID,nAnswer)
	local oQuestion = self:GetQuestionObj(nQuestionID)
	if not oQuestion then
		return
	end
	local nKejuType = oQuestion:GetKejuType()
	self:AddAnswerQuestionCnt(nKejuType,1)
	local nOldYinBi = self.m_oRole:GetYinBi()
	local nOldExp = self.m_oRole:GetAllExp()

	if oQuestion:IsRight(nAnswer) then
		self:AnswerRight(nKejuType)
	else
		self:AnswerWrong(nKejuType)
	end
	local nQuestionID = oQuestion:GetQuestionID()
	self.m_tQuestion[nQuestionID] = nil
	local nLimitCnt = self:GetLimitQuestionCnt(nKejuType)
	if table.InArray(nKejuType,{1,2,3}) then
		local oDailyActivity = self.m_oRole.m_oDailyActivity
		local nDailyType = self:GetDailyActivityType(nKejuType)
        oDailyActivity:OnCompleteDailyOnce(nDailyType,"科举答题")
	end

	local nYinBi = self.m_oRole:GetYinBi()
	local nExp = self.m_oRole:GetAllExp()
	self:RecordReward(nKejuType,nOldYinBi,nOldExp,nYinBi,nExp)


	if self:GetAnswerQuestionCnt(nKejuType) < nLimitCnt then
		self:StartNextQuestion(nKejuType)
	else
		local sKey = "KejuCnt"
		local oToday = self.m_oRole.m_oTimeData.m_oToday
		local nCnt = oToday:Query(sKey,0)
		-- if nCnt < 1 then
		-- 	self.m_oRole:Tips("今日首次科举乡试已结束，请留意第二次乡试时间")
		-- else
		-- 	self.m_oRole:Tips("今日科举乡试已结束，请明天继续努力")
		-- end
		self.m_oRole.m_oTimeData.m_oToday:Add(sKey,1)
		local tFinish = oToday:Query("KejuFinish",{})
		tFinish[nKejuType] = 1
		oToday:Set("KejuFinish",tFinish)
	end
	if nKejuType == 1 then
		self.m_oRole:PushAchieve("仙灵轶事答题次数",{nValue = 1})
	end
	if nKejuType == 2 then
		self.m_oRole:PushAchieve("仙灵课堂答题次数",{nValue = 1})
	end
	goLogger:EventLog(gtEvent.eJoinKeJu,oRole,nKejuType,self:GetAnswerQuestionCnt(nKejuType))
end

function CKeJu:AnswerRight(nKejuType)
	self:AddAnswerQuestionRightCnt(nKejuType,1)
	local oRole = self.m_oRole
	local nLevel = oRole:GetLevel()
	local nRoleExp = nLevel*60+300
	local nPetExp = nLevel*30 + 150
	local nYinBi = 5000

	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "科举奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "科举奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "科举奖励")

	local nExtRewardRatio = 8 + 0.3 * self:GetAnswerQuestionRightCnt(nKejuType)
	if math.random(100) < nExtRewardRatio then
		self:GiveExtReward(oRole,nKejuType)
	end
	local nCnt = self:GetAnswerQuestionRightCnt(nKejuType)
	if nCnt >= 6 then
		self:GiveRightExtReward(oRole)
	end
	local nServerID = oRole:GetServer()
	local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
	
	--乡试
	if nKejuType == 3 then
		goRemoteCall:Call("PushKejuRank",nServerID,nServiceID,0,oRole:GetID(),nKejuType,{nCnt,oRole:GetLevel(),oRole:GetName()})
	end
	if nKejuType == 4 then
		local nCostTime = self:GetDianshiCostTime()
		goRemoteCall:Call("PushKejuRank",nServerID,nServiceID,0,oRole:GetID(),nKejuType,{nCnt,nCostTime,oRole:GetLevel(),oRole:GetName()})
	end
end

function CKeJu:AnswerWrong(nKejuType)
	local oRole = self.m_oRole
	local nLevel = oRole:GetLevel()
	local nRoleExp = math.floor((nLevel*60+300)/2)
	local nPetExp = math.floor((nLevel*30 + 150)/2)
	local nYinBi = 2500

	oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleExp, "科举奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.ePetExp, nPetExp, "科举奖励")
	oRole:AddItem(gtItemType.eCurr, gtCurrType.eYinBi, nYinBi, "科举奖励")

	local nExtRewardRatio = 5
	if math.random(100) < nExtRewardRatio then
		self:GiveExtReward(oRole,nKejuType)
	end
	--殿试
	if nKejuType == 4 then
		local nServerID = oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		oRole.m_oTimeData.m_oToday:Add("DianshiWrong",1)
		local nCnt = self:GetAnswerQuestionRightCnt(nKejuType)
		local nCostTime = self:GetDianshiCostTime()
		goRemoteCall:Call("PushKejuRank",nServerID,nServiceID,0,oRole:GetID(),nKejuType,{nCnt,nCostTime,oRole:GetLevel(),oRole:GetName()})
	end
end

function CKeJu:GiveExtReward(oRole,nKejuType)
	local nRoleLevel = oRole:GetLevel()
	local tRewardItemList = ctAwardPoolConf.GetPool(1000, nRoleLevel, oRole:GetConfID())

	local function GetItemWeight(tNode)
		return tNode.nWeight
	end
	local tRewardItem = CWeightRandom:Random(tRewardItemList, GetItemWeight, 1, false)
	oRole:AddItem(gtItemType.eProp, tRewardItem[1].nItemID, tRewardItem[1].nItemNum, "科举奖励")
end

function CKeJu:GiveRightExtReward(oRole)
	local nRoleLevel = oRole:GetLevel()
	local tRewardItemList = ctAwardPoolConf.GetPool(1000, nRoleLevel, oRole:GetConfID())

	local function GetItemWeight(tNode)
		return tNode.nWeight
	end
	local tRewardItem = CWeightRandom:Random(tRewardItemList, GetItemWeight, 1, false)
	oRole:AddItem(gtItemType.eProp, tRewardItem[1].nItemID, tRewardItem[1].nItemNum, "科举奖励")
end

function CKeJu:StartNextQuestion(nKejuType)
	local oQuestion = self:CreateQuestion(nKejuType)
	local nQuestionID = oQuestion:GetQuestionID()
	self.m_tQuestion[nQuestionID] = oQuestion
	local tMsg = {}
	tMsg.nKejuType = nKejuType
	tMsg.nLeftTime = self:GetLeftAnswerTime(nKejuType)
	tMsg.nAnswerCnt = self:GetAnswerQuestionCnt(nKejuType)
	tMsg.nAnswerRightCnt = self:GetAnswerQuestionRightCnt(nKejuType)
	tMsg.tQuestionData = oQuestion:PackData()
	tMsg.tHelpData = self:PackAskHelpData(oQuestion)
	tMsg.tReward = self:PackRewardData(nKejuType)
	self.m_oRole:SendMsg("OpenKejuDataRet",tMsg)
end

function CKeJu:KejuAskHelp(nQuestionID)
	local nCnt = self:GetAskHelpCount()
	if nCnt >=3 then
		self.m_oRole:Tips("今天已没有求助次数了")
		return
	end
	local nUnionID = self.m_oRole:GetUnionID()
	if not nUnionID or nUnionID == 0 then
		return
	end
	local oQuestion = self:GetQuestionObj(nQuestionID)
	if not oQuestion then
		return
	end
	if oQuestion:GetAskHelp() == 0 then
		self:AddAskHelpCount()
		oQuestion:SetAskHelp()
	end
	local nRoleID = self.m_oRole:GetID()
	local tMsg = {}
	tMsg.nQuestionID = nQuestionID
	tMsg.tHelpData = self:PackAskHelpData(oQuestion)
	self.m_oRole:SendMsg("KejuAskHelpRet",tMsg)
	local sTitle = oQuestion:GetTitle()
	local tAnswer = oQuestion:GetAnswerList()
	local sLink = self:GetClientLinkData(nRoleID,nQuestionID,sTitle,tAnswer)
	local nServerID = self.m_oRole:GetServer()
	goRemoteCall:Call("BroadcastUnionTalk",nServerID,goServerMgr:GetGlobalService(nServerID,20),0,nRoleID,sLink)
end

function CKeJu:GetAskHelpCount()
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	return oToday:Query("KejuAskCnt",0)
end

function CKeJu:AddAskHelpCount()
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	oToday:Add("KejuAskCnt",1)
end

function CKeJu:PackAskHelpData(oQuestion)
	local tData = {}
	tData.nHaveAskHelp = oQuestion:GetAskHelp()
	tData.nAskHelpCnt = self:GetAskHelpCount()
	return tData
end

function CKeJu:KejuAnswerHelpQuestion(nHelpRoleID,sRoleName,nQuestionID,nAnswerNo)
	local oQuestion = self:GetQuestionObj(nQuestionID)
	if not oQuestion then return end
	if oQuestion:IsHelpQuestion(nHelpRoleID) then
		return
	end
	oQuestion:AddHelpData(nHelpRoleID,sRoleName,nAnswerNo)
	local sTitle = oQuestion:GetTitle()
	local tAnswer = oQuestion:GetAnswerList()
	local sAnswer = self:GetClientSelectAnswer(nAnswerNo)
	local sLink = self:GetClientHelpLinkData(sRoleName,sTitle,tAnswer,sAnswer)
	local nRoleID = self.m_oRole:GetID()
	local nServerID = self.m_oRole:GetServer()
	goRemoteCall:Call("BroadcastUnionTalk",nServerID,goServerMgr:GetGlobalService(nServerID,20),0,nRoleID,sLink)

end

function CKeJu:KejuAskHelpData(nQuestionID)
	local oQuestion = self:GetQuestionObj(nQuestionID)
	if not oQuestion then return end
	local tHelpData = oQuestion:PackHelpData()
	local tMsg = {}
	tMsg.nQuestionID = nQuestionID
	tMsg.tHelpData = tHelpData
	self.m_oRole:SendMsg("KejuHelpDataRet",tMsg)
end

function CKeJu:GetClientLinkData(nRoleID,nQuestionID,sTitle,tAnswer)
	local sContent = string.format("<color=#2626E6>【求助】</color> %s<color=#00ff00 click='kejuhelp' nQuestionID='%s' nRoleID='%s'>[帮助]</color>",sTitle,nQuestionID,nRoleID)
	return sContent
end

function CKeJu:GetClientSelectAnswer(nAnswerNo)
	if nAnswerNo == 1 then
		return "A"
	elseif nAnswerNo == 2 then
		return "B"
	elseif nAnswerNo == 3 then
		return "C"
	elseif nAnswerNo == 4 then
		return "D"
	end
end

function CKeJu:GetClientHelpLinkData(sName,sTitle,tAnswer,sAnswer)
	local sContent = string.format("%s <color=#2626E6>【助答】</color>：%s  选了[%s]",sName,sTitle,sAnswer)
	return sContent
end

function CKeJu:KejuHelpQuestionDataReq(nRoleID,nQuestionID)
	local oQuestion = self:GetQuestionObj(nQuestionID)
	if not oQuestion then
		return
	end
	local tMsg = {}
	tMsg.nRoleID = self.m_oRole:GetID()
	tMsg.sName = self.m_oRole:GetName()
	tMsg.sTitle = oQuestion:GetTitle()
	tMsg.tAnswer = oQuestion:GetAnswerList()
	tMsg.nAnswerNo = oQuestion:GetHelpAnswerNo(nRoleID)
	return tMsg
end

--------------------御前殿试相关
function CKeJu:CanJoinDianShi()
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	if oToday:Query("JoinDianShi",0) <= 0 then
		return false
	end
	if oToday:Query("JoinDianshiCnt",0) <= 0 then
		return false
	end
	return true
end

function CKeJu:JoinDianshi()
	if not self:CanJoinDianShi() then
		return
	end
	local oToday = self.m_oRole.m_oTimeData.m_oToday
	oToday:Add("JoinDianshiCnt",-1)
	self.m_oRole:SendMsg("KejuFindNpcRet",{})
	--[[
	local fnJoinDianshi = function (tData)
		tData = tData or {}
		if tData.nSelIdx == 1 then  --确定
			self.m_oRole:SendMsg("KejuFindNpcRet",{})
		elseif tData.nSelIdx == 2 then  --取消
			return
		end
	end
	local sCont = "恭喜您获选参加御前殿试的资格，请于21:00前前往金銮寻找唐太宗进行活动，答对题目越多奖励越丰厚！"
	local tOption = {"立刻前往", "我知道了"}
	local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
	goClientCall:CallWait("ConfirmRet", fnJoinDianshi, self.m_oRole, tMsg)
	]]
end

function CKeJu:GetDianshiStartTime()
	local nNowTime = os.time()
	local nTodayZero = os.ZeroTime(nNowTime)
	local nStartTime = nTodayZero + 19 * 3600 + 60 * 50
	return nStartTime
end

function CKeJu:GetDianshiCostTime()
	local nWrongCnt = self.m_oRole.m_oTimeData.m_oToday:Query("DianshiWrong",0)
	local nCostTime = nWrongCnt * 20
	local nNowTime = os.time()
	local nStartTime = self:GetDianshiStartTime()
	nCostTime = nCostTime + math.max(0,nNowTime-nStartTime)
	return nCostTime
end