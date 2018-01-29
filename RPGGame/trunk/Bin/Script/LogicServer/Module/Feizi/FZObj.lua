--已入宫妃子对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CFZObj:Ctor(oModule, oPlayer, nSysID, nQinMi)
	assert(nQinMi, "参数错误")
	self.m_oModule = oModule
	self.m_oPlayer = oPlayer

	local tConf = assert(ctFeiZiConf[nSysID])
	self.m_nSysID = nSysID 				--配置ID
	self.m_sName = tConf.sName 			--名字
	self.m_nQinMi = nQinMi 				--亲密度
	self.m_nFeiWei = 1 					--妃位
	self.m_nStar = 0 					--天赋星级(已废弃)
	self.m_nCaiDe = 0 					--才德
	self.m_tAttrAdd = {0,0,0,0} 		--属性加成(值)
	self.m_nNengLi = tConf.nInitNL 		--能力
	self.m_nChilds = 0 					--孩子数
	self.m_tGongNv = {} 				--宫女列表
	self.m_nLengGong = 0 				--在冷宫中:>0
	self.m_sDesc = "" 					--描述

	self.m_nOpenCardCD = 0 				--被翻牌冷却到时
	self.m_nQingAnReset = os.time() 	--请按次数重置时间

	self.m_nTalentLevel = 1 			--天赋等级(天赋效果)
	self.m_nCreateTime = os.time()

	self.m_nGongDou = 0	--宫斗力
end

function CFZObj:LoadData(tData)
	for sKey, xVal in pairs(tData) do
		if sKey == "m_nTalentLevel" then
			local tTalentsValue = ctFeiZiConf[self.m_nSysID].tTalentsValue
			self[sKey] = math.min(xVal, #tTalentsValue)
		else
			self[sKey] = xVal
		end
	end
end

function CFZObj:SaveData()
	local tData = {}
	tData.m_nSysID = self.m_nSysID
	tData.m_sName = self.m_sName
	tData.m_nQinMi = self.m_nQinMi
	tData.m_nFeiWei = self.m_nFeiWei
	tData.m_nStar = self.m_nStar
	tData.m_nCaiDe = self.m_nCaiDe
	tData.m_tAttrAdd = self.m_tAttrAdd
	tData.m_nNengLi = self.m_nNengLi
	tData.m_nChilds = self.m_nChilds
	tData.m_tGongNv = self.m_tGongNv
	tData.m_sDesc = self.m_sDesc
	tData.m_nLengGong = self.m_nLengGong

	tData.m_nQingAnReset = self.m_nQingAnReset
	tData.m_nOpenCardCD = self.m_nOpenCardCD
	tData.m_nTalentLevel = self.m_nTalentLevel

	tData.m_nGongDou = self.m_nGongDou
	return tData
end

function CFZObj:MarkDirty(bDirty)
	self.m_oModule:MarkDirty(bDirty)
end

--妃子基本信息
function CFZObj:GetInfo()
	local tInfo = {}
	tInfo.nSysID = self.m_nSysID
	tInfo.sName = self.m_sName
	tInfo.nQinMi = self.m_nQinMi
	tInfo.bRuGong = true
	tInfo.nStar = self.m_nTalentLevel
	tInfo.nNengLi = self.m_nNengLi
	tInfo.nChilds = self.m_nChilds
	tInfo.tGongNv = self.m_tGongNv
	tInfo.nCaiDe = self.m_nCaiDe
	tInfo.nFeiWei = self.m_nFeiWei
	tInfo.sDesc = self.m_sDesc
	tInfo.bLengGong = self.m_nLengGong > 0
	tInfo.nJSFCDEndTime = self:GetOpenCardCDEndTime()
	-- tInfo.nGongDou = self:GetGongDou() --同步妃子属性的时候重新计算宫斗 fix pd
	return tInfo
end

--妃子ID
function CFZObj:GetID() return self.m_nSysID end
--名字
function CFZObj:GetName() return self.m_sName end
--妃位
function CFZObj:FeiWei() return self.m_nFeiWei end
--取当前星级
function CFZObj:GetStar() return self.m_nStar end
--取亲密度
function CFZObj:GetQinMi() return self.m_nQinMi end
--取属性值加成(值)
function CFZObj:AttrAdd() return self.m_tAttrAdd end
--取宫斗力
function CFZObj:GetGongDou() return self.m_nGongDou end

--计算宫斗力: 妃子总能力*（1+（妃子亲密度/25）%）
function CFZObj:CalcGongDou()
	local nGongDou = math.floor(self.m_nNengLi*(1+(self.m_nQinMi/25)/100))
	if self.m_nGongDou ~= nGongDou then
		self.m_nGongDou = nGongDou
		self:MarkDirty(true)
	end
	return self.m_nGongDou
end

--增加亲密度
function CFZObj:AddQinMi(nVal, sReason)
	self.m_nQinMi = math.max(1, math.min(nMAX_INTEGER, self.m_nQinMi+nVal))
	self:MarkDirty(true)
	self:CalcGongDou()

	--同步
	self.m_oModule:SyncFeiZi(self.m_nSysID)
	--亲密度变化
	self.m_oModule:OnQinMiChange()
	
	--通过CPlayer:AddItem不需要在这里写LOG
	if sReason then
		local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
		goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eQinMi, nVal, self.m_nQinMi, self.m_nSysID)
	end

	--日志
	self:_FZLog()
	return self.m_nQinMi
