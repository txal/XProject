--婚礼管理
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nAgreeMarryButtonID = 100
local nNpcWeddingCandyConfID = 42
local nPropWeddingCandyID = 11009

function  CWedding:Ctor()
	self.m_nWeddingState = gtWeddingNpcState.eNormal   --婚礼状态，进度，玩家掉线重连，需要进行状态恢复需要使用
	self.m_nWeddingStamp = 0
	self.m_nWeddingTimer = nil
	self.m_nWeddingLevel = 0
	self.m_nWeddingStep = 0          --婚礼流程

	self.m_nApplyRole = 0
	self.m_nHusband = 0
	self.m_nWife = 0

	self.m_sHusbandName = nil   --缓存下名称, 防止发放喜糖阶段，角色离线或者离开当前逻辑服
	self.m_sWifeName = nil 

	self.m_nMarryConfirmBoxID = 0

	self.m_tCandyList = {}           --{AOIID, ...}
	self.m_nCandyTimer = nil
	self.m_nCandySerial = 0
	self.m_tCandyPickRecord = {}     --{nRoleID:nCount, ...} 每一波次，喜糖拾取记录

end

function CWedding:SetWeddingNpcState(nState)
	self.m_nWeddingState = nState
	self.m_nStateStamp = os.time()
end

--当前申请结婚状态是否忙碌
function CWedding:IsWeddingReqBusy()
	if self.m_nWeddingState == gtWeddingNpcState.ePrepare then
		return true
	end
	return false
end

--是否处于婚礼中
function CWedding:IsWedding()
	if self.m_nWeddingState == gtWeddingNpcState.eWedding then
		return true
	end
	return false
end

function CWedding:IsCandyState()
	if self.m_nWeddingState == gtWeddingNpcState.eCandy then
		return true
	end
	return false
end
--婚礼NPC是否空闲
function CWedding:IsWeddingNpcFree()
	if self.m_nWeddingState == gtWeddingNpcState.eNormal then
		return true
	end
	return false
end

function CWedding:GetMarryConfirmBoxID() return self.m_nMarryConfirmBoxID end
function CWedding:GetMarryConfirmBox() return goMultiConfirmBoxMgr:GetConfirmBox(self.m_nMarryConfirmBoxID) end

function CWedding:CleanMarryConfirmBox()
	if self.m_nMarryConfirmBoxID > 0 then
		local oConfirmBox = self:GetMarryConfirmBox()
		if oConfirmBox then
			oConfirmBox:NotifyDestroyAllConfirmBox()
			goMultiConfirmBoxMgr:RemoveConfirmBox(self.m_nMarryConfirmBoxID)
		end
	end
	self.m_nMarryConfirmBoxID = 0
end

function CWedding:CleanWeddingTimer()
	if self.m_nWeddingTimer then
		goTimerMgr:Clear(self.m_nWeddingTimer)
		self.m_nWeddingTimer = nil
	end
end

function CWedding:CleanCandyTimer() 
	if self.m_nCandyTimer then 
		goTimerMgr:Clear(self.m_nCandyTimer)
		self.m_nCandyTimer = nil
	end
end

function CWedding:ResetState()
	self:CleanMarryConfirmBox()
	self:CleanWeddingTimer()
	self.m_nApplyRole = 0
	if self.m_nHusband > 0 then
		local oRole = goPlayerMgr:GetRoleByID(self.m_nHusband)
		if oRole and (self:IsWeddingReqBusy() or self:IsWedding()) then 
			--抛洒喜糖阶段，角色已离开, 或者在参与其他活动，比如花轿游行
			oRole:ResetActState(true)
		end
	end
	if self.m_nWife > 0 then
		local oRole = goPlayerMgr:GetRoleByID(self.m_nWife)
		if oRole and (self:IsWeddingReqBusy() or self:IsWedding()) then 
			oRole:ResetActState(true)
		end
	end
	self:SetWeddingNpcState(gtWeddingNpcState.eNormal)
	self.m_nHusband = 0
	self.m_nWife = 0
	self.m_sHusbandName = nil
	self.m_sWifeName = nil
	self.m_nWeddingLevel = 0
	self.m_nWeddingStep = 0

	self:CleanCandyTimer()
	self.m_nCandySerial = 0
	self.m_tCandyPickRecord = {}
	--self:ReleaseWeddingFirework()
