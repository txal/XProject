--副本(包括城镇) 基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CDupBase:Ctor(nDupConfID)
    self.m_nDupConfID = nDupConfID
    self.m_nDupID = CUtil:GenUUID()
    self.m_tSceneList = {}
end

function CDupBase:RandScene()
    local nRndIdx = math.random(#self.m_tSceneList)
    local oScene = self.m_tSceneList[nRndIdx]
    return oScene:GetSceneID()
end

function CDupBase:FirstScene()
    return self.m_tSceneList[1]
end

function CDupBase:GetDupID() return self.m_nDupID end
function CDupBase:GetConfID() return self.m_nDupConfID end
function CDupBase:GetConf() return assert(ctDupConf[self.m_nDupConfID], "副本配置不存在") end
function CDupBase:GetDupType() return self:GetConf().nDupType end

--释放
function CDupBase:Release()
    for _, oSceneLuaObj in ipairs(self.m_tSceneList) do
        oSceneLuaObj:Release()
    end
end

--取场景对象
function CDupBase:GetScene(nSceneID)
    for _, oSceneLuaObj in ipairs(self.m_tSceneList) do
        if oSceneLuaObj:GetSceneID() == nSceneID then
            return oSceneLuaObj
        end
    end
end

--进入场景
function CDupBase:EnterScene(nSceneID, oGameLuaObj, nPosX, nPosY, nLine, nFace)
    local oScene = self:GetScene(nSceneID)
    assert(oScene, "场景不存在:"..nSceneID)

    if not self:_BeforeEnterSceneCheck(nSceneID) then
        return LuaTrace("进入场景检测返回失败", self:GetConfID())
    end
    oScene:EnterScene(oGameLuaObj, nPosX, nPosY, nLine, nFace)
end

--离开场景
function CDupBase:LeaveScene(nSceneID, oGameLuaObj)
    local oScene = self:GetScene(nSceneID)
    assert(oScene, "场景不存在:"..nSceneID)

    if not self:_BeforeLeaveSceneCheck(nSceneID) then
        return LuaTrace("离开场景检测返回失败", self:GetConfID())
    end
    oScene:LeaveScene(oGameLuaObj)
end

--对象进入场景事件
function CDupBase:OnObjEnterScene(oSceneLuaObj, oGameLuaObj)
    assert(self:GetScene(oSceneLuaObj:GetSceneID()), "场景不存在:"..oSceneLuaObj:GetSceneID())
    oGameLuaObj:OnEnterScene(self, oSceneLuaObj)
end

--对象离开场景事件
--@nNextSceneID 将要进入的场景ID
function CDupBase:OnObjLeaveScene(oSceneLuaObj, oGameLuaObj, bKick, bIsRelease, nNextSceneID)
    assert(self:GetScene(oSceneLuaObj:GetSceneID()), "场景不存在:"..oSceneLuaObj:GetSceneID())
    oGameLuaObj:OnLeaveScene(self, oSceneLuaObj, bKick)
    if not bIsRelease and not self:GetScene(nNextSceneID) then
        self:OnObjLeaveDup(oGameLuaObj) --离开副本
    end
end

--对象离开了副本
function CDupBase:OnObjLeaveDup(oGameLuaObj)
end

--对象进入视野事件
function CDupBase:OnObjEnterObj(oSceneLuaObj, tObserver, tObserved)
    assert(self:GetScene(oSceneLuaObj:GetSceneID()), "场景不存在:"..oSceneLuaObj:GetSceneID())
    for k = 1, #tObserver do
        local oGameNativeObj = tObserver[k]
        local oGameLuaObj = oGameNativeObj:GetLuaObj()
        assert(oGameLuaObj, "游戏对象未绑定LUA对象")
        oGameLuaObj:OnObjEnterView(tObserved)
    end
end

--对象离开视野事件
function CDupBase:OnObjLeaveObj(oSceneLuaObj, tObserver, tObserved)
    assert(self:GetScene(oSceneLuaObj:GetSceneID()), "场景不存在此副本中")
    local tSessionList = {}
    for k = 1, #tObserver do
        local oGameNativeObj = tObserver[k]
        local oGameLuaObj = oGameNativeObj:GetLuaObj()
        assert(oGameLuaObj, "游戏对象为绑定LUA对象")
        oGameLuaObj:OnObjLeaveView(tObserved)

        local nSessionID = oGameNativeObj:GetSessionID()
        if nSessionID > 0 then
            local nServerID = oGameNativeObj:GetServerID()
            table.insert(tSessionList, nServerID)
            table.insert(tSessionList, nSessionID)
        end
    end
    local tAOIIDList = {}
    for k = 1, #tObserved do
        table.insert(tAOIIDList, tObserved[k]:GetAOIID())
    end
    Network.PBBroadcastExter("ObjLeaveViewRet", tSessionList, {tList=tAOIIDList})
end

--对象移动到达某个坐标点
function CDupBase:OnObjReachTargetPos(oSceneLuaObj, oGameLuaObj, nPosX, nPosY)
    assert(self:GetScene(oSceneLuaObj:GetSceneID()), "场景不存在此副本中")
    oGameLuaObj:OnObjReachTargetPos(nPosX, nPosY)
end
