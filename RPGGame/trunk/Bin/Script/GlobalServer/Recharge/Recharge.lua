local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--[[充值说明
state:
-1 验证失败
0  已下单未购买
1  已验证成功未发货
2  已发货成功
--]]
local nORDER_PROCTIMER = 3000 			--处理订单间隔(毫秒)
local tMysqlConf = gtMgrMysqlConf[1]	--充值数据库

local oRechargeMysql = MysqlDriver:new()
local bRes = oRechargeMysql:Connect(tMysqlConf.sIP, tMysqlConf.nPort, tMysqlConf.sDBName, tMysqlConf.sUserName, tMysqlConf.sPassword, "utf8")
assert(bRes, "Connect to mysql: "..table.ToString(tMysqlConf, true).." fail")
LuaTrace("Connect mysql: "..table.ToString(tMysqlConf, true).." successful")

function CRecharge:Ctor()
	self.m_sNewOrderFmt = "insert into recharge set order_id='%s',server_id=%d,char_id='%s',recharge_id=%d,product_id='%s',money=%d,channel='%s',time=%d;"
	self.m_sSelOrderFmt = "select order_id, char_id, recharge_id from recharge where server_id=%d and state=1 order by time asc limit 32;"
	self.m_sUpdOrderFmt = "update recharge where state=2 where order_id='%s';"
		
	self.m_nTimer = GlobalExport.RegisterTimer(nORDER_PROCTIMER, function() self:RechargeTimer() end)
end

function CRecharge:OnRelease()
	if self.m_nTimer then
		GlobalExport.CancelTimer(self.m_nTimer)
		self.m_nTImer = nil
	end
end

--生成订单号
function CRecharge:_gen_order_id_()
	local sObjID = tostring(GlobalExport.MakeGameObjID())
	return sObjID
end

--商品列表
function CRecharge:ProductListReq(oPlayer)
	local tItemList = {}
	for nID, tConf in pairs(ctRechargeConf) do
		local tItem = {nID=nID, nRMB=tConf.nCostMoney, nDiamond=tConf.nBuyDiamond, nGiveDiamond=tConf.nGiveDiamond}
		table.insert(tItemList, tItem)
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "ProductListRet", {tItemList=tItemList})
end

--下单请求
function CRecharge:MakeOrderReq(oPlayer, nRechargeID)
	local nCharID = tostring(oPlayer:GetCharID())
	local sPlatform = oPlayer:GetPlatform()
	local sChannel = oPlayer:GetChannel()
	local sOrderID = self:_gen_order_id_()
	local tConf = assert(ctRechargeConf[nRechargeID])
	local sNewOrder = string.format(self.m_sNewOrderFmt, sOrderID, gnServerID, nCharID, nRechargeID, tConf.nMoney
		, tConf.sProductID, sPlatform, sChannel, os.time())
	if not oRechargeMysql:Query(sNewOrder) then
		return
	end
	CmdNet.PBSrv2Clt(oPlayer:GetSession(), "MakeOrderRet", {nConfID=nRechargeID, sOrderID=sOrderID})
end

--处理订单
function CRecharge:RechargeTimer()
	local sSql = string.format(self.m_sSelOrderFmt, gnServerID)
	if not oRechargeMysql:Query(sSql) then
		return
	end
	while oRechargeMysql:FetchRow() do
		local sOrderID, nCharID = oRechargeMysql:ToString("order_id", "char_id")
		local nRechargeID = oRechargeMysql:ToInt32("recharge_id")
		if not ctRechargeConf[nRechargeID] then
			LuaTrace("order:", sOrderID, "char:", nCharID, "recharge:", nRechargeID, "not exist!")
		else
			local oPlayer = goGPlayerMgr:GetPlayerByCharID(nCharID)
			if oPlayer then
				Srv2Srv.ProccessRechargeOrderReq(oPlayer:GetLogicService(), oPlayer:GetSession(), sOrderID, nRechargeID)
			end
		end
	end
end

function CRecharge:OnProccessRechargeOrderRet(oPlayer, sOrderID, nRechargeID)	
	print("CRecharge:OnProccessRechargeOrderRet***", oPlayer:GetName(), sOrderID, nRechargeID)
	local sSql = string.format(m_sUpdOrderFmt, sOrderID)
	oRechargeMysql:Query(sSql)
end



goRecharge = goRecharge or CRecharge:new()
