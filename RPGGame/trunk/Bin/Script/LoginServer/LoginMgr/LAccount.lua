--账号模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--每个帐号创建角色上限
local nMaxAccountRole = 1
--玩家ID上限
local nMaxPlayerID = 9999999-gnBasePlayerID
--断线玩家保留时间
local nKeepObjTime = gbInnerServer and 60 or (25*60)

function CLAccount:Ctor(nServer, nSession, nID, nSource, sName)
	self.m_nID = nID
	self.m_sName = sName
	self.m_nSource = nSource
	self.m_nServer = nServer

	self.m_tRoleSummaryMap = {} 	--角色摘要信息: --{[roleid]={nCreateTime=0,nID=0,sName="",nLevel=0,tEquipment={},nLastDup=nID,nCurrDup=nID,},...}
	self.m_nLastRoleID = 0 			--最后登录的角色ID
	self.m_nAccountState = 0 		--账号状态

	--不保存
	self.m_nOnlineRoleID = 0 		--当前在线角色ID(同时只允许一个角色在线)
	self.m_nSession = nSession
	self.m_bDirty = false

	self.m_nKeepTimer = nil
	self.m_nSaveTimer = nil

	self:LoadData()
end

function CLAccount:LoadData()
	local sData = goDBMgr:GetSSDB(self:GetServer(), "user", self:GetID()):HGet(gtDBDef.sAccountDB, self:GetID())
	if sData ~= "" then
		local tData = cjson.decode(sData)
		self.m_nID = tData.m_nID
		self.m_sName = tData.m_sName
		self.m_nSource = tData.m_nSource
		self.m_nServer = tData.m_nServer
		self.m_tRoleSummaryMap = tData.m_tRoleSummaryMap
		self.m_nLastRoleID = tData.m_nLastRoleID
		self.m_nAccountState = tData.m_nAccountState or 0

		--修正旧数据
		for nRoleID, tSummary in pairs(self.m_tRoleSummaryMap) do
			if tSummary.tCurrDup then
				tSummary.nCurrDup = tSummary.tCurrDup[1]
				tSummary.tCurrDup = nil
			end
			if tSummary.tLastDup then
				tSummary.nLastDup = tSummary.tLastDup[1]
				tSummary.tLastDup = nil
			end
		end
	else
		self:MarkDirty(true)
	end
	self:RegAutoSave()
end

function CLAccount:RegAutoSave()
	self.m_nSaveTimer = goTimerMgr:Interval(gnAutoSaveTime, function() self:SaveData() end)
end

function CLAccount:SaveData()
	if not self:IsDirty() then
		return
	end

	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_sName = self.m_sName
	tData.m_nSource = self.m_nSource
	tData.m_nServer = self.m_nServer

	tData.m_tRoleSummaryMap = self.m_tRoleSummaryMap
	tData.m_nLastRoleID = self.m_nLastRoleID
	tData.m_nAccountState = self.m_nAccountState or 0

	goDBMgr:GetSSDB(self:GetServer(), "user", self:GetID()):HSet(gtDBDef.sAccountDB, self:GetID(), cjson.encode(tData)) 
	self:MarkDirty(false)
end

function CLAccount:OnRelease()
	self:SaveData()
	goTimerMgr:Clear(self.m_nKeepTimer)
	self.m_nKeepTimer = nil
	goTimerMgr:Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = nil
end

function CLAccount:IsDirty() return self.m_bDirty end
function CLAccount:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CLAccount:CheckRoleIDExist(nRoleID) 
	return self.m_tRoleSummaryMap[nRoleID] and true or false
end

function CLAccount:GetID() return self.m_nID end
function CLAccount:GetAccountID() return self.m_nID end --接口兼容
function CLAccount:GetName() return self.m_sName end
function CLAccount:GetSource() return self.m_nSource end
function CLAccount:GetServer() return self.m_nServer end
function CLAccount:GetSession() return self.m_nSession end
function CLAccount:GetOnlineRoleID() return self.m_nOnlineRoleID end
function CLAccount:BindSession(nSession) self.m_nSession = nSession end

