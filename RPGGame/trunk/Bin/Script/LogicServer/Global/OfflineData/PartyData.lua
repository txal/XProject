--宴会全局数据
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CPartyData:Ctor(oParent)
	self.m_oParent = oParent
	self.m_bDirty = false

	self.m_tPartyMap = {} 		--宴会列表{[charid]={record={},id=x,starttime=x,sharetime=0,score=0,tPlayer={}},...}
	self.m_tExpireParty = {} 	--过期宴会{[charid]={id=partyid,score=0, tPlayer={}},...}
	self.m_tMessgeMap = {} 		--消息列表
	self.m_tEnemyMap = {} 		--仇人列表
end

function CPartyData:LoadData()
	print("加载宴会数据")
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sOfflinePartyDB, "data")
	if sData == "" then
		return
	end

	local tData = cjson.decode(sData)
	self.m_tPartyMap = tData.m_tPartyMap
	self.m_tExpireParty = tData.m_tExpireParty
	self.m_tMessgeMap = tData.m_tMessgeMap
	self.m_tEnemyMap = tData.m_tEnemyMap
end

function CPartyData:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tPartyMap = self.m_tPartyMap
	tData.m_tExpireParty = self.m_tExpireParty
	tData.m_tMessgeMap = self.m_tMessgeMap
	tData.m_tEnemyMap = self.m_tEnemyMap
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sOfflinePartyDB, "data", cjson.encode(tData))
end

function CPartyData:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CPartyData:IsDirty()
	return self.m_bDirty
end

function CPartyData:OnRelease()
end

function CPartyData:RandParty(nExceptChar, nNum)
	local tList = {}
	for nCharID, tParty in pairs(self.m_tPartyMap) do
		if tParty.bPublic and nCharID ~= nExceptChar and not self:CheckExpire(nCharID) then
			local tConf = ctPartyConf[tParty.nID]
			table.insert(tList, {nCharID=nCharID, sCharName=goOfflineDataMgr:GetName(nCharID), sPartyName=tConf.sName})
			if #tList >= nNum then
				break
			end
		end
	end
	return tList
end

--主场景信息请求
function CPartyData:PartySceneReq(oPlayer)
	if not self:IsOpen(oPlayer, true) then
		return
	end
	local nCharID = oPlayer:GetCharID()
	
	local tParty = self:GetParty(nCharID)
	local tList = self:RandParty(nCharID, 6)
	local nMaxTimes = oPlayer.m_oParty:MaxTimes()
	local nRemainTimes = oPlayer.m_oParty:GetRemainTimes()

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PartySceneRet", {
			tList = tList, 
			nMaxTimes = nMaxTimes, 
			nRemainTimes = nRemainTimes,
			nMyParty = tParty and tParty.nID or 0,
		}
	)

	self:ProcessExpireParty(oPlayer)

	--小红点
	self:CheckRedPoint(oPlayer)
end

--检查宴会过期
function CPartyData:CheckExpire(nCharID)
	local tParty = self.m_tPartyMap[nCharID]
	if not tParty then
		return
	end
	local tConf = ctPartyConf[tParty.nID]
	if os.time() >= tParty.nStartTime + tConf.nOpenTime or tParty.bFull then
		self.m_tExpireParty[nCharID] = tParty
		self.m_tPartyMap[nCharID] = nil
		self:MarkDirty(true)
		return true
	end
end

--取宴会
function CPartyData:GetParty(nCharID)
	self:CheckExpire(nCharID)
	return self.m_tPartyMap[nCharID]
end

