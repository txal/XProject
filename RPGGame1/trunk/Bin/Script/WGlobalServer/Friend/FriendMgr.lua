--好友管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxFriends = 50 --好友上限
-- local nMaxSendProps = 5 --赠送道具上限
local nMaxStrangers = 10 --陌生人上限
local nMaxApplys = 10 	--好友申请上限

function CFriendMgr:Ctor()
	-- self.m_tSentPropMap = {} 		--赠送道具{[角色ID]=道具数量,...}
	-- self.m_nResetTime = os.time()	--赠送道具重置时间

	self.m_tFriendMap = {} 			--好友映射{[角色ID]={[角色ID]=好友对象,...},...}
	self.m_tStrangerMap = {} 		--陌生人映射{[角色ID]={[角色ID]=好友对象,...},...}

	self.m_tDirtyFriendMap = {} 	--脏的好友
	self.m_tDirtyStrangerMap = {} 	--脏的陌生人

	self.m_tApplyMap = {} 			--好友申请列表
	self.m_bEtcDrity = false 

	--不保存
	self.m_tBattleMap = {}
	self.m_tSearchTimeMap = {} 			--查找时间记录
	self.m_tRecommandRoleMap = {} 		--推荐好友记录
	self.m_tLastSearchResMap = {} 		--上次查找推荐好友结果
end

function CFriendMgr:LoadData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oDB:HGet(gtDBDef.sFriendEtcDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_tApplyMap = tData.m_tApplyMap or {}
	end

	local tKeys = oDB:HKeys(gtDBDef.sFriendDataDB)
	for _, sRoleID in pairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sFriendDataDB, sRoleID)
		local tData = cjson.decode(sData)
		local nRoleID = tonumber(sRoleID)
		self.m_tFriendMap[nRoleID] = {}

		for nFriendRoleID, tFriendData in pairs(tData) do
			assert(not tFriendData.m_bStranger, "数据错误")
			local oFriend = CFriend:new(self, nRoleID, nFriendRoleID)
			oFriend:LoadData(tFriendData)
			self.m_tFriendMap[nRoleID][nFriendRoleID] = oFriend
		end

	end

	local tKeys = oDB:HKeys(gtDBDef.sStrangerDataDB)
	for _, sRoleID in pairs(tKeys) do
		local sData = oDB:HGet(gtDBDef.sStrangerDataDB, sRoleID)
		local tData = cjson.decode(sData)
		local nRoleID = tonumber(sRoleID)
		self.m_tStrangerMap[nRoleID] = {}

		for nStrangerRoleID, tStrangerData in pairs(tData) do
			assert(tStrangerData.m_bStranger, "数据错误")
			local oStranger = CFriend:new(self, nRoleID, nStrangerRoleID, true)
			oStranger:LoadData(tStrangerData)
			self.m_tStrangerMap[nRoleID][nStrangerRoleID] = oStranger
		end
	end

	self:RegAutoSave()
end

function CFriendMgr:SaveData()
	local oDB = goDBMgr:GetSSDB(gnServerID, "global", CUtil:GetServiceID())
	if self:IsEtcDirty() then
		local tData = {}
		tData.m_tApplyMap = self.m_tApplyMap
		oDB:HSet(gtDBDef.sFriendEtcDB, "data", cjson.encode(tData))
		self:MarkEtcDirty(false)
	end

	for nRoleID, _ in pairs(self.m_tDirtyFriendMap) do
		local tData = {}
		local tFriendMap = self.m_tFriendMap[nRoleID]
		for nFriendRoleID, oFriend in pairs(tFriendMap) do
			tData[nFriendRoleID] = oFriend:SaveData()
		end
		oDB:HSet(gtDBDef.sFriendDataDB, nRoleID, cjson.encode(tData))
	end
	self.m_tDirtyFriendMap = {}

	for nRoleID, _ in pairs(self.m_tDirtyStrangerMap) do
		local tData = {}
		local tStrangerMap = self.m_tStrangerMap[nRoleID]
		for nStrangerRoleID, oFriend in pairs(tStrangerMap) do
			tData[nStrangerRoleID] = oFriend:SaveData()
		end
		oDB:HSet(gtDBDef.sStrangerDataDB, nRoleID, cjson.encode(tData))
	end
	self.m_tDirtyStrangerMap = {}
end

function CFriendMgr:Release()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
	self:SaveData()
end

function CFriendMgr:RegAutoSave()
	self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

function CFriendMgr:IsEtcDirty() return self.m_bEtcDirty end
function CFriendMgr:MarkEtcDirty(bDirty) self.m_bEtcDirty = bDirty end
function CFriendMgr:MarkFriendDirty(nRoleID, bDirty)
	bDirty = bDirty and true or nil
	self.m_tDirtyFriendMap[nRoleID] = bDirty