end

--取属性加成(百分比)
function CFZObj:AttrPerAdd()
	local tConf = ctFeiZiConf[self.m_nSysID]
	local nAttrID = tConf.nTalents
	local nAttrVal = 0

	local tTalentsValue = tConf.tTalentsValue
	for k = 1, self.m_nTalentLevel do
		local tItem = tTalentsValue[k]
		nAttrVal = nAttrVal + tItem[2]
	end
	return nAttrID, nAttrVal
end

--妃子改名
function CFZObj:ModNameReq(sName, nType)
	assert(nType==1 or nType==2, "参数有误")
	if nType == 1 then 			--改名
		local nCostYB = 5 		--封号消耗5元宝
		if self.m_oPlayer:GetYuanBao() < nCostYB then 
			return self.m_oPlayer:YBDlg()
		end
		
		local nNameLen = string.len(sName)
		if nNameLen <= 0 or nNameLen > 4*3 then
			return self.m_oPlayer:Tips("名字长度非法:"..sName)
		end
		
		--非法字检测
	    if GF.HasBadWord(sName) then
	    	print("CFZObj:ModName名字含有非法字，操作失败:***", sName)
	        return self.m_oPlayer:Tips("名字含有非法字，操作失败:"..sName)
	    end
	    
	    if sName == self.m_sName then 
	    	return self.m_oPlayer:Tips("妃子封号未作出改变")
	    end
	    
		self.m_sName = sName
	    self.m_oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, -nCostYB, "妃子名修改")
		-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond38, 1)
		self.m_oPlayer:Tips("成功更改封号")

	elseif nType == 2 then			--恢复
		self.m_sName = ctFeiZiConf[self.m_nSysID].sName
		self.m_oPlayer:Tips("已恢复为默认封号")
		
	end 
	self:MarkDirty(true)
	self.m_oModule:SyncFeiZi(self.m_nSysID)
end

--妃子改描述
function CFZObj:ModDescReq(sDesc)
	sDesc = sDesc or ""
	local nNameLen = string.len(sDesc)
	assert(nNameLen >= 1 and nNameLen <= 180, "描述超长")
	self.m_sDesc = sDesc
	self:MarkDirty(true)
	self.m_oModule:SyncFeiZi(self.m_nSysID)
end

--提升天赋等级
function CFZObj:UpgradeStarReq()
	local tConf = ctFeiZiConf[self.m_nSysID]
	local tTalentsValue = tConf.tTalentsValue
	if self.m_nTalentLevel >= #tTalentsValue then
		return self.m_oPlayer:Tips("已达天赋等级上限")
	end

	local nMaxTLV = 1
	for k = #tTalentsValue, 1, -1 do
		if self.m_nQinMi >= tTalentsValue[k][1] then
			nMaxTLV = k
			break
		end
	end

	if self.m_nTalentLevel >= nMaxTLV then
		return self.m_oPlayer:Tips("亲密度不足")
	end

	self.m_nTalentLevel = self.m_nTalentLevel + 1
	self:MarkDirty(true)
	
	self.m_oModule:SyncFeiZi(self.m_nSysID)
	self.m_oPlayer.m_oMingChen:OnFZTalentChange()
	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond41, self.m_nSysID, 1)
	--电视
	local sNotice = string.format(ctLang[5], self.m_oPlayer:GetName(), self.m_sName)
	goTV:_TVSend(sNotice)	
	--日志
	self:_FZLog()
end

--宫女上限
function CFZObj:MaxGongNv()
	local tConf = assert(ctFeiWeiConf[self.m_nFeiWei])
	return tConf.nMaxGongNv
end

