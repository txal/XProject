--副本(包括城镇)管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CDupMgr:Ctor()
    self.m_tDupMap = {}
    self.m_tDupConfMap = {}
end

--初始化,GModuleMgr调用
function CDupMgr:Init()
    for nDupID, tConf in pairs(ctDupConf) do
        if tConf.nDupType == gtGDef.tDupType.eCity and tConf.nLogicService == CUtil:GetServiceID() then
            self:CreateDup(nDupID)
        end
    end
end

function CDupMgr:GetDup(nDupID)
	return self.m_tDupMap[nDupID]
end

--创建副本
--@nDupConfID: 副本配置ID,必填
--@tParams: 额外参数,可选
--@fnCallback: 回调,必填
function CDupMgr:CreateDup(nDupConfID, tParams, fnCallback)
    assert(nDupConfID and fnCallback, "参数错误")

    local tDupConf = assert(ctDupConf[nDupConfID], string.format("副本不存在:%d", nDupConfID))
    if CUtil:GetServiceID() == tDupConf.nLogicServiceID then
        local cDupClass = assert(gtGDef.tDupClass[tDupConf.nDupType], string.format("副本类未定义:%d", nDupConfID))
        local oDup = cDupClass:new(nDupConfID, tParams)
        self.m_tDupMap[oDup:GetDupID()] = oDup
        self:AddDupConfMap(oDup)
        local tDupSceneInfo = oDup:GetDupSceneInfo()
        fnCallback(tDupSceneInfo)
    else
        local nServerID = CUtil:GetServerByLogic(tDupConf.nLogicServiceID)
        Network:RMCall("CreateDupReq", fnCallback, nServerID, tDupConf.nLogicServiceID, 0, nDupConfID, tParams)
    end
end

--移除副本
--@nDupID: 副本唯一ID,必填
function CDupMgr:RemoveDup(nDupID)
    local nDupConfID = CUtil:GetDupConfID(nDupID)
    local tDupConf = assert(ctDupConf[nDupConfID], string.format("副本不存在: %d", nDupConfID))
    if CUtil:GetServiceID() == tDupConf.nLogicServiceID then
        local oDup = self:GetDup(nDupID)
        if not oDup then 
            return LuaTrace("副本不存在", nDupID)
        end
        oDup:Release()
        self.m_tDupMap[nDupID] = nil
        self:RemoveDupConfMap(oDup)
    else
        local nServerID = CUtil:GetServerByLogic(tDupConf.nLogicServiceID)
        Network:RMCall("RemoteDupReq", nil, nServerID, tDupConf.nLogicServiceID, 0, nDupID)
    end
end

--添加副本配置ID到副本映射
function CDupMgr:AddDupConfMap(oDup)
    local tDupConf = oDup:GetDupConf()
    if not self.m_tDupConfMap[tDupConf.nID] then
        self.m_tDupConfMap[tDupConf.nID] = {}
    end
    self.m_tDupConfMap[tDupConf.nID][oDup:GetDupID()] = oDup
end

--移除副本配置ID到副本映射
function CDupMgr:RemoveDupConfMap(oDup)
    local tDupConf = oDup:GetDupConf()
    if not self.m_tDupConfMap[tDupConf.nID] then
        return
    end
    self.m_tDupConfMap[tDupConf.nID][oDup:GetDupID()] = nil
end

