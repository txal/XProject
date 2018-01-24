local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--日志上限
local nMaxLog = 10

--战队职位
CUnion.tPosition = 
{
	ePresident = 1,	--队长
	eVicePresident = 2, --副队长
	eMember = 3, --成员
}

--日志类型
CUnion.tLog = 
{
	eCreate = 1, --创建战队
	eJoin = 2, --加入战队
	eExit = 3, --离开战队
	eAppoint = 4, --任命职位
}

--退出战队类型
CUnion.tExit = 
{
	eExit = 1,	--主动退出
	eKick = 2,	--被移出
	eDismiss = 3, --解散
}

--战队对象
function CUnion:Ctor()
	self.m_nID = 0 
	self.m_sName = ""
	self.m_nMembers = 0
	self.m_nMaxMembers = ctUnionEtc[1].nInitPlayer
	self.m_sDeclaration = ""
	self.m_sPresident = ""
	self.m_nLogo = 0
	self.m_nAutoJoin = ctUnionEtc[1].nOpenJoin	--1非审批(自动), 0审批
	self.m_nJoinLevel = ctUnionEtc[1].nJoinLevel
	self.m_tMemberMap = {} --{[sCharID]=true}
	self.m_tVicePresidentMap = {} --{[sCharID]=true}
	self.m_tApplyPlayerMap = {} --{[sCharID]=time}
	self.m_tLogList = {} --{{nLogType, sName, sName, nValue, nTime},...}
end

--玩家创建战队时调用
function CUnion:CreateInit(oPlayer, nID, nLogo, sName, sDeclaration)
	local sCharID = oPlayer:GetCharID()
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(sCharID))
	self.m_nID = nID
	self.m_sName = sName
	self.m_nLogo = nLogo
	self.m_sDeclaration = sDeclaration
	self.m_sPresident = sCharID

	assert(self:JoinUnion(oPlayer, sCharID))
	self:MarkDirty(true)

	goLogger:EventLog(gtEvent.eCreateUnion, oPlayer, self.m_nID, self.m_sName, self.m_nLogo)
end

--加载战队数据
function CUnion:LoadData(tData)
	self.m_nID = tData.nID
	self.m_sName = tData.sName
	self.m_nMembers = tData.nMembers
	self.m_nMaxMembers = tData.nMaxMembers
	self.m_sDeclaration = tData.sDeclaration
	self.m_sPresident = tData.sPresident
	self.m_nLogo = tData.nLogo
	self.m_nAutoJoin = tData.nAutoJoin
	self.m_nJoinLevel = tData.nJoinLevel

	self.m_nMembers = 0
	for _, sCharID in ipairs(tData.tMemberList) do
		local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(sCharID))
		if oUnionPlayer:Get("m_nUnionID") == self.m_nID then
			self.m_tMemberMap[sCharID] = true
			self.m_nMembers = self.m_nMembers + 1
		else
			LuaTrace("Union:"..self.m_nID.." member error")
		end
		self:MarkDirty(true)
	end

	for _, sCharID in ipairs(tData.tVicePresidentList) do
		if self.m_tMemberMap[sCharID] then
			self.m_tVicePresidentMap[sCharID] = true
		else
			LuaTrace("Union:"..self.m_nID.." vice president error")
		end
		self:MarkDirty(true)
	end

	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(self.m_sPresident))
	if oUnionPlayer:Get("m_nUnionID") ~= self.m_nID then
		LuaTrace("Union:"..self.m_nID.." president error")
		local sCharID = next(self.m_tVicePresidentMap)
		if sCharID then
			self.m_tVicePresidentMap[sCharID] = nil
		else
			sCharID = next(self.m_tMemberMap)
		end
		self.m_sPresident = sCharID or ""
		self:MarkDirty(true)
	end

	if self.m_nMembers == 0 or not self.m_sPresident then
		goUnionMgr:OnUnionDismiss(self)
		return false
	end

	self.m_tApplyPlayerMap = tData.tApplyPlayerMap
	self.m_tLogList = tData.tLogList
	return true
end

--保存战队数据
function CUnion:SaveData()
	tData = {}
	tData.nID = self.m_nID
	tData.sName = self.m_sName
	tData.nMembers = self.m_nMembers
	tData.nMaxMembers = self.m_nMaxMembers
	tData.sDeclaration = self.m_sDeclaration
	tData.sPresident = self.m_sPresident
	tData.tVicePresidentList = {}
	for sCharID, v in pairs(self.m_tVicePresidentMap) do
		table.insert(tData.tVicePresidentList, sCharID)
	end
	tData.nLogo = self.m_nLogo
	tData.nAutoJoin = self.m_nAutoJoin
	tData.nJoinLevel = self.m_nJoinLevel
	tData.tMemberList = {}
	for sCharID, v in pairs(self.m_tMemberMap) do
		table.insert(tData.tMemberList, sCharID)
	end
	tData.tApplyPlayerMap = self.m_tApplyPlayerMap
	tData.tLogList = self.m_tLogList
	return tData
