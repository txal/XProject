--帮派管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--战力比较
local function _fnPowerCmp(t1, t2)
	if t1[1] > t2[1] then
		return 1
	end
	if t1[1] < t2[1] then
		return -1
	end
	return 0
end

--积分比较
local function _fnScoreCmp(t1, t2)
	if t1[1] > t2[1] then
		return 1
	end
	if t1[1] < t2[1] then
		return -1
	end
	return 0
end

local nMaxUnionID = 9999
function CUnionMgr:Ctor()
	self.m_nAutoID = 0
	self.m_nAutoShowID = 0
	
	self.m_tUnionMap = {} 		--{[nUnionID]=oUnion}
	self.m_tUnionRoleMap = {} 	--{[nRoleID]=oUnionRole}
	self.m_tCombindMap = {} 	--合并帮派

	self.m_tDirtyUnionMap = {} 		--不保存
	self.m_tDirtyUnionRoleMap = {} 	--不保存

	self.m_oPowerRanking = CSkipList:new(_fnPowerCmp) 	--战力榜{power}
	self.m_oScoreRanking = CSkipList:new(_fnScoreCmp) 	--积分榜{score}

	self.m_tUnionIDList = {} 	--不保存
	self.m_tUnionNameMap = {} 	--不保存{[sUnionName]=nUnionID}

	self.m_nSaveTick = nil
	self.m_nHourTimer = nil 	--每小时计时器
end

function CUnionMgr:AutoSave()
	self.m_nSaveTick = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
	local nNextHourTime = os.NextHourTime(os.time())
	self.m_nHourTimer = GetGModule("TimerMgr"):Interval(nNextHourTime, function() self:OnHourTimer() end)
end

function CUnionMgr:Release()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
	GetGModule("TimerMgr"):Clear(self.m_nHourTimer)
	self.m_nHourTimer = nil
	self:ClearDupTick()
	self:SaveData()
end

--加载帮派数据
function CUnionMgr:LoadData()
	--自动增长ID
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oDB:HGet(gtDBDef.sUnionEtcDB, "data")
	local tData = sData == "" and {} or cjson.decode(sData)

	self.m_nAutoID = tData.m_nAutoID or 0
	self.m_nAutoShowID = tData.m_nAutoShowID or 0
	self.m_tCombindMap = tData.m_tCombindMap or {}

	--帮派玩家数据
	local tKeys = oDB:HKeys(gtDBDef.sUnionRoleDB)
	for _, sKey in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sUnionRoleDB, sKey)
		local tData = cjson.decode(sData)
		local oUnionRole = CUnionRole:new()
		oUnionRole:LoadData(tData)
		self.m_tUnionRoleMap[oUnionRole:GetRoleID()] = oUnionRole
	end

	--帮派数据
	local tKeys = oDB:HKeys(gtDBDef.sUnionDB)
	for _, sKey in ipairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sUnionDB, sKey)
		local tData = cjson.decode(sData)
		local oUnion = CUnion:new()
		if oUnion:LoadData(tData) then
			self.m_tUnionMap[oUnion:GetID()] = oUnion
			self.m_tUnionNameMap[oUnion:GetName()] = oUnion:GetID()
			table.insert(self.m_tUnionIDList, oUnion:GetID())
		end
	end

	--检测玩家数据
	for nRoleID, oUnionRole in pairs(self.m_tUnionRoleMap) do
		local nUnionID = oUnionRole:GetUnionID()
		if nUnionID > 0 then
			if not self:GetUnion(nUnionID) then
				oUnionRole:SetUionID(nUnionID)
				LuaTrace("成员帮派ID错误:", oUnionRole:GetName(), nUnionID)
			end
		end
	end

	--排行榜数据
	for nUnionID, oUnion in pairs(self.m_tUnionMap) do
		if oUnion:GetPower() > 0 then
			self.m_oPowerRanking:Insert(nUnionID, {oUnion:GetPower()})
		end
	end

	--定时保存
	self:AutoSave()

	--检查一下，兼容旧数据
	for nUnionID,oUnion in pairs(self.m_tUnionMap) do
		if oUnion:GetShowID() == 0 then
			local nUnionShowID = self:MakeUnionShowID()
			oUnion:SetShowID(nUnionShowID)
		end
	end
