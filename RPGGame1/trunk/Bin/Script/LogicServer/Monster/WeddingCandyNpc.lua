--婚礼糖果
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
local nPropWeddingCandyID = 11009
function CWeddingCandyNpc:Ctor(nObjID, nConfID)
	CPickPublicNpc.Ctor(self, nObjID, nConfID)
end

function CWeddingCandyNpc:PickReq(oRole, nAOIID)
	assert(oRole and nAOIID > 0, "参数错误")
	--当前拾取喜糖，没有数量限制
	local nRoleID = oRole:GetID()
	local nRoleDup = oRole:GetDupMixID()
	local nWeddingDup = goMarriageSceneMgr:GetSceneMixID()
	local oWedding = goMarriageSceneMgr:GetWeddingInst()
	if nRoleDup ~= nWeddingDup then
		oRole:Tips("非法请求")
		return
	end
	local oDup = goMarriageSceneMgr:GetScene()
	if not oDup or not oWedding then
		return
	end

	local nRecordCount = oWedding.m_tCandyPickRecord[nRoleID] or 0
	local nLimitNum = 2
	if nRecordCount >= nLimitNum then 
		oRole:Tips(string.format("本轮已经拾取了%d颗喜糖了，留点喜糖给别人吧", nLimitNum))
		return
	end
	local nDailyLimitNum = 5
	if oRole.m_oKnapsack:GetPickWeddingCandyCount() >= nDailyLimitNum then 
		oRole:Tips("每天只能拾取%d颗喜糖哦", nDailyLimitNum)
		return 
	end

	local oNativeObj = oDup:GetObj(nAOIID)
	if not oNativeObj then
		oRole:Tips("手太慢了，没抢到")
		return
	end
	local oLuaObj = GetLuaObjByNativeObj(oNativeObj)
	if not oLuaObj then
		oRole:Tips("手太慢了，没抢到")
		return
	end
	if not oLuaObj:IsPickPublicNpc() then
		oRole:Tips("非法请求")
		return
	end
	local nRolePosX, nRolePosY = oRole:GetPos()
	local nCandyPosX, nCandyPosY = oLuaObj:GetPos()
	if (math.abs(nCandyPosX - nRolePosX))^2 + (math.abs(nCandyPosY - nRolePosY))^2 > 200^2 then
		oRole:Tips("距离太远，无法拾取")
		return
	end

	oWedding:RemoveCandy(oLuaObj:GetID())
	--给玩家添加道具
	oRole:AddItem(gtItemType.eProp, nPropWeddingCandyID, 1, "拾取喜糖")
	oWedding.m_tCandyPickRecord[nRoleID] = (oWedding.m_tCandyPickRecord[nRoleID] or 0) + 1
	oRole.m_oKnapsack:AddPickWeddingCandyCount(1)
end