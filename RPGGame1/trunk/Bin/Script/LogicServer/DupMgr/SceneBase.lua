--场景基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert
--CPP场景管理器
local oNativeSceneMgr = GlobalExport.GetSceneMgr()

function CSceneBase:Ctor(oParentDup, nSceneType, nMapID, nLineRoles)
    self.m_oParentDup = oParentDup
    self.m_nSceneType = nSceneType
    self.m_nMapID = nMapID
    self.m_nLineRoles = nLineRoles
    self.m_nSceneID = CUtil:GenUUID()

    self.m_oNativeScene = oNativeSceneMgr:CreateScene(nSceneType, self.m_nSceneID, nMapID, nLineRoles)
    self.m_oNativeScene:BindLuaObj(self)
end

--销毁场景
function CSceneBase:Release()
    oNativeSceneMgr:RemoveScene(self.m_nSceneID)
end

function CSceneBase:GetParentDup() return self.m_oParentDup end
--将场景内所有类型为nObjType的对象踢出场景
--@nObjType 要提出场景的对象类型,0为所有
function CSceneBase:GetSceneID() return self.m_nSceneID end
function CSceneBase:GetMapConf() return ctMapConf[self.m_nMapID] end
function CSceneBase:DumpSceneInfo() self.m_oNativeScene:DumpSceneInfo() end
function CSceneBase:GetGameObj(nAOIID) return self.m_oNativeScene:GetGameObj(nAOIID) end
function CSceneBase:KickAllObjs(nObjType) self.m_oNativeScene:KickAllGameObjs(nObjType) end
--添加角色的观察者身份
function CSceneBase:AddObserver(nAOIID) return self.m_oNativeScene:AddObserver(nAOIID) end
--添加角色的被观察者身份
function CSceneBase:AddObserved(nAOIID) return self.m_oNativeScene:AddObserved(nAOIID) end
--移除角色的观察者身份
--@bLeaveScene 是否离开场景,如果是就不会收到被观察者离开视野的回调
function CSceneBase:RemoveObserver(nAOIID, bLeaveScene) return self.m_oNativeScene:RemoveObserver(nAOIID, bLeaveScene) end
--移除角色的被观察者身份
function CSceneBase:RemoveObserved(nAOIID) return self.m_oNativeScene:RemoveObserved(nAOIID) end
--取场景内某分线所有的角色对象列表
--@nLine -1所有分线; >=0指定分线
--@nObjType: 游戏对象类型,0表示所有
--返回Native对象
function CSceneBase:GetGameObjList(nLine, nObjType) return self.m_oNativeScene:GetObjList(nLine, nObjType) end
--取观察该角色的观察者角色对象列表
--@nObjType: 游戏对象类型,0表示所有
function CSceneBase:GetAreaObservers(nAOIID, nObjType) return self.m_oNativeScene:GetAreaObservers(nAOIID, nObjType) end
--取该角色观察区域内的角色对象列表
--@nObjType: 游戏对象类型,0表示所有
function CSceneBase:GetAreaObserveds(nAOIID, nObjType) return self.m_oNativeScene:GetAreaObserveds(nAOIID, nObjType) end

--广播信息给场景某分线所有角色
--@nLine -1所有分线; >=0指定分线
--@sCmd 指令名
--@tMsg 消息
function CSceneBase:BroadcastScene(nLine, sCmd, tMsg)
    local tObjList = self:GetGameObjList(nLine, gtGDef.tObjType.eRole)
    if #tObjList <= 0 then
        return
    end
    local tSessionList = {}
    for _, oGameNativeObj in ipairs(tObjList) do
        local nServerID = oGameNativeObj:GetServerID()
        local nSessionID = oGameNativeObj:GetSessionID()
        if nServerID > 0 and nSessionID > 0 then
            table.insert(tSessionList, nServerID)
            table.insert(tSessionList, nSessionID)
        end
    end
    Network.PBBroadcastExter(sCmd, tSessionList, tMsg)
end

--广播信息给我的观察者角色
--@nAOID 我的AOI编号
--@sCmd 指令名
--@tMsg 消息
function CSceneBase:BroadcastObserver(nAOIID, sCmd, tMsg)
    local tObserverList = self:GetAreaObservers(nAOIID, gtGDef.tObjType.eRole)
    if #tObserverList <= 0 then
        return
    end
    local tSessionList = {}
    for _, oObserver in ipairs(tObserverList) do
        local nSessionID = oObserver:GetSessionID()
        if nSessionID > 0 then
            local nServerID = oObserver:GetServerID()
            table.insert(tSessionList, nServerID)
            table.insert(tSessionList, nSessionID)
        end
    end
    Network.PBBroadcastExter(sCmd, tSessionList, tMsg)
