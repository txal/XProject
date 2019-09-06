--账号模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--帐号角色上限
local nMaxAccountRole = 1
--断线玩家保留时间
local nKeepObjTime = gbInnerServer and 60 or (25*60)

function CLAccount:Ctor(nServerID, nSessionID, nID, sName, nSource, sChannel)
	self.m_nID = nID
	self.m_sName = sName
	self.m_nSource = nSource
	self.m_sChannel = sChannel
	self.m_nServerID = nServerID

	self.m_nLastRoleID = 0 			--最后登录的角色ID
	self.m_nAccountState = 0 		--账号状态
	self.m_tSimpleRoleMap = {} 		--简单角色信息

	--不保存
	self.m_nOnlineRoleID = 0 		--当前在线角色ID(同时只允许一个角色在线)
	self.m_nSessionID = nSessionID
	self.m_bReleased = false
	self.m_bDirty = false
	self.m_nSaveTimer = nil
	self.m_nKeepTimer = nil
	self:LoadData()
end

function CLAccount:LoadData()
	local oDB = GetGModule("DBMgr"):GetGameDB(self:GetServerID(), "user", self:GetID())
	local sData = oDB:HGet(gtDBDef.sAccountDB, self:GetID())
	if sData == "" then
		self:MarkDirty(true)
	else
		local tData = cseri.decode(sData)
		self.m_nID = tData.m_nID
		self.m_sName = tData.m_sName
		self.m_nSource = tData.m_nSource
		self.m_sChannel = tData.m_sChannel
		self.m_nServerID = tData.m_nServerID
		self.m_nLastRoleID = tData.m_nLastRoleID
		self.m_nAccountState = tData.m_nAccountState

		for nRoleID, tRoleData in pairs(tData.m_tSimpleRoleMap) do
			local oSimpleRole = CSimpleRole:new()
			oSimpleRole:LoadData(tRoleData)
			self.m_tSimpleRoleMap[nRoleID] = oSimpleRole
		end
	end
	self:RegAutoSave()
end

function CLAccount:RegAutoSave()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = GetGModule("TimerMgr"):Interval(gtGDef.tConst.nAutoSaveTime, function() self:SaveData() end)
end

function CLAccount:SaveData()
	if not self:IsDirty() then
		return
	end

	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_sName = self.m_sName
	tData.m_nSource = self.m_nSource
	tData.m_sChannel = self.m_sChannel
	tData.m_nServerID = self.m_nServerID
	tData.m_nLastRoleID = self.m_nLastRoleID
	tData.m_nAccountState = self.m_nAccountState
	tData.m_tSimpleRoleMap = {}

	for nRoleID, oSimpleRole in pairs(self.m_tSimpleRoleMap) do
		local tRoleData = oSimpleRole:SaveData()
		tData.m_tSimpleRoleMap[nRoleID] = tRoleData
	end

	GetGModule("TimerMgr"):GetGameDB(self:GetServerID(), "user", self:GetID()):HSet(gtDBDef.sAccountDB, self:GetID(), cseri.encode(tData)) 
	self:MarkDirty(false)
end

function CLAccount:Release()
	self.m_bReleased = true
	self:SaveData()
	GetGModule("TimerMgr"):Clear(self.m_nSaveTimer)
	self.m_nSaveTimer = nil
	GetGModule("TimerMgr"):Clear(self.m_nKeepTimer)
	self.m_nKeepTimer = nil
end

function CLAccount:IsDirty() return self.m_bDirty end
function CLAccount:MarkDirty(bDirty) self.m_bDirty = bDirty end
function CLAccount:GetSimpleRole(nRoleID) return self.m_tSimpleRoleMap[nRoleID] end

function CLAccount:GetID() return self.m_nID end
function CLAccount:GetAccountID() return self.m_nID end --接口兼容
function CLAccount:GetName() return self.m_sName end
function CLAccount:GetSource() return self.m_nSource end
function CLAccount:GetChannel() return self.m_sChannel end
function CLAccount:GetServerID() return self.m_nServerID end
function CLAccount:GetSessionID() return self.m_nSessionID end
function CLAccount:GetOnlineRoleID() return self.m_nOnlineRoleID end
function CLAccount:BindSession(nSessionID) self.m_nSessionID = nSessionID end
function CLAccount:IsReleased() return self.m_bReleased then

--角色登陆
function CLAccount:RoleOnline(nRoleID)
	self.m_nLastRoleID = nRoleID
	self:MarkDirty(true)

	self.m_nOnlineRoleID = nRoleID
	GetGModule("TimerMgr"):Clear(self.m_nKeepTimer)
	self.m_nKeepTimer = nil
