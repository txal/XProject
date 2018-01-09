local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CBattle:Ctor(oPlayer)
	self.m_oPlayer = oPlayer

    self.m_tBuffMap = {}    --[nBuffID] = {nTime=0}
    self.m_tBattleAttr = {} 
    self.m_nBattleLevel = 0     --战斗等级
    self.m_tWeaponList = nil
end

function CBattle:GetType()
	return gtModuleDef.tBattle.nID, gtModuleDef.tBattle.sName
end

function CBattle:LoadData(tData)
end

function CBattle:SaveData()
end

function CBattle:Online()
    self.m_nBattleLevel = self.m_oPlayer:GetLevel()
end

function CBattle:Offline()
    print("CBattle:Offline***")
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:Offline(self.m_oPlayer) end
end

function CBattle:CalcBattleAttr(nLevel)
    local tBattleAttr = self.m_oPlayer.m_oBagModule:CalcArmBattleAttr(nLevel)
    for sName, nIndex in pairs(gtAttrDef) do
        tBattleAttr[nIndex] = tBattleAttr[nIndex] or 0
    end
    tBattleAttr[gtAttrDef.eSpeed] = self.m_oPlayer:GetStaticSpeed()
    
    nLevel = nLevel or self.m_oPlayer:GetLevel()
    tBattleAttr[gtAttrDef.eAtk] = math.floor((tBattleAttr[gtAttrDef.eAtk] + nLevel * 26 + 300) * (10000 + tBattleAttr[gtAttrDef.eAtkAdj]) * 0.0001)
    tBattleAttr[gtAttrDef.eDef] = math.floor((tBattleAttr[gtAttrDef.eDef] + nLevel * 10 + 120) * (10000 + tBattleAttr[gtAttrDef.eDefAdj]) * 0.0001)
    tBattleAttr[gtAttrDef.eHP] = math.floor((tBattleAttr[gtAttrDef.eHP] + nLevel * 93 + 1080) * (10000 + tBattleAttr[gtAttrDef.eHPAdj]) * 0.0001)

    self.m_tBattleAttr = tBattleAttr
    return self.m_tBattleAttr
end

function CBattle:GetBattleAttr()
    return self.m_tBattleAttr
end

function CBattle:GetRuntimeBattleAttr()
    return self.m_oPlayer:GetCppObj():GetFightParam()
end

function CBattle:UpdateRuntimeBattleAttr(tBattleAttr)
    self.m_oPlayer:GetCppObj():InitFightParam(tBattleAttr)
end

function CBattle:SetBattleLevel(nLevel) self.m_nBattleLevel = nLevel end
function CBattle:GetBattleLevel() return self.m_nBattleLevel end

--取武器列表
function CBattle:GetWeaponList()
    if not self.m_tWeaponList then
        self.m_tWeaponList = self.m_oPlayer.m_oBagModule:GetWeaponList()
    end
    return self.m_tWeaponList
end

--取战斗房间
function CBattle:GetBattleRoom()
    local tBattle = self.m_oPlayer:GetBattle()
    local oBattleMgr = goBattleCnt:GetBattleMgr(tBattle.nType)
    if not oBattleMgr then
        return
    end
    local oRoom = oBattleMgr:GetRoom(tBattle.tData)
    return oRoom
end

--进入场景成功
function CBattle:OnEnterScene(nSceneIndex)
    self:GetWeaponList() --生成武器列表
    self:SetBattleLevel(self.m_oPlayer:GetLevel())
	self.m_oPlayer:GetCppObj():InitFightParam(self.m_tBattleAttr)

    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnEnterScene(self.m_oPlayer) end

    local tGun = self:GetCurrWeapon()
    if tGun then CastDyncFeature(tGun.tFeature, self.m_oPlayer) end
end

--进入场景后
function CBattle:AfterEnterScene(nSceneIndex)
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:AfterEnterScene(self.m_oPlayer) end
end

function CBattle:OnClientSceneReady(nSceneIndex)
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnClientSceneReady(self.m_oPlayer) end
end

--离开场景完成
function CBattle:OnLeaveScene(nSceneIndex)
    self:ClearBuff()
    self:CalcBattleAttr()
    self:SetBattleLevel(self.m_oPlayer:GetLevel())
    self.m_tWeaponList = nil

    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnLeaveScene(self.m_oPlayer) end
end

--玩家复活请求
function CBattle:ReliveReq()
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnReliveReq(self.m_oPlayer) end
end

--玩家死亡
function CBattle:OnPlayerDead(sAtkerID, nAtkerType, nArmID, nArmType)
    print(string.format("%s 死亡 Atker:%s,%d Weapon:%d,%d", self.m_oPlayer:GetName(), sAtkerID, nAtkerType, nArmID, nArmType))
    self:ClearBuff()
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnPlayerDead(self.m_oPlayer, sAtkerID, nAtkerType, nArmID, nArmType) end
end

