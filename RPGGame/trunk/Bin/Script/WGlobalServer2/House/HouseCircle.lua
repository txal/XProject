--家园动态
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CHouseCircle:Ctor(nID)
	self.m_nID = nID
	self.m_tDynamic = {}
	self.m_nDynamicID = 0
	self.m_tClientDynamic = {}			--他人访问客户端显示，按id从大到小排序
	self.m_tFriendDynamic ={}			--好友动态数据{[pid]={[nDynamic]=tData}}
	self.m_tSortFriendDynamic = {}		--排序动态{{nTime,nRoleID,nDynamic}}
end

function CHouseCircle:GetHouse()
	local oHouse = goHouseMgr:GetHouse(self.m_nID)
	return oHouse
end

function CHouseCircle:Online()
	self:InitFriendDynamic()
end

function CHouseCircle:SaveData()
	local tData = {}
	local tDynamic = {}
	for nID,oDynamic in pairs(self.m_tDynamic) do
		tDynamic[nID] = oDynamic:SaveData()
	end
	tData.m_tDynamic = tDynamic
	tData.m_nDynamicID = self.m_nDynamicID
	return tData
end

function CHouseCircle:LoadData(tData)
	tData = tData or {}
	self.m_nDynamicID = tData.m_nDynamicID or self.m_nDynamicID
	local tDynamic = tData.m_tDynamic or {}
	for nID,tDynamicData in pairs(tDynamic) do
		local oDynamic = CHouseDynamic:new(self.m_nID,nID)
		oDynamic:LoadData(tDynamicData)
		self.m_tDynamic[nID] = oDynamic
	end
	local tKeys = table.Keys(tDynamic)
	local fSort = function (a,b)
		if a > b then
			return true
		end
		return false
	end
	table.sort(tKeys,fSort)
	self.m_tClientDynamic = tKeys	
end

function CHouseCircle:PackSimpleDynamic()
	local tMsg = {}
	if #self.m_tClientDynamic > 0 then
		local nDynamicID = self.m_tClientDynamic[1]
		local oDynamic = self:GetDynamic(nDynamicID)
		if oDynamic then
			tMsg = oDynamic:PackSimpleData()
		end
	else
		tMsg.nDynamicID = 0
		tMsg.sMsg = ""
		tMsg.nVoteUp = 0
		tMsg.nCommentCnt = 0
	end
	return tMsg
end

function CHouseCircle:GetRole()
	local oRole = goGPlayerMgr:GetRoleByID(self.m_nID)
	return oRole
end

function CHouseCircle:MarkDirty(bDirty) goHouseMgr:MarkHouseDirty(self.m_nID, bDirty) end
function CHouseCircle:IsDirty() return goHouseMgr:IsHouseDirty(self.m_nID) end


function CHouseCircle:GenerateDynamicID()
	self.m_nDynamicID = self.m_nDynamicID + 1
	if self.m_nDynamicID >= 1000000000 then
		self.m_nDynamicID = 1
	end
	return self.m_nDynamicID
end

function CHouseCircle:AddDynamic(oRole,sContent,tPictureKey)
	local nDynamicID = self:GenerateDynamicID()
	local oDynamic = CHouseDynamic:new(self.m_nID,nDynamicID)
	oDynamic:Init(sContent,tPictureKey)
	self:MarkDirty(true)
	self.m_tDynamic[nDynamicID] = oDynamic
	oDynamic:Refresh(oRole,true)
	table.insert(self.m_tClientDynamic,1,nDynamicID)
	return oDynamic
end

function CHouseCircle:GetDynamic(nID)
	local oDynamic = self.m_tDynamic[nID]
	return oDynamic
end

function CHouseCircle:DeleteDynamic(oRole,nID)
	local oDynamic = self:GetDynamic(nID)
	if not oDynamic then
		return
	end
	self:MarkDirty(true)
	self.m_tDynamic[nID] = nil
	oRole:SendMsg("GS2CHouseDeleteDynamicRet",{nDynamicID = nDynamicID})
	for nPos,nID in ipairs(self.m_tClientDynamic) do
		if nID == nDynamicID then
			table.remove(nPos)
		end
	end
end