end
function CFriendMgr:MarkStrangerDirty(nRoleID, bDirty) 
	bDirty = bDirty and true or nil
	self.m_tDirtyStrangerMap[nRoleID] = bDirty
end

--取好友列表
function CFriendMgr:GetFriendMap(nRoleID)
	if not self.m_tFriendMap[nRoleID] then
		if CUtil:IsRobot(nRoleID) then 
			return 
		end
		self.m_tFriendMap[nRoleID] = {}
		self:MarkFriendDirty(nRoleID, true)
	end
	return self.m_tFriendMap[nRoleID]
end

--陌生人列表
function CFriendMgr:GetStrangerMap(nRoleID)
	if not self.m_tStrangerMap[nRoleID] then
		self.m_tStrangerMap[nRoleID] = {}
		self:MarkStrangerDirty(nRoleID, true)
	end
	return self.m_tStrangerMap[nRoleID]
end

--取好友数量
function CFriendMgr:GetFriendCount(nRoleID)
	local nCount = 0
	local tFriendMap = self:GetFriendMap(nRoleID)
	for k, v in pairs(tFriendMap) do
		nCount = nCount + 1
	end
	return nCount
end

--取好友
function CFriendMgr:GetFriend(nRoleID, nTarRoleID)
	local tFriendMap = self:GetFriendMap(nRoleID)
	return tFriendMap[nTarRoleID]
end

--是否好友
function CFriendMgr:IsFriend(nRoleID, nTarRoleID)
	return self:GetFriend(nRoleID, nTarRoleID)
end

--获取好友列表id
function CFriendMgr:GetFriendList(nRoleID)
	local tFriendMap = self:GetFriendMap(nRoleID)
	local tRoleID = {}
	for nFriendRoleID,oFriend in pairs(tFriendMap) do
		table.insert(tRoleID,nFriendRoleID)
	end
	return tRoleID
end

--好友列表请求
function CFriendMgr:FriendListReq(oRole)
	local tList = {}

	local function _MakeInfo(oTmpRole, oFriend, bStranger)
		local tInfo = {
			nID=oTmpRole:GetID(),
			sName=oTmpRole:GetName(),
			sHeader=oTmpRole:GetHeader(),
			nLevel=oTmpRole:GetLevel(),
			nSchool=oTmpRole:GetSchool(),
			nGender=oTmpRole:GetGender(),
			tLastTalk=oFriend:GetLastTalk(),
			nAddTime=oFriend:GetAddTime(),
			nDegrees=oFriend:GetDegrees(),
			bOnline=oTmpRole:IsOnline(),
			bStranger=bStranger,
			nOfflineTalk=oFriend:GetOfflineTalk(),
		}
		return tInfo
	end

	local tFriendMap = self:GetFriendMap(oRole:GetID())
	for nRoleID, oFriend in pairs(tFriendMap) do
		local oTmpRole = goGPlayerMgr:GetRoleByID(nRoleID) 
		if oTmpRole then 
			table.insert(tList, _MakeInfo(oTmpRole, oFriend, false)) 
		end
	end

	local tStrangerMap = self:GetStrangerMap(oRole:GetID())
	for nStrangerRoleID, oStranger in pairs(tStrangerMap) do
		local oTmpRole = goGPlayerMgr:GetRoleByID(nStrangerRoleID)
		if oTmpRole then --防止机器人等异常
			table.insert(tList, _MakeInfo(oTmpRole, oStranger, true)) 
		end
	end
	oRole:SendMsg("FriendListRet", {tList=tList})
end

