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
	gfRawRequire("LoginServer/"..sScript)
end
require("GMMgr/GMMgrInc")
require("LoginMgr/LoginMgrInc")
require("MainRpc")
require("Watcher")

--全局初始化
local function _InitGlobal()
    goDBMgr:InitNew()
    goServerMgr:InitNew(gnServerID)
    
    goRemoteCall:Init()
    goWatcher:Init()
end

--全局反初始化
local function _UninitGlobal()
    local bSuccess = true
    local function fnError(sErr)
        bSuccess = false
        LuaTrace(sErr, debug.traceback())
    end

    xpcall(function() goDBMgr:OnRelease() end, fnError)
    xpcall(function() goServerMgr:OnRelease() end, fnError)
    xpcall(function() goRemoteCall:OnRelease() end, fnError)
    xpcall(function() goLoginMgr:OnRelease() end, fnError)
    xpcall(function() goWatcher:SignOut() end, fnError)
    return bSuccess
end


local nGCTime = 1800 --秒
local function _LuaGC()
    local nClock = os.clock() 
    collectgarbage()
    local sCostTime = string.format("%.4f", os.clock() - nClock)
    local nLuaMemery = math.floor((collectgarbage("count")/1024))
    LuaTrace("Lua memory: ", nLuaMemery, "M time:", sCostTime, " timers:", goTimerMgr:TimerCount())
end	

gnGCTimer = gnGCTimer
function Main()
    _InitGlobal()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 300)
    collectgarbage()
    gnGCTimer = goTimerMgr:Interval(nGCTime, function() _LuaGC() end)

    --屏蔽非法字接口
    GlobalExport.HasWord = nil
    -- for _, tConf in pairs(ctKeywordConf) do
    --     GlobalExport.AddWord(tConf.sKey)
    -- end
    
    LuaTrace("启动 LoginServer 完成******")
end

function OnExitServer(nServer, nService)
    LuaTrace("服务器关闭------beg", nServer, nService)
    gbServerClosing = true
    --所有帐户断线处理
    goLoginMgr:OnServerClose(nServer)
    --全局模块释放
    local bSuccess = _UninitGlobal()
    assert(bSuccess, "注意！！！关服报错了！！！")

    goTimerMgr:Clear(gnGCTimer)
    if goTimerMgr:TimerCount() > 0 then 
        goTimerMgr:DebugLog()
        assert(false, "！！！计时器泄漏！！！剩余:"..goTimerMgr:TimerCount())
    end
    LuaTrace("服务器关闭------end")
end

function Test()
    -- goRemoteCall:Call("Test", 1, 30, 0, "hehehe")
    -- goRemoteCall:CallWait("Test", nil, 1, 30, 0, "hehehe")
end
