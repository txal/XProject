local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local tNiuNiuConf = gtNiuNiuConf

--出牌时间
local nTurnTime = 15
--最大手牌
local nMaxHandCard = tNiuNiuConf.tEtc.nMaxHandCard
--最大玩家数
local nMaxPlayer = tNiuNiuConf.tEtc.nMaxPlayer

--游戏状态
CNiuNiuRoomBase.tState = 
{
	eFree = 0, 		--等待开始		
	eCall = 1, 		--叫庄状态
	eScore = 2, 	--下注状态
	ePlaying = 3, 	--游戏进行
}

--结束原因
CNiuNiuRoomBase.tReason =
{
	eNormal = 0x00,		--常规结束
	eDismiss = 0x01,	--游戏解散
	eUserLeft = 0x02,	--用户离开
}

--牛牛房间基类
function CNiuNiuRoomBase:Ctor(oRoomMgr, nRoomID, nRoomType, nDeskType)
	assert(oRoomMgr and nRoomID and nRoomType)
	self.m_nGameType = gtGameType.eNiuNiu 
	self.m_nRoomType = nRoomType
	self.m_nDeskType = nDeskType
	self.m_oRoomMgr = oRoomMgr
	self.m_nRoomID = nRoomID

	--玩家数据
	self.m_tPlayerMap = {} 	--{[nCharID]={nChairID=1,nGameScore=0}}
	self.m_nPlayerCount = 0

	--游戏状态
	self.m_nState = self.tState.eFree

	--游戏变量	
	self.m_nStockScore = 0 		--总输赢分
	self.m_nExitScore = 0 		--强退分数
	self.m_nBankerUser = 0 		--庄家用户
	self.m_nFirstCallUser = 0 	--始叫用户
	self.m_nCurrentUser = 0 	--当前用户

	--用户状态
	self.m_tTableScore = {} 	--下注数目
	self.m_tPlayStatus = {}		--游戏状态 {[nChairID]=nCharID}
	self.m_tCallStatus = {} 	--叫庄状态
	self.m_tOxCard = {}			--牛牛数据
	for i = 1, nMaxPlayer do
		self.m_tOxCard[i] = 0xFF
	end

	--扑克变量
	self.m_tHandCardData = {} 	--桌面扑克

	--下注信息
	self.m_tTurnMaxScore ={} 	--最大下注
end

function CNiuNiuRoomBase:IsFull() return self.m_nPlayerCount >= nMaxPlayer end
function CNiuNiuRoomBase:MarkDirty(bDirty) self.m_oRoomMgr:MarkDirty(self.m_nRoomID, bDirty) end

function CNiuNiuRoomBase:LoadData(tData) assert(false, "子类没定义该接口") end
function CNiuNiuRoomBase:SaveData() assert(false, "子类没定义该接口") end

function CNiuNiuRoomBase:GameType() return self.m_nGameType end
function CNiuNiuRoomBase:RoomType() return self.m_nRoomType end
function CNiuNiuRoomBase:DeskType() return self.m_nDeskType end
function CNiuNiuRoomBase:RoomID() return self.m_nRoomID end

function CNiuNiuRoomBase:Offline(oPlayer) end
function CNiuNiuRoomBase:Online(oPlayer) end

--是否已经开始
function CNiuNiuRoomBase:IsStart()
	return self.m_nState == self.tState.eStart
end

