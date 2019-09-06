--副本(包括城镇) 基类
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CDupBase:Ctor(nDupConfID)
    self.m_nDupConfID = nDupConfID
    self.m_nDupID = CUtil:GenDupID(nDupConfID)
    self.m_tSceneList = {}
    self.m_nCreateTime = os.time()
    self:Init()
end

--初始化
function CDupBase:Init()
    local tDupConf = self:GetDupConf()
    for _, tScene in ipairs(tDupConf.tSceneList) do
        local nSceneConfID = tScene[1]
        assert(ctSceneConf[nSceneConfID], "场景不存在:"..nSceneConfID)
        local oSceneLuaObj = CSceneBase:new(self, nSceneConfID)
        table.insert(self.m_tSceneList, oSceneLuaObj)
    end
end

--释放
function CDupBase:Release()
    for _, oSceneLuaObj in ipairs(self.m_tSceneList) do
        oSceneLuaObj:Release()
    end
end

--取副本和场景ID信息
function CDupBase:GetDupSceneInfo()
    local tDupSceneInfo = {
        nDupID = self:GetDupID(),
        tSceneList = {},
    }
    for _, oScene in ipairs(self.m_tSceneList) do
        local nSceneID = oScene:GetSceneID()
        table.insert(tDupSceneInfo.tSceneList, nSceneID)
    end
    return tDupSceneInfo
end

--副本场景列表
function CDupBase:SceneList() return self.m_tSceneList end
--第一个副本场景
function CDupBase:FirstScene() return self.m_tSceneList[1] end
--随机副本场景
function CDupBase:RandScene()
    local nRndIdx = math.random(#self.m_tSceneList)
    local oScene = self.m_tSceneList[nRndIdx]
    return oScene:GetSceneID()
end
--通过ID取副本场景对象
function CDupBase:GetScene(nSceneID)
    for _, oSceneLuaObj in ipairs(self.m_tSceneList) do
        if oSceneLuaObj:GetSceneID() == nSceneID then
            return oSceneLuaObj
        end
    end
end

function CDupBase:GetDupID() return self.m_nDupID end
function CDupBase:GetDupConfID() return self.m_nDupConfID end
function CDupBase:GetDupType() return self:GetDupConf().nDupType end
function CDupBase:GetDupConf() return assert(ctDupConf[self.m_nDupConfID], "副本配置不存在") end

--进入副本场景前检测是否可以进入
--@tGameObjParams 检测用到的游戏对象参数
function CDupBase:BeforeEnterSceneCheck(nSceneID, tGameObjParams)
    local oScene = self:GetScene(nSceneID)
    if not oScene then
        return false, string.format("副本场景不存在 dupconfid:%d sceneconfid:%d", self:GetDupConfID(), CUtil:GetSceneConfID(nSceneID))
    end
    return true
end

--离开副本场景前检测是否可以离开
function CDupBase:BeforeLeaveSceneCheck(nSceneID, oGameLuaObj)
    local oScene = self:GetScene(nSceneID)
    if not oScene then
        return false, string.format("副本场景不存在 dupconfid:%d sceneconfid:%d", self:GetDupConfID(), CUtial:GetSceneConfID(nSceneID))
    end
    return true
end

--进入副本场景,应该由DupMgr统一调用,不应该在其他模块调用,便于统一管理
--@tSceneInfo 副本信息{nDupID=0,nSceneID=0,nPosX=0,nPosY=0,nLine=0,nFace=0}
function CDupBase:EnterScene(oGameLuaObj, tSceneInfo)
    assert(tSceneInfo.nSource == 1, "进入副本场景应该统一由DupMgr模块调用")
    local oScene
    if tSceneInfo.nSceneID > 0 then
        oScene = self:GetScene(tSceneInfo.nSceneID)
    else
        oScene = self:FirstScene()
    end
    assert(oScene, string.format("场景不存在: %s", tSceneInfo))

    local nPosX, nPosY = tSceneInfo.nPosX, tSceneInfo.nPosY
    if not (nPosX or nPosY) then
        nPosX, nPosY = table.unpack(oScene:GetSceneConf().tBornPos[1])
    end
    local nLine = tSceneInfo.nLine or -1
    local nFace = tSceneInfo.nFace or self:GetSceneConf().nInitFace

    oScene:EnterScene(oGameLuaObj, nPosX, nPosY, nLine, nFace)
end

--离开副本场景,应该由DupMgr统一调用,不应该在其他模块调用,便于统一管理
function CDupBase:LeaveScene(oGameLuaObj, tSceneInfo)
    assert(tSceneInfo.nSource == 1, "离开副本场景应该统一由DupMgr模块调用")
    local nSceneID = oGameLuaObj:GetSceneID()
    local oScene = self:GetScene(nSceneID)
    assert(oScene, "场景不存在:"..nSceneID)
    oScene:LeaveScene(oGameLuaObj)
end

--对象进入副本场景事件
function CDupBase:OnObjEnterScene(oSceneLuaObj, oGameLuaObj)
    assert(self:GetScene(oSceneLuaObj:GetSceneID()), "场景不存在:"..oSceneLuaObj:GetSceneID())
    oGameLuaObj:OnEnterScene(self, oSceneLuaObj)
end

--对象离开副本场景事件
--@nNextSceneID 将要进入的副本场景ID
function CDupBase:OnObjLeaveScene(oSceneLuaObj, oGameLuaObj, bSceneReleasedKick, nNextSceneID)
    assert(self:GetScene(oSceneLuaObj:GetSceneID()), "场景不存在:"..oSceneLuaObj:GetSceneID())
    oGameLuaObj:OnLeaveScene(self, oSceneLuaObj, bSceneReleasedKick)
    if not oGameLuaObj:IsReleased() and not self:GetScene(nNextSceneID) then
        self:OnObjLeaveDup(oGameLuaObj) --离开副本
    end
end

--对象离开了整个副本
function CDupBase:OnObjLeaveDup(oGameLuaObj)
    oGameLuaObj:OnLeaveDup(self)
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