end

function CWedding:OnRelease() 
	self:ResetState()
end

function CWedding:WeddingApplyConfirm()
	assert(self.m_nApplyRole > 0 and self.m_nWife > 0 and self.m_nHusband > 0 and self:IsWeddingReqBusy(), "数据错误")
   	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
   	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
   	local oApplyRole = (self.m_nApplyRole == self.m_nHusband) and oHusband or oWife

   	local sBoxContentTemplate = "你愿意和%s缔结婚姻，此后无论环境是好是坏、富贵还是贫贱，健康还是疾病，都会忠贞不渝地爱着对方、珍惜对方、白头偕老吗？"
    local oMultiConfirmBox = goMultiConfirmBoxMgr:CreateConfirmBox("缔结婚姻确认框", {}, 30)
    self.m_nMarryConfirmBoxID = oMultiConfirmBox:GetID()

    local sHusBoxContent = string.format(sBoxContentTemplate, oWife:GetFormattedName())
    local oHusbandConfirm = oMultiConfirmBox:InsertRoleConfirmData(self.m_nHusband)
    oHusbandConfirm:SetContentList({sHusBoxContent})
    oHusbandConfirm:UpdateButton(nAgreeMarryButtonID, "我愿意", true)

    local sWifeBoxContent = string.format(sBoxContentTemplate, oHusband:GetFormattedName())
    local oWifeConfirm = oMultiConfirmBox:InsertRoleConfirmData(self.m_nWife)
    oWifeConfirm:SetContentList({sWifeBoxContent})
    oWifeConfirm:UpdateButton(nAgreeMarryButtonID, "我愿意", true)

    local fnConfirmCallback = function (nRoleID, nSelButton)
    	if nSelButton == nAgreeMarryButtonID then
    		local oConfirmBox = self:GetMarryConfirmBox()
    		assert(oConfirmBox)
    		if oConfirmBox:IsAllConfirmed() then
				self:CleanMarryConfirmBox()
				self:NotifyChooseWeddingLevel()
    			return
    		end
    		--oConfirmBox:UpdateSerialID() --另外一方不需要变化，所以不需要更新序列号
    		local oRoleConfirm = (nRoleID == oHusband:GetID()) and oHusbandConfirm or oWifeConfirm
    		--local oTarConfirm = (nRoleID == oHusband:GetID()) and oWifeConfirm or oHusbandConfirm
    		local tButton = oRoleConfirm:GetButton(nAgreeMarryButtonID)
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
    	local sTipsContent = string.format("%s对于和您缔结婚姻还有疑虑", oRole:GetFormattedName())
    	oTar:Tips(sTipsContent)
    	self:ResetState()
    end

    local fnTimeOutCallback = function ()
    	self:ResetState()
    	local sTipsContent = "确认婚姻意愿超时，请重新申请！"
    	oHusband:Tips(sTipsContent)
    	oWife:Tips(sTipsContent)
    end

    oMultiConfirmBox:SetRoleConfirmCallback(fnConfirmCallback)
    oMultiConfirmBox:SetRoleCancelCallback(fnCancelCallback)
    oMultiConfirmBox:SetTimeOutCallback(fnTimeOutCallback)
    oMultiConfirmBox:SyncAllConfirmBox()
end

function CWedding:IsSysOpen(oRole, bTips)
	if not oRole then 
		return 
	end
	return oRole:IsSysOpen(57, bTips)
end

