--微服私访
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nXunFangRecoverTime = ctWFSFEtcConf[1].nXunFangRecoverTime  --寻访恢复所需的时间为2小时
function CWeiFuSiFang:Ctor(oPlayer)
	self.m_oPlayer = oPlayer 
	self.m_nCurrTiLi = self:MaxTiLi()     		--当前体力
	self.m_nLastTiLiRecoverTime = os.time() 	--上次体力恢复时间
	self.m_nFirstOnlineTime = 0 				--第1次上线
	self.m_tEvent = {}			                --事件{nID, nType, nHaoGan}
	self.m_tHaoGan = {} 				 	 	--未入宫的知己好感度

	--不保存
	self.m_nRecoverTick = nil              		--体力回复定时器
end

function CWeiFuSiFang:LoadData(tData)
	if tData then 
		local nTimeNow = os.time()
		self.m_nCurrTiLi = tData.m_nCurrTiLi or self.m_nCurrTiLi
		self.m_nFirstOnlineTime = tData.m_nFirstOnlineTime or nTimeNow
		self.m_nLastTiLiRecoverTime = math.min(nTimeNow, tData.m_nLastTiLiRecoverTime or nTimeNow)

		--事件
		self.m_tEvent = tData.m_tEvent or {}
		self.m_tHaoGan = tData.m_tHaoGan or {}
	else
		self:MarkDirty(true) --要保存出初数据(新号)
	end
end

function CWeiFuSiFang:SaveData()
	if not self:IsDirty() then
		return 
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nCurrTiLi = self.m_nCurrTiLi
	tData.m_nFirstOnlineTime = self.m_nFirstOnlineTime
	tData.m_nLastTiLiRecoverTime = self.m_nLastTiLiRecoverTime

	--事件
	tData.m_tEvent = self.m_tEvent
	tData.m_tHaoGan = self.m_tHaoGan
	return tData
end

function CWeiFuSiFang:GetType()
	return gtModuleDef.tWeiFuSiFang.nID, gtModuleDef.tWeiFuSiFang.sName
end

function CWeiFuSiFang:Online()
	self:CheckRecover()
	self:InfoReq()
end

function CWeiFuSiFang:Offline()
	goTimerMgr:Clear(self.m_nRecoverTick)
	self.m_nRecoverTick = nil
end

--体力上限
function CWeiFuSiFang:MaxTiLi()
	local nVIP = self.m_oPlayer:GetVIP()
	return ctVIPConf[nVIP].nMaxWFSF
end

--增/减寻访次数
function CWeiFuSiFang:AddTiLi(nVal, sReason)
	assert(nVal and sReason, "参数非法")
	local nXunFang = self.m_nCurrTiLi  
	self.m_nCurrTiLi = math.min(self:MaxTiLi(), math.max(0, self.m_nCurrTiLi+nVal))
	self:MarkDirty(true)

	if nXunFang ~= self.m_nCurrTiLi then
		local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
		goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eXunFang, nVal, self.m_nCurrTiLi)
		self:InfoReq()
	end
end

--注册计时器
function CWeiFuSiFang:CheckRecover()
	goTimerMgr:Clear(self.m_nRecoverTick)
	self.m_nRecoverTick = nil

	local nTimeSec = os.time()
	local nPassTime = nTimeSec - self.m_nLastTiLiRecoverTime
	local nTiLiAdd = math.floor(nPassTime/nXunFangRecoverTime)

	if nTiLiAdd > 0 then
		self.m_nLastTiLiRecoverTime = self.m_nLastTiLiRecoverTime + nTiLiAdd * nXunFangRecoverTime
		self:MarkDirty(true)
		self:AddTiLi(nTiLiAdd, "定时恢复")
	end

	local nRateTime = self.m_nLastTiLiRecoverTime + nXunFangRecoverTime - os.time()
	assert(nRateTime > 0)
	self.m_nRecoverTick = goTimerMgr:Interval(nRateTime, function() self:CheckRecover() end)
