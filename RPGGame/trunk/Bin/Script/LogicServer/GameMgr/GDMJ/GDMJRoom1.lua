--广东麻将熟人房间
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local tGDMJConf = gtGDMJConf

--出牌时间
local nTurnTime = 15
--最大BLOCK数量
local nMaxBlock = (tGDMJConf.tEtc.nMaxHandMJ-2)/3
local nMaxHandMJ = tGDMJConf.tEtc.nMaxHandMJ
--解散房间等待
local nDismissWait = 5*60*1000
--游戏结束后多久释放房间
local nGameOverTime = 10*60*1000

function CGDMJRoom1:Ctor(oRoomMgr, nRoomID, nDeskType, tOption)
	CGDMJRoomBase.Ctor(self, oRoomMgr, nRoomID, tGDMJConf.tRoomType.eRoom1, nDeskType)
	self.m_tOption = tOption or tGDMJConf:NewMJOption() --玩法
	self:CheckOption(self.m_tOption) --检测选项

	self.m_tPlayerMap = {}	--[charid] = {nCharID=0,bOwner=false,bOffline=false,bRobot=false}
	self.m_nPlayerCount = 0

	self.m_nState = self.tState.eInit

	self.m_nRound = 1 				--第几局
	self.m_nBaseScore = 2 			--底分
	self.m_tFengWei = {}			--风位映射([fengwei]=charid)
	self.m_tRoundResult = {}		--每局的情况{[round]={[charid]={},...},...}

	self:InitRound(0)				--初始化局
	self.m_nDismissTick = nil 		--解散房间计时器
	self.m_nGameOverTick = nil 		--游戏结束解散房间计时器
	--self:FillRobot()				--填充机器人
end

function CGDMJRoom1:LoadData(tData)
	--fix pd 正在进行的房间返回TRUE,否则返回FALSE
end

function CGDMJRoom1:SaveData()
	--fix pd
end

--是否已经开始
function CGDMJRoom1:IsStart()
	return self.m_nState == self.tState.eStart
end

--监测选项
function CGDMJRoom1:CheckOption(tOption)
	assert(tOption.nRound == 8 or tOption.nRound == 16, "局数不对")
	if tOption.bWuFeng then
		assert(tOption.nGhostType ~= tGDMJConf.tGhostType.eBlank, "无风白板不能为鬼")
	end
	if tOption.bDoubleGhost then
		assert(tOption.nGhostType == tGDMJConf.tGhostType.eOpen, "双鬼必须选翻鬼")
	end
	if tOption.nGhostType == tGDMJConf.tGhostType.eNone then
		assert(not tOption.bDoubleGhost and not tOption.bGhostDouble, "无鬼和双鬼双倍冲突")
	end
end

--填充机器人(测试用)
function CGDMJRoom1:FillRobot()
	for i = 1, 3 do
		local oRobot = goRobotMgr:CreateRobot()
		self:Join(oRobot)
		self:PlayerReady(oRobot)
	end
end

--释放房间
function CGDMJRoom1:OnRelease()
	self:CancelDismissTick()
	self:CancelGameOverTick()

	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		if tPlayer.bRobot then
			goRobotMgr:RemoveRobot(nCharID)
		else
			local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
			oPlayer.m_oGame:SetCurrGame(0, 0, 0)
		end
	end
	self.m_tPlayerMap = {}
end

--取消释放房间计时器
function CGDMJRoom1:CancelDismissTick()
	if self.m_nDismissTick then
		GlobalExport.CancelTimer(self.m_nDismissTick)
		self.m_nDismissTick = nil
	end
end

--取消游戏结束计时器
function CGDMJRoom1:CancelGameOverTick()
	if self.m_nGameOverTick then
		GlobalExport.CancelTimer(self.m_nGameOverTick)
		self.m_nGameOverTick = nil
	end
end

--生成玩家数据
function CGDMJRoom1:GenPlayer(nCharID)
	local tPlayer = 
	{
		nCharID = nCharID,
		bOwner = false,
		bRobot = false,
		bOffline = false,
		nScore = self.m_tOption.nRound == 8 and 1000 or 2000,
		nFengWei = 0,	--风位
		nBankerCnt = 0,	--当前连庄数量
	}
	return self:InitPlayer(tPlayer)
