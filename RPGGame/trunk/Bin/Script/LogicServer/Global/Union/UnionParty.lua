--联盟副本系统(打BOSS)

--BOSS状态
CUnionParty.tState = 
{
	eInit = 0, 		--可举办
	eParty = 1, 	--举办中
	eKilled = 2, 	--已击杀	
	eLocked = 3,	--未达开放条件
}

local nPartyTime = 24*3600 --副本时间

function CUnionParty:Ctor(oUnion)
	self.m_oUnion = oUnion
	self.m_tBossMap = {} 	--BOSS列表{[nID]={nBlood=0,nTime=0,nState=0, tResult={[nCharID]={sName,nHurt,nContri}, ..}}, ...}
	self.m_nResetTime = os.time()
	self.m_tMCMap = {} 		--出战知己{[nCharID]={[nMCID]=0, ...}, ...}
	self.m_tMCRecMap = {} 	--出战恢复{[charid]={[mcid]=1,...},...}

end

--加载玩家数据
function CUnionParty:LoadData(tData)
	if tData then
		--BOSS
		self.m_tBossMap = tData.m_tBossMap
		self.m_nResetTime = tData.m_nResetTime

		--知己
		for nCharID, tMCMap in pairs(tData.m_tMCMap or {}) do
			if type(tMCMap) == "table" then
				self.m_tMCMap[nCharID] = {}
				for nMCID, v in pairs(tMCMap) do
					if ctMingChenConf[nMCID] then
						self.m_tMCMap[nCharID][nMCID] = v
					end
				end
			end
		end

		--恢复次数
		self.m_tMCRecMap = tData.m_tMCRecMap or {}
	end
end

--保存玩家数据
function CUnionParty:SaveData()
	local tData = {}
	tData.m_tBossMap = self.m_tBossMap
	tData.m_nResetTime = self.m_nResetTime	
	tData.m_tMCMap = self.m_tMCMap
	tData.m_tMCRecMap = self.m_tMCRecMap
	return tData
end

--设置脏
function CUnionParty:MarkDirty(bDirty)
	self.m_oUnion:MarkDirty(bDirty)
end

--检测BOSS状态
function CUnionParty:CheckState()
	--检测重置
	if not os.IsSameDay(self.m_nResetTime, os.time(), 5*3600) then
		self.m_nResetTime = os.time()

		--重置BOSS
		for nID, tBoss in pairs(self.m_tBossMap) do
			if tBoss.nState == CUnionParty.tState.eKilled then
				self.m_tBossMap[nID] = nil
			end
		end

		--重置知己
		self.m_tMCMap = {}
		self.m_tMCRecMap = {}

		self:MarkDirty(true)
	end

	--检测状态
	for nID, tBoss in pairs(self.m_tBossMap) do
		if tBoss.nState == CUnionParty.tState.eParty then
			local nRemainTime = tBoss.nTime + nPartyTime - os.time()
			if nRemainTime <= 0 then
				self.m_tBossMap[nID] = nil
				self:MarkDirty(true)
			end

		end
	end
end

--取BOSS状态
function CUnionParty:GetState(nID)
	local tBoss = self.m_tBossMap[nID]
	local nRemainTime = 0
	if not tBoss then
		local tConf = ctUnionPartyConf[nID]
		if tConf.nUnionLv > self.m_oUnion:GetLevel() then
			return CUnionParty.tState.eLocked, nRemainTime, tConf.nBossHP
		else
			return CUnionParty.tState.eInit, nRemainTime, tConf.nBossHP
		end
	end
	if tBoss.nState == CUnionParty.tState.eParty then --举办中
		nRemainTime = (tBoss.nTime+nPartyTime-os.time())
		return tBoss.nState, nRemainTime, tBoss.nBlood
	else --已被击杀/可举办
		return tBoss.nState, nRemainTime, tBoss.nBlood
	end
end

--列表请求
function CUnionParty:PartyListReq(oPlayer)
	self:CheckState()

	local tList = {}
	for nID, tConf in ipairs(ctUnionPartyConf) do
		local nState, nRemainTime, nBlood = self:GetState(nID)
		local tItem = {nID=nID, nState=nState, nBlood=nBlood, nRemainTime=nRemainTime}
		table.insert(tList, tItem)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionPartyListRet", {tList=tList})
	
	--小红点
	self:CheckRedPoint(oPlayer)
