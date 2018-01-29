--宠物对象
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--成长期
CHZObj.tStage = 
{
	eYingEr = 1, 	--婴儿
	eShaoNian = 2, 	--少年
	eChengNian = 3, --成年
}

function CHZObj:Ctor(oModule, oPlayer, nID, nFZID, nQinMi, nGender, nTalentLv)
	self.m_oModule = oModule
	self.m_oPlayer = oPlayer

	self.m_nID = nID 						--宠物自增ID
	self.m_nFZID = nFZID 					--母亲知己ID
	self.m_nQinMi = nQinMi 					--亲密度
	self.m_sName = "" 						--名字
	self.m_nGender = nGender 				--性别(1男; 2女)
	self.m_nTalentType = math.random(1, 4) 	--天赋类型
	self.m_nTalentLv = nTalentLv 			--天赋等级(宠物类型)

	local tConf = self.m_nGender == 1 and ctHZHeadImgConf or ctHZHeadImgConf
	self.m_sIcon = tConf[self.m_nTalentLv].sYEIcon

	self.m_nHuoLi = 0 						--宠物活力
	self.m_nJueWei = 0 						--爵位(宠物品级)
	self.m_nLastHuoLiRecoverTime = 0		--上1次活力恢复时间
	self.m_nGrowStartTime = os.time() 		--婴儿成长开始时间
	self.m_nStage = CHZObj.tStage.eYingEr 	--婴儿期
	self.m_nLv = 1 							--等级 
	self.m_nExp = 0 						--当前经验
	self.m_nLearnEff = 1 					--学习效率
	self.m_nLastExpRecoverTime = 0 			--上次获得经验时间
	self.m_tPeiOu = { 						--配偶
		nID=0, nGender=0, sName="",
		sIcon="", nFZID=0, tAttr={},
		nJueWei=0, nLv=0, nTalentLv=0,
		nCharID=0, sCharName="", nTime=0,
	}

	self.m_tAttr = {0, 0, 0, 0} 			--总属性
	self.m_tAttrAdj = {0, 0, 0, 0} 			--属性修正参数
	self.m_tLearnAttr = {0, 0, 0, 0} 		--学习随机加成
	self.m_tCaiLiAttr = {0, 0, 0, 0} 		--彩礼随机属性加成
	self.m_tCaiLiAttrPer = {0, 0, 0, 0} 	--彩礼百分比加成

	-- 4个修正项目，分别为X1，X2，X3和X4
	-- X1=RAND(4,6)/10*天赋等级修正
	-- X2=RAND(4,6)/10*天赋等级修正
	-- X3=RAND(4,6)/10*天赋等级修正
	-- X4=2*天赋等级修正-X1-X2-X3
	-- 其中天赋等级修正通过该宠物的天赋等级读表获取
	-- 随机打乱这四个修正值，分别填入商业修正、农业修正、政治修正和军事修正中
	local nTalentAdj = ctHZTalentConf[self.m_nTalentLv].nParamAdj
	local tX = {}
	tX[1] = math.random(4,6)/10*nTalentAdj
	tX[2] = math.random(4,6)/10*nTalentAdj
	tX[3] = math.random(4,6)/10*nTalentAdj
	tX[4] = 2*nTalentAdj-tX[1]-tX[2]-tX[3]
	assert(tX[1] >= 0 and tX[2] >= 0 and tX[3] >= 0 and tX[4] >= 0, "属性非法")
	for k = 1, 4 do
		local nIdx = math.random(1, #tX)
		self.m_tAttrAdj[k] = table.remove(tX, nIdx)
	end

	self.m_nCaiLiID = 0 --已选择的彩礼
	self.m_nCreateTime = os.time() --创建时间
end

function CHZObj:LoadData(tData)
	for k, v in pairs(tData) do
		if k == "m_tAttr" or k == "m_tAttrAdj" then
			for k1 = 1, 4 do v[k1] = math.max(0, v[k1]) end
		end
		self[k] = v
	end
	--修正BUG
	if self.m_nJueWei > 0 and self.m_nStage ~= CHZObj.tStage.eChengNian then
		self.m_nStage = CHZObj.tStage.eChengNian
		self:MarkDirty(true)
	end
	self.m_nQinMi = self.m_nQinMi or 0
end

function CHZObj:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_nFZID = self.m_nFZID
	tData.m_nQinMi = self.m_nQinMi
	tData.m_sName = self.m_sName
	tData.m_nGender = self.m_nGender
	tData.m_nTalentType = self.m_nTalentType
	tData.m_nTalentLv = self.m_nTalentLv
	tData.m_nJueWei = self.m_nJueWei
	tData.m_nLv = self.m_nLv
	tData.m_sIcon = self.m_sIcon
	tData.m_nHuoLi = self.m_nHuoLi
	tData.m_nLastHuoLiRecoverTime = self.m_nLastHuoLiRecoverTime
	tData.m_nStage = self.m_nStage
	tData.m_nGrowStartTime = self.m_nGrowStartTime
	tData.m_nLearnEff = self.m_nLearnEff
	tData.m_nLastExpRecoverTime = self.m_nLastExpRecoverTime
	tData.m_nExp = self.m_nExp
	tData.m_tPeiOu = self.m_tPeiOu

	tData.m_tAttr = self.m_tAttr
	tData.m_tAttrAdj = self.m_tAttrAdj
	tData.m_tLearnAttr = self.m_tLearnAttr
	tData.m_nCreateTime = self.m_nCreateTime
	tData.m_nCaiLiID = self.m_nCaiLiID
	tData.m_tCaiLiAttr = self.m_tCaiLiAttr
	tData.m_tCaiLiAttrPer = self.m_tCaiLiAttrPer
	return tData
end

function CHZObj:MarkDirty(bDirty)
	self.m_oModule:MarkDirty(bDirty)
end

function CHZObj:GetID() return self.m_nID end
function CHZObj:GetIcon() return self.m_sIcon end
function CHZObj:GetLv() return self.m_nLv end
function CHZObj:GetHuoLi() return self.m_nHuoLi end

--宠物改名
function CHZObj:ModName(sName)
	if self.m_nStage == CHZObj.tStage.eChengNian then
		return self.m_oPlayer:Tips("成年宠物不能改名")
	end
	local nNameLen = string.len(sName)
	if nNameLen <= 0 or nNameLen > 6*3 then
		return self.m_oPlayer:Tips("名字长度非法")
	end
    --非法字检测
    if GF.HasBadWord(sName) then
        return self.m_oPlayer:Tips("名字含有非法字，操作失败")
    end
	self.m_sName = sName
	self:MarkDirty(true)
	self:SyncInfo()

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond4, 1, nil, true)
	self.m_oPlayer:Tips("赐名成功")
