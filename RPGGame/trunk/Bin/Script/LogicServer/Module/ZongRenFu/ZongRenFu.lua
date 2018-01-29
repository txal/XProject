--宠物系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CZongRenFu:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nAutoInc = 0
	self.m_tHZMap = {}
	self.m_nGrids = ctHZEtcConf[1].nInitPos --初始席位数
end

function CZongRenFu:GetType()
	return gtModuleDef.tZongRenFu.nID, gtModuleDef.tZongRenFu.sName
end

function CZongRenFu:LoadData(tData)
	if not tData then
		return
	end
	self.m_nAutoInc = tData.m_nAutoInc
	self.m_nGrids = tData.m_nGrids
	for nID, tHZData in pairs(tData.m_tHZMap) do
		local tFZConf = ctMingChenConf[tHZData.m_nFZID]
		if tFZConf then
			local oHZ = CHZObj:new(self, self.m_oPlayer, 
				tHZData.m_nID, 
				tHZData.m_nFZID, 
				tHZData.m_nQinMi, 
				tHZData.m_nGender, 
				tHZData.m_nTalentLv
			)
			oHZ:LoadData(tHZData)
			self.m_tHZMap[nID] = oHZ
		end
	end
end

function CZongRenFu:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nAutoInc = self.m_nAutoInc
	tData.m_nGrids = self.m_nGrids
	tData.m_tHZMap = {}

	for nID, oHZ in pairs(self.m_tHZMap) do
		tData.m_tHZMap[nID] = oHZ:SaveData()
	end
	return tData
end

function CZongRenFu:Online()
	self:CheckRedPoint()
end

function CZongRenFu:CheckOpen(bTips)
	if not next(self.m_tHZMap) then
		if bTips then
			self.m_oPlayer:Tips("拥有宠物后开启")
		end
		return 
	end
	return true
end

--生成萌宠ID
function CZongRenFu:GenID()
	self.m_nAutoInc = self.m_nAutoInc % nMAX_INTEGER + 1
	self:MarkDirty(true)
	return self.m_nAutoInc
end

--获取萌宠列表
function CZongRenFu:HzList()
	return self.m_tHZMap
end

--取对象
function CZongRenFu:GetObj(nHZID)
	return self.m_tHZMap[nHZID]
end

--创建萌宠(萌宠名字,母亲妃子ID)
function CZongRenFu:Create(nFZID, nGender, bDouble, nTalentLv) --bDouble:是否双胞胎,如果是双胞胎可以超出1个席位
	if not bDouble and self:GetFreeGrid() <= 0 then
		return self.m_oPlayer:Tips("兴圣宫萌宠位置已满")
	end
	local oMC = self.m_oPlayer.m_oMingChen:GetObj(nFZID)
	assert(oMC, "萌宠母亲不存在:"..nFZID)

	--计算萌宠天赋等级
	local nTalentLv = nTalentLv	
	if not nTalentLv then
		local X = oMC:GetQinMi()
		local Y = self.m_oPlayer.m_oMingChen:GetTotalQinMi()
		local nRandMax = math.max(1, math.floor(X/2+Y/60))
		local Z = math.random(1, nRandMax) + math.random(1, nRandMax) + math.random(1, nRandMax)
		if Z > 500 then
			nTalentLv = 5
		elseif Z > 300 then
			nTalentLv = 4
		elseif Z > 150 then	
			nTalentLv = 3
		elseif Z > 50 then
			nTalentLv = 2
		else
			nTalentLv = 1
		end
	end

	local nID = self:GenID()
	local oHZ = CHZObj:new(self, self.m_oPlayer, nID, nFZID, oMC:GetQinMi(), nGender, nTalentLv)
	self.m_tHZMap[nID] = oHZ
	self:MarkDirty(true)

	oHZ:UpdateAttr()
	if not bDouble then
		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "MCBornChildRet"
			, {nChildNum=1, nGender1=nGender, nTalentLv1=nTalentLv, sIcon1=oHZ:GetIcon()})
	end

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond24, 1)
	--离线数据
    goOfflineDataMgr:UpdateChildNum(self.m_oPlayer, self:GetChildNum())
    --成就
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond15, 1)
	--活动
    goHDMgr:GetHuoDong(gtHDDef.eTimeAward):UpdateVal(self.m_oPlayer:GetCharID(), gtTAType.eZS, 1)
	--日志
	goLogger:EventLog(gtEvent.eCreateHZ, self.m_oPlayer, nID, nFZID, nGender, nTalentLv)
	--开启联姻
	self.m_oPlayer.m_oLianYin:SetOpen(true)

	return nTalentLv, oHZ
