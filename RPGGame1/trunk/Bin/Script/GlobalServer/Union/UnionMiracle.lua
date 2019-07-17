--联盟奇迹(建筑)

--预处理等级表
local _ctUnionMiracleLevelConf = {}
local function PreProcessConf()
	for _, tConf in ipairs(ctUnionMiracleLevelConf) do
		if not _ctUnionMiracleLevelConf[tConf.nMiracleID] then
			_ctUnionMiracleLevelConf[tConf.nMiracleID] = {}
		end
		table.insert(_ctUnionMiracleLevelConf[tConf.nMiracleID], tConf)
	end	
end
PreProcessConf()

function CUnionMiracle:Ctor(oUnion)
	self.m_oUnion = oUnion
	self.m_tMiracleMap = {} 	--奇迹映射:{[nID]={nExp=0,nLv=1}}
	self.m_tDonateMap = {} 		--捐献次数记录:{[nCharID]=times, ...}
	self.m_nResetTime = os.time()
	self.m_tDonateRecord = {} 	--捐献累积记录{[nCharID]={nTotal,sName,nPos}, ...}

end

--加载玩家数据
function CUnionMiracle:LoadData(tData)
	if tData then
		self.m_tMiracleMap = tData.m_tMiracleMap
		self.m_tDonateMap = tData.m_tDonateMap
		self.m_nResetTime = tData.m_nResetTime
		self.m_tDonateRecord = tData.m_tDonateRecord
	end
end

--保存玩家数据
function CUnionMiracle:SaveData()
	local tData = {}
	tData.m_tMiracleMap = self.m_tMiracleMap
	tData.m_tDonateMap = self.m_tDonateMap
	tData.m_nResetTime = self.m_nResetTime
	tData.m_tDonateRecord = self.m_tDonateRecord
	return tData
end

--设置脏
function CUnionMiracle:MarkDirty(bDirty)
	self.m_oUnion:MarkDirty(bDirty)
end

--检测重置
function CUnionMiracle:CheckReset()
	if not os.IsSameDay(self.m_nResetTime, os.time(), 5*3600) then
		self.m_nResetTime = os.time()
		self.m_tDonateMap = {}
		self:MarkDirty(true)
	end
end

--奇迹列表请求
function CUnionMiracle:MiracleListReq(oPlayer)
	self:CheckReset()
	local nCharID = oPlayer:GetCharID()

	local tList = {}
	for _, tConf in ipairs(ctUnionMiracleConf) do
		local tMiracle = self.m_tMiracleMap[tConf.nID] or {nLv=1, nExp=0}
		local tItem = {nID=tConf.nID, nLv=tMiracle.nLv, nExp=tMiracle.nExp}
		table.insert(tList, tItem)
	end
	local nRemainTimes = ctUnionEtcConf[1].nDayMiracles - (self.m_tDonateMap[nCharID] or 0)
	local tAttrAdd = oPlayer.m_oMingChen:GetTotalUnionAttrAdd()
	local tMsg = {nRemainTimes=nRemainTimes, tList=tList, tAttrAdd=tAttrAdd}
	Network.PBSrv2Clt(oPlayer:GetSession(), "UnionMiracleListRet", tMsg)
	--小红点
	self:CheckRedPoint(oPlayer)
end