--申请好友请求
function CFriendMgr:FriendApplyReq(oRole, nTarRoleID, sMessage)
	local nLevelLimit = 30 
	if oRole:GetLevel() < nLevelLimit then 
		return oRole:Tips(string.format("%d级才可以加好友", nLevelLimit))
	end
	local function fnCallBack(nTotalMoney)
		if not nTotalMoney then
			return
		end
		if nTotalMoney <= 0 then
			return oRole:Tips("需要首充之后，才能发送好友申请")
		end
		local nRoleID = oRole:GetID()
		local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
		if not oTarRole then
			return
		end
		if oTarRole:GetGender() == 1 then
			sMessage = "小哥哥加个好友我们一起畅游仙灵吧"
		else
			sMessage = "小姐姐加个好友我们一起畅游仙灵吧"
		end

		if oTarRole:IsRobot() then 
			local nSrcID = oTarRole:GetSrcID()
			if CUtil:IsRobot(nSrcID) then 
				oRole:SendMsg("FriendApplySuccessRet", {nTarRoleID=nTarRoleID})
				return 
			end
			self:FriendApplyReq(oRole, nSrcID, sMessage)
			return
		end

		if self:IsFriend(nRoleID, nTarRoleID) then
			return oRole:Tips("你们已经是好友了哦")
		end

		if nRoleID == nTarRoleID then
			return oRole:Tips("不能添加自己为好友哦")
		end

		if self:GetFriendCount(nRoleID) >= nMaxFriends then
			return oRole:Tips("好友数量太多，已经放不下啦")
		end

		if self:GetFriendCount(nTarRoleID) >= nMaxFriends then
			return oRole:Tips("对方好友数量太多，已经放不下啦")
		end

		if CUtil:HasBadWord(sMessage) then
			return oRole:Tips("留言存在非法字符")
		end

		local tApply = self:GetFriendApply(nTarRoleID, nRoleID)
		if tApply then
			return oRole:Tips("您已经向对方申请了好友，请等待对方同意")
		end

		--移除超额的
		local tApplyList = {}
		for nTmpRoleID, tTmpApply in pairs(self.m_tApplyMap[nTarRoleID]) do
			table.insert(tApplyList, {nTmpRoleID, tTmpApply})
		end
		table.sort(tApplyList, function(t1, t2) return t1[2][1]>t2[2][1] end)
		while #tApplyList >= nMaxApplys do
			local tTmpApply = table.remove(tApplyList)
			self.m_tApplyMap[nTarRoleID][tTmpApply[1]] = nil
		end
		
		self.m_tApplyMap[nTarRoleID][nRoleID] = {os.time(), sMessage}
		self:MarkEtcDirty(true)

		local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
		self:FriendApplyListReq(oTarRole)

		oRole:SendMsg("FriendApplySuccessRet", {nTarRoleID=nTarRoleID})
		Network.oRemoteCall:Call("OnAddFriend", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {})
	end
    Network.oRemoteCall:CallWait("GetTotalMoneyReq", fnCallBack, oRole:GetStayServer(), oRole:GetLogic(), 0, oRole:GetID())
end

--申请是否过
function CFriendMgr:IsApplyExpired(tApply)
	if os.time()-tApply[1] >= 2*24*3600 then
		return true
	end
end

--取某个好友申请
function CFriendMgr:GetFriendApply(nRoleID, nTarRoleID)
	self.m_tApplyMap[nRoleID] = self.m_tApplyMap[nRoleID] or {}
	local tApply = self.m_tApplyMap[nRoleID][nTarRoleID]
	if tApply and self:IsApplyExpired(tApply) then
		self.m_tApplyMap[nRoleID][nTarRoleID] = nil
		self:MarkEtcDirty(true)
		return
	end
	return tApply
end

--好友申请列表请求
function CFriendMgr:FriendApplyListReq(oRole)
	local function _GetApplyInfo(oTmpRole, tApply)
		local tInfo = {}
		tInfo.nID = oTmpRole:GetID()
		tInfo.sName = oTmpRole:GetName()
		tInfo.sHeader = oTmpRole:GetHeader()
		tInfo.nLevel = oTmpRole:GetLevel()
		tInfo.nGender = oTmpRole:GetGender()
		tInfo.nSchool = oTmpRole:GetSchool()
		tInfo.nTime = tApply[1]
		tInfo.sMessage = tApply[2]
		return tInfo
	end
	local tList = {}	
	local nRoleID = oRole:GetID()
	self.m_tApplyMap[nRoleID] = self.m_tApplyMap[nRoleID] or {}
	for nTmpRoleID, tApply in pairs(self.m_tApplyMap[nRoleID]) do
		if self:IsApplyExpired(tApply) then
			self.m_tApplyMap[nRoleID][nTmpRoleID] = nil
			self:MarkEtcDirty(true)
		else
			local oTmpRole = goGPlayerMgr:GetRoleByID(nTmpRoleID)
			table.insert(tList, _GetApplyInfo(oTmpRole, tApply))
			if #tList >= nMaxApplys then
				break
			end
		end
	end
	oRole:SendMsg("FriendApplyListRet", {tList=tList})
end

--拒绝好友申请
function CFriendMgr:DenyFriendApplyReq(oRole, nTarRoleID)
	local nRoleID = oRole:GetID()
	self.m_tApplyMap[nRoleID] = self.m_tApplyMap[nRoleID] or {}
	self.m_tApplyMap[nRoleID][nTarRoleID] = nil
	self:MarkEtcDirty(true)
	self:FriendApplyListReq(oRole)
end

