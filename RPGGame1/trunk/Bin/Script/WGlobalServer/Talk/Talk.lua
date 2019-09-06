--聊天系统
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

local nMaxShields = 20 			--屏蔽人数上限
local nWorldTalkCDTime = 5 		--世界聊天冷却时间
local nMaxTalkRecord = 40 		--n条历史记录

--频道
CTalk.tChannel = 
{
	eSystem = 1,	--系统
	eWorld = 2,		--世界
	eUnion = 3, 	--联盟
	eTeam = 4,		--队伍
	eCurr = 5,		--当前
	eHearsay= 6, 	--传闻
}

function CTalk:Ctor()
	self.m_bDirty = false
	self.m_tShieldMap = {} 			--屏蔽列表
	self.m_tTalkHistory = {} 		--聊天记录

	--不保存
	self.m_tAccountStateMap = {} 	--这里定时取账号状态{[roleid]={nState=0,nTime=0},...}
	self.m_nSaveTimer = nil 		--计时器
end

--释放定时器
function CTalk:Release()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
	self:SaveData()
end

function CTalk:SaveData()
	local tData = {}
	tData.m_tShieldMap = self.m_tShieldMap
	tData.m_tTalkHistory = self.m_tTalkHistory
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	oSSDB:HSet(gtDBDef.sTalkDB, "data", cseri.encode(tData))
end

function CTalk:LoadData()
	local oSSDB = goDBMgr:GetGameDB(gnServerID, "global", CUtil:GetServiceID())
	local sData = oSSDB:HGet(gtDBDef.sTalkDB, "data")
	if sData ~= "" then
		local tData = cseri.decode(sData)
		self.m_tShieldMap = tData.m_tShieldMap or {}
		self.m_tTalkHistory = tData.m_tTalkHistory or {}
	end
	self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

function CTalk:Online(oRole)
	self:SyncShieldRoleList(oRole)
	
	local nUnionID = oRole:GetUnionID()
	local tWorldTalk = self.m_tTalkHistory[CTalk.tChannel.eWorld] or {}
	local tHearsayTalk = self.m_tTalkHistory[CTalk.tChannel.eHearsay] or {}
	local tUnionTalk = {}
	if self.m_tTalkHistory[CTalk.tChannel.eUnion] and self.m_tTalkHistory[CTalk.tChannel.eUnion][nUnionID] then
		tUnionTalk = self.m_tTalkHistory[CTalk.tChannel.eUnion][nUnionID] 
	end
	oRole:SendMsg("TalkHistoryRet", {tWorldTalk=tWorldTalk, tUnionTalk=tUnionTalk, tHearsayTalk=tHearsayTalk})

	self:SendWelcomeSysTalk(oRole)
end

--发送欢迎系统消息
function CTalk:SendWelcomeSysTalk(oRole)
	local sCont = ctTalkConf["welcomesystalk"].sContent
	self:SendSystemMsg(sCont, nil, {oRole:GetServer(), oRole:GetSession()})
end

function CTalk:IsDirty() return self.m_bDirty end
function CTalk:MarkDirty(bDirty) self.m_bDirty = bDirty end

function CTalk:GetAccountState(nRoleID)
	return self.m_tAccountStateMap[nRoleID]
end

function CTalk:_MakeTalkMsg(tTalkIdent, nChannel, sCont)
	local tTalk = {
		tHead = tTalkIdent,
		nChannel = nChannel,
		sCont = sCont,
		nTime = os.time(),
	}
	return tTalk
end

--发送聊天信息
--@tSessionList {server1,session1,server2,session2,...}
function CTalk:_SendTalkMsg(tTalkIdent, nChannel, sCont, tSessionList)
	local tTalk = self:_MakeTalkMsg(tTalkIdent, nChannel, sCont)
	if tSessionList then
		Network.PBBroadcastExter("TalkRet", tSessionList, {tList={tTalk}})
	else
		Network.PBSrv2All("TalkRet", {tList={tTalk}}) 
	end
	self:AddTalkHistory(nChannel, tTalk)
