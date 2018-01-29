local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--位置
CFashion.tPos = {
	eFX = 1,	--发型
	eTS = 2, 	--头饰
	eSS = 3, 	--首饰
	eFS = 4, 	--服饰
	eZS = 5, 	--装饰品
}

--时装系统
function CFashion:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tFashionMap = {} 	--已获得对象{[id]=obj,..}
	self.m_tFashionBuyMap = {} 	--时装购买映射{[id]=1,...}
	self.m_tWearMap = {} 		--已穿戴的部件
	self.m_nCount = 0
end

function CFashion:GetType()
	return gtModuleDef.tFashion.nID, gtModuleDef.tFashion.sName
end

function CFashion:LoadData(tData)
	if not tData then
		return
	end
	for nID, tFSData in pairs(tData.tFSMap) do
		local oObj = CFSObj:new(self, self.m_oPlayer, nID)
		oObj:LoadData(tFSData)
		self.m_tFashionMap[nID] = oObj
	end
	self.m_tFashionBuyMap = tData.m_tFashionBuyMap
	self.m_tWearMap = tData.m_tWearMap or {}
	self.m_nCount = tData.m_nCount
end

function CFashion:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.tFSMap = {}
	for nID, oObj in pairs(self.m_tFashionMap) do
		tData.tFSMap[nID] = oObj:SaveData()
	end
	tData.m_tFashionBuyMap = self.m_tFashionBuyMap
	tData.m_tWearMap = self.m_tWearMap
	tData.m_nCount = self.m_nCount
	return tData
end

--上线
function CFashion:Online()
	for nID, tConf in pairs(ctFashionConf) do
		local oFS = self:GetFashion(nID)
		if tConf.nCond == 1 and not oFS then --默认获得
			self:Create(nID, "默认", true)
		elseif oFS then
			oFS:UpdateAttr(true)
		end
	end
	self:SyncFashion()
	self:SyncFashionWear()
end

--AddItem添加时装
function CFashion:AddFashion(nID)
	return self:Create(nID)
end

--创建时装
function CFashion:Create(nID, sReason, bNotSync)
	if self:GetFashion(nID) then
		return self.m_oPlayer:Tips(string.format("已拥有 %s", self:FashionName(nID)))
	end

	local oObj = CFSObj:new(self, self.m_oPlayer, nID)
	self.m_tFashionMap[nID] = oObj
	self.m_nCount = self.m_nCount + 1
	self:MarkDirty(true)

	oObj:UpdateAttr(bNotSync)
	if sReason then
		goLogger:AwardLog(gtEvent.eAddItem, sReason, self.m_oPlayer, gtItemType.eFashion, nID, 1)
	end

	--成就	
	self.m_oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond21, self.m_nCount, true)
	return true
end

function CFashion:GetFashion(nID)
	return self.m_tFashionMap[nID]
end

function CFashion:FashionName(nID)
	return ctFashionConf[nID].sName
end	

function CFashion:SyncFashion(nID)
	local tList = {}
	if nID then
		local oFS = self:GetFashion(nID)
		local tInfo = oFS:GetInfo()
		table.insert(tList, tInfo)
	else
		for nID, oFS in pairs(self.m_tFashionMap) do
			local tInfo = oFS:GetInfo()
			table.insert(tList, tInfo)
		end
	end
	local tMsg = {tList=tList, nMaxChar=8000}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FashionListRet", tMsg)
end

--时装商店请求
function CFashion:FashionMallReq()
	local tList = {}
	for nID, tConf in pairs(ctFashionMallConf) do
		local tInfo = {nID=nID, bGot=(self.m_tFashionBuyMap[nID] and true or false)}
		table.insert(tList, tInfo)
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FashionMallRet", {tList=tList})
end

--购买时装请求
function CFashion:FashionBuyReq(nID)
	if self:GetFashion(nID) then
		return self.m_oPlayer:Tips(string.format("已拥有 %s", self:FashionName(nID)))
	end
	local tConf = ctFashionMallConf[nID]
	if self.m_oPlayer:GetYuanBao() < tConf.nPrice then
		return self.m_oPlayer:YBDlg()
	end
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nPrice, "购买时装")

	self:Create(nID, "购买")
	self.m_tFashionBuyMap[nID] = 1
	self:MarkDirty(true)

	self:FashionMallReq()
	self.m_oPlayer:Tips("购买成功")
end

--穿戴请求
function CFashion:FashionWearReq(nID)
	local oFS = self:GetFashion(nID)
	if not oFS then
		return self.m_oPlayer:Tips("时装未获得")
	end
	local tConf = ctFashionConf[nID]
	self.m_tWearMap[tConf.nType] = nID
	self:MarkDirty(true)

	self:SyncFashionWear()
	self.m_oPlayer:UpdateGuoLi("时装穿戴")
end

