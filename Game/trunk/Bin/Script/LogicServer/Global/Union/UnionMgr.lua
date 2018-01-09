local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local sUnionDB = "UnionDB"
local sUnionNameDB = "UnionNameDB"
local sUnionPlayerDB = "UnionPlayerDB"

nMaxUnionNameLen = 6*3 	--名字最大字符长度(6个中文)
nMaxUnionDeclLen = 50*3 --宣言最大字符长度(50个中文)
local nMaxUnionID = 9999
local nServerID = gnServerID
local nAutoSaveTime = 3*60*1000

--战队管理器
function CUnionMgr:Ctor()
	self.m_nAutoInc = 0
	--{[nUnionID]=oUnion}
	self.m_tUnionMap = {}
	--{[sUnionName]=nUnionID}
	self.m_tUnionNameMap = {}
	--{[sCharID]=oUnionPlayer}
	self.m_tUnionPlayerMap = {}

	self.m_tUnionIDList = {} --用来随机
	self.m_tDirtyUnionMap = {}
	self.m_tDirtyUnionPlayerMap = {}
	self.m_bUnionNameDirty = false
end

function CUnionMgr:AutoSave()
	self.m_nSaveTick = GlobalExport.RegisterTimer(nAutoSaveTime, function() self:AutoSave() end)
	self:SaveData()
end

function CUnionMgr:OnRelease()
	if self.m_nSaveTick then
		GlobalExport.CancelTimer(self.m_nSaveTick)
		self.m_nSaveTick = nil
	end
	self:SaveData()
end

--加载战队数据
function CUnionMgr:LoadData()
	--战队名字列表
	local sData = goSSDB:HGet(sUnionNameDB, "UniqueName")
	if sData ~= "" then
		self.m_tUnionNameMap = GlobalExport.Str2Tb(sData)
	end

	--自动增长ID
	local sData = goSSDB:HGet(sUnionNameDB, "AutoInc")
	if sData ~= "" then
		self.m_nAutoInc = tonumber(sData)
	end

	--战队玩家数据
	local tKeys = goSSDB:HKeys(sUnionPlayerDB)
	for _, sKey in ipairs(tKeys) do
		local sData = goSSDB:HGet(sUnionPlayerDB, sKey)
		local tData = GlobalExport.Str2Tb(sData)
		local oUnionPlayer = CUnionPlayer:new()
		oUnionPlayer:LoadData(tData)
		self.m_tUnionPlayerMap[oUnionPlayer:Get("m_sCharID")] = oUnionPlayer
	end

	--战队数据
	local tKeys = goSSDB:HKeys(sUnionDB)
	for _, sKey in ipairs(tKeys) do
		local sData = goSSDB:HGet(sUnionDB, sKey)
		local tData = GlobalExport.Str2Tb(sData)
		local oUnion = CUnion:new()
		if oUnion:LoadData(tData) then
			self.m_tUnionMap[oUnion:Get("m_nID")] = oUnion
		end
	end

	--检测玩家数据
	for sCharID, oUnionPlayer in pairs(self.m_tUnionPlayerMap) do
		local nUnionID = oUnionPlayer:Get("m_nUnionID")
		if nUnionID > 0 then
			if not self:GetUnion(nUnionID) then
				oUnionPlayer:Set("m_nUnionID", 0)
				oUnionPlayer:MarkDirty(true)
				LuaTrace("UnionPlayer: "..oUnionPlayer:Get("m_sName").." data error: union "..nUnionID.." not found!")
			end
		end
	end
	--检测战队名字
	for sName, nUnionID in pairs(self.m_tUnionNameMap) do
		local oUnion = self:GetUnion(nUnionID)
		if not oUnion then
			self.m_tUnionNameMap[sName] = nil
			self:MarkNameDirty(true)
			LuaTrace("UnionName '"..sName.."' union not found!")
		else
			table.insert(self.m_tUnionIDList, nUnionID)
		end
	end

	--定时保存
	self:AutoSave()
end

--保存战队数据
function CUnionMgr:SaveData()
	print("CUnionMgr:SaveData***")
	--保存战队
	for nUnionID, v in pairs(self.m_tDirtyUnionMap) do
		local oUnion = self.m_tUnionMap[nUnionID]
		local tData = oUnion:SaveData()
		local sData = GlobalExport.Tb2Str(tData)
		goSSDB:HSet(sUnionDB, nUnionID, sData)
	end
	self.m_tDirtyUnionMap = {}

	--保存玩家
	for sCharID , v in pairs(self.m_tDirtyUnionPlayerMap) do
		local oUnionPlayer = self.m_tUnionPlayerMap[sCharID]
		local tData = oUnionPlayer:SaveData()
		local sData = GlobalExport.Tb2Str(tData)
		goSSDB:HSet(sUnionPlayerDB, sCharID, sData)
	end
	self.m_tDirtyUnionPlayerMap = {}

	--战队名字
	if self.m_bUnionNameDirty then
		local sData = GlobalExport.Tb2Str(self.m_tUnionNameMap)
		goSSDB:HSet(sUnionNameDB, "UniqueName", sData)
		self:MarkNameDirty(false)
	end

	--自动增长ID
	goSSDB:HSet(sUnionNameDB, "AutoInc", self.m_nAutoInc)
