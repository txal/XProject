--军机处
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxGroups = 4 		--最大使节团数
local nMaxGroupMCs = 5 		--每个团最大的知己数
local nRecoverTime = 3600 	--恢复次数间隔
local nMaxRecoverTimes = 3 	--最大累积出使次数
local nMaxRecords = 100 	--最大记录数

local tEtcConf = ctJunJiChuEtcConf[1]
local nWinWW = tEtcConf.tWin[1][1] 		--胜利威望
local nWinWJ = tEtcConf.tWin[1][2] 		--胜利外交
local nLostWW = tEtcConf.tLost[1][1] 	--失败威望
local nLostWJ = tEtcConf.tLost[1][2] 	--失败外交
local nWinScore = tEtcConf.tWin[1][5] 	--胜利出使积分
local nLostScore = tEtcConf.tLost[1][5] 	--失败出使积分

CJunJiChu.nCancelNoticeWW = 30 	--被掠夺的威望多少去除公告
CJunJiChu.nCanelTJNeedWW = 100 	--被抓捕扣掉多少威望减通缉次数

--战斗类型 
CJunJiChu.tBattleType = {
	eSend = 0, 			--出使	
	eRevenge = 1, 		--复仇
	eChallenge = 2, 	--挑战
	eCatch = 3, 		--抓捕
}

function CJunJiChu:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tGroupMap = {{}, {}, {}, {}} 	--1商,2农,3政,4军
	self.m_nSendTimes = 0 					--已出使次数
	self.m_nResetTime = os.time() 			--重置时间
	self.m_nCurrTimes = nMaxRecoverTimes 	--当前拥有次数
	self.m_nLastRecoverTime = os.time()
	self.m_nCSScore = 0 --出使积分
	self.m_nWins = 0 	--连胜
	self.m_nLosts = 0 	--连败

	self.m_tOfflineAward = {} 		--论战离线结算奖励
	self.m_tEnemyRecord = {} 		--仇人列表
	self.m_tZaoJianRecord = {} 		--召见列表
	self.m_nLastViewZJ = os.time() 	--最后查看召见时间
	self.m_nPlayStep = 0 			--0:首次打开; 1:首次匹配; 2:第一次结算
	self.m_nOpenDay = 0 			--每天第一次打开标记

	--保存
	self.m_tBattle = {bEnd=true} --战斗
	self.m_tCTRecord = {tCTMap={}, nGuWu=0} --刺探/鼓舞:0,1,2,3
end

function CJunJiChu:LoadData(tData)
	if tData then
		for nGroup, tGroupMC in ipairs(tData.m_tGroupMap or {}) do
			for nGrid, nMCID in pairs(tGroupMC) do
				if ctMingChenConf[nMCID] then
					self.m_tGroupMap[nGroup][nGrid] = nMCID
				end
			end
		end
		self.m_nSendTimes = tData.m_nSendTimes or self.m_nSendTimes
		self.m_nResetTime = tData.m_nResetTime or self.m_nResetTime
		self.m_nCurrTimes = tData.m_nCurrTimes or self.m_nCurrTimes
		self.m_nLastRecoverTime = tData.m_nLastRecoverTime or self.m_nLastRecoverTime
		self.m_nCSScore = tData.m_nCSScore or self.m_nCSScore
		self.m_nWins = tData.m_nWins or self.m_nWins
		self.m_nLosts = tData.m_nLosts or self.m_nLosts

		self.m_tOfflineAward = tData.m_tOfflineAward or self.m_tOfflineAward
		self.m_tZaoJianRecord = tData.m_tZaoJianRecord or self.m_tZaoJianRecord
		self.m_tEnemyRecord = tData.m_tEnemyRecord or self.m_tEnemyRecord
		self.m_nLastViewZJ = tData.m_nLastViewZJ or self.m_nLastViewZJ
		self.m_nPlayStep = tData.m_nPlayStep or self.m_nPlayStep
		self.m_nOpenDay = tData.m_nOpenDay or self.m_nOpenDay
		self.m_tBattle = tData.m_tBattle or self.m_tBattle
		self.m_tCTRecord = tData.m_tCTRecord or self.m_tCTRecord

	end
end

function CJunJiChu:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tGroupMap = self.m_tGroupMap
	tData.m_nSendTimes = self.m_nSendTimes
	tData.m_nResetTime = self.m_nResetTime
	tData.m_nCurrTimes = self.m_nCurrTimes
	tData.m_nLastRecoverTime = self.m_nLastRecoverTime
	tData.m_nCSScore = self.m_nCSScore
	tData.m_nWins = self.m_nWins
	tData.m_nLosts = self.m_nLosts

	tData.m_tOfflineAward = self.m_tOfflineAward
	tData.m_tZaoJianRecord = self.m_tZaoJianRecord
	tData.m_tEnemyRecord = self.m_tEnemyRecord
	tData.m_nLastViewZJ = self.m_nLastViewZJ
	tData.m_nPlayStep = self.m_nPlayStep
	tData.m_nOpenDay = self.m_nOpenDay
	tData.m_tBattle = self.m_tBattle
	tData.m_tCTRecord = self.m_tCTRecord
	return tData
end

function CJunJiChu:GetType()
	return gtModuleDef.tJunJiChu.nID, gtModuleDef.tJunJiChu.sName
end

--上线
function CJunJiChu:Online()
	self:CheckRecover()
	self:CheckRedPoint()	

	--计算离线奖励
	for _, tMCAward in ipairs(self.m_tOfflineAward) do
		for _, tAward in ipairs(tMCAward) do
			local oMC = self.m_oPlayer.m_oMingChen:GetObj(tAward.nMCID)
			if oMC then
				oMC:AddZhanJi(tAward.nScore, "离线论战结算")
				oMC:AddGrowPoint(tAward.nGroup or 1, tAward.nGrow, "离线论战结算")
			end
		end
	end

	if #self.m_tOfflineAward > 0 then
		self.m_tOfflineAward = {}
		self:MarkDirty(true)
	end
end

--离线
function CJunJiChu:Offline()
	--保存使团信息到离线数据
	local tMCGroup = self:GetGroupData()
	goOfflineDataMgr.m_oJJCData:UpdateMCGroup(self.m_oPlayer, tMCGroup)
end

--是否开放
function CJunJiChu:IsOpen(bTips)
	local nChapter = ctJunJiChuEtcConf[1].nOpenChapter
	local bRes = self.m_oPlayer.m_oDup:IsChapterPass(nChapter)
	if not bRes and bTips then
		return self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
	end
	return bRes
end

--取使节团数量
function CJunJiChu:GetMCGroups()
	local nGroups, tGroup = 0, {}
	for k = 1, nMaxGroups do
		local tTmpGroup = self.m_tGroupMap[k]
		for j = 1, nMaxGroupMCs do
			if (tTmpGroup[j] or 0) > 0 then
				nGroups = nGroups + 1
				table.insert(tGroup, k)
				break
			end
		end
	end
	return nGroups, tGroup
end

--取使节团数据 
function CJunJiChu:GetGroupData(nTarGroup)
	local tMCGroup
	if nTarGroup then
		tMCGroup = {}
		local tGroup = self.m_tGroupMap[nTarGroup]
		for j = 1, nMaxGroupMCs do
			if (tGroup[j] or 0) > 0 then
				local tData = self:GetMCData(nTarGroup, j, tGroup[j])
				table.insert(tMCGroup, tData)
			end
		end
	else
		tMCGroup = {{}, {}, {}, {}}
		for k = 1, nMaxGroups do
			local tGroup = self.m_tGroupMap[k]
			for j = 1, nMaxGroupMCs do
				if (tGroup[j] or 0) > 0 then
					local tData = self:GetMCData(k, j, tGroup[j])
					table.insert(tMCGroup[k], tData)
				end
			end
		end
	end
	return tMCGroup
end

--取知己战斗属性
function CJunJiChu:GetMCData(nGroup, nGrid, nMCID)
	local oMC = self.m_oPlayer.m_oMingChen:GetObj(nMCID)
	local tAttr = oMC:GetAttr()
	local tSkLv = oMC:GetSkillLv()
	local tSkQua = oMC:GetSkillQua()
	local tData = {nLv=oMC:GetLevel(), nGroup=nGroup, nGrid=nGrid, nMCID=nMCID, sName=oMC:GetName(), tAttr=tAttr, tSkLv=tSkLv, tSkQua=tSkQua}
	return tData
end

--累积恢复次数上限(如果经常改动,增加到配表)
function CJunJiChu:MaxTimes()
	return nMaxRecoverTimes
end

--增加次数
function CJunJiChu:AddTimes(nVal, sReason)
	assert(nVal and sReason, "参数非法")
	local nOrgTimes = self.m_nCurrTimes
	self.m_nCurrTimes = math.min(self:MaxTimes(), math.max(0, self.m_nCurrTimes+nVal))
	self:CheckRedPoint()	
	self:MarkDirty(true)
	if nOrgTimes ~= self.m_nCurrTimes then
		local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
		goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eSendTimes, nVal, self.m_nCurrTimes)
	end
end

