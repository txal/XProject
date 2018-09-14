--联盟类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--日志上限
local nMaxLog = 10
--名字上限
CUnion.nMaxUnionNameLen = 18
--公告上限
CUnion.nMaxUnionDeclLen = 180

--联盟职位
CUnion.tPosition = 
{
	eMengZhu = 1,		--盟主
	eFuMengZhu = 2, 	--副盟主
	eJingYing = 3, 		--精英
	eMember = 4, 		--成员
}

--日志类型
CUnion.tLog = 
{
	eCreate = 1,	--创建联盟
	eJoin = 2, 		--加入联盟
	eExit = 3, 		--离开联盟
	eAppoint = 4, 	--任命职位
}

--退出联盟类型
CUnion.tExit = 
{
	eExit = 1,		--主动退出
	eKick = 2,		--被移出
	eDismiss = 3, 	--解散
}

--联盟对象
function CUnion:Ctor()
	self.m_nID = 0  		--公会ID
	self.m_sName = "" 		--公会名字
	self.m_nMembers = 0 	--成员数量
	self.m_nMengZhu = 0  	 --盟主ID
	self.m_sDeclaration = "" --联盟公告

	self.m_nLv = 1 			--联盟等级
	self.m_nExp = 0 		--联盟经验
	self.m_nTotalAddExp = 0 --总增加经验
	self.m_nGuoLi = 0 		--联盟总国力
	self.m_nActivity = 0 	--联盟活跃点
	self.m_nAutoJoin = ctUnionEtcConf[1].nAutoJoin		--1非审批(自动); 0审批

	self.m_tMemberMap = {} --{[nCharID]=1}
	self.m_tFuMengZhuMap = {} --{[nCharID]=1}
	self.m_tJingYingMap = {} --{[nCharID]=1}
	self.m_tApplyPlayerMap = {} --{[nCharID]=time}
	self.m_tLogList = {} --{{nLogType, sName, sName, nValue, nTime},...}

	self.m_tBuildMap = {} 	--建设记录
	self.m_nBuildResetTime = os.time() --建设重置时间

	self.m_tExchangeMap = {} --兑换记录
	self.m_nExchangeResetTime = os.time() --兑换重置时间

	--子系统
	self.m_oUnionParty = CUnionParty:new(self) 		--联盟宴会
	self.m_oUnionMiracle = CUnionMiracle:new(self) 	--联盟奇迹
end

--玩家创建联盟时调用
function CUnion:CreateInit(oPlayer, nID, sName, sNotice)
	local nCharID = oPlayer:GetCharID()
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(nCharID))
	self.m_nID = nID
	self.m_sName = sName
	self.m_nMengZhu = nCharID
	self.m_sDeclaration = sNotice

	assert(self:JoinUnion(oPlayer, nCharID))
	self:MarkDirty(true)

	goLogger:EventLog(gtEvent.eCreateUnion, oPlayer, self.m_nID, self.m_sName)
	return true
end

--加载联盟数据
function CUnion:LoadData(tData)
	self.m_nID = tData.m_nID
	self.m_sName = tData.m_sName
	self.m_nMembers = tData.m_nMembers
	self.m_nMengZhu = tData.m_nMengZhu
	self.m_sDeclaration = tData.m_sDeclaration

	self.m_nLv = math.max(1, tData.m_nLv)
	self.m_nExp = tData.m_nExp or 0
	self.m_nTotalAddExp = tData.m_nTotalAddExp or 0
	self.m_nGuoLi = tData.m_nGuoLi
	self.m_nActivity = tData.m_nActivity
	self.m_nAutoJoin = tData.m_nAutoJoin

	--成员列表
	self.m_nMembers = 0
	for nCharID, nFlag in pairs(tData.m_tMemberMap) do
		local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
		if oUnionPlayer and oUnionPlayer:Get("m_nUnionID") == self.m_nID then
			self.m_tMemberMap[nCharID] = nFlag
			self.m_nMembers = self.m_nMembers + 1
		else
			LuaTrace("union:"..self.m_nID.." member error")
			self:MarkDirty(true)
		end
	end

	--盟主
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(self.m_nMengZhu)
	if not oUnionPlayer or oUnionPlayer:Get("m_nUnionID") ~= self.m_nID then
		self.m_nMengZhu = nil
	end

	if self.m_nMembers == 0 or not self.m_nMengZhu then
		return goUnionMgr:OnUnionDismiss(self)
	end

	--副盟主
	for nCharID, nFlag in pairs(tData.m_tFuMengZhuMap) do
		local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
		if oUnionPlayer and oUnionPlayer:Get("m_nUnionID") == self.m_nID then
			self.m_tFuMengZhuMap[nCharID] = nFlag
		else
			LuaTrace("union:"..self.m_nID.." member error")
			self:MarkDirty(true)
		end
	end

	--精英
	for nCharID, nFlag in pairs(tData.m_tJingYingMap) do
		local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
		if oUnionPlayer and oUnionPlayer:Get("m_nUnionID") == self.m_nID then
			self.m_tJingYingMap[nCharID] = nFlag
		else
			LuaTrace("union:"..self.m_nID.." member error")
			self:MarkDirty(true)
		end
	end

	--申请
	self.m_tApplyPlayerMap = tData.m_tApplyPlayerMap

	--日志列表
	self.m_tLogList = tData.m_tLogList

	--建设记录
	self.m_nBuildResetTime = tData.m_nBuildResetTime or os.time()
	self.m_tBuildMap = tData.m_tBuildMap

	--兑换记录
	self.m_nExchangeResetTime = tData.m_nExchangeResetTime or os.time()
	self.m_tExchangeMap = tData.m_tExchangeMap

	--子系统
	self.m_oUnionParty:LoadData(tData.tUnionParty)
	self.m_oUnionMiracle:LoadData(tData.tUnionMiracle)

	return true
