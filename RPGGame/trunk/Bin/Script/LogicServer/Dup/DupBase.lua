--场景基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

--副本类型
CDupBase.tType = 
{
    eCity = 1,  --城镇
    eDup = 2,   --副本
}

--AOI类型
CDupBase.tAOIType = 
{
    eObserver = 1,  --观察者
    eObserved = 2,  --被观察者
}

--默认AOI宽高
-- local nDefAOIWidth = 720
-- local nDefAOIHeight = 1280
local nDefAOIWidth = 1080
local nDefAOIHeight = 1640

function CDupBase:Ctor(nDupID)
    self.m_nDupID = nDupID

    local tDupConf = ctDupConf[self.m_nDupID]
    local bCanCollected = tDupConf.nType==CDupBase.tType.eDup and true or false
    local nDupMixID, oDupObj = goNativeDupMgr:CreateDup(tDupConf.nType, self.m_nDupID, tDupConf.nMapID, bCanCollected, tDupConf.nLine)
    self.m_nMixID = nDupMixID
    self.m_oNativeObj = oDupObj

    self:InitCallback()
end

function CDupBase:InitCallback()
    self.m_fnOnObjEnterCallback = nil
    self.m_fnOnObjLeaveCallback = nil
    self.m_fnOnObjBattleBeginCallback = nil
    self.m_fnOnBattleEndCallback = nil
    self.m_fnOnLeaveTeamCallback = nil
    self.m_fnOnLeaderActivityCallback = nil
    self.m_fnOnObjDisconnectCallback = nil
    self.m_fnObjAfterEnterCallback = nil
    self.m_fnOnTeamChangeCallback = nil

    self.m_fnEnterCheckCallback = nil
    self.m_fnLeaveCheckCallback = nil

    self.m_fnOnReachTargetPos = nil
end

--销毁副本
function CDupBase:OnRelease()
    --CPP对象不能手动删除,只能设置为自动收集
    self:SetAutoCollected(true)
    self:InitCallback()
    self:KickAllRole()
    self.m_oNativeObj = nil
end

function CDupBase:GetConf() return ctDupConf[self.m_nDupID] end
function CDupBase:GetMapConf() return ctMapConf[self:GetConf().nMapID] end
function CDupBase:GetName() return ctDupConf[self.m_nDupID].sName end
function CDupBase:GetDupID() return self.m_nDupID end
function CDupBase:GetMixID() return self.m_nMixID end
--设置是否可以被收集，自动收集规则: 没有玩家,3分钟后释放
function CDupBase:SetAutoCollected(bCollected) self.m_oNativeObj:SetAutoCollected(bCollected) end

--取角色对象
function CDupBase:GetObj(nAOIID) 
    return self.m_oNativeObj:GetObj(nAOIID)
end

--添加角色的观察者身份
function CDupBase:AddObserver(nAOIID)
    return self.m_oNativeObj:AddObserver(nAOIID)
end

--添加角色的被观察者身份
function CDupBase:AddObserved(nAOIID)
    return self.m_oNativeObj:AddObserved(nAOIID)
end

--移除角色的观察者身份
--@bLeaveScene 是否离开场景,如果是就不会收到被观察者离开视野的回调
function CDupBase:RemoveObserver(nAOIID, bLeaveScene)
    return self.m_oNativeObj:RemoveObserver(nAOIID, bLeaveScene)
end

--移除角色的被观察者身份
function CDupBase:RemoveObserved(nAOIID)
    return self.m_oNativeObj:RemoveObserved(nAOIID)
end

--将所有角色移出副本,会返回到城镇
function CDupBase:KickAllRole()
    local fnGetLuaObjByNativeObj = GetLuaObjByNativeObj 
    local tRoleNativeList = self:GetObjList(-1, gtObjType.eRole)
    for _, oNativeObj in ipairs(tRoleNativeList) do
        local oRole = fnGetLuaObjByNativeObj(oNativeObj)
        if oRole then
            oRole:EnterLastCity()
        end
    end
end

--取副本内某分线所有的角色对象列表
--@nLine -1所有线; >=0指定线
--@nObjType: 游戏对象类型,0表示所有
function CDupBase:GetObjList(nLine, nObjType)
    return self.m_oNativeObj:GetObjList(nLine, nObjType)
end

--取观察该角色的观察者角色对象列表
--@nObjType: 游戏对象类型,0表示所有
function CDupBase:GetAreaObservers(nAOIID, nObjType)
    return self.m_oNativeObj:GetAreaObservers(nAOIID, nObjType)
end