--增加出使积分
function CJunJiChu:AddCSScore(nVal, sReason)
	assert(nVal, "参数非法")
	self.m_nCSScore = math.min(nMAX_INTEGER, math.max(0, self.m_nCSScore+nVal))
	self:MarkDirty(true)
	if sReason then
		local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
		goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eCSScore, nVal, self.m_nCSScore)
	end
	return self.m_nCSScore
end

--取下次恢复时间
function CJunJiChu:GetRecoverTime()
	return math.max(0, (self.m_nLastRecoverTime+nRecoverTime-os.time()))
end

--次数恢复处理
function CJunJiChu:CheckRecover()
	local nNowTime = os.time() 
	local nPassTime = nNowTime - self.m_nLastRecoverTime 
	local nTimesAdd = math.floor(nPassTime / nRecoverTime) 
	if nTimesAdd > 0 then                                                                                                        
		self.m_nLastRecoverTime = self.m_nLastRecoverTime + nTimesAdd * nRecoverTime
		self:AddTimes(nTimesAdd, "次数恢复")
		self:MarkDirty(true)
	end
end

--格子是否开放
function CJunJiChu:IsGridOpen(nGrid, bTips)
	local tConf = ctJunJiChuGridConf[nGrid]
	if tConf.nOpenChapter > 0 then
		if not self.m_oPlayer.m_oDup:IsChapterPass(tConf.nOpenChapter) then
			if bTips then
				local sTips = string.format("通关第%d章: %s开启", tConf.nOpenChapter, CDup:ChapterName(tConf.nOpenChapter))
				self.m_oPlayer:Tips(sTips)
			end
			return
		end
	end
	return true
end

--标记设置过使节团(可以被匹配到)
function CJunJiChu:MarkMCGroup()
	if not goOfflineDataMgr.m_oJJCData:HasMCGroup(self.m_oPlayer:GetCharID()) and self:GetMCGroups() > 0 then
		goOfflineDataMgr.m_oJJCData:MarkMCGroup(self.m_oPlayer)
	end
end

--添加知己到使节团
function CJunJiChu:AddMC(nGroup, nGrid, nMCID)
	assert(nGrid >= 1 and nGrid <= nMaxGroupMCs, "位置非法")
	local oMC = self.m_oPlayer.m_oMingChen:GetObj(nMCID) 
	if not oMC then
		return self.m_oPlayer:Tips("知己不存在:"..nMCID)
	end

	--格子未开放
	if not self:IsGridOpen(nGrid, true) then
		return
	end

	--先罢免如果已任命
	for _, tGroup in pairs(self.m_tGroupMap) do
		for k = 1, nMaxGroupMCs do
			if tGroup[k] and tGroup[k] == nMCID then
				tGroup[k] = 0
			end
		end
	end

	--如果目标位置已有则替换
	local tGroup = self.m_tGroupMap[nGroup]
	local nOldMCID = tGroup[nGrid] or 0
	if nOldMCID > 0 and nMCID ~= nOldMCID then
		tGroup[nGrid] = 0
	end
	tGroup[nGrid] = nMCID
	self:MarkDirty(true)
	self:SyncInfo()
	--标记已设置过使节团
	self:MarkMCGroup()

	return true
end

--移除知己到使节团
function CJunJiChu:RemoveMC(nGroup, nGrid)
	assert(nGrid >= 1 and nGrid <= nMaxGroupMCs, "位置非法")
	local tGroup = self.m_tGroupMap[nGroup]
	if (tGroup[nGrid] or 0) == 0 then
		return
	end
	tGroup[nGrid] = 0
	self:MarkDirty(true)
	self:SyncInfo()
end

--检测出使次数重置
function CJunJiChu:CheckReset()
	local nNowSec = os.time()
	if not os.IsSameDay(nNowSec, self.m_nResetTime, 5*3600) then
		self.m_nSendTimes = 0
		self.m_nResetTime = nNowSec
		self:MarkDirty(true)
	end
end

--同步信息
function CJunJiChu:SyncInfo()
	self:CheckReset()
	self:CheckRecover()

	--正常发信息
	local tInfo = {bOpen=false}
	if self:IsOpen() then
		if self.m_nPlayStep == 0 then
			self.m_nPlayStep = 1 
			self:MarkDirty(true)
			self:DoOneKeyAddMC()
		end

		tInfo.bOpen = true
		tInfo.nSendTimes = self.m_nSendTimes
		tInfo.nCurrTimes = self.m_nCurrTimes
		tInfo.nRecoverTime = self:GetRecoverTime()
		tInfo.bOpenZhaoJian = false
		tInfo.tMCList = {}

		--每天第一次打开检测
		if self.m_nOpenDay ~= os.YDay(os.time()) then
			self.m_nOpenDay = os.YDay(os.time())
			self:MarkDirty(true)
			if #self.m_tZaoJianRecord > 0 then
				tInfo.bOpenZhaoJian = true
			end
		end

		for k = 1, nMaxGroups do
			local tGroup = self.m_tGroupMap[k]
			for j = 1, nMaxGroupMCs do
				if (tGroup[j] or 0) > 0 then
					local tMC = {nGroup=k, nMCID=tGroup[j], nGrid=j}
					table.insert(tInfo.tMCList, tMC)
				end
			end
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCInfoRet", tInfo)

	--战斗准备中
	if not self.m_tBattle.bEnd then
		self:SendPrepare()
	end
end

--根据连胜/败匹配玩家
function CJunJiChu:MatchEnemy()
	--首次匹配
	if self.m_nPlayStep == 1 then
		self.m_nPlayStep = 2
		self:MarkDirty(true)
		return 0 --0是机器人ID
	else
		self.m_nPlayStep = self.m_nPlayStep + 1
		self:MarkDirty(true)
	end
	--加权
	local nWinsAdd = math.max(0, self.m_nWins-2)
	local nLostsAdd = math.max(0, self.m_nLosts-2)

	--计算区间
	local nTotalW, nPreW = 0, 0
	for _, tConf in ipairs(ctJunJiChuMatchConf) do
		local nWeight = tConf.nBaseWeight+nWinsAdd*tConf.nWinsAdd+nLostsAdd*tConf.nLostsAdd
		tConf.nWeight = nWeight
		tConf.nMinW = nPreW + 1
		tConf.nMaxW = tConf.nMinW + nWeight - 1
		nPreW = tConf.nMaxW
		nTotalW = nTotalW + nWeight
	end

	--拿到威望区间
	local tRang = {}
	local nRnd = math.random(1, nTotalW)
	for _, tConf in ipairs(ctJunJiChuMatchConf) do
		if nRnd >= tConf.nMinW and nRnd <= tConf.nMaxW then
			tRang[1] = tConf.tRang[1][1]
			tRang[2] = tConf.tRang[1][2]
			break
		end
	end

	local nWeiWang = self.m_oPlayer:GetWeiWang()
	tRang[1] = math.max(0, tRang[1] + nWeiWang)
	tRang[2] = math.max(0, tRang[2] + nWeiWang)
	return goOfflineDataMgr.m_oJJCData:MatchMCGroup(self.m_oPlayer:GetCharID(), tRang[1], tRang[2])
end

--是否在有效时间内
function CJunJiChu:InValidTime()
	local nNowSec = os.time()
 	local tDate = os.date("*t", nNowSec)  	
 	local tConf = ctJunJiChuEtcConf[1]
	local nBegTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tConf.nStartTime, 0, 0)
	local nEndTime = os.MakeTime(tDate.year, tDate.month, tDate.day, tConf.nEndTime, 0, 0)
	if nNowSec < nBegTime or nNowSec >= nEndTime then
		return
	end
	return true
end

--是否可以出使
function CJunJiChu:CanSend(bUseProp, bNoTips)
	self:CheckReset()
	if not self:IsOpen(not bNoTips) then
		return
	end
	if self:IsInBattle() then
		if not bNoTips then self.m_oPlayer:Tips("正在战斗中") end
		return
	end
	if not self:InValidTime() then
		if not bNoTips then self.m_oPlayer:Tips("未到可出使时间") end
		return
	end
	if self.m_nCurrTimes <= 0 then
		if not bNoTips then self.m_oPlayer:Tips("没有可出使次数") end
		return 
	end
 	local tConf = ctJunJiChuEtcConf[1]
	if not bUseProp and self.m_nSendTimes >= tConf.nMaxDaySend then
		if not bNoTips then self.m_oPlayer:Tips("今天出使次数已用完") end
		return
	end
	local nGroups, tGroup = self:GetMCGroups()
	if nGroups == 0 then
		if not bNoTips then self.m_oPlayer:Tips("请先设置使团") end
		return 
	end
	return true
end