end

--保存联盟数据
function CUnion:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_sName = self.m_sName
	tData.m_nMembers = self.m_nMembers
	tData.m_nMengZhu = self.m_nMengZhu
	tData.m_sDeclaration = self.m_sDeclaration

	tData.m_nLv = self.m_nLv
	tData.m_nExp = self.m_nExp
	tData.m_nTotalAddExp = self.m_nTotalAddExp
	tData.m_nGuoLi = self.m_nGuoLi
	tData.m_nActivity = self.m_nActivity
	tData.m_nAutoJoin = self.m_nAutoJoin

	tData.m_tMemberMap = self.m_tMemberMap
	tData.m_tFuMengZhuMap = self.m_tFuMengZhuMap
	tData.m_tJingYingMap = self.m_tJingYingMap
	tData.m_tApplyPlayerMap = self.m_tApplyPlayerMap
	tData.m_tLogList = self.m_tLogList
	tData.m_tBuildMap = self.m_tBuildMap
	tData.m_nBuildResetTime = self.m_nBuildResetTime
	tData.m_tExchangeMap = self.m_tExchangeMap
	tData.m_nExchangeResetTime = self.m_nExchangeResetTime

	--子系统
	tData.tUnionParty = self.m_oUnionParty:SaveData()
	tData.tUnionMiracle = self.m_oUnionMiracle:SaveData()
	return tData
end

--取玩家职位
function CUnion:GetPos(nCharID)
	local nPos = CUnion.tPosition.eMember
	if self:IsMengZhu(nCharID) then
		nPos = CUnion.tPosition.eMengZhu

	elseif self:IsFuMengZhu(nCharID) then
		nPos = CUnion.tPosition.eFuMengZhu

	elseif self:IsJingYing(nCharID) then
		nPos = CUnion.tPosition.eJingYing

	end
	return nPos
end

--ID
function CUnion:GetID() return self.m_nID end
--名称
function CUnion:GetName() return self.m_sName end
--等级
function CUnion:GetLevel() return self.m_nLv end
--设置脏
function CUnion:MarkDirty(bDirty) goUnionMgr:MarkUnionDirty(self.m_nID, bDirty) end
--是否盟主
function CUnion:IsMengZhu(nCharID) return self.m_nMengZhu == nCharID end
--是否副盟主
function CUnion:IsFuMengZhu(nCharID) return self.m_tFuMengZhuMap[nCharID] end
--是否精英
function CUnion:IsJingYing(nCharID) return self.m_tJingYingMap[nCharID] end
--是否成员
function CUnion:IsMember(nCharID) return not (self:IsMengZhu(nCharID) or self:IsFuMengZhu(nCharID) or self:IsJingYing(nCharID)) end
--是否已满
function CUnion:IsFull() return self.m_nMembers >= self:MaxMembers() end
--是否允许自动加入
function CUnion:IsAutoJoin() return self.m_nAutoJoin == 1 end
--取活跃点
function CUnion:GetActivity() return self.m_nActivity end

--盟主名字
function CUnion:GetMengZhuName()
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(self.m_nMengZhu)
	return oUnionPlayer:GetName()
end

--人数
function CUnion:GetMembers()
	return self.m_nMembers
end

--成员表
function CUnion:GetMemberMap()
	return self.m_tMemberMap
end

--人数上限
function CUnion:MaxMembers()
	local tConf = ctUnionLevelConf[self.m_nLv]
	return tConf.nMaxMembers
end

