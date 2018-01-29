--妃子系统(取消)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CFeiZi:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_tFeiZiMap = {} --已获得妃子对象{[sysid]=obj,..}
	self.m_tUnGetFeiZiMap = {} --未入宫妃子映射{[sysid]=nQinMi,...}

	--不保存
	self.m_tFeiWeiMap = {} --妃位已获得的妃子数{[FeiWei]=nCount,...}
	self.m_nLengGongCount = 0
	self.m_nCount = 0 --已获得妃子数量
end

function CFeiZi:GetType()
	return gtModuleDef.tFeiZi.nID, gtModuleDef.tFeiZi.sName
end

function CFeiZi:LoadData(tData)
	if tData then
		--亲密度
		for sSysID, nQinMi in pairs(tData.m_tUnGetFeiZiMap) do
			local nSysID = tonumber(sSysID)
			if ctFeiZiConf[nSysID] then
				self.m_tUnGetFeiZiMap[nSysID] = nQinMi
			end
		end

		--妃子
		for sSysID, tFZData in pairs(tData.m_tFeiZiMap or {}) do
			local nSysID = tonumber(sSysID)
			if ctFeiZiConf[nSysID] then
				local oFZ = CFZObj:new(self, self.m_oPlayer, nSysID, 0)
				oFZ:LoadData(tFZData)
				self.m_tFeiZiMap[nSysID] = oFZ
				if oFZ:IsInLengGong() then
					self.m_nLengGongCount = self.m_nLengGongCount + 1
				end
				self.m_nCount = self.m_nCount + 1
			end
		end
	end
end

function CFeiZi:SaveData()
	if not self:IsDirty() then return end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tUnGetFeiZiMap = self.m_tUnGetFeiZiMap
	tData.m_tFeiZiMap = {}
	
	for nSysID, _ in pairs(self.m_tFeiZiMap) do
		local oFZ = self.m_tFeiZiMap[nSysID]
		tData.m_tFeiZiMap[nSysID] = oFZ:SaveData()
	end
	return tData
end

--上线
function CFeiZi:Online()
	do return end --(已取消)

	--创建初始就获得的妃子&初始化未入宫妃子
	for nSysID, tConf in pairs(ctFeiZiConf) do
		if tConf.bInitGot then
			if not self.m_tFeiZiMap[nSysID] then
				self:Create(nSysID)
			end
		else
			if not self.m_tFeiZiMap[nSysID] and not self.m_tUnGetFeiZiMap[nSysID] then
				self.m_tUnGetFeiZiMap[nSysID] = 0
				self:MarkDirty(true)
			end
		end
	end
	
	--计算妃位妃子
	self:CalcFeiWei()
	--同步列表
	self:SyncFeiZi()
	--小红点
	self:CheckRedPoint()
end

--妃子数量(已入宫)
function CFeiZi:GetCount()
	return self.m_nCount
end

--妃位数量计算
function CFeiZi:CalcFeiWei()
	self.m_tFeiWeiMap = {}
	for _, oObj in pairs(self.m_tFeiZiMap) do
		local nFeiWei = oObj:FeiWei()
		self.m_tFeiWeiMap[nFeiWei] = (self.m_tFeiWeiMap[nFeiWei] or 0) + 1
	end
end

--妃子容器返回
function CFeiZi:GetFZMap()
	return self.m_tFeiZiMap
end

--妃位数量
function CFeiZi:FeiWeiCount(nFeiWei)
	return (self.m_tFeiWeiMap[nFeiWei] or 0)
end

--增加妃子亲密度
function CFeiZi:AddQinMi(nSysID, nQinMi, sReason)
	if self.m_tFeiZiMap[nSysID] then
		return self.m_tFeiZiMap[nSysID]:AddQinMi(nQinMi, sReason)

	elseif self.m_tUnGetFeiZiMap[nSysID] then
		self.m_tUnGetFeiZiMap[nSysID] = math.max(1, math.min(nMAX_INTEGER, self.m_tUnGetFeiZiMap[nSysID]+nQinMi))
		self:SyncFeiZi(nSysID)
		self:MarkDirty(true)

		if sReason then --通过CPlayer:AddItem不需要在这里写LOG
			local nEventID = nQinMi > 0 and gtEvent.eAddItem or gtEvent.eSubItem
			goLogger:AwardLog(nEventID, sReason, self.m_oPlayer
				, gtItemType.eCurr, gtCurrType.eQinMi, nQinMi, self.m_tUnGetFeiZiMap[nSysID], nSysID)
		end
		return self.m_tUnGetFeiZiMap[nSysID]

	end
