local function _StrField(xField)
	if not xField then
		return ""
	end
	if type(xField) == "number" then
		return tostring(xField)
	elseif type(xField) == "string" then
		return GlobalExport.EscapeString(xField)
	elseif type(xField) == "table" then
		return tostring(xField)
	end
	return xField
end

--事件日志
function Srv2Srv.EventLogReq(nSrcServer, nSrcService, nTarSession, nEventID, sReason, tInfo, ...)
	tInfo.sRoleName = _StrField(tInfo.sRoleName)
	local tField = {...}
	local sField1 = _StrField(tField[1])
	local sField2 = _StrField(tField[2])
	local sField3 = _StrField(tField[3])
	local sField4 = _StrField(tField[4])
	local sField5 = _StrField(tField[5])
	local sField6 = _StrField(tField[6])
	local nTime = assert(tField[7])

	local sSql = string.format(gtGameSql.sInsertEventLogSql
		, nEventID, sReason, tInfo.nAccountID, tInfo.nRoleID, tInfo.sRoleName, tInfo.nLevel, tInfo.nVIP
		, sField1, sField2, sField3, sField4, sField5, sField6, nTime)
	goMysqlPool:GameQuery(sSql)

	--检测作弊
	goLogMgr:CheckCheat(tInfo.nRoleID, nEventID, sField1, sField2, sReason)
end

--账号日志
function Srv2Srv.CreateAccountLogReq(nSrcServer, nSrcService, nTarSession, nSource, nAccountID, sAccountName, nVIP, nTime)
	sAccountName = _StrField(sAccountName)
	local sSql = string.format(gtGameSql.sInsertAccountSql, nSource, nAccountID, sAccountName, nVIP, nTime)
	goMysqlPool:GameQuery(sSql)
end

--角色日志
function Srv2Srv.CreateRoleLogReq(nSrcServer, nSrcService, nTarSession, nAccountID, nRoleID, sRoleName, nLevel, sImgHeader, nGender, nSchool, nTime)
	sRoleName = _StrField(sRoleName)
	local sSql = string.format(gtGameSql.sInsertRoleSql, nAccountID, nRoleID, sRoleName, nLevel, sImgHeader, nGender, nSchool, nTime)
	goMysqlPool:GameQuery(sSql)
end

--更新账号信息
function Srv2Srv.UpdateAccountLogReq(nSrcServer, nSrcService, nTarSession, nAccountID, tParam)
	local sSetSql = ""
	for k, v in pairs(tParam) do
		sSetSql = sSetSql .. string.format("%s='%s',", k, _StrField(v))
	end
	sSetSql = string.sub(sSetSql, 1, -2)
	local sSql = string.format(gtGameSql.sUpdateAccountSql, sSetSql, nAccountID)
	goMysqlPool:GameQuery(sSql)
end

--更新账号信息
function Srv2Srv.UpdateRoleLogReq(nSrcServer, nSrcService, nTarSession, nRoleID, tParam)
	local sSetSql = ""
	for k, v in pairs(tParam) do
		sSetSql = sSetSql .. string.format("%s='%s',", k, _StrField(v))
	end
	sSetSql = string.sub(sSetSql, 1, -2)
	local sSql = string.format(gtGameSql.sUpdateRoleSql, sSetSql, nRoleID)
	goMysqlPool:GameQuery(sSql)
end

--上线下线日志
function Srv2Srv.OnlineLogReq(nSrcServer, nSrcService, nTarSession, tInfo, nType, nKeepTime, nTime)
	local sql = string.format(gtGameSql.sOnlineLogSql, tInfo.nAccountID, tInfo.nRoleID, tInfo.nLevel, tInfo.nVIP, nType, nKeepTime, nTime)
	goMysqlPool:GameQuery(sql)
end

--分享日志
function Srv2Srv.ShareLogReq(nSrcServer, nSrcService, nTarSession, nSrcServer, nSrcRole, nTarServer, nTarRole, nTime)
	local sql = string.format(gtGameSql.sInsertShareSql, nSrcServer, nSrcRole, nTarServer, nTarRole, nTime)
	goMysqlPool:BackQuery(sql)

	--推广员后台
	--1.判断邀请者是不是1,2级推广员,如果不是就直接插入,没有relation关系
	local oMysql = goMysqlPool:GetSyncBackMysql()	
	local sql = string.format("select relation,level from promoter where charid=%d;", nSrcRole)
	oMysql:Query(sql)

	local sql = "insert into promoter set charid=%d,relation='%s',level=0,srcinviter=%d,srcserverid=%d,tarserverid=%d,createtime=%d,tartime=%d;"
	if not oMysql:FetchRow() or oMysql:ToInt32("level") == 0 then
		local sql = string.format(sql, nTarRole, '[]', nSrcRole, nSrcServer, nTarServer, os.time(), os.time())
		goMysqlPool:BackQuery(sql)
	--2.如果要求者是2级推广员，那么就要拼接relation关系
	else
		local tRelation = {nSrcRole}
		if oMysql:ToInt32("level") == 2 then
			local tTmp = cjson_raw.decode(oMysql:ToString("relation"))
			if #tTmp > 0 then
				table.insert(tRelation, 1, tTmp[1])
			end
		end
		local sql = string.format(sql, nTarRole, cjson_raw.encode(tRelation), nSrcRole, nSrcServer, nTarServer, os.time(), os.time())
		goMysqlPool:BackQuery(sql)
	end