function CWedding:WeddingReq(oRole, nTarRoleID)
	assert(oRole, "参数错误")
	if not nTarRoleID or nTarRoleID <= 0 then 
		return 
	end
	local oTarRole = goPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTarRole then 
		return 
	end
	if not self:IsSysOpen(oRole, true) then 
		-- oRole:Tips("功能未开启")
		return 
	end
    if oRole:GetTeamID() <= 0 then
        return oRole:Tips("请组队前来申请")
    end
    if not oRole:IsLeader() then
        return oRole:Tips("只有队长方可申请")
    end
	local nRoleID = oRole:GetID()
	local fnCheckCallback = function (bRet, bLover)
		local oRole = goPlayerMgr:GetRoleByID(nRoleID)
		--防止中途极端情况，玩家切换逻辑服或者服务器关闭，重新查找一次
		if not oRole or not oRole:IsOnline() then 
			return
		end
		if not bRet then
			oRole:Tips("当前未满足结婚条件")
			return
		end
		if bLover then 
			oRole:Tips("和对方存在情缘关系，无法申请结婚")
			return
		end
		local nHusbandID = (oRole:GetGender() == 1) and nRoleID or nTarRoleID
		local nWifeID = (oRole:GetGender() == 2) and nRoleID or nTarRoleID

	   	local oHusband = goPlayerMgr:GetRoleByID(nHusbandID)
	   	local oWife = goPlayerMgr:GetRoleByID(nWifeID)
		assert(oHusband and oWife, "数据错误")  --极端情况，有玩家离开当前服
		if not self:IsSysOpen(oHusband, true) then 
			oWife:Tips("对方婚姻功能未开启")
			return 
		end
		if not self:IsSysOpen(oWife, true) then 
			oHusband:Tips("对方婚姻功能未开启")
			return 
		end
	   	
	    if self:IsWeddingReqBusy() then
	        return oRole:Tips("其他玩家正在申请结婚")
	    end
	    if self:IsWedding() or self:IsCandyState() then
	        return oRole:Tips("其他玩家正在举行婚礼")
	    end
	    if not self:IsWeddingNpcFree() then
	    	LuaTrace("结婚NPC处于未知状态:", self.m_nWeddingState)
	        return
	    end

	    self:SetWeddingNpcState(gtWeddingNpcState.ePrepare)
	    self.m_nApplyRole = nRoleID
	   	self.m_nHusband = nHusbandID
		self.m_nWife = nWifeID
		self.m_sHusbandName = oHusband:GetName()
		self.m_sWifeName = oWife:GetName()
	   	self:WeddingApplyConfirm()	   	 
	   	oHusband:SetActState(gtRoleActState.eWeddingApply)
		oWife:SetActState(gtRoleActState.eWeddingApply)
	   	end	

	goRemoteCall:CallWait("MarriageWeddingReq", fnCheckCallback, gnWorldServerID, 
		goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, nRoleID, nTarRoleID)
end

function CWedding:WeddingLevelChooseTimeOut()
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
	local oRole = (self.m_nApplyRole == self.m_nHusband) and oHusband or oWife
	local sTipsContent = string.format("%s终止了结婚流程", oRole:GetFormattedName())
	oHusband:Tips(sTipsContent)
	oWife:Tips(sTipsContent)
	self:ResetState()  --内部会删除定时器
end

function CWedding:NotifyChooseWeddingLevel()
	assert(self.m_nApplyRole, "数据错误")
	self.m_nWeddingTimer = goTimerMgr:Interval(30, function () self:WeddingLevelChooseTimeOut() end)
	--谁申请谁负责 通知客户端选择
	local oRole = goPlayerMgr:GetRoleByID(self.m_nApplyRole)
	if not oRole then
		self:ResetState()
	end
	oRole:SendMsg("MarriageNotifyChooseWeddingLevelRet", {})
end

