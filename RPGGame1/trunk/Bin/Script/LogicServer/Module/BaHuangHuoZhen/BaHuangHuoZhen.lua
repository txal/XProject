local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--八荒火阵

local nMaxBoxTimes = 8    	--八个宝箱
local nMinTaskTimes = 5		--5个箱子才能发起求助
local nMaxHelpTimes = ctBaHuangHuoZhenComplex[1].nCanHelpTimes		--最多求助的宝箱数
local nMaxHelpPackingBoxTimes = ctBaHuangHuoZhenComplex[1].nHelpTiems 	--最多


function CBaHuangHuoZhen:Ctor(oRole)
	self.m_oRole = oRole
	self.m_bFirstTask = false 		--首次参加任务标记
	self.m_bPickTask = false 		--今日是否接取任务
	self.m_oBoxMap = {}				--宝箱对象,self.m_oBox[BoxID] = oBox

	self.m_bComplete = false		--是否完成八个箱子
	self.m_nCompleteReward = 0		--是否领取完成奖励
	self.m_nComplteTaskTimes = 0 	--当前完成的箱子数量
	self.m_nBoxHelpTimes = 0		--当前箱子求助数量
	self.m_nHasHelpTimes = 0		--已帮助封箱次数
	self.m_bPracticeState = false	--当前修炼技能是否达到上限 true为已经达到
	self.m_nCheckTime = 0
	self.m_tBoxIndex = {}			--self.m_tBoxIndex[1]	--存宝箱ID
	self.m_oTomorrowBox = {}		--记录明日宝箱的信息
end

function CBaHuangHuoZhen:LoadData(tData)
	if tData then
		for nBoxID, tBox in pairs(tData.m_oBoxMap) do
			local oBox = CBaHuangHuoZhenBoxObj:new(self.m_oRole, self ,nBoxID, tBox)
			if oBox then
				oBox:LoadData(tBox)
				self.m_oBoxMap[nBoxID] = oBox
			end
		end

		for nBoxID, tBox in pairs(tData.m_oTomorrowBox or {}) do
			local oBox = CBaHuangHuoZhenBoxObj:new(self.m_oRole, self ,nBoxID, tBox)
			if oBox then
				oBox:LoadData(tBox)
				self.m_oTomorrowBox[nBoxID] = oBox
			end
		end

		self.m_bFirstTask = tData.m_bFirstTask or false
		self.m_bComplete = tData.m_bComplete or false
		self.m_nCompleteReward = tData.m_nCompleteReward or 0
		self.m_nComplteTaskTimes = tData.m_nComplteTaskTimes or 0
		self.m_nBoxHelpTimes = tData.m_nBoxHelpTimes or 0
		self.m_nHasHelpTimes = tData.m_nHasHelpTimes or 0
		self.m_bPracticeState = self:GetPracticeState()
		self.m_bPickTask = tData.m_bPickTask or false
		self.m_tBoxIndex = tData.m_tBoxIndex
		self.m_nCheckTime = tData.m_nCheckTime or self:GetResetTime()
	end
	if self.m_nCheckTime == 0 then
		self.m_nCheckTime = self:GetResetTime()
		self:MarkDirty(true)
	end
	self:OpenTaskCheck()

	
 end

function CBaHuangHuoZhen:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	
	local tData = {}
	tData.m_oBoxMap = {}
	for nBoxID, oBox in pairs(self.m_oBoxMap) do
		tData.m_oBoxMap[nBoxID] = oBox:SaveData()
	end

	tData.m_oTomorrowBox = {}
	for nBoxID, oBox in pairs(self.m_oTomorrowBox) do
		tData.m_oTomorrowBox[nBoxID] = oBox:SaveData()
	end
	tData.m_bFirstTask = self.m_bFirstTask
	tData.m_bComplete = self.m_bComplete
	tData.m_nCompleteReward = self.m_nCompleteReward
	tData.m_nComplteTaskTimes = self.m_nComplteTaskTimes
	tData.m_nBoxHelpTimes = self.m_nBoxHelpTimes
	tData.m_nHasHelpTimes = self.m_nHasHelpTimes
	tData.m_bPracticeState = self.m_bPracticeState
	tData.m_tBoxIndex = self.m_tBoxIndex
	tData.m_nCheckTime = self.m_nCheckTime
	tData.m_bPickTask = self.m_bPickTask
	return tData
end

function CBaHuangHuoZhen:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CBaHuangHuoZhen:IsDirty() return self.m_bDirty end
function CBaHuangHuoZhen:GetType() 
	return gtModuleDef.tBaHuangHuoZhen.nID, gtModuleDef.tBaHuangHuoZhen.sName
 end
function CBaHuangHuoZhen:Release()

 end

function CBaHuangHuoZhen:Online()
	local nNewTime = os.time()
	if nNewTime >= self.m_nCheckTime then
		self:CheckReset()
	end
	self:TaskInfoReq()
 end

function CBaHuangHuoZhen:IsSysOpen(bTips)
	local tActCfg = ctDailyActivity[gtDailyID.eBaHuangHuoZhen]
	assert(tActCfg or tActCfg.nSysOpenID > 0, "八荒火阵配置错误")
	return self.m_oRole.m_oSysOpen:IsSysOpen(tActCfg.nSysOpenID, bTips)
end

function CBaHuangHuoZhen:OnLevelChange(nNewLevel)
	self:OpenTaskCheck()
 end

function CBaHuangHuoZhen:GetRandomCfg(nID)
	if not nID then return end
	return ctBaHuangHuoZhenRandomProp[nID]
end

--获取单个宝箱
function CBaHuangHuoZhen:GetBoxObj(nBoxID)
	return self.m_oBoxMap[nBoxID]
end

