--花轿游行
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CPalanquin:Ctor(nID, nHusband, nWife)
	assert(nID > 0, "参数错误")
	self.m_nID = nID
	self.m_nHusband = nHusband
	self.m_nWife = nWife
	self.m_nTimer = nil
	self.m_nConfirmBoxID = 0
	self.m_nPalanquinStep = 0  --当前行进阶段
	-- self.m_nStepStamp = 0      --行进阶段开始的时间戳
	self.m_nStartStamp = 0      --开始游行时间戳
	self.m_nPalanquinNpcID = 0

	self.m_nPlanRunTime = 0
end

function CPalanquin:GetID() return self.m_nID end
function CPalanquin:GetHusbandID() return self.m_nHusband end
function CPalanquin:GetWifeID() return self.m_nWife end
function CPalanquin:GetConfirmBoxID() return self.m_nConfirmBoxID end
function CPalanquin:GetConfirmBox() return goMultiConfirmBoxMgr:GetConfirmBox(self.m_nConfirmBoxID) end
function CPalanquin:IsRunning() return self.m_nPalanquinStep > 0 end
function CPalanquin:GetPalanquinStep() return self.m_nPalanquinStep end
function CPalanquin:GetPalanquinStepConf() return ctPalanquinWayConf["common_3036"] end
function CPalanquin:GetRunTime()
	local nTime = 0
	if self.m_nPalanquinStep > 0 then 
		nTime = os.time() - self.m_nStartStamp
	end
	return nTime
end
function CPalanquin:GetRunRemainTime(nTimeStamp)
	nTimeStamp = nTimeStamp or os.time()
	local nRemainTime = 0
	if self.m_nPlanRunTime + self.m_nStartStamp - nTimeStamp > 0 then 
		nRemainTime = self.m_nPlanRunTime + self.m_nStartStamp - nTimeStamp
	end
	return nRemainTime
end 

function CPalanquin:Start()
	assert(self.m_nHusband > 0 and self.m_nWife > 0 and self.m_nID > 0, "数据错误")
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
	if not oHusband or not oWife then
		self:Release()
		return
	end

    local oMultiConfirmBox = goMultiConfirmBoxMgr:CreateConfirmBox("申请确认框", {"您是否愿意与伴侣一同乘坐花轿，分享幸福？"}, 30)
    self.m_nConfirmBoxID = oMultiConfirmBox:GetID()

    local nAgreeButtonID = 100

    local oHusbandConfirm = oMultiConfirmBox:InsertRoleConfirmData(self.m_nHusband)
    oHusbandConfirm:UpdateButton(gnMultiConfirmBoxCancelButtonID, "我再想想", true)
    oHusbandConfirm:UpdateButton(nAgreeButtonID, "我愿意", true)

    local oWifeConfirm = oMultiConfirmBox:InsertRoleConfirmData(self.m_nWife)
    oWifeConfirm:UpdateButton(gnMultiConfirmBoxCancelButtonID, "我再想想", true)
    oWifeConfirm:UpdateButton(nAgreeButtonID, "我愿意", true)

    local fnConfirmCallback = function (nRoleID, nSelButton)
    	if nSelButton == nAgreeButtonID then
    		local oConfirmBox = self:GetConfirmBox()
    		assert(oConfirmBox)
    		if oConfirmBox:IsAllConfirmed() then
				self:CleanConfirmBox()
				self:AfterRentConfirm()
    			return
    		end
    		local oRoleConfirm = (nRoleID == oHusband:GetID()) and oHusbandConfirm or oWifeConfirm
    		local tButton = oRoleConfirm:GetButton(gnMultiConfirmBoxCancelButtonID)
    		tButton.bActive = false
    		tButton = oRoleConfirm:GetButton(nAgreeButtonID)
    		tButton.bActive = false
    		oRoleConfirm:SetCanCancel(false)
    		oRoleConfirm:SetContentList({"正在等待对方同意"})
    		oConfirmBox:SyncRoleConfirmBox(nRoleID) --同步单个玩家的即可
    	else
    		assert(false, "系统数据异常")
    	end
    end

    local fnCancelCallback = function (nRoleID)
    	local oRole = (nRoleID == oHusband:GetID()) and oHusband or oWife
    	local oTar = (nRoleID == oHusband:GetID()) and oWife or oHusband
    	oRole:Tips("您已经取消了租赁申请")
    	oTar:Tips("对方取消了租赁申请")
    	self:Release()
    end

    local fnTimeOutCallback = function ()
    	self:Release()
    	local sTipsContent = "申请已超时，请重新申请！"
    	oHusband:Tips(sTipsContent)
    	oWife:Tips(sTipsContent)
    end

    oMultiConfirmBox:SetRoleConfirmCallback(fnConfirmCallback)
    oMultiConfirmBox:SetRoleCancelCallback(fnCancelCallback)
    oMultiConfirmBox:SetTimeOutCallback(fnTimeOutCallback)
    oMultiConfirmBox:SyncAllConfirmBox()


	oHusband:SetActState(gtRoleActState.ePalanquinApply)
	oWife:SetActState(gtRoleActState.ePalanquinApply)