--复活玩家
function CBattle:Relive(nPosX, nPosY)
    local oScene = self.m_oPlayer:GetScene()
    if not oScene then return end

    if not nPosX or not nPosY then
        nPosX, nPosY = self:GetPos()
    end

    if not self.m_oPlayer:GetCppObj():Relive(nPosX, nPosY) then
        return print("复活失败")
    end

    local nOrgHP = self.m_tBattleAttr[gtAttrDef.eHP]
    self.m_oPlayer:GetCppObj():UpdateFightParam(gtAttrDef.eHP, nOrgHP)

    --场景广播
    local nAOIID = self.m_oPlayer:GetAOIID()
    local tSessionList = oScene:GetSessionList(nAOIID, true)
    CmdNet.PBBroadcastExter(tSessionList, "PlayerReliveSync", {nAOIID=nAOIID, nPosX=nPosX, nPosY=nPosY, tBattleAttr=self:GetRuntimeBattleAttr()})
    return true
end

--玩家切换武器广播
function CBattle:SwitchWeapon(nArmID)
    local oScene = self.m_oPlayer:GetScene()
    if not oScene then return end

    local tOldGun = assert(self:GetCurrWeapon())
    if tOldGun.nArmID == nArmID then
        return
    end
    self.m_tWeaponList.nCurrWeapon = nArmID

    local tNewGun = assert(self:GetCurrWeapon())
    CastDyncFeature(tNewGun.tFeature, self.m_oPlayer, tOldGun.tFeature)

    local nAOIID = self.m_oPlayer:GetAOIID()
    local tSessionList = oScene:GetSessionList(nAOIID)
    CmdNet.PBBroadcastExter(tSessionList, "PlayerSwitchWeaponSync", {nAOIID=self.m_nAOIID, nArmID=nArmID})
end

--清除所有BUFF
function CBattle:ClearBuff()
    for k, v in pairs(self.m_tBuffMap) do
        v:Expire()
    end
    self.m_tBuffMap = {}
end

--添加BUFF
function CBattle:AddBuff(nBuffID)
    local tConf = assert(ctBuffConf[nBuffID])
    if self.m_oPlayer:GetCppObj():AddBuff(nBuffID, tConf.nTime) then
        local oBuff = self.m_tBuffMap[nBuffID]
        if not oBuff then
            oBuff = CBuff:new(self.m_oPlayer, nBuffID)
            self.m_tBuffMap[nBuffID] = oBuff
        end
        oBuff:BroadcastAddBuff()
        return true
    end
end

--BUFF过期
function CBattle:OnBuffExpired(nBuffID)
    local oBuff = self.m_tBuffMap[nBuffID]
    if oBuff then
        oBuff:Expire()
        self.m_tBuffMap[nBuffID] = nil
    end
end

function CBattle:GetCurrWeapon()
    if not self.m_tWeaponList then
        return
    end
    for k, v in ipairs(self.m_tWeaponList.tGunList) do
        if v.nArmID == self.m_tWeaponList.nCurrWeapon then
            return v
        end
    end
end

--视野数据
function CBattle:GetViewData()
    local tBattle = self.m_oPlayer:GetBattle()
    local nPosX, nPosY = self.m_oPlayer:GetPos()
    local nSpeedX, nSpeedY = self.m_oPlayer:GetRunningSpeed()

    local tViewData = {}
    tViewData.tBaseData = 
    {   nAOIID = self.m_oPlayer:GetAOIID()
        , nObjType = gtObjType.ePlayer
        , nConfID = self.m_oPlayer:GetRoleID()
        , sName = self.m_oPlayer:GetName() 
        , nLevel = self.m_nBattleLevel
        , nPosX = nPosX
        , nPosY = nPosY
        , nSpeedX = nSpeedX
        , nSpeedY = nSpeedY
        , nBattleType = tBattle.nType
        , nBattleCamp = tBattle.nCamp
        , tBattleAttr = self:GetRuntimeBattleAttr()
        , nPower = self.m_oPlayer:GetPower()
    }
    tViewData.tWeaponList = self:GetWeaponList()
    return tViewData
end

function CBattle:OnEnterBackground()
    print("CBattle:OnEnterBackground***")
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnEnterBackground(self.m_oPlayer) end
end

function CBattle:OnEnterForeground()
    print("CBattle:OnEnterForeground***")
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnEnterForeground(self.m_oPlayer) end
end

--发送战场表情
function CBattle:OnSendBattleFaceReq(nFaceID)
    local oRoom = self:GetBattleRoom()
    if oRoom then oRoom:OnSendBattleFaceReq(self.m_oPlayer, nFaceID) end
end

--治疗
function CBattle:OnCureReq(nAOIID, nPosX, nPosY, nAddHP)
    local oRoom = self:GetBattleRoom()
    if oRoom then oBattleMgr:OnCureReq(self.m_oPlayer, nAOIID, nPosX, nPosY, nAddHP) end
end

--购买弹药
function CBattle:OnBuyBulletReq(oPlayer)
    local oRoom = self:GetBattleRoom()
    if oRoom then oBattleMgr:OnBuyBulletReq(oPlayer) end
end
