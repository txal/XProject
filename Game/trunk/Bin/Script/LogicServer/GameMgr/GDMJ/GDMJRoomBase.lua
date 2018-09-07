local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local tGDMJConf = gtGDMJConf

--游戏状态
CGDMJRoomBase.tState = 
{
	eInit = 0,		--初始
	eStart = 1,		--开始
	eRound = 2,		--1局结束
	eGameOver= 3,	--游戏结束
}

--出牌时间
local nTurnTime = 15
--最大BLOCK数量
local nMaxBlock = (tGDMJConf.tEtc.nMaxHandMJ-2)/3
local nMaxHandMJ = tGDMJConf.tEtc.nMaxHandMJ
--排序函数
local function _AscSort(v1, v2)
	return v1 < v2
end

--房间基类
function CGDMJRoomBase:Ctor(oRoomMgr, nRoomID, nRoomType, nDeskType)
	assert(oRoomMgr and nRoomID and nRoomType)
	self.m_nGameType = gtGameType.eGDMJ 
	self.m_nRoomType = nRoomType
	self.m_nDeskType = nDeskType
	self.m_oRoomMgr = oRoomMgr
	self.m_nRoomID = nRoomID

end

function CGDMJRoomBase:GameType()
	return self.m_nGameType
end

function CGDMJRoomBase:RoomType()
	return self.m_nRoomType
end

function CGDMJRoomBase:DeskType()
	return self.m_nDeskType
end

function CGDMJRoomBase:RoomID()
	return self.m_nRoomID
end

function CGDMJRoomBase:LoadData(tData)
	assert(false, "子类没定义该接口")
end

function CGDMJRoomBase:SaveData()
	assert(false, "子类没定义该接口")
end

function CGDMJRoomBase:Offline(oPlayer)
end

function CGDMJRoomBase:Online(oPlayer)
end

--是否已经开始
function CGDMJRoomBase:IsStart()
	return self.m_nState == self.tState.eStart
end