end

--保存帮派数据
function CUnionMgr:SaveData()
	print("CUnionMgr:SaveData***")
	--保存帮派
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	for nUnionID, _ in pairs(self.m_tDirtyUnionMap) do
		local oUnion = self.m_tUnionMap[nUnionID]
		if oUnion then
			local tData = oUnion:SaveData()
			oDB:HSet(gtDBDef.sUnionDB, nUnionID, cjson.encode(tData))
		end
	end
	self.m_tDirtyUnionMap = {}

	--保存玩家
	for nRoleID, _ in pairs(self.m_tDirtyUnionRoleMap) do
		local oUnionRole = self.m_tUnionRoleMap[nRoleID]
		local tData = oUnionRole:SaveData()
		oDB:HSet(gtDBDef.sUnionRoleDB, nRoleID, cjson.encode(tData))
	end
	self.m_tDirtyUnionRoleMap = {}

	--自动增长ID
	local tEtcData = {m_nAutoID=self.m_nAutoID,m_nAutoShowID=self.m_nAutoShowID,m_tCombindMap=self.m_tCombindMap}
	oDB:HSet(gtDBDef.sUnionEtcDB, "data", cjson.encode(tEtcData))
end

--帮派脏
function CUnionMgr:MarkUnionDirty(nUnionID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyUnionMap[nUnionID] = bDirty
end

--玩家脏
function CUnionMgr:MarkRoleDirty(nRoleID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyUnionRoleMap[nRoleID] = bDirty
end

--生成帮派ID
function CUnionMgr:MakeUnionID()
	self.m_nAutoID = self.m_nAutoID or 1000
	self.m_nAutoID = self.m_nAutoID % nMaxUnionID + 1
	local nUnionID = gnServerID*10000 + self.m_nAutoID
	return nUnionID
end

--生成帮派显示ID
function CUnionMgr:MakeUnionShowID()
	self.m_nAutoShowID = self.m_nAutoShowID % gtGDef.tConst.nMaxInteger + 1
	return self.m_nAutoShowID
end

--取帮派
function CUnionMgr:GetUnion(nUnionID)
	return self.m_tUnionMap[nUnionID]
end

--通过玩家ID取公会
function CUnionMgr:GetUnionByRoleID(nRoleID)
	local oUnionRole = self:GetUnionRole(nRoleID)
	if oUnionRole then
		local nUnionID = oUnionRole:GetUnionID()
		return self:GetUnion(nUnionID)
	end
end

--取帮派玩家
function CUnionMgr:GetUnionRole(nRoleID)
	return self.m_tUnionRoleMap[nRoleID]
end

--创建帮派玩家
function CUnionMgr:CreateUnionRole(oRole)
	local nRoleID = oRole:GetID()
	assert(not self:GetUnionRole(nRoleID))
	local oUnionRole = CUnionRole:new()
	oUnionRole.m_nRoleID = nRoleID
	self.m_tUnionRoleMap[nRoleID] = oUnionRole
	oUnionRole:MarkDirty(true)
	self:SaveData() --立即保存

	--日志
	goLogger:CreateUnionMemberLog(oRole)
	return oUnionRole
end

--取冷却时间
function CUnionMgr:GetJoinCD(oRole, bNotify)
	local nRoleID = oRole:GetID()
	local oUnionRole = self:GetUnionRole(nRoleID)
	if not oUnionRole then
		return 0
	end
	local nHourCD = ctUnionEtcConf[1].nExitCD
	local nRemainCD = math.max(0, oUnionRole:GetExitTime()+nHourCD*3600-os.time())
	if nRemainCD > 0 and bNotify then
		oRole:Tips(string.format("退出帮派不足%d小时，无法加入新的帮派", nHourCD))
	end
	return nRemainCD
end

--是否开放
function CUnionMgr:IsOpen(oRole)
	if oRole:GetLevel() < ctSysOpenConf[22].nLevel then
		return oRole:Tips("帮派系统未开启")
	end
	return true
end

--创建新帮派
function CUnionMgr:CreateUnion(oRole, sName)
	if not self:IsOpen(oRole) then
		return
	end
	sName = string.Trim(sName)
	local sNameLen = string.len(sName)
	if sNameLen <= 0 then
		return oRole:Tips("请输入帮派名字")
	end
	if sNameLen > CUnion.nMaxUnionNameLen then
		return oRole:Tips("名字超长，不能超过6个汉字")
	end
	local nRoleID = oRole:GetID()
	if self.m_tUnionNameMap[sName] then
		return oRole:Tips("帮派名字已被占用")
	end
	local oUnionRole = self:GetUnionRole(nRoleID)
	if oUnionRole and oUnionRole:GetUnionID() > 0 then
		return oRole:Tips("你已经有帮派")
	end
	--冷却
	if self:GetJoinCD(oRole, true) > 0 then
		return
	end


	local function fnCallback(bRes)
		bRes = bRes == nil and true or bRes
		if bRes then
			return oRole:Tips("名字含有非法字符")
		end

		--前后端创建费用显示不同意，策划要求服务器做一个弹窗提示
		local _fnClientConfirmed = function()
			--等待确认期间，可能帮派名称被占用
			if self.m_tUnionNameMap[sName] then
				return oRole:Tips("帮派名字已被占用")
			end

			local oUnionRole = self:GetUnionRole(nRoleID)  --再次检查下，防止重复发起
			if oUnionRole and oUnionRole:GetUnionID() > 0 then
				return oRole:Tips("你已经有帮派")
			end
			local nUnionID = self:MakeUnionID()
			if self.m_tUnionMap[nUnionID] then
				return oRole:Tips("帮派ID已经被占用")
			end
			local nUnionShowID = self:MakeUnionShowID()
			if not oUnionRole then
				oUnionRole = self:CreateUnionRole(oRole)
			end

			local tItemList = {{nType=gtItemType.eCurr, nID=gtCurrType.eYuanBao, nNum=ctUnionEtcConf[1].nCreateCost}}
			oRole:SubItem(tItemList, "创建帮派", function(bRes)
				if not bRes then
					return oRole:YuanBaoTips()
				end
				if oUnionRole:GetUnionID() > 0 then
					return oRole:Tips("已经有帮派了")
				end

				local oUnion = CUnion:new()
				self.m_tUnionMap[nUnionID] = oUnion
				if not oUnion:CreateInit(oRole, nUnionID, nUnionShowID, sName) then
					self.m_tUnionMap[nUnionID] = nil
					LuaTrace(oRole:GetID(), "创建帮派失败")
					return
				end
				self.m_tUnionNameMap[sName] = nUnionID
				table.insert(self.m_tUnionIDList, nUnionID)

				self:SaveData() --立即保存
				oUnion:SyncDetailInfo(oRole) --前端要详细信息

				goRankingMgr:OnUnionCreate(nUnionID)
				oUnion:CreateUnionScene()
			end)
		end
		_fnClientConfirmed()

		-- local tOption = {"取消", "确定"}
		-- local nYuanbaoCost = ctUnionEtcConf[1].nCreateCost
		-- local sCont = string.format("创建帮派需要消耗 %d 元宝, 是否继续？", nYuanbaoCost)
		-- local tMsg = {sCont=sCont, tOption=tOption, nTimeOut=30}
		-- goClientCall:CallWait("ConfirmRet", function(tData)
		-- 	if not tData then 
		-- 		return 
		-- 	end
		-- 	if tData.nSelIdx == 1 then
		-- 		return
		-- 	end
		-- 	_fnClientConfirmed()
		-- end, oRole, tMsg)
	end
	CUtil:HasBadWord(sName, fnCallback)
end

--帮派解散
function CUnionMgr:OnUnionDismiss(oUnion)
	local nUnionID, sUnionName = oUnion:GetID(), oUnion:GetName()
	self.m_tUnionMap[nUnionID] = nil
	self.m_tUnionNameMap[sUnionName] = nil
	self:MarkUnionDirty(nUnionID, false)
	goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID()):HDel(gtDBDef.sUnionDB, nUnionID)

	for nIndex, nTmpID in ipairs(self.m_tUnionIDList) do
		if nTmpID == nUnionID then
			table.remove(self.m_tUnionIDList, nIndex)
			break
		end
	end

	goRankingMgr:OnUnionDismiss(nUnionID)
	oUnion:RemoveDup()

	local nServiceID = goServerMgr:GetGlobalService(gnWorldServerID, 110)
	Network.oRemoteCall:Call("OnUnionDismissReq", gnWorldServerID, nServiceID, 0, nUnionID)

	--日志
	goLogger:DelUnionLog(gnServerID, nUnionID)
end

--同步帮派基本信息
function CUnionMgr:SyncUnionInfo(nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end

	local nID, sName, nPos, sPos,nShowID = 0, "", 0, "",0
	local oUnion = self:GetUnionByRoleID(nRoleID)
	if oUnion then
		nID, sName, nPos, sPos,nShowID = oUnion:GetID(), oUnion:GetName(), oUnion:GetPos(nRoleID), oUnion:GetPosName(nRoleID),oUnion:GetShowID()
	end

	local tMsg = {nID=nID, sName=sName, nPos=nPos, sPos=sPos,nShowID=nShowID}
	oRole:SendMsg("UnionInfoRet", tMsg)
	print("CUnionMgr:SyncUnionInfo***", tMsg)
end

--帮派列表请求
--帮派编号，帮派名，帮派等级，人数（当前人数/人数上限），帮主名，每一页显示10个帮派的信息，可上下滚动翻页
function CUnionMgr:UnionListReq(oRole, sUnionKey, nPageIndex)
	print("CUnionMgr:UnionListReq***", sUnionKey)
	local nPageSize = 15
	local nRoleID = oRole:GetID()
	local nPageBegin = (nPageIndex-1)*10+1
	local nPageEnd = nPageBegin+nPageSize-1
	local nPageCount = 0

	local tUnionIDList = {}
	if sUnionKey == "" then
		local tTmpList = {}
		for nUnionID, oUnion in pairs(self.m_tUnionMap) do
			table.insert(tTmpList,{oUnion:GetShowID(),nUnionID})
		end
		local fnSort = function (tID1,tID2)
			if tID1[1] ~= tID2[1] then
				return tID1[1] > tID2[1]
			else
				return tID1[2] > tID2[2]
			end
		end
		table.sort(tTmpList, fnSort)
		nPageCount = math.ceil(#tTmpList/nPageSize)
 
		for k = nPageBegin, nPageEnd do
			if not tTmpList[k] then break end
			local tUnionID = tTmpList[k]
			table.insert(tUnionIDList, tUnionID[2])
		end
	else
		--筛选帮派
		local tTmpList = {}
		for sName, nUnionID in pairs(self.m_tUnionNameMap) do
			local oUnion = self:GetUnion(nUnionID)
			local nShowID = oUnion:GetShowID()
			if string.find(sName, sUnionKey) or string.find(tostring(nShowID), sUnionKey) then
				table.insert(tTmpList, {nShowID,nUnionID})
			end
		end
		local fnSort = function (tID1,tID2)
			if tID1[1] ~= tID2[1] then
				return tID1[1] > tID2[1]
			else
				return tID1[2] > tID2[2]
			end
		end
		table.sort(tTmpList, fnSort)
		nPageCount = math.ceil(#tTmpList/nPageSize)

		for k = nPageBegin, nPageEnd do
			if not tTmpList[k] then break end
			local tUnionID = tTmpList[k]
			table.insert(tUnionIDList, tUnionID[2])
		end
	end

	--帮派编号，帮派名，帮派等级，人数（当前人数/人数上限），帮主名，每一页显示10个帮派的信息，可上下滚动翻页
	local tUnionList = {}
	for _, nUnionID in ipairs(tUnionIDList) do
		local oUnion = self:GetUnion(nUnionID)
		if oUnion then
			local tItem = {}
			tItem.nID = nUnionID
			tItem.sName = oUnion:GetName()
			tItem.nLevel = oUnion:GetLevel()
			tItem.nMembers = oUnion:GetMembers()
			tItem.nMaxMembers = oUnion:MaxMembers()
			tItem.sMengZhu = oUnion:GetMengZhuName()
			tItem.bApplied = oUnion:IsApplied(nRoleID)
			tItem.nPower = oUnion:GetPower()
			tItem.sPurpose = oUnion:GetPurpose()
			tItem.nShowID = oUnion:GetShowID()
			table.insert(tUnionList, tItem)
		end
	end
	nPageIndex = math.min(nPageCount, nPageIndex)
	local tMsg = {tUnionList=tUnionList, nPageIndex=nPageIndex, nPageCount=nPageCount}
	oRole:SendMsg("UnionListRet", tMsg)
	print("UnionListRet****", tMsg)
end

--创建帮派请求
function CUnionMgr:UnionCreateReq(oRole, sName)
	self:CreateUnion(oRole, sName)
end

--随机加入帮派请求
function CUnionMgr:UnionJoinRandReq(oRole)
	if not self:IsOpen(oRole) then
		return
	end
	local nRoleID = oRole:GetID()
	if self:GetUnion(nRoleID) then
		return oRole:Tips("你已有帮派")
	end
	if self:GetJoinCD(oRole, true) > 0 then
		return
	end

	local tUnionList = {}
	for _, nUnionID in ipairs(self.m_tUnionIDList) do
		local oUnion = self:GetUnion(nUnionID)
		if not oUnion:IsFull() and oUnion:IsAutoJoin() then
			table.insert(tUnionList, oUnion)
		end
	end
	if #tUnionList <= 0 then
		return oRole:Tips("没有可加入的帮派")
	end

	local oUnion = tUnionList[math.random(#tUnionList)]
	local oUnionRole = goUnionMgr:GetUnionRole(nRoleID)
	if not oUnionRole then
		oUnionRole = self:CreateUnionRole(oRole)
	end
	oUnion:JoinUnion(nil, nRoleID)
end

--玩家上线
function CUnionMgr:Online(oRole)
	local nRoleID = oRole:GetID()
	self:SyncUnionInfo(nRoleID)
	self:UpdateUnionAppellation(nRoleID) --每次上线，更新下最新的帮会称号
	local oUnion = self:GetUnionByRoleID(nRoleID)
	if oUnion then oUnion:Online(oRole) end
end

--帮派改名事件
function CUnionMgr:OnSetUnionName(oUnion, sOldName)
	self.m_tUnionNameMap[sOldName] = nil
	self.m_tUnionNameMap[oUnion:GetName()] = oUnion:GetID()
end

--整点计时器
function CUnionMgr:OnHourTimer()
	GetGModule("TimerMgr"):Clear(self.m_nHourTimer)
	self.m_nHourTimer = GetGModule("TimerMgr"):Interval(os.NextHourTime(os.time()), function() self:OnHourTimer() end)

	for _, oUnion in pairs(self.m_tUnionMap) do
		oUnion:OnHourTimer()
	end

	local nHour = os.Hour()
	if nHour == 0 then
		self:CombindUnion()
	end
end

--合并帮派
function CUnionMgr:CombindUnion()
	local tCombindList = {}
	for nUnionID, nTime in pairs(self.m_tCombindMap) do
		if self:GetUnion(nUnionID) then
			if os.time() - nTime >= 3*24*3600 then
				table.insert(tCombindList, nUnionID)
			end
		else
			self.m_tCombindMap[nUnionID] = nil
		end
	end
	
	if #tCombindList <= 0 then
		LuaTrace("没有可合并帮派")
		return -1
	end
	LuaTrace("满足合并条件帮派:", tCombindList)

	--首先筛选出所有人数符合要求的帮派，即待合并帮派+目标帮派人数≤目标帮派容纳上限
	--优先选择合并到活跃度100000的5级帮派，其次选择活跃度100000的4级帮派
	--若没有则选择活跃度75000以上的5级帮派，其次选择活跃度75000以上的4级帮派
	--若没有则选择活跃度100000以上的3级帮派

	local  tCondList = {}
	for nUnionID, oUnion in pairs(self.m_tUnionMap) do
		if not oUnion:IsFull() and not self.m_tCombindMap[nUnionID] then
			if oUnion:GetActivity()==100000 and oUnion:GetLevel()==5 then
				table.insert(tCondList, {oUnion,1, nUnionID})
			elseif oUnion:GetActivity()==100000 and oUnion:GetLevel()==4 then
				table.insert(tCondList, {oUnion,2, nUnionID})
			elseif oUnion:GetActivity()>=75000 and oUnion:GetLevel()==5 then
				table.insert(tCondList, {oUnion,3, nUnionID})
			elseif oUnion:GetActivity()>=75000 and oUnion:GetLevel()==4 then
				table.insert(tCondList, {oUnion,4, nUnionID})
			elseif oUnion:GetActivity()>=100000 and oUnion:GetLevel()==3 then
				table.insert(tCondList, {oUnion,5, nUnionID})
			end
		end
	end
	table.sort(tCondList, function(t1, t2) return t1[2]<t2[2] end)
	if #tCondList <= 0 then
		LuaTrace("没有满足条件的目标帮派")
		return -2 
	end

	local nCombindCount = 0
	for _, nCombindUnionID in ipairs(tCombindList) do
		local oSrcUnion = self:GetUnion(nCombindUnionID)
		for _, tUnion in ipairs(tCondList) do
			local oTarUnion = tUnion[1]
			if oSrcUnion:GetMembers()+oTarUnion:GetMembers() <= oTarUnion:MaxMembers() then
				local tSrcMemberMap = oSrcUnion:GetMemberMap()
				for nRoleID, v in pairs(tSrcMemberMap) do
					local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
					local oUnionRole = self:GetUnionRole(nRoleID)		
					local nPos = oSrcUnion:GetPos(nRoleID)
					if oRole:GetOfflineKeepTime() >= 5*24*3600 then
						oUnionRole:OnExitUnion(CUnion.tExit.eCombind)
						local sCont = string.format("我帮已与%s帮派成功合并。由于您离线时间大于5天，系统已将您请离帮派！您可以重新申请加入一个新帮派", oTarUnion:GetName())
						CUtil:SendMail(oRole:GetServer(), "退帮通知", sCont, {}, nRoleID)
					else
						oUnionRole:OnExitUnion(CUnion.tExit.eCombind)
						oTarUnion:JoinUnion(nil, nRoleID)
						
						local sCont = string.format("您的帮派已与%s帮派成功合并。给予以下补偿，请查收。", oTarUnion:GetName())
						local tItemList = nPos==CUnion.tPosition.eMengZhu and {{gtItemType.eProp,4,1250000}} or {{{gtItemType.eProp,4,50000}}}
						CUtil:SendMail(oRole:GetServer(), "合帮补偿通知", sCont, tItemList, nRoleID)
					end
				end
				oTarUnion:BroadcastUnionTalk(string.format("%s帮派已成功合并到我帮，大家欢迎新来的朋友。", oSrcUnion:GetName()))
				self.m_tCombindMap[nCombindUnionID] = nil
				self:OnUnionDismiss(oSrcUnion)
				nCombindCount = nCombindCount + 1
				LuaTrace("帮派合并:%d:%s->%d:%s", oSrcUnion:GetID(), oSrcUnion:GetName(), oTarUnion:GetID(), oTarUnion:GetName())
				goLogger:EventLog(gtEvent.eUnionCombind, nil, oSrcUnion:GetID(), oTarUnion:GetID())
			end
		end
	end
	return nCombindCount
end

--加入到待合并帮派
function CUnionMgr:AddCombindUnion(nUnionID)
	if self.m_tCombindMap[nUnionID] then
		return
	end
	self.m_tCombindMap[nUnionID] = os.time()
end

--从待合并帮派移除
function CUnionMgr:RemoveCombindUnion(nUnionID)
	self.m_tCombindMap[nUnionID] = nil
end

--取联盟成员列表 
function CUnionMgr:GetMemberList(nRoleID)
	local oUnion = self:GetUnionByRoleID(nRoleID)
	if not oUnion then
		return {}
	end
	local tMemberList = {}
	local tMemberMap = oUnion:GetMemberMap()
	for nRoleID, v in pairs(tMemberMap) do
		table.insert(tMemberList, nRoleID)
	end
	return tMemberList
end

--角色战力变化
function CUnionMgr:OnRolePowerChange(oRole)
	local oUnion = self:GetUnionByRoleID(oRole:GetID())
	if not oUnion then
		return
	end
	oUnion:UpdatePower()
end

--联盟总战力变化
function CUnionMgr:OnUnionPowerChange(oUnion)
	local nUnionID = oUnion:GetID()
	local nPower = oUnion:GetPower()
	if nPower <= 0 then return end

	local tData = self.m_oPowerRanking:GetDataByKey(nUnionID)
	if tData then
		if tData[1]	== nPower then
			return
		end
		self.m_oPowerRanking:Remove(nUnionID)
		tData[1] = nPower
	else
		tData = {nPower}
	end
	self.m_oPowerRanking:Insert(nUnionID, tData)
end

--战力排行榜请求
function CUnionMgr:UnionPowerRankingReq(oRole, nRankNum)
	nRankNum = math.max(1, math.min(100, nRankNum))
	local nRoleID = oRole:GetID()

	--我的排名
	local nMyRank, sMyName, nMyValue = 0, "", 0
	local oMyUnion = self:GetUnionByRoleID(nRoleID)
	if oMyUnion then
		sMyName = oMyUnion:GetName()
		local nUnionID = oMyUnion:GetID()
		nMyRank = self.m_oPowerRanking:GetRankByKey(nUnionID)
		local tData = self.m_oPowerRanking:GetDataByKey(nUnionID)
		nMyValue = tData and tData[1] or 0
	end

	--前nRankNum名联盟
	local tRanking = {}
	local function _fnTraverse(nRank, nUnionID, tData)
		local oUnion = self:GetUnion(nUnionID)
		if oUnion then
			local tRank = {nRank=nRank, sName=oUnion:GetName(), nValue=tData[1], nLevel=0, sMengZhu="", nMember=0, nMaxMember=0}
			tRank.nLevel = oUnion:GetLevel()
			tRank.sMengZhu = oUnion:GetMengZhuName()
			tRank.nMember = oUnion:GetMembers()
			tRank.nMaxMember = oUnion:MaxMembers()
			table.insert(tRanking, tRank)
		end
	end
	self.m_oPowerRanking:Traverse(1, nRankNum, _fnTraverse)
	local tMsg = {
		tRanking = tRanking,
		nMyRank = nMyRank,
		sMyName = sMyName,
		nMyValue = nMyValue,
	}
	oRole:SendMsg("UnionPowerRankingRet", tMsg)
end

--打包帮战信息
function CUnionMgr:PackUnionArenaData()
	local tRet = {}
	local tUnionData = {}
	local nCount = 0
	for nUnionID, oUnion in pairs(self.m_tUnionMap) do
		if (oUnion:GetLevel() >= 2 and oUnion:GetActivity() >= 60) or gbInnerServer then 
			tUnionData[nUnionID] = oUnion:PackUnionArenaData()
			nCount = nCount + 1
		end
	end
	if nCount > 1024 then 
		LuaTrace(string.format("请注意，帮会数据过多，当前数量(%d)", nCount))
	end
	tRet.nServerID = gnServerID
	tRet.tUnionData = tUnionData
	return tRet
end

function CUnionMgr:SetMatchArenaData(tData)
	tData = tData or {}
	for nUnionID,nEnemyUnionID in pairs(tData) do
		local oUnion = self:GetUnion(nUnionID)
		if oUnion then
			if nEnemyUnionID and nEnemyUnionID ~= 0 then
				oUnion:AddMatchArean(nEnemyUnionID)
			else
				oUnion:ArenaLunKong()
			end
		end
	end
end

function CUnionMgr:ClearDupTick()
	self.m_tCreateDupTick = self.m_tCreateDupTick or {}
	local tStep = table.Keys(self.m_tCreateDupTick)
	for _,nStep in pairs(tStep) do
		GetGModule("TimerMgr"):Clear(self.m_tCreateDupTick[nStep])
	end
	self.m_tCreateDupTick = {}
end

function CUnionMgr:_CreateUnionScene(tStepUnion,nStep)
	GetGModule("TimerMgr"):Clear(self.m_tCreateDupTick[nStep])
	self.m_tCreateDupTick[nStep] = nil
	
	local tUnionID = tStepUnion[nStep]
	if not tUnionID then
		return
	end
	for nUnionID,_ in pairs(tUnionID) do
		local oUnion = self:GetUnion(nUnionID)
		if oUnion and oUnion:GetDupMixID() == 0 then
			oUnion:CreateUnionScene()
		end
	end
end

function CUnionMgr:CreateUnionScene()
	local tUnionID = table.Keys(self.m_tUnionMap)
	local tStepUnion = {}
	for nNo,nUnionID in ipairs(tUnionID) do
		local oUnion = self:GetUnion(nUnionID)
		if oUnion and oUnion:GetDupMixID() == 0 then
			local nStep = nNo // 100 + 1
			if not tStepUnion[nStep] then
				tStepUnion[nStep] = {}
			end
			tStepUnion[nStep][nUnionID] = 1
		end
	end
	if table.Count(tStepUnion) <= 0 then
		return
	end
	
	self.m_tCreateDupTick = {}
	for nStep,tUnionID in pairs(tStepUnion) do
		local fnCallback = function ()
			self:_CreateUnionScene(tStepUnion,nStep)
		end
		self.m_tCreateDupTick[nStep] = GetGModule("TimerMgr"):Interval(1,fnCallback)
	end
end

--更新角色帮会称谓
function CUnionMgr:UpdateUnionAppellation(nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole:IsOnline() then --玩家不在线，不处理，玩家上线，会自动做一次更新同步
		return 
	end
	local nAppeID = 0
	local tAppeParam = {}
	local nSubKey = 0

	local oUnion = self:GetUnionByRoleID(nRoleID)
	if oUnion then 
		local nPosition = oUnion:GetPos(nRoleID)
		nAppeID = oUnion:GetAppellationByPos(nPosition)
		local sUnionName = oUnion:GetName()
		local sPosName = oUnion:GetPosName(nRoleID)
		assert(nAppeID > 0 and sUnionName and sPosName)
		tAppeParam = {tNameParam={sUnionName, sPosName}, nUnionID = oUnion:GetID()}
	else
		nAppeID = 0
	end

	local nServer = oRole:GetStayServer()
	local nService = oRole:GetLogic()
	local nSession = oRole:GetSession()
	local nRoleID = oRole:GetID()
	Network.oRemoteCall:Call("UpdateUnionAppellation", nServer, nService, nSession, nRoleID, nAppeID, tAppeParam, nSubKey)
end