end

--自我销毁
function CPalanquin:Release()
	print("花轿开始销毁")
	goMarriageSceneMgr:RemovePlanquin(self.m_nID)
end

function CPalanquin:CleanConfirmBox()
	if self.m_nConfirmBoxID > 0 then
		local oConfirmBox = self:GetConfirmBox()
		if oConfirmBox then
			oConfirmBox:NotifyDestroyAllConfirmBox()
			goMultiConfirmBoxMgr:RemoveConfirmBox(self.m_nConfirmBoxID)
		end
	end
	self.m_nConfirmBoxID = 0
end

function CPalanquin:CleanTimer()
	if self.m_nTimer then
		goTimerMgr:Clear(self.m_nTimer)
		self.m_nTimer = nil
	end
end

--管理器中资源已删除了，这里只能使用本对象内资源
function CPalanquin:OnRelease()
	print("花轿资源清理")
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
	oHusband:ResetActState(true)
	oWife:ResetActState(true)
	self:CleanConfirmBox()
	self:CleanTimer()
	if self.m_nPalanquinNpcID > 0 then 
		goMonsterMgr:RemoveMonster(self.m_nPalanquinNpcID)
	end
end


function CPalanquin:AfterRentConfirm()
	local nTotalCost = 1314
	local nHalfCost = math.ceil(nTotalCost / 2)
	local sCommonContent = string.format("支付 %d 元宝即可租赁花轿游览三生殿，期间无法移动！", nTotalCost)
    local oMultiConfirmBox = goMultiConfirmBoxMgr:CreateConfirmBox("租赁费用确认框", {sCommonContent}, 60)
    self.m_nConfirmBoxID = oMultiConfirmBox:GetID()

	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)

    local nPayTotalButton = 100      
    local nPayHalfButton = 200

    local oHusbandConfirm = oMultiConfirmBox:InsertRoleConfirmData(self.m_nHusband)
    oHusbandConfirm:UpdateButton(nPayTotalButton, "全部支付", true)
    oHusbandConfirm:UpdateButton(nPayHalfButton, "分摊支付", true)

    local oWifeConfirm = oMultiConfirmBox:InsertRoleConfirmData(self.m_nWife)
    oWifeConfirm:UpdateButton(nPayTotalButton, "全部支付", true)
    oWifeConfirm:UpdateButton(nPayHalfButton, "分摊支付", true)

    local fnConfirmCallback = function (nRoleID, nSelButton)
    	local oRole = goPlayerMgr:GetRoleByID(nRoleID)
    	if nSelButton == nPayHalfButton then
    		local oRoleConfirm = (nRoleID == oHusband:GetID()) and oHusbandConfirm or oWifeConfirm
    		if oRole:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao) < nHalfCost then
    			oRole:YuanBaoTips()
				-- oRoleConfirm:SetConfirmState(gtMultiConfirmBoxRoleState.eUnconfirmed) 
				oRoleConfirm:ResetConfirmState() --状态回滚
				return
    		end
    		local oConfirmBox = self:GetConfirmBox()
    		assert(oConfirmBox)
    		if oConfirmBox:IsAllConfirmed() then
				self:CleanConfirmBox()
				self:CheckRoleHalfPay()
    			return
    		end
    		local tButton = oRoleConfirm:GetButton(nPayTotalButton)
    		tButton.bActive = false
    		tButton = oRoleConfirm:GetButton(nPayHalfButton)
    		tButton.bActive = false
    		oRoleConfirm:SetCanCancel(false)
    		oRoleConfirm:SetContentList({"正在等待对方支付"})

    		oTarConfirm = (nRoleID == oHusband:GetID()) and oWifeConfirm or oHusbandConfirm
    		local tButton = oTarConfirm:GetButton(nPayTotalButton)
    		tButton.bActive = false
    		local sHalfPayContent = string.format("对方希望和你分摊支付 %d 元宝", nHalfCost)
    		oTarConfirm:SetContentList({sHalfPayContent})

    		oMultiConfirmBox:SyncAllConfirmBox()

    	elseif nSelButton == nPayTotalButton then
    		if not oRole:CheckSubShowNotEnoughTips({{gtItemType.eCurr, gtCurrType.eAllYuanBao, nTotalCost}}, "花轿游行") then
    			local oRoleConfirm = (nRoleID == oHusband:GetID()) and oHusbandConfirm or oWifeConfirm
				-- oRoleConfirm:SetConfirmState(gtMultiConfirmBoxRoleState.eUnconfirmed) 
				oRoleConfirm:ResetConfirmState() --状态回滚
				return
    		end
    		self:CleanConfirmBox()
    		oTarRole = (nRoleID == oHusband:GetID()) and oWife or oHusband
    		oTarRole:Tips("对方已支付全部费用")
    		self:OnParadeStart()
    	else
    		assert(false, "系统数据异常")
    	end
    end

    local fnCancelCallback = function (nRoleID)
    	local oRole = (nRoleID == oHusband:GetID()) and oHusband or oWife
    	local oTar = (nRoleID == oHusband:GetID()) and oWife or oHusband
    	oRole:Tips("您已经取消了租赁申请")
    	oTar:Tips("对方取消了租赁申请")
    	self:Release()
    end

    local fnTimeOutCallback = function ()
    	self:Release()
    	local sTipsContent = "费用支付超时，申请被取消！"
    	oHusband:Tips(sTipsContent)
    	oWife:Tips(sTipsContent)
    end

    oMultiConfirmBox:SetRoleConfirmCallback(fnConfirmCallback)
    oMultiConfirmBox:SetRoleCancelCallback(fnCancelCallback)
    oMultiConfirmBox:SetTimeOutCallback(fnTimeOutCallback)
    oMultiConfirmBox:SyncAllConfirmBox()
