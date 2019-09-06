--场景管理器
local table, string, math, os, pairs, ipairs, assert = table, string, math, os, pairs, ipairs, assert


function CDupMgr:Ctor()
    self.m_tDupMap = {}

    self.m_nTimer = nil
    self.m_nDupCount = 0
    self.m_tDupCountData = {}  --{nDupConfID:nNum, ...}
    --测试用
    -- self.m_oMonsterMaker = CMonsterMaker:new(1)
end

function CDupMgr:Init()
    for nDupID, tConf in pairs(ctDupConf) do
        if tConf.nType == CDupBase.tType.eCity and tConf.nLogic == CUtil:GetServiceID() then
            local oDup = self:CreateDup(nDupID)
            --测试用
            if oDup then
                goMonsterMgr:CreateMonster(999, nDupID, -100, -100)
                -- self.m_oMonsterMaker:StartMake()
            end
        end
    end
    self.m_nTimer = GetGModule("TimerMgr"):Interval(300, function() self:Tick() end)
end

--取副本对象
--@nDupMixID: 副本唯一ID, 城镇:=nDupID; 副本:=自增ID<<16|nDupID 下同
function CDupMgr:GetDup(nDupMixID)
    return self.m_tDupMap[nDupMixID]
end

function CDupMgr:GetDupCount() return self.m_nDupCount end
function CDupMgr:AddDupCount(nDupMixID, nNum) 
    self.m_nDupCount = math.max(self.m_nDupCount + nNum, 0)

    local nDupConfID = CUtil:GetDupID(nDupMixID)
    local tDupConf = ctDupConf[nDupConfID]
    assert(tDupConf)
    local nConfIDCount = self.m_tDupCountData[nDupConfID] or 0
    nConfIDCount = nConfIDCount + nNum
    if nConfIDCount == 0 then 
        self.m_tDupCountData[nDupConfID] = nil --删除下，减少统计打印，不用外层判断
    else
        self.m_tDupCountData[nDupConfID] = nConfIDCount 
    end
end

--创建副本
--@nDupID: 副本配置ID 下同
function CDupMgr:CreateDup(nDupID)
    print("CDupMgr:CreateDup***", nDupID)
    local tDupConf = assert(ctDupConf[nDupID], "副本不存在:"..nDupID)
    
    if CUtil:GetServiceID() ~= tDupConf.nLogic then
        assert(false, "不能创建非本逻辑服副本:"..nDupID)
    end
    local nMapID = tDupConf.nMapID
    if not ctMapConf[nMapID] then
        return LuaTrace("副本:", nDupID, "地图不存在:", nMapID)
    end
    local oDup = CDupBase:new(nDupID)
    self.m_tDupMap[oDup:GetMixID()] = oDup
    self:AddDupCount(oDup:GetMixID(), 1)
    return oDup
end

--移除副本
--@nDupMixID: 同上
function CDupMgr:RemoveDup(nDupMixID)
    print("CDupMgr:RemoveDup***", nDupMixID)
    local oDup = self:GetDup(nDupMixID)
    if not oDup then 
        return LuaTrace("副本不存在", nDupMixID)
    end
    oDup:Release()
    self.m_tDupMap[nDupMixID] = nil
    self:AddDupCount(nDupMixID, -1)
end