end

--角色释放
function CLAccount:RoleOffline()
	if self.m_nOnlineRoleID > 0 then 
		goLoginMgr:AddOnlineNum(-1)
	end
	if self.m_nKeepTimer then --角色离线后，没必要继续保持定时器，防止未及时清理泄露
		GetGModule("TimerMgr"):Clear(self.m_nKeepTimer)
		self.m_nKeepTimer = nil
	end
	self.m_nSessionID = 0
	self.m_nOnlineRoleID = 0
end

--角色断线
function CLAccount:OnDisconnect()
	self.m_nSessionID = 0
	GetGModule("TimerMgr"):Clear(self.m_nKeepTimer)
	self.m_nKeepTimer = GetGModule("TimerMgr"):Interval(nKeepObjTime, function(nTimerID) GetGModule("LoginMgr"):AccountOffline(self:GetID()) end)
	GetGModule("LoginMgr"):GetLoginQueue():Remove(self:GetID()) --不论是否在排队都尝试删除下当前排队
end

--取角色数量
function CLAccount:GetRoleCount()
	local nCount = 0
	for nRoleID, oRole in pairs(self.m_tSimpleRoleMap) do
		nCount = nCount +1
	end
	return nCount
end

--取当前登录角色的逻辑服ID
function CLAccount:GetLogicServiceID()
	if self.m_nOnlineRoleID == 0 then
		return 0
	end
	local oSimpleRole = self:GetSimpleRole(self.m_nOnlineRoleID)
	if not oSimpleRole then
		return 0
	end
	return oSimpleRole:GetLogicServiceID()
end

--取当前场景类型
function CLAccount:GetCurrSceneType()
	if self.m_nOnlineRoleID == 0 then
		return 0
	end
	local oSimpleRole = self:GetSimpleRole(self.m_nOnlineRoleID)
	if not oSimpleRole then
		return 0
	end
	return oSimpleRole:GetCurrSceneType()
end

function CLAccount:SendMsg(sCmd, tMsg, nServerID, nSessionID)
    nServerID = nServerID or self:GetServerID()
    nSessionID = nSessionID or self:GetSessionID()
    if nServerID <= 0 or nSessionID <= 0 then
    	return
    end
    assert(nServerID < GetGModule("ServerMgr"):GetWorldServerID(), "服务器ID错了")
    Network.PBSrv2Clt(sCmd, nServerID, nSessionID, tMsg)
end

--飘字提示
function CLAccount:Tips(sCont, nServerID, nSessionID)
    assert(sCont, "参数错误")
    self:SendMsg("FloatTipsRet", {sCont=sCont}, nServerID, nSessionID)
end

--角色列表请求
function CLAccount:RoleListReq(nServerID, nSessionID)
	local nServerID = nServerID or self:GetServerID()
	local nSessionID = nSessionID or self:GetSessionID()

	local tList = {}
	for nRoleID, oSimpleRole in pairs(self.m_tSimpleRoleMap) do
		local tRoleConf = oSimpleRole:GetRoleConf()
		local tRole = {
			nID = nRoleID,
			sName = oSimpleRole:GetName(),
			nLevel = oSimpleRole:GetLevel(),
			nGender = tRoleConf.nGender,
			nSchool = tRoleConf.nSchool,
		}
		table.insert(tList, tRole)
	end
	self:SendMsg("RoleListRet", {nAccountID=self:GetID(), tList=tList}, nServerID, nSessionID)
end

function CLAccount:DealLogin(nRoleID)
	if self.m_nOnlineRoleID > 0 then
		if not (self.m_nOnlineRoleID == nRoleID) then 
			return false
		end
	else
		GetGModule("LoginMgr"):AddOnlineNum(1)
	end
	self:RoleOnline(nRoleID)

	local oSimpleRole = self:GetSimpleRole(nRoleID)
	local tMsg = {nAccountID=self:GetID(), nRoleID=nRoleID, nServerID=gnServerID, nCreateTime=oSimpleRole:GetCreateTime()}
	self:SendMsg("RoleLoginRet", tMsg)
	--通知逻辑服登录成功
	Network:RMCall("RoleOnlineReq", nil, self:GetServerID(), self:GetLogicServiceID(), 0, nRoleID)
	return true
end