function CBaHuangHuoZhen:OpenTaskCheck()
	if self:IsSysOpen() then
		if next(self.m_oBoxMap) == nil then
			self:InitBox()
		end
	end
end

function CBaHuangHuoZhen:OnHourTimer()
	if os.Hour(os.time()) == 5 then
		self:CheckReset()
		self:TaskInfoReq()
	end
end

function CBaHuangHuoZhen:CheckReset()
	self.m_tBoxIndex = {}
	self:CheckRewardState()

	self.m_bComplete = false		--是否完成八个箱子
	self.m_nCompleteReward = 0		--是否领取完成奖励
	self.m_nComplteTaskTimes = 0 	--当前完成的箱子数量
	self.m_nBoxHelpTimes = 0		--当前箱子求助数量
	self.m_nHasHelpTimes = 0		--已帮助封箱次数
	self.m_bPracticeState = false	--当前修炼技能是否达到上限 true为已经达到
	self.m_bPickTask =  false

	self.m_nCheckTime = self:GetResetTime()
	self:BoxReset()
	self:MarkDirty(true)
end

function CBaHuangHuoZhen:BoxReset()
	if not self:IsSysOpen() then 
		return 
	end
	if next(self.m_oTomorrowBox) then
		self.m_oBoxMap = self.m_oTomorrowBox
		self.m_oTomorrowBox = {}
	else
		self:InitBox()
	end
end

--初始化宝箱
 function CBaHuangHuoZhen:InitBox(bFalg)
 	print("初始化宝箱信息******************")
 	local tBoxListInfo = self:GetBox()
 	if not tBoxListInfo then 
 		LuaTrace("宝箱初始化数据错误:")
 		return 
 	end
	for nBoxID, tBox in pairs(tBoxListInfo) do
		local oBox =  CBaHuangHuoZhenBoxObj:new(self.m_oRole, self, nBoxID, tBox)
		if oBox then
			if bFalg then
				self.m_oTomorrowBox[nBoxID] = oBox
			else
				self.m_oBoxMap[nBoxID] = oBox
			end
		end
	end
 	self:MarkDirty(true)
 end

function CBaHuangHuoZhen:SetCompleteState(bState)
	self.m_bComplete = bState 
end

--获取总任务完成状态
 function CBaHuangHuoZhen:GetCompleteState()
 	return self.m_bComplete
 end

 function CBaHuangHuoZhen:SetCompleteRewardState(nState)
 	self.m_nCompleteReward = nState
 end

--获取领奖状态
 function CBaHuangHuoZhen:GetCompleteRewardState()
 	return self.m_nCompleteReward
 end

 function CBaHuangHuoZhen:GetPickTaskState()
 	return self.m_bPickTask
 end

function CBaHuangHuoZhen:SetPickTaskState(bNewState)
	self.m_bPickTask = bNewState
	self:MarkDirty(true)
end

 function CBaHuangHuoZhen:SetFirstTaskState(bState)
 	self.m_bFirstTask = bState
 	self:MarkDirty(true)
 end

function CBaHuangHuoZhen:GetFirstTaskState()
	return self.m_bFirstTask
end

function CBaHuangHuoZhen:SetHasHelpTimes(nTimes)
	if not nTimes and nTimes < 1 then return end
	self.m_nHasHelpTimes = self.m_nHasHelpTimes + nTimes
	self:MarkDirty(true)
end

function CBaHuangHuoZhen:GetHasHelpTimes()
	return self.m_nHasHelpTimes
end

--设置当前完成的任务数
function CBaHuangHuoZhen:SetComplteTaskTimes(nTimes)
	self.m_nComplteTaskTimes = self.m_nComplteTaskTimes + (nTimes or 0)
end

function CBaHuangHuoZhen:GetComplteTaskTimes()
	return self.m_nComplteTaskTimes
end

--设置当前求助次数
function CBaHuangHuoZhen:SetBoxHelpTimes(nTimes)
	self.m_nBoxHelpTimes = math.max(self.m_nBoxHelpTimes + (nTimes or 0), 0)
end

--获取当前求助次数
function CBaHuangHuoZhen:GetBoxHelpTimes()
	return self.m_nBoxHelpTimes
end

function CBaHuangHuoZhen:GetBox()
	local nRoleLevel = self.m_oRole:GetLevel()
	local tItemList = self:RandomBoxList(nRoleLevel)
	return tItemList
end

--获取剩余提交时间
function CBaHuangHuoZhen:GetOverTime()
	local nNextDayTime = os.MakeDayTime(os.time(),1,5)
	local nUpdeteTime = nNextDayTime - os.time()
	return nUpdeteTime
end

function CBaHuangHuoZhen:GetResetTime()
	 local nResetTime = os.MakeDayTime(os.time(),1,5)
	 return nResetTime
end

function CBaHuangHuoZhen:RandomBoxList(nRoleLevel)
	local tItemList, nWeight = self:GetRandomList(nRoleLevel)
	local nBoxID = 1
	local tBoxList = {}
	local tmpMap = {}
	for i = 1, 8, 1 do
		local rdValue = math.random(1, nWeight)
		local curValue = 0
		for _, v in pairs(tItemList) do
		    --if not tmpMap[v.nID] then
		        curValue = curValue + v.nProbability
		        if curValue >= rdValue then
		        	tBoxList[nBoxID] = v
		           -- tmpMap[v.nID] = true
		            nBoxID = nBoxID + 1
		            break
		        end
		    --end
		 end
	end
	return tBoxList
end