end

--取宠物成长阶段和剩余时间
function CHZObj:CheckStage()
	if self.m_nStage == CHZObj.tStage.eYingEr then
		local nYingErTime = ctHZEtcConf[1].nYingErTime
		local nRemainTime = math.max(0, self.m_nGrowStartTime+nYingErTime-os.time())
		if nRemainTime <= 0 and self.m_sName ~= "" then
			--进入少年阶段
			self:OnStageChange(self.m_nStage, CHZObj.tStage.eShaoNian)
			self:MarkDirty(true)
		end
		return self.m_nStage, nRemainTime
	else
		return self.m_nStage, 0
	end
end

--成长阶段变化
function CHZObj:OnStageChange(nSrcStage, nTarStage)
	if nTarStage == CHZObj.tStage.eShaoNian then --少年
		--选择头像
		local tConf = self.m_nGender == 1 and ctHZHeadImgConf or ctHZHeadImgConf
		self.m_sIcon = tConf[self.m_nTalentLv].sSNIcon
		--开始恢复活力 
		self.m_nLastHuoLiRecoverTime = os.time()
		--开始经验增长
		self.m_nLastExpRecoverTime = os.time()
		self.m_nStage = nTarStage
		self:AddHuoLi(self:MaxHuoLi(), "进入少年期加满活力")

	elseif nTarStage == CHZObj.tStage.eChengNian then --成年
		--选择头像
		local tConf = self.m_nGender == 1 and ctHZHeadImgConf or ctHZHeadImgConf
		self.m_sIcon = tConf[self.m_nTalentLv].sCNIcon
		self.m_nStage = nTarStage

	else
		assert(false, "目标阶段错误")

	end
	self:MarkDirty(true)