function CWedding:WeddingLevelChoose(nRoleID, nLevel)
	print("nRoleID:", nRoleID, "nLevel:", nLevel)
	--取消，nLevel传0
	if self.m_nApplyRole ~= nRoleID then  --不是当前申请的玩家提交的
		local oRole = goPlayerMgr:GetRoleByID(nRoleID)
		oRole:Tips("提交已过期，请重新申请")
		return
	end
	local oRole = goPlayerMgr:GetRoleByID(self.m_nApplyRole)
	local nTarRoleID = (self.m_nApplyRole == self.m_nHusband) and self.m_nWife or self.m_nHusband
	local oTarRole = goPlayerMgr:GetRoleByID(nTarRoleID)
	assert(oRole and oTarRole, "玩家不存在")
	if nLevel == 0 then  --取消
		self:ResetState()
		return
	end
	local tWeddingLevelTbl = ctWeddingLevelConf
	local tLevelConf = tWeddingLevelTbl[nLevel]
	if not tLevelConf then  --非法数据
		return
	end
	local tCost = {}
	for k, v in pairs(tLevelConf.tCost) do
		if v[1] > 0 then
			assert(v[2] > 0 and v[3] >= 0, "配置错误")
			table.insert(tCost, {v[1], v[2], v[3]})
		end
	end
	if #tCost > 0 then
		if not oRole:CheckSubShowNotEnoughTips(tCost, "结婚", true) then
			local sTipsContent = "支付婚礼费用失败，请重新申请"
			oRole:Tips(sTipsContent)
			oTarRole:Tips(sTipsContent)
			self:ResetState()
			return
		end
	end

	self.m_nWeddingLevel = nLevel
	self:CleanWeddingTimer()

	local fnMarryCallback = function (bRet)
		if not bRet then
			oRole:Tips("缔结婚姻失败")
			for k, v in ipairs(tCost) do
				oRole:AddItem(v[1], v[2], v[3], "结婚失败回滚")
			end
			self:ResetState()
			return
		end

		self:SetWeddingNpcState(gtWeddingNpcState.eWedding)
		local sTipsContent = "恭喜您已与%s缔结婚姻成功！"
		oRole:Tips(string.format(sTipsContent, oTarRole:GetFormattedName()))
		oTarRole:Tips(string.format(sTipsContent, oRole:GetFormattedName()))

		--添加新婚礼服buff和新婚祝福buff
		oRole.m_oRoleState:AddMarriageSuit()
		oTarRole.m_oRoleState:AddMarriageSuit()
		oRole.m_oRoleState:AddMarriageBless()
		oTarRole.m_oRoleState:AddMarriageBless()
		oRole.m_oRoleState:SyncState()
		oTarRole.m_oRoleState:SyncState()
		self:StartWedding()
	end
	goRemoteCall:CallWait("MarriageMarryReq", fnMarryCallback, gnWorldServerID, 
		goServerMgr:GetGlobalService(gnWorldServerID, 110), 0, self.m_nHusband, self.m_nWife)
end

function CWedding:StartWedding()
	if gbServerClosing then --防止关服时，异步事件返回
		self:ResetState()
		return 
	end
	print("======== 婚礼开始 ========")
		--通知客户端婚礼开始
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
	local oLeader = oHusband:IsLeader() and oHusband or oWife
	goNativeDupMgr:SetFollow(oLeader:GetMixObjID(), {})  --取消原来的跟随关系
	oHusband:SendMsg("MarriageWeddingStartRet", {})
	oWife:SendMsg("MarriageWeddingStartRet", {})

	--全区广播婚礼开始, 播放特效
	local tBroadcastMsg = {}
	local tRoleListInfo = {}
	local tHusbandInfo = 
	{
		nID = oHusband:GetID(),
		sName = oHusband:GetName(),
		nRoleConfID = oHusband:GetConfID(),
		nLevel = oHusband:GetLevel(),
	}
	table.insert(tRoleListInfo, tHusbandInfo)

	local tWifeInfo = 
	{
		nID = oWife:GetID(),
		sName = oWife:GetName(),
		nRoleConfID = oWife:GetConfID(),
		nLevel = oWife:GetLevel(),
	}
	table.insert(tRoleListInfo, tWifeInfo)
	tBroadcastMsg.tRoleList = tRoleListInfo
	CmdNet.PBSrv2All("MarriageWeddingStartBroadcastRet", tBroadcastMsg)

	-- local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	-- local oWife =goPlayerMgr:GetRoleByID(self.m_nWife)
	oHusband:SetActState(gtRoleActState.eWedding, true)
	oWife:SetActState(gtRoleActState.eWedding, true)
	self.m_nWeddingStep = 1
	-- local tStepConf = self:GetWeddingStepConf(self.m_nWeddingStep)
	self:DoWeddingStep(self.m_nWeddingStep)
end

function CWedding:GetWeddingStepConf(nStep) return ctWeddingStepConf[nStep] end

function CWedding:OnWeddingStepEnd()
	--self:ReleaseWeddingFirework()
	self:CleanWeddingTimer()
	if not self:GetWeddingStepConf(self.m_nWeddingStep + 1) then
		self:OnWeddingEnd()
		return
	end
	self.m_nWeddingStep = self.m_nWeddingStep + 1
	self:DoWeddingStep(self.m_nWeddingStep)
end