function CBaHuangHuoZhen:GetRandomList(nRoleLevel)
	local tItemList = {}
	--筛选出对应等级的道具
	local nWeight = 0
	for nPropID, tProp in pairs(ctBaHuangHuoZhenRandomProp) do
		if nRoleLevel >= tProp.nMinLevel and nRoleLevel <= tProp.nMaxLevel then
			nWeight = nWeight + tProp.nProbability
			tItemList[#tItemList+1] = tProp
		end
	end
	assert(#tItemList > 0 , "检查配置表道具最高等级")
	return tItemList, nWeight
end

--获取默认修炼技能状态
function CBaHuangHuoZhen:GetPracticeState()
	local bFalg = false
	local nPracticeSkillID = self.m_oRole.m_oPractice:GetDefauID()
	local tPracticeSkillCfg = ctPracticeConf[nPracticeSkillID]
	if not tPracticeSkillCfg then
		return self.m_oRole:Tips("修炼技能数据错误")
	end
	local tPracticeSkill =  self.m_oRole.m_oPractice:GetSkillInfo(nPracticeSkillID)
	if not tPracticeSkill then  return self.m_oRole:Tips("修炼技能数据错误") end

	--达到等级上限不能获得修炼经验
	local nSkillLevel = tPracticeSkill.nLevel
	local nSkillMaxLevel = self.m_oRole.m_oPractice:MaxLevel() 
	if nSkillLevel >= nSkillMaxLevel then
		bFalg = true
	end
	return bFalg 
end

--玩家没有领取奖励时,重置的时候通过邮件发送
function CBaHuangHuoZhen:CheckRewardState()
	if self:GetCompleteRewardState() == gtReeardState.eComplete then
		local tReeardCfg = ctBaHuangHuoZhenComplex[1].tCompleteTaskReward
		if not tReeardCfg or tReeardCfg[1][1] < 1 or tReeardCfg[1][2] < 1 then
			return self.m_oRole:Tips("奖励配置错误")
		end
		local tItemList = {{gtItemType.eProp, tReeardCfg[1][1], tReeardCfg[1][2]}}
		CUtil:SendMail(self.m_oRole:GetServer(), "八荒火阵任务获得", "八荒火阵任务获得,请查收", tItemList, self.m_oRole:GetID())
	end
end

--接取任务请求
function CBaHuangHuoZhen:PickupTaskReq()
	if not self:IsSysOpen(true) then
		-- self.m_oRole:Tips("系统暂未开放")
		return 
	end

	if self:GetPickTaskState() then
		return self.m_oRole:Tips("今日已经接取了任务")
	end
	if self:GetCompleteState() then
		return self.m_oRole:Tips("今日任务已经完成了哦")
	end
	self:SetPickTaskState(true)
	local tMsg = self:GetBoxInfoMsg()
	self.m_oRole:SendMsg("BaHuangHuoZhenPickupTaskRet", tMsg)
	self:TaskInfoReq(1)
end

function CBaHuangHuoZhen:TaskInfoReq(nType)
	if not self:IsSysOpen() then
		return 
	end

	--检查道具是否有修改
	self:BoxPropChexk()

	local tMsg = {}
	tMsg.nState = gtBoxTaskState.eNouJoin
	tMsg.tFirsItemList = {}
	tMsg.tCompleteList = {}
	tMsg.tBoxData = {}
	self:OpenTaskCheck()

	if self:GetCompleteState() and self:GetCompleteRewardState() ~= 2 then
		tMsg.nState = gtBoxTaskState.eJoin
		tMsg.tCompleteList = self:GetCompleteItem()
	elseif self:GetCompleteState() and self:GetCompleteRewardState() == 2 then
		tMsg.nState = gtBoxTaskState.eComplete
		tMsg.tCompleteList = self:GetCompleteItem()
	elseif self:GetPickTaskState() then
		tMsg.nState = gtBoxTaskState.eJoin
	end
	self:SendTaskInfoHandle(tMsg, nType)
end

function CBaHuangHuoZhen:SendTaskInfoHandle(tMsg, nType, fnCallBack)
	-- local nServerID = self.m_oRole:GetServer()
	-- local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)
	-- local nServerLv = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	-- local tItemList,tBoxItemList = self:GetBoxCostProp()
	-- local fnGetItemBasePriceCallBack = function (tItemList)
	-- 	if not tItemList or #tItemList <= 0 then return end
	-- 	for nBoxID, nPropID in pairs(tBoxItemList) do
	-- 		for _,  tItem in ipairs(tItemList) do
	-- 			if nPropID == tItem.nItemID then
	-- 				local oBox = self.m_oBoxMap[nBoxID]
	-- 				oBox:PracticeExpHandle(tItem.nBasePrice, self.m_oRole)
	-- 			end
	-- 		end
	-- 	end
	-- 	tMsg.tBoxData = self:GetBoxChangeMsg().tBoxData
	-- 	tMsg.nPushType = nType and nType or 2
	-- 	self:SendTaskBaseInfo(tMsg, nType)
	-- end
	-- Network:RMCall("GetMultipleItemBasePriceReq", fnGetItemBasePriceCallBack, nServerID, nGlobalLogic, 0, self.m_oRole:GetID(), tItemList)
	local fnCallBack = function ()
			tMsg.tBoxData = self:GetBoxChangeMsg().tBoxData
			tMsg.nPushType = nType and nType or 2
			self:SendTaskBaseInfo(tMsg, nType)
	end
	self:PracticeExpHandle(fnCallBack)
end

function CBaHuangHuoZhen:PracticeExpHandle(fnCallBack)
	local nServerID = self.m_oRole:GetServer()
	local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)
	local nServerLv = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	local tItemList,tBoxItemList = self:GetBoxCostProp()
	local fnGetItemBasePriceCallBack = function (tItemList)
		if not tItemList or #tItemList <= 0 then return end
		for nBoxID, nPropID in pairs(tBoxItemList) do
			for _,  tItem in ipairs(tItemList) do
				if nPropID == tItem.nItemID then
					local oBox = self.m_oBoxMap[nBoxID]
					oBox:PracticeExpHandle(tItem.nBasePrice, self.m_oRole)
				end
			end
		end
		fnCallBack()
	end
	Network:RMCall("GetMultipleItemBasePriceReq", fnGetItemBasePriceCallBack, nServerID, nGlobalLogic, 0, self.m_oRole:GetID(), tItemList)
