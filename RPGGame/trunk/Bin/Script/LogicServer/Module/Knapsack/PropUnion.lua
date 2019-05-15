--帮派神诏令
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nNorProp = 10007 	--普通帮派神诏
local nAdvProp = 10013 	--高级帮派神诏
local nMaxFolds = 30 	--折叠上限

function CPropUnion:Ctor(oModule, nID, nGrid, bBind, tPropExt)
	CPropBase.Ctor(self,oModule, nID, nGrid, bBind, tPropExt) 
end

function CPropUnion:LoadData(tData)
	CPropBase.LoadData(self, tData)
end

function CPropUnion:SaveData()
	local tData = CPropBase.SaveData(self)
	return tData
end

--检测还可以加多少个帮派神诏道具
--@nPropID 道具ID
--@nAddNum 要添加的数量
--@bMail 是否邮件附件
-- function CPropUnion:CheckCanAddNum(oRole, nPropID, nAddNum, bMail)
-- 	assert(nPropID==nNorProp or nPropID==nAdvProp, "参数错误:"..nPropID)
-- 	local oKnapsack = oRole.m_oKnapsack
-- 	local nCurNum = oKnapsack:ItemCount(nPropID) + oKnapsack:StorageItemCount(nPropID)
-- 	if nAddNum + nCurNum > nMaxFolds then
-- 		if bMail then
-- 			oRole:Tips(string.format("您获得的%s已达上限，无法继续领取更多", CKnapsack:PropName(nPropID)))
-- 			return 0 
-- 		end
-- 		oRole:Tips(string.format("您获得的%s已达上限", CKnapsack:PropName(nPropID)))
-- 		return math.max(0, nMaxFolds-nCurNum)
-- 	end
-- 	return nAddNum
-- end

--使用道具
--@nParam1
function CPropUnion:Use(nParam1)
	nParam1 = math.max(nParam1 or 0, 1)
	local oRole = self.m_oModule.m_oRole

	if self:GetNum() < nParam1 then
		return oRole:Tips(string.format("%s数量不足", self:GetName()))
	end

	local nServer = oRole:GetServer()
	local nGlobalService = goServerMgr:GetGlobalService(nServer, 20)
	local nPropID= self:GetID()

	local nDayLimit = nPropID==nNorProp and 30 or 15
	assert(nPropID == nNorProp or nPropID == nAdvProp, "道具ID错误")

	goRemoteCall:CallWait("UsedShenZhaoNumReq", function(nUsedNum)
		if not nUsedNum then
			return oRole:Tips("请先加入帮派")
		end
		if nUsedNum >= nDayLimit  then
			return oRole:Tips(string.format("每天最多可使用%d个%s", nDayLimit, self:GetName()))
		end
		local nPropNum = math.min(nDayLimit-nUsedNum, nParam1)
		goRemoteCall:CallWait("OnUseShenZhaoReq", function(bRes)
			if not bRes then
				oRole:Tips(string.format("使用%s失败", self:GetName()))
				return
			end
			oRole:SubItem(gtItemType.eProp, nPropID, nPropNum, "背包使用道具")

			local nLevel = oRole:GetLevel()
			if nPropID == nNorProp then	
				oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, (nLevel*10+1000)*nPropNum, "使用帮派神诏")
				oRole:AddItem(gtItemType.eCurr, gtCurrType.eUnionContri, 5*nPropNum, "使用帮派神诏")
				oRole:AddItem(gtItemType.eCurr, gtCurrType.eUnionExp, 1*nPropNum, "使用帮派神诏")

			elseif nPropID == nAdvProp then
				oRole:AddItem(gtItemType.eCurr, gtCurrType.eExp, (nLevel*10+1000)*nPropNum, "使用高级帮派神诏")
				oRole:AddItem(gtItemType.eCurr, gtCurrType.eUnionContri, 50*nPropNum, "使用高级帮派神诏")
				oRole:AddItem(gtItemType.eCurr, gtCurrType.eUnionExp, 10*nPropNum, "使用高级帮派神诏")

			end

		end, nServer, nGlobalService, 0, oRole:GetID(), nPropID, nPropNum, nDayLimit)

	end, nServer, nGlobalService, 0, oRole:GetID(), nPropID)
end