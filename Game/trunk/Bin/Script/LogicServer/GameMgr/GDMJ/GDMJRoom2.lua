--广东麻将自由房间
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local tGDMJConf = gtGDMJConf

--出牌时间
local nTurnTime = 15
--离开房间倒计时
local nLeaveTime = 15
--最大BLOCK数量
local nMaxBlock = (tGDMJConf.tEtc.nMaxHandMJ-2)/3
local nMaxHandMJ = tGDMJConf.tEtc.nMaxHandMJ

function CGDMJRoom2:Ctor(oRoomMgr, nRoomID, nDeskType)
	CGDMJRoomBase.Ctor(self, oRoomMgr, nRoomID, tGDMJConf.tRoomType.eRoom2, nDeskType)

	self.m_tPlayerMap = {}	--[charid]={nCharID=0,bOffline=false,bRobot=false,bAI=false}
	self.m_nPlayerCount = 0

	self.m_tOption = self:InitOption() 		--玩法选项
	self.m_nState = self.tState.eInit

	self.m_nRound = 1 						--第几局
	self.m_tFengWei = {}					--风位映射([fengwei]=charid)
	local tConf = assert(ctGDMJDeskConf[nDeskType])
	self.m_nBaseScore = tConf.nBaseScore 	--底分

	self:InitRound(0)	--初始化房间
	--通知GLOBAL
	Srv2Srv.OnCreateRoomReq(gtNetConf:GlobalService(), 0, nRoomID, nDeskType)
	self:FillRobot()	--填充机器人

	self.m_nTurnTick = nil	--当前玩家出牌计时器
	self.m_nOperTick = nil 	--可操作计时器
end

function CGDMJRoom2:LoadData(tData)
	--fix pd 所有房间都需要加载 
end

function CGDMJRoom2:SaveData()
	--fix pd
end

--初始化玩法
function CGDMJRoom2:InitOption()
	local oOption = tGDMJConf:NewMJOption()
	oOption.bWuFeng = false
	oOption.bGenZhuang = true 				--跟庄
	oOption.bGangShangBao = true 			--杠上开花全包
	oOption.bGangShangDouble = false		--杠上开花2倍
	oOption.bQiangGang = true 				--可抢杠胡
	oOption.bQiangGangBao = true 			--抢杠胡全包
	oOption.bQiangGangDouble = false 		--抢杠胡2倍
	oOption.bSiGui = false 					--4鬼胡牌
	oOption.bSiGuiDouble = false			--4鬼胡牌2倍
	oOption.bQiDui = true					--7对胡4倍
	oOption.bPengPeng = true				--碰碰胡2倍
	oOption.bQingYiSe = true				--清一色4倍
	oOption.bQuanFeng = true				--全风8倍
	oOption.bShiSanYao = true				--十三幺8倍
	oOption.bYaoJiu = true					--幺九6倍
	oOption.nGhostType = tGDMJConf.tGhostType.eNone  --鬼类型
	oOption.bDoubleGhost = false 			--双鬼
	oOption.bGhostDouble = false			--无鬼双倍
	oOption.nMaType = tGDMJConf.tMaType.eZhuang		--连庄买马
	return oOption
end

--填充机器人(测试用)
function CGDMJRoom2:FillRobot()
	for i = 1, 3 do
		local oRobot = goRobotMgr:CreateRobot()
		self:Join(oRobot)
		self:PlayerReady(oRobot)
	end
end

--生成玩家数据
function CGDMJRoom2:GenPlayer(nCharID)
	local tPlayer = 
	{
		nCharID = nCharID,
		bRobot = false,
		bOffline = false,
		nFengWei = 0,	--风位
		nBankerCnt = 0,	--当前连庄数量
	}
	return self:InitPlayer(tPlayer)
end

--初始角色
function CGDMJRoom2:InitPlayer(tPlayer)
	tPlayer.tHandMJ = {} 	--手上的麻将
	tPlayer.nHandMJ = 0 	--手上麻将数量
	tPlayer.oHu = tGDMJConf:NewMJHu()	--胡牌面
	tPlayer.nStep = 0 		--走到第几步
	tPlayer.tOutMJ = {} 	--已出牌
	tPlayer.bReady = false 	--是否已准备
	tPlayer.nActionRight = 0 --操作权限
	tPlayer.nFollowScore = 0 --跟庄分
	tPlayer.nGangScore = 0 	--杠分
	tPlayer.bAI = false 	--是否托管
	return tPlayer