end

function CBaHuangHuoZhen:SendTaskBaseInfo(tMsg)
	self.m_oRole:SendMsg("BaHuangHuoZhenInfoTaskRet", tMsg)
end

function CBaHuangHuoZhen:GetBoxCostProp()
	local tItemList = {}
	local tTempList = {}
	local tBoxItemList = {}
	for nBoxID, oBox in pairs(self.m_oBoxMap) do
		local nPropID = oBox:GetPropID()
		local nItemID = self:GetCostProp(nPropID)
		tBoxItemList[nBoxID] = nItemID
		if not tTempList[nPropID] then
			table.insert(tItemList, nItemID)
			tTempList[nPropID] = true
		end
	end
	return tItemList, tBoxItemList
end

function CBaHuangHuoZhen:GetCostProp(nPropID)
	local nItemID
	local tPropCfg = ctBaHuangHuoZhenRandomProp[nPropID]
	assert(tPropCfg, string.format("八荒道具配置错误<%d>ID", nPropID))
	if tPropCfg.tSubPropID[1][1] ~= 0 then
		local nServerLv = self:GetServerLevel()
		local nStar = ctBaHuangHuoZhenComplex[1].eFnSpecialMedicine(nServerLv)
		nStar = nStar > 10 and 10 or nStar
		assert(tPropCfg.tSubPropID[nStar], string.format("八荒道具配置错误<%d>星级", nStar))
		assert(ctPropConf[tPropCfg.tSubPropID[nStar][1]], string.format("八荒道具配置错误<%d>ID", tPropCfg.tSubPropID[nStar][1]))
		nItemID = tPropCfg.tSubPropID[nStar][1]
		return  nItemID
	else
		return nPropID
	end
end

function CBaHuangHuoZhen:GetServerLevel()
	local nServerLv = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	return nServerLv
end
function CBaHuangHuoZhen:GetCompleteItem()
	local tItemList = {}
	for _, nBoxID in pairs(self.m_tBoxIndex) do
		local oBox = self.m_oTomorrowBox[nBoxID]
		if oBox and self:GetRandomCfg(oBox:GetPropID()) then
			local tItem = self:GetRandomCfg(oBox:GetPropID())
			tItemList[#tItemList+1] = {nID = tItem.nID, nNum = tItem.nNum}
		end
	end
	return tItemList
end

--领取奖励
function CBaHuangHuoZhen:ReceiveReq()
	if self.m_nComplteTaskTimes ~= nMaxBoxTimes then
		return self.m_oRole:Tips("还有物品未填满,您不能领取奖励")
	end
	if self.m_nCompleteReward == gtReeardState.eReceive then
		return self.m_oRole:Tips("你已经领取奖励,不能重复领取")
	end
	local tReeardCfg = ctBaHuangHuoZhenComplex[1].tCompleteTaskReward
	if not tReeardCfg or tReeardCfg[1][1] < 1 or tReeardCfg[1][2] < 1 then
		return self.m_oRole:Tips("奖励配置错误")
	end
	self.m_oRole:AddItem(gtItemType.eProp, tReeardCfg[1][1], tReeardCfg[1][2], "八荒火阵任务获得")
	self.m_nCompleteReward = gtReeardState.eReceive
	self:MarkDirty(true)
	local tMsg = {}
	tMsg.nState = gtReeardState.eReceive
	print("领奖消息", tMsg)
	self.m_oRole:SendMsg("BaHuangHuoZhenReceiveRet", tMsg)
	self:TaskInfoReq(1)
end

--装箱请求
function CBaHuangHuoZhen:PackingReq(nBoxID, tItemList)
	if self:GetCompleteState() and self:GetPickTaskState() then
		return  self.m_oRole:Tips("这是明日的宝箱哦")
	end
	if self:GetCompleteState() then
		return self.m_oRole:Tips("宝箱已经全部完成")
	end
	local oBox = self.m_oBoxMap[nBoxID]
	if not oBox  then return self.m_oRole:Tips("宝箱不存在") end
	if oBox:GetBoxState() == gtBoxState.eComplete then
		return self.m_oRole:Tips("该宝箱已经完成,不用重复装箱")
	end
	if not self:SubItemCheck(oBox:GetPropID(), oBox:GetPropNum()) then
		return 
	end
	--处理装箱操作
	self:CheckPracticeSkill(oBox)
	--玩家等级低于服务器等级10级将获得任务经验奖励
	self:GetExpCheck()
	--自己装箱,减掉
	if oBox:GetBoxState() ==  gtBoxState.eSeekHelp then
		self:SetBoxHelpTimes(-1)
	end
	--箱子状态处理，对求助的玩家发邮件
	oBox:SetBoxState(1)
	self:SetComplteTaskTimes(1)
	if self:GetComplteTaskTimes() == nMaxBoxTimes then
		--全部箱子装箱完成
		self.m_oRole.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eBaHuangHuoZhen, "八荒火阵")
		self:SetCompleteRewardState(1)
		self:SetCompleteState(true)
		--self:SetPickTaskState(false)
		self:TaskCompleteHandle()
	end

	self:MarkDirty(true)
	local tMsg = self:GetBoxChangeMsg(oBox)
	print("装箱请求消息", tMsg)
	self.m_oRole:SendMsg("BaHuangHuoZhenBoxChangeRet", tMsg)
	--self:BoxListReq()
	self.m_oRole:Tips("装箱成功")
	print("self.m_nComplteTaskTimes", self.m_nComplteTaskTimes)