--开启宴会
function CPartyData:PartyOpenReq(oPlayer, nID, bPublic)
	if not self:IsOpen(oPlayer, true) then
		return
	end

	if oPlayer.m_oParty:GetOpenTimes() >= ctPartyEtcConf[1].nOpenTimes then
		return oPlayer:Tips("进入开宴次数已用完，请娘娘明日再来")
	end

	local nCharID = oPlayer:GetCharID()
	local tParty = self:GetParty(nCharID)
	if tParty then
		return oPlayer:Tips("每人同时只能举办一个宴会")
	end

	--判断道具
	local tConf = assert(ctPartyConf[nID])
	local tPropList = tConf.tConsumables
	for _, tProp in ipairs(tPropList) do
		if oPlayer:GetItemCount(tProp[1], tProp[2]) < tProp[3] then
			return oPlayer:Tips("所需材料或元宝不足，请娘娘备齐元宝与材料再试")
		end
	end

	--判断元宝
	if oPlayer:GetYuanBao() < tConf.nYuanBao then
		return oPlayer:YBDlg()
	end

	--扣除道具
	for _, tProp in ipairs(tPropList) do
		oPlayer:SubItem(tProp[1], tProp[2], tProp[3], "开启宴会:"..nID)
	end

	--扣除元宝
	oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nYuanBao, "开启宴会:"..nID)

	--增加宴会
	local tParty = {
		nID = nID,
		nStartTime = os.time(),
		nShareTime = 0,
		nScore = tConf.nIntegral,
		tPlayer = {}, --{[pos]={charid=0, icon="", charname="", jointype=0, time=0}}
		bPublic = bPublic,
		tRecord = {},
	}
	self.m_tPartyMap[nCharID] = tParty
	oPlayer.m_oParty:AddOpenTimes(1)
	self:MarkDirty(true)

	--开启成功
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PartyOpenRet", {nCharID=nCharID, nPartyID=nID})
	self:PartyInfoReq(oPlayer, nCharID)

	--日志
	goLogger:EventLog(gtEvent.ePartyStart, oPlayer)
end

--取宴会已参加人数
function CPartyData:PlayerCount(nCharID)
	local tParty = self:GetParty(nCharID)
	if not tParty then
		return 0, 0
	end
	local tConf = assert(ctPartyConf[tParty.nID])
	local nCount = 0
	for nPos, tData in pairs(tParty.tPlayer) do
		nCount = nCount + 1
	end
	return nCount, tConf.nMaxPeople
end

--取宴会剩余时间
function CPartyData:PartyRemainTime(nCharID)
	local tParty = self:GetParty(nCharID)
	if not tParty then
		return 0
	end
	local tConf = assert(ctPartyConf[tParty.nID])
	local nRemainTime = (tParty.nStartTime+tConf.nOpenTime)-os.time()
	return math.max(0, nRemainTime)
end

