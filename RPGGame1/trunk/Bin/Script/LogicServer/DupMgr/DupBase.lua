--副本/城镇 基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CDupBase:Ctor(nDupConfID)
    self.m_nDupConfID = nDupConfID
    self.m_nDupID = CUtil:GenUUID()
    self.m_tSceneMap = {}
end

--对象进入场景事件
function CDupBase:OnObjEnterScene(oSceneLuaObj, oGameLuaObj)
    assert(self.m_tSceneMap[oSceneLuaObj:GetSceneID()], "场景不存在此副本/城镇中")
    oGameLuaObj:OnEnterScene(self, oSceneLuaObj)
end

--对象离开场景事件
--@nNextSceneID 将要进入的场景ID
function CDupBase:OnObjLeaveScene(oSceneLuaObj, oGameLuaObj, bKick, bIsRelease, nNextSceneID)
    assert(self.m_tSceneMap[oSceneLuaObj:GetSceneID()], "场景不存在此副本/城镇中")
    oGameLuaObj:OnLeaveScene(self, oSceneLuaObj, bKick)
    if not bIsRelease and not self.m_tSceneMap[nNextSceneID] then
        self:OnObjLeaveDup(oGameLuaObj) --离开副本/城镇
    end
end

--对象离开了副本/城镇
function CDupBase:OnObjLeaveDup(oGameLuaObj)
end

--对象进入视野事件
function CDupBase:OnObjEnterObj(oSceneLuaObj, tObserver, tObserved)
    assert(self.m_tSceneMap[oSceneLuaObj:GetSceneID()], "场景不存在此副本/城镇中")
    for k = 1, #tObserver do
        local oGameNativeObj = tObserver[k]
        local oGameLuaObj = oGameNativeObj:GetLuaObj()
        assert(oGameLuaObj, "游戏对象未绑定LUA对象")
        oGameLuaObj:OnObjEnterView(tObserved)
    end
end

--对象离开视野事件
function CDupBase:OnObjLeaveObj(oSceneLuaObj, tObserver, tObserved)
    assert(self.m_tSceneMap[oSceneLuaObj:GetSceneID()], "场景不存在此副本/城镇中")
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
    assert(self.m_tSceneMap[oSceneLuaObj:GetSceneID()], "场景不存在此副本/城镇中")
    oGameLuaObj:OnObjReachTargetPos(nPosX, nPosY)
end