end

--宠物加速成长操作
function CHZObj:SpeedGrowUp(nPropID, nPropNum)
	print("CHZObj:SpeedGrowUp***", nPropID, nPropNum)
	assert(nPropNum >= 0, "参数非法")
	local nState, nRemainTime = self:CheckStage()
	if self.m_nStage ~= CHZObj.tStage.eYingEr then
		return self.m_oPlayer:Tips("非婴儿阶段不能加速")
	end

	local sTips = ""
	local nSpeedUpTime = 0
	local tConf = assert(ctPropConf[nPropID], "道具配置不存在:"..nPropNum)
	if tConf.nType == gtPropType.eCurr then
		assert(tConf.nSubType == gtCurrType.eYuanBao, "货币道具非法:"..nPropID)
		nPropNum  = math.ceil(nRemainTime/(ctHZEtcConf[1].nMinPerYB*60))
		nSpeedUpTime = nRemainTime
		sTips = "宠物进入少年阶段"

	elseif tConf.nType == gtPropType.eTeShu then
		assert(tConf.nDetType == gtDetType.eHZJiaSu, "特殊道具非法:"..nPropID)
		nSpeedUpTime = tConf.nVal * 3600
		sTips = string.format("宠物成长加速%d小时", tConf.nVal) --宠物成长加速x小时

	else
		assert(false, "道具非法")

	end
	local nCurrNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, nPropID)
	if nCurrNum < nPropNum then
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nPropID))) --道具不足
	end
	self.m_oPlayer:SubItem(gtItemType.eProp, nPropID, nPropNum, "宠物加速")
	self.m_nGrowStartTime = self.m_nGrowStartTime - nSpeedUpTime
	local nStage, nRemainTime = self:CheckStage()
	self.m_oPlayer:Tips(sTips)
	self:MarkDirty(true)
	self:SyncInfo()
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond34, 1)
end

--活力上限
function CHZObj:MaxHuoLi()
	local nVIP = self.m_oPlayer:GetVIP()
	local nMaxHuoLi = ctVIPConf[nVIP].nHZHuoLi
	return nMaxHuoLi
end

--增加活力
function CHZObj:AddHuoLi(nHuoLi, sReason, bOneKey)
	local nLastHuoLi = self.m_nHuoLi
	self.m_nHuoLi = math.min(self:MaxHuoLi(), math.max(0, self.m_nHuoLi+nHuoLi))
	local nEventID = nHuoLi > 0 and gtEvent.eAddItem or gtEvent.eSubItem
    goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eHuoLi, nHuoLi, self.m_nHuoLi, self.m_nID)
	self:MarkDirty(true)
	--小红点
	if self.m_nHuoLi ~= nLastHuoLi and not bOneKey then
		self.m_oModule:CheckRedPoint()
	end
end

--增加经验
function CHZObj:AddExp(nExp, sReason)
	print("CHZObj:AddExp***", nExp, sReason)
	self.m_nExp = math.min(nMAX_INTEGER, math.max(0, self.m_nExp+nExp))
	local nEventID = nExp > 0 and gtEvent.eAddItem or gtEvent.eSubItem
    goLogger:AwardLog(nEventID, sReason, self.m_oPlayer, gtItemType.eCurr, gtCurrType.eHZExp, nExp, self.m_nExp, self.m_nID)
	self:MarkDirty(true)
end

