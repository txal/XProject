--联盟玩家信息
function CUnionPlayer:Ctor()
	self.m_nUnionID = 0
	self.m_nCharID = ""
	self.m_nExitTime = 0 		--上次退出联盟时间
	self.m_tApplyUnionMap = {} 	--申请公会列表映射{[nUnionID]=true}
	self.m_nUnionContri = 0 	--联盟贡献
	self.m_nOnlineTime = 0 		--上线事件

	--不保存
	self.m_sJoinNotice = "" 	--加入联盟第一次打开界面Tips提示
	self.m_sDismissNotice = "" 	--联盟解散下次打开界面的时候Tips提示
	self.m_sKickNotice = "" 	--被踢出联盟下次打开界面的时候Tips提示
end

--加载玩家数据
function CUnionPlayer:LoadData(tData)
	self.m_nUnionID = tData.m_nUnionID
	self.m_nCharID = tData.m_nCharID
	self.m_nExitTime = tData.m_nExitTime
	self.m_nOnlineTime = tData.m_nOnlineTime or 0
	self.m_nUnionContri = tData.m_nUnionContri or 0
	self.m_tApplyUnionMap = tData.m_tApplyUnionMap
end

--保存玩家数据
function CUnionPlayer:SaveData()
	tData = {}
	tData.m_nUnionID = self.m_nUnionID
	tData.m_nCharID = self.m_nCharID
	tData.m_nExitTime = self.m_nExitTime
	tData.m_nOnlineTime = self.m_nOnlineTime
	tData.m_nUnionContri = self.m_nUnionContri
	tData.m_tApplyUnionMap = self.m_tApplyUnionMap
	return tData
end

function CUnionPlayer:GetName()
	return goOfflineDataMgr:GetName(self.m_nCharID) --为啥要这样取呢，因为玩家可以改名
end

--玩家上线
function CUnionPlayer:Online()
	self.m_nOnlineTime = os.time()
	self:MarkDirty(true)
end

--退出联盟调用
function CUnionPlayer:OnExitUnion(nExitType)
	print("CUnionPlayer:OnExitUnion******")
	assert(nExitType, "没有填退出原因")
	goLogger:EventLog(gtEvent.eExitUnion, nil, self.m_nUnionID, self.m_nCharID, nExitType)
	local oUnion = goUnionMgr:GetUnion(self.m_nUnionID)

	self.m_nUnionID = 0
	self.m_nExitTime = os.time()
	self:AddUnionContri(-math.floor(self.m_nUnionContri*0.5), "退出联盟") --扣除1半贡献
	self:MarkDirty(true)

	goUnionMgr:SyncUnionInfo(self.m_nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(self.m_nCharID)
	if oPlayer then
		Network.PBSrv2Clt(oPlayer:GetSession(), "ExitUnionRet", {nExitType=nExitType})
		oPlayer.m_oMingChen:OnUnionChange()

	elseif nExitType == CUnion.tExit.eDismiss then
		self.m_sDismissNotice = string.format("%s 联盟已解散", oUnion:GetName())

	elseif nExitType == CUnion.tExit.eKick then
		self.m_sKickNotice = string.format("你已被踢出 %s 联盟", oUnion:GetName())

	end

	--频道公告
	if nExitType == CUnion.tExit.eExit then
		oUnion:BroadcastUnion(string.format("%s 退出联盟", self:GetName()))
	end
	--小红点清除
	CRedPoint:MarkRedPointAnyway(self.m_nCharID, gtRPDef.eUNMiracle, 0)
	CRedPoint:MarkRedPointAnyway(self.m_nCharID, gtRPDef.eUNParty, 0)
	CRedPoint:MarkRedPointAnyway(self.m_nCharID, gtRPDef.eUNBuild, 0)
	CRedPoint:MarkRedPointAnyway(self.m_nCharID, gtRPDef.eUNJoinReq, 0)
end

--进入联盟调用
function CUnionPlayer:OnEnterUnion(oUnion)
	print("CUnionPlayer:OnEnterUnion******")
	assert(self.m_nUnionID == 0)
	self.m_nUnionID = oUnion:Get("m_nID")
	self.m_sJoinNotice = string.format("加入 %s 联盟", oUnion:GetName())
	self:MarkDirty(true)

	goUnionMgr:SyncUnionInfo(self.m_nCharID)
	oUnion:BroadcastUnion(string.format("%s 加入联盟", self:GetName()))
	goLogger:EventLog(gtEvent.eJoinUnion, nil, self.m_nUnionID, self.m_nCharID, self:GetName())

	local oPlayer = goPlayerMgr:GetPlayerByCharID(self.m_nCharID)
	if oPlayer then --在线
		--名臣属性变更
		oPlayer.m_oMingChen:OnUnionChange()
	end
end

--设置脏
function CUnionPlayer:MarkDirty(bDirty)
	goUnionMgr:MarkPlayerDirty(self.m_nCharID, bDirty)
end

--加/减联盟贡献
function CUnionPlayer:AddUnionContri(nCount, sReason, oPlayer)
    self.m_nUnionContri = math.max(0, math.min(nMAX_INTEGER, self.m_nUnionContri+nCount))
    local nEventID = nCount> 0 and gtEvent.eAddItem or gtEvent.eSubItem
    goLogger:AwardLog(nEventID, sReason, oPlayer, gtItemType.eCurr, gtCurrType.eUnionContri, nCount, self.m_nUnionContri, self:GetName())
    self:MarkDirty(true)
end

--取联盟贡献
function CUnionPlayer:GetUnionContri()
	return self.m_nUnionContri
end

--首次加入联盟打开联盟主界面的时候通知
function CUnionPlayer:FirstJoinNotify(oPlayer)
	if self.m_sJoinNotice == "" then
		return
	end
	oPlayer:Tips(self.m_sJoinNotice)
	self.m_sJoinNotice = ""
end

--联盟解散玩家下一次点击联盟的时候
function CUnionPlayer:FirstDismissNotify(oPlayer)
	if self.m_sDismissNotice == "" then
		return
	end
	oPlayer:Tips(self.m_sDismissNotice)
	self.m_sDismissNotice = ""
end

--被踢出联盟下次打开界面的时候Tips提示
function CUnionPlayer:FirstKickNotify(oPlayer)
	if self.m_sKickNotice == "" then
		return
	end
	oPlayer:Tips(self.m_sKickNotice)
	self.m_sKickNotice = ""
end
