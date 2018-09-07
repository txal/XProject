--战队玩家信息
function CUnionPlayer:Ctor()
	self.m_nUnionID = 0
	self.m_sCharID = ""
	self.m_sName = 0
	self.m_nLevel = 0
	self.m_nFame = 0
	self.m_nExitTime = 0 --上次退出战队时间
	self.m_tApplyUnionMap = {} --申请公会列表映射{[nUnionID]=true}
end

--加载玩家数据
function CUnionPlayer:LoadData(tData)
	self.m_nUnionID = tData.nUnionID or 0
	self.m_sCharID = tData.sCharID
	self.m_sName = tData.sName
	self.m_nLevel = tData.nLevel
	self.m_nFame = tData.nFame
	self.m_nExitTime = tData.nExitTime
	for _, nUnionID in ipairs(tData.tApplyUnionList) do
		self.m_tApplyUnionMap[nUnionID] = true
	end
end

--保存玩家数据
function CUnionPlayer:SaveData()
	tData = {}
	tData.nUnionID = self.m_nUnionID
	tData.sCharID = self.m_sCharID
	tData.sName = self.m_sName
	tData.nLevel = self.m_nLevel
	tData.nFame = self.m_nFame
	tData.nExitTime = self.m_nExitTime
	tData.tApplyUnionList = {}
	for nUnionID, v in ipairs(self.m_tApplyUnionMap) do
		table.insert(tData.tApplyUnionList, nUnionID)
	end
	return tData
end

--退出战队调用
function CUnionPlayer:OnExitUnion(nExitType)
	print("CUnionPlayer:OnExitUnion******")
	assert(nExitType, "没有填退出原因")
	goLogger:EventLog(gtEvent.eExitUnion, nil, self.m_nUnionID, self.m_sCharID, nExitType)
	
	self.m_nUnionID = 0
	self.m_nExitTime = os.time()
	self:MarkDirty(true)

	goUnionMgr:SynUnionInfo(self.m_sCharID)
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(self.m_sCharID)
	if oPlayer then
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ExitUnionRet", {nType=nExitType})
	end
end

--进入战队调用
function CUnionPlayer:OnEnterUnion(oUnion)
	print("CUnionPlayer:OnEnterUnion******")
	assert(self.m_nUnionID == 0)
	self.m_nUnionID = oUnion:Get("m_nID")
	self:MarkDirty(true)

	goUnionMgr:SynUnionInfo(self.m_sCharID)
	goLogger:EventLog(gtEvent.eJoinUnion, nil, self.m_nUnionID, self.m_sCharID)
end

--设置脏
function CUnionPlayer:MarkDirty(bDirty)
	goUnionMgr:MarkPlayerDirty(self.m_sCharID, bDirty)
end