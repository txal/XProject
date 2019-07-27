--副本(包括城镇)管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert

function CDupMgr:Ctor()
    self.m_tDupMap = {}
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

function CDupMgr:GetDupCount()
	local nCount = 0
	for k, v in pairs(self.m_tDupMap) do
		nCount = nCount + 1
	end
	return nCount
end

--创建副本
--@nDupConfID: 副本配置ID
function CDupMgr:CreateDup(nDupConfID, tParams)
    local tDupConf = assert(ctDupConf[nDupConfID], "副本不存在:"..nDupConfID)
    if CUtil:GetServiceID() ~= tDupConf.nLogicServiceID then
        assert(false, "不能创建非本逻辑服副本:"..nDupConfID)
    end
    local cDupClass = assert(gtGDef.tDupClass[tDupConf.nDupType], "副本类未定义:"..nDupConfID)
    local oDup = cDupClass:new(nDupConfID)
    self.m_tDupMap[oDup:GetDupID()] = oDup
    return oDup
end

--远程调用创建副本
function CDupMgr:CreateDupReq(nDupConfID, tParams)
    return self:CreateDup(nDupConfID, tParams)
end

--移除副本
--@nDupID: 副本唯一ID
function CDupMgr:RemoveDup(nDupID)
    local oDup = self:GetDup(nDupID)
    if not oDup then 
        return LuaTrace("副本不存在", nDupID)
    end
    oDup:Release()
    self.m_tDupMap[nDupID] = nil
end

--进入场景前检测
--@tGameObjParams 进入场景需要的检测数据
--@tDupInfo 副本信息{nDupID=0,nDupConfID=0,nSceneID=0,nSceneConfID=0,nPosX=0,nPosY=0,nLine=0,nFace=0}
function CDupMgr:BeforeEnterSceneCheck(tGameObjParams, tDupInfo, fnCallback)
    local tDupConf = assert(ctDupConf[tDupInfo.nDupConfID], "副本配置不存在:"..tDupInfo.nDupConfID)
    --本地逻辑服
    if CUtil:GetServiceID() == tDupConf.nLogicServiceID then
        local bCanEnter, sError
        local oDup = self:GetDup(tDupInfo.nDupID)
        if not oDup then
            bCanEnter, sError = false, string.format("副本不存在 dupid:%d dupconfid:%d", tDupInfo.nDupID, tDupInfo.nDupConfID)
        else
            bCanEnter, sError = oDup:BeforeEnterSceneCheck(tDupInfo.nSceneID, tGameObjParams)
        end
        if fnCallback then
            fnCallback(bCanEnter, sError)
        else
            return bCanEnter, sError
        end
    --跨逻辑服
    else
        if not fnCallback then
            assert(false, "远程调应该是准确的目标服务进程,不应该再触发远程调用")
        end
        local function _fnEnterCheckCallback(bCanEnter, sError) 
            if fnCallback then
                fnCallback(bCanEnter, sError)
            end
        end

        Network.oRemoteCall:CallWait("BeforeEnterSceneCheckReq",
            _fnEnterCheckCallback,
            CUtil:GetServerByLogic(tDupConf.nLogicServiceID),
            tDupType.nLogicServiceID,
            0, --通常不需要会话ID
            tGameObjParams,
            tDupInfo)
    end
end

--远程调用进入场景前检测
--@tGameObjParams 同上
--@tDupInfo 同上
function CDupMgr:BeforeEnterSceneCheckReq(tGameObjParams, tDupInfo)
    return self:BeforeEnterSceneCheck(tGameObjParams, tDupInfo)
end

