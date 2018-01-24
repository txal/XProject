function CDropItemMgr:Ctor()
	self.m_tDropItemMap = {}
end

function CDropItemMgr:GetDropItem(sObjID)
	return self.m_tDropItemMap[sObjID]
end

function CDropItemMgr:GetCount()
	local nCount = 0
	for sObjID, oItem in pairs(self.m_tDropItemMap) do
		nCount = nCount + 1
	end
	return nCount
end

--创建掉落
function CDropItemMgr:CreateDropItem(nConfID, nSceneIndex, nPosX, nPosY, tBattle)
	assert(tBattle and tBattle.nType and tBattle.nCamp)
	local tConf = assert(ctSceneDropConf[nConfID], "场景掉落:"..nConfID.." 不存在")
	if tConf.nType ~= gtDropItemType.eBuff then
		assert(false, "不支持场景掉落类型:"..tConf.nType)
	end
	local sObjID = GlobalExport.MakeGameObjID()
	local oDropItem = CDropItem:new(sObjID, nConfID, tBattle)
	self.m_tDropItemMap[sObjID] = oDropItem
	oDropItem:EnterScene(nSceneIndex, nPosX, nPosY)
	return oDropItem
end

--移除
function CDropItemMgr:RemoveDropItem(sObjID)
	local oDropItem = self:GetDropItem(sObjID)
	if oDropItem then
		oDropItem:OnRelease()
	end
	self.m_tDropItemMap[sObjID] = nil
end

--被清理
function CDropItemMgr:OnDropItemCollected(sObjID)
	self:RemoveDropItem(sObjID)
end

--捡东西
function CDropItemMgr:PickDropItemReq(oPlayer, nSrcAOIID, nTarAOIID)
	print("CDropItemMgr:PickDropItemReq******")
	local oScene = oPlayer:GetScene()	
	if not oScene then
		return
	end
	local oSrcObj = oScene:GetObj(nSrcAOIID)
	if not oSrcObj then
		return print("找不到捡东西的人")
	end
	local oTarObj = oScene:GetObj(nTarAOIID)
	if not oTarObj then
		return print("找不到东西")
	end
	local sSrcObjID = oSrcObj:GetObjID()
	local nSrcObjType = oSrcObj:GetObjType()
	local sTarObjID = oTarObj:GetObjID()
	local nTarObjType = oTarObj:GetObjType()
	local oPicker
	if nSrcObjType == gtObjType.ePlayer then
		oPicker = goLuaPlayerMgr:GetPlayerByCharID(sSrcObjID)

	elseif nSrcObjType == gtObjType.eRobot then
		oPicker = goLuaSRobotMgr:GetRobot(sSrcObjID)

	end
	if not oPicker then
		return print("找不到捡东西的人")
	end

	if nTarObjType == gtObjType.eSceneDrop then
		local oDropItem = self:GetDropItem(sTarObjID)
		if oDropItem then
			oDropItem:OnPick(oPicker)
		end
	else
		assert(false, "物品非场景掉落不能捡")
	end
end


goCppDropItemMgr = GlobalExport.GetDropItemMgr()
goLuaDropItemMgr = goLuaDropItemMgr or CDropItemMgr:new()
