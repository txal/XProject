local function _StrField(xField)
	if not xField then
		return ""
	end
	if type(xField) == "number" then
		return tostring(xField)
	end
	return xField
end

function Srv2Srv.EventLog(nSrc, nSession, nEventID, nReason, nCharID, sCharName, nLevel, nVIP, ...)
	local tField = {...}
	local sField1 = _StrField(tField[1])
	local sField2 = _StrField(tField[2])
	local sField3 = _StrField(tField[3])
	local sField4 = _StrField(tField[4])
	local sField5 = _StrField(tField[5])
	local sField6 = _StrField(tField[6])
	local nTime = assert(tField[7])
	local sSql = string.format("call proc_log(%d, %d,'%s','%s',%d, %d,'%s','%s','%s','%s','%s','%s', %d);"
		, nEventID, nReason, nCharID, sCharName, nLevel, nVIP, sField1, sField2, sField3, sField4, sField5, sField6, nTime)
	goMysqlPool:Query(sSql)
end

function Srv2Srv.CreateAccountLog(nSrc, nSession, sAccount, nCharID, sCharName, nRoleID, nTime)
	local sSql = string.format("call proc_account('%s','%s','%s', %d, %d);", sAccount, nCharID, sCharName, nRoleID, nTime)
	goMysqlPool:Query(sSql)
end