--进入副本中的场景
--@oGameLuaObj: 游戏LUA对象
--@tDupInfo: 同上
function CDupMgr:EnterDup(oGameLuaObj, tDupInfo)
    local function _fnEnterCheckCallback(bCanEnter, sError)
        if oGameLuaObj:IsReleased() then
            return LuaTrace("CDupMgr:EnterDup 远程调用过程中游戏对象已释放")
        end
        if not bCanEnter then
            return oGameLuaObj:Tips(sError)
        end

        --本地逻辑服
        local tDupConf = ctDupConf[tDupInfo.nDupConfID]
        if CUtil:GetServiceID() == tDupConf.nLogicServiceID then
            local oDup = self:GetDup(tDupInfo.nDupID)
            assert(oDup, string.format("副本不存在 dupid:%d dupconfid:%d", tDupInfo.nDupID, tDupInfo.nDupConfID))
            tDupInfo.nSource = 1 --做个调用来源标记
            oDup:EnterScene(oGameLuaObj, tDupInfo)

        --跨逻辑服
        else
            if not oGameLuaObj:IsSwitchLogicObjType() then
                assert(false, "对象类型不能切换逻辑服:"..oGameLuaObj:GetObjType())
            end
            local tSwitchData = oGameLuaObj:MakeSwitchLogicData(tDupInfo)
            self:SwitchLogic(tSwitchData)
        end
    end

   local tGameObjParams = oGameLuaObj:GetSceneEnterLeaveCheckParams()
    self:BeforeEnterSceneCheck(tGameObjParams, tDupInfo, _fnEnterCheckCallback)
end

--发起切换逻辑服
function CDupMgr:SwitchLogic(oGameLuaObj, tSwitchData)
    assert(tSwitchData.nSrcDupID ~= tSwitchData.nTarDupID, "切换逻辑服数据错误")
    GetGModule("RoleMgr"):RoleOfflineReq(tSwitchData.nObjID, true) --先把当前逻辑服的角色下了
    Network.oRemoteCall:Call("SwitchLogicReq", tSwitchData.nTarServer, tSwitchData.nTarService, tSwitchData.nSession, tSwitchData)
end

--离开场景前检测
--@tGameObjParams 离开场景需要的检测数据
--@tDupInfo {nDupID=0, nDupConfID=0, nSceneID=0}
function CDupMgr:BeforeLeaveSceneCheck(tGameObjParams, nDupID, nDupConfID, nSceneID)
    local bCanLeave, sError
    local oDup = self:GetDup(nDupID)
    if not oDup then
        bCanLeave, sError = false, string.format("副本不存在 dupid:%d dupconfid:%d", nDupID, nDupConfID)
    else
        bCanLeave, sError = oDup:BeforeLeaveSceneCheck(nSceneID, tGameObjParams)
    end
    return bCanLeave, sError
end

--离开当前所在副本中的场景
function CDupMgr:LeaveDup(oGameLuaObj)
    local nDupID = oGameLuaObj:GetDupID()
    local nDupConfID = oGameLuaObj:GetDupConf().nID
    local nSceneID = oGameLuaObj:GetSceneID()
    local bCanLeave, sError = self:BeforeLeaveSceneCheck(oGameLuaObj:GetSceneEnterLeaveCheckParams(), nDupID, nDupConfID, nSceneID)
    if not bCanLeave then
        return oGameLuaObj:Tips(sError)
    end
    local oDup = oGameLuaObj:GetDup()
    oDup:LeaveScene(oGameLuaObj)
end

--远程请求角色当前场景观察者的角色ID列表,不包括自己
function CDupMgr:RoleObserverListReq(oRole)
    local tRoleIDList = {}
    local oScene = oRole:GetScene()
    local tNativeObjList = oScene:GetAreaObservers(oRole:GetObjID(), gtGDef.tObjType.eRole)
    for _, oNativeObj in ipairs(tNativeObjList) do
        table.insert(tRoleIDList, oNativeObj:GetObjID())
    end
    return tRoleIDList
end

function CDupMgr:PrintDupData()
    LuaTrace(string.format("当前场景总数量%d", self:GetDupCount()))
    local tDupDataMap = {}
    for nDupID, oDup in pairs(self.m_tDupMap) do
        local tDupConf = oDup:GetDupConf()
        tDupDataMap[tDupConf.nID] = tDupDataMap[tDupConf.nID] or 0
        tDupDataMap[tDupConf.nID] = tDupDataMap[tDupConf.nID] + 1
    end
    for nDupConfID, nCount in pairs(tDupDataMap) do
        local tDupConf = ctDupConf[nDupConfID]
        LuaTrace(string.format("场景配置ID(%d) 场景类型(%d) 名称(%s) 数量(%d)", nDupConfID, tDupConf.nDupType, tDupConf.sName, nCount))
    end
end

function CDupMgr:OnMinTimer()
    self:PrintDupData()
end