end


--进入场景
--@oGameLuaObj: 游戏LUA对象
--@nPosX,nPosY: 坐标
--@nLine: 0公共分线; -1自动分线
--返回值: AOIID, 大于0成功; 小于等于0失败
function CSceneBase:EnterScene(oGameLuaObj, nPosX, nPosY, nLine)
    assert(self.m_oNativeScene, "场景已释放")
    local oGameNativeObj = oGameLuaObj:GetNativeObj()
    assert(oGameNativeObj, "获取对象CPP对象失败")

    local tMapConf = self:GetMapConf()
    nPosX = math.max(10, math.min(nPosX, tMapConf.nWidth-10))
    nPosY = math.max(10, math.min(nPosY, tMapConf.nHeight-10))
    nLine = nLine or -1 --默认为自动分线

    --先离开旧场景
    local nCurrSceneID = oGameLuaObj:GetSceneID()
    if nCurrSceneID == self:GetSceneID() then
        --角色已经在场景中更新坐标和分线
        local nOldPosX, nOldPosY = oGameLuaObj:GetPos()
        if nOldPosX ~= nPosX or nOldPosY ~= nPosY then
            oGameLuaObj:SetPos(nPosX, nPosY)
        end
        local nOldLine = oGameLuaObj:GetLine()
        if nLine > 0 and nLine ~= nOldLine then
            oGameLuaObj:SetLine(nLine)
        end
        return
    end
    if nCurrSceneID > 0 then
        oGameLuaObj:StopRun()
        oGameLuaObj:SetNextSceneID(self.m_nSceneID) --设置将要进入的场景ID
        oGameLuaObj:LeaveScene()
    end

    --掉线的玩家和怪物没有观察者身份
    local nAOIMode = gtAOIType.eObserved
    if oGameLuaObj:IsOnline() then
        nAOIMode = nAOIMode | gtAOIType.eObserver
    end

    --进入新场景
    local nAOIWidth = gtAOISize.eWidth
    local nAOIHeight = gtAOISize.eHeight
    return self.m_oNativeScene:EnterScene(self:GetSceneID(), oNativeNativeObj, nPosX, nPosY, nAOIMode, nAOIWidth, nAOIHeight, nLine)
end

--离开场景
--@nNextSceneID 将要进入的场景ID
function CSceneBase:LeaveScene(oGameLuaObj)
    local nAOIID = oGameLuaObj:GetAOIID()
    self.m_oNativeScene:LeaveScene(nAOIID)
end

--对象进入场景事件
function CSceneBase:OnObjEnterScene(oGameNativeObj)
    local oGameLuaObj = oGameNativeObj:GetLuaObj()
    assert(oGameLuaObj, "游戏对象未绑定LUA对象")
    self.m_oParentDup:OnObjEnterScene(self, oGameLuaObj)
end

--对象离开场景事件
function CSceneBase:OnObjLeaveScene(oGameNativeObj, bKick)
    local oGameLuaObj = oGameNativeObj:GetLuaObj()
    assert(oGameLuaObj, "游戏对象未绑定LUA对象")
    local bIsRelease = oGameLuaObj:IsRelease()
    local nNextSceneID = oGameLuaObj:GetNextSceneID()
    oGameLuaObj:SetNextSceneID(nil)
    self.m_oParentDup:OnObjLeaveScene(self, oGameLuaObj, bKick, bIsRelease, nNextSceneID)
end

function CSceneBase:OnObjEnterObj(tObserver, tObserved)
    self.m_oParentDup:OnObjEnterObj(self, tObserver, tObserved)
end

function CSceneBase:OnObjLeaveObj(tObserver, tObserved)
    self.m_oParentDup:OnObjLeaveObj(self, tObserver, tObserved)
end

function CSceneBase:OnObjReachTargetPos(oGameNativeObj, nPosX, nPosY)
    local oGameLuaObj = oGameNativeObj:GetLuaObj()
    assert(oGameLuaObj, "游戏对象未绑定LUA对象")
    self.m_oParentDup:OnObjReachTargetPos(self, oGameLuaObj, nPosX, nPosY)
end





















--事件和回调
function CSceneBase:RegObjEnterCallback(fnCallback)
    self.m_fnOnObjEnterCallback = fnCallback
