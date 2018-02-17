--日志模块(支持世界服)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--自己服务器ID
local nServerID = gnServerID
--服务器-日志服务影射
local tServerLogMap = {}
if gtServerConf then
	for _, tConf in ipairs(gtServerConf.tLogService) do
		tServerLogMap[tConf.nServer] = tServerLogMap[tConf.nServer] or {}
		table.insert(tServerLogMap[tConf.nServer], tConf)
	end
end

function CLogger:Ctor()
end

function CLogger:_normal_log(nEventID, nReason, oRole, Field1, Field2, Field3, Field4, Field5, Field6)
	assert(nEventID and nReason)

	Field1 = Field1 or ""
	Field2 = Field2 or ""
	Field3 = Field3 or ""
	Field4 = Field4 or ""
	Field5 = Field5 or ""
	Field6 = Field6 or ""

	local nTarServer, nTarSevice = 0, 0
	local nAccountID, sAccountName, nRoleID, sRoleName, nLevel, nVIP = 0, "", 0, "", 0, 0

	if oRole then
		nTarServer = oRole:GetServer()
		nTarService = tServerLogMap[nTarServer][1].nID

		nAccountID = oRole:GetAccountID()
		sAccountName = oRole:GetAccountName()
		nRoleID = oRole:GetID()
		sRoleName = oRole:GetName()
		nLevel = oRole:GetLevel()
		nVIP = oRole:GetVIP()

		goRemoteCall:Call("EventLogReq", nTarServer, nTarService, 0
			, nEventID, nReason
			, nAccountID, nRoleID, sRoleName, nLevel, nVIP
			, Field1, Field2, Field3, Field4, Field5, Field6, os.time())
	else
		for nServerID, tLogList in pairs(tServerLogMap) do
			goRemoteCall:Call("EventLogReq", nServerID, tLogList[1].nID, 0
				, nEventID, nReason
				, nAccountID, nRoleID, sRoleName, nLevel, nVIP
				, Field1, Field2, Field3, Field4, Field5, Field6, os.time())
		end
	end
end

function CLogger:EventLog(nEventID, oRole, Field1, Field2, Field3, Field4, Field5, Field6)
	self:_normal_log(nEventID, 0, oRole, Field1, Field2, Field3, Field4, Field5, Field6)
end

function CLogger:AwardLog(nEventID, nReason, oRole, nItemType, nItemID, nItemNum, Field1, Field2, Field3)
	assert(nItemType and nItemID and nItemNum)
	self:_normal_log(nEventID, nReason, oRole, nItemType, nItemID, nItemNum, Field1, Field2, Field3)
end

function CLogger:CreateAccountLog(nSource, nAccountID, sAccountName, nVIP)
	assert(nSource and nAccountID and sAccountName and nVIP)
	--只会在本服创建账号
	assert(nServerID < 10000, "世界服不能创建账号!")
	local nLogService = tServerLogMap[nServerID][1].nID
	goRemoteCall:Call("CreateAccountLogReq", nServerID, nLogService, 0, nSource, nAccountID, sAccountName, nVIP, os.time())
end

function CLogger:CreateRoleLog(nAccountID, nRoleID, sRoleName, nLevel)
	assert(nAccountID and nRoleID and sRoleName and nLevel)
	--只会在本服创建角色
	assert(nServerID < 10000, "世界服不能创建角色!")
	local nLogService = tServerLogMap[nServerID][1].nID
	goRemoteCall:Call("CreateRoleLogReq", nServerID, nLogService, 0, nAccountID, nRoleID, sRoleName, nLevel, os.time())
end

function CLogger:UpdateAccountLog(oAccount, tParam) 
	local nAccountID = oAccount:GetID()
	local nServerID = oAccount:GetServer()
	local nLogService = tServerLogMap[nServerID][1].nID
	goRemoteCall:Call("UpdateAccountLogReq", nServerID, nLogService, 0, nAccountID, tParam)
end

function CLogger:UpdateRoleLog(oRole, tParam) 
	assert(oRole and next(tParam))
	local nRoleID = oRole:GetID()
	local nServerID = oRole:GetServer()
	local nLogService = tServerLogMap[nServerID][1].nID
	goRemoteCall:Call("UpdateRoleLogReq", nServerID, nLogService, 0, nRoleID, tParam)
end

goLogger = goLogger or CLogger:new()