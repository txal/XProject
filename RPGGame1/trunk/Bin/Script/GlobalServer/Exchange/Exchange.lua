--礼包兑换
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--类型
CExchange.tType = {
	eDuoRenYiKey = 1, 	--多人一KEY
	eYiRenDuoKey = 2, 	--一人多KEY
	eYiRenYiKey = 3, 	--一人一KEY
}

function CExchange:Ctor()
end

function CExchange:Init()
	self.m_oMgrMysql = MysqlDriver:new()
	
	local tConf = gtMgrMysqlConf
	local bRes = self.m_self.m_oMgrMysql:Connect(tConf.sIP, tConf.nPort, tConf.sDBName, tConf.sUserName, tConf.sPassword, "utf8")
	assert(bRes, "连接数据库失败", tConf)
	LuaTrace("连接数据库成功", tConf)
end

function CExchange:LoadData()
end

function CExchange:SaveData()
end

function CExchange:Release()
end

--兑换
function CExchange:ExchangeReq(oRole, sCDKey)
	local nRoleID = oRole:GetID()

	local sSql = "select server,charlist,type,starttime,endtime,award from cdkeycode,cdkeytype where cdkeycode.id=cdkeytype.id and `key`='%s';"
	sSql = string.format(sSql, sCDKey)
	if not self.m_oMgrMysql:Query(sSql) then
		return oRole:Tips("查询兑换码失败")	
	end
	if not self.m_oMgrMysql:FetchRow() then
		return oRole:Tips("兑换码不存在")	
	end
	local nServer, nType, nStartTime, nEndTime = self.m_oMgrMysql:ToInt32("server", "type", "starttime", "endtime")
	local sRoleList, sAward = self.m_oMgrMysql:ToString("rolelist", "award")
	if nServer > 0 and nServer ~= gnServerID then 
		return oRole:Tips("兑换码在该服无效")
	end

	--类型列表
	local tTypeList = {}
	for k, v in pairs(CExchange.tType) do
		table.insert(tTypeList, v)
	end
	if not table.InArray(nType, tTypeList) then
		return oRole:Tips("兑换码类型错误")
	end

	local nTimeNow = os.time()
	if nTimeNow < nStartTime or nTimeNow >= nEndTime then
		return oRole:Tips("兑换码已过期")
	end

	local tAward = cseri.decode(sAward)
	if #tAward <= 0 then
		return oRole:Tips("礼包奖励不存在")
	end

	local tRoleList = cseri.decode(sRoleList)
	if nType == self.tType.eDuoRenYiKey then
		if table.InArray(nRoleID, tRoleList) then
			return oPlayer:Tips("您已经使用过该兑换码")
		end
	else
		if #tRoleList > 0 then
			return oPlayer:Tips("该兑换码已经被使用了")
		end
	end

	table.insert(tRoleList, nRoleID)
	sSql = string.format("update cdkeycode set rolelist='%s',time=%d where `key`='%s';", cseri.encode(tRoleList), os.time(), sCDKey)
	self.m_oMgrMysql:Query(sSql)

	local tList = {}
	for _, tItem in ipairs(tAward) do
		table.insert(tList, {nType=tItem[1], nID=tItem[2], nNum=tItem[3]})
	end
	oRole:AddItem(tList, "兑换码兑换")
	Network.PBSrv2Clt("ExchangeRet", oRole:GetServer(), oRole:GetSession(), {tList=tList})
	goLogger:EventLog(gtEvent.eKeyExchange, oRole, nType, sCDKey)
end