--进入副本,不存在则失败
--@nDupMixID: 同上
--@oNativeObj: C++对象
--@nPosX,nPosY: 坐标
--@nLine: 分线 0公共线; -1自动
--@nFace: 模型方向(左上0,右上1,右下2,左下3)
--返回值: AOIID, 大于0成功; 小于等于0失败
function CDupMgr:EnterDup(nDupMixID, oNativeObj, nPosX, nPosY, nLine, nFace)
    print("CDupMgr:EnterDup***", nDupMixID, nPosX, nPosY, nLine, nFace)
    if not oNativeObj then 
        assert(false, "请检查代码，重复离开场景或者进入场景未完成即再次离开场景")
    end
    --判断是不是在战斗中
    local oLuaObj = GetLuaObjByNativeObj(oNativeObj)
    if oLuaObj:IsInBattle() then
        return oLuaObj:Tips("战斗中不能切换场景")
    end
    local nDupID = CUtil:GetDupID(nDupMixID)
    local tDupConf = assert(ctDupConf[nDupID], "副本配置不存在:"..nDupID)


    local fnEnterCallback = function()
        --进入新副本
        if CUtil:GetServiceID() == tDupConf.nLogic then
            --城镇
            if tDupConf.nType == CDupBase.tType.eCity then
                local oDup = self:GetDup(nDupMixID)
                assert(oDup, "城镇不存在")
                return oDup:Enter(oNativeObj, nPosX, nPosY, nLine, nFace)

            else
            --副本
                local oDup = self:GetDup(nDupMixID)
                if not oDup then
                    oLuaObj:Tips("副本不存在")
                    return
                end
                return oDup:Enter(oNativeObj, nPosX, nPosY, nLine, nFace)

            end
        end

        --切换逻辑服
        assert(oNativeObj:GetObjType() == gtGDef.tObjType.eRole, "只有角色才跨服务")
        local oRole = goPlayerMgr:GetRoleByID(oNativeObj:GetObjID())
        if not oRole then 
            return
        end
        local tSwitch = {nServer=oRole:GetServer(), nSession=oRole:GetSession(), nRoleID=oRole:GetID()
            , nSrcDupMixID=oRole:GetDupMixID(), nTarDupMixID=nDupMixID
            , nPosX=nPosX, nPosY=nPosY, nLine=nLine, nFace=nFace}
        return self:SwitchLogic(tSwitch)
    end
    return fnEnterCallback()

    --如果是角色 并且当前处于执行上线操作阶段
    -- if oLuaObj:GetObjType() == gtGDef.tObjType.eRole then 
    --     local oRole = oLuaObj
    --     if oRole:IsDealOnline() then 
    --         local fnCheck = function(bRet)
    --             if oRole:IsReleasedd() then --异步事件期间, 角色已经释放, 可能切换逻辑服
    --                 return 
    --             end
    --             --暂时不考虑异步事件期间, 还执行了其他跳转到同逻辑服其他场景的情况
    --             --正常, 上线期间, 发生多次场景跳转,
    --             --都是当前标识场景的回调处理及返回场景处理都检查到需要跳转场景
    --             --就算发生多次跳转, 基本目标场景都是同一个场景, 第二次进入场景不会真正执行
    --             if not bRet then --服务异常
    --                 if oRole:IsOnline() then
    --                     goPlayerMgr:RoleOfflineReq(oRole:GetID())
    --                 end
    --                 return
    --             end
    --             fnEnterCallback()
    --         end
    --         local nServer = oRole:GetServer()
    --         local nService = goServerMgr:GetGlobalService(nServer, 20)
    --         Network:RMCall("AsyncEnterScene", fnCheck, nServer, nService, 0, oRole:GetID())
    --     else
    --         fnEnterCallback()
    --     end
    -- else
    --     fnEnterCallback()
    -- end
    -- return 0
end

--切换逻辑服(请求)
function CDupMgr:SwitchLogic(tSwitch)
    print("CDupMgr:SwitchLogic***", tSwitch)
    --同副本不用切换服务器
    local oRole = goPlayerMgr:GetRoleByID(tSwitch.nRoleID)
    if tSwitch.nSrcDupMixID == tSwitch.nTarDupMixID then
        return self:EnterDup(tSwitch.nTarDupMixID, oRole:GetNativeObj(), tSwitch.nPosX, tSwitch.nPosY, tSwitch.nLine, tSwitch.nFace)
    end
    --同服务器不做远程调用
    local nTarDupID = CUtil:GetDupID(tSwitch.nTarDupMixID)
    local tTarDupConf = assert(ctDupConf[nTarDupID])
    if tTarDupConf.nLogic == CUtil:GetServiceID() then
        return self:EnterDup(tSwitch.nTarDupMixID, oRole:GetNativeObj(), tSwitch.nPosX, tSwitch.nPosY, tSwitch.nLine, tSwitch.nFace)
    end
    if oRole:IsInBattle() then
        return oRole:Tips("战斗中不能切换场景")
    end

    local nTargetServerID = tTarDupConf.nLogic>=100 and gnWorldServerID or tSwitch.nServer 
    if oRole:IsRobot() then --机器人
        -- goPlayerMgr:RoleOfflineReq(tSwitch.nRoleID, false)
        local tCreateData = oRole:GetCreateData()
        local tSaveData = oRole:GetRoleSaveData()
        goPlayerMgr:RoleOfflineReq(tSwitch.nRoleID, true) --把当前逻辑服的角色下了
        Network:RMCall("RobotSwitchLogicReq", nil, nTargetServerID, tTarDupConf.nLogic, 
            tSwitch.nSession, tSwitch, tCreateData, tSaveData)
    else
        --远程调用
        goPlayerMgr:RoleOfflineReq(tSwitch.nRoleID, true) --把当前逻辑服的角色下了
        Network:RMCall("SwitchLogicReq", nil, nTargetServerID, tTarDupConf.nLogic, tSwitch.nSession, tSwitch)
    end
end

--离开副本
function CDupMgr:LeaveDup(nDupMixID, nAOIID)
    if nDupMixID == 0 then
        return LuaTrace("场景ID错误:", nDupMixID, nAOIID, debug.traceback())
    end
    local oDup = self:GetDup(nDupMixID)
    if not oDup then --玩家处于活动场景，离线后，如果期间场景销毁，上线会触发异常
        return LuaTrace("场景不存在错误:", nDupMixID, nAOIID, debug.traceback())
    end
    oDup:Leave(nAOIID)