end

--取下次寻访恢复剩余时间
function CWeiFuSiFang:GetTiLiRecoverTime()
	local nRemainTimeSec = math.max(0, self.m_nLastTiLiRecoverTime+nXunFangRecoverTime-os.time())
	return nRemainTimeSec
end

--寻访处理
function CWeiFuSiFang:XunFangReq(bUseProp, nBuildID)  
	nBuildID = nBuildID or 0
	if not self:IsOpen(true) then 
		return
	end

	if bUseProp then
		local tXFProp = ctWFSFEtcConf[1].tXunFangProp[1]
		local nCurrCount = self.m_oPlayer:GetItemCount(tXFProp[1], tXFProp[2])
		if nCurrCount <= 0 then
			return self.m_oPlayer:Tips(string.format("%s不足", tXFProp[2]))
		end
		self.m_oPlayer:SubItem(tXFProp[1], tXFProp[2], 1, "寻访恢复")       --消耗体力丹
		local AddXunFang = self:MaxTiLi()                                   --满寻访次数
		self:AddTiLi(AddXunFang, "恢复满寻访体力")
		self.m_oPlayer:Tips("已恢复满体力")
		return 
	end
	
	if self.m_nCurrTiLi <= 0 then
		return self.m_oPlayer:Tips("体力不足")
	end

	if next(self.m_tEvent) then
		local bValid = true
		local nID = self.m_tEvent[1]
		local nType = self.m_tEvent[2]
		if nType == 1 or nType == 2 then
			if not ctWFSFBuildEventConf[nID] then
				bValid = false
				self.m_tEvent = {}
				self:MarkDirty(true)
			end
		else
			if not ctWFSFBlankEventConf[nID] then
				bValid = false
				self.m_tEvent = {}
				self:MarkDirty(true)
			end
		end
		if bValid then
			local tMsg = {
				nID=self.m_tEvent[1],
				nType=self.m_tEvent[2],
				bRuGong = self.m_tEvent[3],
				nQinMi=self.m_tEvent[4],
				nCurrHaoGan=self.m_tEvent[5],
				nNeedHaoGan=self.m_tEvent[6]
			}
			CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "XXunFangRet", tMsg)
			return
		end
	end

	local tMsg = nil
	--建筑事件
	if nBuildID > 0 then
		tMsg = self:BuildEvent(nBuildID)
	--空格事件
	else
		tMsg = self:BlankEvent()
	end

	if not tMsg then
		return self.m_oPlayer:Tips("参数错误")
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "XXunFangRet", tMsg)

	--任务
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond14, 1)
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond21, 1)
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond14, 1)
	--活动
	goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eXF, 1)
end	

