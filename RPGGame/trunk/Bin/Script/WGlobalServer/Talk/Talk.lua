--聊天系统

--频道
CTalk.tChannel = 
{
	eSystem = 1,	--系统
	eWorld = 2,		--世界
	eUnion = 3, 	--联盟
}

local nMaxConts = 100 	--聊天最大显示信息
local nAutoSaveTime = 3*60

function CTalk:Ctor()
	self.m_bDirty = false
	self.m_tTalkHistory = {}	--聊天记录{{channel, scont},...}
	self.m_tUnionTalk = {}		--联盟聊天记录{[unionid]={},...}
	self.m_nSaveTick = nil
end

--释放定时器
function CTalk:OnRelease()
	goTimerMgr:Clear(self.m_nSaveTick)
	self.m_nSaveTick = nil

	self:SaveData()
end

--自动保存
function CTalk:AutoSave()
	self.m_nSaveTick = goTimerMgr:Interval(nAutoSaveTime, function() self:SaveData() end)
end

function CTalk:LoadData()
	local sData = goDBMgr:GetSSDB("Player"):HGet(gtDBDef.sTalkDB, "data")
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_tUnionTalk = tData.m_tUnionTalk
		self.m_tTalkHistory = tData.m_tTalkHistory
	end
	--定时保存
	self:AutoSave()
end

function CTalk:SaveData()
	if not self:IsDirty() then
		return
	end 
	self:MarkDirty(false)
	
	local tData = {}
	tData.m_tTalkHistory = self.m_tTalkHistory
	tData.m_tUnionTalk = self.m_tUnionTalk
	goDBMgr:GetSSDB("Player"):HSet(gtDBDef.sTalkDB, "data", cjson.encode(tData))
end

function CTalk:Online(oPlayer)
	self:TalkHistory(oPlayer)
end

function CTalk:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

function CTalk:IsDirty()
	return self.m_bDirty 
end

--联盟解散清理历史聊天
function CTalk:OnUnionDismiss(nUnionID)
	self.m_tUnionTalk[nUnionID] = nil
	self:MarkDirty(true)
end

--聊天记录返回
function CTalk:TalkHistory(oPlayer)
	local nCharID = oPlayer:GetCharID() 
	local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
	local tUnion = nil
	if oUnion then 
		local nUnionID = oUnion:GetID()
		tUnion = self.m_tUnionTalk[nUnionID]
	end

	local tMsg = {tWorld=self.m_tTalkHistory, tUnion=tUnion}
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "TalkHistoryRet", tMsg)
end

--发送聊天信息
function CTalk:_SendTalkMsg(nSrcCharID, sSrcCharName, nVIP, nChannel, sCont, tTarSessionList)
	local tMsg = {
		nCharID=nSrcCharID,
		sCharName=sSrcCharName,
		nVIP=nVIP,
		nChannel=nChannel,
		sCont=sCont,
		nTitle=goOfflineDataMgr.m_oGSGData:GetTitle(nSrcCharID),
	}
	if tTarSessionList then
		CmdNet.PBBroadcastExter(tTarSessionList, "TalkRet", tMsg)
	else
		CmdNet.PBSrv2All("TalkRet", tMsg) 
	end

	--世界聊天记录
	tMsg.nTime = os.time()
	if nChannel == self.tChannel.eWorld then 
		self.m_tTalkHistory = self.m_tTalkHistory or {}
		table.insert(self.m_tTalkHistory, tMsg)
		if #self.m_tTalkHistory > nMaxConts then 
			table.remove(self.m_tTalkHistory, 1)
		end
	end

	--联盟聊天记录
	if nChannel == self.tChannel.eUnion then
		local oUnion = goUnionMgr:GetUnionByCharID(nSrcCharID)
		if not oUnion then return end
		local nUnionID = oUnion:GetID()
		
		self.m_tUnionTalk = self.m_tUnionTalk or {}
		self.m_tUnionTalk[nUnionID] = self.m_tUnionTalk[nUnionID] or {}
		table.insert(self.m_tUnionTalk[nUnionID], tMsg)
		if #self.m_tUnionTalk[nUnionID] > nMaxConts then 
			table.remove(self.m_tUnionTalk[nUnionID], 1)
		end
	end
	self:MarkDirty(true)
end

--世界消息
function CTalk:SendWorldMsg(oPlayer, sCont)
	local nCharID, sCharName, nVIP = 0, "", 0
	if oPlayer then
		nCharID, sCharName, nVIP = oPlayer:GetCharID(), oPlayer:GetName(), oPlayer:GetVIP()
	end
	self:_SendTalkMsg(nCharID, sCharName, nVIP, self.tChannel.eWorld, sCont)	
end

--系统消息
function CTalk:SendSystemMsg(sCont)
	local nCharID, sCharName, nVIP = 0, "系统", 0 --系统
	self:_SendTalkMsg(nCharID, sCharName, nVIP, self.tChannel.eSystem, sCont)	
end

--联盟信息
function CTalk:SendUnionMsg(oPlayer, sCont, oUnion)
	local nCharID, sCharName, nVIP = 0, "", 0
	if oPlayer then
		nCharID, sCharName, nVIP = oPlayer:GetCharID(), oPlayer:GetName(), oPlayer:GetVIP()
		oUnion = goUnionMgr:GetUnionByCharID(nCharID)
		if not oUnion then return end
	end
	local tSessionList = oUnion:GetSessionList()
	self:_SendTalkMsg(nCharID, sCharName, nVIP, self.tChannel.eUnion, sCont, tSessionList)	
end

--聊天请求
function CTalk:TalkReq(oPlayer, nChannel, sCont)
	local nCharID = oPlayer:GetCharID()
	if goPlayerMgr:IsJinYan(oPlayer) then
		return oPlayer:Tips("你已经被禁言")
	end

	local nLen = string.len(sCont)
	if nLen <= 0 then
		return
	end
	
	local nMaxLen = 300
	if nLen >= nMaxLen then
		return oPlayer:Tips("内容过长，只支持100个汉字")
	end
	sCont = GF.FilterBadWord(sCont)
	if nChannel == self.tChannel.eWorld then
		self:SendWorldMsg(oPlayer, sCont)

	elseif nChannel == self.tChannel.eUnion then
		local oUnion = goUnionMgr:GetUnionByCharID(nCharID)
		if not oUnion then return oPlayer:Tips("请先加入联盟") end
		self:SendUnionMsg(oPlayer, sCont, oUnion)
	else
		assert(false, "不支持频道:"..nChannel)
	end
end

--GM清除聊天记录
function CTalk:GMClearTalk(oPlayer)
	self.m_tTalkHistory = {}
	self.m_tUnionTalk = {}
	self:MarkDirty(true)

	self:TalkHistory(oPlayer)
	oPlayer:Tips("清空聊天记录成功")
end


goTalk = goTalk or CTalk:new()