end

--初始化新的1局
function CGDMJRoom2:InitRound(nBankerUser)
	self.m_tTouchMJ = {}
	self.m_nBankerUser = nBankerUser
	self.m_nCurrentUser = 0
	self.m_nTurnStartTime = 0
	self.m_nOutMJ = 0
	self.m_tMaMJ = {}
	self.m_tFollowMJ = {}
	self.m_tGhostList = {}

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

--释放出牌计时器
function CGDMJRoom2:CancelTurnTimer()
	if self.m_nTurnTick then
		GlobalExport.CancelTimer(self.m_nTurnTick)
		self.m_nTurnTick = nil
	end
end

--释放可操作计时器
function CGDMJRoom2:CancelOperTimer()
	if self.m_nOperTick then
		GlobalExport.CancelTimer(self.m_nOperTick)
		self.m_nOperTick = nil
	end
end

--注册出牌计时器
function CGDMJRoom2:RegisterTurnTimer(nCharID, nTimeSec)
	self:CancelTurnTimer()
	self.m_nTurnTick = GlobalExport.RegisterTimer(nTimeSec*1000, function() self:OnTurnTimeOut(nCharID) end)
end

--注册可操作计时器
function CGDMJRoom2:RegisterOperTimer(nCharID, nTimeSec)
	self:CancelOperTimer()
	self.m_nOperTick = GlobalExport.RegisterTimer(nTimeSec*1000, function() self:OnOperTimeOut(nCharID) end)
end

--出牌计时器到期
function CGDMJRoom2:OnTurnTimeOut(nCharID)
	print("CGDMJRoom2:OnTurnTimeOut***", nCharID)
	self:CancelTurnTimer()
	--如果有可操作计时器则不进入托管	
	if self.m_nOperTick then
		return
	end

	local tPlayer = self.m_tPlayerMap[nCharID]
	if not tPlayer.bAI then
		tPlayer.bAI = true
		CmdNet.PBSrv2Clt(self:GetSession(nCharID), "FreeRoomEnterAIRet", {})
		tPlayer.oBindRobot = goRobotMgr:CreateRobot(nCharID)
		tPlayer.oBindRobot:SetCurrGame(self:GameType(), self:RoomID(), self:DeskType())
		tPlayer.oBindRobot:SwitchPlayerRet(0)
	else
		tPlayer.oBindRobot:SwitchPlayerRet(nTurnTime)
	end
	self:MarkDirty(true)
end

--可操作计时器到时
function CGDMJRoom2:OnOperTimeOut(nCharID)
	print("CGDMJRoom2:OnOperTimeOut***", nCharID)
	self:CancelOperTimer()

	local tPlayer = self.m_tPlayerMap[nCharID]
	if not tPlayer.bAI then
		tPlayer.bAI = true
		CmdNet.PBSrv2Clt(self:GetSession(nCharID), "FreeRoomEnterAIRet", {})
		tPlayer.oBindRobot = goRobotMgr:CreateRobot(nCharID)
		tPlayer.oBindRobot:SetCurrGame(self:GameType(), self:RoomID(), self:DeskType())
		tPlayer.oBindRobot:OperationRet(0)
	else
		tPlayer.oBindRobot:OperationRet(nTurnTime)
	end
	self:MarkDirty(true)
end

--取消托管
function CGDMJRoom2:CancelAIReq(nCharID)
	self:CancelTurnTimer()
	self:CancelOperTimer()
	local tPlayer = self.m_tPlayerMap[nCharID]
	tPlayer.bAI = false
	if tPlayer.oBindRobot then
		goRobotMgr:RemoveRobot(nCharID)
	end
	self:MarkDirty(true)
end

--释放房间
function CGDMJRoom2:OnRelease()
	self:CancelTurnTimer()
	self:CancelOperTimer()

	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		if tPlayer.bRobot then
			goRobotMgr:RemoveRobot(nCharID)
		else
			local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
			oPlayer.m_oGame:SetCurrGame(0, 0, 0)
			--AI绑定的机器人
			if tPlayer.oBindRobot then
				goRobotMgr:RemoveRobot(nCharID)
			end
		end
	end
end