end

--元宝日志
function Srv2Srv.YuanBaoLogReq(nSrcServer, nSrcService, nTarSession, tInfo, nTime)
	local sql = string.format(gtGameSql.sInsertYuanBaoSql
		, tInfo.nAccountID, tInfo.nRoleID, tInfo.nLevel, tInfo.nVIP, tInfo.nYuanBao, tInfo.nCurrYuanBao, tInfo.nBind, tInfo.sReason, nTime)
	goMysqlPool:GameQuery(sql)
end

--聊天日志
function Srv2Srv.TalkLogReq(nSrcServer, nSrcService, nTarSession, tData)
	goChatReport:AddTalk(tData)
end

--活动日志
function Srv2Srv.ActivityLogReq(nSrcServer, nSrcService, nTarSession, tData)
	local sql = string.format(gtGameSql.sInsertActLogSql
		, tData.roleid, tData.level, tData.vip
		, tData.actid, tData.acttype, tData.actname
		, tData.subactid, tData.subactname
		, cjson_raw.encode(tData.cost), cjson_raw.encode(tData.award)
		, tData.charge, tData.ext1, tData.ext2
		, os.date("%Y-%m-%d %H:%M:%S", tData.time))
	goMysqlPool:GameQuery(sql)
end

--任务日志
function Srv2Srv.TaskLogReq(nSrcServer, nSrcService, nTarSession, tInfo, nType, nTaskID, nTime)
	local sql = string.format(gtGameSql.sInsertTaskSql
		, tInfo.nAccountID, tInfo.nRoleID, tInfo.nLevel, tInfo.nVIP, nType, nTaskID, tInfo.nSchool, nTime)
	goMysqlPool:GameQuery(sql)
end


--创建帮派日志
function Srv2Srv.CreateUnionLogReq(nSrcServer, nSrcService, nTarSession, tLog)
	local sql = string.format(gtGameSql.sCreateUnionSql, tLog.nUnionID, tLog.nDisplayID, tLog.sUnionName, tLog.nUnionLevel, tLog.nLeaderID, tLog.sLeaderName, tLog.nCreateTime)
	goMysqlPool:GameQuery(sql)
end
--删除帮派
function Srv2Srv.DelUnionLogReq(nSrcServer, nSrcService, nTarSession, nUnionID)
	local sql = string.format(gtGameSql.sDelUnionSql, nUnionID)
	goMysqlPool:GameQuery(sql)
end
--更新帮派日志
function Srv2Srv.UpdateUnionLogReq(nSrcServer, nSrcService, nTarSession, nUnionID, tParam)
	local sSetSql = ""
	for k, v in pairs(tParam) do
		sSetSql = sSetSql .. string.format("%s='%s',", k, _StrField(v))
	end
	sSetSql = string.sub(sSetSql, 1, -2)
	local sql = string.format(gtGameSql.sUpdateUnionSql, sSetSql, nUnionID)
	goMysqlPool:GameQuery(sql)
end
--创建帮派成员日志
function Srv2Srv.CreateUnionMemberLogReq(nSrcServer, nSrcService, nTarSession, tLog)
	local sql = string.format(gtGameSql.sCreateUnionMemberSql, tLog.nRoleID, tLog.sRoleName, tLog.nUnionID, tLog.nPosition, tLog.nJoinTime, tLog.nLeaveTime, tLog.nCurrContri, tLog.nTotalContri, tLog.nDayContri)
	goMysqlPool:GameQuery(sql)
end
--更新帮派成员日志
function Srv2Srv.UpdateUnionMemberLogReq(nSrcServer, nSrcService, nTarSession, nRoleID, tParam)
	local sSetSql = ""
	for k, v in pairs(tParam) do
		sSetSql = sSetSql .. string.format("%s='%s',", k, _StrField(v))
	end
	sSetSql = string.sub(sSetSql, 1, -2)
	local sql = string.format(gtGameSql.sUpdateUnionMemberSql, sSetSql, nRoleID)
	goMysqlPool:GameQuery(sql)
end


---------------- CltPBProc ----------------
--玩家行为日志
function CltPBProc.RoleBehaviourReq(nCmd, nServer, nService, nSession, tData)
	do return end  --暂时屏蔽
	if not tData then 
		return 
	end
	local tLogList = tData.tBehaviourList
	local nSingleInsertNum = 10

	if #tLogList > 100 then 
		LuaTrace(string.format("nServer(%d)nService(%d)nSession(%d)玩家单次RoleBehaviourLog数据较多(%d)", 
		nServer, nService, nSession, #tLogList))
	end

	local tDML = {}
	for k, tLog in ipairs(tLogList) do 
		local sInsertSql = string.format(gtGameSql.sInsertRoleBehaviourSql, tLog.nRoleID, 
		tLog.nLevel, tLog.nBehaviourID, tLog.nTimeStamp)
		table.insert(tDML, sInsertSql)
		if #tDML >= nSingleInsertNum then 
			local sDMLList = table.concat(tDML)
			goMysqlPool:GameQuery(sDMLList)
			tDML = {}
		end
	end
	if #tDML > 0 then 
		local sDMLList = table.concat(tDML)
		goMysqlPool:GameQuery(sDMLList)
		tDML = {}
	end
end