end

--排行榜请求
function CUnionParty:RankingReq(oPlayer, nID)
	self:CheckState()
	local nState = self:GetState(nID)
	if nState ~= CUnionParty.tState.eKilled then
		return oPlayer:Tips("BOSS未击杀没有副本详情")
	end

	local tList = {}
	local tBoss = self.m_tBossMap[nID]
	for nCharID, tRank in pairs(tBoss.tResult) do
		local tItem = {sName=tRank.sName, nHurt=tRank.nHurt, nContri=tRank.nContri}
		table.insert(tList, tItem)
	end

	local sKiller, nGotExp = "", 0
	if tBoss.tKill then
		sKiller = tBoss.tKill.sCharName or ""
		nGotExp = tBoss.tKill.nExp or 0
	end
	local nBossLv = ctUnionPartyConf[nID].nPartyLv
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionPartyRankingRet", {tList=tList, sKiller=sKiller, nGotExp=nGotExp, nBossLv=nBossLv})
	print("CUnionParty:RankingReq***", tList)
end

--开启副本
function CUnionParty:OpenPartyReq(oPlayer, nID, nType)
	assert(nType == 1 or nType == 2, "消耗类型错误")
	self:CheckState()

	local nState = self:GetState(nID)
	if nState ~= CUnionParty.tState.eInit then
		return oPlayer:Tips("副本不是可举办状态")
	end

	local tConf = ctUnionPartyConf[nID]
	local nCharID = oPlayer:GetCharID()
	if nType == 1 then --元宝
		if self.m_oUnion:IsMember(nCharID) then
			return oPlayer:Tips("盟主、副盟主、精英才能使用元宝开启副本")
		end
		if oPlayer:GetYuanBao() < tConf.nYuanBao then
			return oPlayer:YBDlg()
		end
		oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, tConf.nYuanBao, "开启副本")

	elseif nType == 2 then --联盟财富(活跃点)
		if not self.m_oUnion:IsMengZhu(nCharID) and not self.m_oUnion:IsFuMengZhu(nCharID) then
			return oPlayer:Tips("盟主、副盟主才能使用联盟财富开启副本")
		end
		if self.m_oUnion:GetActivity() < tConf.nActivity then
			return oPlayer:Tips("联盟财富不足")
		end
		self.m_oUnion:AddActivity(-tConf.nActivity, "开启副本消耗", oPlayer)

	end
	self.m_tBossMap[nID] = {nBlood=tConf.nBossHP, nTime=os.time(), nState=CUnionParty.tState.eParty, tResult={}, tRecord={}, tKill={}}
	oPlayer:Tips(string.format("成功开机%d级副本", tConf.nPartyLv))
	self.m_oUnion:BroadcastUnion(string.format("%d级副本开启，大家赶紧前往击败BOSS吧", tConf.nPartyLv))
	self:MarkDirty(true)
	self:PartyListReq(oPlayer)
end

--BOSS界面信息请求
function CUnionParty:BossInfoReq(oPlayer, nPartyID)
	self:CheckState()
	self:AutoSelectMC(oPlayer, nPartyID)

	local nCharID = oPlayer:GetCharID()
	local nState, nRemainTime, nBlood = self:GetState(nPartyID)
	local tBoss = self.m_tBossMap[nPartyID]

	local nMCPower = 0
	local sMCName = ""
	local nTarMCID = self:GetCurrMC(oPlayer)
	if nTarMCID > 0 then
		local oMC = oPlayer.m_oMingChen:GetObj(nTarMCID)
		nMCPower = oMC:GetPower()
		sMCName = oMC:GetName()
	end

	local tRecord = {}
	if tBoss.tRecord then
		tRecord = tBoss.tRecord[nCharID] or {}
	end
	local tMsg = {nPartyID=nPartyID, nState=nState, nBlood=nBlood, tRecord=tRecord
		, nMCID=nTarMCID, nMCPower=nMCPower, sMCName=sMCName}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionPartyBossRet", tMsg)
end