--取玩家SESSION
function CGDMJRoomBase:GetSession(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	local nSession = oPlayer and oPlayer:GetSession() or 0
	return nSession
end

--取房间玩家SESSION
function CGDMJRoomBase:GetSessionList(nExceptID)
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
function CGDMJRoomBase:GetPlayer(nCharID)
	return self.m_tPlayerMap[nCharID]
end

--取玩家对象
function CGDMJRoomBase:GetPlayerObj(nCharID)
	local tPlayer = self:GetPlayer(nCharID)
	if not tPlayer then
		return
	end
	local oPlayer
	if tPlayer.bRobot then
		oPlayer = goRobotMgr:GetRobot(nCharID)
	else
		oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	end
	return oPlayer
end

--房间是否已满 
function CGDMJRoomBase:IsFull()
	return self.m_nPlayerCount >= tGDMJConf.tEtc.nMaxPlayer
end

--设置脏
function CGDMJRoomBase:MarkDirty(bDirty)
	self.m_oRoomMgr:MarkDirty(self.m_nRoomID, bDirty)
end

--取下一风位玩家
function CGDMJRoomBase:GetNextFengWeiPlayer(nCharID)
	local tPlayer = assert(self:GetPlayer(nCharID))
	for i = tPlayer.nFengWei + 1, tPlayer.nFengWei + tGDMJConf.tEtc.nMaxPlayer - 1 do
		local nFengWei = i % tGDMJConf.tEtc.nMaxPlayer
		if nFengWei == 0 then
			nFengWei = tGDMJConf.tEtc.nMaxPlayer
		end
		if self.m_tFengWei[nFengWei] then
			return self.m_tFengWei[nFengWei]
		end
	end
end

--取最大操作权限
function CGDMJRoomBase:GetMaxRightPlayer()
	local nMaxRight, nMaxRightCharID = 0, 0
	for nFengWei, nCharID in ipairs(self.m_tFengWei) do
		local tPlayer = self.m_tPlayerMap[nCharID]
		if tPlayer and tPlayer.nActionRight > nMaxRight then
			nMaxRight = tPlayer.nActionRight
			nMaxRightCharID = nCharID
		end
	end
	return nMaxRightCharID, nMaxRight
end

--打乱麻将
function CGDMJRoomBase:CopyRandomMJ()
	local tCopyMJ = {}
	--COPY麻将(无风处理)
	for _, nMJ in ipairs(tGDMJConf.tMJs) do
		if self.m_tOption.bWuFeng and nMJ >= 0x31 and nMJ <= 0x34 then

		else
			table.insert(tCopyMJ, nMJ)
		end
	end
	--打乱麻将
	for i = 1, #tCopyMJ do
		local nRnd = math.random(1, #tCopyMJ)
		if i ~= nRnd then
			nMJTmp = tCopyMJ[i]
			tCopyMJ[i] = tCopyMJ[nRnd]
			tCopyMJ[nRnd] = nMJTmp
		end
	end
	--马牌处理
	local nMaCount = 0
	local nMaType = self.m_tOption.nMaType
	if nMaType == tGDMJConf.tMaType.eTwo then
		nMaCount = 2
	elseif nMaType == tGDMJConf.tMaType.eFour then
		nMaCount = 4
	elseif nMaType == tGDMJConf.tMaType.eSix then
		nMaCount = 6
	elseif nMaType == tGDMJConf.tMaType.eZhuang then
		local tBanker = assert(self:GetPlayer(self.m_nBankerUser))
		nMaCount = math.min(4, math.max(1, tBanker.nBankerCnt))
	end
	for i = 1, nMaCount do
		table.insert(self.m_tMaMJ, tCopyMJ[#tCopyMJ])
		table.remove(tCopyMJ)
	end
	self:MarkDirty(true)
	return tCopyMJ
end

--排序麻将
function CGDMJRoomBase:SortMJ(tHandMJ, nHandMJ)
	assert(nHandMJ == nMaxHandMJ or nHandMJ == nMaxHandMJ - 1, "牌数量错误")
	self:SortGhost(tHandMJ)
	if tHandMJ[nMaxHandMJ] == 0xFF then
		tHandMJ[nMaxHandMJ] = 0
	end
	self:MarkDirty(true)
end

--排序鬼牌(如果有)
function CGDMJRoomBase:SortGhost(tHandMJ)
	if #(self.m_tGhostList or {}) <= 0 then
		table.sort(tHandMJ, _AscSort)
		return
	end

	--筛选鬼牌
	for k, nMJ in ipairs(tHandMJ) do
		if table.InArray(nMJ, self.m_tGhostList) then
			tHandMJ[k] = -nMJ
		end
	end
	table.sort(tHandMJ, _AscSort)

	--调整鬼位置
	local tGhost, nPos = {}, #tHandMJ
	for k, nMJ in ipairs(tHandMJ) do
		if nMJ < 0 then
			tHandMJ[k] = 0
			table.insert(tGhost, math.abs(nMJ))
		elseif nMJ > 0 then
			nPos = k - 1
			break
		end
	end

	for k, nMJ in ipairs(tGhost) do
		tHandMJ[nPos] = nMJ
		nPos = nPos - 1
	end
	return true
end

--切换玩家事件
function CGDMJRoomBase:OnSwitchPlayer(nCharID)
	--有需要子类实现
end

--切换玩家
function CGDMJRoomBase:SwitchPlayer(nCharID)
	self.m_nCurrentUser = nCharID
	self.m_nTurnStartTime = os.time()
	local tMsg = {nCharID=nCharID, nRemainTime=nTurnTime}
	CmdNet.PBBroadcastExter(self:GetSessionList(), "SwitchPlayerRet", tMsg)
	self:MarkDirty(true)

	--机器人
	local tPlayer = self:GetPlayer(nCharID)
	if tPlayer.bRobot then
		local oRobot = goRobotMgr:GetRobot(nCharID)
		oRobot:SwitchPlayerRet(nTurnTime)
	else
		self:OnSwitchPlayer(nCharID)
	end
end

--翻鬼牌
function CGDMJRoomBase:OpenGhost()
	--有需要子类实现
end

--游戏开始
function CGDMJRoomBase:GameStart()
	print("CGDMJRoomBase:GameStart***")
	if self.m_nState == self.tState.eGameOver then
		print("游戏已结束")
		return
	end
	if self.m_nState == self.tState.eStart then
		print("游戏已经开始")
		return
	end

	--连庄计算
	local tBanker = self:GetPlayer(self.m_nBankerUser)
	tBanker.nBankerCnt = tBanker.nBankerCnt + 1

	--生成并打乱麻将
	self.m_tTouchMJ = self:CopyRandomMJ()

	--发牌
	local tPlayerMJ = {}
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		local nHu, nGang = 0, 0
		if nCharID == self.m_nBankerUser then
	        tPlayer.nHandMJ = nMaxHandMJ
            for i = 1, tPlayer.nHandMJ do
            	local nMJ = self.m_tTouchMJ[#self.m_tTouchMJ]
                tPlayer.tHandMJ[i] = nMJ
                table.remove(self.m_tTouchMJ)
            end
            self:SortMJ(tPlayer.tHandMJ, tPlayer.nHandMJ)

            nHu = self:IsHu(tPlayer.tHandMJ, tPlayer.nHandMJ-1, tPlayer.tHandMJ[nMaxHandMJ], tPlayer.oHu)
            nGang = self:IsAnGang(tPlayer.tHandMJ, tPlayer.nHandMJ).nGangStyle
            if nHu > 0 then
            	tPlayer.nActionRight = tGDMJConf.tMJAction.eHu
            elseif nGang > 0 then
            	tPlayer.nActionRight = tGDMJConf.tMJAction.eGang
            end
        else
            tPlayer.nHandMJ = nMaxHandMJ - 1
            for i = 1, tPlayer.nHandMJ do
            	local nMJ = self.m_tTouchMJ[#self.m_tTouchMJ]
                tPlayer.tHandMJ[i] = nMJ
                table.remove(self.m_tTouchMJ)
            end
            tPlayer.tHandMJ[nMaxHandMJ] = 0xFF 
            self:SortMJ(tPlayer.tHandMJ, tPlayer.nHandMJ)
		end
		local tInfo = self:GenPlayerMJMsg(tPlayer)
		if nCharID == self.m_nBankerUser then
			tInfo.nHu = nHu
			tInfo.nGang = nGang
			tInfo.bShow = true
		end
		table.insert(tPlayerMJ, tInfo)
	end

	--发送信息
	local tMsg =
	{
		tPlayerMJ = tPlayerMJ
		, nRound = self.m_nRound
		, nMaxRound = self.m_tOption.nRound
		, nBankerCharID = self.m_nBankerUser
		, nRemainMJ = #self.m_tTouchMJ
	}
	CmdNet.PBBroadcastExter(self:GetSessionList(), "SendMJRet", tMsg)

	--翻鬼牌
	self:OpenGhost()
	--设置状态
	self.m_nState = self.tState.eStart

	--切换用户
	self:SwitchPlayer(self.m_nBankerUser)
	self:MarkDirty(true)
end

--可操作事件
function CGDMJRoomBase:OnSendOperation(nCharID)
	--子类有需要就实现
end

--发送可操作通知
function CGDMJRoomBase:SendOperation(nCharID)
	print("CGDMJRoomBase:SendOperation***", nCharID)
	CmdNet.PBSrv2Clt(self:GetSession(nCharID), "OperationRet", {})

	self:OnSendOperation(nCharID)
end

--生成玩家牌信息
function CGDMJRoomBase:GenPlayerMJMsg(tPlayer, bProtect)
	local tMsg = 
	{
		nCharID = tPlayer.nCharID
		, tHandMJ = nil
		, tOutMJ = tPlayer.tOutMJ
		, tBlock = {}
	}
	if bProtect then
		tMsg.tHandMJ={}
		for k, v in ipairs(tPlayer.tHandMJ) do
			if v > 0 then
				tMsg.tHandMJ[k] = 0xFF
			else
				tMsg.tHandMJ[k] = 0
			end
		end
	else
		tMsg.tHandMJ = tPlayer.tHandMJ
	end
	for _, oBlock in ipairs(tPlayer.oHu.tBlock) do
		if oBlock.nStyle ~= tGDMJConf.tBlockStyle.eNone then
			table.insert(tMsg.tBlock, {nFirstMJ=oBlock.nFirst, nBlockStyle=oBlock.nStyle})
		end
	end
	return tMsg
end

--麻将类型
function CGDMJRoomBase:GetMJType(nMJ)
	return nMJ & tGDMJConf.tEtc.nMJMaskType
end

--麻将值
function CGDMJRoomBase:GetMJValue(nMJ)
	return nMJ & tGDMJConf.tEtc.nMJMaskValue
end

--是否可以做将牌
function CGDMJRoomBase:IsJiang(nMJ1, nMJ2)
	return nMJ1 == nMJ2
end

--九莲灯
function CGDMJRoomBase:IsNineLight(tHandMJ, nMJ)
	local nType = self:GetMJType(nMJ)
	for i = 1, nMaxHandMJ - 1 do
		if self:GetMJType(tHandMJ[i]) ~= nType then
			return
		end
		if self:GetMJValue(tHandMJ[i]) ~= tGDMJConf.tNineLight[i] then
			return
		end
	end
	return true
end

--十三幺
function CGDMJRoomBase:IsThirteenOne(tTmpMJ, tGhost)
	if not self.m_tOption.bShiSanYao then
		return
	end
	local tGhostCopy = table.DeepCopy(tGhost)
	local nJiangGhost = math.min(#tGhostCopy, 2)
	local function _check()
		local k, n = 1, 0
		while k <= 13 do
			if tTmpMJ[k] ~= tGDMJConf.tThirteen[k] then
				if #tGhostCopy > 0 then
					table.remove(tGhostCopy)
				else
					break
				end
			else
				k = k + 1
			end
			n = n + 1
			if n == 13 then
				return true
			end
		end
	end
	for i = 0, nJiangGhost do
		if i == 0 then
			for j = 1, nMaxHandMJ - #tGhost - 1 do
				if self:IsJiang(tTmpMJ[j], tTmpMJ[j+1]) then
					local nMJ = tTmpMJ[j]
					table.remove(tTmpMJ, j)
					if not _check() then
						table.insert(tTmpMJ, j, nMJ)
					else
						return true
					end
				end
			end

		elseif i == 1 then
			local nGhostMJ = tGhostCopy[#tGhostCopy]
			table.remove(tGhostCopy)
			if _check() then
				return true
			else
				table.insert(tGhostCopy, nGhostMJ)
			end

		elseif i == 2 then
			table.remove(tGhostCopy)
			table.remove(tGhostCopy)
			if _check() then
				return true
			end
		end
	end
end

--七对子
function CGDMJRoomBase:IsSevenPairs(tTmpMJ, tGhost)
	if not self.m_tOption.bQiDui then
		return
	end
	local n = 0
	local tGhostCopy = table.DeepCopy(tGhost)
	for i = 1, nMaxHandMJ - 1, 2 do
		if not tTmpMJ[i] and not tTmpMJ[i+1] then
			if #tGhostCopy >= 2 then
				table.remove(tGhostCopy)
				table.remove(tGhostCopy)
			else
				return 
			end
		elseif tTmpMJ[i] ~= tTmpMJ[i+1] then
			if #tGhostCopy > 0 then
				table.remove(tGhostCopy)
			else
				return
			end
		end
		n = n + 1
		if n == 7 then
			return true
		end
	end
end

--4鬼胡牌
function CGDMJRoomBase:IsFourGhostHu(tTmpMJ, tGhost)
	if not self.m_tOption.bSiGui then
		return
	end
	if #tGhost >= 4 then
		return true
	end
end

--特殊胡牌
function CGDMJRoomBase:IsSpecialHu(tTmpMJ, tGhost)
	if self:IsThirteenOne(tTmpMJ, tGhost) then
		return tGDMJConf.tHuType.eThirteen
	elseif self:IsSevenPairs(tTmpMJ, tGhost) then
		return tGDMJConf.tHuType.eSevenPair
	elseif self:IsFourGhostHu(tTmpMJ, tGhost) then
		return tGDMJConf.tHuType.eFourGhost
	end
end

--清除胡牌数据
function CGDMJRoomBase:CleanHu(oHu)
	oHu.tBlock = {}
	oHu.nJiangMJ = 0
	oHu.bQiangGang = false
end

--拷贝胡牌数据
function CGDMJRoomBase:CopyHu(oTarHu, oSrcHu)
	oTarHu.nJiangMJ = oSrcHu.nJiangMJ
	oTarHu.bQiangGang = oSrcHu.bQiangGang
	for _, oBlock in ipairs(oSrcHu.tBlock) do
		table.insert(oTarHu.tBlock, table.DeepCopy(oBlock))
	end
end

--类型判断
function CGDMJRoomBase:CheckBlock(nMJ1, nMJ2, nMJ3)
	--排序
	local tMJList = {nMJ1, nMJ2, nMJ3}
	table.sort(tMJList, _AscSort)
	
	--刻子形结构
	if tMJList[1] == tMJList[2] and tMJList[2] == tMJList[3] then
		local oBlock = tGDMJConf:NewMJBlock()
		oBlock.nFirst = tMJList[1]
		oBlock.nStyle = tGDMJConf.tBlockStyle.eKe
		return oBlock
	end

	--顺子结构	
	if tMJList[3] < 0x31 then --不为风，字, 花
		if tMJList[3] == tMJList[2] + 1 and tMJList[2] == tMJList[1] + 1 then
			local oBlock = tGDMJConf:NewMJBlock()
			oBlock.nFirst = tMJList[1]
			oBlock.nStyle = tGDMJConf.tBlockStyle.eSun
			return oBlock
		end
	end
end

--加BLOCK到胡牌结构
function CGDMJRoomBase:AddBlock(oHu, oBlock, bTmp)
	assert(#oHu.tBlock < nMaxBlock, "胡牌结构过多")
	table.insert(oHu.tBlock, oBlock)
	--临时的胡牌结果不保存
	if not bTmp then
		self:MarkDirty(true)
	end
end

--是否暗杠
function CGDMJRoomBase:IsAnGang(tHandMJ, nHandMJ, nIgnMJ1, nIgnMJ2)
	nIgnMJ1 = nIgnMJ1 or 0xFF
	nIgnMJ2 = nIgnMJ2 or 0xFF

	local oGang = tGDMJConf:NewMJGang()
	for i = nMaxHandMJ - nHandMJ + 1, nMaxHandMJ - 3 do
		--跳过指定牌
		if tHandMJ[i] ~= nIgnMJ1 and tHandMJ[i] ~= nIgnMJ2 then
			if tHandMJ[i] == tHandMJ[i+1] and tHandMJ[i] == tHandMJ[i+2] then
				--手上有杠牌
				if tHandMJ[i] == tHandMJ[i+3] then
					oGang.nGangStyle = tGDMJConf.tGangType.eAnGang
					oGang.nGangMJ = tHandMJ[i]

				--刚摸到杠牌
				elseif tHandMJ[i] == tHandMJ[nMaxHandMJ] then
					oGang.nGangStyle = tGDMJConf.tGangType.eAnGang
					oGang.nGangMJ = tHandMJ[i]

				end
			end
		end
	end
	return oGang
end

--是否放明杠
function CGDMJRoomBase:IsFangGang(tHandMJ, nHandMJ, nMJ)
	--明杠手上不会有第十四张牌
	assert(nHandMJ < nMaxHandMJ)
	local oGang = tGDMJConf:NewMJGang()
	for i = nMaxHandMJ - nHandMJ, nMaxHandMJ - 3 do
		if tHandMJ[i] == nMJ and tHandMJ[i+1] == nMJ and tHandMJ[i+2] == nMJ then
			oGang.nGangStyle = tGDMJConf.tGangType.eNormal
			oGang.nGangMJ = tHandMJ[i]
			return oGang
		end
	end
	return oGang
end

--是否自摸杠(补杠&明杠)
function CGDMJRoomBase:IsZMGang(tHandMJ, nHandMJ, oHu, nIgnMJ1, nIgnMJ2)
	nIgnMJ1 = nIgnMJ1 or 0xFF
	nIgnMJ2 = nIgnMJ2 or 0xFF
	local oGang = tGDMJConf:NewMJGang()
	for _, oBlock in ipairs(oHu.tBlock) do
		--跳过多个补杠
		if oBlock.nStyle == tGDMJConf.tBlockStyle.ePeng then
			if oBlock.nFirst ~= nIgnMJ1 and oBlock.nFirst ~= nIgnMJ2 then
				for j = nMaxHandMJ - nHandMJ + 1, nMaxHandMJ do
					if tHandMJ[j] == oBlock.nFirst then
						oGang.nGangMJ = tHandMJ[j] 				--明杠胡牌块位
						oGang.nGangStyle = tGDMJConf.tGangType.eZMGang 	--自摸明杠
						return oGang
					end
				end
			end
		end
	end
	return oGang
end

--是否可以碰牌
function CGDMJRoomBase:IsPeng(tHandMJ, nHandMJ, nMJ)
	--不会有14张牌
	assert(nHandMJ < nMaxHandMJ)
	for i = nMaxHandMJ - nHandMJ, nMaxHandMJ - 2 do
		if tHandMJ[i] == nMJ and tHandMJ[i+1] == nMJ then
			return true
		end
	end
end

--是否可以吃牌
function CGDMJRoomBase:IsChi(tHandMJ, nHandMJ, nMJ)
	--风,字不能吃
	if nMJ > 0x30 then
		return 0
	end
	local nChiType = 0 --吃牌信息, 0-无吃牌,1-**@型, 2-*@*, 4-@**型
	local nPos, nIgnMJ1, nIgnMJ2 = true, true, true
	--不会有14张牌
	for i = nMaxHandMJ-nHandMJ, nMaxHandMJ-1 do
		--**@
		if tHandMJ[i] == nMJ - 2 and nIgnMJ2 then
			for j=i, nMaxHandMJ-1 do
				if tHandMJ[j] == nMJ-1 then
					nChiType = nChiType + 1 --吃牌类型1
					break
				end
			end
			nIgnMJ2 = false
		--*@*
		elseif tHandMJ[i] == nMJ-1 and nIgnMJ1 then
			for j=i, nMaxHandMJ-1 do
				if tHandMJ[j] == nMJ+1 then
					nChiType = nChiType + 2 --吃牌类型2
					break
				end
			end
			nIgnMJ1 = false
		--@**
		elseif tHandMJ[i] == nMJ+1 and nPos then
			for j=i, nMaxHandMJ-1 do
				if tHandMJ[j] == tMJ+2 then
					nChiType = nChiType + 4 --吃牌类型2
					break
				end
			end
			nPos = false
		end
	end
	return nChiType
end

--nZeroPos位置必须为0，用于存放第14张牌
function CGDMJRoomBase:MakeTouchZero(tHandMJ, nZeroPos)
	assert(tHandMJ[nZeroPos] == 0, "位置错误")
	tHandMJ[nZeroPos] = tHandMJ[nMaxHandMJ]
	table.remove(tHandMJ)
	self:SortGhost(tHandMJ)
	tHandMJ[nMaxHandMJ] = 0

	self:MarkDirty(true)
end

--碰操作
function CGDMJRoomBase:Peng(nCharID, nTarget)
	local tPlayer = self:GetPlayer(nCharID)
	local tHandMJ = tPlayer.tHandMJ
	local nHandMJ = tPlayer.nHandMJ
	local nOutMJ = self.m_nOutMJ
	local oHu = tPlayer.oHu	

	--不会有14张牌
	assert(tHandMJ[nMaxHandMJ] == 0)
	for i = nMaxHandMJ - nHandMJ, nMaxHandMJ - 2 do
		if tHandMJ[i] == nOutMJ then
			tHandMJ[i] = 0
			tHandMJ[i+1] = 0
			tPlayer.nHandMJ = nHandMJ - 2
			self:SortGhost(tHandMJ)

			local oBlock = tGDMJConf:NewMJBlock()
			oBlock.nFirst = nOutMJ
			oBlock.nStyle = tGDMJConf.tBlockStyle.ePeng
			oBlock.nStep = tPlayer.nStep
			oBlock.nTarget = nTarget
			self:AddBlock(oHu, oBlock)
			self:MarkDirty(true)
			return oBlock
		end
	end
end

--放明杠
function CGDMJRoomBase:FangGang(nCharID, nTarget)
	local tPlayer = self:GetPlayer(nCharID)
	local tHandMJ = tPlayer.tHandMJ
	local nHandMJ = tPlayer.nHandMJ
	local nOutMJ = self.m_nOutMJ
	local oHu = tPlayer.oHu	

	--不会有14张牌
	assert(tHandMJ[nMaxHandMJ] == 0)
	for i = nMaxHandMJ - nHandMJ, nMaxHandMJ - 3 do
		if tHandMJ[i] == nOutMJ then
			tHandMJ[i] = 0
			tHandMJ[i+1] = 0
			tHandMJ[i+2] = 0
			tPlayer.nHandMJ = nHandMJ - 3
			self:MakeTouchZero(tHandMJ, i)

			local oBlock = tGDMJConf:NewMJBlock()
			oBlock.nFirst = nOutMJ
			oBlock.nStyle = tGDMJConf.tBlockStyle.eGang
			oBlock.nStep = tPlayer.nStep
			oBlock.nTarget = nTarget
			self:AddBlock(oHu, oBlock)
			self:MarkDirty(true)
			return oBlock
		end
	end
end

--自摸明杠&补杠
function CGDMJRoomBase:ZMGang(nCharID, nSelectMJ)
	local tPlayer = self.m_tPlayerMap[nCharID]
	local tHandMJ = tPlayer.tHandMJ
	local nHandMJ = tPlayer.nHandMJ
	local oHu = tPlayer.oHu	

	for _, oBlock in ipairs(oHu.tBlock) do
		if oBlock.nStyle == tGDMJConf.tBlockStyle.ePeng then
			local nTarPos
			if nSelectMJ then
				if oBlock.nFirst == nSelectMJ then
					for i = nMaxHandMJ - nHandMJ + 1, nMaxHandMJ do
						if tHandMJ[i] == nSelectMJ then
							nTarPos = i
							break
						end
					end
				end
			else
				for i = nMaxHandMJ - nHandMJ + 1, nMaxHandMJ do
					if oBlock.nFirst == tHandMJ[i] then
						nTarPos = i
						break
					end
				end
			end
			if nTarPos then
				tHandMJ[nTarPos] = 0
				self:MakeTouchZero(tHandMJ, nTarPos)
				oBlock.nStyle = tGDMJConf.tBlockStyle.eZMGang
				oBlock.nStep = tPlayer.nStep
				oBlock.nTarget = nCharID
				tPlayer.nHandMJ = nHandMJ - 1
				self:MarkDirty(true)
				return oBlock
			end
		end
	end
end

--暗杠
function CGDMJRoomBase:AnGang(nCharID, nSelectMJ)
	local tPlayer = self.m_tPlayerMap[nCharID]
	local tHandMJ = tPlayer.tHandMJ
	local nHandMJ = tPlayer.nHandMJ
	local oHu = tPlayer.oHu
	local nGangMJ = nSelectMJ

	local nZeroPos = 0
	for i = nMaxHandMJ - nHandMJ + 1, nMaxHandMJ do
		if nSelectMJ then
			if tHandMJ[i] == nSelectMJ then
				nZeroPos = i
				tHandMJ[i] = 0
			end
		elseif i <= nMaxHandMJ - 3 then
			if tHandMJ[i] == tHandMJ[i+1] and tHandMJ[i] == tHandMJ[i+2] then
				if tHandMJ[i] == tHandMJ[i+3] then
					nZeroPos = i
					nGangMJ = tHandMJ[i]
					for k = i, i + 3 do tHandMJ[k] = 0 end
					break
				elseif tHandMJ[i] == tHandMJ[nMaxHandMJ] then
					nZeroPos = i
					nGangMJ = tHandMJ[i]
					for k = i, i + 2 do tHandMJ[k] = 0 end
					tHandMJ[nMaxHandMJ] = 0
					break
				end
			end
		end
	end
	assert(nZeroPos > 0, "暗杠出错")
	tPlayer.nHandMJ = nHandMJ - 4
	self:MakeTouchZero(tHandMJ, nZeroPos)

	local oBlock = tGDMJConf:NewMJGang()
	oBlock.nStyle = tGDMJConf.tBlockStyle.eAnGang
	oBlock.nFirst = nGangMJ
	oBlock.nStep = tPlayer.nStep
	oBlock.nTarget = nCharID
	self:AddBlock(oHu, oBlock)
	self:MarkDirty(true)
	return oBlock
end

--吃牌操作
function CGDMJRoomBase:Chi(nCharID, nChiType, nTarget)
	local tPlayer = self.m_tPlayerMap[nCharID]
	local tHandMJ = tPlayer.tHandMJ
	local nHandMJ = tPlayer.nHandMJ
	local nOutMJ = self.m_nOutMJ
	local oHu = tPlayer.oHu

	local oBlock = tGDMJConf:NewMJBlock()
	oBlock.nTarget = nTarget
	--@@*
	if nChiType == 1 then
		oBlock.nFirst = nOutMJ - 2
		oBlock.nStyle = tGDMJConf.tBlockStyle.eChi
		--清零麻将
		for i = nMaxHandMJ - nHandMJ, nMaxHandMJ - 1 do
			if tHandMJ[i] == nOutMJ - 2 then
				tHandMJ[i] = 0
				for j = i + 1, nMaxHandMJ - 1 do
					if tHandMJ[j] == nOutMJ - 1 then
						tHandMJ[j] = 0
						return oBlock
					end
				end
				break
			end
		end
	--@*@
	elseif nChiType == 2 then
		oBlock.nFirst = nOutMJ - 1
		oBlock.nStyle = tGDMJConf.tBlockStyle.eChi
		--清零麻将
		for i = nMaxHandMJ - nHandMJ, nMaxHandMJ - 1 do
			if tHandMJ[i] == nOutMJ - 1 then
				tHandMJ[i] = 0
				for j = i + 1, nMaxHandMJ - 1 do
					if tHandMJ[j] == nOutMJ + 1 then
						tHandMJ[j] = 0
						return oBlock
					end
				end
				break
			end
		end
	--*@@
	elseif nChiType == 4 then
		oBlock.nFirst = nOutMJ
		oBlock.nStyle = tGDMJConf.tBlockStyle.eChi
		--清零麻将
		for i = nMaxHandMJ - nHandMJ, nMaxHandMJ - 1 do
			if tHandMJ[i] == nOutMJ + 1 then
				tHandMJ[i] = 0
				for j = i + 1, nMaxHandMJ - 1 do
					if tHandMJ[j] == nOutMJ + 2 then
						tHandMJ[j] = 0
						return oBlock
					end
				end
				break
			end
		end
	end
	assert(oBlock.nStyle ~= tGDMJConf.tBlockStyle.eNone, "判断可以吃，但是吃不了")
	self:MarkDirty(true)
	return oBlock
end

--玩家摸牌
function CGDMJRoomBase:TouchMJ(nCharID)
	assert(self:IsStart(), "游戏状态错误")
	local tPlayer = assert(self:GetPlayer(nCharID))

	--流局
	if #self.m_tTouchMJ == 0 then
		self:OnRoundEnd()
		return
	end

	--摸牌
	local nTouchMJ = self.m_tTouchMJ[#self.m_tTouchMJ]
	table.remove(self.m_tTouchMJ)

	--加入手牌
	tPlayer.tHandMJ[nMaxHandMJ] = nTouchMJ
	tPlayer.nHandMJ = tPlayer.nHandMJ + 1
	tPlayer.nStep = tPlayer.nStep + 1
	
	--胡、杠牌判断
	local nHu = self:IsHu(tPlayer.tHandMJ, tPlayer.nHandMJ-1, nTouchMJ, tPlayer.oHu)
	local nGang = self:IsAnGang(tPlayer.tHandMJ, tPlayer.nHandMJ).nGangStyle
		+ self:IsZMGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tPlayer.oHu).nGangStyle

	if nHu > 0 then
		tPlayer.nActionRight = tGDMJConf.tMJAction.eHu
	elseif nGang > 0  then
		tPlayer.nActionRight = tGDMJConf.tMJAction.eGang
	end

	--发送数据
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		local tMsg = {nCharID=nCharID, nTouchMJ=0xFF, nRemainMJ=#self.m_tTouchMJ}
		if nCharID == nTmpCharID then
			tMsg.nHu = nHu
			tMsg.nGang = nGang
			tMsg.nTouchMJ = nTouchMJ
			if nHu > 0 or nGang > 0 then
				self:OnSendOperation(nTmpCharID)
			end
		end
		CmdNet.PBSrv2Clt(self:GetSession(nTmpCharID), "TouchMJRet", tMsg)
	end

	--切换玩家
	self:SwitchPlayer(nCharID)
	self:MarkDirty(true)
end

--用户出牌
function CGDMJRoomBase:OnUserOutMJ(oPlayer, nOutMJ)
	assert(nOutMJ > 0)
	local nCharID = oPlayer:GetCharID()
	local tPlayer = assert(self:GetPlayer(nCharID))

	--校验状态
	assert(self:IsStart(), "游戏状态错误")
	assert(self.m_nCurrentUser == nCharID, "没到玩家出牌")
	assert(tPlayer.tHandMJ[nMaxHandMJ] > 0, "不能重复出牌")

	--出牌
	self.m_nOutMJ = nOutMJ
	table.insert(tPlayer.tOutMJ, self.m_nOutMJ)

	--取消操作权
	tPlayer.nActionRight = 0
	--增加步数
	tPlayer.nStep = tPlayer.nStep + 1

	--判断跟庄
	if self.m_tOption.bGenZhuang then
		local tBanker = assert(self:GetPlayer(self.m_nBankerUser))
		if tBanker.nStep == 1 and tPlayer.nStep == 1 then
			if #self.m_tFollowMJ >= 4 then
				tBanker.nFollowScore = tBanker.nFollowScore - 3 * self.m_nBaseScore
				for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
					if nTmpCharID ~= self.m_nBankerUser then
						tTmpPlayer.nFollowScore = tTmpPlayer.nFollowScore + self.m_nBaseScore
					end
				end
				self.m_tFollowMJ = {}
				CmdNet.PBBroadcastExter(self:GetSessionList(), "FollowMJRet", {nMJ=nOutMJ})
				print("CGDMJRoomBase:OnUserOutMJ**", "跟庄")
			else
				if self.m_nBankerUser == self.m_nCurrentUser then
					self.m_tFollowMJ[1] = self.m_nOutMJ

				elseif self.m_tFollowMJ[1] == self.m_nOutMJ then
					table.insert(self.m_tFollowMJ, self.m_nOutMJ)

				end
			end
		end
	end

	--牌值校验
	for i = 1, nMaxHandMJ do
		if tPlayer.tHandMJ[i] == self.m_nOutMJ then
			--有效删除麻将
			tPlayer.tHandMJ[i] = 0
			tPlayer.nHandMJ = tPlayer.nHandMJ - 1
			self:MakeTouchZero(tPlayer.tHandMJ, i)
			break
		end
	end
	print("OutMJ***", tPlayer.nCharID, tPlayer.nHandMJ)

	local nNextPlayer = 0
	local nMaxActionRight = 0
	local nMaxActionRightCharID = 0
	local nCurrFengWei = tPlayer.nFengWei

	for i = nCurrFengWei, nCurrFengWei + tGDMJConf.tEtc.nMaxPlayer - 1 do
		local nFengWei = i % tGDMJConf.tEtc.nMaxPlayer
		if nFengWei == 0 then
			nFengWei = tGDMJConf.tEtc.nMaxPlayer
		end
		local nTmpCharID = self.m_tFengWei[nFengWei]
		local tTmpPlayer = self.m_tPlayerMap[nTmpCharID]
		--不发送自己的信息
		local nGang, bPeng
		if nTmpCharID ~= self.m_nCurrentUser then
			bPeng = self:IsPeng(tTmpPlayer.tHandMJ, tTmpPlayer.nHandMJ, self.m_nOutMJ)
			nGang = self:IsFangGang(tTmpPlayer.tHandMJ, tTmpPlayer.nHandMJ, self.m_nOutMJ).nGangStyle
			--下家
			if nFengWei == nCurrFengWei % tGDMJConf.tEtc.nMaxPlayer + 1 then
				nNextPlayer = nTmpCharID
			end
			--操作权限
			if nGang > 0 then
				tTmpPlayer.nActionRight = tGDMJConf.tMJAction.eGang
			elseif bPeng then
				tTmpPlayer.nActionRight = tGDMJConf.tMJAction.ePeng
			end
			--筛选最大权限
			if tTmpPlayer.nActionRight > nMaxActionRight then
				nMaxActionRight = tTmpPlayer.nActionRight
				nMaxActionRightCharID = nTmpCharID
			end
		end
		local tMsg = {nCharID=nCharID, nOutMJ=nOutMJ, nGang=nGang, bPeng=bPeng}
		CmdNet.PBSrv2Clt(self:GetSession(nTmpCharID), "OutMJRet", tMsg)
	end

	--无人有操作,下家摸牌
	if nMaxActionRight == 0 then
		self:TouchMJ(nNextPlayer)
	else
	--发送可操作通知
		self:SendOperation(nMaxActionRightCharID)
	end
	self:MarkDirty(true)
end

--自摸放弃事件
function CGDMJRoomBase:OnCurrentUserGiveUp()
	--子类需要时实现
end

--玩家放弃
function CGDMJRoomBase:OnUserGiveUp(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tPlayer = assert(self:GetPlayer(nCharID))
	assert(self:IsStart(), "游戏状态错误")
	if tPlayer.nActionRight <= 0 then
		return
	end
	tPlayer.nActionRight = 0
	if not tPlayer.bRobot and oPlayer == tPlayer.oBindRobot then
		local oRealPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
		CmdNet.PBSrv2Clt(oRealPlayer:GetSession(), "GiveUpRet", {nCharID=nCharID})
	end

	--非当前玩家
	if self.m_nCurrentUser ~= nCharID then
		local nMaxRight = 0
		local nNextPlayer = 0
		local nMaxRightCharID = 0
		local tCurrPlayer = self:GetPlayer(self.m_nCurrentUser)
		local nCurrFengWei = tCurrPlayer.nFengWei

		for i = nCurrFengWei, nCurrFengWei + tGDMJConf.tEtc.nMaxPlayer - 1 do	
			local nFengWei = i % tGDMJConf.tEtc.nMaxPlayer
			if nFengWei == 0 then
				nFengWei = tGDMJConf.tEtc.nMaxPlayer
			end
			local nTmpCharID = self.m_tFengWei[nFengWei]
			local tTmpPlayer = self.m_tPlayerMap[nTmpCharID]
			if nFengWei == nCurrFengWei % tGDMJConf.tEtc.nMaxPlayer + 1 then
				nNextPlayer = nTmpCharID
			end
			if tTmpPlayer.nActionRight > nMaxRight then
				nMaxRight = tTmpPlayer.nActionRight
				nMaxRightCharID = nTmpCharID
			end
		end
		--允许下家操作
		if nMaxRight > 0 then
			self:SendOperation(nMaxRightCharID)
		else
		--全部人都放弃操作,下家摸牌
			self:TouchMJ(nNextPlayer)
		end
	else
		self:OnCurrentUserGiveUp()
	end
	self:MarkDirty(true)
end

--用户碰牌
function CGDMJRoomBase:OnUserPeng(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tPlayer = assert(self:GetPlayer(nCharID))
	assert(self:IsStart(), "游戏状态错误")
	assert(tPlayer.nActionRight >= tGDMJConf.tMJAction.ePeng, "权限不足")

	--无碰操作权限以上的操作
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		--跳过自已,和出牌者
		if nTmpCharID ~= nCharID and nTmpCharID ~= self.m_nCurrentUser then
			if tTmpPlayer.nActionRight <= tGDMJConf.tMJAction.ePeng then
				tTmpPlayer.nActionRight = 0
			else
				assert(false, "有更高优先级的玩家:", nTmpCharID, tTmpPlayer.nActionRight)
			end
		end
	end

	tPlayer.nActionRight = 0
	tPlayer.nStep = tPlayer.nStep + 1
	--处理碰
	local oBlock = assert(self:Peng(nCharID, self.m_nCurrentUser))
	--发送消息
	local tMsg = 
	{
		nFirstMJ = oBlock.nFirst
		, nBlockStyle = oBlock.nStyle
		, nActionPlayer = nCharID
		, nOutMJPlayer = self.m_nCurrentUser
	}
	CmdNet.PBBroadcastExter(self:GetSessionList(), "PengRet", tMsg)

	--移除所出牌
	local tCurrPlayer = self:GetPlayer(self.m_nCurrentUser)
	table.remove(tCurrPlayer.tOutMJ)

	--切换玩家
	self:SwitchPlayer(nCharID)
	self:MarkDirty(true)
end

--自摸杠成功
function CGDMJRoomBase:AfterZMGang(tPlayer, oBlock)
	--发送杠牌消息
	local tMsg =
	{
		nFirstMJ = oBlock.nFirst
		, nBlockStyle = oBlock.nStyle
		, nGangType = tGDMJConf.tGangType.eZMGang
		, nActionPlayer = tPlayer.nCharID
		, nOutMJPlayer = self.m_nCurrentUser
	}
	CmdNet.PBBroadcastExter(self:GetSessionList(), "GangRet", tMsg)

	--算分
	tPlayer.nGangScore = tPlayer.nGangScore + 3 * self.m_nBaseScore
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		if nTmpCharID ~= nCharID then
			tTmpPlayer.nGangScore = tTmpPlayer.nGangScore - self.m_nBaseScore
		end
	end

	--抢杠胡判断
	if self.m_tOption.bQiangGang and self:QiangGangCheck(oBlock.nFirst) then
		--已发送抢杠胡提示
	else
		--杠牌者摸牌
		self:TouchMJ(tPlayer.nCharID)
	end
end

--暗杠成功
function CGDMJRoomBase:AfterAnGang(tPlayer, oBlock)
	--发送杠牌消息
	local tMsg =
	{
		nFirstMJ = oBlock.nFirst
		, nBlockStyle = oBlock.nStyle
		, nGangType = tGDMJConf.tGangType.eAnGang
		, nActionPlayer = tPlayer.nCharID
		, nOutMJPlayer = self.m_nCurrentUser
	}
	CmdNet.PBBroadcastExter(self:GetSessionList(), "GangRet", tMsg)

	--算分
	tPlayer.nGangScore = tPlayer.nGangScore + 3 * 2 * self.m_nBaseScore 
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		if nTmpCharID ~= nCharID then
			tTmpPlayer.nGangScore = tTmpPlayer.nGangScore - 2 * self.m_nBaseScore
		end
	end

	--杠牌者摸牌
	self:TouchMJ(tPlayer.nCharID)
end

--杠牌操作
function CGDMJRoomBase:OnUserGang(oPlayer, nGangType)
	local nCharID = oPlayer:GetCharID()
	print("CGDMJRoomBase:OnUserGang***", nCharID)
	local tPlayer = assert(self:GetPlayer(nCharID))
	assert(self:IsStart(), "游戏状态错误")
	assert(tPlayer.nActionRight >= tGDMJConf.tMJAction.eGang, "权限不足")

	--无杠操作权限以上的操作
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		--跳过自已,和出牌者
		if nTmpCharID ~= nCharID and nTmpCharID ~= self.m_nCurrentUser then
			assert(tTmpPlayer.nActionRight <= tGDMJConf.tMJAction.eGang, "有更高优先级的玩家:", nTmpCharID, tTmpPlayer.nActionRight)
			tTmpPlayer.nActionRight = 0
		end
	end

	if nGangType == tGDMJConf.tGangType.eNormal then
	--普通杠
		tPlayer.nActionRight = 0
		tPlayer.nStep = tPlayer.nStep + 1
		local oBlock = assert(self:FangGang(nCharID, self.m_nCurrentUser))

		--发送杠牌消息
		local tMsg =
		{
			nFirstMJ = oBlock.nFirst
			, nBlockStyle = oBlock.nStyle
			, nGangType = tGDMJConf.tGangType.eNormal
			, nActionPlayer = nCharID
			, nOutMJPlayer = self.m_nCurrentUser
		}
		CmdNet.PBBroadcastExter(self:GetSessionList(), "GangRet", tMsg)

		--移除所出牌
		local tCurrPlayer = self:GetPlayer(self.m_nCurrentUser)
		table.remove(tCurrPlayer.tOutMJ)

		--算分
		local nScore = self.m_nBaseScore * 3
		tCurrPlayer.nGangScore = tCurrPlayer.nGangScore - nScore
		tPlayer.nGangScore = tPlayer.nGangScore + nScore

		--杠牌者摸牌
		self:TouchMJ(nCharID)

	elseif nGangType == tGDMJConf.tGangType.eZMGang then
	--自摸杠
		local tGangMJ = {0, 0, 0}
		local oGang1 = self:IsZMGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tPlayer.oHu)
		assert(oGang1.nGangMJ > 0, "没有自摸杠")
		tGangMJ[1] = oGang1.nGangMJ

		local oGang2 = self:IsZMGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tPlayer.oHu, tGangMJ[1])
		tGangMJ[2] = oGang2.nGangMJ

		--如果有多个自摸杠,进入杠牌选择模式
		if tGangMJ[2] ~= 0 then
			local oGang3 = self._IsZMGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tPlayer.oHu, tGangMJ[1], tGangMJ[2])
			tGangMJ[3] = oGang3.nGangMJ
			
			local tMsg = {nGangType=tGDMJConf.tGangType.eZMGang, tGangMJ=tGangMJ}
			CmdNet.PBSrv2Clt(self:GetSession(nCharID), "GangSelectRet", tMsg)

		--没有选择,杠处理
		else
			tPlayer.nActionRight = 0
			tPlayer.nStep = tPlayer.nStep + 1
			local oBlock = assert(self:ZMGang(nCharID))
			self:AfterZMGang(tPlayer, oBlock)
		end

	elseif nGangType == tGDMJConf.tGangType.eAnGang then
	--暗杠
		--如果有多个暗杠,进先杠牌选择模式
		local tGangMJ = {0, 0, 0}
		local oGang1 = self:IsAnGang(tPlayer.tHandMJ, tPlayer.nHandMJ)
		assert(oGang1.nGangMJ > 0, "没有暗杠")
		tGangMJ[1] = oGang1.nGangMJ

		local oGang2 = self:IsAnGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tGangMJ[1])
		tGangMJ[2] = oGang2.nGangMJ

		--有多个暗杠,进先杠牌选择模式
		if tGangMJ[2] ~= 0 then
			local oGang3 = self:IsAnGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tGangMJ[1], tGangMJ[2])
			tGangMJ[3] = oGang3.nGangMJ

			local tMsg = {nGangType=tGDMJConf.tGangType.eAnGang, tGangMJ=tGangMJ}
			CmdNet.PBSrv2Clt(self:GetSession(nCharID), "GangSelectRet", tMsg)

		else
			tPlayer.nActionRight = 0
			tPlayer.nStep = tPlayer.nStep + 1
			local oBlock = assert(self:AnGang(nCharID))
			self:AfterAnGang(tPlayer, oBlock)
		end

	elseif nGangType == tGDMJConf.tGangType.eZMGang + tGDMJConf.tGangType.eAnGang then
	--有自摸杠也有暗杠,进行杠牌选择
		local tGangMJ = {0, 0, 0}
		local oGang1 = self:IsAnGang(tPlayer.tHandMJ, tPlayer.nHandMJ)
		assert(oGang1.nGangMJ > 0, "没有暗杠")
		tGangMJ[1] = oGang1.nGangMJ

		local oGang2 = self:IsZMGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tPlayer.oHu)
		assert(oGang2.nGangMJ > 0, "没有自摸杠")
		tGangMJ[2] = oGang2.nGangMJ

		--有多个暗杠或补杠,进先杠牌选择模式
		local nGangType = tGDMJConf.tGangType.eZMGang
		local oGang3 = self:IsAnGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tGangMJ[1])
		if oGang3.nGangMJ > 0 then
			tGangMJ[2] = oGang3.nGangMJ
			nGangType = tGDMJConf.tGangType.eAnGang
		else
			oGang3 = self:IsZMGang(tPlayer.tHandMJ, tPlayer.nHandMJ, tPlayer.oHu, tGangMJ[2])
			if oGang3.nGangMJ > 0 then
				tGangMJ[1] = oGang3.nGangMJ
				nGangType = tGDMJConf.tGangType.eZMGang
			else
				tGangMJ[2] = 0
				nGangType = tGDMJConf.tGangType.eAnGang
			end
		end

		local tMsg = {nGangType=nGangType, tGangMJ=tGangMJ}
		CmdNet.PBSrv2Clt(self:GetSession(nCharID), "GangSelectRet", tMsg)
	end
	self:MarkDirty(true)
end

--抢杠胡判断(摸明杠/补杠)
function CGDMJRoomBase:QiangGangCheck(nGangMJ)
	for nCharID, tPlayer in pairs(self.m_tPlayerMap) do
		--杠牌者必定是当前玩家
		if nCharID ~= self.m_nCurrentUser then
			assert(tPlayer.tHandMJ[nMaxHandMJ] == 0)
			local nHu = self:IsHu(tPlayer.tHandMJ, tPlayer.nHandMJ, nGangMJ, tPlayer.oHu)
			if nHu > 0 then
				tPlayer.nActionRight = tGDMJConf.tMJAction.eHu	
				CmdNet.PBSrv2Clt(self:GetSession(nCharID), "QiangGangRet", {nQiangGangMJ = nGangMJ})
				self:OnSendOperation(nCharID)
				self:MarkDirty(true)
				return true
			end
		end
	end
end

--用户选择杠
function CGDMJRoomBase:OnUserGangSelect(oPlayer, nGangType, nSelectMJ)
	local nCharID = oPlayer:GetCharID()
	local tPlayer = assert(self:GetPlayer(nCharID))

	if nGangType == tGDMJConf.tGangType.eZMGang then
	--自摸杠
		tPlayer.nActionRight = 0
		tPlayer.nStep = tPlayer.nStep + 1
		local oBlock = assert(self:ZMGang(nCharID, nSelectMJ))
		self:AfterZMGang(tPlayer, oBlock)

	elseif nGangType == tGDMJConf.tGangType.eAnGang then
	--暗杠
		tPlayer.nActionRight = 0
		tPlayer.nStep = tPlayer.nStep + 1
		local oBlock = assert(self:AnGang(nCharID, nSelectMJ))
		self:AfterAnGang(tPlayer, oBlock)

	else
		assert(false, "不支持杠类型:"..nGangType)
	end
	self:MarkDirty(true)
end

--用户胡牌
function CGDMJRoomBase:OnUserHu(oPlayer, nQiangGangMJ)
	local nCharID = oPlayer:GetCharID()
	assert(self:IsStart(), "游戏状态错误")
	local tPlayer = assert(self:GetPlayer(nCharID))
	assert(tPlayer.nActionRight >= tGDMJConf.tMJAction.eHu, "权限不足")
	--增加步数
	tPlayer.nStep = tPlayer.nStep + 1
	--抢杠胡牌
	if nQiangGangMJ > 0 then
		assert(tPlayer.tHandMJ[nMaxHandMJ] == 0, "摸牌区应该是0")
		tPlayer.tHandMJ[nMaxHandMJ] = nQiangGangMJ
		tPlayer.oHu.bQiangGang = true

		--把被抢杠的玩家的杠恢复成碰
		local tCurrPlayer = self:GetPlayer(self.m_nCurrentUser)
		for _, oBlock in ipairs(tCurrPlayer.oHu.tBlock) do
			if oBlock.nStyle == tGDMJConf.tBlockStyle.eZMGang and oBlock.nFirst == nQiangGangMJ then
				oBlock.nStyle = tGDMJConf.tBlockStyle.ePeng
				break
			end
		end
	end
	--清除权限
	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		tTmpPlayer.nActionRight = 0
	end
	self:MarkDirty(true)
	--发送信息
	local tMsg = 
	{
		nQiangGangMJ=nQiangGangMJ
		, nQiangGangTar=nQiangGangMJ>0 and self.m_nCurrentUser or 0
	}
	CmdNet.PBBroadcastExter(self:GetSessionList(), "HuRet", tMsg)
	return self:OnRoundEnd(nCharID)
end

--取赢家风位对应的马
function CGDMJRoomBase:GetMaMap(nCharID)
	local tPlayer = assert(self:GetPlayer(nCharID))
	local tBanker = assert(self:GetPlayer(self.m_nBankerUser))
	local nTarPos = 1
	for i = tBanker.nFengWei, tBanker.nFengWei + tGDMJConf.tEtc.nMaxPlayer - 1 do
		local nFengWei = i % tGDMJConf.tEtc.nMaxPlayer
		if nFengWei == 0 then
			nFengWei = tGDMJConf.tEtc.nMaxPlayer
		end
		if self.m_tFengWei[nFengWei] ~= nCharID then
			nTarPos = nTarPos + 1
		end
	end
	return tGDMJConf.tMaMap[nTarPos]
end


--分析胡牌类型,返回番数等
function CGDMJRoomBase:CheckHuType(nCharID, nHuType, oTmpHu)
	local tPlayer = self:GetPlayer(nCharID)
	--十三幺8倍
	if self.m_tOption.bShiSanYao then
		if nHuType == tGDMJConf.tHuType.eThirteen then
			return 8, "十三幺"
		end
	end

	local nJiangMJ = oTmpHu and oTmpHu.nJiangMJ
	if nHuType == tGDMJConf.tHuType.eNormal then
		assert(nJiangMJ and nJiangMJ > 0)
		--全风8倍
		if self.m_tOption.bQuanFeng then
			if self:GetMJType(nJiangMJ) == 0x30 or table.InArray(nJiangMJ, self.m_tGhostList) then
				local bRes = true
				for _, oBlock in ipairs(tPlayer.oHu.tBlock) do
					local nMJ = oBlock.nFirst	
					if self:GetMJType(nMJ) ~= 0x30 and not table.InArray(nMJ, self.m_tGhostList) then
						bRes = false
						break
					end
				end
				if bRes then
					for i = nMaxHandMJ - tPlayer.nHandMJ + 1, nMaxHandMJ do
						local nMJ = tPlayer.tHandMJ[i]
						if self:GetMJType(nMJ) ~= 0x30 and not table.InArray(nMJ, self.m_tGhostList) then
							bRes = false
							break
						end
					end
				end
				if bRes then
					return 8, "全风"
				end
			end
		end
		--幺九6倍
		if self.m_tOption.bYaoJiu then
			local tMJList = {0x01, 0x09, 0x11, 0x19, 0x21, 0x29, 0x31, 0x32, 0x33, 0x34, 0x41, 0x42, 0x43}
			if table.InArray(nJiangMJ, self.m_tGhostList) or table.InArray(nJiangMJ, tMJList) then
				for _, oBlock in ipairs(tPlayer.oHu.tBlock) do
					local nMJ = oBlock.nFirst	
					if not table.InArray(nMJ, self.m_tGhostList) and not table.InArray(nMJ, tMJList) then
						bRes = false
						break
					end
				end
				if bRes then
					for i = nMaxHandMJ - tPlayer.nHandMJ + 1, nMaxHandMJ do
						local nMJ = tPlayer.tHandMJ[i]
						if not table.InArray(nMJ, self.m_tGhostList) and not table.InArray(nMJ, tMJList) then
							bRes = false
							break
						end
					end
				end
				if bRes then
					return 6, "幺九"
				end
			end
		end
	end

	--7对4倍
	if self.m_tOption.bQiDuiHu then
		if nHuType == tGDMJConf.tHuType.eSevenPair then
			return 4, "7对"
		end
	end

	if nHuType == tGDMJConf.tHuType.eNormal then
		assert(nJiangMJ and nJiangMJ > 0)
		--清一色4倍
		if self.m_tOption.bQingYiSe then
			local nJangType = self:GetMJType(nJiangMJ)
			local bJiangGhost = table.InArray(nJiangMJ, self.m_tGhostList)
			if bJiangGhost or nJangType <= 0x20 then
				local bRes = true
				local nType = bJiangGhost and 0 or nJangType
				for _, oBlock in ipairs(tPlayer.oHu.tBlock) do
					local nMJ = oBlock.nFirst	
					if table.InArray(nMJ, self.m_tGhostList) then
					else
						local nTmpType = self:GetMJType(nMJ)
						if nType == 0 then
							nType = nTmpType
						elseif nType ~= nTmpType then
							bRes = false
							break
						end
					end
				end

				if bRes then
					for i = nMaxHandMJ - tPlayer.nHandMJ + 1, nMaxHandMJ do
						local nMJ = tPlayer.tHandMJ[i]
						if table.InArray(nMJ, self.m_tGhostList) then
						else
							local nTmpType = self:GetMJType(nMJ)
							if nType == 0 then
								nType = nTmpType
							elseif nType ~= nTmpType then
								bRes = false
								break
							end
						end
					end
				end
				if bRes then
					return 4, "清一色"
				end
			end
		end

		--碰碰胡2倍
		if self.m_tOption.bPengPeng then
			local nPengCount = 0
			for _, oBlock in ipairs(oTmpHu.tBlock) do
				if oBlock.nStyle == tGDMJConf.tBlockStyle.ePeng then
					nPengCount = nPengCount + 1
					if nPengCount >= 4 then
						return 2, "碰碰胡"
					end
				end
			end
		end
	end

	--4鬼胡牌2倍
	if self.m_tOption.bSiGui then
		if nHuType == tGDMJConf.tHuType.eFourGhost then
			return self.m_tOption.bSiGuiDouble and 2 or 1, "4鬼胡牌"
		end
	end

	return 1, "自摸"
end

--返回无鬼胡倍数
function CGDMJRoomBase:CheckWuGui(nCharID)
	if #(self.m_tGhostList or {}) <= 0 then
		return 1
	end
	if not self.m_tOption.bGhostDouble then
		return 1
	end
	local tPlayer = assert(self:GetPlayer(nCharID))
	for _, nMJ in pairs(tPlayer.tHandMJ) do
		if nMJ > 0 and table.InArray(nMJ, self.m_tGhostList) then
			return 1
		end
	end
	for _, oBlock in ipairs(tPlayer.tBlock) do
		if table.InArray(oBlock.nFirst, self.m_tGhostList) then
			return 1
		end
	end
	return 2
end

--返回杠上开花倍数和点杠人
function CGDMJRoomBase:CheckGangShang(nCharID, oTmpHu)
	local tPlayer = self:GetPlayer(nCharID)
	for _, oBlock in ipairs(oTmpHu.tBlock) do
		if oBlock.nStyle == tGDMJConf.tBlockStyle.eGang or oBlock.nStyle == tGDMJConf.tBlockStyle.eAnGang or oBlock.nStyle == tGDMJConf.tBlockStyle.eZMGang then
			if oBlock.nStep + 2 == tPlayer.nStep then
				local nTarCharID = oBlock.nStyle == tGDMJConf.tBlockStyle.eGang and oBlock.nTarget or nil
				return true, (self.m_tOption.bGangShangDouble and 2 or 1), nTarCharID
			end
		end
	end
	return false, 1
end

--返回抢杠倍数和被抢人
function CGDMJRoomBase:CheckQiangGang(nCharID, oTmpHu)
	if oTmpHu.bQiangGang then	
		return true, (oTmpHu.bQiangGangDouble and 2 or 1), self.m_nCurrentUser
	end
	return false, 1
end

--是否只有BLOCK
function CGDMJRoomBase:IsBlockOnly(tTmpMJ, oTmpHu)
	assert(#tTmpMJ >= 3 and #tTmpMJ % 3 == 0, "牌数量不对")
	local j = 1
	while j <= #tTmpMJ - 2 do
		local bHasBlock = false
		local oBlock1 = self:CheckBlock(tTmpMJ[j], tTmpMJ[j+1], tTmpMJ[j+2])
		if oBlock1 then
			self:AddBlock(oTmpHu, oBlock1, true)	
			bHasBlock = true
		elseif j + 5 <= #tTmpMJ then
			--223344 
			local oBlock1 = self:CheckBlock(tTmpMJ[j], tTmpMJ[j+2], tTmpMJ[j+4])
			if oBlock1 then
				local oBlock2 = self:CheckBlock(tTmpMJ[j+1], tTmpMJ[j+3], tTmpMJ[j+5])
				if oBlock2 then
					self:AddBlock(oTmpHu, oBlock1, true)
					self:AddBlock(oTmpHu, oBlock2, true)
					bHasBlock = true
					j = j + 3
				end
			--233334
			else
				local oBlock1 = self:CheckBlock(tTmpMJ[j], tTmpMJ[j+1], tTmpMJ[j+5])
				if oBlock1 then
					local oBlock2 = self:CheckBlock(tTmpMJ[j+2], tTmpMJ[j+3], tTmpMJ[j+4])
					if oBlock2 then
						self:AddBlock(oTmpHu, oBlock1, true)
						self:AddBlock(oTmpHu, oBlock2, true)
						bHasBlock = true
						j = j + 3
					end
				end
			end
		end
		if not bHasBlock then
			return
		end
		j = j + 3
	end
	return true
end

--判断胡(无鬼)
function CGDMJRoomBase:IsHu(tHandMJ, nHandMJ, nMJ, oHu)
	assert(nMJ > 0 and nHandMJ < nMaxHandMJ, "牌面错误,不能是14张")

	--排序牌面,分类
	local tTmpMJ, tTypeMap, tGhost = {}, {}, {}
	local function _make_map(nTmpMJ, bLast)
		local nType = self:GetMJType(nTmpMJ)
		if not tTypeMap[nType] then
			tTypeMap[nType] = {}
		end
		table.insert(tTypeMap[nType], nTmpMJ)
		if bLast then
			table.sort(tTypeMap[nType], _AscSort)
		end
	end
	local function _make_tmp(nTmpMJ, bLast)
		table.insert(tTmpMJ, nTmpMJ)
		if bLast then
			table.sort(tTmpMJ, _AscSort)
		end
	end
	for i = nMaxHandMJ - nHandMJ, nMaxHandMJ - 1 do
		local nTmpMJ = tHandMJ[i]
		if nTmpMJ > 0 then
			if table.InArray(nTmpMJ, self.m_tGhostList) then
				table.insert(tGhost, nTmpMJ)
			else
				assert((tTmpMJ[#tTmpMJ] or 0) <= nTmpMJ)
				_make_tmp(nTmpMJ)
				_make_map(nTmpMJ)
			end
		end
	end
	if table.InArray(nMJ, self.m_tGhostList) then
		table.insert(tGhost, nMJ)
	else
		_make_tmp(nMJ, true)
		_make_map(nMJ, true)
	end

	--特殊胡
	if nHandMJ == nMaxHandMJ - 1 then
		local nSpecialHu = self:IsSpecialHu(tTmpMJ, tGhost)
		if nSpecialHu then
			return nSpecialHu
		end
	end

	local nHu, oTmpHu = tGDMJConf.tHuType.eNone, nil
	if #tGhost == 0 then
		nHu, oTmpHu = self:IsHuNotGhost(tTypeMap, oHu)
	else
		nHu, oTmpHu = self:IsHuHasGhost(tTypeMap, tGhost, oHu)
	end
	print("IsHu***", nHu)
	return nHu, oTmpHu
end

--判断胡(无鬼)
function CGDMJRoomBase:IsHuNotGhost(tTypeMap, oHu)
	print("CGDMJRoomBase:IsHuNotGhost***", tTypeMap)
	--普通胡
	local oTmpHu = tGDMJConf:NewMJHu()
	self:CopyHu(oTmpHu, oHu)
	for nType, tMJList in pairs(tTypeMap) do
		local nMJCount = #tMJList
		if nMJCount < 2 then
			return tGDMJConf.tHuType.eNone

		elseif nMJCount == 2 then
			if not self:IsJiang(tMJList[1], tMJList[2]) then
				return tGDMJConf.tHuType.eNone
			end
			oTmpHu.nJiangMJ = tMJList[1]
			if #oTmpHu.tBlock >= nMaxBlock then
				return tGDMJConf.tHuType.eNormal, oTmpHu
			end

		elseif nMJCount % 3 == 0 then
			if not self:IsBlockOnly(tMJList, oTmpHu) then
				return tGDMJConf.tHuType.eNone
			end
			if #oTmpHu.tBlock >= nMaxBlock and oTmpHu.nJiangMJ > 0 then
				return tGDMJConf.tHuType.eNormal, oTmpHu
			end

		elseif nMJCount % 3 == 2 then
			if oTmpHu.nJiangMJ > 0 then
				return tGDMJConf.tHuType.eNone
			end
			local bBlockOnly = false
			local oTmpHu1 = tGDMJConf:NewMJHu()
			for j = 1, #tMJList - 1 do 
				if self:IsJiang(tMJList[j], tMJList[j+1]) then
					self:CleanHu(oTmpHu1)
					oTmpHu1.nJiangMJ = tMJList[j]
					local tCopyMJ = {}
					for k, nTmpMJ in ipairs(tMJList) do
						if k ~= j and k ~= j + 1 then
							table.insert(tCopyMJ, nTmpMJ)
						end
					end
					if self:IsBlockOnly(tCopyMJ, oTmpHu1) then
						oTmpHu.nJiangMJ = oTmpHu1.nJiangMJ
						for _, oBlock in ipairs(oTmpHu1.tBlock) do
							table.insert(oTmpHu.tBlock, oBlock)
						end
						if #oTmpHu.tBlock >= nMaxBlock and oTmpHu.nJiangMJ > 0 then
							return tGDMJConf.tHuType.eNormal, oTmpHu
						end
						bBlockOnly = true
						break
					end
				end
			end
			if not bBlockOnly then
				return tGDMJConf.tHuType.eNone
			end
		else
			return tGDMJConf.tHuType.eNone
		end
	end
	return tGDMJConf.tHuType.eNone
end

--判断胡(有鬼)
function CGDMJRoomBase:IsHuHasGhost(tTypeMap, tGhost, oHu)
	print("CGDMJRoomBase:IsHuHasGhost***", tTypeMap, tGhost)
	local nCurGhostNum = #tGhost
	if self.m_tOption.bSiGui then
		assert(nCurGhostNum < 4, "4鬼胡牌")
	end

	local nMaxGhost = self.m_tOption.bDoubleGhost and 2*4 or 1*4
	local tWanList = tTypeMap[0x00] or {}
	local tBingList = tTypeMap[0x10] or {}
	local tTiaoList = tTypeMap[0x20] or {}
	local tFengList = tTypeMap[0x30] or {}
	local tZiList = tTypeMap[0x40] or {}

	local nWanToPuNeedNum = self:GetNeedGhostNumToBePu(tWanList, 0, nMaxGhost)
	local nBingToPuNeedNum = self:GetNeedGhostNumToBePu(tBingList, 0, nMaxGhost)
	local nTiaoToPuNeedNum = self:GetNeedGhostNumToBePu(tTiaoList, 0, nMaxGhost)
	for _, nMJ in ipairs(tZiList) do table.insert(tFengList, nMJ) end
	local nFengToPuNeedNum = self:GetNeedGhostNumToBePu(tFengList, 0, nMaxGhost)

	print(string.format("nWanToPuNeedNum:%d nBingToPuNeedNum:%d nTiaoToPuNeedNum:%d nFengToPuNeedNum:%d"
		, nWanToPuNeedNum, nBingToPuNeedNum, nTiaoToPuNeedNum, nFengToPuNeedNum))

	--将在万中
	--如果需要的混小于等于当前的则计算将在将在万中需要的混的个数
	local nNeedGhostNum = nBingToPuNeedNum + nTiaoToPuNeedNum + nFengToPuNeedNum
	if nNeedGhostNum <= nCurGhostNum then
		print(string.format("jiang in wan need:%d cur:%d", nNeedGhostNum, nCurGhostNum))
		local nHasNum = nCurGhostNum - nNeedGhostNum
		local bIsHu, nJiangMJ = self:ListCanHu(tWanList, nHasNum)
		if bIsHu then
			local oTmpHu = tGDMJConf:NewMJHu()
			self:CopyHu(oTmpHu, oHu)
			oTmpHu.nJiangMJ = nJiangMJ
			return tGDMJConf.tHuType.eNormal, oTmpHu
		end
	end
	--将在饼中
	local nNeedGhostNum = nWanToPuNeedNum + nTiaoToPuNeedNum + nFengToPuNeedNum
	if nNeedGhostNum <= nCurGhostNum then
		print(string.format("jiang in bing:%d %d", nNeedGhostNum, nCurGhostNum))
		local nHasNum = nCurGhostNum - nNeedGhostNum
		--不装混牌
		local bIsHu, nJiangMJ = self:ListCanHu(tBingList, nHasNum)
		if bIsHu then
			local oTmpHu = tGDMJConf:NewMJHu()
			self:CopyHu(oTmpHu, oHu)
			oTmpHu.nJiangMJ = nJiangMJ
			return tGDMJConf.tHuType.eNormal, oTmpHu
		end
	end
	--将在条中
	local nNeedGhostNum = nWanToPuNeedNum + nBingToPuNeedNum + nFengToPuNeedNum
	if nNeedGhostNum <= nCurGhostNum then
		print(string.format("jiang in tiao:%d %d", nNeedGhostNum, nCurGhostNum))
		local nHasNum = nCurGhostNum - nNeedGhostNum
		local bIsHu, nJiangMJ = self:ListCanHu(tTiaoList, nHasNum)
		if bIsHu then
			local oTmpHu = tGDMJConf:NewMJHu()
			self:CopyHu(oTmpHu, oHu)
			oTmpHu.nJiangMJ = nJiangMJ
			return tGDMJConf.tHuType.eNormal, oTmpHu
		end
	end
	--将在风中
	local nNeedGhostNum = nWanToPuNeedNum + nBingToPuNeedNum + nTiaoToPuNeedNum
	if nNeedGhostNum <= nCurGhostNum then
		print(string.format("jiang in feng:%d %d", nNeedGhostNum, nCurGhostNum))
		local nHasNum = nCurGhostNum - nNeedGhostNum
		local bIsHu, nJiangMJ = self:ListCanHu(tFengList, nHasNum)
		if bIsHu then
			local oTmpHu = tGDMJConf:NewMJHu()
			self:CopyHu(oTmpHu, oHu)
			oTmpHu.nJiangMJ = nJiangMJ
			return tGDMJConf.tHuType.eNormal, oTmpHu
		end
	end
	return tGDMJConf.tHuType.eNone
end 

function CGDMJRoomBase:ListCanHu(tMJList, nGhostNum)
	if #tMJList <= 0 then
		if nGhostNum >= 2 then
			return true, self.m_tGhostList[1]
		end
		return
	end

	local tCopyMJ = table.DeepCopy(tMJList, true)
	local nMaxGhost = self.m_tOption.bDoubleGhost and 2*4 or 1*4
	local k = 1
	while k <= #tCopyMJ do
		if tCopyMJ[k] == tCopyMJ[k+1] then
			local nMJ = tCopyMJ[k]
			table.remove(tCopyMJ, k)
			table.remove(tCopyMJ, k)
			local nNeedNum = self:GetNeedGhostNumToBePu(tCopyMJ, 0, nMaxGhost)
			if nGhostNum >= nNeedNum then
				return true, nMJ
			end
			table.insert(tCopyMJ, k, nMJ)
			table.insert(tCopyMJ, k, nMJ)
			k = k + 2

		elseif nGhostNum > 0 then
			local nMJ = tCopyMJ[k]
			nGhostNum = nGhostNum - 1	
			table.remove(tCopyMJ, k)
			local nNeedNum = self:GetNeedGhostNumToBePu(tCopyMJ, 0, nMaxGhost)
			if nGhostNum >= nNeedNum then
				return true, nMJ
			end
			nGhostNum = nGhostNum + 1
			table.insert(tCopyMJ, k, nMJ)
			k = k + 1
		else
			k = k + 1
		end
	end
end

--成为整扑需要的癞子个数
function CGDMJRoomBase:GetNeedGhostNumToBePu(tMJList, nNeedNum, nNeedMinNum)
	if nNeedMinNum == 0 then
		return 0
	end

	if nNeedNum >= nNeedMinNum then
		return nNeedMinNum 
	end

	local nSize = #tMJList
	if nSize == 0 then
		return math.min(nNeedNum, nNeedMinNum)

	elseif nSize == 1 then
		return math.min(nNeedNum+2, nNeedMinNum)

	elseif nSize == 2 then
		local nMJ1 = tMJList[1]
		local nMJ2 = tMJList[2]

		--如果后一个是东西南北中发白  不可能是出现顺牌
		local nType2 = self:GetMJType(nMJ2)
		if nType2 == 0x30 or nType2 == 0x40 then
			if nMJ1 == nMJ2 then
				nNeedMinNum = math.min(nNeedMinNum, nNeedNum+1)
			else
				nNeedMinNum = math.min(nNeedMinNum, nNeedNum+4)
			end
		else
			if nMJ2 - nMJ1 < 3 then
				nNeedMinNum = math.min(nNeedMinNum, nNeedNum+1)
			else
				nNeedMinNum = math.min(nNeedMinNum, nNeedNum+4)
			end
		end
		return nNeedMinNum
	end
	--大于等于3张牌
	local nMJ1 = tMJList[1]
	local nMJ2 = tMJList[2]
	local nMJ3 = tMJList[3]

	--第一个自己一扑
	if nNeedNum + 2 < nNeedMinNum then
		table.remove(tMJList, 1)
		nNeedMinNum = self:GetNeedGhostNumToBePu(tMJList, nNeedNum+2, nNeedMinNum)
		table.insert(tMJList, 1, nMJ1)
	end

	--第一个跟其它的一个一扑
	if nNeedNum + 1 < nNeedMinNum then
		--nMJ1是风
		local nType = self:GetMJType(nMJ1)
		if nType == 0x30 or nType == 0x40 then
			if nMJ1 == nMJ2 then
				table.remove(tMJList, 1)
				table.remove(tMJList, 1)
				nNeedMinNum = self:GetNeedGhostNumToBePu(tMJList, nNeedNum+1, nNeedMinNum)
				table.insert(tMJList, 1, nMJ2)
				table.insert(tMJList, 1, nMJ1)
			end
		else
			for i = 2, #tMJList do
				if nNeedNum + 1 >= nNeedMinNum then
					break
				end
				nMJ2 = tMJList[i]
				--455567这里可结合的可能为 45 46 否则是45 45 45 46
				--如果当前的value不等于下一个value则和下一个结合避免重复
				local bEqual = false
				if i + 1 <= #tMJList then
					nMJ3 = tMJList[i+1]
					if nMJ3 == nMJ2 then
						bEqual = true
					end
				end

				if not bEqual then
					if nMJ2 - nMJ1 < 3 then
						table.remove(tMJList, i)
						table.remove(tMJList, 1)
						nNeedMinNum = self:GetNeedGhostNumToBePu(tMJList, nNeedNum+1, nNeedMinNum)
						table.insert(tMJList, 1, nMJ1)
						table.insert(tMJList, i, nMJ2)
					else
						break
					end
				end
			end
		end
	end

	--第一个和其它两个一扑
	--后面间隔两张张不跟前面一张相同222234 
	--可能性为222 234
	for i = 2, #tMJList do
		if nNeedNum >= nNeedMinNum then
			break
		end
		nMJ2 = tMJList[i]
		local bEqual = false
		if i + 2 <= #tMJList then
			if tMJList[i+2] == nMJ2 then
				bEqual = true
			end
		end
		if not bEqual then
			for j = i + 1, #tMJList do
				if nNeedNum >= nNeedMinNum then
					break
				end
				nMJ3 = tMJList[j]
				if nMJ1 == nMJ3 then
					--print("cao!!")
				end
				bEqual = false
				if j + 1 <= #tMJList then
					if nMJ3 == tMJList[j+1] then
						bEqual = true
					end
				end
				if not bEqual then
					if (nMJ1 == nMJ2 and nMJ2 == nMJ3)
						or (nMJ1 + 1 == nMJ2 and nMJ2 + 1 == nMJ3) then
						local tTmpList = {}
						for k, nMJ in ipairs(tMJList) do
							if k ~= 1 and k ~= i and k ~= j then
								table.insert(tTmpList, nMJ)
							end
						end
						nNeedMinNum = self:GetNeedGhostNumToBePu(tTmpList, nNeedNum, nNeedMinNum)
					end
				end
			end
		end
	end
	return nNeedMinNum
end

--恢复牌局
function CGDMJRoomBase:RecoverDesk(oPlayer)
	print("CRoom2:RecoverDesk***")
	local nCharID = oPlayer:GetCharID()
	local tPlayer = assert(self:GetPlayer(nCharID))
	local tMsg =
	{
		nGameState = self.m_nState
		, nRound = self.m_nRound
		, nMaxRound = self.m_tOption.nRound
		, nCurrPlayer = self.m_nCurrentUser
		, nBankerCharID = self.m_nBankerUser
		, nRemainTime = math.max(0, os.time()-self.m_nTurnStartTime)
		, nRemainMJ = #self.m_tTouchMJ
		, tGhostMJ = self.m_tGhostList
		, bAI = tPlayer.bAI --自由房有效
	}
	if self.m_nState == self.tState.eStart then
		--发送信息
		local tPlayerMJ = {}
		for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
			local tMJMsg = self:GenPlayerMJMsg(tTmpPlayer, nTmpCharID~=nCharID)
			if nTmpCharID == nCharID then
				if self.m_nCurrentUser ~= nCharID then
					if tTmpPlayer.nActionRight > 0 then
						tMJMsg.nGang = self:IsFangGang(tTmpPlayer.tHandMJ, tTmpPlayer.nHandMJ, self.m_nOutMJ).nGangStyle
						tMJMsg.bPeng = self:IsPeng(tTmpPlayer.tHandMJ, tTmpPlayer.nHandMJ, self.m_nOutMJ)
						tMJMsg.bShow = self:GetMaxRightPlayer() == nCharID
					end
				else
					if tTmpPlayer.nActionRight > 0 then
						tMJMsg.nHu = self:IsHu(tTmpPlayer.tHandMJ, tTmpPlayer.nHandMJ-1, tTmpPlayer.tHandMJ[nMaxHandMJ], tTmpPlayer.oHu)
						tMJMsg.nGang = self:IsAnGang(tTmpPlayer.tHandMJ, tTmpPlayer.nHandMJ).nGangStyle
							+ self:IsZMGang(tTmpPlayer.tHandMJ, tTmpPlayer.nHandMJ, tTmpPlayer.oHu).nGangStyle
						tMJMsg.bShow = true
					end
				end
			end
			table.insert(tPlayerMJ, tMJMsg)
			print("RecoverDesk***", tMJMsg)
		end
		tMsg.tPlayerMJ = tPlayerMJ
	end
	CmdNet.PBSrv2Clt(self:GetSession(nCharID), "RecoverDeskRet", tMsg)
end

--1局结算
function CGDMJRoomBase:RoundCalc(nWinnerID)
	nWinnerID = nWinnerID or 0
	local tRoundScore = {}
	if nWinnerID == 0 then
	--流局	
		for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
			local nScore = tTmpPlayer.nFollowScore + tTmpPlayer.nGangScore --跟庄/杠分
			tRoundScore[nTmpCharID] = nScore
		end
		return tRoundScore
	end

	local tPlayer = assert(self:GetPlayer(nWinnerID))
	local nHuType, oTmpHu = self:IsHu(tPlayer.tHandMJ, tPlayer.nHandMJ-1, tPlayer.tHandMJ[nMaxHandMJ], tPlayer.oHu)

	--胡牌分 = 底分 * 番数 * 无鬼加倍 * 杠上开花 *（1 + 马数）
	local nHuFan, sHuStr = self:CheckHuType(nWinnerID, nHuType, oTmpHu)
	print("番数:", nHuFan)
	--无鬼
	local nWuGui = self:CheckWuGui(nWinnerID)
	print("无鬼加倍翻:", nWuGui)

	--杠上开花/抢杠不会同时存在
	local bGangShang, nGangShangFan, nGangShangTar = self:CheckGangShang(nWinnerID, oTmpHu)
	print("杠上开花翻:", bGangShang, nGangShangFan, nGangShangTar)
	if bGangShang then sHuStr = sHuStr.." 杠上开花" end

	local bQiangGang, nQiangGangFan, nQiangGangTar = self:CheckQiangGang(nWinnerID, oTmpHu)
	print("抢杠翻:", bQiangGang, nQiangGangFan, nQiangGangTar)
	if bQiangGang then sHuStr = sHuStr.." 抢杠胡" end

	local nGangFan = math.max(nGangShangFan, nQiangGangFan)

	--马
	local nMaFan = 0
	local tMaList = self:GetMaMap(nWinnerID)
	for _, nMaMJ in ipairs(self.m_tMaMJ) do
		if table.InArray(nMaMJ, tMaList) then
			nMaFan = nMaFan + 1
		end
	end
	print("中马翻:", nMaFan)

	local nHuScore = self.m_nBaseScore * nHuFan * nWuGui * nGangFan * (1 + nMaFan)
	print("胡牌分:", nHuScore)

	assert(not (nGangShangTar and nQiangGangTar), "杠上开花和抢杠同时出现了")
	local nQuanBaoCharID
	--杠上开花全包
	if self.m_tOption.bGangShangBao and nGangShangTar then
		nQuanBaoCharID = nGangShangTar
		print("杠上开花全包:", nQuanBaoCharID)
	end
	--抢杠全包
	if self.m_tOption.bQiangGangBao and nQangGangTar then
		nQuanBaoCharID = nQangGangTar	
		print("抢杠全包:", nQuanBaoCharID)
	end

	for nTmpCharID, tTmpPlayer in pairs(self.m_tPlayerMap) do
		local nOtherScore = tTmpPlayer.nFollowScore + tTmpPlayer.nGangScore --跟庄/杠分
		print(nTmpCharID, "杠分:", tTmpPlayer.nGangScore)
		print(nTmpCharID, "跟庄分:", tTmpPlayer.nFollowScore)
		if nTmpCharID == nWinnerID then
			tRoundScore[nTmpCharID] = nHuScore * 3 + nOtherScore
		else
			if nQuanBaoCharID then
				if nQuanBaoCharID == nTmpCharID then
					tRoundScore[nTmpCharID] = -nHuScore * 3 + nOtherScore
				else
					tRoundScore[nTmpCharID] = nOtherScore
				end
			else
				tRoundScore[nTmpCharID] = -nHuScore + nOtherScore
			end
		end
	end
	return tRoundScore, sHuStr
end