end

--只针对客户端发起的，做进入和离开检查
function CDupMgr:EnterDupReq(oRole, nDupMixID, nPosX, nPosY, nLine, nFace)
    assert(oRole)
    if not nDupMixID or nDupMixID <= 0 then 
        return 
    end
    local nRoleID = oRole:GetID()
    if oRole:IsInBattle() then
        return oRole:Tips("战斗中不能切换场景")
    end
    local nDupID = CUtil:GetDupID(nDupMixID)
    local tDupConf = ctDupConf[nDupID]
    if not tDupConf then 
        return 
    end
    -- nPosX = math.max(math.min(nPosX, tDupConf.nWidth), 0)
    -- nPosY = math.max(math.min(nPosY, tDupConf.nHeight), 0)
    nPosX = tDupConf.tBorn[1][1]
    nPosY = tDupConf.tBorn[1][2]


    local oCurDup = oRole:GetCurrDupObj()
    if not oCurDup then 
        return 
    end
    if oCurDup:GetMixID() == nDupMixID then 
        return 
    end

    --某些场景，可能对离开场景条件有控制，玩家处于某些状态时，不能离开
    local bCanLeave, sReason = oCurDup:LeaveCheck(nRoleID)
    if not bCanLeave then 
        if sReason then 
            oRole:Tips(sReason)
        end
        return 
    end
    --直接使用本地逻辑服的，不通过世界服rpc中转，数据太多太频繁
    local tRoleParam = {}
    tRoleParam.nLevel = oRole:GetLevel()
    tRoleParam.nRoleConfID = oRole:GetConfID()
    tRoleParam.nTeamID = oRole:GetTeamID()
    tRoleParam.bLeader = oRole:IsLeader()

    if CUtil:GetServiceID() == tDupConf.nLogic then
        local oDup = self:GetDup(nDupMixID)
        if not oDup then
            return oRole:Tips("场景不存在")
        end
        local bCanEnter, sReason = 
            oDup:EnterCheck(nRoleID, tRoleParam)
        if not bCanEnter then 
            if sReason then 
                oRole:Tips(sReason)
            end
            return 
        end
        oRole:EnterScene(nDupMixID, nPosX, nPosY, -1, nFace)
    else
        local nPreDupID = oRole:GetCurrDup()[1]
        local fnEnterCallback = function(bCanEnter, sReason)
            oRole = goPlayerMgr:GetRoleByID(nRoleID) --rpc期间，玩家离线
            if not oRole then return end
            local nCurDupID = oRole:GetCurrDup()[1]
            if nCurDupID ~= nPreDupID then return end --rpc期间，玩家场景发生变化了
            if bCanEnter then 
                oRole:EnterScene(nDupMixID, nPosX, nPosY, -1, nFace)
            elseif sReason then 
                oRole:Tips(sReason)
            end
        end
        Network:RMCall("EnterCheckReq", fnEnterCallback, oRole:GetServer(), 
		tDupConf.nLogic, 0, oRole:GetID(), nDupMixID, tRoleParam)
    end
end


--副本被回收
function CDupMgr:OnDupCollected(nDupMixID)
    LuaTrace("副本地图被收集(CPP)***", nDupMixID, CUtil:GetDupID(nDupMixID))
    local oDup = self:GetDup(nDupMixID)
    if not oDup then
        return
    end
    -- oDup:Release()
    -- self.m_tDupMap[nDupMixID] = nil
    self:RemoveDup(nDupMixID) 
end

--WGLBOAL请求角色当前场景观察者的角色ID列表
function CDupMgr:DupRoleViewListReq(oRole)
    local nDupMixID = oRole:GetDupMixID()
    local oDup = self:GetDup(nDupMixID)
    if not oDup then return end

    local tRoleList = {}
    local tRoleNativeList = oDup:GetAreaObservers(oRole:GetAOIID(), gtGDef.tObjType.eRole)
    for _, oNativeObj in ipairs(tRoleNativeList) do
        table.insert(tRoleList, oNativeObj:GetObjID())
    end
    table.insert(tRoleList, oRole:GetID()) --自己
    return tRoleList
end

function CDupMgr:PrintDupCount()
    LuaTrace(string.format("当前场景总数量%d", self:GetDupCount()))
    for nDupConfID, nCount in pairs(self.m_tDupCountData) do 
        local tDupConf = ctDupConf[nDupConfID]
        assert(tDupConf, "场景不存在:"..nDupConfID)
        LuaTrace(string.format("场景配置ID(%d) 场景类型(%d) 名称(%s) 数量(%d)", nDupConfID, tDupConf.nType, tDupConf.sName, nCount))
    end
end

function CDupMgr:Tick()
    self:PrintDupCount()
end

function CDupMgr:Release()
    GetGModule("TimerMgr"):Clear(self.m_nTimer)
end
