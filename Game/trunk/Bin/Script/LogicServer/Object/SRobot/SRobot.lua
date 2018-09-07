local nSyncHPMSTime = 333
function CSRobot:Ctor(sObjID, nConfID, tBattle)
    assert(tBattle and tBattle.nType and tBattle.nCamp)
    local tConf = assert(ctRobotConf[nConfID])
    local sName = GF.GenNameByPool()
    local oCppObj = goCppSRobotMgr:CreateRobot(sObjID, nConfID, sName, tConf.nAI, tBattle.nCamp, nSyncHPMSTime)
    CObjBase.Ctor(self, gtObjType.eRobot, sObjID, sName, nConfID, tBattle, oCppObj)

    self.m_nSceneIndex = 0
    self.m_tBattleAttr = nil
    self.m_tBuffMap = {}
end

function CSRobot:GetLevel() return ctRobotConf[self:GetConfID()].nLevel end
function CSRobot:GetStaticSpeed() return ctRobotConf[self:GetConfID()].nMoveSpeed end
function CSRobot:GetRunningSpeed() return self:GetCppObj():GetRunningSpeed() end
function CSRobot:GetRuntimeBattleAttr() return self:GetCppObj():GetFightParam() end

function CSRobot:GetPower()
	local tBattleAttr = self:GetBattleAttr()
    return GF.CalcPower(tBattleAttr[1], tBattleAttr[2], tBattleAttr[3])
end
        
function CSRobot:GetBattleAttr()
	if not self.m_tBattleAttr then
		self.m_tBattleAttr = {}
        local tBattleAttr = assert(ctRobotConf[self:GetConfID()]).tBattleAttr
		for k, v in pairs(gtAttrDef) do
			self.m_tBattleAttr[v] = tBattleAttr[v] and tBattleAttr[v][1] or 0
		end
        self.m_tBattleAttr[gtAttrDef.eSpeed] = self:GetStaticSpeed()
	end
	return self.m_tBattleAttr
end

function CSRobot:GetWeaponList()
	if not self.m_tWeaponList then
        local tConf = assert(ctRobotConf[self.m_nConfID])
		self.m_tWeaponList = {tGunList={}, tBombList={}, nCurrWeapon=tConf.nCurrGun}	
		self.m_tWeaponDetailList = {tGunList={}, tBombList={}, nCurrWeapon=tConf.nCurrGun}
		for k = 1, 4 do
			local tGunConf = assert(tConf["tGun"..k])
			local nArmID = tGunConf[1][1]
			if nArmID > 0 then
				local tGun = {nArmID=nArmID,tFeature={}}
				for k = 2, #tGunConf do
					table.insert(tGun.tFeature, tGunConf[k][1])
				end
				table.insert(self.m_tWeaponList.tGunList, tGun)

				local tGunDetail = CBagModule:GetWeaponDetail(gtArmType.eGun, tGun.nArmID, tGun.tFeature)
				table.insert(self.m_tWeaponDetailList.tGunList, tGunDetail)
			end
		end
		for k, v in ipairs(tConf.tBombList) do
			local nArmID = v[1]
			if nArmID > 0 then
				local tBomb = {nArmID=nArmID,tFeature={}}
				table.insert(self.m_tWeaponList.tBombList, tBomb)

				local tBombDetail = CBagModule:GetWeaponDetail(gtArmType.eBomb, tBomb.nArmID, tBomb.tFeature)
				table.insert(self.m_tWeaponDetailList.tBombList, tBombDetail)
			end
		end
	end
	return self.m_tWeaponList, self.m_tWeaponDetailList
end

function CSRobot:OnRelease()
    CObjBase.OnRelease(self)
end

--取战斗房间
function CSRobot:GetBattleRoom()
    local tBattle = self:GetBattle()
    local oBattleMgr = goBattleCnt:GetBattleMgr(tBattle.nType)
    if not oBattleMgr then
        return
    end
    local oRoom = oBattleMgr:GetRoom(tBattle.tData)
    return oRoom
end

--进入场景
function CSRobot:OnEnterScene(nSceneIndex)
	print("CSRobot:OnEnterScene***", nSceneIndex, self:GetName())
    CObjBase.OnEnterScene(self, nSceneIndex)
    local oCppObj = self:GetCppObj()
    oCppObj:InitFightParam(self:GetBattleAttr())
    local _, tWeaponDetailList = self:GetWeaponList()
    oCppObj:SetWeaponList(tWeaponDetailList)

    local tGun = assert(self:GetCurrWeapon())
    CastDyncFeature(tGun.tFeature, self)
    print("战斗属性:", self:GetName(), self.m_tBattleAttr)
end

--进入场景后
function CSRobot:AfterEnterScene(nSceneIndex)
end

