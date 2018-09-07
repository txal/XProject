--联盟管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxUnionID = 9999
local nServerID = gnServerID
local nAutoSaveTime = 3*60

function CUnionMgr:Ctor()
	self.m_nAutoInc = 0
	--{[nUnionID]=oUnion}
	self.m_tUnionMap = {}
	--{[sUnionName]=nUnionID}
	self.m_tUnionNameMap = {}
	--{[nCharID]=oUnionPlayer}
	self.m_tUnionPlayerMap = {}

	self.m_tUnionIDList = {} --用来随机
	self.m_tDirtyUnionMap = {}
	self.m_tDirtyUnionPlayerMap = {}
	self.m_bUnionNameDirty = false
end

function CUnionMgr:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CUnionMgr:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil
	
	self:SaveData()
end

--加载联盟数据
function CUnionMgr:LoadData()
	--联盟名字列表
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sUnionNameDB, "UniqueName")
	if sData ~= "" then
		self.m_tUnionNameMap = cjson.decode(sData)
	end

	--自动增长ID
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sUnionNameDB, "AutoInc")
	if sData ~= "" then
		self.m_nAutoInc = tonumber(sData)
	end

	--联盟玩家数据
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sUnionPlayerDB)
	for _, sKey in ipairs(tKeys) do
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sUnionPlayerDB, sKey)
		local tData = cjson.decode(sData)
		local oUnionPlayer = CUnionPlayer:new()
		oUnionPlayer:LoadData(tData)
		self.m_tUnionPlayerMap[oUnionPlayer:Get("m_nCharID")] = oUnionPlayer
	end

	--联盟数据
	local tKeys = goDBMgr:GetSSDB("Player"):HKeys(gtDBDef.sUnionDB)
	for _, sKey in ipairs(tKeys) do
		local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sUnionDB, sKey)
		local tData = cjson.decode(sData)
		if type(tData) == "table" then
			local oUnion = CUnion:new()
			if oUnion:LoadData(tData) then
				self.m_tUnionMap[oUnion:Get("m_nID")] = oUnion
			end
		end
	end

	--检测玩家数据
	for nCharID, oUnionPlayer in pairs(self.m_tUnionPlayerMap) do
		local nUnionID = oUnionPlayer:Get("m_nUnionID")
		if nUnionID > 0 then
			if not self:GetUnion(nUnionID) then
				oUnionPlayer:Set("m_nUnionID", 0)
				oUnionPlayer:MarkDirty(true)
				LuaTrace("成员联盟ID错误:", oUnionPlayer:GetName(), nUnionID)
			end
		end
	end
	
	--检测联盟名字
	for sName, nUnionID in pairs(self.m_tUnionNameMap) do
		local oUnion = self:GetUnion(nUnionID)
		if not oUnion then
			self.m_tUnionNameMap[sName] = nil
			self:MarkNameDirty(true)
			LuaTrace("联盟名字:", sName, "已不再使用")
		else
			table.insert(self.m_tUnionIDList, nUnionID)
		end
	end

	--定时保存
	self:AutoSave()
end

--保存联盟数据
function CUnionMgr:SaveData()
	print("CUnionMgr:SaveData***")
	--保存联盟
	for nUnionID, v in pairs(self.m_tDirtyUnionMap) do
		local oUnion = self.m_tUnionMap[nUnionID]
		if oUnion then
			local tData = oUnion:SaveData()
			goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sUnionDB, nUnionID, cjson.encode(tData))
		end
	end
	self.m_tDirtyUnionMap = {}

	--保存玩家
	for nCharID , v in pairs(self.m_tDirtyUnionPlayerMap) do
		local oUnionPlayer = self.m_tUnionPlayerMap[nCharID]
		local tData = oUnionPlayer:SaveData()
		goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sUnionPlayerDB, nCharID, cjson.encode(tData))
	end
	self.m_tDirtyUnionPlayerMap = {}

	--联盟名字
	if self.m_bUnionNameDirty then
		local sData = cjson.encode(self.m_tUnionNameMap)
		goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sUnionNameDB, "UniqueName", sData)
		self:MarkNameDirty(false)
	end

	--自动增长ID
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sUnionNameDB, "AutoInc", self.m_nAutoInc)
end