--加入房间
function CGDMJRoom2:Join(oPlayer)
	print("CGDMJRoom2:Join***", oPlayer:GetName())
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

	--生成玩家
	local tPlayer = self:GenPlayer(nCharID)
	self.m_tPlayerMap[nCharID] = tPlayer
	tPlayer.bRobot = oPlayer:GetObjType() == gtObjType.eRobot
	self.m_nPlayerCount = self.m_nPlayerCount + 1
	if self.m_nPlayerCount == 1 then --第1个进入玩家坐庄
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

	--进入事件
	self:OnPlayerEnter(oPlayer)
	self:MarkDirty(true)
	return true
end

--进入房间事件
function CGDMJRoom2:OnPlayerEnter(oPlayer)
	print("CGDMJRoom2:OnPlayerEnter***", oPlayer:GetName())
	local nCharID = oPlayer:GetCharID()
	oPlayer.m_oGame:SetCurrGame(self:GameType(), self:RoomID(), self:DeskType())

	--玩家信息
	local tMyInfo
	local tMsg = {bSuccess=true, nRoomID=self:RoomID(), nRoomType=self:RoomType(), tPlayerList={}}
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		local oTmpPlayer = self:GetPlayerObj(nTmpCharID)
		local tInfo = 
		{
			nCharID = nTmpCharID,
			sName = oTmpPlayer:GetName(),
			sImgURL = oTmpPlayer:GetImgURL(),
			nScore = oTmpPlayer.m_oGDMJ:GetTili(),
			nFengWei = tTmpPlayer.nFengWei,
			bOffline = tTmpPlayer.bOffline,
			bReady = tTmpPlayer.bReady,
			nWinCnt = oTmpPlayer.m_oGDMJ:GetWinCnt(),
			nRounds = oTmpPlayer.m_oGDMJ:GetRounds(),
		}
		table.insert(tMsg.tPlayerList, tInfo)
		if nTmpCharID == nCharID then
			tMyInfo = tInfo
		end
	end

	--发给自己
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "JoinRoomRet", tMsg)
	--广播其他玩家
	CmdNet.PBBroadcastExter(self:GetSessionList(nMyCharID), "PlayerJoinBroadcast", {tPlayer=tMyInfo})
	--恢复牌局(中途重连)
	if self.m_nState ~= self.tState.eInit then
		self:RecoverDesk(oPlayer)
	end
	--通知GLOBAL
	Srv2Srv.OnPlayerEnterReq(gtNetConf:GlobalService(), 0, self:RoomID(), self.m_nDeskType, nCharID)
end

--离开房间
function CGDMJRoom2:Leave(oPlayer)
	print("CGDMJRoom2:Leave***", oPlayer:GetName())
	local nCharID = oPlayer:GetCharID()
	local tPlayer = self.m_tPlayerMap[nCharID]
	if not tPlayer then
		return
	end
	if self:IsStart() then
		--return oPlayer:Tips(ctLang[3]) fix pd 暂时屏蔽
	end

	if self.m_nBankerUser == nCharID then
		self.m_nBankerUser = self:GetNextFengWeiPlayer(nCharID)
	end
	self.m_tPlayerMap[nCharID] = nil
	self.m_tFengWei[tPlayer.nFengWei] = nil
	self.m_nPlayerCount = self.m_nPlayerCount - 1
	if tPlayer.oBindRobot then --清除绑定的机器人
		goRobotMgr:RemoveRobot(nCharID)
	end

	self:OnPlayerLeave(oPlayer)
	self:MarkDirty(true)
end

--离开房间事件
function CGDMJRoom2:OnPlayerLeave(oPlayer)
	print("CGDMJRoom2:OnPlayerLeave***", oPlayer:GetName())
	oPlayer.m_oGame:SetCurrGame(0, 0, 0)
	local nCharID = oPlayer:GetCharID()
	--发给自己
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "LeaveRoomRet", {nRoomType=self:RoomType()})
	--广播其他玩家
	CmdNet.PBBroadcastExter(self:GetSessionList(nCharID), "PlayerLeaveBroadcast", {nCharID=nCharID})
	--通知GLOAL
	Srv2Srv.OnPlayerLeaveReq(gtNetConf:GlobalService(), 0, self:RoomID(), self.m_nDeskType, nCharID)

	--没有人了解散房间
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
function CGDMJRoom2:Offline(oPlayer)
	print("CGDMJRoom2:Offline***", oPlayer:GetName()) 
	if self.m_nState ~= self.tState.eStart then
		self.m_oRoomMgr:FreeRoomLeaveReq(oPlayer)
		return
	end