end

--名字脏
function CUnionMgr:MarkNameDirty(bDirty)
	self.m_bUnionNameDirty = bDirty
end

--战队脏
function CUnionMgr:MarkUnionDirty(nUnionID, bDirty)
	if bDirty then
		self.m_tDirtyUnionMap[nUnionID] = true
	else
		self.m_tDirtyUnionMap[nUnionID] = nil
	end
end

--玩家脏
function CUnionMgr:MarkPlayerDirty(sCharID, bDirty)
	if bDirty then
		self.m_tDirtyUnionPlayerMap[sCharID] = true
	else
		self.m_tDirtyUnionPlayerMap[sCharID] = nil
	end
end

--生成战队ID
function CUnionMgr:MakeUnionID()
	self.m_nAutoInc = self.m_nAutoInc % nMaxUnionID + 1
	local nUnionID = gnServerID * 10000 + self.m_nAutoInc
	return nUnionID
end

--取战队
function CUnionMgr:GetUnion(nUnionID)
	return self.m_tUnionMap[nUnionID]
end

--通过玩家ID取公会
function CUnionMgr:GetUnionByCharID(sCharID)
	local oUnionPlayer = self:GetUnionPlayer(sCharID)
	if oUnionPlayer then
		local nUnionID = oUnionPlayer:Get("m_nUnionID")	
		if nUnionID > 0 then
			return self:GetUnion(nUnionID)
		end
	end
end

--取战队玩家
function CUnionMgr:GetUnionPlayer(sCharID)
	return self.m_tUnionPlayerMap[sCharID]
end

--创建战队玩家
function CUnionMgr:CreateUnionPlayer(oPlayer)
	local sCharID = oPlayer:GetCharID()
	assert(not self:GetUnionPlayer(sCharID))
	local oUnionPlayer = CUnionPlayer:new()
	oUnionPlayer.m_nUnionID = 0 
	oUnionPlayer.m_sCharID = sCharID
	oUnionPlayer.m_sName = oPlayer:GetName()
	oUnionPlayer.m_nLevel = oPlayer:GetLevel()
	oUnionPlayer.m_nFame = oPlayer.m_oGVGModule:GetFame()
	oUnionPlayer.m_nExitTime = 0
	self.m_tUnionPlayerMap[sCharID] = oUnionPlayer
	oUnionPlayer:MarkDirty(true)
	
	self:SaveData() --立即保存
	return oUnionPlayer
end

--创建新战队
function CUnionMgr:CreateUnion(oPlayer, nLogo, sName, sDeclaration)
	sName = string.Trim(sName)
	assert(nLogo > 0 and sName ~= "" and sDeclaration, "数据非法")
	local sCharID = oPlayer:GetCharID()
	if oPlayer:GetMoney() < ctUnionEtc[1].nCreateDiamond then
		return oPlayer:ScrollMsg(ctLang[4])
	end
	local nOpenLevel = ctUnionEtc[1].nOpenLevel 
	if oPlayer:GetLevel() < nOpenLevel then
		return oPlayer:ScrollMsg(string.format(ctLang[47], nOpenLevel))	
	end
	if string.len(sName) > nMaxUnionNameLen then
		return oPlayer:ScrollMsg(ctLang[43])
	end
	if string.len(sDeclaration) > nMaxUnionDeclLen then
		return oPlayer:ScrollMsg(ctLang[44])
	end
	if self.m_tUnionNameMap[sName] then
		return oPlayer:ScrollMsg(ctLang[45])
	end
	local oUnionPlayer = self:GetUnionPlayer(sCharID)
	if oUnionPlayer and oUnionPlayer:Get("m_nUnionID") > 0 then
		return oPlayer:ScrollMsg(ctLang[46])
	end
	if not oUnionPlayer then
		oUnionPlayer = self:CreateUnionPlayer(oPlayer)
	end
	local nHourCD = ctUnionEtc[1].nExitCD
	local nRemainCD = math.max(0, oUnionPlayer:Get("m_nExitTime") + nHourCD * 3600 - os.time())
	if  nRemainCD > 0 then
		local nHour, nMin = os.SplitTime(nRemainCD)
		local sNotice = string.format(ctLang[48], nHourCD, nHour, nMin)
		return oPlayer:ScrollMsg(sNotice)
	end
	local nUnionID = self:MakeUnionID()
	if self.m_tUnionMap[nUnionID] then
		print("战队ID已被占用")
		return
	end
	local oUnion = CUnion:new()
	self.m_tUnionMap[nUnionID] = oUnion
	if not pcall(function() oUnion:CreateInit(oPlayer, nUnionID, nLogo, sName, sDeclaration) end) then
		self.m_tUnionMap[nUnionID] = nil
		return
	end
	self.m_tUnionNameMap[sName] = nUnionID
	table.insert(self.m_tUnionIDList, nUnionID)
	oPlayer:SubMoney(ctUnionEtc[1].nCreateDiamond, gtReason.eCreateUnion)
	self:MarkNameDirty(true)

	self:SaveData() --立即保存
	return oUnion