end

--取玩家职位
function CUnion:GetPos(sCharID)
	local nPos = self.tPosition.eMember
	if self:IsPresident(sCharID) then
		nPos = self.tPosition.ePresident
	elseif self:IsVicePresident(sCharID) then
		nPos = self.tPosition.eVicePresident
	end
	return nPos
end

--设置脏
function CUnion:MarkDirty(bDirty) goUnionMgr:MarkUnionDirty(self.m_nID, bDirty) end
--是否队长
function CUnion:IsPresident(sCharID) return self.m_sPresident == sCharID end
--是否副队长
function CUnion:IsVicePresident(sCharID) return self.m_tVicePresidentMap[sCharID] end
--是否已满
function CUnion:IsFull() return self.m_nMembers >= self.m_nMaxMembers end
--副队长当前个数
function CUnion:VicePresidentNum()
	local nCount = 0
	for k, v in pairs(self.m_tVicePresidentMap) do
		nCount = nCount + 1
	end 
	return nCount
end
--副队长最大个数
function CUnion:MaxVicePresidentNum() return math.floor(self.m_nMaxMembers/10) end

--退出战队
function CUnion:ExitUnion(sCharID, nExitType)
	if not self.m_tMemberMap[sCharID] then
		return
	end
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(sCharID))
	assert(oUnionPlayer:Get("m_nUnionID") == self.m_nID)
	if sCharID == self.m_sPresident then
		self:Dismiss()
		return
	end
	oUnionPlayer:OnExitUnion(nExitType)
	self.m_tMemberMap[sCharID] = nil
	self.m_tVicePresidentMap[sCharID] = nil
	self.m_nMembers = self.m_nMembers - 1
	self:MarkDirty(true)
	self:AddLog(self.tLog.eExit, oUnionPlayer:Get("m_sName"), "", 0)
	return true
end

--解散战队
function CUnion:Dismiss()
	print("CUnion:Dismiss***")
	for sCharID, v in pairs(self.m_tMemberMap) do
		local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(sCharID))
		oUnionPlayer:OnExitUnion(self.tExit.eDismiss)
	end
	goUnionMgr:OnUnionDismiss(self)

	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(self.m_sPresident)
	goLogger:EventLog(gtEvent.eDismissUnion, oPlayer, self.m_nID)
end

--设置战队图标
function CUnion:SetLogo(oPlayer, nLogo)
	assert(nLogo > 0, "图标ID必须>0")
	if self.m_nLogo == nLogo then
		return
	end
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) then
		return
	end
	self.m_nLogo = nLogo
	self:MarkDirty(true)
	return true
end

--设置战队名称
function CUnion:SetName(oPlayer, sName)
	sName = string.Trim(sName)
	assert(sName ~= "")
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) then
		return
	end
	if string.len(sName) > nMaxUnionNameLen then
		return oPlayer:ScrollMsg(ctLang[43])
	end
	self.m_sName = sName
	self:MarkDirty(true)
	return true
end

--设置宣言
function CUnion:SetDeclaration(oPlayer, sDesc)
	sDesc = string.Trim(sDesc)
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) then
		return
	end
	if string.len(sDesc) > nMaxUnionDeclLen then
		return oPlayer:ScrollMsg(ctLang[44])
	end
	self.m_sDeclaration = sDesc
	self:MarkDirty(true)
	return true
end

--设置审批否
function CUnion:SetAutoJoin(oPlayer, nAutoJoin)
	assert(nAutoJoin == 0 or nAutoJoin == 1)
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) then
		return
	end
	self.m_nAutoJoin = nAutoJoin
	self:MarkDirty(true)
	return true
end

--设置入队等级
function CUnion:SetJoinLevel(oPlayer, nJoinLevel)
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) then
		return
	end
	self.m_nJoinLevel = nJoinLevel
	self:MarkDirty(true)
	return true
end