--出使
function CJunJiChu:Send(bUseProp)
	if bUseProp then
		local tProp = ctJunJiChuEtcConf[1].tSendProp[1]
		local nPackCount = self.m_oPlayer:GetItemCount(tProp[1], tProp[2])
		if nPackCount < tProp[3] then return self.m_oPlayer:Tips("出使令不足") end
		self:AddTimes(1, "使用出使令")
		self.m_oPlayer:SubItem(tProp[1], tProp[2], tProp[3], "使用出使令")
	end
	if not self:CanSend(bUseProp) then
		return
	end

	--随机1个团出战
	local _, tValidGroup = self:GetMCGroups()
	if #tValidGroup <= 0 then
		return self.m_oPlayer:Tips("数据错误，请先设置使节团")
	end

	local nTarCharID = self.m_nGMCharID and self.m_nGMCharID or self:MatchEnemy()
	local nTarGroup = self.m_nGMCharID and 1 or tValidGroup[math.random(#tValidGroup)]
	if nTarCharID == 0 then --首次匹配机器人
		nTarGroup = 1 --首次匹配必是商业论战
	end
	if not nTarCharID then
		return self.m_oPlayer:Tips("匹配对手失败")
	end
	if nTarCharID >= gnBaseCharID then
		local oOfflineData = goOfflineDataMgr:GetPlayer(nTarCharID)
		print("匹配到对手:", nTarCharID, oOfflineData.m_sName)
		self:OnPlayerBattle(nTarCharID, nTarGroup)
	else
		print("匹配到机器人:", nTarCharID)
		self:OnRobotBattle(nTarCharID, nTarGroup)
	end
	self:SendPrepare()
end

--发送准备信息
function CJunJiChu:SendPrepare()
	local nGroup = self.m_tBattle.nGroup
	local nBattleType = self.m_tBattle.nBattleType
	local nSrcCharID = self.m_tBattle.nSrcCharID
	local nTarCharID = self.m_tBattle.nTarCharID

	local tSrcMCList = self.m_tBattle[nSrcCharID]
	local tTarMCList = self.m_tBattle[nTarCharID]
	local tList = {}
	for k = 1, nMaxGroupMCs do
		local tSrcMC = tSrcMCList[k] or {}
		local tTarMC = tTarMCList[k] or {}
		local tGrid = {nGrid=k,
			nSrcID=tSrcMC.nMCID, sSrcName=tSrcMC.sName, nSrcBlood=tSrcMC.nBlood, nSrcMCLv=tSrcMC.nLv, nSrcAttr=(tSrcMC.tAttr and tSrcMC.tAttr[nGroup]),
			nTarID=tTarMC.nMCID, sTarName=tTarMC.sName, nTarBlood=tTarMC.nBlood, nTarMCLv=tTarMC.nLv, nTarAttr=(tTarMC.tAttr and tTarMC.tAttr[nGroup]),
			bCT=(self.m_tCTRecord.tCTMap[k] or false)
		}

		table.insert(tList, tGrid)
	end
	local sSrcCharName = self.m_oPlayer:GetName()
	local nSrcWeiWang = self.m_oPlayer:GetWeiWang()

	local sTarCharName = ""
	local nTarWeiWang = 0
	if self.m_tBattle.bRobot then
		local tConf = ctJunJiChuRobotConf[nTarCharID]
		sTarCharName = tConf.sName
		nTarWeiWang = tConf.nWW
	else
		local oTarPlayer = goOfflineDataMgr:GetPlayer(nTarCharID)
		sTarCharName = oTarPlayer.m_sName
		nTarWeiWang = oTarPlayer.m_nWeiWang
	end
	local tMsg = {
		nGroup=nGroup,
		tList=tList,
		sSrcName=sSrcCharName,
		nSrcWW=nSrcWeiWang,
		sTarName=sTarCharName,
		nTarWW=nTarWeiWang,
		nBattleType=nBattleType,
		nGuWu=self.m_tCTRecord.nGuWu,
		nCSScore=self.m_nCSScore,
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCPrepareRet", tMsg)
end

--积分刺探
function CJunJiChu:JFCTReq()
	if self.m_tBattle.bEnd then return self.m_oPlayer:Tips("战斗已结束") end
	local tCTProp = ctJunJiChuEtcConf[1].tCTProp[1]
	if self.m_nCSScore < tCTProp[3] then
		return self.m_oPlayer:Tips("出使积分不足")
	end
	local nTarCharID = self.m_tBattle.nTarCharID
	local tTarMCList = self.m_tBattle[nTarCharID]

	local tList = {}
	for k = 1, nMaxGroupMCs do
		if not self.m_tCTRecord.tCTMap[k] and tTarMCList[k] then
			table.insert(tList, k)
		end
	end
	if #tList <= 0 then
		return self.m_oPlayer:Tips("敌方没有可刺探的大臣")
	end
	self:AddCSScore(-tCTProp[3], "积分刺探")
	local nGrid = tList[math.random(#tList)]
	self.m_tCTRecord.tCTMap[nGrid] = true
	self:MarkDirty(true)
	self:SendPrepare()
	self.m_oPlayer:Tips("成功刺探敌方一名大臣属性")
end

--鼓舞
function CJunJiChu:GuWuReq(nGWType)
	if self.m_tCTRecord.nGuWu == 3 then --已经都鼓舞过
		return self.m_oPlayer:Tips("每种鼓舞只能鼓舞一次")
	end
	if nGWType == self.m_tCTRecord.nGuWu then
		return self.m_oPlayer:Tips("已鼓舞过了")
	end
	if nGWType == 1 then --积分鼓舞
		local tGWProp1 = ctJunJiChuEtcConf[1].tGWProp1[1]
		if self.m_nCSScore < tGWProp1[3] then
			return self.m_oPlayer:Tips("出使积分不足")
		end
		self:AddCSScore(-tGWProp1[3], "积分鼓舞")
		self.m_tCTRecord.nGuWu = self.m_tCTRecord.nGuWu + nGWType
		self:MarkDirty(true)
		self:SendPrepare()
		local nPercent = tGWProp1[4]*100
		self.m_oPlayer:Tips(string.format("临时伤害加成%d%%", nPercent))

	elseif nGWType == 2 then --元宝鼓舞
		local tGWProp2 = ctJunJiChuEtcConf[1].tGWProp2[1]
		if self.m_oPlayer:GetYuanBao() < tGWProp2[3] then
			return self.m_oPlayer:YBDlg()
		end
		self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, -tGWProp2[3], "元宝鼓舞")
		self.m_tCTRecord.nGuWu = self.m_tCTRecord.nGuWu + nGWType
		self:MarkDirty(true)
		self:SendPrepare()
		local nPercent = tGWProp2[4]*100
		self.m_oPlayer:Tips(string.format("临时伤害加成%d%%", nPercent))

	end
end

--调整位置请求
function CJunJiChu:ExchangePosReq(nGrid1, nGrid2)
	assert(nGrid1 >= 1 and nGrid1 <= nMaxGroupMCs)
	assert(nGrid2 >= 1 and nGrid2 <= nMaxGroupMCs)
	local nSrcCharID = self.m_tBattle.nSrcCharID
	local tSrcMCList = self.m_tBattle[nSrcCharID]
	local tTmpMC = tSrcMCList[nGrid1]
	tSrcMCList[nGrid1] = tSrcMCList[nGrid2]
	tSrcMCList[nGrid2] = tTmpMC
	self:MarkDirty(true)
	self:SendPrepare()
end

--开始战斗
function CJunJiChu:StartBattleReq(nBattleType)
	print("CJunJiChu:StartBattleReq******", nBattleType)
	if self.m_tBattle.bEnd then
		return self.m_oPlayer:Tips("不在战斗准备中")
	end
	local nBattleType = self.m_tBattle.nBattleType --前端发错了,不用前端发的
	if nBattleType == self.tBattleType.eSend then
		self:AddTimes(-1, "出使消耗")
		self.m_nSendTimes = self.m_nSendTimes + 1
		self:MarkDirty(true)
		--任务
		self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond17, 1)
		self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond23, 1)
		--成就
		self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond11, 1)
		--开始战斗
		self:BattleProcedure(self.m_tBattle.nSrcCharID, self.m_tBattle.nTarCharID)
	else
		local tProp = ctJunJiChuEtcConf[1].tChallengeProp[1]
		self.m_oPlayer:SubItem(tProp[1], tProp[2], tProp[3], "攻打指定玩家:"..nBattleType)
		--活动
	    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eTZS, tProp[3])
	    --开始战斗
		self:BattleProcedure(self.m_tBattle.nSrcCharID, self.m_tBattle.nTarCharID)
	end
end