end

--战队解散
function CUnionMgr:OnUnionDismiss(oUnion)
	local nUnionID, sUnionName = oUnion:Get("m_nID"), oUnion:Get("m_sName")
	print("CUnionMgr:OnUnionDismiss***", nUnionID)
	self.m_tUnionMap[nUnionID] = nil
	self.m_tUnionNameMap[sUnionName] = nil
	self:MarkNameDirty(true)
	self:MarkUnionDirty(nUnionID, false)
	goSSDB:HDel(sUnionDB, nUnionID)

	for nIndex, nTmpID in ipairs(self.m_tUnionIDList) do
		if nTmpID == nUnionID then
			table.remove(self.m_tUnionIDList, nIndex)
			break
		end
	end
end

--同步公会基本信息
function CUnionMgr:SynUnionInfo(sCharID)
	local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sCharID)
	if not oPlayer then
		return
	end

	local nID, sName, nPos = 0, "", 0
	local oUnion = self:GetUnionByCharID(sCharID)
	if oUnion then
		nID, sName, nPos = oUnion:Get("m_nID"), oUnion:Get("m_sName"), oUnion:GetPos(sCharID)
	end
	local tMsg = {nID=nID, sName=sName, nPos=nPos}
	print("CUnionMgr:SynUnionInfo***", tMsg)
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionInfoRet", tMsg)
end

--战队列表请求
function CUnionMgr:UnionListReq(oPlayer, sUnionName, nReturnNum)
	nReturnNum = math.max(1, math.min(nReturnNum, 100))
	local sCharID = oPlayer:GetCharID()

	local tRndIDList, tRndIDMap = {}, {}
	if sUnionName == "" then
		if nReturnNum >= #self.m_tUnionIDList then
			tRndIDList = self.m_tUnionIDList
		else
			local k = 0
			while k < nReturnNum do
				local nRnd = math.random(1, #self.m_tUnionIDList)
				local nUnionID = self.m_tUnionIDList[nRnd]
				if not tRndIDMap[nUnionID] then
					table.insert(tRndIDList, nUnionID)
					tRndIDMap[nUnionID] = true
					k = k + 1
				end
			end
		end
	else
		local nUnionID = self.m_tUnionNameMap[sUnionName]
		if nUnionID then
			table.insert(tRndIDList,nUnionID)
		end
	end
	local tUnionList = {}
	for _, nUnionID in ipairs(tRndIDList) do
		local oUnion = self:GetUnion(nUnionID)
		local tItem = {}
		tItem.nID = nUnionID
		tItem.nIcon = oUnion:Get("m_nLogo")
		tItem.sName = oUnion:Get("m_sName")
		local sPresident = oUnion:Get("m_sPresident")
		local oUnionPlayer = goUnionMgr:GetUnionPlayer(sPresident)
		local sCharName = oUnionPlayer and oUnionPlayer:Get("m_sName") or ""
		tItem.sPresident = sCharName
		tItem.nMembers = oUnion:Get("m_nMembers")
		tItem.nMaxMembers = oUnion:Get("m_nMaxMembers")
		tItem.sDeclaration = oUnion:Get("m_sDeclaration")
		tItem.bApplied = oUnion:IsApplied(sCharID)
		table.insert(tUnionList, tItem)
	end
	local tMsg = {tUnionList = tUnionList}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "UnionListRet", tMsg)
end

--创建战队请求
function CUnionMgr:CreateUnionReq(oPlayer, nIcon, sName, sDeclaration)
	self:CreateUnion(oPlayer, nIcon, sName, sDeclaration)
end

--玩家上线
function CUnionMgr:Online(oPlayer)
	self:SynUnionInfo(oPlayer:GetCharID())
end

--玩家等级改变
function CUnionMgr:OnLevelChange(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local oUnionPlayer = self:GetUnionPlayer(sCharID)
	if not oUnionPlayer then
		return
	end
	oUnionPlayer:Set("m_nLevel", oPlayer:GetLevel())
	self:MarkPlayerDirty(sCharID, true)
end

--玩家声望改变
function CUnionMgr:OnFameChange(oPlayer)
	local sCharID = oPlayer:GetCharID()
	local oUnionPlayer = self:GetUnionPlayer(sCharID)
	if not oUnionPlayer then
		return
	end
	local nFame = oPlayer.m_oGVGModule:GetFame()
	oUnionPlayer:Set("m_nFame", nFame)
	self:MarkPlayerDirty(sCharID, true)
end


goUnionMgr = goUnionMgr or CUnionMgr:new()