--扩展人数
function CUnion:ExtendMembers(oPlayer)
	print("CUnion:ExtendMembers***")
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) then
		return
	end
	local tConf
	for _, v in ipairs(ctExtendCost) do
		if self.m_nMaxMembers < v.nPlayers then
			tConf = v
			break
		end
	end
	--达到上限
	if not tConf then
		return oPlayer:ScrollMsg(ctLang[50])
	end
	--钻石不足
	if oPlayer:GetMoney() < tConf.nCostDiamond then
		return oPlayer:ScrollMsg(ctLang[4])
	end
	self.m_nMaxMembers = tConf.nPlayers
	oPlayer:SubMoney(tConf.nCostDiamond, gtReason.eExtendUnionMember)
	self:MarkDirty(true)
	return true
end

--清除进入战队的玩家的申请信息
function CUnion:ClearPlayerApply(sCharID)
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(sCharID))
	for nUnionID, nTime in pairs(oUnionPlayer:Get("m_tApplyUnionMap")) do
		local oUnion = goUnionMgr:GetUnion(nUnionID)
		if oUnion then
			oUnion.m_tApplyPlayerMap[sCharID] = nil
		end
	end
	oUnionPlayer:Set("m_tApplyUnionMap", {})
	self.m_tApplyPlayerMap[sCharID] = nil
	self:MarkDirty(true)
end

--清除玩家对该战队的申请信息
function CUnion:CancelPlayerApply(sCharID)
	if not self.m_tApplyPlayerMap[sCharID] then
		return
	end
	self.m_tApplyPlayerMap[sCharID] = nil
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(sCharID))
	oUnionPlayer:Get("m_tApplyUnionMap")[self.m_nID] = nil
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
	if oPlayer then
		return oPlayer:ScrollMsg(string.format(ctLang[53], self.m_sName))
	end
	self:MarkDirty(true)
end

--拒绝申请
function CUnion:RefuseApply(oPlayer, sTarCharID)
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) and not self:IsVicePresident(sCharID) then
		return
	end
	self:CancelPlayerApply(sTarCharID)
end

--全部拒绝
function CUnion:RefuseAllApply(oPlayer)
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) and not self:IsVicePresident(sCharID) then
		return
	end
	for sCharID, v in pairs(self.m_tApplyPlayerMap) do
		self:CancelPlayerApply(sCharID)
	end
end

--接受申请
function CUnion:AcceptApply(oPlayer, sTarCharID)
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) and not self:IsVicePresident(sCharID) then
		return
	end
	return self:JoinUnion(oPlayer, sTarCharID)
end

--全部接受
function CUnion:AcceptAllApply(oPlayer)
	local sCharID = oPlayer:GetCharID()
	if not self:IsPresident(sCharID) and not self:IsVicePresident(sCharID) then
		return
	end
	local tApplyList = {}
	for sCharID, nTime in pairs(self.m_tApplyPlayerMap) do
		table.insert(tApplyList, {sCharID, nTime})
	end
	table.sort(tApplyList, function(t1, t2) return t1[2] < t2[2] end)
	for _, v in ipairs(tApplyList) do
		self:JoinUnion(oPlayer, v[1])
	end
end

--是否已经申请过
function CUnion:IsApplied(sCharID)
	return (self.m_tApplyPlayerMap[sCharID] and true or false)
end

--申请进入战队
function CUnion:ApplyJoin(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(sCharID)
	if not oUnionPlayer then
		oUnionPlayer = goUnionMgr:CreateUnionPlayer(oPlayer)
	end
	if oUnionPlayer:Get("m_nUnionID") > 0 then
		return oPlayer:ScrollMsg(ctLang[46])
	end

	if self:IsFull() then
	--人数已满
		return oPlayer:ScrollMsg(ctLang[51])
	end

	if oPlayer:GetLevel() < self.m_nJoinLevel then
	--等级不足
		return oPlayer:ScrollMsg(string.format(ctLang[54], self.m_nJoinLevel))
	end

	if self.m_nAutoJoin == 1 then
	--自动进入
		self:JoinUnion(nil, sCharID)

	elseif self.m_tApplyPlayerMap[sCharID] then
	--已申请过
		return oPlayer:ScrollMsg(ctLang[55])

	else
	--增加申请
		self.m_tApplyPlayerMap[sCharID] = os.time()
		oUnionPlayer:Get("m_tApplyUnionMap")[self.m_nID] = os.time()
		self:MarkDirty(true)
		return true
	end
end

--玩家加入战队
function CUnion:JoinUnion(oManager, sTarCharID)
	if self:IsFull() then
		if oManager then
			oManager:ScrollMsg(ctLang[51])
		end
		return
	end
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(sTarCharID))
	if oUnionPlayer:Get("m_nUnionID") > 0 then
	--玩家已加入其他战队(理论上不会到这里)
		if oManager then
			oManager:ScrollMsg(ctLang[52])
		end
		return
	end
	self.m_tMemberMap[sTarCharID] = true
	self.m_nMembers = self.m_nMembers + 1

	self:ClearPlayerApply(sTarCharID)
	oUnionPlayer:OnEnterUnion(self)
	local nLogType = sTarCharID == self.m_sPresident and self.tLog.eCreate or self.tLog.eJoin
	self:AddLog(nLogType, oUnionPlayer:Get("m_sName"), "", 0)
	self:MarkDirty(true)	
	return true