--当前副盟主个数
function CUnion:FuMengZhuNum()
	local nCount = 0
	for k, v in pairs(self.m_tFuMengZhuMap) do
		nCount = nCount + 1
	end 
	return nCount
end

--副盟主最大个数
function CUnion:MaxFuMengZhuNum()
	local tConf = ctUnionLevelConf[self.m_nLv]
	return tConf.nFMZNum
end

--当前精英个数
function CUnion:JingYingNum()
	local nCount = 0
	for k, v in pairs(self.m_tJingYingMap) do
		nCount = nCount + 1
	end 
	return nCount
end

--精英上限
function CUnion:MaxJingYingNum()
	local tConf = ctUnionLevelConf[self.m_nLv]
	return tConf.nJYNum
end

--退出联盟
function CUnion:ExitUnion(nCharID, nExitType)
	if not self.m_tMemberMap[nCharID] then
		return
	end
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(nCharID))
	assert(oUnionPlayer:Get("m_nUnionID") == self.m_nID)
	if nCharID == self.m_nMengZhu then
		return self:Dismiss() --盟主退出解散
	end
	oUnionPlayer:OnExitUnion(nExitType)
	self.m_tMemberMap[nCharID] = nil
	self.m_tFuMengZhuMap[nCharID] = nil
	self.m_tJingYingMap[nCharID] = nil
	self.m_nMembers = self.m_nMembers - 1
	self:MarkDirty(true)
	self:AddLog(CUnion.tLog.eExit, oUnionPlayer:GetName(), "", 0)
	--联盟国力排行
	self:UpdateGuoLi()
	return true
end

--解散联盟
function CUnion:Dismiss()
	print("CUnion:Dismiss***")
	for nCharID, v in pairs(self.m_tMemberMap) do
		local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(nCharID))
		oUnionPlayer:OnExitUnion(CUnion.tExit.eDismiss)
	end
	goUnionMgr:OnUnionDismiss(self)

	local oPlayer = goPlayerMgr:GetPlayerByCharID(self.m_nMengZhu)
	goLogger:EventLog(gtEvent.eDismissUnion, oPlayer, self.m_nID)

	--移除联盟国力/经验排行
	goRankingMgr.m_oUGLRanking:Remove(self.m_nID)
	goRankingMgr.m_oUnExpRanking:Remove(self.m_nID)
end

--设置联盟名称
function CUnion:SetName(oPlayer, sName)
	sName = string.Trim(sName)
	assert(sName ~= "")
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	if string.len(sName) > CUnion.nMaxUnionNameLen then
		return oPlayer:Tips("名字超长，不能超过6个汉字")
	end
	self.m_sName = sName
	self:MarkDirty(true)
	self:_UnionLog(oPlayer)
	return true
end

--设置宣言
function CUnion:SetDeclaration(oPlayer, sDesc)
	sDesc = string.Trim(sDesc)
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	if string.len(sDesc) > CUnion.nMaxUnionDeclLen then
		return oPlayer:Tips("公告超长，不能超过60个汉字")
	end
	self.m_sDeclaration = sDesc
	self:MarkDirty(true)
	oPlayer:Tips("成功修改联盟公告")
	return true
end

--设置审批否
function CUnion:SetAutoJoin(oPlayer, nAutoJoin)
	assert(nAutoJoin == 0 or nAutoJoin == 1)
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	self.m_nAutoJoin = nAutoJoin
	self:MarkDirty(true)
	return true
end

--扩展人数
function CUnion:ExtendMembers(oPlayer)
	print("CUnion:ExtendMembers***")
end

--清除进入联盟的玩家的申请信息
function CUnion:ClearPlayerApply(nCharID)
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(nCharID))
	for nUnionID, nTime in pairs(oUnionPlayer:Get("m_tApplyUnionMap")) do
		local oUnion = goUnionMgr:GetUnion(nUnionID)
		if oUnion then
			oUnion.m_tApplyPlayerMap[nCharID] = nil
			oUnion:MarkDirty(true)
		end
	end
	oUnionPlayer:Set("m_tApplyUnionMap", {})
	self.m_tApplyPlayerMap[nCharID] = nil
	self:MarkDirty(true)
end

--清除玩家对该联盟的申请信息
function CUnion:CancelPlayerApply(nCharID)
	if not self.m_tApplyPlayerMap[nCharID] then
		return
	end
	self.m_tApplyPlayerMap[nCharID] = nil
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(nCharID))
	oUnionPlayer:Get("m_tApplyUnionMap")[self.m_nID] = nil
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if oPlayer then
		return oPlayer:Tips("取消联盟申请成功")
	end
	self:MarkDirty(true)
end

--拒绝申请
function CUnion:RefuseApply(oPlayer, nTarCharID)
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	self:CancelPlayerApply(nTarCharID)
end