--构造战斗数据
function CJunJiChu:MakeBattleData(nGroup, nSrcCharID, tSrcGroupData, nTarCharID, tTarGroupData, nBattleType, nNoticeID)
	self.m_tCTRecord = {nGuWu=0, tCTMap={}}
	self.m_tBattle.nGroup = nGroup
	self.m_tBattle.nBattleType = nBattleType
	self.m_tBattle.nSrcCharID = nSrcCharID
	self.m_tBattle.nTarCharID = nTarCharID
	self.m_tBattle.nSrcWins = 0
	self.m_tBattle.nTarWins = 0
	self.m_tBattle.tGlobalAward = {}
	self.m_tBattle.tGlobalAward[nSrcCharID] = {nWeiWang=0, nWaiJiao=0, nCSScore=0} --威望外交奖励
	self.m_tBattle.tGlobalAward[nTarCharID] = {nWeiWang=0, nWaiJiao=0, nCSScore=0} --威望外交奖励
	self.m_tBattle.nNoticeID = nNoticeID
	self.m_tBattle.bRobot = tTarGroupData.bRobot --对手是不是机器人
	self.m_tBattle.bEnd = false

	self.m_tBattle[nSrcCharID] = {}
	self.m_tBattle[nTarCharID] = {}

	local nSrcMCs = 0
	for _, tData in ipairs(tSrcGroupData) do
		tData.nBlood = 0 
		tData.bWin = nil
		tData.tAward = nil

		for k = 1, 4 do tData.nBlood = tData.nBlood + (tData.tAttr[k] or 0 ) end
		assert(tData.nBlood > 0, "攻方知己血量为0"..table.ToString(tData.tAttr, true))
		self.m_tBattle[nSrcCharID][tData.nGrid] = tData
		nSrcMCs = nSrcMCs + 1

	end
	assert(nSrcMCs > 0, "攻方没有知己")

	local nTarMCs = 0
	for _, tData in ipairs(tTarGroupData) do
		tData.bWin = nil
		tData.tAward = nil

		if not tTarGroupData.bRobot then
			tData.nBlood = 0
			for k = 1, 4 do tData.nBlood = tData.nBlood + (tData.tAttr[k] or 0 ) end
			assert(tData.nBlood > 0, "目标知己血量为0"..table.ToString(tData.tAttr, true))
		else
			assert(tData.nBlood > 0, "机器人血量必须大于0")
		end
		self.m_tBattle[nTarCharID][tData.nGrid] = tData
		nTarMCs = nTarMCs + 1

	end
	self:MarkDirty(true)
end

--取鼓舞加成
function CJunJiChu:GetGuWuAdd()
	local tConf = ctJunJiChuEtcConf[1]
	local nGuWu = self.m_tCTRecord.nGuWu
	if nGuWu == 1 then
		return tConf.tGWProp1[1][4]
	elseif nGuWu == 2 then
		return tConf.tGWProp2[1][4]
	elseif nGuWu == 3 then
		return tConf.tGWProp1[1][4] + tConf.tGWProp2[1][4]
	end
	return 0
end

