local function _StrField(xField)
	if not xField then
		return ""
	end
	if type(xField) == "number" then
		return tostring(xField)
	elseif type(xField) == "string" then
		return string.AddSlashes(xField)
	elseif type(xField) == "table" then
		return tostring(xField)
	end
	return xField
end

--事件日志
function Srv2Srv.EventLogReq(nSrcServer, nSrcService, nTarSession, nEventID, nReason, nAccountID, nRoleID, sRoleName, nLevel, nVIP, ...)
	sRoleName = _StrField(sRoleName)
	local tField = {...}
	local sField1 = _StrField(tField[1])
	local sField2 = _StrField(tField[2])
	local sField3 = _StrField(tField[3])
	local sField4 = _StrField(tField[4])
	local sField5 = _StrField(tField[5])
	local sField6 = _StrField(tField[6])
	local nTime = assert(tField[7])

	local sSql = string.format("call proc_log(%d, %d, %d, %d ,'%s', %d, %d,'%s','%s','%s','%s','%s', '%s', %d);"
		, nEventID, nReason, nAccountID, nRoleID, sRoleName, nLevel, nVIP, sField1, sField2, sField3, sField4, sField5, sField6, nTime)
	goMysqlPool:Query(sSql)
end

--账号日志
function Srv2Srv.CreateAccountLogReq(nSrcServer, nSrcService, nTarSession, nSource, nAccountID, sAccountName, nVIP, nTime)
	sAccountName = _StrField(sAccountName)
	local sSql = string.format(gtGameSql.sInsertAccountSql, nSource, nAccountID, sAccountName, nVIP, nTime)
	goMysqlPool:Query(sSql)
end

--角色日志
function Srv2Srv.CreateRoleLogReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID, sRoleName, nLevel, nTime)
	sRoleName = _StrField(sRoleName)
	local sSql = string.format(gtGameSql.sInsertRoleSql, nAccountID, nRoleID, sRoleName, nLevel, nTime)
	goMysqlPool:Query(sSql)
end

--更新账号信息
function Srv2Srv.UpdateAccountLogreq(nSrcServer, nSrcService, nTarSession, nAccountID, tParam)
	local sSetSql = ""
	for k, v in pairs(tParam) do
		sSetSql = sSetSql .. string.format("%s='%s',", k, _StrField(v))
	end
	sSetSql = string.sub(sSetSql, 1, -2)
	local sSql = string.format(gtGameSql.sUpdateAccountSql, sSetSql, nAccountID)
	goMysqlPool:Query(sSql)
end

--更新账号信息
function Srv2Srv.UpdateRoleLogReq(nSrcServer, nSrcService, nTarSession, nRoleID, tParam)
	local sSetSql = ""
	for k, v in pairs(tParam) do
		sSetSql = sSetSql .. string.format("%s='%s',", k, _StrField(v))
	end
	sSetSql = string.sub(sSetSql, 1, -2)
	local sSql = string.format(gtGameSql.sUpdateRoleSql, sSetSql, nRoleID)
	goMysqlPool:Query(sSql)
end