--全部拒绝
function CUnion:RefuseAllApply(oPlayer)
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	for nCharID, v in pairs(self.m_tApplyPlayerMap) do
		self:CancelPlayerApply(nCharID)
	end
end

--接受申请
function CUnion:AcceptApply(oPlayer, nTarCharID)
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	return self:JoinUnion(oPlayer, nTarCharID)
end

--全部接受
function CUnion:AcceptAllApply(oPlayer)
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	local tApplyList = {}
	for nCharID, nTime in pairs(self.m_tApplyPlayerMap) do
		table.insert(tApplyList, {nCharID, nTime})
	end
	table.sort(tApplyList, function(t1, t2) return t1[2] < t2[2] end)
	for _, v in ipairs(tApplyList) do
		self:JoinUnion(oPlayer, v[1])
	end

	print("排行榜", tApplyList)

end

--是否已经申请过
function CUnion:IsApplied(nCharID)
	return (self.m_tApplyPlayerMap[nCharID] and true or false)
end

--申请进入联盟
function CUnion:ApplyJoin(oPlayer)
	if not goUnionMgr:IsOpen(oPlayer) then
		return
	end
	local nCharID = oPlayer:GetCharID()
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
	if not oUnionPlayer then
		oUnionPlayer = goUnionMgr:CreateUnionPlayer(oPlayer)
	end
	if oUnionPlayer:Get("m_nUnionID") > 0 then
		return oPlayer:Tips("您已经有联盟")
	end

	--冷却
	if goUnionMgr:GetJoinCD(oPlayer, true) > 0 then
		return
	end

	--人数已满
	if self:IsFull() then
		return oPlayer:Tips("联盟成员已满，无法加入")
	end

	--自动进入
	if self.m_nAutoJoin == 1 then
		if self:JoinUnion(nil, nCharID) then
			self:SyncDetailInfo(oPlayer) --前端说想要返回详细信息
			return oPlayer:Tips(string.format("已加入%s", self.m_sName))
		end

	elseif self.m_tApplyPlayerMap[nCharID] then
	--已申请过
		return oPlayer:Tips("已申请过该联盟")

	else
	--增加申请
		self.m_tApplyPlayerMap[nCharID] = os.time()
		oUnionPlayer:Get("m_tApplyUnionMap")[self.m_nID] = os.time()
		oPlayer:Tips("申请加入联盟成功")
		self:MarkDirty(true)

		--小红点
		CRedPoint:MarkRedPointAnyway(self.m_nMengZhu, gtRPDef.eUNJoinReq, 1)
		for nCharID, v in ipairs(self.m_tFuMengZhuMap) do
			CRedPoint:MarkRedPointAnyway(nCharID, gtRPDef.eUNJoinReq, 1)
		end
		return true
	end
end

--玩家加入联盟
function CUnion:JoinUnion(oManager, nTarCharID)
	if self:IsFull() then
		if oManager then
			oManager:Tips("联盟人数已满")
		end
		return
	end
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(nTarCharID))
	if oUnionPlayer:Get("m_nUnionID") > 0 then
	--玩家已加入其他联盟(理论上不会到这里)
		if oManager then
			oManager:Tips(string.format("%s 已加入其它联盟", oUnionPlayer:GetName()))
		end
		return
	end
	self.m_tMemberMap[nTarCharID] = true
	self.m_nMembers = self.m_nMembers + 1

	self:ClearPlayerApply(nTarCharID)
	oUnionPlayer:OnEnterUnion(self)
	local nLogType = nTarCharID == self.m_nMengZhu and CUnion.tLog.eCreate or CUnion.tLog.eJoin
	self:AddLog(nLogType, oUnionPlayer:GetName(), "", 0)
	self:MarkDirty(true)	
	--联盟国力排行
	self:UpdateGuoLi()
	--日志
	self:_UnionLog(oPlayer)
	return true
end

