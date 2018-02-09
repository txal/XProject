--账号模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--每个帐号创建角色上限
local nMaxAccountRole = 3
--玩家ID上限
local nMaxPlayerID = 9999999-nBASE_PLAYERID

function CLAccount:Ctor(nID, nServer, nSession, nSource, sName)
	self.m_nID = nID
	self.m_sName = sName
	self.m_nSource = nSource
	self.m_nServer = nServer

	self.m_tRoleSummaryMap = {} 	--角色摘要信息:{[roleid]={nID=0,sName="",nLevel=0,nGender=0,nSchool=0,tEquipment={},},...}
	self.m_nLastRoleID = 0 			--最后登录的角色ID
	self.m_nOnlineRoleID = 0 		--当前在线角色ID(同时只允许一个角色在线)

	--不保存
	self.m_nSession = nSession

end

function CLAccount:LoadData()
	local sData = goDBMgr:GetSSDB(self:GetServer(), "user", self:GetID()):HGet(gtDBDef.sAccountDB, self:GetID())
	if sData then
		local tData = cjson.decode(sData)
		self.m_tRoleSummaryMap = tData.m_tRoleSummaryMap
		self.m_nLastRoleID = tData.m_nLastRoleID
		self.m_nOnlineRoleID = tData.m_nOnlineRoleID
	end
end

function CLAccount:SaveData()
	local tData = {}
	tData.m_tRoleSummaryMap = self.m_tRoleSummaryMap
	tData.m_nLastRoleID = self.m_nLastRoleID
	tData.m_nOnlineRoleID = self.m_nOnlineRoleID

	goDBMgr:GetSSDB(self:GetServer(), "user", self:GetID()):HSet(gtDBDef.sAccountDB, self:GetID(), cjson.encode(tData)) 
end

function CLAccount:GetID() return self.m_nID end
function CLAccount:GetName() return self.m_sName end
function CLAccount:GetSource() return self.m_nScoure end
function CLAccount:GetServer() return self.m_nServer end
function CLAccount:GetSession() return self.m_nSession end
function CLAccount:GetOnlineRoleID() return self.m_nOnlineRoleID end

--角色登陆成功
function CLAccount:OnRoleOnline(nRoleID)
	self.m_nLastRoleID = nRoleID
	self.m_nOnlineRoleID = nRoleID
	self:SaveData()
end

--角色离线成功
function CLAccount:OnRoleOffline(nRoleID)
	self.m_nOnlineRoleID = 0
	self:SaveData()
end

--生成唯一账号/角色ID
function CLAccount:GenPlayerID()
	local nIncr = goDBMgr:GetSSDB(0, "center"):HIncr(gtDBDef.sPlayerIDDB, "data")
	local nPlayerID = nBASE_PLAYERID + nIncr % nMaxPlayerID
	return nPlayerID
end

--取角色数量
function CLAccount:GetRoleCount()
	local nCount = 0
	for nRoleID, v in pairs(self.m_tRoleSummaryMap) do
		nCount = nCount +1
	end
	return nCount
end

--飘字提示
function CLAccount:Tips(sCont, nServer, nSession)
    assert(sCont, "参数错误")
    nServer = nServer or self:GetServer()
    nSession = nSession or self:GetSession()
    CmdNet.PBSrv2Clt("TipsMsgRet", nServer, nSession, {sCont=sCont})
end

--角色登录
function CLAccount:RoleLogin(nRoleID)
	local tSummary = self.m_tRoleSummaryMap[nRoleID]
	if not tSummary then
		return self:Tips("角色不存在")
	end

	if self.m_nOnlineRoleID > 0 then
		assert(self.m_oOnlineRoleID == nRoleID, "角色登录冲突")
		return CmdNet.PBSrv2Clt("LoginRet", self:GetServer(), self:GetSession(), {nServerID=self:GetServer()})
	end
	--通知逻辑服 fix pd
end

--创建角色
function CLAccount:CreateRole(sName, nGender, nSchool)
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

	local nRoleID = self:GenPlayerID()
	local tData = {m_nID=nRoleID, m_sName=sName, m_nLevel=1, m_nGender=nGender, m_nSchool=nSchool,}
	goDBMgr:GetSSDB(self:GetServer(), "user", nRoleID):HSet(gtDBDef.sRoleDB, nRoleID, cjson_encode(tData))

	self.m_tRoleSummaryMap[nRoleID] = {nID=nRoleID, sName=sName, nLevel=1, nGender=nGender, nSchool=nSchool, tEquipment={},}
	self:SaveData()

	self:RoleLogin(nRoleID)
end

--删除角色
function CLAccount:DeleteRole(nID)
end

--角色列表请求
function CLAccount:RoleListReq()
	if self.m_nOnlineRoleID > 0 then
		return self:Tips("需要先退出当前登陆角色")
	end
	local tList = {}
	for nRoleID, tSummary in pairs(self.m_tRoleSummaryMap) do
		local tRole = {nID=nRoleID, sName=tSummary.sName, nGender=tSummary.nGender, nSchool=tSummary.nSchool, nLevel=tSummary.nLevel}
		table.insert(tList, tRole)
	end
	CmdNet.PBSrv2Clt("RoleListRet", self:GetServer(), self:GetSession(), {tList=tList})
end