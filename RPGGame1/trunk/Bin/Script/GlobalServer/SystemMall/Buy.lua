--购买
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
function CBuy:Ctor(model)
	self.m_oModule = model
	self.m_tFirstBuyTime = {}
	self.m_tAllreadyBuy = {} 
end

function CBuy:LoadData(tData)
	self.m_tAllreadyBuy = tData.m_tAllreadyBuy or {}
	self.m_tFirstBuyTime = tData.m_tFirstBuyTime or {}
end

function CBuy:SaveData()
	local tData = {}
	tData.m_tAllreadyBuy = self.m_tAllreadyBuy
	tData.m_tFirstBuyTime = self.m_tFirstBuyTime
	return tData
end

function CBuy:ZeroUpdate()
	if self.m_tFirstBuyTime[1] and not os.IsSameWeek( os.time() , self.m_tFirstBuyTime[1] , 0 )  then --每周限购
		self.m_tAllreadyBuy = {}
		self.m_tFirstBuyTime = {}
		self:MarkDirty(true)
	end
end

function CBuy:GoidBuyReq(nID, oRole)
	if not oRole:IsSysOpen(18, true) then
		return
	end
	local tItem = ctBuyConf[nID]
	if not tItem then
		return 
	end

	local nTID = nID
	if tItem.nLimitNum ~= 0 then
		if self.m_tAllreadyBuy[oRole:GetID()] and self.m_tAllreadyBuy[oRole:GetID()][nID] then
		 	if self.m_tAllreadyBuy[oRole:GetID()][nID] ==  tItem.nLimitNum then
		 		return oRole:Tips("剩余购买次数不足")
		 	end
		end
	end

	local tItemList = {}
	tItemList[#tItemList+1] =  {nType = gtItemType.eCurr, nID = tItem.nCostType, nNum = tItem.nCostNum}
	local fnFlushCostCallBack = function (bRet)
		if not bRet then
			if tItem.nCostType == gtCurrType.eYinBi then
				return oRole:YinBiTips()
			elseif tItem.nCostType == gtCurrType.eYuanBao or tItem.nCostType == gtCurrType.eBYuanBao
				 or tItem.nCostType == gtCurrType.eAllYuanBao then
				return oRole:YuanBaoTips()
			elseif tItem.nCostType == gtCurrType.eDrawSpirit then
				--return oRole:Tips("当前灵气不足，兑换失败，可通过镇妖任务和完成日常任务获得灵气")
			end
		end

		--记录限购时间
		if tItem.nLimitNum ~= 0 then
			if not self.m_tFirstBuyTime[tItem.nLimBuyType] then
				self.m_tFirstBuyTime[tItem.nLimitType] = os.ZeroTime(os.time())
			end

			if not self.m_tAllreadyBuy[oRole:GetID()] then
				self.m_tAllreadyBuy[oRole:GetID()] = {[nTID] = 1}
			else
				if not self.m_tAllreadyBuy[oRole:GetID()][nTID] then
					self.m_tAllreadyBuy[oRole:GetID()][nTID] = 1
				else
					self.m_tAllreadyBuy[oRole:GetID()][nTID] = self.m_tAllreadyBuy[oRole:GetID()][nTID] + 1
				end
				
			end
		end
		tItemList ={}
		tItemList[#tItemList+1] = {nType = gtItemType.eCurr, nID = tItem.nBuyType, nNum = tItem.nBuyCoin, bBind = false, tPropExt = {}}
		oRole:AddItem(tItemList, "元宝购买获得")
		oRole:Tips("购买成功")
		self:MarkDirty(true)
		local tMsg = {}
		tMsg.nID = nTID
		tMsg.nNum = tItem.nBuyCoin
		oRole:SendMsg("SystemMalluyRet", tMsg)
		if tItem and tItem.nBuyType == gtCurrType.eUnionContri then
			self:UnionContriDataReq(oRole)
		end
	end
	oRole:SubItem(tItemList, "购买消耗", fnFlushCostCallBack)
end

function CBuy:MarkDirty(bMark)
	self.m_oModule:MarkDirty(bMark)
end

function CBuy:GetBuyData(oRole,nID)
	local nRoleID = oRole:GetID()
	local tData = self.m_tAllreadyBuy[nRoleID] or {}
	return tData[nID] or 0
end

function CBuy:CanBuyAmount(oRole,nID)
	local tConf = ctBuyConf[nID] or {}
	local nLimitNum = tConf.nLimitNum or 0
	local nBuyAmount = self:GetBuyData(oRole,nID)
	local nCanBuyAmount = math.max(nLimitNum-nBuyAmount,0)
	return nCanBuyAmount
end

function CBuy:MoneyConvertReq(nID, nNum, oRole)
	if not nID or not nNum or nNum < 1 then
		return oRole:Tips("参数错误")
	end
	local tItem = ctBuyConf[nID]
	if not tItem then return end
	local  tItemList = {}
	tItemList[#tItemList+1] =  {nType = gtItemType.eCurr, nID = tItem.nCostType, nNum = tItem.nCostNum * nNum}
	local fnSubCallBack = function (bRet)
		if not bRet then
			return oRole:Tips("当前灵气不足，兑换失败，可通过镇妖任务和完成日常任务获得灵气")
		end
		local tAddItem = {}
		tAddItem[#tAddItem+1] ={nType = gtItemType.eCurr, nID = tItem.nBuyType, nNum = tItem.nBuyCoin * nNum, bBind = false, tPropExt = {}}
		oRole:AddItem(tAddItem, "兑换获得")
	end
	oRole:SubItem(tItemList, "兑换消耗", fnSubCallBack)
end

function CBuy:UnionContriDataReq(oRole)
	local tMsg = {}
	for nID,tConf in pairs(ctBuyConf) do
		if tConf.nBuyType == gtCurrType.eUnionContri then				--帮贡
			local nCanBuyAmount = self:CanBuyAmount(oRole,nID)
			table.insert(tMsg,{
				nID = nID,
				nAmount = nCanBuyAmount,
			})
		end
	end
	oRole:SendMsg("SystemUnionContriAmountRet",{tAmount = tMsg})
end