end

--任命职位
function CUnion:AppointPosition(oPlayer, sTarCharID, nTarPos)
	local sCharID = oPlayer:GetCharID()
	if sCharID == sTarCharID then
		print("不能任命自己")
		return
	end
	if not self.m_tMemberMap[sTarCharID] then
		print("目标队员不存在")
		return
	end
	local oUnionPlayer = assert(goUnionMgr:GetUnionPlayer(sTarCharID))
	if nTarPos == self.tPosition.ePresident then
	--任命队长
		if not self:IsPresident(sCharID) then
			return
		end
		self.m_sPresident = sTarCharID
		if self:IsVicePresident(sTarCharID) then
			self.m_tVicePresidentMap[sTarCharID] = nil
		end

	elseif nTarPos == self.tPosition.eVicePresident then
	--任命副队长
		if not self:IsPresident(sCharID) then
			return
		end
		if self:IsVicePresident(sTarCharID) then
			return
		end
		local nMaxVice = self:MaxVicePresidentNum()
		if self:VicePresidentNum() >= nMaxVice then
			return oPlayer:ScrollMsg(string.format(ctLang[56], nMaxVice))
		end
		self.m_tVicePresidentMap[sTarCharID] = true

	elseif nTarPos == self.tPosition.eMember then
	--降为成员
		if not self:IsPresident(sCharID) then
			return
		end
		if not self:IsVicePresident(sTarCharID) then
			return
		end
		self.m_tVicePresidentMap[sTarCharID] = nil

	else
		assert(false, "职位错误")
	end
	self:MarkDirty(true)
	self:AddLog(self.tLog.eAppoint, oPlayer:GetName(), oUnionPlayer:Get("m_sName"), nTarPos)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "PosChangeRet", {sCharID=sTarCharID, nPos=nTarPos})

	goLogger:EventLog(gtEvent.eAppointPos, oPlayer, self.m_nID, sTarCharID, nTarPos)
end

--剔除队员
function CUnion:KickMember(oPlayer, sTarCharID)
	if not self.m_tMemberMap[sTarCharID] then
		print("目标队员不存在")
		return
	end
	local sCharID = oPlayer:GetCharID()
	if self:IsPresident(sCharID) then
		if not self:IsPresident(sTarCharID) then
			self:ExitUnion(sTarCharID, self.tExit.eKick)
			return
		end
		print("不能移除自己")
	elseif self:IsVicePresident(sCharID) then
		local nTarPos = self:GetPos(sTarCharID)
		if nTarPos == self.tPosition.eMember then
			self:ExitUnion(sTarCharID, self.tExit.eKick)
			return
		end
		print("副队长只能移除成员")
	end
	assert(false, "没有移除成员权限")
end

--添加战队日志
function CUnion:AddLog(nType, sName1, sName2, nValue)
	assert(nType and sName1 and sName2 and nValue)
	local tLog = {nType, sName1, sName2, nValue, os.time()}
	table.insert(self.m_tLogList, 1, tLog)
	if #self.m_tLogList > nMaxLog then
		table.remove(self.m_tLogList)
	end
	self:MarkDirty(true)
end



function CUnion:UnionDetailReq(oPlayer)
	local tMsg = {}
	tMsg.nID = self.m_nID
	tMsg.nIcon = self.m_nLogo
	tMsg.sName = self.m_sName
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(self.m_sPresident)
	local sCharName = oUnionPlayer and oUnionPlayer:Get("m_sName") or ""
	tMsg.sPresident = sCharName
	tMsg.nMembers = self.m_nMembers 
	tMsg.nMaxMembers = self.m_nMaxMembers
	tMsg.sDeclaration = self.m_sDeclaration
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionDetailRet", tMsg)
end

function CUnion:ApplyUnionReq(oPlayer)
	if self:ApplyJoin(oPlayer) then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ApplyUnionRet", {nUnionID=self.m_nID})
	end
end

function CUnion:ExitUnionReq(oPlayer)
	print("CUnion:ExitUnionReq***")
	self:ExitUnion(oPlayer:GetCharID(), self.tExit.eExit)