end

function CBaHuangHuoZhen:GetExpCheck(bReturn)
	local nServerLv = goServerMgr:GetServerLevel(self.m_oRole:GetServer())
	local nRoleLevel = self.m_oRole:GetLevel()
	if nRoleLevel <= nServerLv - 10 then
		local nRoleExp = ctBaHuangHuoZhenComplex[1].eFnRoleRewardExp(nRoleLevel)
		if bReturn then
			return nRoleExp
		else
			self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, nRoleLevel, "八荒火阵装箱获得")
		end
	end
end

--检查道具是否满足装箱,主要是一些特殊药品
function CBaHuangHuoZhen:SubItemCheck(nPropID, nPropNum)
	--assert(tItemList or next(tItemList), "装箱数据错误")
	local tItemCfg = ctBaHuangHuoZhenRandomProp[nPropID]
	local nSumNum = 0
	local tSubItemList = {}
	local bSpecialProp = tItemCfg.tSubPropID[1][1] ~= 0 and true or false
	assert(tItemCfg, string.format("八荒配置道具错误<%d>", nPropID))

	local tSubItemList = {}
	if bSpecialProp then
		--采用连续遍历
		local nItemNum = 0
		local nSubItemNum = 0
		for _, tItem in ipairs(tItemCfg.tSubPropID) do
			local nNum = self.m_oRole:ItemCount(gtItemType.eProp, tItem[1])
			if nNum > 0 then
				local nOverNum = nPropNum - nSubItemNum
				nNum = nNum > nOverNum and nOverNum or nNum
				table.insert(tSubItemList, {gtItemType.eProp, tItem[1], nNum})
				nSubItemNum = nSubItemNum + nNum
				if nSubItemNum >= nPropNum then
					break
				end
			end
		end
		if nSubItemNum < nPropNum then
			return self.m_oRole:Tips("道具数量不足")
		end
	else
		table.insert(tSubItemList, {gtItemType.eProp, nPropID, nPropNum})
	end
	local bRet = self.m_oRole:CheckSubItemList(tSubItemList, "装箱消耗")
	--防止这个调用期间,道具数量发生了变化
	if not bRet then
		return self.m_oRole:Tips("道具数量不足")
	end
	return true
end

--任务完成处理
function CBaHuangHuoZhen:TaskCompleteHandle()
	--清掉之前的box信息
	--self.m_oBoxMap = {}
	self:InitBox(true)
	--随机抽取五个箱子的道具显示在接取界面
	local nWeight = 0
	for BoxID, oBox in pairs(self.m_oTomorrowBox) do
		if ctBaHuangHuoZhenRandomProp[oBox:GetPropID()] then
			nWeight =  nWeight + ctBaHuangHuoZhenRandomProp[oBox:GetPropID()].nProbability
		end
	end
	local tBoxList = {}
	local tmpMap = {}
	for i = 1, 3, 1 do
		local rdValue = math.random(1, nWeight)
		local curValue = 0
		for nBoxID, oBox in pairs(self.m_oTomorrowBox) do
		    if not tBoxList[nBoxID] then
		    	local nProbability = ctBaHuangHuoZhenRandomProp[oBox:GetPropID()].nProbability
		        curValue = curValue + nProbability
		        if curValue >= rdValue then
		           	tmpMap[i] = nBoxID
		           	tBoxList[nBoxID] = true
		           	nWeight = nWeight - nProbability
		            break
		        end
		    end
		 end
	end
	self.m_tBoxIndex = tmpMap
	self:MarkDirty(true)
end

--宝箱求助
function CBaHuangHuoZhen:BoxHelpReq(nBoxID, nType)
	local oBox = self.m_oBoxMap[nBoxID]
	if not oBox then
		return self.m_oRole:Tips("宝箱不存在")
	end

	if self:GetCompleteState() and self:GetPickTaskState() then
		return  self.m_oRole:Tips("这是明日的宝箱哦")
	end

	if oBox:GetBoxState() == gtBoxState.eSeekHelp then
		return self.m_oRole:Tips("该宝箱已经求助,不能重复求助")
	end

	if self:GetBoxHelpTimes() >= nMaxHelpTimes then
		return self.m_oRole:Tips(string.format("每天只能发布%d个材料求助",nMaxHelpTimes))
	end

	if self:GetComplteTaskTimes() < nMinTaskTimes then
		return self.m_oRole:Tips("寻求帮助需要你自己先完成5个箱子的的装填")
	end
	self:UnionHelp(oBox)
end

--帮派求助
function CBaHuangHuoZhen:UnionHelp(oBox)
	local nServerID = self.m_oRole:GetServer()
	local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)

	if self:GetCompleteState() and self:GetPickTaskState() then
		return  self.m_oRole:Tips("这是明日的宝箱哦")
	end
	local fnGetUnionCallBack = function (nUnionID)
		if not nUnionID then
			return self.m_oRole:Tips("您还没有帮派，加入帮派后可发布帮派求助")
		end

		oBox:SetBoxState(2)
		self:SetBoxHelpTimes(1)
		self:MarkDirty(true)
		--宝箱信息变化
		local tMsg = self:GetBoxChangeMsg(oBox)
		print("求助宝箱信息变更", tMsg)
		self.m_oRole:SendMsg("BaHuangHuoZhenBoxChangeRet", tMsg)
		--发一个帮派消息,通知帮派好友装箱
		local tTalkConf = ctTalkConf["boxhelp"]  --TODO
		local sPropName = ctPropConf[oBox:GetPropID()].sName
		local sContent = string.format(tTalkConf.sContent, self.m_oRole:GetName(), sPropName .. "*" .. oBox:GetPropNum(), oBox:GetBoxID(), self.m_oRole:GetID())

		local nGlobalService = goServerMgr:GetGlobalService(gnWorldServerID, 110)
		Network:RMCall("SendUnionTalkReq", nil, gnWorldServerID, nGlobalService, 0, self.m_oRole:GetID(), sContent)		
	end
	Network:RMCall("GetPlayerUnionReq", fnGetUnionCallBack, nServerID, nGlobalLogic, 0, self.m_oRole:GetID())

