math.randomseed(os.clock()*1000)
math.random() math.random() math.random()
cjson.encode_sparse_array(true, 1, 1) --稀疏表转换成对象
cjson_raw.encode_sparse_array(true, 1, 1) --稀疏表转换成对象

--打开协议
local function OpenProto()
    local f = io.open("protopath.txt", "r")
    if not f then
        require("../../Data/Protobuf/LoadPBCProto")
        LoadProto("../../Data/Protobuf")
        return
    else
        local sLoaderPath = f:read("l")
        local sProtoPath = f:read("l")
        f:close()
        require(sLoaderPath)
        LoadProto(sProtoPath)
        return
    end
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

--全局初始化
local function _InitGlobal()
    goDBMgr:Init()
    goRemoteCall:Init()
end

--全局反初始化
local function _UninitGlobal()
    local bSuccess = true
    local function fnError(sErr)
        bSuccess=false
        LuaTrace(sErr, debug.traceback())
    end

    xpcall(function() goRemoteCall:OnRelease() end, fnError)
    return bSuccess
end


local nGCTime = 180 --秒
local function _LuaGC()
    collectgarbage()
end	

gnGCTimer = gnGCTimer
function Main()
    _InitGlobal()
    collectgarbage("setpause", 100)
    collectgarbage("setstepmul", 300)
    collectgarbage()
    gnGCTimer = goTimerMgr:Interval(nGCTime, function() _LuaGC() end)
    LuaTrace("启动 LoginServer 完成******")
    Test()
end

function OnExitServer()
    LuaTrace("OnExitServer start***")
    goTimerMgr:Clear(gnGCTimer)
    local bSuccess = _UninitGlobal()
    assert(bSuccess, "注意！！！关服报错了！！！")
    if goTimerMgr:TimerCount() > 0 then
        assert(false, "！！！计时器泄漏！！！剩余:"..goTimerMgr:TimerCount())
    end
    LuaTrace("OnExitServer finish***")
    os.exit()
end

function Test()
    -- goRemoteCall:Call("Test", 1, 30, 0, "hehehe")
    -- goRemoteCall:CallWait("Test", nil, 1, 30, 0, "hehehe")
end