end

--创建双胞胎
function CZongRenFu:CreateDouble(nFZID, nGender1, nGender2)
	local tMsg = {nChildNum=2, nGender1=nGender1, nGender2=nGender2, nTalentLv1=0, nTalentLv2=0, sIcon1="", sIcon2=""}
	local nTalentLv1, oHZ1 = self:Create(nFZID, nGender1, true)
	local nTalentLv2, oHZ2 = self:Create(nFZID, nGender2, true)
	if nTalentLv1 and nTalentLv2 then
		tMsg.nTalentLv1 = nTalentLv1
		tMsg.nTalentLv2 = nTalentLv2
		tMsg.sIcon1 = oHZ1:GetIcon()
		tMsg.sIcon2 = oHZ2:GetIcon()
		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "MCBornChildRet", tMsg)
		return true
	end
end

--扩建席位
function CZongRenFu:OpenGrid()
	local nVIP = self.m_oPlayer:GetVIP()
	local nMaxGrid = ctVIPConf[nVIP].nZRFPos
	if self.m_nGrids >= nMaxGrid then
		return self.m_oPlayer:Tips("已达到扩建上限，提升VIP等级可提高扩建席位上限")
	end
	local nOpenGrid = self.m_nGrids + 1
	local nYuanBao = ctHZGridConf[nOpenGrid].nYuanBao
	if self.m_oPlayer:GetYuanBao() < nYuanBao then
		return self.m_oPlayer:YBDlg()
	end
	self.m_nGrids = nOpenGrid
	self:MarkDirty(true)

	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, "兴圣宫扩建")
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "HZOpenGridRet", {nGrids=self.m_nGrids})
	print("CZongRenFu:OpenGrid***--------", self.m_nGrids)

	--任务
	self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond29, self.m_nGrids, nil, true)

	--电视
	if self.m_nGrids >= 6 then
		goTV:_TVSend(string.format(ctLang[16], self.m_oPlayer:GetName()))
	end

	self.m_oPlayer:Tips("兴圣宫扩建成功")
end

--席位数
function CZongRenFu:GetGrids()
	return self.m_nGrids
end

--取剩余席位数
function CZongRenFu:GetFreeGrid()
	local nWCNCount = 0 --未成年的萌宠数
	for nHZID, oHZ in pairs(self.m_tHZMap) do
		if not oHZ:IsChengNian() then
			nWCNCount = nWCNCount + 1
		end
	end
	return self.m_nGrids - nWCNCount
end

--子嗣数量
function CZongRenFu:GetChildNum()
	local nChildNum = 0
	for nHZID, oHZ in pairs(self.m_tHZMap) do
		nChildNum = nChildNum + 1
	end
	return nChildNum
end

--未婚萌宠列表
function CZongRenFu:UnmarriedListReq()
	--爵位名、萌宠名、综合能力
	local tList = {}
	local nLYTime = ctHZEtcConf[1].nLYTime
	for nID, oHZ in pairs(self.m_tHZMap) do
		if oHZ:IsChengNian() and not oHZ:IsMarried() then
			local nLYRemainTime = 0
			local tLYData = self.m_oPlayer.m_oLianYin:GetSendLY(nID)
			if tLYData then --联姻申请剩余时间
				nLYRemainTime = nLYTime + tLYData.nTime - os.time()
			end
			local tInfo = {
				nID = nID,
				nLv = oHZ.m_nLv,
				sIcon = oHZ.m_sIcon,
				sName = oHZ.m_sName,
				nFZID = oHZ.m_nFZID,
				tAttr = oHZ.m_tAttr,
				nQinMi = oHZ.m_nQinMi,
				nGender = oHZ.m_nGender,
				nNengLi = oHZ:GetNengLi(),
				nJueWei = oHZ.m_nJueWei,
				nTalentLv = oHZ.m_nTalentLv,
				nTalentType = oHZ.m_nTalentType,
				nLYRemainTime = nLYRemainTime,
			}
			table.insert(tList, tInfo)
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "HZUnmarriedListRet", {tList=tList})
end