--进入场景前检测
--@tSceneInfo 场景信息{nDupID=0,nSceneID=0,nPosX=0,nPosY=0,nLine=0,nFace=0},必填
--@tGameObjParams 进入场景需要的检测数据,必填
--@fnCallback 回调,必填
function CDupMgr:BeforeEnterSceneCheck(tSceneInfo, tGameObjParams, fnCallback)
    assert(tSceneInfo and tGameObjParams and fnCallback, "参数错误")

    local nDupConfID = CUtil:GetDupConfID(tSceneInfo.nDupID)
    local tDupConf = assert(ctDupConf[nDupConfID], string.format("副本配置不存在: %d", nDupConfID))

    --本地逻辑服
    if CUtil:GetServiceID() == tDupConf.nLogicServiceID then
        local bCanEnter, sError
        local oDup = self:GetDup(tSceneInfo.nDupID)
        if not oDup then
            bCanEnter, sError = false, string.format("副本不存在 dupid:%d dupconfid:%d", tSceneInfo.nDupID, nDupConfID)
        else
            bCanEnter, sError = oDup:BeforeEnterSceneCheck(tSceneInfo.nSceneID, tGameObjParams)
        end
        fnCallback(bCanEnter, sError)

    --跨逻辑服
    else
        local nServerID = CUtil:GetServerByLogic(tDupConf.nLogicServiceID)
        Network:RMCall("BeforeEnterSceneCheckReq", fnCallback, nServerID, tDupConf.nLogicServiceID, 0 tSceneInfo, tGameObjParams)
    end
end

--进入副本中的场景
--@oGameLuaObj: 游戏LUA对象
--@tSceneInfo: 同上
function CDupMgr:EnterScene(oGameLuaObj, tSceneInfo)
    local function _fnQueryDupSceneCallback(tDupSceneInfo)
        if oGameLuaObj:IsReleased() then
            return LuaTrace("CDupMgr:EnterScene 远程调用过程中游戏对象已释放")
        end
        if not tDupSceneInfo then
            return oGameLuaObj:Tips("副本不存在")
        end
        local function _fnEnterSceneCheckCallback(bCanEnter, sError)
            if oGameLuaObj:IsReleased() then
                return LuaTrace("CDupMgr:EnterScene 远程调用过程中游戏对象已释放")
            end
            if not bCanEnter then
                return oGameLuaObj:Tips(sError)
            end

            --本地逻辑服
            local nDupConfID = CUtil:GetDupConfID(tSceneInfo.nDupID)
            local tDupConf = ctDupConf[nDupConfID]
            if CUtil:GetServiceID() == tDupConf.nLogicServiceID then
                local oDup = self:GetDup(tSceneInfo.nDupID)
                if not oDup then
                    return oGameLuaObj:Tips(tring.format("副本不存在 dupid:%d dupconfid:%d", tSceneInfo.nDupID, nDupConfID))
                end
                tSceneInfo.nSource = 1 --做个调用来源标记
                oDup:EnterScene(oGameLuaObj, tSceneInfo)

            --跨逻辑服
            else
                if not oGameLuaObj:IsSwitchLogicObjType() then
                    assert(false, "对象类型不能切换逻辑服:"..oGameLuaObj:GetObjType())
                end
                local tSwitchData = oGameLuaObj:MakeSwitchLogicData(tSceneInfo)
                self:SwitchLogic(tSwitchData)

            end
        end

        local tGameObjParams = oGameLuaObj:GetSceneEnterCheckParams()
        self:BeforeEnterSceneCheck(tSceneInfo, tGameObjParams, _fnEnterSceneCheckCallback)
    end
    self:QueryDupSceneByDupID(tSceneInfo.nDupID, _fnQueryDupSceneCallback)
end

--发起切换逻辑服
function CDupMgr:SwitchLogic(oGameLuaObj, tSwitchData)
    assert(tSwitchData.tSrcDupInfo.nDupID ~= tSwitchData.tTarDupInfo.nDupID, "切换逻辑服数据错误")
    GetGModule("RoleMgr"):RoleOfflineReq(tSwitchData.nObjID, true) --先把当前逻辑服的角色下了
    Network:RMCall("SwitchLogicReq", nil, tSwitchData.nTarServerID, tSwitchData.nTarServiceID, tSwitchData.nSessionID, tSwitchData)
end