end

--上线事件
function CGDMJRoom2:Online(oPlayer)
	print("CGDMJRoom2:Online***", oPlayer:GetName()) 
end

--玩家准备
function CGDMJRoom2:PlayerReady(oPlayer)
	print("CGDMJRoom2:PlayerReady***", oPlayer:GetName())
	local nCharID = oPlayer:GetCharID()
	local tPlayer = self:GetPlayer(nCharID)
	tPlayer.bReady = true
	self:MarkDirty(true)
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

--真正解散房间
function CGDMJRoom2:OnDismiss()
	print("CGDMJRoom2:OnDismiss***")
	self.m_nState = self.tState.eGamgOver
	--通知GLOBAL
	Srv2Srv.OnDismissRoomReq(gtNetConf:GlobalService(), 0, self:RoomID(), self.m_nDeskType)
	--释放房间
	self.m_oRoomMgr:RemoveRoom(self:RoomID())
	CmdNet.PBBroadcastExter(self:GetSessionList(), "DismissRoomBroadcast", {nRoomID=self:RoomID()})
end

--1局结束
function CGDMJRoom2:OnRoundEnd(nWinnerID)
	print("CGDMJRoom2:_OnRoundEnd***", nWinnerID)
	nWinnerID = nWinnerID or 0
	self.m_nState = self.tState.eRound
	self:CancelTurnTimer()
	self:CancelOperTimer()

	local nNewBankerUser = self.m_nBankerUser
	local tOldBanker = assert(self:GetPlayer(self.m_nBankerUser))

	--撤销连庄
	if nWinnerID > 0 then
		if nWinnerID ~= self.m_nBankerUser then
			tOldBanker.nBankerCnt = 0
			nNewBankerUser = nWinnerID
		end
	end

	--结果结算
	local tRoundScore = self:RoundCalc(nWinnerID)

	--处理杂事
	local tWinMap, tLoseMap = {}, {}
	local nAwardPool, nAwardPool1 = 0, 0
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		if tPlayer.oBindRobot then
			tPlayer.oBindRobot:OnRoundEnd()
		end
		--奖池
		local nScore = tRoundScore[nCharID]
		if nScore < 0 then
			nAwardPool = nAwardPool + math.abs(nScore)
			tLoseMap[nCharID] = nScore
		elseif nScore > 0 then
			nAwardPool1 = nAwardPool1 + nScore
			tWinMap[nCharID] = nScore
		end

		--连胜奖励(金币/奖券)
		local oPlayer = self:GetPlayerObj(nCharID)
		local nWinCnt = oPlayer.m_oGDMJ:GetWinCnt()
		if nCharID == nWinnerID then
			nWinCnt = nWinCnt + 1
			oPlayer.m_oGDMJ:SetWinCnt(nWinCnt)
			local nIndex = math.min(#ctGDMJAwardConf, nWinCnt)
			local tAwardConf = ctGDMJAwardConf[nIndex]["tAward"..self:DeskType()]
			if tAwardConf then
				oPlayer:AddItem(tAwardConf[1], tAwardConf[2], tAwardConf[3], gtReason.eFreeRoomWinCntAward, true)
				print(nCharID, "连胜奖励:", tAwardConf)
			end
		else
			oPlayer.m_oGDMJ:SetWinCnt(0)
		end

		--对局奖励(奖券)
		local nRounds = oPlayer.m_oGDMJ:GetRounds() + 1
		oPlayer.m_oGDMJ:SetRounds(nRounds)
		local tDeskConf = ctGDMJDeskConf[self:DeskType()]
		local tAwardConf = tDeskConf.tTicket[1]
		if tAwardConf[1] > 0 and nRounds % tAwardConf[1] == 0 then
			oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eTicket, tAwardConf[2], gtReason.eFreeRoomRoundAward, true)
			print(nCharID, "对局奖励:", tAwardConf)
		end

		--经验奖励
		local nExpAward = tDeskConf.nExp
		oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eExp, nExpAward, gtReason.eFreeRoomRoundAward, true)
		print(nCharID, "经验奖励:", nExpAward)

		--发送连胜，对局信息
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "FreeRoomWinRoundRet", {nWinCnt=nWinCnt, nRounds=nRounds})

		--记录场数
		oPlayer.m_oGDMJ:AddDayRound(nCharID==nWinnerID)

		--清除离线玩家
		if not oPlayer:IsOnline() then
			self.m_oRoomMgr:FreeRoomLeaveReq(oPlayer)
		end
	end
	assert(nAwardPool == nAwardPool1, "结算积分错误")

	--扣除服务费,结算体力
	local nDeskTax = ctGDMJDeskConf[self.m_nDeskType]
	local tRealRoundScore = {}
	for nCharID, nScore in pairs(tWinMap) do
		local nWinDeskScore = self.m_tPlayerMap[nCharID].nScore
		local nWinRatio = nScore / nAwardPool
		local nRealWin = 0 
		for nCharID1, nScore1 in pairs(tLoseMap) do
			nScore1 = math.abs(nScore1)
			local nLoseDeskScore = self.m_tPlayerMap[nCharID1].nScore
			local nLoseScore = math.min(math.floor(nLoseDeskScore*nWinRatio), math.floor(nScore1*nWinRatio))
			local nMinWin = math.min(nWinDeskScore, nLoseScore)
			nRealWin = nRealWin + nMinWin
			tRealRoundScore[nCharID1] = (tRealRoundScore[nCharID1] or 0) - nMinWin
			print(nCharID.."->"..nCharID1, nMinWin, nRealWin)
		end
		nRealWin = math.floor(math.max(0, nRealWin - nDeskTax * nWinRatio))
		tRealRoundScore[nCharID] = nRealWin
	end
	print("RealRoundScore:", tRealRoundScore)

	--发送信息
	local tMsg = {nHuPlayer=nWinnerID, tMaMJ=self.m_tMaMJ, tResult={}}
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		local oPlayer = self:GetPlayerObj(nCharID)
		local nCurTili = oPlayer.m_oGDMJ:GetTili()
		nCurTili = math.max(0, nCurTili + (tRealRoundScore[nCharID] or 0))
		oPlayer.m_oGDMJ:SetTili(nCurTili)
		local tResult = 
		{
			nCharID = nCharID
			, nTotalScore = nCurTili
			, nRoundScore = tRealRoundScore[nCharID] or 0
			, tHandMJ = table.DeepCopy(tPlayer.tHandMJ)
			, tBlock={}
		}
		for _, oBlock in ipairs(tPlayer.oHu.tBlock) do
			table.insert(tResult.tBlock, {nFirstMJ=oBlock.nFirst, nBlockStyle=oBlock.nStyle})
		end
		table.insert(tMsg.tResult, tResult)
	end
	CmdNet.PBBroadcastExter(self:GetSessionList(), "RoundEndRet", tMsg)

	--开始新的一局
	if self.m_nRound >= self.m_tOption.nRound then
		self.m_nRound = 1
		self:OnGameEnd()
	else
		self.m_nRound = self.m_nRound + 1
		self:InitRound(nNewBankerUser)
	end
	self:MarkDirty(true)