function CWedding:DoWeddingStep(nStep)
	assert(nStep and nStep > 0, "参数错误")
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
	local tStepConf = self:GetWeddingStepConf(nStep)
	if not tStepConf then 
		self:OnWeddingEnd()  --直接强制结束婚礼
		assert(false, "配置不存在，配置ID:"..nStep) --婚礼结束状态重置后，加一个断言错误
	end

	--场景广播，当前婚礼阶段信息
	local oScene = goMarriageSceneMgr:GetScene()
	assert(oScene, "场景丢失")
	local tMsg = {}
	tMsg.nStep = nStep
	tMsg.nHusband = self.m_nHusband
	tMsg.sHusbandName = oHusband:GetName()
	tMsg.nWife = self.m_nWife
	tMsg.sWifeName = oWife:GetName()
	oScene:BroadcastScene(-1, "MarriageWeddingStepNotifyRet", tMsg)

	oHusband:SetPos(tStepConf.tHusbandPos[1][1], tStepConf.tHusbandPos[1][2], tStepConf.tHusbandPos[1][3])
	oWife:SetPos(tStepConf.tWifePos[1][1], tStepConf.tWifePos[1][2], tStepConf.tWifePos[1][3])
	oHusband:SetActID(tStepConf.nActState, true)
	oWife:SetActID(tStepConf.nActState, true)

	if tStepConf.nTimeCost > 0 then
		self.m_nWeddingTimer = goTimerMgr:Interval(tStepConf.nTimeCost, function () self:OnWeddingStepEnd() end)
	else
		self:OnWeddingStepEnd()
	end
	print(string.format("======== 开始婚礼第%d步 ========", nStep))
end

function CWedding:OnWeddingEnd()
	--通知玩家婚礼结束
	local oHusband = goPlayerMgr:GetRoleByID(self.m_nHusband)
	local oWife = goPlayerMgr:GetRoleByID(self.m_nWife)
	oHusband:SendMsg("MarriageWeddingEndRet", {})
	oWife:SendMsg("MarriageWeddingEndRet", {})
	--发送邮件
	local sMailTitle = "结婚后的影响"
	-- local sMailContent = table.concat(tContentTbl)
	local sMailContent = ctTalkConf["marriageeffctmail"].sContent
	GF.SendMail(oHusband:GetServer(), sMailTitle, sMailContent, {}, oHusband:GetID())
	GF.SendMail(oWife:GetServer(), sMailTitle, sMailContent, {}, oWife:GetID())

	oHusband:ResetActState(true)
	oWife:ResetActState(true)

	local oLeader = oHusband:IsLeader() and oHusband or oWife
	local nFollowID = oHusband:IsLeader() and oWife:GetID() or oHusband:GetID()
	goNativeDupMgr:SetFollow(oLeader:GetMixObjID(), {nFollowID})
	print("======== 拜堂结束 ========")
	self:OnWeddingCandyStart()
	-- local fnConfirmCallback = function(tData)
	-- 	if not tData then --超时
	-- 		return
	-- 	end
	-- 	if tData.nSelIdx == 1 then  --再考虑下
    --         return 
	-- 	else
	-- 		--TODO
	-- 	end
	-- end
	-- local sCont = string.format("是否花费1314元宝和你的新婚对象游览三生殿接受大家的祝福呢？", oRoleMaster:GetName())
    -- local tMsg = {sCont=sCont, tOption={"考虑一下", "好的"}, nTimeOut=30}
    -- goClientCall:CallWait("ConfirmRet", fnConfirmCallback, oRole, tMsg)
	return
end

function CWedding:OnWeddingCandyStart() 
	self.m_nCandySerial = 0 --重置下，防止其他数据异常，导致逻辑错误
	self:SetWeddingNpcState(gtWeddingNpcState.eCandy)
	local tLevelConf = ctWeddingLevelConf[self.m_nWeddingLevel]
	if not tLevelConf or tLevelConf.nCandyNum <= 0 or tLevelConf.nCandyTimes <= 0 then --配置错误
		self:ResetState()
		return 
	end
	self:SetCandy(tLevelConf.nCandyNum)
end

