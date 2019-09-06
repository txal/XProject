--帮派玩家信息
function CUnionRole:Ctor()
	self.m_nUnionID = 0
	self.m_nRoleID = 0
	self.m_nExitTime = 0 		--上次退出帮派时间
	self.m_tApplyUnionMap = {} 	--申请公会列表映射{[nUnionID]=true}
	self.m_nUnionContri = 0 	--当前帮贡
	self.m_nTotalContri = 0 	--本帮派历史总帮贡
	self.m_nJoinTime = 0 		--加入帮派时间
	self.m_nDispatchGiftBoxTime = 0	--领取帮派礼盒的时间
	self.m_nDayContri = 0 		--日贡献
	self.m_nDayResetTime = 0 	--重置时间
end

--加载玩家数据
function CUnionRole:LoadData(tData)
	for k, v in pairs(tData)do
		self[k]= v
	end
end

--保存玩家数据
function CUnionRole:SaveData()
	tData = {}
	tData.m_nUnionID = self.m_nUnionID
	tData.m_nRoleID = self.m_nRoleID
	tData.m_nExitTime = self.m_nExitTime
	tData.m_tApplyUnionMap = self.m_tApplyUnionMap
	tData.m_nUnionContri = self.m_nUnionContri
	tData.m_nTotalContri = self.m_nTotalContri
	tData.m_nJoinTime = self.m_nJoinTime
	tData.m_nDispatchGiftBoxTime = self.m_nDispatchGiftBoxTime
	tData.m_nDayContri = self.m_nDayContri
	tData.m_nDayResetTime = self.m_nDayResetTime
	return tData
end

function CUnionRole:GetName() return goGPlayerMgr:GetRoleByID(self.m_nRoleID):GetName() end
function CUnionRole:GetRoleID() return self.m_nRoleID end
function CUnionRole:GetUnionID() return self.m_nUnionID end
function CUnionRole:GetExitTime() return self.m_nExitTime end
function CUnionRole:GetApplyUnionMap() return self.m_tApplyUnionMap end
function CUnionRole:SetApplyUnionMap(tApplyUnionMap) self.m_tApplyUnionMap=tApplyUnionMap end

function CUnionRole:SetUnionID(nUnionID)
	self.m_nUnionID = nUnionID
	self:MarkDirty(true)
end

function CUnionRole:CheckReset()
	if not os.IsSameDay(os.time(), self.m_nDayResetTime, 0) then
		self.m_nDayContri = 0
		self.m_nDayResetTime = os.time()
		self:MarkDirty(true)
	end
end

--退出帮派调用
function CUnionRole:OnExitUnion(nExitType)
	print("CUnionRole:OnExitUnion******")
	assert(nExitType, "没有填退出原因")
	local oUnion = goUnionMgr:GetUnion(self.m_nUnionID)
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)

	self.m_nUnionID = 0
	self.m_nDayContri = 0
	self.m_nTotalContri = 0
	self.m_nExitTime = os.time()
	self:MarkDirty(true)
	goUnionMgr:SyncUnionInfo(self.m_nRoleID)

	--扣除帮贡
	if nExitType == CUnion.tExit.eExit then
		local nSubNum = math.floor(self.m_nUnionContri*0.5)
		self:AddUnionContri(-nSubNum, "退出帮派")
	end

	oRole:SendMsg("UnionExitRet", {nExitType=nExitType})

	if nExitType == CUnion.tExit.eExit then
		oRole:Tips(string.format("已退出 %s 帮派", oUnion:GetName()))
	elseif nExitType == CUnion.tExit.eKick then
		CUtil:SendMail(oRole:GetServer(), "帮派信息", string.format("您已被%s派请离了", oUnion:GetName()), {}, self.m_nRoleID)
	end
	if nExitType ~= CUnion.tExit.eDismiss then
		oUnion:BroadcastUnionTalk(string.format("%s 离开了帮派", self:GetName()))
	end

	local tData = {m_nUnionID = 0}
	Network:RMCall("RoleUpdateReq", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetServer(), self.m_nRoleID, tData)
	oRole:UpdateReq(tData)
	local nServiceID = goServerMgr:GetGlobalService(gnWorldServerID,110)
	Network:RMCall("GRoleUpdateReq", nil, gnWorldServerID, nServiceID, oRole:GetSession(),self.m_nRoleID,tData)

	--返回京城
	if oRole:GetDupMixID() == oUnion:GetDupMixID() then
		local nDupMixID = 1
		Network:RMCall("RoleEnterDup", nil, oRole:GetServer(),oRole:GetLogic(),0,oRole:GetID(),nDupMixID,{nPosX=0,nPosY=0})
	end
	goUnionMgr:UpdateUnionAppellation(self.m_nRoleID)

	--日志
	goLogger:EventLog(gtEvent.eExitUnion, oRole, self.m_nUnionID, nExitType)
	goLogger:UpdateUnionMemberLog(gnServerID, self.m_nRoleID, {unionid=0, position=0, leavetime=os.time()
		, currcontri=self.m_nUnionContri, totalcontri=self.m_nTotalContri, daycontri=self.m_nDayContri})