--出战知己
function CUnionParty:AddMCReq(oPlayer, nMCID)
	self:CheckState()

	local oMC = oPlayer.m_oMingChen:GetObj(nMCID)
	if not oMC then
		return oPlayer:Tips("知己不存在")
	end

	-- local nLiangCao = oPlayer:GetLiangCao()
	-- if self:CalcLianCao(oFZ:GetNengLi()) > nLiangCao then
	-- 	return oPlayer:Tips("粮草不足")
	-- end

	local nCharID = oPlayer:GetCharID()
	local tMCMap = self.m_tMCMap[nCharID] or {}

	if (tMCMap[nMCID] or 0) == 1 then
		return oPlayer:Tips("知己已经出战过")
	end

	--只能出战一个
	for nMCID, nFlag in pairs(tMCMap) do
		if nFlag == 0 then
			tMCMap[nMCID] = nil
		end
	end

	tMCMap[nMCID] = 0
	self.m_tMCMap[nCharID] = tMCMap
	self:MarkDirty(true)
	
	self:SyncMCList(oPlayer)
end

--撤下知己
function CUnionParty:RemoveFZReq(oPlayer, nMCID)
	self:CheckState()

	local nCharID = oPlayer:GetCharID()
	local tMCMap = self.m_tMCMap[nCharID] or {}
	if (tMCMap[nMCID] or 0) == 1 then
		return oPlayer:Tips("今天已经打过，撤下知己失败")
	end
	tMCMap[nMCID] = nil
	self:MarkDirty(true)
	self:SyncMCList(oPlayer)
end

--计算粮食消耗
-- function CUnionParty:CalcLianCao(nNengLi)
-- 	local tCost = ctUnionEtcConf[1]
-- 	local nNum1 = tCost.nNum1
-- 	local nNum2 = tCost.nNum2
-- 	local nLSCost = math.floor((nNengLi^tCost.nLSCost)*nNum1+nNengLi*nNum2)
-- 	return nLSCost
-- end

--自动添加默认知己(bNotUp不上阵)
function CUnionParty:AutoSelectMC(oPlayer, nPartyID, bNotUp)
	local nCharID = oPlayer:GetCharID()
	local tMCMap = self.m_tMCMap[nCharID] or {}
	-- local nLiangCao = oPlayer:GetLiangCao()

	--筛选知己
	local tPowerList = {}
	local tMCObjMap = oPlayer.m_oMingChen:GetMCMap()
	for nID, oObj in pairs(tMCObjMap) do
		local nPower = oObj:GetPower()
		if (tMCMap[nID] or 0) == 0 then
			table.insert(tPowerList, {nID, nPower})
		end
	end
	if #tPowerList <= 0 then
		return 0
	end
	table.sort(tPowerList, function(t1, t2) return t1[2] < t2[2] end)

	--优先出战能击杀该BOSS且造成伤害最低的知己,如果所有知己都不能击杀该BOSS,则出战伤害最高的知己
	local nTarMCID = 0
	local tBoss = self.m_tBossMap[nPartyID]
	local nBlood = tBoss.nBlood
	for _, tMC in ipairs(tPowerList) do
		nTarMCID = tMC[1]
		if tMC[2] >= nBlood then
			break
		end
	end
	if nTarMCID <= 0 then
		return nTarMCID
	end

	if not bNotUp then
		--只能上阵一个
		for nMCID, nFlag in pairs(tMCMap) do
			if nFlag == 0 then
				tMCMap[nMCID] = nil
			end
		end
		--上阵目标知己
		tMCMap[nTarMCID] = 0
		self.m_tMCMap[nCharID] = tMCMap
		self:MarkDirty(true)
	end
	return nTarMCID
end

--知己列表请求
function CUnionParty:MCListReq(oPlayer, nPartyID)
	self:CheckState()
	if not ctUnionPartyConf[nPartyID] then
		return oPlayer:Tips("副本ID:"..nPartyID.."不存在")
	end
	local nState = self:GetState(nPartyID)
	if nState ~= CUnionParty.tState.eParty then
		return oPlayer:Tips("副本已经结束或者未开始")
	end
	self:SyncMCList(oPlayer)
end

