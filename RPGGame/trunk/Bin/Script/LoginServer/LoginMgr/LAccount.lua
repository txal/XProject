--账号模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--每个帐号创建角色上限
local nMaxAccountRole = 3
--玩家ID上限
local nMaxPlayerID = 9999999-nBASE_PLAYERID

function CLAccount:Ctor(nServer, nSession, nID, nSource, sName)
	self.m_nID = nID
	self.m_sName = sName
	self.m_nSource = nSource
	self.m_nServer = nServer

	self.m_tRoleSummaryMap = {} 	--角色摘要信息:{[roleid]={nCreateTime=0,nID=0,sName="",nLevel=0,nGender=0,nSchool=0,tEquipment={},tLastDup={nID,nX,nY},tCurrDup={nID,nX,nY}},...}
	self.m_nLastRoleID = 0 			--最后登录的角色ID
	self.m_nVIP = 0

	--不保存
	self.m_nOnlineRoleID = 0 		--当前在线角色ID(同时只允许一个角色在线)
	self.m_nSession = nSession

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
		self.m_nVIP = tData.m_nVIP or 0
	else
		self:SaveData()
	end
end

function CLAccount:SaveData()
	local tData = {}
	tData.m_nID = self.m_nID
	tData.m_sName = self.m_sName
	tData.m_nSource = self.m_nSource
	tData.m_nServer = self.m_nServer

	tData.m_tRoleSummaryMap = self.m_tRoleSummaryMap
	tData.m_nLastRoleID = self.m_nLastRoleID
	tData.m_nVIP = self.m_nVIP

	goDBMgr:GetSSDB(self:GetServer(), "user", self:GetID()):HSet(gtDBDef.sAccountDB, self:GetID(), cjson.encode(tData)) 
end

function CLAccount:GetID() return self.m_nID end
function CLAccount:GetName() return self.m_sName end
function CLAccount:GetSource() return self.m_nScoure end
function CLAccount:GetServer() return self.m_nServer end
function CLAccount:GetSession() return self.m_nSession end
function CLAccount:GetOnlineRoleID() return self.m_nOnlineRoleID end
function CLAccount:BindSession(nSession) return self.m_nSession = nSession end

--角色登陆成功
function CLAccount:RoleOnline(nRoleID)
	print("CLAccount:RoleOnline***", nRoleID)
	self.m_nLastRoleID = nRoleID
	self:SaveData()

	self.m_nOnlineRoleID = nRoleID
end

--角色离线成功
function CLAccount:RoleOffline()
	print("CLAccount:RoleOffline***", self:GetName())
	self.m_nSession = 0
	self.m_nOnlineRoleID = 0
end

--生成唯一账号/角色ID
function CLAccount:GenPlayerID()
	local oDB = goDBMgr:GetSSDB(0, "center")
	local nIncr = oDB:HIncr(gtDBDef.sPlayerIDDB, "data")
	local nPlayerID = nBASE_PLAYERID + nIncr % nMaxPlayerID
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
	local tCurrDup = tSummary.tCurrDup
	if tCurrDup[1] > 0 then
		local nDupID = GF.GetDupID(tCurrDup[1])
		local tConf = ctDupConf[nDupID]
		if tConf then
			return tConf.nLogic
		end
		local tLastDup = tSummary.tLastDup
		local nDupID = GF.GetDupID(tLastDup[1])
		return ctDupConf[nDupID].nLogic
	end
	return 0
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
		local tRole = {
			nID = nRoleID,
			sName = tSummary.sName,
			nGender = tSummary.nGender,
			nSchool = tSummary.nSchool,
			nLevel = tSummary.nLevel,
			tEquipment = tSummary.tEquipment,
		}
		table.insert(tList, tRole)
	end
	CmdNet.PBSrv2Clt("RoleListRet", nServer, nSession, {tList=tList, nAccountID=self:GetID()})
end

--角色登录
function CLAccount:RoleLogin(nRoleID)
	local tSummary = self.m_tRoleSummaryMap[nRoleID]
	if not tSummary then
		return self:Tips("角色不存在")
	end

	if self.m_nOnlineRoleID > 0 then
		assert(self.m_nOnlineRoleID == nRoleID, "需要先退出当前登陆角色")
	end
	
	self:RoleOnline(nRoleID)
	CmdNet.PBSrv2Clt("RoleLoginRet", self:GetServer(), self:GetSession(), {nAccountID=self:GetID(), nRoleID=nRoleID})

	--通知逻辑服登录成功
	goRemoteCall:Call("RoleOnlineReq", self:GetServer(), self:GetLogic(), self:GetSession(), self:GetID(), nRoleID) 
	return true
end

--创建角色
function CLAccount:CreateRole(nConfID, sName)
	print("CLAccount:CreateRole***", nConfID, sName)

	local tRoleConf = assert(ctRoleInitConf[nConfID])

	if self.m_nOnlineRoleID > 0 then
		return self:Tips("需要先退出当前登陆角色")
	end
	if self:GetRoleCount() >= nMaxAccountRole then
		return CRole:Tips("每个帐号只能创建三个角色")
	end
	local sData = goDBMgr:GetSSDB(self:GetServer(), "global"):HGet(gtDBDef.sRoleNameDB, sName)
	if sData ~= "" then
		return CRole:Tips("角色名已被占用")
	end

	local tBorn = tRoleConf.tBorn[1]
	--保存角色数据
	local nRoleID = self:GenPlayerID()
	local tData = {
		m_nCreateTime = os.time(),
		m_nID = nRoleID,
		m_sName = sName,
		m_nLevel = 1,
		m_nGender = tRoleConf.nGender,
		m_nSchool = tRoleConf.nSchool,
		m_tLastDup = {0, 0, 0},
		m_tCurrDup = {tRoleConf.nInitDup, tBorn[1], tBorn[2]},
	}
	goDBMgr:GetSSDB(self:GetServer(), "user", nRoleID):HSet(gtDBDef.sRoleDB, nRoleID, cjson.encode(tData))

	--生成角色摘要
	self.m_tRoleSummaryMap[nRoleID] = {
		nCreateTime = os.time(),
		nID = nRoleID,
		sName = sName,
		nLevel = 1,
		tEquipment = {},
		nGender = tRoleConf.nGender,
		nSchool = tRoleConf.nSchool,
		tLastDup = {0, 0, 0},
		tCurrDup = {tRoleConf.nInitDup, tBorn[1], tBorn[2]},
	}

	self:SaveData()
	return self:RoleLogin(nRoleID)
end

--删除角色
function CLAccount:DeleteRole(nID)
end