--任命职位
function CUnion:AppointPosition(oPlayer, nTarCharID, nTarPos)
	local nCharID = oPlayer:GetCharID()
	if nCharID == nTarCharID then
		return oPlayer:Tips("不能任命自己")
	end
	if not self.m_tMemberMap[nTarCharID] then
		return oPlayer:Tips("目标成员不存在")
	end
	local nSrcPos = self:GetPos(nTarCharID)
	if nSrcPos == nTarPos then
		return oPlayer:Tips("当前已是该职务")
	end
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(nTarCharID))
	if nTarPos == self.tPosition.eMengZhu then
	--任命盟主
		if not self:IsMengZhu(nCharID) then
			return oPlayer:Tips("没有权限")
		end
		if not self:IsFuMengZhu(nTarCharID) then
			return oPlayer:Tips("需要从副盟主中任命盟主")
		end
		self.m_nMengZhu = nTarCharID
		self.m_tFuMengZhuMap[nCharID] = 1
		oPlayer:Tips(string.format("您已将盟主之位让给 %s", oUnionPlayer:GetName()))
		self:BroadcastUnion(string.format("%s 把盟主之位转让给 %s", oPlayer:GetName(), oUnionPlayer:GetName()))

	elseif nTarPos == CUnion.tPosition.eFuMengZhu then
	--任命副盟主
		if not self:IsMengZhu(nCharID) then
			return oPlayer:Tips("没有权限")
		end
		if not self:IsJingYing(nTarCharID) then
			return oPlayer:Tips("需要从精英中任命副盟主")
		end
		if self:FuMengZhuNum() >= self:MaxFuMengZhuNum() then
			return oPlayer:Tips("副盟主人数已达上限，无法提升职务")
		end
		self.m_tFuMengZhuMap[nTarCharID] = 1
		self.m_tJingYingMap[nTarCharID] = nil
		oPlayer:Tips(string.format("%s 提升为副盟主", oUnionPlayer:GetName()))
		self:BroadcastUnion(string.format("%s 被提升为副盟主", oUnionPlayer:GetName()))

	elseif nTarPos == CUnion.tPosition.eJingYing then
		if self:JingYingNum() >= self:MaxJingYingNum() then
			return oPlayer:Tips("精英人数已达上限，无法任命职务")
		end
		self.m_tJingYingMap[nTarCharID] = 1
		if nSrcPos == CUnion.tPosition.eFuMengZhu then
			if not self:IsMengZhu(nCharID) then
				return oPlayer:Tips("没有权限")
			end
			self.m_tFuMengZhuMap[nTarCharID] = nil
			oPlayer:Tips(string.format("%s 降职为精英", oUnionPlayer:GetName()))
			self:BroadcastUnion(string.format("%s 被降职为精英", oUnionPlayer:GetName()))
		else
			if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
				return oPlayer:Tips("没有权限")
			end
			oPlayer:Tips(string.format("%s 提升为精英", oUnionPlayer:GetName()))
			self:BroadcastUnion(string.format("%s 被提升为精英", oUnionPlayer:GetName()))
		end

	elseif nTarPos == self.tPosition.eMember then
	--降为成员
		if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
			return oPlayer:Tips("没有权限")
		end
		if not self:IsJingYing(nTarCharID) then
			return oPlayer:Tips("请先降职到精英")
		end
		self.m_tJingYingMap[nTarCharID] = nil
		oPlayer:Tips(string.format("%s 降职为成员", oUnionPlayer:GetName()))
		self:BroadcastUnion(string.format("%s 被降职为普通成员", oUnionPlayer:GetName()))

	else
		assert(false, "职位错误")
	end
	self:MarkDirty(true)
	self:AddLog(CUnion.tLog.eAppoint, oPlayer:GetName(), oUnionPlayer:GetName(), nSrcPos, nTarPos)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PosChangeRet", {nCharID=nTarCharID, nPos=nTarPos})
	goLogger:EventLog(gtEvent.eAppointPos, oPlayer, self.m_nID, nTarCharID, nTarPos)
	goUnionMgr:SyncUnionInfo(nCharID)
end

--剔除队员
function CUnion:KickMember(oPlayer, nTarCharID)
	if not self.m_tMemberMap[nTarCharID] then
		return print("目标队员不存在")
	end
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	if nCharID == nTarCharID then
		return oPlayer:Tips("不能剔除自己")
	end
	self:ExitUnion(nTarCharID, CUnion.tExit.eKick)
end

--添加联盟日志
function CUnion:AddLog(nType, sName1, sName2, nValue)
	assert(nType and sName1 and sName2 and nValue)
	local tLog = {nType, sName1, sName2, nValue, os.time()}
	table.insert(self.m_tLogList, 1, tLog)
	if #self.m_tLogList > nMaxLog then
		table.remove(self.m_tLogList)
	end
	self:MarkDirty(true)
end

--取句柄列表
function CUnion:GetSessionList()
	local tSessionList = {}
	for nCharID, v in pairs(self.m_tMemberMap) do
		local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
		if oPlayer then
			table.insert(tSessionList, oPlayer:GetSession())
		end
	end
	return tSessionList
end

--广播联盟
function CUnion:BroadcastUnion(sCont)
	goTalk:SendUnionMsg(nil, sCont, self)
end

