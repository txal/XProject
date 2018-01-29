--国使馆
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CGSGData:Ctor()
	self.m_bDirty = false
	self.m_tTitleMap = {}			--玩家称号映射{titleid={charid,ntime},...}
	self:Init()
end

function CGSGData:Init()
	self.m_tTaoJiaoMap = {} 		--玩家讨教映射{[charid]={[titleid]=state},...},...}
	self.m_nResetTime = os.time() 	--重置讨教时间
end

function CGSGData:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sOfflineGSGDB, "data")
	if sData == "" then
		return
	end

	local tData = cjson.decode(sData)
	self.m_tTitleMap = tData.m_tTitleMap
	for nTitleID, tInfo in pairs(self.m_tTitleMap) do
		if not tInfo.nCharID then
			self.m_tTitleMap[nTitleID] = nil
			self:MarkDirty(true)
		end
	end
	self.m_tTaoJiaoMap = tData.m_tTaoJiaoMap
	self.m_nResetTime = tData.m_nResetTime
end

function CGSGData:SaveData()
	if not self:IsDirty() then
		return
	end
	self:MarkDirty(false)

	local tData = {}
	tData.m_tTitleMap = self.m_tTitleMap
	tData.m_tTaoJiaoMap = self.m_tTaoJiaoMap 
	tData.m_nResetTime = self.m_nResetTime
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sOfflineGSGDB, "data", cjson.encode(tData))
end

function CGSGData:OnRelease()
	self:SaveData()
end

function CGSGData:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CGSGData:IsDirty() return self.m_bDirty end

function CGSGData:Online(oPlayer)
	self:CheckRedPoint(oPlayer)
end

--保存第一名称号
function CGSGData:SetFirst(nTitleID, nCharID, nTime)
	if not nCharID then 
		self.m_tTitleMap[nTitleID] = nil
		self:MarkDirty(true)
		return 
	end
	self.m_tTitleMap[nTitleID] = self.m_tTitleMap[nTitleID] or {}
	self.m_tTitleMap[nTitleID].nCharID = nCharID
	self.m_tTitleMap[nTitleID].nTime = nTime
	self:MarkDirty(true)
end

--检测今天是否讨教过
function CGSGData:CheckTaoJiao()
	if not os.IsSameDay(os.time(), self.m_nResetTime, 0) then
		self:Init()
		self:MarkDirty(true)
	end
end

--取个人称号
function CGSGData:GetTitle(nCharID)
	local nTitle, nMaxTime = 0, 0
	for nID, tTitle in pairs(self.m_tTitleMap) do
		if tTitle and nCharID == tTitle.nCharID then 
			if tTitle.nTime > nMaxTime then 
				nTitle = nID
				nMaxTime = tTitle.nTime
			end
		end
	end 
	return nTitle
end

--讨教状态
function CGSGData:TaoJiaoState(nTitleID, nCharID)
	if self.m_tTitleMap[nTitleID] and self.m_tTitleMap[nTitleID].nCharID == nCharID then 
		return 2 --自己
	end

	if not self.m_tTaoJiaoMap[nCharID] then 
		return 0 --未讨教
	else 
		return 1 --已讨教
	end
end

--获得最新称号类型
function CGSGData:GetNewTitle()
	local nType, nMaxTime  = 0, 0
	for nID, tData in pairs(self.m_tTitleMap) do
		tData.nTime = tData.nTime or 0 
		if nMaxTime == tData.nTime then 
			nType = math.min(nType, nID)
		end
		if tData.nTime > nMaxTime then 
			nType = nID
			nMaxTime = tData.nTime
		end
	end 
	return nType
end

--同步界面
function CGSGData:SyncInfoReq(oPlayer)
	self:CheckTaoJiao()

	local tList = {}
	local nCharID = oPlayer:GetCharID()
	for k=1, #ctTitleConf do
		local sFirstName = ""
		local nFirstVIP = 0
		local nFirstLevel = 0
		local nPlayerID = 0
		if self.m_tTitleMap[k] then 
			nPlayerID = self.m_tTitleMap[k].nCharID 
			local oFirstPlayer = goOfflineDataMgr:GetPlayer(nPlayerID)
			if oFirstPlayer then
				sFirstName = oFirstPlayer:GetName()
				nFirstVIP = oFirstPlayer:GetVIP()
				nFirstLevel = oFirstPlayer:GetLevel()
			else
				LuaTrace("为啥玩家不存在:", nPlayerID)
			end
		end
		local nLevel = oPlayer:GetLevel()
		local nState = self:TaoJiaoState(k, nCharID)
		table.insert(tList, {nCharID=nPlayerID, nFirstLevel=nFirstLevel, sFirstName=sFirstName, nFirstVIP=nFirstVIP, nType=k, nState=nState, nLevel=nLevel})
	end
	local nNewTitle = self:GetNewTitle()
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "GSGInfoRet", {nNewTitle=nNewTitle, tList=tList})
end

--讨教
function CGSGData:TaoJiaoReq(nTitleID, oPlayer)
	self:CheckTaoJiao()
	local nCharID = oPlayer:GetCharID()
	local nState = self:TaoJiaoState(nTitleID, nCharID)
	if nState == 2 then
		return oPlayer:Tips("不能向自己讨教")
	end
	if nState == 1 then
		return oPlayer:Tips("已讨教过")
	end
	self.m_tTaoJiaoMap[nCharID] = self.m_tTaoJiaoMap[nCharID] or 1
	self:MarkDirty(true)

	local nLev = oPlayer:GetLevel()
	local nYuanBao = ctLevelConf[nLev].nTJYB
	if self.m_tTitleMap[nTitleID] then 
		local nOfflineCharID = self.m_tTitleMap[nTitleID].nCharID
		local OfflinePlayer = goOfflineDataMgr:GetPlayer(nOfflineCharID) 
		local nLevel = OfflinePlayer:GetLevel()
		local sName = OfflinePlayer:GetName()
		CmdNet.PBSrv2Clt(oPlayer:GetSession(), "GSGTaoJiaoRet", {nYuanBao=nYuanBao, nLevel=nLevel, sName=sName})
	else
		oPlayer:Tips(string.format("恭喜娘娘, 讨教获得%s元宝", nYuanBao))
	end
	oPlayer:AddItem(gtItemType.eCurr, gtCurrType.eYuanBao, nYuanBao, "讨教获得奖励")
	
	self:SyncInfoReq(oPlayer)
	self:CheckRedPoint(oPlayer)
	--任务
	oPlayer.m_oMainTask:Progress(gtMainTaskType.eCond43, 1)
end

--检测小红点
function CGSGData:CheckRedPoint(oPlayer)
	self:CheckTaoJiao()
	local tRedPoint = {}
	local bRed = false
	local nCharID = oPlayer:GetCharID()
	for k=1, #ctTitleConf do
		local nState = self:TaoJiaoState(k, nCharID)
		if nState == 0 then 
			bRed =true
		end
		table.insert(tRedPoint, bRed)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "GSGRedPointRet", {tRedPoint = tRedPoint})
end