--取该角色观察区域内的角色对象列表
--@nObjType: 游戏对象类型,0表示所有
function CDupBase:GetAreaObserveds(nAOIID, nObjType)
    return self.m_oNativeObj:GetAreaObserveds(nAOIID, nObjType)
end

--广播信息给全场景某分线角色
--@nLine -1所有线; >=0指定线
--@sCmd 指令名
--@tMsg 消息
function CDupBase:BroadcastScene(nLine, sCmd, tMsg)
    local tObjList = self:GetObjList(nLine, gtObjType.eRole)
    if #tObjList <= 0 then
        return
    end
    local tSessionList = {}
    for _, oObj in ipairs(tObjList) do
        local nServer = oObj:GetServerID()
        local nSession = oObj:GetSessionID()
        if nSession > 0 then
            table.insert(tSessionList, nServer)
            table.insert(tSessionList, nSession)
        end
    end
    CmdNet.PBBroadcastExter(sCmd, tSessionList, tMsg)
end

--广播信息给我的观察者角色
--@nAOID 我的AOI编号
--@sCmd 指令名
--@tMsg 消息
function CDupBase:BroadcastObserver(nAOIID, sCmd, tMsg)
    local tObserverList = self:GetAreaObservers(nAOIID, gtObjType.eRole)
    if #tObserverList <= 0 then
        return
    end
    local tSessionList = {}
    for _, oObserver in ipairs(tObserverList) do
        local nServer = oObserver:GetServerID()
        local nSession = oObserver:GetSessionID()
        if nSession > 0 then
            table.insert(tSessionList, nServer)
            table.insert(tSessionList, nSession)
        end
    end
    CmdNet.PBBroadcastExter(sCmd, tSessionList, tMsg)
end


--进入副本
--@oNativeObj: C++对象
--@nPosX,nPosY: 坐标
--@nLine: 0公共线; -1自动分线
--@nFace: 模型方向(左上0,右上1,右下2,左下3)
--返回值: AOIID, 大于0成功; 小于等于0失败
function CDupBase:Enter(oNativeObj, nPosX, nPosY, nLine, nFace)
    assert(type(oNativeObj) == "userdata", "不是CPP对象")
    assert(self.m_oNativeObj, "场景已释放")
    local tDupConf = self:GetConf()
    nPosX = math.max(50, math.min(nPosX, tDupConf.nWidth-50))
    nPosY = math.max(50, math.min(nPosY, tDupConf.nHeight-50))


    nLine = nLine or -1 --默认为自动分线
    nFace = nFace or math.random(0,3)

    --先离开旧副本
    local nCurrMixID = oNativeObj:GetDupMixID()
    if nCurrMixID == self:GetMixID() then
        --角色已经在副本中更新坐标和分线
        local nOldPosX, nOldPosY = oNativeObj:GetPos()
        if nOldPosX ~= nPosX or nOldPosY ~= nPosY then
            oNativeObj:SetPos(nPosX, nPosY)
        end
        local nOldLine = oNativeObj:GetLine()
        if nLine > 0 and nLine ~= nOldLine then
            oNativeObj:SetLine(nLine)
        end

        return
    end
    if nCurrMixID > 0 then
        if oNativeObj.StopRun then
            oNativeObj:StopRun() --停止移动
        end
        goDupMgr:LeaveDup(nCurrMixID, oNativeObj:GetAOIID())
    end

    --掉线的玩家和怪物没有观察者身份
    local nAOIMode = CDupBase.tAOIType.eObserved

    local oLuaObj = GetLuaObjByNativeObj(oNativeObj)
    local bRobot = false 
    if oLuaObj and oLuaObj:GetObjType() == gtObjType.eRole then 
        bRobot = oLuaObj:IsRobot()
    end
    if oNativeObj:GetSessionID() > 0 or bRobot then
        nAOIMode = nAOIMode | CDupBase.tAOIType.eObserver
    end

    --进入新副本
    local nAOIWidth, nAOIHeight = nDefAOIWidth, nDefAOIHeight
    return self.m_oNativeObj:EnterDup(self:GetMixID(), oNativeObj, nPosX, nPosY, nAOIMode, nAOIWidth, nAOIHeight, nLine, nFace)
end

--离开副本
function CDupBase:Leave(nAOIID)
    self.m_oNativeObj:LeaveDup(nAOIID)
end

--事件和回调
function CDupBase:RegObjEnterCallback(fnCallback)
    self.m_fnOnObjEnterCallback = fnCallback
end
function CDupBase:RegObjLeaveCallback(fnCallback)
    self.m_fnOnObjLeaveCallback = fnCallback
end
function CDupBase:RegObjBattleBeginCallback(fnCallback)
    self.m_fnOnObjBattleBeginCallback = fnCallback