end

--初始角色
function CGDMJRoom1:InitPlayer(tPlayer)
	tPlayer.tHandMJ = {} 		--手上的麻将
	tPlayer.nHandMJ = 0 		--手上麻将数量
	tPlayer.oHu = tGDMJConf:NewMJHu()		--胡牌面
	tPlayer.nStep = 0 			--走到第几步
	tPlayer.tOutMJ = {} 		--已出牌
	tPlayer.bReady = false 		--是否已准备
	tPlayer.nActionRight = 0 	--操作权限
	tPlayer.nFollowScore = 0 	--跟庄分
	tPlayer.nGangScore = 0 		--杠分
	return tPlayer
end

--初始化新的1局
function CGDMJRoom1:InitRound(nBankerUser)
	self.m_tTouchMJ = {}
	self.m_nBankerUser = nBankerUser
	self.m_nCurrentUser = 0
	self.m_nTurnStartTime = 0
	self.m_nOutMJ = 0
	self.m_tMaMJ = {}
	self.m_tGhostList = {}
	self.m_tFollowMJ = {}
	self.m_tAgreeDismissPlayer = {}

	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		self:InitPlayer(tPlayer)
	end

	--机器人准备
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		if tPlayer.bRobot then
			local oRobot = goRobotMgr:GetRobot(nCharID)
			self:PlayerReady(oRobot)
		end
	end
	self:MarkDirty(true)
end

--加入房间
function CGDMJRoom1:Join(oPlayer)
	print("CGDMJRoom1:Join***", oPlayer:GetName())
	local nCharID = oPlayer:GetCharID()
	local tPlayer = self:GetPlayer(nCharID)
	if tPlayer then
		self:OnPlayerEnter(oPlayer)
		return true
	end

	--房间满
	if self:IsFull() then
		oPlayer:Tips(ctLang[2])
		oPlayer.m_oGame:SetCurrGame(0, 0, 0)
		return
	end

	local tPlayer = self:GenPlayer(nCharID)
	self.m_tPlayerMap[nCharID] = tPlayer
	self.m_nPlayerCount = self.m_nPlayerCount + 1
	tPlayer.bOwner = self.m_nPlayerCount == 1
	tPlayer.bRobot = oPlayer:GetObjType() == gtObjType.eRobot
	if tPlayer.bOwner then --第1局房主坐庄
		self.m_nBankerUser = nCharID
	end

	--生成风位
	for k = 1, tGDMJConf.tFengWei.eNorth do
		if not self.m_tFengWei[k] then
			tPlayer.nFengWei = k
			self.m_tFengWei[k] = nCharID
			break
		end
	end

	self:OnPlayerEnter(oPlayer)
	self:MarkDirty(true)
	return true
end

--进入房间事件
function CGDMJRoom1:OnPlayerEnter(oPlayer)
	print("CGDMJRoom1:OnPlayerEnter***", oPlayer:GetName())
	local nMyCharID = oPlayer:GetCharID()
	oPlayer.m_oGame:SetCurrGame(self:GameType(), self:RoomID(), self:DeskType())

	--玩家信息
	local tMyInfo
	local tMsg = {bSuccess=true, nRoomID=self:RoomID(), nRoomType=self:RoomType(), tPlayerList={}}
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		local oTmpPlayer = self:GetPlayerObj(nCharID)
		local tInfo = 
		{
			sName = oTmpPlayer:GetName(),
			sImgURL = oTmpPlayer:GetImgURL(),
			nCharID = tPlayer.nCharID,
			nScore = tPlayer.nScore,
			nFengWei = tPlayer.nFengWei,
			bOffline = tPlayer.bOffline,
			bOwner = tPlayer.bOwner,
			bReady = tPlayer.bReady,
		}
		table.insert(tMsg.tPlayerList, tInfo)
		if nCharID == nMyCharID then
			tMyInfo = tInfo
		end
	end
	--发给自己
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "JoinRoomRet", tMsg)

	--广播其他玩家
	CmdNet.PBBroadcastExter(self:GetSessionList(nMyCharID), "PlayerJoinBroadcast", {tPlayer=tMyInfo})

	--恢复牌局如果是中途重连
	if self.m_nState ~= self.tState.eInit then
		self:RecoverDesk(oPlayer)
	end
