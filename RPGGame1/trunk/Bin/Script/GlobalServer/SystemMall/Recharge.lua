--充值
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
function CRecharge:Ctor(model)
	self.m_tRecharge = {} --self.m_tRecharge[nRole] = {nQuota = 0, reward = {}}
end

function CRecharge:LoadData(tData)
	self.m_tRecharge = tData.m_tRecharge or {}
end

function CRecharge:SaveData()
	local tData = {}
	tData.m_tRecharge = self.m_tRecharge
	return tData
end

--@tItemList {{nType=0,nID=0,nNum=0,bBind=false,tPropExt={}},...}
function CRecharge:RecInterface(nGold, nRole)
	if not self.m_tRecharge[nRole:GetID()] then
		self.m_tRecharge[nRole] = {nGold = nGold, reward = {}}
	else
		self.m_tRecharge[nRole].nGold = self.m_tRecharge[nRole].nGold + nGold
	end
	local nBYuanBao = ctRechargeConf[nGold/10].nBYuanBao
	local tItemList = {}
	tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID = gtCurrType.eBYuanBao, nNum = self:GetConf(nGold).nGiveYuanBao, bBind = false, tPropExt = {}}
	nRole:AddItem(tItemList, "元宝充值获得")
	self:RecCheck(nGold)
end

function CRecharge:ZeroUpdate()
end

function CRecharge:GetConf(nGold)
	if nGold <= 0 then
		return 
	end
	for _, tConf in ipairs(ctRechargeConf) do
		if tConf.nBuyYuanBao == nGold then
			return tConf
		end 
	end
end
function CRecharge:RewardReq(nType, nRole)
	if nType < 1 and  nType > 20 then
		nRole:Tips("领奖类型错误")
	end

	 if not self.m_tRecharge[nRole:GetID()] then
	 	nRole:Tips("玩家没有可领取的奖励")
	end

	if self.m_tRecharge[nRole:GetID()].reward[nType] then
		nRole:Tips("玩家已经领取该奖励")
	end

	if not self.m_tRecharge[nRole:GetID()].reward[nType] then
		self.m_tRecharge[nRole:GetID()].reward[nType] = true
	end
	local tItemList = {}
	tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID = gtCurrType.eBYuanBao,  nNum = nBYuanBao, bBind = false, tPropExt = {}}
	nRole:AddItem(tItemList, "元宝充值获得")
end

function CRecharge:RecCheck(nGold, nRole)

end

function CRecharge:MarkDirty(bMark)
	self.m_oModule:MarkDirty(bMark)
end
