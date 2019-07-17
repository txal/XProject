--月老NPC(刷新道具)
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function COldManNpc:Ctor(nObjID, nConfID)
	CPickPublicNpc.Ctor(self, nObjID, nConfID)
end

function COldManNpc:PickReq(oRole, nAOIID)
	assert(oRole and nAOIID > 0, "参数错误")
	--当前拾取喜糖，没有数量限制
	local nRoleID = oRole:GetID()
	local nRoleDup = oRole:GetDupMixID()
	local nWeddingDup = goMarriageSceneMgr:GetSceneMixID()
	local oOldMan = goMarriageSceneMgr:GetOldManItemInst()
	if nRoleDup ~= nWeddingDup then
		oRole:Tips("非法请求")
		return
	end
	local oDup = goMarriageSceneMgr:GetScene()
	if not oDup then
		return
	end

	local tItemCfg = self:GetOldManCfg()
	-- if oRole.m_oKnapsack:GetPickOldManItemCount() >= tItemCfg.nPickItemNum then 
	-- 	oRole:Tips("这一批礼物您已经领过了，给别人留点吧")
	-- 	return 
	-- end
	if oOldMan:IsPickRecord(oRole:GetID()) then
		return  oRole:Tips("这一批礼物您已经领过了，给别人留点吧")
	end

	local oNativeObj = oDup:GetObj(nAOIID)
	if not oNativeObj then
		oRole:Tips("该礼品已经消失")
		return
	end
	local oLuaObj = GetLuaObjByNativeObj(oNativeObj)
	if not oLuaObj then
		oRole:Tips("该礼品已经消失")
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
	oOldMan:RemoveOldMan(oLuaObj:GetID())
	--给玩家添加道具
	oRole:AddItem(gtItemType.eProp, tItemCfg.nPickItemID, 1, "拾取月老道具")
	--oRole.m_oKnapsack:AddPickOldManItemCount(1)
	oOldMan:AddPickCount(oRole:GetID(), 1)
end

function COldManNpc:GetOldManCfg()
	local ID = self:GetConfID()
	local tItemCfg = ctOldManItemConf[ID]
	assert(tItemCfg, "月老刷新物品道具配置错误")
	return tItemCfg
end