end

function CBaHuangHuoZhen:GetBoxInfoList(oRole)
	local tBoxList = {}
	for nBoxID, oBox in pairs(self.m_oBoxMap) do
		tBoxList[#tBoxList+1] = oBox:GetBoxInfo(oRole)
	end	
	return tBoxList
end

function CBaHuangHuoZhen:GetHelpBoxID()
	local tBoxID = {}
	for _, oBox in pairs(self.m_oBoxMap) do
		if oBox:GetBoxState() == gtBoxState.eSeekHelp then
			table.insert(tBoxID, oBox:GetBoxID())
		end
	end
	return tBoxID
end

--宝箱列表信息请求
function CBaHuangHuoZhen:BoxListReq()
	local tMsg = self:GetBoxInfoMsg()
	if tMsg then
		self.m_oRole:SendMsg("BaHuangHuoZhenBoxListRet", tMsg)
	end
end

function CBaHuangHuoZhen:GetBoxInfoMsg()
	if not self:IsSysOpen(true) then
		-- self.m_oRole:Tips("系统暂未开放")
		return
	end
	--为了以防开启条件修改,使用的时候检测一次
	self:OpenTaskCheck()

	local tBoxList = {}
	for nBoxID, oBox in pairs(self.m_oBoxMap) do
		tBoxList[#tBoxList+1] = oBox:GetBoxInfo(self.m_oRole)
	end
	local tMsg = {}
	local tBoxData = {}
	tBoxData.nHelpTimes = self.m_nHasHelpTimes
	tBoxData.nCurHelpTimes = self.m_nBoxHelpTimes
	tBoxData.nOverTime = self:GetOverTime()
	tBoxData.bHelpButton = self:GetHelpButtonState()
	tBoxData.nState = self.m_nCompleteReward
	tBoxData.bPracticeState = self:GetPracticeState() or false
	tBoxData.tBoxList = tBoxList
	tBoxData.tCompleteList = self:GetCompleteItem()
	tMsg.tBoxData = tBoxData
	return tMsg
end

--请求获取求助玩家宝箱信息
function CBaHuangHuoZhen:HelpPlayerBoxListReq(nHelpRoleID,  nBoxID)
	if self.m_oRole:GetID() == nHelpRoleID then
		return self.m_oRole:Tips("你无法打开自己的求助内容")
	end
	local nServerID = self.m_oRole:GetServer()
	local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)
	local nRoleLevel = self.m_oRole:GetLevel()
	 local nLevelLimit = ctDailyActivity[gtDailyID.eBaHuangHuoZhen].nOpenLimit
	if nRoleLevel < nLevelLimit then
		return self.m_oRole:Tips(string.format("完成八荒火阵求助需等级达到%d级", nLevelLimit))
	end
	local fnGetUnionCallBack = function (nRoleUnionID, nTarRoleUnioiD)
		if not nTarRoleUnioiD then
			return self.m_oRole:Tips("求助玩家当前没有帮派哦")
		end
		if not nRoleUnionID then
			return self.m_oRole:Tips("当前你没有帮派哦")
		end

		if nRoleUnionID ~= nTarRoleUnioiD then
			return self.m_oRole:Tips("必须是同帮派的才能帮助哦")
		end

		local nServerID = self.m_oRole:GetServer()
		local nServiceID = goServerMgr:GetGlobalService(nServerID,20)
		Network:RMCall("GetHelpRoleDataReq", nil, nServerID, nServiceID, 0,self.m_oRole:GetID(), nHelpRoleID,nBoxID)
	end
	Network:RMCall("GetPlayerUnionReq", fnGetUnionCallBack, nServerID, nGlobalLogic, 0, self.m_oRole:GetID(), nHelpRoleID)
end

function CBaHuangHuoZhen:HelpRoleInfoHdanle(nHelpRoleID,nBoxID, tList)
	local tMsg = {}
	tMsg.nRoleID = nHelpRoleID
	tMsg.tBoxList = tList
	tMsg.tBoxID = {}
	table.insert(tMsg.tBoxID, nBoxID)
	return tMsg
end

--帮助玩家装箱请求
function CBaHuangHuoZhen:HelpPackingBoxReq(nHelpRoleID, nBoxID, tItemList)
	local nServerID = self.m_oRole:GetServer()
	local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)
	if self.m_oRole:GetID() == nHelpRoleID then
		return self.m_oRole:Tips("你无法打开自己的求助内容")
	end
	--等级没有达到任务开发等级.则不能帮助求助
	local nRoleLevel = self.m_oRole:GetLevel()
	 local nLevelLimit = ctDailyActivity[gtDailyID.eBaHuangHuoZhen].nOpenLimit
	if nRoleLevel < nLevelLimit then
		return self.m_oRole:Tips(string.format("完成八荒火阵求助需等级达到%d级", nLevelLimit))
	end
	local fnGetUnionCallBack = function (nRoleUnionID, nTarRoleUnioiD)
		if not nTarRoleUnioiD then
			return self.m_oRole:Tips("求助玩家当前没有帮派哦")
		end
		if not nRoleUnionID then
			return self.m_oRole:Tips("当前你没有帮派哦")
		end
		if nRoleUnionID ~= nTarRoleUnioiD then
			return self.m_oRole:Tips("必须是同帮派的才能帮助哦")
		end
		if self:GetHasHelpTimes() >= ctBaHuangHuoZhenComplex[1].nHelpTiems then
			return self.m_oRole:Tips(string.format("今天已完成了%d次八荒火阵的求助", self:GetHasHelpTimes()))
		end
		Network:RMCall("HelpPackingBoxReq", nil, nServerID, nGlobalLogic, 0, self.m_oRole:GetID(), nHelpRoleID, nBoxID)
	end
	Network:RMCall("GetPlayerUnionReq", fnGetUnionCallBack, nServerID, nGlobalLogic, 0, self.m_oRole:GetID(), nHelpRoleID)