--已婚萌宠列表
function CZongRenFu:MarriedListReq()
	--爵位、头像、名字、综合能力，亲家昵称，联姻加成以及联姻日期
	local tList = {}
	for nID, oHZ in pairs(self.m_tHZMap) do
		if oHZ:IsMarried() then
			local tPO = oHZ.m_tPeiOu
			local tInfo = {
				nID = nID,
				nJueWei = oHZ.m_nJueWei,
				sIcon = oHZ.m_sIcon,
				sName = oHZ.m_sName,
				nNengLi = oHZ:GetNengLi(),
				nGender = oHZ.m_nGender,
				tAttr = oHZ.m_tAttr,
				nQinMi = oHZ.m_nQinMi,
				nFZID = oHZ.m_nFZID,
				nTalentLv = oHZ.m_nTalentLv,
				nTalentType = oHZ.m_nTalentType,
				nLv = oHZ.m_nLv,

				nPOJueWei = tPO.nJueWei,
				sPOIcon = tPO.sIcon,
				sPOName = tPO.sName,
				sPOCharName = tPO.sCharName,
				nPOLv = tPO.nLv,
				tPOAttr = tPO.tAttr,
				nPOTalentLv = tPO.nTalentLv,
				nPOTime = tPO.nTime,
				nPOGender = tPO.nGender,
			}
			table.insert(tList, tInfo)
		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "HZMarriedListRet", {tList=tList})
end

--萌宠列表
function CZongRenFu:HZListReq()
	local tList = {}
	for nID, oHZ in pairs(self.m_tHZMap) do
		local tInfo = oHZ:GetInfo()
		table.insert(tList, tInfo)
	end
	local tMsg = {tList=tList, nGrids=self.m_nGrids}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "HZListRet", tMsg)
end

--萌宠属性变化
function CZongRenFu:OnHZAttrChange()
	local nTotal = 0
	for nID, oHZ in pairs(self.m_tHZMap) do
		local nNengLi = oHZ:GetNengLi()
		nTotal = nTotal + nNengLi
	end
	goRankingMgr.m_oHZRanking:Update(self.m_oPlayer, nTotal) --更新排行榜
end

--萌宠属性
function CZongRenFu:GetTotalAttr()
	local tAttr = {0, 0, 0, 0}
	for nID, oHZ in pairs(self.m_tHZMap) do
		local tHZAttr = oHZ:GetAttr()
		for k = 1, 4 do
			tAttr[k] = tAttr[k] + tHZAttr[k]
		end
	end
	return tAttr
end

--萌宠联姻属性
function CZongRenFu:GetTotalPOAttr()
	local tAttr = {0, 0, 0, 0}
	for nID, oHZ in pairs(self.m_tHZMap) do
		local tPOAttr = oHZ:POAttr()
		for k = 1, 4 do
			tAttr[k] = tAttr[k] + (tPOAttr[k] or 0)
		end
	end
	return tAttr
end

--彩礼加成(百分比)
function CZongRenFu:GetCLAttrPer()
	local tAttrPer = {0, 0, 0, 0}
	for nID, oHZ in pairs(self.m_tHZMap) do
		local tCaiLiAttrPer = oHZ.m_tCaiLiAttrPer
		for k = 1, 4 do
			tAttrPer[k] = tAttrPer[k] + tCaiLiAttrPer[k]
		end
	end
	return tAttrPer
end

