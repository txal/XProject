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

--Common script
require = gfRawRequire or require  --恢复原生require
require("ServerConf")
require("Config/Main")
require("Common/CommonInc")
OpenProto()

--GlobalServer script
gfRawRequire = require 	--hook require
require = function(sScript)
	gfRawRequire("WGlobalServer/"..sScript)
end

require("MainRpc")
require("GMMgr/GMMgrInc")
require("HDMgr/HDMgrInc")
require("Talk/TalkInc")
require("Team/TeamInc")
require("Friend/FriendInc")
require("Marriage/MarriageInc")
require("Relationship/RelationshipInc")
require("Gift/GiftInc")
require("Invite/InviteInc")
require("GRobotMgr/GRobotMgrInc")
require("GPVPActivity/GPVPActivityInc")
require("GPVEActivity/GPVEActivityInc")

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
        local nLuaMemery = math.floor((collectgarbage("count")/1024))
        LuaTrace("Lua memory: ", nLuaMemery, "M time:", sCostTime, " index:", nGCIndex, " timers:", GetGModule("TimerMgr"):TimerCount())
    end
    nGCIndex = nGCIndex + 1
end

function Main()
    _InitGlobal()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 300)
    collectgarbage()
    gnGCTimer = GetGModule("TimerMgr"):Interval(nGCTime, function() _LuaGC() end)
	LuaTrace("启动 WGlobalServer 成功")

    --加载非法字
    for _, tConf in pairs(ctKeywordConf) do
        GlobalExport.AddWord(tConf.sKey)
    end
end

function OnExitServer(nServer, nService)
    LuaTrace("服务器关闭------beg", nServer, nService)
    gbServerClosing = true
    local bSuccess = _UninitGlobal()
    assert(bSuccess, "注意！！！关服报错了！！！")

    GetGModule("TimerMgr"):Clear(gnGCTimer)
    if GetGModule("TimerMgr"):TimerCount() > 0 then
        GetGModule("TimerMgr"):DebugLog()
        assert(false, "！！！计时器泄漏！！！剩余:"..GetGModule("TimerMgr"):TimerCount())
    end
    LuaTrace("服务器关闭------end")
end