--更新国力
function CUnion:UpdateGuoLi()
	local nTotalGuoLi = 0
	for nCharID, v in pairs(self.m_tMemberMap) do
		nTotalGuoLi = nTotalGuoLi + goRankingMgr.m_oGLRanking:GetPlayerGuoLi(nCharID)
	end
	goRankingMgr.m_oUGLRanking:Update(self.m_nID, nTotalGuoLi, self.m_sName)
end

--取总国力
function CUnion:GetGuoLi()
	return goRankingMgr.m_oUGLRanking:GetUnionGuoLi(self.m_nID)
end

--同步联盟详细信息
function CUnion:SyncDetailInfo(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local tMsg = {}
	tMsg.nID = self.m_nID
	tMsg.sName = self.m_sName
	tMsg.nLevel = self.m_nLv
	tMsg.nExp = self.m_nExp
	tMsg.nNextExp = ctUnionLevelConf[self.m_nLv].nExp
	tMsg.nActivity = self.m_nActivity
	tMsg.nMembers = self:GetMembers()
	tMsg.nMaxMembers = self:MaxMembers()
	tMsg.nPos = self:GetPos(nCharID)
	tMsg.sDeclaration = self.m_sDeclaration
	tMsg.nUnionContri = oPlayer:GetUnionContri()
	tMsg.nAutoJoin = self.m_nAutoJoin
	tMsg.sMengZhu = self:GetMengZhuName()
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionDetailRet", tMsg)
	print("CUnion:SyncDetailInfo***", tMsg)
end

--联盟详细信息请求
function CUnion:UnionDetailReq(oPlayer)
	self:SyncDetailInfo(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
	oUnionPlayer:FirstJoinNotify(oPlayer)
end

function CUnion:ApplyUnionReq(oPlayer)
	if self:ApplyJoin(oPlayer) then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ApplyUnionRet", {nUnionID=self.m_nID})
	end
end

function CUnion:ExitUnionReq(oPlayer)
	print("CUnion:ExitUnionReq***")
	if self:ExitUnion(oPlayer:GetCharID(), CUnion.tExit.eExit) then
		self:BroadcastUnion(string.format("%s 退出联盟", oPlayer:GetName()))
	end
end

function CUnion:SetUnionDeclReq(oPlayer, sDesc)
	if self:SetDeclaration(oPlayer, sDesc) then
		self:SyncDetailInfo(oPlayer)
	end
end

function CUnion:SetAutoJoinReq(oPlayer, nAutoJoin)
	if self:SetAutoJoin(oPlayer, nAutoJoin) then
		self:SyncDetailInfo(oPlayer)
	end
end

function CUnion:UpgradeReq(oPlayer)
	local nCharID = oPlayer:GetCharID()
	if not self:IsMengZhu(nCharID) and not self:IsFuMengZhu(nCharID) then
		return oPlayer:Tips("没有权限")
	end
	if self.m_nLv >= #ctUnionLevelConf then
		return oPlayer:Tips("联盟已达等级上限")
	end
	local nNextExp = ctUnionLevelConf[self.m_nLv].nExp
	if self.m_nExp >= nNextExp then
		self.m_nLv = self.m_nLv + 1
		self:AddExp(-nNextExp, "联盟升级", oPlayer)
		self:MarkDirty(true)
	end
	self:SyncDetailInfo(oPlayer)
end

function CUnion:ApplyListReq(oPlayer)
	local tApplyList = {}
	for nCharID, nTime in pairs(self.m_tApplyPlayerMap) do
		local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
		local tItem = {}
		tItem.nID = nCharID
		tItem.sName = oUnionPlayer:GetName()
		tItem.nTime = nTime
		tItem.nGuoLi = goRankingMgr.m_oGLRanking:GetPlayerGuoLi(nCharID)
		table.insert(tApplyList, tItem)
	end
	local tMsg = {tApplyList=tApplyList, nMembers=self:GetMembers(), nMaxMembers=self:MaxMembers()}
	print("CUnion:ApplyListReq***", tMsg)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ApplyListRet", tMsg)
	--小红点
	oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eUNJoinReq, 0)
end

function CUnion:AcceptApplyReq(oPlayer, nTarCharID)
	if nTarCharID == 0 then
		self:AcceptAllApply(oPlayer)
	else
		self:AcceptApply(oPlayer, nTarCharID)
	end
	self:ApplyListReq(oPlayer)
end

function CUnion:RefuseApplyReq(oPlayer, nTarCharID)
	if nTarCharID == 0 then
		self:RefuseAllApply(oPlayer)
	else
		self:RefuseApply(oPlayer, nTarCharID)
	end
	self:ApplyListReq(oPlayer)
end

function CUnion:MemberListReq(oPlayer)
	local tMemberList = {}
	for nCharID, v in pairs(self.m_tMemberMap) do
		local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
		local tItem = {}
		tItem.nID = nCharID
		tItem.sName = oUnionPlayer:GetName()
		tItem.nPos = self:GetPos(nCharID)
		tItem.nGuoLi = goRankingMgr.m_oGLRanking:GetPlayerGuoLi(nCharID)
		tItem.nContri = oUnionPlayer:GetUnionContri()
		tItem.bOnline = goPlayerMgr:GetPlayerByCharID(nCharID) and true or false
		tItem.nOnlineTime = oUnionPlayer.m_nOnlineTime
		table.insert(tMemberList, tItem)
	end
	local tMsg = {tMemberList=tMemberList, nMembers=self:GetMembers(), nMaxMembers=self:MaxMembers(), nGuoLi=self:GetGuoLi()}
	print("MemberListReq***", tMsg)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "MemberListRet", tMsg)