--角色登陆成功
function CLAccount:RoleOnline(nRoleID)
	print("CLAccount:RoleOnline***", nRoleID)
	self.m_nLastRoleID = nRoleID
	self:MarkDirty(true)

	self.m_nOnlineRoleID = nRoleID
	goTimerMgr:Clear(self.m_nKeepTimer)
	self.m_nKeepTimer = nil
end

--角色释放
function CLAccount:RoleOffline()
	if self.m_nOnlineRoleID > 0 then 
		goLoginMgr:AddOnlineNum(-1)
	end
	if self.m_nKeepTimer then --角色离线后，没必要继续保持定时器，防止未及时清理泄露
		goTimerMgr:Clear(self.m_nKeepTimer)
		self.m_nKeepTimer = nil
	end
	self.m_nSession = 0
	self.m_nOnlineRoleID = 0
end

--角色断线
function CLAccount:OnDisconnect()
	goLoginMgr:GetLoginQueue():Remove(self.m_nID) --不论是否在排队都尝试删除下当前排队
	self.m_nSession = 0
	goTimerMgr:Clear(self.m_nKeepTimer)
	self.m_nKeepTimer = goTimerMgr:Interval(nKeepObjTime, function(nTimerID) goLoginMgr:AccountOffline(self:GetID()) end)
	-- goLoginMgr:AccountOffline(self:GetID())
end

--生成唯一账号/角色ID
function CLAccount:GenPlayerID()
	local oDB = goDBMgr:GetSSDB(0, "center")
	local nIncr = oDB:HIncr(gtDBDef.sPlayerIDDB, "data")
	local nPlayerID = gnBasePlayerID + nIncr % nMaxPlayerID
	return nPlayerID
end

--取角色数量
function CLAccount:GetRoleCount()
	local nCount = 0
	for nRoleID, tRole in pairs(self.m_tRoleSummaryMap) do
		nCount = nCount +1
	end
	return nCount
end

--取当前登录角色的逻辑服ID
function CLAccount:GetLogic()
	if self.m_nOnlineRoleID == 0 then
		return 0
	end

	local tSummary = self.m_tRoleSummaryMap[self.m_nOnlineRoleID]
	if not tSummary then
		return 0
	end
	local nCurrDup = tSummary.nCurrDup
	if nCurrDup > 0 then
		local nDupID = GF.GetDupID(nCurrDup)
		local tConf = ctDupConf[nDupID]
		if tConf then
			return tConf.nLogic
		end
		local nLastDup = tSummary.nLastDup
		local nDupID = GF.GetDupID(nLastDup)
		return ctDupConf[nDupID].nLogic
	end
	return 0
end

--取当前场景类型(1城镇; 2副本)
function CLAccount:GetCurrDupType()
	if self.m_nOnlineRoleID == 0 then
		return 1
	end
	local tSummary = self.m_tRoleSummaryMap[self.m_nOnlineRoleID]
	if not tSummary then
		return 1
	end
	
	local nCurrDup = tSummary.nCurrDup
	if nCurrDup > 0 then
		local nDupID = GF.GetDupID(nCurrDup)
		local tConf = ctDupConf[nDupID]
		return tConf and tConf.nType or 1
	end
	return 1
end

--飘字提示
function CLAccount:Tips(sCont, nServer, nSession)
    assert(sCont, "参数错误")
    nServer = nServer or self:GetServer()
    nSession = nSession or self:GetSession()
    CmdNet.PBSrv2Clt("TipsMsgRet", nServer, nSession, {sCont=sCont})
end

--角色列表请求
function CLAccount:RoleListReq(nServer, nSession)
	local nServer = nServer or self:GetServer()
	local nSession = nSession or self:GetSession()

	local tList = {}
	for nRoleID, tSummary in pairs(self.m_tRoleSummaryMap) do
		local nConfID = tSummary.nConfID or 1
		local tRoleConf = ctRoleInitConf[nConfID]
		local tRole = {
			nID = nRoleID,
			sName = tSummary.sName,
			nGender = tRoleConf.nGender,
			nSchool = tRoleConf.nSchool,
			nLevel = tSummary.nLevel,
			tEquipment = tSummary.tEquipment,
			sModel = tRoleConf.sModel,
		}
		table.insert(tList, tRole)
	end
	CmdNet.PBSrv2Clt("RoleListRet", nServer, nSession, {tList=tList, nAccountID=self:GetID()})