--分享
function CPartyData:PartyShareReq(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tParty = self:GetParty(nCharID)
	if not tParty then
		return oPlayer:Tips("宴会已结束")
	end
	if self:ShareRemainTime(nCharID) > 0 then
		return oPlayer:Tips("分享冷却中")
	end
	tParty.nShareTime = os.time()
	self:MarkDirty(true)
	--发送聊天频道
	local tConf = assert(ctPartyConf[tParty.nID])
	local sCont = string.format("<on click='partySkipGo'><color=#00FF00>【%s】</color></on uid=%d>佳肴美酒已备，各位小伙伴们赶紧来赴宴吧~"
			, tConf.sName, nCharID)
	goTalk:SendUnionMsg(oPlayer, sCont)
	goTalk:SendWorldMsg(oPlayer, sCont)
	oPlayer:Tips("分享宴会成功")
end

--分享冷却时间
function CPartyData:ShareRemainTime(nCharID)
	local tParty = self:GetParty(nCharID)
	if not tParty then
		return 0
	end
	local tConf = assert(ctPartyConf[tParty.nID])
	local nRemainTime = math.max(0, tParty.nShareTime+tConf.nShareTime-os.time())
	return nRemainTime
end

--检测是否开放
function CPartyData:IsOpen(oPlayer, bTips)
	local nChapter = ctPartyEtcConf[1].nOpenChapter
	if oPlayer.m_oDup:IsChapterPass(nChapter) then
		return true
	end
	if bTips then
		return oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
	end
end

--生成宴会信息
function CPartyData:MakePartyMsg(nCharID)
	local tParty = self:GetParty(nCharID)

	local tMsg = {}
	tMsg.nCharID = nCharID --玩家编号
	tMsg.sCharName = goOfflineDataMgr:GetName(nCharID) --角色名
	tMsg.nPartyID = tParty.nID --宴会ID
	tMsg.nScore = tParty.nScore --此次宴会积分
	tMsg.nRemainTime = self:PartyRemainTime(nCharID) --剩余时间
	local nPlayerCount, nMaxPlayer = self:PlayerCount(nCharID)
	tMsg.nPlayerCount =  nPlayerCount --当前赴宴人数
	tMsg.nMaxPlayer = nMaxPlayer --最大赴宴人数
	tMsg.tRecord = tParty.tRecord --记录列表
	tMsg.tDesk = {} --座位列表

	local tConf = ctPartyConf[tParty.nID]
	for k = 1, tConf.nMaxPeople do
		local tPlayer = tParty.tPlayer[k]
		if tPlayer then
			table.insert(tMsg.tDesk, {nDesk=k,
				sIcon=tPlayer.sIcon ~= "" and tPlayer.sIcon or "icon_zhujue01",
				sName=tPlayer.sCharName})
		else
			table.insert(tMsg.tDesk, {nDesk=k, sIcon="", sName=""})
		end
	end
	return tMsg
end

--处理结束的宴会
function CPartyData:ProcessExpireParty(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tExpireParty = self.m_tExpireParty[nCharID]	
	if tExpireParty then
		if not tExpireParty.nDealTime then
			tExpireParty.nDealTime = os.time()
			oPlayer.m_oParty:AddScore(tExpireParty.nScore, "宴会结束")	
			oPlayer.m_oParty:AddActive(tExpireParty.nScore, "宴会结束")	

			local sName = ctPartyConf[tExpireParty.nID].sName
			CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PartyFinishRet", {
					nID = tExpireParty.nID,
					sName = sName,
					nScore = tExpireParty.nScore,
					nPlayer = #tExpireParty.tRecord,
					tRecord = tExpireParty.tRecord,
				}
			)

			--记录消息
			local nDLPlayer = 0
			for _, tRecord in ipairs(tExpireParty.tRecord) do
				if tRecord.nJoinType == 4 then --捣乱
					nDLPlayer = nDLPlayer + 1
				end
			end
			self.m_tMessgeMap[nCharID] = self.m_tMessgeMap[nCharID] or {}
			table.insert(self.m_tMessgeMap[nCharID], 1, {
					nID=tExpireParty.nID, 
					nPlayer=#tExpireParty.tRecord, 
					nDLPlayer=nDLPlayer, 
					nScore=tExpireParty.nScore,
					nTime=tExpireParty.nStartTime, 
				})
			if #self.m_tMessgeMap[nCharID] > 100 then
				table.remove(self.m_tMessgeMap[nCharID])
			end
		else
			self.m_tExpireParty[nCharID] = nil
		end
		self:MarkDirty(true)
		--日志
		goLogger:EventLog(gtEvent.ePartyFinish, oPlayer, tExpireParty.nScore)
		return true
	end
end

--宴会内部信息请求
function CPartyData:PartyInfoReq(oPlayer, nTarCharID)
	if not self:IsOpen(oPlayer, true) then
		return
	end

	local nCharID = oPlayer:GetCharID()
	local tParty = self:GetParty(nTarCharID)
	if not tParty then
		if nCharID == nTarCharID then
			return self:PartySceneReq(oPlayer)
		else
			self:PartySceneReq(oPlayer)
			return oPlayer:Tips("宴会已结束，请娘娘查证后再试")
		end
	end
	if nCharID ~= nTarCharID and not tParty.bPublic then
		return oPlayer:Tips("非公开宴会，请娘娘参加其他宴会")
	end

	local tMsg = self:MakePartyMsg(nTarCharID)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PartyInfoRet", tMsg)