--建筑物事件
function CWeiFuSiFang:BuildEvent(nBuildID)
	local nFlourish = self.m_oPlayer:GetFlourish()
	local tConf = goWFSFEventMgr:GetEvent(nBuildID, nFlourish)
	if not tConf then --没有激活的NPC，转空格事件
		return self:BlankEvent()
	end

	local nZJID, sZJName = 0, ""
	local bRuGong, nQinMi, nCurrHaoGan, nNeedHaoGan = false, 0, 0, 0
	if tConf.nType == 1 then  --知己事件
		nZJID = tonumber(tConf.sNPCID)
 		assert(ctMingChenConf[nZJID], "知己配置不存在"..nZJID)
 		local oZJ = self.m_oPlayer.m_oMingChen:GetObj(nZJID)
 		if oZJ then
 			bRuGong = true
 			nQinMi = oZJ:GetQinMi() 
 			nCurrHaoGan = oZJ:GetHaoGan()
 			sZJName = oZJ:GetName()
 		else
 			local tZJ = self.m_oPlayer.m_oMingChen:GetOutMCInfo(nZJID)
 			nQinMi = tZJ.nQinMi
 			nCurrHaoGan = self.m_tHaoGan[nZJID] or 0
 			sZJName = ctMingChenConf[nZJID].sName
 		end
		nNeedHaoGan = ctMingChenQinMiConf[math.min(#ctMingChenQinMiConf, nQinMi)].nHaoGan
	end

	local tInfo = {}
	tInfo.nID = tConf.nID 
	tInfo.nType = tConf.nType
	tInfo.nZJID = nZJID
	tInfo.sZJName = sZJName
	tInfo.bRuGong = bRuGong
	tInfo.nQinMi = nQinMi
	tInfo.nCurrHaoGan = nCurrHaoGan
	tInfo.nNeedHaoGan = nNeedHaoGan
	self.m_tEvent = {tConf.nID, tConf.nType, bRuGong, nQinMi, nCurrHaoGan, nNeedHaoGan}
	return tInfo
end

--寻访奖励
function CWeiFuSiFang:BuildEventAwardReq(nSelect)
	assert(nSelect == 1 or nSelect == 2, "选项错误")
	if not self:IsOpen(true) then 
		return
	end

	if self.m_nCurrTiLi <= 0 then
		return self.m_oPlayer:Tips("体力不足")
	end
	if not next(self.m_tEvent) then
		return self.m_oPlayer:Tips("当前没有事件")
	end
	self:AddTiLi(-1, "扣除体力次数")
 	
	local nID = self.m_tEvent[1]
	local nType = self.m_tEvent[2]
	local tConf = ctWFSFBuildEventConf[nID]
	assert(nType==1 or nType == 2, "类型有误")

	local tMsg = {nEventID=nID, nType=nType, nSelect=nSelect}
	if nType == 1 then  --知己事件
		local nZJID = tonumber(tConf.sNPCID)
 		local tItem = goWFSFEventMgr:GetItem(tConf.nBuildID, tConf.nID, nSelect)
 		local nRndTimes = tConf["nRandom"..nSelect]

 		local nHaoGan = 0
 		for k=1, nRndTimes do 
			nHaoGan = nHaoGan + tItem[4]
 		end

 		local nCurrQinMi, nCurrHaoGan = 0, 0
		local oZJ = self.m_oPlayer.m_oMingChen:GetObj(nZJID)
 		if oZJ then	--已入宫
 			oZJ:AddHaoGan(nHaoGan, "微服私访奖励")
 			self.m_tHaoGan[nZJID] = nil
 			nCurrQinMi = oZJ:GetQinMi() --当前亲密
 			nCurrHaoGan = oZJ:GetHaoGan() --当前好感

 		else --未入宫
 			local tZJ= self.m_oPlayer.m_oMingChen:GetOutMCInfo(nZJID)
 			self.m_tHaoGan[nZJID] = (self.m_tHaoGan[nZJID] or 0) + nHaoGan

 			nCurrQinMi = tZJ.nQinMi
	 		local nGotQM, n = 0, 1024
			while n > 0 do
	 			local nNeedHG = ctMingChenQinMiConf[math.min(#ctMingChenQinMiConf, nCurrQinMi)].nHaoGan
	 			if self.m_tHaoGan[nZJID] >= nNeedHG then 
	 				self.m_tHaoGan[nZJID] = self.m_tHaoGan[nZJID] - nNeedHG
	 				nCurrQinMi = nCurrQinMi + 1
	 				nGotQM = nGotQM + 1
	 			else
	 				break
	 			end
				n = n - 1	
	 		end
	 		nCurrHaoGan = self.m_tHaoGan[nZJID] --当前好感
	 		if nGotQM > 0 then 
				self.m_oPlayer.m_oMingChen:AddQinMi(nZJID, nGotQM, "微服私访奖励")
			end
 		end 
 		tMsg.nHaoGan = nHaoGan 			--获得好感
 		tMsg.nCurrQinMi = nCurrQinMi 	--当前亲密度
 		tMsg.nCurrHaoGan = nCurrHaoGan 	--当前好感
 		tMsg.nNeedHaoGan = ctMingChenQinMiConf[math.min(#ctMingChenQinMiConf, nCurrQinMi)].nHaoGan

	else --名士事件
		local nBuildID = tConf.nBuildID
		local nRndTimes = tConf["nRandom"..nSelect]
		local tList = {}
		for k=1, nRndTimes do 
			local tItem = goWFSFEventMgr:GetItem(nBuildID, nID, nSelect)
			table.insert(tList, tItem)
		end
		tMsg.tList = {} 
		for _, tItem in ipairs(tList) do
			self.m_oPlayer:AddItem(tItem[2], tItem[3], tItem[4], "寻访名士奖励")
			table.insert(tMsg.tList, {nType=tItem[2], nID=tItem[3], nNum=tItem[4]})
		end

	end
	self.m_tEvent = {}
 	self:MarkDirty(true)
 	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "XFBuildEventAwardRet", tMsg)
	self:InfoReq()
end 

--空格事件
function CWeiFuSiFang:BlankEvent()
	local nFlourish = self.m_oPlayer:GetFlourish()
	local tConf = goWFSFEventMgr:GetEvent(0, nFlourish)
	if not tConf then
		return self.m_oPlayer:Tips("随机事件失败，请提高繁荣度:"..nFlourish)
	end
	self.m_tEvent = {tConf.nID, tConf.nType}
	return {nID=tConf.nID, nType=tConf.nType}
end

--银两,文化,兵力奖励计算
function CWeiFuSiFang:CalcCoinAward()
	--奖励的银两、文化和兵力奖励=int（power（势力，0.25）*rand（800,1200））
	local nGuoLi = self.m_oPlayer:GetGuoLi()
	local nNum = math.floor((nGuoLi^0.25)*math.random(800,1200))
	return nNum
end

--空格事件奖励
function CWeiFuSiFang:BlankEventAwardReq(bBuy)
	if self.m_nCurrTiLi <= 0 then
		return self.m_oPlayer:Tips("体力次数不足")
	end
	if not next(self.m_tEvent) then
		return self.m_oPlayer:Tips("当前没有事件")
	end

	local nID, nType = self.m_tEvent[1], self.m_tEvent[2]
	assert(nType==3 or nType==4 or nType==5 or nType==6 or nType==7, "参数有误")
	
	self:AddTiLi(-1, "扣除体力次数")

	local tAward = {}
	local tConf = ctWFSFBlankEventConf[nID]
	local tItem = goWFSFEventMgr:GetItem(0, nID)
	if nType == 3 then 
		local nNum = self:CalcCoinAward()
		self.m_oPlayer:AddItem(tItem[2], tItem[3], nNum, "拾到银两")
		tAward = {nType=tItem[2], nID=tItem[3], nNum=nNum}

	elseif nType == 4 then 
		local nNum = self:CalcCoinAward()
		self.m_oPlayer:AddItem(tItem[2], tItem[3], nNum, "拾到文化")
		tAward = {nType=tItem[2], nID=tItem[3], nNum=nNum}
	
	elseif nType == 5 then 
		local nNum = self:CalcCoinAward()
		self.m_oPlayer:AddItem(tItem[2], tItem[3], nNum, "拾到兵力")
		tAward = {nType=tItem[2], nID=tItem[3], nNum=nNum}
	
	elseif nType == 6 then
		self.m_oPlayer:AddItem(tItem[2], tItem[3], tItem[4], "拾到物品")
		tAward = {nType=tItem[2], nID=tItem[3], nNum=tItem[4]}
	
	else
		if bBuy then 
			local nYuanBao = tConf.nPrice
			if self.m_oPlayer:GetYuanBao() >= nYuanBao then 
				self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, "微服私访买商品")
				self.m_oPlayer:AddItem(tItem[2], tItem[3], tItem[4], "微服私访买商品")
				tAward = {nType=tItem[2], nID=tItem[3], nNum=tItem[4]}
			else
				return self.m_oPlayer:YBDlg()
			end
		else
			return 
		end
	end
	self.m_tEvent = {}
	self:MarkDirty(true)
 	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "XFBlankEventAwardRet", tAward)
	self:InfoReq()
end

--寻宝处理
function CWeiFuSiFang:XunBaoReq()
	if not self:IsOpen(true) then 
		return
	end

	local tXBProp = ctWFSFEtcConf[1].tXunBaoProp[1]
	local nBaoTuCount = self.m_oPlayer:GetItemCount(tXBProp[1], tXBProp[2])
	if nBaoTuCount <= 0 then
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tXBProp[2])))
	end
	self.m_oPlayer:SubItem(tXBProp[1], tXBProp[2], 1, "扣除藏宝图")
	self:MarkDirty(true)
	
	--伪概率判定
	local tList = self.m_oPlayer.m_oWGL:CheckAward(gtWGLDef.eXB)
	if #tList > 0 and tList[1][1] > 0 then 
		for _, tAward in ipairs(tList) do 
			self.m_oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "微服私访寻宝伪概率")
		end
	else
		if self.m_nFirstOnlineTime == 0 then 
			self.m_nFirstOnlineTime = os.time()
			self:MarkDirty(true)
			local tFirstList = goWFSFDropMgr:GetItem(0)
			table.insert(tList, {tFirstList[1], tFirstList[2], tFirstList[3]})
			self.m_oPlayer:AddItem(tFirstList[1], tFirstList[2], tFirstList[3], "首次寻宝")
		else
			local tConf = ctWFSFEtcConf[1]
			local nYLPercent = tConf.nYLPercent
			local nRnd = math.random(1, 100)
			if nRnd <= nYLPercent then
				local nNum = self:CalcCoinAward()
				table.insert(tList, {gtItemType.eCurr, 10002, nNum})
				self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYinLiang, nNum, "寻宝奖励银两")
			else
				local tItem = goWFSFDropMgr:GetItem(1)
				table.insert(tList, tItem)
				self.m_oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "使用藏宝图获得珍宝")
			end
		end
	end

	local tAward = {} 
	for _, tConf in ipairs(tList) do 
		table.insert(tAward, {nType=tConf[1], nID=tConf[2], nNum=tConf[3]})
	end
	local tMsg = {tAwardList=tAward}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "XXunBaoRet", tMsg)

	--添加奖励记录
	local tConf = {}
	local sText, nCount, sCont = "", 0, ""
	for _, tAward in ipairs(tList) do 
		tConf = ctPropConf[tAward[2]]
		sText = sText..(tConf.nType == gtPropType.eCurr and tConf.sName.."*"..tAward[3].." " or (tConf.nColor.."星"..tConf.sName).."*"..tAward[3].." ")
		
		--电视广告
		if tConf.nColor >= 3 then 
			sCont = sCont..tConf.nColor.."星珍宝"..tConf.sName.." "
			goTV:_TVSend(string.format(ctLang[12], self.m_oPlayer:GetName(), sCont))
		end
	end
	local sRecord = string.format(ctLang[20], self.m_oPlayer:GetName(), sText)
	goAwardRecordMgr:AddRecord(gtAwardRecordDef.eWeiFuSiFang, sRecord)

	--同步
	self:InfoReq()
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond22, 1)
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond17, 1)
	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eXB, 1)
