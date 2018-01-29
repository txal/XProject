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

function Srv2Srv.EventLog(nSrc, nSession, nEventID, nReason, nCharID, sCharName, nLevel, nVIP, ...)
	print("EventLog***", nEventID)
	sCharName = _StrField(sCharName)

	local tField = {...}
	local sField1 = _StrField(tField[1])
	local sField2 = _StrField(tField[2])
	local sField3 = _StrField(tField[3])
	local sField4 = _StrField(tField[4])
	local sField5 = _StrField(tField[5])
	local sField6 = _StrField(tField[6])
	local nTime = assert(tField[7])

	local sSql = string.format("call proc_log(%d, '%s','%s','%s',%d, %d,'%s','%s','%s','%s','%s','%s', %d);", nEventID, nReason, nCharID, sCharName, nLevel, nVIP
		, sField1, sField2, sField3, sField4, sField5, sField6, nTime)
	goMysqlPool:Query(sSql)
end

function Srv2Srv.CreateAccountLog(nSrc, nSession, sAccount, nCharID, sCharName, nSource, nTime)
	print("CreateAccountLog***", sAccount)
	sCharName = _StrField(sCharName)
	local sSql = string.format("call proc_account('%s','%s','%s', %d, %d);", sAccount, nCharID, sCharName, nSource, nTime)
	goMysqlPool:Query(sSql)
end

function Srv2Srv.UpdateAccountLog(nSrc, nSession, nCharID, tParam)
	print("UpdateAccountLog***", nCharID)
	local sSql = "update account set %s where char_id='%s';"
	local sSet = ""
	for k, v in pairs(tParam) do sSet = sSet .. string.format("%s='%s',", k, _StrField(v)) end
	sSet = string.sub(sSet, 1, -2)
	sSql = string.format(sSql, sSet, nCharID)
	goMysqlPool:Query(sSql)
end

function Srv2Srv.RankingLog(nSrc, nSession, nCharID, sCharName, nVIP, nRankID, nRankVal, nRecharge)
	print("RankingLog***", sCharName, nRankID, nRankVal)
	sCharName = _StrField(sCharName)
	local sSql = string.format("call proc_ranking('%s','%s', %d, %d, %d, %d, %d);"
		, nCharID, sCharName, nRankID, nRankVal, nVIP, nRecharge, os.time())
	goMysqlPool:Query(sSql)
end