end
function CDupBase:RegBattleEndCallback(fnCallback)
    self.m_fnOnBattleEndCallback = fnCallback
end
function CDupBase:RegLeaveTeamCallback(fnCallback)
    self.m_fnOnLeaveTeamCallback = fnCallback
end
function CDupBase:RegLeaderActivityCallback(fnCallback)
    self.m_fnOnLeaderActivityCallback = fnCallback
end
function CDupBase:RegObjDisconnectCallback(fnCallback)
    self.m_fnOnObjDisconnectCallback = fnCallback
end
function CDupBase:RegObjAfterEnterCallback(fnCallback)
    self.m_fnObjAfterEnterCallback = fnCallback
end

function CDupBase:RegTeamChangeCallback(fnCallback)
    self.m_fnOnTeamChangeCallback = fnCallback
end

function CDupBase:RegObjReachTargetPosCallback(fnCallback)
    self.m_fnOnReachTargetPos = fnCallback
end

-- 进入场景前检查回调
-- 需要注意，nRoleID角色，当前不一定在此逻辑服
-- fnCallback(nRoleID, tRoleParam)
-- tRoleParam = {nLevel = , nRoleConfID = , nTeamID = , bLeader = , ...}
-- 返回值 bCanEnter, sReason(tip when failed)
function CDupBase:RegEnterCheckCallback(fnCallback)
    self.m_fnEnterCheckCallback = fnCallback
end

--离开场景前检查回调
--fnCallback(nRoleID)
function CDupBase:RegLeaveCheckCallback(fnCallback)
    self.m_fnLeaveCheckCallback = fnCallback
end

--对象进入
function CDupBase:OnObjEnter(oLuaObj, bReconnet) --这里，还没用计算观察者关系，进行观察者数据同步
    if self.m_fnOnObjEnterCallback then
        self.m_fnOnObjEnterCallback(oLuaObj, bReconnet)
    end
end

--对象退出成功
function CDupBase:OnObjLeave(oLuaObj, nBattleID)
    if self.m_fnOnObjLeaveCallback then
        self.m_fnOnObjLeaveCallback(oLuaObj, nBattleID)
    end
end

function CDupBase:OnObjBattleBegin(oLuaObj)
    if self.m_fnOnObjBattleBeginCallback then 
        self.m_fnOnObjBattleBeginCallback(oLuaObj)
    end
end

--战斗结束
function CDupBase:OnBattleEnd(...)
    if self.m_fnOnBattleEndCallback then
        self.m_fnOnBattleEndCallback(...)
    end
end

--离开队伍
function CDupBase:OnLeaveTeam(oLuaObj)
    if self.m_fnOnLeaveTeamCallback then
        self.m_fnOnLeaveTeamCallback(oLuaObj)
    end
end

--队伍活跃事件
function CDupBase:OnLeaderActivity(oLuaObj, nLastPacketTime)
    if self.m_fnOnLeaderActivityCallback then
        self.m_fnOnLeaderActivityCallback(oLuaObj, nLastPacketTime)
    end
end

--断开连接
function CDupBase:OnObjDisconnect(oLuaObj)
    if self.m_fnOnObjDisconnectCallback then
        self.m_fnOnObjDisconnectCallback(oLuaObj)
    end
end

--进入场景后
function CDupBase:ObjAfterEnter(oLuaObj)
    if self.m_fnObjAfterEnterCallback then
        self.m_fnObjAfterEnterCallback(oLuaObj)
    end
end

--队伍变化
function CDupBase:OnTeamChange(oLuaObj)
    if self.m_fnOnTeamChangeCallback then
        self.m_fnOnTeamChangeCallback(oLuaObj)
    end
end

function CDupBase:OnReachTargetPos(oLuaObj)
    if self.m_fnOnReachTargetPos then 
        self.m_fnOnReachTargetPos(oLuaObj)
    end
end

function CDupBase:DumpSceneObjInfo()
    self.m_oNativeObj:DumpSceneObjInfo()
end

--进入场景检查，即是否允许进入当前场景
function CDupBase:EnterCheck(nRoleID, tRoleParam)
    if not self.m_fnEnterCheckCallback then 
        --对于主城，默认可进入，对于副本，默认不可进入
        local tConf = self:GetConf()
        if CDupBase.tType.eCity == tConf.nType then 
            return true
        end
        return false 
    end
    return self.m_fnEnterCheckCallback(nRoleID, tRoleParam)
end

--离开场景检查，即是否允许离开当前场景
function CDupBase:LeaveCheck(nRoleID)
    if not self.m_fnLeaveCheckCallback then 
        return true 
    end
    return self.m_fnLeaveCheckCallback(nRoleID)
end