end

--添加历史记录
function CTalk:AddTalkHistory(nChannel, tTalk, nUnionID)
	self.m_tTalkHistory[nChannel] = self.m_tTalkHistory[nChannel] or {}
	if nChannel == CTalk.tChannel.eUnion then
		if (nUnionID or 0) <= 0 then
			return
		end
		self.m_tTalkHistory[nChannel][nUnionID] = self.m_tTalkHistory[nChannel][nUnionID] or {}
		table.insert(self.m_tTalkHistory[nChannel][nUnionID], tTalk)
		while #self.m_tTalkHistory[nChannel][nUnionID] > nMaxTalkRecord do
			table.remove(self.m_tTalkHistory[nChannel][nUnionID], 1)
		end
		self:MarkDirty(true)

	elseif nChannel == CTalk.tChannel.eWorld or nChannel == CTalk.tChannel.eHearsay then
		table.insert(self.m_tTalkHistory[nChannel], tTalk)
		while #self.m_tTalkHistory[nChannel] > nMaxTalkRecord do
			table.remove(self.m_tTalkHistory[nChannel], 1)
		end
		self:MarkDirty(true)
	end
end

--世界聊天消息
--bSys，是否为系统功能发起的调用，系统功能发起的调用，不消耗道具和不受CD限制
function CTalk:SendWorldMsg(oRole, sCont, bSys)
	if not oRole then
		return
	end
	if bSys then 
		return self:SendWorldMsgBySys(oRole, sCont)
	end

	local fnQueryCallback = function(nTotalRechargeRMB)
		if not nTotalRechargeRMB then
			return 
		end

		local nCDTime = os.time() - oRole:GetLastWorldTalkTime()
		if nCDTime < nWorldTalkCDTime then
			return oRole:Tips(string.format("请%s秒后输入", nWorldTalkCDTime-nCDTime))
		end
		if oRole:GetLevel() < 40 and nTotalRechargeRMB < 50 then 
			return oRole:Tips("世界频道发言需达到40级且充值50元以上")
		end
		if oRole:GetLevel() < 40 then
			return oRole:Tips("世界发言需要等级达到40级")
		end
		if nTotalRechargeRMB < 50 then 
			return oRole:Tips("世界发言需要累计充值达到50元")
		end

		local tItemList = {}
		table.insert(tItemList, {nType=gtItemType.eCurr, nID=gtCurrType.eVitality, nNum=10})
		oRole:SubItem(tItemList, "世界频道聊天扣除", function(bRes)
			if not bRes then return oRole:Tips("活力不足，世界发言需要消耗10点活力") end
			self:_SendTalkMsg(oRole:GetTalkIdent(), CTalk.tChannel.eWorld, sCont)
			oRole:Tips("发言消耗了10点活力")
		end)
	end

	Network:RMCall("QueryRoleTotalRechargeReq", fnQueryCallback, 
		oRole:GetStayServer(), oRole:GetLogic(), 0, oRole:GetID())
end

--系统功能发起的世界聊天信息
function CTalk:SendWorldMsgBySys(oRole, sCont)
	if oRole:IsOnline() then 
		self:_SendTalkMsg(oRole:GetTalkIdent(), CTalk.tChannel.eWorld, sCont)
	end
end

--系统聊天消息
function CTalk:SendSystemMsg(sCont, sTitle, tSessionList)
	local tTalkIdent = {sName=sTitle or "系统"}
	self:_SendTalkMsg(tTalkIdent, CTalk.tChannel.eSystem, sCont, tSessionList)
end

--联盟聊天信息 
function CTalk:SendUnionMsg(oRole, sCont)
	print("sCont---------------------", sCont)
	local nServer = oRole:GetServer()
	local nService = goServerMgr:GetGlobalService(nServer, 20)
	local tTalk = self:_MakeTalkMsg(oRole:GetTalkIdent(), CTalk.tChannel.eUnion, sCont)
	Network:RMCall("UnionTalkReq", nil, nServer, nService, 0, oRole:GetID(), tTalk)
	self:AddTalkHistory(CTalk.tChannel.eUnion, tTalk, oRole:GetUnionID())
