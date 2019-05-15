--背包
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CRBKnapsack:Ctor(oRobot)
	self.m_oRobot = oRobot
end

function CRBKnapsack:Run()
	local tList = {}
	for nID, tConf in pairs(ctPropConf) do
		table.insert(tList, nID)
	end
	local nID = tList[math.random(#tList)]
	local nRnd = math.random(3)
	if nRnd == 1 then
		self.m_oRobot:SendPressMsg("GMCmdReq", {sCmd="lgm additem 1 7 1000"})
	elseif nRnd == 2 then	
		self.m_oRobot:SendPressMsg("GMCmdReq", {sCmd="lgm additem 1 11 100"})
	else
		self.m_oRobot:SendPressMsg("GMCmdReq", {sCmd="lgm additem 1 "..nID.." 10"})
	end

end

function CRBKnapsack:KnapsackItemAddRet(tData)
	if tData.nType == 1 then
		local tItem = tData.tItemList[1]
		local nRnd = math.random(4)
		if nRnd == 1 then
			self.m_oRobot:SendPressMsg("KnapsackUseItemReq", {nGrid=tItem.nGrid, nParam1=1})
		elseif nRnd == 2 then
			self.m_oRobot:SendPressMsg("KnapsackPutStorageReq", {nGrid=tItem.nGrid})
		end
	end
end

function CRBKnapsack:KnapsackItemModRet(tData)
	if math.random(2) == 1 then
		local tItem = tData.tItemList[1]
		self.m_oRobot:SendPressMsg("KnapsackUseItemReq", {nGrid=tItem.nGrid, nParam1=1})
	end
end