end

--离开房间
function CGDMJRoom1:Leave(oPlayer)
	print("CGDMJRoom1:Leave***", oPlayer:GetName())
	local nCharID = oPlayer:GetCharID()
	local tPlayer = self.m_tPlayerMap[nCharID]
	if not tPlayer then
		return
	end
	if self.m_nState == self.tState.eStart or self.m_nState == self.tState.eRound then
		return oPlayer:Tips(ctLang[3])
	end
	if tPlayer.bOwner then
		self:OnDismiss()
		--self:Offline(oPlayer)
		--CmdNet.PBSrv2Clt(oPlayer:GetSession(), "LeaveRoomRet", {nRoomType=self:RoomType(),nRoomID=self:RoomID()})
	else
		self.m_tPlayerMap[nCharID] = nil
		self.m_tFengWei[tPlayer.nFengWei] = nil
		self.m_nPlayerCount = self.m_nPlayerCount - 1
		self:OnPlayerLeave(oPlayer)
	end
	self:MarkDirty(true)
end

--离开房间事件
function CGDMJRoom1:OnPlayerLeave(oPlayer)
	print("CGDMJRoom1:OnPlayerLeave***", oPlayer:GetName())
	local nCharID = oPlayer:GetCharID()
	oPlayer.m_oGame:SetCurrGame(0, 0, 0)
	--发给自己
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "LeaveRoomRet", {nRoomType=self:RoomType()})
	--广播其他玩家
	CmdNet.PBBroadcastExter(self:GetSessionList(nCharID), "PlayerLeaveBroadcast", {nCharID=nCharID})

	--只有机器人解散房间
	local nHumenCount = 0
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		if not tTmpPlayer.bRobot then
			nHumenCount = nHumenCount + 1
		end
	end
	if nHumenCount == 0 then
		self:OnDismiss()
	end
end

--离线事件
function CGDMJRoom1:Offline(oPlayer)
	print("CGDMJRoom1:Offline***", oPlayer:GetName()) 
	local nCharID = oPlayer:GetCharID()
	local tPlayer = self:GetPlayer(nCharID)
	tPlayer.bOffline = true	
	self:MarkDirty(true)
	CmdNet.PBBroadcastExter(self:GetSessionList(nCharID), "PlayerOfflineBroadcast", {nCharID=nCharID})
end

--上线事件
function CGDMJRoom1:Online(oPlayer)
	print("CGDMJRoom1:Online***", oPlayer:GetName()) 
	local nCharID = oPlayer:GetCharID()
	local tPlayer = self:GetPlayer(nCharID)
	tPlayer.bOffline = false
	self:MarkDirty(true)
	CmdNet.PBBroadcastExter(self:GetSessionList(nCharID), "PlayerOnlineBroadcast", {nCharID=nCharID})
end

--玩家准备
function CGDMJRoom1:PlayerReady(oPlayer)
	print("CGDMJRoom1:PlayerReady***", oPlayer:GetName())
	local nCharID = oPlayer:GetCharID()
	local tPlayer = self:GetPlayer(nCharID)
	tPlayer.bReady = true
	self:MarkDirty(true)

	--广播房间所有玩家
	CmdNet.PBBroadcastExter(self:GetSessionList(), "PlayerReadyBroadcast", {nCharID=nCharID})

	--所有人准备了就开始游戏
	local nReadyCount = 0
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		if tPlayer.bReady then
			nReadyCount = nReadyCount + 1
		end
	end
	if nReadyCount >= tGDMJConf.tEtc.nMaxPlayer then
		self:GameStart()
	end
end

