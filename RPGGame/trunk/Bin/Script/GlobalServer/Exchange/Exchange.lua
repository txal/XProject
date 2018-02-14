--礼包兑换

 --管理数据
local tMysqlConf = gtMgrMysqlConf
local oMgrMysql = MysqlDriver:new()
local bRes = oMgrMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, tMysqlConf.sDBName, tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8")
assert(bRes, "连接数据库失败: "..table.ToString(tMysqlConf, true))
LuaTrace("连接数据库成功:", tMysqlConf)

--类型
CExchange.tType = {
	eSMBX = 1,	--神秘宝箱
	eDuoRenYiKey = 2, 	--多人对一KEY
	eYiRenDuoKey = 3, 	--一人多KEY
	eYiRenYiKey = 4, 	--一人一KEY
}

function CExchange:Ctor()
end

function CExchange:LoadData()
end

function CExchange:SaveData()
end

function CExchange:OnRelease()
end

--兑换
function CExchange:ExchangeReq(oPlayer, sCDKey, bSMBX)
	local nCharID = oPlayer:GetCharID()

	local sSql = "select server,charlist,type,starttime,endtime,award from cdkeycode,cdkeytype where cdkeycode.id=cdkeytype.id and `key`='%s';"
	sSql = string.format(sSql, sCDKey)
	if not oMgrMysql:Query(sSql) then
		return oPlayer:Tips("查询兑换码失败")	
	end
	if not oMgrMysql:FetchRow() then
		return oPlayer:Tips("兑换码不存在")	
	end
	local nServer, nType, nStartTime, nEndTime = oMgrMysql:ToInt32("server", "type", "starttime", "endtime")
	local sCharList, sAward = oMgrMysql:ToString("charlist", "award")
	if nServer > 0 and nServer ~= gnServerID then 
		return oPlayer:Tips("兑换码在该区无效")
	end

	--类型列表
	local tTypeList = {}
	for k, v in pairs(self.tType) do
		table.insert(tTypeList, v)
	end
	if bSMBX and nType ~= self.tType.eSMBX then
		return oPlayer:Tips("非神秘宝箱兑换码")
	end
	if not table.InArray(nType, tTypeList) then
		return oPlayer:Tips("兑换码类型错误")
	end

	local nTimeNow = os.time()
	if nTimeNow < nStartTime or nTimeNow >= nEndTime then
		return oPlayer:Tips("兑换码已过期")
	end

	local tAward = cjson.decode(sAward)
	if #tAward <= 0 then
		return oPlayer:Tips("礼包奖励不存在")
	end

	if nType == self.tType.eSMBX then --神秘宝箱
		Srv2Srv.SMBXExchangeReq(oPlayer:GetLogicService(), oPlayer:GetSession(), nType, sCDKey, tAward)
		print("CExchange:ExchangeReq***", nType, sCDKey, tAward)

	else
		local tCharList = cjson.decode(sCharList)
		if nType == self.tType.eDuoRenYiKey then
			if table.InArray(nCharID, tCharList) then
				return oPlayer:Tips("您已经使用过该兑换码")
			end
		else
			if #tCharList > 0 then
				return oPlayer:Tips("该兑换码已经被使用了")
			end
		end
		Srv2Srv.KeyExchangeReq(oPlayer:GetLogicService(), oPlayer:GetSession(), nType, sCDKey, tAward)

	end
end

--兑换成功返回
function CExchange:OnExchangeRet(oPlayer, nType, sCDKey)
	if nType == self.tType.eSMBX then --神秘宝箱不用处理
		return
	end
	local nCharID = oPlayer:GetCharID()
	local sSql = string.format("select charlist from cdkeycode where `key`='%s' and (server=0 or server=%d);"
		, sCDKey, gnServerID)
	if not oMgrMysql:Query(sSql) then
		return LuaTrace("兑换码查询失败:", nType, sCDKey)
	end
	if not oMgrMysql:FetchRow(sSql) then
		return LuaTrace("兑换码不存在:", nType, sCDKey)
	end
	local sCharList = oMgrMysql:ToString("charlist")
	local tCharList = cjson.decode(sCharList)
	table.insert(tCharList, nCharID)
	sSql = string.format("update cdkeycode set charlist='%s',time=%d where `key`='%s';"
		, cjson.encode(tCharList), os.time(), sCDKey)
	oMgrMysql:Query(sSql)
end

--神秘宝箱信息
function CExchange:SMBXDescReq(oPlayer)
	local sSql = string.format("select `desc` from cdkeytype where type=%d limit 1;", self.tType.eSMBX)
	if not oMgrMysql:Query(sSql) then
		return oPlayer:Tips("查询宝箱失败")	
	end
	if not oMgrMysql:FetchRow() then
		return oPlayer:Tips("宝箱不存在")	
	end
	local sDesc = oMgrMysql:ToString("desc")
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "SMBXDescRet", {sDesc=sDesc})
	print("CExchange:SMBXDescReq***", sDesc)
end


goExchange = goExchange or CExchange:new()