--取玩家SESSION
function CNiuNiuRoomBase:GetSession(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	local nSession = oPlayer and oPlayer:GetSession() or 0
	return nSession
end

--取房间玩家SESSION
function CNiuNiuRoomBase:GetSessionList(nExceptID)
	local tSessionList = {}
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		if nCharID ~= nExceptID then
			local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
			local nSession = oPlayer and oPlayer:GetSession() or 0
			if nSession > 0 then
				table.insert(tSessionList, nSession)
			end
		end
	end
	return tSessionList
end

--取玩家数据
function CNiuNiuRoomBase:GetPlayer(nCharID)
	return self.m_tPlayerMap[nCharID]
end

--取玩家对象
function CNiuNiuRoomBase:GetPlayerObj(nCharID)
	local tPlayer = self:GetPlayer(nCharID)
	if not tPlayer then
		return
	end
	if tPlayer.bRobot then
		return goRobotMgr:GetRobot(nCharID)
	else
		return goPlayerMgr:GetPlayerByCharID(nCharID)
	end
end

--复位房间
function CNiuNiuRoomBase:ResetRoom()
	--游戏变量
	self.m_nExitScore = 0	
	self.m_CurrentUser = 0

	--用户状态
	self.m_tTableScore = {} 	--下注数目
	self.m_tPlayStatus = {}		--游戏状态
	self.m_tCallStatus = {} 	--叫装状态
	self.m_tOxCard = {}			--牛牛数据
	for i = 1, nMaxPlayer do
		self.m_tOxCard[i] = 0xFF
	end

	--扑克变量
	self.m_tHandCardData = {} 	--桌面扑克

	--下注信息
	self.m_tTurnMaxScore ={} 	--最大下注
end

--游戏状态
function CNiuNiuRoomBase:IsUserPlaying(nChairID)
	if nChairID <= nMaxPlayer and self.m_tPlayStatus[nChairID] then
		return true
	end
end

--游戏开始
function CNiuNiuRoomBase:GameStart()
	--设置状态
	self.m_nState = self.tState.eCall

	--用户状态
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		m_bPlayStatus[tPlayer.nChairID] = true
	end

	--首局随机始叫
	if self.m_nFirstCallUser == 0 then
		self.m_nFirstCallUser = math.random(1, nMaxPlayer)
	else
		self.m_nFirstCallUser = (self.m_nFirstCallUser + 1) % nMaxPlayer
	end

	--始叫用户
	while not m_bPlayStatus[self.m_nFirstCallUser] do
		self.m_nFirstCallUser = (self.m_nFirstCallUser + 1) % nMaxPlayer
	end

	--当前用户
	self.m_nCurrentUser = self.m_nFisrtCallUser

	--发送庄家
	CmdNet.PBBroadcastExter(self:GetSessionList(), "NNCallBankerRet", {nCallBanker=self.m_nCurrentUser})
end

--游戏结束
-- function CNiuNiuRoomBase:GameEnd(nChairID, nReason)
-- 	--常规结束
-- 	if nReason == self.tReason.eNormal then
-- 		--定义变量
-- 		local tWinTimes = {}
-- 		local tWinCount = {}
-- 		--保存扑克
-- 		local tUserCardData = table.DeepCopy(self.m_tHandCardData)

-- 		--庄家倍数
-- 		assert(self.m_tOxCard[self.m_nBankerUser] ~= 0xFF)
-- 		if self.m_tOxCard[m_wBankerUser] then
-- 			tWinTimes[self.m_nBankerUser] = self:GetTimes(tUserCardData[self.m_nBankerUser])
-- 		else
-- 			tWinTimes[self.m_nBankerUser] = 1
-- 		end

-- 		--对比玩家
-- 		for i = 1, nMaxPlayer do
-- 			if i == self.m_nBankerUser or not self.m_tPlayStatus[i] then
-- 			else
-- 				assert(self.m_tOxCard[i] ~= 0xFF)
-- 				--对比扑克
-- 				if self:CompareCard(tUserCardData[i], tUserCardData[self.m_nBankerUser], self.m_bOxCard[i], self.m_tOxCard[m_wBankerUser]) then
-- 					tWinCount[i] = (tWinCount[i] or 0) + 1
-- 					--获取倍数
-- 					if self.m_tOxCard[i] then
-- 						tWinTimes[i] = self:GetTimes(tUserCardData[i])
-- 					else
-- 						tWinTimes[i] = 1
-- 					end
-- 				else
-- 					tWinCount[self.m_nBankerUser] = (tWinCount[self.m_nBankerUser] or 0) + 1
-- 				end
-- 			end
-- 		end

-- 		--统计得分
-- 		local tGameScore = {}
-- 		for i = 1, nMaxPlayer do
-- 			if i == self.m_nBankerUser or not self.m_tPlayStatus[i] then
-- 				tGameScore[i] = tGameScore[i] or 0
-- 			else
-- 				local j = i
-- 				if tWinCount[j] > 0	then --闲家胜利
-- 					tGameScore[j] = self.m_tTableScore[j] * tWinTimes[j]
-- 					tGameScore[self.m_nBankerUser] = tGameScore[self.m_nBankerUser] - tGameScore[j]
-- 					self.m_tTableScore[j] = 0

-- 				else --庄家胜利
-- 					tGameScore[j] = (-1) * self.m_tTableScore[j] * tWinTimes[self.m_BankerUser]
-- 					tGameScore[self.m_nBankerUser] = tGameScore[self.m_nBankerUser] + (-1)*tGameScore[j]
-- 					self.m_tTableScore[j] = 0
-- 				end
-- 			end
-- 		end

-- 		--闲家强退分数	
-- 		tGameScore[self.m_nBankerUser] = tGameScore[self.m_nBankerUser] + self.m_nExitScore

-- 		--离开用户 fix pd 不明白
-- 		for i = 1, nMaxPlayer do
-- 			if self.m_tTableScore[i] > 0 then
-- 				tGameScore[i] = -self.m_tTableScore[i]
-- 			end
-- 		end

-- 		--扣税变量
-- 		local nRevenue = 0.005

-- 		--积分税收
-- 		local tGameTax = {}
-- 		for i = 1, nMaxPlayer do
-- 			if tGameScore[i] > 0 then
-- 				tGameTax[i] = math.ceil(tGameScore[i]*nRevenue)
-- 				tGameScore[i] = math.max(0, tGameScore[i]-tGameTax[i])
-- 			else
-- 				tGameTax[i] = 0
-- 			end
-- 		end

-- 		--发送信息
-- 		CmdNet.PBBroadcastExter(self:GetSessionList(), "NNGameEndRet", {tGameScore=tGameScore, tGameTax=tGameTax})

-- 		--修改积分
-- 		for i = 1, nMaxPlayer do
-- 			if self.m_tPlayStatus[i] then
-- 				local tPlayer = self.m_tPlayerMap[self.m_tPlayStatus[i]]
-- 				tPlayer.nGameScore = tGameScore[i]
-- 				local bWin = tGameScore[i] > 0 
-- 			end
-- 		end

-- 		--库存统计
-- 		for i = 1, nMaxPlayer do
-- 			--获取用户
-- 			if self.m_tPlayStatus[i] then
-- 				local tPlayer = self.m_tPlayerMap[self.m_tPlayStatus[i]]
-- 				--库存累计
-- 				if tPlayer.bRobot then
-- 					self.m_nStockScore = self.m_nStockScore + tGameScore[i]
-- 				end
-- 			end
-- 		end

-- 		--库存回收
-- 		self.m_nStockScore = 0

-- 		--结束游戏
-- 		--m_pITableFrame->ConcludeGame();
-- 		return true
-- 	end

-- 	--用户强退
-- 	if nReason == self.tReason.eUserLeft then
-- 		assert(nChairID <= nMaxPlayer and self.m_tPlayStatus[nChairID])
-- 		--设置状态
-- 		local nCharID = self.m_tPlayStatus[nChairID]
-- 		self.m_tPlayStatus[nChairID] = nil
-- 		self.m_tPlayerMap[nCharID] = nil
-- 		self.m_nPlayerCount = self.m_nPlayerCount - 1

-- 		--发送信息
-- 		CmdNet.PBBroadcastExter(self:GetSessionList(), "NNPlayerExit", {nChairID=nChairID})

-- 		tWinTimes = {}
-- 		if self.m_nState > self.tState.eCall then
-- 				if nChairID == self.m_nBankerUser then	--庄家强退
-- 					--定义变量
-- 					local tUserCardData = table.DeepCopy(self.m_tHandCardData)

-- 					--得分倍数
-- 					for i = 1, nMaxPlayer do
-- 						if i == self.m_nBankerUser or not self.m_tPlayStatus[i] then
-- 						else
-- 							tWinTimes[i] = self.m_nState ~= self.tState.ePlaying and 1 or self:GetTimes(tUserCardData[i])
-- 						end
-- 					end

-- 					--统计得分 已下或没下
-- 					local tGameScore = {}
-- 					for i = 1, nMaxPlayer do
-- 						if i == self.m_BankerUser or not self.m_tPlayStatus[i] then
-- 							tGameScore[i] = tGameScore[i] or 0
-- 						else
-- 							tGameScore[i] = self.m_tTableScore[i] * tWinTimes[i]
-- 							tGameScore[self.m_nBankerUser] = tGameScore[self.m_nBankerUser] - tGameScore[i]
-- 							self.m_tTableScore[i] = 0
-- 						end
-- 					end

-- 					--闲家强退分数 
-- 					tGameScore[self.m_nBankerUser] = tGameScore[self.m_nBankerUser] + self.m_nExitScore

-- 					--离开用户
-- 					for i = 1, nMaxPlayer do
-- 						if self.m_tTableScore[i] > 0 then
-- 							tGameScore[i] = -self.m_tTableScore[i]
-- 						end
-- 					end

-- 					//扣税变量
-- 					WORD cbRevenue=m_pGameServiceOption->wRevenue;

-- 					//积分税收
-- 					for(WORD i=0;i<m_wPlayerCount;i++)
-- 					{
-- 						if(GameEnd.lGameScore[i]>0L)
-- 						{
-- 							GameEnd.lGameTax[i]=GameEnd.lGameScore[i]*cbRevenue/1000L;
-- 							GameEnd.lGameScore[i]-=GameEnd.lGameTax[i];
-- 						}
-- 					}

-- 					//发送信息
-- 					for (WORD i=0;i<m_wPlayerCount;i++)
-- 					{
-- 						if(i==m_wBankerUser || m_bPlayStatus[i]==FALSE)continue;
-- 						m_pITableFrame->SendTableData(i,SUB_S_GAME_END,&GameEnd,sizeof(GameEnd));
-- 					}
-- 					m_pITableFrame->SendLookonData(INVALID_CHAIR,SUB_S_GAME_END,&GameEnd,sizeof(GameEnd));

-- 					//修改积分
-- 					for (WORD i=0;i<m_wPlayerCount;i++)
-- 					{
-- 						if(m_bPlayStatus[i]==FALSE && i!=m_wBankerUser)continue;
-- 						enScoreKind nScoreKind=(GameEnd.lGameScore[i]>0L)?enScoreKind_Win:enScoreKind_Lost;
-- 						m_pITableFrame->WriteUserScore(i,GameEnd.lGameScore[i],GameEnd.lGameTax[i],nScoreKind);
-- 					}

-- 					//获取用户
-- 					IServerUserItem * pIServerUserIte=m_pITableFrame->GetServerUserItem(m_wBankerUser);
					
-- 					//库存累计
-- 					if ((pIServerUserIte!=NULL)&&(pIServerUserIte->IsAndroidUser()!=false)) 
-- 						m_lStockScore+=GameEnd.lGameScore[m_wBankerUser];
	
-- 					//库存回收
-- 					m_lStockScore=m_lStockScore-m_lStockScore*STOCK_TAX/100;

-- 					//结束游戏
-- 					m_pITableFrame->ConcludeGame();
-- 				}
-- 				else						//闲家强退
-- 				{
-- 					//已经下注
-- 					if (m_lTableScore[wChairID]>0L)
-- 					{
-- 						ZeroMemory(m_wWinTimes,sizeof(m_wWinTimes));

-- 						//用户扑克
-- 						BYTE cbUserCardData[MAX_COUNT];
-- 						CopyMemory(cbUserCardData,m_cbHandCardData[m_wBankerUser],MAX_COUNT);

-- 						//用户倍数
-- 						m_wWinTimes[m_wBankerUser]=(m_pITableFrame->GetGameStatus()==GS_TK_SCORE)?(1):(m_GameLogic.GetTimes(cbUserCardData,MAX_COUNT));

-- 						//修改积分
-- 						LONG lScore=-m_lTableScore[wChairID]*m_wWinTimes[m_wBankerUser];
-- 						m_lExitScore+=(-1*lScore);
-- 						m_lTableScore[wChairID]=(-1*lScore);
-- 						m_pITableFrame->WriteUserScore(wChairID,lScore,0,enScoreKind_Lost);

-- 						//获取用户
-- 						IServerUserItem * pIServerUserIte=m_pITableFrame->GetServerUserItem(wChairID);
						
-- 						//库存累计
-- 						if ((pIServerUserIte!=NULL)&&(pIServerUserIte->IsAndroidUser()!=false)) 
-- 							m_lStockScore+=lScore;		

-- 					}

-- 					//玩家人数
-- 					WORD wUserCount=0;
-- 					for (WORD i=0;i<m_wPlayerCount;i++)if(m_bPlayStatus[i]==TRUE)wUserCount++;

-- 					//结束游戏
-- 					if(wUserCount==1)
-- 					{
-- 						//定义变量
-- 						CMD_S_GameEnd GameEnd;
-- 						ZeroMemory(&GameEnd,sizeof(GameEnd));
-- 						ASSERT(m_lExitScore>=0L); 

-- 						//扣税变量
-- 						WORD cbRevenue=m_pGameServiceOption->wRevenue;

-- 						//统计得分
-- 						GameEnd.lGameScore[m_wBankerUser]+=m_lExitScore;
-- 						GameEnd.lGameTax[m_wBankerUser]=GameEnd.lGameScore[m_wBankerUser]*cbRevenue/1000L;
-- 						GameEnd.lGameScore[m_wBankerUser]-=GameEnd.lGameTax[m_wBankerUser];

-- 						//离开用户
-- 						for (WORD i=0;i<m_wPlayerCount;i++)
-- 						{
-- 							if(m_lTableScore[i]>0)GameEnd.lGameScore[i]=-m_lTableScore[i];
-- 						}

-- 						//发送信息
-- 						m_pITableFrame->SendTableData(m_wBankerUser,SUB_S_GAME_END,&GameEnd,sizeof(GameEnd));
-- 						m_pITableFrame->SendLookonData(INVALID_CHAIR,SUB_S_GAME_END,&GameEnd,sizeof(GameEnd));

-- 						for (WORD Zero=0;Zero<m_wPlayerCount;Zero++)if(m_lTableScore[Zero]!=0)break;
-- 						if(Zero!=m_wPlayerCount)
-- 						{
-- 							//修改积分
-- 							LONG lRevenue = GameEnd.lGameTax[m_wBankerUser];
-- 							LONG lScore=GameEnd.lGameScore[m_wBankerUser];
-- 							m_pITableFrame->WriteUserScore(m_wBankerUser,lScore,lRevenue,enScoreKind_Win);

-- 							//获取用户
-- 							IServerUserItem * pIServerUserIte=m_pITableFrame->GetServerUserItem(wChairID);
							
-- 							//库存累计
-- 							if ((pIServerUserIte!=NULL)&&(pIServerUserIte->IsAndroidUser()!=false)) 
-- 								m_lStockScore+=lScore;
-- 						}

-- 						//库存回收
-- 						m_lStockScore=m_lStockScore-m_lStockScore*STOCK_TAX/100;

-- 						//结束游戏
-- 						m_pITableFrame->ConcludeGame();		
-- 					}
-- 					else if	(m_pITableFrame->GetGameStatus()==GS_TK_SCORE && m_lTableScore[wChairID]==0L)
-- 					{
-- 						OnUserAddScore(wChairID,0);
-- 					}
-- 					else if (m_pITableFrame->GetGameStatus()==GS_TK_PLAYING && m_bOxCard[wChairID]==0xff)
-- 					{
-- 						OnUserOpenCard(wChairID,0);
-- 					}
-- 				}
-- 			else 
-- 			{
-- 				//玩家人数
-- 				WORD wUserCount=0;
-- 				for (WORD i=0;i<m_wPlayerCount;i++)if(m_bPlayStatus[i]==TRUE)wUserCount++;

-- 				//结束游戏
-- 				if(wUserCount==1)
-- 				{
-- 					//定义变量
-- 					CMD_S_GameEnd GameEnd;
-- 					ZeroMemory(&GameEnd,sizeof(GameEnd));

-- 					//发送信息
-- 					for (WORD i=0;i<m_wPlayerCount;i++)
-- 					{
-- 						if(i==m_wBankerUser || m_bPlayStatus[i]==FALSE)continue;
-- 						m_pITableFrame->SendTableData(i,SUB_S_GAME_END,&GameEnd,sizeof(GameEnd));
-- 					}
-- 					m_pITableFrame->SendLookonData(INVALID_CHAIR,SUB_S_GAME_END,&GameEnd,sizeof(GameEnd));

-- 					//结束游戏
-- 					m_pITableFrame->ConcludeGame();			
-- 				}
-- 				else if(m_wCurrentUser==wChairID)OnUserCallBanker(wChairID,0);
-- 			}

