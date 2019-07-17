--充值模块
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--[[充值说明
state:
-1 验证失败
0  已下单未购买
1  已验证成功未发货
2  已发货成功
--]]

local nProcessTime = 2 --处理订单间隔(秒)
local nServerID = gnServerID

function CRecharge:Ctor()
	self.m_oMgrMysql = MysqlDriver:new()
	self.m_sSelectSql = "select orderid, charid, rechargeid, money, time from recharge where serverid=%d and state=1 order by time asc limit 32;"
	self.m_sUpdateSql = "update recharge set level=%d, vip=%d, state=2 where orderid='%s';"
	self:Init()
end

function CRecharge:Init()
	local tConf = gtMgrSQL --后台数据库
	local bRes = self.m_oMgrMysql:Connect(tConf.ip, tConf.port, tConf.db, tConf.usr, tConf.pwd, "utf8")
	assert(bRes, "连接数据库失败")
	LuaTrace("连接数据库成功", tConf)

	self.m_nTimer = GetGModule("TimerMgr"):Interval(nProcessTime, function() self:RechargeTimer() end)
end

function CRecharge:Release()
	GetGModule("TimerMgr"):Clear(self.m_nTimer)
	self.m_nTimer = nil 
end

function CRecharge:SaveData()
end

--处理订单
function CRecharge:RechargeTimer()
	local sSql = string.format(self.m_sSelectSql, nServerID)
	if not self.m_oMgrMysql:Query(sSql) then
		return
	end

	local tInvalidList = {}
	while self.m_oMgrMysql:FetchRow() do
		local sOrderID = self.m_oMgrMysql:ToString("orderid")
		local nRoleID, nRechargeID, nMoney, nTime = self.m_oMgrMysql:ToInt32("charid", "rechargeid", "money", "time")
		local tConf = ctRechargeConf[nRechargeID]
		if tConf then
			if tConf.nMoney == nMoney then	
				local oRole = goGPlayerMgr:GetRoleByID(nRoleID)
				if oRole and oRole:IsOnline() then
					Network.oRemoteCall:CallWait("ProccessRechargeOrderReq", function(sOrderID, nRechargeID)
						self.m_oMgrMysql:Query(string.format(self.m_sUpdateSql, oRole:GetLevel(), oRole:GetVIP(), sOrderID))
					end, oRole:GetStayServer(), oRole:GetLogic(), oRole:GetSession(), sOrderID, nRechargeID, nTime)
				elseif not oRole then
					-- LuaTrace("角色不存在***", nRoleID)
				end
			else
				LuaTrace("orderid:", sOrderID, "rechargeid:", nRechargeID, "money:", nMoney, " money not match!", debug.traceback())
			end
		else
			table.insert(tInvalidList, sOrderID)
			LuaTrace("orderid:", sOrderID, "rechargeid:", nRechargeID, " not exist!")
		end
	end
	for _, nOrderID in ipairs(tInvalidList) do
		self.m_oMgrMysql:Query(string.format("delete from recharge where orderid='%s';", nOrderID))
	end
end
