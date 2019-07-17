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
    goGModuleMgr:Init()
    Network:Init()
end

--全局反初始化
local function _UninitGlobal()
    local bSuccess = true
    local function fnError(sErr)
        bSuccess = false
        LuaTrace(sErr, debug.traceback())
    end

    xpcall(function() goGModuleMgr:Release() end, fnError)
    xpcall(function() Network:Release() end, fnError)
    return bSuccess
end

--GC
local nGCIndex = 0
local nGCTime = 10
gnGCTimer = gnGCTimer
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
       LuaTrace("Lua memory: ", nLuaMemery, "M time:", sCostTime, " index:", nGCIndex, " timers:", GetGModule("TimerMgr"):TimerCount())
    end
    nGCIndex = nGCIndex + 1
end

--主函数
function Main()
    _InitGlobal()
    collectgarbage()
    collectgarbage("setpause", 100) --开启新的循环前不等待
    collectgarbage("setstepmul", 300) --内存分配速度的3倍
    gnGCTimer = GetGModule("TimerMgr"):Interval(nGCTime, function() _LuaGC() end)
    
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

    if nServer == gnServerID and nService == CUtil:GetServiceID() then
        --全局模块释放
        local bSuccess = _UninitGlobal()
        assert(bSuccess, "注意！！！关服报错了！！！")

        --计时器检测
        GetGModule("TimerMgr"):Clear(gnGCTimer)
        if GetGModule("TimerMgr"):TimerCount() > 0 then
            GetGModule("TimerMgr"):DebugLog()
            assert(false, "！！！计时器泄漏！！！剩余:"..GetGModule("TimerMgr"):TimerCount())
        end
    end
    
    LuaTrace("服务器关闭------end")

end
