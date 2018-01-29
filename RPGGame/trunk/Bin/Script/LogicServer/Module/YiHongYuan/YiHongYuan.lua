--怡红院
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CYiHongYuan:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self:Init()
end

function CYiHongYuan:Init()
	self.m_nCountTimes = ctYHYEtcConf[1].nMaxTimes  --抽奖次数
	self.m_nCJTime = 0				--抽奖时间
	self.m_nResetTime = os.time()	--重置抽奖时间
	--不保存
	self.m_tAward = {0,0,0,0}		--奖励
end

function CYiHongYuan:LoadData(tData)
	if tData then 
		self.m_nResetTime = tData.m_nResetTime 
		self.m_nCountTimes = tData.m_nCountTimes
		self.m_nCJTime = tData.m_nCJTime
	else
		self:MarkDirty(true)
	end
end

function CYiHongYuan:SaveData()
	if not self:IsDirty() then
		return 
	end
	self:MarkDirty(false)
	local tData = {}
	tData.m_nResetTime = self.m_nResetTime
	tData.m_nCountTimes = self.m_nCountTimes
	tData.m_nCJTime = self.m_nCJTime
	return tData
end

function CYiHongYuan:GetType()
	return gtModuleDef.tYiHongYuan.nID, gtModuleDef.tYiHongYuan.sName
end

function CYiHongYuan:Online()
	self:InfoReq()
end

--重置抽奖
function CYiHongYuan:CheckSameDay()
	if not os.IsSameDay(os.time(), self.m_nResetTime, 5*3600) then
		self:Init()
		self:MarkDirty(true)
	end
end