end

--1盘结束
function CGDMJRoom2:OnGameEnd()
	-- for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
	-- 	if not tPlayer.bRobot then
	-- 		local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	-- 		self.m_oRoomMgr:FreeRoomSwitchReq(oPlayer)
	-- 	end
	-- end
	-- self:MarkDirty(true)
end

--切换玩家事件
function CGDMJRoom2:OnSwitchPlayer(nCharID)
	print("CGDMJRoom2:OnSwitchPlayer***", nCharID)
	self:CancelTurnTimer()
	local tPlayer = self.m_tPlayerMap[nCharID]
	if not tPlayer.bRobot then
		if tPlayer.bAI then
			self:OnTurnTimeOut(nCharID)
		else
			local nRemainTime = math.max(1, os.time() + nTurnTime - self.m_nTurnStartTime)
			self:RegisterTurnTimer(nCharID, nRemainTime)
		end
	end
end

--可操作事件
function CGDMJRoom2:OnSendOperation(nCharID)
	print("CGDMJRoom2:OnSendOperation***", nCharID)
	local tPlayer = self.m_tPlayerMap[nCharID]
	if not tPlayer.bRobot then
		if tPlayer.bAI then
			self:OnOperTimeOut(nCharID)
		else
			self:RegisterOperTimer(nCharID, nTurnTime)
		end
	else
		local oRobot = goRobotMgr:GetRobot(nCharID)
		oRobot:OperationRet(nTurnTime)
	end
end