end

function CBaHuangHuoZhen:HelpPackingBoxHandle(nBoxID)

end

function CBaHuangHuoZhen:GetBoxChangeMsg(oBox)
	local tMsg = {}
	local tBoxData = {}
	tBoxData.tBoxList = {}
	tBoxData.nHelpTimes = self.m_nHasHelpTimes
	tBoxData.nCurHelpTimes = self.m_nBoxHelpTimes
	tBoxData.nOverTime = self:GetOverTime()
	tBoxData.bHelpButton = self:GetHelpButtonState()
	tBoxData.nState = self.m_nCompleteReward
	tBoxData.bPracticeState = self:GetPracticeState() or false
	if oBox then
		table.insert(tBoxData.tBoxList, oBox:GetBoxInfo(self.m_oRole))
	else
		tBoxData.tBoxList = self:GetBoxInfoList(self.m_oRole)
	end
	--adb()
	tBoxData.tCompleteList = self:GetCompleteItem()
	tMsg.tBoxData = tBoxData
	return tMsg
end

function CBaHuangHuoZhen:GetHelpButtonState()
	local bFalg = false
	if self.m_nComplteTaskTimes >= 5 then
		if self:GetBoxHelpTimes() < nMaxHelpTimes then
			bFalg =  true
		end
	end
	return bFalg
end

--获取修炼技能经验检查
function CBaHuangHuoZhen:CheckPracticeSkill(oBox, bReturn)
	local nPracticeSkillID = self.m_oRole.m_oPractice:GetDefauID()
	local tPracticeSkillCfg = ctPracticeConf[nPracticeSkillID]
	if not tPracticeSkillCfg then
		return self.m_oRole:Tips("修炼技能数据错误")
	end
	local tPracticeSkill =  self.m_oRole.m_oPractice:GetSkillInfo(nPracticeSkillID)
	if not tPracticeSkill then  return self.m_oRole:Tips("修炼技能数据错误") end

	--达到等级上限不能获得修炼经验
	local nSkillLevel = tPracticeSkill.nLevel
	local nSkillMaxLevel = self.m_oRole.m_oPractice:MaxLevel() 
	if nSkillLevel < nSkillMaxLevel then
		 local nPracticeExp = oBox:GetPracticeExp()
		 if bReturn then
		 	return nPracticeExp
		 else
		 	self:addPractice(nPracticeExp)
		 end
	end
end

function CBaHuangHuoZhen:addPractice(nExp)
		self.m_oRole:AddItem(gtItemType.eCurr, gtCurrType.ePracticeExp, nExp, "八荒火阵装箱获得")
		local sTips = self:GetPracticeTips(self.m_oRole.m_oPractice:GetDefauID(), nExp)
		self.m_oRole:Tips(sTips)
end

function CBaHuangHuoZhen:GetPracticeTips(nDefauID, nExp)
	local sTipsCfg = ctTalkConf["addpracticeexp"]
	local sName = ctPracticeConf[nDefauID].sName
	local sTips = string.format(sTipsCfg.sContent, nExp, sName)
	return sTips
end

--修炼技能改变通知
function CBaHuangHuoZhen:PracticeChange()
	local tMsg = {}
	tMsg.bPracticeState = self:GetPracticeState()
	self.m_oRole:SendMsg("BaHuangHuoZhenPracticeChangeRet", tMsg)
end

--宝箱道具检查,存数据库的没有了，就随机一个吧
function CBaHuangHuoZhen:BoxPropChexk()
	local function fnGetWeight (tNode) return tNode.nProbability end
	local tItemList = self:GetRandomList(self.m_oRole:GetLevel())
	local bFalg = false
	for nBoxID, oBox in pairs(self.m_oBoxMap) do
		local nPropID = oBox:GetPropID()
		if not ctBaHuangHuoZhenRandomProp[nPropID] then
			LuaTrace("八荒道具配置已删除:", nPropID)
			local tResut = CWeightRandom:Random(tItemList, fnGetWeight, 1, false)
			LuaTrace("随机新一个新的八荒道具:", tResut[1].nID)
			oBox:SetPropID(tResut[1].nID)
			oBox:SetPropNum(tResut[1].nNum)
			bFalg = true
		end
	end
	if bFalg then
		self:MarkDirty(true)
	end
end

--摆摊获取需要刷新的消耗道具
function CBaHuangHuoZhen:GetCommitItem()
	local tItemList = {}
	for _, oBox in pairs(self.m_oBoxMap) do
		if oBox:GetBoxState() ~= gtBoxState.eComplete and self:GetPickTaskState() then
			local nPropID = oBox:GetPropID()
			if ctBaHuangHuoZhenRandomProp[nPropID] then
				local tProp = ctBaHuangHuoZhenRandomProp[nPropID]
				if tProp.tSubPropID[1][1] ~= 0 then
					for _, tItem in ipairs(tProp.tSubPropID) do
						if ctBourseItem[tItem[1]] then
							tItemList[tItem[1]] = (tItemList[tItem[1]] or 0) + 1
						end
					end
				else
					if ctBourseItem[nPropID] then
						tItemList[nPropID] = (tItemList[nPropID] or 0) + 1
					end
				end
			end
		end
	end
	return tItemList