end

--成员详细信息请求(离线也可以看，所以只能保存到离线数据里面)
function CUnion:MemberDetailReq(oPlayer, nTarCharID)
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(nTarCharID)
	local oOfflineData = goOfflineDataMgr:GetPlayer(nTarCharID)

	local tMsg = {}
	tMsg.nCharID = nTarCharID
	tMsg.sName = oOfflineData.m_sName
	tMsg.nVIP = oOfflineData.m_nVIP 
	tMsg.nGuoLi = goRankingMgr.m_oGLRanking:GetPlayerGuoLi(nTarCharID)
	tMsg.tAttr = goRankingMgr.m_oGLRanking:GetPlayerAttr(nTarCharID)
	tMsg.nQinMi = goRankingMgr.m_oQMRanking:GetPlayerQinMi(nTarCharID)
	tMsg.nChildNum = oOfflineData.m_nChildNum
	tMsg.nWeiWang = goRankingMgr.m_oWWRanking:GetPlayerWW(nTarCharID)
	tMsg.nChapter = oOfflineData.m_nChapter

	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "MemberDetailRet", tMsg)
end

--踢出玩家请求
function CUnion:KickMemberReq(oPlayer, nCharID)
	self:KickMember(oPlayer, nCharID)
end

--任命请求
function CUnion:AppointReq(oPlayer, nTarCharID, nTarPos)
	self:AppointPosition(oPlayer, nTarCharID, nTarPos)
end

--日志列表请求
function CUnion:LogListReq(oPlayer)
	local tLogList = {}
	for _, tLog in ipairs(self.m_tLogList) do
		local tItem = {}
		tItem.nType = tLog[1]
		tItem.sName1 = tLog[2]
		tItem.sName2 = tLog[3]
		tItem.nValue = tLog[4]
		tItem.nTime = tLog[5]
		table.insert(tLogList, tItem)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "LogListRet", {tLogList=tLogList})
end

--增加活跃度
function CUnion:AddActivity(nVal, sReason, oPlayer)
	if nVal == 0 then return end
	self.m_nActivity = math.max(0, math.min(nMAX_INTEGER, self.m_nActivity + nVal))
	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, oPlayer, gtItemType.eCurr, gtCurrType.eUnionActivity, nVal, self.m_nActivity, self.m_nID)
	self:MarkDirty(true)
	--日志
	self:_UnionLog(oPlayer)
end

--增加经验
function CUnion:AddExp(nVal, sReason, oPlayer)
	if nVal == 0 then return end
	self.m_nExp = math.max(0, math.min(nMAX_INTEGER, self.m_nExp + nVal))
	self:MarkDirty(true)

	local nEventID = nVal > 0 and gtEvent.eAddItem or gtEvent.eSubItem
	goLogger:AwardLog(nEventID, sReason, oPlayer, gtItemType.eCurr, gtCurrType.eUnionExp, nVal, self.m_nExp, self.m_nID)

	if nVal > 0 then --只记录增加的
		self.m_nTotalAddExp = math.max(0, math.min(nMAX_INTEGER, self.m_nTotalAddExp+nVal))
		goRankingMgr.m_oUnExpRanking:Update(self.m_nID, self.m_nTotalAddExp, self.m_sName)
	end
end

--重置检查
function CUnion:CheckReset()
	if not os.IsSameDay(self.m_nBuildResetTime, os.time(), 5*3600) then
		--建设重置
		self.m_tBuildMap = {}
		self.m_nBuildResetTime = os.time()
		--兑换重置
		self.m_tExchangeMap = {}
		self.m_nExchangeResetTime = os.time()
		self:MarkDirty(true)
	end

end

--建设情况请求
function CUnion:BuildInfoReq(oPlayer)
	self:CheckReset()
	local nBuildID = self.m_tBuildMap[oPlayer:GetCharID()] or 0
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionBuildInfoRet", {nBuildID=nBuildID})
	--小红点
	self:CheckRedPoint(oPlayer)