--同意好友申请请求
function CFriendMgr:AddFriendReq(oRole, nTarRoleID)
	local tApply = self:GetFriendApply(oRole:GetID(), nTarRoleID)
	if not tApply or self:IsApplyExpired(tApply) then
		return oRole:Tips("好友申请已过期")
	end
	local nRoleID = oRole:GetID()
	if nRoleID == nTarRoleID then
		return oRole:Tips("不能添加自己为好友哦")
	end
	if self:IsFriend(nRoleID, nTarRoleID) then
		return oRole:Tips("你们已经是好友了哦")
	end
	if self:GetFriendCount(nRoleID) >= nMaxFriends then
		return oRole:Tips("好友数量太多，已经放不下啦")
	end
	if self:GetFriendCount(nTarRoleID) >= nMaxFriends then
		return oRole:Tips("对方好友数量太多，已经放不下啦")
	end

	--添加好友
	local tFriendMap = self:GetFriendMap(nRoleID)
	local oFriend = CFriend:new(self, nRoleID, nTarRoleID)
	tFriendMap[nTarRoleID] = oFriend
	self:MarkFriendDirty(nRoleID, true)

	local tTarFriendMap = self:GetFriendMap(nTarRoleID)
	local oTarFriend = CFriend:new(self, nTarRoleID, nRoleID)
	tTarFriendMap[nRoleID] = oTarFriend
	self:MarkFriendDirty(nTarRoleID, true)

	--删除陌生人
	self:DelStranger(nRoleID, nTarRoleID)
	self:DelStranger(nTarRoleID, nRoleID)

	--同步好友列表
	self:FriendListReq(oRole)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	self:FriendListReq(oTarRole)
	oRole:Tips("添加好友成功")

	--互为好友
	local oFriend = self:GetFriend(nRoleID, nTarRoleID)
	local oTarFriend = self:GetFriend(nTarRoleID, nRoleID)
	assert(oFriend and oTarFriend, "好友关系错误")

	--好友度
	oFriend:AddDegrees(1, "互为好友")
	oTarFriend:AddDegrees(1, "互为好友")
	self:SyncDegrees(nRoleID, nTarRoleID)

	--聊天
	local tTalkMsg = self:MakeTalkMsg(nTarRoleID, "我们已是好友，开始聊天吧")
	local tTarTalkMsg = self:MakeTalkMsg(nRoleID, "我们已是好友，开始聊天吧")
	oFriend:AddTalk(tTalkMsg)
	oTarFriend:AddTalk(tTarTalkMsg)
	oRole:SendMsg("FriendTalkRet", {tTalk=tTalkMsg})
	oTarRole:SendMsg("FriendTalkRet", {tTalk=tTarTalkMsg})

	--清除好友申请
	tApply[1] = 0
	local tTarApply = self:GetFriendApply(nTarRoleID, oRole:GetID())
	if tTarApply then tTarApply[1] = 0 end
	self:MarkEtcDirty(true)

	self:FriendApplyListReq(oRole)
	self:SyncHouseFriendData(nRoleID,nTarRoleID)
	local nFriendNum = self:GetFriendCount(nRoleID)
	Network.oRemoteCall:Call("OnBecomeFriend", oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID(), {nFriendNum=nFriendNum})

	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
    if oTarRole then 
		local nTarRoleFriendNum = self:GetFriendCount(nTarRoleID)
		Network.oRemoteCall:Call("OnBecomeFriend", oTarRole:GetStayServer(), oTarRole:GetLogic(), oTarRole:GetSession(), oTarRole:GetID(), {nFriendNum=nTarRoleFriendNum})
    end
end

--删除好友请求
function CFriendMgr:DelFriendReq(oRole, nTarRoleID)
	local nRoleID = oRole:GetID()
	local bCouple = goMarriageMgr:IsCouple(nRoleID, nTarRoleID)
	if bCouple then
		oRole:Tips("不可解除和配偶的好友关系")
		return
	end

	local tFriendMap = self:GetFriendMap(nRoleID)
	local tTarFriendMap = self:GetFriendMap(nTarRoleID)

	local oFriend = tFriendMap[nTarRoleID]
	local oTarFriend = tTarFriendMap[nRoleID]

	if oFriend then
		tFriendMap[nTarRoleID] = nil
		oFriend:Release()
		self:MarkFriendDirty(nRoleID, true)
	end

	if oTarFriend then
		tTarFriendMap[nRoleID] = nil
		oTarFriend:Release()
		self:MarkFriendDirty(nTarRoleID, true)
	end

	oRole:Tips("删除好友成功")
	self:FriendListReq(oRole)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	self:FriendListReq(oTarRole)
end