--开始战斗流程
function CJunJiChu:BattleProcedure(nSrcCharID, nTarCharID)
	--血量=总属性
	--判断商业/农业/政治/军事对应技能是否触发
	--若技能触发，商业/农业/政治/军事伤害=int （rand（0.95,1.05）*知己对应属性*0.2*对应技能伤害百分比）
	--若技能不触发，商业/农业/政治/军事伤害= int （rand（0.95,1.05）*知己对应属性*0.2）
	--例如：当前论战项目为商业，某知己商业属性为2000，对应技能为：
	--商业论战中有20%几率对敌方造成200%伤害，判断该知己技能是否触发，若触发，伤害=2000*0.2*200%=800，若不触发，伤害=2000*0.2=400
	--商业/农业/政治/军事论战中有20%+星级*5%概率造成200%+技能等级*2%伤害
	goLogger:EventLog(gtEvent.eLZStart, self.m_oPlayer, nTarCharID, self.m_tBattle.bRobot
		, self.m_tBattle.nGroup, self.m_tBattle[nSrcCharID], self.m_tBattle[nTarCharID], self.m_tBattle.nBattleType)

	--知己奖励
	local function _MakeAward(bWin, nCharID)
		local nGrow
		if nCharID == nSrcCharID and self.m_nPlayStep == 2 then
			nGrow = 80 --玩家第一次出使知己获得80点成长，无论成功失败
		end
		if bWin then
			return {nScore=tEtcConf.tWin[1][3], nGrow=(nGrow or tEtcConf.tWin[1][4])}
		else
			return {nScore=tEtcConf.tLost[1][3], nGrow=(nGrow or tEtcConf.tLost[1][4])}
		end
	end

	self.m_tBattle.nSrcWins = 0
	self.m_tBattle.nTarWins = 0
	local nGroup = self.m_tBattle.nGroup

	local nRounds = 0 		--回合数
	local tRounds = {} 		--回合数据
	local tResGrid = {} 	--记录分出胜负的格子
	local nMaxRounds = 32 	--最大回合数

	local tSrcAward = self.m_tBattle.tGlobalAward[nSrcCharID]
	local tTarAward = self.m_tBattle.tGlobalAward[nTarCharID]
	local nGuWuAdd = self:GetGuWuAdd()

	while nRounds < nMaxRounds do
		nRounds = nRounds + 1
		tRounds[nRounds] = {nRounds=nRounds, tBattle={}}
		for k = 1, nMaxGroupMCs do
			local tSrcMC = self.m_tBattle[nSrcCharID][k]
			local tTarMC = self.m_tBattle[nTarCharID][k]
			if tSrcMC and tTarMC then
				if not tResGrid[k] then
					--攻方数值
					local nSrcAttr = tSrcMC.tAttr[nGroup]
					local nSrcSkRate = (0.2+tSrcMC.tSkQua[nGroup]*0.05)*100
					local nSrcSkHurt = 2+tSrcMC.tSkLv[nGroup]*0.02

					--攻方伤害
					local bSrcSkill = false
					local nSrcHurt = math.random(95, 105)/100*nSrcAttr*0.25
					local nRnd = math.random(1, 100)
					if nRnd >= 1 and nRnd <= nSrcSkRate then
						bSrcSkill = true
						nSrcHurt = math.floor(nSrcHurt * nSrcSkHurt * (1 + nGuWuAdd))
					else
						nSrcHurt = math.floor(nSrcHurt * (1 + nGuWuAdd))
					end
					local nOrgTarBlood = tTarMC.nBlood
					tTarMC.nBlood = math.max(0, tTarMC.nBlood - nSrcHurt)
					print("守方扣血:", nOrgTarBlood, tTarMC.nBlood, nSrcHurt, nSrcAttr, nSrcSkHurt, bSrcSkill)
					
					local bTarSkill = false
					local nOrgSrcBlood = tSrcMC.nBlood
					if tTarMC.nBlood > 0 then
						--守方数值
						local nTarAttr = tTarMC.tAttr[nGroup]
						local nTarSkRate = (0.2+tTarMC.tSkQua[nGroup]*0.05)*100
						local nTarSkHurt = 2+tTarMC.tSkLv[nGroup]*0.02

						--守方伤害
						local nTarHurt = math.random(95, 105)/100*nTarAttr*0.25
						local nRnd = math.random(1, 100)
						if nRnd >= 1 and nRnd <= nTarSkRate then
							bTarSkill = true
							nTarHurt = math.floor(nTarHurt * nTarSkHurt * (1 + nGuWuAdd))
						else
							nTarHurt = math.floor(nTarHurt * (1 + nGuWuAdd))
						end
						tSrcMC.nBlood = math.max(0, tSrcMC.nBlood - nTarHurt)
						print("攻方扣血:", nOrgSrcBlood, tSrcMC.nBlood, nTarHurt, nTarAttr, nTarSkHurt, bTarSkill)
					end

					local nWin = 0
					if tSrcMC.nBlood > 0 and tTarMC.nBlood == 0 then
						tSrcMC.bWin = true
						tTarMC.bWin = false
						self.m_tBattle.nSrcWins = self.m_tBattle.nSrcWins + 1
						tResGrid[k] = true
						nWin = 1

						tSrcMC.tAward = _MakeAward(true, nSrcCharID)
						tSrcAward.nWeiWang = tSrcAward.nWeiWang + nWinWW	
						tSrcAward.nWaiJiao = tSrcAward.nWaiJiao + nWinWJ	
						tSrcAward.nCSScore = tSrcAward.nCSScore + nWinScore

						tTarMC.tAward = _MakeAward(false, nTarCharID)
						tTarAward.nWeiWang = tTarAward.nWeiWang + nLostWW	
						tTarAward.nWaiJiao = tTarAward.nWaiJiao + nLostWJ	

					elseif tSrcMC.nBlood == 0 and tTarMC.nBlood >= 0 then
						tSrcMC.bWin = false
						tTarMC.bWin = true
						self.m_tBattle.nTarWins = self.m_tBattle.nTarWins + 1
						tResGrid[k] = true
						nWin = 2

						tSrcMC.tAward = _MakeAward(false, nSrcCharID)
						tSrcAward.nWeiWang = tSrcAward.nWeiWang + nLostWW	
						tSrcAward.nWaiJiao = tSrcAward.nWaiJiao + nLostWJ	
						tSrcAward.nCSScore = tSrcAward.nCSScore + nLostScore
						
						tTarMC.tAward = _MakeAward(true, nTarCharID)
						tTarAward.nWeiWang = tTarAward.nWeiWang + nWinWW	
						tTarAward.nWaiJiao = tTarAward.nWaiJiao + nWinWJ	

					elseif nRounds == nMaxRounds then
						if tSrcMC.nBlood > tTarMC.nBlood then
							tSrcMC.bWin = true
							tTarMC.bWin = false
							self.m_tBattle.nSrcWins = self.m_tBattle.nSrcWins + 1
							tResGrid[k] = true
							nWin = 1

							tSrcMC.tAward = _MakeAward(true, nSrcCharID)
							tSrcAward.nWeiWang = tSrcAward.nWeiWang + nWinWW	
							tSrcAward.nWaiJiao = tSrcAward.nWaiJiao + nWinWJ	
							tSrcAward.nCSScore = tSrcAward.nCSScore + nWinScore

							tTarMC.tAward = _MakeAward(false, nTarCharID)
							tTarAward.nWeiWang = tTarAward.nWeiWang + nLostWW	
							tTarAward.nWaiJiao = tTarAward.nWaiJiao + nLostWJ	

						else
							tSrcMC.bWin = false
							tTarMC.bWin = true
							self.m_tBattle.nTarWins = self.m_tBattle.nTarWins + 1
							tResGrid[k] = true
							nWin = 2

							tSrcMC.tAward = _MakeAward(false, nSrcCharID)
							tSrcAward.nWeiWang = tSrcAward.nWeiWang + nLostWW	
							tSrcAward.nWaiJiao = tSrcAward.nWaiJiao + nLostWJ	
							tSrcAward.nCSScore = tSrcAward.nCSScore + nLostScore
							
							tTarMC.tAward = _MakeAward(true, nTarCharID)
							tTarAward.nWeiWang = tTarAward.nWeiWang + nWinWW	
							tTarAward.nWaiJiao = tTarAward.nWaiJiao + nWinWJ	

						end

					end

					--回合数据
					local tSrcConf = ctMingChenConf[tSrcMC.nMCID]
					local sSrcName = tSrcMC.sName or tSrcConf.sName
					local tTarConf = ctMingChenConf[tTarMC.nMCID]
					local sTarName = tTarMC.sName or tTarConf.sName
					local tRound = {nGrid=k,
						nSrcID=tSrcMC.nMCID, nTarID=tTarMC.nMCID,
						sSrcName=sSrcName, sTarName=sTarName,
						nSrcBlood=nOrgSrcBlood, nTarBlood=nOrgTarBlood,
						nSrcBloodRemain=tSrcMC.nBlood, nTarBloodRemain=tTarMC.nBlood,
						bSrcSkill=bSrcSkill, bTarSkill=bTarSkill, nWin=nWin,
						nSrcSkLv=tSrcMC.tSkLv[nGroup], nTarSkLv=tTarMC.tSkLv[nGroup],
						nSrcMCLv=tSrcMC.nLv, nTarMCLv=tTarMC.nLv,
						nSrcAttr=tSrcMC.tAttr[nGroup], nTarAttr=tTarMC.tAttr[nGroup],
					}
					table.insert(tRounds[nRounds].tBattle, tRound)
				end

			elseif tSrcMC then
			 	if not tResGrid[k] then
					tSrcMC.bWin = true
					tSrcMC.tAward = _MakeAward(true, nSrcCharID)
					self.m_tBattle.nSrcWins = self.m_tBattle.nSrcWins + 1
					tResGrid[k] = true

					tSrcAward.nWeiWang = tSrcAward.nWeiWang + nWinWW	
					tSrcAward.nWaiJiao = tSrcAward.nWaiJiao + nWinWJ	
					tSrcAward.nCSScore = tSrcAward.nCSScore + nWinScore
					
					tTarAward.nWeiWang = tTarAward.nWeiWang + nLostWW	
					tTarAward.nWaiJiao = tTarAward.nWaiJiao + nLostWJ	

					--回合数据
					local tSrcConf = ctMingChenConf[tSrcMC.nMCID]
					local sSrcName = tSrcMC.sName or tSrcConf.sName
					local tRound = {nGrid=k,
						nSrcID=tSrcMC.nMCID, nTarID=0,
						sSrcName=sSrcName, sTarName="",
						nSrcBlood=tSrcMC.nBlood, nTarBlood=0,
						nSrcBloodRemain=tSrcMC.nBlood, nTarBloodRemain=0,
						bSrcSkill=false, bTarSkill=false, nWin=1,
						nSrcSkLv=tSrcMC.tSkLv[nGroup], nSrcMCLv=tSrcMC.nLv,
						nSrcAttr=tSrcMC.tAttr[nGroup], nTarAttr=0,
					}
					table.insert(tRounds[nRounds].tBattle, tRound)
				end

			elseif tTarMC then
				if not tResGrid[k] then
					tTarMC.bWin = true
					tTarMC.tAward = _MakeAward(true, nTarCharID)
					self.m_tBattle.nTarWins = self.m_tBattle.nTarWins + 1
					tResGrid[k] = true

					tSrcAward.nWeiWang = tSrcAward.nWeiWang + nLostWW	
					tSrcAward.nWaiJiao = tSrcAward.nWaiJiao + nLostWJ	
					tSrcAward.nCSScore = tSrcAward.nCSScore + nLostScore
					
					tTarAward.nWeiWang = tTarAward.nWeiWang + nWinWW	
					tTarAward.nWaiJiao = tTarAward.nWaiJiao + nWinWJ	

					--回合数据
					local tTarConf = ctMingChenConf[tTarMC.nMCID]
					local sTarName = tTarMC.sName or tTarConf.sName
					local tRound = {nGrid=k,
						nSrcID=0, nTarID=tTarMC.nMCID,
						sSrcName="", sTarName=sTarName,
						nSrcBlood=0, nTarBlood=tTarMC.nBlood,
						nSrcBloodRemain=0, nTarBloodRemain=tTarMC.nBlood,
						bSrcSkill=false, bTarSkill=false, nWin=2,
						nTarSkLv=tTarMC.tSkLv[nGroup], nTarMCLv=tTarMC.nLv,
						nSrcAttr=0, nTarAttr=tTarMC.tAttr[nGroup]
					}
					table.insert(tRounds[nRounds].tBattle, tRound)
				end

			elseif not tResGrid[k] then
				tResGrid[k] = true
				-- self.m_tBattle.nTarWins = self.m_tBattle.nTarWins + 1

				-- tSrcAward.nWeiWang = tSrcAward.nWeiWang + nLostWW
				-- tSrcAward.nWaiJiao = tSrcAward.nWaiJiao + nLostWJ

				-- tTarAward.nWeiWang = tTarAward.nWeiWang + nWinWW
				-- tTarAward.nWaiJiao = tTarAward.nWaiJiao + nWinWJ

			end
		end

		local nResultCount = 0
		for k = 1, nMaxGroupMCs do
			if tResGrid[k] then
				nResultCount = nResultCount + 1
			end
		end
		if nResultCount >= nMaxGroupMCs then
			break
		end
	end

	--发送战斗过程
	local sSrcCharName = self.m_oPlayer:GetName()
	local nSrcWeiWang = self.m_oPlayer:GetWeiWang()

	local sTarCharName = ""
	local nTarWeiWang = 0
	if self.m_tBattle.bRobot then
		local tConf = ctJunJiChuRobotConf[nTarCharID]
		sTarCharName = tConf.sName
		nTarWeiWang = tConf.nWW
	else
		local oTarPlayer = goOfflineDataMgr:GetPlayer(nTarCharID)
		sTarCharName = oTarPlayer.m_sName
		nTarWeiWang = oTarPlayer.m_nWeiWang
	end

	local tBattleMsg = {nGroup=nGroup, sSrcCharName=sSrcCharName, nSrcWeiWang=nSrcWeiWang,
		sTarCharName=sTarCharName, nTarWeiWang=nTarWeiWang, tRounds=tRounds,
		nSrcWins=self.m_tBattle.nSrcWins, nTarWins=self.m_tBattle.nTarWins} 
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCBattleProcedureRet", tBattleMsg)
	-- print("JJCBattleProcedureRet***", tBattleMsg)

	--攻方全胜要确认是否乘胜追击
	if self.m_tBattle.nSrcWins < nMaxGroupMCs then
		self:BattleResult()
	end
end

--乘胜追击
function CJunJiChu:ExtraRobReq(bYes)
	local nCharID = self.m_oPlayer:GetCharID()
	if bYes then
		if self.m_tBattle.nSrcWins < nMaxGroupMCs then
			return self.m_oPlayer:Tips("没有5胜,不能乘胜追击")
		end
		self:BattleResult(bYes)
	else
		self:BattleResult()
	end
end

--取做好查看召见列表时间
function CJunJiChu:GetLastViewZJ()
	return self.m_nLastViewZJ
end

--添加召见
function CJunJiChu:AddZhaoJian(oTarPlayer, tZJInfo, nTarCharID)
	--召见小红点统计
	local function _CheckZJRedPoint(nLastViewZJ, tZJList, oTarPlayer, nTarCharID)
		local nCount = 0
		for k, v in ipairs(tZJList) do
			if v.nTime > nLastViewZJ then nCount = nCount + 1 end
		end
		if oTarPlayer then
			oTarPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eJJCZhaoJian, nCount)
		elseif nTarCharID > 0 then
		    CRedPoint:MarkRedPointOffline(nTarCharID, gtRPDef.eJJCZhaoJian, nCount)
		end
	end

	if oTarPlayer then
		local tZJRecord = oTarPlayer.m_oJunJiChu.m_tZaoJianRecord
		table.insert(tZJRecord, 1, tZJInfo)
		if #tZJRecord > nMaxRecords then
			table.remove(tZJRecord)
		end
		oTarPlayer.m_oJunJiChu:MarkDirty(true)
		_CheckZJRedPoint(oTarPlayer.m_oJunJiChu:GetLastViewZJ(), tZJRecord, oTarPlayer)
	else
	    local _, sDBName = self:GetType()
	    local sData = goDBMgr:GetSSDB("Player"):HGet(sDBName, nTarCharID)  
	    local tData = sData == "" and {} or cjson.decode(sData)

	    tData.m_tZaoJianRecord = tData.m_tZaoJianRecord or {}
	    table.insert(tData.m_tZaoJianRecord, 1, tZJInfo)
		if #tData.m_tZaoJianRecord > nMaxRecords then
			table.remove(tData.m_tZaoJianRecord)
		end
		tData.m_nLastViewZJ = tData.m_nLastViewZJ or (os.time()-1)

	    goDBMgr:GetSSDB("Player"):HSet(sDBName, nTarCharID, cjson.encode(tData))  
		_CheckZJRedPoint(tData.m_nLastViewZJ, tData.m_tZaoJianRecord, nil, nTarCharID)
	end