--名字脏
function CUnionMgr:MarkNameDirty(bDirty)
	self.m_bUnionNameDirty = bDirty
end

--联盟脏
function CUnionMgr:MarkUnionDirty(nUnionID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyUnionMap[nUnionID] = bDirty
end

--玩家脏
function CUnionMgr:MarkPlayerDirty(nCharID, bDirty)
	bDirty = bDirty or nil
	self.m_tDirtyUnionPlayerMap[nCharID] = bDirty
end

--生成联盟ID
function CUnionMgr:MakeUnionID()
	self.m_nAutoInc = self.m_nAutoInc % nMaxUnionID + 1
	local nUnionID = nServerID*10000 + self.m_nAutoInc
	return nUnionID
end

--取联盟
function CUnionMgr:GetUnion(nUnionID)
	return self.m_tUnionMap[nUnionID]
end

--通过玩家ID取公会
function CUnionMgr:GetUnionByCharID(nCharID)
	local oUnionPlayer = self:GetUnionPlayer(nCharID)
	if oUnionPlayer then
		local nUnionID = oUnionPlayer:Get("m_nUnionID")	
		if nUnionID > 0 then
			return self:GetUnion(nUnionID)
		end
	end
end

--取联盟玩家
function CUnionMgr:GetUnionPlayer(nCharID)
	return self.m_tUnionPlayerMap[nCharID]
end

--创建联盟玩家
function CUnionMgr:CreateUnionPlayer(oPlayer)
	local nCharID = oPlayer:GetCharID()
	assert(not self:GetUnionPlayer(nCharID))
	local oUnionPlayer = CUnionPlayer:new()
	oUnionPlayer.m_nUnionID = 0 
	oUnionPlayer.m_nCharID = nCharID
	oUnionPlayer.m_sName = oPlayer:GetName()
	oUnionPlayer.m_nLevel = oPlayer:GetLevel()
	oUnionPlayer.m_nExitTime = 0
	self.m_tUnionPlayerMap[nCharID] = oUnionPlayer
	oUnionPlayer:MarkDirty(true)
	
	self:SaveData() --立即保存
	return oUnionPlayer
end

--取冷却时间
function CUnionMgr:GetJoinCD(oPlayer, bNotify)
	local nCharID = oPlayer:GetCharID()
	local oUnionPlayer = self:GetUnionPlayer(nCharID)
	if not oUnionPlayer then
		return 0
	end
	local nHourCD = ctUnionEtcConf[1].nExitCD
	local nRemainCD = math.max(0, oUnionPlayer:Get("m_nExitTime") + nHourCD * 3600 - os.time())
	if nRemainCD > 0 then
		if bNotify then
			oPlayer:Tips(string.format("退出联盟不足%d小时，无法加入新的联盟", nHourCD))
		end
	end
	return nRemainCD
end

--是否开放
function CUnionMgr:IsOpen(oPlayer)
	local nChapter = ctUnionEtcConf[1].nOpenChapter
	local nPassChapter = oPlayer.m_oDup:MaxChapterPass()
	if nPassChapter < nChapter then
		return oPlayer:Tips(string.format("通关第%d章：%s开启", nChapter, CDup:ChapterName(nChapter)))
	end
	return true
end

--创建新联盟
function CUnionMgr:CreateUnion(oPlayer, sName, sNotice)
	if not self:IsOpen(oPlayer) then
		return
	end
	sName = string.Trim(sName)
	assert(sName ~= "", "名字数据非法")
	if string.len(sName) > CUnion.nMaxUnionNameLen then
		return oPlayer:Tips("名字超长，不能超过6个汉字")
	end
	if string.len(sNotice) > CUnion.nMaxUnionDeclLen then
		return oPlayer:Tips("公告超长，不能超过60个汉字")
	end

	local nCharID = oPlayer:GetCharID()
	if oPlayer:GetYuanBao() < ctUnionEtcConf[1].nCreateCost then
		return oPlayer:YBDlg()
	end
	if string.len(sName) > CUnion.nMaxUnionNameLen then
		return oPlayer:Tips("联盟名字超长")
	end
	if self.m_tUnionNameMap[sName] then
		return oPlayer:Tips("联盟名字已被占用")
	end
	local oUnionPlayer = self:GetUnionPlayer(nCharID)
	if oUnionPlayer and oUnionPlayer:Get("m_nUnionID") > 0 then
		return oPlayer:Tips("您已经有联盟")
	end
	if not oUnionPlayer then
		oUnionPlayer = self:CreateUnionPlayer(oPlayer)
	end
	if self:GetJoinCD(oPlayer, true) > 0 then
		return
	end
	local nUnionID = self:MakeUnionID()
	if self.m_tUnionMap[nUnionID] then
		return oPlayer:Tips("联盟ID已经被占用")
	end
	local oUnion = CUnion:new()
	self.m_tUnionMap[nUnionID] = oUnion
	--local bRes, sErr = pcall(function()  end)
	if not oUnion:CreateInit(oPlayer, nUnionID, sName, sNotice) then
		self.m_tUnionMap[nUnionID] = nil
		return
	end
	self.m_tUnionNameMap[sName] = nUnionID
	table.insert(self.m_tUnionIDList, nUnionID)
	oPlayer:SubItem(gtItemType.eCurr, gtCurrType.eYuanBao, ctUnionEtcConf[1].nCreateCost, "创建联盟")
	self:MarkNameDirty(true)
	self:SaveData() --立即保存
	oUnion:SyncDetailInfo(oPlayer) --前端说想要详细信息
	return oUnion
end

--联盟解散
function CUnionMgr:OnUnionDismiss(oUnion)
	local nUnionID, sUnionName = oUnion:GetID(), oUnion:GetName()
	self.m_tUnionMap[nUnionID] = nil
	self.m_tUnionNameMap[sUnionName] = nil
	self:MarkNameDirty(true)
	self:MarkUnionDirty(nUnionID, false)
	goDBMgr:GetSSDB("Player"):HDel(gtDBDef.sUnionDB, nUnionID)

	for nIndex, nTmpID in ipairs(self.m_tUnionIDList) do
		if nTmpID == nUnionID then
			table.remove(self.m_tUnionIDList, nIndex)
			break
		end
	end

	--清除聊天记录
	goTalk:OnUnionDismiss(nUnionID)
end

--同步公会基本信息
function CUnionMgr:SyncUnionInfo(nCharID)
	local oPlayer = goPlayerMgr:GetPlayerByCharID(nCharID)
	if not oPlayer then return end

	local nID, sName, nPos = 0, "", 0
	local oUnion = self:GetUnionByCharID(nCharID)
	if oUnion then
		nID, sName, nPos = oUnion:GetID(), oUnion:GetName(), oUnion:GetPos(nCharID)
	end

	local tMsg = {nID=nID, sName=sName, nPos=nPos}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionInfoRet", tMsg)
end

--联盟列表请求
function CUnionMgr:UnionListReq(oPlayer, sUnionKey, bNotFull)
	print("CUnionMgr:UnionListReq***", sUnionKey, bNotFull)
	local nPageSize = 4
	local nCharID = oPlayer:GetCharID()

	local tUnionIDList = {}
	if sUnionKey == "" then
		local tTmpList = {}
		for nUnionID, oUnion in pairs(self.m_tUnionMap) do
			if bNotFull then
				if not oUnion:IsFull() then
					table.insert(tTmpList, nUnionID)
				end
			else
				table.insert(tTmpList, nUnionID)
			end
		end
		for k = 1, nPageSize do
			if #tTmpList <= 0 then
				break
			end
			local nRnd = math.random(1, #tTmpList)
			table.insert(tUnionIDList, table.remove(tTmpList, nRnd))
		end
	else
		--筛选联盟
		local nUnionID = tonumber(sUnionKey)
		if self.m_tUnionMap[nUnionID] then
			table.insert(tUnionIDList, nUnionID)
		end
		for sName, nUnionID in pairs(self.m_tUnionNameMap) do
			if string.find(sName, sUnionKey) then
				table.insert(tUnionIDList, nUnionID)
			end
			if #tUnionIDList >= nPageSize then
				break
			end
		end

		-- --排序
		-- local function _DescSort(id1, id2)
		-- 	local nRank1 = goRankingMgr.m_oUGLRanking:GetUnionRank(id1)
		-- 	local nRank2 = goRankingMgr.m_oUGLRanking:GetUnionRank(id2)
		-- 	return nRank1 < nRank2
		-- end
		-- table.sort(tTmpIDList, _DescSort)
		-- nPageCount = math.ceil(#tTmpIDList/ nPageSize)
		-- nPageIndex = math.max(1, math.min(nPageIndex, nPageCount))
		-- local nBeg = (nPageIndex-1)*nPageSize+1
		-- local nEnd = math.min(#tTmpIDList, nBeg+nPageSize-1)
		-- for k = nBeg, nEnd do
		-- 	if tTmpIDList[k] then
		-- 		table.insert(tUnionIDList, tTmpIDList[k])
		-- 	end
		-- end
	end

	local tUnionList = {}
	for _, nUnionID in ipairs(tUnionIDList) do
		local oUnion = self:GetUnion(nUnionID)
		if oUnion then
			local tItem = {}
			tItem.nID = nUnionID
			tItem.sName = oUnion:GetName()
			tItem.nLevel = oUnion:GetLevel()
			tItem.nGuoLi = oUnion:GetGuoLi()
			tItem.sMengZhu = oUnion:GetMengZhuName()
			tItem.nMembers = oUnion:GetMembers()
			tItem.nMaxMembers = oUnion:MaxMembers()
			tItem.bApplied = oUnion:IsApplied(nCharID)
			table.insert(tUnionList, tItem)
		end
	end
	local tMsg = {tUnionList = tUnionList}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionListRet", tMsg)
	print("CUnionMgr:UnionListReq***", tMsg)

	--1些通知
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
	if oUnionPlayer then
		oUnionPlayer:FirstKickNotify(oPlayer)
		oUnionPlayer:FirstDismissNotify(oPlayer)
	end
end

--创建联盟请求
function CUnionMgr:CreateUnionReq(oPlayer, sName, sNotice)
	self:CreateUnion(oPlayer, sName, sNotice)
end

--随机加入联盟请求
function CUnionMgr:JoinRandUnionReq(oPlayer)
	if not self:IsOpen(oPlayer) then
		return
	end
	local nCharID = oPlayer:GetCharID()
	local oUnion = self:GetUnion(nCharID)
	if oUnion then
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
		return oPlayer:Tips("没有可加入的联盟")
	end

	--冷却
	local oUnion = tUnionList[math.random(#tUnionList)]
	if self:GetJoinCD(oPlayer, true) > 0 then
		return
	end
	local oUnionPlayer = goUnionMgr:GetUnionPlayer(nCharID)
	if not oUnionPlayer then
		oUnionPlayer = self:CreateUnionPlayer(oPlayer)
	end
	oUnion:JoinUnion(nil, nCharID)
end

--玩家上线
function CUnionMgr:Online(oPlayer)
	local nCharID = oPlayer:GetCharID()
	local oUnion = self:GetUnionByCharID(nCharID)
	if oUnion then
		oUnion:Online(oPlayer)
	end
	
	local oUnionPlayer= goUnionMgr:GetUnionPlayer(nCharID)
	if oUnionPlayer then
		oUnionPlayer:Online()
	end
	self:SyncUnionInfo(oPlayer:GetCharID())
end

goUnionMgr = goUnionMgr or CUnionMgr:new()