end

function CPalanquin:CheckRoleHalfPay()
	local nTotalCost = 1314
	local nHalfCost = math.ceil(nTotalCost / 2)
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
	local bSuccess = true  --再次检查，防止玩家选择过程中，使用元宝，导致不足
	if oHusband:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao) < nHalfCost then
		bSuccess = false
		oHusband:Tips("元宝不足，支付失败")
		oWife:Tips("支付失败")
	end
	if oWife:ItemCount(gtItemType.eCurr, gtCurrType.eAllYuanBao) < nHalfCost then
		bSuccess = false
		oWife:Tips("元宝不足，支付失败")
		oHusband:Tips("支付失败")
	end
	if not bSuccess then
		self:Release()
		return
	end
	oHusband:SubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nHalfCost, "花轿游行")
	oWife:SubItem(gtItemType.eCurr, gtCurrType.eAllYuanBao, nHalfCost, "花轿游行")
	self:OnParadeStart()
end

function CPalanquin:GetPalanquinNpc()
	if self.m_nPalanquinNpcID <= 0 then
		return
	end
	return goMonsterMgr:GetMonster(self.m_nPalanquinNpcID)
end

function CPalanquin:CalcPlanRunTime()
	local nStep = 1
	local tStepConf = self:GetPalanquinStepConf()
	-- local nSpeed = tStepConf.nSpeed
	-- assert(nSpeed >= 1)
	-- local nTotalStepDistance = 0
	-- while tStepConf.tTargetPos[nStep] do
	-- 	local tStepPos = tStepConf.tTargetPos[nStep]
	-- 	local tNextStepPos = tStepConf.tTargetPos[nStep+1]
	-- 	if not tNextStepPos then 
	-- 		break
	-- 	end
	-- 	local nStepDistance = math.sqrt((tNextStepPos[1] - tStepPos[1])^2 + (tNextStepPos[2] - tStepPos[2])^2)
	-- 	nTotalStepDistance = nTotalStepDistance + nStepDistance
	-- 	nStep = nStep + 1
	-- end
	-- local nPlanRunTime = math.ceil(nTotalStepDistance / nSpeed)
	local nPlanRunTime = 0
	for k = 2, #(tStepConf.tTargetPos) do 
		nPlanRunTime = nPlanRunTime + tStepConf.tTargetPos[k][3]
	end
	return nPlanRunTime
end