end

--手否仇人
function CJunJiChu:IsChouRen(nTarCharID)
	for _, tInfo in ipairs(self.m_tEnemyRecord) do
		if tInfo.nCharID == nTarCharID then
			return true
		end
	end
	return false
end

--添加仇恨
function CJunJiChu:AddChouHen(oTarPlayer, tEnemyInfo, nTarCharID)
	if oTarPlayer then
		local tEnemyRecord = oTarPlayer.m_oJunJiChu.m_tEnemyRecord
		table.insert(tEnemyRecord, 1, tEnemyInfo)
		if #tEnemyRecord > nMaxRecords then
			table.remove(tEnemyRecord)
		end
		oTarPlayer.m_oJunJiChu:MarkDirty(true)
		nTarCharID = oTarPlayer:GetCharID()
	else
	    local _, sDBName = self:GetType()
	    local sData = goDBMgr:GetSSDB("Player"):HGet(sDBName, nTarCharID)  
	    local tData = sData == "" and {} or cjson.decode(sData)
	    tData.m_tEnemyRecord = tData.m_tEnemyRecord or {}
	    table.insert(tData.m_tEnemyRecord, 1, tEnemyInfo)
		if #tData.m_tEnemyRecord > nMaxRecords then
			table.remove(tData.m_tEnemyRecord)
		end
	    goDBMgr:GetSSDB("Player"):HSet(sDBName, nTarCharID, cjson.encode(tData))  
	end

	--电视
	local sTarName = goOfflineDataMgr:GetName(nTarCharID)
	local sNotice = string.format(ctLang[7], tEnemyInfo.sCharName, sTarName)
	goTV:_TVSend(sNotice)	
end

--战斗结束
function CJunJiChu:BattleResult(bExtraRob)
	if not next(self.m_tBattle) or self.m_tBattle.bEnd then
		return
	end
	self.m_tBattle.bEnd = true
	self:MarkDirty(true)

	local nGroup = self.m_tBattle.nGroup
	local nSrcCharID = self.m_tBattle.nSrcCharID
	local nTarCharID = self.m_tBattle.nTarCharID
	
	goLogger:EventLog(gtEvent.eLZEnd, self.m_oPlayer, nTarCharID, self.m_tBattle.bRobot, self.m_tBattle.nGroup, bExtraRob, self.m_tBattle.nBattleType)

	--记录连胜
	local bSrcWin = false
	if self.m_tBattle.nSrcWins > self.m_tBattle.nTarWins then
		self.m_nWins = self.m_nWins + 1
		self.m_nLosts = 0
		bSrcWin = true
	else
		self.m_nLosts = self.m_nLosts + 1
		self.m_nWins = 0
	end
	self:MarkDirty(true)

	--发放奖励
	local tSrcAward = self.m_tBattle.tGlobalAward[nSrcCharID]
	local tTarAward = self.m_tBattle.tGlobalAward[nTarCharID]
	local nSrcTotalWW = tSrcAward.nWeiWang
	local nSrcTotalWJ = tSrcAward.nWaiJiao
	local nSrcScore = tSrcAward.nCSScore
	local nTarTotalWW = tTarAward.nWeiWang
	local nTarTotalWJ = tTarAward.nWaiJiao

	--发放积分奖励
	self:AddCSScore(nSrcScore, "论战结算")

	--离线知己奖励
	local tMCAward= {}
	--攻方知己列表
	local tSrcMCList = {}
	--召见信息
	local tZJInfo = {sCharName=self.m_oPlayer:GetName(), nGroup=nGroup, nTime=os.time(), nWaiJiao=0, nWeiWang=0,tMCList={}}

	local bRobot = self.m_tBattle.bRobot 
	local oTarPlayer = (not bRobot) and goPlayerMgr:GetPlayerByCharID(nTarCharID) or nil

	for k = 1, nMaxGroupMCs do
		local tSrcMC = self.m_tBattle[nSrcCharID][k]
		local tTarMC = self.m_tBattle[nTarCharID][k]
		if tSrcMC then
			local oMC = self.m_oPlayer.m_oMingChen:GetObj(tSrcMC.nMCID)
			oMC:AddZhanJi(tSrcMC.tAward.nScore, "论战结算")
			oMC:AddGrowPoint(nGroup, tSrcMC.tAward.nGrow, "论战结算")
			--0轮空; 1胜利; 2失败
			table.insert(tSrcMCList, {nGrid=tSrcMC.nGrid, nMCID=tSrcMC.nMCID,
				nScore=tSrcMC.tAward.nScore, nGrow=tSrcMC.tAward.nGrow, nWin=(tSrcMC.bWin and 1 or 2)})
		else
			table.insert(tSrcMCList, {nGrid=k, nMCID=0, nScore=0, nGrow=0, nWin=(tTarMC and 2 or 0)})
		end
		if tTarMC and not bRobot then
			if oTarPlayer then --在线
				local oMC = oTarPlayer.m_oMingChen:GetObj(tTarMC.nMCID)
				oMC:AddZhanJi(tTarMC.tAward.nScore, "论战结算")
				oMC:AddGrowPoint(nGroup, tTarMC.tAward.nGrow, "论战结算")
			else
				table.insert(tMCAward, {nGroup=nGroup, nMCID=tTarMC.nMCID, nScore=tTarMC.tAward.nScore, nGrow=tTarMC.tAward.nGrow})
			end
			table.insert(tZJInfo.tMCList, {nGrid=tTarMC.nGrid, nMCID=tTarMC.nMCID,
				nScore=tTarMC.tAward.nScore, nGrow=tTarMC.tAward.nGrow, bWin=tTarMC.bWin})
		end
	end

	--乘胜追击增加对外交点掠夺
	if bExtraRob then
		nSrcTotalWJ = nSrcTotalWJ + 0.15
		nTarTotalWJ = nTarTotalWJ - 0.15
	end

	--攻方威望
	local nSrcOrgWW = self.m_oPlayer:GetWeiWang()
	self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWeiWang, nSrcTotalWW, "论战结算")
	nSrcTotalWW = self.m_oPlayer:GetWeiWang() - nSrcOrgWW

	--守方威望
	if not bRobot then
		local nTarOrgWW = CPlayer:GetWeiWangAnyway(nTarCharID)
		CPlayer:AddWeiWangAnyway(nTarCharID, nTarTotalWW, "论战结算")
		nTarTotalWW = CPlayer:GetWeiWangAnyway(nTarCharID) - nTarOrgWW
		tZJInfo.nWeiWang = nTarTotalWW 
	end

	--守方知己离线奖励
	if not bRobot and not oTarPlayer then
	    local _, sDBName = self:GetType()
	    local sData = goDBMgr:GetSSDB("Player"):HGet(sDBName, nTarCharID)  
	    local tData = sData == "" and {} or cjson.decode(sData)
	    tData.m_tOfflineAward = tData.m_tOfflineAward or {}
	    table.insert(tData.m_tOfflineAward, tMCAward)
	    goDBMgr:GetSSDB("Player"):HSet(sDBName, nTarCharID, cjson.encode(tData))  
	end

	--外交点计算
	local nReferWJ = 0
	if bSrcWin then --攻方胜
		assert(nSrcTotalWJ >= 0, "数据错误")
		if bRobot then
			nReferWJ = ctJunJiChuRobotConf[nTarCharID].nWJ
		else
			nReferWJ = CPlayer:GetWaiJiaoAnyway(nTarCharID)
		end
		nReferWJ = math.floor(nSrcTotalWJ*nReferWJ)

		--攻方获得外交
		self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWaiJiao, nReferWJ, "论战结算")

		--守方非ROBOT扣除外交
		if not bRobot then
			CPlayer:AddWaiJiaoAnyway(nTarCharID, -nReferWJ, "论战结算")
			tZJInfo.nWaiJiao = -nReferWJ
		end

	else --守方胜
		assert(nTarTotalWJ >= 0, "数据错误")
		nReferWJ = math.floor(nTarTotalWJ*self.m_oPlayer:GetWaiJiao())

		--攻方扣除外交
		self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eWaiJiao, -nReferWJ, "论战结算")

		--守方非ROBOT获得外交
		if not bRobot then
			CPlayer:AddWaiJiaoAnyway(nTarCharID, nReferWJ, "论战结算")
			tZJInfo.nWaiJiao = nReferWJ
		end

	end

	--守方添加召见
	--召见的玩家昵称、商业/农业/政治/军事使节团、出使时间、信息内容、对阵信息
	--（外交点、名望增加的数值以及胜利用绿色显示，外交点、名望减少的数值以及失败用红色显示，玩家名用橘黄色显示）
	if not bRobot then
		CJunJiChu:AddZhaoJian(oTarPlayer, tZJInfo, nTarCharID)
	end

	--攻方是否变成仇人
	--显示仇人信息：昵称、进攻时间、进攻的使节团（商业、农业、政治、军事）、掠夺外交点的百分比。
	--若5连胜，显示选择乘胜追击还是手下留情以及（玩家名用橘黄色显示、手下留情绿色显示、乘胜追击红色显示）
	local nExtraRob = 0
	if bSrcWin then
		--乘胜追击判定
		if self.m_tBattle.nSrcWins >= nMaxGroupMCs then
			nExtraRob = bExtraRob and 1 or 2 --1乘胜追击; 2手下留情
		end
		--添加攻方到守方仇人列表
		if not bRobot and self.m_tBattle.nSrcWins >= 3 then
			local tEnemyInfo = {nCharID=nSrcCharID, sCharName=self.m_oPlayer:GetName(),
				nTime=os.time(), nGroup=nGroup, nTotalWJ=-nReferWJ, nSrcWins=self.m_tBattle.nSrcWins,
				nWeiWang=self.m_oPlayer:GetWeiWang(), nGuoLi=self.m_oPlayer:GetGuoLi(), nExtraRob=nExtraRob}
			CJunJiChu:AddChouHen(oTarPlayer, tEnemyInfo, nTarCharID)

			--从攻方仇恨列表中移除守方
			if self.m_tBattle.nBattleType > 0 then
				local tRemainEnemy = {}
				for _, tEnemyInfo in ipairs(self.m_tEnemyRecord) do
					if tEnemyInfo.nCharID ~= nTarCharID then
						table.insert(tRemainEnemy, tEnemyInfo)
					end
				end
				self.m_tEnemyRecord = tRemainEnemy
			end
		end
		self:MarkDirty(true)
	end

	--显示所有玩家的对战信息
	--只有进攻方全歼防守方5名知己且时间在5点~22点才显示挑战按钮
	local sTarCharName = ""
	if bRobot then
		sTarCharName = ctJunJiChuRobotConf[nTarCharID].sName
	else
		sTarCharName = goOfflineDataMgr:GetName(nTarCharID)
	end
	local tNoticeInfo = {nCharID=nSrcCharID, sCharName=self.m_oPlayer:GetName(),sTarCharName=sTarCharName
		,nTime=os.time(),nGroup=nGroup,nTotalWJ=math.floor(nSrcTotalWJ*100),nExtraRob=nExtraRob,nLostWW=0
		,bSrcWin=bSrcWin,nSrcMCs=(bSrcWin and self.m_tBattle.nSrcWins or self.m_tBattle.nTarWins)}
	goOfflineDataMgr.m_oJJCData:AddJJCNotice(tNoticeInfo)


	--如果是挑战且被掠夺威望超过30则去掉公告
	if nTarTotalWW < 0 and self.m_tBattle.nBattleType == self.tBattleType.eChallenge then
		goOfflineDataMgr.m_oJJCData:SubJJCNotice(self.m_tBattle.nNoticeID, math.abs(nTarTotalWW))
	end

	--每当被抓捕失去的威望值达到100，则通缉次数-1
	if nTarTotalWW < 0 and self.m_tBattle.nBattleType == self.tBattleType.eCatch then
		goOfflineDataMgr.m_oJJCData:SubTongJi(nTarCharID, math.abs(nTarTotalWW))

		--电视
		local sTarName = goOfflineDataMgr:GetName(nTarCharID)
		local sNotice = string.format(ctLang[8], self.m_oPlayer:GetName(), sTarName, nSrcTotalWW)
		goTV:_TVSend(sNotice)
	end

	--伪概率判定
	local tList = {}
	if bSrcWin then
		local tAward = self.m_oPlayer.m_oWGL:CheckAward(gtWGLDef.eJJC)
		if tAward[1] and tAward[1][1] > 0 then
			for _, tItem in ipairs(tAward) do
				self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "军机处伪概率")
				local tItem = {nType=tItem[1], nID=tItem[2], nNum=tItem[3]}
				table.insert(tList, tItem)
			end

			--电视
			local sNotice = string.format(ctLang[9], self.m_oPlayer:GetName())
			goTV:_TVSend(sNotice)
		end
	end

	--消息
	local tSrcMsg = {
		tMCList = tSrcMCList,
		nGroup = nGroup,
		nSrcTotalWW = nSrcTotalWW,
		nSrcTotalWJ = math.floor(nSrcTotalWJ*100),
		nSrcWJValue = bSrcWin and nReferWJ or -nReferWJ,
		nSrcCSScore = nSrcScore,
		tList = tList,
	}
	print("JJCBattleResultRet***", tSrcMsg.nSrcTotalWW, tSrcMsg.nSrcTotalWJ)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCBattleResultRet", tSrcMsg)