--检测活力恢复
function CHZObj:UpdateHuoLi()
	--婴儿没有活力
	if self.m_nStage == CHZObj.tStage.eYingEr or self.m_nLastHuoLiRecoverTime <= 0 then
		return  0
	end
	local nNowSec = os.time()
	local nPassTime = nNowSec - self.m_nLastHuoLiRecoverTime
	local nHuoLiTime = ctHZEtcConf[1].nHuoLiTime
	local nHuoLiAdd = math.floor(nPassTime / nHuoLiTime)
	if nHuoLiAdd > 0 then
		self.m_nLastHuoLiRecoverTime = self.m_nLastHuoLiRecoverTime + nHuoLiAdd * nHuoLiTime
		self:MarkDirty(true)
		self:AddHuoLi(nHuoLiAdd, "活力恢复")
		return nHuoLiAdd
	end
	return 0
end

--下一活力恢复CD
function CHZObj:HuoLiCD()
	return math.max(0, self.m_nLastHuoLiRecoverTime+ctHZEtcConf[1].nHuoLiTime-os.time())
end

--等级上限
function CHZObj:MaxLevel()
	local tConf = ctHZTalentConf[self.m_nTalentLv]
	return tConf.nMaxLv
end

--更新宠物动态数据
function CHZObj:UpdateHZ()
	self:CheckStage()
	local nHLAdd = self:UpdateHuoLi() --增加活力
	local nExpAdd = self:UpdateExp() --增加经验
	return nHuoLiAdd, nExpAdd
end

--取宠物信息
function CHZObj:GetInfo()
	local nHuoLiAdd, nExpAdd = self:UpdateHZ()
	local nStage, nRemainTime = self:CheckStage()

	local tInfo = {}
	tInfo.nID = self.m_nID
	tInfo.sIcon = self.m_sIcon or ""
	tInfo.sName = self.m_sName
	tInfo.nLv = self.m_nLv
	tInfo.nMaxLv = self:MaxLevel()
	tInfo.nHuoLi = self.m_nHuoLi
	tInfo.nExpEff = self.m_nLearnEff
	tInfo.nStage = nStage
	tInfo.nStageTime = nRemainTime
	tInfo.nHuoLiCD = self:HuoLiCD()
	tInfo.tAttr = self.m_tAttr
	tInfo.nFZID = self.m_nFZID
	tInfo.nQinMi = self.m_nQinMi
	tInfo.nJueWei = self.m_nJueWei
	tInfo.nGender = self.m_nGender
	tInfo.nExp = self.m_nExp
	tInfo.nTalentType = self.m_nTalentType
	tInfo.nTalentLv = self.m_nTalentLv
	tInfo.nExpAdd = nExpAdd
	return tInfo
end

--同步信息
function CHZObj:SyncInfo(nLearnExp)
	local tInfo = self:GetInfo()
	if nLearnExp then
		tInfo.nLearnExpAdd = nLearnExp
	end	
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "HZSyncInfo", {tInfo=tInfo})
end

--提升学习效率
function CHZObj:UpLearnEffReq()
	local nCostYB = 0
	local nNextEff = 0
	if self.m_nLearnEff == 1 then
		nCostYB = 50
		nNextEff = 2

	elseif self.m_nLearnEff == 2 then
		nCostYB = 130
		nNextEff = 4

	elseif self.m_nLearnEff == 4 then
		return self.m_oPlayer:Tips("已达可提高上限") --理论上前端拦截(所以提示文字就不放到配置了)
	end
	local nCurrNum = self.m_oPlayer:GetYuanBao()
	if nCurrNum < nCostYB then
		return self.m_oPlayer:YBDlg() --元宝不足
	end
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nCostYB, "宠物提升学习效率")
	self.m_nLearnEff = nNextEff
	self:MarkDirty(true)
	self:SyncInfo()
end