--捐献
function CUnionMiracle:DonateReq(oPlayer, nMID, nDID)
	self:CheckReset()
	local nCharID = oPlayer:GetCharID()
	if (self.m_tDonateMap[nCharID] or 0) >= ctUnionEtcConf[1].nDayMiracles then
		return oPlayer:Tips("今日捐献次数已达到上限")
	end

	local tMiracle = self.m_tMiracleMap[nMID] or {nLv=1, nExp=0}
	local tLvConfList = _ctUnionMiracleLevelConf[nMID]
	if tMiracle.nLv >= #tLvConfList then
		return oPlayer:Tips("该奇迹已达等级上限")
	end

	local tDonateConf = ctUnionMiracleDonateConf[nDID]
	local tCost = tDonateConf.tCost[1]
	if oPlayer:GetItemCount(tCost[1], tCost[2]) < tCost[3] then
		return oPlayer:Tips("资源不足")
	end
	oPlayer:SubItem(tCost[1], tCost[2], tCost[3], "奇迹捐献消耗")

	--记录捐献数量
	local tRecord = self.m_tDonateRecord[nCharID]
	if not tRecord then
		tRecord = {0, "", 0}
		self.m_tDonateRecord[nCharID] = tRecord
	end
	tRecord[1] = tRecord[1] + tCost[3]
	tRecord[2] = oPlayer:GetName()
	tRecord[3] = self.m_oUnion:GetPos(nCharID)

	--记录使用次数
	self.m_tDonateMap[nCharID] = (self.m_tDonateMap[nCharID] or 0) + 1

	--增加贡献
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
	oUnionPlayer:AddUnionContri(tDonateConf.nContri, string.format("奇迹捐献奖励%d:%d", nMID, nDID), oPlayer)

	--增加经验
	tMiracle.nExp = tMiracle.nExp + tDonateConf.nExp
	self.m_tMiracleMap[nMID] = tMiracle

	--Tips
	local tMiracleConf = ctUnionMiracleConf[nMID]
	oPlayer:Tips(string.format("贡献+%d", tDonateConf.nContri))
	oPlayer:Tips(string.format("%s经验+%d", tMiracleConf.sName, tDonateConf.nExp))

	--检测升级
	local nOrgLv = tMiracle.nLv
	while tMiracle.nLv < #tLvConfList do
		local tLvConf = tLvConfList[tMiracle.nLv]
		if tMiracle.nExp >= tLvConf.nExp then
			tMiracle.nLv = tMiracle.nLv + 1
			tMiracle.nExp = tMiracle.nExp - tLvConf.nExp
		else
			break
		end
	end
	self:MarkDirty(true)

	--同步
	self:MiracleListReq(oPlayer)
	self.m_oUnion:SyncDetailInfo(oPlayer)

	--升级通知
	if nOrgLv ~= tMiracle.nLv then
		Network.PBSrv2Clt(oPlayer:GetSession(), "UnionMiracleUpgradeRet", {nMID=nMID, nLv=tMiracle.nLv})
		--更新名臣属性
		for nCharID, v in pairs(self.m_oUnion.m_tMemberMap) do
			local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
			if oPlayer then oPlayer.m_oMingChen:OnUnionChange() end
		end
		self.m_oUnion:UpdateGuoLi()
		--奇迹等级变化日志
		self.m_oUnion:_UnionLog(oPlayer)
	end
	--小红点
	self:CheckRedPoint(oPlayer)
	--捐献日志
	goLogger:EventLog(gtEvent.eUnionDonate, oPlayer, self.m_oUnion:GetID(), nMID, nDID, tDonateConf.nContri, tDonateConf.nExp, tMiracle.nLv)
end

--捐献详情请求
function CUnionMiracle:DonateDetailReq(oPlayer)
	local tList = {}
	for nCharID, tLog in pairs(self.m_tDonateRecord) do
		local tItem = {nNum=tLog[1], sName=tLog[2], nPos=tLog[3]}
		table.insert(tList, tItem)
	end
	Network.PBSrv2Clt(oPlayer:GetSession(), "UnionDonateDetailRet", {tList=tList})
end

--取奇迹名臣属性加成百分比
function CUnionMiracle:GetAddPercent()
	local tAttrAdd = {0, 0, 0, 0}
	for _, tConf in ipairs(ctUnionMiracleConf) do
		local tMiracle = self.m_tMiracleMap[tConf.nID] or {nLv=1, nExp=0}
		local tLvConf = _ctUnionMiracleLevelConf[tConf.nID][tMiracle.nLv]
		tAttrAdd[tConf.nAttrType] = (tAttrAdd[tConf.nAttrType] or 0) + tLvConf.nPercent/10000
	end
	return tAttrAdd
end

--小红点检测
function CUnionMiracle:CheckRedPoint(oPlayer)
	oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eUNMiracle, 0)
	do return end --屏蔽奇迹建造小红点
	
	local nCharID = oPlayer:GetCharID()
	if (self.m_tDonateMap[nCharID] or 0) >= ctUnionEtcConf[1].nDayMiracles then
		return oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eUNMiracle, 0)
	end
	oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eUNMiracle, 1)
end

--取建筑等级列表
function CUnionMiracle:GetLevelList()
	local tList = {}
	for _, tConf in ipairs(ctUnionMiracleConf) do
		local tMiracle = self.m_tMiracleMap[tConf.nID] or {nLv=1, nExp=0}
		table.insert(tList, tMiracle.nLv)
	end
	return tList
end

--取今日捐献次数
function CUnionMiracle:GetTodayDonate(nCharID)
	return (self.m_tDonateMap[nCharID] or 0)
end