function CHouseCircle:AddComment(nRoleID,nDynamicID,nTargetCommentID,sContent)
	local oDynamic = self:GetDynamic(nDynamicID)
	if not oDynamic then
		return
	end
	self:MarkDirty(true)
	oDynamic:AddComment(nTargetCommentID,nRoleID,sContent)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if oRole then
		oDynamic:Refresh(oRole,false)
	end
end

function CHouseCircle:DeleteComment(oRole,nDynamicID,nCommentID)
	local nRoleID = oRole:GetID()
	local oDynamic = self:GetDynamic(nDynamicID)
	if not oDynamic then
		return
	end
	if not oDynamic:CanDeleteComment(nRoleID,nCommentID) then
		oRole:Tips("只能删除自己发表的评论")
		return
	end
	self:MarkDirty(true)
	oDynamic:DeleteComment(nCommentID)
	--oDynamic:Refresh(oRole,false)
	local tMsg = {}
	tMsg.nRoleID = self.m_nID
	tMsg.nDynamicID = nDynamicID
	tMsg.nCommentID = nCommentID
	oRole:SendMsg("GS2CHouseDynamicDeleteCommentRet",tMsg)
end

--非房主发家园主人动态，主人则发好友动态
function CHouseCircle:DymaicDataReq(oRole,nPage)
	local nRoleID = oRole:GetID()
	if oRole:GetID() == self.m_nID then
		self:FriendDynamicDataReq(oRole,nPage)
	else
		local nPageAmount = 5
		local nStartPos = (nPage-1) * nPageAmount
		local nEndPos = nPage * nPageAmount
		local tData = {}
		for nPos,nDynamicID in ipairs(self.m_tClientDynamic) do
			if nPos > nStartPos and nPos <= nEndPos then
				local oDynamic = self:GetDynamic(nDynamicID)
				if oDynamic then
					table.insert(tData,oDynamic:PackData(oRole))
				end
			end
		end
		oRole:SendMsg("GS2CHouseDyanmicDataRet",{tDynamic = tData})
	end
end

function CHouseCircle:FriendDynamicDataReq(oRole,nPage)
	local nPageAmount = 5
	local nStartPos = (nPage-1) * nPageAmount
	local nEndPos = nPage * nPageAmount
	local tData = {}
	for nPos,tSortData in ipairs(self.m_tSortFriendDynamic) do
		if nPos > nStartPos and nPos <= nEndPos then
			local nTime,nFriendID,nDynamicID = table.unpack(tSortData)
			local oDynamic = self:GetFriendDynamic(nFriendID,nDynamicID)
			if oDynamic then
				table.insert(tData,oDynamic:PackData(oRole))
			end
		end
	end
	oRole:SendMsg("GS2CHouseDyanmicDataRet",{tDynamic = tData})
end

--取20条
function CHouseCircle:GetNewDynamic()
	local nCnt = 0
	local tData = {}
	for _,nDynamicID in pairs(self.m_tClientDynamic) do
		nCnt = nCnt + 1
		local oDynamic = self:GetDynamic(nDynamicID)
		if oDynamic then
			tData[nDynamicID] = oDynamic:SaveData()
		end
		if nCnt >= 20 then
			break
		end
	end
	return tData
end

function CHouseCircle:GetDynamicData()
	local tData = {}
	for _,nDynamicID in pairs(self.m_tClientDynamic) do
		local oDynamic = self:GetDynamic(nDynamicID)
		if oDynamic then
			tData[nDynamicID] = oDynamic:SaveData()
		end
	end
	return tData
end

function CHouseCircle:InitFriendDynamic()
	local nRoleID = self.m_nID
	local fnCallback = function (tFriendList)
		self:_InitFriendDynamic(nRoleID,tFriendList)
	end
	goRemoteCall:CallWait("GetFriendList",fnCallback,gnWorldServerID,goServerMgr:GetGlobalService(gnWorldServerID, 110),0,self.m_nID)
end

function CHouseCircle:_InitFriendDynamic(nRoleID,tFriendList)
	tFriendList = tFriendList or {}
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then return end
	local tFriendDynamic = {}
	for _,nFriendID in ipairs(tFriendList) do
		local oFriendHouse = goHouseMgr:GetHouse(nFriendID)
		if oFriendHouse then
			local tDynamic = oFriendHouse:GetCircleDynamic()
			tFriendDynamic[nFriendID] = tDynamic
		end
	end
	tFriendDynamic[nRoleID] = self:GetDynamicData()
	self:ReSortFriendDynamic(tFriendDynamic)
