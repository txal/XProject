local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CScene:Ctor(nSceneConfID, nBattleType)
    assert(nBattleType)
    local tSceneConf = assert(ctSceneConf[nSceneConfID])
    local nSceneIndex, oCppScene = goCppSceneMgr:CreateScene(nSceneConfID
        , tSceneConf.nMapID, tSceneConf.nWidth, tSceneConf.nHeight, tSceneConf.bCollected
        , nBattleType)
    self.m_nSceneIndex = nSceneIndex 
    self.m_oCppScene = oCppScene
end

function CScene:GetSceneIndex() return self.m_nSceneIndex end
function CScene:GetSceneID() return goLuaSceneMgr:GetSceneConfID(self.m_nSceneIndex) end
function CScene:GetCppScene() return self.m_oCppScene end
function CScene:KickAllPlayer() if self.m_oCppScene then self.m_oCppScene:KickAllPlayer() end end 
function CScene:RemoveObj(nAOIObjID) self.m_oCppScene:RemoveObj(nAOIObjID) end
function CScene:GetObj(nAOIObjID) return self.m_oCppScene:GetObj(nAOIObjID) end

--被动
function CScene:OnRelease()
    self.m_oCppScene = nil
end

--主动
function CScene:Destroy()
    goCppSceneMgr:RemoveScene(self.m_nSceneIndex)
    goLuaSceneMgr:OnSceneRelease(self.m_nSceneIndex)
end

--取玩家会话列表:bSelf是否包含自己
function CScene:GetSessionList(nAOIID, bSelf)
    local tSessionList = {}
    local tObserverList = self.m_oCppScene:GetAreaObservers(nAOIID, gtObjType.ePlayer)
    for _, oObj in ipairs(tObserverList) do
        local sObjID = oObj:GetObjID()
        local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sObjID)
        if oPlayer then
            table.insert(tSessionList, oPlayer:GetSession())
        end
    end
    if bSelf then
        local oObj = self:GetObj(nAOIID)
        local sObjID = oObj and oObj:GetObjID() or ""
        local oPlayer = goLuaPlayerMgr:GetPlayerByCharID(sObjID)
        if oPlayer then
            table.insert(tSessionList, oPlayer:GetSession())
        end
    end
    return tSessionList
end

function CScene:_add_obj(oCppGameObj, nPosX, nPosY, nAOIMode, nAOIWidth, nAOIHeight)
    local tSceneConf = goLuaSceneMgr:GetSceneConfByIndex(self.m_nSceneIndex)
    if not nAOIWidth or not nAOIHeight then
        nAOIWidth, nAOIHeight = tSceneConf.nWidth, tSceneConf.nHeight
    end
    local nAOIType = gtSceneDef.tAOI.eTypeRect
    local nAOIObjID = self.m_oCppScene:AddObj(oCppGameObj, nPosX, nPosY, nAOIMode, nAOIType, nAOIWidth, nAOIHeight)
    return nAOIObjID
end

--赋予对象观察者身份
function CScene:AddObserver(oCppGameObj)
    self.m_oCppScene:AddObserver(oCppGameObj:GetAOIID())
end

--赋予对像被观察者身份
function CScene:AddObserved(oCppGameObj)
    self.m_oCppScene:AddObserved(oCppGameObj:GetAOIID())
end

function CScene:AddPlayer(oCppGameObj, nPosX, nPosY)
    assert(oCppGameObj:GetObjType() == gtObjType.ePlayer)
    local nAOIMode = gtSceneDef.tAOI.eModeNone
    return self:_add_obj(oCppGameObj, nPosX, nPosY, nAOIMode)
end

function CScene:AddMonster(oCppGameObj, nPosX, nPosY)
    assert(oCppGameObj:GetObjType() == gtObjType.eMonster)
    local nAOIMode = gtSceneDef.tAOI.eModeObserved | gtSceneDef.tAOI.eModeObserver
    return self:_add_obj(oCppGameObj, nPosX, nPosY, nAOIMode)
end

function CScene:AddRobot(oCppGameObj, nPosX, nPosY)
    assert(oCppGameObj:GetObjType() == gtObjType.eRobot)
    local nAOIMode = gtSceneDef.tAOI.eModeObserved | gtSceneDef.tAOI.eModeObserver
    return self:_add_obj(oCppGameObj, nPosX, nPosY, nAOIMode)
end

function CScene:AddDropItem(oCppGameObj, nPosX, nPosY)
    assert(oCppGameObj:GetObjType() == gtObjType.eSceneDrop)
    local nAOIMode = gtSceneDef.tAOI.eModeObserved
    return self:_add_obj(oCppGameObj, nPosX, nPosY, nAOIMode, 0, 0)
end

--战斗结束
function CScene:BattleResult()
    self.m_oCppScene:BattleResult()
end