--随机性格美女
function CYiHongYuan:RandomPerson()
	local nPersonality1 = math.random(#ctPersonalityConf)
	local nPerson1 = math.random(#ctGrilsConf)
	local nPersonality2 = math.random(#ctPersonalityConf)
	local nPerson2 = math.random(#ctGrilsConf)
	
	if nPerson1 == nPerson2 then
		return self:RandomPerson()
	else
		return nPersonality1, nPerson1, nPersonality2, nPerson2
	end
end

--抽奖冷却时间
function CYiHongYuan:CDTime()
	local nCDTime = ctYHYEtcConf[1].nCDTime
	local nRemainTime = math.max(0, self.m_nCJTime+nCDTime-os.time())
	return nRemainTime
end

--界面显示
function CYiHongYuan:InfoReq()
	local bOpen = self:IsOpen() 
	self:CheckSameDay()
	local tMsg = {nCountTimes=self.m_nCountTimes, nRemainTime=self:CDTime()}
	if bOpen then 
		if self.m_nCountTimes > 0 and self:CDTime() <= 0 then 
			local nPersonality1, nPerson1, nPersonality2, nPerson2 = self:RandomPerson()
			sPersonality1 = ctPersonalityConf[nPersonality1].sPersonality
			sName1 = ctGrilsConf[nPerson1].sName
			sPersonality2 = ctPersonalityConf[nPersonality2].sPersonality
			sName2 = ctGrilsConf[nPerson2].sName
			
			tMsg.sPersonality1 = sPersonality1
			tMsg.sName1 = sName1
			tMsg.sPersonality2 = sPersonality2 
			tMsg.sName2 = sName2
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "YHYInfoRet", tMsg)

	--奖励记录
	goAwardRecordMgr:AwardRecordReq(self.m_oPlayer, gtAwardRecordDef.eYiHongYuan)
end

--抽奖
function CYiHongYuan:ChouJiangReq(nSelect)
	if not self:IsOpen(true) then return end
	assert(nSelect==1 or nSelect==2, "选项有误")
	self:CheckSameDay()

	if self.m_nCountTimes <= 0 then
		return self.m_oPlayer:Tips("公子对姑娘们可还满意?")
	end 
	if self:CDTime() > 0 then
		return self.m_oPlayer:Tips("公子请等片刻，姑娘们正忙着打扮呢~")
	end

	--伪概率判定
	local tItem = self.m_oPlayer.m_oWGL:CheckAward(gtWGLDef.eYHY)
	local tConf = tItem[1]
	if tItem and #tItem > 0 and tConf[1] > 0 then
		local sAward = ""
		for _, tAward in ipairs(tItem) do 
			self.m_tAward = {tAward[1], tAward[2], tAward[3], 4}
			self.m_oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "怡红院伪概率")
			local tPropConf = ctPropConf[tAward[2]]
			sAward = sAward..tPropConf.sName.."*"..tAward[3].." "
		end

		--电视广告
		local sCont = string.format(ctLang[13], self.m_oPlayer:GetName(), sAward)
		goTV:_TVSend(sCont)
	else
		self.m_tAward = {}
		self.m_tAward = goYHYAwardMgr:GetItem()
		
		--不是宫女直接发奖励
		if self.m_tAward[1] ~= gtItemType.eGongNv then
			self.m_oPlayer:AddItem(self.m_tAward[1], self.m_tAward[2], self.m_tAward[3], "怡红院奖励")
		end
	end
	self.m_nCountTimes = self.m_nCountTimes - 1
	self.m_nCJTime = os.time()
	self:MarkDirty(true)

	local tMsg = {
		nType = self.m_tAward[1],
		nID = self.m_tAward[2],
		nNum = self.m_tAward[3],
		nIndex = self.m_tAward[4],
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "YHYChouJiangRet", tMsg)

	-- 添加奖励记录
	local sRecord = ""
	local nID = self.m_tAward[2]
	local tConf = ctPropConf[nID]
	local tShowType = ctYHYAwardConf[self.m_tAward[4]]
	local nShowType = tShowType.nShowType
	local nNum = self.m_tAward[3]
	if nShowType == 2 then 
		sRecord = string.format(ctLang[21], self.m_oPlayer:GetName(), tConf.sName.."*"..nNum)
	elseif nShowType == 1 then 
		sRecord = string.format(ctLang[22], self.m_oPlayer:GetName(), tConf.sName.."*"..nNum)
	end
	goAwardRecordMgr:AddRecord(gtAwardRecordDef.eYiHongYuan, sRecord)
	self:InfoReq()
	
	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond39, 1)
end

--购买宫女
function CYiHongYuan:BuyGongNvReq()
	if self.m_tAward[1] ~= gtItemType.eGongNv then
		return self.m_oPlayer:Tips("没有宫女可赎身")
	end

	local nYuanBaoCount = self.m_oPlayer:GetYuanBao()       			--获取玩家元宝数
	local nConsumption = ctYHYAwardConf[self.m_tAward[4]].nConsumption	--赎身消费所需的元宝
	if nYuanBaoCount < nConsumption then
		return self.m_oPlayer:YBDlg()
	end

	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nConsumption, "怡红院购买宫女")
	self.m_oPlayer:AddItem(self.m_tAward[1], self.m_tAward[2], self.m_tAward[3], "怡红院奖励")
		
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "YHYBuyGongNvRet", {nGNID=self.m_tAward[2]})

	--奖励记录
	local nID = self.m_tAward[2]
	local tConf = ctGongNvConf[nID]
	local nNum = self.m_tAward[3]
	local sRecord = string.format(ctLang[23], self.m_oPlayer:GetName(), tConf.sName.."*"..nNum)
	goAwardRecordMgr:AddRecord(gtAwardRecordDef.eYiHongYuan, sRecord)

	self.m_tAward = {0,0,0,0}
	self:InfoReq()
end

--加速请求
function CYiHongYuan:AddSpeedReq(nSpeed)
	--GM加速
	if nSpeed == 1 then 
		self.m_nCJTime = 0
		self:InfoReq()
		self:MarkDirty(true)
	end

	--使用回春露加速
	if self.m_nCountTimes == 0 then 
		return self.m_oPlayer:Tips("该回宫了")
	end
	local tProp = ctYHYEtcConf[1].tProp[1]
	if self.m_oPlayer:GetItemCount(tProp[1], tProp[2]) < tProp[3] then 
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tProp[2])))
	else
		self.m_oPlayer:SubItem(gtItemType.eProp, tProp[2], tProp[3], "使用回春露")
		self.m_nCJTime = 0
		self:InfoReq()
		self:MarkDirty(true)
	end
end

--开放条件
function CYiHongYuan:IsOpen(bTips)
	local nDupID = ctYHYEtcConf[1].nDupID
	local bPass = self.m_oPlayer.m_oDup:IsDupPass(nDupID)
	if not bPass and bTips then
		return self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", ctCheckPointConf[nDupID].nChapter, CDup:DupName(nDupID)))
	end
	return bPass
end