end

--直接添加妃子(选秀)
function CFeiZi:Create(nFZID)
	local tConf = assert(ctFeiZiConf[nFZID], "妃子配置不存在:"..nFZID)
	--如果已经有妃子,转成亲密度
	if not self.m_tFeiZiMap[nFZID] then
		self.m_tUnGetFeiZiMap[nFZID] = (self.m_tUnGetFeiZiMap[nFZID] or 0) + tConf.nHoney
		self:RuGongReq(nFZID)
	else
		self.m_tFeiZiMap[nFZID]:AddQinMi(tConf.nExchangeQinMi, "妃子兑换成亲密度")
		goLogger:EventLog(gtEvent.eFeiZiToQinMi, self.m_oPlayer, nFZID)
	end
	return self:GetCount()
end

--入宫妃子(玩家点击)
function CFeiZi:RuGongReq(nSysID)
	if self.m_tFeiZiMap[nSysID] then
		return self.m_oPlayer:Tips("妃子已在宫中:"..nSysID)
	end
	local nQinMi = assert(self.m_tUnGetFeiZiMap[nSysID])
	local nQinMiNeed = ctFeiZiConf[nSysID].nHoney
	assert(nQinMi >= nQinMiNeed, "亲密度不足:"..nSysID)
	
	local oFZ = CFZObj:new(self, self.m_oPlayer, nSysID, nQinMi)
	self.m_tFeiZiMap[nSysID] = oFZ
	self.m_tUnGetFeiZiMap[nSysID] = nil
	self.m_nCount = self.m_nCount + 1
	self:MarkDirty(true)

	self:SyncFeiZi(nSysID)
	self.m_oPlayer:UpdateGuoLi("妃子入宫")
	goLogger:EventLog(gtEvent.eCreateFeiZi, self.m_oPlayer, nSysID)
	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond40, nSysID, 1)
	--更新榜单
	self:OnQinMiChange()
	self:OnNengLiChange()
end

--取妃子对象
function CFeiZi:GetObj(nSysID)
	return self.m_tFeiZiMap[nSysID]
end

--取未入宫妃子信息
function CFeiZi:GetUnGetInfo(nSysID)
	local nQinMi = assert(self.m_tUnGetFeiZiMap[nSysID])
	local tConf = assert(ctFeiZiConf[nSysID])
	local tInfo = {}
	tInfo.nSysID = nSysID
	tInfo.sName = tConf.sName
	tInfo.nQinMi = nQinMi
	tInfo.bRuGong = false
	return tInfo
end

--妃子信息同步
function CFeiZi:SyncFeiZi(nSysID)
	local tList = {}
	if not nSysID then
		for _, oFZ in pairs(self.m_tFeiZiMap) do
			table.insert(tList, oFZ:GetInfo())
		end
		
		for nSysID, nQinMi in pairs(self.m_tUnGetFeiZiMap) do
			table.insert(tList, self:GetUnGetInfo(nSysID))
		end
	else
		if self.m_tFeiZiMap[nSysID] then
			table.insert(tList, self.m_tFeiZiMap[nSysID]:GetInfo())

		elseif self.m_tUnGetFeiZiMap[nSysID] then
			table.insert(tList, self:GetUnGetInfo(nSysID))
		end
	end
	--向客户端发送
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FZListRet", {tList=tList})
	-- print("CFeiZi:SyncFeiZi***", tList)
end

--请安信息请求
function CFeiZi:QingAnInfoReq()
	local tMsg = {
		nJingLi = self.m_oPlayer:GetJingLi(),
		nMaxJingLi = self.m_oPlayer:GetMaxJingLi(),
		nRecoverCD =self.m_oPlayer:GetJingLiRecoverCD(),
	}
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FZQingAnInfoRet", tMsg)
end

