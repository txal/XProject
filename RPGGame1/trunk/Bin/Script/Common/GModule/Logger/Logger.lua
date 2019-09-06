--日志模块(支持世界服)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--本地化一下,加快速度
local nServerID = GetGModule("ServerMgr"):GetServerID()
local nWorldServerID = GetGModule("ServerMgr"):GetWorldServerID()
local tItemType = gtGDef.tItemType
local tSubItemType = gtGDef.tSubItemType

function CLogger:Ctor()
	CGModuleBase.Ctor(self, gtGModuleDef.tLogger)
	self.m_tRoleInfo = {}
end

function CLogger:_GetRoleInfo(oRole)
	local tInfo = self.m_tRoleInfo
	if oRole then
		tInfo.nServerID = oRole:GetServerID()
		tInfo.nServiceID = GetGModule("ServerMgr"):GetGlobalService(tInfo.nServerID)
		tInfo.nAccountID = oRole:GetAccountID()
		tInfo.nRoleID = oRole:GetID()
		tInfo.sRoleName = oRole:GetName()
		tInfo.nSchool = oRole:GetSchool()
		tInfo.nLevel = oRole:GetLevel()
		tInfo.nVIP = oRole:GetVIP()
	else
		tInfo.nServerID = 0
		tInfo.nServiceID = 0
		tInfo.nAccountID = 0
		tInfo.nRoleID = 0
		tInfo.sRoleName = ""
		tInfo.nSchool = 0
		tInfo.nLevel = 0
		tInfo.nVIP = 0
	end
	return tInfo
end

function CLogger:_normal_log(nEventID, sReason, oRole, xField1, xField2, xField3, xField4, xField5, xField6)
	assert(nEventID and sReason)

	xField1 = xField1 or ""
	xField2 = xField2 or ""
	xField3 = xField3 or ""
	xField4 = xField4 or ""
	xField5 = xField5 or ""
	xField6 = xField6 or ""

	local tRoleInfo = self:_GetRoleInfo(oRole)
	if oRole then
		Network:RMCall("EventLogReq", nil, tInfo.nServerID, tInfo.nServiceID, 0, nEventID, sReason, tRoleInfo
			, xField1, xField2, xField3, xField4, xField5, xField6, os.time())

	else
		local oServerMgr = GetGModule("ServerMgr")
		local tGlobalServiceList = oServerMgr:GetGlobalServiceList()
		for _, tConf in pairs(tGlobalServiceList) do
			if tConf.nServerID < nWorldServerID then
				Network:RMCall("EventLogReq", nil, tConf.nServerID, tConf.nServiceID, 0, nEventID, sReason, tRoleInfo
					, xField1, xField2, xField3, xField4, xField5, xField6, os.time())
			end
		end
	end
end

--事件日志
function CLogger:EventLog(nEventID, oRole, xField1, xField2, xField3, xField4, xField5, xField6)
	assert(oRole, "参数错误")
	if nEventID == gtEvent.eOnline or nEventID == gtEvent.eOffline then --上线离线事件
		local tRoleInfo = self:_GetRoleInfo(oRole)
		local nOnlineType = nEventID == gtEvent.eOnline and 1 or 0
		Network:RMCall("OnlineLogReq", nil, tInfo.nServerID, tInfo.nServiceID, 0, tRoleInfo, nOnlineType, xField1, os.time())
		return

	elseif nEventID == gtEvent.eTask then --任务类
		local tRoleInfo = self:_GetRoleInfo(oRole)
		Network:RMCall("TaskLogReq", nil, tInfo.nServerID, tInfo.nServiceID, 0, tRoleInfo, xField1, xField2, XField3, os.time())
		return

	end
	self:_normal_log(nEventID, "", oRole, xField1, xField2, xField3, xField4, xField5, xField6)
end

--奖励日志
function CLogger:AwardLog(nEventID, sReason, oRole, nItemID, nItemNum, xField1, xField2, xField3)
	assert(sReason and nItemID and nItemNum, "参数错误")
	local tItemConf = assert(ctItemConf[nItemID], "物品不存在")
	local _tSubItemType = tSubItemType[tItemConf.nType]
	if tItemConf.nType==tItemType.eCurr and (tItemConf.nSubType==_tSubItemType.eYuanBao or tItemConf.nSubType==_tSubItemType.eBYuanBao) then
	--元宝单独日志
		assert(oRole, "参数错误")
		local tRoleInfo = self:_GetRoleInfo(oRole)
		local nYuanBao = math.abs(nItemNum)
		if nEventID == gtEvent.eSubItem then
			nYuanBao = -nYuanBao
		end
		local nCurrYuanBao = tonumber(xField1)
		local nBindFlag = tItemConf.nSubType==_tSubItemType.eBYuanBao and 1 or 0
		Network:RMCall("YuanBaoLogReq", nil, tRoleInfo.nServerID, tRoleInfo.nServiceID, 0
			, tRoleInfo, sReason, nYuanBao, nCurrYuanBao, nBindFlag, os.time())
		return
	end
	self:_normal_log(nEventID, sReason, oRole, nItemType, nItemID, nItemNum, xField1, xField2, xField3)

end

--创建账号日志
--@tAccountInfo {nSource=0, sChannel="", nAccountID=0 , sAccountName="", nVIP=0, nTime=0}
function CLogger:CreateAccountLog(tAccountInfo)
	assert(nServerID < nWorldServerID, "世界服不能创建账号!")
	local oServerMgr = GetGModule("ServerMgr")
	local nGlobalServiceID = oServerMgr:GetGlobalService(nServerID)
	Network:RMCall("CreateAccountLogReq", nil, nServerID, nGlobalServiceID, 0, tAccountInfo)
end

--更新账号数据
function CLogger:UpdateAccountLog(oAccount, tParams) 
	local nServerID = oAccount:GetServerID()
	local nAccountID = oAccounto:GetAccountID()
	local oServerMgr = GetGModule("ServerMgr")
	local nGlobalServiceID = oServerMgr:GetGlobalService(nServerID)
	Network:RMCall("UpdateAccountLogReq", nil, nServerID, nGlobalServiceID, 0, nAccountID, tParams)
end

--创建角色日志
--@tRoleInfo{nAccountID=0, nRoleID=0, sRoleName="", nLevel=0, sHeader="", nGender=0, nSchool=0, nTime=0)
function CLogger:CreateRoleLog(tRoleInfo)
	assert(nServerID < nWorldServerID, "世界服不能创建角色!")
	local oServerMgr = GetGModule("ServerMgr")
	local nGlobalServiceID = oServerMgr:GetGlobalService(nServerID)
	Network:RMCall("CreateRoleLogReq", nil, nServerID, nGlobalServiceID, 0, tRoleInfo)
end

--更新角色数据
function CLogger:UpdateRoleLog(oRole, tParams) 
	local nRoleID = oRole:GetID()
	local nServerID = oRole:GetServerID()
	local oServerMgr = GetGModule("ServerMgr")
	local nGlobalServiceID = oServerMgr:GetGlobalService(nServerID)
	Network:RMCall("UpdateRoleLogReq", nil, nServerID, nGlobalServiceID, 0, nRoleID, tParams)
end