end

--建设
function CUnion:BuildReq(oPlayer, nBuildID)
	self:CheckReset()
	--每天只能建设一次
	local nCharID = oPlayer:GetCharID()
	if self.m_tBuildMap[nCharID] then
		return oPlayer:Tips("今天已经进行过建设，明天再来吧")
	end
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(nCharID))

	--消耗
	local tConf = ctUnionBuildConf[nBuildID]
	local tCost = tConf.tCost[1]
	if oPlayer:GetItemCount(tCost[1], tCost[2]) < tCost[3] then
		return oPlayer:Tips(string.format("%s 不足", CGuoKu:PropName(tCost[2])))
	end
	oPlayer:SubItem(tCost[1], tCost[2], tCost[3], "联盟每日建设")

	--奖励
	if tConf.nContri > 0 then	
		oUnionPlayer:AddUnionContri(tConf.nContri, "联盟建设获得", oPlayer)
		oPlayer:Tips(string.format("贡献 +%d", tConf.nContri))
	end
	if tConf.nExp > 0 then
		self:AddExp(tConf.nExp, "联盟建设获得", oPlayer)
		oPlayer:Tips(string.format("联盟经验 +%d", tConf.nExp))
	end
	if tConf.nActivity > 0 then
		self:AddActivity(tConf.nActivity, "联盟建设获得", oPlayer)
		oPlayer:Tips(string.format("活跃点 +%d", tConf.nActivity))
	end
	self.m_tBuildMap[nCharID] = nBuildID
	self:MarkDirty(true)

	self:BuildInfoReq(oPlayer)
	self:SyncDetailInfo(oPlayer)

	--任务
	oPlayer.m_oDailyTask:Progress(gtDailyTaskType.eCond16, 1)
	--成就
	oPlayer.m_oAchievements:SetAchievement(gtAchieDef.eCond18, 1)
end

--兑换列表请求
function CUnion:ExchangeListReq(oPlayer)
	self:CheckReset()
	local nCharID = oPlayer:GetCharID()

	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(oPlayer:GetCharID()))
	local tMsg = {nLv=self.m_nLv, nContri=oUnionPlayer:GetUnionContri(), tList={}}
	local tItemMap = self.m_tExchangeMap[nCharID] or {}
	for nID, nNum in pairs(tItemMap) do
		local nRemain = ctUnionExchangeConf[nID].nDayExchange - nNum
		local tItem = {nID=nID, nRemain=nRemain}
		table.insert(tMsg.tList, tItem)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionExchangeListRet", tMsg)
end

--兑换请求
function CUnion:ExchangeReq(oPlayer, nID)
	self:CheckReset()

	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(oPlayer:GetCharID()))
	local tConf = ctUnionExchangeConf[nID]
	if tConf.nUnionLv > self.m_nLv then
		return oPlayer:Tips("物品未解锁")
	end
	local nCharID = oPlayer:GetCharID()
	local tItemMap = self.m_tExchangeMap[nCharID] or {}
	local nNum = tItemMap[nID] or 0
	if nNum >= tConf.nDayExchange then
		return oPlayer:Tips("物品已经售罄")
	end
	
	if oUnionPlayer:GetUnionContri() < tConf.nContri then
		return oPlayer:Tips("联盟贡献不足")
	end
	oUnionPlayer:AddUnionContri(-tConf.nContri, "联盟兑换消耗", oPlayer)

	local tItem = tConf.tItem[1]
	oPlayer:AddItem(tItem[1], tItem[2], tItem[3], "联盟兑换获得")

	tItemMap[nID] = (tItemMap[nID] or 0) + 1
	self.m_tExchangeMap[nCharID] = tItemMap
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionExchangeSuccRet", {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	self:MarkDirty(true)
end

--检测小红点
function CUnion:CheckRedPoint(oPlayer)
	--建设小红点
	self:CheckReset()
	local nCharID = oPlayer:GetCharID()
	if self.m_tBuildMap[nCharID] then
		return oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eUNBuild, 0)
	end
	oPlayer.m_oRedPoint:MarkRedPoint(gtRPDef.eUNBuild, 1)
end

--玩家上线
function CUnion:Online(oPlayer)
	self:CheckRedPoint(oPlayer)
	self.m_oUnionMiracle:CheckRedPoint(oPlayer)
	self.m_oUnionParty:CheckRedPoint(oPlayer)
end

--联盟日志
function CUnion:_UnionLog(oPlayer)
	goLogger:EventLog(gtEvent.eUnionAttr, oPlayer, self.m_nID, self.m_sName
		, self.m_nActivity, self.m_nMembers, self.m_oUnionMiracle:GetLevelList())
end