end

function CLAccount:DealLogin(nRoleID)
	if self.m_nOnlineRoleID > 0 then
		if not (self.m_nOnlineRoleID == nRoleID) then 
			return false
		end
	else
		goLoginMgr:AddOnlineNum(1)
	end
	self:RoleOnline(nRoleID)

	local tSummary = self.m_tRoleSummaryMap[nRoleID]
	local tMsg = {nAccountID=self:GetID(), nRoleID=nRoleID, nServerID=gnServerID, nCreateTime=tSummary.nCreateTime or os.time()}
	CmdNet.PBSrv2Clt("RoleLoginRet", self:GetServer(), self:GetSession(), tMsg)
	--通知逻辑服登录成功
	goRemoteCall:Call("RoleOnlineReq", self:GetServer(), self:GetLogic(), self:GetSession(), nRoleID)
	return true
end

--角色登录
function CLAccount:RoleLogin(nRoleID)
	local tSummary = self.m_tRoleSummaryMap[nRoleID]
	if not tSummary then
		self:Tips("角色不存在")
		return false
	end

	if self.m_nOnlineRoleID > 0 then
		assert(self.m_nOnlineRoleID == nRoleID, "需要先退出当前登陆角色")
		--离线保护期间重新登录，不需要排队
		if self.m_nKeepTimer then 
			goTimerMgr:Clear(self.m_nKeepTimer)
			self.m_nKeepTimer = nil
		end
		return self:DealLogin(nRoleID) 
	end
	--角色登录排队，然后离线，账号保留，此时继续登录排队，因为排队，未发生角色online，可能导致旧定时器未删除
	if self.m_nKeepTimer then 
		goTimerMgr:Clear(self.m_nKeepTimer)
		self.m_nKeepTimer = nil
	end
	if not goLoginMgr:GetLoginQueue():Insert(self:GetID(), nRoleID) then --可能排队上限
		return false
	end
	return true
end

--创建角色
function CLAccount:CreateRole(nConfID, sName, nInviteRoleID)
	print("CLAccount:CreateRole***", nConfID, sName, nInviteRoleID)
	sName = string.Trim(sName)
	local bRes, sTips = true, ""

	if string.len(sName)<=0 or string.len(sName)>gnMaxRoleNameLen then
		bRes = false
		sTips = "名字长度过长"

	elseif self.m_nOnlineRoleID > 0 then
		bRes = false
		sTips = "请先退出当前登陆角色"

	elseif self:GetRoleCount() >= nMaxAccountRole then
		bRes = false
		sTips = string.format("每个帐号只能创建%d个角色", nMaxAccountRole)
	else
		local sData = goDBMgr:GetSSDB(0, "center"):HGet(gtDBDef.sRoleNameDB, sName)
		if sData ~= "" then
			bRes = false
			sTips = "角色名已被占用"
		end
	end
	if not bRes then
		LuaTrace(sTips, sName)
		self:Tips(sTips)
		return
	end

	--保存角色数据
	local tRoleConf = assert(ctRoleInitConf[nConfID])
	local tBorn = tRoleConf.tBorn[1]
	local nRndX, nRndY = GF.RandPos(tBorn[1], tBorn[2], 10)
	local tDupConf = ctDupConf[tRoleConf.nInitDup]

	local nRoleID = self:GenPlayerID()
	local tData = {
		m_nSource = self:GetSource(),
		m_nAccountID = self:GetID(),
		m_sAccountName = self:GetName(),
		m_nCreateTime = os.time(),
		m_nID = nRoleID,
		m_nConfID = nConfID,
		m_sName = sName,
		m_nLevel = 0, 	--初始0级
		m_tLastDup = {0, 0, 0, 0},
		m_tCurrDup = {tRoleConf.nInitDup, nRndX, nRndY, tDupConf.nFace},
		m_nInviteRoleID = nInviteRoleID,
		m_bCreate = true, --是否创建新角色,给逻辑服用
	}
	goDBMgr:GetSSDB(self:GetServer(), "user", nRoleID):HSet(gtDBDef.sRoleDB, nRoleID, cjson.encode(tData))

	--生成角色摘要
	self.m_tRoleSummaryMap[nRoleID] = {
		nCreateTime = os.time(),
		nID = nRoleID,
		sName = sName,
		nLevel = 0,
		nConfID = nConfID,
		nLastDup = 0,
		nCurrDup = tRoleConf.nInitDup,
		tEquipment = {},
	}
	self:MarkDirty(true)
	self:SaveData() --马上保存下

	goDBMgr:GetSSDB(0, "center"):HSet(gtDBDef.sRoleNameDB, sName, nRoleID)
	goLogger:CreateRoleLog(self:GetID(), nRoleID, sName, 0, tRoleConf.sHeader, tRoleConf.nGender, tRoleConf.nSchool)
	return self:RoleLogin(nRoleID)