end

--进入帮派调用
function CUnionRole:OnEnterUnion(oUnion)
	print("CUnionRole:OnEnterUnion******")
	assert(self.m_nUnionID == 0)
	self.m_nJoinTime = os.time()
	self.m_nUnionID = oUnion:GetID()
	self:MarkDirty(true)

	goUnionMgr:SyncUnionInfo(self.m_nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
	oUnion:SyncDetailInfo(oRole)
	oUnion:BroadcastUnionTalk(string.format("%s 加入帮派，作了个四方揖：小弟初来乍到，请各位多多关照。", self:GetName()))


	local tData = {m_nUnionID = self.m_nUnionID, m_nUnionJoinTime = self.m_nJoinTime}
	Network:RMCall("RoleUpdateReq", nil, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetServer(), self.m_nRoleID, tData)
	oRole:UpdateReq({m_nUnionID = self.m_nUnionID})

	local nServiceID = goServerMgr:GetGlobalService(gnWorldServerID,110)
	Network:RMCall("GRoleUpdateReq", nil, gnWorldServerID, nServiceID, oRole:GetSession(),self.m_nRoleID,{m_nUnionID = self.m_nUnionID})

	--日志
	goLogger:EventLog(gtEvent.eJoinUnion, oRole, self.m_nUnionID)
	goLogger:UpdateUnionMemberLog(gnServerID, self.m_nRoleID, {unionid=self.m_nUnionID, position=CUnion.tPosition.eChengYuan, jointime=os.time()
		, currcontri=self.m_nUnionContri, totalcontri=self.m_nTotalContri, daycontri=self.m_nDayContri})
end

--设置脏
function CUnionRole:MarkDirty(bDirty)
	goUnionMgr:MarkRoleDirty(self.m_nRoleID, bDirty)
end

--取联盟贡献
function CUnionRole:GetUnionContri() return self.m_nUnionContri end
function CUnionRole:GetTotalContri() return self.m_nTotalContri end

--加/减帮派贡献
function CUnionRole:AddUnionContri(nCount, sReason)
	if nCount == 0 then
		return
	end
	self:CheckReset()
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
    self.m_nUnionContri = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nUnionContri+nCount))
    if nCount > 0 then
		self.m_nDayContri = self.m_nDayContri + nCount
    	self.m_nTotalContri = math.max(0, math.min(gtGDef.tConst.nMaxInteger, self.m_nTotalContri+nCount))
    end
    self:MarkDirty(true)
    if nCount > 0 then
	    oRole:Tips(string.format("获得%d点帮派贡献", nCount))
	end

    --日志
    local nEventID = nCount> 0 and gtEvent.eAddItem or gtEvent.eSubItem
    goLogger:AwardLog(nEventID, sReason, oRole, gtItemType.eCurr, gtCurrType.eUnionContri, nCount, self.m_nUnionContri, self:GetUnionID())
	goLogger:UpdateUnionMemberLog(gnServerID, self.m_nRoleID, {currcontri=self.m_nUnionContri, totalcontri=self.m_nTotalContri, daycontri=self.m_nDayContri})

	if nCount > 0 then 
		oRole:AddActGTPersonUnionContri(nCount)
	end
    return self.m_nUnionContri
end

--取加入时间
function CUnionRole:GetJoinTime()
	return self.m_nJoinTime or 0
end

function CUnionRole:IsDispatchGiftBox()
	if os.IsSameWeek( os.time() , self.m_nDispatchGiftBoxTime , 0 ) then
		return true
	end
	return false
end

function CUnionRole:GetGiftBoxState()
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nRoleID)
	local nJoinTime = self:GetJoinTime()
	--这周已经领取了帮派礼盒
	if self:IsDispatchGiftBox() then
		return 2
	end
	if os.time() - nJoinTime < 5 * 24 * 3600 and oRole:GetTestMan() ~= 99 then
		return 1
	end
	if oRole:GetLevel() < 30 then
		return 1
	end
	return 0
end

function CUnionRole:SetDispatchGiftBoxTime()
	self:MarkDirty(true)
	self.m_nDispatchGiftBoxTime = os.time()
end