end

function CHouseCircle:ReSortFriendDynamic(tFriendDynamic)
	tFriendDynamic = tFriendDynamic or {}
	local tSortDynamic = {}
	for nFriendID,tDynamic in pairs(tFriendDynamic) do
		for nDynamicID,tDynamicData in pairs(tDynamic) do
			table.insert(tSortDynamic,{tDynamicData.nTime,nFriendID,nDynamicID})
		end
	end
	local fSort = function (tData1,tData2)
		if tData1[1] ~= tData2[1] then
			return tData1[1] > tData2[1]
		else
			return tData1[2] > tData2[2]
		end
	end
	table.sort(tSortDynamic,fSort)
	self.m_tSortFriendDynamic = tSortDynamic
end

function CHouseCircle:GetFriendDynamic(nFriendID,nDynamicID)
	local oFriendRole = goGPlayerMgr:GetRoleByID(nFriendID)
	if not oFriendRole then return end
	local oHouse = goHouseMgr:GetHouse(nFriendID)
	if not oHouse then return end
	return oHouse:GetDynamic(nDynamicID)
end

function CHouseCircle:UpdateFriendDynamic(nFriendID,nDynamicID,tDynamic)
	local tFriendData = self.m_tFriendDynamic[nFriendID] or {}
	if tFriendData[nDynamicID] then
		tFriendData[nDynamicID] = tDynamic
	else
		tFriendData[nDynamicID] = tDynamic
		table.insert(self.m_tSortFriendDynamic,1,{tDynamic.nTime,nFriendID,nDynamicID})
	end
end

function CHouseCircle:FriendChange(nTargetRole)
	local oFriendHouse = goHouseMgr:GetHouse(nTargetRole)
	local tDynamic = oFriendHouse:GetCircleDynamic()
	self:InitFriendDynamic()
end

function CHouseCircle:DynamicPublicCommentReq(oRole,nDynamicID,nTargetCommentID,sMsg)
	local nRoleID = oRole:GetID()
	self:AddComment(nRoleID,nDynamicID,nTargetCommentID,sMsg)
	local oDynamic = self:GetDynamic(nDynamicID)
	return oDynamic
end

function CHouseCircle:DynamicUpVoteReq(oRole,nDynamicID)
	local oDynamic = self:GetDynamic(nDynamicID)
	if not oDynamic then
		return
	end
	if oDynamic:IsUpVote(oRole) then
		return
	end
	self:MarkDirty(true)
	oDynamic:UpVote(oRole)
	local tMsg = {
		nRoleID = self.m_nID,
		nDynamicID = nDynamicID,
		nVoteUp = oDynamic:UpVoteCount()
	}
	oRole:SendMsg("GS2CHouseDynamicUpVoteRet",tMsg)
end

---------------------------------------------------动态------------------------------------
function CHouseDynamic:Ctor(nRoleID,nDynamicID)
	self.m_nRoleID = nRoleID
	self.m_nID = nDynamicID
	self.m_sContent = ""
	self.m_tPictureKey = {}
	self.m_nCreateTime = 0
	self.m_tCommnet = {}
	self.m_tUpVote = {}
	self.m_nCommentID = 0
end

function CHouseDynamic:Init(sContent,tPictureKey)
	self.m_sContent = sContent
	self.m_tPictureKey = tPictureKey
	self.m_nCreateTime = os.time()
end

function CHouseDynamic:SaveData()
	local tData = {}
	tData.m_nRoleID = self.m_nRoleID
	tData.m_sContent = self.m_sContent
	tData.m_tPictureKey = self.m_tPictureKey
	tData.m_nCreateTime = self.m_nCreateTime
	tData.m_tUpVote = self.m_tUpVote
	tData.m_nCommentID = self.m_nCommentID
	tData.m_tCommnet = self.m_tCommnet
	return tData
end