--检测经验增加
function CHZObj:UpdateExp()
	--只有少年有经验增加
	if self.m_nStage ~= CHZObj.tStage.eShaoNian or self.m_nLastExpRecoverTime <= 0 then
		return 0
	end

	local nLearnTime = ctHZEtcConf[1].nLearnTime
	local nPassTime = os.time() - self.m_nLastExpRecoverTime
	local nExpBase = math.floor(nPassTime / nLearnTime)
	if nExpBase > 0 then
		self.m_nLastExpRecoverTime = self.m_nLastExpRecoverTime+nExpBase*nLearnTime
		self:MarkDirty(true)

		--达到等级上限不增加经验
		if self.m_nLv < self:MaxLevel() then
			local nExpAdd = math.floor(nExpBase*self.m_nLearnEff)
			self:AddExp(nExpAdd, "宠物经验定时增加")
			self:CheckUpgrade()
			return nExpAdd
		end
	end
	return 0
end

--学习(突飞猛进)随机获得属性
function CHZObj:LearnRandAttr()
	local nAttrID = math.random(1, 4)
	local nRnd = math.random(1, 100)
	local nAttrVal = nRnd <= 70 and 1 or 2
	return nAttrID, nAttrVal
end

--学习/培养/突飞猛进使用活力丹
function CHZObj:UseHLD()
	if self.m_nStage ~= CHZObj.tStage.eShaoNian then
		return self.m_oPlayer:Tips("非少年时期")
	end
	local tConf = ctHZEtcConf[1]
	local tHLDProp = tConf.tHLDProp[1]
	if self.m_oPlayer:GetItemCount(tHLDProp[1], tHLDProp[2]) < tHLDProp[3] then
		return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tHLDProp[2])))
	end
	self.m_oPlayer:SubItem(tHLDProp[1], tHLDProp[2], tHLDProp[3], "宠物学习消耗道具")
	self:AddHuoLi(self:MaxHuoLi(), "使用活力丹恢复体力")
	self.m_oPlayer:Tips("已恢复所有活力")
	self:SyncInfo()
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond18, 1)
	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eHLD, tHLDProp[3])
end

--学习/突飞猛进/培养
function CHZObj:LearnReq(bUseProp)
	if self.m_nStage ~= CHZObj.tStage.eShaoNian then
		return self.m_oPlayer:Tips("非少年时期")
	end
	if self.m_nLv >= self:MaxLevel() then
		return self.m_oPlayer:Tips("已达等级上限") --已达等级上限
	end

	--使用道具
	if bUseProp then	
		return self:UseHLD()
	end

	--检测资源
	local tConf = ctHZEtcConf[1]
	local nLearnCostHL = tConf.nLearnCostHL
	if self.m_nHuoLi < nLearnCostHL then
		return self.m_oPlayer:Tips("活力不足")
	end

	--扣资源 
	local nZhuFu = self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eHXBJ)	--神迹祝福
	nLearnCostHL = nLearnCostHL - nZhuFu
	self:AddHuoLi(-nLearnCostHL, "宠物学习扣活力")

	--增加经验
	self:AddExp(tConf.nLearnGetExp, "宠物学习增加经验")
	--检测升级
	self:CheckUpgrade()

	--学习随机属性获得
	local nAttrID, nAttrVal = self:LearnRandAttr()
	self.m_tLearnAttr[nAttrID] = self.m_tLearnAttr[nAttrID] + nAttrVal
	self:MarkDirty(true)
	self:UpdateAttr()

	--同步
	self:SyncInfo(tConf.nLearnGetExp)
	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond17, 1)
	self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond13, 1)
end