end

--获取繁荣
function CWeiFuSiFang:GetFlourish()
	local nFlourish = self.m_oPlayer:GetFlourish()
	local nShiLi = self.m_oPlayer:GetGuoLi()
	local nNextFR = math.min(#ctWFSFFlourishConf, math.max(0, nFlourish+1))
	local nNextSL = ctWFSFFlourishConf[nNextFR].nSL
	return nFlourish, nShiLi, nNextSL
end

--显示界面
function CWeiFuSiFang:InfoReq()
	local bOpen = self:IsOpen()
	local tMsg = {bOpen=bOpen, nBTCount=0, nXFCount=0, nXFMaxCount=0, nRemainTimeSec=0}
	if not bOpen then	
	else
		local tXBProp = ctWFSFEtcConf[1].tXunBaoProp[1]
		local nBaoTuCount = self.m_oPlayer:GetItemCount(tXBProp[1], tXBProp[2])
		local nBTCount = nBaoTuCount
		local nXFCount = self.m_nCurrTiLi	
		local nXFMaxCount = self:MaxTiLi()
		local nRemainTimeSec = self:GetTiLiRecoverTime()
		local nFlourish, nShiLi, nNextSL = self:GetFlourish()
		tMsg = {bOpen=bOpen, 
			nBTCount=nBTCount, 
			nXFCount=nXFCount, 
			nXFMaxCount=nXFMaxCount, 
			nRemainTimeSec=nRemainTimeSec,
			nFlourish = nFlourish,
			nShiLi = nShiLi,
			nNextSL = nNextSL
		}
	end
	--奖励记录
	goAwardRecordMgr:AwardRecordReq(self.m_oPlayer, gtAwardRecordDef.eWeiFuSiFang)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "WFSFInfoRet", tMsg)
