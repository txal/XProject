--冷宫(取消)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CLengGong:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nOpenGrid = 1	--解锁格子数
	self.m_tFeiZiMap = {} 	--{[id]=nTime,...}
	self.m_nCount = 0 		--冷宫妃子数量
end

function CLengGong:LoadData(tData)
	if tData then
		self.m_nCount = tData.m_nCount
		self.m_nOpenGrid = tData.m_nOpenGrid

		self.m_tFeiZiMap = {}
		for sID, tTmp in pairs(tData.m_tFeiZiMap) do
			local nID = tonumber(sID)
			self.m_tFeiZiMap[nID] = tTmp
		end
	end
end

function CLengGong:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_nCount = self.m_nCount
	tData.m_nOpenGrid = self.m_nOpenGrid
	tData.m_tFeiZiMap = self.m_tFeiZiMap
	return tData
end

function CLengGong:GetType()
	return gtModuleDef.tLengGong.nID, gtModuleDef.tLengGong.sName
end

--同步信息
function CLengGong:SyncInfo()
	local tMsg = {}
	tMsg.tFZList = {}
	tMsg.nGridCount = self.m_nOpenGrid

	local nTimeSec = os.time()
	local nCD = ctLengGongEtcConf[1].nCallbackCD
	for nFZID, nTime in pairs(self.m_tFeiZiMap) do
		local nRemainTime = math.max(0, nTime+nCD-nTimeSec)
		table.insert(tMsg.tFZList, {nFZID=nFZID, nRemainTime=nRemainTime})
	end

	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "LGInfoRet", tMsg)
end

--是否开放
function CLengGong:IsOpen()
	local nChapter = ctLengGongEtcConf[1].nChapter
	if not self.m_oPlayer.m_oDup:IsChapterPass(nChapter) then
		return self.m_oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
	end
	return true
end

--扩建
function CLengGong:OpenGrid()
	if not self:IsOpen() then
		return
	end
	if self.m_nOpenGrid >= ctLengGongEtcConf[1].nMaxGrid then
		return self.m_oPlayer:Tips("厢房已达上限") --厢房已达上限
	end
	local nOpenGrid = self.m_nOpenGrid + 1
	local nYuanBao = ctLengGongGridConf[nOpenGrid].nYuanBao
	if self.m_oPlayer:GetYuanBao() < nYuanBao then
		return self.m_oPlayer:YBDlg()
	end
	self.m_oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, "冷宫扩建")
	self.m_nOpenGrid = nOpenGrid
	self:MarkDirty(true)
	self:SyncInfo()
	self.m_oPlayer:Tips("冷宫扩建成功")	
end

--打入冷宫
function CLengGong:PutFeiZi(nFZID)
	if not self:IsOpen() then
		return
	end
	local oFZ = self.m_oPlayer.m_oFeiZi:GetObj(nFZID)
	if oFZ:IsInLengGong() then
		self.m_oPlayer:Tips("妃子已在冷宫中")
	end
	if self.m_tFeiZiMap[nFZID] then
		self.m_oPlayer:Tips("数据错误")
	end
	if self.m_nCount >= self.m_nOpenGrid then
		return self.m_oPlayer:Tips("请先扩建冷宫")
	end
	if not self.m_oPlayer.m_oFeiZi:CanAddLengGong(nFZID) then
		return self.m_oPlayer:Tips("皇宫中至少留下两位妃子处理事务")
	end
	self.m_tFeiZiMap[nFZID] = os.time()
	self.m_nCount = self.m_nCount + 1
	self:MarkDirty(true)

	oFZ:AddQinMi(-ctLengGongEtcConf[1].nSubQinMi, "将妃子放入冷宫")
	oFZ:SetLengGong(true)
	self:SyncInfo()
end

--冷宫召回
function CLengGong:CallFeiZi(nFZID)
	local oFZ = self.m_oPlayer.m_oFeiZi:GetObj(nFZID)
	assert(oFZ, "妃子不存在:"..nFZID)
	assert(oFZ:IsInLengGong(), "妃子不在冷宫:"..nFZID)
	assert(self.m_tFeiZiMap[nFZID], "数据错误")

	--冷却时间判断
	local nCD = ctLengGongEtcConf[1].nCallbackCD
	if os.time() - self.m_tFeiZiMap[nFZID] < nCD then
		return self.m_oPlayer:Tips("冷却时间未到不能召回妃子") --
	end

	--移出冷宫
	self.m_tFeiZiMap[nFZID] = nil
	self.m_nCount = self.m_nCount - 1
	self:MarkDirty(true)

	oFZ:SetLengGong(false)
	self:SyncInfo()
end