--修习
function CFZObj:LearnReq()
	if self.m_nFeiWei >= #ctFeiWeiConf then
		return self.m_oPlayer:Tips("皇后娘娘已经是最高位分了")
	end
	local tLearnProp = ctFeiZiEtcConf[1].tLearnProp[1]
	if self.m_oPlayer:GetItemCount(tLearnProp[1], tLearnProp[2]) < tLearnProp[3] then
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tLearnProp[2])))
	end
	self.m_oPlayer:AddItem(tLearnProp[1], tLearnProp[2], -tLearnProp[3], "妃子修习")
	self:AddCaiDe(tLearnProp[4], "妃子修习")
	self.m_oModule:SyncFeiZi(self.m_nSysID)
	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond25, 1)
end

--是否可以进封
function CFZObj:CanUpFeiWei(bTips)
	if self.m_nFeiWei >= #ctFeiWeiConf then
		if bTips then
			self.m_oPlayer:Tips("皇后娘娘已经是最高位分了")
		end
		return
	end
	local tConf = ctFeiWeiConf[self.m_nFeiWei]
	if self.m_nCaiDe < tConf.nNeed then
		if bTips then
			self.m_oPlayer:Tips("娘娘还需要修习获得更多才德") --需要更多才德
		end
		return 
	end
	local nCurrCount = self.m_oModule:FeiWeiCount(self.m_nFeiWei+1)
	if tConf.nLimit > 0 and nCurrCount >= tConf.nLimit then
		if bTips then
			self.m_oPlayer:Tips(string.format("皇上，%s人数已满了", tConf.sName))
		end
		return 
	end
	return true
end

--进封
function CFZObj:UpFeiWeiReq()
	if not self:CanUpFeiWei(true) then
		return
	end
	self.m_nFeiWei = self.m_nFeiWei + 1
	self:AddNengLi(tConf.nAdd, "妃子进封")
	self.m_oModule:CalcFeiWei()
	self:MarkDirty(true)
	self.m_oModule:SyncFeiZi(self.m_nSysID)
end

--那啥
function CFZObj:NaShaReq(nTimes, bUseProp)
	assert(nTimes == 1 or nTimes == 10, "次数错误")
	local tFiziConf = ctFeiZiConf[self.m_nSysID]
	--元宝检测
	local tBaseCost = ctFeiZiEtcConf[1].tNaShaCost[1]
	local nCost = 0
	if nTimes == 1 then
		nCost = math.min(self.m_nQinMi*10, 800)
	else
		nCost = math.min(self.m_nQinMi*100+450, 800)
	end
	if self.m_oPlayer:GetYuanBao() < nCost then
		return self.m_oPlayer:YBDlg()
	end
	--扣除元宝
	self.m_oPlayer:SubItem(tBaseCost[1], tBaseCost[2], nCost, "妃子那啥")
	--增加亲密度
	self:AddQinMi(nTimes, "那啥获得")
	--增加属性	
	self.m_tAttrAdd[tFiziConf.nTalents] = self.m_tAttrAdd[tFiziConf.nTalents] + self.m_nNengLi*nTimes
	self.m_oPlayer:UpdateGuoLi("妃子那啥") --更新国力
	self:MarkDirty(true)

	--检测生孩子
	local tProp = ctFeiZiEtcConf[1].tNaShaSzd[1]
	for k = 1, nTimes do
		--使用双丹
		if bUseProp then
			local nCount = self.m_oPlayer:GetItemCount(tProp[1], tProp[2])
			if nCount <= 0 then bUseProp = false end
		end
		local nChildRes = self:ChildCheck(bUseProp)
		if nChildRes == 0 then
			if bUseProp then
				self.m_oPlayer:SubItem(tProp[1], tProp[2], 1, "那啥消耗")
				--活动(消耗双子丹数)
			    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eSZD, 1)
			end
		elseif nChildRes == -2 then --宗人府满
			break
		end
	end

	--同步信息
	self.m_oModule:SyncFeiZi(self.m_nSysID)
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FZNaShaRet", {nQinMi=nTimes, nShiLi=0, nAttrID=tFiziConf.nTalents, nAttrVal=self.m_nNengLi*nTimes})

	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond7, nTimes)
end

