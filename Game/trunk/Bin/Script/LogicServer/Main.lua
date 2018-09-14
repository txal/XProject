math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--通用脚本
require = gfRawRequire or require  --恢复原生require
require("Config/Main")
require("Common/CommonInc")
require("../../Data/Protobuf/LoadPBCProto")
LoadProto()

--逻辑服
gfRawRequire = require  --hook require
require = function(sScript)
	gfRawRequire("LogicServer/"..sScript)
end
require("MainRpc")
require("ItemDef")
require("GameDef")
require("Global/GlobalInc")
require("Module/ModuleInc")
require("Player/PlayerInc")
require("DBMgr/DBMgrInc")
require("GameMgr/GameMgrInc")
require("Robot/RobotInc")

--检测配置
require("ConfCheck/ConfCheckInc")

--全局初始化
local function _InitGlobal()
    goDBMgr:Init()
    goGameMgr:Init()
    -- goMailMgr:LoadData()
    -- goMailQueue:LoadData()
    -- goOfflinePlayerMgr:LoadData()

end

--全局反初始化
local function _UninitGlobal()
    local function _release_global()
        -- goMailMgr:OnRelease()
        -- goMailQueue:OnRelease()
        -- goOfflinePlayerMgr:OnRelease()

     end
    xpcall(_release_global, function(sErr) LuaTrace(sErr) end)
end

--GC
local nGCIndex = 0
local nGCTime = 10*1000
local function _LuaGC()
    local nClock = os.clock() 
    if nGCIndex % 6 == 0 then
        collectgarbage()
    else
        collectgarbage("step", 256) --KB
    end
    if nGCIndex % 60 == 0 then --10分钟打印1次
        local sCostTime = string.format("%.4f", os.clock() - nClock)
        local nLuaMemery = math.floor((collectgarbage("count")/1024))
        LuaTrace("Lua memory: "..nLuaMemery.."M time:"..sCostTime.." index:"..nGCIndex)
    end
    nGCIndex = nGCIndex + 1
end

--主函数
function Main()
    _InitGlobal()
    collectgarbage()
    collectgarbage("setpause", 100) --开启新的循环前不等待
    collectgarbage("setstepmul", 300) --内存分配速度的3倍
    GlobalExport.RegisterTimer(nGCTime, function() _LuaGC() end)
    LuaTrace("LogicServer lua start successful")
    Test()
end

function Test()
end

--准备退出进程
function OnExitServer()
    LuaTrace("OnExitServer start***")
    _UninitGlobal()
    LuaTrace("OnExitServer finish***")
    os.exit()
end