end

--取玩家任务数据
function CBaHuangHuoZhen:GetHelpRoleData(nRoleID, nHeleRoleID, nBoxID)
	local tList = {}
	local oBox = self:GetBoxObj(nBoxID)
	local sTips 
	if not oBox then
		sTips = "宝箱数据错误"
	end

	if oBox and oBox:GetBoxState() == gtBoxState.eComplete then
		sTips = "该宝箱已经完成"
	end

	local fnCallBack = function ()
		local nServerID = self.m_oRole:GetServer()
		local nGlobalLogic = goServerMgr:GetGlobalService(nServerID, 20)
		tList = self:GetBoxInfoList(self.m_oRole)
		local tMsg = self:HelpRoleInfoHdanle(nRoleID, nBoxID, tList)
		Network:RMCall("PushHelpRoleBoxReq", nil, nServerID, nGlobalLogic, 0, self.m_oRole:GetID(), nHeleRoleID,tMsg, sTips)
	end
	 self:PracticeExpHandle(fnCallBack)
end

--nType=0,nID=0,nNum=0
function CBaHuangHuoZhen:HelpPackingBoxCheck(nRoleID, nBoxID)
	local tSubItemList = {}
	local tAddItemList = {}
	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
	local tList = {}
	if not oRole  then 
		return "该玩家已经下线哦", tSubItemList
	end
	local oBox = oRole.m_oBaHuangHuoZhen:GetBoxObj(nBoxID)
	if not oBox then
		return "宝箱数据错误", tSubItemList
	end
	if oBox:GetBoxState() == gtBoxState.eComplete then
		return "该宝箱已经完成", tSubItemList
	end
	self:TaskInfoReq()
	tSubItemList.nID = oBox:GetPropID()
	tSubItemList.nNum = oBox:GetPropNum()
	local tAddItemList = {}

	--TODD,顺序添加
	--获取装箱修炼经验
	 local nPracticeExp = self:CheckPracticeSkill(oBox, true)
	 if nPracticeExp then
	 	nPracticeExp = nPracticeExp > 0 and nPracticeExp or 50
	 	 table.insert(tAddItemList, {nType = gtItemType.eCurr, nID = gtCurrType.ePracticeExp, nNum = nPracticeExp})
	 end

	 local nRoleExp = self:GetExpCheck(true)
	 if nRoleExp then
	 	 table.insert(tAddItemList, { nType = gtItemType.eCurr, nID = gtCurrType.eExp, nNum = nRoleExp})
	 end

	--添添加帮贡
	local nUnionContri = ctBaHuangHuoZhenComplex[1].nUnionTimes
	table.insert(tAddItemList, {nType = gtItemType.eCurr,  nID = gtCurrType.eUnionContri,  nNum = nUnionContri})
	return true, tSubItemList, tAddItemList
end

function CBaHuangHuoZhen:HelpPackingBoxCheckHandle(nHeleRoleID,nBoxID, tData)
	local oBox = self:GetBoxObj(nBoxID)
	if not oBox then return end
	oBox:SetBoxState(1)
	self:SetComplteTaskTimes(1)
	if self:GetComplteTaskTimes() == nMaxBoxTimes then
		--全部箱子装箱完成
		self.m_oRole.m_oDailyActivity:OnCompleteDailyOnce(gtDailyID.eBaHuangHuoZhen, "八荒火阵")
		self:SetCompleteRewardState(1)
		self:SetCompleteState(true)
		self:TaskCompleteHandle()
	end
	self:MarkDirty(true)
	local tMsg = self:GetBoxChangeMsg(oBox)
	self.m_oRole:SendMsg("BaHuangHuoZhenBoxChangeRet", tMsg)

	--发布完成信息
	local tTalkConf = ctTalkConf["completehelp"]  --TODO
	local nPropID = oBox:GetPropID()
	local nNum = oBox:GetPropNum()
	local sContent = string.format(tTalkConf.sContent,tData.sName , self.m_oRole:GetName(),ctPropConf[nPropID].sName .. "*" .. nNum)
	local nGlobalService = goServerMgr:GetGlobalService(gnWorldServerID, 110)
	Network:RMCall("SendUnionTalkReq", nil, gnWorldServerID, nGlobalService, 0, tData.nRoleID, sContent)

	local sRoleTips = "你今天已完成求助%d次，每天最多完成求助%d次"
	sRoleTips = string.format(sRoleTips, tData.nHelpTimes, nMaxHelpPackingBoxTimes)
	local sPracticeTips
	if tData.nPracticeExp then
		 sPracticeTips= self:GetPracticeTips(tData.nDefauID, tData.nPracticeExp)
	end
	--发送一封完成邮件给求助的玩家
	local sTitle = "求助完成"
	local sContent = "你发布的%s*%d求助，已被帮派的%s完成封箱"
	local sPropName = ctPropConf[oBox:GetPropID()].sName
	sContent = string.format(sContent, sPropName, oBox:GetPropNum(), tData.sName)
	--CUtil:SendMail(tData.nServerID, sTitle, sContent, {}, tData.nRoleID)
	CUtil:SendMail(self.m_oRole:GetServer(), sTitle, sContent, {}, self.m_oRole:GetID())
	return tMsg, sRoleTips, sPracticeTips
end

function CBaHuangHuoZhen:ResettAct()
	self:CheckReset()
	self.m_oRole:Tips("清除成功")
end