--申请解散房间
function CGDMJRoom1:DismissReq(oPlayer)
	if self:IsStart() then
		if not self.m_nDismissTick then
			self.m_tAgreeDismissPlayer = {}
			CmdNet.PBBroadcastExter(self:GetSessionList(), "AskDismissRoomBroadcast", {nRoomID=self:RoomID()})
			self.m_nDismissTick = GlobalExport.RegisterTimer(nDismissWait, function() self:OnDismiss() end)
		end
	else
		self:OnDismiss()
	end
end

--同意解散房间
function CGDMJRoom1:AgreeDismiss(oPlayer, bAgree)
	local nCharID = oPlayer:GetCharID()
	local tPlayer = assert(self:GetPlayer(nCharID), "玩家不存在")
	if not bAgree then
		self:CancelDismissTick()
		local tSessionList = self:GetSessionList(nCharID)
		for _, nSession in ipairs(tSessionList) do
		    goNoticeMgr:Tips(ctLang[4], nSession)
		end
		return
	end

	--所有人同意解散了就解散房间
	self.m_tAgreeDismissPlayer[nCharID] = bAgree
	local nAgreeCount =  0
	for nCharID, v in pairs(self.m_tAgreeDismissPlayer) do
		nAgreeCount = nAgreeCount + 1
	end
	if nAgreeCount >= tGDMJConf.tEtc.nMaxPlayer then
		self:OnDismiss()		
	end
end

--真正解散房间
function CGDMJRoom1:OnDismiss()
	print("CGDMJRoom1:OnDismiss***")
	CmdNet.PBBroadcastExter(self:GetSessionList(), "DismissRoomBroadcast", {nRoomID=self:RoomID()})
	self.m_oRoomMgr:RemoveRoom(self:RoomID())
end

--翻鬼牌
function CGDMJRoom1:OpenGhost()
	if self.m_tOption.nGhostType == tGDMJConf.tGhostType.eNone then
		return
	end
	if self.m_tOption.nGhostType == tGDMJConf.tGhostType.eBlank then
		return
	end
	assert(self.m_tOption.nGhostType == tGDMJConf.tGhostType.eOpen, "鬼牌选项错误")
	local nGhostCount = self.m_tOption.bDoubleGhost and 2 or 1
	local nDice1 = math.random(1, 6)
	local nDice2 = math.random(1, 6)
	local nRand = (nDice1 + nDice2) * 2
	local nStartMJ = self.m_tTouchMJ[nRand]
	for i = 1, nGhostCount do
		local nType = self:GetMJType(nStartMJ)
		local nValue = self:GetMJValue(nStartMJ)
		if nStartMJ <= 0x29 then
			nValue = nValue + 1
			if nValue == 10 then
				nValue = 1
			end
			local nGhostMJ = nType | nValue	
			table.insert(self.m_tGhostList, nGhostMJ)
			nStartMJ = nGhostMJ

		elseif nStartMJ <= 0x34 then
			nValue = nValue + 1
			if nValue == 4 then
				nValue = 1
			end
			local nGhostMJ = nType | nValue	
			table.insert(self.m_tGhostList, nGhostMJ)
			nStartMJ = nGhostMJ

		elseif nStartMJ <= 0x43 then
			nValue = nValue + 1
			if nValue == 3 then
				nValue = 1
			end
			local nGhostMJ = nType | nValue	
			table.insert(self.m_tGhostList, nGhostMJ)
			nStartMJ = nGhostMJ
		end
	end
	CmdNet.PBBroadcastExter(self:GetSessionList(), "TouchGhostRet", {tGhostMJ=self.m_tGhostList, tDice={nDice1, nDice2}})
	self:MarkDirty(true)
	print("CGDMJRoom1:_OpenGhost***", self.m_tGhostList)
end