end

--查询别的玩家宴会
function CPartyData:PartyQueryReq(oPlayer, nTarCharID)
	local tParty = self:GetParty(nTarCharID)
	if not tParty or not tParty.bPublic then
		return oPlayer:Tips("该玩家没有公开宴会，请娘娘查证后再试")
	end

	local nPlayerCount, nMaxPlayer = self:PlayerCount(nTarCharID)
	local tMsg = {
		nCharID = nTarCharID, 	
		sCharName = goOfflineDataMgr:GetName(nTarCharID),
		sPartyName = ctPartyConf[tParty.nID].sName,
		nPlayerCount = nPlayerCount,
		nMaxPlayer = nMaxPlayer,
		nRemainTime = self:PartyRemainTime(nTarCharID),
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PartyQueryRet", tMsg)
end

--赴宴请求(nJoinType配表的)
function CPartyData:PartyJoinReq(oPlayer, nJoinType, nTarCharID, nDesk, bFC)
	print("CPartyData:PartyJoinReq***", nJoinType, nTarCharID)
	if not self:IsOpen(oPlayer, true) then
		return
	end
	local tJoinConf = assert(ctPartyMudoConf[nJoinType])
	local tProp = tJoinConf.tConsumption[1]
	if oPlayer:GetItemCount(tProp[1], tProp[2]) < tProp[3] then
		return oPlayer:Tips(string.format("%s不足，请娘娘带齐物品再试", CGuoKu:PropName(tProp[2])))
	end

	local nCharID = oPlayer:GetCharID()
	if nCharID == nTarCharID then
		return oPlayer:Tips("不能参加自己的宴会哦")
	end

	local tParty = self:GetParty(nTarCharID)
	if not tParty then
		return oPlayer:Tips("该宴会已结束，请娘娘选择别的宴会")
	end

	if not tParty.bPublic then
		return oPlayer:Tips("该宴会非公开，请娘娘选择别的宴会")
	end

	local tPartyConf = ctPartyConf[tParty.nID]
	if nDesk < 1 or nDesk > tPartyConf.nMaxPeople then
		return oPlayer:Tips("位置错误，请选娘娘选择其他空位")
	end

	for nDesk, tChar in pairs(tParty.tPlayer) do
		if tChar.nCharID == nCharID then
			return oPlayer:Tips("已参加过该宴会，请娘娘选择别的宴会")
		end
	end

	if tParty.tPlayer[nDesk] then
		return oPlayer:Tips("该位置已经有人了，请选娘娘选择其他空位")
	end

	if oPlayer.m_oParty:GetRemainTimes() <= 0 then
		return oPlayer:Tips("今日赴宴次数已用完，请娘娘明日再来吧")
	end
	oPlayer.m_oParty:AddJoinTimes(1)
	oPlayer:SubItem(tProp[1], tProp[2], tProp[3], "赴宴消耗")

	tParty.nScore = math.min(nMAX_INTEGER, tParty.nScore+tJoinConf.nIntegral)
	tParty.tPlayer[nDesk] = {
		nCharID = nCharID,
		sIcon = oPlayer:GetIcon(),
		sCharName = oPlayer:GetName(),
		nJoinType = nJoinType,
		nTime = os.time()
	}

	--赴宴记录
	local tJoinRecord = {sName=oPlayer:GetName(), nJoinType=nJoinType, nScore=tJoinConf.nIntegral}
	table.insert(tParty.tRecord, tJoinRecord)

	--人数已满则结束
	local nPlayerCount = self:PlayerCount(nTarCharID)
	if nPlayerCount >= tPartyConf.nMaxPeople then
		tParty.bFull = true
	end

	--记录仇人
	if nJoinType == 4 then
		if not bFC then --捣乱
			self.m_tEnemyMap[nTarCharID] = self.m_tEnemyMap[nTarCharID] or {}
			self.m_tEnemyMap[nTarCharID][nCharID] = os.time()
		else --复仇
			self.m_tEnemyMap[nCharID] = self.m_tEnemyMap[nCharID] or {}
			self.m_tEnemyMap[nCharID][nTarCharID] = nil
		end
	end
	self:MarkDirty(true)

	--发放奖励
	local tAwardList = {}
	local nRnd = math.random(1, 100)
	if nRnd <= tJoinConf.nProbability then
		local tAward = tJoinConf.tAward[math.random(#tJoinConf.tAward)]
		table.insert(tAwardList, tAward)
	end
	local nJoinScore = tJoinConf.nJoinScore

	local tAward = {}
	for _, tItem in ipairs(tAwardList) do
		oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "赴宴奖励")
		oPlayer.m_oParty:AddScore(nJoinScore, "赴宴奖励")
		oPlayer.m_oParty:AddActive(nJoinScore, "赴宴奖励")
		table.insert(tAward, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end

	--返回信息
	local tMsg = {
		tAward = tAward,
		nScore = nJoinScore,
		nJoinType = nJoinType,
		nPartyScore = tJoinConf.nIntegral,
		sName = goOfflineDataMgr:GetName(nTarCharID),
	}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PartyJoinRet", tMsg)

	--同步列表
	self:PartyInfoReq(oPlayer, nTarCharID)

	--奖励记录
	local sAward = ""
	for _, tItem in ipairs(tAward) do
		local tPropConf = ctPropConf[tItem.nID]
		sAward = sAward..tPropConf.sName.."*"..tItem.nNum.." "
	end
	local sRecord = string.format(ctLang[24], 
		oPlayer:GetName(), 
		goOfflineDataMgr:GetName(nTarCharID), 
		tPartyConf.sName, 
		sAward)
	goAwardRecordMgr:AddRecord(gtAwardRecordDef.eYanHui, sRecord)

	--任务
	oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond18, 1)
	--成就
	oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond19, 1)
	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(nCharID, gtTAType.eYH, 1)
end

--玩家上线
function CPartyData:Online(oPlayer)
	self:CheckRedPoint(oPlayer)
end

--检测小红点
function CPartyData:CheckRedPoint(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tParty = self:GetParty(nCharID)
	local tExpireParty = self.m_tExpireParty[nCharID]
	if tExpireParty and not tExpireParty.nDealTime then
		oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eParty, 1)
	else
		oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eParty, 0)
	end