--取推荐好友列表
function CFriendMgr:RecommandFriendList(oRole)
	local nRequireNum = 6
	local nMinMatchNum = 100
	local nMaxMatchNum = 100

	local nRoleID = oRole:GetID()
	local nLevel = oRole:GetLevel()

	local tExceptList = { nRoleID }
	--已是好友的不推荐
	local tFriendMap = self:GetFriendMap(nRoleID)
	for nFriendRoleID, oFriend in pairs(tFriendMap) do
		table.insert(tExceptList, nFriendRoleID)
	end

	--同等级段角色
	--可能某个等级区间内，存在大量玩家，比如初始的或者满级的，设定最大匹配数量100
	local tOnlineRoleList = goGPlayerMgr.m_oOnlineLevelMatchHelper:MatchTarget(tExceptList, nLevel-5, nLevel+5, nLevel, nMinMatchNum, nMaxMatchNum)
	local nMatchCount = #tOnlineRoleList
	if nMatchCount < nMinMatchNum then
		for _, nTmpRoleID in pairs(tOnlineRoleList) do
			table.insert(tExceptList, nTmpRoleID)
		end
		local tOfflineRoleList = goGPlayerMgr.m_oLevelMatchHelper:MatchTarget(tExceptList, nLevel-5, nLevel+5, nLevel, nMinMatchNum-nMatchCount, nMaxMatchNum-nMatchCount)
		nMatchCount = nMatchCount + #tOfflineRoleList
		for _, nTmpRoleID in pairs(tOfflineRoleList) do
			table.insert(tOnlineRoleList, nTmpRoleID)
		end
	end

	if nMatchCount <= 0 then --没有玩家
		return {}
	end

	local tRecommandMap = self.m_tRecommandRoleMap[nRoleID] or {}
	local function _fnSort(nRoleID1, nRoleID2)	
		local oTmpRole1 = goGPlayerMgr:GetRoleByID(nRoleID1)
		local oTmpRole2 = goGPlayerMgr:GetRoleByID(nRoleID2)
		local nRecommand1 = tRecommandMap[nRoleID1] or 0
		local nRecommand2 = tRecommandMap[nRoleID2] or 0
		if nRecommand1 ~= nRecommand2 then
			return nRecommand1 < nRecommand2
		end
		local nOnline1 = oTmpRole1:IsOnline() and 1 or 0
		local nOnline2 = oTmpRole2:IsOnline() and 1 or 0
		if nOnline1 ~= nOnline2 then
			return nOnline1 > nOnline2
		end
		local nDiff1 = nLevel - oTmpRole1:GetLevel()
		local nDiff2 = nLevel - oTmpRole2:GetLevel()
		if math.abs(nDiff1) == math.abs(nDiff2) then
			return nDiff1 < nDiff2
		end
		return math.abs(nDiff1) < math.abs(nDiff2)
	end
	table.sort(tOnlineRoleList, _fnSort)	

	local tTarRoleList = {}
	for _, nTmpRoleID in ipairs(tOnlineRoleList) do
		tRecommandMap[nTmpRoleID] = (tRecommandMap[nTmpRoleID] or 0) + 1
		local oTmpRole = goGPlayerMgr:GetRoleByID(nTmpRoleID)
		table.insert(tTarRoleList, oTmpRole)
		if #tTarRoleList >= nRequireNum then
			break
		end
	end
	self.m_tRecommandRoleMap[nRoleID] = tRecommandMap

	return tTarRoleList
end

--查找玩家请求
function CFriendMgr:SearchFriendReq(oRole, sTarNameOrID)
	local nRoleID = oRole:GetID()

	local function _fnGetRoleInfo(oTarRole)
		local tInfo = {}
		tInfo.nID = oTarRole:GetID()
		tInfo.sName = oTarRole:GetName()
		tInfo.sHeader = oTarRole:GetHeader()
		tInfo.nLevel = oTarRole:GetLevel()
		tInfo.nGender = oTarRole:GetGender()
		tInfo.nSchool = oTarRole:GetSchool()
		tInfo.bOnline = oTarRole:IsOnline()
		local tApply = self:GetFriendApply(oTarRole:GetID(), nRoleID)
		tInfo.bApplied = tApply and true or false
		return tInfo
	end

	local nLastSearchTime = self.m_tSearchTimeMap[nRoleID] or 0
	if os.time() - nLastSearchTime < 5 then
		local tLastList = self.m_tLastSearchResMap[nRoleID]
		if tLastList then
			oRole:SendMsg("SearchFriendRet", {tList=tLastList})
		end
		return oRole:Tips(string.format("操作太频繁啦，请%d秒后再试", nLastSearchTime+5-os.time()))
	end
	self.m_tSearchTimeMap[nRoleID] = os.time()

	local tList = {}
	if sTarNameOrID == "" then
		local tRoleList = self:RecommandFriendList(oRole)
		for _, oTmpRole in ipairs(tRoleList) do
			table.insert(tList, _fnGetRoleInfo(oTmpRole))
		end

	else
		local oTmpRole1 = goGPlayerMgr:GetRoleByID(tonumber(sTarNameOrID))
		local oTmpRole2 = goGPlayerMgr:GetRoleByName(sTarNameOrID)
		if oTmpRole1 and oTmpRole1:IsOnline() then
			table.insert(tList, _fnGetRoleInfo(oTmpRole1))
		end
		if oTmpRole2 and oTmpRole2:IsOnline() then
			table.insert(tList, _fnGetRoleInfo(oTmpRole2))
		end
		if #tList <= 0 then
			oRole:Tips("您搜索的玩家不存在或者不在线")
		end
		
	end
	self.m_tLastSearchResMap[nRoleID] = tList
	oRole:SendMsg("SearchFriendRet", {tList=tList})