end

--队伍聊天信息
function CTalk:SendTeamMsg(oRole, sCont, bSys, tExceptList)
	if not bSys and not oRole then
		assert(false, "参数错误")
	end

	local oTeam = goTeamMgr:GetTeamByRoleID(oRole:GetID())
	if not oTeam then
		return oRole:Tips("请先加入队伍")
	end

	local tTalkIdent = {}
	if not bSys then
		tTalkIdent = oRole:GetTalkIdent()
	end

	local tSessionList = oTeam:GetSessionList(tExceptList)
	if #tSessionList > 0 then 
		self:_SendTalkMsg(tTalkIdent, CTalk.tChannel.eTeam, sCont, tSessionList)	
	end
end

--给nTarID的单个玩家发送队伍消息
function CTalk:SendTeamMsgToRole(oRole, sCont, bSys, nTarID)
	if not bSys and not oRole then
		assert(false, "参数错误")
	end

	local tTalkIdent = {}
	if not bSys then
		tTalkIdent = oRole:GetTalkIdent()
	end

	local oTarRole = goGPlayerMgr:GetRoleByID(nTarID)
	if not oTarRole then 
		if oRole then 
			oRole:Tips("目标玩家不存在")
		end
		return 
	end
	if oTarRole:IsRobot() or not oTarRole:IsOnline() then 
		return 
	end
	if not oTarRole:IsOnline() then 
		return 
	end

	local tSessionList = {}
	table.insert(tSessionList, oTarRole:GetServer())
	table.insert(tSessionList, oTarRole:GetSession())
	self:_SendTalkMsg(tTalkIdent, CTalk.tChannel.eTeam, sCont, tSessionList)	
end

--当前频道信息
function CTalk:SendCurrMsg(oRole, sCont)
	Network:RMCall("DupRoleViewListReq", function(tRoleList)
		if not tRoleList or #tRoleList == 0 then
			return
		end
		local tSessionList = {}
		for _, nRoleID in ipairs(tRoleList) do
			local oTmpRole = goGPlayerMgr:GetRoleByID(nRoleID)
			if oTmpRole:IsOnline() then
				table.insert(tSessionList, oTmpRole:GetServer())
				table.insert(tSessionList, oTmpRole:GetSession())
			end
		end
		self:_SendTalkMsg(oRole:GetTalkIdent(), CTalk.tChannel.eCurr, sCont, tSessionList)	

	end, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), oRole:GetID())
end

--传闻信息
function CTalk:SendHearsayMsg(sCont)
	self:_SendTalkMsg({}, CTalk.tChannel.eHearsay, sCont)
end

--聊天请求
function CTalk:TalkReq(oRole, nChannel, sCont, bXMLMsg)
	local nLen = string.len(sCont)
	if nLen <= 0 then
		return
	end
	
	local nMaxLen = 512*3
	if nLen > nMaxLen then
		return oRole:Tips("内容过长，只支持60个汉字")
	end

	local function _fnDoTalk()
		local tAccountState = self:GetAccountState(oRole:GetID())
		local nAccountState = tAccountState and tAccountState.nState or 0
		if nAccountState == gtAccountState.eLockTalk then
			return oRole:Tips("你已经被禁言，请联系客服")
		end

		local sRawCont = sCont
		if not bXMLMsg then 
			sCont = CUtil:FilterBadWord(sCont)
		end
		if nChannel == CTalk.tChannel.eWorld then
			self:SendWorldMsg(oRole, sCont)

		elseif nChannel == CTalk.tChannel.eUnion then
			self:SendUnionMsg(oRole, sCont)

		elseif nChannel == CTalk.tChannel.eTeam then
			self:SendTeamMsg(oRole, sCont)

		elseif nChannel == CTalk.tChannel.eCurr then
			self:SendCurrMsg(oRole, sCont)

		else
			return oRole:Tips("频道不能发言")
		end

		--聊天日志
		local tData = {}
		tData.nVIP = oRole:GetVIP()
		tData.nRoleID = oRole:GetID()
		tData.sRoleName = oRole:GetName()
		tData.sCont = sRawCont
		tData.nTime = os.time()
		goLogger:TalkLog(oRole, tData)
	end
	local tAccountState = self:GetAccountState(oRole:GetID())
	if not tAccountState or os.time()-tAccountState.nTime > 60 then
		local function fnCallback(nAccountState)
			if not nAccountState then
				return
			end
			self.m_tAccountStateMap[oRole:GetID()] = {nState=nAccountState, nTime=os.time()}
			_fnDoTalk()
		end
		oRole:GetAccountState(fnCallback)

	else
		_fnDoTalk()

	end