--离开场景前检测
--@tSceneInfo 同上
function CDupMgr:BeforeLeaveSceneCheck(tSceneInfo, oGameLuaObj)
    local nDupConfID = CUtil:GetDupConfID(tSceneInfo.nDupID)
    local bCanLeave, sError
    local oDup = self:GetDup(tSceneInfo.nDupID)
    if not oDup then
        bCanLeave, sError = false, string.format("副本不存在 dupid:%d dupconfid:%d", tSceneInfo.nDupID, nDupConfID)
    else
        bCanLeave, sError = oDup:BeforeLeaveSceneCheck(tSceneInfo.nSceneID, oGameLuaObj)
    end
    return bCanLeave, sError
end

--离开当前所在副本中的场景
function CDupMgr:LeaveScene(oGameLuaObj)
    local tSceneInfo = {
        nDupID = oGameLuaObj:GetDupID(),
        nSceneID = oGameLuaObj:GetSceneID(),
        nSource = 1,
    } 
    local bCanLeave, sError = self:BeforeLeaveSceneCheck(tSceneInfo, oGameLuaObj)
    if not bCanLeave then
        return oGameLuaObj:Tips(sError)
    end
    local oDup = oGameLuaObj:GetDup()
    oDup:LeaveScene(oGameLuaObj, tSceneInfo)
end

--去角色当前场景观察者的角色ID列表,不包括自己
function CDupMgr:GetRoleObserverList(oRole)
    local tRoleIDList = {}
    local oScene = oRole:GetScene()
    local tNativeObjList = oScene:GetAreaObservers(oRole:GetObjID(), gtGDef.tObjType.eRole)
    for _, oNativeObj in ipairs(tNativeObjList) do
        table.insert(tRoleIDList, oNativeObj:GetObjID())
    end
    return tRoleIDList
end

--查询副本信息,回调返回副本信息
function CDupMgr:QueryDupSceneByDupID(nDupID, fnCallback)
    assert(nDupID and fnCallback, "参数错误")

    local nDupConfID = CUtil:GetDupConfID(nDupID)
    local tDupConf = assert(ctDupConf[nDupConfID], "副本配置不存在:"..nDupConfID)

    if tDupConf.nLogicServiceID == CUtil:GetServiceID() then 
        local tDupSceneInfo
        local oDup = self:GetDup(nDupID)
        if oDup then
            tDupSceneInfo = oDup:GetDupSceneInfo()
        end
        fnCallback(tDupSceneInfo)

    else
        local nServerID = CUtil:GetServerByLogic(tDupConf.nLogicServiceID)
        Network:RMCall("QueryDupSceneByDupIDReq", fnCallback, nServerID, tDupConf.nLogicServiceID, 0, nDupID)
    end
end

function CDupMgr:QueryCityByDupConfID(nDupConfID)
    local tDupConf = assert(ctDupConf[nDupConfID], "副本配置不存在:"..nDupConfID)
    assert(tDupConf.nDupType == gtGDef.tDupType.eCity, "副本类型错误")
    local tDupMap = self.m_tDupConfMap[nDupConfID]
    if not tDupMap then
        return
    end
    local nDupID, oDup = next(tDupMap)
    return oDup:GetDupSceneInfo()
end

function CDupMgr:OnMinTimer()
    self:PrintDupData()
end

--取副本数量
function CDupMgr:GetDupCount()
    local nCount = 0
    for k, v in pairs(self.m_tDupMap) do
        nCount = nCount + 1
    end
    return nCount
end

function CDupMgr:PrintDupData()
    LuaTrace(string.format("当前场景总数量%d", self:GetDupCount()))
    local tDupDataMap = {}
    for nDupID, oDup in pairs(self.m_tDupMap) do
        local tDupConf = oDup:GetDupConf()
        tDupDataMap[tDupConf.nID] = (tDupDataMap[tDupConf.nID] or 0) + 1
    end
    for nDupConfID, nCount in pairs(tDupDataMap) do
        local tDupConf = ctDupConf[nDupConfID]
        LuaTrace(string.format("场景配置ID(%d) 场景类型(%d) 名称(%s) 数量(%d)", nDupConfID, tDupConf.nDupType, tDupConf.sName, nCount))
    end
end