end

-- --检测赠送道具重置
-- function CFriendMgr:CheckReset()
-- 	if not os.IsSameDay(os.time(), self.m_nResetTime, 0) then
-- 		self.m_tSentPropMap = {}
-- 		self.m_nResetTime = os.time()
-- 		self:MarkDirty(true)
-- 	end
-- end

-- --取已赠送的道具数量
-- function CFriendMgr:GetSentProps(nRoleID)
-- 	self:CheckReset()
-- 	return (self.m_tSentPropMap[nRoleID] or 0)
-- end

-- --赠送道具
-- function CFriendMgr:SendPropReq(oRole, nTarRoleID, nGridID, nSendNum)
-- 	assert(nPropNum > 0, "参数错误")

-- 	local nRoleID = oRole:GetID()
-- 	if nRoleID == nTarRoleID then
-- 		return
-- 	end

-- 	local oFriend = self:GetFriend(nRoleID, nTarRoleID)
-- 	local oTarFriend = self:GetFriend(nTarRoleID, nRoleID)
-- 	if not oFriend or not oTarFriend then
-- 		return oRole:Tips("互为好友才能赠送物品")
-- 	end

-- 	local tPropConf = ctPropConf[nPropID]
-- 	if not tPropConf.bGiftable then
-- 		return oRole:Tips(string.format("%s不能赠送", tPropConf.sName))
-- 	end

-- 	if self:GetSentProps(nRoleID) >= nMaxSendProps then
-- 		return oRole:Tips(string.format("每天只能赠送%d个物品哦", nMaxSendProps))
-- 	end

-- 	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
-- 	if not oTarRole:IsOnline() then
-- 		return oRole:Tips("好友不在线，不能赠送物品")
-- 	end

-- 	oRole:GetPropData(nGridID, function(tPropData)
-- 		if not tPropData or tPropData.m_nFold<nSendNum then
-- 			return oRole:Tips("物品数量不足")
-- 		end
-- 		if tPropData.m_bBind then
-- 			return oRole:Tips("绑定物品不能赠送")
-- 		end

-- 		local tItemList = {{nType=gtItemType.eProp, nID=tPropData.m_nID, nNum=nSendNum}}
-- 		oRole:SubItem(tItemList, "赠送物品扣除", function(bRes)
-- 			if not bRes then
-- 				return oRole:Tips("物品数量不足??")
-- 			end

-- 			tPropData.m_nFold = nSendNum
-- 			oTarRole:TransferItem(gtItemType.eProp, tPropData, "好友赠送物品", function(bRes)
-- 				if not bRes then
-- 					return oRole:Tips("赠送物品失败")
-- 				end
-- 				oFriend:OnSendProp(tPropData.m_nID, nSendNum)
-- 				oTarFriend:OnSendProp(tPropData.m_nID, nSendNum)
-- 				self:SyncDegrees(nRoleID, nTarRoleID)
-- 				self.m_tSentPropMap[nRoleID] = (self.m_tSentPropMap[nRoleID] or 0) + nSendNum
-- 				self:MarkDirty(true)
-- 				oRole:Tips("赠送物品成功")
-- 			end)
-- 		end)
-- 	end)
-- end

--同步友好度
function CFriendMgr:SyncDegrees(nRoleID, nTarRoleID)
	local oFriend = self:GetFriend(nRoleID, nTarRoleID)
	local oTarFriend = self:GetFriend(nTarRoleID, nRoleID)
	if not oFriend or not oTarFriend then
		return
	end
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	oRole:SendMsg("FriendDegreesRet", {nRoleID=nTarRoleID, nDegrees=oTarFriend:GetDegrees()})
	oTarRole:SendMsg("FriendDegreesRet", {nRoleID=nRoleID, nDegrees=oFriend:GetDegrees()})
end

--战斗结束
function CFriendMgr:OnBattleEnd(nRoleID, tBTRes)
	if CUtil:IsRobot(nRoleID) then 
		return
	end
	--同一场战斗可能多次调用，所以要过滤下
	if self.m_tBattleMap[tBTRes.nBattleID] then
		return
	end
	self.m_tBattleMap[tBTRes.nBattleID] = true

	--失败，竞技场，逃跑不算
	if not tBTRes.bWin or tBTRes.nBattleType == gtBTT.eArena or tBTRes.nEndType == gtBTRes.eEscape then
		return
	end

	for _, nTeamRoleID in ipairs(tBTRes.tTeamRoleList) do
		if not CUtil:IsRobot(nTeamRoleID) then 
			local oFriend = self:GetFriend(nRoleID, nTeamRoleID)
			local oTarFriend = self:GetFriend(nTeamRoleID, nRoleID)
			if oFriend and oTarFriend then
				oFriend:OnBattleEnd()
				oTarFriend:OnBattleEnd()
			end
		end
	end
end