--卸下请求
function CFashion:FashionOffReq(nID)
	local oFS = self:GetFashion(nID)
	if not oFS then
		return self.m_oPlayer:Tips("时装未获得")
	end
	local tConf = ctFashionConf[nID]
	self.m_tWearMap[tConf.nType] = nil
	self:MarkDirty(true)

	self:SyncFashionWear()
	self.m_oPlayer:UpdateGuoLi("时装卸下")
end

--同步穿戴列表
function CFashion:SyncFashionWear()
	local tList = {}
	for nPos, nID in pairs(self.m_tWearMap) do
		table.insert(tList, {nPos=nPos, nID=nID})
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FashionWearRet", {tList=tList})
end

--取时装加成
function CFashion:GetFashionAttr()
	local tTotalAttr = {0, 0, 0, 0}
	for nID, oFS in pairs(self.m_tFashionMap) do
		local tAttr = oFS:GetAttr()
		for k = 1, 4 do
			tTotalAttr[k] = tTotalAttr[k] + tAttr[k]
		end
	end
	return tTotalAttr
end

--制作时装请求
function CFashion:FashionMakeReq(nID)
	local nChapter = ctFashionEtcConf[1].nMakeChapter
	if not self.m_oPlayer.m_oDup:IsChapterPass(nChapter) then
		self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
		return
	end
	if self.m_tFashionMap[nID] then
		return self.m_oPlayer:Tips(string.format("已拥有 %s",self:FashionName(nID)))
	end
	local tConf = ctFashionMakeConf[nID]
	if self.m_oPlayer:GetLevel() < tConf.nGP then
		return self.m_oPlayer:Tips("未达到所需官品")
	end
	if self.m_oPlayer:GetYinLiang() < tConf.nYL then
		return self.m_oPlayer:Tips("银两不足")
	end
	local tProp = tConf.tProp
	for _, tItem in ipairs(tProp) do
		if self.m_oPlayer:GetItemCount(tItem[1], tItem[2]) <tItem[3] then
			return self.m_oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(tItem[2])))
		end
	end
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nYL, "制作时装")
	for _, tItem in ipairs(tProp) do
		self.m_oPlayer:SubItem(tItem[1], tItem[2], tItem[3], "制作时装")
	end
	self:Create(nID, "制作")
	--任务
    self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond47, nID, 1, true)
end

--计算副本评分
function CFashion:CalcDupScore(nDupID)
	local tDupConf = ctFashionDupConf[nDupID]
	local tKeyIDMap = {}
	for k, v in ipairs(tDupConf.tKeyID) do
		tKeyIDMap[v[1]] = true
	end
	local tScoreList = {}
	local tKeyScoreMap = {}

	for k = 1, 5 do
		local nFSID = self.m_tWearMap[k]
		local oFS = self:GetFashion(nFSID)
		if oFS then
			local tFSConf = ctFashionConf[oFS:GetID()]	
			--场景加分
			for _, v in ipairs(tFSConf.tScene) do
				if tKeyIDMap[v[1]] then
					tKeyScoreMap[v[1]] = (tKeyScoreMap[v[1]] or 0) + v[2]
					print("场景加分:", "时装ID:"..nFSID, "关键字ID:"..v[1], "分数:"..v[2])
				end
			end
			--特性加成 & 强化加成 & 反季
			local tChar = oFS:GetChar()
			for k = 1, CFSObj.nMaxCharCount do
				if tKeyIDMap[k] then
					--特性
					tKeyScoreMap[k] = (tKeyScoreMap[k] or 0) + tChar[k]
					print("特性加分:", "时装ID:"..nFSID, "关键字ID:"..k, "分数:"..tChar[k])
					--强化
					local nTmpScore = tChar[k] - tFSConf["tChar"..k][1][1]
					print("强化加分:", "时装ID:"..nFSID, "关键字ID:"..k, "分数:"..nTmpScore)
					tKeyScoreMap[k] = tKeyScoreMap[k] + nTmpScore
					--反季(保温,清凉)
					if (k == 12 or k == 14) and tChar[k] > 0 then
						if (k == 12 and tKeyIDMap[14]) or (k == 14 and tKeyIDMap[12]) then
							tKeyScoreMap[k] = tKeyScoreMap[k] - 1000
							print("反季扣分:", "时装ID:"..nFSID, "关键字ID:"..k, "分数:-1000")
						end
					end
				end
			end
		end
	end	

	local nTotalScore = 0	
	for nKey, nScore in pairs(tKeyScoreMap) do
		nTotalScore = nTotalScore + nScore
		local sName = gtSceneTypeName[nKey] or gtCharTypeName[nKey]
		table.insert(tScoreList, {sName=sName, nScore=nScore})
	end
	print("换装总分:", nTotalScore)
	return nTotalScore, tScoreList
end


--取某等级时装数
function CFashion:GetLevelFSCount(nLevel)
	local nCount = 0
	for nID, oFS in pairs(self.m_tFashionMap) do
		if oFS:GetLv() >= nLevel then
			nCount = nCount + 1
		end
	end
	return nCount
end