--角色登录
function CLAccount:RoleLogin(nRoleID)
	local oSimpleRole = self:GetSimpleRole(nRoleID)
	if not oSimpleRole then
		self:Tips("角色不存在")
		return false
	end

	if self.m_nOnlineRoleID > 0 then
		assert(self.m_nOnlineRoleID == nRoleID, "要先退出当前登陆角色")
		--离线保护期间重新登录，不需要排队
		if self.m_nKeepTimer then 
			GetGModule("TimerMgr"):Clear(self.m_nKeepTimer)
			self.m_nKeepTimer = nil
		end
		return self:DealLogin(nRoleID) 
	end
	--角色登录排队，然后离线，账号保留，此时继续登录排队，因为排队，未发生角色online，可能导致旧定时器未删除
	if self.m_nKeepTimer then 
		GetGModule("TimerMgr"):Clear(self.m_nKeepTimer)
		self.m_nKeepTimer = nil
	end
	if not GetGModule("LoginMgr"):GetLoginQueue():Insert(self:GetID(), nRoleID) then --可能排队上限
		return false
	end
	return true
end

--是否重名
function CLAccount:IsRoleNameExist(sRoleName)
	local sData = GetGModule("DBMgr"):GetGameDB(0, "center"):HGet(gtDBDef.sRoleNameDB, sRoleName)
	return (sData ~= "")
end

--创建角色
function CLAccount:CreateRole(nConfID, sRoleName)
	if self.m_bCreatingRole then
		return self:Tips("正在创建角色中,请稍后")
	end
	sRoleName = string.Trim(sRoleName)
	local nNameLen = string.len(sRoleName)

	local bRes, sTips = true, ""
	if sNameLen<=0 or sNameLen>gtGDef.tConst.nMaxRoleNameLen then
		bRes = false
		sTips = "角色名字长度过长"

	elseif self.m_nOnlineRoleID > 0 then
		bRes = false
		sTips = "请先退出当前登陆角色"

	elseif self:GetRoleCount() >= nMaxAccountRole then
		bRes = false
		sTips = string.format("每个帐号只能创建%d个角色", nMaxAccountRole)

	elseif self:IsRoleNameExist(sRoleName) then
		bRes = false
		sTips = "角色名已被占用"

	end

	if not bRes then
		LuaTrace("创建角色失败:", sRoleName, sTips)
		self:Tips(sTips)
		return
	end

	--保存角色数据
	local tRoleConf = assert(ctRoleConf[nConfID], "角色配置不存在:"..nConfID)
	local tDupConf = assert(ctDupConf[tRoleConf.nInitDupID], "初始副本配置不存在")
	local tSceneConf = assert(ctSceneConf[tRoleConf.nInitSceneID], "初始场景配置不存在")
	local nPosX, nPosY = table.unpack(tSceneConf.tBornPos[1])
	local nRndBornX, nRndBornY = CUtil:RandPos(nPosX, nPosY, 10)
	local nInitFace = tSceneConf.nInitFace
	self.m_bCreatingRole = true 

	Network:RMCall("QueryCityByDupConfIDReq", function(tDupSceneInfo)
		self.m_bCreatingRole = false
		if self:IsReleased() then
			return
		end
		if not tDupSceneInfo then
			return self:Tips("查询城镇信息失败")
		end

		local nRoleID = CUtil:GenUUID()
		--生成角色初始数据
		local tData = {
			m_nSource = self:GetSource(),
			m_sChannel = self:GetChannel(),
			m_nCreateTime = os.time(),
			m_nObjID = nRoleID,
			m_nConfID = nConfID,
			m_nObjType = gtGDef.tObjType.eRole,
			m_nAccountID = self:GetID(),
			m_sAccountName = self:GetName(),
			m_sRoleName = sRoleName,
			m_nLevel = tRoleConf.nInitLevel,
			m_bCreateRole = true, --是否创建新角色,给逻辑服用
			m_tCurrSceneInfo = {
				nDupID = tDupSceneInfo.nDupID,
				nSceneID = tDupSceneInfo.tSceneList[1],
				nPosX = nRandBornX,
				nPosY = nRandBornY,
				nLine = -1,
				nFace = nInitFace,
			},
			m_tLastSceneInfo = {
				nDupID = 0,
				nSceneID = 0,
				nPosX = 0,
				nPosY = 0,
				nLine = -1,
				nFace = 0,
			},
		}
		GetGModule("DBMgr"):GetGameDB(self:GetServerID(), "user", nRoleID):HSet(gtDBDef.sRoleDB, nRoleID, cseri.encode(tData))

		--生成简版角色数据
		local oSimpleRole = CSimpleRole:new(nRoleID, tRoleConf.nInitLevel, sRoleName, tData.m_tCurrSceneInfo, tData.m_tLastSceneInfo)
		self.m_tSimpleRoleMap[nRoleID] = oSimpleRole
		self:MarkDirty(true)
		self:SaveData()

		--记录角色名字到角色ID映射
		GetGModule("DBMgr"):GetGameDB(0, "center"):HSet(gtDBDef.sRoleNameDB, sRoleName, nRoleID)

		--日志
		local tRoleInfo = {
			nAccountID = nAccountID,
			nRoleID = nRoleID,
			sRoleName = sRoleName,
			nLevel = nLevel,
			sHeader = sHeader,
			nGender = nGender,
			nSchool = nSchool,
			os.time(),
		}
		GetGModule("Logger"):CreateRoleLog(tRoleInfo)
		return self:RoleLogin(nRoleID)

	end, CUtil:GetServerByLogic(tDupConf.nLogicServiceID), tDupConf.nLogicServiceID, 0)