--更新属性
function CHZObj:UpdateAttr(bNotUpdate)
	-- 商业 =10*商业修正+（1 + 宠物等级）*宠物等级/2*商业修正*（1+（母亲亲密度/2）%）+宠物等级*对应天赋技能等级 + 学习随机值
	-- 农业 =10*农业修正+（1 + 宠物等级）*宠物等级/2*农业修正*（1+（母亲亲密度/2）%）+宠物等级*对应天赋技能等级 + 学习随机值
	-- 政治 =10*政治修正+（1 + 宠物等级）*宠物等级/2*政治修正*（1+（母亲亲密度/2）%）+宠物等级*对应天赋技能等级 + 学习随机值
	-- 军事 =10*军事修正+（1 + 宠物等级）*宠物等级/2*军事修正*（1+（母亲亲密度/2）%）+宠物等级*对应天赋技能等级 + 学习随机值
	local bChange = false
	for k = 1, 4 do
		local nTalentAdd = (k==self.m_nTalentType) and ctHZTalentConf[self.m_nTalentLv].nTalentAdd or 0
		local nAttr = 10*self.m_tAttrAdj[k]
			+ (1+self.m_nLv)*self.m_nLv/2*self.m_tAttrAdj[k]*(1+(self.m_nQinMi/2)/100)
			+ self.m_nLv*nTalentAdd
			+ self.m_tLearnAttr[k]
			+ self.m_tCaiLiAttr[k]

		nAttr = math.floor(nAttr)

		assert(nAttr >= 0, "属性错误")
		bChange = bChange or nAttr ~= self.m_tAttr[k]
		self.m_tAttr[k] = nAttr
	end
	if bChange ~= 0 then
		self.m_oModule:OnHZAttrChange()
		if not bNotUpdate then
			self.m_oPlayer:UpdateGuoLi("宠物") --更新国力
		end
		self:MarkDirty(true)
	end
	return tAttrAdd
end

--检测升级
function CHZObj:CheckUpgrade(bOneKey)
	local bLevelChange = false
	for k = self.m_nLv, self:MaxLevel()-1 do
		local tConf = ctHZLevelConf[k]
		if self.m_nExp >= tConf.nExp then
			self.m_nLv = k + 1
			self:MarkDirty(true)
			self:AddExp(-tConf.nExp, "宠物升级扣除经验")
			bLevelChange = true
		else
			break
		end
	end
	if bLevelChange and not bOneKey then
		self:UpdateAttr()
	end
end

--取能力
function CHZObj:GetNengLi()
	local nTotal = 0
	for _, v in pairs(self.m_tAttr) do
		nTotal = nTotal + v
	end
	return nTotal
end

--封爵/评级
function CHZObj:FengJueReq()
	if self.m_nStage ~= CHZObj.tStage.eShaoNian then
		return self.m_oPlayer:Tips("只有少年阶段可以评级")
	end
	if self.m_nJueWei > 0 then
		return self.m_oPlayer:Tips("已有评级，操作失败")
	end
	if self.m_nLv < self:MaxLevel() then
		return self.m_oPlayer:Tips("请先升到最高等级")
	end
	local sJueWei = ""
	local nNengLi = self:GetNengLi()
	for k = #ctHZTitleConf, 1, -1 do
		local tNLConf = ctHZTitleConf[k].tNengLi[1]
		if nNengLi >= tNLConf[1] then
			self.m_nJueWei = k
			self:OnStageChange(self.m_nStage, CHZObj.tStage.eChengNian)
			self:MarkDirty(true)
			sJueWei = ctHZTitleConf[k]["sName"..self.m_nGender]
			break
		end
	end
	self:SyncInfo()
	--电视
	local sNotice = string.format(ctLang[14], self.m_oPlayer:GetName(), self.m_sName, sJueWei)
	goTV:_TVSend(sNotice)	
	--小红点
	self.m_oModule:CheckRedPoint()
end

function CHZObj:IsMarried() return self.m_tPeiOu.nJueWei > 0 end
function CHZObj:GetAttr() return self.m_tAttr end --宠物属性
function CHZObj:GetPO() return self.m_tPeiOu end
function CHZObj:GetJueWei() return self.m_nJueWei end
function CHZObj:GetName() return self.m_sName end
function CHZObj:GetGender() return self.m_nGender end
function CHZObj:GetHuoLi() return self.m_nHuoLi end