end

--召见列表请求
function CJunJiChu:ZJListReq()
	self.m_nLastViewZJ = os.time()
	self:MarkDirty(true)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCZhaoJianListRet", {tList=self.m_tZaoJianRecord})
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eJJCZhaoJian, 0)
end

--取仇恨列表
function CJunJiChu:CHListReq(nWinType)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCChouHenListRet", {tList=self.m_tEnemyRecord, nWinType=nWinType})
end

--取公告列表
function CJunJiChu:NoticeReq()
	local tList = {}
	local tRemainMap = {} --未过期的

	local bChange = false
	local tNoticeMap = goOfflineDataMgr.m_oJJCData:GetJJCNoticeMap()
	for nID, tNotice in pairs(tNoticeMap) do
		if os.time() - tNotice.nTime >= 3*24*3600 then --公告保留3公告保留3天
			bChange = true
		else
			local tInfo = {
				nID = tNotice.nID,
				nGroup = tNotice.nGroup,
				nCharID = tNotice.nCharID,
				sCharName = tNotice.sCharName,
				sTarCharName = tNotice.sTarCharName,
				nTotalWJ = tNotice.nTotalWJ,
				bSrcWin = tNotice.bSrcWin or false,
				nExtraRob = tNotice.nExtraRob,
				nSrcMCs = tNotice.nSrcMCs or 0,
				bChallenge = false,
				nTime = tNotice.nTime,
			}
			if tInfo.bSrcWin and tInfo.nSrcMCs >= nMaxGroupMCs and self:InValidTime() then
				tInfo.bChallenge = true
			end
			if #tList < nMaxRecords then	
				table.insert(tList, tInfo)
			end
			tRemainMap[nID] = tNotice
		end
	end
	if bChange then
		goOfflineDataMgr.m_oJJCData:SetJJCNoticeMap(tRemainMap)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCNoticeListRet", {tList=tList})
end

--攻打指定玩家(复仇/挑战/抓捕)
function CJunJiChu:AttackReq(nTarCharID, nTarGroup, nBattleType, nNoticeID)
	print("CJunJiChu:AttackReq***", nTarCharID, nTarGroup, nBattleType, nNoticeID, "***")
	if not self:IsOpen(true) then
		return
	end
	if self:IsInBattle() then
		return self.m_oPlayer:Tips("正在战斗中")
	end

	local tProp = ctJunJiChuEtcConf[1].tChallengeProp[1]
	if self.m_oPlayer:GetItemCount(tProp[1], tProp[2]) <= 0 then
		return self.m_oPlayer:Tips("挑战书不足")
	end

	if nBattleType == self.tBattleType.eCatch then
		if not goOfflineDataMgr.m_oJJCData:GetTongJi(nTarCharID) then
			return self.m_oPlayer:Tips("对方已不在通缉榜上")
		end
	elseif nBattleType == self.tBattleType.eChallenge then
		local tNotice = goOfflineDataMgr.m_oJJCData:GetJJCNotice(nNoticeID)
		if not tNotice then
			return self.m_oPlayer:Tips("对方已不在公告榜上")
		end
		if tNotice.bSrcWin and (tNotice.nSrcMCs or 0) < nMaxGroupMCs then
			return self.m_oPlayer:Tips("对方不可被挑战")
		end
		if not self:InValidTime() then
			return self.m_oPlayer:Tips("每天5点至22点才可挑战")
		end
	end

	local nSrcCharID = self.m_oPlayer:GetCharID()
	if nSrcCharID == nTarCharID then
		return self.m_oPlayer:Tips("不能打自己")
	end
	if not self:InValidTime() then
		return self.m_oPlayer:Tips("未到活动时间")
	end
	
	local tSrcGroupData = self:GetGroupData(nTarGroup)
	if #tSrcGroupData <= 0 then
		return self.m_oPlayer:Tips("请先设置使团")
	end

	local tTarGroupData
	local oTarPlayer = goPlayerMgr:GetPlayerByCharID(nTarCharID)
	if oTarPlayer then
	--在线
		-- if oTarPlayer.m_oJunJiChu:IsInBattle() then
		-- 	return self.m_oPlayer:Tips("对方正在战斗中，请稍后再试")
		-- end
		tTarGroupData = oTarPlayer.m_oJunJiChu:GetGroupData(nTarGroup)
	else
	--不在线
		tTarGroupData = goOfflineDataMgr.m_oJJCData:GetMCGroup(nTarCharID, nTarGroup)
	end
	assert(tTarGroupData, "数据错误")

	--构造战斗数据
	self:MakeBattleData(nTarGroup, nSrcCharID, tSrcGroupData, nTarCharID, tTarGroupData, nBattleType, nNoticeID)
	self:SendPrepare()
