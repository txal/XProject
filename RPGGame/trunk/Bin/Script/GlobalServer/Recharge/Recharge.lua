local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--[[充值说明
state:
-1 验证失败
0  已下单未购买
1  已验证成功未发货
2  已发货成功
--]]

local nORDER_PROCTIMER = 3 --处理订单间隔(秒)
local tMysqlConf = gtMgrMysqlConf --充值数据库
local oRechargeMysql = MysqlDriver:new()
local bRes = oRechargeMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, tMysqlConf.sDBName, tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8")
assert(bRes, "连接数据库失败: "..table.ToString(tMysqlConf, true))
LuaTrace("连接数据库成功:", tMysqlConf)

local sSelOrderFmt = "select orderid, charid, rechargeid, money, time from recharge"
	.." where serverid=%d and state=1 order by time asc limit 32;"
local sUpdOrderFmt = "update recharge set state=2 where orderid='%s';"

		
function CRecharge:Ctor()
	self.m_nTimer = goTimerMgr:Interval(nORDER_PROCTIMER, function() self:RechargeTimer() end)
end

function CRecharge:OnRelease()
	goTimerMgr:Clear(self.m_nTimer)
	self.m_nTimer = nil
end

--处理订单
function CRecharge:RechargeTimer()
	local sSql = string.format(sSelOrderFmt, gnServerID)
	if not oRechargeMysql:Query(sSql) then
		return
	end
	while oRechargeMysql:FetchRow() do
		local sOrderID = oRechargeMysql:ToString("orderid")
		local nCharID, nRechargeID, nTime = oRechargeMysql:ToInt32("charid", "rechargeid", "time")
		local tConf = ctRechargeConf[nRechargeID]
		if not tConf then
			return LuaTrace("orderid:"..sOrderID.." rechargeid:"..nRechargeID.." not exist!")
		end
		local oPlayer = goGPlayerMgr:GetPlayerByCharID(nCharID)
		if oPlayer and oPlayer:IsOnline() then
			Srv2Srv.ProccessRechargeOrderReq(oPlayer:GetLogicService(), oPlayer:GetSession(), sOrderID, nRechargeID, nTime)
		end
	end
end

function CRecharge:OnProccessRechargeOrderRet(oPlayer, sOrderID)	
	LuaTrace("CRecharge:OnProccessRechargeOrderRet***", oPlayer:GetName(), sOrderID)
	local sSql = string.format(sUpdOrderFmt, sOrderID)
	oRechargeMysql:Query(sSql)
end


goRecharge = goRecharge or CRecharge:new()