end

--更新简单角色
function CLAccount:UpdateSimpleRoleData(nRoleID, tData)
	local oSimpleRole = self:GetSimpleRole(nRoleID)
	if not oSimpleRole then 
		return LuaTrace("CLAccount:UpdateSimpleRole: 角色不存在，已删除??")
	end
	oSimpleRole:UpdateData(tData)
	self:MarkDirty(true)
end

--取账号状态
function CLAccount:GetAccountState()
	return self.m_nAccountState
end

--设置账号数据
function CLAccount:UpdateAccountData(tData)
	for key, val in pairs(tData) do
		self[key] = val
		if key == "m_nAccountState" then
			GetGModule("Logger"):UpdateAccountLog(self, {accountstate=val})
		end
	end
	self:MarkDirty(true)
end 

function CLAccount:DeleteRole(nRoleID) 
	assert(nRoleID > 0)
	if not self:GetSimpleRole(nRoleID) then 
		return 
	end
	print("开始删除角色", nRoleID)
	self.m_tSimpleRoleMap[nRoleID] = nil
	if self.m_nLastRoleID == nRoleID then 
		self.m_nLastRoleID = 0 
	end
	if self.m_nOnlineRoleID == nRoleID then 
		self.m_nOnlineRoleID = 0 
	end

	--对所有全局服广播角色删除事件
	local tGlobalServiceList = GetGModule("ServerMgr"):GetGlobalServiceList()
    for _, tConf in pairs(tGlobalServiceList) do
		local nServerID = tConf.nServerID
		local nServiceID = tConf.nServiceID
		local fnNotifyCallback = function(bRet) 
			if not bRet then 
				LuaTrace(string.format("角色删除通知AccountRoleDeleteNotify操作失败, AccountID(%d), RoleID(%d), Server(%d), Service(%d)",
					self:GetID(), nRoleID, nServerID, nService)) 
				return 
			end
		end
		Network:RMCall("AccountRoleDeleteNotify", fnNotifyCallback, nServerID, nServiceID, self:GetSessionID(), self:GetID(), nRoleID)
	end
	self:SaveData() --主动保存下，防止rpc期间，账号下线 
end

function CLAccount:DeleteRoleReq(nRoleID)
	assert(nRoleID > 0, "参数错误")
	if not self:GetSimpleRole(nRoleID) then 
		return self:Tips("不存在该角色，请检查角色ID")
	end
	local nOldSession = self:GetSessionID()
	--当前，只是在账号数据中，解除角色关联，不处理角色中，关联账号的数据
	local fnCheckCallback = function(bSucc, sReason) 
		if not bSucc and sReason then
			return self:Tips(sReason)
		end
		self:MarkDirty(true) 
		self:DeleteRole(nRoleID)
		self:Tips("请刷新页面或退出游戏，重新登录")
		GetGModule("LoginMgr"):OtherPlaceLogin(self:GetServerID(), nOldSession)
	end

	--检查角色是否在线，如果在线，将角色离线
	if self:GetOnlineRoleID() == nRoleID then 
		--检查并将角色离线
		Network:RMCall("DeleteRoleCheckReq", fnCheckCallback, self:GetServerID(), self:GetLogicServiceID(), self:GetSessionID(), nRoleID)
	else
		self:MarkDirty(true) 
		self:DeleteRole(nRoleID)
		GetGModule("LoginMgr"):OtherPlaceLogin(self:GetServerID(), nOldSession)
		self:Tips("请刷新页面或退出游戏，重新登录")
	end
end