end

--是否正在战斗
function CJunJiChu:IsInBattle()
	if not self.m_tBattle.bEnd then
		return true
	end
end

--pvp
function CJunJiChu:OnPlayerBattle(nTarCharID, nTarGroup)
	local nSrcCharID = self.m_oPlayer:GetCharID()
	local tSrcGroupData = self:GetGroupData(nTarGroup)

	local tTarGroupData
	local oTarPlayer = goPlayerMgr:GetPlayerByCharID(nTarCharID)
	if oTarPlayer then
	--在线
		if oTarPlayer.m_oJunJiChu:IsInBattle() then
			return self.m_oPlayer:Tips("对方正在战斗中，请稍后再试")
		end
		tTarGroupData = oTarPlayer.m_oJunJiChu:GetGroupData(nTarGroup)
	else
	--不在线
		tTarGroupData = goOfflineDataMgr.m_oJJCData:GetMCGroup(nTarCharID, nTarGroup)
	end
	assert(tTarGroupData, "数据错误")
	--构造战斗数据
	self:MakeBattleData(nTarGroup, nSrcCharID, tSrcGroupData, nTarCharID, tTarGroupData, self.tBattleType.eSend)
end

--pve
function CJunJiChu:OnRobotBattle(nTarCharID, nTarGroup)
	local tConf = assert(ctJunJiChuRobotConf[nTarCharID], "机器人不存在:"..nTarCharID)
	local tTarMC = assert(tConf["tMC"..nTarGroup], "机器人知己不存在:"..nTarGroup)
	--攻方
	local nSrcCharID = self.m_oPlayer:GetCharID()
	local tSrcGroupData = self:GetGroupData(nTarGroup)

	--守方
	local tTarGroupData = {bRobot=true}
	for k = 1, nMaxGroupMCs do
		if tTarMC[k] and tTarMC[k][1] > 0 then
			local tData = {nGroup=nTarGroup, nGrid=k, nMCID=0, nBlood=0, tAttr={0,0,0,0}, tSkLv={0,0,0,0}, tSkQua={0,0,0,0}}
			tData.nMCID = tTarMC[k][1]
			local tMCConf = ctMingChenConf[tData.nMCID]
			tData.sName = tMCConf.sName
			tData.nLv = tConf.nLv
			tData.nBlood = tTarMC[k][2]
			tData.tAttr[nTarGroup] = tTarMC[k][3]
			tData.tSkLv[nTarGroup] = tTarMC[k][4]
			tData.tSkQua[nTarGroup] = tTarMC[k][5]
			table.insert(tTarGroupData, tData)
		end
	end
	
	--构造战斗数据
	self:MakeBattleData(nTarGroup, nSrcCharID, tSrcGroupData, nTarCharID, tTarGroupData, self.tBattleType.eSend)
end

--取通缉列表
function CJunJiChu:TongJiListReq()
	if not self:IsOpen(true) then
		return
	end
	local tList = {}
	for nCharID, tData in pairs(goOfflineDataMgr.m_oJJCData:GetTongJiMap()) do
		local tInfo = {}
		tInfo.nCharID = nCharID
		tInfo.sCharName = tData.sCharName
		tInfo.nTJTimes = tData.nTJTimes
		tInfo.nWWRank = tData.nWWRank
		tInfo.nGuoLi = tData.nGuoLi
		tInfo.nTime = tData.nTime
		tInfo.nLostWW = (CJunJiChu.nCanelTJNeedWW*tData.nTJTimes)-tData.nLostWW
		table.insert(tList, tInfo)
		if #tList >= nMaxRecords then
			break
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCTongJiListRet", {tList=tList})
end

--取排行通缉列表
function CJunJiChu:RankTongJiListReq()
	if not self:IsOpen(true) then
		return
	end
	local tList = {}
	local function _fnTraverse(nRank, nCharID, tData)
		local tInfo = {nRank=nRank, nCharID=nCharID, nWeiWang=tData[2], sCharName=goOfflineDataMgr:GetName(nCharID), nGuoLi=0}
		local tGLData = goRankingMgr.m_oGLRanking.m_oRanking:GetDataByKey(nCharID)
		if tGLData then tInfo.nGuoLi = tGLData[2] end
		table.insert(tList, tInfo)
	end
	goRankingMgr.m_oWWRanking.m_oRanking:Traverse(1, nMaxRecords, _fnTraverse)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JJCRankTongJiListRet", {tList=tList})
	print("RankTongJiListReq***", tList)
end

--通缉玩家请求
function CJunJiChu:TongJiPlayerReq(nTarCharID)
	if not self:IsOpen(true) then
		return
	end
	if nTarCharID == self.m_oPlayer:GetCharID() then
		return self.m_oPlayer:Tips("不能通缉自己")
	end
	local tProp = ctJunJiChuEtcConf[1].tTJProp[1]
	if self.m_oPlayer:GetItemCount(tProp[1], tProp[2]) <= 0 then
		return self.m_oPlayer:Tips("通缉令不足")
	end
	if not goOfflineDataMgr.m_oJJCData:HasMCGroup(nTarCharID) then
		return self.m_oPlayer:Tips("目标玩家没有使节团")
	end
	self.m_oPlayer:SubItem(tProp[1], tProp[2], tProp[3], "通缉玩家")
	local oOfflineData = goOfflineDataMgr:GetPlayer(nTarCharID)
	goOfflineDataMgr.m_oJJCData:AddTongJi(nTarCharID, oOfflineData.m_sName)
	self.m_oPlayer:Tips(string.format("通缉%s成功", oOfflineData:Get("m_sName")))
	--日志
	goLogger:EventLog(gtEvent.eTongJi, self.m_oPlayer, nTarCharID
		, goRankingMgr.m_oWWRanking:GetPlayerRank(nTarCharID), self:IsChouRen(nTarCharID))
end

--检测小红点
function CJunJiChu:CheckRedPoint()	
	if self:CanSend(false, true) then
		return self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eJJCSend, 1)
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eJJCSend, 0)
end

--1键任免实现
function CJunJiChu:DoOneKeyAddMC()
	--筛选出已经出战的知己
	local tOnGroupMCMap = {}
	for nGroup, tGroup in pairs(self.m_tGroupMap) do
		for k = 1, nMaxGroupMCs do
			if (tGroup[k] or 0) > 0 then
				tOnGroupMCMap[tGroup[k]] = true
			end
		end
	end
	--知己列表
	local tMCList = {}
	local tMCMap = self.m_oPlayer.m_oMingChen:GetMCMap()
	for nMCID, oMC in pairs(tMCMap) do
		if not tOnGroupMCMap[nMCID] then
			local tAttr = oMC:GetAttr()
			local tAttrList = {}
			for k = 1, 4 do table.insert(tAttrList, {k, tAttr[k]}) end --组,属性值
			table.sort(tAttrList, function(t1, t2) return t1[2] > t2[2] end) --按属性值排序
			table.insert(tMCList, {nMCID, tAttrList})
		end
	end
	if #tMCList <= 0 then
		return 0
	end
	--出战
	local nAllocCount = 0
	for _, tMC in ipairs(tMCList) do
		local nMCID, tAttrList  = tMC[1], tMC[2]
		for _, tGroupAttr in ipairs(tAttrList) do
			local bSuccess = false
			local nGroup, nAttr = tGroupAttr[1], tGroupAttr[2]
			local tGroup = self.m_tGroupMap[nGroup]
			for k = 1, nMaxGroupMCs do
				if self:IsGridOpen(k) and (tGroup[k] or 0) == 0 then
					tGroup[k] = nMCID
					bSuccess = true
					break
				end
			end
			--成功分配则跳出
			if bSuccess then
				nAllocCount = nAllocCount + 1
				break
			end
		end
	end
	--分配成功
	if nAllocCount > 0 then
		--标记已设置过使节团
		self:MarkMCGroup()
		self:MarkDirty(true)
	end
	return nAllocCount
end

--1键任免请求
function CJunJiChu:OneKeyAddMCReq()
	if self:DoOneKeyAddMC() > 0 then
		self:SyncInfo()
	else
		self.m_oPlayer:Tips("没有可出战的知己")
	end
end

--GM重置军机处次数
function CJunJiChu:GMReset()
	self.m_nSendTimes = 0
	self:AddTimes(nMaxRecoverTimes, "GM")
	self.m_oPlayer:Tips("重置军机处次数成功")
end

--GM设置目标
function CJunJiChu:GMSetEnemy(nCharID)
	self.m_nGMCharID = nCharID
end