--检测生孩子
function CFZObj:ChildCheck(bUseProp)
	--宗人府检测
	local nVIP = self.m_oPlayer:GetVIP()
	local nVIPRate = ctVIPConf[nVIP].nHZRate
	local nRate = (0.5 + nVIPRate) * 100
	local nRnd = math.random(1, 100) 

	--第1次肯定生孩子(新手引导)
	if self.m_oPlayer.m_oZongRenFu:GetChildNum() == 0 then
		nRate = 100
	end

	if nRnd <= nRate then
		local nFreeGrid = self.m_oPlayer.m_oZongRenFu:GetFreeGrid()
		if nFreeGrid <= 0 then
			self.m_oPlayer:Tips("宗人府已满,无法生更多孩子")
			return -2
		end
		local nChildNum = bUseProp and 2 or 1
		local nChildSex1 = math.random(1, 2)
		if nChildNum == 1 then
			self.m_oPlayer.m_oZongRenFu:Create(self.m_nSysID, nChildSex1)	

		elseif nChildNum == 2 then
			local nChildSex2 = math.random(1, 2)
			self.m_oPlayer.m_oZongRenFu:CreateDouble(self.m_nSysID, nChildSex1, nChildSex2)	
			
		end

		self.m_nChilds = self.m_nChilds + nChildNum
		self:MarkDirty(true)
		--日志
		self:_FZLog()
		return 0
	end
	return -1
end

--赏赐珍宝
function CFZObj:GiveTreasureReq(nPropID, nPropNum)
	assert(nPropNum > 0)
	local tConf = assert(ctPropConf[nPropID], "道具不存在")
	assert(tConf.nDetType == gtDetType.eFZZhenBao1 or tConf.nDetType == gtDetType.eFZZhenBao2, "非珍宝道具")
	local nPackNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, nPropID)
	if nPropNum > nPackNum then
		return self.m_oPlayer:Tips("珍宝不足") --珍宝不足
	end
	self.m_oPlayer:SubItem(gtItemType.eProp, nPropID, nPropNum, "妃子赏赐珍宝")

	local nAddName = ""
	local nAddVal = tConf.nVal * nPropNum
	if tConf.nDetType == gtDetType.eFZZhenBao1 then --衣服
		nAddName = "亲密度"
		self:AddQinMi(nAddVal, "妃子赏赐珍宝")
	else --饰品
		nAddName = "能力"
		self:AddNengLi(nAddVal, "妃子赏赐珍宝")
	end
	self:MarkDirty(true)
	self.m_oPlayer:Tips(string.format("使用%s，%s %s+%d", tConf.sName, self.m_sName, nAddName, nAddVal))
	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond24, 1)
end

--请安
function CFZObj:QingAn(nYF, nZhuFu) --nZhuFu(神迹祝福倍数)
	--获得的势力值 = （妃子起始能力值*3 + （妃子能力值/10）*（1+（亲密度/1）%））*（1+羁绊平均加成%）
	assert(nYF >= 0, "缘分错误")
	nZhuFu = nZhuFu or 1

	local tYFConf = ctYuanFenConf[nYF]
	local nYuanFenAdd = tYFConf and tYFConf.nAddPer or 0
	local tFZConf = ctFeiZiConf[self.m_nSysID]

	local nShiLi = math.floor((tFZConf.nInitNL*3+(self.m_nNengLi/10)*(1+self.m_nQinMi/100))*(1+nYuanFenAdd))*nZhuFu
	local tProp = ctFeiZiEtcConf[1].tQingAnShiLi[1]
	self.m_oPlayer:AddItem(tProp[1], tProp[2], nShiLi, "妃子请安")
	self:MarkDirty(true)
	return {nID=self.m_nSysID, nShiLi=nShiLi}
end

--是否在冷宫
function CFZObj:IsInLengGong() return self.m_nLengGong > 0 end
--取放入冷宫时间
function CFZObj:LengGongTime() return self.m_nLengGong end

--设置是否放入冷宫
function CFZObj:SetLengGong(bLengGong)
	if (self.m_nLengGong > 0) == bLengGong then
		return
	end
	self.m_nLengGong = bLengGong and os.time() or 0
	self:MarkDirty(true)

	self.m_oModule:OnLengGongChange(bLengGong)
	self.m_oModule:SyncFeiZi(self.m_nSysID)
end

--是否可以被翻牌
function CFZObj:CanOpenCard()
	if self:IsInLengGong() then
		return
	end
	--翻牌冷却
	if os.time() < self.m_nOpenCardCD then
		return 
	end
	return true
end

--取翻牌冷却结束的时间戳
function CFZObj:GetOpenCardCDEndTime()
	if self:CanOpenCard() then
		return 0
	end
	if self:IsInLengGong() then
		return 0
	end
	return self.m_nOpenCardCD
end