--同步知己列表
function CUnionParty:SyncMCList(oPlayer)
	self:CheckState()

	local nCharID = oPlayer:GetCharID()
	local tMCOutMap = self.m_tMCMap[nCharID] or {}
	local tMCRecMap = self.m_tMCRecMap[nCharID] or {}

	local tList = {}
	local tMCMap = oPlayer.m_oMingChen:GetMCMap()
	for nID, oMC in pairs(tMCMap) do
		local tInfo = {}
		tInfo.nID = nID
		tInfo.sName = oMC:GetName()
		tInfo.nLv = oMC:GetLevel()
		tInfo.nAttr = oMC:GetQua(4)
		tInfo.nPower = oMC:GetPower()
		if not tMCOutMap[nID] then
			tInfo.nState = 0 --可出战

		elseif tMCOutMap[nID] == 0 then
			tInfo.nState = 1 --出战中

		elseif tMCOutMap[nID] == 1 then
			if not tMCRecMap[nID] then
				tInfo.nState = 2 --可恢复
			else 
				tInfo.nState = 3 --已出战
			end

		end
		table.insert(tList, tInfo)
	end

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionPartyMCListRet", {tList=tList})
	print("CUnionParty:SyncMCList***", tList)
end

--重置知己列表请求
function CUnionParty:RecoverMCReq(oPlayer, nMCID)
	self:CheckState()
	local nCharID = oPlayer:GetCharID()
	local tMCMap = self.m_tMCMap[nCharID] or {}
	local tMCRecMap = self.m_tMCRecMap[nCharID] or {}
	--没有出战过
	if (tMCMap[nMCID] or 0) ~= 1 then
		return
	end
	--已恢复过
	if tMCRecMap[nMCID] then
		return oPlayer:Tips("每天只能恢复一次，请明日再来")
	end
	local nPropID = 30524 --出战令
	if oPlayer:GetItemCount(gtItemType.eProp, nPropID) <= 0 then
		return oPlayer:Tips(string.format("%s不足", CGuoKu:PropName(nPropID)))
	end
	oPlayer:SubItem(gtItemType.eProp, nPropID, 1, "知己恢复出战")
	tMCMap[nMCID] = nil
	tMCRecMap[nMCID] = 1
	self.m_tMCMap[nCharID] = tMCMap
	self.m_tMCRecMap[nCharID] = tMCRecMap
	self:MarkDirty(true)
	self:SyncMCList(oPlayer)
end

