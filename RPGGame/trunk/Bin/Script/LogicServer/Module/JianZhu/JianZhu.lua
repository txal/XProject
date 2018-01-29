--建筑
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CJianZhu:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tJZMap = {} --属性建筑
end

function CJianZhu:GetType()
	return gtModuleDef.tJianZhu.nID, gtModuleDef.tJianZhu.sName
end

function CJianZhu:LoadData(tData)
	if tData then
		for sSysID, tJianZhu in pairs(tData) do
			local nSysID = tonumber(sSysID)
			if ctJianZhuConf[nSysID] then
				local oJZ = CJZBase:new(self, self.m_oPlayer, nSysID)
				oJZ:LoadData(tJianZhu)
				self.m_tJZMap[nSysID] = oJZ
			end
		end
	end
	self:OnLoaded()
end

function CJianZhu:OnLoaded()
	for nID, tConf in pairs(ctJianZhuConf) do
		if not self.m_tJZMap[nID] then
			self.m_tJZMap[nID] = CJZBase:new(self, self.m_oPlayer, nID)
			self:MarkDirty(true)
		end
	end
end

function CJianZhu:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)
	local tData = {}
	for nID, oJZ in pairs(self.m_tJZMap) do
		tData[nID] = oJZ:SaveData()
	end
	return tData
end

--取建筑对象
function CJianZhu:GetObj(nID)
	return self.m_tJZMap[nID]
end

--取建筑总加成
function CJianZhu:GetTotalAttr()
	local tAttr, nTotal = {}, 0
	for nID, oJZ in pairs(self.m_tJZMap) do
		local nID, nVal = oJZ:AttrAdd()
		tAttr[nID] = (tAttr[nID] or 0) + nVal
		nTotal = nTotal + nVal
	end
	goRankingMgr.m_oJZRanking:Update(self.m_oPlayer, nTotal) --更新排行榜
	return tAttr, nTotal
end

function CJianZhu:CheckOpen()
	local tConf = ctJianZhuEtcConf[1]
	local nChapter = tConf.nChapter
	if not self.m_oPlayer.m_oDup:IsChapterPass(nChapter) then
		return self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
	end
	return true
end

function CJianZhu:Upgrade(nID)
	if not self:CheckOpen() then
		return
	end
	local oJZ = self.m_tJZMap[nID]
	if not oJZ then
		return self.m_oPlayer:Tips("建筑不存在")
	end
	local nLv = oJZ:Lv()
	if nLv >= #ctJianZhuLvConf then	
		return self.m_oPlayer:Tips("建筑已达等级上限")
	end
	local tLvConf = ctJianZhuLvConf[nLv]
	local tCost = tLvConf.tCost[1]
	if self.m_oPlayer:GetShiLi() < tCost[3] then
		return self.m_oPlayer:Tips("势力点不足")
	end
	oJZ:SetLv(nLv+1)	
	self.m_oPlayer:SubItem(tCost[1], tCost[2], tCost[3], "建筑升级")
	self.m_oPlayer:UpdateGuoLi("建筑升级") --更新国力
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JZUpgradeRet", {nID=nID, nLv=oJZ:Lv()})
	self.m_oPlayer:Tips(string.format("建筑成功升到%d级", oJZ:Lv()))

	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond10, nID, oJZ:Lv(), true)
	--LOG
	goLogger:EventLog(gtEvent.eJianZhu, self.m_oPlayer, ctJianZhuConf[nID].sName, oJZ:Lv())
end

--列表请求
function CJianZhu:ListReq()
	if not self:CheckOpen() then
		return
	end
	local tList = {}
	for nID, oJZ in pairs(self.m_tJZMap) do
		table.insert(tList, {nID=nID, nLv=oJZ:Lv()})
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "JZListRet", {tList=tList})
end