function CWedding:OnWeddingCandyStepEnd() 
	self:CleanAllCandy()
	local bContinue = true
	local tLevelConf = ctWeddingLevelConf[self.m_nWeddingLevel]
	if not tLevelConf then --配置错误
		self:ResetState()
		return 
	end

	if self.m_nCandySerial >= tLevelConf.nCandyTimes then 
		bContinue = false
	end

	if bContinue and tLevelConf.nCandyNum > 0 then 
		self:SetCandy(tLevelConf.nCandyNum)
	else
		self:OnWeddingCandyEnd()
	end
end

function CWedding:OnWeddingCandyEnd()
	self:ResetState()
	print(">>>>>>> 婚礼完整结束 <<<<<<<")
end

function CWedding:SetCandy(nCandyNum)
	assert(nCandyNum > 0)
	print(">>>>>>>>>> 开始刷新喜糖 <<<<<<<<<<")
	print("喜糖数量", nCandyNum)
	self.m_nCandySerial = self.m_nCandySerial + 1
	self.m_tCandyPickRecord = {}

	local nCandyConfID = nNpcWeddingCandyConfID

	local nWeddingNpc = 5016   --月老  --TODO
	local tNpcConf = ctNpcConf[nWeddingNpc]
	assert(tNpcConf)
	local tNpcPos = tNpcConf.tPos[1]
	local tDupConf = goMarriageSceneMgr:GetScene():GetConf()
	assert(tDupConf)
	local nRadius = 500
	local nEdgeDistance = 150 --靠近地图边界范围限定
	assert(tDupConf.nWidth >= (100 + 2*nEdgeDistance))
	assert(tDupConf.nHeight >= (100 + 2*nEdgeDistance))
	local nPosXMin = math.floor(math.max(nEdgeDistance, tNpcPos[1] - nRadius))
	local nPosXMax = math.floor(math.min(tDupConf.nWidth - nEdgeDistance, tNpcPos[1] + nRadius))
	local nPosYMin = math.floor(math.max(nEdgeDistance, tNpcPos[2] - nRadius))
	local nPosYMax = math.floor(math.min(tDupConf.nHeight - nEdgeDistance, tNpcPos[2] + nRadius))
	print("====================================")
	print(string.format("喜糖刷新半径 X(%d, %d), Y(%d, %d)", 
		nPosXMin, nPosXMax, nPosYMin, nPosYMax))
	print("====================================")

	--刷新喜糖
	for k = 1, nCandyNum do
		local nPosX = math.random(nPosXMin, nPosXMax)
		local nPosY = math.random(nPosYMin, nPosYMax)
		local oCandy = goMonsterMgr:CreatePublicNpcWithEnter(gtMonType.eWeddingCandy, nCandyConfID, 
			goMarriageSceneMgr:GetSceneMixID(), nPosX, nPosY)
		if oCandy then
			local nCandyID = oCandy:GetID()
			self.m_tCandyList[nCandyID] = oCandy:GetAOIID()
			print(string.format("刷新婚礼糖果NPC 第%d个, ID:%d", k, nCandyID))
		end
	end
	self.m_nCandyTimer = goTimerMgr:Interval(30, function () self:OnWeddingCandyStepEnd() end)
	--通知客户端，当前有喜糖刷新 以播放npc喊话
	local oScene = goMarriageSceneMgr:GetScene()
	assert(oScene, "场景丢失")
	oScene:BroadcastScene(-1, "MarriageWeddingCandyNotifyRet", {})

	local sCandyContent = string.format("恭喜%s和%s喜结连理，月老洒下了大量喜糖，快去捡取~", 
		self.m_sHusbandName, self.m_sWifeName)
	GF.SendNotice(0, sCandyContent)
end

function CWedding:RemoveCandy(nCandyID)
	goMonsterMgr:RemoveMonster(nCandyID)
	self.m_tCandyList[nCandyID] = nil
	print(string.format("移除婚礼糖果NPC, ID:%d", nCandyID))
end

function CWedding:CleanAllCandy()
	for k, v in pairs(self.m_tCandyList) do
		goMonsterMgr:RemoveMonster(k)
		print(string.format("移除婚礼糖果NPC, ID:%d", k))
	end
	self.m_tCandyList = {}
	self:CleanCandyTimer()
	print(">>>>>>>>>> 移除所有喜糖 <<<<<<<<<<")
end