--取当前上阵知己
function CUnionParty:GetCurrMC(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tMCMap = self.m_tMCMap[nCharID] or {}
	local nTarMCID = 0
	for nMCID, nState in pairs(tMCMap) do
		if nState == 0 then
			nTarMCID = nMCID 
			break
		end
	end
	return nTarMCID
end

--开战
function CUnionParty:StartBattleReq(oPlayer, nID, bAuto)
	self:CheckState()

	local nState = self:GetState(nID)
	if nState == CUnionParty.tState.eKilled then
		return oPlayer:Tips("BOSS已被击杀")
	end
	if nState ~= CUnionParty.tState.eParty then
		return oPlayer:Tips("副本未开始")
	end
	local nCharID = oPlayer:GetCharID()

	local tRound = {}
	local nTotalHurt = 0
	local tBoss = self.m_tBossMap[nID]
	local nOrgBlood = tBoss.nBlood

	local tMCMap = self.m_tMCMap[nCharID] or {}
	self.m_tMCMap[nCharID] = tMCMap

	if not tBoss.tRecord then
		tBoss.tRecord = {}
	end
	local tRecordList = tBoss.tRecord[nCharID] or {}
	tBoss.tRecord[nCharID] = tRecordList

	if bAuto then --自动战斗
		if oPlayer:GetVIP() < ctUnionEtcConf[1].nPartyVIP then
			return oPlayer:Tips(string.format("需要VIP%d才能自动战斗", ctUnionEtcConf[1].nPartyVIP))
		end
		--开始战斗
		local nTarMCID = self:GetCurrMC(oPlayer)
		if nTarMCID == 0 then
			return oPlayer:Tips("请选择出战知己")
		end
		repeat
			local oMC = oPlayer.m_oMingChen:GetObj(nTarMCID)
			local nPower = oMC:GetPower()
			tMCMap[nTarMCID] = 1

			local nHurt = math.min(nPower, tBoss.nBlood)
			tBoss.nBlood = tBoss.nBlood - nHurt
			nTotalHurt = nTotalHurt + nHurt
			table.insert(tRound, {nMCID=nTarMCID, nHurt=nHurt})
			table.insert(tRecordList, 1, {sName=oPlayer:GetName(), sMCName=oMC:GetName(), nHurt=nHurt, nTime=os.time()})
			if #tRecordList > 100 then
				table.remove(tRecordList)
			end
			if tBoss.nBlood == 0 then
				tBoss.nState = CUnionParty.tState.eKilled
				break
			end
			nTarMCID = self:AutoSelectMC(oPlayer, nID)

		until (nTarMCID <= 0)

	else
		local nTarMCID = self:GetCurrMC(oPlayer)
		if nTarMCID <= 0 then
			return oPlayer:Tips("请选择出战知己")
		end
		local oMC = oPlayer.m_oMingChen:GetObj(nTarMCID)
		local nPower = oMC:GetPower()
		tMCMap[nTarMCID] = 1

		local nHurt = math.min(nPower, tBoss.nBlood)
		tBoss.nBlood = tBoss.nBlood - nHurt
		nTotalHurt = nTotalHurt + nHurt
		table.insert(tRound, {nMCID=nTarMCID, nHurt=nHurt})
		table.insert(tRecordList, 1, {sName=oPlayer:GetName(), sMCName=oMC:GetName(), nHurt=nHurt, nTime=os.time()})
		if #tRecordList > 100 then
			table.remove(tRecordList)
		end
		if tBoss.nBlood == 0 then
			tBoss.nState = CUnionParty.tState.eKilled
		end
	end

	--结算
	--获得贡献=int（对BOSS造成伤害/BOSS总血量*总贡献）
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
	local tConf = ctUnionPartyConf[nID]
	local nFullBlood = tConf.nBossHP
	local nContri = math.floor(nTotalHurt/nFullBlood*tConf.nContri)
	oUnionPlayer:AddUnionContri(nContri, "联盟副本奖励", oPlayer)

	--记录结果
	local sName = oPlayer:GetName()
	local tInfo = tBoss.tResult[nCharID] or {}
	tInfo.sName = sName
	tInfo.nHurt = (tInfo.nHurt or 0) + nTotalHurt
	tInfo.nContri = (tInfo.nContri or 0) + nContri
	tBoss.tResult[nCharID] = tInfo

	--击杀奖励
	local nExp, tExtAward = 0, {}
	if tBoss.nBlood == 0 then
		nExp = tConf.nExp
		self.m_oUnion:AddExp(nExp, "联盟副本奖励", oPlayer)
		local tAward = tConf.tExtAward[1]
		if tAward[1] > 0 then
			oPlayer:AddItem(tAward[1], tAward[2], tAward[3], "联盟副本奖励")
			table.insert(tExtAward, {nType=tAward[1], nID=tAward[2], nNum=tAward[3]})
		end

		tBoss.tKill = tBoss.tKill or {}
		tBoss.tKill.sCharName = oPlayer:GetName()
		tBoss.tKill.nExp = nExp
	end
	self:MarkDirty(true)

	local tMsg = {nBossHP=nOrgBlood, nTotalHurt=nTotalHurt, nContri=nContri, nExp=nExp, tExtAward=tExtAward, tRound=tRound}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionPartyBattleRet", tMsg)
	self:SyncMCList(oPlayer)
	self:PartyListReq(oPlayer)
	--小红点
	self:CheckRedPoint(oPlayer)
end

--小红点检测
function CUnionParty:CheckRedPoint(oPlayer)
	self:CheckState()
	for nID, tConf in ipairs(ctUnionPartyConf) do
		local nState = self:GetState(nID)
		if nState == CUnionParty.tState.eParty then
			if self:AutoSelectMC(oPlayer, nID, true) > 0 then
				return oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eUNParty, 1)
			end
		end
	end
	oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eUNParty, 0)
end

--GM重置知己出战
function CUnionParty:GMResetFZ(oPlayer)
	local nCharID = oPlayer:GetCharID()
	self.m_tMCMap[nCharID] = {}
	self.m_tMCRecMap[nCharID] = {}
	self:MarkDirty(true)
	oPlayer:Tips("重置联盟副本知己成功")
end