-- 			return true;
-- 		}
-- 	}

-- 	return false;
-- }


--牌类型
function CNiuNiuRoomBase:GetCarkColor(nCard)
	return nCard & tNiuNiuConf.tEtc.nMaskType
end

--牌值
function CNiuNiuRoomBase:GetCardValue(nCard)
	return nCard & tNiuNiuConf.tEtc.nMaskValue
end

--逻辑数值
function CNiuNiuRoomBase:GetCardLogicValue(nCard)
	--扑克属性
	local nCardColor = self:GetCardColor(nCard)
	local nCardValue = self:GetCardValue(nCard)
	--转换数值
	return nCardValue > 10 and 10 or nCardValue
end

--获取类型
function CNiuNiuRoomBase:GetCardType(tCardList)
	assert(#tCardList== nMaxHandCard)

	local nTenCount = 0
	local nKingCount = 0
	for i = 1, nMaxHandCard do
		local nCardVal = self:GetCardValue(tCardList[i])
		if  nCardVal > 10 then
			nKingCount = nKingCount + 1

		elseif nCardVal == 10 then
			nTenCount = nTenCount + 1 

		end
	end
	
	if nKingCount == nMaxHandCard then
		return tNiuNiuConf.tCardType.eFiveKing
	end
	if nKingCount == nMaxHandCard - 1 and nTenCount == 1 then
		return tNiuNiuConf.tCardType.eFourKing
	end

	local nSum = 0
	local tTemp = {}
	for i = 1, nMaxHandCard do
		local nCardVal = self:GetCardLogicValue(tCardList[i])
		tTemp[i] = nCardVal
		nSum = nSum + nCardVal
	end

	for i = 1, nMaxHandCard - 1 do
		for j = i + 1, nMaxHandCard do
			if (nSum - tTemp[i] - tTemp[j]) % 10 == 0 then
				return (tTemp[i] + tTemp[j]) > 10 and (tTemp[i] + tTemp[j] - 10) or (tTemp[i] + tTemp[j])
			end
		end
	end

	return tNiuNiuConf.tCardType.eValue0
end

--获取倍数
function CNiuNiuRoomBase:GetTimes(tCardList)
	if #tCardList ~= nMaxHandCard then
		return 0
	end

	local nTimes = self:GetCardType(tCardList)
	if nTimes < 7 then
		return 1
	end
	if nTimes == 7 then
		return 2
	end
	if nTimes == 8 then
		return 3
	end
	if nTimes == 9 then
		return 4
	end
	if nTimes == 10 then
		return 5
	end
	if nTimes == tNiuNiuConf.tCardType.eFourKing then
		return 5
	end
	if nTimes == tNiuNiuConf.tCardType.eFiveKing then
		return 5
	end
	return 0
end

--获取牛牛
function CNiuNiuRoomBase:GetOxCard(tCardList)
	assert(#tCardList == nMaxHandCard)

	--设置变量
	local nSum = 0
	local tTemp = {}
	local tTempCard = table.DeepCopy(tCardList, true)
	for i = 1, nMaxHandCard do
		local nCardVal = self:GetCardLogicValue(tCardList[i])
		tTemp[i] = nCardVal
		nSum = nSum + nCardVal
	end

	--查找牛牛
	for i = 1, nMaxHandCard do
		for j = i + 1, nMaxHandCard - 1 do
			if (nSum - tTemp[i] - tTemp[j]) % 10 == 0 then
				local nCount = 1
				for k = 1, nMaxHandCard do
					if k ~= i and k ~= j then
						tCardList[nCount] = tTempCard[k]
						nCount = nCount + 1
					end
				end
				assert(nCount == 4)
				tCardList[nCount] = tTempCard[i]
				tCardList[nCount+1] = tTempCard[j]
				return true
			end
		end
	end
	return
end

--获取整数
function CNiuNiuRoomBase:IsIntValue(tCardList)
	local nSum = 0
	for i = 1, #tCardList do
		nSum = nSum + self:GetCardLogicValue(tCardList[i])
	end
	assert(nSum > 0)
	return (nSum % 10 == 0)
end

--排列扑克
function CNiuNiuRoomBase:SortCardList(tCardList)
	local function _DescSort(nCard1, nCard2)
		local nCardVal1 = self:GetCardValue(nCard1)
		local nCardVal2 = self:GetCardValue(nCard2)
		if nCardVal1 == nCardVal2 then
			return nCard1 > nCard2
		else
			return nCardVal1 > nCardVal2
		end
	end
	table.sort(tCardList, _DescSort)
end

--混乱扑克
function CNiuNiuRoomBase:RandCardList()
	local nCardCount = nMaxHandCard * nMaxPlayer
	local tTmpCard = table.DeepCopy(tNiuNiuConf.tCard, true)
	local tRandCard = {}
	for k = 1, nCardCount do
		local nPos = math.random(1, #tTmpCard)
		table.insert(tRandCard, tTmpCard[nPos])
		tTmpCard[nPos] = tTmpCard[#tTmpCard]
		table.remove(tTmpCard)
	end
	return tRandCard
end

--对比扑克
function CNiuNiuRoomBase:CompareCard(tCardList1, tCardList2, bOx1, bOx2)
	if bOx1 ~= bOx2 then
		return bOx1
	end

	--比较牛大小
	if bOx1 then
		--获取点数
		local nCardType2 = self:GetCardType(tCardList2)
		local nCardType1 = self:GetCardType(tCardList1)

		--点数判断
		if nCardType1 ~= nCardType2 then
			return nCardType1 > nCardType2
		end
	end

	--排序大小
	local tTempCard1 = table.DeepCopy(tCardList1, true)
	local tTempCard2 = table.DeepCopy(tCardList2, true)
	self:SortCardList(tTempCard1)
	self:SortCardList(tTempCard2)

	--比较数值
	local nMaxVal1 = self:GetCardValue(tTempCard1[1])
	local nMaxVal2 = self:GetCardValue(tTempCard2[1])
	if nMaxVal1 == nMaxVal2 then
		--比较颜色
		return self:GetCardColor(tTempCard1[1]) > self:GetCardColor(tTempCard2[1])
	else
		return nMaxVal1 > nMaxVal2
	end
end