end

--更新角色摘要
function CLAccount:UpdateRoleSummary(nRoleID, tSummary)
	if not self.m_tRoleSummaryMap[nRoleID] then 
		print("角色不存在，已删除??")
		return 
	end
	self.m_tRoleSummaryMap[nRoleID] = tSummary
	self:MarkDirty(true)
end

--取账号状态
function CLAccount:GetAccountState()
	return self.m_nAccountState
end

--设置账号数据
function CLAccount:UpdateValueReq(tData)
	for key, val in pairs(tData) do
		self[key] = val
		if key == "m_nAccountState" then
			goLogger:UpdateAccountLog(self, {accountstate=val})
		end
	end
	self:MarkDirty(true)
end 

function CLAccount:DeleteRole(nRoleID) 
	assert(nRoleID > 0)
	if not self:CheckRoleIDExist(nRoleID) then 
		return 
	end
	print("开始删除角色", nRoleID)
	self.m_tRoleSummaryMap[nRoleID] = nil
	if self.m_nLastRoleID == nRoleID then 
		self.m_nLastRoleID = 0 
	end
	if self.m_nOnlineRoleID == nRoleID then 
		self.m_nOnlineRoleID = 0 
	end

	--对所有全局服广播角色删除事件
	local tGlobalServiceList = goServerMgr:GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
		if tConf.nServer == self:GetServer() or tConf.nServer == gnWorldServerID then 
			local nServer = tConf.nServer
			local nService = tConf.nID
			local fnNotifyCallback = function(bRet) 
				if not bRet then 
					LuaTrace(string.format(
						"角色删除通知AccountRoleDeleteNotify操作失败, AccountID(%d), RoleID(%d), Server(%d), Service(%d)", 
						self:GetID(), nRoleID, nServer, nService)) 
					return 
				end
			end

			goRemoteCall:CallWait("AccountRoleDeleteNotify", fnNotifyCallback, 
				nServer, nService, self:GetSession(), self:GetID(), nRoleID)
        end
	end
	self:SaveData() --主动保存下，防止rpc期间，账号下线 
end

function CLAccount:DeleteRoleReq(nRoleID)
	assert(nRoleID > 0, "参数错误")
	if not self:CheckRoleIDExist(nRoleID) then 
		self:Tips("不存在该角色，请检查角色ID")
		return
	end
	local nOldSession = self:GetSession()
	--当前，只是在账号数据中，解除角色关联，不处理角色中，关联账号的数据
	local fnCheckCallback = function(bSucc, sReason) 
		if not bSucc then
			if sReason and type(sReason) == "string" then  
				self:Tips(sReason) 
			end
			return
		end
		self:MarkDirty(true) 
		self:DeleteRole(nRoleID)
		self:Tips("请刷新页面或退出游戏，重新登录")
		goLoginMgr:OtherPlaceLogin(self:GetServer(), nOldSession, self:GetName(), 0)
	end

	--检查角色是否在线，如果在线，将角色离线
	if self:GetOnlineRoleID() == nRoleID then 
		--检查并将角色离线
		goRemoteCall:CallWait("DeleteRoleCheckReq", fnCheckCallback, 
			self:GetServer(), self:GetLogic(), self:GetSession(), nRoleID) 
	else
		self:MarkDirty(true) 
		self:DeleteRole(nRoleID)
		self:Tips("请刷新页面或退出游戏，重新登录")
		goLoginMgr:OtherPlaceLogin(self:GetServer(), nOldSession, self:GetName(), 0)
	end
end