end

--开放条件
function CWeiFuSiFang:IsOpen(bTips)
	local nChapter = ctWFSFEtcConf[1].nChapter
	local bPass = self.m_oPlayer.m_oDup:IsChapterPass(nChapter)
	if not bPass and bTips then
		return self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
	end
	return bPass
end

--指定寻访建筑信息请求
function CWeiFuSiFang:SpecifyBuildInfoReq(nBuildID)
	local tNPCMap = {}
	local tList = {} --人物列表

	local tNPCList = goWFSFEventMgr:GetNPCList(nBuildID, self.m_oPlayer:GetFlourish())
	for _, tNPC in ipairs(tNPCList) do
		if not tNPCMap[tNPC.sNPCID] then
			tNPCMap[tNPC.sNPCID] = true

			local tEventConf = ctWFSFBuildEventConf[tNPC.nEventID]
			if tNPC.nEventType == 1 then --知己事件
				local nQinMi, sZJName = 0, ""
				local oZJ = self.m_oPlayer.m_oMingChen:GetObj(tonumber(tNPC.sNPCID))
				if oZJ then
					nQinMi = oZJ:GetQinMi()
					sZJName = oZJ:GetName()
				else
					local tZJ = self.m_oPlayer.m_oMingChen:GetOutMCInfo(tonumber(tNPC.sNPCID))
					nQinMi = tZJ.nQinMi
					sZJName = tZJ.sName
				end
				table.insert(tList, {
					nEventType=tNPC.nEventType,
					sNPCID=tNPC.sNPCID,
					sNPCName=tEventConf.sName,
					sNPCDesc=tEventConf.sNPCDesc,
					nQinMi=nQinMi,
					sZJName=sZJName,
				})

			elseif tNPC.nEventType == 2 then --NPC事件
				table.insert(tList, {
					nEventType=tNPC.nEventType,
					sNPCID=tNPC.sNPCID,
					sNPCName=tEventConf.sName,
					sNPCDesc=tEventConf.sNPCDesc,
				})
			end
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "XFSpecifyBuildInfoRet", {tList=tList})
end

--指定寻访请求
function CWeiFuSiFang:SpecifyXunFangReq(nBuildID)
	local tProp = ctWFSFEtcConf[1].tSXFProp[1]
	if self.m_oPlayer:GetItemCount(tProp[1], tProp[2]) < tProp[3] then
		return self.m_oPlayer:Tips(string.format("%s 不足", CGuoKu:PropName(tProp[2])))
	end
	self.m_oPlayer:SubItem(tProp[1], tProp[2], tProp[3], "指定寻访")
	self:XunFangReq(false, nBuildID)
end