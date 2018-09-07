--充值模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--[[充值说明
state:
-1 验证失败
0  已下单未购买
1  已验证成功未发货
2  已发货成功
--]]

local nProcessTime = 3 --处理订单间隔(秒)
local nServerID = gnServerID

function CRecharge:Ctor()
	self.m_oMgrMysql = MysqlDriver:new()
	self.m_sSelectSql = "select orderid, roleid, rechargeid, money, time from recharge where serverid=%d and state=1 order by time asc limit 32;"
	self.m_sUpdateSql = "update recharge set state=2 where orderid='%s';"
	self:Init()
end

function CRecharge:Init()
	local tConf = gtMgrMysqlConf --后台数据库
	local bRes = self.m_oMgrMysql:Connect(tConf.sIP, tConf.nPort, tConf.sDBName, tConf.sUserName, tConf.sPassword, "utf8")
	assert(bRes, "连接数据库失败", tConf)
	LuaTrace("连接数据库成功", tConf)

	self.m_nTimer = goTimerMgr:Interval(nProcessTime, function() self:RechargeTimer() end)
end

function CRecharge:OnRelease()
	goTimerMgr:Clear(self.m_nTimer)
	self.m_nTimer = nil 
end

--处理订单
function CRecharge:RechargeTimer()
	local sSql = string.format(self.m_sSelectSql, nServerID)
	if not self.m_oMgrMysql:Query(sSql) then
		return
	end

	while self.m_oMgrMysql:FetchRow() do
		local sOrderID = self.m_oMgrMysql:ToString("orderid")
		local nRoleID, nRechargeID, nTime = self.m_oMgrMysql:ToInt32("roleid", "rechargeid", "time")
		local tConf = ctRechargeConf[nRechargeID]
		if not tConf then
			return LuaTrace("orderid:"..sOrderID.." rechargeid:"..nRechargeID.." not exist!")
		end
		local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
		if oRole:IsOnline() then
			goRemoteCall.CallWait("ProccessRechargeOrderReq", function(nRoleID)
				self.m_oMgrMysql:Query(string.format(self.m_sUpdateSql, sOrderID))
			end, oRole:GetServer(), oRole:GetLogic(), oRole:GetSession(), sOrderID, nRechargeID, nTime)
		end
	end
end


goRecharge = goRecharge or CRecharge:new()