function CHouseDynamic:LoadData(tData)
	tData = tData or {}
	self.m_sContent = tData.m_sContent or self.m_sContent
	self.m_tPictureKey = tData.m_tPictureKey or self.m_tPictureKey
	self.m_nCreateTime = tData.m_nCreateTime or self.m_nCreateTime
	self.m_tUpVote = tData.m_tUpVote or self.m_tUpVote
	self.m_nCommentID = tData.m_nCommentID or self.m_nCommentID
	self.m_tCommnet = tData.m_tCommnet or self.m_tCommnet
end

function CHouseDynamic:GetHouse()
	local oHouse = goHouseMgr:GetHouse(self.m_nRoleID)
	return oHouse
end

function CHouseDynamic:PackCommentData()
	local tData = {}
	for nCommentID,tCommentData in pairs(self.m_tCommnet) do
		table.insert(tData,{
			nRoleID = tCommentData.nRoleID,
			nID = nCommentID,
			nTargetID = tCommentData.nTargetCommentID,
			sMsg = tCommentData.sContent,
			sName = tCommentData.sName
		})
	end
	return tData
end

function CHouseDynamic:PackData(oRole)
	local tData = {}
	local oHouse = self:GetHouse()
	tData.nRoleID = self.m_nRoleID
	tData.nDynamicID = self.m_nID
	tData.sModel = oHouse:GetHeader()
	tData.sName = oHouse:GetName()
	tData.nGender = oHouse:GetGender()
	tData.nSchool = oHouse:GetSchool()
	tData.nFriend = 1
	tData.nTime = self.m_nCreateTime
	tData.sMsg = self.m_sContent
	tData.tPictureKey = self.m_tPictureKey
	tData.nVoteUp = table.Count(self.m_tUpVote)
	tData.tComment = self:PackCommentData()
	tData.nIsVoteUp = 0
	if self:IsUpVote(oRole) then
		tData.nIsVoteUp = 1
	end
	return tData
end

function CHouseDynamic:PackSimpleData()
	local tMsg = {}
	tMsg.nDynamicID = self.m_nID
	tMsg.sMsg = self.m_sContent
	tMsg.nVoteUp = table.Count(self.m_tUpVote)
	tMsg.nCommentCnt = table.Count(self.m_tCommnet)
	return tMsg
end

function CHouseDynamic:IsUpVote(oRole)
	if self.m_tUpVote[oRole:GetID()] then
		return true
	end
	return false
end

function CHouseDynamic:UpVote(oRole)
	self.m_tUpVote[oRole:GetID()] = 1
end

function CHouseDynamic:UpVoteCount()
	return table.Count(self.m_tUpVote)
end

function CHouseDynamic:Refresh(oRole,bAdd)
	local tData = self:PackData(oRole)
	bAdd = bAdd or false
	oRole:SendMsg("GS2CHouseDynamicRefreshRet",{tDynamic = tData,bAdd = bAdd})

	--通知在线好友更新动态
	local nRoleID = self.m_nRoleID
	goHouseMgr:DynamicRefresh(nRoleID,self.m_nID,tData)
end

--增加评论
function CHouseDynamic:AddComment(nTargetCommentID,nRoleID,sContent)
	local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
	if not oRole then
		return
	end
	local tData = {
		nRoleID = nRoleID,
		sContent = sContent,
		sName = oRole:GetName(),
		nTargetCommentID = nTargetCommentID
	}
	local nCommentID = self:GenerateCommentID()
	self.m_tCommnet[nCommentID] = tData
end

function CHouseDynamic:GenerateCommentID()
	self.m_nCommentID = self.m_nCommentID + 1
	if self.m_nCommentID >= 1000000000 then
		self.m_nCommentID = 1
	end
	return self.m_nCommentID
end

function CHouseDynamic:HasComment(nSeq)
	if self.m_tCommnet[nSeq] then
		return true
	end
	return false
end

function CHouseDynamic:CanDeleteComment(nRoleID,nSeq)
	local tComment = self.m_tCommnet[nSeq]
	if not tComment then
		return false
	end
	local nCommentRoleID = tComment["nRoleID"]
	if nCommentRoleID ~= nRoleID then
		return false
	end
	return true
end

function CHouseDynamic:DeleteComment(nSeq)
	self.m_tCommnet[nSeq] = nil
end