function CPalanquin:OnParadeStart()
	print("======= 花轿游行开始 =======")
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife) 
	
	-- local tCouple = {}
	-- tCouple.nHusband = self.m_nHusband
	-- tCouple.nWife = self.m_nWife
	goRemoteCall:Call("MarriagePalanquinStartNoticeReq", gnWorldServerID, 
		goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, self.m_nHusband)

	local oDup = goMarriageSceneMgr:GetScene()
	oDup:RemoveObserved(oHusband:GetAOIID())
	oDup:RemoveObserved(oWife:GetAOIID())

	oHusband:SetActState(gtRoleActState.ePalanquinParade, true)
	oWife:SetActState(gtRoleActState.ePalanquinParade, true)
	-- 设置花轿、关联花轿
	self.m_nPalanquinStep = 1
	-- self.m_nStepStamp = os.time()
	self.m_nStartStamp = os.time()
	self.m_nPlanRunTime = self:CalcPlanRunTime()
	local tWayConf = self:GetPalanquinStepConf()
	assert(tWayConf, "配置错误")
	local nPosX = tWayConf.tTargetPos[1][1]
	local nPosY = tWayConf.tTargetPos[1][2]
	-- local nFace = tWayConf.tTargetPos[1][3] --已改为速度

	local oLeader = oHusband:IsLeader() and oHusband or oWife
	goNativeDupMgr:SetFollow(oLeader:GetMixObjID(), {})  --取消原来的跟随关系
	oHusband:SetPos(nPosX, nPosY)
	oWife:SetPos(nPosX, nPosY)

	local nPalanquinNpcID = 43  --TODO
	local oPalanquin = goMonsterMgr:CreatePublicNpc(gtMonType.ePalanquin, nPalanquinNpcID)
	self.m_nPalanquinNpcID = oPalanquin:GetID()
	oPalanquin:SetRelationObj(self)
	--初始化所有信息，确保状态正确后，再进入场景
	oPalanquin:EnterScene(goMarriageSceneMgr:GetSceneMixID(), nPosX, nPosY, 0, 0)
	oPalanquin:SetMoveTargetCallback(function(oObj) self:OnReachTargetPos(oObj) end)
	--设置跟随
	local tFollowList = {}
	table.insert(tFollowList, oHusband:GetMixObjID())
	table.insert(tFollowList, oWife:GetMixObjID())
	goNativeDupMgr:SetFollow(oPalanquin:GetMixObjID(), tFollowList)
	self:MovePalanquin()
end

function CPalanquin:MovePalanquin()
	if self.m_nPalanquinStep < 1 then
		LuaTrace("数据错误，花轿即将被销毁")
		self:OnParadeEnd()
		return
	end
	print(string.format("=== 花轿开始移动 Step:%d ===", self.m_nPalanquinStep))
	local nNextStep = self.m_nPalanquinStep + 1
	local tStepConf = self:GetPalanquinStepConf()
	local tTargetPos = tStepConf.tTargetPos[nNextStep]
	if not tTargetPos then
		self:OnParadeEnd()
		return
	end
	local nTarPosX = tTargetPos[1]
	local nTarPosY = tTargetPos[2]
	local nStepTime = tTargetPos[3]
	assert(nStepTime >= 1)

	local oPalanquinNpc = self:GetPalanquinNpc()
	if not oPalanquinNpc then
		self:OnParadeEnd()
		return
	end
	local nCurPosX, nCurPosY = oPalanquinNpc:GetPos()

	local nStepDistance = math.sqrt((nTarPosX - nCurPosX)^2 + (nTarPosY - nCurPosY)^2)
	local nSpeed = math.ceil(nStepDistance / nStepTime)

	print(string.format("当前坐标(%d, %d), 目标坐标(%d, %d), 速度:%d", 
		nCurPosX, nCurPosY, nTarPosX, nTarPosY, nSpeed))
	oPalanquinNpc:GetNativeObj():RunTo(nTarPosX, nTarPosY, nSpeed)
end

function CPalanquin:OnReachTargetPos(oPalanquinNpc)
	print(string.format("=== 花轿移动到目标点 Step:%d ===", self.m_nPalanquinStep))
	self.m_nPalanquinStep = self.m_nPalanquinStep + 1
	-- self.m_nStepStamp = os.time()
	self:MovePalanquin()
end

function CPalanquin:OnParadeEnd()
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
	local oPalanquin = self:GetPalanquinNpc()
	-- 重新设置跟随关系
	goNativeDupMgr:SetFollow(oPalanquin:GetMixObjID(), {})
	local oLeader = oHusband:IsLeader() and oHusband or oWife
	local nFollowID = oHusband:IsLeader() and oWife:GetID() or oHusband:GetID()
	goNativeDupMgr:SetFollow(oLeader:GetMixObjID(), {nFollowID})

	goMonsterMgr:RemoveMonster(self.m_nPalanquinNpcID)
	self.m_nPalanquinNpcID = 0
	self.m_nPalanquinStep = 0

	local oDup = goMarriageSceneMgr:GetScene()
	oDup:AddObserved(oHusband:GetAOIID()) 
	oDup:AddObserved(oWife:GetAOIID())

	--给当前场景所有玩家发放一颗喜糖
	local tRoleNativeList = oDup:GetObjList(-1, gtObjType.eRole)
	for _, oNativeObj in ipairs(tRoleNativeList) do
		local oTempRole = GetLuaObjByNativeObj(oNativeObj)
		if oTempRole then
			oTempRole:AddItem(gtItemType.eProp, gnWeddingCandyPropID, 1, "花轿游行结束奖励")
		end
	end
	print("======= 花轿游行结束 =======")
	self:Release()
end