function CFriendMgr:MakeTalkMsg(nRoleID, sCont)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)				
	local function _GetTalkIdent(oRole)
		local tInfo = {}
		tInfo.nID = oRole:GetID()
		tInfo.sName = oRole:GetName()
		tInfo.sHeader = oRole:GetHeader()
		tInfo.nLevel = oRole:GetLevel()
		tInfo.nGender = oRole:GetGender()
		tInfo.nSchool = oRole:GetSchool()
		return tInfo
	end
	local tTalkMsg = {
		tHead = _GetTalkIdent(oRole),
		sCont = sCont,
		nTime = os.time(), 
	}
	return tTalkMsg
end

function CFriendMgr:BroadcastFriendTalk(oRole, bOnlyOnline, sCont, tFilter)
	if not oRole then
		return
	end
	if string.len(sCont) <= 0 then 
		return
	end
	sCont = CUtil:FilterBadWord(sCont)

	local nRoleID = oRole:GetID()
	local tFriendList = self:GetFriendMap(nRoleID)	
	local tTalkMsg = self:MakeTalkMsg(nRoleID, sCont)
	local tSessionList = {}
	for nTarRoleID, oFriend in pairs(tFriendList) do
		local bFilter = false
		if not tFilter or not tFilter[nTarRoleID] then
			local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)				
			local bTarOnline = oTarRole:IsOnline()
			if bTarOnline or not bOnlyOnline then
				local tTalkTemp = self:MakeTalkMsg(nRoleID, sCont)
				--oRole:SendMsg("FriendTalkRet", {tTalk=tTalkTemp})
				if bTarOnline then
					table.insert(tSessionList, oTarRole:GetServer())
					table.insert(tSessionList, oTarRole:GetSession())
				end

				oFriend:AddTalk(tTalkTemp)
				local oTarFriend = self:GetFriend(nTarRoleID, nRoleID)
				if oTarFriend then
					oTarFriend:AddTalk(tTalkTemp)
				end
			end
		end
	end
	if #tSessionList > 0 then
		Network.PBBroadcastExter("FriendTalkRet", tSessionList, {tTalk = tTalkMsg})
	end
end

function CFriendMgr:TalkFriend(oRole, nTarRoleID, sCont, bXMLMsg)
	if string.len(sCont) <= 0 then 
		return
	end
	if not bXMLMsg then 
		sCont = CUtil:FilterBadWord(sCont)
	end

	local nRoleID = oRole:GetID()
	local oTarRole = goGPlayerMgr:GetRoleByID(nTarRoleID)
	if not oTarRole then 
		return 
	end		
	-- if not oTarRole:IsOnline() then
	-- 	return oRole:Tips("对方不在线")
	-- end

	--是否被屏蔽了
	local bShielded = goTalk:IsShield(oTarRole, nRoleID)

	--发给自己
	local tTalkMsg = self:MakeTalkMsg(nRoleID, sCont)
	oRole:SendMsg("FriendTalkRet", {tTalk=tTalkMsg})

	if oTarRole:IsRobot() then --如果是机器人，直接退出
		return 
	end 

	--被屏蔽了不发给对方
	if not bShielded then
		oTarRole:SendMsg("FriendTalkRet", {tTalk=tTalkMsg})
	end

	--好友
	local oFriend = self:GetFriend(nRoleID, nTarRoleID)
	if oFriend then
		local oTarFriend = self:GetFriend(nTarRoleID, nRoleID)
		if not oTarFriend then
			self:DelFriendReq(oRole, nTarRoleID)
			LuaTrace("好友数据错误", nRoleID, nTarRoleID)

		else
			oFriend:AddTalk(tTalkMsg)
			if not bShielded then
				oTarFriend:AddTalk(tTalkMsg, not oTarRole:IsOnline())
			end
			
		end

	--陌生人
	else
		local oStranger = self:GetStranger(nRoleID, nTarRoleID)
		local oTarStranger = self:GetStranger(nTarRoleID, nRoleID)
		if not oStranger then
			oStranger = self:AddStranger(nRoleID, nTarRoleID)
			oTarStranger = self:AddStranger(nTarRoleID, nRoleID)
		end
		oStranger:AddTalk(tTalkMsg)
		if not bShielded then
			oTarStranger:AddTalk(tTalkMsg)
		end

	end
end

function CFriendMgr:TalkReq(oRole, nTarRoleID, sCont, bXMLMsg, bSys)
    if bSys then 
        self:TalkFriend(oRole, nTarRoleID, sCont, bXMLMsg)
        return
    end
    local fnQueryCallback = function(nTotalRechargeRMB)
        if not nTotalRechargeRMB then
            return 
        end
        if oRole:GetLevel() < 40 and nTotalRechargeRMB < 50 then 
            return oRole:Tips("好友私聊发言需达到40级且充值50元以上")
        end
        if oRole:GetLevel() < 40 then
            return oRole:Tips("好友私聊发言需要等级达到40级")
        end
        if nTotalRechargeRMB < 50 then 
            return oRole:Tips("好友私聊发言需要累计充值达到50元")
        end

        self:TalkFriend(oRole, nTarRoleID, sCont, bXMLMsg)
    end
    Network.oRemoteCall:CallWait("QueryRoleTotalRechargeReq", fnQueryCallback, 
        oRole:GetStayServer(), oRole:GetLogic(), 0, oRole:GetID())