end

--屏蔽/移除屏蔽请求
--@nType 1屏蔽; 2移除
function CTalk:ShieldRoleReq(oRole, nTarRoleID, nType)
	assert(nType == 1 or nType == 2, "参数错误")
	local nRoleID = oRole:GetID()
	if not self.m_tShieldMap[nRoleID] then
		self.m_tShieldMap[nRoleID] = {nCount=0,tRoleMap={}}
	end
	if CUtil:IsRobot(nTarRoleID) then 
		return 
	end

	if nType == 1 then
		if self.m_tShieldMap[nRoleID].nCount >= nMaxShields then
			return oRole:Tips("屏蔽人数已达到人上限")
		end
		if not self.m_tShieldMap[nRoleID].tRoleMap[nTarRoleID] then
			self.m_tShieldMap[nRoleID].tRoleMap[nTarRoleID] = 1
			self.m_tShieldMap[nRoleID].nCount = self.m_tShieldMap[nRoleID].nCount + 1
			self:MarkDirty(true)
			oRole:Tips("屏蔽成功")
			self:SyncShieldRoleList(oRole)
		end
	elseif nType == 2 then
		if self.m_tShieldMap[nRoleID].tRoleMap[nTarRoleID] then
			self.m_tShieldMap[nRoleID].tRoleMap[nTarRoleID] = nil
			self.m_tShieldMap[nRoleID].nCount = self.m_tShieldMap[nRoleID].nCount - 1
			self:MarkDirty(true)
			oRole:Tips("取消屏蔽成功")
			self:SyncShieldRoleList(oRole)
		end
	end
end

--屏蔽列表
function CTalk:SyncShieldRoleList(oRole)
	local tList = {}
	local nRoleID = oRole:GetID()
	local tShieldMap = self.m_tShieldMap[nRoleID] or {}
	for nTmpRoleID, v in pairs(tShieldMap.tRoleMap or {}) do
		local oTmpRole = goGPlayerMgr:GetRoleByID(nTmpRoleID)
		local tInfo = {
			nRoleID=nTmpRoleID,
			sName=oTmpRole:GetName(),
			sHeader=oTmpRole:GetHeader(),
			nSchool=oTmpRole:GetSchool(),
			nLevel=oTmpRole:GetLevel(),
			nGender=oTmpRole:GetGender(),
		}
		table.insert(tList, tInfo)
	end
	oRole:SendMsg("ShieldRoleListRet", {tList=tList})
end

--是否被对方屏蔽了
function CTalk:IsShield(oRole, nTarRoleID)
	local tShieldMap = self.m_tShieldMap[oRole:GetID()]
	if not tShieldMap then
		return
	end
	if not tShieldMap.tRoleMap or not tShieldMap.tRoleMap[nTarRoleID] then
		return
	end
	return true
end

--帮派解散
function CTalk:OnUnionDismiss(nUnionID)
	if self.m_tTalkHistory[CTalk.tChannel.eUnion] then
		if self.m_tTalkHistory[CTalk.tChannel.eUnion][nUnionID] then
			self.m_tTalkHistory[CTalk.tChannel.eUnion][nUnionID] = nil
			self:MarkDirty(true)
		end
	end
end