--结婚
function CHZObj:Married(tData)
	assert(not self:IsMarried(), "宠物已经结婚")
	self.m_tPeiOu = tData

	--请按折
    -- self.m_oPlayer.m_oQingAnZhe:OnHZMarried()

	--活动累计联姻次数
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eLY, 1)

	--电视
	local sNotice = string.format(ctLang[15], self.m_oPlayer:GetName(), tData.sCharName)
	goTV:_TVSend(sNotice)	

	--彩礼加成
	local nRndID = math.random(1, 4)
	if tData.nCaiLiID > 0 then
		local tConf = ctPropConf[tData.nCaiLiID]
		self.m_tCaiLiAttr[nRndID] = self.m_tCaiLiAttr[nRndID] + tConf.nVal
		self.m_tCaiLiAttrPer[nRndID] = 0.25
	end
	if self.m_nCaiLiID > 0 then
		local tConf = ctPropConf[self.m_nCaiLiID]
		self.m_tCaiLiAttr[nRndID] = self.m_tCaiLiAttr[nRndID] + tConf.nVal
	end
	self:MarkDirty(true)
	self:UpdateAttr(true)

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond27, 1)
	--成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond16, 1)
end

--配偶属性
function CHZObj:POAttr()
	if self.m_tPeiOu.nJueWei > 0 then
		return self.m_tPeiOu.tAttr
	end
	return {}
end

--是否成年
function CHZObj:IsChengNian()
	self:UpdateHZ()
	return self.m_nStage == CHZObj.tStage.eChengNian
end

--是否少年
function CHZObj:IsShaoNian()
	self:UpdateHZ()
	return self.m_nStage == CHZObj.tStage.eShaoNian
end

--取彩礼ID
function CHZObj:GetCaiLiID()
	return self.m_nCaiLiID
end

--设置彩礼ID
function CHZObj:SetCaiLiID(nCaiLiID)
	self.m_nCaiLiID = nCaiLiID
	self:MarkDirty(true)
end

--彩礼信息请求
function CHZObj:CaiLiInfoReq()
	local tList = {}
	local tConf = ctHZEtcConf[1]
	for _, nID in ipairs(tConf.tCaiLiID[1]) do
		local nNum = self.m_oPlayer:GetItemCount(gtItemType.eProp, nID)
		if nID == self.m_nCaiLiID and nNum <= 0 then
			self.m_nCaiLiID = 0
			self:MarkDirty(true)
		end
		table.insert(tList, {nID=nID, nNum=nNum, bSel=(nID==self.m_nCaiLiID)})
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "HZCaiLiInfoRet", {tList=tList})
end

--设置彩礼
function CHZObj:SetCaiLiReq(nCaiLiID)
	assert(nCaiLiID >= 0)
	if nCaiLiID == 0 and self.m_nCaiLiID > 0 then --移除彩礼
		self.m_nCaiLiID = 0
		self:MarkDirty(true)
		self:CaiLiInfoReq()
		return
	end
	assert(nCaiLiID > 0, "彩礼ID不能为0")	
	if self.m_oPlayer:GetItemCount(gtItemType.eProp, nCaiLiID) <= 0 then
		self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nCaiLiID)))
		return
	end
	--设置新彩礼
	self.m_nCaiLiID = nCaiLiID
	self:CaiLiInfoReq()
	self:MarkDirty(true)
end

--GM设置等级
function CHZObj:GMSetLv(nLv)
	if self.m_nStage ~= CHZObj.tStage.eShaoNian then
		return self.m_oPlayer:Tips("请先培养宠物到少年")
	end
	self.m_nLv = nLv or self:MaxLevel()
	self:UpdateAttr()
	self:MarkDirty(true)
end

--GM设置爵位
function CHZObj:GMSetJW(nJueWei)
	if self.m_nJueWei > 0 then
		return
	end
	nJueWei = math.max(1, math.min(nJueWei or 0, #ctHZTitleConf))
	self.m_nJueWei = nJueWei
	self:OnStageChange(self.m_nStage, CHZObj.tStage.eChengNian)
	self:MarkDirty(true)
end
