--VIP系统
function CVIP:Ctor(oPlayer)
	self.m_oPlayer = oPlayer
	self.m_nVIP = 0
	self.m_nTotalRecharged = 0
	self.m_tProccessedOrder = {}	--不保存(用来防止重复处理同一订单)
	self.m_bDirty = false
end

function CVIP:LoadData(tData)
	self.m_nTotalRecharged = tData.nTotalRecharged
	self.m_tProccessedOrder = tData.tProccessedOrder
	self.m_nVIP = tData.nVIP or 0
end

function CVIP:SaveData()
	if not self.m_bDirty then
		return
	end
	local tData = {}
	tData.nTotalRecharged = self.m_nTotalRecharged
	tData.tProccessedOrder = self.m_tProccessedOrder
	tData.nVIP = self.m_nVIP
	self.m_bDirty = false
	return tData
end

function CVIP:GetType()
	return gtModuleDef.tVIP.nID, gtModuleDef.tVIP.sName
end

function CVIP:GetVIP()
	return self.m_nVIP
end

function CVIP:MarkDirty(bDirty)
	self.m_bDirty = bDirty
end

--取累计充值
function CVIP:GetTotalRecharge()
	return self.m_nTotalRecharged
end

--处理订单
function CVIP:OnProcessRechargeOrderReq(sOrderID, nRechargeID)
	assert(sOrderID and nRechargeID)
	if not self.m_tProccessedOrder[sOrderID] then
		self.m_tProccessedOrder[sOrderID] = {nRechargeID, os.time()}

		local tConf = assert(ctRechargeConf[nRechargeID])
		self.m_nTotalRecharged = self.m_nTotalRecharged + tConf.nCostMoney
		local nBuyDiamond, nGiveDiamond = tConf.nBuyDiamond, tConf.nGiveDiamond
		self.m_oPlayer:AddDiamond(nBuyDiamond+nGiveDiamond, gtReason.eRechage)
		CmdNet.PBSrv2Clt(self.m_oPlayer:GetSession(), "RechargeSuccessRet", {nDiamond=nBuyDiamond+nGiveDiamond})
		self:OnRechargeSuccess(tConf.nCostMoney, nBuyDiamond+nGiveDiamond)

		--日志
		goLogger:EventLog(gtEvent.eRechage, self.m_oPlayer, sOrderID, nRechargeID, nBuyDiamond, nGiveDiamond)
	else
		LuaTrace("订单已处理,说明逻辑服3秒内没处理完成订单或订单号冲突", sOrderID, nRechargeID)
	end
	Srv2Srv.ProccessRechargeOrderRet(gtNetConf:GlobalService(), self.m_oPlayer:GetSession(), sOrderID, nRechargeID)
	self:MarkDirty(true)
end

--充值成功
function CVIP:OnRechargeSuccess(nMoney, nDiamond)
end

--VIP变化
function CVIP:OnVIPChange()
    --离线玩家
    goOfflinePlayerMgr:OnVIPChange(self.m_oPlayer)
end

--GM模拟充值
function CVIP:GMRecharge(nMoney)
	if nMoney <= 0 then
		return
	end
	self.m_nTotalRecharged = math.min(nMAX_INTEGER, self.m_nTotalRecharged+nMoney)
	self:MarkDirty(true)
end