--1局结束
function CGDMJRoom1:OnRoundEnd(nWinnerID)
	print("CGDMJRoom1:_OnRoundEnd***", nWinnerID)
	nWinnerID = nWinnerID or 0
	self.m_nState = self.tState.eRound

	local nNewBankerUser = self.m_nBankerUser
	local tOldBanker = self:GetPlayer(self.m_nBankerUser)

	--生成结果
	local tRoundScore, sHuStr = self:RoundCalc(nWinnerID)

	--生成消息体
	local tMsg = {nHuPlayer=nWinnerID, tMaMJ=self.m_tMaMJ, sHuStr=sHuStr, tResult={}}
	local function _gen_result_msg(nCharID)
		local tPlayer = self:GetPlayer(nCharID)
		local tResult = 
		{
			nCharID = nCharID
			, nTotalScore = tPlayer.nScore
			, nRoundScore = tRoundScore[nCharID]
			, tHandMJ = table.DeepCopy(tPlayer.tHandMJ)
			, tBlock = {}
		}
		for _, oBlock in ipairs(tPlayer.oHu.tBlock) do
			table.insert(tResult.tBlock, {nFirstMJ=oBlock.nFirst, nBlockStyle=oBlock.nStyle})
		end
		return tResult
	end
	
	--增减分数,生成记录
	local tRoundResult = {}
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		--增减分数
		tTmpPlayer.nScore = tTmpPlayer.nScore + tRoundScore[nTmpCharID]
		--扣除房卡
		if self.m_nRound == 1 and tTmpPlayer.bOwner and not tTmpPlayer.bRobot then
			local oPlayer = goPlayerMgr:GetPlayerByCharID(nTmpCharID)
			local nCardCost = self.m_tOption.nRound == 8 and 1 or 2
			oPlayer:SubCard(nCardCost, gtReason.eGDMJRoundEnd, true)
		end

		--记录结果
		local tRound = tRoundResult[nTmpCharID]
		if not tRound then
			tRound = {}
			tRoundResult[nTmpCharID] = tRound
		end
		tRound.nRoundScore = tRoundScore[nTmpCharID]
		
		--生产信息
		table.insert(tMsg.tResult, _gen_result_msg(nTmpCharID))
	end
	self.m_tRoundResult[self.m_nRound] = tRoundResult

	--撤销连庄
	if nWinnerID > 0 then
		if nWinnerID ~= self.m_nBankerUser then
			tOldBanker.nBankerCnt = 0
			nNewBankerUser = nWinnerID
		end
	end
	--发送信息
	print("RoundEnd***", tMsg)
	CmdNet.PBBroadcastExter(self:GetSessionList(), "RoundEndRet", tMsg)

	if self.m_nRound >= self.m_tOption.nRound then
		self:OnGameEnd()
	else
		self.m_nRound = self.m_nRound + 1
		self:InitRound(nNewBankerUser)
	end
	self:MarkDirty(true)
end

--1盘结束
function CGDMJRoom1:OnGameEnd()
	self.m_nState = self.tState.eGameOver

	local tMsg = {tResult={}}
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		local oTmpPlayer = self:GetPlayerObj(nTmpCharID)
		local tInfo =
		{
			bOwner=tTmpPlayer.bOwner
			, nCharID=nTmpCharID
			, sImgURL=oTmpPlayer:GetImgURL()
			, sCharName=oTmpPlayer:GetName()
			, nWinScore=0
		}
		local nWinScore = 0
		for i = 1, self.m_tOption.nRound do
			nWinScore = nWinScore + self.m_tRoundResult[i][nTmpCharID].nRoundScore
		end
		tInfo.nWinScore = nWinScore
		table.insert(tMsg.tResult, tInfo)
	end
	CmdNet.PBBroadcastExter(self:GetSessionList(), "GameEndRet", tMsg)
	self.m_nGameOverTick = GlobalExport.RegisterTimer(nGameOverTime, function(nTimerID) self:OnDismiss() end)
	self:MarkDirty(true)
end

--可操作事件
function CGDMJRoom1:OnSendOperation(nCharID)
	print("CGDMJRoom1:OnSendOperation***", nCharID)
	local tPlayer = self.m_tPlayerMap[nCharID]
	if tPlayer.bRobot then
		local oRobot = goRobotMgr:GetRobot(nCharID)
		oRobot:OperationRet(nTurnTime)
	end
end