--设置被翻牌时间
function CFZObj:OnOpenCard()
	self.m_nOpenCardCD = nMAX_INTEGER
	self.m_oModule:SyncFeiZi(self.m_nSysID)
	self:MarkDirty(true)
end

--翻牌完成生孩子事件
function CFZObj:OnOpenCardFinish(bChild)
	local nCDTime = 0
	local nQinMi = self:GetQinMi()
	for k = #ctJingShiFangChildConf, 1, -1  do
		local tConf = ctJingShiFangChildConf[k]
		if nQinMi >= tConf.nQinMi then
			nCDTime = bChild and tConf.nChildCD*60 or tConf.nNoChildCD*60
			break
		end
	end
	self.m_nOpenCardCD = os.time() + nCDTime
	self.m_oModule:SyncFeiZi(self.m_nSysID)
	self:MarkDirty(true)
end

--取才德
function CFZObj:GetCaiDe() return self.m_nCaiDe end
--取能力值
function CFZObj:GetNengLi() return self.m_nNengLi end

--增加能力
function CFZObj:AddNengLi(nVal, sReason)
	self.m_nNengLi = math.max(1, math.min(nMAX_INTEGER, self.m_nNengLi+nVal))
	self:CalcGongDou()
	self:MarkDirty(true)

	self.m_oModule:OnNengLiChange()
	self.m_oModule:SyncFeiZi(self.m_nSysID)

	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eRandNengLi, nVal, self.m_nNengLi, self.m_nSysID)

	--日志
	self:_FZLog()
	return self.m_nNengLi
end

--增加才德
function CFZObj:AddCaiDe(nVal, sReason)
	self.m_nCaiDe = math.max(1, math.min(nMAX_INTEGER, self.m_nCaiDe+nVal))
	self.m_oModule:SyncFeiZi(self.m_nSysID)
	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eCaiDe, nVal, self.m_nCaiDe, self.m_nSysID)
	self:MarkDirty(true)
	self.m_oModule:OnCaiDeChange()
	return self.m_nCaiDe
end

--取宫女列表
function CFZObj:GetGongNvList() return self.m_tGongNv end

--是否可以侍奉
function CFZObj:CanShiFeng(nGNID)
	local tGNConf = ctGongNvConf[nGNID]
	local tFWConf = ctFeiWeiConf[self.m_nFeiWei]
	local nMaxGongNv = tFWConf.nMaxGongNv
	local nExchangeIndex = 0
	if #self.m_tGongNv >= nMaxGongNv then
		local function fnDesc(nGN1, nGN2)
			local tGNConf1 = ctGongNvConf[nGN1]
			local tGNConf2 = ctGongNvConf[nGN2]
			return tGNConf1.nPj > tGNConf2.nPj
		end
		table.sort(self.m_tGongNv, fnDesc)
		local nLastID = self.m_tGongNv[#self.m_tGongNv]
		local tTmpConf = ctGongNvConf[nLastID]
		if tTmpConf.nPj > tGNConf.nPj then
			return
		end
		nExchangeIndex = #self.m_tGongNv
	end
	return true, nExchangeIndex
end

--侍奉妃子
function CFZObj:ShiFeng(nGNID)
	local bRes, nExchangeIndex = self:CanShiFeng(nGNID)
	if not bRes then
		return
	end
	local nOrgGNID = 0
	if nExchangeIndex == 0 then
		table.insert(self.m_tGongNv, nGNID)
	else
		nOrgGNID = self.m_tGongNv[nExchangeIndex]
		self.m_tGongNv[nExchangeIndex]= nGNID

		local tOrgGNConf = ctGongNvConf[nOrgGNID]
		self:AddNengLi(-tOrgGNConf.nPower, "侍奉替换宫女")
	end
	local tGNConf = ctGongNvConf[nGNID]
	self:AddNengLi(tGNConf.nPower, "侍奉获得")
	self.m_oModule:SyncFeiZi(self.m_nSysID)
	self:MarkDirty(true)

	self.m_oPlayer:Tips(string.format("%s 能力+%d", self.m_sName, tGNConf.nPower))
	if nOrgGNID > 0 then
		self.m_oPlayer:AddItem(gtItemType.eGongNv, nOrgGNID, 1, "侍奉替换宫女")
	end
	--日志
	self:_FZLog()
	return true
end

--日志
function CFZObj:_FZLog()
	goLogger:EventLog(gtEvent.eFZAttr, self.m_oPlayer, self.m_nSysID
		, self.m_nQinMi, self.m_nNengLi, self.m_nTalentLevel, #self.m_tGongNv, self.m_nChilds)
end
