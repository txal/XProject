math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象
cjson_raw.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--打开协议
local function OpenProto()
    local sDir = gsDataPath and gsDataPath or "../../"
    require(sDir.."/Data/Protobuf/LoadPBCProto")
    LoadProto(sDir.."/Data/Protobuf")
end

--通用脚本
require = gfRawRequire or require  --恢复原生require
require("ServerConf")
require("Config/Main")
require("Common/CommonInc")
OpenProto()

--逻辑服
gfRawRequire = require  --hook require
require = function(sScript)
	gfRawRequire("LogicServer/"..sScript)
end
require("MainRpc")
require("Global/GlobalInc")
require("Player/PlayerInc")
require("LRobot/LRobotInc")
require("Monster/MonsterInc")
require("Module/ModuleInc")
require("Dup/DupInc")
require("NpcFunc/NpcInc")
require("BattleDup/BattleDupInc")
require("PVPActivity/PVPActivityInc")
require("Arena/ArenaLogicInc")
require("Marriage/MarriageLogicInc")
require("Market/MarketLogicRpc")
require("EventHandler/EventHandlerInc")
require("RoleTimeExpiryMgr/RoleTimeExpiryMgrInc")  --必须在角色相关Module后面加载


--全局初始化
local function _InitGlobal()
    goDBMgr:InitNew()
    goServerMgr:InitNew(gnServerID)
    
    goRemoteCall:Init()
    goClientCall:Init(GF.GetServiceID())
    
    goRoleTimeExpiryMgr:Init()
    goDupMgr:Init()
    goPVPActivityMgr:Init()
    goPVEActivityMgr:Init()
    goMultiConfirmBoxMgr:Init(GF.GetServiceID())
    CMarriageSceneMgr:Inst() --必须在DupMgr:Init后面初始化
    CFBTransitScene:Inst()
    goNpcMgr:LoadData()

end

--全局反初始化
local function _UninitGlobal()
    local bSuccess = true
    local function fnError(sErr)
        bSuccess = false
        LuaTrace(sErr, debug.traceback())
    end

    xpcall(function() goLRobotMgr:OnRelease() end, fnError) --必须在BattleMgr和BattleDupMgr之前
    xpcall(function() goDBMgr:OnRelease() end, fnError)
    xpcall(function() goServerMgr:OnRelease() end, fnError)
    xpcall(function() goClientCall:OnRelease() end, fnError)
    xpcall(function() goBattleMgr:OnRelease() end, fnError)
    xpcall(function() goPVPActivityMgr:OnRelease() end, fnError)
    xpcall(function() goPVEActivityMgr:OnRelease() end, fnError)
    xpcall(function() goMultiConfirmBoxMgr:OnRelease() end, fnError)
    xpcall(function() if goMarriageSceneMgr then goMarriageSceneMgr:OnRelease() end end, fnError)
    xpcall(function() if goFBTransitScene then goFBTransitScene:OnRelease() end end, fnError)
    xpcall(function() goNpcMgr:OnRelease() end, fnError)
    xpcall(function() goBattleDupMgr:OnRelease() end, fnError)
    xpcall(function() goRoleTimeExpiryMgr:OnRelease() end, fnError)
    xpcall(function() goPlayerMgr:OnRelease() end, fnError)
    xpcall(function() goDupMgr:OnRelease() end, fnError)
    xpcall(function() goRemoteCall:OnRelease() end, fnError)

    return bSuccess
end

--GC
local nGCIndex = 0
local nGCTime = 10
local function _LuaGC()
    local nClock = os.clock() 
    if nGCIndex % 180 == 0 then
        collectgarbage()
    else
        collectgarbage("step", 1024) --k
    end
    if nGCIndex % 30 == 0 then --5分钟打印1次
        local sCostTime = string.format("%.4f", os.clock() - nClock)
        local nLuaMemery = (collectgarbage("count")/1024)
       LuaTrace("Lua memory: ", nLuaMemery, "M time:", sCostTime, " index:", nGCIndex, " timers:", goTimerMgr:TimerCount(), goPlayerMgr:GetCount())
    end
    nGCIndex = nGCIndex + 1
end

--主函数
gnGCTimer = gnGCTimer
function Main()
    _InitGlobal()
    collectgarbage()
    collectgarbage("setpause", 100) --开启新的循环前不等待
    collectgarbage("setstepmul", 300) --内存分配速度的3倍
    gnGCTimer = goTimerMgr:Interval(nGCTime, function() _LuaGC() end)
    
    local nLuaMemory = math.floor((collectgarbage("count")/1024))
    LuaTrace("启动 LogicServer 完成******", "lua memory:", nLuaMemory)

    if gnServerID ~= gnWorldServerID then
        goServerMgr:OnLogicStart()
    end
end

--准备退出进程
function OnExitServer(nServer, nService)
    LuaTrace("服务器关闭------beg", nServer, nService)

    gbServerClosing = true
    --强制相关服所有玩家下线
    goPlayerMgr:OnServerClose(nServer)

    if nServer == gnServerID and nService == GF.GetServiceID() then
        --全局模块释放
        local bSuccess = _UninitGlobal()
        assert(bSuccess, "注意！！！关服报错了！！！")

        --计时器检测
        goTimerMgr:Clear(gnGCTimer)
        if goTimerMgr:TimerCount() > 0 then
            goTimerMgr:DebugLog()
            assert(false, "！！！计时器泄漏！！！剩余:"..goTimerMgr:TimerCount())
        end
    end
    
    LuaTrace("服务器关闭------end")

end