--离开场景完成
function CSRobot:OnLeaveScene(nSceneIndex)
	print("CSRobot:OnLeaveScene***", nSceneIndex, self:GetName())
    CObjBase.OnLeaveScene(self, nSceneIndex)
    goLuaSRobotMgr:RemoveRobot(self.m_sObjID)
end

--进入场景
function CSRobot:EnterScene(nSceneIndex, nPosX, nPosY)
	local oScene = goLuaSceneMgr:GetSceneByIndex(nSceneIndex)
	oScene:AddRobot(self:GetCppObj(), nPosX, nPosY)
end

--离开场景
function CSRobot:LeaveScene()
    local oScene = self:GetScene()
	oScene:RemoveObj(self:GetAOIID())
end

--死亡
function CSRobot:OnRobotDead(sAtkerID, nAtkerType, nArmID, nArmType)
    print(string.format("%s 死亡 Atker:%s,%d Weapon:%d,%d", self:GetName(), sAtkerID, nAtkerType, nArmID, nArmType))
    self:ClearBuff()
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnRobotDead(self, sAtkerID, nAtkerType, nArmID, nArmType) end
end

--清除所有BUFF
function CSRobot:ClearBuff()
    for k, v in pairs(self.m_tBuffMap) do
        v:Expire()
    end
    self.m_tBuffMap = {}
end

--添加BUFF
function CSRobot:AddBuff(nBuffID)
    local tConf = assert(ctBuffConf[nBuffID])
    if self:GetCppObj():AddBuff(nBuffID, tConf.nTime) then
        local oBuff = self.m_tBuffMap[nBuffID]
        if not oBuff then
            oBuff = CBuff:new(self, nBuffID)
            self.m_tBuffMap[nBuffID] = oBuff
        end
        oBuff:BroadcastAddBuff()
        return true
    end
end

--buff过期
function CSRobot:OnBuffExpired(nBuffID)
    local oBuff = self.m_tBuffMap[nBuffID]
    if oBuff then
        oBuff:Expire()
        self.m_tBuffMap[nBuffID] = nil
    end
end

--复活
function CSRobot:Relive(nPosX, nPosY)
    local oScene = self:GetScene()
    if not oScene then return end

    if not nPosX or not nPosY then
        nPosX, nPosY = self:GetPos()
    end

    if not self:GetCppObj():Relive(nPosX, nPosY) then
        return print("复活失败")
    end

    local nOrgHP = self.m_tBattleAttr[gtAttrDef.eHP]
    self:GetCppObj():UpdateFightParam(gtAttrDef.eHP, nOrgHP)

    --场景广播
    local nAOIID = self:GetAOIID()
    local tSessionList = oScene:GetSessionList(nAOIID)
    CmdNet.PBBroadcastExter(tSessionList, "PlayerReliveSync", {nAOIID=nAOIID, nPosX=nPosX, nPosY=nPosY, tBattleAttr=self:GetRuntimeBattleAttr()})
    return true
end

function CSRobot:OnSwitchWeapon(nArmID)
    local oScene = self:GetScene()
    if not oScene then return end

    local tOldGun = assert(self:GetCurrWeapon())
    if tOldGun.nArmID == nArmID then
        return
    end
    self.m_tWeaponList.nCurrWeapon = nArmID 

    local tNewGun = assert(self:GetCurrWeapon())
    CastDyncFeature(tNewGun.tFeature, self, tOldGun.tFeature)

    local nAOIID = self:GetAOIID()
    local tSessionList = oScene:GetSessionList(nAOIID)
    CmdNet.PBBroadcastExter(tSessionList, "PlayerSwitchWeaponSync", {nAOIID=nAOIID, nArmID=nArmID})
end

function CSRobot:GetCurrWeapon()
    if not self.m_tWeaponList then
        return
    end
    for k, v in ipairs(self.m_tWeaponList.tGunList) do
        if v.nArmID == self.m_tWeaponList.nCurrWeapon then
            return v
        end
    end
    assert(false, self.m_tWeaponList.nCurrWeapon.." 不存在当前枪支列表中")
end

function CSRobot:GetViewData()
    local tBattle = self:GetBattle()
    local nPosX, nPosY = self:GetPos()
    local nSpeedX, nSpeedY = self:GetRunningSpeed()
    local tViewData = {}
    tViewData.tBaseData = 
    {	nAOIID = self:GetAOIID()
        , nObjType = gtObjType.eRobot
        , nConfID = self:GetConfID()
        , sName = self:GetName()
        , nLevel = self:GetLevel()
        , nPosX = nPosX
        , nPosY = nPosY
        , nSpeedX = nSpeedX 
        , nSpeedY = nSpeedY
        , nBattleType = tBattle.nType
        , nBattleCamp = tBattle.nCamp
        , tBattleAttr = self:GetRuntimeBattleAttr()
        , nPower = self:GetPower()
    }
    tViewData.tWeaponList = self:GetWeaponList()
    return tViewData
end
