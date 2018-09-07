function CSceneMgr:Ctor()
    self.m_tSceneMap = {}
    self:CreateScene(self:GetBeginnerScene(), gtBattleType.eTest)
end

function CSceneMgr:GetSceneConfID(nSceneIndex)
    local nSceneConfID = nSceneIndex & 0xFFFF
    return nSceneConfID
end

function CSceneMgr:GetSceneConfByID(nSceneConfID)
    return ctSceneConf[nSceneConfID]
end

function CSceneMgr:GetSceneConfByIndex(nSceneIndex)
    local nSceneConfID = self:GetSceneConfID(nSceneIndex)
    return ctSceneConf[nSceneConfID]
end

function CSceneMgr:GetSceneByIndex(nSceneIndex)
    local nSceneConfID = self:GetSceneConfID(nSceneIndex)
    local tSceneMap = self.m_tSceneMap[nSceneConfID]
    return tSceneMap and tSceneMap[nSceneIndex]
end

function CSceneMgr:GetSceneByID(nSceneConfID)
    local tSceneMap = self.m_tSceneMap[nSceneConfID] or {}
    local nSceneIndex, oScene = next(tSceneMap)
    return oScene
end

function CSceneMgr:CreateScene(nSceneConfID, nBattleType)
    assert(nBattleType, "必须设置战斗类型")
    assert(ctSceneConf[nSceneConfID], "场景不存在")
    local oScene = CScene:new(nSceneConfID, nBattleType)
    local nSceneIndex = oScene:GetSceneIndex()
    self.m_tSceneMap[nSceneConfID] = self.m_tSceneMap[nSceneConfID] or {}
    self.m_tSceneMap[nSceneConfID][nSceneIndex] = oScene
    return oScene
end

function CSceneMgr:OnSceneRelease(nSceneIndex)
    local nSceneConfID = self:GetSceneConfID(nSceneIndex)
    local tSceneMap = self.m_tSceneMap[nSceneConfID] or {}
    local oScene = tSceneMap[nSceneIndex]
    if oScene then
        oScene:OnRelease()
    end
    tSceneMap[nSceneIndex] = nil
end

--新手村
function CSceneMgr:GetBeginnerScene()
    return 100
end


goCppSceneMgr = GlobalExport.GetSceneMgr()
goLuaSceneMgr = goLuaSceneMgr or CSceneMgr:new()