--请安请求
function CFeiZi:QingAnReq(bUseProp)
	if bUseProp then
		--使用精力丹
		local tJingLiDan = ctFeiZiEtcConf[1].tQingAnJld[1]
		local nJingLiDan = self.m_oPlayer:GetItemCount(tJingLiDan[1], tJingLiDan[2])
		if nJingLiDan <= 0 then
			return self.m_oPlayer:Tips("精力丹不足")
		end
		self.m_oPlayer:SubItem(tJingLiDan[1], tJingLiDan[2], tJingLiDan[3], "妃子请安")

		--加满精力
		local nAddJingLi = self.m_oPlayer:GetMaxJingLi()
		local tJingLi = ctFeiZiEtcConf[1].tQingAnJingLi[1]
		self.m_oPlayer:AddItem(tJingLi[1], tJingLi[2], nAddJingLi, "妃子请安")
		self.m_oPlayer:Tips("精力已加满")
		return 
	end

	local tJingLi = ctFeiZiEtcConf[1].tQingAnJingLi[1]
	local nJingLi = self.m_oPlayer:GetJingLi()
	if nJingLi < tJingLi[3] then
		return self.m_oPlayer:Tips("精力点不足")
	end
	self.m_oPlayer:SubItem(tJingLi[1], tJingLi[2], tJingLi[3], "妃子请安")

	--所有妃子ID
	local tFZList = {}
	for nID, tConf in pairs(ctFeiZiConf) do
		table.insert(tFZList, nID)
	end

	--随机8个处理
	local nFZNum = ctFeiZiEtcConf[1].nQingAnFZNum
	local tRandList = {}
	for k = 1, nFZNum do
		if #tFZList <= 0 then
			break
		end
		local nIndex = math.random(1, #tFZList)
		table.insert(tRandList, table.remove(tFZList, nIndex))
	end

	--剔除未入宫和冷宫妃子
	local tValidList = {}
	for _, nFZID in ipairs(tRandList) do
		local oFZ = self.m_tFeiZiMap[nFZID]
		if oFZ and not oFZ:IsInLengGong() then
			table.insert(tValidList, oFZ)
		end
	end

	local tMsg = {nYF=0, tList={}}

	--没有随机到有效妃子则随机1个有效的(不会所有妃子都在冷宫)
	--神迹祝福
	local nZhuFu = self.m_oPlayer.m_oShenJiZhuFu:ShenJiZhuFu(gtSJZFDef.eLYZD)
	if nZhuFu <= 0 then nZhuFu = 1 end

	if #tValidList <= 0 then
		local oFZ = self:RandObj(1)[1]
		local tInfo = oFZ:QingAn(0, nZhuFu)
		table.insert(tMsg.tList, tInfo)
	else
		--缘分统计
		local tYuanFenMap = {}
		for _, oFZ in ipairs(tValidList) do
			local tConf = ctFeiZiConf[oFZ:GetID()]
			for _, tYF in ipairs(tConf.tYuanFen) do
				if not tYuanFenMap[tYF[1]] then
					tYuanFenMap[tYF[1]] = {}
				end
				tYuanFenMap[tYF[1]][oFZ:GetID()] = oFZ
			end
		end

		--排序缘分
		local tYuanFenList = {}
		for nYuanFen, tFZMap in pairs(tYuanFenMap) do
			if nYuanFen > 0 then
				local tList = {}
				local tConf = ctYuanFenConf[nYuanFen]
				for _, tFZ in ipairs(tConf.tFZ) do
					local oFZ = tFZMap[tFZ[1]] 
					if oFZ then
						table.insert(tList, oFZ)
					else
						break
					end
				end
				if #tList >= #tConf.tFZ then
					tList.nYF = nYuanFen
					table.insert(tYuanFenList, tList)
				end
			end
		end
		table.sort(tYuanFenList, function(t1, t2) return #t1 > #t2 end)

		if #tYuanFenList > 0 then
			local tList = tYuanFenList[1]
			tMsg.nYF = tList.nYF
			local nTotalShiLi = 0
			for _, oFZ in ipairs(tList) do
				local tInfo = oFZ:QingAn(tList.nYF, nZhuFu)
				table.insert(tMsg.tList, tInfo)
				nTotalShiLi = nTotalShiLi + tInfo.nShiLi
			end
			--电视
			if #tList >= 5 and nZhuFu > 1 then
				local sNotice = string.format(ctLang[4], self.m_oPlayer:GetName(), nTotalShiLi)
				goTV:_TVSend(sNotice)	
			end

		elseif #tValidList > 0 then
			local oFZ = tValidList[math.random(#tValidList)]
			local tInfo = oFZ:QingAn(0, nZhuFu)
			table.insert(tMsg.tList, tInfo)

		else
			return oPlayer:Tips("没有随机到有效妃子")

		end
	end
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "FZQingAnRet", tMsg)
	print("CFeiZi:QingAnReq***", tMsg.nYF)
	--任务
	-- ----self.m_oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond6, 1)
	--self.m_oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond7, 1)
end

--属性加成(值)
function CFeiZi:GetTotalAttr()
	local tTotalAttr = {0, 0, 0, 0}
	for nID, oFZ in pairs(self.m_tFeiZiMap) do
		local tAttr = oFZ:AttrAdd()
		for nAttrID, nAttrVal in pairs(tAttr) do
			tTotalAttr[nAttrID] = tTotalAttr[nAttrID] + nAttrVal

			local tConf = ctFeiZiConf[nID]
			if tConf.nTalents == nAttrID then
				tTotalAttr[nAttrID] = tTotalAttr[nAttrID] + tConf.nGuoLi
			end
		end
	end
	return tTotalAttr
end

--属性加成(百分比)
function CFeiZi:GetTotalAttrPer()
	local tTotalPerAttr = {}
	for nID, oFZ in pairs(self.m_tFeiZiMap) do
		local nAttrID, nPerVal = oFZ:AttrPerAdd()
		tTotalPerAttr[nAttrID] = (tTotalPerAttr[nAttrID] or 0) + nPerVal
	end
	return tTotalPerAttr
end

--冷宫改变
function CFeiZi:OnLengGongChange(bLengGong)
	if bLengGong then
		self.m_nLengGongCount = self.m_nLengGongCount + 1
	else
		self.m_nLengGongCount = self.m_nLengGongCount - 1
	end
end

--是否可以放冷宫
function CFeiZi:CanAddLengGong(nFZID)
	if self.m_nLengGongCount >= self.m_nCount - 2 then
		return 
	end
	return true
end

--妃子是否在冷宫
function CFeiZi:IsInLengGong(nFZID)
	local oFZ = self:GetObj(nFZID)
	if not oFZ then
		return 
	end
	return oFZ:IsInLengGong()
end

--随机妃子(非冷宫)
function CFeiZi:RandObj(nNum)
	local tFZList = {}
	local tTarFZList = {}
	for nID, oFZ in pairs(self.m_tFeiZiMap) do
		if not oFZ:IsInLengGong() then	
			table.insert(tFZList, oFZ)
		end
	end
	if #tFZList <= 0 then
		return tTarFZList
	end
	for k = 1, nNum do
		local nRnd = math.random(1, #tFZList)
		table.insert(tTarFZList, tFZList[nRnd])
		table.remove(tFZList, nRnd)
		if #tFZList <= 0 then break end
	end
	return tTarFZList
end

--所有妃子亲密度
function CFeiZi:GetTotalQinMi()
	local nTotalQinMi = 0
	for nID, oFZ in pairs(self.m_tFeiZiMap) do
		nTotalQinMi = nTotalQinMi + oFZ:GetQinMi()		
	end
	return nTotalQinMi
end

--取可翻牌妃子
function CFeiZi:GetCanOpenCardList()
	local tList = {}
	for nID, oFZ in pairs(self.m_tFeiZiMap) do
		if oFZ:CanOpenCard() then
			table.insert(tList, oFZ)
		end
	end
	return tList
end

--亲密度变化
function CFeiZi:OnQinMiChange()
	local nTotal = 0
	for nID, oFZ in pairs(self.m_tFeiZiMap) do
		nTotal = nTotal + oFZ:GetQinMi()
	end
	goRankingMgr.m_oQMRanking:Update(self.m_oPlayer, nTotal)
end

--能力变化
function CFeiZi:OnNengLiChange()
	local nTotal = 0
	for nID, oFZ in pairs(self.m_tFeiZiMap) do
		nTotal = nTotal + oFZ:GetNengLi()
	end
	goRankingMgr.m_oNLRanking:Update(self.m_oPlayer, nTotal)
end

--才德变化 
function CFeiZi:OnCaiDeChange()
	local nTotal = 0
	for nID, oFZ in pairs(self.m_tFeiZiMap) do
		nTotal = nTotal + oFZ:GetCaiDe()
	end
	goRankingMgr.m_oCDRanking:Update(self.m_oPlayer, nTotal)
end

--宗人府席位信息请求
function CFeiZi:ZRFGridInfoReq()
	local tMsg = {}
	tMsg.nFreeGrids = self.m_oPlayer.m_oZongRenFu:GetFreeGrid()
	tMsg.nMaxGrids = self.m_oPlayer.m_oZongRenFu:GetGrids()
	CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "ZRFGridInfoRet", tMsg)
end

--检测小红点
function CFeiZi:CheckRedPoint()
	local tJingLi = ctFeiZiEtcConf[1].tQingAnJingLi[1]
	local nJingLi = self.m_oPlayer:GetJingLi()
	if nJingLi < tJingLi[3] then
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eKNGQinAn, 0)
	else
		self.m_oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eKNGQinAn, 1)
	end
end

--敬事房妃子休息列表请求
function CFeiZi:JSFCDFZList()
end