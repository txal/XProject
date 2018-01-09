
function CDropItem:Ctor(sObjID, nConfID, tBattle)
	assert(tBattle and tBattle.nType and tBattle.nCamp)
	local tConf = assert(ctSceneDropConf[nConfID])
	local oCppObj = goCppDropItemMgr:CreateDropItem(sObjID, nConfID, tConf.sName, tConf.nAliveTime, tBattle.nCamp)
	CObjBase.Ctor(self, gtObjType.eSceneDrop, sObjID, tConf.sName, nConfID, tBattle, oCppObj)

	local nRnd = math.random(1, #tConf.tItemPool)
	self.m_nItemType = tConf.nType
	self.m_nItemID = tConf.tItemPool[nRnd][1]
end

function CDropItem:GetItemID()
	return self.m_nItemID
end

function CDropItem:OnRelease()
	CObjBase.OnRelease(self)
end

--进入场景
function CDropItem:OnEnterScene(nSceneIndex)
	print("CDropItem:OnEnterScene***")
	CObjBase.OnEnterScene(self, nSceneIndex)
end

--进入场景后
function CDropItem:AfterEnterScene(nSceneIndex)
end

--离开场景完成
function CDropItem:OnLeaveScene(nSceneIndex)
	print("CDropItem:OnLeaveScene***")
	CObjBase.OnLeaveScene(self, nSceneIndex)
	goLuaDropItemMgr:RemoveDropItem(self.m_sObjID)
end

--进入场景
function CDropItem:EnterScene(nSceneIndex, nPosX, nPosY)
	local oScene = goLuaSceneMgr:GetSceneByIndex(nSceneIndex)
	oScene:AddDropItem(self:GetCppObj(), nPosX, nPosY)
end

--离开场景
function CDropItem:LeaveScene()
	local oScene = self:GetScene()
	oScene:RemoveObj(self:GetAOIID())
end

--视野数据
function CDropItem:GetViewData()
	local nPosX, nPosY = self:GetPos()
	local tViewData = 
	{	nAOIID = self:GetAOIID()
		, nObjType = gtObjType.eSceneDrop
		, nSceneDropID = self.m_nConfID
		, nItemType = self.m_nItemType
		, nItemID = self.m_nItemID
		, nPosX = nPosX
		, nPosY = nPosY
	}
	return tViewData
end

--捡东西
function CDropItem:OnPick(oPicker)
	local nItemPosX, nItemPosY = self:GetPos()
	local nPickerPosX, nPickerPosY = oPicker:GetPos()
	local nDistX = math.abs(nPickerPosX - nItemPosX)
	local nDistY = math.abs(nPickerPosY - nItemPosY)
	if not GF.AcceptableDistance(nPickerPosX, nPickerPosY, nItemPosX, nItemPosY) then
		return LuaTrace("捡物品位置非法")
	end
	self:LeaveScene()

	if self.m_nItemID <= 0 then
		return LuaTrace("物品非物品")
	end
	
	if self.m_nItemType == gtDropItemType.eBuff then
		local nPickerType = oPicker:GetObjType()
		if nPickerType == gtObjType.ePlayer then
			if oPicker.m_oBattle:AddBuff(self.m_nItemID) then
			    CmdNet.PBSrv2Clt(oPicker:GetSession(), "PickDropItemSuccRet", {nItemType=self.m_nItemType, nItemID=self.m_nItemID})
			end

		elseif nPickerType == gtObjType.eRobot then
			oPicker:AddBuff(self.m_nItemID)

		else
			assert(false, "不支持角色类型:"..nPickerType)
		end
	else 
		assert(false, "不支持场景掉落类型:"..tDropConf.nType)
	end
end