end

--宴会信息请求
function CPartyData:PartyMessageReq(oPlayer)
	if not self:IsOpen(oPlayer, true) then
		return
	end
	local nTimeNow = os.time()
	local nCharID = oPlayer:GetCharID()
	local tMessageList = self.m_tMessgeMap[nCharID] or {}
	local tEnemyMap = self.m_tEnemyMap[nCharID] or {}
	local tEnemyList = {}
	for nCharID, nTime in pairs(tEnemyMap) do
		if nTimeNow - nTime >= 7*24*3600 then --保留7天
			tEnemyMap[nCharID] = nil
			self:MarkDirty(true)
		else
			local tEnemy = {nCharID=nCharID, sName=goOfflineDataMgr:GetName(nCharID), bParty=false}
			local tParty = self:GetParty(nCharID)
			if tParty and tParty.bPublic then
				tEnemy.bParty = true
				table.insert(tEnemyList, tEnemy)
				if #tEnemyList >= 100 then
					break
				end
			end
		end
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PartyMessageRet", {tMessageList=tMessageList, tEnemyList=tEnemyList})
end

--GM结束样
function CPartyData:GMFinishParty(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tParty = self:GetParty(nCharID)
	if not tParty then
		return oPlayer:Tips("没有进行中的宴会")
	end
	tParty.bFull = true
	self:MarkDirty(true)
	oPlayer:Tips("结束宴会成功")
end