end

function CUnion:UnionMgrInfoReq(oPlayer)
	self:SyncUnionMgrInfo(oPlayer)
end

function CUnion:SyncUnionMgrInfo(oPlayer)
	print("CUnion:SyncUnionMgrInfo***")
	local tMsg = {}
	tMsg.nIcon = self.m_nLogo
	tMsg.sName = self.m_sName
	tMsg.nMembers = self.m_nMembers
	tMsg.nMaxMembers = self.m_nMaxMembers
	tMsg.nAutoJoin = self.m_nAutoJoin
	tMsg.nJoinLevel = self.m_nJoinLevel
	tMsg.sDeclaration = self.m_sDeclaration
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionMgrInfoRet", tMsg)
end

function CUnion:SetUnionIconReq(oPlayer, nIcon)
	if self:SetLogo(oPlayer, nIcon) then
		self:SyncUnionMgrInfo(oPlayer)
	end
end

function CUnion:SetUnionNameReq(oPlayer, sName)
	if self:SetName(oPlayer, sName) then
		self:SyncUnionMgrInfo(oPlayer)
	end
end

function CUnion:SetUnionDeclReq(oPlayer, sDesc)
	if self:SetDeclaration(oPlayer, sDesc) then
		self:SyncUnionMgrInfo(oPlayer)
	end
end

function CUnion:SetAutoJoinReq(oPlayer, nAutoJoin)
	if self:SetAutoJoin(oPlayer, nAutoJoin) then
		self:SyncUnionMgrInfo(oPlayer)
	end
end

function CUnion:SetJoinLevelReq(oPlayer, nJoinLevel)
	if self:SetJoinLevel(oPlayer, nJoinLevel) then
		self:SyncUnionMgrInfo(oPlayer)
	end
end

function CUnion:ExtendMembersReq(oPlayer)
	if self:ExtendMembers(oPlayer) then
		self:SyncUnionMgrInfo(oPlayer)
	end
end

function CUnion:ApplyListReq(oPlayer)
	local tApplyList = {}
	for sCharID, nTime in pairs(self.m_tApplyPlayerMap) do
		local oUnionPlayer = goUnionMgr:GetUnionPlayer(sCharID)
		local tItem = {}
		tItem.sID = sCharID
		tItem.sName = oUnionPlayer:Get("m_sName")
		tItem.nLevel = oUnionPlayer:Get("m_nLevel")
		tItem.nFame = oUnionPlayer:Get("m_nFame")
		tItem.nTime = nTime
		table.insert(tApplyList, tItem)
	end
	local tMsg = {tApplyList=tApplyList, nMembers=self.m_nMembers, nMaxMembers=self.m_nMaxMembers}
	print("CUnion:ApplyListReq***", tMsg)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ApplyListRet", tMsg)
end

function CUnion:AcceptApplyReq(oPlayer, sTarCharID)
	if sTarCharID == "" then
		self:AcceptAllApply(oPlayer)
	else
		self:AcceptApply(oPlayer, sTarCharID)
	end
end

function CUnion:RefuseApplyReq(oPlayer, sTarCharID)
	if sTarCharID == "" then
		self:RefuseAllApply(oPlayer)
	else
		self:RefuseApply(oPlayer, sTarCharID)
	end
end

function CUnion:MemberListReq(oPlayer)
	local tMemberList = {}
	for sCharID, v in pairs(self.m_tMemberMap) do
		local oUnionPlayer = goUnionMgr:GetUnionPlayer(sCharID)
		local tItem = {}
		tItem.sID = sCharID
		tItem.sName = oUnionPlayer:Get("m_sName")
		tItem.nLevel = oUnionPlayer:Get("m_nLevel")
		tItem.nFame = oUnionPlayer:Get("m_nFame")
		tItem.nPos = self.tPosition.eMember
		if self:IsPresident(sCharID) then
			tItem.nPos = self.tPosition.ePresident
		elseif self:IsVicePresident(sCharID) then
			tItem.nPos = self.tPosition.eVicePresident
		end
		tItem.bOnline = false
		if goLuaPlayerMgr:GetPlayerByCharID(sCharID) then
			tItem.bOnline = true
		end
		table.insert(tMemberList, tItem)
	end
	local tMsg = {tMemberList = tMemberList}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "MemberListRet", tMsg)
end

function CUnion:KickMemberReq(oPlayer, sCharID)
	self:KickMember(oPlayer, sCharID)
end

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

function CUnion:AppointReq(oPlayer, sTarCharID, nTarPos)
	self:AppointPosition(oPlayer, sTarCharID, nTarPos)
end