end

function CFriendMgr:Online(oRole)
	self:FriendListReq(oRole)
	self:FriendApplyListReq(oRole)
	self.m_tRecommandRoleMap[oRole:GetID()] = {} --清空推荐记录
end

--取陌生人
function CFriendMgr:GetStranger(nRoleID, nTarRoleID)
	local tStrangerMap = self:GetStrangerMap(nRoleID)
	return tStrangerMap[nTarRoleID]
end

--添加陌生人
function CFriendMgr:AddStranger(nRoleID, nTarRoleID)
	local tStrangerMap = self:GetStrangerMap(nRoleID)
	tStrangerMap[nTarRoleID] = CFriend:new(self, nRoleID, nTarRoleID, true)
	self:MarkStrangerDirty(nRoleID, true)

	--检测删除超额的陌生人
	local tStrangerList = {}
	for nTmpRoleID, oFriend in pairs(tStrangerMap) do
		table.insert(tStrangerList, oFriend)
	end
	if #tStrangerList > nMaxStrangers then
		table.sort(tStrangerList, function(oFriend1, oFriend2) return oFriend1:GetAddTime()<oFriend2:GetAddTime() end)
		local oDelFriend = tStrangerList[1]
		self:DelStranger(nRoleID, oDelFriend:GetID())
		self:DelStranger(oDelFriend:GetID(), nRoleID)
	end
	return tStrangerMap[nTarRoleID]
end

--删除陌生人
function CFriendMgr:DelStranger(nRoleID, nTarRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local tStrangerMap = self:GetStrangerMap(nRoleID)
	if not tStrangerMap then
		return
	end

	if not nTarRoleID then --清空
		self.m_tStrangerMap[nRoleID] = nil
	else --删除特定
		tStrangerMap[nTarRoleID] = nil
	end
	self:MarkStrangerDirty(nRoleID, true)
	-- oRole:Tips("删除成功")
end

--好友历史聊天记录请求
function CFriendMgr:FriendHistoryTalkReq(oRole, nTarRoleID)
	local oFriend = self:GetFriend(oRole:GetID(), nTarRoleID)
	local oStranger = self:GetStranger(oRole:GetID(), nTarRoleID)
	if not (oFriend or oStranger) then
		oRole:SendMsg("FriendHistoryTalkRet", {nTarRoleID=nTarRoleID, tTalkList={}})
		return
	end
	local tList
	if oFriend then
		oFriend:ClearOfflineTalk()
		tList = oFriend:GetTalkList()
	else
		tList = oStranger:GetTalkList()
	end
	oRole:SendMsg("FriendHistoryTalkRet", {nTarRoleID=nTarRoleID, tTalkList=tList})
end

--取玩家总好友度
function CFriendMgr:GetTotalDegrees(oRole)
	local nTotalDegrees = 0
	local tFriendMap = self:GetFriendMap(oRole:GetID())
	for _, oFriend in pairs(tFriendMap) do
		nTotalDegrees = nTotalDegrees + oFriend:GetDegrees()
	end
	return nTotalDegrees
end

--玩家亲密度发生变化
function CFriendMgr:OnDegreesChange(nRoleID)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	local nTotalDegrees = self:GetTotalDegrees(oRole)
	Network.oRemoteCall:Call("FriendDegreeChangeReq", oRole:GetServer(), goServerMgr:GetGlobalService(oRole:GetServer(), 20), 0, nRoleID, nTotalDegrees)
end

--GM增加亲密度
function CFriendMgr:GMAddDegrees(oRole, nTarRoleID, nDegrees)
	local oFriend = self:GetFriend(oRole:GetID(), nTarRoleID)
	local oTarFriend = self:GetFriend(nTarRoleID, oRole:GetID())
	if not oFriend or not oTarFriend then
		return oRole:Tips("互为好友才能增加友好度")
	end
	oFriend:AddDegrees(nDegrees, "GM增加友好度")
	oTarFriend:AddDegrees(nDegrees, "GM增加友好度")
	oRole:Tips("添加友好度成功")
end

function CFriendMgr:SyncHouseFriendData(nRoleID,nTarRoleID)
	local nServiceID = goServerMgr:GetGlobalService(gnWorldServerID,111)
	Network.oRemoteCall:Call("FriendChange",gnWorldServerID,nServiceID,0,nRoleID,nTarRoleID)
end