--随机萌宠
function CZongRenFu:RandObj(nNum)
	local tHZList = {}
	local tTarHZList = {}
	for nID, oHZ in pairs(self.m_tHZMap) do
		table.insert(tHZList, oHZ)
	end
	if #tHZList <= 0 then
		return tTarHZList
	end
	for k = 1, nNum do
		local nRnd = math.random(1, #tHZList)
		table.remove(tHZList, nRnd)
		table.insert(tTarHZList, tHZList[nRnd])
		if #tHZList <= 0 then break end
	end
	return tTarHZList
end

--随机已婚萌宠
function CZongRenFu:RandMarriedObj(nNum)
	local tHZList = {}
	local tTarHZList = {}
	for nID, oHZ in pairs(self.m_tHZMap) do
		if oHZ:IsMarried() then
			table.insert(tHZList, oHZ)
		end
	end
	if #tHZList <= 0 then
		return tTarHZList
	end
	
	for k = 1, nNum do
		local nRnd = math.random(1, #tHZList)
		table.insert(tTarHZList, tHZList[nRnd])
		table.remove(tHZList, nRnd)
		if #tHZList <= 0 then break end
	end
	return tTarHZList
end

--一键突飞猛进
function CZongRenFu:OneKeyLearnReq()
	local tConf = ctHZEtcConf[1]
	if self.m_nGrids < tConf.nOneKeyLearnGrids then
		local sTips = string.format("需要开启%d个席位才能一键培养", tConf.nOneKeyLearnGrids)
		return self.m_oPlayer:Tips(sTips)
	end

	local tResMap = {}
	for nID, oHZ in pairs(self.m_tHZMap) do
		local n = 256 --防止死循环
		local nSuccTimes = 0 --成功次数
		while n > 0 do 
			n = n - 1
			local tLvConf = ctHZLevelConf[oHZ:GetLv()]
			if not oHZ:IsShaoNian() 
				or oHZ:GetLv() >= oHZ:MaxLevel()
				or oHZ:GetHuoLi() < tConf.nLearnCostHL then
					break
			else
				oHZ:AddHuoLi(-tConf.nLearnCostHL, "萌宠一键学习扣活力", true)
				oHZ:AddExp(tConf.nLearnGetExp, "萌宠一键学习增加经验")
				oHZ:CheckUpgrade(true)
				local nAttrID, nAttrVal = oHZ:LearnRandAttr()
				oHZ.m_tLearnAttr[nAttrID] = oHZ.m_tLearnAttr[nAttrID] + nAttrVal
				oHZ:MarkDirty(true)

				if not tResMap[nID] then
					tResMap[nID] = {oHZ=oHZ, nTimes=0, nZhuFu=0, nExp=0}
				end
				tResMap[nID].nTimes = tResMap[nID].nTimes + 1
				tResMap[nID].nExp = tResMap[nID].nExp + tConf.nLearnGetExp
				local nZhuFu = self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eHXBJ, true)
				if nZhuFu > 0 then
					tResMap[nID].nZhuFu = tResMap[nID].nZhuFu + nZhuFu
				end
			end
		end
	end
	local nTotalZhuFu = 0
	for nID, tRes in pairs(tResMap) do
		--同步
		tRes.oHZ:UpdateAttr(true)
		tRes.oHZ:SyncInfo(tRes.nExp)
		--神迹
		tRes.oHZ:AddHuoLi(tRes.nZhuFu, "萌宠1键学习神迹", true)
		nTotalZhuFu = nTotalZhuFu + tRes.nZhuFu
	end
	if next(tResMap) then
		self.m_oPlayer:UpdateGuoLi("萌宠") --国力
		if nTotalZhuFu > 0 then
			self.m_oPlayer.m_oShenJiZhuFu:SyncShenJiZhuFu(gtSJZFDef.eHXBJ)
		end
		self:CheckRedPoint() --小红点
	else
		self.m_oPlayer:Tips("没有可培养萌宠")
	end
end

--一键恢复活力(使用活力丹)
function CZongRenFu:OneKeyRecoverReq()
	local tConf = ctHZEtcConf[1]
	local tHLDProp = tConf.tHLDProp[1]

	local nCount = 0
	for nID, oHZ in pairs(self.m_tHZMap) do
		if oHZ:IsShaoNian() and oHZ:GetHuoLi() < oHZ:MaxHuoLi() then
			local nCurrHLD = self.m_oPlayer:GetItemCount(tHLDProp[1], tHLDProp[2])
			if nCurrHLD >= tHLDProp[3] then
				oHZ:UseHLD()
				nCount = nCount + 1
			else
				break
			end
		end
	end
	if nCount > 0 then
		self.m_oPlayer:Tips("一键恢复活力成功")
	else
		self.m_oPlayer:Tips("活力丹不足或没萌宠需要恢复活力")
	end
end

--检测小红点
function CZongRenFu:CheckRedPoint()
	if not self:CheckOpen() then
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eZRFTFMJ, 0)
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eZRFFJ, 0)
		return
	end

	local bTFMJ, bFJ = false, false
	for nID, oHZ in pairs(self.m_tHZMap) do
		if oHZ:IsShaoNian() then
			if not bTFMJ and oHZ:GetLv() < oHZ:MaxLevel() and oHZ:GetHuoLi() > 0 then
				bTFMJ = true --突飞猛进
			end
			if not bFJ and oHZ:GetLv() >= oHZ:MaxLevel() and oHZ:GetJueWei() <= 0 then
				bFJ = true --封爵
			end
		end
	end
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eZRFTFMJ, bTFMJ and 1 or 0)
	self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eZRFFJ, bFJ and 1 or 0)
end

--宗仁府格子信息请求
function CZongRenFu:GridInfoReq()
	local tMsg = {}
	tMsg.nFreeGrids = self:GetFreeGrid()
	tMsg.nMaxGrids = self:GetGrids()
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ZRFGridInfoRet", tMsg)
end