end
function CSceneBase:RegObjLeaveCallback(fnCallback)
    self.m_fnOnObjLeaveCallback = fnCallback
end
function CSceneBase:RegObjBattleBeginCallback(fnCallback)
    self.m_fnOnObjBattleBeginCallback = fnCallback
end
function CSceneBase:RegBattleEndCallback(fnCallback)
    self.m_fnOnBattleEndCallback = fnCallback
end
function CSceneBase:RegLeaveTeamCallback(fnCallback)
    self.m_fnOnLeaveTeamCallback = fnCallback
end
function CSceneBase:RegLeaderActivityCallback(fnCallback)
    self.m_fnOnLeaderActivityCallback = fnCallback
end
function CSceneBase:RegObjDisconnectCallback(fnCallback)
    self.m_fnOnObjDisconnectCallback = fnCallback
end
function CSceneBase:RegJoinTeamCallback(fnCallback)
    self.m_fnOnTeamChangeCallback = fnCallback
end
function CSceneBase:RegObjReachTargetPosCallback(fnCallback)
    self.m_fnOnReachTargetPos = fnCallback
end

-- 进入场景前检查回调
-- 需要注意，nRoleID角色，当前不一定在此逻辑服
-- fnCallback(nRoleID, tRoleParam)
-- tRoleParam = {nLevel = , nRoleConfID = , nTeamID = , bLeader = , ...}
-- 返回值 bCanEnter, sReason(tip when failed)
function CSceneBase:RegEnterCheckCallback(fnCallback)
    self.m_fnEnterCheckCallback = fnCallback
end

--离开场景前检查回调
--fnCallback(nRoleID)
function CSceneBase:RegLeaveCheckCallback(fnCallback)
    self.m_fnLeaveCheckCallback = fnCallback
end

function CSceneBase:OnObjBattleBegin(oLuaObj)
    if self.m_fnOnObjBattleBeginCallback then 
        self.m_fnOnObjBattleBeginCallback(oLuaObj)
    end
end

--战斗结束
function CSceneBase:OnBattleEnd(...)
    if self.m_fnOnBattleEndCallback then
        self.m_fnOnBattleEndCallback(...)
    end
end

--离开队伍
function CSceneBase:OnLeaveTeam(oLuaObj)
    if self.m_fnOnLeaveTeamCallback then
        self.m_fnOnLeaveTeamCallback(oLuaObj)
    end
end

--队伍活跃事件
function CSceneBase:OnLeaderActivity(oLuaObj, nLastPacketTime)
    if self.m_fnOnLeaderActivityCallback then
        self.m_fnOnLeaderActivityCallback(oLuaObj, nLastPacketTime)
    end
end

--对象进入
function CSceneBase:OnObjEnterScene(oLuaObj, bReconnet) --这里，还没用计算观察者关系，进行观察者数据同步
    if self.m_fnOnObjEnterCallback then
        self.m_fnOnObjEnterCallback(oLuaObj, bReconnet)
    end
end

--对象退出成功
function CSceneBase:OnObjLeaveScene(oLuaObj, nBattleID)
    if self.m_fnOnObjLeaveCallback then
        self.m_fnOnObjLeaveCallback(oLuaObj, nBattleID)
    end
end

--断开连接
function CSceneBase:OnObjDisconnect(oLuaObj)
    if self.m_fnOnObjDisconnectCallback then
        self.m_fnOnObjDisconnectCallback(oLuaObj)
    end
end

function CSceneBase:OnReachTargetPos(oLuaObj)
    if self.m_fnOnReachTargetPos then 
        self.m_fnOnReachTargetPos(oLuaObj)
    end
end

function CSceneBase:DumpSceneObjInfo()
    self.m_oNativeScene:DumpSceneObjInfo()
end

--进入场景检查，即是否允许进入当前场景
function CSceneBase:EnterCheck(nRoleID, tRoleParam)
    if not self.m_fnEnterCheckCallback then 
        --对于主城，默认可进入，对于场景，默认不可进入
        local tConf = self:GetConf()
        if CSceneBase.tType.eCity == tConf.nType then 
            return true
        end
        return false 
    end
    return self.m_fnEnterCheckCallback(nRoleID, tRoleParam)
end

--离开场景检查，即是否允许离开当前场景
function CSceneBase:LeaveCheck(nRoleID)
    if not self.m_fnLeaveCheckCallback then 
        return true 
    end
    return self.m_fnLeaveCheckCallback(nRoleID)
end

