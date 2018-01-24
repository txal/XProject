
function CMonster:Ctor(sObjID, nConfID, tBattle)
    assert(tBattle and tBattle.nType and tBattle.nCamp)
	local tConf = assert(ctMonsterConf[nConfID])
	local oCppObj = goCppMonsterMgr:CreateMonster(sObjID, nConfID, tConf.sName, tConf.nAI, tBattle.nCamp)
	CObjBase.Ctor(self, gtObjType.eMonster, sObjID, tConf.sName, nConfID, tBattle, oCppObj)

    self.m_tBattleAttr = nil
end

function CMonster:GetLevel() return ctMonsterConf[self:GetConfID()].nLevel end
function CMonster:GetStaticSpeed() return ctMonsterConf[self:GetConfID()].nMoveSpeed end
function CMonster:GetRunningSpeed() return self:GetCppObj():GetRunningSpeed() end
function CMonster:GetRuntimeBattleAttr() return self:GetCppObj():GetFightParam() end

function CMonster:GetBattleAttr()
    if not self.m_tBattleAttr then
    	self.m_tBattleAttr = {}
    	for sAttr, nIndex in pairs(gtAttrDef) do
    		self.m_tBattleAttr[nIndex] = 0
    	end
    	local tConf = assert(ctMonsterConf[self.m_nConfID])
    	self.m_tBattleAttr[gtAttrDef.eAtk] = tConf.nAtk
    	self.m_tBattleAttr[gtAttrDef.eDef] = tConf.nDef
    	self.m_tBattleAttr[gtAttrDef.eHP] = tConf.nHP
    	self.m_tBattleAttr[gtAttrDef.eCrit] = tConf.nCrit
        self.m_tBattleAttr[gtAttrDef.eSpeed] = tConf.nMoveSpeed
    end
	return self.m_tBattleAttr
end

function CMonster:OnRelease()
    CObjBase.OnRelease(self)
end

--取战斗房间
function CMonster:GetBattleRoom()
    local tBattle = self:GetBattle()
    local oBattleMgr = goBattleCnt:GetBattleMgr(tBattle.nType)
    if not oBattleMgr then
        return
    end
    local oRoom = oBattleMgr:GetRoom(tBattle.tData)
    return oRoom
end

--进入场景
function CMonster:OnEnterScene(nSceneIndex)
	print("CMonster:OnEnterScene***")
    CObjBase.OnEnterScene(self, nSceneIndex)
    self:GetCppObj():InitFightParam(self:GetBattleAttr())
end

--进入场景后
function CMonster:AfterEnterScene(nSceneIndex)
end

--离开场景完成
function CMonster:OnLeaveScene(nSceneIndex)
	print("CMonster:OnLeaveScene***")
    CObjBase.OnLeaveScene(self, nSceneIndex)
	goLuaMonsterMgr:RemoveMonster(self.m_sObjID)
end

--进入场景
function CMonster:EnterScene(nSceneIndex, nPosX, nPosY)
	local oScene = goLuaSceneMgr:GetSceneByIndex(nSceneIndex)
	oScene:AddMonster(self:GetCppObj(), nPosX, nPosY)
end

--离开场景
function CMonster:LeaveScene()
    local oScene = self:GetScene()
	oScene:RemoveObj(self:GetAOIID())
end

--死亡
function CMonster:OnMonsterDead(sAtkerID, nAtkerType, nArmID, nArmType)
    print(string.format("怪物 '%s' 死亡 Atker:%s,%d Weapon:%d,%d", self:GetName(), sAtkerID, nAtkerType, nArmID, nArmType))
    local oRoom = self:GetBattleRoom()
    local tBattle = self:GetBattle()
    if oRoom then oRoom:OnMonsterDead(self, sAtkerID, nAtkerType, nArmID, nArmType) end
	self:LeaveScene()
end

function CMonster:GetViewData()
    local tBattle = self:GetBattle()
    local nPosX, nPosY = self:GetPos()
    local nSpeedX, nSpeedY = self:GetRunningSpeed()

    local tViewData = 
    {	nAOIID = self:GetAOIID()
	    , nObjType = self:GetObjType()
	    , nConfID = self:GetConfID()
	    , sName = self:GetName()
	    , nLevel = self:GetLevel()
        , nPosX = nPosX
        , nPosY = nPosY
        , nSpeedX = nSpeedX
        , nSpeedY = nSpeedY
        , nBattleType = tBattle.nType
        , nBattleCamp = tBattle.nCamp
        , tBattleAttr = self:GetBattleAttr()
        , nPower = 0
    }
    return tViewData
end
